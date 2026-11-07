import Foundation

enum ShopStarter {
    static let balance = 250
    static let owned = [
        "cloth.shirt.cream",
        "cloth.pants.cloud-shorts",
        "room.wall.cream",
        "room.floor.wood",
        "room.bed.cloud",
        "room.rug.rose",
        "room.window.arch",
        "room.plant.daisy",
        "room.lamp.honey"
    ]
    static let equipped = [
        ShopAnchor.shirt.rawValue: "cloth.shirt.cream",
        ShopAnchor.pants.rawValue: "cloth.pants.cloud-shorts"
    ]
    static let placements = [
        ShopAnchor.wall.rawValue: "room.wall.cream",
        ShopAnchor.floor.rawValue: "room.floor.wood",
        ShopAnchor.bed.rawValue: "room.bed.cloud",
        ShopAnchor.rug.rawValue: "room.rug.rose",
        ShopAnchor.window.rawValue: "room.window.arch",
        ShopAnchor.plant.rawValue: "room.plant.daisy",
        ShopAnchor.lamp.rawValue: "room.lamp.honey"
    ]
}

enum ShopEngine {
    /// Stable across reinstalls. Decimal form fits in a JSON number as well as a string.
    static let bundledSeed: UInt64 = 0x600B_DA17

    static func fresh() -> ShopState {
        ShopState(
            schema: 1,
            seedToken: String(bundledSeed),
            balance: ShopStarter.balance,
            ownedIDs: ShopStarter.owned,
            equipped: ShopStarter.equipped,
            placements: ShopStarter.placements,
            lightingMode: ShopDaylight.auto.rawValue,
            outfits: [],
            roomDesigns: [],
            favoriteIDs: [],
            activeDestinationID: nil,
            previewWear: ShopStarter.equipped,
            previewRoom: [:]
        )
    }

    static func cleanName(_ raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? fallback : trimmed
        if base.count <= 24 {
            return base
        }
        return String(base.prefix(24))
    }

    static func sanitize(_ incoming: ShopState) -> ShopState {
        var state = incoming
        state.schema = 1
        if UInt64(state.seedToken) == nil {
            state.seedToken = String(bundledSeed)
        }
        if state.balance < 0 {
            state.balance = 0
        }
        var seen = Set<String>()
        state.ownedIDs = state.ownedIDs.filter { id in
            guard ShopCatalog.byID[id] != nil else { return false }
            return seen.insert(id).inserted
        }
        let owned = Set(state.ownedIDs)
        state.equipped = filteredMap(state.equipped, ownedOnly: owned, wear: true)
        state.placements = filteredMap(state.placements, ownedOnly: owned, wear: false)
        state.previewWear = filteredMap(state.previewWear, ownedOnly: nil, wear: true)
        state.previewRoom = filteredMap(state.previewRoom, ownedOnly: nil, wear: false)
        if ShopDaylight(rawValue: state.lightingMode) == nil {
            state.lightingMode = ShopDaylight.auto.rawValue
        }
        state.favoriteIDs = Array(state.favoriteIDs.filter { ShopCatalog.byID[$0] != nil }.prefix(500))
        state.outfits = Array(state.outfits.prefix(100)).map { outfit in
            var copy = outfit
            copy.name = cleanName(copy.name, fallback: "Outfit")
            copy.pieces = filteredMap(copy.pieces, ownedOnly: owned, wear: true)
            return copy
        }
        state.roomDesigns = Array(state.roomDesigns.prefix(100)).map { design in
            var copy = design
            copy.name = cleanName(copy.name, fallback: "Room")
            copy.placements = filteredMap(copy.placements, ownedOnly: owned, wear: false)
            if ShopDaylight(rawValue: copy.lightingMode) == nil {
                copy.lightingMode = ShopDaylight.auto.rawValue
            }
            return copy
        }
        if let active = state.activeDestinationID {
            let owns = state.ownedIDs.contains { ShopCatalog.byID[$0]?.destinationID == active }
            if !owns {
                state.activeDestinationID = nil
            }
        }
        return state
    }

