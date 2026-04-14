import Foundation
import SwiftUI

/// Represents the seven phases of a Warhammer Age of Sigmar: Spearhead battle round
enum GamePhase: String, CaseIterable, Codable {
    case startOfTurn = "Start of Turn"
    case hero = "Hero"
    case movement = "Movement"
    case shooting = "Shooting"
    case charge = "Charge"
    case combat = "Combat"
    case endOfTurn = "End of Turn"

    /// Icon name for each phase (using SF Symbols)
    var iconName: String {
        switch self {
        case .startOfTurn:
            return "sunrise.fill"
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
        case .endOfTurn:
            return "moon.fill"
        }
    }

    /// Color associated with each phase for UI display
    var displayColor: Color {
        switch self {
        case .startOfTurn:
            return .cyan
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
        case .endOfTurn:
            return .indigo
        }
    }

    /// Returns the next phase in the battle round sequence
    func next() -> GamePhase {
        let allPhases = GamePhase.allCases
        guard let currentIndex = allPhases.firstIndex(of: self) else {
            return .startOfTurn
        }
        let nextIndex = (currentIndex + 1) % allPhases.count
        return allPhases[nextIndex]
    }
}
