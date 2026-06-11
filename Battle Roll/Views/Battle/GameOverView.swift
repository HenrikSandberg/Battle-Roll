import SwiftUI

/// Shown after round 4's second end of turn.
struct GameOverView: View {
    @ObservedObject var session: BattleSession
    let onFinish: () -> Void

    private var state: BattleState { session.state }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)

                if let winner = state.winner() {
                    Text("\(state[winner].name) wins!")
                        .font(.largeTitle.bold())
                } else {
                    Text("It's a draw!")
                        .font(.largeTitle.bold())
                }

                HStack(spacing: 32) {
                    finalScore(.one)
                    Text("–").font(.title)
                    finalScore(.two)
                }

                List {
                    Section("Victory point log") {
                        ForEach(state[.one].vpLog + state[.two].vpLog) { entry in
                            HStack {
                                Text("R\(entry.round) · \(state[entry.player].name)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(entry.source)
                                    .font(.caption)
                                Spacer()
                                Text("+\(entry.points)")
                                    .font(.caption.bold().monospacedDigit())
                            }
                        }
                    }
                }
                .frame(maxHeight: 280)
                .scrollContentBackground(.hidden)

                Button {
                    onFinish()
                } label: {
                    Label("Save to history", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }

    private func finalScore(_ side: PlayerSide) -> some View {
        VStack {
            Text(state[side].name).font(.headline)
            Text("\(state[side].totalVP)")
                .font(.system(size: 44, weight: .black, design: .rounded))
            Text(session.army(for: side).name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
