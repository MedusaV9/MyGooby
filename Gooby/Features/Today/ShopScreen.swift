import SwiftUI

/// Shop tab: five shop sections as colorful chips, today's offers (deterministic daily rotation)
/// and every item of the section as white tiles with a preview, rarity and price. Buying and
/// selling use the engine unchanged. `initialShop` opens a section (the bag's colors tile).
struct ShopScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var shop: String
    @Environment(\.isPresented) private var isPresented
    @Environment(\.dismiss) private var dismiss

    init(engine: GoobyEngine, reduceMotion: Bool, initialShop: String = "wardrobe") {
        self.engine = engine
        self.reduceMotion = reduceMotion
        _shop = State(initialValue: ShopSection.find(initialShop)?.id ?? "wardrobe")
    }

    var body: some View {
        let offers = engine.dailyOfferIDs(shop: shop)
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                chips
                dailyCard(offers)
                SectionCaps(engine.t("shop.all"), color: ShopInk.caps)
                    .padding(.top, 6)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(catalog) { item in
                        NavigationLink {
                            ItemDetail(engine: engine, item: item, reduceMotion: reduceMotion)
                        } label: {
                            ItemCard(engine: engine, item: item, deal: offers.contains(item.id))
                        }
                        .buttonStyle(ShopPressStyle())
                    }
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .top, spacing: 0) { topRow }
        .goobyScreen(Theme.Tab.shop.bg)
        .toolbar(.hidden, for: .navigationBar)
        .navigationTitle(engine.t("kit.tab.shop"))
    }

    private var topRow: some View {
        HStack(spacing: 8) {
            if isPresented {
                BackChevronButton(label: engine.t("kit.back")) { dismiss() }
            }
            Text(engine.t("kit.tab.shop"))
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            ShopSparksPill(engine: engine)
        }
        .padding(.leading, isPresented ? 8 : Theme.Space.margin)
        .padding(.trailing, Theme.Space.margin)
        .padding(.vertical, 8)
        .background(Theme.Tab.shop.bg)
    }

    private var chips: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(ShopSection.all) { section in
                let selected = section.id == shop
                Button {
                    shop = section.id
                } label: {
                    VStack(spacing: 6) {
                        IconTile(color: section.color, size: 52, radius: 14) {
                            GoobyIcon(section.icon, size: 32)
                        }
                        Text(engine.t("shop.\(section.id)"))
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .frame(height: 28, alignment: .top)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white)
                                .cardShadow()
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(ShopPressStyle())
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.top, 4)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: shop)
    }

    private func dailyCard(_ offers: [String]) -> some View {
        let items = offers.compactMap { engine.catalog.itemsByID[$0] }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(engine.t("shop.daily"))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    GoobyIcon("alarm.fill", size: 18)
                    Text(engine.tx("social.shop.tomorrow", de: "Neu ab morgen", en: "New tomorrow"))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Color.white.opacity(0.9))
                }
            }
            .padding(.horizontal, Theme.Space.inner)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        NavigationLink {
                            ItemDetail(engine: engine, item: item, reduceMotion: reduceMotion)
                        } label: {
                            ItemCard(engine: engine, item: item, deal: true)
                                .frame(width: 150)
                        }
                        .buttonStyle(ShopPressStyle())
                    }
                }
                .padding(.horizontal, Theme.Space.inner)
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, Theme.Space.inner)
        .background(Theme.Tab.shop.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    private var catalog: [ItemDef] {
        if shop == "seasonal" {
            return engine.catalog.items.filter { !$0.seasonalEvent.isEmpty && !$0.starter }
        }
        return engine.catalog.items.filter { $0.shop == shop && $0.seasonalEvent.isEmpty && !$0.starter }
    }
}

/// One shop section chip.
struct ShopSection: Identifiable {
    var id: String
    var icon: String
    var color: Color

    static let all: [ShopSection] = [
        ShopSection(id: "wardrobe", icon: "👕", color: Theme.Tab.quests.purple),
        ShopSection(id: "furniture", icon: "🛋️", color: Theme.Tab.quests.yellow),
        ShopSection(id: "colors", icon: "🎨", color: Theme.Tab.quests.pink),
        ShopSection(id: "travel", icon: "✈️", color: Theme.Tab.quests.sky),
        ShopSection(id: "seasonal", icon: "🎁", color: Theme.Tab.quests.green)
    ]

    static func find(_ id: String) -> ShopSection? { all.first { $0.id == id } }
}

/// Shop colors that are not in the shared palette.
enum ShopInk {
    static let caps = Color(hex: 0x9A6378)
    static let deal = Color(hex: 0xE84A4A)
    static let rarityCommon = Color(hex: 0x9AA3AD)

    static func rarity(_ id: String) -> Color {
        switch id {
        case "uncommon": return Theme.Tab.quests.green
        case "rare": return Theme.Tab.quests.sky
        case "special": return Theme.Tab.quests.purple
        default: return rarityCommon
        }
    }
}

