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

            playerAbilitySection(for: active, title: "\(state[active].name) — your turn")
            playerAbilitySection(for: active.other, title: "\(state[active.other].name) — reactions")

            if state.desolationEnabled, state.phase == .hero {
                desolationSection
            }

            if !PhaseEngine.coreAbilities(for: state.phase).isEmpty {
                Section {
                    DisclosureGroup("Core abilities", isExpanded: $showCore) {
                        ForEach(PhaseEngine.coreAbilities(for: state.phase)) { core in
                            AbilityRow(ability: core, style: .army, sourceLabel: "Core rules",
                                       used: false, onToggleUsed: nil)
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
    private func playerAbilitySection(for side: PlayerSide, title: String) -> some View {
        let items = PhaseEngine.items(for: side, session: session,
                                      phase: state.phase, includePassives: showPassives)
        if !items.isEmpty {
            let armyItems = items.filter { if case .tacticCommand = $0.source { return false }; return true }
            let cardItems = items.filter { if case .tacticCommand = $0.source { return true }; return false }

            Section {
                ForEach(armyItems) { item in
                    armyAbilityRow(item: item, side: side)
                }
                if !cardItems.isEmpty {
                    commandsDivider
                    ForEach(cardItems) { item in
                        cardCommandRow(item: item, side: side)
                    }
                }
            } header: {
                playerSectionHeader(title: title, side: side, armyCount: armyItems.count, cardCount: cardItems.count)
            }
        }
    }

    @ViewBuilder
    private func playerSectionHeader(title: String, side: PlayerSide, armyCount: Int, cardCount: Int) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(side.themeColor)
                .frame(width: 3, height: 14)
            Text(title)
                .foregroundStyle(side.themeColor)
                .fontWeight(.semibold)
            Spacer()
            if cardCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.caption2)
                    Text("\(cardCount)")
                        .font(.caption2.bold())
                }
                .foregroundStyle(SpearheadTheme.flame)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(SpearheadTheme.flame.opacity(0.15), in: Capsule())
            }
        }
        .textCase(nil)
    }

    @ViewBuilder
    private var commandsDivider: some View {
        HStack(spacing: 8) {
            Rectangle().fill(SpearheadTheme.flame.opacity(0.35)).frame(height: 1)
            HStack(spacing: 4) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.caption2)
                Text("Battle Tactic Commands")
                    .font(.caption.bold())
            }
            .foregroundStyle(SpearheadTheme.flame)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(SpearheadTheme.flame.opacity(0.12), in: Capsule())
            Rectangle().fill(SpearheadTheme.flame.opacity(0.35)).frame(height: 1)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
    }

    @ViewBuilder
    private func armyAbilityRow(item: AbilityItem, side: PlayerSide) -> some View {
        let used = session.isUsed(key: item.usageKey, frequency: item.ability.frequency, side: side)
        AbilityRow(
            ability: item.ability,
            style: .army,
            sourceLabel: item.sourceLabel,
            used: used,
            onToggleUsed: item.ability.frequency == .passive || item.ability.frequency == .unlimited ? nil : {
                if used {
                    session.unmarkUsed(key: item.usageKey, side: side)
                } else {
                    session.markUsed(key: item.usageKey, frequency: item.ability.frequency, side: side)
                }
            }
        )
    }

    @ViewBuilder
    private func cardCommandRow(item: AbilityItem, side: PlayerSide) -> some View {
        if case .tacticCommand(let card) = item.source {
            AbilityRow(ability: item.ability, style: .tacticCard, sourceLabel: card.name,
                       used: false, onToggleUsed: nil)
                .swipeActions(edge: .trailing) {
                    Button {
                        session.setTactic(card.name, to: .usedAsCommand, for: side)
                    } label: {
                        Label("Use command", systemImage: "bolt.fill")
                    }
                    .tint(SpearheadTheme.flame)
                }
                .contextMenu {
                    Button {
                        session.setTactic(card.name, to: .usedAsCommand, for: side)
                    } label: {
                        Label("Use as command (discard card)", systemImage: "bolt.fill")
                    }
                }
        }
    }

    // MARK: - Other sections

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
                    AbilityRow(ability: a, style: .army, sourceLabel: module.name, used: false, onToggleUsed: nil)
                }
            }
        }
    }
}

// MARK: - AbilityRow

enum AbilityRowStyle {
    case army       // army ability / battle trait / unit ability
    case tacticCard // battle tactic card command
}

/// A single ability card row — styled differently for army abilities vs tactic card commands.
struct AbilityRow: View {
    let ability: AbilityData
    var style: AbilityRowStyle = .army
    let sourceLabel: String
    let used: Bool
    let onToggleUsed: (() -> Void)?

    var body: some View {
        switch style {
        case .army:
            armyRow
        case .tacticCard:
            tacticCardRow
        }
    }

    // MARK: Army ability row

    private var armyRow: some View {
        HStack(alignment: .top, spacing: 10) {
            // Phase-colored left accent strip
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor.opacity(0.7))
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    if ability.window == .start {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundStyle(SpearheadTheme.gold)
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
                            .background(badgeColor.opacity(0.18), in: Capsule())
                            .foregroundStyle(badgeColor)
                    }
                }

                // Timing bar
                Text(ability.timingText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SpearheadTheme.arcane)

                if let declare = ability.declare {
                    abilityDetail("Declare", declare)
                }
                abilityDetail("Effect", ability.effect)

                HStack {
                    Text(sourceLabel)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    if let onToggleUsed {
                        Button(used ? "Used ✓" : "Mark used") {
                            onToggleUsed()
                        }
                        .font(.caption.bold())
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(accentColor)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(used ? 0.45 : 1)
    }

    // MARK: Tactic card command row

    private var tacticCardRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card banner header
            HStack(spacing: 7) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.caption2.bold())
                Text(sourceLabel)
                    .font(.caption2.bold())
                    .lineLimit(1)
                Spacer()
                Text("Swipe → to use")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(SpearheadTheme.flame)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(SpearheadTheme.flame.opacity(0.1))

            // Ability content
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(SpearheadTheme.flame)
                    Text(ability.name)
                        .font(.subheadline.bold())
                    Spacer()
                }

                Text(ability.timingText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SpearheadTheme.arcane)

                if let declare = ability.declare {
                    abilityDetail("Declare", declare)
                }
                abilityDetail("Effect", ability.effect)

                Text("Using as command discards this card — it cannot be scored as a battle tactic.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(.top, 2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(SpearheadTheme.flame.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    // MARK: Helpers

    private func abilityDetail(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(label): ")
                .font(.caption.bold())
            Text(value)
                .font(.caption)
        }
    }

    private var accentColor: Color {
        if ability.frequency == .passive { return SpearheadTheme.steel }
        if ability.window == .start { return SpearheadTheme.gold }
        if ability.window == .reaction { return SpearheadTheme.ember }
        return SpearheadTheme.jade
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
