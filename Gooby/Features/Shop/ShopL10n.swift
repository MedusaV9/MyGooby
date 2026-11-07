import Foundation

enum ShopL10n {
    enum Key: Equatable {
        case shopTitle
        case wardrobeTitle
        case roomTitle
        case todayHeading
        case todayHint
        case currencyName
        case filterAll
        case filterToday
        case filterOwned
        case filterFavorites
        case dailyBadge
        case owned
        case notEnoughTitle
        case notEnoughBody
        case buyTitle
        case buyQuestion
        case confirmBuy
        case sellTitle
        case sellQuestion
        case confirmSell
        case cancel
        case wear
        case takeOff
        case tryOn
        case use
        case sell
        case buy
        case saveOutfit
        case saveDesign
        case outfits
        case designs
        case noOutfits
        case noDesigns
        case apply
        case delete
        case favorite
        case unfavorite
        case clearSlot
        case endTryOn
        case tryOnBanner
        case previewBanner
        case lighting
        case emptyFilter
        case boughtToast
        case soldToast
        case wornToast
        case placedToast
        case savedToast
        case tripToast
        case removedToast
        case sparksLine
        case save
        case done
        case deleteQuestion
        case wearingNow
        case placedNow
        case chosenTrip
        case onlyTrying
        case roomHint
        case wardrobeHint
        case setDestination
        case outfitFallback
        case designFallback
        case piecesLine
        case auditOk
        case summarySeed
        case summaryLight
        case summaryOwned
        case summaryTrip
        case summaryToday
        case summaryAudit
        case none
        case seasonNow
        case catalogHeading
        case bunnyPlain
        case bunnyWearing
        case roomPortrait
        case namePlaceholder
        case lightLine
    }

    static func text(_ key: Key, _ language: ShopLanguage) -> String {
        let pair = pair(key)
        return language == .en ? pair.1 : pair.0
    }

    static func format(_ key: Key, _ language: ShopLanguage, _ arguments: CVarArg...) -> String {
        let template = text(key, language)
        return String(format: template, locale: language.locale, arguments: arguments)
    }

    static func sparks(_ amount: Int, _ language: ShopLanguage) -> String {
        format(.sparksLine, language, amount)
    }

    static func anchor(_ anchor: ShopAnchor, _ language: ShopLanguage) -> String {
        let pair: (String, String)
        switch anchor {
        case .hat: pair = ("Hut", "Hat")
        case .bow: pair = ("Schleife", "Bow")
        case .glasses: pair = ("Brille", "Glasses")
        case .shirt: pair = ("Shirt", "Shirt")
        case .sweater: pair = ("Pullover", "Sweater")
        case .jacket: pair = ("Jacke", "Jacket")
        case .dress: pair = ("Kleid", "Dress")
        case .pants: pair = ("Hose", "Pants")
        case .shoes: pair = ("Schuhe", "Shoes")
        case .backpack: pair = ("Rucksack", "Backpack")
        case .scarf: pair = ("Schal", "Scarf")
        case .accessory: pair = ("Accessoire", "Accessory")
        case .wall: pair = ("Wand", "Wall")
        case .floor: pair = ("Boden", "Floor")
        case .bed: pair = ("Bett", "Bed")
        case .rug: pair = ("Teppich", "Rug")
        case .lamp: pair = ("Lampe", "Lamp")
        case .window: pair = ("Fenster", "Window")
        case .plant: pair = ("Pflanze", "Plant")
        case .shelf: pair = ("Regal", "Shelf")
        case .picture: pair = ("Bild", "Picture")
        case .sofa: pair = ("Sofa", "Sofa")
        case .table: pair = ("Tisch", "Table")
        case .pillow: pair = ("Kissen", "Pillow")
        case .seasonal: pair = ("Saison", "Season")
        case .destination: pair = ("Reiseziel", "Destination")
        }
        return language == .en ? pair.1 : pair.0
    }

    static func department(_ department: ShopDepartment, _ language: ShopLanguage) -> String {
        let pair: (String, String)
        switch department {
        case .wardrobe: pair = ("Kleiderschrank", "Wardrobe")
        case .furniture: pair = ("Möbelhaus", "Furniture")
        case .colors: pair = ("Farben & Accessoires", "Colors & Accessories")
        case .travel: pair = ("Reiseagentur", "Travel Desk")
        case .season: pair = ("Saison-Shop", "Season Shop")
        }
        return language == .en ? pair.1 : pair.0
    }

