# Spearhead Strategist - Implementation Summary

## Overview
The app has been restructured to focus on the complete game flow for Warhammer Age of Sigmar: Spearhead battles. The implementation follows the user's requested workflow from game setup through completion and history tracking.

## Game Flow Implementation

### 1. App Launch → Main Menu
**File:** `Battle Roll/ContentView.swift`

- **Start New Game**: Launches the game setup flow
- **Game History**: View past games, scores, and statistics

### 2. Game Setup Flow
**Files:** 
- `Battle Roll/Views/Setup/GameSetupView.swift`
- `Battle Roll/Views/Setup/ArmySelectionView.swift`
- `Battle Roll/Views/Setup/SeasonSelectionView.swift`

**Steps:**
1. **Select Your Army & Spearhead**
   - Choose from all Age of Sigmar factions (placeholder data)
   - Select specific Spearhead for your army
   
2. **Select Opponent's Army & Spearhead**
   - Same selection process for opponent
   
3. **Select Season & Board Layout**
   - Choose season (Fire and Jade, Sand and Bone)
   - Select battlefield layout
   
4. **Game Summary**
   - Review all selections before starting
   - Press "Start Game" to begin

### 3. In-Game Dashboard
**File:** `Battle Roll/Views/Game/GameDashboardView.swift`

**Features:**

#### Header Section
- Current round number and season
- Current player's turn indicator
- Live score tracking (You vs Opponent)
- Underdog indicator (arrow icon)

#### Current Twist Display
- Shows the active twist for the current round
- Name and description clearly displayed

#### Battle Tactics Tracking
- Indicators showing if each player can pick new tactics
- After 3 tactics used, player cannot pick more (automatic tracking)
- View available battle tactics

#### Phase Tracker
- Visual display of all 6 phases: Hero, Movement, Shooting, Charge, Combat, Battleshock
- Current phase highlighted
- Navigate forward/backward through phases

#### Quick Actions
- **My Abilities**: View your abilities available in current phase
- **Opponent Abilities**: Check opponent's abilities
- **Priority Roll**: Record who won priority (from Round 2 onwards)

#### Phase Navigation Bar
- Previous Phase / Next Phase buttons
- Current phase name displayed
- "End Turn" button appears at Battleshock phase

### 4. Ability Tracking System
**File:** `Battle Roll/Views/Game/GameDashboardView.swift` (AbilityListView)

**Features:**
- Abilities filtered by current game phase
- Only shows abilities from units that are NOT destroyed
- Displays ability details:
  - Name and associated unit
  - Full description
  - Timing (Start of Phase, During Phase, etc.)
  - Usage limit (Unlimited, Once Per Turn, Once Per Game)
- **Mark as Used** functionality
  - Tracks once-per-turn abilities (resets each turn)
  - Tracks once-per-game abilities (persists entire game)
- Passive abilities clearly indicated

### 5. Turn & Round Management
**File:** `Battle Roll/Models/Game/GameStateManager.swift`

**Turn Flow:**
1. Navigate through all 6 phases
2. At end of Battleshock phase → "End Turn" sheet
3. Record any Battle Tactics scored this turn
4. Ability usage flags reset for "Once Per Turn" abilities
5. Switch to other player OR end round if both players finished

**Round Flow:**
1. After both players complete turns → Round ends
2. Underdog calculated (player with lower score)
3. Round number increments
4. New twist becomes active
5. Priority Roll sheet appears (starting Round 2)
6. Winner chooses who goes first
7. Underdog may change based on who goes first

### 6. End Game & Results
**File:** `Battle Roll/Views/Game/GameDashboardView.swift` (EndGameView)

**Features:**
- Confirmation dialog before ending
- Results screen shows:
  - Victory/Defeat/Draw status with icon
  - Final scores
  - Trophy for winner
- Game automatically saved to history
- Return to main menu

### 7. Game History
**File:** `Battle Roll/Views/Game/GameHistoryView.swift`

**Features:**
- List of all completed games (newest first)
- Each entry shows:
  - Date and time played
  - Season and board layout
  - Your army and spearhead
  - Opponent's army and spearhead
  - Final score
  - Win/Loss/Draw badge
- Swipe to delete games
- Empty state when no games played

## Data Models

### Core Data Schema
**File:** `Battle Roll/Battle_Roll.xcdatamodeld/Battle_Roll.xcdatamodel/contents`

#### Entities Created:

1. **GameRecord** - Complete game information
   - id, date, season, boardLayout
   - myArmyName, mySpearheadName, myFinalScore
   - opponentArmyName, opponentSpearheadName, opponentFinalScore
   - didIWin, isComplete
   - Relationship: rounds (one-to-many)

2. **RoundRecord** - Per-round tracking
   - roundNumber, whoWonPriority, whoWentFirst
   - underdogAtStart
   - myScoreThisRound, opponentScoreThisRound
   - Relationship: game (many-to-one)

3. **BattleTactic** - Battle tactic cards
   - name, description, victoryPoints, season

4. **Twist** - Twist cards
   - name, description, season, roundNumber

5. **SeasonPack** - Season definitions
   - name, description, boardLayouts

6. **Existing Entities** (from previous implementation):
   - Warscroll (units with stats)
   - Ability (phase-tagged abilities)
   - Weapon (unit weapons)
   - SpearheadArmy (army compositions)

### Game State Manager
**File:** `Battle Roll/Models/Game/GameStateManager.swift`

**Key Classes & Enums:**

