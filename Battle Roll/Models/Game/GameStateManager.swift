import Foundation
import SwiftUI
import Combine
import CoreData

struct PlayerSetup: Codable {
    let armyName: String
    let spearheadName: String
    var score: Int = 0
    var usedBattleTactics: [String] = [] // IDs of battle tactics used
    var canPickNewTactic: Bool = true
}

class GameStateManager: ObservableObject {
    // Game Configuration
    @Published var season: String = ""
    @Published var boardLayout: String = ""
    @Published var mySetup: PlayerSetup?
    @Published var opponentSetup: PlayerSetup?

    // Round and Turn State
    @Published var currentRound: Int = 1
    @Published var currentTurn: PlayerSide = .me
    @Published var currentPhase: GamePhase = .startOfTurn
    @Published var underdog: PlayerSide? = nil
    @Published var isAttacker: Bool = true // Round 1: attacker chooses who goes first

    // Battle Tactics and Twists
    @Published var currentTwist: Twist?
    @Published var availableBattleTactics: [BattleTactic] = []

    // Round History
    @Published var roundRecords: [RoundData] = []

    // Game Status
    @Published var isGameActive: Bool = false
    @Published var gameRecordId: UUID?

    struct RoundData: Identifiable {
        let id = UUID()
        let roundNumber: Int
        var whoWonPriority: PlayerSide?
        var whoWentFirst: PlayerSide?
        var underdogAtStart: PlayerSide?
        var myScoreThisRound: Int = 0
        var opponentScoreThisRound: Int = 0
        var myPriorityRoll: Int?
        var opponentPriorityRoll: Int?
    }

    // MARK: - Game Setup

    func startNewGame(
        myArmy: String,
        mySpearhead: String,
        opponentArmy: String,
        opponentSpearhead: String,
        season: String,
        boardLayout: String,
        isAttacker: Bool = true
    ) {
        self.mySetup = PlayerSetup(armyName: myArmy, spearheadName: mySpearhead)
        self.opponentSetup = PlayerSetup(armyName: opponentArmy, spearheadName: opponentSpearhead)
        self.season = season
        self.boardLayout = boardLayout
        self.currentRound = 1
        self.currentTurn = .me
        self.currentPhase = .startOfTurn
        self.underdog = nil
        self.isAttacker = isAttacker
        self.roundRecords = []
        self.isGameActive = true
        self.gameRecordId = UUID()

        // Create initial round record
        let initialRound = RoundData(
            roundNumber: 1,
            underdogAtStart: nil
        )
        roundRecords.append(initialRound)
    }

    // MARK: - Phase Management

    func nextPhase() {
        guard let currentIndex = GamePhase.allCases.firstIndex(of: currentPhase) else { return }

        if currentIndex < GamePhase.allCases.count - 1 {
            currentPhase = GamePhase.allCases[currentIndex + 1]
        } else {
            // End of turn
            endTurn()
        }
    }

    func previousPhase() {
        guard let currentIndex = GamePhase.allCases.firstIndex(of: currentPhase) else { return }

        if currentIndex > 0 {
            currentPhase = GamePhase.allCases[currentIndex - 1]
        }
    }

    // MARK: - Turn Management

    func endTurn() {
        // Reset ability usage for "once per turn" abilities
        resetTurnAbilities()

        // Reset to start of turn phase for next turn
        currentPhase = .startOfTurn

        // Switch player or end round
        if currentTurn == .me {
            currentTurn = .opponent
        } else {
            // Both players have gone, end the round
            endRound()
        }
    }

