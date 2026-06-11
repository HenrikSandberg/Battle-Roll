# CLAUDE.md - Spearhead Strategist

## Project Overview
**Spearhead Strategist** (internal: "Battle Roll") is an iOS/iPadOS companion app for Warhammer Age of Sigmar: Spearhead battles. It tracks the full battle flow — rounds, turns, phases, abilities, twists, battle tactics, scoring and unit health — for both players.

## Technical Stack
- **UI:** SwiftUI (`@main` App lifecycle, no AppDelegate/SceneDelegate, no storyboards)
- **Persistence:** JSON files in Documents (current battle snapshot + game history). No Core Data.
- **Game data:** Bundled JSON in `Battle Roll/Resources/Data/` (armies + season packs)
- **Project format:** `objectVersion 77` with `PBXFileSystemSynchronizedRootGroup` — every file under `Battle Roll/` is automatically part of the target. Never hand-edit file lists into the pbxproj; just create files on disk.
- **Xcode:** Located at `/Volumes/External/Applications/Xcode.app`. For CLI builds:
  `DEVELOPER_DIR="/Volumes/External/Applications/Xcode.app/Contents/Developer" xcodebuild -project "Battle Roll.xcodeproj" -scheme "Battle Roll" -destination "generic/platform=iOS Simulator" build`
  (Plain `xcodebuild` fails — the default developer dir is CommandLineTools. Beware: piping output hides the real exit code.)

## Official Spearhead Rules (the app implements these exactly)
- **Battle length:** exactly 4 battle rounds, two turns per round.
- **Turn steps:** Start of Turn → Hero → Movement → Shooting → Charge → Combat → End of Turn. (No battleshock phase in AoS 4th edition.)
- **Start of round sequence:** 1) Round 1: attacker chooses first player; rounds 2–4 priority roll, winner chooses, tie → previous round's first player chooses. 2) Determine underdog (fewer VP). 3) Draw one twist card. 4) Players refill battle tactic hands to 3 (may discard first). 5) Start of Battle Round abilities.
- **Seizing the initiative:** if the player who went second last round wins priority and goes first, they draw NO battle tactic cards that round unless they are the underdog and the VP difference is ≥ 5.
- **No command points.** Commands come from battle tactic cards: each card is EITHER scored as a tactic (1 VP at end of your turn, condition met) OR discarded to use its command effect. Never both.
- **End-of-turn scoring:** +1 VP control ≥1 objective, +1 VP control ≥2, +1 VP control more than opponent, +1 VP per battle tactic completed this turn, plus any twist VP.
- **Reinforcements:** units with the Reinforcements keyword can be replaced once after being destroyed (core ability, your movement phase).
- **Army structure:** fixed composition; 1+ battle traits; pick 1 of 2 regiment abilities; pick 1 of 4 enhancements for the general (enhancement dies with the general).

## Architecture
- `Models/` — Codable structs mirroring the JSON schema (`SpearheadArmy`, `WarscrollData`, `AbilityData`, `SeasonPack`, `BattleTacticCard`, `TwistCard`). `GamePhase.swift` holds the phase/timing enums.
- `Engine/` — `BattleState` (one Codable value = entire game, trivially saved/resumed), `BattleSession` (ObservableObject driving the sequence), `PhaseEngine` (filters abilities per phase/turn/side, excludes destroyed units, surfaces tactic-card commands and core abilities).
- `Services/` — `GameDataStore` (loads bundled JSON; tolerant of flat or nested bundle layout), `SessionStore` (autosave/resume/history).
- `Views/` — `HomeView`, `Setup/SetupView`, `Battle/` (BattleView + PhaseBar, PhaseContentView, StartOfRoundView, EndOfTurnScoringSheet, TacticHandView, UnitTrackerView, GameOverView), `HistoryView`, `ArmyBrowserView`.

## Data files
- `Resources/Data/Seasons/FireAndJade.json` — twist decks (6 Aqshy + 6 Ghyran), 12 dual-use battle tactic cards, optional Desolation module. Card effects are stored as concise functional descriptions, not verbatim card text.
- `Resources/Data/Armies/*.json` — one file per Spearhead army. Schema: see `KhainiteShadowCoven.json` as the reference example. Ability timing is structured: `phase` (startOfRound/startOfTurn/hero/movement/shooting/charge/combat/endOfTurn/any), `turn` (yours/enemy/any), `window` (start/during/end/reaction), `frequency` (passive/unlimited/oncePerPhase/oncePerTurn/oncePerTurnArmy/oncePerBattle), plus the display string `timingText`.
- Source PDFs for armies live in `/Users/henrik/Downloads/armies/` (37 spearheads); rules in `/Users/henrik/Downloads/Rules/`.
- Ability timings interleave badly in PDF text extraction — verify timing labels and stat hexes (Move/Health/Save/Control) against rendered page images (`pdftoppm -png -r 200`, installed via Homebrew at `/opt/homebrew/bin/pdftoppm`).

## Engine testing
A headless smoke test exists at `/tmp/br_extract/main.swift` (compile Models+Engine with swiftc and run). Re-create something similar when changing engine logic; the engine has no UIKit dependencies by design.

## Coding Style
- SwiftUI everywhere; MVVM-ish: rules logic lives in `Engine/`, never in views.
- All game state is Codable and lives in `BattleState`; views mutate it only through `BattleSession` methods.
- New armies = drop a JSON into `Resources/Data/Armies/`. No code changes needed.
