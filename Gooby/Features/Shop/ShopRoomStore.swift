import Foundation
import Observation

enum ShopBrowserFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case owned
    case favorites

    var id: String { rawValue }
}

@MainActor
@Observable
final class ShopRoomStore {
    static let shared = ShopRoomStore()

    private(set) var state: ShopState
    private(set) var clock: Date
    var language: ShopLanguage
    private(set) var shownBalance: Int
    private(set) var tradeTick: Int

    @ObservationIgnored private var trading = false
    @ObservationIgnored private var wallet: ShopWalletBridge?
    @ObservationIgnored private var dateProvider: () -> Date
    @ObservationIgnored private var dateOverride: Date?
    @ObservationIgnored private var languagePinned = false

    private init() {
        let loaded = ShopEngine.sanitize(ShopPersistence.load())
        state = loaded
        clock = Date()
        language = .de
        shownBalance = loaded.balance
        tradeTick = 0
        dateProvider = { Date() }
        ShopPersistence.save(state)
        adoptShellLanguageIfNeeded()
    }

    func syncClock() {
        adoptShellLanguageIfNeeded()
        let next = dateOverride ?? dateProvider()
        if clock != next {
            clock = next
        }
        refreshBalance()
    }

    func setLanguage(code: String) {
        languagePinned = true
        let resolved = ShopLanguage.resolve(code)
        if resolved != language {
            language = resolved
        }
    }

    func bindWallet(_ bridge: ShopWalletBridge?) {
        wallet = bridge
        refreshBalance()
    }

    func bindDateProvider(_ provider: @escaping () -> Date) {
        dateProvider = provider
        if dateOverride == nil {
            clock = provider()
        }
    }

    func refreshBalance() {
        let next = max(0, wallet?.balance() ?? state.balance)
        if next != shownBalance {
            shownBalance = next
        }
    }

    func dayParts() -> (year: Int, month: Int, day: Int) {
        let parts = ShopDailyOffers.dayParts(of: clock)
        return (parts.year, parts.month, parts.day)
    }

    func currentSeason() -> ShopSeason {
        ShopSeason.of(month: dayParts().month)
    }

    func offers(for department: ShopDepartment) -> [ShopItem] {
        let parts = dayParts()
        return ShopDailyOffers.offers(
            catalog: ShopCatalog.items,
            department: department,
            year: parts.year,
            month: parts.month,
            day: parts.day,
            seed: state.seedValue
        )
    }

    func isDaily(_ item: ShopItem) -> Bool {
        offers(for: item.department).contains { $0.id == item.id }
    }

    func price(for item: ShopItem) -> Int {
        ShopDailyOffers.salePrice(catalogPrice: item.price, discounted: isDaily(item))
    }

    func refund(for item: ShopItem) -> Int {
        ShopDailyOffers.sellPrice(catalogPrice: item.price)
    }

    func owns(_ id: String) -> Bool {
        state.ownedIDs.contains(id)
    }

    func isFavorite(_ id: String) -> Bool {
        state.favoriteIDs.contains(id)
    }

    func lightingMode() -> ShopDaylight {
        ShopDaylight(rawValue: state.lightingMode) ?? .auto
    }

    func resolvedPhase() -> ShopDaylight {
        lightingMode().resolved(at: clock)
    }

    func resolved(_ map: [String: String]) -> [ShopAnchor: ShopItem] {
        var result: [ShopAnchor: ShopItem] = [:]
        for (key, id) in map {
            guard let anchor = ShopAnchor(rawValue: key), let item = ShopCatalog.byID[id] else { continue }
            result[anchor] = item
        }
        return result
    }

    func wardrobeChoices(for anchor: ShopAnchor) -> [ShopItem] {
        let season = currentSeason()
        let items = ShopCatalog.items.filter { item in
            guard item.anchor == anchor else { return false }
            if owns(item.id) { return true }
            if let itemSeason = item.season { return itemSeason == season }
            return item.department == .wardrobe || item.department == .colors
        }
        return sorted(items)
    }

    func roomChoices(for anchor: ShopAnchor) -> [ShopItem] {
        let season = currentSeason()
        let items = ShopCatalog.items.filter { item in
            guard item.anchor == anchor else { return false }
            if owns(item.id) { return true }
            if let itemSeason = item.season { return itemSeason == season }
            return item.department == .furniture || item.department == .colors
        }
        return sorted(items)
    }

