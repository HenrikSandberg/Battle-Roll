import Foundation
import CoreData
import Combine

/// Singleton service for Core Data CRUD operations and Season Pack loading
class DataService: ObservableObject {
    static let shared = DataService()

    // MARK: - Published Properties

    /// All armies in the database
    @Published var armies: [SpearheadArmy] = []

    /// Currently selected army for battle
    @Published var selectedArmy: SpearheadArmy?

    // MARK: - Dependencies

    private let persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    private init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Army Management

    /// Fetch all armies from the database
    func fetchArmies() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<SpearheadArmy> = SpearheadArmy.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SpearheadArmy.name, ascending: true)]

        do {
            armies = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching armies: \(error)")
            armies = []
        }
    }

    /// Create a new army
    @discardableResult
    func createArmy(
        name: String,
        faction: String,
        traitName: String? = nil,
        traitDescription: String? = nil
    ) -> SpearheadArmy {
        let context = persistenceController.container.viewContext
        let army = SpearheadArmy(context: context)
        army.id = UUID()
        army.name = name
        army.faction = faction
        army.traitName = traitName
        army.traitDescription = traitDescription

        persistenceController.save()
        fetchArmies()

        return army
    }

    /// Delete an army
    func deleteArmy(_ army: SpearheadArmy) {
        let context = persistenceController.container.viewContext
        context.delete(army)
        persistenceController.save()
        fetchArmies()
    }

    // MARK: - Warscroll Management

    /// Add a warscroll to an army
    @discardableResult
    func addWarscroll(
        to army: SpearheadArmy,
        name: String,
        move: Int16,
        health: Int16,
        control: Int16,
        save: Int16,
        unitType: String? = nil,
        iconName: String? = nil
    ) -> Warscroll {
        let context = persistenceController.container.viewContext
        let warscroll = Warscroll.create(
            in: context,
            name: name,
            move: move,
            health: health,
            control: control,
            save: save,
            unitType: unitType,
            iconName: iconName
        )
        warscroll.army = army

        persistenceController.save()
        return warscroll
    }

    /// Delete a warscroll
    func deleteWarscroll(_ warscroll: Warscroll) {
        let context = persistenceController.container.viewContext
        context.delete(warscroll)
        persistenceController.save()
    }

    /// Mark a warscroll as destroyed
    func destroyWarscroll(_ warscroll: Warscroll) {
        warscroll.isDestroyed = true
        persistenceController.save()
    }

    /// Restore a destroyed warscroll
    func restoreWarscroll(_ warscroll: Warscroll) {
        warscroll.isDestroyed = false
        warscroll.damageAllocated = 0
        persistenceController.save()
    }

    // MARK: - Ability Management

    /// Add an ability to a warscroll
    @discardableResult
    func addAbility(
        to warscroll: Warscroll,
        name: String,
        description: String,
        phase: GamePhase,
        timing: AbilityTiming = .duringPhase,
        usageLimit: AbilityUsageLimit = .unlimited,
        isPassive: Bool = false,
        sortOrder: Int16 = 0
    ) -> Ability {
        let context = persistenceController.container.viewContext
        let ability = Ability.create(
            in: context,
            name: name,
            description: description,
            phase: phase,
            timing: timing,
            usageLimit: usageLimit,
            isPassive: isPassive,
            sortOrder: sortOrder
        )
        ability.warscroll = warscroll

        persistenceController.save()
        return ability
    }

    /// Delete an ability
    func deleteAbility(_ ability: Ability) {
        let context = persistenceController.container.viewContext
        context.delete(ability)
        persistenceController.save()
    }

    // MARK: - Batch Operations

    /// Load all data (armies, warscrolls, etc.)
    func loadAllData() {
        fetchArmies()
    }

    /// Reset all usage tracking for a new turn
    func resetTurnTracking() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<Ability> = Ability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "hasBeenUsedThisTurn == YES")

        do {
            let abilities = try context.fetch(fetchRequest)
            abilities.forEach { $0.hasBeenUsedThisTurn = false }
            persistenceController.save()
        } catch {
            print("Error resetting turn tracking: \(error)")
        }
    }

    /// Reset all usage tracking for a new game
    func resetGameTracking() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<Ability> = Ability.fetchRequest()

        do {
            let abilities = try context.fetch(fetchRequest)
            abilities.forEach {
                $0.hasBeenUsedThisTurn = false
                $0.hasBeenUsedThisGame = false
            }
            persistenceController.save()
        } catch {
            print("Error resetting game tracking: \(error)")
        }
    }

    /// Clear all data from the database
    func clearAllData() {
        let context = persistenceController.container.viewContext

        // Delete all armies (cascade will handle warscrolls and abilities)
        let armyFetchRequest: NSFetchRequest<NSFetchRequestResult> = SpearheadArmy.fetchRequest()
        let armyDeleteRequest = NSBatchDeleteRequest(fetchRequest: armyFetchRequest)

        do {
            try context.execute(armyDeleteRequest)
            persistenceController.save()
            fetchArmies()
        } catch {
            print("Error clearing data: \(error)")
        }
    }

    // MARK: - Sample Data (for testing)

    /// Create sample data for testing the Phase Engine
    func createSampleData() {
        let context = persistenceController.container.viewContext

        // Create a sample Stormcast Eternals army
        let army = SpearheadArmy(context: context)
        army.id = UUID()
        army.name = "Stormcast Vanguard"
        army.faction = "Stormcast Eternals"
        army.traitName = "Swift Strikers"
        army.traitDescription = "Once per turn, one unit can run and still shoot or charge."

        // Create Stormstrike Chariot
        let chariot = Warscroll.create(
            in: context,
            name: "Stormstrike Chariot",
            move: 10,
            health: 12,
            control: 2,
            save: 3,
            unitType: "Cavalry",
            iconName: "bolt.fill"
        )
        chariot.army = army

        let _ = Ability.create(
            in: context,
            name: "Rapid Redeployment",
            description: "Remove this unit from the battlefield and set it up again anywhere more than 9\" from all enemy units.",
            phase: .hero,
            timing: .startOfPhase,
            usageLimit: .oncePerGame,
            sortOrder: 1
        ).apply { $0.warscroll = chariot }

        let _ = Ability.create(
            in: context,
            name: "Swift Strike",
            description: "This unit can run and still charge in the same turn.",
            phase: .movement,
            timing: .duringPhase,
            usageLimit: .unlimited,
            isPassive: true,
            sortOrder: 1
        ).apply { $0.warscroll = chariot }

        let _ = Ability.create(
            in: context,
            name: "Thunderous Impact",
            description: "Add 1 to the Attacks characteristic of this unit's melee weapons if it charged this turn.",
            phase: .combat,
            timing: .duringPhase,
            usageLimit: .unlimited,
            isPassive: true,
            sortOrder: 1
        ).apply { $0.warscroll = chariot }

        // Create Liberators
        let liberators = Warscroll.create(
            in: context,
            name: "Liberators",
            move: 5,
            health: 10,
            control: 1,
            save: 3,
            unitType: "Infantry",
            iconName: "shield.fill"
        )
        liberators.army = army

        let _ = Ability.create(
            in: context,
            name: "Shield Wall",
            description: "Add 1 to save rolls for attacks that target this unit.",
            phase: .combat,
            timing: .duringPhase,
            usageLimit: .unlimited,
            isPassive: true,
            sortOrder: 1
        ).apply { $0.warscroll = liberators }

        let _ = Ability.create(
            in: context,
            name: "Lay Low the Tyrant",
            description: "Add 1 to wound rolls for attacks made by this unit that target enemy Heroes.",
            phase: .combat,
            timing: .endOfPhase,
            usageLimit: .oncePerTurn,
            sortOrder: 2
        ).apply { $0.warscroll = liberators }

        persistenceController.save()
        fetchArmies()

        print("✅ Sample data created successfully!")
    }
}

// MARK: - Helper Extension

extension NSObject {
    @discardableResult
    func apply(_ closure: (Self) -> Void) -> Self {
        closure(self)
        return self
    }
}