    static func audit(catalog: [ShopItem] = ShopCatalog.items) -> [String] {
        var issues: [String] = []
        let ids = catalog.map(\.id)
        if Set(ids).count != ids.count {
            issues.append("duplicate ids")
        }
        for id in ShopStarter.owned where !ids.contains(id) {
            issues.append("missing starter \(id)")
        }
        let destinations = catalog.compactMap(\.destinationID)
        if Set(destinations).count != ShopDestinations.all.count {
            issues.append("destination count")
        }
        for place in ShopDestinations.all where !destinations.contains(place) {
            issues.append("missing place \(place)")
        }
        for department in ShopDepartment.allCases {
            if !catalog.contains(where: { $0.department == department }) {
                issues.append("empty \(department.rawValue)")
            }
        }
        for anchor in ShopAnchor.wearAnchors {
            let count = catalog.filter { $0.anchor == anchor }.count
            if count < 3 {
                issues.append("thin wear \(anchor.rawValue)")
            }
        }
        for anchor in ShopAnchor.roomAnchors {
            let count = catalog.filter { $0.anchor == anchor }.count
            if count < 2 {
                issues.append("thin room \(anchor.rawValue)")
            }
        }
        for item in catalog {
            if item.price < 40 {
                issues.append("cheap \(item.id)")
            }
            if ShopDailyOffers.sellPrice(catalogPrice: item.price) >= item.price {
                issues.append("sell \(item.id)")
            }
            if item.department == .travel && item.destinationID == nil {
                issues.append("ticket \(item.id)")
            }
            if item.department == .season && item.season == nil {
                issues.append("season \(item.id)")
            }
            if item.anchor == .destination && item.department != .travel {
                issues.append("anchor \(item.id)")
            }
        }
        let first = offers(year: 2026, month: 11, day: 7, seed: bundledSeed)
        let second = offers(year: 2026, month: 11, day: 7, seed: bundledSeed)
        if first != second {
            issues.append("offers not stable")
        }
        let nextDay = offers(year: 2026, month: 11, day: 8, seed: bundledSeed)
        if first[ShopDepartment.wardrobe.rawValue] == nextDay[ShopDepartment.wardrobe.rawValue] {
            issues.append("wardrobe offers ignore the day")
        }
        let once = sanitize(fresh())
        if sanitize(once) != once {
            issues.append("sanitize not stable")
        }
        return issues
    }

    private static func offers(year: Int, month: Int, day: Int, seed: UInt64) -> [String: [String]] {
        var result: [String: [String]] = [:]
        for department in ShopDepartment.allCases {
            let picks = ShopDailyOffers.offers(
                catalog: ShopCatalog.items,
                department: department,
                year: year,
                month: month,
                day: day,
                seed: seed
            )
            result[department.rawValue] = picks.map(\.id)
        }
        return result
    }

    private static func filteredMap(
        _ map: [String: String],
        ownedOnly: Set<String>?,
        wear: Bool
    ) -> [String: String] {
        var result: [String: String] = [:]
        for (key, id) in map {
            guard let anchor = ShopAnchor(rawValue: key) else { continue }
            if wear {
                guard anchor.isWear else { continue }
            } else {
                guard anchor.isRoom else { continue }
            }
            guard let item = ShopCatalog.byID[id], item.anchor == anchor else {
                continue
            }
            if let ownedOnly, !ownedOnly.contains(id) {
                continue
            }
            result[key] = id
        }
        return result
    }
}

extension ShopState {
    mutating func buy(item: ShopItem, price: Int, wallet: ShopWalletBridge?) -> ShopTradeResult {
        guard !ownedIDs.contains(item.id) else { return .alreadyOwned }
        guard price >= 0 else { return .rejected }
        if let wallet {
            guard wallet.debit(price) else { return .insufficientFunds }
        } else {
            guard balance >= price else { return .insufficientFunds }
            balance -= price
        }
        ownedIDs.append(item.id)
        return .success
    }

    @discardableResult
    mutating func sell(item: ShopItem, refund: Int, wallet: ShopWalletBridge?) -> Bool {
        guard ownedIDs.contains(item.id) else { return false }
        ownedIDs.removeAll { $0 == item.id }
        let key = item.anchor.rawValue
        if equipped[key] == item.id { equipped[key] = nil }
        if placements[key] == item.id { placements[key] = nil }
        if previewWear[key] == item.id { previewWear[key] = nil }
        if previewRoom[key] == item.id { previewRoom[key] = nil }
        favoriteIDs.removeAll { $0 == item.id }
        outfits = outfits.map { outfit in
            var copy = outfit
            if copy.pieces[key] == item.id {
                copy.pieces[key] = nil
            }
            return copy
        }
        roomDesigns = roomDesigns.map { design in
            var copy = design
            if copy.placements[key] == item.id {
                copy.placements[key] = nil
            }
            return copy
        }
        if item.destinationID == activeDestinationID {
            activeDestinationID = nil
        }
        if let wallet {
            wallet.credit(max(0, refund))
        } else {
            balance += max(0, refund)
        }
        return true
    }

