import Foundation

/// When an ability can be activated within a phase
enum AbilityTiming: String, CaseIterable, Codable {
    case startOfPhase = "Start of Phase"
    case duringPhase = "During Phase"
    case endOfPhase = "End of Phase"
    case passive = "Passive" // Always active, no timing trigger

    /// Whether this timing requires a visual reminder
    var requiresReminder: Bool {
        switch self {
        case .startOfPhase:
            return true // Critical - easy to miss
        case .endOfPhase:
            return true // Also easy to forget
        case .duringPhase, .passive:
            return false
        }
    }
}

/// How many times an ability can be used
enum AbilityUsageLimit: String, CaseIterable, Codable {
    case unlimited = "Unlimited"
    case oncePerTurn = "Once Per Turn"
    case oncePerGame = "Once Per Game"

    /// Display text for UI
    var displayText: String {
        switch self {
        case .unlimited:
            return "Any Time"
        case .oncePerTurn:
            return "1/Turn"
        case .oncePerGame:
            return "1/Game"
        }
    }
}