    private func resetTurnAbilities() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Ability> = Ability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "hasBeenUsedThisTurn == YES")

        do {
            let abilities = try context.fetch(fetchRequest)
            for ability in abilities {
                ability.hasBeenUsedThisTurn = false
            }
            try context.save()
        } catch {
            print("Error resetting turn abilities: \(error)")
        }
    }

    func scoreBattleTactic(for player: PlayerSide, points: Int, tacticId: String, usedAsCommand: Bool = false) {
        if player == .me {
            if !usedAsCommand {
                mySetup?.score += points
                if var current = getCurrentRoundRecord() {
                    current.myScoreThisRound += points
                    updateCurrentRoundRecord(current)
                }
            }
            mySetup?.usedBattleTactics.append(tacticId)

            // Check if player has used 3 tactics (can't pick new ones)
            if let count = mySetup?.usedBattleTactics.count, count >= 3 {
                mySetup?.canPickNewTactic = false
            }
        } else {
            if !usedAsCommand {
                opponentSetup?.score += points
                if var current = getCurrentRoundRecord() {
                    current.opponentScoreThisRound += points
                    updateCurrentRoundRecord(current)
                }
            }
            opponentSetup?.usedBattleTactics.append(tacticId)

            if let count = opponentSetup?.usedBattleTactics.count, count >= 3 {
                opponentSetup?.canPickNewTactic = false
            }
        }
    }

    // MARK: - Round Management

    func endRound() {
        // Game ends after round 4
        if currentRound >= 4 {
            endGame()
            return
        }

        // Determine underdog for next round
        if let myScore = mySetup?.score, let oppScore = opponentSetup?.score {
            if myScore < oppScore {
                underdog = .me
            } else if oppScore < myScore {
                underdog = .opponent
            } else {
                underdog = nil // Tied
            }
        }

        // Move to next round
        currentRound += 1
        currentTurn = .me // Will be determined by priority roll
        currentPhase = .startOfTurn

        // Create new round record
        let newRound = RoundData(
            roundNumber: currentRound,
            underdogAtStart: underdog
        )
        roundRecords.append(newRound)
    }

    func setPriorityWinner(_ winner: PlayerSide) {
        if var current = getCurrentRoundRecord() {
            current.whoWonPriority = winner
            updateCurrentRoundRecord(current)
        }
    }

    func setFirstPlayer(_ player: PlayerSide) {
        currentTurn = player
        if var current = getCurrentRoundRecord() {
            current.whoWentFirst = player
            updateCurrentRoundRecord(current)
        }
    }

    // MARK: - Helper Methods

    private func getCurrentRoundRecord() -> RoundData? {
        return roundRecords.first { $0.roundNumber == currentRound }
    }

    private func updateCurrentRoundRecord(_ updated: RoundData) {
        if let index = roundRecords.firstIndex(where: { $0.roundNumber == currentRound }) {
            roundRecords[index] = updated
        }
    }

    func getMyScore() -> Int {
        return mySetup?.score ?? 0
    }

    func getOpponentScore() -> Int {
        return opponentSetup?.score ?? 0
    }

    func isUnderdog(_ player: PlayerSide) -> Bool {
        return underdog == player
    }

    func canPickBattleTactic(_ player: PlayerSide) -> Bool {
        if player == .me {
            return mySetup?.canPickNewTactic ?? true
        } else {
            return opponentSetup?.canPickNewTactic ?? true
        }
    }

    // MARK: - Priority Roll System

    /// Roll priority for rounds 2-4
    func rollPriority(myRoll: Int, opponentRoll: Int) -> PriorityRoll {
        let roll = PriorityRoll(myRoll: myRoll, opponentRoll: opponentRoll)

        // Update round record
        if var current = getCurrentRoundRecord() {
            current.myPriorityRoll = myRoll
            current.opponentPriorityRoll = opponentRoll
            current.whoWonPriority = roll.winner
            updateCurrentRoundRecord(current)
        }

        return roll
    }

    /// For round 1, attacker chooses who goes first
    func attackerChoosesFirstPlayer(_ player: PlayerSide) {
        setFirstPlayer(player)
    }

    /// For rounds 2-4 tie-breaker: previous first player chooses
    func previousFirstPlayerChooses(_ player: PlayerSide) {
        setFirstPlayer(player)
    }

    // MARK: - End of Turn Scoring

    /// Score objectives at end of turn
    func scoreObjectives(for player: PlayerSide, scoring: ObjectiveScoring) {
        let points = scoring.totalVP

        if player == .me {
            mySetup?.score += points
            if var current = getCurrentRoundRecord() {
                current.myScoreThisRound += points
                updateCurrentRoundRecord(current)
            }
        } else {
            opponentSetup?.score += points
            if var current = getCurrentRoundRecord() {
                current.opponentScoreThisRound += points
                updateCurrentRoundRecord(current)
            }
        }
    }

    // MARK: - Twist Management

    /// Draw a Twist card for the current round
    func drawTwist(_ twist: Twist) {
        currentTwist = twist
    }

    /// Clear the current Twist
    func clearTwist() {
        currentTwist = nil
    }

    // MARK: - Game Completion

    func endGame() -> (didIWin: Bool, myScore: Int, opponentScore: Int) {
        isGameActive = false
        let myScore = getMyScore()
        let opponentScore = getOpponentScore()
        let didIWin = myScore > opponentScore

        return (didIWin, myScore, opponentScore)
    }
}
