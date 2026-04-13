# Build Fix Applied - UPDATED

## Issues Fixed
1. ✅ **Duplicate `GamePhase` enum** - Removed duplicate from `GameStateManager.swift`, using existing one in `GamePhase.swift`
2. ✅ **Duplicate `BattleTactic` and `Twist` structs** - Removed placeholder structs, using Core Data auto-generated classes

## How to Build (IMPORTANT - Follow Exactly)

### Step 1: Quit Xcode Completely
- **Close Xcode entirely** (⌘Q) if it's open
- This ensures build cache is released

### Step 2: Clean Derived Data
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Battle_Roll-*
```

### Step 3: Open and Build
```bash
open "Battle Roll.xcodeproj"
```

Wait for Xcode to finish indexing (watch the progress bar at top), then:

1. **Clean Build Folder**: Press `⇧⌘K` (Shift-Command-K)
2. **Build**: Press `⌘B` (Command-B)
3. **Run**: Press `⌘R` (Command-R)

## What Core Data Auto-Generates

During build, Core Data automatically creates these classes in `DerivedData`:
- `BattleTactic+CoreDataClass.swift` / `+CoreDataProperties.swift`
- `Twist+CoreDataClass.swift` / `+CoreDataProperties.swift`
- `GameRecord+CoreDataClass.swift` / `+CoreDataProperties.swift`
- `RoundRecord+CoreDataClass.swift` / `+CoreDataProperties.swift`
- `SeasonPack+CoreDataClass.swift` / `+CoreDataProperties.swift`
- `Warscroll+CoreDataClass.swift` / `+CoreDataProperties.swift`
- `Ability+CoreDataClass.swift` / `+CoreDataProperties.swift`
- `Weapon+CoreDataClass.swift` / `+CoreDataProperties.swift`
- `SpearheadArmy+CoreDataClass.swift` / `+CoreDataProperties.swift`

**Do NOT add these to your project** - they are auto-generated each build.

## If Still Getting Errors

### "Invalid redeclaration" errors:
This means the derived data wasn't fully cleaned. Try:

1. Quit Xcode
2. Run this command:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```
3. Delete the `Battle Roll.xcodeproj/project.xcworkspace` folder:
   ```bash
   rm -rf "Battle Roll.xcodeproj/project.xcworkspace"
   ```
4. Reopen Xcode and clean build

### "Cannot find type" errors during editing:
These are **expected** before the build completes:
- SourceKit can't see Core Data types until after first successful build
- They will disappear after build succeeds
- **Ignore these if you see them in the editor** - just build anyway

## Verification Checklist

After successful build, verify:
- ✅ No compilation errors
- ✅ App launches in simulator
- ✅ Main menu shows "Start New Game" and "Game History"
- ✅ Army selection shows:
  - **Blades of Khorne**: Bloodbound Gore Pilgrims, Fangs of the Blood God
  - **Cities of Sigmar**: Castelite Company

## Build Output Should Show

```
Build succeeded
```

If you see warnings, that's usually OK. Only errors will prevent the build.
