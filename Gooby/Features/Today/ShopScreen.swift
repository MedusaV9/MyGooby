import SwiftUI

struct ShopScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var floor: ShopFloor = .clothes

    private var still: Bool { reduceMotion || systemReduce }

    private var activeEvent: EventDef? {
        engine.catalog.events.first { engine.isEventActive($0.id) }
    }

    private var colorToken: String {
        "\(floor.rawValue)|\(activeEvent?.id ?? "")"
    }

    private var paint: ShopFloorPaint {
        if let activeEvent {
            return .season(activeEvent.id)
        }
        return floor == .clothes ? .clothes : .furniture
    }

    private var npcLine: String {
        let base = engine.t(floor == .clothes ? "shop.npc.clothes" : "shop.npc.furniture")
        guard let activeEvent else { return base }
        let extra = engine.tf("shop.npc.season", activeEvent.title.text(engine.languageCode))
        return base + " " + extra
    }

    private var seasonSubtitle: String {
        if let activeEvent {
            return activeEvent.title.text(engine.languageCode)
        }
        return engine.t("shop.season")
    }

    var body: some View {
        ZStack {
            paint.screen.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    ShopKeeperRow(
                        clothes: floor == .clothes,
                        name: engine.t(floor == .clothes ? "shop.npc.lilo" : "shop.npc.fiete"),
                        line: npcLine,
                        accent: floor == .clothes ? Color(hex: 0x6E4FE0) : Color(hex: 0x8E5A30),
                        still: still
                    )
                    sheet
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .scrollContentBackground(.hidden)
            .id(floor)
        }
        .animation(still ? nil : .easeInOut(duration: 0.28), value: colorToken)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ShopFloorSwitch(
                floor: $floor,
                paint: paint,
                clothesTitle: engine.t("shop.stage.clothes"),
                furnitureTitle: engine.t("shop.stage.furniture")
            )
        }
        .navigationTitle(engine.t("tab.shop"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ShopStonePill(count: engine.wallet.sparks, spoken: engine.tf("shop.balance", engine.wallet.sparks))
            }
        }
        .toolbarBackground(paint.screen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(paint.lightStatus ? .dark : .light, for: .navigationBar)
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    ShopCollectionHeader(
                        title: section.title,
                        subtitle: section.id == "season" ? seasonSubtitle : nil,
                        ink: paint.ink,
                        badge: paint.badge,
                        freeTitle: engine.t("shop.free"),
                        showsFree: section.special,
                        sparkle: section.special
                    )
                    if section.special {
                        ShopRefreshLine(engine: engine, still: still, ink: paint.ink)
                    }
                    ShopGrid(engine: engine, items: section.items, paint: paint, reduceMotion: still)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(paint.sheet, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var sections: [ShopShelf] {
        switch floor {
        case .clothes:
            return shelves([
                ("special", engine.t("shop.collection.special"), offer("wardrobe"), true),
                ("everyday", engine.t("shop.collection.everyday"), rest("wardrobe"), false),
                ("colors", engine.t("shop.collection.colors"), rotated("colors"), false),
                ("season", engine.t("shop.collection.season"), seasonRows(clothes: true), false)
            ])
        case .furniture:
            return shelves([
                ("special", engine.t("shop.collection.special"), offer("furniture"), true),
                ("everyday", engine.t("shop.collection.everyday"), rest("furniture"), false),
                ("travel", engine.t("shop.collection.travel"), rotated("travel"), false),
                ("season", engine.t("shop.collection.season"), seasonRows(clothes: false), false)
            ])
        }
    }

    private func shelves(_ rows: [(String, String, [ItemDef], Bool)]) -> [ShopShelf] {
        rows.compactMap { row in
            guard !row.2.isEmpty else { return nil }
            return ShopShelf(id: row.0, title: row.1, items: row.2, special: row.3)
        }
    }

    /// The first four ids match `GoobyEngine.dailyOfferIDs`, which shuffles with `ShopRotation`.
    private func pool(_ shop: String) -> [ItemDef] {
        if shop == "seasonal" {
            return engine.catalog.items.filter { !$0.seasonalEvent.isEmpty && !$0.starter }
        }
        return engine.catalog.items.filter { $0.shop == shop && $0.seasonalEvent.isEmpty && !$0.starter }
    }

    private func rotated(_ shop: String) -> [ItemDef] {
        let rows = pool(shop)
        let ids = ShopRotation.orderedIDs(
            rows.map(\.id),
            dayKey: engine.dayKey(),
            category: shop,
            appSeed: engine.profile.appSeed
        )
        let byID = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    private func offer(_ shop: String) -> [ItemDef] {
        engine.dailyOfferIDs(shop: shop).compactMap { engine.catalog.itemsByID[$0] }
    }

    private func rest(_ shop: String) -> [ItemDef] {
        let daily = Set(engine.dailyOfferIDs(shop: shop))
        return rotated(shop).filter { !daily.contains($0.id) }
    }

    private func seasonRows(clothes: Bool) -> [ItemDef] {
        let daily = Set(engine.dailyOfferIDs(shop: "seasonal"))
        let rows = rotated("seasonal").filter { clothes ? isCloth($0) : !isCloth($0) }
        return rows.filter { daily.contains($0.id) } + rows.filter { !daily.contains($0.id) }
    }

    private func isCloth(_ item: ItemDef) -> Bool {
        item.kind == "clothing" || item.kind == "color"
    }
}

private struct ShopShelf: Identifiable {
    var id: String
    var title: String
    var items: [ItemDef]
    var special: Bool
}

private struct ShopRefreshLine: View {
    var engine: GoobyEngine
    var still: Bool
    var ink: Color

    var body: some View {
        Group {
            if still {
                Text(engine.t("shop.refresh.still"))
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(clock(engine.now()))
                }
            }
        }
        .font(.system(.caption, design: .rounded))
        .foregroundStyle(ink.opacity(0.92))
    }

    private func clock(_ now: Date) -> String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        guard let next = calendar.date(byAdding: .day, value: 1, to: start) else {
            return engine.t("shop.refresh.still")
        }
        let remain = max(0, Int(next.timeIntervalSince(now)))
        let text = String(format: "%02d:%02d:%02d", remain / 3600, (remain % 3600) / 60, remain % 60)
        return engine.tf("shop.refresh.live", text)
    }
}

