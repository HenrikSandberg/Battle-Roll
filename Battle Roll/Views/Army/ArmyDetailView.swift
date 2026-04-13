import SwiftUI

/// Displays the full warscrolls and rules for a selected army
struct ArmyDetailView: View {
    let army: SpearheadArmy
    @State private var selectedUnit: Warscroll?

    var units: [Warscroll] {
        let warscrollSet = army.warscrolls as? Set<Warscroll> ?? []
        return warscrollSet.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Army Header
                ArmyHeaderCard(army: army)

                // Army Trait
                if let traitName = army.traitName, let traitDesc = army.traitDescription {
                    ArmyTraitCard(name: traitName, description: traitDesc)
                }

                // Units List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Units (\(units.count))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    ForEach(units) { unit in
                        Button(action: {
                            selectedUnit = unit
                        }) {
                            UnitCard(unit: unit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(army.name ?? "Army")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedUnit) { unit in
            UnitDetailSheet(unit: unit)
        }
    }
}

// MARK: - Army Header Card

struct ArmyHeaderCard: View {
    let army: SpearheadArmy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Faction
            if let faction = army.faction {
                Text(faction)
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            // Army name
            Text(army.name ?? "Unknown Army")
                .font(.title)
                .fontWeight(.bold)

            // Stats summary
            HStack(spacing: 20) {
                StatPill(icon: "person.3.fill", value: "\(army.warscrolls?.count ?? 0)", label: "Units")

                if let warscrolls = army.warscrolls as? Set<Warscroll> {
                    let abilityCount = warscrolls.reduce(0) { $0 + ($1.abilities?.count ?? 0) }
                    StatPill(icon: "bolt.fill", value: "\(abilityCount)", label: "Abilities")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Army Trait Card

struct ArmyTraitCard: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Army Trait")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(name)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Unit Card

struct UnitCard: View {
    let unit: Warscroll

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Unit name and type
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(unit.name ?? "Unknown")
                        .font(.headline)
                    if let type = unit.unitType {
                        Text(type)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }

            // Stats row
            HStack(spacing: 16) {
                UnitStatBadge(icon: "figure.walk", value: "\(unit.move)\"", label: "Move")
                UnitStatBadge(icon: "heart.fill", value: "\(unit.health)", label: "Health")
                UnitStatBadge(icon: "shield.fill", value: "\(unit.save)+", label: "Save")
                UnitStatBadge(icon: "person.fill", value: "\(unit.control)", label: "Control")
            }

            // Ability count
            if let abilities = unit.abilities, abilities.count > 0 {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("\(abilities.count) Abilities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct UnitStatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.blue)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Unit Detail Sheet

struct UnitDetailSheet: View {
    let unit: Warscroll
    @Environment(\.dismiss) private var dismiss

    var abilities: [Ability] {
        let abilitySet = unit.abilities as? Set<Ability> ?? []
        return abilitySet.sorted { $0.sortOrder < $1.sortOrder }
    }

    var weapons: [Weapon] {
        let weaponSet = unit.weapons as? Set<Weapon> ?? []
        return weaponSet.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Stats section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Characteristics")
                            .font(.headline)

                        HStack(spacing: 20) {
                            CharacteristicItem(label: "Move", value: "\(unit.move)\"")
                            CharacteristicItem(label: "Health", value: "\(unit.health)")
                            CharacteristicItem(label: "Save", value: "\(unit.save)+")
                            CharacteristicItem(label: "Control", value: "\(unit.control)")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Weapons section
                    if !weapons.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weapons")
                                .font(.headline)

                            ForEach(weapons) { weapon in
                                WeaponRow(weapon: weapon)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Abilities section
                    if !abilities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Abilities")
                                .font(.headline)

                            ForEach(abilities) { ability in
                                AbilityDetailCard(ability: ability)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(unit.name ?? "Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CharacteristicItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeaponRow: View {
    let weapon: Weapon

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(weapon.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(weapon.isMelee ? "Melee" : "Range \(weapon.range ?? 0)\"")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(weapon.isMelee ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }

            HStack(spacing: 12) {
                WeaponStat(label: "Atk", value: weapon.attacks ?? "")
                WeaponStat(label: "Hit", value: "\(weapon.hit)+")
                WeaponStat(label: "Wnd", value: "\(weapon.wound)+")
                WeaponStat(label: "Rnd", value: "\(weapon.rend)")
                WeaponStat(label: "Dmg", value: weapon.damage ?? "")
            }

            if let abilities = weapon.abilities, !abilities.isEmpty {
                Text(abilities)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct WeaponStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct AbilityDetailCard: View {
    let ability: Ability

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ability.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if let badge = ability.badgeText {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            HStack {
                if let phase = ability.phase {
                    Label(phase, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let timing = ability.timing {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(timing)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(ability.abilityDescription ?? "")
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct ArmyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleArmy = SpearheadArmy(context: context)
        sampleArmy.name = "Stormcast Eternals"
        sampleArmy.faction = "Stormcast Eternals"

        return NavigationView {
            ArmyDetailView(army: sampleArmy)
        }
    }
}
