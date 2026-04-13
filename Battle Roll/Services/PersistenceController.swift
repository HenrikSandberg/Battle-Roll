import Foundation
import CoreData

/// Manages Core Data persistence with preview support
struct PersistenceController {
    /// Shared instance for production use
    static let shared = PersistenceController()

    /// Preview instance with in-memory store for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for previews
        let sampleWarscroll = Warscroll.create(
            in: viewContext,
            name: "Stormstrike Chariot",
            move: 10,
            health: 12,
            control: 2,
            save: 3,
            unitType: "Cavalry",
            iconName: "bolt.fill"
        )

        let heroAbility = Ability.create(
            in: viewContext,
            name: "Rapid Redeployment",
            description: "Remove this unit and set it up again more than 9\" from enemies.",
            phase: .hero,
            timing: .startOfPhase,
            usageLimit: .oncePerGame,
            sortOrder: 1
        )
        heroAbility.warscroll = sampleWarscroll

        let chargeAbility = Ability.create(
            in: viewContext,
            name: "Thunderous Impact",
            description: "Add 1 to Attacks if this unit charged this turn.",
            phase: .combat,
            timing: .duringPhase,
            usageLimit: .unlimited,
            isPassive: true,
            sortOrder: 2
        )
        chargeAbility.warscroll = sampleWarscroll

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    /// Initialize with optional in-memory store
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Battle_Roll")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // Enable automatic merging of changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Save the view context if there are changes
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    /// Create a background context for batch operations
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
}
