import SwiftUI
import CoreData

struct GameHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GameRecord.date, ascending: false)],
        animation: .default)
    private var games: FetchedResults<GameRecord>

    var body: some View {
        NavigationStack {
            List {
                if games.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No games played yet")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Start a new game to track your battles")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(games) { game in
                        GameHistoryRow(game: game)
                    }
                    .onDelete(perform: deleteGames)
                }
            }
            .navigationTitle("Game History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func deleteGames(offsets: IndexSet) {
        withAnimation {
            offsets.map { games[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Error deleting games: \(error)")
            }
        }
    }
}

struct GameHistoryRow: View {
    @ObservedObject var game: GameRecord

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormatter.string(from: game.date ?? Date()))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(game.season ?? "Unknown Season")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                // Result Badge
                HStack(spacing: 5) {
                    if game.didIWin {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("Victory")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else if game.myFinalScore == game.opponentFinalScore {
                        Image(systemName: "equal.circle.fill")
                            .foregroundColor(.gray)
                        Text("Draw")
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Defeat")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }

            Divider()

            // Score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Army")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(game.myArmyName ?? "Unknown")")
                        .font(.caption)
                    Text("\(game.mySpearheadName ?? "Unknown")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(game.myFinalScore)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(":")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text("\(game.opponentFinalScore)")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Opponent")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(game.opponentArmyName ?? "Unknown")")
                        .font(.caption)
                    Text("\(game.opponentSpearheadName ?? "Unknown")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    GameHistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
