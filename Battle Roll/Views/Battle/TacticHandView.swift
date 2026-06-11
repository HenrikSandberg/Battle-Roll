import SwiftUI

/// Manage one player's battle tactic cards: which are in hand, scored,
/// spent as commands or discarded. Mirrors the physical deck.
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
                } footer: {
                    Text("Mark the cards you physically drew, or let the app draw for you. Swipe a card for actions.")
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
            Section(title) {
                ForEach(cards) { card in
                    TacticCardRow(card: card)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            actions(for: card, at: location)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func actions(for card: BattleTacticCard, at location: TacticCardLocation) -> some View {
        switch location {
        case .inDeck:
            Button("To hand") { session.setTactic(card.name, to: .inHand, for: side) }
                .tint(.blue)
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
            Text("Tactic: ").font(.caption.bold()) + Text(card.tactic).font(.caption)
            (Text("Command — \(card.command.name) (\(card.command.timingText)): ").font(.caption.bold())
                + Text(card.command.effect).font(.caption))
        }
        .padding(.vertical, 3)
    }
}
