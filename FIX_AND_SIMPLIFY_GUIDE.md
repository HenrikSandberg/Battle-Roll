# Fix Bugs & Simplify App Guide

## 🐛 Critical Bug Fixes

### Issue 1: Core Data Duplicate Entities

**Error**: `Multiple NSEntityDescriptions claim the NSManagedObject subclass 'SpearheadArmy'`

**Cause**: Multiple Core Data model files or duplicate model loading

**Fix Steps**:
1. In Xcode, press `Cmd + Shift + F` (Find in Project)
2. Search for: `.xcdatamodeld`
3. **You should only have ONE file**: `Battle_Roll.xcdatamodeld`
4. If you find duplicates (like `Mac_Battle_Roll.xcdatamodeld`), delete them
5. Clean build folder: `Cmd + Shift + K`
6. Rebuild: `Cmd + B`

### Issue 2: AppDelegate vs PersistenceController Conflict

You have TWO Core Data stacks running:
- One in `AppDelegate.persistentContainer`
- One in `PersistenceController.shared.container`

**Fix in `SceneDelegate.swift`**:

Change line 19 from:
```swift
let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
```

To:
```swift
let context = PersistenceController.shared.container.viewContext
```

### Issue 3: Color & Symbol Errors

**Fix in `GamePhase.swift`**:

1. Change `displayColor` return type:
```swift
// OLD
var displayColor: String { ... }

// NEW
var displayColor: Color { ... }
```

2. Change combat icon:
```swift
case .combat:
    return "shield.lefthalf.filled"  // instead of "crossed.swords"
```

3. Update all color cases:
```swift
var displayColor: Color {
    switch self {
    case .hero: return .purple
    case .movement: return .blue
    case .shooting: return .orange
    case .charge: return .red
    case .combat: return .red  // was "crimson"
    case .battleshock: return .gray
    }
}
```

**Fix in `PhaseAbilitiesView.swift`** (line ~55):

Change:
```swift
.background(Color(phase.displayColor).opacity(0.2))
```
To:
```swift
.background(phase.displayColor.opacity(0.2))
```

### Issue 4: Core Data Merge Conflicts

**Fix in `PersistenceController.swift`**:

Change the merge policy:
```swift
// OLD
container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

// NEW
container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
```

## 🎯 Simplify to Score Tracker

Based on your needs (simple points, underdog status, competitor tracking), I've created a simplified app in `SIMPLIFIED_SCORE_TRACKER.swift`.

### Features:
✅ Two-player score tracking
✅ Underdog indicator (shows when you're behind)
✅ Quick +1 to +5 point buttons
✅ Battle Tactics tracker
✅ Score difference display
✅ Round counter
✅ Player name customization

### Implementation Steps:

#### Option A: Replace Entire App (Simplest)

1. **Create new file**: `ScoreTrackerView.swift`
2. **Copy the entire content** from `SIMPLIFIED_SCORE_TRACKER.swift`
3. **Update `SceneDelegate.swift` line 24**:

```swift
// OLD
let contentView = ContentView()
    .environment(\.managedObjectContext, context)
    .environmentObject(gameState)
    .environmentObject(phaseManager)

// NEW
let contentView = ScoreTrackerView()
```

4. **Remove Core Data environment** (no longer needed):
```swift
// Remove this line from SceneDelegate:
let context = ...
```

5. **Build and run**: `Cmd + R`

#### Option B: Keep Both (Advanced Users)

Add a tab view in `ContentView.swift`:

```swift
TabView {
    ScoreTrackerView()
        .tabItem {
            Label("Score", systemImage: "chart.bar.fill")
        }

    PhaseEngineMainView()
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(gameState)
        .environmentObject(phaseManager)
        .tabItem {
            Label("Phase Engine", systemName: "bolt.fill")
        }
}
```

## 📱 Score Tracker Usage

### Starting a Game
1. Tap **Settings** (gear icon)
2. Set player names
3. Tap **Done**

### Tracking Points
- Tap **+1** through **+5** to add points
- Tap **− button** to subtract 1 point
- **Green highlight** shows who's winning
- **Orange "Underdog" badge** appears when you're behind

### Battle Tactics
1. Tap **"Battle Tactics"** button
2. Enter tactic name (e.g., "Slay the Warlord")
3. Select which player scored it
4. Tap **+** to add

### Round Management
- Tap **"Next Round"** to increment
- Tap **↻ button** to reset entire game

## 🧹 Clean Up Unused Files (Optional)

Once the simplified version works, you can delete:
- `PhaseManager.swift`
- `PhaseAbilitiesView.swift`
- `PhaseEngineMainView.swift`
- `DataService.swift`
- `Warscroll+Extensions.swift`
- `Ability+Extensions.swift`

**Keep these**:
- `GamePhase.swift` (if using Option B)
- `GameState.swift` (if using Option B)
- `PersistenceController.swift` (only if using Core Data for army lists later)

## 🔍 Verify Fixes

After applying fixes, check for these in Xcode console:

### ✅ Should NOT see:
- ❌ "Multiple NSEntityDescriptions claim..."
- ❌ "No color named 'purple' found..."
- ❌ "No symbol named 'crossed.swords'..."
- ❌ "Could not merge changes"

### ✅ Should see:
- ✅ Clean build with no warnings
- ✅ App launches successfully
- ✅ Score tracker displays correctly

## 🎨 Customization

### Change Colors
In `PlayerScoreCard`, change the winning color:
```swift
.foregroundColor(isWinning ? .green : .primary)
// Change .green to .blue, .orange, etc.
```

### Add More Quick-Add Buttons
In `PlayerScoreCard`, add to the button grid:
```swift
HStack(spacing: 12) {
    QuickAddButton(value: 1, onTap: onAdd)
    QuickAddButton(value: 2, onTap: onAdd)
    QuickAddButton(value: 3, onTap: onAdd)
    QuickAddButton(value: 10, onTap: onAdd)  // ADD THIS
}
```

### Change Round Limit
Add to `BattleGame`:
```swift
var isGameOver: Bool {
    currentRound > 5  // Standard Spearhead is 5 rounds
}
```

## 📊 Score Tracker vs Phase Engine

| Feature | Score Tracker | Phase Engine |
|---------|---------------|--------------|
| **Complexity** | Simple | Complex |
| **Setup Time** | Instant | Requires army data |
| **Points Tracking** | ✅ Two players | ✅ One player |
| **Underdog Status** | ✅ Yes | ❌ No |
| **Ability Filtering** | ❌ No | ✅ Yes |
| **Battle Tactics** | ✅ Manual entry | ❌ No |
| **Best For** | Quick games | Detailed tracking |

## 🚀 Next Steps

1. **Fix the Core Data duplication** (most critical)
2. **Fix color/symbol references**
3. **Choose**: Simplified Score Tracker OR Enhanced Phase Engine
4. **Test on device**
5. **Customize to your preferences**

## 💡 Pro Tips

- **Landscape mode** works great on iPad for side-by-side scores
- **Use Siri/Voice** to add points while playing
- **Screenshot scores** at end of each round for history
- **Add haptic feedback** for button taps (more satisfying)

## 🆘 Still Having Issues?

1. **Delete the app** from your device
2. **Clean build folder**: `Cmd + Shift + K`
3. **Delete derived data**: `Cmd + Shift + Option + K` (or manually delete ~/Library/Developer/Xcode/DerivedData)
4. **Rebuild**: `Cmd + B`
5. **Run**: `Cmd + R`

---

**Choose your path**: Simple Score Tracker (recommended) or Enhanced Phase Engine with fixes!
