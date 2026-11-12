import SwiftUI

/// Outfit and nest shop. The keeper is the cream rabbit, prices are rainbow stones,
/// and every cell draws a look, a nest piece, or a ticket from the catalog.
struct MyShopScreen: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var floor: ShopFloor = .clothes
    @State private var list: MyShopList?
    @State private var bob = false

    private var still: Bool { systemReduce || engine.reduceMotion }
    private var paint: ShopFloorPaint { floor == .clothes ? .clothes : .furniture }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    paint.screen.frame(height: 280)
                    paint.sheet
                }
                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 168)
                        tray
                    }
                }
                .scrollIndicators(.hidden)
                .id(floor)
                keeper
            }
            .clipped()
        }
        .background(alignment: .top) {
            Color.black.frame(height: 160).ignoresSafeArea(edges: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            floorBar
        }
        .animation(still ? nil : .easeInOut(duration: 0.28), value: floor)
        .toolbar(.hidden, for: .navigationBar)
        .navigationTitle(engine.t("tab.shop"))
        .sheet(item: $list) { which in
            NavigationStack {
                switch which {
                case .catalog:
                    ShopCatalogScreen(engine: engine, paint: paint, pictures: .glyph, still: still) { item in
                        MyShopDetail(engine: engine, item: item, still: still)
                    }
                case .sell:
                    ShopSellScreen(engine: engine, paint: paint, pictures: .glyph, still: still) { item in
                        MyShopDetail(engine: engine, item: item, still: still)
                    }
                }
            }
        }
        .onAppear {
            guard !still else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
        .sceneLoop(.shop)
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 8) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color(hex: 0xF2F2F2))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: 0x2C2B2D), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("shop.close"))
            stonePill
            Spacer(minLength: 4)
            barButton(engine.t("shop.catalog"), art: "still-catalog") { list = .catalog }
            barButton(engine.t("shop.sell"), art: "still-sell") { list = .sell }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black)
    }

    private var stonePill: some View {
        HStack(spacing: 6) {
            ShopStoneGlyph()
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
            Text("\(engine.wallet.sparks)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x1C1C1E))
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 4)
        .background(Color.white, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(engine.tf("shop.balance", engine.wallet.sparks))
    }

    private func barButton(_ title: String, art: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                StageStill(name: art)
                    .frame(width: 26, height: 26)
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var keeper: some View {
        HStack(alignment: .bottom, spacing: 4) {
            GoobyCharacterView(
                look: keeperLook,
                stage: "young",
                animation: floor == .clothes ? .idle : .wave,
                reduceMotion: still,
                companion: nil,
                showCompanion: false
            )
            .frame(width: 150, height: 158)
            .offset(y: bob && !still ? -4 : 0)
            .accessibilityHidden(true)
            bubble(name: keeperName, line: engine.t(floor == .clothes ? "shop.counter.clothes" : "shop.counter.nest"))
                .frame(maxWidth: 220, alignment: .leading)
                .layoutPriority(1)
                .padding(.trailing, 12)
                .padding(.bottom, 28)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .allowsHitTesting(false)
    }

    private var keeperName: String {
        let trimmed = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? engine.t("shop.counter.fallback") : trimmed
    }

    /// Cream fur and catalog clothes the rabbit can already wear.
    private var keeperLook: WornLook {
        var slots: [String: ItemDef] = [:]
        let picks = floor == .clothes
            ? ["hat-star", "scarf-honey", "shirt-cream"]
            : ["hat-cloud", "jacket-mint"]
        for id in picks {
            if let item = engine.catalog.itemsByID[id] {
                slots[item.slot] = item
            }
        }
        return WornLook(fur: "fur-cream", slots: slots)
    }

    private func bubble(name: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0xFBE9C8))
                .padding(.horizontal, 10)
                .frame(height: 22)
                .background(Color(hex: 0xE07A2F), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .offset(x: 8, y: 10)
                .zIndex(1)
            Text(line)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x6E5A2E))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0xF0E79E), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityElement(children: .combine)
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
                        .padding(.top, 18)
                        .padding(.bottom, 8)
                }
                MyShopGrid(engine: engine, items: section.items, paint: paint, still: still, mapTag: section.special)
                    .padding(.horizontal, 10)
            }
        }
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(paint.sheet, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22, style: .continuous))
    }

    private func specialHeader(_ title: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            StageClip(name: "clip-sparkles", reduceMotion: still)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                MyShopRefreshLine(engine: engine, still: still)
            }
            Spacer(minLength: 4)
            HStack(spacing: 0) {
                Text(engine.t("shop.free"))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(paint.badge, in: Capsule())
                StageStill(name: "still-refresh")
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(bob && !still ? 180 : 0))
                    .padding(.leading, 6)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var floorBar: some View {
        HStack(spacing: 0) {
            floorButton(.clothes, title: engine.t("shop.stage.clothes"), sample: floorSample(slot: "shirt", color: "F58A4B", second: "4FC3C0"))
            floorButton(.furniture, title: engine.t("shop.stage.furniture"), sample: floorSample(slot: "sofa", color: "E07A5F", second: "F2C14E"))
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(paint.sheet.ignoresSafeArea(edges: .bottom))
    }

    private func floorButton(_ choice: ShopFloor, title: String, sample: ItemDef) -> some View {
        let selected = floor == choice
        return Button { floor = choice } label: {
            VStack(spacing: 0) {
                ShopItemGlyph(item: sample)
                    .frame(width: 64, height: 48)
                    .scaleEffect(0.55)
                    .frame(width: 36, height: 28)
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(paint.pill)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var sections: [MyShopShelf] {
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

    private func shelves(_ rows: [(String, String, [ItemDef], Bool)]) -> [MyShopShelf] {
        rows.compactMap { row in
            guard !row.2.isEmpty else { return nil }
            return MyShopShelf(id: row.0, title: row.1, items: row.2, special: row.3)
        }
    }

    private func pool(_ shop: String) -> [ItemDef] {
        if shop == "seasonal" {
            return engine.catalog.items.filter { !$0.seasonalEvent.isEmpty && !$0.starter }
        }
        return engine.catalog.items.filter { $0.shop == shop && $0.seasonalEvent.isEmpty && !$0.starter }
    }

    private func rotated(_ shop: String) -> [ItemDef] {
        let rows = pool(shop)
        let ids = ShopRotation.orderedIDs(rows.map(\.id), dayKey: engine.dayKey(), category: shop, appSeed: engine.profile.appSeed)
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

    private func special(_ shop: String) -> [ItemDef] {
        let picks = offer(shop)
        return picks + rest(shop).prefix(max(0, 6 - picks.count))
    }

    private func everyday(_ shop: String) -> [ItemDef] {
        Array(rest(shop).dropFirst(max(0, 6 - offer(shop).count)))
    }

    private func seasonRows(clothes: Bool) -> [ItemDef] {
        let daily = Set(engine.dailyOfferIDs(shop: "seasonal"))
        let rows = rotated("seasonal").filter { clothes ? isCloth($0) : !isCloth($0) }
        return rows.filter { daily.contains($0.id) } + rows.filter { !daily.contains($0.id) }
    }

    private func isCloth(_ item: ItemDef) -> Bool {
        item.kind == "clothing" || item.kind == "color"
    }

    private func floorSample(slot: String, color: String, second: String) -> ItemDef {
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

private enum MyShopList: String, Identifiable {
    case catalog, sell
    var id: String { rawValue }
}

private struct MyShopShelf: Identifiable {
    var id: String
    var title: String
    var items: [ItemDef]
    var special: Bool
}

private struct MyShopRefreshLine: View {
    var engine: GoobyEngine
    var still: Bool

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
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.92))
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

struct MyShopGrid: View {
    var engine: GoobyEngine
    var items: [ItemDef]
    var paint: ShopFloorPaint
    var still: Bool
    var mapTag = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                NavigationLink {
                    MyShopDetail(engine: engine, item: item, still: still)
                } label: {
                    MyShopCell(engine: engine, item: item, paint: paint)
                        .overlay(alignment: .topLeading) {
                            if mapTag && index == 0 {
                                StageStill(name: "still-map")
                                    .frame(width: 22, height: 22)
                                    .offset(x: 4, y: 4)
                                    .accessibilityHidden(true)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct MyShopCell: View {
    var engine: GoobyEngine
    var item: ItemDef
    var paint: ShopFloorPaint

    private var owned: Bool { engine.owns(item.id) }
    private var locked: Bool { !item.seasonalEvent.isEmpty && !engine.isEventActive(item.seasonalEvent) }

    var body: some View {
        VStack(spacing: 0) {
            ShopItemGlyph(item: item)
                .frame(width: 84, height: 64)
                .opacity(locked ? 0.45 : 1)
                .padding(.top, 8)
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                if owned {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                    Text(engine.t("shop.have"))
                } else if locked {
                    StageStill(name: "still-lock")
                        .frame(width: 14, height: 14)
                    Text(engine.t("shop.locked"))
                } else {
                    ShopStoneGlyph()
                        .frame(width: 18, height: 18)
                    Text("\(engine.price(of: item))")
                }
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(paint.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(height: 24)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .frame(height: 118)
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

struct MyShopDetail: View {
    var engine: GoobyEngine
    var item: ItemDef
    var still: Bool
    @State private var confirmBuy = false
    @State private var confirmSell = false
    @State private var message: String?
    @State private var preview = true
    @State private var burst = false

    private var wearable: Bool { item.kind == "clothing" || item.kind == "color" }
    private var locked: Bool { !item.seasonalEvent.isEmpty && !engine.isEventActive(item.seasonalEvent) }
    private var paint: ShopFloorPaint {
        if item.kind == "clothing" || item.kind == "color" || item.shop == "wardrobe" || item.shop == "colors" {
            return .clothes
        }
        return .furniture
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    hero
                    if burst && !still {
                        StageClip(name: "clip-confetti", reduceMotion: false, loop: false, lead: 0.8)
                            .frame(height: 180)
                            .allowsHitTesting(false)
                        StageClip(name: "clip-sparkles", reduceMotion: false, loop: false)
                            .frame(width: 120, height: 120)
                            .allowsHitTesting(false)
                    }
                }
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
        .toolbarColorScheme(paint.lightStatus ? .dark : .light, for: .navigationBar)
        .alert(engine.t("shop.confirmBuy"), isPresented: $confirmBuy) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.buy")) { buy() }
        } message: {
            Text(item.name.text(engine.languageCode))
        }
        .alert(engine.t("shop.confirmSell"), isPresented: $confirmSell) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.sell"), role: .destructive) {
                if let error = engine.sell(item) { message = engine.t(error) }
            }
        } message: {
            Text(engine.tf("shop.sell.amount", item.name.text(engine.languageCode), engine.sellPrice(of: item)))
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
                animation: still ? .idle : .present,
                reduceMotion: still,
                companion: nil,
                showCompanion: false
            )
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .background(Theme.cream.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            ShopItemGlyph(item: item)
                .frame(width: 160, height: 140)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
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
                Text(engine.tf("shop.sell.backline", engine.sellPrice(of: item)))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                    .frame(maxWidth: .infinity)
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

    private func buy() {
        if let error = engine.buy(item) {
            message = engine.t(error)
            return
        }
        guard !still else { return }
        burst = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { burst = false }
    }
}