    static func rarity(_ rarity: ShopRarity, _ language: ShopLanguage) -> String {
        let pair: (String, String)
        switch rarity {
        case .common: pair = ("Alltäglich", "Everyday")
        case .uncommon: pair = ("Besonders", "Special")
        case .rare: pair = ("Selten", "Rare")
        case .epic: pair = ("Zauberhaft", "Magical")
        case .legendary: pair = ("Legendär", "Legendary")
        }
        return language == .en ? pair.1 : pair.0
    }

    static func season(_ season: ShopSeason, _ language: ShopLanguage) -> String {
        let pair: (String, String)
        switch season {
        case .spring: pair = ("Frühling", "Spring")
        case .summer: pair = ("Sommer", "Summer")
        case .autumn: pair = ("Herbst", "Autumn")
        case .winter: pair = ("Winter", "Winter")
        }
        return language == .en ? pair.1 : pair.0
    }

    static func daylight(_ phase: ShopDaylight, _ language: ShopLanguage) -> String {
        let pair: (String, String)
        switch phase {
        case .auto: pair = ("Automatisch", "Automatic")
        case .morning: pair = ("Morgen", "Morning")
        case .day: pair = ("Tag", "Day")
        case .evening: pair = ("Abend", "Evening")
        case .night: pair = ("Nacht", "Night")
        }
        return language == .en ? pair.1 : pair.0
    }

    static func daylightCaption(_ phase: ShopDaylight, _ language: ShopLanguage) -> String {
        let pair: (String, String)
        switch phase {
        case .auto: pair = ("Folgt der App-Zeit", "Follows the app time")
        case .morning: pair = ("Warmes, weiches Licht", "Warm, soft light")
        case .day: pair = ("Helles, klares Licht", "Bright, clear light")
        case .evening: pair = ("Goldenes Abendlicht", "Golden evening light")
        case .night: pair = ("Ruhiges Nachtlicht", "Quiet night light")
        }
        return language == .en ? pair.1 : pair.0
    }

    static func symbol(for department: ShopDepartment) -> String {
        switch department {
        case .wardrobe: return "tshirt"
        case .furniture: return "sofa"
        case .colors: return "paintpalette"
        case .travel: return "paperplane"
        case .season: return "leaf"
        }
    }

    static func symbol(for phase: ShopDaylight) -> String {
        switch phase {
        case .auto: return "clock"
        case .morning: return "sunrise"
        case .day: return "sun.max"
        case .evening: return "sunset"
        case .night: return "moon.stars"
        }
    }

