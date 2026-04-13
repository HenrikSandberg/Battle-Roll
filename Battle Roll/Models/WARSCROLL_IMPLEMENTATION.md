# Warscroll & Phase Engine Implementation Guide

## Overview
This implementation provides a complete **Phase Engine** system for managing Warhammer Age of Sigmar: Spearhead battles. It includes Core Data models, Swift extensions, and filtering logic as specified in `CLAUDE.md`.

## Architecture

### Core Data Schema

#### Warscroll Entity
Represents a unit on the battlefield.

**Attributes:**
- `id` (UUID) - Unique identifier
- `name` (String) - Unit name
- `move` (Int16) - Movement characteristic
- `health` (Int16) - Total health
- `control` (Int16) - Control characteristic
- `save` (Int16) - Save characteristic
- `isDestroyed` (Bool) - Whether the unit has been destroyed
- `damageAllocated` (Int16) - Current damage on the unit
- `iconName` (String, optional) - SF Symbol name for UI
- `unitType` (String, optional) - Unit type classification

**Relationships:**
- `abilities` → [Ability] (One-to-Many, Cascade Delete)
- `weapons` → [Weapon] (One-to-Many, Cascade Delete)
- `army` → SpearheadArmy (Many-to-One)

#### Ability Entity
Represents a unit ability tagged to a specific phase.

**Attributes:**
- `id` (UUID) - Unique identifier
- `name` (String) - Ability name
- `abilityDescription` (String) - Full text of the ability
- `phase` (String) - Game phase (Hero/Movement/Shooting/Charge/Combat/Battleshock)
- `timing` (String) - When to use (Start of Phase/During Phase/End of Phase/Passive)
- `usageLimit` (String) - Frequency (Unlimited/Once Per Turn/Once Per Game)
- `hasBeenUsedThisTurn` (Bool) - Turn usage tracking
- `hasBeenUsedThisGame` (Bool) - Game usage tracking
- `isPassive` (Bool) - Whether it's a passive ability
- `sortOrder` (Int16) - Display order

**Relationships:**
- `warscroll` → Warscroll (Many-to-One)

## Phase Engine Logic

### 1. Phase Filtering
The `PhaseManager` service filters abilities based on:
- **Current Phase**: Only shows abilities tagged to the active phase
- **Unit Status**: Excludes abilities from destroyed units (`isDestroyed == true`)
- **Usage Limits**: Hides used "Once Per Turn" or "Once Per Game" abilities

### 2. Reminder System
Abilities with timing set to `"Start of Phase"` or `"End of Phase"` appear in a **Reminder Banner** to prevent missed triggers.

### 3. Usage Tracking
When an ability is used:
- `hasBeenUsedThisTurn` is set to `true` for "Once Per Turn" abilities
- `hasBeenUsedThisGame` is set to `true` for "Once Per Game" abilities
- The ability becomes unavailable until reset

Turn tracking is reset when advancing from Battleshock → Hero phase.

## File Structure

```
Models/
├── Game/
│   ├── GamePhase.swift          # Phase enum + icons/colors
│   └── GameState.swift          # ObservableObject for game state
├── Warscroll/
│   ├── AbilityTiming.swift      # Timing and usage limit enums
│   ├── Warscroll+Extensions.swift  # Convenience methods
│   └── Ability+Extensions.swift    # Ability helpers
Services/
└── PhaseManager.swift           # Phase filtering logic
Views/
└── Battle/
    └── PhaseAbilitiesView.swift # UI demonstration
```

## Usage Examples

### Creating a Warscroll with Abilities

```swift
import CoreData

let context = viewContext // Your Core Data context

// Create the Warscroll
let stormstrikeChariot = Warscroll.create(
    in: context,
    name: "Stormstrike Chariot",
    move: 10,
    health: 12,
    control: 2,
    save: 3,
    unitType: "Cavalry"
)

// Add a Hero Phase ability
let rapidRedeployment = Ability.create(
    in: context,
    name: "Rapid Redeployment",
    description: "Remove this unit from the battlefield and set it up again anywhere more than 9\" from all enemy units.",
    phase: .hero,
    timing: .startOfPhase,
    usageLimit: .oncePerGame,
    sortOrder: 1
)
rapidRedeployment.warscroll = stormstrikeChariot

// Add a Charge Phase ability
let thunderousCharge = Ability.create(
    in: context,
    name: "Thunderous Charge",
    description: "Add 1 to the Attacks characteristic of this unit's melee weapons if it charged this turn.",
    phase: .charge,
    timing: .duringPhase,
    usageLimit: .unlimited,
    isPassive: true,
    sortOrder: 1
)
thunderousCharge.warscroll = stormstrikeChariot

try? context.save()
```

### Setting Up the Phase Engine

```swift
import SwiftUI

@main
struct SpearheadApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject private var gameState = GameState()
    @StateObject private var phaseManager: PhaseManager

    init() {
        let state = GameState()
        _gameState = StateObject(wrappedValue: state)
        _phaseManager = StateObject(wrappedValue: PhaseManager(gameState: state))
    }

    var body: some Scene {
        WindowGroup {
            PhaseAbilitiesView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(gameState)
                .environmentObject(phaseManager)
        }
    }
}
```

### Filtering Abilities Manually

```swift
// Get all Movement phase abilities for alive units
let movementAbilities = warscroll.abilities(for: .movement)
    .filter { warscroll.canUseAbility($0) }

// Get abilities requiring reminders
let reminders = warscroll.abilitiesRequiringReminder(for: .hero)

// Check if a specific ability is available
let canUse = warscroll.canUseAbility(someAbility)
```

### Advancing Phases

```swift
// Advance to next phase
gameState.advancePhase()

// When entering Hero phase, reset turn abilities
if gameState.currentPhase == .hero {
    phaseManager.resetTurnAbilities(in: context)
}

// Mark an ability as used
phaseManager.markAbilityAsUsed(ability, in: context)
```

## UI Components

### PhaseAbilitiesView
Main view displaying:
- Current phase header with icon
- Reminder banner for start/end of phase abilities
- List of all available abilities
- Phase navigation controls

### AbilityCardView
Individual ability card showing:
- Unit name and ability name
- Full description
- Timing information
- Usage badge (1/TURN, 1/GAME, USED)
- "Mark Used" button for limited abilities

## Integration Checklist

- [x] Core Data schema defined
- [x] Phase enum with 6 battle phases
- [x] GameState ObservableObject
- [x] Ability timing and usage limit enums
- [x] Warscroll extensions for filtering
- [x] Ability extensions for usage tracking
- [x] PhaseManager service
- [x] Example UI view
- [ ] DataService integration (TODO)
- [ ] Season Pack JSON loading (TODO)
- [ ] Army trait system (TODO)

## Next Steps

1. **Implement DataService** - Singleton for Core Data CRUD operations
2. **Create Army Models** - SpearheadArmy entity with faction traits
3. **Build Season Loader** - Parse JSON from `Resources/Data/SeasonPacks/`
4. **Design PhaseBar Component** - Visual phase selector for iPad
5. **Add Weapon Profiles** - Complete the Weapon entity with attack rolls

## Notes

- The system automatically excludes abilities from destroyed units
- "Passive" abilities are displayed but don't require activation
- Phase colors and icons use SF Symbols for native iOS look
- All Core Data operations should be wrapped in try-catch blocks
- Consider adding undo/redo support for ability usage tracking
