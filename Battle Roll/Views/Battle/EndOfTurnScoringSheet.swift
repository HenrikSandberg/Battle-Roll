import SwiftUI

/// Official end-of-turn scoring: up to 3 objective VP, 1 VP per completed
/// battle tactic, plus any extra VP granted by the current twist.
///
/// If the active player's hand was tracked face down (an opponent), this is
/// the moment their scored cards are revealed — pick them from the deck list.
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

    private var knownHand: [BattleTacticCard] {
        season.battleTactics.filter { session.tacticLocation($0.name, for: side) == .inHand }
    }

    private var unrevealedDeck: [BattleTacticCard] {
        season.battleTactics.filter { session.tacticLocation($0.name, for: side) == .inDeck }
    }

    /// How many of the selected tactics come from the face-down hand.
    private var hiddenSelectedCount: Int {
        completedTactics.filter { name in
            session.tacticLocation(name, for: side) == .inDeck
        }.count
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
                    if knownHand.isEmpty && state[side].hiddenHandCount == 0 {
                        Text("No cards in hand.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(knownHand) { card in
                        tacticRow(card, disabled: false)
                    }
                }

                if state[side].hiddenHandCount > 0 {
                    Section {
                        ForEach(unrevealedDeck) { card in
                            tacticRow(card, disabled: !completedTactics.contains(card.name)
                                      && hiddenSelectedCount >= state[side].hiddenHandCount)
                        }
                    } header: {
                        Text("Hidden hand — \(state[side].hiddenHandCount) face-down card\(state[side].hiddenHandCount == 1 ? "" : "s")")
                    } footer: {
                        Text("\(state[side].name)'s hand is tracked face down. Pick the card(s) they revealed and scored this turn — they'll move out of the hidden hand.")
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

    private func tacticRow(_ card: BattleTacticCard, disabled: Bool) -> some View {
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
                    .foregroundStyle(completedTactics.contains(card.name)
                                     ? SpearheadTheme.jade : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name).font(.subheadline.bold())
                    Text(card.tactic).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }

    private var season: SeasonPack { session.season }
}
