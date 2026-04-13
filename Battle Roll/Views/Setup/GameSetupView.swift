import SwiftUI

struct GameSetupView: View {
    @StateObject private var gameState = GameStateManager()
    @State private var setupStep: SetupStep = .selectMyArmy

    enum SetupStep {
        case selectMyArmy
        case selectOpponentArmy
        case selectSeason
        case readyToStart
    }

    // Temporary placeholder data - will be replaced with Core Data
    @State private var mySelectedArmy: String = ""
    @State private var mySelectedSpearhead: String = ""
    @State private var opponentSelectedArmy: String = ""
    @State private var opponentSelectedSpearhead: String = ""
    @State private var selectedSeason: String = ""
    @State private var selectedBoardLayout: String = ""

    @State private var navigateToGame: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Progress indicator
                ProgressView(value: progressValue, total: 4.0)
                    .padding()

                Text(stepTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()

                // Step content
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Navigation buttons
                HStack {
                    if setupStep != .selectMyArmy {
                        Button(action: previousStep) {
                            Label("Back", systemImage: "chevron.left")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    Button(action: nextStep) {
                        Label(nextButtonText, systemImage: "chevron.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
                }
                .padding()
            }
            .navigationTitle("Game Setup")
            .navigationDestination(isPresented: $navigateToGame) {
                GameDashboardView(gameState: gameState)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch setupStep {
        case .selectMyArmy:
            ArmySelectionView(
                selectedArmy: $mySelectedArmy,
                selectedSpearhead: $mySelectedSpearhead,
                title: "Select Your Army"
            )

        case .selectOpponentArmy:
            ArmySelectionView(
                selectedArmy: $opponentSelectedArmy,
                selectedSpearhead: $opponentSelectedSpearhead,
                title: "Select Opponent's Army"
            )

        case .selectSeason:
            SeasonSelectionView(
                selectedSeason: $selectedSeason,
                selectedBoardLayout: $selectedBoardLayout
            )

        case .readyToStart:
            GameSummaryView(
                myArmy: mySelectedArmy,
                mySpearhead: mySelectedSpearhead,
                opponentArmy: opponentSelectedArmy,
                opponentSpearhead: opponentSelectedSpearhead,
                season: selectedSeason,
                boardLayout: selectedBoardLayout
            )
        }
    }

    private var stepTitle: String {
        switch setupStep {
        case .selectMyArmy: return "Your Army"
        case .selectOpponentArmy: return "Opponent's Army"
        case .selectSeason: return "Season & Board"
        case .readyToStart: return "Ready to Battle"
        }
    }

    private var nextButtonText: String {
        setupStep == .readyToStart ? "Start Game" : "Next"
    }

    private var canProceed: Bool {
        switch setupStep {
        case .selectMyArmy:
            return !mySelectedArmy.isEmpty && !mySelectedSpearhead.isEmpty
        case .selectOpponentArmy:
            return !opponentSelectedArmy.isEmpty && !opponentSelectedSpearhead.isEmpty
        case .selectSeason:
            return !selectedSeason.isEmpty && !selectedBoardLayout.isEmpty
        case .readyToStart:
            return true
        }
    }

    private var progressValue: Double {
        switch setupStep {
        case .selectMyArmy: return 1.0
        case .selectOpponentArmy: return 2.0
        case .selectSeason: return 3.0
        case .readyToStart: return 4.0
        }
    }

    private func nextStep() {
        switch setupStep {
        case .selectMyArmy:
            setupStep = .selectOpponentArmy
        case .selectOpponentArmy:
            setupStep = .selectSeason
        case .selectSeason:
            setupStep = .readyToStart
        case .readyToStart:
            startGame()
        }
    }

    private func previousStep() {
        switch setupStep {
        case .selectOpponentArmy:
            setupStep = .selectMyArmy
        case .selectSeason:
            setupStep = .selectOpponentArmy
        case .readyToStart:
            setupStep = .selectSeason
        case .selectMyArmy:
            break
        }
    }

    private func startGame() {
        gameState.startNewGame(
            myArmy: mySelectedArmy,
            mySpearhead: mySelectedSpearhead,
            opponentArmy: opponentSelectedArmy,
            opponentSpearhead: opponentSelectedSpearhead,
            season: selectedSeason,
            boardLayout: selectedBoardLayout
        )
        navigateToGame = true
    }
}

// MARK: - Supporting Views

struct GameSummaryView: View {
    let myArmy: String
    let mySpearhead: String
    let opponentArmy: String
    let opponentSpearhead: String
    let season: String
    let boardLayout: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Forces")
                    .font(.headline)
                Text("\(myArmy) - \(mySpearhead)")
                    .font(.body)
                    .foregroundColor(.blue)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Opponent's Forces")
                    .font(.headline)
                Text("\(opponentArmy) - \(opponentSpearhead)")
                    .font(.body)
                    .foregroundColor(.red)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Battle Details")
                    .font(.headline)
                Text("Season: \(season)")
                Text("Board: \(boardLayout)")
            }

            Spacer()

            Text("Press 'Start Game' when ready to begin the battle!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

#Preview {
    GameSetupView()
}
