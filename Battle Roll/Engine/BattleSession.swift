import Foundation
import Combine

/// Drives a Spearhead battle through the official sequence:
/// 4 battle rounds; each round starts with priority/underdog/twist/tactic draws,
/// then two player turns of 7 phases each. Scoring happens at end of each turn.
final class BattleSession: ObservableObject {
    @Published var state: BattleState
    let season: SeasonPack
    let realm: RealmBattlefield
    let armies: [PlayerSide.RawValue: SpearheadArmy]

    private var cancellable: AnyCancellable?
    var onAutosave: ((BattleState) -> Void)?

    init(state: BattleState, season: SeasonPack, armies: [PlayerSide.RawValue: SpearheadArmy]) {
        self.state = state
        self.season = season
        self.realm = season.realms.first { $0.id == state.realmID } ?? season.realms[0]
        self.armies = armies
        cancellable = $state
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] s in self?.onAutosave?(s) }
    }

    // MARK: - Setup

    static func newBattle(season: SeasonPack,
                          realmID: String,
                          desolation: Bool,
                          attacker: PlayerSide,
                          one: (name: String, army: SpearheadArmy, regiment: String, enhancement: String),
                          two: (name: String, army: SpearheadArmy, regiment: String, enhancement: String)) -> BattleSession {
        var s = BattleState(seasonID: season.id, realmID: realmID)
        s.desolationEnabled = desolation
        s.attacker = attacker

        func makePlayer(_ p: (name: String, army: SpearheadArmy, regiment: String, enhancement: String)) -> PlayerBattleState {
            var ps = PlayerBattleState(name: p.name, armyID: p.army.id,
                                       regimentAbilityName: p.regiment, enhancementName: p.enhancement)
            for scroll in p.army.units {
                if scroll.instances > 1 {
                    for i in 1...scroll.instances {
                        ps.units.append(UnitState(warscrollName: scroll.name, label: "\(scroll.name) (\(i))"))
                    }
                } else {
                    ps.units.append(UnitState(warscrollName: scroll.name, label: scroll.name))
                }
            }
            for card in season.battleTactics {
                ps.tacticLocations[card.name] = .inDeck
            }
            return ps
        }

        s.players[PlayerSide.one.rawValue] = makePlayer(one)
        s.players[PlayerSide.two.rawValue] = makePlayer(two)
        return BattleSession(state: s,
                             season: season,
                             armies: [PlayerSide.one.rawValue: one.army, PlayerSide.two.rawValue: two.army])
    }

    func army(for side: PlayerSide) -> SpearheadArmy { armies[side.rawValue]! }
    func warscroll(for unit: UnitState, side: PlayerSide) -> WarscrollData? {
        army(for: side).units.first { $0.name == unit.warscrollName }
    }

    // MARK: - Start of round

    /// Round 1: attacker chooses. Rounds 2-4: priority roll winner chooses (tie: previous first player chooses).
    func beginRound(firstPlayer: PlayerSide, wonPriorityAfterGoingSecond: Bool) {
        state.firstPlayerByRound[state.round] = firstPlayer
        state.underdog = state.round >= 2 ? state.trailingPlayer() : nil
        state.seizedInitiative = nil

        if state.round >= 2, wonPriorityAfterGoingSecond,
           firstPlayer == state.firstPlayerByRound[state.round - 1]?.other {
            state.seizedInitiative = firstPlayer
        }
        state.stage = .firstTurn
        state.phase = .startOfTurn
    }

    /// True if `side` skips its battle tactic draw this round (seized the initiative).
    func skipsTacticDraw(_ side: PlayerSide) -> Bool {
        guard state.seizedInitiative == side else { return false }
        let isBigUnderdog = state.underdog == side && state.vpDifference() >= 5
        return !isBigUnderdog
    }

    func drawTwist(_ name: String) {
        state.twistByRound[state.round] = name
    }

    func drawRandomTwist() {
        let drawn = Set(state.twistByRound.values)
        let remaining = realm.twists.filter { !drawn.contains($0.name) }
        if let card = remaining.randomElement() {
            state.twistByRound[state.round] = card.name
        }
    }

    var currentTwist: TwistCard? {
        guard let name = state.currentTwistName else { return nil }
        return realm.twists.first { $0.name == name }
    }

    // MARK: - Battle tactic cards

    func tacticLocation(_ card: String, for side: PlayerSide) -> TacticCardLocation {
        state[side].tacticLocations[card] ?? .inDeck
    }

    func setTactic(_ card: String, to location: TacticCardLocation, for side: PlayerSide) {
        state[side].tacticLocations[card] = location
        if location == .scored {
            state[side].vpLog.append(VPEntry(round: state.round, player: side,
                                             source: "Battle Tactic: \(card)", points: 1))
        }
    }

    /// Draw random cards from the deck until the hand has 3 (mirrors physical play if you prefer the app to draw).
    func drawRandomTactics(for side: PlayerSide) {
        var hand = state[side].handCount
        while hand < 3 {
            let deck = season.battleTactics.map(\.name).filter { tacticLocation($0, for: side) == .inDeck }
            guard deck.count > state[side].hiddenHandCount, let card = deck.randomElement() else { break }
            state[side].tacticLocations[card] = .inHand
            hand += 1
        }
    }

    /// Cards still in the unrevealed pool for `side` (the deck, which may include their hidden hand).
    func deckCount(for side: PlayerSide) -> Int {
        season.battleTactics.filter { tacticLocation($0.name, for: side) == .inDeck }.count
    }

    /// Track `side`'s hand face down: you know how many cards they hold, not which.
    /// Clamped so known + hidden never exceeds 3 and hidden never exceeds the deck.
    func setHiddenHandCount(_ count: Int, for side: PlayerSide) {
        let maxHidden = min(deckCount(for: side), 3 - state[side].knownHandCount)
        state[side].hiddenHandCount = max(0, min(count, maxHidden))
    }

    /// One of `side`'s face-down cards is revealed to be `card` (they used its
    /// command, scored it, or discarded it). Moves it out of the hidden hand.
    func revealHiddenTactic(_ card: String, as location: TacticCardLocation, for side: PlayerSide) {
        guard state[side].hiddenHandCount > 0,
              tacticLocation(card, for: side) == .inDeck else { return }
        state[side].hiddenHandCount -= 1
        setTactic(card, to: location, for: side)
    }

    // MARK: - Phases & turns

    func advancePhase() {
        guard !state.isOver else { return }
        state[state.activePlayer].usedThisPhase.removeAll()
        state[state.activePlayer.other].usedThisPhase.removeAll()
        if let next = state.phase.next {
            state.phase = next
        }
    }

    func retreatPhase() {
        if let prev = state.phase.previous {
            state.phase = prev
        }
    }

    /// Called after end-of-turn scoring is committed.
    func endTurn() {
        let active = state.activePlayer
        state[active].usedThisTurn.removeAll()
        state[active.other].usedThisTurn.removeAll()
        state[active].usedThisPhase.removeAll()
        state[active.other].usedThisPhase.removeAll()

        switch state.stage {
        case .startOfRound, .firstTurn:
            state.stage = .secondTurn
            state.phase = .startOfTurn
        case .secondTurn:
            if state.round >= 4 {
                state.isOver = true
            } else {
                state.round += 1
                state.stage = .startOfRound
                state.phase = .startOfTurn
            }
        }
    }

    /// End-of-turn objective scoring per the official rules (1+1+1) plus twist extras.
    func commitEndOfTurnScoring(for side: PlayerSide,
                                controlsOne: Bool,
                                controlsTwoPlus: Bool,
                                controlsMore: Bool,
                                tacticsCompleted: [String],
                                twistExtraVP: Int) {
        var objectiveVP = 0
        if controlsOne { objectiveVP += 1 }
        if controlsTwoPlus { objectiveVP += 1 }
        if controlsMore { objectiveVP += 1 }
        if objectiveVP > 0 {
            state[side].vpLog.append(VPEntry(round: state.round, player: side,
                                             source: "Objectives", points: objectiveVP))
        }
        for card in tacticsCompleted {
            // A card scored from a face-down hand is revealed at this moment.
            if tacticLocation(card, for: side) == .inDeck, state[side].hiddenHandCount > 0 {
                revealHiddenTactic(card, as: .scored, for: side)
            } else {
                setTactic(card, to: .scored, for: side)
            }
        }
        if twistExtraVP != 0 {
            state[side].vpLog.append(VPEntry(round: state.round, player: side,
                                             source: "Twist: \(state.currentTwistName ?? "")",
                                             points: twistExtraVP))
        }
        endTurn()
    }

    func adjustVP(for side: PlayerSide, by points: Int, reason: String = "Adjustment") {
        state[side].vpLog.append(VPEntry(round: state.round, player: side, source: reason, points: points))
    }

    // MARK: - Units

    func setDamage(_ damage: Int, slainModels: Int, on unitID: UUID, side: PlayerSide) {
        guard let i = state[side].units.firstIndex(where: { $0.id == unitID }) else { return }
        state[side].units[i].damage = max(0, damage)
        state[side].units[i].slainModels = max(0, slainModels)
        if let scroll = warscroll(for: state[side].units[i], side: side) {
            let destroyed = scroll.modelsPerUnit > 1
                ? state[side].units[i].slainModels >= scroll.modelsPerUnit
                : state[side].units[i].damage >= scroll.health
            state[side].units[i].isDestroyed = destroyed
        }
    }

    func toggleDestroyed(_ unitID: UUID, side: PlayerSide) {
        guard let i = state[side].units.firstIndex(where: { $0.id == unitID }) else { return }
        state[side].units[i].isDestroyed.toggle()
    }

    /// Call for Reinforcements: replace a destroyed Reinforcements unit (once each).
    func callReinforcements(for unitID: UUID, side: PlayerSide) {
        guard let i = state[side].units.firstIndex(where: { $0.id == unitID }) else { return }
        var unit = state[side].units[i]
        guard unit.isDestroyed, !unit.hasBeenReplaced, !unit.isReplacement else { return }
        state[side].units[i].hasBeenReplaced = true
        unit = state[side].units[i]
        var replacement = UnitState(warscrollName: unit.warscrollName,
                                    label: unit.label + " ↺",
                                    isReplacement: true)
        replacement.hasBeenReplaced = true
        state[side].units.insert(replacement, at: i + 1)
        markUsed(key: "core|Call for Reinforcements", frequency: .oncePerTurn, side: side)
    }

    /// Units eligible for Call for Reinforcements right now.
    func reinforcementCandidates(for side: PlayerSide) -> [UnitState] {
        state[side].units.filter { unit in
            unit.isDestroyed && !unit.hasBeenReplaced && !unit.isReplacement
                && (warscroll(for: unit, side: side)?.reinforcements ?? false)
        }
    }

    // MARK: - Ability usage

    func usageKey(source: String, ability: String) -> String { "\(source)|\(ability)" }

    func isUsed(key: String, frequency: AbilityFrequency, side: PlayerSide) -> Bool {
        switch frequency {
        case .passive, .unlimited:
            return false
        case .oncePerPhase:
            return state[side].usedThisPhase.contains(key)
        case .oncePerTurn:
            return state[side].usedThisTurn.contains(key)
        case .oncePerTurnArmy:
            // Shared across the army: match on ability name only.
            let name = key.split(separator: "|").last.map(String.init) ?? key
            return state[side].usedThisTurn.contains { $0.hasSuffix("|\(name)") }
        case .oncePerBattle:
            return state[side].usedThisBattle.contains(key)
        }
    }

    func markUsed(key: String, frequency: AbilityFrequency, side: PlayerSide) {
        switch frequency {
        case .passive, .unlimited:
            break
        case .oncePerPhase:
            state[side].usedThisPhase.insert(key)
        case .oncePerTurn, .oncePerTurnArmy:
            state[side].usedThisTurn.insert(key)
        case .oncePerBattle:
            state[side].usedThisBattle.insert(key)
        }
    }

    func unmarkUsed(key: String, side: PlayerSide) {
        state[side].usedThisPhase.remove(key)
        state[side].usedThisTurn.remove(key)
        state[side].usedThisBattle.remove(key)
    }

    // MARK: - Desolation module

    var desolationModule: RulesModule? {
        guard state.desolationEnabled else { return nil }
        return season.modules.first { $0.id == "desolation" }
    }
}
