import Foundation

/// Language for shop, wardrobe, and room copy. German is the default.
enum ShopLanguage: String, Equatable {
    case de
    case en

    var locale: Locale {
        Locale(identifier: rawValue == "en" ? "en" : "de")
    }

    static func resolve(_ code: String?) -> ShopLanguage {
        let value = code?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if value.hasPrefix("en") {
            return .en
        }
        return .de
    }
}

enum ShopDepartment: String, Codable, CaseIterable, Identifiable, Equatable {
    case wardrobe
    case furniture
    case colors
    case travel
    case season

    var id: String { rawValue }
}

enum ShopRarity: String, Codable, CaseIterable, Identifiable, Equatable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var id: String { rawValue }

    var rank: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
}

enum ShopSeason: String, Codable, CaseIterable, Identifiable, Equatable {
    case spring
    case summer
    case autumn
    case winter

    var id: String { rawValue }

    static func of(month: Int) -> ShopSeason {
        switch month {
        case 3, 4, 5:
            return .spring
        case 6, 7, 8:
            return .summer
        case 9, 10, 11:
            return .autumn
        default:
            return .winter
        }
    }
}

/// Wear, furniture, and travel anchors. One item occupies one anchor.
enum ShopAnchor: String, Codable, CaseIterable, Identifiable, Equatable {
    case hat
    case bow
    case glasses
    case shirt
    case sweater
    case jacket
    case dress
    case pants
    case shoes
    case backpack
    case scarf
    case accessory
    case wall
    case floor
    case bed
    case rug
    case lamp
    case window
    case plant
    case shelf
    case picture
    case sofa
    case table
    case pillow
    case seasonal
    case destination

    var id: String { rawValue }

    var isWear: Bool {
        switch self {
        case .hat, .bow, .glasses, .shirt, .sweater, .jacket, .dress, .pants, .shoes, .backpack, .scarf, .accessory:
            return true
        default:
            return false
        }
    }

    var isRoom: Bool {
        switch self {
        case .wall, .floor, .bed, .rug, .lamp, .window, .plant, .shelf, .picture, .sofa, .table, .pillow, .seasonal:
            return true
        default:
            return false
        }
    }

    static var wearAnchors: [ShopAnchor] {
        allCases.filter(\.isWear)
    }

    static var roomAnchors: [ShopAnchor] {
        allCases.filter(\.isRoom)
    }
}

enum ShopDraw: String, Codable, Equatable {
    case beanie
    case cap
    case sunhat
    case beret
    case pompom
    case flowerCrown
    case bow
    case glassesRound
    case glassesSun
    case glassesStar
    case tee
    case teeHeart
    case teeStripe
    case sweater
    case hoodie
    case jacket
    case raincoat
    case vest
    case dress
    case dressTulle
    case shorts
    case trousers
    case dungarees
    case shoes
    case sneakers
    case boots
    case slippers
    case backpack
    case satchel
    case pouch
    case scarf
    case scarfPlaid
    case pinStar
    case pinFlower
    case pinBell
    case pinHeart
    case wallFill
    case floorFill
    case bedCloud
    case bedNest
    case bedCanopy
    case rugRound
    case rugOval
    case rugRunner
    case lampHoney
    case lampMushroom
    case lampMoon
    case lampOrb
    case lampLantern
    case windowArch
    case windowRound
    case windowGarden
    case plantDaisy
    case plantFern
    case plantSucculent
    case plantHanging
    case plantTulip
    case shelfCloud
    case shelfBooks
    case pictureMeadow
    case pictureMoon
    case pictureSea
    case pictureHarvest
    case sofa
    case tableRound
    case tableTea
    case pillowHeart
    case pillowStar
    case pillowRound
    case garlandBlossom
    case garlandLeaf
    case garlandLights
    case garlandShell
    case ticket
}

enum ShopDaylight: String, Codable, CaseIterable, Identifiable, Equatable {
    case auto
    case morning
    case day
    case evening
    case night

    var id: String { rawValue }

    /// Manual modes stay as chosen. Automatic follows the hour of the app date.
    func resolved(at date: Date, calendar: Calendar = .current) -> ShopDaylight {
        switch self {
        case .morning, .day, .evening, .night:
            return self
        case .auto:
            let hour = calendar.component(.hour, from: date)
            switch hour {
            case 5..<11:
                return .morning
            case 11..<17:
                return .day
            case 17..<21:
                return .evening
            default:
                return .night
            }
        }
    }
}

struct ShopItem: Identifiable, Equatable, Hashable {
    let id: String
    let department: ShopDepartment
    let anchor: ShopAnchor
    let draw: ShopDraw
    let rarity: ShopRarity
    let price: Int
    let nameDE: String
    let nameEN: String
    let blurbDE: String
    let blurbEN: String
    let primary: UInt32
    let secondary: UInt32
    let accent: UInt32
    let season: ShopSeason?
    let destinationID: String?

    func name(_ language: ShopLanguage) -> String {
        language == .en ? nameEN : nameDE
    }

    func blurb(_ language: ShopLanguage) -> String {
        language == .en ? blurbEN : blurbDE
    }
}

struct ShopOutfit: Identifiable, Equatable, Codable, Hashable {
    var id: UUID
    var name: String
    var pieces: [String: String]
    var favorite: Bool
}

struct ShopRoomDesign: Identifiable, Equatable, Codable, Hashable {
    var id: UUID
    var name: String
    var placements: [String: String]
    var lightingMode: String
    var favorite: Bool
}

struct ShopState: Equatable, Codable {
    var schema: Int
    /// Decimal token so the seed survives JSON without losing integer precision.
    var seedToken: String
    var balance: Int
    var ownedIDs: [String]
    var equipped: [String: String]
    var placements: [String: String]
    var lightingMode: String
    var outfits: [ShopOutfit]
    var roomDesigns: [ShopRoomDesign]
    var favoriteIDs: [String]
    var activeDestinationID: String?
    var previewWear: [String: String]
    var previewRoom: [String: String]

    var seedValue: UInt64 {
        UInt64(seedToken) ?? ShopEngine.bundledSeed
    }
}

struct ShopWalletBridge {
    var balance: () -> Int
    var debit: (Int) -> Bool
    var credit: (Int) -> Void
}

enum ShopTradeResult: Equatable {
    case success
    case alreadyOwned
    case notOwned
    case insufficientFunds
    case unknownItem
    case rejected
}

extension Notification.Name {
    static let goobyShopRoomDidChange = Notification.Name("gooby.shopRoom.didChange")
}

enum ShopDestinations {
    /// Same ids as the adventures place catalog.
    static let meadow = "flower-meadow"
    static let cloudland = "cloud-land"
    static let starforest = "star-forest"
    static let sugarisland = "sugar-island"
    static let crystallake = "crystal-lake"
    static let sunbeach = "sunny-beach"
    static let moonvalley = "moon-valley"
    static let fairygarden = "fairy-garden"
    static let snowvillage = "snow-village"
    static let cherrypark = "cherry-park"

    static let all = [
        meadow, cloudland, starforest, sugarisland, crystallake,
        sunbeach, moonvalley, fairygarden, snowvillage, cherrypark
    ]
}
