import SwiftUI

/// Pre-battle configuration following the official pre-battle sequence:
/// season → realm side → armies → regiment ability + enhancement → attacker.
struct SetupView: View {
    @EnvironmentObject private var dataStore: GameDataStore
    @Environment(\.dismiss) private var dismiss
    let onStart: (BattleSession) -> Void

    @State private var seasonID = ""
    @State private var realmID = ""
    @State private var desolation = false
    @State private var attacker: PlayerSide = .one

    @State private var p1Name = "Player 1"
    @State private var p1ArmyID = ""
    @State private var p1Regiment = ""
    @State private var p1Enhancement = ""

    @State private var p2Name = "Player 2"
    @State private var p2ArmyID = ""
    @State private var p2Regiment = ""
    @State private var p2Enhancement = ""

    private var season: SeasonPack? { dataStore.season(id: seasonID) ?? dataStore.seasons.first }
    private var p1Army: SpearheadArmy? { dataStore.army(id: p1ArmyID) }
    private var p2Army: SpearheadArmy? { dataStore.army(id: p2ArmyID) }

    private var canStart: Bool {
        season != nil && p1Army != nil && p2Army != nil
            && !p1Regiment.isEmpty && !p1Enhancement.isEmpty
            && !p2Regiment.isEmpty && !p2Enhancement.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Battlefield") {
                    Picker("Season pack", selection: $seasonID) {
                        ForEach(dataStore.seasons) { s in
                            Text(s.name).tag(s.id)
                        }
                    }
                    if let season {
                        Picker("Realm side", selection: $realmID) {
                            ForEach(season.realms) { r in
                                Text("\(r.name) – \(r.subtitle)").tag(r.id)
                            }
                        }
                        if season.modules.contains(where: { $0.id == "desolation" }) {
                            Toggle("Desolation of the Mortal Realms module", isOn: $desolation)
                        }
                    }
                }

                playerSection(title: "Player 1", name: $p1Name, armyID: $p1ArmyID,
                              regiment: $p1Regiment, enhancement: $p1Enhancement, army: p1Army)
                playerSection(title: "Player 2", name: $p2Name, armyID: $p2ArmyID,
                              regiment: $p2Regiment, enhancement: $p2Enhancement, army: p2Army)

                Section {
                    Picker("Attacker (won the roll-off)", selection: $attacker) {
                        Text(p1Name).tag(PlayerSide.one)
                        Text(p2Name).tag(PlayerSide.two)
                    }
                } footer: {
                    Text("The attacker picks their regiment ability and enhancement first, then the defender. The defender chooses the realm side, deployment map and territory, and sets up terrain first.")
                }

                Section {
                    Button {
                        startBattle()
                    } label: {
                        Label("Start Battle", systemImage: "flag.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canStart)
                }
            }
            .navigationTitle("New Battle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if seasonID.isEmpty, let s = dataStore.seasons.first {
                    seasonID = s.id
                    realmID = s.realms.first?.id ?? ""
                }
            }
            .onChange(of: seasonID) { _, newValue in
                realmID = dataStore.season(id: newValue)?.realms.first?.id ?? realmID
            }
        }
    }

    @ViewBuilder
    private func playerSection(title: String, name: Binding<String>, armyID: Binding<String>,
                               regiment: Binding<String>, enhancement: Binding<String>,
                               army: SpearheadArmy?) -> some View {
        Section(title) {
            TextField("Name", text: name)
            Picker("Spearhead army", selection: armyID) {
                Text("Choose…").tag("")
                ForEach(dataStore.armies) { a in
                    Text("\(a.faction): \(a.name)").tag(a.id)
                }
            }
            if let army {
                Picker("Regiment ability", selection: regiment) {
                    Text("Choose…").tag("")
                    ForEach(army.regimentAbilities) { r in
                        Text(r.name).tag(r.name)
                    }
                }
                Picker("Enhancement", selection: enhancement) {
                    Text("Choose…").tag("")
                    ForEach(army.enhancements) { e in
                        Text(e.name).tag(e.name)
                    }
                }
            }
        }
        .onChange(of: armyID.wrappedValue) { _, _ in
            regiment.wrappedValue = ""
            enhancement.wrappedValue = ""
        }
    }

    private func startBattle() {
        guard let season, let p1Army, let p2Army else { return }
        let session = BattleSession.newBattle(
            season: season,
            realmID: realmID.isEmpty ? (season.realms.first?.id ?? "") : realmID,
            desolation: desolation,
            attacker: attacker,
            one: (p1Name, p1Army, p1Regiment, p1Enhancement),
            two: (p2Name, p2Army, p2Regiment, p2Enhancement)
        )
        onStart(session)
    }
}
