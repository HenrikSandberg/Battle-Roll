import Foundation
import CoreData

struct SpearheadData: Codable {
    let name: String
    let faction: String
    let general: String
    let battleTraits: [AbilityData]
    let regimentAbilities: [AbilityData]
    let enhancements: [AbilityData]
    let warscrolls: [WarscrollData]
}

struct WarscrollData: Codable {
    let name: String
    let move: Int
    let health: Int
    let control: Int
    let save: Int
    let unitType: String
    let isGeneral: Bool?
    let count: Int?
    let weapons: [WeaponData]
    let abilities: [AbilityData]
}

struct WeaponData: Codable {
    let name: String
    let attacks: String
    let hit: Int
    let wound: Int
    let rend: Int
    let damage: String
    let isMelee: Bool
}

struct AbilityData: Codable {
    let name: String
    let description: String
    let phase: String
    let timing: String
    let usageLimit: String
    let isPassive: Bool
    let attachedTo: String?
}

class SpearheadLoader {
    static let shared = SpearheadLoader()
    private let persistenceController = PersistenceController.shared
    private var hasLoaded = false

    private init() {}

    /// Load all spearheads from the Resources/Data/Spearheads directory
    func loadAllSpearheads() {
        // Only load once per app session
        if hasLoaded {
            print("✅ Spearheads already loaded, skipping...")
            return
        }

        print("🔍 SpearheadLoader: Attempting to load spearheads...")

        // Try different bundle paths
        var spearheadFiles: [URL]?

        // Try with subdirectory
        spearheadFiles = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Resources/Data/Spearheads")

        // If not found, try without subdirectory
        if spearheadFiles == nil || spearheadFiles!.isEmpty {
            print("⚠️ No files found in Resources/Data/Spearheads, trying direct path...")
            spearheadFiles = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil)?.filter { $0.lastPathComponent.contains("Gore") || $0.lastPathComponent.contains("Fangs") || $0.lastPathComponent.contains("Castelite") }
        }

        guard let files = spearheadFiles, !files.isEmpty else {
            print("❌ No spearhead JSON files found in bundle")
            print("📦 Bundle path: \(Bundle.main.bundlePath)")
            return
        }

        print("✅ Found \(files.count) spearhead file(s):")
        for file in files {
            print("  - \(file.lastPathComponent)")
        }

        for fileURL in files {
            loadSpearhead(from: fileURL)
        }

