## PDF Army Import Guide

I've created a complete system to import Spearhead armies from PDFs into the app! Here's how to use it:

## ✅ What I Built

### 1. Data Models (`ArmyData.swift`)
- `SpearheadArmyData` - Complete army structure
- `UnitData` - Warscroll with stats
- `WeaponData` - Weapon profiles
- `AbilityData` - Phase-tagged abilities

### 2. Army Loader (`ArmyLoader.swift`)
- PDF text extraction
- JSON importing
- Core Data conversion

### 3. UI Components
- **ArmySelectionView** - Browse and import armies
- **ArmyDetailView** - View full warscrolls and rules
- **PDFImportView** - Extract text from PDFs

## 🚀 Quick Start: Using Your PDFs

### Option A: Manual JSON Creation (Recommended)

Since PDF parsing depends heavily on the PDF format, the fastest way is to create JSON files manually:

1. **Create a folder**: `Battle Roll/Resources/Armies/`

2. **Create JSON files** for each army (see template below)

3. **Add to Xcode**:
   - Right-click `Resources` folder
   - Add Files to "Battle Roll"
   - Select all JSON files
   - Check "Copy items if needed"
   - Check "Battle Roll" target

4. **Launch app** → Army Selection → Import!

### Option B: PDF Text Extraction (Advanced)

If your PDFs have selectable text (not scanned images):

1. **Create folder**: `Battle Roll/Resources/PDFs/`

2. **Add PDF files to Xcode**:
   - Drag PDFs into the PDFs folder
   - Check "Copy items if needed"
   - Check "Battle Roll" target

3. **In app**: Tap "Import from PDF" to extract text

4. **Read the output** in Xcode console to see PDF structure

5. **Create custom parser** based on your PDF format

## 📄 JSON Template

