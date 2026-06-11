import Foundation

/// The seven steps of a Spearhead turn, in order.
enum GamePhase: String, Codable, CaseIterable, Identifiable {
    case startOfTurn
    case hero
    case movement
    case shooting
    case charge
    case combat
    case endOfTurn

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .startOfTurn: return "Start of Turn"
        case .hero: return "Hero"
        case .movement: return "Movement"
        case .shooting: return "Shooting"
        case .charge: return "Charge"
        case .combat: return "Combat"
        case .endOfTurn: return "End of Turn"
        }
    }

    var shortName: String {
        switch self {
        case .startOfTurn: return "Start"
        case .hero: return "Hero"
        case .movement: return "Move"
        case .shooting: return "Shoot"
        case .charge: return "Charge"
        case .combat: return "Combat"
        case .endOfTurn: return "End"
        }
    }

    var symbolName: String {
        switch self {
        case .startOfTurn: return "sunrise"
        case .hero: return "person.fill"
        case .movement: return "arrow.up.right"
        case .shooting: return "scope"
        case .charge: return "bolt.fill"
        case .combat: return "shield.lefthalf.filled"
        case .endOfTurn: return "flag.checkered"
        }
    }

    var next: GamePhase? {
        let all = Self.allCases
        guard let i = all.firstIndex(of: self), i + 1 < all.count else { return nil }
        return all[i + 1]
    }

    var previous: GamePhase? {
        let all = Self.allCases
        guard let i = all.firstIndex(of: self), i > 0 else { return nil }
        return all[i - 1]
    }
}

/// Phase tag used by ability data. Includes values that are not turn steps.
enum AbilityPhase: String, Codable {
    case startOfRound
    case startOfTurn
    case hero
    case movement
    case shooting
    case charge
    case combat
    case endOfTurn
    case deployment
    case any

    /// The turn step in which this ability should surface, if any.
    func matches(_ phase: GamePhase) -> Bool {
        switch self {
        case .startOfTurn: return phase == .startOfTurn
        case .hero: return phase == .hero
        case .movement: return phase == .movement
        case .shooting: return phase == .shooting
        case .charge: return phase == .charge
        case .combat: return phase == .combat
        case .endOfTurn: return phase == .endOfTurn
        case .startOfRound: return phase == .startOfTurn
        case .deployment: return false
        case .any: return true
        }
    }
}

/// Whose turn an ability can be used in.
enum AbilityTurn: String, Codable {
    case yours
    case enemy
    case any
}

/// When within the phase the ability is used.
enum AbilityWindow: String, Codable {
    case start
    case during
    case end
    case reaction
}

/// How often an ability can be used.
enum AbilityFrequency: String, Codable {
    case passive
    case unlimited
    case oncePerPhase
    case oncePerTurn
    case oncePerTurnArmy
    case oncePerBattle

    var badgeText: String? {
        switch self {
        case .passive: return "Passive"
        case .unlimited: return nil
        case .oncePerPhase: return "1/Phase"
        case .oncePerTurn: return "1/Turn"
        case .oncePerTurnArmy: return "1/Turn (Army)"
        case .oncePerBattle: return "1/Battle"
        }
    }
}
