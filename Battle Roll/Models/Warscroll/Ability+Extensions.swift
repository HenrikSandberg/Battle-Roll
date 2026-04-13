import Foundation
import CoreData

extension Ability {
    /// Parsed game phase for this ability
    var gamePhase: GamePhase? {
        guard let phaseString = phase else { return nil }
        return GamePhase(rawValue: phaseString)
    }

    /// Parsed timing for this ability
    var abilityTiming: AbilityTiming? {
        guard let timingString = timing else { return nil }
        return AbilityTiming(rawValue: timingString)
    }

    /// Parsed usage limit for this ability
    var abilityUsageLimit: AbilityUsageLimit? {
        guard let limitString = usageLimit else { return nil }
        return AbilityUsageLimit(rawValue: limitString)
    }

    /// Whether this ability requires a visual reminder
    var requiresReminder: Bool {
        abilityTiming?.requiresReminder ?? false
    }

    /// Whether this ability can currently be used
    var isAvailable: Bool {
        guard let limit = abilityUsageLimit else { return true }

        switch limit {
        case .unlimited:
            return true
        case .oncePerTurn:
            return !hasBeenUsedThisTurn
        case .oncePerGame:
            return !hasBeenUsedThisGame
        }
    }

    /// Display text for the usage limit
    var usageLimitDisplay: String {
        abilityUsageLimit?.displayText ?? ""
    }

    /// Full display text including timing
    var timingDisplay: String {
        guard let timing = abilityTiming else { return "" }
        return timing.rawValue
    }

    /// Badge text for UI display (shows usage status)
    var badgeText: String? {
        guard let limit = abilityUsageLimit else { return nil }

        switch limit {
        case .unlimited:
            return nil
        case .oncePerTurn:
            return hasBeenUsedThisTurn ? "USED" : "1/TURN"
        case .oncePerGame:
            return hasBeenUsedThisGame ? "USED" : "1/GAME"
        }
    }
}

// MARK: - Convenience Initializers

extension Ability {
    /// Create a new Ability in the given context
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        description: String,
        phase: GamePhase,
        timing: AbilityTiming = .duringPhase,
        usageLimit: AbilityUsageLimit = .unlimited,
        isPassive: Bool = false,
        sortOrder: Int16 = 0
    ) -> Ability {
        let ability = Ability(context: context)
        ability.id = UUID()
        ability.name = name
        ability.abilityDescription = description
        ability.phase = phase.rawValue
        ability.timing = timing.rawValue
        ability.usageLimit = usageLimit.rawValue
        ability.isPassive = isPassive
        ability.sortOrder = sortOrder
        ability.hasBeenUsedThisTurn = false
        ability.hasBeenUsedThisGame = false
        return ability
    }
}
