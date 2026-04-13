// ============================================
// SIMPLIFIED SCORE TRACKER FOR BATTLE ROLL
// ============================================
// Copy this code into your project to replace the complex Phase Engine
// with a simple two-player score tracker

import SwiftUI

// MARK: - Game State Model

class BattleGame: ObservableObject {
    @Published var myScore: Int = 0
    @Published var opponentScore: Int = 0
    @Published var currentRound: Int = 1
    @Published var myName: String = "Me"
    @Published var opponentName: String = "Opponent"

    // Battle Tactics tracking
    @Published var myTacticsScored: [String] = []
    @Published var opponentTacticsScored: [String] = []

    var isUnderdog: Bool {
        myScore < opponentScore
    }

    var scoreDifference: Int {
        abs(myScore - opponentScore)
    }

    func addPoints(to player: Player, amount: Int) {
        switch player {
        case .me:
            myScore += amount
        case .opponent:
            opponentScore += amount
        }
    }

    func removePoints(from player: Player, amount: Int) {
        switch player {
        case .me:
            myScore = max(0, myScore - amount)
        case .opponent:
            opponentScore = max(0, opponentScore - amount)
        }
    }

    func nextRound() {
        currentRound += 1
    }

    func reset() {
        myScore = 0
        opponentScore = 0
        currentRound = 1
        myTacticsScored = []
        opponentTacticsScored = []
    }

    func addTactic(_ tactic: String, to player: Player) {
        switch player {
        case .me:
            myTacticsScored.append(tactic)
        case .opponent:
            opponentTacticsScored.append(tactic)
        }
    }
}

enum Player {
    case me
    case opponent
}

// MARK: - Main Score View

struct ScoreTrackerView: View {
    @StateObject private var game = BattleGame()
    @State private var showSettings = false
    @State private var showTactics = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Round Header
                RoundHeader(round: game.currentRound, isUnderdog: game.isUnderdog)

                // Score Display
                HStack(spacing: 0) {
                    // My Score
                    PlayerScoreCard(
                        name: game.myName,
                        score: game.myScore,
                        isWinning: game.myScore > game.opponentScore,
                        isUnderdog: game.isUnderdog,
                        onAdd: { amount in
                            game.addPoints(to: .me, amount: amount)
                        },
                        onSubtract: {
                            game.removePoints(from: .me, amount: 1)
                        }
                    )

                    Divider()

                    // Opponent Score
                    PlayerScoreCard(
                        name: game.opponentName,
                        score: game.opponentScore,
                        isWinning: game.opponentScore > game.myScore,
                        isUnderdog: !game.isUnderdog && game.opponentScore < game.myScore,
                        onAdd: { amount in
                            game.addPoints(to: .opponent, amount: amount)
                        },
                        onSubtract: {
                            game.removePoints(from: .opponent, amount: 1)
                        }
                    )
                }
                .frame(maxHeight: .infinity)

                // Battle Tactics Button
                Button(action: { showTactics = true }) {
                    HStack {
                        Image(systemName: "list.clipboard.fill")
                        Text("Battle Tactics")
                        Spacer()
                        Text("\(game.myTacticsScored.count + game.opponentTacticsScored.count)")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                }

                // Bottom Controls
                HStack(spacing: 16) {
                    Button(action: {
                        game.nextRound()
                    }) {
                        Label("Next Round", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        game.reset()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Battle Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(game: game)
            }
            .sheet(isPresented: $showTactics) {
                BattleTacticsView(game: game)
            }
        }
    }
}

// MARK: - Round Header

struct RoundHeader: View {
    let round: Int
    let isUnderdog: Bool

    var body: some View {
        HStack {
            Label("Round \(round)", systemImage: "clock.fill")
                .font(.headline)

            Spacer()

            if isUnderdog {
                Label("You're the Underdog", systemImage: "arrow.up.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Player Score Card

struct PlayerScoreCard: View {
    let name: String
    let score: Int
    let isWinning: Bool
    let isUnderdog: Bool
    let onAdd: (Int) -> Void
    let onSubtract: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Player Name
            Text(name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isWinning ? .green : .primary)

            // Score Display
            VStack(spacing: 8) {
                Text("\(score)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(isWinning ? .green : .primary)

                Text("Victory Points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Quick Add Buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    QuickAddButton(value: 1, onTap: onAdd)
                    QuickAddButton(value: 2, onTap: onAdd)
                    QuickAddButton(value: 3, onTap: onAdd)
                }

                HStack(spacing: 12) {
                    QuickAddButton(value: 4, onTap: onAdd)
                    QuickAddButton(value: 5, onTap: onAdd)

                    // Subtract Button
                    Button(action: onSubtract) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .frame(width: 60, height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isWinning ? Color.green.opacity(0.05) : Color.clear)
    }
}

struct QuickAddButton: View {
    let value: Int
    let onTap: (Int) -> Void

    var body: some View {
        Button(action: { onTap(value) }) {
            Text("+\(value)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 60, height: 50)
                .background(Color.blue)
                .cornerRadius(10)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var game: BattleGame
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Player Names") {
                    TextField("Your Name", text: $game.myName)
                    TextField("Opponent Name", text: $game.opponentName)
                }

                Section("Game Info") {
                    HStack {
                        Text("Current Round")
                        Spacer()
                        Text("\(game.currentRound)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Score Difference")
                        Spacer()
                        Text("\(game.scoreDifference) VP")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Reset Game", role: .destructive) {
                        game.reset()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Battle Tactics Tracker

struct BattleTacticsView: View {
    @ObservedObject var game: BattleGame
    @Environment(\.dismiss) private var dismiss
    @State private var newTactic = ""
    @State private var selectedPlayer: Player = .me

    var body: some View {
        NavigationView {
            VStack {
                // Add Tactic Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Score Battle Tactic")
                        .font(.headline)

                    Picker("Player", selection: $selectedPlayer) {
                        Text(game.myName).tag(Player.me)
                        Text(game.opponentName).tag(Player.opponent)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        TextField("Tactic name (e.g., Slay the Warlord)", text: $newTactic)
                            .textFieldStyle(.roundedBorder)

                        Button(action: addTactic) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newTactic.isEmpty)
                    }
                }
                .padding()
                .background(Color(.systemGray6))

                // Scored Tactics List
                List {
                    if !game.myTacticsScored.isEmpty {
                        Section(game.myName) {
                            ForEach(game.myTacticsScored, id: \.self) { tactic in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(tactic)
                                }
                            }
                        }
                    }

                    if !game.opponentTacticsScored.isEmpty {
                        Section(game.opponentName) {
                            ForEach(game.opponentTacticsScored, id: \.self) { tactic in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(tactic)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Battle Tactics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addTactic() {
        guard !newTactic.isEmpty else { return }
        game.addTactic(newTactic, to: selectedPlayer)
        newTactic = ""
    }
}

// MARK: - Preview

struct ScoreTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        ScoreTrackerView()
    }
}

// ============================================
// USAGE INSTRUCTIONS:
// ============================================
// 1. Replace ContentView with ScoreTrackerView in SceneDelegate
// 2. Or create a new file and copy this code
// 3. Update SceneDelegate.swift line 24 to use ScoreTrackerView()
// ============================================
