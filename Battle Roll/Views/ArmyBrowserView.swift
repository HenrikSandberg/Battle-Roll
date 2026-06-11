import SwiftUI

/// Reference browser for every loaded Spearhead army.
struct ArmyBrowserView: View {
    @EnvironmentObject private var dataStore: GameDataStore

    var body: some View {
        List {
            ForEach(dataStore.factions, id: \.self) { faction in
                Section(faction) {
                    ForEach(dataStore.armies.filter { $0.faction == faction }) { army in
                        NavigationLink {
                            ArmyDetailView(army: army)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(army.name).font(.subheadline.bold())
                                Text("\(army.units.count) warscrolls · \(army.grandAlliance)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Armies")
    }
}

struct ArmyDetailView: View {
    let army: SpearheadArmy

    var body: some View {
        List {
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
                HStack(spacing: 16) {
                    stat("Move", scroll.move)
                    stat("Health", "\(scroll.health)")
                    stat("Save", scroll.save)
                    stat("Control", "\(scroll.control)")
                }
                .frame(maxWidth: .infinity)
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
                    VStack(alignment: .leading, spacing: 3) {
                        Text(w.name).font(.subheadline.bold())
                        HStack(spacing: 12) {
                            if ranged, let range = w.range { weaponStat("Rng", range) }
                            weaponStat("Atk", w.attacks)
                            weaponStat("Hit", w.hit)
                            weaponStat("Wnd", w.wound)
                            weaponStat("Rnd", w.rend)
                            weaponStat("Dmg", w.damage)
                        }
                        if !w.abilities.isEmpty {
                            Text(w.abilities.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.purple)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func weaponStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.caption.bold().monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
