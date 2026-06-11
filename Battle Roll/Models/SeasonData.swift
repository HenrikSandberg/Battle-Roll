import Foundation

/// A twist card: one is drawn at the start of each battle round.
struct TwistCard: Codable, Identifiable, Hashable {
    var name: String
    var effect: String

    var id: String { name }
}

/// One side of a realm battlefield, with its own twist deck.
struct RealmBattlefield: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var subtitle: String
    var twists: [TwistCard]
}

/// The command half of a battle tactic card.
struct CommandData: Codable, Hashable {
    var name: String
    var timingText: String
    var phase: AbilityPhase
    var turn: AbilityTurn
    var window: AbilityWindow
    var effect: String
}

/// A dual-use battle tactic card: score it at end of turn, or spend it as a command.
struct BattleTacticCard: Codable, Identifiable, Hashable {
    var name: String
    var tactic: String
    var command: CommandData

    var id: String { name }
}

/// An optional rules module that can be layered on a season (e.g. Desolation).
struct RulesModule: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var summary: String
    var abilities: [AbilityData]
}

/// A season pack: realm battlefields with twist decks, plus a battle tactic deck.
struct SeasonPack: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var battlefieldSize: String
    var realms: [RealmBattlefield]
    var battleTactics: [BattleTacticCard]
    var modules: [RulesModule]

    enum CodingKeys: String, CodingKey {
        case id, name, battlefieldSize, realms, battleTactics, modules
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        battlefieldSize = try c.decodeIfPresent(String.self, forKey: .battlefieldSize) ?? ""
        realms = try c.decode([RealmBattlefield].self, forKey: .realms)
        battleTactics = try c.decode([BattleTacticCard].self, forKey: .battleTactics)
        modules = try c.decodeIfPresent([RulesModule].self, forKey: .modules) ?? []
    }
}
