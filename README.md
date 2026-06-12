# Battle Roll — Spearhead Strategist

An iOS/iPadOS companion app for **Warhammer Age of Sigmar: Spearhead** battles. It tracks the full battle flow — rounds, turns, phases, abilities, twists, battle tactics, scoring, and unit health — for both players simultaneously.

## Features

- **Full battle sequence** — Start of Round → Hero → Movement → Shooting → Charge → Combat → End of Turn, all four rounds
- **Phase-filtered abilities** — Only shows abilities relevant to the current phase and turn, for both players at once
- **Battle tactic cards** — Hidden hand tracking (opponents can't see your cards until played), dual-use as tactic (score VP) or command (discard to use the effect)
- **Live scoring** — VP tracked per round, objective control, battle tactics, twist bonuses
- **Unit health tracking** — Per-unit casualty tracking; destroyed units disappear from the ability list
- **Twist cards** — Draw from the season pack's twist deck each round
- **Army browser** — Full reference for every loaded Spearhead army: stats, weapons, abilities
- **Battle history** — Review past games

**Supported season packs:** Fire and Jade (Aqshy + Ghyran), Sand and Bone (Dolorum + Ossia)

---

## Project Structure

```
Battle Roll/
├── Models/              # Codable structs mirroring the JSON schema
│   ├── SpearheadArmy.swift     # Army, warscroll, weapon, ability models
│   ├── SeasonPack.swift        # Season, realm, twist card, battle tactic models
│   ├── BattleTacticCard.swift
│   └── GamePhase.swift         # Phase/timing enums
├── Engine/              # Game logic — no UIKit dependencies
│   ├── BattleState.swift       # Entire game state, Codable (trivially saved/resumed)
│   ├── BattleSession.swift     # ObservableObject driving the turn sequence
│   └── PhaseEngine.swift       # Filters abilities per phase/turn/side
├── Services/
│   ├── GameDataStore.swift     # Loads bundled JSON; tolerant of flat/nested bundle layout
│   └── SessionStore.swift      # Autosave/resume/history
├── Views/
│   ├── HomeView.swift
│   ├── Setup/SetupView.swift   # Pre-battle: season → armies → regiment → attacker
│   ├── Battle/                 # BattleView, PhaseContentView, TacticHandView, etc.
│   ├── ArmyBrowserView.swift   # Grand Alliance → Faction → Army reference browser
│   ├── HistoryView.swift
│   └── Theme.swift             # SpearheadTheme colors, gradients, per-alliance/phase accents
└── Resources/
    └── Data/
        ├── Armies/             # One JSON file per Spearhead army
        └── Seasons/            # One JSON file per season pack
```

### Architecture principles

- **SwiftUI everywhere** — MVVM-ish: rules logic lives in `Engine/`, never in views
- **All game state is Codable** — stored in `BattleState`; views mutate it only through `BattleSession` methods
- **Auto-included files** — the Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so every file dropped into `Battle Roll/` is automatically part of the build target
- **Persistence** — JSON snapshot in Documents; no Core Data

---

## Adding a New Spearhead Army

Drop a single JSON file into `Battle Roll/Resources/Data/Armies/`. No code changes needed — `GameDataStore` picks it up automatically on next launch.

### Army JSON schema

```jsonc
{
  "id": "kebab-case-army-name",         // unique, kebab-case
  "name": "Army Name As Printed",        // Title Case, e.g. "Heartflayer Troupe"
  "faction": "Faction Name",             // e.g. "Daughters of Khaine"
  "grandAlliance": "Order",              // Order | Chaos | Death | Destruction
  "battleTraits": [ /* Ability, ... */ ],
  "regimentAbilities": [ /* Ability × 2 */ ],   // player picks 1
  "enhancements": [ /* Ability × 4 */ ],         // player picks 1 for the general
  "units": [ /* Warscroll, ... */ ]
}
```

#### Ability

```jsonc
{
  "name": "Name As Printed",
  "declare": "Declare text",           // omit key entirely if no Declare section
  "effect": "Effect text",
  "timingText": "Once Per Turn, Any Combat Phase",  // the printed timing bar text
  "phase": "hero",        // startOfRound | startOfTurn | hero | movement | shooting
                          // | charge | combat | endOfTurn | deployment | any
  "turn": "any",          // yours | enemy | any
  "window": "during",     // start | during | end | reaction
  "frequency": "oncePerTurn"
                          // passive | unlimited | oncePerPhase | oncePerTurn
                          // | oncePerTurnArmy | oncePerBattle
}
```

**Timing → fields quick reference:**

| Timing bar text | phase | turn | window | frequency |
|---|---|---|---|---|
| Passive (gold/grey header) | `any` | `any` | `during` | `passive` |
| Your Hero Phase | `hero` | `yours` | `during` | `unlimited` |
| Enemy Movement Phase | `movement` | `enemy` | `during` | `unlimited` |
| Any Combat Phase | `combat` | `any` | `during` | `unlimited` |
| Once Per Turn, Any Combat Phase | `combat` | `any` | `during` | `oncePerTurn` |
| Once Per Battle, Your Hero Phase | `hero` | `yours` | `during` | `oncePerBattle` |
| Start of Your Turn | `startOfTurn` | `yours` | `start` | `unlimited` |
| Reaction: … | `any`* | `any` | `reaction` | `unlimited` |
| Start of Battle Round | `startOfRound` | `any` | `start` | `unlimited` |

*Set `phase` to the phase the trigger occurs in, or `any` if it depends on an attack ability that can happen in shooting or combat.

#### Warscroll

```jsonc
{
  "name": "Unit Name",
  "isGeneral": false,          // true for the unit listed under GENERAL on page 1
  "instances": 1,              // how many times this unit appears in the army list
  "modelsPerUnit": 5,          // models in one instance; heroes/monsters → 1
  "move": "6\"",
  "health": 2,                 // per model
  "save": "4+",
  "control": 1,
  "keywords": ["Infantry", "Ward (6+)"],
  "reinforcements": false,     // true if the unit has the circular-arrows icon on page 1
  "rangedWeapons": [ /* Weapon */ ],
  "meleeWeapons": [ /* Weapon */ ],
  "abilities": [ /* Ability */ ]
}
```

#### Weapon

```jsonc
{
  "name": "Weapon Name",
  "range": "12\"",             // ranged weapons only; omit for melee
  "attacks": "2",
  "hit": "3+",
  "wound": "4+",
  "rend": "1",                 // use "0" when the card shows "-"
  "damage": "1",
  "abilities": ["Crit (Mortal)"]   // bracketed weapon abilities; [] if none
}
```

---

## Adding a New Season Pack

Drop a single JSON file into `Battle Roll/Resources/Data/Seasons/`. See `FireAndJade.json` for the full structure.

```jsonc
{
  "id": "season-id",
  "name": "Season Name",
  "realms": [
    {
      "id": "realm-id",
      "name": "Realm Name",
      "subtitle": "Descriptive subtitle"
    }
  ],
  "twistCards": [ /* TwistCard × 12 per realm side */ ],
  "battleTactics": [ /* BattleTacticCard × 12 */ ],
  "modules": [ /* optional expansion modules */ ]
}
```

### TwistCard

```jsonc
{
  "id": "unique-id",
  "name": "Card Name",
  "realmID": "realm-id",       // which realm side this card belongs to
  "effect": "Effect text"
}
```

### BattleTacticCard

```jsonc
{
  "id": "unique-id",
  "name": "Card Name",
  "tacticCondition": "Score 1 VP at end of your turn if…",
  "commandEffect": "Alternative command effect when discarded"
}
```

---

## Development Setup

Requires Xcode (tested with Xcode 16+) on macOS. No external dependencies.

```bash
open "Battle Roll.xcodeproj"
```

Or build from the CLI (requires Xcode at the default location — adjust the path if needed):

```bash
DEVELOPER_DIR="/Volumes/External/Applications/Xcode.app/Contents/Developer" \
  xcodebuild \
    -project "Battle Roll.xcodeproj" \
    -scheme "Battle Roll" \
    -destination "generic/platform=iOS Simulator" \
    build
```

---

## Contributing

Pull requests welcome, especially:
- New army JSON files (see schema above)
- New season pack JSON files
- Bug fixes in the game engine
- UI/UX improvements

Please open an issue before large refactors or new features so we can discuss the approach first.

---

## Legal

This is a fan-made companion tool. Warhammer Age of Sigmar and Spearhead are trademarks of Games Workshop Ltd. All rule names, ability text, and card text are property of Games Workshop and are reproduced here solely for personal, non-commercial use.
