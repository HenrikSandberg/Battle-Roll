import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        List {
            if sessionStore.history.isEmpty {
                ContentUnavailableView("No battles yet",
                                       systemImage: "clock.arrow.circlepath",
                                       description: Text("Finished battles appear here."))
            }
            ForEach(sessionStore.history) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.resultText)
                        .font(.subheadline.bold())
                    Text("\(record.playerOneName) (\(record.playerOneArmy)) vs \(record.playerTwoName) (\(record.playerTwoArmy))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(record.seasonName) · \(record.realmName) · \(record.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
            .onDelete { offsets in
                sessionStore.deleteHistory(at: offsets)
            }
        }
        .navigationTitle("Game History")
    }
}
