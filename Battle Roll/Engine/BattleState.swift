import Foundation

enum PlayerSide: String, Codable, CaseIterable, Identifiable {
    case one, two
    var id: String { rawValue }
    var other: PlayerSide { self == .one ? .two : .one }
}

/// Where a battle tactic card currently is for one player.
enum TacticCardLocation: String, Codable {
    case inDeck
    case inHand
    case scored
    case usedAsCommand
    case discarded
}

/// A live unit on the table.
struct UnitState: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var warscrollName: String
    var label: String            // "Sisters of Slaughter (2)"
    var damage: Int = 0          // damage points allocated to the unit
    var slainModels: Int = 0     // for multi-model units
    var isDestroyed: Bool = false
    var isReplacement: Bool = false   // this unit is a reinforcements replacement
    var hasBeenReplaced: Bool = false // reinforcements already used for this unit
}

/// One scoring event in the VP log.
struct VPEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var round: Int
    var player: PlayerSide
    var source: String           // "Objectives", "Battle Tactic: Raid", "Twist", "Adjustment"
    var points: Int
}

/// Per-player battle state.
struct PlayerBattleState: Codable {
    var name: String
    var armyID: String
    var regimentAbilityName: String
    var enhancementName: String
    var units: [UnitState] = []
    var tacticLocations: [String: TacticCardLocation] = [:]
    /// Cards known to be in this player's hand but not identified (face-down
    /// tracking for an opponent whose hand you cannot see). They conceptually
    /// belong to the `.inDeck` pool until revealed.
    var hiddenHandCount: Int = 0
    var vpLog: [VPEntry] = []

    // Ability usage tracking. Keys are "<sourceLabel>|<abilityName>".
    var usedThisBattle: Set<String> = []
    var usedThisTurn: Set<String> = []
    var usedThisPhase: Set<String> = []

    // Desolation module.
    var desolationPoints: Int = 0
    var desolatedCount: Int = 0  // objectives + terrain currently desolated by this player

    var totalVP: Int { vpLog.reduce(0) { $0 + $1.points } }
    var knownHandCount: Int { tacticLocations.values.filter { $0 == .inHand }.count }
    var handCount: Int { knownHandCount + hiddenHandCount }
    var scoredTacticCount: Int { tacticLocations.values.filter { $0 == .scored }.count }

    enum CodingKeys: String, CodingKey {
        case name, armyID, regimentAbilityName, enhancementName, units
        case tacticLocations, hiddenHandCount, vpLog
        case usedThisBattle, usedThisTurn, usedThisPhase
        case desolationPoints, desolatedCount
    }
}

// Tolerant decoding so saves made before `hiddenHandCount` existed still resume.
// Defined in an extension to keep the synthesized memberwise initializer.
extension PlayerBattleState {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        armyID = try c.decode(String.self, forKey: .armyID)
        regimentAbilityName = try c.decodeIfPresent(String.self, forKey: .regimentAbilityName) ?? ""
        enhancementName = try c.decodeIfPresent(String.self, forKey: .enhancementName) ?? ""
        units = try c.decodeIfPresent([UnitState].self, forKey: .units) ?? []
        tacticLocations = try c.decodeIfPresent([String: TacticCardLocation].self, forKey: .tacticLocations) ?? [:]
        hiddenHandCount = try c.decodeIfPresent(Int.self, forKey: .hiddenHandCount) ?? 0
        vpLog = try c.decodeIfPresent([VPEntry].self, forKey: .vpLog) ?? []
        usedThisBattle = try c.decodeIfPresent(Set<String>.self, forKey: .usedThisBattle) ?? []
        usedThisTurn = try c.decodeIfPresent(Set<String>.self, forKey: .usedThisTurn) ?? []
        usedThisPhase = try c.decodeIfPresent(Set<String>.self, forKey: .usedThisPhase) ?? []
        desolationPoints = try c.decodeIfPresent(Int.self, forKey: .desolationPoints) ?? 0
        desolatedCount = try c.decodeIfPresent(Int.self, forKey: .desolatedCount) ?? 0
    }
}

/// Stage of the current battle round.
enum RoundStage: String, Codable {
    case startOfRound   // priority, underdog, twist, tactic draw
    case firstTurn
    case secondTurn
}

/// The whole game in one Codable value, so saving/resuming is trivial.
struct BattleState: Codable {
    // Configuration (fixed at setup)
    var seasonID: String
    var realmID: String
    var desolationEnabled: Bool = false
    var attacker: PlayerSide = .one
    var players: [PlayerSide.RawValue: PlayerBattleState] = [:]
    var startedAt: Date = Date()

    // Round/turn progress
    var round: Int = 1
    var stage: RoundStage = .startOfRound
    var phase: GamePhase = .startOfTurn
    var firstPlayerByRound: [Int: PlayerSide] = [:]
    var twistByRound: [Int: String] = [:]
    var underdog: PlayerSide?
    var seizedInitiative: PlayerSide? // player who seized this round, if any

    var isOver: Bool = false

    // MARK: - Accessors

    subscript(side: PlayerSide) -> PlayerBattleState {
        get { players[side.rawValue]! }
        set { players[side.rawValue] = newValue }
    }

    var firstPlayerThisRound: PlayerSide { firstPlayerByRound[round] ?? attacker }

    /// The player whose turn it currently is.
    var activePlayer: PlayerSide {
        switch stage {
        case .startOfRound, .firstTurn: return firstPlayerThisRound
        case .secondTurn: return firstPlayerThisRound.other
        }
    }

    var currentTwistName: String? { twistByRound[round] }

    func vpDifference() -> Int {
        abs(self[.one].totalVP - self[.two].totalVP)
    }

    /// The player with fewer VP, or nil on a tie.
    func trailingPlayer() -> PlayerSide? {
        let a = self[.one].totalVP
        let b = self[.two].totalVP
        if a == b { return nil }
        return a < b ? .one : .two
    }

    func winner() -> PlayerSide? {
        trailingPlayer()?.other
    }
}

/// A finished game, stored in history.
struct GameRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var seasonName: String
    var realmName: String
    var playerOneName: String
    var playerOneArmy: String
    var playerOneVP: Int
    var playerTwoName: String
    var playerTwoArmy: String
    var playerTwoVP: Int

    var resultText: String {
        if playerOneVP == playerTwoVP { return "Draw \(playerOneVP)–\(playerTwoVP)" }
        let w = playerOneVP > playerTwoVP ? playerOneName : playerTwoName
        return "\(w) won \(max(playerOneVP, playerTwoVP))–\(min(playerOneVP, playerTwoVP))"
    }
}
