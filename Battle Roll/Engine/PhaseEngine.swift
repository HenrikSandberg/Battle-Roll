import Foundation

/// One row in the phase-filtered ability list.
struct AbilityItem: Identifiable {
    enum Source {
        case battleTrait
        case regimentAbility
        case enhancement
        case unit(UnitState)
        case core
        case module
        case tacticCommand(BattleTacticCard)
    }

    let owner: PlayerSide
    let source: Source
    let sourceLabel: String
    let ability: AbilityData
    let usageKey: String

    var id: String { "\(owner.rawValue)|\(usageKey)" }

    var isStartOfPhaseReminder: Bool { ability.window == .start }
    var isReaction: Bool { ability.window == .reaction }
}

/// Builds the list of abilities available to each player in the current phase.
/// Destroyed units are excluded; the general's enhancement disappears with the general.
enum PhaseEngine {

    static let coreAbilityTable: [GamePhase: [AbilityData]] = [
        .movement: [
            AbilityData(name: "Normal Move", declare: "Pick a friendly unit that is not in combat.",
                        effect: "The unit can move up to its Move characteristic. It cannot move into combat.",
                        timingText: "Your Movement Phase", phase: .movement, turn: .yours, window: .during, frequency: .unlimited),
            AbilityData(name: "Run", declare: "Pick a friendly unit that is not in combat.",
                        effect: "Make a run roll of D6. The unit can move up to its Move plus the run roll. It cannot move into combat, and cannot shoot or charge this turn.",
                        timingText: "Your Movement Phase", phase: .movement, turn: .yours, window: .during, frequency: .unlimited),
            AbilityData(name: "Retreat", declare: "Pick a friendly unit that is in combat.",
                        effect: "Inflict D3 mortal damage on the unit. It can move up to its Move, through enemy combat ranges, but cannot end the move in combat. It cannot shoot or charge this turn.",
                        timingText: "Your Movement Phase", phase: .movement, turn: .yours, window: .during, frequency: .unlimited)
        ],
        .shooting: [
            AbilityData(name: "Shoot", declare: "Pick a friendly unit that has not used Run or Retreat this turn, then pick enemy target(s).",
                        effect: "Resolve shooting attacks against the target unit(s).",
                        timingText: "Your Shooting Phase", phase: .shooting, turn: .yours, window: .during, frequency: .unlimited)
        ],
        .charge: [
            AbilityData(name: "Charge", declare: "Pick a friendly unit not in combat that has not used Run or Retreat this turn, then make a charge roll of 2D6.",
                        effect: "The unit can move up to the charge roll, through enemy combat ranges, and must end within ½\" of an enemy unit. If it does, it has charged.",
                        timingText: "Your Charge Phase", phase: .charge, turn: .yours, window: .during, frequency: .unlimited)
        ],
        .combat: [
            AbilityData(name: "Fight", declare: "Pick a friendly unit that is in combat or that charged this turn. It can make a pile-in move, then pick enemy target(s).",
                        effect: "Resolve combat attacks against the target unit(s). Players alternate using Fight abilities, starting with the active player.",
                        timingText: "Any Combat Phase", phase: .combat, turn: .any, window: .during, frequency: .oncePerTurn)
        ]
    ]

    /// All ability items for `side` in the current phase. `activeSide` is whose turn it is.
    static func items(for side: PlayerSide,
                      session: BattleSession,
                      phase: GamePhase,
                      includePassives: Bool) -> [AbilityItem] {
        let army = session.army(for: side)
        let player = session.state[side]
        let isActive = (side == session.state.activePlayer)
        var result: [AbilityItem] = []

        func relevant(_ a: AbilityData) -> Bool {
            if a.frequency == .passive { return includePassives }
            guard a.phase.matches(phase) else { return false }
            switch a.turn {
            case .yours: return isActive
            case .enemy: return !isActive
            case .any: return true
            }
        }

        func add(_ a: AbilityData, source: AbilityItem.Source, label: String) {
            guard relevant(a) else { return }
            result.append(AbilityItem(owner: side, source: source, sourceLabel: label,
                                      ability: a, usageKey: session.usageKey(source: label, ability: a.name)))
        }

        // Army-wide rules
        for trait in army.battleTraits {
            add(trait, source: .battleTrait, label: "Battle Trait")
        }
        if let regiment = army.regimentAbilities.first(where: { $0.name == player.regimentAbilityName }) {
            add(regiment, source: .regimentAbility, label: "Regiment Ability")
        }

        // Enhancement lives on the general; gone if the general is destroyed.
        let generalAlive = player.units.contains { unit in
            !unit.isDestroyed && (session.warscroll(for: unit, side: side)?.isGeneral ?? false)
        }
        if generalAlive,
           let enhancement = army.enhancements.first(where: { $0.name == player.enhancementName }) {
            add(enhancement, source: .enhancement, label: "Enhancement (General)")
        }

        // Unit abilities, excluding destroyed units.
        for unit in player.units where !unit.isDestroyed {
            guard let scroll = session.warscroll(for: unit, side: side) else { continue }
            for a in scroll.abilities {
                add(a, source: .unit(unit), label: unit.label)
            }
        }

        // Call for Reinforcements (core), if any destroyed Reinforcements unit can return.
        if phase == .movement, isActive, !session.reinforcementCandidates(for: side).isEmpty {
            let core = AbilityData(
                name: "Call for Reinforcements",
                declare: "Pick a friendly Reinforcements unit that has been destroyed.",
                effect: "Set up an identical replacement unit wholly within friendly territory, wholly within 6\" of the battlefield edge and not in combat. Each Reinforcements unit can only be replaced once.",
                timingText: "Once Per Turn, Your Movement Phase",
                phase: .movement, turn: .yours, window: .during, frequency: .oncePerTurn)
            result.append(AbilityItem(owner: side, source: .core, sourceLabel: "Core",
                                      ability: core, usageKey: session.usageKey(source: "core", ability: core.name)))
        }

        // Desolation module abilities.
        if let module = session.desolationModule {
            for a in module.abilities {
                add(a, source: .module, label: module.name)
            }
        }

        // Battle tactic commands in hand that can be used now.
        for card in season(session).battleTactics where session.tacticLocation(card.name, for: side) == .inHand {
            let cmd = card.command
            let asAbility = AbilityData(name: "\(cmd.name) (discard \(card.name))",
                                        effect: cmd.effect,
                                        timingText: cmd.timingText,
                                        phase: cmd.phase, turn: cmd.turn, window: cmd.window,
                                        frequency: .unlimited)
            // Reactions can come up in several phases; show them in matching phases only.
            guard asAbility.phase == .any || asAbility.phase.matches(phase) else { continue }
            switch cmd.turn {
            case .yours: guard isActive else { continue }
            case .enemy: guard !isActive else { continue }
            case .any: break
            }
            result.append(AbilityItem(owner: side, source: .tacticCommand(card), sourceLabel: "Command",
                                      ability: asAbility,
                                      usageKey: session.usageKey(source: "command", ability: card.name)))
        }

        return result
    }

    static func coreAbilities(for phase: GamePhase) -> [AbilityData] {
        coreAbilityTable[phase] ?? []
    }

    private static func season(_ session: BattleSession) -> SeasonPack { session.season }
}
