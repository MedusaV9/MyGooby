import SwiftUI

/// Bag tab (screen 7): night sky with hills, then a big orange sheet with Gooby's red bindle
/// sack on its edge, the yellow name tag and white tiles for mail, outfits, furniture, fur
/// colors and mini-friends. The bottom row names the place of Gooby's latest adventure.
struct BagScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.isPresented) private var isPresented
    @Environment(\.dismiss) private var dismiss
    @State private var showRoom = false
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            let night = max(150, geo.size.height * 0.27)
            ScrollView {
                VStack(spacing: 0) {
                    BagNightArt()
                        .frame(height: night + Theme.Radius.sheet)
                        .padding(.bottom, -Theme.Radius.sheet)
                    sheet
                        .frame(minHeight: geo.size.height - night, alignment: .top)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background {
            VStack(spacing: 0) {
                Theme.Tab.bag.night
                Theme.Tab.bag.sheet
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .top) { topRow }
        .toolbar(.hidden, for: .navigationBar)
        .navigationTitle(engine.t("kit.tab.bag"))
        .navigationDestination(isPresented: $showSettings) { SettingsView(engine: engine) }
        .goobySheet(isPresented: $showRoom) {
            if let make = FeatureHost.shared.roomScreen { make(engine) } else { RoomEditorSheet(engine: engine) }
        }
    }

    private var topRow: some View {
        HStack {
            if isPresented {
                BackChevronButton(label: engine.t("kit.back")) { dismiss() }
            }
            Spacer()
            GearButton(label: engine.t("kit.settings.open")) { showSettings = true }
        }
        .padding(.horizontal, 12)
    }

    private var sheet: some View {
        VStack(spacing: Theme.Space.gap) {
            BagSackArt()
                .padding(.top, -96)
            BagNameTag(text: tagText)
                .rotationEffect(.degrees(-2))
                .padding(.top, -34)
            NavigationLink {
                BagMailScreen(engine: engine)
            } label: {
                tile(engine.tx("social.bag.mail", de: "Post", en: "Mail"), height: 92) {
                    GoobyIcon("📮", size: 46)
                }
            }
            .buttonStyle(ShopPressStyle())
            HStack(spacing: Theme.Space.gap) {
                NavigationLink {
                    if let make = FeatureHost.shared.wardrobeScreen { make(engine) } else { BagOutfitsScreen(engine: engine, reduceMotion: reduceMotion) }
                } label: {
                    tile(engine.tx("social.bag.outfits", de: "Outfits", en: "Outfits"), height: 108) {
                        ZStack {
                            GoobyIcon("👕", size: 40).offset(x: -10, y: -4)
                            GoobyIcon("👗", size: 44).offset(x: 12, y: 4)
                        }
                        .frame(width: 64, height: 56)
                    }
                }
                .buttonStyle(ShopPressStyle())
                Button {
                    showRoom = true
                } label: {
                    tile(engine.t("kit.bag.furniture"), height: 108) {
                        GoobyIcon("🛋️", size: 56)
                    }
                }
                .buttonStyle(ShopPressStyle())
            }
            HStack(spacing: Theme.Space.gap) {
                colorsTile
                NavigationLink {
                    MicropediaScreen(engine: engine, reduceMotion: reduceMotion, fromBag: true)
                } label: {
                    tile(engine.tx("social.bag.friends", de: "Mini-Freunde", en: "Mini-friends"), height: 108) {
                        BagPawPrints(size: 54)
                    }
                }
                .buttonStyle(ShopPressStyle())
            }
            placeRow
        }
        .padding(.horizontal, Theme.Space.margin)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.sheet, topTrailingRadius: Theme.Radius.sheet, style: .continuous)
                .fill(Theme.Tab.bag.sheet)
        }
    }

    /// "Goobys Tasche" / "Gooby's bag"; German drops the s after s, ß, x and z.
    private var tagText: String {
        let trimmed = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Gooby" : trimmed
        if engine.languageCode == "de", let last = name.lowercased().last, "sßxz".contains(last) {
            return engine.txf("social.bag.tag.s", de: "%@’ Tasche", en: "%@’ bag", name)
        }
        return engine.txf("social.bag.tag", de: "%@s Tasche", en: "%@’s bag", name)
    }

    /// Fur colors beyond the starter coat. Without one the tile is locked and opens the shop.
    private var ownsColors: Bool {
        engine.all(OwnedItem.self).contains { row in
            guard let item = engine.catalog.itemsByID[row.catalogID] else { return false }
            return item.kind == "color" && !item.starter
        }
    }

    @ViewBuilder private var colorsTile: some View {
        let title = engine.tx("social.bag.colors", de: "Farben", en: "Colors")
        if ownsColors {
            NavigationLink {
                BagColorsScreen(engine: engine, reduceMotion: reduceMotion)
            } label: {
                tile(title, height: 108) {
                    GoobyIcon("🎨", size: 54)
                }
            }
            .buttonStyle(ShopPressStyle())
        } else {
            NavigationLink {
                ShopScreen(engine: engine, reduceMotion: reduceMotion, initialShop: "colors")
            } label: {
                tile(title, locked: true, height: 108) {
                    Text(verbatim: "?")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(height: 56)
                }
            }
            .buttonStyle(ShopPressStyle())
            .accessibilityHint(engine.tx("social.bag.colors.locked", de: "Noch keine Fellfarben. Öffnet den Farben-Shop.", en: "No fur colors yet. Opens the color shop."))
        }
    }

    private var placeRow: some View {
        NavigationLink {
            if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
        } label: {
            HStack(spacing: 6) {
                GoobyIcon("mappin.and.ellipse", size: 22)
                Text(engine.socialCurrentPlace()?.name.text(engine.languageCode) ?? engine.t("tab.world"))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(ShopPressStyle())
        .padding(.top, 2)
    }

    private func tile<Icon: View>(_ title: String, locked: Bool = false, height: CGFloat, @ViewBuilder icon: () -> Icon) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
        return VStack(spacing: 4) {
            icon()
            Text(title)
                .font(Theme.Fonts.headline)
                .foregroundStyle(locked ? Theme.Tab.bag.lockedLabel : Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: height)
        .background(locked ? Theme.Tab.bag.locked : Color.white, in: shape)
        .cardShadow()
        .contentShape(shape)
    }
}