/// Slight press feedback for tiles; the scale only runs when reduce motion is off.
struct ShopPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduce

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(!reduce && configuration.isPressed ? 0.97 : 1)
            .animation(reduce ? nil : .easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// White pill with the star-spark balance.
struct ShopSparksPill: View {
    var engine: GoobyEngine

    var body: some View {
        HStack(spacing: 4) {
            GoobyIcon("sparkles", size: 22)
            Text(verbatim: "\(engine.wallet.sparks)")
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.text)
                .monospacedDigit()
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
        .background(Color.white, in: Capsule())
        .cardShadow()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(engine.tf("shop.balance", engine.wallet.sparks))
    }
}

/// Rarity in a small colored pill.
struct ShopRarityPill: View {
    var engine: GoobyEngine
    var rarity: String

    var body: some View {
        Text(engine.t("rarity.\(rarity)"))
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(ShopInk.rarity(rarity), in: Capsule())
    }
}

/// Preview of an item: Gooby wearing clothes or a fur color, a drawn ticket for trips, and the
/// furniture glyph on the item's color for room pieces.
struct ShopItemArt: View {
    var engine: GoobyEngine
    var item: ItemDef
    var height: CGFloat

    var body: some View {
        let tint = Color(hexString: item.color)
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.28))
            switch item.kind {
            case "clothing":
                GoobyCharacterView(
                    look: WornLook(fur: engine.pet.furStyle, slots: [item.slot: item]),
                    stage: Growth.stage(of: engine.pet),
                    animation: .idle,
                    reduceMotion: true,
                    companion: nil,
                    showCompanion: false
                )
                .frame(width: height, height: height)
            case "color":
                GoobyAvatar(look: WornLook(fur: item.id, slots: [:]), stage: Growth.stage(of: engine.pet), size: height * 0.78)
            case "travel":
                ticket
            default:
                ZStack {
                    Circle()
                        .fill(tint)
                        .frame(width: height * 0.66, height: height * 0.66)
                        .overlay(Circle().stroke(Color(hexString: item.color2), lineWidth: 4))
                    GoobyIcon(ShopItemArt.furnitureIcon(item.slot), size: height * 0.5)
                }
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityHidden(true)
    }

    private var ticket: some View {
        let place = engine.catalog.placesByID[String(item.id.dropFirst("ticket-".count))]
        let top = Color(hexString: place?.skyTop ?? item.color)
        let bottom = Color(hexString: place?.skyBottom ?? item.color2)
        return ZStack {
            LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 2) {
                GoobyIcon("✈️", size: height * 0.42)
                GoobyIcon("🎟️", size: height * 0.3)
            }
        }
    }

    static func furnitureIcon(_ slot: String) -> String {
        switch slot {
        case "wall": return "🖌️"
        case "floor": return "🪵"
        case "bed": return "🛏️"
        case "rug": return "🧶"
        case "lamp": return "💡"
        case "window": return "🪟"
        case "plant": return "🪴"
        case "shelf": return "📚"
        case "picture": return "🖼️"
        case "sofa": return "🛋️"
        case "table": return "🪑"
        case "cushion": return "☁️"
        case "seasonal": return "🏮"
        case "accessory": return "🧸"
        default: return "✨"
        }
    }
}

/// White item tile: preview, name, rarity pill and price (or owned).
struct ItemCard: View {
    var engine: GoobyEngine
    var item: ItemDef
    var deal: Bool = false

    var body: some View {
        let owned = engine.owns(item.id)
        VStack(alignment: .leading, spacing: 8) {
            ShopItemArt(engine: engine, item: item, height: 96)
                .overlay(alignment: .topLeading) {
                    if deal && !owned {
                        Text(verbatim: "-15%")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(ShopInk.deal, in: Capsule())
                            .padding(6)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if !item.seasonalEvent.isEmpty && !engine.isEventActive(item.seasonalEvent) && !owned {
                        GoobyIcon("lock.fill", size: 20).padding(6)
                    }
                }
            Text(item.name.text(engine.languageCode))
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.text)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            HStack(spacing: 4) {
                ShopRarityPill(engine: engine, rarity: item.rarity)
                Spacer(minLength: 2)
                if owned {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.checkGreen)
                        .accessibilityLabel(engine.t("common.owned"))
                } else {
                    GoobyIcon("sparkles", size: 16)
                    Text(verbatim: "\(engine.price(of: item))")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Theme.text)
                        .monospacedDigit()
                }
            }
        }
        .padding(10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
        .cardShadow()
        .accessibilityElement(children: .combine)
    }
}

/// Item page: big preview (try on), name, rarity, story, then buy (with confirmation), wear or
/// take off, favorite and sell back for half.
struct ItemDetail: View {
    var engine: GoobyEngine
    var item: ItemDef
    var reduceMotion: Bool
    @State private var confirmBuy = false
    @State private var confirmSell = false
    @State private var message: String?
    @State private var preview = true

