import SwiftUI

/// Spearhead "Fire and Jade" palette: sigmarite gold, Aqshy embers, Ghyran jade.
/// Also covers "Sand and Bone" Shyish palette: grave-purple, bone, ash.
/// Used as accents on top of the standard system look — lists, forms and
/// materials stay native so the app keeps the system glass feel.
enum SpearheadTheme {
    // Fire and Jade
    static let gold   = Color(red: 0.83, green: 0.62, blue: 0.18)
    static let ember  = Color(red: 0.80, green: 0.25, blue: 0.13)
    static let flame  = Color(red: 0.95, green: 0.50, blue: 0.12)
    static let jade   = Color(red: 0.10, green: 0.55, blue: 0.42)
    static let leaf   = Color(red: 0.35, green: 0.70, blue: 0.40)
    static let arcane = Color(red: 0.48, green: 0.32, blue: 0.78)
    static let steel  = Color(red: 0.35, green: 0.45, blue: 0.60)
    static let blood  = Color(red: 0.65, green: 0.12, blue: 0.15)

    // Sand and Bone (Shyish)
    static let bone   = Color(red: 0.85, green: 0.80, blue: 0.70)
    static let grave  = Color(red: 0.22, green: 0.17, blue: 0.32)
    static let deathPurple = Color(red: 0.40, green: 0.28, blue: 0.58)
    static let sand   = Color(red: 0.62, green: 0.52, blue: 0.36)
    static let ash    = Color(red: 0.48, green: 0.44, blue: 0.40)

    /// Player identity colors: player one fights under fire, player two under jade.
    static func color(for side: PlayerSide) -> Color {
        side == .one ? ember : jade
    }

    static let fireGradient = LinearGradient(
        colors: [ember, flame],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let jadeGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.40, blue: 0.32), leaf],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let goldGradient = LinearGradient(
        colors: [gold, Color(red: 0.95, green: 0.78, blue: 0.35)],
        startPoint: .top, endPoint: .bottom)

    static let dolurumGradient = LinearGradient(
        colors: [grave, deathPurple],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let ossiaGradient = LinearGradient(
        colors: [sand, bone],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// Gradient matching the realm side being fought over.
    static func realmGradient(_ realmID: String) -> LinearGradient {
        let id = realmID.lowercased()
        if id.contains("ghyran") { return jadeGradient }
        if id.contains("dolorum") { return dolurumGradient }
        if id.contains("ossia") { return ossiaGradient }
        return fireGradient // default: Aqshy
    }
}

extension PlayerSide {
    var themeColor: Color { SpearheadTheme.color(for: self) }
}

extension GamePhase {
    /// Accent color for the phase bar and phase-specific controls.
    var themeColor: Color {
        switch self {
        case .startOfTurn: return SpearheadTheme.gold
        case .hero: return SpearheadTheme.arcane
        case .movement: return SpearheadTheme.steel
        case .shooting: return SpearheadTheme.flame
        case .charge: return SpearheadTheme.ember
        case .combat: return SpearheadTheme.blood
        case .endOfTurn: return SpearheadTheme.jade
        }
    }
}
