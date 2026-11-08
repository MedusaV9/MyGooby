import SwiftUI

/// Bag tab (screen B): night sky with bushes, then a big orange sheet with Gooby's red bindle
/// sack on its edge, the stitched yellow name tag and white tiles for mail, outfits, furniture,
/// fur colors and mini-friends. The bottom row names the place of Gooby's latest adventure.
struct BagScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.isPresented) private var isPresented
    @Environment(\.dismiss) private var dismiss
    @State private var showRoom = false
    @State private var showSettings = false
    /// Taps on the sack; each one makes it jiggle.
    @State private var sackTaps = 0
    @State private var showWorldShot = false
    @State private var showEventsShot = false
    /// Tiles zoom into their screens (iOS 18+).
    @Namespace private var zoom

    /// Top corner radius of the orange sheet.
    private let sheetRadius: CGFloat = 36
    private let tileHeight: CGFloat = 80

    var body: some View {
        GeometryReader { geo in
            let night = max(150, geo.size.height * 0.27)
            ScrollView {
                VStack(spacing: 0) {
                    BagNightArt(reduceMotion: reduceMotion)
                        .frame(height: night + sheetRadius)
                        .padding(.bottom, -sheetRadius)
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
        .navigationDestination(isPresented: $showWorldShot) { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
        .navigationDestination(isPresented: $showEventsShot) { EventScreen(engine: engine) }
        .goobySheet(isPresented: $showRoom) {
            if let make = FeatureHost.shared.roomScreen { make(engine) } else { RoomEditorSheet(engine: engine) }
        }
        .task {
            // Screenshot routes (DEBUG only): `world` and `events` are pushed from the bag.
            guard !isPresented else { return }
            switch ShotMode.route {
            case .world?: showWorldShot = true
            case .events?: showEventsShot = true
            default: break
            }
        }
    }

    private var topRow: some View {
        HStack {
            if isPresented {
                BackChevronButton(label: engine.t("kit.back")) { dismiss() }
            }
            Spacer()
            GearButton(label: engine.t("kit.settings.open"), tint: Theme.Tab.bag.gear) { showSettings = true }
        }
        .padding(.horizontal, 12)
    }

    private var sheet: some View {
        VStack(spacing: Theme.Space.gap) {
            // The sack sits on the sheet's edge and sways gently; a tap makes it jiggle.
            Button {
                MomentHub.shared.emit(.tap)
                sackTaps += 1
            } label: {
                BagSackArt()
                    .goobySway(2, duration: 2.2, anchor: .bottom)
                    .goobyPop(on: sackTaps, amount: 1.08)
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
            .padding(.top, -60)
            BagNameTag(text: tagText)
                .padding(.top, -14)
                .padding(.bottom, 4)
            NavigationLink {
                BagMailScreen(engine: engine)
                    .goobyZoomDestination("bag.mail", in: zoom, reduce: reduceMotion)
            } label: {
                tile(engine.tx("social.bag.mail", de: "Post", en: "Mail")) {
                    BagMailIcon(size: 42)
                }
                .goobyZoomSource("bag.mail", in: zoom)
            }
            .buttonStyle(BagTilePressStyle())
            .goobyEntrance(0)
            HStack(spacing: Theme.Space.gap) {
                NavigationLink {
                    Group {
                        if let make = FeatureHost.shared.wardrobeScreen { make(engine) } else { BagOutfitsScreen(engine: engine, reduceMotion: reduceMotion) }
                    }
                    .goobyZoomDestination("bag.outfits", in: zoom, reduce: reduceMotion)
                } label: {
                    tile(engine.tx("social.bag.outfits", de: "Outfits", en: "Outfits")) {
                        BagOutfitIcon(size: 42)
                    }
                    .goobyZoomSource("bag.outfits", in: zoom)
                }
                .buttonStyle(BagTilePressStyle())
                .goobyEntrance(1)
                Button {
                    showRoom = true
                } label: {
                    tile(engine.t("kit.bag.furniture")) {
                        BagFurnitureIcon(size: 42)
                    }
                }
                .buttonStyle(BagTilePressStyle())
                .goobyEntrance(2)
            }
            HStack(spacing: Theme.Space.gap) {
                colorsTile
                    .goobyEntrance(3)
                NavigationLink {
                    MicropediaScreen(engine: engine, reduceMotion: reduceMotion, fromBag: true)
                        .goobyZoomDestination("bag.friends", in: zoom, reduce: reduceMotion)
                } label: {
                    tile(engine.tx("social.bag.friends", de: "Mini-Freunde", en: "Mini-friends")) {
                        BagPawPrints(size: 42)
                    }
                    .goobyZoomSource("bag.friends", in: zoom)
                }
                .buttonStyle(BagTilePressStyle())
                .goobyEntrance(4)
            }
            placeRow
                .goobyEntrance(5)
        }
        .padding(.horizontal, Theme.Space.margin)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: sheetRadius, topTrailingRadius: sheetRadius, style: .continuous)
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
                    .goobyZoomDestination("bag.colors", in: zoom, reduce: reduceMotion)
            } label: {
                tile(title) {
                    BagPaintsIcon(size: 42)
                }
                .goobyZoomSource("bag.colors", in: zoom)
            }
            .buttonStyle(BagTilePressStyle())
        } else {
            NavigationLink {
                ShopScreen(engine: engine, reduceMotion: reduceMotion, initialShop: "colors")
            } label: {
                tile(title, locked: true) {
                    Text(verbatim: "?")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(height: 42)
                }
            }
            .buttonStyle(BagTilePressStyle())
            .accessibilityHint(engine.tx("social.bag.colors.locked", de: "Noch keine Fellfarben. Öffnet den Farben-Shop.", en: "No fur colors yet. Opens the color shop."))
        }
    }

    private var placeRow: some View {
        NavigationLink {
            if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "mappin")
                    .font(.system(size: 12, weight: .black))
                Text(engine.socialCurrentPlace()?.name.text(engine.languageCode) ?? engine.t("tab.world"))
                    .font(Theme.Fonts.caption)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(ShopPressStyle())
        .padding(.top, 4)
    }

    private func tile<Icon: View>(_ title: String, locked: Bool = false, @ViewBuilder icon: () -> Icon) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
        return VStack(spacing: 3) {
            icon()
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(locked ? Theme.Tab.bag.lockedLabel : Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: tileHeight)
        .background(locked ? Theme.Tab.bag.locked : Color.white, in: shape)
        .shadow(color: Theme.Tab.bag.tileShadow.opacity(locked ? 0 : 0.22), radius: 3, x: 0, y: 3)
        .contentShape(shape)
    }
}

/// Bag tiles: sink and shrink a little while pressed, with the shared tap moment.
struct BagTilePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    func makeBody(configuration: Configuration) -> some View {
        let reduce = systemReduce || appReduce
        let pressed = configuration.isPressed
        configuration.label
            .scaleEffect(!reduce && pressed ? 0.96 : 1)
            .offset(y: !reduce && pressed ? 2 : 0)
            .brightness(pressed ? -0.03 : 0)
            .animation(reduce ? nil : .spring(response: 0.22, dampingFraction: 0.6), value: pressed)
            .onChange(of: pressed) { _, down in
                if down { MomentHub.shared.emit(.tap) }
            }
    }
}
