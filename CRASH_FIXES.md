# Crash Fixes Applied - Ability View

## Issues Found in Console

### 1. ❌ **Duplicate Spearheads** 
```
📊 Found 7 total spearheads  // Should be 3!
ForEach: the ID Bloodbound Gore Pilgrims occurs multiple times
```

**Cause:** Spearheads were loading multiple times:
- AppDelegate.didFinishLaunching
- ContentView.onAppear
- ArmySelectionView.onAppear

### 2. ❌ **Multiple NSManagedObjectModels**
```
CoreData: warning: Multiple NSEntityDescriptions claim 'SpearheadArmy'
CoreData: warning: Multiple NSEntityDescriptions claim 'Ability'
```

**Cause:** Multiple Core Data contexts or duplicate data persisting

### 3. ❌ **Ability Fetch Crash**
```
CoreData: error: +[Ability entity] Failed to find unique match
executeFetchRequest:error: A fetch request must have an entity
```

**Cause:** `@FetchRequest` initialized in `init()` before managed object context was available, combined with Core Data entity disambiguation issues

## Fixes Applied

### ✅ Fix 1: Single Load Guard
Added `hasLoaded` flag to `SpearheadLoader`:
```swift
private var hasLoaded = false

func loadAllSpearheads() {
    if hasLoaded {
        print("✅ Spearheads already loaded, skipping...")
        return
    }
    // ... load logic ...
    hasLoaded = true
}
```

**Result:** Spearheads only load once per app session

### ✅ Fix 2: Clear Old Data on Launch
In `AppDelegate`:
```swift
SpearheadLoader.shared.deleteAllSpearheads()  // Clear old
SpearheadLoader.shared.loadAllSpearheads()    // Load fresh
```

**Result:** No duplicate data persisting between app launches

### ✅ Fix 3: Removed Duplicate Load Calls
- ❌ Removed from `ContentView.onAppear`
- ❌ Removed from `ArmySelectionView.onAppear`
- ✅ Kept only in `AppDelegate` (single source)

### ✅ Fix 4: Fixed AbilityListView
Changed from `@FetchRequest` to manual fetching:

**Before (Broken):**
```swift
@FetchRequest private var abilities: FetchedResults<Ability>

init(gameState: GameStateManager, player: PlayerSide) {
    _abilities = FetchRequest<Ability>(...)  // Crashes!
}
```

**After (Fixed):**
```swift
@State private var abilities: [Ability] = []

.onAppear {
    fetchAbilities()  // Fetch when view appears
}
.onChange(of: gameState.currentPhase) { _, _ in
    fetchAbilities()  // Re-fetch when phase changes
}

private func fetchAbilities() {
    let fetchRequest: NSFetchRequest<Ability> = Ability.fetchRequest()
    // ... configure and fetch
    abilities = try viewContext.fetch(fetchRequest)
}
```

**Result:** No more crash when tapping "My Abilities" or "Opponent Abilities"

## How to Test

### Clean Build Required
```bash
# 1. Quit Xcode completely
# 2. Delete app from simulator/device
# 3. Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Battle_Roll-*

# 4. Open and build
open "Battle Roll.xcodeproj"
```

In Xcode:
1. Clean Build Folder (`⇧⌘K`)
2. Build (`⌘B`)
3. Run (`⌘R`)

### Expected Console Output

**On App Launch:**
```
🚀 AppDelegate: Clearing old spearheads...
All spearheads deleted
🚀 AppDelegate: Loading spearhead data...
🔍 SpearheadLoader: Attempting to load spearheads...
⚠️ No files found in Resources/Data/Spearheads, trying direct path...
✅ Found 3 spearhead file(s):
  - BloodBoundGorePilgrims.json
  - CasteliteCompany.json
  - FangsOfTheBloodGod.json
Successfully loaded spearhead: Bloodbound Gore Pilgrims
Successfully loaded spearhead: Castelite Company
Successfully loaded spearhead: Fangs of the Blood God
✅ SpearheadLoader: All spearheads loaded, hasLoaded = true
✅ AppDelegate: Spearhead loading complete
```

**When Opening Army Selection:**
```
🔍 ArmySelectionView: Loading available factions...
📊 Found 3 total spearheads  // ✅ Should be 3, not 7!
🎯 Available factions: ["Blades of Khorne", "Cities of Sigmar"]
```

**NO MORE:**
- ❌ Duplicate ID warnings
- ❌ Multiple NSEntityDescriptions warnings
- ❌ "Failed to find unique match" errors

### Test Ability Views

1. **Start a game** with any armies
2. **Navigate to dashboard** (Round 1 view)
3. **Tap "My Abilities"**
   - ✅ Should open without crash
   - ✅ Should show abilities for current phase
4. **Tap "Opponent Abilities"**
   - ✅ Should open without crash
   - ✅ Should show opponent's abilities
5. **Navigate through phases**
   - ✅ Abilities should update per phase

## What Changed

| File | Change |
|------|--------|
| `SpearheadLoader.swift` | Added `hasLoaded` flag, only load once |
| `AppDelegate.swift` | Clear old data before loading |
| `ContentView.swift` | Removed duplicate load call |
| `ArmySelectionView.swift` | Removed duplicate load call |
| `GameDashboardView.swift` | Fixed AbilityListView to use manual fetch |

## Verification Checklist

After building:
- [ ] Console shows "Found 3 spearhead file(s)" (not 7)
- [ ] Console shows "📊 Found 3 total spearheads" (not 7)
- [ ] No "Multiple NSEntityDescriptions" warnings
- [ ] No "ForEach duplicate ID" warnings
- [ ] Main menu shows "3 spearheads loaded"
- [ ] Tapping "My Abilities" doesn't crash
- [ ] Tapping "Opponent Abilities" doesn't crash
- [ ] Abilities display correctly for each phase

## If Still Crashing

### Delete App Data
```bash
# For simulator:
xcrun simctl uninstall booted com.yourcompany.BattleRoll

# Or: Settings → Apps → Battle Roll → Delete App
```

Then rebuild and reinstall. This ensures no corrupted Core Data.

### Check Console for:
- Still seeing "Found 7 spearheads"? → hasLoaded flag not working
- Still seeing "Multiple NSEntityDescriptions"? → Data not cleared
- Different crash? → Share the new error message

The key issue was **multiple loads creating duplicate data**, causing Core Data to not know which entity definition to use!
