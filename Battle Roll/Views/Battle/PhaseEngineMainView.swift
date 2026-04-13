import SwiftUI
import CoreData

/// Main Phase Engine view with game controls
struct PhaseEngineMainView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var phaseManager: PhaseManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss

    private func dismissAction() {
        if #available(iOS 15.0, *) {
            dismiss()
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Game Status Bar
                GameStatusBar()

                // Phase Abilities View
                PhaseAbilitiesView()
            }
            .navigationTitle("Phase Engine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismissAction()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            if gameState.isGameActive {
                                gameState.endGame()
                            } else {
                                startNewGame()
                            }
                        }) {
                            Label(
                                gameState.isGameActive ? "End Game" : "Start Game",
                                systemImage: gameState.isGameActive ? "stop.circle" : "play.circle"
                            )
                        }

                        Divider()

                        Button(action: {
                            gameState.addCommandPoints(1)
                        }) {
                            Label("Add CP", systemImage: "plus.circle")
                        }

                        Button(action: {
                            gameState.addVictoryPoints(1)
                        }) {
                            Label("Add VP", systemImage: "star.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func startNewGame() {
        gameState.startGame()
        DataService.shared.resetGameTracking()

        // Restore all destroyed units
        let fetchRequest: NSFetchRequest<Warscroll> = Warscroll.fetchRequest()
        do {
            let warscrolls = try viewContext.fetch(fetchRequest)
            warscrolls.forEach {
                $0.isDestroyed = false
                $0.damageAllocated = 0
            }
            try viewContext.save()
        } catch {
            print("Error restoring units: \(error)")
        }

        phaseManager.updateAvailableAbilities(from: viewContext)
    }
}

// MARK: - Game Status Bar

struct GameStatusBar: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        HStack(spacing: 20) {
            // Round Counter
            VStack(spacing: 4) {
                Text("Round")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(gameState.currentRound)")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Divider()
                .frame(height: 40)

            // Victory Points
            VStack(spacing: 4) {
                Text("VP")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(gameState.victoryPoints)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }

            Spacer()

            // Command Points
            VStack(spacing: 4) {
                Text("CP")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundColor(.purple)
                    Text("\(gameState.commandPoints)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Preview

struct PhaseEngineMainView_Previews: PreviewProvider {
    struct PreviewContainer: View {
        let gameState: GameState
        let phaseManager: PhaseManager
        let context = PersistenceController.preview.container.viewContext

        init() {
            let gs = GameState()
            gs.isGameActive = true
            gs.currentRound = 2
            gs.victoryPoints = 5
            gs.commandPoints = 3
            self.gameState = gs
            self.phaseManager = PhaseManager(gameState: gs)
        }

        var body: some View {
            PhaseEngineMainView()
                .environment(\.managedObjectContext, context)
                .environmentObject(gameState)
                .environmentObject(phaseManager)
        }
    }

    static var previews: some View {
        PreviewContainer()
    }
}
