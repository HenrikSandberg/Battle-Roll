import SwiftUI

/// Reference browser for every loaded Spearhead army.
struct ArmyBrowserView: View {
    @EnvironmentObject private var dataStore: GameDataStore

    var body: some View {
        List {
            ForEach(dataStore.grandAlliances, id: \.self) { alliance in
                Section {
                    ForEach(dataStore.factions(in: alliance), id: \.self) { faction in
                        factionRow(faction: faction, alliance: alliance)
                    }
                } header: {
                    allianceHeader(alliance)
                }
            }
        }
        .navigationTitle("Armies")
    }

    @ViewBuilder
    private func allianceHeader(_ alliance: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: SpearheadTheme.allianceSymbol(alliance))
                .foregroundStyle(SpearheadTheme.allianceColor(alliance))
            Text(alliance)
                .foregroundStyle(SpearheadTheme.allianceColor(alliance))
                .fontWeight(.bold)
        }
        .font(.subheadline)
        .textCase(nil)
    }

    @ViewBuilder
    private func factionRow(faction: String, alliance: String) -> some View {
        let armies = dataStore.armies(inFaction: faction)
        NavigationLink {
            FactionArmyListView(faction: faction, alliance: alliance, armies: armies)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: SpearheadTheme.allianceSymbol(alliance))
                    .font(.callout)
                    .foregroundStyle(SpearheadTheme.allianceColor(alliance))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(faction)
                        .font(.subheadline.bold())
                    Text(armies.count == 1 ? "1 spearhead" : "\(armies.count) spearheads")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct FactionArmyListView: View {
    let faction: String
    let alliance: String
    let armies: [SpearheadArmy]

    var body: some View {
        List(armies) { army in
            NavigationLink {
                ArmyDetailView(army: army)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: SpearheadTheme.allianceSymbol(alliance))
                        .font(.callout)
                        .foregroundStyle(SpearheadTheme.allianceColor(alliance))
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(army.name).font(.subheadline.bold())
                        Text("\(army.units.count) warscrolls")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(faction)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ArmyDetailView: View {
    let army: SpearheadArmy

    var body: some View {
        List {
            // Army header card
            Section {
                armyHeaderCard
            }

            abilityGroup("Battle Traits", army.battleTraits)
            abilityGroup("Regiment Abilities (pick 1)", army.regimentAbilities)
            abilityGroup("Enhancements (pick 1 for your general)", army.enhancements)

            Section("Warscrolls") {
                ForEach(army.units) { scroll in
                    NavigationLink {
                        WarscrollDetailView(scroll: scroll)
                    } label: {
                        HStack {
                            if scroll.isGeneral {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scroll.name).font(.subheadline.bold())
                                Text("M \(scroll.move) · H \(scroll.health) · Sv \(scroll.save) · C \(scroll.control)\(scroll.instances > 1 ? " · ×\(scroll.instances) units" : "")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(army.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var armyHeaderCard: some View {
        HStack(spacing: 14) {
            Image(systemName: SpearheadTheme.allianceSymbol(army.grandAlliance))
                .font(.largeTitle)
                .foregroundStyle(SpearheadTheme.allianceColor(army.grandAlliance))
                .frame(width: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(army.faction)
                    .font(.caption.bold())
                    .foregroundStyle(SpearheadTheme.allianceColor(army.grandAlliance))
                    .textCase(.uppercase)
                    .kerning(0.5)
                Text(army.name)
                    .font(.title3.bold())
                Text("\(army.grandAlliance) · \(army.units.count) warscrolls")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func abilityGroup(_ title: String, _ abilities: [AbilityData]) -> some View {
        if !abilities.isEmpty {
            Section(title) {
                ForEach(abilities) { a in
                    AbilityRow(ability: a, sourceLabel: title, used: false, onToggleUsed: nil)
                }
            }
        }
    }
}

struct WarscrollDetailView: View {
    let scroll: WarscrollData

    var body: some View {
        List {
            Section {
                statBlock
                if scroll.modelsPerUnit > 1 {
                    Text("\(scroll.modelsPerUnit) models per unit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(scroll.keywords.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            weaponSection("Ranged weapons", scroll.rangedWeapons, ranged: true)
            weaponSection("Melee weapons", scroll.meleeWeapons, ranged: false)

            if !scroll.abilities.isEmpty {
                Section("Abilities") {
                    ForEach(scroll.abilities) { a in
                        AbilityRow(ability: a, sourceLabel: scroll.name, used: false, onToggleUsed: nil)
                    }
                }
            }
        }
        .navigationTitle(scroll.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statBlock: some View {
        HStack(spacing: 0) {
            statCell("Move", scroll.move, color: SpearheadTheme.jade)
            statCell("Health", "\(scroll.health)", color: SpearheadTheme.ember)
            statCell("Save", scroll.save, color: SpearheadTheme.steel)
            statCell("Control", "\(scroll.control)", color: SpearheadTheme.gold)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(.vertical, 4)
    }

    private func statCell(_ label: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func weaponSection(_ title: String, _ weapons: [WeaponProfile], ranged: Bool) -> some View {
        if !weapons.isEmpty {
            Section(title) {
                ForEach(weapons) { w in
                    weaponRow(w, ranged: ranged)
                }
            }
        }
    }

    private func weaponRow(_ w: WeaponProfile, ranged: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(w.name)
                .font(.subheadline.bold())
            HStack(spacing: 0) {
                if ranged, let range = w.range {
                    weaponStatCell("Rng", range)
                }
                weaponStatCell("Atk", w.attacks)
                weaponStatCell("Hit", w.hit)
                weaponStatCell("Wnd", w.wound)
                weaponStatCell("Rnd", w.rend)
                weaponStatCell("Dmg", w.damage)
            }
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
            if !w.abilities.isEmpty {
                Text(w.abilities.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.purple)
            }
        }
        .padding(.vertical, 2)
    }

    private func weaponStatCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
    }

    private func weaponStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.caption.bold().monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