    func browserItems(department: ShopDepartment, filter: ShopBrowserFilter) -> [ShopItem] {
        let season = currentSeason()
        let daily = Set(offers(for: department).map(\.id))
        let visible = ShopCatalog.items.filter { item in
            guard item.department == department else { return false }
            if let itemSeason = item.season, itemSeason != season, !owns(item.id) {
                return false
            }
            return true
        }
        let filtered: [ShopItem]
        switch filter {
        case .all:
            filtered = visible
        case .today:
            filtered = visible.filter { daily.contains($0.id) }
        case .owned:
            filtered = visible.filter { owns($0.id) }
        case .favorites:
            filtered = visible.filter { isFavorite($0.id) }
        }
        return filtered.sorted { lhs, rhs in
            let leftDaily = daily.contains(lhs.id)
            let rightDaily = daily.contains(rhs.id)
            if leftDaily != rightDaily { return leftDaily && !rightDaily }
            if lhs.rarity.rank != rhs.rarity.rank { return lhs.rarity.rank > rhs.rarity.rank }
            return lhs.name(language) < rhs.name(language)
        }
    }

    func buy(id: String) -> ShopTradeResult {
        guard !trading else { return .rejected }
        guard let item = ShopCatalog.byID[id] else { return .unknownItem }
        trading = true
        defer { trading = false }
        let cost = price(for: item)
        var copy = state
        let result = copy.buy(item: item, price: cost, wallet: wallet)
        guard result == .success else { return result }
        if commit(copy, traded: true) {
            return .success
        }
        wallet?.credit(cost)
        return .rejected
    }

    func sell(id: String) -> ShopTradeResult {
        guard !trading else { return .rejected }
        guard let item = ShopCatalog.byID[id] else { return .unknownItem }
        guard owns(id) else { return .notOwned }
        trading = true
        defer { trading = false }
        let refund = refund(for: item)
        var copy = state
        guard copy.sell(item: item, refund: refund, wallet: wallet) else { return .notOwned }
        if commit(copy, traded: true) {
            return .success
        }
        if wallet != nil {
            _ = wallet?.debit(refund)
        }
        return .rejected
    }

    @discardableResult
    func use(id: String) -> ShopAnchor? {
        guard let item = ShopCatalog.byID[id], owns(id) else { return nil }
        var copy = state
        if item.anchor.isWear {
            copy.equip(item)
        } else if item.anchor.isRoom {
            copy.place(item)
        } else if item.destinationID != nil {
            copy.activate(item)
        } else {
            return nil
        }
        return commit(copy, traded: false) ? item.anchor : nil
    }

    func tryOn(id: String) {
        guard let item = ShopCatalog.byID[id] else { return }
        var copy = state
        if item.anchor.isWear {
            copy.stageWear(item)
        } else if item.anchor.isRoom {
            copy.stageRoom(item)
        } else {
            return
        }
        _ = commit(copy, traded: false)
    }

    func clearWear(_ anchor: ShopAnchor) {
        var copy = state
        copy.clearWear(anchor)
        _ = commit(copy, traded: false)
    }

    func clearRoom(_ anchor: ShopAnchor) {
        var copy = state
        copy.clearRoom(anchor)
        _ = commit(copy, traded: false)
    }

    func endTryOn() {
        var copy = state
        copy.alignPreviewWithEquipped()
        _ = commit(copy, traded: false)
    }

    func endWearTryOn() {
        var copy = state
        copy.previewWear = copy.equipped
        _ = commit(copy, traded: false)
    }

    func clearRoomPreview() {
        var copy = state
        copy.previewRoom = [:]
        _ = commit(copy, traded: false)
    }

    func toggleFavorite(id: String) {
        var copy = state
        copy.toggleFavorite(itemID: id)
        _ = commit(copy, traded: false)
    }

    func saveOutfit(named raw: String) {
        var copy = state
        let fallback = ShopL10n.format(.outfitFallback, language, copy.outfits.count + 1)
        copy.storeOutfit(named: raw, fallback: fallback)
        _ = commit(copy, traded: false)
    }

    func applyOutfit(id: UUID) {
        guard let outfit = state.outfits.first(where: { $0.id == id }) else { return }
        var copy = state
        copy.apply(outfit: outfit)
        _ = commit(copy, traded: false)
    }

    func deleteOutfit(id: UUID) {
        var copy = state
        copy.deleteOutfit(id: id)
        _ = commit(copy, traded: false)
    }

    func toggleOutfitFavorite(id: UUID) {
        var copy = state
        copy.toggleOutfitFavorite(id: id)
        _ = commit(copy, traded: false)
    }

    func saveDesign(named raw: String) {
        var copy = state
        let fallback = ShopL10n.format(.designFallback, language, copy.roomDesigns.count + 1)
        copy.storeDesign(named: raw, fallback: fallback)
        _ = commit(copy, traded: false)
    }

    func applyDesign(id: UUID) {
        guard let design = state.roomDesigns.first(where: { $0.id == id }) else { return }
        var copy = state
        copy.apply(design: design)
        _ = commit(copy, traded: false)
    }

    func deleteDesign(id: UUID) {
        var copy = state
        copy.deleteDesign(id: id)
        _ = commit(copy, traded: false)
    }

