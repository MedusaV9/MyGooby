import SwiftUI

struct ShopScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var floor: ShopFloor = .clothes
    @State private var list: ShopList?

    private var still: Bool { reduceMotion || systemReduce }

    private var paint: ShopFloorPaint {
        floor == .clothes ? .clothes : .furniture
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    paint.screen.frame(height: 420)
                    paint.sheet
                }
                ScrollView {
                    VStack(spacing: 0) {
                        stage
                        tray
                    }
                }
                .scrollIndicators(.hidden)
                .id(floor)
            }
            .clipped()
        }
        .background(alignment: .top) {
            Color.black.frame(height: 200).ignoresSafeArea(edges: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ShopFloorBar(
                floor: $floor,
                paint: paint,
                clothesTitle: engine.t("shop.stage.clothes"),
                furnitureTitle: engine.t("shop.stage.furniture")
            )
        }
        .animation(still ? nil : .easeInOut(duration: 0.24), value: floor)
        .toolbar(.hidden, for: .navigationBar)
        .navigationTitle(engine.t("tab.shop"))
        .sheet(item: $list) { which in
            NavigationStack {
                ShopListPage(
                    engine: engine,
                    title: engine.t(which == .catalog ? "shop.catalog" : "shop.sell"),
                    empty: engine.t("shop.sell.empty"),
                    items: which == .catalog ? catalogRows : sellRows,
                    paint: paint,
                    reduceMotion: still
                )
            }
        }
        .sceneLoop(.shop)
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color(hex: 0xD9D9DB))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: 0x2C2B2D), in: Circle())
                    .contentShape(Rectangle().inset(by: -8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("shop.close"))
            .padding(.leading, 11.4)
            .padding(.top, 5.7)
            ShopStonePill(count: engine.wallet.sparks, spoken: engine.tf("shop.balance", engine.wallet.sparks))
                .padding(.leading, 26.6)
                .padding(.top, 7.7)
            Spacer(minLength: 8)
            barButton(engine.t("shop.catalog"), width: 58) { list = .catalog } icon: { ShopCatalogIcon() }
            barButton(engine.t("shop.sell"), width: 40) { list = .sell } icon: { ShopSellIcon() }
                .padding(.trailing, 2)
        }
        .frame(height: 44.5, alignment: .top)
        .background(Color.black)
    }

    private func barButton<Icon: View>(_ title: String, width: CGFloat, action: @escaping () -> Void, @ViewBuilder icon: () -> Icon) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                icon()
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: width)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var stage: some View {
        ZStack(alignment: .topLeading) {
            if floor == .furniture {
                ShopKeeperBubble(
                    name: engine.t("shop.npc.fiete"),
                    line: engine.t("shop.npc.furniture")
                )
                .padding(.leading, 196)
                .padding(.trailing, 14)
                .padding(.top, 55)
            }
            ShopKeeper(engine: engine, clothes: floor == .clothes, still: still)
                .frame(width: 190, height: 190)
                .offset(x: -2, y: 273)
        }
        .frame(maxWidth: .infinity, minHeight: 401.5, maxHeight: 401.5, alignment: .topLeading)
        .background(paint.screen)
    }

    private var tray: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sections) { section in
                if section.special {
                    specialHeader(section.title)
                } else {
                    Text(section.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, 14)
                        .padding(.top, 22)
                        .padding(.bottom, 10)
                }
                ShopGrid(engine: engine, items: section.items, paint: paint, reduceMotion: still, mapTag: section.special)
                    .padding(.horizontal, 10.7)
            }
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(paint.sheet, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22, style: .continuous))
    }

    private func specialHeader(_ title: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ShopSparkle(color: Color(hex: 0xF7C548))
                .frame(width: 30, height: 30)
                .padding(.leading, 10)
                .padding(.top, 9)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                ShopRefreshLine(engine: engine, still: still, ink: .white)
            }
            .padding(.leading, 8)
            .padding(.top, 11)
            Spacer(minLength: 6)
            ZStack(alignment: .trailing) {
                Text(engine.t("shop.free"))
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.leading, 12)
                    .padding(.trailing, 30)
                    .frame(height: 24)
                    .background(paint.badge, in: UnevenRoundedRectangle(topLeadingRadius: 5, bottomLeadingRadius: 5, bottomTrailingRadius: 12, topTrailingRadius: 12))
                    .padding(.trailing, 14)
                ShopRefreshDisc()
                    .frame(width: 38, height: 38)
            }
            .padding(.trailing, 11)
            .padding(.top, 12)
            .accessibilityHidden(true)
        }
        .frame(height: 57.5, alignment: .top)
    }

    private var sections: [ShopShelf] {
        switch floor {
        case .clothes:
            return shelves([
                ("special", engine.t("shop.collection.special"), special("wardrobe"), true),
                ("everyday", engine.t("shop.collection.everyday"), everyday("wardrobe"), false),
                ("colors", engine.t("shop.collection.colors"), rotated("colors"), false),
                ("season", engine.t("shop.collection.season"), seasonRows(clothes: true), false)
            ])
        case .furniture:
            return shelves([
                ("special", engine.t("shop.collection.special"), special("furniture"), true),
                ("everyday", engine.t("shop.collection.everyday"), everyday("furniture"), false),
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

    /// Today's offer filled up to two full rows with the next items of today's rotation.
    private func special(_ shop: String) -> [ItemDef] {
        let picks = offer(shop)
        return picks + rest(shop).prefix(max(0, Self.specialCount - picks.count))
    }

    private func everyday(_ shop: String) -> [ItemDef] {
        Array(rest(shop).dropFirst(max(0, Self.specialCount - offer(shop).count)))
    }

    private static let specialCount = 6

    private func seasonRows(clothes: Bool) -> [ItemDef] {
        let daily = Set(engine.dailyOfferIDs(shop: "seasonal"))
        let rows = rotated("seasonal").filter { clothes ? isCloth($0) : !isCloth($0) }
        return rows.filter { daily.contains($0.id) } + rows.filter { !daily.contains($0.id) }
    }

    private func isCloth(_ item: ItemDef) -> Bool {
        item.kind == "clothing" || item.kind == "color"
    }

    private var catalogRows: [ItemDef] {
        let seasonal = pool("seasonal").filter { floor == .clothes ? isCloth($0) : !isCloth($0) }
        let shops = floor == .clothes ? ["wardrobe", "colors"] : ["furniture", "travel"]
        return shops.flatMap { pool($0) } + seasonal
    }

    private var sellRows: [ItemDef] {
        engine.catalog.items.filter { !$0.starter && engine.owns($0.id) }
    }
}

private enum ShopList: String, Identifiable {
    case catalog, sell
    var id: String { rawValue }
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
        .font(.system(size: 13.5, weight: .medium, design: .rounded))
        .foregroundStyle(ink)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
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
    var mapTag = false

    private let columns = [
        GridItem(.flexible(), spacing: 7.4),
        GridItem(.flexible(), spacing: 7.4),
        GridItem(.flexible(), spacing: 7.4)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 7.4) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                NavigationLink {
                    ItemDetail(engine: engine, item: item, reduceMotion: reduceMotion)
                } label: {
                    ShopGridCell(engine: engine, item: item, paint: paint)
                        .overlay(alignment: .topLeading) {
                            if mapTag && index == 0 {
                                ShopMapTag().offset(x: -4, y: -1)
                            }
                        }
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
        VStack(spacing: 0) {
            ShopItemGlyph(item: item)
                .frame(width: 84, height: 64)
                .scaleEffect(1.1)
                .opacity(locked ? 0.45 : 1)
                .padding(.top, 13)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                if owned {
                    ShopCheckMark(ink: paint.ink)
                    Text(engine.t("shop.have"))
                } else if locked {
                    ShopLockMark(ink: paint.ink)
                    Text(engine.t("shop.locked"))
                } else {
                    ShopStoneGlyph()
                        .frame(width: 24, height: 24)
                    Text("\(engine.price(of: item))")
                }
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(paint.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(height: 26)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .frame(height: 127)
        .background(paint.cell, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
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

/// Catalog and sell lists: the same cells in one grid, opened from the shop's top bar.
private struct ShopListPage: View {
    var engine: GoobyEngine
    var title: String
    var empty: String
    var items: [ItemDef]
    var paint: ShopFloorPaint
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            if items.isEmpty {
                Text(empty)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                ShopGrid(engine: engine, items: items, paint: paint, reduceMotion: reduceMotion)
                    .padding(10.7)
            }
        }
        .background(paint.sheet.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(paint.sheet, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            Button(engine.t("common.done")) { dismiss() }
                .foregroundStyle(.white)
        }
    }
}

/// The shopkeeper: a Gooby in a top hat and dark glasses, standing on the tray.
private struct ShopKeeper: View {
    var engine: GoobyEngine
    var clothes: Bool
    var still: Bool

    var body: some View {
        GoobyCharacterView(look: look, stage: "adult", animation: clothes ? .idle : .wave, reduceMotion: true, companion: nil, showCompanion: false)
            .accessibilityHidden(true)
    }

    private var look: WornLook {
        var slots: [String: ItemDef] = [:]
        let picks = clothes ? ["hat-star", "glass-star", "scarf-honey"] : ["hat-sun", "jacket-sun"]
        for id in picks {
            if let item = engine.catalog.itemsByID[id] { slots[item.slot] = item }
        }
        return WornLook(fur: "fur-cream", slots: slots)
    }
}

private struct ShopKeeperBubble: View {
    var name: String
    var line: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0xFBE9C8))
                .padding(.horizontal, 12)
                .frame(height: 25)
                .background(Color(hex: 0xC8743A), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .offset(x: 6, y: 12)
                .zIndex(1)
            Text(line)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x6E5A2E))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xF0E79E), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .accessibilityElement(children: .combine)
    }
}

struct ShopFloorBar: View {
    @Binding var floor: ShopFloor
    var paint: ShopFloorPaint
    var clothesTitle: String
    var furnitureTitle: String

    var body: some View {
        HStack(spacing: 0) {
            button(.clothes, title: clothesTitle, slot: "shirt", color: "F58A4B", second: "4FC3C0")
            button(.furniture, title: furnitureTitle, slot: "sofa", color: "E5413B", second: "F2B13B")
        }
        .padding(.horizontal, 4)
        .padding(.top, 3.6)
        .padding(.bottom, 1.4)
        .background(paint.sheet.ignoresSafeArea(edges: .bottom))
    }

    private func button(_ choice: ShopFloor, title: String, slot: String, color: String, second: String) -> some View {
        let selected = floor == choice
        return Button {
            floor = choice
        } label: {
            VStack(spacing: 0) {
                ShopItemGlyph(item: sample(slot: slot, color: color, second: second))
                    .frame(width: 64, height: 52)
                    .scaleEffect(0.6)
                    .frame(width: 40, height: 32)
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.top, 3)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58, alignment: .top)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(paint.pill)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    private func sample(slot: String, color: String, second: String) -> ItemDef {
        ItemDef(
            id: "shop-floor-\(slot)",
            kind: slot == "sofa" ? "furniture" : "clothing",
            slot: slot,
            style: 0,
            price: 0,
            rarity: "common",
            color: color,
            color2: second,
            name: LocText(de: "", en: ""),
            blurb: LocText(de: "", en: ""),
            shop: slot == "sofa" ? "furniture" : "wardrobe",
            starter: false,
            seasonalEvent: ""
        )
    }
}

/// Opens the shop like a store counter: tapping the Shop tab slides it up full screen
/// and the tab bar stays on the page you came from.
struct ShopCoverHook: ViewModifier {
    @Binding var tab: ShellTab
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var open = false

    func body(content: Content) -> some View {
        content
            .onChange(of: tab) { previous, next in
                guard next == .shop else { return }
                tab = previous == .shop ? .home : previous
                open = true
            }
            .onAppear {
                guard tab == .shop else { return }
                tab = .home
                open = true
            }
            .fullScreenCover(isPresented: $open) {
                NavigationStack {
                    if let make = FeatureHost.shared.shopScreen {
                        make(engine)
                    } else {
                        ShopScreen(engine: engine, reduceMotion: reduceMotion)
                    }
                }
                .preferredColorScheme(.dark)
            }
    }
}

extension View {
    func shopCover(tab: Binding<ShellTab>, engine: GoobyEngine, reduceMotion: Bool) -> some View {
        modifier(ShopCoverHook(tab: tab, engine: engine, reduceMotion: reduceMotion))
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