    mutating func equip(_ item: ShopItem) {
        guard ownedIDs.contains(item.id), item.anchor.isWear else { return }
        equipped[item.anchor.rawValue] = item.id
        previewWear[item.anchor.rawValue] = item.id
    }

    mutating func stageWear(_ item: ShopItem) {
        guard item.anchor.isWear else { return }
        previewWear[item.anchor.rawValue] = item.id
    }

    mutating func clearWear(_ anchor: ShopAnchor) {
        guard anchor.isWear else { return }
        equipped[anchor.rawValue] = nil
        previewWear[anchor.rawValue] = nil
    }

    mutating func place(_ item: ShopItem) {
        guard ownedIDs.contains(item.id), item.anchor.isRoom else { return }
        placements[item.anchor.rawValue] = item.id
        previewRoom[item.anchor.rawValue] = nil
    }

    mutating func stageRoom(_ item: ShopItem) {
        guard item.anchor.isRoom else { return }
        previewRoom[item.anchor.rawValue] = item.id
    }

    mutating func clearRoom(_ anchor: ShopAnchor) {
        guard anchor.isRoom else { return }
        placements[anchor.rawValue] = nil
        previewRoom[anchor.rawValue] = nil
    }

    mutating func alignPreviewWithEquipped() {
        previewWear = equipped
        previewRoom = [:]
    }

    mutating func toggleFavorite(itemID: String) {
        if let index = favoriteIDs.firstIndex(of: itemID) {
            favoriteIDs.remove(at: index)
        } else if ShopCatalog.byID[itemID] != nil {
            favoriteIDs.append(itemID)
        }
    }

    mutating func storeOutfit(named raw: String, fallback: String) {
        let outfit = ShopOutfit(
            id: UUID(),
            name: ShopEngine.cleanName(raw, fallback: fallback),
            pieces: equipped,
            favorite: false
        )
        outfits.append(outfit)
    }

    mutating func apply(outfit: ShopOutfit) {
        equipped = outfit.pieces
        previewWear = outfit.pieces
    }

    mutating func deleteOutfit(id: UUID) {
        outfits.removeAll { $0.id == id }
    }

    mutating func toggleOutfitFavorite(id: UUID) {
        guard let index = outfits.firstIndex(where: { $0.id == id }) else { return }
        outfits[index].favorite.toggle()
    }

    mutating func storeDesign(named raw: String, fallback: String) {
        let design = ShopRoomDesign(
            id: UUID(),
            name: ShopEngine.cleanName(raw, fallback: fallback),
            placements: placements,
            lightingMode: lightingMode,
            favorite: false
        )
        roomDesigns.append(design)
    }

    mutating func apply(design: ShopRoomDesign) {
        placements = design.placements
        lightingMode = design.lightingMode
        previewRoom = [:]
    }

    mutating func deleteDesign(id: UUID) {
        roomDesigns.removeAll { $0.id == id }
    }

    mutating func toggleDesignFavorite(id: UUID) {
        guard let index = roomDesigns.firstIndex(where: { $0.id == id }) else { return }
        roomDesigns[index].favorite.toggle()
    }

    mutating func setLighting(_ mode: ShopDaylight) {
        lightingMode = mode.rawValue
    }

    mutating func activate(item: ShopItem) {
        guard ownedIDs.contains(item.id), let place = item.destinationID else { return }
        activeDestinationID = place
    }

    mutating func unlockAll(catalog: [ShopItem]) {
        let owned = Set(ownedIDs)
        for item in catalog where !owned.contains(item.id) {
            ownedIDs.append(item.id)
        }
    }

    mutating func resetInventory() {
        ownedIDs = ShopStarter.owned
        equipped = ShopStarter.equipped
        placements = ShopStarter.placements
        previewWear = ShopStarter.equipped
        previewRoom = [:]
        outfits = []
        roomDesigns = []
        favoriteIDs = []
        activeDestinationID = nil
    }
}
