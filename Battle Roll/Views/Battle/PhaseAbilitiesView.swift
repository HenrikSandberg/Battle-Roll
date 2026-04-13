import SwiftUI
import CoreData

/// Displays all available abilities for the current phase
struct PhaseAbilitiesView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var phaseManager: PhaseManager
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack(spacing: 0) {
            // Phase Header
            PhaseHeaderView(phase: gameState.currentPhase)

            // Reminder Section (Start/End of Phase abilities)
            if !phaseManager.reminderAbilities.isEmpty {
                ReminderBanner(abilities: phaseManager.reminderAbilities)
            }

            // Available Abilities List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(phaseManager.availableAbilities, id: \.id) { ability in
                        AbilityCardView(
                            ability: ability,
                            onUse: {
                                phaseManager.markAbilityAsUsed(ability, in: viewContext)
                            }
                        )
                    }
                }
                .padding()
            }

            // Phase Controls
            PhaseControlsView()
        }
        .onAppear {
            phaseManager.updateAvailableAbilities(from: viewContext)
        }
        .onChange(of: gameState.currentPhase) { _, _ in
            phaseManager.updateAvailableAbilities(from: viewContext)
        }
    }
}

// MARK: - Phase Header

struct PhaseHeaderView: View {
    let phase: GamePhase
    
    private var phaseHeaderColor: Color {
        // Map known phases to system colors; adjust as needed for your phases
        switch phase {
        case .hero:
            return .blue
        case .movement:
            return .green
        case .shooting:
            return .orange
        case .charge:
            return .purple
        case .combat:
            return .red
        case .battleshock:
            return .teal
        default:
            return .gray
        }
    }

    var body: some View {
        HStack {
            Image(systemName: phase.iconName)
                .font(.title)
            Text(phase.rawValue)
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
        }
        .padding()
        .background(phaseHeaderColor.opacity(0.2))
    }
}

// MARK: - Reminder Banner

struct ReminderBanner: View {
    let abilities: [Ability]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Don't Forget!")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            ForEach(abilities, id: \.id) { ability in
                HStack {
                    Text(ability.warscroll?.name ?? "Unknown")
                        .fontWeight(.semibold)
                    Text("•")
                    Text(ability.name ?? "Unknown Ability")
                    Spacer()
                    Text(ability.timingDisplay)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Ability Card

struct AbilityCardView: View {
    let ability: Ability
    let onUse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ability.warscroll?.name ?? "Unknown Unit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(ability.name ?? "Unknown Ability")
                        .font(.headline)
                }

                Spacer()

                if let badge = ability.badgeText {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ability.isAvailable ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }

            // Description
            Text(ability.abilityDescription ?? "")
                .font(.subheadline)
                .foregroundColor(.primary)

            // Timing Info
            HStack {
                Label(ability.timingDisplay, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if ability.isAvailable && ability.abilityUsageLimit != .unlimited {
                    Button(action: onUse) {
                        Text("Mark Used")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .opacity(ability.isAvailable ? 1.0 : 0.5)
    }
}

// MARK: - Phase Controls

struct PhaseControlsView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var phaseManager: PhaseManager
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        HStack(spacing: 16) {
            // Previous Phase (for iPad)
            Button(action: {
                // Navigate backwards through phases
                let allPhases = GamePhase.allCases
                if let currentIndex = allPhases.firstIndex(of: gameState.currentPhase) {
                    let previousIndex = (currentIndex - 1 + allPhases.count) % allPhases.count
                    gameState.currentPhase = allPhases[previousIndex]
                }
            }) {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            Spacer()

            // Next Phase
            Button(action: {
                gameState.advancePhase()

                // Reset turn abilities when returning to Hero phase
                if gameState.currentPhase == .hero {
                    phaseManager.resetTurnAbilities(in: viewContext)
                }
            }) {
                HStack {
                    Text("Next Phase")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right.circle.fill")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Preview

struct PhaseAbilitiesView_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        let phaseManager = PhaseManager(gameState: gameState)

        PhaseAbilitiesView()
            .environmentObject(gameState)
            .environmentObject(phaseManager)
    }
}
