import SwiftUI

struct SeasonSelectionView: View {
    @Binding var selectedSeason: String
    @Binding var selectedBoardLayout: String

    // Placeholder data - will be loaded from JSON/Core Data
    private let seasons = [
        "Fire and Jade",
        "Sand and Bone"
    ]

    private let boardLayouts = [
        "Layout A - Standard",
        "Layout B - Dense Terrain",
        "Layout C - Open Field",
        "Layout D - Narrow Pass"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Season Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Season")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(seasons, id: \.self) { season in
                        Button(action: {
                            selectedSeason = season
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(season)
                                        .font(.headline)
                                    Text("Includes unique Twists and Battle Tactics")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedSeason == season {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(selectedSeason == season ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                // Board Layout Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Board Layout")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                        ForEach(boardLayouts, id: \.self) { layout in
                            Button(action: {
                                selectedBoardLayout = layout
                            }) {
                                Text(layout)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(selectedBoardLayout == layout ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedBoardLayout == layout ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    SeasonSelectionView(
        selectedSeason: .constant(""),
        selectedBoardLayout: .constant("")
    )
}
