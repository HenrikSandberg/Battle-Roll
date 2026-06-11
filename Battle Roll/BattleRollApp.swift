import SwiftUI

@main
struct BattleRollApp: App {
    @StateObject private var dataStore = GameDataStore()
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(dataStore)
                .environmentObject(sessionStore)
        }
    }
}
