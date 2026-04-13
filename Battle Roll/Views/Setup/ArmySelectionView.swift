import SwiftUI
import CoreData

struct ArmySelectionView: View {
    @Binding var selectedArmy: String
    @Binding var selectedSpearhead: String
    let title: String

    @State private var availableFactions: [String] = []
    @State private var availableSpearheads: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(title)
                    .font(.headline)

                // Army Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Faction")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if availableFactions.isEmpty {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Loading factions...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                            ForEach(availableFactions, id: \.self) { faction in
                                Button(action: {
                                    selectedArmy = faction
                                    selectedSpearhead = "" // Reset spearhead when faction changes
                                    loadSpearheadsForFaction(faction)
                                }) {
                                    Text(faction)
                                        .font(.body)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(selectedArmy == faction ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedArmy == faction ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                // Spearhead Selection (only show when faction is selected)
                if !selectedArmy.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Spearhead")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if availableSpearheads.isEmpty {
                            Text("No spearheads available for this faction")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                                ForEach(availableSpearheads, id: \.self) { spearhead in
                                    Button(action: {
                                        selectedSpearhead = spearhead
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(spearhead)
                                                .font(.body)
                                                .fontWeight(selectedSpearhead == spearhead ? .semibold : .regular)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(selectedSpearhead == spearhead ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedSpearhead == spearhead ? .white : .primary)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            loadAvailableFactions()
        }
    }

    private func loadAvailableFactions() {
        print("🔍 ArmySelectionView: Loading available factions...")

        // Spearheads already loaded in AppDelegate, just fetch them
        let allSpearheads = SpearheadLoader.shared.getAllSpearheads()
        print("📊 Found \(allSpearheads.count) total spearheads")

        let factions = Array(Set(allSpearheads.map { $0.faction })).sorted()
        availableFactions = factions

        print("🎯 Available factions: \(factions)")

        // If a faction is already selected, load its spearheads
        if !selectedArmy.isEmpty {
            loadSpearheadsForFaction(selectedArmy)
        }
    }

    private func loadSpearheadsForFaction(_ faction: String) {
        availableSpearheads = SpearheadLoader.shared.getSpearheads(forFaction: faction)
    }
}

#Preview {
    ArmySelectionView(
        selectedArmy: .constant(""),
        selectedSpearhead: .constant(""),
        title: "Select Your Army"
    )
}
