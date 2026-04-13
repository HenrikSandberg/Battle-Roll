# Army System Integration Guide

## 🎯 Quick Integration Steps

I've built a complete army management system for your app. Here's how to integrate it:

## Step 1: Add Files to Xcode

All files have been created. Make sure they're added to your Xcode project:

### Models
- `Battle Roll/Models/Army/ArmyData.swift` ✅

### Services
- `Battle Roll/Services/ArmyLoader.swift` ✅

### Views
- `Battle Roll/Views/Army/ArmySelectionView.swift` ✅
- `Battle Roll/Views/Army/ArmyDetailView.swift` ✅

### Resources
- `SampleArmies.json` - Add this to Xcode project

## Step 2: Add Sample JSON to Xcode

1. **In Xcode**, right-click on "Battle Roll" folder
2. **Select "New Group"**, name it `Resources`
3. **Right-click `Resources`**, select "Add Files to 'Battle Roll'..."
4. **Select `SampleArmies.json`**
5. **Check**:
   - ✅ "Copy items if needed"
   - ✅ "Battle Roll" target
6. **Click Add**

## Step 3: Update ContentView

Replace your `ContentView.swift` with this integrated version:

```swift
import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var phaseManager: PhaseManager
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedArmy: SpearheadArmy?
    @State private var showArmySelection = false
    @State private var showBattle = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Header
                VStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)

                    Text("Spearhead Strategist")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Phase Engine Active ⚡")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }

                Divider()

                // Army Selection Section
                VStack(spacing: 16) {
                    Text("Select Your Army")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let army = selectedArmy {
                        // Show selected army
                        Button(action: {
                            showArmySelection = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(army.name ?? "Unknown Army")
                                        .font(.headline)
                                    Text(army.faction ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }

                        // View Army Details
                        NavigationLink(destination: ArmyDetailView(army: army)) {
                            Label("View Warscrolls", systemImage: "doc.text.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        // Start Battle
                        Button(action: {
                            showBattle = true
                        }) {
                            Label("Start Battle", systemImage: "bolt.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                    } else {
                        // No army selected
                        Button(action: {
                            showArmySelection = true
                        }) {
                            Label("Choose Army", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }

                Spacer()

                // Footer
                Text("Army System v1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Battle Roll")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showArmySelection) {
                ArmySelectionView(selectedArmy: $selectedArmy)
            }
            .sheet(isPresented: $showBattle) {
                if let army = selectedArmy {
                    PhaseEngineMainView()
                        .environmentObject(gameState)
                        .environmentObject(phaseManager)
                }
            }
        }
        .onAppear {
            loadArmyIfNeeded()
        }
    }

    private func loadArmyIfNeeded() {
        // Auto-select the first army if available
        let fetchRequest: NSFetchRequest<SpearheadArmy> = SpearheadArmy.fetchRequest()
        fetchRequest.fetchLimit = 1

        do {
            if let firstArmy = try viewContext.fetch(fetchRequest).first {
                selectedArmy = firstArmy
            }
        } catch {
            print("Error fetching army: \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        let phaseManager = PhaseManager(gameState: gameState)

        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(gameState)
            .environmentObject(phaseManager)
    }
}
```

## Step 4: Test the Import System

1. **Build and run** the app (`Cmd + R`)
2. **Tap "Choose Army"**
3. **Tap "Import New Army"** section
4. **Select "Stormcast Eternals - Hammers of Sigmar"**
5. **Tap army to import**
6. **Army is now in "My Armies"!**

## Step 5: View Your Army

1. **Select the army** from "My Armies"
2. **Tap "View Warscrolls"**
3. **See all units** with:
   - Full stats
   - Weapon profiles
   - Abilities by phase

## 🎯 How the System Works

### Data Flow

```
PDFs (in project)
    ↓
SampleArmies.json
    ↓
ArmyLoader.loadArmiesFromJSON()
    ↓
[SpearheadArmyData] (Swift structs)
    ↓
ArmyLoader.importArmyToCoreData()
    ↓
Core Data (SpearheadArmy entities)
    ↓
ArmySelectionView → ArmyDetailView
    ↓
PhaseEngineMainView (battle mode)
```

