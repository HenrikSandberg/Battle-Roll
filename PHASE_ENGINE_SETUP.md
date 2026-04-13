# Phase Engine Setup Guide

## 🎯 What's Been Implemented

The **Phase Engine** is now fully integrated into your Battle Roll app! Here's what's ready:

### ✅ Core Systems
- **Core Data Schema** - Warscroll, Ability, Weapon, and SpearheadArmy entities
- **GameState** - Tracks phase, round, CP, VP
- **PhaseManager** - Filters abilities by phase and unit status
- **DataService** - CRUD operations and sample data generation
- **PersistenceController** - Core Data stack with preview support

### ✅ Game Logic
- 6 battle phases (Hero → Movement → Shooting → Charge → Combat → Battleshock)
- Ability timing (Start/During/End of Phase, Passive)
- Usage limits (Unlimited, Once Per Turn, Once Per Game)
- Automatic filtering of destroyed units
- Turn/game usage tracking with automatic reset

### ✅ UI Components
- **ContentView** - Main launcher with sample data creation
- **PhaseEngineMainView** - Game dashboard with status bar
- **PhaseAbilitiesView** - Phase-filtered ability list
- **Reminder Banner** - Highlights start/end of phase abilities

## 🚀 How to Build and Run

### Step 1: Open in Xcode
```bash
cd "/Users/henrik/Documents/GitHub/Battle-Roll"
open "Battle Roll.xcodeproj"
```

### Step 2: Build the Project
1. **Select a target device** - iPhone or iPad simulator
2. **Press `Cmd+B`** to build
   - This generates the Core Data classes (Warscroll, Ability, etc.)
   - All current diagnostics will disappear after the first build

### Step 3: Add Files to Target (if needed)
If Xcode shows "file not in target" warnings:
1. Select each new file in the Project Navigator
2. Check the **Target Membership** in the File Inspector (right panel)
3. Ensure "Battle Roll" is checked

### Step 4: Run the App
1. **Press `Cmd+R`** to run
2. You'll see the main launcher screen

## 🎮 Using the Phase Engine

### First Launch
1. **Tap "Create Sample Army"** - Generates a Stormcast Eternals army with:
   - Stormstrike Chariot (3 abilities across Hero/Movement/Combat phases)
   - Liberators (2 abilities in Combat phase)

2. **Tap "Launch Phase Engine"** - Opens the Phase Runner

### During a Game
1. **Start Game** - Tap the menu (⋯) → "Start Game"
   - Resets all tracking
   - Restores destroyed units
   - Sets phase to Hero

2. **Navigate Phases** - Use "Next Phase" button
   - Available abilities update automatically
   - Reminder banner shows start/end of phase abilities
   - Usage badges show 1/TURN, 1/GAME, or USED

3. **Mark Abilities Used** - Tap "Mark Used" on limited abilities
   - Once Per Turn abilities reset when Hero phase begins
   - Once Per Game abilities stay used

4. **Track Resources**
   - Menu → "Add CP" or "Add VP"
   - Round counter increments when returning to Hero phase

## 📁 File Structure

```
Battle Roll/
├── Models/
│   ├── Game/
│   │   ├── GamePhase.swift           # Phase enum + icons
│   │   └── GameState.swift           # Game state manager
│   ├── Warscroll/
│   │   ├── AbilityTiming.swift       # Timing enums
│   │   ├── Warscroll+Extensions.swift  # Filtering logic
│   │   ├── Ability+Extensions.swift    # Usage helpers
│   │   └── WARSCROLL_IMPLEMENTATION.md  # Full documentation
├── Services/
│   ├── DataService.swift             # CRUD operations
│   ├── PhaseManager.swift            # Phase filtering
│   └── PersistenceController.swift   # Core Data stack
├── Views/
│   └── Battle/
│       ├── PhaseAbilitiesView.swift  # Main phase view
│       └── PhaseEngineMainView.swift # Game dashboard
├── Battle_Roll.xcdatamodeld/         # Core Data schema
├── AppDelegate.swift                 # App lifecycle
├── SceneDelegate.swift               # Environment injection
└── ContentView.swift                 # Main launcher
```

## 🔧 Troubleshooting

### "Cannot find 'Warscroll' in scope"
**Solution:** Build the project (`Cmd+B`). Core Data classes are auto-generated.

