# Phase Engine Quick Reference

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    PhaseEngineMainView                   │
│  ┌────────────────┐  ┌──────────────────────────────┐  │
│  │  GameStatusBar │  │    PhaseAbilitiesView        │  │
│  │  - Round       │  │  ┌────────────────────────┐  │  │
│  │  - VP          │  │  │   PhaseHeaderView      │  │  │
│  │  - CP          │  │  ├────────────────────────┤  │  │
│  └────────────────┘  │  │   ReminderBanner       │  │  │
│                      │  ├────────────────────────┤  │  │
│                      │  │   AbilityCardView      │  │  │
│                      │  │   AbilityCardView      │  │  │
│                      │  │   ...                  │  │  │
│                      │  └────────────────────────┘  │  │
│                      └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
         ┌──────▼──────┐        ┌──────▼──────┐
         │  GameState  │        │PhaseManager │
         │  (Published)│        │ (Published) │
         └──────┬──────┘        └──────┬──────┘
                │                      │
                │                      │
         ┌──────▼──────────────────────▼──────┐
         │        Core Data Stack              │
         │  ┌────────────┐  ┌────────────┐    │
         │  │ Warscroll  │  │  Ability   │    │
         │  │ ─────────  │  │  ────────  │    │
         │  │ +name      │◄─┤ +name      │    │
         │  │ +health    │  │ +phase     │    │
         │  │ +isAlive   │  │ +timing    │    │
         │  └────────────┘  │ +usageLimit│    │
         │                  └────────────┘    │
         └─────────────────────────────────────┘
```

## 📋 Core Data Entities

### Warscroll
```swift
// Attributes
id: UUID
name: String
move, health, control, save: Int16
isDestroyed: Bool
damageAllocated: Int16

// Relationships
abilities: [Ability]
weapons: [Weapon]
army: SpearheadArmy

// Key Methods
abilities(for: GamePhase) -> [Ability]
canUseAbility(Ability) -> Bool
markAbilityAsUsed(Ability)
```

### Ability
```swift
// Attributes
id: UUID
name: String
abilityDescription: String
phase: String              // "Hero", "Movement", etc.
timing: String             // "Start of Phase", "During Phase"
usageLimit: String         // "Unlimited", "Once Per Turn"
hasBeenUsedThisTurn: Bool
hasBeenUsedThisGame: Bool

// Relationships
warscroll: Warscroll

// Computed Properties
gamePhase: GamePhase?
isAvailable: Bool
badgeText: String?
```

## 🔄 Data Flow

### Phase Change
```
User taps "Next Phase"
    │
    ├─► GameState.advancePhase()
    │       │
    │       └─► currentPhase.next()
    │
    └─► PhaseManager.updateAvailableAbilities()
            │
            ├─► Fetch all Warscrolls where isDestroyed == false
            ├─► For each warscroll, get abilities(for: currentPhase)
            ├─► Filter by canUseAbility()
            └─► Update @Published availableAbilities
                    │
                    └─► UI refreshes automatically
```

### Ability Usage
```
User taps "Mark Used"
    │
    └─► PhaseManager.markAbilityAsUsed()
            │
            ├─► Warscroll.markAbilityAsUsed()
            │       │
            │       └─► Update hasBeenUsedThisTurn/ThisGame
            │
            ├─► Save Core Data context
            │
            └─► updateAvailableAbilities()
                    │
                    └─► UI refreshes (ability now shows "USED")
```

### Turn Reset
```
Advance from Battleshock → Hero
    │
    ├─► GameState.currentRound++
    │
    └─► PhaseManager.resetTurnAbilities()
            │
            ├─► Fetch all Warscrolls
            ├─► For each: warscroll.resetTurnUsage()
            │       │
            │       └─► Set hasBeenUsedThisTurn = false for all abilities
            │
            └─► Save & update UI
```

## 🎮 Key Enums

### GamePhase
```swift
case hero, movement, shooting, charge, combat, battleshock

// Properties
var iconName: String       // SF Symbol
var displayColor: String   // UI color
func next() -> GamePhase   // Next in sequence
```

### AbilityTiming
```swift
case startOfPhase   // Shows in reminder banner
case duringPhase    // Normal use
case endOfPhase     // Shows in reminder banner
case passive        // Always active

var requiresReminder: Bool
```

### AbilityUsageLimit
```swift
case unlimited      // No tracking
case oncePerTurn    // Reset at Hero phase
case oncePerGame    // Never resets

var displayText: String  // "Any Time", "1/Turn", "1/Game"
```

## 🛠️ Common Operations

### Filter abilities by phase
```swift
// Manual
let abilities = warscroll.abilities(for: .combat)

