import Foundation
import Combine

/// Main game state manager - tracks the current battle progress
class GameState: ObservableObject {
    // MARK: - Published Properties

    /// Current active phase in the battle round
    @Published var currentPhase: GamePhase = .hero

    /// Current battle round number (starts at 1)
    @Published var currentRound: Int = 1

    /// Command Points available to the player
    @Published var commandPoints: Int = 0

    /// Victory Points accumulated by the player
    @Published var victoryPoints: Int = 0

    /// Active Twist card (Season-specific)
    @Published var activeTwist: String?

    /// Whether the game is currently in progress
    @Published var isGameActive: Bool = false

    // MARK: - Lifecycle

    init() {
        // Start with Hero phase, Round 1
    }

    // MARK: - Phase Management

    /// Advance to the next phase in the battle round
    func advancePhase() {
        let nextPhase = currentPhase.next()

        // If we're wrapping back to Hero, increment round
        if nextPhase == .hero && currentPhase == .battleshock {
            currentRound += 1
        }

        currentPhase = nextPhase
    }

    /// Jump directly to a specific phase
    func setPhase(_ phase: GamePhase) {
        currentPhase = phase
    }

    // MARK: - Resource Management

    /// Add command points (e.g., from abilities or tactics)
    func addCommandPoints(_ amount: Int) {
        commandPoints += amount
    }

    /// Spend command points (returns false if insufficient)
    @discardableResult
    func spendCommandPoints(_ amount: Int) -> Bool {
        guard commandPoints >= amount else { return false }
        commandPoints -= amount
        return true
    }

    /// Add victory points
    func addVictoryPoints(_ amount: Int) {
        victoryPoints += amount
    }

    // MARK: - Game Lifecycle

    /// Start a new game
    func startGame() {
        currentPhase = .hero
        currentRound = 1
        commandPoints = 0
        victoryPoints = 0
        activeTwist = nil
        isGameActive = true
    }

    /// End the current game
    func endGame() {
        isGameActive = false
    }

    /// Reset to initial state
    func reset() {
        currentPhase = .hero
        currentRound = 1
        commandPoints = 0
        victoryPoints = 0
        activeTwist = nil
        isGameActive = false
    }
}