private struct ShopGrid: View {
    var engine: GoobyEngine
    var items: [ItemDef]
    var paint: ShopFloorPaint
    var reduceMotion: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items) { item in
                NavigationLink {
                    ItemDetail(engine: engine, item: item, reduceMotion: reduceMotion)
                } label: {
                    ShopGridCell(engine: engine, item: item, paint: paint)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ShopGridCell: View {
    var engine: GoobyEngine
    var item: ItemDef
    var paint: ShopFloorPaint

    private var owned: Bool { engine.owns(item.id) }

    private var locked: Bool {
        !item.seasonalEvent.isEmpty && !engine.isEventActive(item.seasonalEvent)
    }

    var body: some View {
        VStack(spacing: 4) {
            ShopItemGlyph(item: item)
                .frame(height: 64)
                .opacity(locked ? 0.45 : 1)
            HStack(spacing: 3) {
                if owned {
                    ShopCheckMark(ink: paint.ink)
                    Text(engine.t("shop.have"))
                } else if locked {
                    ShopLockMark(ink: paint.ink)
                    Text(engine.t("shop.locked"))
                } else {
                    ShopStoneGlyph()
                        .frame(width: 14, height: 14)
                    Text("\(engine.price(of: item))")
                }
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(paint.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 3)
        .frame(maxWidth: .infinity)
        .background(paint.cell, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessLabel)
        .accessibilityHint(item.blurb.text(engine.languageCode))
    }

    private var accessLabel: String {
        let name = item.name.text(engine.languageCode)
        if owned { return "\(name), \(engine.t("shop.have"))" }
        if locked { return "\(name), \(engine.t("shop.locked"))" }
        return "\(name), \(engine.tf("shop.balance", engine.price(of: item)))"
    }
}

struct ItemDetail: View {
    var engine: GoobyEngine
    var item: ItemDef
    var reduceMotion: Bool
    @State private var confirmBuy = false
    @State private var confirmSell = false
    @State private var message: String?
    @State private var preview = true

    private var wearable: Bool {
        item.kind == "clothing" || item.kind == "color"
    }

    private var locked: Bool {
        !item.seasonalEvent.isEmpty && !engine.isEventActive(item.seasonalEvent)
    }

    private var activeEvent: EventDef? {
        engine.catalog.events.first { engine.isEventActive($0.id) }
    }

    private var paint: ShopFloorPaint {
        if let activeEvent {
            return .season(activeEvent.id)
        }
        if item.kind == "clothing" || item.kind == "color" || item.shop == "wardrobe" || item.shop == "colors" {
            return .clothes
        }
        return .furniture
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.name.text(engine.languageCode))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text(item.blurb.text(engine.languageCode))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.8))
                    Text(engine.t("rarity.\(item.rarity)"))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.ink.opacity(0.7))
                    if wearable {
                        Toggle(engine.t("shop.preview"), isOn: $preview)
                            .tint(Theme.rose)
                            .foregroundStyle(Theme.ink)
                    }
                    actions
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding(16)
        }
        .scrollContentBackground(.hidden)
        .background(paint.screen.ignoresSafeArea())
        .navigationTitle(engine.t("shop.detail"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(item.name.text(engine.languageCode))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(paint.lightStatus ? Color.white : paint.ink)
                    .lineLimit(1)
            }
        }
        .toolbarBackground(paint.screen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(paint.lightStatus ? .dark : .light, for: .navigationBar)
        .alert(engine.t("shop.confirmBuy"), isPresented: $confirmBuy) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.buy")) {
                if let error = engine.buy(item) { message = engine.t(error) }
            }
        } message: {
            Text(item.name.text(engine.languageCode))
        }
        .alert(engine.t("shop.confirmSell"), isPresented: $confirmSell) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.sell"), role: .destructive) {
                if let error = engine.sell(item) { message = engine.t(error) }
            }
        }
        .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    @ViewBuilder
    private var hero: some View {
        if wearable && preview {
            GoobyCharacterView(
                look: engine.wornLook(preview: item),
                stage: Growth.stage(of: engine.pet),
                animation: .present,
                reduceMotion: reduceMotion,
                companion: nil
            )
            .frame(height: 240)
            .frame(maxWidth: .infinity)
            .background(Theme.cream.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            ShopItemGlyph(item: item)
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(paint.cell, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    @ViewBuilder
    private var actions: some View {
        if engine.owns(item.id) {
            Button(engine.t("common.equip")) { engine.equip(item) }
                .buttonStyle(GoobyButtonStyle())
            Button(engine.t("common.unequip")) { engine.unequip(slot: item.slot) }
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            Button(engine.t(engine.ownedRow(item.id)?.favorite == true ? "shop.unfavorite" : "common.favorite")) {
                engine.toggleFavoriteItem(item.id)
            }
            .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            if !item.starter {
                Button(engine.t("common.sell")) { confirmSell = true }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.rose)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        } else if locked {
            Text(engine.t("shop.season"))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.ink)
        } else {
            Button(engine.tf("shop.buyFor", engine.price(of: item))) { confirmBuy = true }
                .buttonStyle(GoobyButtonStyle(fill: Theme.rose, ink: Theme.ink))
        }
    }
}
