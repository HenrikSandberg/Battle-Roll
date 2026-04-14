import Foundation

/// Represents which player side (me or opponent)
enum PlayerSide: String, Codable {
    case me = "Me"
    case opponent = "Opponent"
}

/// Represents a Twist card from a Season Pack
struct Twist: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let effect: String
    let seasonPack: String // "Fire and Jade", "Sand and Bone", etc.

    init(id: UUID = UUID(), name: String, description: String, effect: String, seasonPack: String) {
        self.id = id
        self.name = name
        self.description = description
        self.effect = effect
        self.seasonPack = seasonPack
    }
}

/// Represents a Battle Tactic card
struct BattleTactic: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let victoryPoints: Int
    let seasonPack: String?  // nil for universal tactics

    init(id: UUID = UUID(), name: String, description: String, victoryPoints: Int = 1, seasonPack: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.victoryPoints = victoryPoints
        self.seasonPack = seasonPack
    }
}

/// Scoring options for objectives at End of Turn
struct ObjectiveScoring {
    var controlsOneOrMoreObjectives: Bool = false
    var controlsTwoOrMoreObjectives: Bool = false
    var controlsMoreThanOpponent: Bool = false

    /// Calculate total VP from objective control
    var totalVP: Int {
        var vp = 0
        if controlsOneOrMoreObjectives { vp += 1 }
        if controlsTwoOrMoreObjectives { vp += 1 }
        if controlsMoreThanOpponent { vp += 1 }
        return vp
    }
}

/// Priority roll result for rounds 2-4
struct PriorityRoll {
    let myRoll: Int
    let opponentRoll: Int

    var winner: PlayerSide? {
        if myRoll > opponentRoll {
            return .me
        } else if opponentRoll > myRoll {
            return .opponent
        }
        return nil // Tie - previous first player chooses
    }

    var isTie: Bool {
        myRoll == opponentRoll
    }
}
