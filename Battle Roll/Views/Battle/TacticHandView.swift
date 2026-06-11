import SwiftUI

/// Manage one player's battle tactic cards: which are in hand, scored,
/// spent as commands or discarded. Mirrors the physical deck.
///
/// Your own hand is tracked card by card. An opponent's hand can be tracked
/// face down ("hidden cards"): you only know how many they hold, and you
/// reveal which card it was when they use a command, or when they score or
/// discard it at the end of their turn.
struct TacticHandView: View {
    @ObservedObject var session: BattleSession
    let side: PlayerSide
    @Environment(\.dismiss) private var dismiss

    private var player: PlayerBattleState { session.state[side] }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("\(player.handCount)/3 in hand", systemImage: "rectangle.stack")
                        Spacer()
                        Button {
                            session.drawRandomTactics(for: side)
                        } label: {
                            Label("Draw to 3", systemImage: "shuffle")
                                .font(.caption.bold())
                        }
                        .buttonStyle(.bordered)
                        .disabled(player.handCount >= 3)
                    }
                    HStack {
                        Label("Hidden cards: \(player.hiddenHandCount)",
                              systemImage: "questionmark.square.dashed")
                            .foregroundStyle(player.hiddenHandCount > 0 ? SpearheadTheme.arcane : Color.primary)
                        Spacer()
                        Stepper("Hidden cards", value: Binding(
                            get: { player.hiddenHandCount },
                            set: { session.setHiddenHandCount($0, for: side) }
                        ), in: 0...3)
                        .labelsHidden()
                    }
                } footer: {
                    Text("Track your own hand card by card. If this is your opponent and you can't see their cards, add hidden cards instead — then swipe a card in the deck to reveal it when they use its command or discard it. Scored cards are revealed in their end-of-turn scoring.")
                }

                tacticSection("In hand", .inHand)
                tacticSection("In deck", .inDeck)
                tacticSection("Scored (1 VP)", .scored)
                tacticSection("Used as command", .usedAsCommand)
                tacticSection("Discarded", .discarded)
            }
            .navigationTitle("\(player.name) — Tactics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func tacticSection(_ title: String, _ location: TacticCardLocation) -> some View {
        let cards = session.season.battleTactics.filter {
            session.tacticLocation($0.name, for: side) == location
        }
        if !cards.isEmpty {
            Section {
                ForEach(cards) { card in
                    TacticCardRow(card: card)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            actions(for: card, at: location)
                        }
                }
            } header: {
                if location == .inDeck && player.hiddenHandCount > 0 {
                    Text("\(title) — may include their \(player.hiddenHandCount) hidden card\(player.hiddenHandCount == 1 ? "" : "s")")
                } else {
                    Text(title)
                }
            }
        }
    }

    @ViewBuilder
    private func actions(for card: BattleTacticCard, at location: TacticCardLocation) -> some View {
        switch location {
        case .inDeck:
            if player.hiddenHandCount > 0 {
                // Revealing a hidden card: it was in their hand all along.
                Button("Used command") { session.revealHiddenTactic(card.name, as: .usedAsCommand, for: side) }
                    .tint(.orange)
                Button("Discarded") { session.revealHiddenTactic(card.name, as: .discarded, for: side) }
                    .tint(.gray)
                Button("Show in hand") { session.revealHiddenTactic(card.name, as: .inHand, for: side) }
                    .tint(.blue)
            } else {
                Button("To hand") { session.setTactic(card.name, to: .inHand, for: side) }
                    .tint(.blue)
            }
        case .inHand:
            Button("Command") { session.setTactic(card.name, to: .usedAsCommand, for: side) }
                .tint(.orange)
            Button("Discard") { session.setTactic(card.name, to: .discarded, for: side) }
                .tint(.gray)
            Button("Back to deck") { session.setTactic(card.name, to: .inDeck, for: side) }
                .tint(.indigo)
        case .scored, .usedAsCommand, .discarded:
            Button("To hand") { session.setTactic(card.name, to: .inHand, for: side) }
                .tint(.blue)
        }
    }
}

struct TacticCardRow: View {
    let card: BattleTacticCard

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(card.name).font(.subheadline.bold())
            (Text("Tactic: ").font(.caption.bold()).foregroundColor(SpearheadTheme.jade)
                + Text(card.tactic).font(.caption))
            (Text("Command — \(card.command.name) (\(card.command.timingText)): ")
                .font(.caption.bold()).foregroundColor(SpearheadTheme.flame)
                + Text(card.command.effect).font(.caption))
        }
        .padding(.vertical, 3)
    }
}