    func toggleDesignFavorite(id: UUID) {
        var copy = state
        copy.toggleDesignFavorite(id: id)
        _ = commit(copy, traded: false)
    }

    func setLighting(_ mode: ShopDaylight) {
        var copy = state
        copy.setLighting(mode)
        _ = commit(copy, traded: false)
    }

    func unlockedDestinationIDs() -> Set<String> {
        Set(state.ownedIDs.compactMap { ShopCatalog.byID[$0]?.destinationID })
    }

    func activeDestinationID() -> String? {
        state.activeDestinationID
    }

    func debugUnlockAll() {
        var copy = state
        copy.unlockAll(catalog: ShopCatalog.items)
        _ = commit(copy, traded: false)
    }

    func debugResetInventory() {
        var copy = state
        copy.resetInventory()
        _ = commit(copy, traded: false)
    }

    func debugSetBalance(_ amount: Int) -> Bool {
        guard wallet == nil else { return false }
        var copy = state
        copy.balance = min(9_999_999, max(0, amount))
        return commit(copy, traded: false)
    }

    func debugSetSeed(_ seed: UInt64) {
        var copy = state
        copy.seedToken = String(seed)
        _ = commit(copy, traded: false)
    }

    func debugSetAppDate(_ date: Date?) {
        dateOverride = date
        clock = date ?? dateProvider()
    }

    func debugSetLighting(_ raw: String) -> Bool {
        guard let mode = ShopDaylight(rawValue: raw) else { return false }
        setLighting(mode)
        return true
    }

    func debugOfferIDs(year: Int, month: Int, day: Int) -> [String] {
        ShopDepartment.allCases.flatMap { department in
            ShopDailyOffers.offers(
                catalog: ShopCatalog.items,
                department: department,
                year: year,
                month: month,
                day: day,
                seed: state.seedValue
            ).map(\.id)
        }
    }

    func debugSummary() -> String {
        let parts = dayParts()
        let issues = ShopEngine.audit()
        let worn = state.equipped.keys.sorted().joined(separator: ", ")
        let room = state.placements.keys.sorted().joined(separator: ", ")
        let today = debugOfferIDs(year: parts.year, month: parts.month, day: parts.day).joined(separator: ", ")
        let trip = state.activeDestinationID ?? ShopL10n.text(.none, language)
        let day = String(format: "%04d-%02d-%02d", parts.year, parts.month, parts.day)
        let lines = [
            "\(ShopL10n.text(.summarySeed, language)): \(state.seedToken)",
            "\(ShopL10n.text(.summaryToday, language)): \(day)",
            "\(ShopL10n.text(.summaryLight, language)): \(resolvedPhase().rawValue)",
            "\(ShopL10n.text(.currencyName, language)): \(shownBalance)",
            "\(ShopL10n.text(.summaryOwned, language)): \(state.ownedIDs.count)",
            "\(ShopL10n.text(.wearingNow, language)): \(worn.isEmpty ? ShopL10n.text(.none, language) : worn)",
            "\(ShopL10n.text(.placedNow, language)): \(room.isEmpty ? ShopL10n.text(.none, language) : room)",
            "\(ShopL10n.text(.summaryTrip, language)): \(trip)",
            "\(ShopL10n.text(.summaryToday, language)): \(today)",
            "\(ShopL10n.text(.summaryAudit, language)): \(issues.isEmpty ? ShopL10n.text(.auditOk, language) : issues.joined(separator: ", "))"
        ]
        return lines.joined(separator: "\n")
    }

    func debugJSON() -> String {
        ShopPersistence.exportText()
    }

    private func sorted(_ items: [ShopItem]) -> [ShopItem] {
        items.sorted { lhs, rhs in
            let order = lhs.name(language).localizedStandardCompare(rhs.name(language))
            if order == .orderedSame { return lhs.id < rhs.id }
            return order == .orderedAscending
        }
    }

    @discardableResult
    private func commit(_ copy: ShopState, traded: Bool) -> Bool {
        let clean = ShopEngine.sanitize(copy)
        guard ShopPersistence.save(clean) else { return false }
        state = clean
        if traded {
            tradeTick += 1
        }
        refreshBalance()
        NotificationCenter.default.post(name: .goobyShopRoomDidChange, object: nil)
        return true
    }

    private func adoptShellLanguageIfNeeded() {
        guard !languagePinned else { return }
        let keys = ["gooby.language", "Gooby.language", "appLanguage"]
        for key in keys {
            guard let value = UserDefaults.standard.string(forKey: key)?.lowercased() else { continue }
            guard value.hasPrefix("de") || value.hasPrefix("en") else { continue }
            let resolved = ShopLanguage.resolve(value)
            if resolved != language {
                language = resolved
            }
            return
        }
    }
}