        hasLoaded = true
        print("✅ SpearheadLoader: All spearheads loaded, hasLoaded = true")
    }

    /// Load a specific spearhead by name
    func loadSpearhead(named name: String) {
        guard let fileURL = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Resources/Data/Spearheads") else {
            print("Spearhead file not found: \(name)")
            return
        }

        loadSpearhead(from: fileURL)
    }

    /// Load spearhead from a file URL
    private func loadSpearhead(from fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let spearheadData = try decoder.decode(SpearheadData.self, from: data)

            // Check if already loaded
            if isSpearheadAlreadyLoaded(name: spearheadData.name) {
                print("Spearhead already loaded: \(spearheadData.name)")
                return
            }

            // Load into Core Data
            createSpearheadInCoreData(spearheadData)
            print("Successfully loaded spearhead: \(spearheadData.name)")
        } catch {
            print("Error loading spearhead from \(fileURL.lastPathComponent): \(error)")
        }
    }

    /// Check if spearhead already exists in Core Data
    private func isSpearheadAlreadyLoaded(name: String) -> Bool {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<SpearheadArmy> = SpearheadArmy.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)

        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking for existing spearhead: \(error)")
            return false
        }
    }

    /// Create spearhead in Core Data
    private func createSpearheadInCoreData(_ data: SpearheadData) {
        let context = persistenceController.container.viewContext

        context.perform {
            // Create army entity
            let army = SpearheadArmy(context: context)
            army.id = UUID()
            army.name = data.name
            army.faction = data.faction

            // Store battle traits and regiment abilities as trait description (JSON encoded)
            let traitsInfo = [
                "battleTraits": data.battleTraits.map { ["name": $0.name, "description": $0.description] },
                "regimentAbilities": data.regimentAbilities.map { ["name": $0.name, "description": $0.description] },
                "enhancements": data.enhancements.map { ["name": $0.name, "description": $0.description] }
            ]

            if let traitsJSON = try? JSONEncoder().encode(traitsInfo),
               let traitsString = String(data: traitsJSON, encoding: .utf8) {
                army.traitDescription = traitsString
            }

            // Create warscrolls
            for warscrollData in data.warscrolls {
                let warscroll = Warscroll(context: context)
                warscroll.id = UUID()
                warscroll.name = warscrollData.name
                warscroll.move = Int16(warscrollData.move)
                warscroll.health = Int16(warscrollData.health)
                warscroll.control = Int16(warscrollData.control)
                warscroll.save = Int16(warscrollData.save)
                warscroll.unitType = warscrollData.unitType
                warscroll.isDestroyed = false
                warscroll.damageAllocated = 0
                warscroll.army = army

                // Create weapons
                for (index, weaponData) in warscrollData.weapons.enumerated() {
                    let weapon = Weapon(context: context)
                    weapon.id = UUID()
                    weapon.name = weaponData.name
                    weapon.attacks = weaponData.attacks
                    weapon.hit = Int16(weaponData.hit)
                    weapon.wound = Int16(weaponData.wound)
                    weapon.rend = Int16(weaponData.rend)
                    weapon.damage = weaponData.damage
                    weapon.isMelee = weaponData.isMelee
                    weapon.range = weaponData.isMelee ? 0 : 12 // Default range for ranged
                    weapon.warscroll = warscroll
                }

                // Create abilities from warscroll
                for (index, abilityData) in warscrollData.abilities.enumerated() {
                    let ability = Ability(context: context)
                    ability.id = UUID()
                    ability.name = abilityData.name
                    ability.abilityDescription = abilityData.description
                    ability.phase = abilityData.phase
                    ability.timing = abilityData.timing
                    ability.usageLimit = abilityData.usageLimit
                    ability.isPassive = abilityData.isPassive
                    ability.hasBeenUsedThisTurn = false
                    ability.hasBeenUsedThisGame = false
                    ability.sortOrder = Int16(index)
                    ability.warscroll = warscroll
                }

                // Add battle traits to general's warscroll
                if warscrollData.isGeneral == true {
                    var sortOrder = warscrollData.abilities.count

                    // Add battle traits
                    for traitData in data.battleTraits {
                        let ability = Ability(context: context)
                        ability.id = UUID()
                        ability.name = traitData.name
                        ability.abilityDescription = traitData.description
                        ability.phase = traitData.phase
                        ability.timing = traitData.timing
                        ability.usageLimit = traitData.usageLimit
                        ability.isPassive = traitData.isPassive
                        ability.hasBeenUsedThisTurn = false
                        ability.hasBeenUsedThisGame = false
                        ability.sortOrder = Int16(sortOrder)
                        ability.warscroll = warscroll
                        sortOrder += 1
                    }

                    // Add enhancements (player will pick one)
                    for enhancementData in data.enhancements {
                        let ability = Ability(context: context)
                        ability.id = UUID()
                        ability.name = enhancementData.name
                        ability.abilityDescription = enhancementData.description
                        ability.phase = enhancementData.phase
                        ability.timing = enhancementData.timing
                        ability.usageLimit = enhancementData.usageLimit
                        ability.isPassive = enhancementData.isPassive
                        ability.hasBeenUsedThisTurn = false
                        ability.hasBeenUsedThisGame = false
                        ability.sortOrder = Int16(sortOrder)
                        ability.warscroll = warscroll
                        sortOrder += 1
                    }
                }
            }

            // Save context
            do {
                try context.save()
            } catch {
                print("Error saving spearhead to Core Data: \(error)")
            }
        }
    }

    /// Get all loaded spearheads
    func getAllSpearheads() -> [(faction: String, spearhead: String)] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<SpearheadArmy> = SpearheadArmy.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \SpearheadArmy.faction, ascending: true),
            NSSortDescriptor(keyPath: \SpearheadArmy.name, ascending: true)
        ]

        do {
            let armies = try context.fetch(fetchRequest)
            return armies.map { ($0.faction ?? "Unknown", $0.name ?? "Unknown") }
        } catch {
            print("Error fetching spearheads: \(error)")
            return []
        }
    }

    /// Get spearheads for a specific faction
    func getSpearheads(forFaction faction: String) -> [String] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<SpearheadArmy> = SpearheadArmy.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "faction == %@", faction)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SpearheadArmy.name, ascending: true)]

        do {
            let armies = try context.fetch(fetchRequest)
            return armies.compactMap { $0.name }
        } catch {
            print("Error fetching spearheads for faction: \(error)")
            return []
        }
    }

    /// Delete all spearheads (for testing)
    func deleteAllSpearheads() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SpearheadArmy.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
            print("All spearheads deleted")
        } catch {
            print("Error deleting spearheads: \(error)")
        }
    }
}