    private static func pair(_ key: Key) -> (String, String) {
        switch key {
        case .shopTitle: return ("Goobys Laden", "Gooby's Shop")
        case .wardrobeTitle: return ("Kleiderschrank", "Wardrobe")
        case .roomTitle: return ("Goobys Zimmer", "Gooby's Room")
        case .todayHeading: return ("Heute im Laden", "Today in the shop")
        case .todayHint: return ("Gleicher App-Tag, gleiche Angebote.", "Same app day, same offers.")
        case .currencyName: return ("Sternenfunken", "Star sparks")
        case .filterAll: return ("Alles", "All")
        case .filterToday: return ("Heute", "Today")
        case .filterOwned: return ("Inventar", "Inventory")
        case .filterFavorites: return ("Favoriten", "Favorites")
        case .dailyBadge: return ("Heute −20 %", "Today −20%")
        case .owned: return ("Gehört dir", "Yours")
        case .notEnoughTitle: return ("Noch nicht genug", "Not enough yet")
        case .notEnoughBody: return ("Dafür brauchst du noch mehr Sternenfunken.", "You need more star sparks for this.")
        case .buyTitle: return ("Kaufen?", "Buy this?")
        case .buyQuestion: return ("„%@“ für %@ kaufen?", "Buy “%@” for %@?")
        case .confirmBuy: return ("Ja, kaufen", "Yes, buy")
        case .sellTitle: return ("Verkaufen?", "Sell this?")
        case .sellQuestion: return ("„%@“ verkaufen und %@ zurückbekommen?", "Sell “%@” and get %@ back?")
        case .confirmSell: return ("Ja, verkaufen", "Yes, sell")
        case .cancel: return ("Abbrechen", "Cancel")
        case .wear: return ("Anlegen", "Wear")
        case .takeOff: return ("Ablegen", "Take off")
        case .tryOn: return ("Anprobieren", "Try on")
        case .use: return ("Verwenden", "Use")
        case .sell: return ("Verkaufen", "Sell")
        case .buy: return ("Kaufen", "Buy")
        case .saveOutfit: return ("Outfit speichern", "Save outfit")
        case .saveDesign: return ("Design speichern", "Save design")
        case .outfits: return ("Outfits", "Outfits")
        case .designs: return ("Designs", "Designs")
        case .noOutfits: return ("Noch kein gespeichertes Outfit.", "No saved outfit yet.")
        case .noDesigns: return ("Noch kein gespeichertes Design.", "No saved design yet.")
        case .apply: return ("Übernehmen", "Apply")
        case .delete: return ("Löschen", "Delete")
        case .favorite: return ("Favorit", "Favorite")
        case .unfavorite: return ("Favorit lösen", "Remove favorite")
        case .clearSlot: return ("Platz leeren", "Clear slot")
        case .endTryOn: return ("Anprobe beenden", "End try-on")
        case .tryOnBanner: return ("Anprobe", "Try-on")
        case .previewBanner: return ("Vorschau", "Preview")
        case .lighting: return ("Licht", "Light")
        case .emptyFilter: return ("In diesem Filter ist noch nichts.", "Nothing in this filter yet.")
        case .boughtToast: return ("Im Inventar", "In your inventory")
        case .soldToast: return ("Verkauft", "Sold")
        case .wornToast: return ("Angelegt", "Worn")
        case .placedToast: return ("Hingestellt", "Placed")
        case .savedToast: return ("Gespeichert", "Saved")
        case .tripToast: return ("Reiseziel gemerkt", "Destination saved")
        case .removedToast: return ("Abgelegt", "Taken off")
        case .sparksLine: return ("%d Sternenfunken", "%d star sparks")
        case .save: return ("Sichern", "Save")
        case .done: return ("Fertig", "Done")
        case .deleteQuestion: return ("„%@“ wirklich löschen?", "Delete “%@”?")
        case .wearingNow: return ("Angezogen", "Wearing")
        case .placedNow: return ("Im Zimmer", "In the room")
        case .chosenTrip: return ("Nächste Reise", "Next trip")
        case .onlyTrying: return ("Nur anprobiert", "Only trying this on")
        case .roomHint: return ("Stelle Möbel in die festen Plätze und wähle das Licht.", "Place furniture in the fixed slots and choose the light.")
        case .wardrobeHint: return ("Zieh Gooby an, speichere Outfits und merke dir Favoriten.", "Dress Gooby, save outfits, and keep favorites.")
        case .setDestination: return ("Als nächste Reise merken", "Set as the next trip")
        case .outfitFallback: return ("Outfit %d", "Outfit %d")
        case .designFallback: return ("Zimmer %d", "Room %d")
        case .piecesLine: return ("%d Teile", "%d pieces")
        case .auditOk: return ("Prüfungen in Ordnung", "Checks passed")
        case .summarySeed: return ("Shop-Seed", "Shop seed")
        case .summaryLight: return ("Licht", "Light")
        case .summaryOwned: return ("Inventar", "Inventory")
        case .summaryTrip: return ("Reise", "Trip")
        case .summaryToday: return ("Heute", "Today")
        case .summaryAudit: return ("Prüfungen", "Checks")
        case .none: return ("Keins", "None")
        case .seasonNow: return ("Saison: %@", "Season: %@")
        case .catalogHeading: return ("Im Regal", "On the shelf")
        case .bunnyPlain: return ("Gooby ohne Kleidung", "Gooby without clothes")
        case .bunnyWearing: return ("Gooby trägt %@", "Gooby is wearing %@")
        case .roomPortrait: return ("Goobys Zimmer bei %@ Licht", "Gooby's room in %@ light")
        case .namePlaceholder: return ("Name", "Name")
        case .lightLine: return ("%@ · %@", "%@ · %@")
        }
    }
}