    var body: some View {
        let owned = engine.owns(item.id)
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                previewCard
                GCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name.text(engine.languageCode))
                            .font(Theme.Fonts.title)
                            .foregroundStyle(Theme.text)
                        HStack(spacing: 8) {
                            ShopRarityPill(engine: engine, rarity: item.rarity)
                            Text(engine.t("slot.\(item.slot)"))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.greyText)
                            Spacer()
                            if owned {
                                Text(engine.t("common.owned"))
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.checkGreen)
                            } else {
                                GoobyIcon("sparkles", size: 18)
                                Text(verbatim: "\(engine.price(of: item))")
                                    .font(Theme.Fonts.headline)
                                    .foregroundStyle(Theme.text)
                            }
                        }
                        Text(item.blurb.text(engine.languageCode))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.text.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                actions(owned: owned)
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.vertical, Theme.Space.gap)
        }
        .goobyScreen(Theme.Tab.shop.bg)
        .navigationTitle(engine.t("shop.detail"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(engine.t("shop.confirmBuy"), isPresented: $confirmBuy) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.buy")) {
                if let error = engine.buy(item) { message = engine.t(error) }
            }
        } message: { Text(item.name.text(engine.languageCode)) }
        .alert(engine.t("shop.confirmSell"), isPresented: $confirmSell) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.sell"), role: .destructive) {
                if let error = engine.sell(item) { message = engine.t(error) }
            }
        }
        .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: { Text(message ?? "") }
    }

    private var wearable: Bool { item.kind == "clothing" || item.kind == "color" }

    @ViewBuilder private var previewCard: some View {
        if wearable {
            GCard {
                VStack(spacing: 8) {
                    GoobyCharacterView(
                        look: engine.wornLook(preview: preview ? item : nil),
                        stage: Growth.stage(of: engine.pet),
                        animation: .present,
                        reduceMotion: reduceMotion,
                        companion: nil
                    )
                    .frame(height: 250)
                    Toggle(engine.t("shop.preview"), isOn: $preview)
                        .font(Theme.Fonts.button)
                        .foregroundStyle(Theme.text)
                        .tint(Theme.checkGreen)
                }
            }
        } else {
            GCard(padding: 10) {
                ShopItemArt(engine: engine, item: item, height: 200)
            }
        }
    }

    private var equipped: Bool {
        if item.kind == "color" { return engine.pet.furStyle == item.id }
        return engine.ownedRow(item.id)?.equippedSlot.isEmpty == false
    }

    @ViewBuilder private func actions(owned: Bool) -> some View {
        VStack(spacing: 10) {
            if owned {
                if item.kind == "travel" {
                    NavigationLink {
                        if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
                    } label: {
                        Text(engine.tx("social.shop.toMap", de: "Reiseziele ansehen", en: "See destinations"))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.quests.sky, edge: nil, radius: 18, vertical: 14, expand: true))
                } else if equipped {
                    if item.kind != "color" {
                        Button(engine.t("common.unequip")) { engine.unequip(slot: item.slot) }
                            .buttonStyle(Press3DButtonStyle(radius: 18, vertical: 14, expand: true))
                            .foregroundStyle(Theme.text)
                    }
                } else {
                    Button(engine.t("common.equip")) { engine.equip(item) }
                        .buttonStyle(Press3DButtonStyle(fill: Theme.checkGreen, edge: Theme.checkGreenEdge, radius: 18, vertical: 14, expand: true))
                        .foregroundStyle(.white)
                }
                let favorite = engine.ownedRow(item.id)?.favorite == true
                Button {
                    engine.toggleFavoriteItem(item.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: favorite ? "star.fill" : "star")
                            .foregroundStyle(Theme.progressFill)
                        Text(engine.t(favorite ? "shop.unfavorite" : "common.favorite"))
                            .foregroundStyle(Theme.text)
                    }
                }
                .buttonStyle(Press3DButtonStyle(fill: .white, radius: 18, vertical: 14, expand: true))
                if !item.starter {
                    Button(engine.t("common.sell")) { confirmSell = true }
                        .font(Theme.Fonts.button)
                        .foregroundStyle(Theme.rose)
                        .padding(.top, 4)
                }
            } else if !item.seasonalEvent.isEmpty && !engine.isEventActive(item.seasonalEvent) {
                GCard {
                    HStack(spacing: 10) {
                        GoobyIcon("lock.fill", size: 26)
                        Text(engine.t("shop.season"))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.text)
                    }
                }
            } else {
                Button {
                    confirmBuy = true
                } label: {
                    HStack(spacing: 6) {
                        GoobyIcon("sparkles", size: 22)
                        Text(engine.tf("shop.buyFor", engine.price(of: item)))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.shop.accent, edge: nil, radius: 18, vertical: 14, expand: true))
            }
        }
    }
}
