import SwiftUI

/// Track damage, slain models and destroyed state for every unit on both sides.
struct UnitTrackerView: View {
    @ObservedObject var session: BattleSession
    @Environment(\.dismiss) private var dismiss
    @State private var side: PlayerSide = .one

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Player", selection: $side) {
                    Text(session.state[.one].name).tag(PlayerSide.one)
                    Text(session.state[.two].name).tag(PlayerSide.two)
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    ForEach(session.state[side].units) { unit in
                        UnitRow(session: session, side: side, unit: unit)
                    }
                    let candidates = session.reinforcementCandidates(for: side)
                    if !candidates.isEmpty {
                        Section("Call for Reinforcements (your movement phase)") {
                            ForEach(candidates) { unit in
                                Button {
                                    session.callReinforcements(for: unit.id, side: side)
                                } label: {
                                    Label("Return \(unit.label) as replacement unit",
                                          systemImage: "arrow.uturn.backward.circle")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct UnitRow: View {
    @ObservedObject var session: BattleSession
    let side: PlayerSide
    let unit: UnitState

    var body: some View {
        let scroll = session.warscroll(for: unit, side: side)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        if scroll?.isGeneral == true {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                        Text(unit.label)
                            .font(.subheadline.bold())
                            .strikethrough(unit.isDestroyed)
                    }
                    if let scroll {
                        Text("M \(scroll.move) · H \(scroll.health)\(scroll.modelsPerUnit > 1 ? "×\(scroll.modelsPerUnit)" : "") · Sv \(scroll.save) · C \(scroll.control)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(scroll.keywords.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Button {
                    session.toggleDestroyed(unit.id, side: side)
                } label: {
                    Image(systemName: unit.isDestroyed ? "xmark.octagon.fill" : "xmark.octagon")
                        .font(.title3)
                        .foregroundStyle(unit.isDestroyed ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }

            if !unit.isDestroyed, let scroll {
                if scroll.modelsPerUnit > 1 {
                    Stepper(value: Binding(
                        get: { unit.slainModels },
                        set: { session.setDamage(unit.damage, slainModels: $0, on: unit.id, side: side) }
                    ), in: 0...scroll.modelsPerUnit) {
                        Text("Slain models: \(unit.slainModels)/\(scroll.modelsPerUnit)")
                            .font(.caption)
                    }
                } else {
                    Stepper(value: Binding(
                        get: { unit.damage },
                        set: { session.setDamage($0, slainModels: unit.slainModels, on: unit.id, side: side) }
                    ), in: 0...scroll.health) {
                        Text("Damage: \(unit.damage)/\(scroll.health)")
                            .font(.caption)
                            .foregroundStyle(unit.damage > scroll.health / 2 ? .red : .primary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
        .opacity(unit.isDestroyed ? 0.55 : 1)
    }
}