Create a file named `StormcastEternals.json`:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "Stormcast Eternals - Hallowed Knights",
  "faction": "Stormcast Eternals",
  "armyTrait": {
    "name": "Only the Faithful",
    "description": "Once per turn, you can return 1 slain model to a friendly Hallowed Knights unit.",
    "phase": "Hero"
  },
  "units": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Lord-Vigilant on Gryph-stalker",
      "move": 9,
      "health": 12,
      "control": 2,
      "save": 3,
      "unitType": "Cavalry Hero",
      "weapons": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440010",
          "name": "Gryph-stalker's Razor Beak",
          "attacks": "3",
          "hit": 3,
          "wound": 3,
          "rend": 2,
          "damage": "2",
          "range": null,
          "abilities": null
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440011",
          "name": "Warden's Halberd",
          "attacks": "4",
          "hit": 3,
          "wound": 3,
          "rend": 1,
          "damage": "2",
          "range": null,
          "abilities": null
        }
      ],
      "abilities": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440020",
          "name": "Lord of the Host",
          "description": "Add 1 to run rolls and charge rolls for friendly units wholly within 12\" of this unit.",
          "phase": "Movement",
          "timing": "During Phase",
          "usageLimit": "Unlimited",
          "isPassive": true
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440021",
          "name": "Gryph-stalker's Swiftness",
          "description": "This unit can run and still charge in the same turn.",
          "phase": "Movement",
          "timing": "During Phase",
          "usageLimit": "Unlimited",
          "isPassive": true
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "name": "Liberators",
      "move": 5,
      "health": 10,
      "control": 1,
      "save": 3,
      "unitType": "Infantry",
      "weapons": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440012",
          "name": "Warhammer",
          "attacks": "2",
          "hit": 3,
          "wound": 3,
          "rend": 1,
          "damage": "1",
          "range": null,
          "abilities": null
        }
      ],
      "abilities": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440022",
          "name": "Lay Low the Tyrant",
          "description": "Add 1 to wound rolls for attacks made by this unit that target enemy Heroes.",
          "phase": "Combat",
          "timing": "During Phase",
          "usageLimit": "Unlimited",
          "isPassive": true
        }
      ]
    }
  ]
}
```

## 📊 JSON Field Guide

### Army Level
- **id**: Generate unique UUID (use https://uuidgenerator.net)
- **name**: Full army name with variant
- **faction**: Grand Alliance or faction name
- **armyTrait**: Optional army-wide rule

### Unit Level
- **id**: Unique UUID for each unit
- **name**: Warscroll name
- **move**: Movement in inches (number only)
- **health**: Total wounds
- **control**: Control characteristic
- **save**: Save characteristic (3 = 3+, 4 = 4+, etc.)
- **unitType**: "Infantry", "Cavalry", "Monster", "Hero", "War Machine"

### Weapon Level
- **id**: Unique UUID
- **name**: Weapon name
- **attacks**: Can be "3", "D6", "2D3", etc.
- **hit**: Hit roll (3 = 3+)
- **wound**: Wound roll (3 = 3+)
- **rend**: Rend value (0 for no rend, 1 for -1, etc.)
- **damage**: Can be "1", "D3", "2", etc.
- **range**: `null` for melee, number for ranged
- **abilities**: Special weapon abilities (e.g., "Crit (2 Hits)")

### Ability Level
- **id**: Unique UUID
- **name**: Ability name
- **description**: Full text of the ability
- **phase**: Must be one of:
  - `"Hero"`
  - `"Movement"`
  - `"Shooting"`
  - `"Charge"`
  - `"Combat"`
  - `"Battleshock"`
- **timing**: One of:
  - `"Start of Phase"`
  - `"During Phase"`
  - `"End of Phase"`
  - `"Passive"`
- **usageLimit**: One of:
  - `"Unlimited"`
  - `"Once Per Turn"`
  - `"Once Per Game"`
- **isPassive**: `true` for always-on abilities, `false` for activated

## 🛠️ Creating JSON from PDFs

### Step 1: Extract Unit Names
Open your PDF and list all units:
- Heroes
- Core units
- Special units

### Step 2: For Each Unit, Note:
- **Stats bar**: Move, Health, Control, Save
- **Weapons table**: Attacks, Hit, Wound, Rend, Damage, Range
- **Abilities section**: Name, text, when it's used

### Step 3: Identify Phases
Match each ability to a phase:
- Buffs/healing → **Hero**
- Movement bonuses → **Movement**
- Shooting attacks → **Shooting**
- Charge bonuses → **Charge**
- Combat bonuses → **Combat**
- Bravery/morale → **Battleshock**

### Step 4: Build the JSON
- Start with the template above
- Replace values with your army's data
- Add/remove units as needed
- Generate new UUIDs for each item

## 📱 Using Imported Armies

### 1. Select Army
In the main app, tap "Select Army" → Choose from imported armies

### 2. View Warscrolls
Tap any unit to see:
- Full stats
- All weapons with profiles
- All abilities organized by phase

### 3. Use in Battle
Once selected, the army is available to:
- Track unit health
- Filter abilities by current phase
- Mark abilities as used

## 🎯 Example Armies

I've included one sample army (Stormcast Eternals). You can use it as a template for your PDFs.

### Common Spearhead Armies:
- Stormcast Eternals
- Orruk Warclans (Kruleboyz)
- Nighthaunt
- Ossiarch Bonereapers
- Skaven
- Daughters of Khaine
- Lumineth Realm-lords
- Seraphon
- Cities of Sigmar
- Slaves to Darkness

## 🔧 Troubleshooting

### "No armies found to import"
- Check that JSON files are in `Resources/Armies/`
- Verify files are added to Xcode target
- Check JSON syntax (use JSONLint.com to validate)

### "Failed to decode army"
- Verify all required fields are present
- Check phase names match exactly (case-sensitive)
- Ensure UUIDs are valid format
- Validate JSON syntax

### PDF text extraction shows gibberish
- PDF is likely scanned images, not text
- Use manual JSON creation instead
- Or use OCR tool first, then clean up text

## 📚 Batch Creating Armies

### Quick Workflow:
1. **Create template** - Save `template.json` with structure
2. **For each army**:
   - Duplicate template
   - Rename to army name
   - Update all fields
   - Generate new UUIDs
3. **Validate** - Use JSONLint.com
4. **Import** - Add all to Xcode

### Tools to Help:
- **UUID Generator**: https://uuidgenerator.net (bulk generate)
- **JSON Validator**: https://jsonlint.com
- **JSON Formatter**: https://jsonformatter.org

## 🚀 Next Steps

1. **Create your first army JSON** using the template
2. **Test import** in the app
3. **Refine** based on how it looks
4. **Create more armies** using the same pattern

## 💡 Pro Tips

- **Start small** - Do one army completely before batch creating
- **Use consistent naming** - Makes abilities easier to find
- **Test in app frequently** - Catch errors early
- **Keep PDFs reference** - For double-checking stats
- **Version control** - Save JSON files in git

## 🆘 Need Help?

If you get stuck:
1. Check JSON syntax with validator
2. Compare against template
3. Check Xcode console for specific errors
4. Verify all phase names are spelled correctly

---

**Ready to import your armies!** Start with one JSON file and expand from there.
