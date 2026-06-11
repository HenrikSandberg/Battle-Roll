import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dataStore: GameDataStore
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var activeSession: BattleSession?
    @State private var showSetup = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 52))
                            .foregroundStyle(.tint)
                        Text("Spearhead Strategist")
                            .font(.title.bold())
                        Text("\(dataStore.armies.count) armies · \(dataStore.seasons.count) season pack\(dataStore.seasons.count == 1 ? "" : "s") loaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                Section {
                    Button {
                        showSetup = true
                    } label: {
                        Label("New Battle", systemImage: "play.circle.fill")
                            .font(.headline)
                    }

                    if let saved = sessionStore.savedBattle, !saved.isOver {
                        Button {
                            resume(saved)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("Resume Battle", systemImage: "arrow.uturn.forward.circle.fill")
                                    .font(.headline)
                                Text("Round \(saved.round) · \(saved[.one].name) \(saved[.one].totalVP)–\(saved[.two].totalVP) \(saved[.two].name)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    NavigationLink {
                        ArmyBrowserView()
                    } label: {
                        Label("Army Reference", systemImage: "book.closed")
                    }
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("Game History", systemImage: "clock.arrow.circlepath")
                    }
                }

                if !dataStore.loadErrors.isEmpty {
                    Section("Data problems") {
                        ForEach(dataStore.loadErrors, id: \.self) { err in
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Battle Roll")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSetup) {
                SetupView { session in
                    showSetup = false
                    start(session)
                }
            }
            .fullScreenCover(item: $activeSession) { session in
                BattleView(session: session) {
                    activeSession = nil
                }
            }
        }
    }

    private func start(_ session: BattleSession) {
        session.onAutosave = { [weak sessionStore] state in
            sessionStore?.saveCurrent(state)
        }
        sessionStore.saveCurrent(session.state)
        activeSession = session
    }

    private func resume(_ state: BattleState) {
        guard let season = dataStore.season(id: state.seasonID),
              let a1 = dataStore.army(id: state[.one].armyID),
              let a2 = dataStore.army(id: state[.two].armyID) else { return }
        let session = BattleSession(state: state, season: season,
                                    armies: [PlayerSide.one.rawValue: a1, PlayerSide.two.rawValue: a2])
        start(session)
    }
}

extension BattleSession: Identifiable {}