### Key Components

1. **ArmyData.swift** - Swift structs for JSON
2. **ArmyLoader.swift** - Imports JSON → Core Data
3. **ArmySelectionView** - Browse and import
4. **ArmyDetailView** - View warscrolls
5. **PhaseEngineMainView** - Use in battle

## 📱 User Workflow

### First Time Setup
1. Launch app
2. Choose Army
3. Import from list
4. View warscrolls

### Before Each Battle
1. Select army
2. View warscrolls (refresh memory)
3. Start Battle
4. Phase Engine filters abilities automatically

### During Battle
1. Advance through phases
2. See only relevant abilities
3. Mark limited abilities as used
4. Track scores

## 🔧 Customization Options

### Add More Armies

Create new JSON files following the template:
- `StormcastEternals.json`
- `OrrukWarclans.json`
- `Nighthaunt.json`
- etc.

Place in `Resources/` folder and add to Xcode.

### Modify Army Selection UI

Edit `ArmySelectionView.swift`:
- Change list style
- Add search bar
- Add faction filters
- Add army artwork

### Enhance Army Detail View

Edit `ArmyDetailView.swift`:
- Add unit images
- Show weapon range indicators
- Color-code abilities by phase
- Add notes/tactics section

## 🚀 Advanced Features (Future)

### PDF Auto-Import
The `ArmyLoader` has PDF text extraction. To enable:

1. Add PDFs to `Resources/PDFs/` folder
2. Tap "Import from PDF" in app
3. Review extracted text
4. Create parser for your PDF format

### Custom Parser Example

```swift
func parseArmyFromPDF(url: URL) -> SpearheadArmyData? {
    guard let text = extractTextFromPDF(url: url) else { return nil }

    // Example: Extract army name
    let lines = text.components(separatedBy: "\n")
    guard let armyName = lines.first else { return nil }

    // Parse units (depends on PDF format)
    // You'll need to customize this based on your PDFs

    return SpearheadArmyData(
        name: armyName,
        faction: "Extracted Faction",
        units: []  // Parse from PDF
    )
}
```

## 📊 Data Structure Overview

```
SpearheadArmyData
├── id: UUID
├── name: String
├── faction: String
├── armyTrait: ArmyTrait?
│   ├── name
│   ├── description
│   └── phase
└── units: [UnitData]
    ├── UnitData
    │   ├── id, name, stats (move, health, control, save)
    │   ├── weapons: [WeaponData]
    │   │   └── attacks, hit, wound, rend, damage, range
    │   └── abilities: [AbilityData]
    │       └── name, description, phase, timing, usageLimit
    └── ...more units
```

## ✅ Checklist

- [ ] Add all Swift files to Xcode project
- [ ] Add `SampleArmies.json` to Resources folder
- [ ] Update `ContentView.swift` with integrated version
- [ ] Build project (`Cmd + B`)
- [ ] Run on device/simulator (`Cmd + R`)
- [ ] Test army import
- [ ] View army details
- [ ] Start a battle

## 🎯 What You Can Do Now

### Immediate
✅ Import sample Stormcast army
✅ View all warscrolls and rules
✅ Use in Phase Engine battle mode

### This Week
📝 Create JSON for your PDF armies
📝 Import all your Spearhead armies
📝 Test abilities during practice game

### Future
🚀 Add army artwork
🚀 Create favorite armies list
🚀 Add battle tactics tracking per army
🚀 Export/share army lists

## 🆘 Troubleshooting

### "Cannot find 'SpearheadArmyData'"
→ Make sure `ArmyData.swift` is added to target

### "Failed to load armies from JSON"
→ Check JSON syntax with JSONLint.com
→ Verify file is in Xcode project
→ Check target membership

### Armies not appearing in list
→ Check Xcode console for errors
→ Verify JSON is valid
→ Make sure file is in Resources

### Phase Engine not showing abilities
→ Ensure abilities have correct phase names
→ Check ability.phase matches GamePhase enum

---

**You now have a complete army management system!** Import your PDFs as JSON and start battling! 🎲⚔️
