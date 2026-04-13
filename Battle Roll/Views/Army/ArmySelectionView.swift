import SwiftUI
import CoreData

/// Army selection screen - choose which Spearhead army to use
struct ArmySelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SpearheadArmy.name, ascending: true)],
        animation: .default)
    private var armies: FetchedResults<SpearheadArmy>

    @State private var availableArmies: [SpearheadArmyData] = []
    @State private var showImportSheet = false
    @Binding var selectedArmy: SpearheadArmy?

    var body: some View {
        NavigationView {
            List {
                // Already imported armies (from Core Data)
                if !armies.isEmpty {
                    Section("My Armies") {
                        ForEach(armies) { army in
                            ArmyListRow(army: army)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedArmy = army
                                    dismiss()
                                }
                        }
                        .onDelete(perform: deleteArmies)
                    }
                }

                // Available armies to import
                if !availableArmies.isEmpty {
                    Section("Import New Army") {
                        ForEach(availableArmies) { armyData in
                            Button(action: {
                                importArmy(armyData)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(armyData.name)
                                            .font(.headline)
                                        Text(armyData.faction)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                // Import from PDFs
                Section {
                    Button(action: {
                        showImportSheet = true
                    }) {
                        Label("Import from PDF", systemImage: "doc.text.fill")
                    }
                }
            }
            .navigationTitle("Select Army")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImportSheet) {
                PDFImportView()
            }
            .onAppear {
                loadAvailableArmies()
            }
        }
    }

    private func loadAvailableArmies() {
        // Load sample armies (replace with JSON loader later)
        availableArmies = SpearheadArmyData.allSampleArmies

        // Try to load from JSON
        let jsonArmies = ArmyLoader.shared.loadArmiesFromJSON()
        if !jsonArmies.isEmpty {
            availableArmies = jsonArmies
        }
    }

    private func importArmy(_ armyData: SpearheadArmyData) {
        ArmyLoader.shared.importArmyToCoreData(armyData, context: viewContext)
        loadAvailableArmies()
    }

    private func deleteArmies(offsets: IndexSet) {
        withAnimation {
            offsets.map { armies[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Error deleting: \(error)")
            }
        }
    }
}

// MARK: - Army List Row

struct ArmyListRow: View {
    let army: SpearheadArmy

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Army name
            Text(army.name ?? "Unknown Army")
                .font(.headline)

            // Faction
            if let faction = army.faction {
                Text(faction)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Unit count
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.caption)
                Text("\(army.warscrolls?.count ?? 0) Units")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let trait = army.traitName {
                    Spacer()
                    Text(trait)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PDF Import View

struct PDFImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pdfURLs: [URL] = []
    @State private var selectedPDF: URL?
    @State private var extractedText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if pdfURLs.isEmpty {
                    ContentUnavailableView(
                        "No PDFs Found",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Add PDF files to the PDFs folder in Xcode")
                    )
                } else {
                    List {
                        Section("Available PDFs") {
                            ForEach(pdfURLs, id: \.self) { url in
                                Button(action: {
                                    selectedPDF = url
                                    extractPDF(url)
                                }) {
                                    HStack {
                                        Image(systemName: "doc.fill")
                                            .foregroundColor(.red)
                                        Text(url.lastPathComponent)
                                        Spacer()
                                        if selectedPDF == url {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }

                        if !extractedText.isEmpty {
                            Section("Extracted Text (Preview)") {
                                Text(extractedText.prefix(500) + "...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Import PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        // TODO: Parse and import
                        dismiss()
                    }
                    .disabled(selectedPDF == nil)
                }
            }
            .onAppear {
                pdfURLs = ArmyLoader.shared.findArmyPDFs()
            }
        }
    }

    private func extractPDF(_ url: URL) {
        if let text = ArmyLoader.shared.extractTextFromPDF(url: url) {
            extractedText = text
        }
    }
}

// MARK: - Preview

struct ArmySelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ArmySelectionView(selectedArmy: .constant(nil))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