```swift
enum GamePhase: Hero, Movement, Shooting, Charge, Combat, Battleshock
enum PlayerSide: Me, Opponent
struct PlayerSetup: armyName, spearheadName, score, usedBattleTactics, canPickNewTactic
class GameStateManager: ObservableObject
```

**State Tracking:**
- Season, board layout
- Player setups (yours and opponent)
- Current round, turn, phase
- Underdog status
- Current twist and available battle tactics
- Round history with detailed records
- Game active status

**Key Methods:**
- `startNewGame()` - Initialize game
- `nextPhase()` / `previousPhase()` - Phase navigation
- `endTurn()` - Turn completion, reset abilities
- `endRound()` - Round completion, underdog calculation
- `scoreBattleTactic()` - Record scored tactics
- `setPriorityWinner()` / `setFirstPlayer()` - Priority tracking
- `endGame()` - Finalize and get results

### Services

#### GameRecordService
**File:** `Battle Roll/Services/GameRecordService.swift`

- `saveGame()` - Save completed game to Core Data
- `fetchAllGames()` - Retrieve game history
- `getStatistics()` - Win/loss/draw stats
- `deleteGame()` - Remove game from history

## Implementation Status

### ✅ Completed
- [x] Core Data models for game tracking
- [x] Game state management service
- [x] Complete setup flow (4 steps)
- [x] In-game dashboard with all features
- [x] Phase tracking and navigation
- [x] Ability filtering by phase
- [x] Turn and round management
- [x] Underdog tracking
- [x] Battle tactic usage limiting
- [x] End game flow with results
- [x] Game history with full details
- [x] Persistence service

### 🔄 Placeholder Data (To Be Replaced)
- Army and Spearhead lists (currently hardcoded arrays)
- Season data (Fire and Jade, Sand and Bone)
- Board layouts (4 placeholder layouts)
- Battle Tactics (awaiting JSON/MD files)
- Twists (awaiting JSON/MD files)

### 📋 Next Steps (When Army Data Arrives)
1. Create JSON or MD files for each army with:
   - Army name and faction
   - Available Spearheads
   - Unit Warscrolls
   - Abilities with phase tags
   - Weapons and stats

2. Create Season Pack data:
   - Battle Tactics with VP values
   - Twists by round
   - Board layout definitions

3. Build data loading service:
   - Parse army files into Core Data
   - Load season packs
   - Populate Battle Tactics and Twists

## File Structure

```
Battle Roll/
├── AppDelegate.swift
├── SceneDelegate.swift
├── ContentView.swift (Main menu)
├── Models/
│   └── Game/
│       └── GameStateManager.swift
├── Services/
│   ├── DataService.swift (existing)
│   ├── PersistenceController.swift (existing)
│   ├── PhaseManager.swift (existing)
│   └── GameRecordService.swift (new)
├── Views/
│   ├── Setup/
│   │   ├── GameSetupView.swift
│   │   ├── ArmySelectionView.swift
│   │   └── SeasonSelectionView.swift
│   └── Game/
│       ├── GameDashboardView.swift
│       └── GameHistoryView.swift
└── Battle_Roll.xcdatamodeld/
    └── Battle_Roll.xcdatamodel/
        └── contents (Core Data schema)
```

## Key Design Decisions

### 1. Phase-Driven Ability Filtering
Abilities are stored with phase tags in Core Data. The dashboard automatically filters and displays only relevant abilities for the current phase, considering unit destruction status.

### 2. Automatic Battle Tactic Limiting
The system tracks how many tactics each player has used. After 3 tactics, `canPickNewTactic` is automatically set to false, with visual indicators on the dashboard.

### 3. Turn vs Round Distinction
- **Turn**: One player going through all 6 phases
- **Round**: Both players complete their turns
- Ability resets happen per turn, underdog calculation per round

### 4. Observable Game State
`GameStateManager` uses `@Published` properties, allowing all views to react to state changes automatically.

### 5. Core Data for Persistence
Game records are permanently stored, allowing full history tracking and future analytics.

## UI/UX Highlights

- **Progress Tracking**: Setup flow shows progress bar
- **Clear Phase Navigation**: Visual phase tracker with navigation controls
- **Score Prominence**: Large, clear score display with underdog indicators
- **Contextual Actions**: Buttons and options appear based on game state
- **Confirmation Dialogs**: Destructive actions (end game) require confirmation
- **Results Celebration**: Victory/defeat screen with appropriate visuals
- **Empty States**: Helpful messages when no data available

## Testing Notes

The implementation includes `#Preview` blocks for SwiftUI previews. When Xcode indexes the project:
- All views can be previewed individually
- Sample data is generated via `PersistenceController.preview`
- Game state can be simulated for testing

## Known Limitations

1. **SourceKit Diagnostics**: Some transient errors may appear until Xcode fully indexes the new files
2. **Placeholder Data**: Army and season data needs to be populated
3. **No Data Validation**: Army selection doesn't verify actual data exists yet
4. **Single Game Instance**: Only one game can be active at a time
5. **No Undo**: Actions in-game cannot be undone (by design for simplicity)

## Recommended Next Actions

1. **Open in Xcode**: Let Xcode index and validate the project
2. **Test Setup Flow**: Run the app and go through game setup
3. **Provide Army Data**: Create MD files for armies as discussed
4. **Create Season Packs**: Define JSON for seasons with tactics and twists
5. **Build Data Loader**: Implement service to parse army/season files into Core Data
