import SwiftUI

/// Lists everything relevant in the current phase for both players:
/// start-of-phase reminders, usable abilities, reactions, commands and core abilities.
struct PhaseContentView: View {
    @ObservedObject var session: BattleSession
    @Binding var showUnits: Bool
    let showTactics: (PlayerSide) -> Void

    @State private var showPassives = false
    @State private var showCore = false

    private var state: BattleState { session.state }
    private var active: PlayerSide { state.activePlayer }

    var body: some View {
        List {
            if state.phase == .startOfTurn {
                startOfTurnChecklist
            }

            abilitySection(for: active, title: "\(state[active].name) — your turn")
            abilitySection(for: active.other, title: "\(state[active.other].name) — reactions")

            if state.desolationEnabled, state.phase == .hero {
                desolationSection
            }

            if !PhaseEngine.coreAbilities(for: state.phase).isEmpty {
                Section {
                    DisclosureGroup("Core abilities", isExpanded: $showCore) {
                        ForEach(PhaseEngine.coreAbilities(for: state.phase)) { core in
                            AbilityRow(ability: core, sourceLabel: "Core", used: false, onToggleUsed: nil)
                        }
                    }
                }
            }

            Section {
                Toggle("Show passive abilities", isOn: $showPassives.animation())
            }

            if state.phase == .endOfTurn {
                endOfTurnHints
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Sections

    @ViewBuilder
    private func abilitySection(for side: PlayerSide, title: String) -> some View {
        let items = PhaseEngine.items(for: side, session: session,
                                      phase: state.phase, includePassives: showPassives)
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { item in
                    abilityRow(item: item, side: side)
                }
            }
        }
    }

    @ViewBuilder
    private func abilityRow(item: AbilityItem, side: PlayerSide) -> some View {
        let used = session.isUsed(key: item.usageKey, frequency: item.ability.frequency, side: side)
        if case .tacticCommand(let card) = item.source {
            AbilityRow(ability: item.ability, sourceLabel: "Command card", used: false, onToggleUsed: nil)
                .swipeActions(edge: .trailing) {
                    Button {
                        session.setTactic(card.name, to: .usedAsCommand, for: side)
                    } label: {
                        Label("Use command", systemImage: "bolt.fill")
                    }
                    .tint(.orange)
                }
                .contextMenu {
                    Button {
                        session.setTactic(card.name, to: .usedAsCommand, for: side)
                    } label: {
                        Label("Use as command (discard card)", systemImage: "bolt.fill")
                    }
                }
        } else {
            AbilityRow(ability: item.ability,
                       sourceLabel: item.sourceLabel,
                       used: used,
                       onToggleUsed: item.ability.frequency == .passive || item.ability.frequency == .unlimited ? nil : {
                if used {
                    session.unmarkUsed(key: item.usageKey, side: side)
                } else {
                    session.markUsed(key: item.usageKey, frequency: item.ability.frequency, side: side)
                }
            })
        }
    }

    private var startOfTurnChecklist: some View {
        Section("Start of turn") {
            if state.stage == .firstTurn {
                Label("First turn of round \(state.round)", systemImage: "1.circle")
            } else {
                Label("Second turn of round \(state.round)", systemImage: "2.circle")
            }
            if let seized = state.seizedInitiative, seized == active {
                Label("\(state[seized].name) seized the initiative — no battle tactic draw this round (unless underdog by 5+).",
                      systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.callout)
            }
            Button {
                showTactics(active)
            } label: {
                Label("Review battle tactic hand (\(state[active].handCount)/3)", systemImage: "rectangle.stack")
            }
        }
    }

    private var endOfTurnHints: some View {
        Section("End of turn") {
            Label("Score objectives and battle tactics, then end the turn with the button below.", systemImage: "info.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button {
                showUnits = true
            } label: {
                Label("Update unit casualties first", systemImage: "person.3")
            }
        }
    }

    private var desolationSection: some View {
        Section("Desolation — \(state[active].name)") {
            Stepper(value: Binding(
                get: { session.state[active].desolatedCount },
                set: { session.state[active].desolatedCount = max(0, $0) }
            ), in: 0...8) {
                Label("Desolated sites: \(state[active].desolatedCount)", systemImage: "flame")
            }
            Stepper(value: Binding(
                get: { session.state[active].desolationPoints },
                set: { session.state[active].desolationPoints = max(0, $0) }
            ), in: 0...30) {
                Label("Desolation points: \(state[active].desolationPoints)", systemImage: "circle.hexagongrid")
            }
            if let module = session.desolationModule {
                ForEach(module.abilities) { a in
                    AbilityRow(ability: a, sourceLabel: module.name, used: false, onToggleUsed: nil)
                }
            }
        }
    }
}

/// A single ability card row.
struct AbilityRow: View {
    let ability: AbilityData
    let sourceLabel: String
    let used: Bool
    let onToggleUsed: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                if ability.window == .start {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                Text(ability.name)
                    .font(.subheadline.bold())
                    .strikethrough(used)
                Spacer()
                if let badge = ability.frequency.badgeText {
                    Text(badge)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeColor.opacity(0.2), in: Capsule())
                        .foregroundStyle(badgeColor)
                }
            }
            Text(ability.timingText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.purple)
            if let declare = ability.declare {
                abilityDetail("Declare", declare)
            }
            abilityDetail("Effect", ability.effect)
            HStack {
                Text(sourceLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if let onToggleUsed {
                    Button(used ? "Used ✓" : "Mark used") {
                        onToggleUsed()
                    }
                    .font(.caption.bold())
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(used ? 0.5 : 1)
    }

    private func abilityDetail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(label): ")
                .font(.caption.bold())
            Text(value)
                .font(.caption)
        }
    }

    private var badgeColor: Color {
        switch ability.frequency {
        case .oncePerBattle: return .red
        case .oncePerTurn, .oncePerTurnArmy, .oncePerPhase: return .orange
        case .passive: return .blue
        case .unlimited: return .gray
        }
    }
}
