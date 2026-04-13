import SwiftUI
import CoreData

struct GameDashboardView: View {
    @ObservedObject var gameState: GameStateManager
    @State private var showAbilitySheet = false
    @State private var selectedPlayerForAbilities: PlayerSide = .me
    @State private var showPriorityRollSheet = false
    @State private var showEndTurnSheet = false
    @State private var showEndGameSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Header - Scores and Round Info
            headerView
                .background(Color.gray.opacity(0.1))

            Divider()

            // Main Content
            ScrollView {
                VStack(spacing: 20) {
                    // Current Twist
                    currentTwistCard

                    // Battle Tactics
                    battleTacticsSection

                    // Phase Tracker
                    phaseTrackerSection

                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }

            Divider()

            // Phase Navigation Footer
            phaseNavigationBar
        }
        .navigationTitle("Battle in Progress")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End Game") {
                    showEndGameSheet = true
                }
            }
        }
        .sheet(isPresented: $showAbilitySheet) {
            AbilityListView(gameState: gameState, player: selectedPlayerForAbilities)
        }
        .sheet(isPresented: $showPriorityRollSheet) {
            PriorityRollView(gameState: gameState, isPresented: $showPriorityRollSheet)
        }
        .sheet(isPresented: $showEndTurnSheet) {
            EndTurnView(gameState: gameState, isPresented: $showEndTurnSheet)
        }
        .sheet(isPresented: $showEndGameSheet) {
            EndGameView(gameState: gameState, isPresented: $showEndGameSheet)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Round \(gameState.currentRound)")
                        .font(.headline)
                    Text("\(gameState.season)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack {
                    Text("Turn")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(gameState.currentTurn.rawValue)
                        .font(.headline)
                }
            }

            // Score Display
            HStack(spacing: 40) {
                VStack {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 5) {
                        Text("\(gameState.getMyScore())")
                            .font(.title)
                            .fontWeight(.bold)
                        if gameState.isUnderdog(.me) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }

                Text(":")
                    .font(.title)
                    .foregroundColor(.secondary)

                VStack {
                    Text("Opponent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 5) {
                        Text("\(gameState.getOpponentScore())")
                            .font(.title)
                            .fontWeight(.bold)
                        if gameState.isUnderdog(.opponent) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Current Twist

    private var currentTwistCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Current Twist - Round \(gameState.currentRound)", systemImage: "sparkles")
                .font(.headline)

            if let twist = gameState.currentTwist {
                VStack(alignment: .leading, spacing: 8) {
                    Text(twist.name ?? "No card selected")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(twist.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
            } else {
                Text("No twist active")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Battle Tactics

    private var battleTacticsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Battle Tactics", systemImage: "list.bullet.clipboard")
                .font(.headline)

            HStack(spacing: 10) {
                VStack(alignment: .leading) {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if gameState.canPickBattleTactic(.me) {
                        Text("Can pick new tactic")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("Cannot pick new tactics")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Opponent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if gameState.canPickBattleTactic(.opponent) {
                        Text("Can pick new tactic")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("Cannot pick new tactics")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)

            Button(action: {
                // TODO: Show battle tactics picker
            }) {
                Label("View Available Battle Tactics", systemImage: "rectangle.stack")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Phase Tracker

    private var phaseTrackerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Current Phase", systemImage: "clock")
                .font(.headline)

            HStack {
                ForEach(GamePhase.allCases, id: \.self) { phase in
                    VStack(spacing: 5) {
                        Image(systemName: gameState.currentPhase == phase ? "circle.fill" : "circle")
                            .foregroundColor(gameState.currentPhase == phase ? .blue : .gray)

                        Text(phase.rawValue)
                            .font(.caption2)
                            .foregroundColor(gameState.currentPhase == phase ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(spacing: 10) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Button(action: {
                    selectedPlayerForAbilities = .me
                    showAbilitySheet = true
                }) {
                    Label("My Abilities", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    selectedPlayerForAbilities = .opponent
                    showAbilitySheet = true
                }) {
                    Label("Opponent Abilities", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if gameState.currentRound > 1 {
                Button(action: {
                    showPriorityRollSheet = true
                }) {
                    Label("Priority Roll", systemImage: "dice")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Phase Navigation

    private var phaseNavigationBar: some View {
        HStack {
            Button(action: {
                gameState.previousPhase()
            }) {
                Label("Previous Phase", systemImage: "chevron.left")
            }
            .disabled(gameState.currentPhase == .hero)

            Spacer()

            Text(gameState.currentPhase.rawValue)
                .font(.headline)

            Spacer()

            Button(action: {
                if gameState.currentPhase == .battleshock {
                    showEndTurnSheet = true
                } else {
                    gameState.nextPhase()
                }
            }) {
                Label(gameState.currentPhase == .battleshock ? "End Turn" : "Next Phase", systemImage: "chevron.right")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }
}

// MARK: - Supporting Views

struct AbilityListView: View {
    @ObservedObject var gameState: GameStateManager
    let player: PlayerSide
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var abilities: [Ability] = []

    var body: some View {
        NavigationView {
            List {
                if abilities.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No abilities available")
                            .font(.headline)
                        Text("No active abilities in the \(gameState.currentPhase.rawValue) phase")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(abilities) { ability in
                        AbilityRowView(ability: ability)
                    }
                }

                Section {
                    Text("Showing abilities for \(player.rawValue) in \(gameState.currentPhase.rawValue) phase")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("\(player.rawValue) Abilities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                fetchAbilities()
            }
            .onChange(of: gameState.currentPhase) { _, _ in
                fetchAbilities()
            }
        }
    }

    private func fetchAbilities() {
        let fetchRequest: CoreData.NSFetchRequest<Ability> = Ability.fetchRequest()
        fetchRequest.sortDescriptors = [
            CoreData.NSSortDescriptor(keyPath: \Ability.sortOrder, ascending: true),
            CoreData.NSSortDescriptor(keyPath: \Ability.name, ascending: true)
        ]
        fetchRequest.predicate = NSPredicate(format: "phase == %@ AND warscroll.isDestroyed == NO", gameState.currentPhase.rawValue)

        do {
            abilities = try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching abilities: \(error)")
            abilities = []
        }
    }
}

struct AbilityRowView: View {
    @ObservedObject var ability: Ability
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ability.name ?? "Unknown")
                        .font(.headline)

                    if let warscroll = ability.warscroll {
                        Text(warscroll.name ?? "Unknown Unit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Usage indicator
                if ability.usageLimit == "Once Per Turn" && ability.hasBeenUsedThisTurn {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if ability.usageLimit == "Once Per Game" && ability.hasBeenUsedThisGame {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }

            if showDetails {
                Divider()

                Text(ability.abilityDescription ?? "")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                HStack {
                    Label(ability.timing ?? "During Phase", systemImage: "clock")
                    Spacer()
                    Label(ability.usageLimit ?? "Unlimited", systemImage: "repeat")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)

                if !ability.isPassive {
                    Button(action: {
                        markAbilityAsUsed()
                    }) {
                        Text(ability.hasBeenUsedThisTurn || ability.hasBeenUsedThisGame ? "Used" : "Mark as Used")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(ability.hasBeenUsedThisTurn || ability.hasBeenUsedThisGame ? Color.gray.opacity(0.3) : Color.blue)
                            .foregroundColor(ability.hasBeenUsedThisTurn || ability.hasBeenUsedThisGame ? .secondary : .white)
                            .cornerRadius(8)
                    }
                    .disabled(ability.hasBeenUsedThisTurn || ability.hasBeenUsedThisGame)
                    .padding(.top, 8)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showDetails.toggle()
            }
        }
    }

    private func markAbilityAsUsed() {
        if ability.usageLimit == "Once Per Turn" {
            ability.hasBeenUsedThisTurn = true
        } else if ability.usageLimit == "Once Per Game" {
            ability.hasBeenUsedThisGame = true
        }

        do {
            try ability.managedObjectContext?.save()
        } catch {
            print("Error saving ability state: \(error)")
        }
    }
}

struct PriorityRollView: View {
    @ObservedObject var gameState: GameStateManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Who won the priority roll?")
                    .font(.title2)
                    .padding()

                HStack(spacing: 20) {
                    Button(action: {
                        gameState.setPriorityWinner(.me)
                        chooseFirstPlayer()
                    }) {
                        Text("You")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        gameState.setPriorityWinner(.opponent)
                        chooseFirstPlayer()
                    }) {
                        Text("Opponent")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Priority Roll")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private func chooseFirstPlayer() {
        // TODO: Add sheet to let priority winner choose who goes first
        // For now, just auto-assign
        isPresented = false
    }
}

struct EndTurnView: View {
    @ObservedObject var gameState: GameStateManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("End of \(gameState.currentTurn.rawValue) Turn")
                    .font(.title2)

                Text("Record any Battle Tactics scored this turn")
                    .foregroundColor(.secondary)

                // TODO: Add scoring interface

                Button(action: {
                    gameState.endTurn()
                    isPresented = false
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("End Turn")
        }
    }
}

struct EndGameView: View {
    @ObservedObject var gameState: GameStateManager
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss

    @State private var showResults = false
    @State private var gameResult: (didIWin: Bool, myScore: Int, opponentScore: Int)?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if showResults, let result = gameResult {
                    // Game Results View
                    VStack(spacing: 20) {
                        if result.didIWin {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.yellow)
                            Text("Victory!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else if result.myScore == result.opponentScore {
                            Image(systemName: "equal.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            Text("Draw")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        } else {
                            Image(systemName: "shield.slash.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.red)
                            Text("Defeat")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }

                        // Final Score
                        HStack(spacing: 20) {
                            VStack {
                                Text("You")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(result.myScore)")
                                    .font(.system(size: 60, weight: .bold))
                            }

                            Text(":")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)

                            VStack {
                                Text("Opponent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(result.opponentScore)")
                                    .font(.system(size: 60, weight: .bold))
                            }
                        }

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Back to Menu")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                } else {
                    // Confirmation View
                    Text("End Game")
                        .font(.title)

                    Text("Are you sure you want to end the game?")
                        .foregroundColor(.secondary)

                    HStack(spacing: 20) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            endGameAndSave()
                        }) {
                            Text("End Game")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .padding()
        }
    }

    private func endGameAndSave() {
        let result = gameState.endGame()
        gameResult = result

        // Save to Core Data
        GameRecordService.shared.saveGame(gameState: gameState) { saveResult in
            switch saveResult {
            case .success:
                print("Game saved successfully")
            case .failure(let error):
                print("Error saving game: \(error)")
            }
        }

        showResults = true
    }
}

#Preview {
    let gameState = GameStateManager()
    gameState.startNewGame(
        myArmy: "Stormcast Eternals",
        mySpearhead: "Hammerstrike Force",
        opponentArmy: "Lumineth Realm-lords",
        opponentSpearhead: "Alarith Temple Guard",
        season: "Fire and Jade",
        boardLayout: "Layout A"
    )
    return NavigationView {
        GameDashboardView(gameState: gameState)
    }
}
