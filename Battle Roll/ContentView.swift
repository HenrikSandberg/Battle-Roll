import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showGameSetup = false
    @State private var showHistory = false
    @State private var loadedCount: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // App Header
                VStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)

                    Text("Spearhead Strategist")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Warhammer Age of Sigmar: Spearhead")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Main Menu
                VStack(spacing: 16) {
                    // Start New Game Button
                    Button(action: {
                        showGameSetup = true
                    }) {
                        Label("Start New Game", systemImage: "play.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    // Game History Button
                    Button(action: {
                        showHistory = true
                    }) {
                        Label("Game History", systemImage: "book.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    // Debug: Show loaded army count
                    if loadedCount > 0 {
                        Text("\(loadedCount) spearheads loaded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Footer
                Text("v1.0 - Built for Spearhead")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Battle Roll")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showGameSetup) {
                GameSetupView()
            }
            .sheet(isPresented: $showHistory) {
                GameHistoryView()
            }
            .onAppear {
                // Just update count (spearheads already loaded in AppDelegate)
                loadedCount = SpearheadLoader.shared.getAllSpearheads().count
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
