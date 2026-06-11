import SwiftUI

/// Official end-of-turn scoring: up to 3 objective VP, 1 VP per completed
/// battle tactic, plus any extra VP granted by the current twist.
struct EndOfTurnScoringSheet: View {
    @ObservedObject var session: BattleSession
    @Environment(\.dismiss) private var dismiss

    @State private var controlsOne = false
    @State private var controlsTwoPlus = false
    @State private var controlsMore = false
    @State private var completedTactics: Set<String> = []
    @State private var twistExtra = 0

    private var state: BattleState { session.state }
    private var side: PlayerSide { state.activePlayer }

    private var totalVP: Int {
        (controlsOne ? 1 : 0) + (controlsTwoPlus ? 1 : 0) + (controlsMore ? 1 : 0)
            + completedTactics.count + twistExtra
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Objectives — \(state[side].name)") {
                    Toggle("Controls at least 1 objective (+1 VP)", isOn: $controlsOne)
                    Toggle("Controls 2 or more objectives (+1 VP)", isOn: $controlsTwoPlus)
                    Toggle("Controls more objectives than opponent (+1 VP)", isOn: $controlsMore)
                }

                Section("Battle tactics completed this turn (+1 VP each)") {
                    let hand = season.battleTactics.filter {
                        session.tacticLocation($0.name, for: side) == .inHand
                    }
                    if hand.isEmpty {
                        Text("No cards in hand.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(hand) { card in
                        Button {
                            if completedTactics.contains(card.name) {
                                completedTactics.remove(card.name)
                            } else {
                                completedTactics.insert(card.name)
                            }
                        } label: {
                            HStack(alignment: .firstTextBaseline) {
                                Image(systemName: completedTactics.contains(card.name)
                                      ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(card.name).font(.subheadline.bold())
                                    Text(card.tactic).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let twist = session.currentTwist {
                    Section("Twist: \(twist.name)") {
                        Stepper("Extra VP from twist: \(twistExtra)", value: $twistExtra, in: 0...10)
                        Text(twist.effect)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        session.commitEndOfTurnScoring(for: side,
                                                       controlsOne: controlsOne,
                                                       controlsTwoPlus: controlsTwoPlus,
                                                       controlsMore: controlsMore,
                                                       tacticsCompleted: Array(completedTactics),
                                                       twistExtraVP: twistExtra)
                        dismiss()
                    } label: {
                        Label("Score \(totalVP) VP and end turn", systemImage: "flag.checkered")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("End of Turn — \(state[side].name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var season: SeasonPack { session.season }
}
