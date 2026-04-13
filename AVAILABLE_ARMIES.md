# Available Spearheads

## Currently Loaded Armies

### 1. Blades of Khorne - Bloodbound Gore Pilgrims
**General:** Slaughterpriest  
**Units:**
- 5 Blood Warriors (A)
- 5 Blood Warriors (B)
- 10 Bloodreavers
- 3 Mighty Skullcrushers

**Key Mechanics:**
- Blood Tithe point system
- Abilities in: Hero, Charge, Combat, Battleshock

---

### 2. Blades of Khorne - Fangs of the Blood God
**General:** Karanak  
**Units:**
- 5 Flesh Hounds (A)
- 5 Flesh Hounds (B)
- 8 Claws of Karanak

**Key Mechanics:**
- The Quarry targeting system
- Fast-moving daemon hounds (Move 8")
- Ward (6+) on multiple units
- Abilities in: Hero, Shooting, Charge, Combat, Battleshock

---

### 3. Cities of Sigmar - Castelite Company
**General:** Freeguild Cavalier-Marshal  
**Units:**
- 5 Freeguild Steelhelms (A)
- 5 Freeguild Steelhelms (B)
- 5 Freeguild Cavaliers
- 1 Ironweld Great Cannon

**Key Mechanics:**
- Officer's Order (tactic card manipulation)
- Artillery support with cannon
- Cavalry charges with STRIKE-FIRST
- Abilities in: Hero, Movement, Shooting, Charge, Combat, Battleshock

---

## How to Test

1. **Build and Run** the app in Xcode
2. **Start New Game**
3. **Step 1 - Your Army:**
   - Select faction: "Blades of Khorne" or "Cities of Sigmar"
   - Choose one of the spearheads listed above
4. **Step 2 - Opponent Army:**
   - Select any faction/spearhead (can pick same for testing)
5. **Step 3 - Season:**
   - Choose any season and board layout
6. **Start Game**

## Testing Abilities by Phase

### Hero Phase
- **Bloodbound:** Blood Boil, Blood Sacrifice, The Blood Tithe, Heads Must Roll, Murderlust
- **Fangs:** The Quarry, Stalk the Prey
- **Castelite:** The Officer's Order, Decisive Commander, Flask of Lethisian Darkwater

### Movement Phase
- **Castelite:** Consecrate the Land (Steelhelms)

### Shooting Phase
- **Fangs:** Evasive Hunter (passive defense)
- **Castelite:** Ironweld Discipline, Shot and Shell

### Charge Phase
- **Bloodbound:** Brass Stampede (Skullcrushers)
- **Fangs:** Unflagging Hunters, Killing Pounce
- **Castelite:** Devastating Charge (Cavaliers)

### Combat Phase
- **Bloodbound:** No Respite (Blood Warriors)
- **Fangs:** Anti-HERO, The Scent of Blood, Pack Hunters, Savagery Upon Savagery
- **Castelite:** For Sigmar Charge!, Heirloom Blade, Glimmering

### Battleshock Phase
- **Bloodbound:** Frenzied Devotion (Bloodreavers)
- **Fangs:** Blood-Drenched, Sustained by Gore, Furious Bites
- **Castelite:** Brazier of Holy Flame

## Phase Filtering Test

To verify phase filtering works:
1. Start a game
2. Navigate to different phases using the phase navigation bar
3. Tap "My Abilities"
4. **Expected:** Only abilities relevant to the current phase should appear
5. **Example:** In Hero phase, you should NOT see "Brass Stampede" (Charge) or "No Respite" (Combat)

## Unit Stats Reference

| Unit | Move | Health | Save | Special |
|------|------|--------|------|---------|
| Slaughterpriest | 5" | 6 | 4+ | General |
| Karanak | 8" | 7 | 4+ | Ward (6+) |
| Cavalier-Marshal | 10" | 7 | 3+ | Cavalry |
| Flesh Hounds | 8" | 2 | 6+ | Ward (6+) |
| Blood Warriors | 5" | 2 | 3+ | Infantry |
| Freeguild Cavaliers | 10" | 3 | 3+ | Cavalry |
| Ironweld Great Cannon | 3" | 8 | 4+ | Artillery |

---

## Adding More Spearheads

To add additional spearheads:
1. Create a new JSON file in `Battle Roll/Resources/Data/Spearheads/`
2. Follow the structure from existing files
3. Add the file to the Xcode project (Resources phase)
4. The app will automatically load it on launch

**Note:** Ensure all abilities have correct `phase` tags:
- Hero
- Movement
- Shooting
- Charge
- Combat
- Battleshock
