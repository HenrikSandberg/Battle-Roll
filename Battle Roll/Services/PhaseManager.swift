import Foundation
import CoreData
import Combine

/// Manages phase-based filtering and ability availability
class PhaseManager: ObservableObject {
    // MARK: - Published Properties

    /// Abilities available in the current phase from alive units
    @Published var availableAbilities: [Ability] = []

    /// Abilities requiring immediate attention (start/end of phase)
    @Published var reminderAbilities: [Ability] = []

    // MARK: - Dependencies

    private let gameState: GameState
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(gameState: GameState) {
        self.gameState = gameState

        // React to phase changes
        gameState.$currentPhase
            .sink { [weak self] _ in
                self?.updateAvailableAbilities()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Fetch all abilities available in the current phase from alive units
    /// - Parameter context: Core Data context to fetch from
    func updateAvailableAbilities(from context: NSManagedObjectContext) {
        let currentPhase = gameState.currentPhase

        // Fetch all alive warscrolls
        let fetchRequest: NSFetchRequest<Warscroll> = Warscroll.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isDestroyed == NO")

        do {
            let warscrolls = try context.fetch(fetchRequest)

            // Collect all abilities for the current phase
            var allAbilities: [Ability] = []
            var reminders: [Ability] = []

            for warscroll in warscrolls {
                let phaseAbilities = warscroll.abilities(for: currentPhase)
                    .filter { warscroll.canUseAbility($0) }

                allAbilities.append(contentsOf: phaseAbilities)

                // Check for abilities requiring reminders
                let reminderAbilities = warscroll.abilitiesRequiringReminder(for: currentPhase)
                    .filter { warscroll.canUseAbility($0) }
                reminders.append(contentsOf: reminderAbilities)
            }

            // Sort by warscroll name, then by sort order
            availableAbilities = allAbilities.sorted { ability1, ability2 in
                let warscroll1Name = ability1.warscroll?.name ?? ""
                let warscroll2Name = ability2.warscroll?.name ?? ""

                if warscroll1Name != warscroll2Name {
                    return warscroll1Name < warscroll2Name
                }
                return ability1.sortOrder < ability2.sortOrder
            }

            reminderAbilities = reminders

        } catch {
            print("Error fetching warscrolls: \(error)")
            availableAbilities = []
            reminderAbilities = []
        }
    }

    /// Mark an ability as used and update the available list
    /// - Parameters:
    ///   - ability: The ability that was used
    ///   - context: Core Data context
    func markAbilityAsUsed(_ ability: Ability, in context: NSManagedObjectContext) {
        guard let warscroll = ability.warscroll else { return }

        warscroll.markAbilityAsUsed(ability)

        // Save context
        do {
            try context.save()
            // Refresh available abilities
            updateAvailableAbilities(from: context)
        } catch {
            print("Error saving ability usage: \(error)")
        }
    }

    /// Reset all "once per turn" abilities at the start of a new turn
    /// - Parameter context: Core Data context
    func resetTurnAbilities(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Warscroll> = Warscroll.fetchRequest()

        do {
            let warscrolls = try context.fetch(fetchRequest)
            warscrolls.forEach { $0.resetTurnUsage() }

            try context.save()
            updateAvailableAbilities(from: context)
        } catch {
            print("Error resetting turn abilities: \(error)")
        }
    }

    /// Get abilities grouped by warscroll for the current phase
    /// - Parameter context: Core Data context
    /// - Returns: Dictionary mapping warscroll names to their abilities
    func abilitiesByWarscroll(from context: NSManagedObjectContext) -> [String: [Ability]] {
        var grouped: [String: [Ability]] = [:]

        for ability in availableAbilities {
            guard let warscrollName = ability.warscroll?.name else { continue }

            if grouped[warscrollName] == nil {
                grouped[warscrollName] = []
            }
            grouped[warscrollName]?.append(ability)
        }

        return grouped
    }

    // MARK: - Private Methods

    private func updateAvailableAbilities() {
        // This is a placeholder - actual implementation requires context
        // The UI layer will call updateAvailableAbilities(from:) with proper context
    }
}
