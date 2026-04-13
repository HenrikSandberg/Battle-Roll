import Foundation
import SwiftUI

/// Represents the six phases of a Warhammer Age of Sigmar battle round
enum GamePhase: String, CaseIterable, Codable {
    case hero = "Hero"
    case movement = "Movement"
    case shooting = "Shooting"
    case charge = "Charge"
    case combat = "Combat"
    case battleshock = "Battleshock"

    /// Icon name for each phase (using SF Symbols)
    var iconName: String {
        switch self {
        case .hero:
            return "star.fill"
        case .movement:
            return "arrow.right.circle.fill"
        case .shooting:
            return "scope"
        case .charge:
            return "bolt.fill"
        case .combat:
            return "dice.fill"
        case .battleshock:
            return "exclamationmark.triangle.fill"
        }
    }

    /// Color associated with each phase for UI display
    var displayColor: Color {
        switch self {
        case .hero:
            return .purple
        case .movement:
            return .blue
        case .shooting:
            return .orange
        case .charge:
            return .red
        case .combat:
            return .pink
        case .battleshock:
            return .gray
        }
    }

    /// Returns the next phase in the battle round sequence
    func next() -> GamePhase {
        let allPhases = GamePhase.allCases
        guard let currentIndex = allPhases.firstIndex(of: self) else {
            return .hero
        }
        let nextIndex = (currentIndex + 1) % allPhases.count
        return allPhases[nextIndex]
    }
}
