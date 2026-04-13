import Foundation
import CoreData

extension Warscroll {
    /// Returns all abilities for this warscroll, sorted by order
    var sortedAbilities: [Ability] {
        let abilitySet = abilities as? Set<Ability> ?? []
        return abilitySet.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Returns all weapons for this warscroll
    var weaponsList: [Weapon] {
        let weaponSet = weapons as? Set<Weapon> ?? []
        return weaponSet.sorted { $0.name ?? "" < $1.name ?? "" }
    }

    /// Returns abilities available in a specific phase
    /// - Parameter phase: The game phase to filter by
    /// - Returns: Array of abilities that can be used in the specified phase
    func abilities(for phase: GamePhase) -> [Ability] {
        sortedAbilities.filter { ability in
            guard let phaseString = ability.phase else { return false }
            return phaseString == phase.rawValue
        }
    }

    /// Returns abilities that should show a reminder (start/end of phase)
    func abilitiesRequiringReminder(for phase: GamePhase) -> [Ability] {
        abilities(for: phase).filter { ability in
            guard let timingString = ability.timing,
                  let timing = AbilityTiming(rawValue: timingString) else {
                return false
            }
            return timing.requiresReminder
        }
    }

    /// Whether this unit is still active in the battle
    var isAlive: Bool {
        !isDestroyed
    }

    /// Remaining health of the unit
    var remainingHealth: Int16 {
        max(0, health - damageAllocated)
    }

    /// Deal damage to this unit
    /// - Parameter amount: Amount of damage to allocate
    /// - Returns: True if the unit is destroyed
    @discardableResult
    func dealDamage(_ amount: Int16) -> Bool {
        damageAllocated += amount
        if damageAllocated >= health {
            isDestroyed = true
            return true
        }
        return false
    }

    /// Reset all per-turn ability usage for this warscroll
    func resetTurnUsage() {
        sortedAbilities.forEach { ability in
            ability.hasBeenUsedThisTurn = false
        }
    }

    /// Check if an ability can be used based on its usage limits
    /// - Parameter ability: The ability to check
    /// - Returns: True if the ability is available to use
    func canUseAbility(_ ability: Ability) -> Bool {
        guard let limitString = ability.usageLimit,
              let limit = AbilityUsageLimit(rawValue: limitString) else {
            return true
        }

        switch limit {
        case .unlimited:
            return true
        case .oncePerTurn:
            return !ability.hasBeenUsedThisTurn
        case .oncePerGame:
            return !ability.hasBeenUsedThisGame
        }
    }

    /// Mark an ability as used
    /// - Parameter ability: The ability that was used
    func markAbilityAsUsed(_ ability: Ability) {
        guard let limitString = ability.usageLimit,
              let limit = AbilityUsageLimit(rawValue: limitString) else {
            return
        }

        switch limit {
        case .unlimited:
            break
        case .oncePerTurn:
            ability.hasBeenUsedThisTurn = true
        case .oncePerGame:
            ability.hasBeenUsedThisGame = true
            ability.hasBeenUsedThisTurn = true
        }
    }

    /// Display name with status indicator
    var displayName: String {
        if isDestroyed {
            return "\(name ?? "Unknown") ☠️"
        } else if damageAllocated > 0 {
            return "\(name ?? "Unknown") (\(remainingHealth)/\(health))"
        }
        return name ?? "Unknown"
    }
}

// MARK: - Convenience Initializers

extension Warscroll {
    /// Create a new Warscroll in the given context
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        move: Int16,
        health: Int16,
        control: Int16,
        save: Int16,
        unitType: String? = nil,
        iconName: String? = nil
    ) -> Warscroll {
        let warscroll = Warscroll(context: context)
        warscroll.id = UUID()
        warscroll.name = name
        warscroll.move = move
        warscroll.health = health
        warscroll.control = control
        warscroll.save = save
        warscroll.unitType = unitType
        warscroll.iconName = iconName
        warscroll.isDestroyed = false
        warscroll.damageAllocated = 0
        return warscroll
    }
}
