import Foundation

/// A Spearhead ability as loaded from the bundled army/season JSON.
struct AbilityData: Codable, Identifiable, Hashable {
    var name: String
    var declare: String?
    var effect: String
    var timingText: String
    var phase: AbilityPhase
    var turn: AbilityTurn
    var window: AbilityWindow
    var frequency: AbilityFrequency

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, declare, effect, timingText, phase, turn, window, frequency
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        declare = try c.decodeIfPresent(String.self, forKey: .declare)
        effect = try c.decode(String.self, forKey: .effect)
        timingText = try c.decodeIfPresent(String.self, forKey: .timingText) ?? "Passive"
        phase = try c.decodeIfPresent(AbilityPhase.self, forKey: .phase) ?? .any
        turn = try c.decodeIfPresent(AbilityTurn.self, forKey: .turn) ?? .any
        window = try c.decodeIfPresent(AbilityWindow.self, forKey: .window) ?? .during
        frequency = try c.decodeIfPresent(AbilityFrequency.self, forKey: .frequency) ?? .unlimited
    }

    init(name: String, declare: String? = nil, effect: String, timingText: String,
         phase: AbilityPhase, turn: AbilityTurn, window: AbilityWindow, frequency: AbilityFrequency) {
        self.name = name
        self.declare = declare
        self.effect = effect
        self.timingText = timingText
        self.phase = phase
        self.turn = turn
        self.window = window
        self.frequency = frequency
    }
}

/// A weapon row on a warscroll. Values are kept as strings ("D6", "3+", "-").
struct WeaponProfile: Codable, Identifiable, Hashable {
    var name: String
    var range: String?
    var attacks: String
    var hit: String
    var wound: String
    var rend: String
    var damage: String
    var abilities: [String]

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, range, attacks, hit, wound, rend, damage, abilities
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        range = try c.decodeIfPresent(String.self, forKey: .range)
        attacks = try c.decode(String.self, forKey: .attacks)
        hit = try c.decode(String.self, forKey: .hit)
        wound = try c.decode(String.self, forKey: .wound)
        rend = try c.decode(String.self, forKey: .rend)
        damage = try c.decode(String.self, forKey: .damage)
        abilities = try c.decodeIfPresent([String].self, forKey: .abilities) ?? []
    }
}

/// A unit's warscroll as loaded from JSON.
struct WarscrollData: Codable, Identifiable, Hashable {
    var name: String
    var isGeneral: Bool
    var instances: Int
    var modelsPerUnit: Int
    var move: String
    var health: Int
    var save: String
    var control: Int
    var keywords: [String]
    var reinforcements: Bool
    var rangedWeapons: [WeaponProfile]
    var meleeWeapons: [WeaponProfile]
    var abilities: [AbilityData]

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, isGeneral, instances, modelsPerUnit, move, health, save, control
        case keywords, reinforcements, rangedWeapons, meleeWeapons, abilities
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        isGeneral = try c.decodeIfPresent(Bool.self, forKey: .isGeneral) ?? false
        instances = try c.decodeIfPresent(Int.self, forKey: .instances) ?? 1
        modelsPerUnit = try c.decodeIfPresent(Int.self, forKey: .modelsPerUnit) ?? 1
        move = try c.decode(String.self, forKey: .move)
        health = try c.decode(Int.self, forKey: .health)
        save = try c.decode(String.self, forKey: .save)
        control = try c.decode(Int.self, forKey: .control)
        keywords = try c.decodeIfPresent([String].self, forKey: .keywords) ?? []
        reinforcements = try c.decodeIfPresent(Bool.self, forKey: .reinforcements) ?? false
        rangedWeapons = try c.decodeIfPresent([WeaponProfile].self, forKey: .rangedWeapons) ?? []
        meleeWeapons = try c.decodeIfPresent([WeaponProfile].self, forKey: .meleeWeapons) ?? []
        abilities = try c.decodeIfPresent([AbilityData].self, forKey: .abilities) ?? []
    }

    /// Total health of the whole unit (models x health per model).
    var totalHealth: Int { health * modelsPerUnit }

    var wardKeyword: String? { keywords.first { $0.hasPrefix("Ward") } }
    var isHero: Bool { keywords.contains("Hero") }
}

/// A complete Spearhead army definition.
struct SpearheadArmy: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var faction: String
    var grandAlliance: String
    var battleTraits: [AbilityData]
    var regimentAbilities: [AbilityData]
    var enhancements: [AbilityData]
    var units: [WarscrollData]
}
