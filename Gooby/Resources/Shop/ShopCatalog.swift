import Foundation

enum ShopCatalog {
    static let items: [ShopItem] = clothing + furnishings + journeys + seasonalGoods

    static let byID: [String: ShopItem] = {
        var result: [String: ShopItem] = [:]
        for item in items {
            result[item.id] = item
        }
        return result
    }()

    static func make(
        _ id: String,
        _ department: ShopDepartment,
        _ anchor: ShopAnchor,
        _ draw: ShopDraw,
        _ rarity: ShopRarity,
        _ price: Int,
        _ nameDE: String,
        _ nameEN: String,
        _ blurbDE: String,
        _ blurbEN: String,
        _ primary: UInt32,
        _ secondary: UInt32,
        _ accent: UInt32,
        _ season: ShopSeason? = nil,
        _ destinationID: String? = nil
    ) -> ShopItem {
        ShopItem(
            id: id,
            department: department,
            anchor: anchor,
            draw: draw,
            rarity: rarity,
            price: price,
            nameDE: nameDE,
            nameEN: nameEN,
            blurbDE: blurbDE,
            blurbEN: blurbEN,
            primary: primary,
            secondary: secondary,
            accent: accent,
            season: season,
            destinationID: destinationID
        )
    }
}
