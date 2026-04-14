# CLAUDE.md - Spearhead Strategist

## Project Overview
**Spearhead Strategist** (Internal: "Battle Roll") is a specialized iOS/iPadOS app for managing Warhammer Age of Sigmar: Spearhead battles. 
**Status:** Active rebuild. Transitioning from a general tool to a phase-driven Spearhead companion.

## Technical Stack
- **Frameworks:** SwiftUI (UI), Core Data (Persistence), UIKit (App Lifecycle)
- **Minimum iOS:** 26.0
- **Swift Version:** 5.10+
- **Database:** `Battle_Roll.xcdatamodeld` (Core Data)

## Spearhead Game Logic (Core Requirements)
Claude should prioritize these logic patterns during implementation:

### 1. The Phase Engine
Every unit ability and army trait must be mapped to specific game phases following official Spearhead rules:
- **7 Phases per turn:** `Start of Turn`, `Hero`, `Movement`, `Shooting`, `Charge`, `Combat`, `End of Turn`.
- **Game Length:** Exactly 4 battle rounds. Game automatically ends after Round 4's End of Turn phase.
- **Priority System:**
  - Round 1: Attacker chooses who goes first
  - Rounds 2-4: Priority roll (D6 vs D6). Winner chooses. Tie: previous first player chooses.
- **Logic:** The UI must filter and highlight abilities based on the active phase selected in the `GameState`.
- **Unit State:** When a unit is marked as `isDestroyed` in Core Data, its abilities must be excluded from the active Phase Engine view.

### 2. Scoring System
Official Spearhead scoring at End of Turn phase:
- **Objective Control:** 1 VP for ≥1 objective, 1 VP for ≥2 objectives, 1 VP for controlling more than opponent
- **Battle Tactics:** 1 VP per completed tactic (maximum 3 tactics total per game)
- **Underdog:** At start of Rounds 2-4, the player with fewer VP is marked as the Underdog

### 3. Season & Battlefield Management
The app supports modular "Season Packs" (stored in `Resources/Data/Spearheads/`):
- **Twist Cards:** Draw one Twist card at the start of each round (Rounds 2-4). Keep effect visible on dashboard.
- **Battle Tactics:** Must support dual-state tracking: `Scored for VP` OR `Used as Command`.
- **12 Spearhead Armies:** All armies loaded from JSON with unique traits and abilities.

### 4. Ability Tracking
- Support for "Once Per Game" and "Once Per Turn" toggles.
- Visual cues/reminders for "Start of Phase" abilities to prevent missed triggers.

## Architecture & Folder Structure

### Models (`Models/`)
- `Army/`: Spearhead-specific army definitions and traits.
- `Warscroll/`: Unit stats and phase-tagged abilities.
- `Game/`: `GameState.swift` (ObservableObject) managing CP, VP, Phase, and active Twist.
- `Season/`: Definitions for Season-specific rules and layouts.

### Services (`Services/`)
- `DataService.swift`: Singleton handling Core Data CRUD and Season Pack JSON parsing.
- `PhaseManager.swift`: Logic for filtering available actions based on the current game state.

### Views (`Views/`)
- `Battle/`: The main "Dashboard" (iPad) or "Phase Runner" (iPhone).
- `Setup/`: Pre-game configuration (Select Season -> Select Army -> Select Traits).

## Development Workflow for Claude Code

### Core Data Integration
When generating models, use the existing `Battle_Roll` container. Access via:
`(UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext`

### Implementation Priorities (TODOs)
1. **Model Definition:** Define `SpearheadArmy` and `Warscroll` entities in Core Data.
2. **Phase Engine:** Create a `PhaseBar` component that updates `GameState.currentPhase`.
3. **Filtering Logic:** Implement a view that lists all available `Abilities` for the current phase, filtered by "Alive" units.
4. **Season Loader:** Build a service to parse JSON from `SeasonPacks/` into the app.

### Coding Style
- Prefer **SwiftUI** for all new views.
- Use **EnvironmentObjects** for `GameState` and `DataService`.
- Follow **MVVM**: Keep business logic out of View files and inside ViewModels or Services.
