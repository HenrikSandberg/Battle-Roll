import Foundation

/// Saves the in-progress battle (for resume) and finished games (history) as JSON
/// in the app's Documents directory.
final class SessionStore: ObservableObject {
    @Published private(set) var history: [GameRecord] = []
    @Published private(set) var savedBattle: BattleState?

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private var currentURL: URL { documents.appendingPathComponent("currentBattle.json") }
    private var historyURL: URL { documents.appendingPathComponent("gameHistory.json") }

    init() {
        savedBattle = try? decoder.decode(BattleState.self, from: Data(contentsOf: currentURL))
        history = (try? decoder.decode([GameRecord].self, from: Data(contentsOf: historyURL))) ?? []
    }

    func saveCurrent(_ state: BattleState) {
        savedBattle = state
        if let data = try? encoder.encode(state) {
            try? data.write(to: currentURL, options: .atomic)
        }
    }

    func clearCurrent() {
        savedBattle = nil
        try? FileManager.default.removeItem(at: currentURL)
    }

    func finishGame(_ session: BattleSession) {
        let s = session.state
        let record = GameRecord(
            date: Date(),
            seasonName: session.season.name,
            realmName: session.realm.name,
            playerOneName: s[.one].name,
            playerOneArmy: session.army(for: .one).name,
            playerOneVP: s[.one].totalVP,
            playerTwoName: s[.two].name,
            playerTwoArmy: session.army(for: .two).name,
            playerTwoVP: s[.two].totalVP
        )
        history.insert(record, at: 0)
        if let data = try? encoder.encode(history) {
            try? data.write(to: historyURL, options: .atomic)
        }
        clearCurrent()
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        if let data = try? encoder.encode(history) {
            try? data.write(to: historyURL, options: .atomic)
        }
    }
}
