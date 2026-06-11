import Foundation

/// Loads bundled army and season JSON. All armies live in Resources/Data/Armies,
/// all season packs in Resources/Data/Seasons; both folders are bundled flat.
final class GameDataStore: ObservableObject {
    @Published private(set) var armies: [SpearheadArmy] = []
    @Published private(set) var seasons: [SeasonPack] = []
    @Published private(set) var loadErrors: [String] = []

    init() {
        load()
    }

    func load() {
        let decoder = JSONDecoder()
        var loadedArmies: [SpearheadArmy] = []
        var loadedSeasons: [SeasonPack] = []
        var errors: [String] = []

        for url in jsonResources() {
            do {
                let data = try Data(contentsOf: url)
                if let army = try? decoder.decode(SpearheadArmy.self, from: data), !army.units.isEmpty {
                    loadedArmies.append(army)
                } else if let season = try? decoder.decode(SeasonPack.self, from: data) {
                    loadedSeasons.append(season)
                } else {
                    // Decode once more as army to surface the real error message.
                    _ = try decoder.decode(SpearheadArmy.self, from: data)
                }
            } catch {
                errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        armies = loadedArmies.sorted { ($0.faction, $0.name) < ($1.faction, $1.name) }
        seasons = loadedSeasons.sorted { $0.name < $1.name }
        loadErrors = errors
    }

    private func jsonResources() -> [URL] {
        var urls: [URL] = []
        // Folder-reference layout (Resources/Data preserved in bundle).
        for sub in ["Data/Armies", "Data/Seasons", "Armies", "Seasons"] {
            if let found = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: sub) {
                urls.append(contentsOf: found)
            }
        }
        // Flat layout (Xcode group resources end up at bundle root).
        if let flat = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) {
            urls.append(contentsOf: flat)
        }
        // De-duplicate by file name.
        var seen = Set<String>()
        return urls.filter { seen.insert($0.lastPathComponent).inserted }
    }

    func army(id: String) -> SpearheadArmy? {
        armies.first { $0.id == id }
    }

    func season(id: String) -> SeasonPack? {
        seasons.first { $0.id == id }
    }

    var factions: [String] {
        Array(Set(armies.map(\.faction))).sorted()
    }
}
