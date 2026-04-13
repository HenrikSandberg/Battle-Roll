import Foundation
import PDFKit

/// Loads army data from JSON files or PDFs
class ArmyLoader {
    static let shared = ArmyLoader()

    private init() {}

    // MARK: - Load from JSON

    /// Load all armies from JSON files in the Resources folder
    func loadArmiesFromJSON() -> [SpearheadArmyData] {
        guard let url = Bundle.main.url(forResource: "Armies", withExtension: "json") else {
            print("❌ Armies.json not found")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let armies = try JSONDecoder().decode([SpearheadArmyData].self, from: data)
            print("✅ Loaded \(armies.count) armies from JSON")
            return armies
        } catch {
            print("❌ Error loading armies: \(error)")
            return []
        }
    }

    /// Load a single army from a JSON file
    func loadArmy(fromFile filename: String) -> SpearheadArmyData? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("❌ \(filename).json not found")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let army = try JSONDecoder().decode(SpearheadArmyData.self, from: data)
            print("✅ Loaded army: \(army.name)")
            return army
        } catch {
            print("❌ Error loading army from \(filename): \(error)")
            return nil
        }
    }

    // MARK: - PDF Parsing (Basic Text Extraction)

    /// List all PDF files in the PDFs folder
    func findArmyPDFs() -> [URL] {
        guard let resourceURL = Bundle.main.resourceURL else { return [] }
        let pdfURL = resourceURL.appendingPathComponent("PDFs")

        do {
            let contents = try FileManager.default.contentsOfDirectory(at: pdfURL, includingPropertiesForKeys: nil)
            return contents.filter { $0.pathExtension.lowercased() == "pdf" }
        } catch {
            print("❌ Error finding PDFs: \(error)")
            return []
        }
    }

    /// Extract text from a PDF file
    func extractTextFromPDF(url: URL) -> String? {
        guard let pdf = PDFDocument(url: url) else {
            print("❌ Could not open PDF: \(url.lastPathComponent)")
            return nil
        }

        var fullText = ""
        for pageIndex in 0..<pdf.pageCount {
            if let page = pdf.page(at: pageIndex),
               let text = page.string {
                fullText += text + "\n"
            }
        }

        return fullText.isEmpty ? nil : fullText
    }

    /// Parse PDF text into army data (basic implementation)
    /// NOTE: This is a template - you'll need to customize based on PDF format
    func parseArmyFromPDF(url: URL) -> SpearheadArmyData? {
        guard let text = extractTextFromPDF(url: url) else { return nil }

        // Extract army name from filename
        let armyName = url.deletingPathExtension().lastPathComponent

        // TODO: Parse the text based on your PDF format
        // This is a placeholder - real parsing depends on PDF structure

        print("📄 Extracted text from \(armyName):")
        print(text.prefix(500))  // Print first 500 chars to see format

        // For now, return nil - we'll implement parsing based on actual PDF format
        return nil
    }

    // MARK: - Import to Core Data

    /// Import army data into Core Data
    func importArmyToCoreData(_ armyData: SpearheadArmyData, context: NSManagedObjectContext) {
        // Create SpearheadArmy entity
        let army = SpearheadArmy(context: context)
        army.id = armyData.id
        army.name = armyData.name
        army.faction = armyData.faction
        army.traitName = armyData.armyTrait?.name
        army.traitDescription = armyData.armyTrait?.description

        // Create Warscroll entities for each unit
        for unitData in armyData.units {
            let warscroll = Warscroll.create(
                in: context,
                name: unitData.name,
                move: Int16(unitData.move),
                health: Int16(unitData.health),
                control: Int16(unitData.control),
                save: Int16(unitData.save),
                unitType: unitData.unitType
            )
            warscroll.army = army

            // Create Ability entities
            for (index, abilityData) in unitData.abilities.enumerated() {
                let ability = Ability.create(
                    in: context,
                    name: abilityData.name,
                    description: abilityData.description,
                    phase: GamePhase(rawValue: abilityData.phase) ?? .hero,
                    timing: AbilityTiming(rawValue: abilityData.timing) ?? .duringPhase,
                    usageLimit: AbilityUsageLimit(rawValue: abilityData.usageLimit) ?? .unlimited,
                    isPassive: abilityData.isPassive,
                    sortOrder: Int16(index)
                )
                ability.warscroll = warscroll
            }

            // Create Weapon entities
            for weaponData in unitData.weapons {
                let weapon = Weapon(context: context)
                weapon.id = weaponData.id
                weapon.name = weaponData.name
                weapon.attacks = weaponData.attacks
                weapon.hit = Int16(weaponData.hit)
                weapon.wound = Int16(weaponData.wound)
                weapon.rend = Int16(weaponData.rend)
                weapon.damage = weaponData.damage
                weapon.range = weaponData.range.map { Int16($0) }
                weapon.abilities = weaponData.abilities
                weapon.isMelee = weaponData.isMelee
                weapon.warscroll = warscroll
            }
        }

        do {
            try context.save()
            print("✅ Imported army: \(armyData.name)")
        } catch {
            print("❌ Error saving army: \(error)")
        }
    }
}
