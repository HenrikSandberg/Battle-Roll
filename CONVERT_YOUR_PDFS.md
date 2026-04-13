# How to Convert Your PDF Spearhead Armies

## 📋 Quick Start

You have PDFs of Spearhead armies. Here's the fastest way to get them into the app:

## Option 1: Tell Me What You Have (Recommended)

**I can help you create the JSON files!**

Please tell me:
1. **What's in the PDF folder?** List the army names (e.g., "Stormcast Eternals", "Orruk Warclans", etc.)
2. **Open one PDF** and tell me:
   - Can you select/copy the text? (If yes, it's parseable!)
   - Is it a scan/image? (If yes, we'll do manual entry)
3. **Share a sample** - Copy/paste 10-15 lines from one PDF so I can see the format

Then I can either:
- ✅ Create a custom PDF parser for your specific format
- ✅ Create template JSON files you just fill in
- ✅ Generate complete JSON files if you share the text

## Option 2: Manual Conversion (30-45 min per army)

### Step-by-Step for One Army

**Example: Converting "Stormcast Eternals" PDF**

1. **Create new file**: `StormcastEternals.json`

2. **Start with template structure**:
```json
{
  "id": "NEW-UUID-HERE",
  "name": "Army Name from PDF",
  "faction": "Faction Name",
  "armyTrait": {
    "name": "Trait Name",
    "description": "Trait description from PDF",
    "phase": "Hero"
  },
  "units": []
}
```

3. **For each unit in the PDF**, add this structure to the `units` array:

```json
{
  "id": "UNIT-UUID-HERE",
  "name": "Unit Name from PDF",
  "move": 5,
  "health": 10,
  "control": 1,
  "save": 3,
  "unitType": "Infantry",
  "weapons": [],
  "abilities": []
}
```

4. **For each weapon**, add to `weapons` array:

```json
{
  "id": "WEAPON-UUID-HERE",
  "name": "Weapon name",
  "attacks": "2",
  "hit": 3,
  "wound": 3,
  "rend": 1,
  "damage": "1",
  "range": null,
  "abilities": null
}
```

5. **For each ability**, add to `abilities` array:

```json
{
  "id": "ABILITY-UUID-HERE",
  "name": "Ability name",
  "description": "Full text from PDF",
  "phase": "Combat",
  "timing": "During Phase",
  "usageLimit": "Unlimited",
  "isPassive": true
}
```

### Field Mapping Guide

When reading your PDF, map like this:

#### Stats Bar (usually at top of warscroll)
```
PDF Shows:        JSON Field:
Move 5"       →   "move": 5
Health 10     →   "health": 10
Control 1     →   "control": 1
Save 3+       →   "save": 3
```

#### Weapon Profiles (usually a table)
```
PDF Column:        JSON Field:
Atk/Attacks    →   "attacks": "2" or "D6"
Hit/To Hit     →   "hit": 3 (for 3+)
Wnd/Wound      →   "wound": 4 (for 4+)
Rnd/Rend       →   "rend": 1 (for -1)
Dmg/Damage     →   "damage": "1" or "D3"
Rng/Range      →   "range": 12 or null (melee)
```

#### Phases (when ability is used)
```
PDF Text:                                    JSON:
"at the start of your hero phase"       →   "phase": "Hero", "timing": "Start of Phase"
"in your movement phase"                 →   "phase": "Movement", "timing": "During Phase"
"after this unit shoots"                 →   "phase": "Shooting", "timing": "During Phase"
"when you pick this unit to charge"      →   "phase": "Charge", "timing": "During Phase"
"after this unit fights"                 →   "phase": "Combat", "timing": "During Phase"
"at the end of battleshock phase"        →   "phase": "Battleshock", "timing": "End of Phase"
"this unit has Ward (6+)" (passive)      →   "phase": "Combat", "timing": "Passive", "isPassive": true
```

#### Usage Limits
```
PDF Says:                                JSON:
(no limit mentioned)                 →   "usageLimit": "Unlimited"
"once per turn"                      →   "usageLimit": "Once Per Turn"
"once per battle"                    →   "usageLimit": "Once Per Game"
"you can use this ability once"      →   "usageLimit": "Once Per Game"
```

### Real Example

**PDF shows**:
```
VINDICTORS
Move 5" | Health 10 | Control 1 | Save 3+

MELEE WEAPONS
Stormspear: Atk 2, Hit 3+, Wound 3+, Rend -1, Dmg 1, Charge (+1 Damage)

ABILITIES
Champion: This unit includes a Vindictor-Prime. Add 1 to the Attacks
characteristic of that model's melee weapons.
```

**Becomes JSON**:
```json
{
  "id": "generated-uuid",
  "name": "Vindictors",
  "move": 5,
  "health": 10,
  "control": 1,
  "save": 3,
  "unitType": "Infantry",
  "weapons": [
    {
      "id": "generated-uuid",
      "name": "Stormspear",
      "attacks": "2",
      "hit": 3,
      "wound": 3,
      "rend": 1,
      "damage": "1",
      "range": null,
      "abilities": "Charge (+1 Damage)"
    }
  ],
  "abilities": [
    {
      "id": "generated-uuid",
      "name": "Champion",
      "description": "This unit includes a Vindictor-Prime. Add 1 to the Attacks characteristic of that model's melee weapons.",
      "phase": "Combat",
      "timing": "During Phase",
      "usageLimit": "Unlimited",
      "isPassive": true
    }
  ]
}
```

## Option 3: Automated Extraction

If you can share the PDF folder path or copy/paste the PDF text, I can:

1. **Extract all text automatically**
2. **Parse it into the JSON format**
3. **Generate complete ready-to-use JSON files**

Just need to see the format once!

## 🔧 Tools You'll Need

### UUID Generator
**Go to**: https://uuidgenerator.net/version4

Click "Generate" for each:
- Army ID (1 per army)
- Unit IDs (1 per unit)
- Weapon IDs (1 per weapon)
- Ability IDs (1 per ability)

Or use bulk generate and copy into a text file.

### JSON Validator
**Go to**: https://jsonlint.com

Paste your JSON and click "Validate" to check for errors.

## ⚡ Speed Tips

### Fastest Workflow

1. **Generate UUIDs in batch** - Get 50+ at once, paste into text file
2. **Copy template** for each unit
3. **Fill in stats first** (easiest part)
4. **Then weapons** (straightforward table)
5. **Finally abilities** (need to read carefully for phase)

### Common Mistakes

❌ **Using `Move 5"` instead of `5`** - Remove the quote mark
❌ **Using `3+` instead of `3`** - Just the number
❌ **Misspelling phase** - Must match exactly: Hero, Movement, Shooting, Charge, Combat, Battleshock
❌ **Forgetting commas** - Each item needs a comma except the last
❌ **Wrong quotes** - Use `"` not `'` or `"`

## 📊 Time Estimates

**Per Army** (typical Spearhead has 4-5 units):
- Generate UUIDs: 2 min
- Army header + trait: 3 min
- First unit (learning): 15 min
- Subsequent units: 7-10 min each
- Validation & testing: 5 min

**Total: ~30-45 minutes per army**

**After your first army, you'll be much faster!**

## 🎯 Recommended Approach

### Week 1: Start Small
- Pick your **favorite army**
- Convert **just that one**
- Test in app thoroughly
- Refine the process

### Week 2: Batch Convert
- Convert 2-3 more armies
- Create your own shortcuts/templates
- Find your rhythm

### Week 3: Finish Up
- Convert remaining armies
- Build complete collection

## 🆘 Get Help From Me

Instead of doing this all yourself, you can:

### Share the PDFs
If you can share (or describe in detail):
1. List of army names
2. Sample text from one PDF
3. Format/structure of the PDFs

I can:
✅ Build a custom parser for your specific PDF format
✅ Generate template JSON with structure already in place
✅ Create complete JSON files if you share the raw text

### What I Need

Just respond with:
```
1. My PDF folder has these armies:
   - Stormcast Eternals
   - Orruk Warclans
   - [list others]

2. Here's text from one PDF: [copy/paste 15-20 lines]

3. Format: [Text is selectable / Is scanned images]
```

Then I can help automate this!

## 📱 Once You Have JSON

1. Add JSON files to Xcode project
2. In app: Army Selection → Import
3. Select army to import
4. Done! Army is now usable in battles

---

**Ready to convert?** Start with one army or let me help automate it!
