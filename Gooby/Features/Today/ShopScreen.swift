import SwiftUI

struct ShopScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var shop = "wardrobe"
    private let shops = ["wardrobe", "furniture", "colors", "travel", "seasonal"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(engine.tf("shop.balance", engine.wallet.sparks))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(shops, id: \.self) { id in
                            Button(engine.t("shop.\(id)")) { shop = id }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(shop == id ? Theme.ink : Theme.pink, in: Capsule())
                                .foregroundStyle(shop == id ? Theme.cream : Theme.ink)
                        }
                    }
                }
                Text(engine.t("shop.daily")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(daily) { item in
                        NavigationLink { ItemDetail(engine: engine, item: item, reduceMotion: reduceMotion) } label: {
                            ItemCard(engine: engine, item: item, badge: engine.t("shop.deal"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(engine.t("shop.all")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(catalog) { item in
                        NavigationLink { ItemDetail(engine: engine, item: item, reduceMotion: reduceMotion) } label: {
                            ItemCard(engine: engine, item: item, badge: engine.t("rarity.\(item.rarity)"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                wardrobe
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("tab.shop"))
    }

    private var daily: [ItemDef] {
        engine.dailyOfferIDs(shop: shop).compactMap { engine.catalog.itemsByID[$0] }
    }

    private var catalog: [ItemDef] {
        if shop == "seasonal" {
            return engine.catalog.items.filter { !$0.seasonalEvent.isEmpty && !$0.starter }
        }
        return engine.catalog.items.filter { $0.shop == shop && $0.seasonalEvent.isEmpty && !$0.starter }
    }

    private var wardrobe: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(engine.t("wardrobe.title")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
            GoobyCharacterView(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), animation: .present, reduceMotion: reduceMotion, companion: nil)
                .frame(height: 220)
            Button(engine.t("wardrobe.save")) { engine.saveOutfit(name: engine.t("wardrobe.outfit")) }
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            ForEach(engine.all(SavedOutfit.self)) { outfit in
                HStack {
                    Button(outfit.name) { engine.apply(outfit: outfit) }
                    Spacer()
                    Button { engine.toggleFavoriteOutfit(outfit) } label: {
                        Image(systemName: outfit.favorite ? "star.fill" : "star")
                    }
                }
                .foregroundStyle(Theme.ink)
            }
            Text(engine.t("pet.stage." + Growth.stage(of: engine.pet))).foregroundStyle(Theme.ink.opacity(0.7))
            ForEach(Personality.keys, id: \.self) { key in
                HStack {
                    Text(engine.t("stat.\(key)")).frame(width: 120, alignment: .leading)
                    ProgressRibbon(value: Personality.value(engine.pet, key), tint: Theme.lavender)
                    Text("\(Int(Personality.value(engine.pet, key) * 100))")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.ink)
            }
        }
    }
}

struct ItemCard: View {
    var engine: GoobyEngine
    var item: ItemDef
    var badge: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hexString: item.color))
                .frame(height: 72)
                .overlay(Image(systemName: symbol).foregroundStyle(Theme.ink.opacity(0.7)))
            Text(item.name.text(engine.languageCode)).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundStyle(Theme.ink).lineLimit(2)
            Text(badge).font(.system(.caption2, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.6))
            Text(engine.owns(item.id) ? engine.t("common.owned") : engine.tf("shop.price", engine.price(of: item)))
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
        }
        .padding(10)
        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var symbol: String {
        switch item.slot {
        case "hat": return "crown.fill"
        case "bow": return "gift.fill"
        case "glasses": return "eyeglasses"
        case "scarf": return "wind"
        default: return "tshirt.fill"
        }
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

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GoobyCharacterView(
                    look: engine.wornLook(preview: preview ? item : nil),
                    stage: Growth.stage(of: engine.pet),
                    animation: .present,
                    reduceMotion: reduceMotion,
                    companion: nil
                )
                .frame(height: 260)
                Toggle(engine.t("shop.preview"), isOn: $preview)
                Text(item.name.text(engine.languageCode)).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
                Text(item.blurb.text(engine.languageCode)).foregroundStyle(Theme.ink.opacity(0.75))
                Text(engine.t("rarity.\(item.rarity)")).foregroundStyle(Theme.ink)
                if engine.owns(item.id) {
                    Button(engine.t("common.equip")) { engine.equip(item) }.buttonStyle(GoobyButtonStyle())
                    Button(engine.t("common.unequip")) { engine.unequip(slot: item.slot) }.buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
                    Button(engine.t(engine.ownedRow(item.id)?.favorite == true ? "shop.unfavorite" : "common.favorite")) {
                        engine.toggleFavoriteItem(item.id)
                    }
                    if !item.starter {
                        Button(engine.t("common.sell")) { confirmSell = true }.foregroundStyle(Theme.rose)
                    }
                } else if !item.seasonalEvent.isEmpty && !engine.isEventActive(item.seasonalEvent) {
                    Text(engine.t("shop.season")).foregroundStyle(Theme.ink)
                } else {
                    Button(engine.tf("shop.buyFor", engine.price(of: item))) { confirmBuy = true }
                        .buttonStyle(GoobyButtonStyle(fill: Theme.rose, ink: Theme.ink))
                }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("shop.detail"))
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
}
