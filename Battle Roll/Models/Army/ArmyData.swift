import Foundation

/// Represents a complete Spearhead army with all units and rules
struct SpearheadArmyData: Codable, Identifiable {
    let id: UUID
    let name: String
    let faction: String
    let armyTrait: ArmyTrait?
    let units: [UnitData]

    init(id: UUID = UUID(), name: String, faction: String, armyTrait: ArmyTrait? = nil, units: [UnitData]) {
        self.id = id
        self.name = name
        self.faction = faction
        self.armyTrait = armyTrait
        self.units = units
    }
}

/// Army-wide trait/rule
struct ArmyTrait: Codable {
    let name: String
    let description: String
    let phase: String?  // Optional: some traits are always active
}

/// Unit warscroll data
struct UnitData: Codable, Identifiable {
    let id: UUID
    let name: String
    let move: Int
    let health: Int
    let control: Int
    let save: Int
    let unitType: String  // "Infantry", "Cavalry", "Monster", etc.
    let weapons: [WeaponData]
    let abilities: [AbilityData]

    init(id: UUID = UUID(), name: String, move: Int, health: Int, control: Int, save: Int, unitType: String, weapons: [WeaponData] = [], abilities: [AbilityData] = []) {
        self.id = id
        self.name = name
        self.move = move
        self.health = health
        self.control = control
        self.save = save
        self.unitType = unitType
        self.weapons = weapons
        self.abilities = abilities
    }
}

/// Weapon profile
struct WeaponData: Codable, Identifiable {
    let id: UUID
    let name: String
    let attacks: String  // Can be "3", "D6", "2D3", etc.
    let hit: Int  // Hit roll (e.g., 3+ = 3)
    let wound: Int  // Wound roll
    let rend: Int  // Rend value
    let damage: String  // Can be "1", "D3", "2", etc.
    let range: Int?  // nil for melee, value for ranged
    let abilities: String?  // Weapon abilities (e.g., "Crit (2 Hits)")

    var isMelee: Bool {
        range == nil || range == 0
    }

    init(id: UUID = UUID(), name: String, attacks: String, hit: Int, wound: Int, rend: Int, damage: String, range: Int? = nil, abilities: String? = nil) {
        self.id = id
        self.name = name
        self.attacks = attacks
        self.hit = hit
        self.wound = wound
        self.rend = rend
        self.damage = damage
        self.range = range
        self.abilities = abilities
    }
}

/// Unit ability
struct AbilityData: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let phase: String  // "Hero", "Movement", "Shooting", "Charge", "Combat", "Battleshock"
    let timing: String  // "Start of Phase", "During Phase", "End of Phase", "Passive"
    let usageLimit: String  // "Unlimited", "Once Per Turn", "Once Per Game"
    let isPassive: Bool

    init(id: UUID = UUID(), name: String, description: String, phase: String, timing: String = "During Phase", usageLimit: String = "Unlimited", isPassive: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.phase = phase
        self.timing = timing
        self.usageLimit = usageLimit
        self.isPassive = isPassive
    }
}

// MARK: - Sample Data for Testing

extension SpearheadArmyData {
    static let stormcastEternals = SpearheadArmyData(
        name: "Stormcast Eternals - Hallowed Knights",
        faction: "Stormcast Eternals",
        armyTrait: ArmyTrait(
            name: "Only the Faithful",
            description: "Once per turn, you can return 1 slain model to a friendly Hallowed Knights unit.",
            phase: "Hero"
        ),
        units: [
            UnitData(
                name: "Lord-Vigilant on Gryph-stalker",
                move: 9,
                health: 12,
                control: 2,
                save: 3,
                unitType: "Cavalry Hero",
                weapons: [
                    WeaponData(name: "Gryph-stalker's Razor Beak", attacks: "3", hit: 3, wound: 3, rend: 2, damage: "2"),
                    WeaponData(name: "Warden's Halberd", attacks: "4", hit: 3, wound: 3, rend: 1, damage: "2")
                ],
                abilities: [
                    AbilityData(
                        name: "Lord of the Host",
                        description: "Add 1 to run rolls and charge rolls for friendly Hallowed Knights units wholly within 12\" of this unit.",
                        phase: "Movement",
                        isPassive: true
                    ),
                    AbilityData(
                        name: "Gryph-stalker's Swiftness",
                        description: "This unit can run and still charge in the same turn.",
                        phase: "Movement",
                        isPassive: true
                    )
                ]
            ),
            UnitData(
                name: "Liberators",
                move: 5,
                health: 10,
                control: 1,
                save: 3,
                unitType: "Infantry",
                weapons: [
                    WeaponData(name: "Warhammer", attacks: "2", hit: 3, wound: 3, rend: 1, damage: "1"),
                    WeaponData(name: "Warblades", attacks: "3", hit: 3, wound: 4, rend: 0, damage: "1")
                ],
                abilities: [
                    AbilityData(
                        name: "Lay Low the Tyrant",
                        description: "Add 1 to wound rolls for attacks made by this unit that target enemy Heroes.",
                        phase: "Combat",
                        timing: "During Phase",
                        isPassive: true
                    )
                ]
            )
        ]
    )

    static let allSampleArmies: [SpearheadArmyData] = [
        stormcastEternals
    ]
}