// Automatic (PhaseManager)
phaseManager.updateAvailableAbilities(from: context)
// Uses: gameState.currentPhase
```

### Check if ability is available
```swift
if warscroll.canUseAbility(someAbility) {
    // Can use
}

// Or use computed property
if ability.isAvailable {
    // Can use
}
```

### Mark ability as used
```swift
// Via PhaseManager (recommended)
phaseManager.markAbilityAsUsed(ability, in: context)

// Or directly
warscroll.markAbilityAsUsed(ability)
try? context.save()
```

### Get reminder abilities
```swift
let reminders = warscroll.abilitiesRequiringReminder(for: .hero)
// Returns abilities with timing == .startOfPhase or .endOfPhase
```

## 📊 State Management

### GameState (@Published)
```swift
currentPhase: GamePhase       // Active phase
currentRound: Int             // Battle round (1-5)
commandPoints: Int            // CP pool
victoryPoints: Int            // VP score
isGameActive: Bool            // Game in progress

// Methods
advancePhase()
setPhase(GamePhase)
addCommandPoints(Int)
spendCommandPoints(Int) -> Bool
addVictoryPoints(Int)
startGame()
endGame()
reset()
```

### PhaseManager (@Published)
```swift
availableAbilities: [Ability]   // Current phase abilities
reminderAbilities: [Ability]    // Start/end abilities

// Methods
updateAvailableAbilities(from: NSManagedObjectContext)
markAbilityAsUsed(Ability, in: NSManagedObjectContext)
resetTurnAbilities(in: NSManagedObjectContext)
abilitiesByWarscroll() -> [String: [Ability]]
```

## 🎨 UI Components

### PhaseAbilitiesView
- Shows abilities for current phase
- Reminder banner for critical timing
- Ability cards with usage tracking

### AbilityCardView
- Unit name + ability name
- Description text
- Timing indicator
- Usage badge (1/TURN, USED, etc.)
- "Mark Used" button

### PhaseHeaderView
- Phase name + icon
- Color-coded background

### PhaseControlsView
- Previous/Next phase buttons
- Auto-reset on new turn

## 🔍 Filtering Logic

```swift
// PhaseManager.updateAvailableAbilities()
1. Fetch all Warscrolls where isDestroyed == false
2. For each warscroll:
   a. Get abilities(for: currentPhase)
   b. Filter by canUseAbility()
      - Unlimited: always true
      - OncePerTurn: !hasBeenUsedThisTurn
      - OncePerGame: !hasBeenUsedThisGame
3. Sort by warscroll name, then sortOrder
4. Update @Published properties
5. UI auto-refreshes via Combine
```

## 💡 Best Practices

### ✅ DO
- Use `PhaseManager.updateAvailableAbilities()` after phase changes
- Reset turn tracking when advancing from Battleshock → Hero
- Check `isAvailable` before allowing ability use
- Save context after modifying entities
- Use `@EnvironmentObject` for GameState and PhaseManager

### ❌ DON'T
- Mutate Core Data entities without saving
- Forget to filter out destroyed units
- Skip reminder abilities (easy to miss triggers)
- Hardcode phase logic in views (use PhaseManager)

## 🧪 Testing Checklist

- [ ] Abilities filter by phase correctly
- [ ] Destroyed units excluded from ability list
- [ ] Once Per Turn abilities reset at Hero phase
- [ ] Once Per Game abilities persist
- [ ] Reminder banner shows start/end abilities
- [ ] Usage badges update in real-time
- [ ] Round counter increments correctly
- [ ] CP/VP tracking works
- [ ] Phase navigation loops correctly

## 📚 File Locations

```
Models/Game/GamePhase.swift
Models/Game/GameState.swift
Models/Warscroll/AbilityTiming.swift
Models/Warscroll/Warscroll+Extensions.swift
Models/Warscroll/Ability+Extensions.swift
Services/PhaseManager.swift
Services/DataService.swift
Services/PersistenceController.swift
Views/Battle/PhaseAbilitiesView.swift
Views/Battle/PhaseEngineMainView.swift
```

## 🚀 Quick Start Code

```swift
// In your view
@EnvironmentObject var gameState: GameState
@EnvironmentObject var phaseManager: PhaseManager
@Environment(\.managedObjectContext) private var viewContext

// Advance phase
gameState.advancePhase()

// Get abilities for current phase
phaseManager.updateAvailableAbilities(from: viewContext)

// Use an ability
phaseManager.markAbilityAsUsed(ability, in: viewContext)

// Check if usable
if warscroll.canUseAbility(ability) {
    // Show button
}
```

---

**This system implements all Phase Engine requirements from CLAUDE.md ✅**