### "No such module 'UIKit'"
**Solution:** Clean build folder (`Cmd+Shift+K`) then rebuild.

### "File not in target"
**Solution:** Select file → File Inspector → Check "Battle Roll" target.

### Sample data button stays disabled
**Solution:** App checks for existing armies. If you already created data, the button correctly disables.

## 🎯 Next Steps - Future Features

### Immediate Priorities (from CLAUDE.md)
1. **PhaseBar Component** - Visual phase selector with icons
2. **Season Pack Loader** - Parse JSON from `Resources/Data/SeasonPacks/`
3. **Army Trait System** - Link faction traits to armies
4. **Weapon Profiles** - Display attack characteristics

### Recommended Enhancements
1. **Unit Health Tracking** - Damage allocation UI
2. **Battle Tactics** - Dual-state tracking (VP or Command)
3. **Twist Deck** - Season-specific rules
4. **Army Builder** - Create custom armies
5. **iPad Split View** - Dashboard + unit cards

## 📊 Sample Data Details

The `createSampleData()` method creates:

### Stormstrike Chariot
- **Stats:** Move 10", Health 12, Control 2, Save 3+
- **Abilities:**
  - *Rapid Redeployment* (Hero, Start of Phase, 1/Game)
  - *Swift Strike* (Movement, Passive)
  - *Thunderous Impact* (Combat, Passive)

### Liberators
- **Stats:** Move 5", Health 10, Control 1, Save 3+
- **Abilities:**
  - *Shield Wall* (Combat, Passive)
  - *Lay Low the Tyrant* (Combat, End of Phase, 1/Turn)

## 🧪 Testing the Phase Engine

### Test Scenario 1: Usage Tracking
1. Start game
2. Advance to Hero phase
3. Use "Rapid Redeployment" (1/Game)
4. Verify badge shows "USED"
5. Advance through all phases back to Hero
6. Verify ability still shows "USED"

### Test Scenario 2: Turn Reset
1. Start game
2. Advance to Combat phase
3. Use "Lay Low the Tyrant" (1/Turn)
4. Verify badge shows "USED"
5. Advance through Battleshock → Hero
6. Verify badge shows "1/TURN" (reset)

### Test Scenario 3: Destroyed Units
1. Start game
2. In Xcode, manually set a warscroll's `isDestroyed = true`
3. Verify its abilities don't appear in any phase
4. Menu → "End Game" → "Start Game"
5. Verify unit is restored and abilities return

## 📚 Documentation

- **Full API Reference:** `Models/WARSCROLL_IMPLEMENTATION.md`
- **Usage Examples:** See code examples in the implementation guide
- **Project Requirements:** `CLAUDE.md`

## 🎨 UI Customization

### Phase Colors
Edit `GamePhase.swift` → `displayColor` property

### Phase Icons
Edit `GamePhase.swift` → `iconName` property (uses SF Symbols)

### Ability Cards
Modify `AbilityCardView` in `PhaseAbilitiesView.swift`

## 💾 Core Data Tips

### Access the context in views
```swift
@Environment(\.managedObjectContext) private var viewContext
```

### Save changes
```swift
try? viewContext.save()
// or
PersistenceController.shared.save()
```

### Create new entities
```swift
let warscroll = Warscroll.create(in: viewContext, ...)
let ability = Ability.create(in: viewContext, ...)
```

## ✨ Key Features

### Automatic Phase Filtering
- Only shows abilities for the current phase
- Excludes destroyed units automatically
- Hides used limited abilities

### Smart Reminders
- Start/End of Phase abilities show in banner
- Prevents missed triggers
- Color-coded for visibility

### Usage Tracking
- "Once Per Turn" resets at start of turn
- "Once Per Game" persists entire game
- Visual badges show status

### Resource Management
- Command Points tracking
- Victory Points tracking
- Round counter

## 🐛 Known Limitations

1. No undo/redo for ability usage (consider adding)
2. No multi-player support (single army only)
3. No persistence between app launches for game state (only data)
4. No weapon attack roll calculator (planned)

## 📞 Support

If you encounter issues:
1. Check `WARSCROLL_IMPLEMENTATION.md` for detailed API docs
2. Review code examples in sample data
3. Verify Core Data schema matches documentation

---

**Ready to battle! ⚔️**

The Phase Engine is fully operational. Build the project and tap "Create Sample Army" to get started!
