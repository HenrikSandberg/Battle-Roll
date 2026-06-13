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
    @State private var p1Alliance = ""
    @State private var p1Faction = ""
    @State private var p1ArmyID = ""
    @State private var p1Regiment = ""
    @State private var p1Enhancement = ""

    @State private var p2Name = "Player 2"
    @State private var p2Alliance = ""
    @State private var p2Faction = ""
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
                Section {
                    battlefieldHeader
                } header: {
                    Text("Battlefield")
                }

                Section("Battlefield Setup") {
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

                playerSection(
                    title: "Player 1", playerSide: .one,
                    name: $p1Name,
                    alliance: $p1Alliance, faction: $p1Faction, armyID: $p1ArmyID,
                    regiment: $p1Regiment, enhancement: $p1Enhancement,
                    army: p1Army
                )

                playerSection(
                    title: "Player 2", playerSide: .two,
                    name: $p2Name,
                    alliance: $p2Alliance, faction: $p2Faction, armyID: $p2ArmyID,
                    regiment: $p2Regiment, enhancement: $p2Enhancement,
                    army: p2Army
                )

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
                        HStack {
                            Spacer()
                            Label("Start Battle", systemImage: "flag.fill")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .background(
                            canStart ? SpearheadTheme.fireGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
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
                if p1Alliance.isEmpty, let first = dataStore.grandAlliances.first {
                    p1Alliance = first
                    p1Faction = dataStore.factions(in: first).first ?? ""
                }
                if p2Alliance.isEmpty, let first = dataStore.grandAlliances.first {
                    p2Alliance = first
                    p2Faction = dataStore.factions(in: first).first ?? ""
                }
            }
            .onChange(of: seasonID) { _, newValue in
                realmID = dataStore.season(id: newValue)?.realms.first?.id ?? realmID
            }
        }
    }

    // MARK: - Battlefield header

    @ViewBuilder
    private var battlefieldHeader: some View {
        if let season {
            let gradient = SpearheadTheme.realmGradient(realmID)
            ZStack {
                gradient
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(height: 80)
                VStack(spacing: 4) {
                    Text(season.name)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    if let realm = season.realms.first(where: { $0.id == realmID }) ?? season.realms.first {
                        Text("\(realm.name) – \(realm.subtitle)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
    }

    // MARK: - Player section

    @ViewBuilder
    private func playerSection(title: String, playerSide: PlayerSide,
                               name: Binding<String>,
                               alliance: Binding<String>, faction: Binding<String>, armyID: Binding<String>,
                               regiment: Binding<String>, enhancement: Binding<String>,
                               army: SpearheadArmy?) -> some View {
        Section {
            // Player name + alliance color strip
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(SpearheadTheme.color(for: playerSide))
                    .frame(width: 4)
                TextField("Name", text: name)
                    .font(.body.bold())
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 16))

            // Grand alliance picker with icon
            Picker(selection: alliance) {
                Text("Choose…").tag("")
                ForEach(dataStore.grandAlliances, id: \.self) { ga in
                    Label(ga, systemImage: SpearheadTheme.allianceSymbol(ga)).tag(ga)
                }
            } label: {
                Label("Grand Alliance", systemImage: "shield.lefthalf.filled")
            }
            .onChange(of: alliance.wrappedValue) { _, newGA in
                let factions = dataStore.factions(in: newGA)
                faction.wrappedValue = factions.first ?? ""
                armyID.wrappedValue = ""
                regiment.wrappedValue = ""
                enhancement.wrappedValue = ""
            }

            // Faction picker — only shown after alliance chosen
            if !alliance.wrappedValue.isEmpty {
                let factions = dataStore.factions(in: alliance.wrappedValue)
                Picker(selection: faction) {
                    Text("Choose…").tag("")
                    ForEach(factions, id: \.self) { f in
                        Text(f).tag(f)
                    }
                } label: {
                    Label("Faction", systemImage: "person.3.fill")
                }
                .onChange(of: faction.wrappedValue) { _, _ in
                    armyID.wrappedValue = ""
                    regiment.wrappedValue = ""
                    enhancement.wrappedValue = ""
                }
            }

            // Army picker — only shown after faction chosen
            if !faction.wrappedValue.isEmpty {
                let armies = dataStore.armies(inFaction: faction.wrappedValue)
                Picker(selection: armyID) {
                    Text("Choose…").tag("")
                    ForEach(armies) { a in
                        Text(a.name).tag(a.id)
                    }
                } label: {
                    Label("Spearhead", systemImage: "flag.fill")
                }
                .onChange(of: armyID.wrappedValue) { _, _ in
                    regiment.wrappedValue = ""
                    enhancement.wrappedValue = ""
                }
            }

            // Regiment + enhancement — only shown after army chosen
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

                // Chosen army summary card
                if !armyID.wrappedValue.isEmpty {
                    armySummaryCard(army: army, side: playerSide)
                }
            }
        } header: {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(SpearheadTheme.color(for: playerSide))
                    .frame(width: 3, height: 14)
                Text(title)
            }
        }
    }

    @ViewBuilder
    private func armySummaryCard(army: SpearheadArmy, side: PlayerSide) -> some View {
        HStack(spacing: 12) {
            Image(systemName: SpearheadTheme.allianceSymbol(army.grandAlliance))
                .font(.title3)
                .foregroundStyle(SpearheadTheme.allianceColor(army.grandAlliance))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(army.name)
                    .font(.subheadline.bold())
                Text("\(army.faction) · \(army.grandAlliance)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(army.units.count) warscrolls")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
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
