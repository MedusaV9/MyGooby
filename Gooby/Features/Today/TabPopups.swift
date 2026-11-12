import SwiftUI

/// Shop and bag grow out of the tab bar instead of taking the page.
/// The panel uses the catalog spring: scale 0.6 from the bottom, plus opacity.
enum TabPopup: Equatable {
    case shop
    case bag

    var tab: ShellTab {
        switch self {
        case .shop: return .shop
        case .bag: return .bag
        }
    }

    static func startingPage() -> ShellTab {
        #if DEBUG
        let tab = GoobyScreenshotMode.tab
        if tab == .shop || tab == .bag { return .home }
        return tab
        #else
        return .home
        #endif
    }

    static func startingPopup() -> TabPopup? {
        #if DEBUG
        switch GoobyScreenshotMode.tab {
        case .shop: return .shop
        case .bag: return .bag
        default: return nil
        }
        #else
        return nil
        #endif
    }
}

/// One cover for both counters, so shop and bag are not two competing full-screen covers.
enum TabHop: Identifiable {
    case shop(ShopFloor)
    case bag(BagRoute)

    var id: String {
        switch self {
        case .shop(let floor): return "shop-\(floor.rawValue)"
        case .bag(let route): return "bag-\(route.id)"
        }
    }
}

/// Dims the page under the open dock and lays the panel on the tab bar.
struct TabDock: View {
    var popup: TabPopup
    var engine: GoobyEngine
    var reduceMotion: Bool
    var close: () -> Void
    var openShop: (ShopFloor) -> Void
    var openBag: (BagRoute) -> Void
    var openHome: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea(edges: [.top, .horizontal])
                .contentShape(Rectangle())
                .onTapGesture(perform: close)
                .accessibilityElement()
                .accessibilityLabel(engine.t("common.close"))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(.default, close)
                .accessibilitySortPriority(-1)
                .transition(.opacity)
            panelBlock
                .fixedSize(horizontal: false, vertical: true)
                .id(popup)
                .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
        }
    }

    private var panelBlock: some View {
        panel
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var panel: some View {
        switch popup {
        case .shop:
            ShopPopupPanel(engine: engine, still: reduceMotion, open: openShop)
        case .bag:
            BagPopupPanel(engine: engine, still: reduceMotion, open: openBag, openHome: openHome)
        }
    }
}

struct ShopPopupPanel: View {
    var engine: GoobyEngine
    var still: Bool
    var open: (ShopFloor) -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabShopIcon()
                .frame(width: 86, height: 78)
                .accessibilityHidden(true)
                .padding(.bottom, -30)
                .zIndex(1)
            VStack(spacing: 16) {
                TabPopupPlaque(text: engine.t("popup.shop.sign"))
                HStack(spacing: 12) {
                    shopChoice(.clothes, title: engine.t("popup.shop.clothes")) { BagOutfitsIcon() }
                    shopChoice(.furniture, title: engine.t("popup.shop.furniture")) { BagFurnitureIcon() }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 38)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .background(TabPopupShape().fill(HomePalette.shopPopup))
        }
        .accessibilityElement(children: .contain)
    }

    private func shopChoice(_ floor: ShopFloor, title: String, @ViewBuilder icon: () -> some View) -> some View {
        Button { open(floor) } label: {
            VStack(spacing: 4) {
                icon()
                    .frame(width: 40, height: 40)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(BagColor.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(TabPopupPress(still: still))
        .accessibilityLabel(title)
    }
}

struct BagPopupPanel: View {
    var engine: GoobyEngine
    var still: Bool
    var open: (BagRoute) -> Void
    var openHome: () -> Void
    @State private var swing = false

    var body: some View {
        VStack(spacing: 0) {
            BagSatchel()
                .frame(width: 76, height: 76)
                .rotationEffect(.degrees(still ? 0 : (swing ? 8 : -8)), anchor: .bottom)
                .offset(y: still ? 0 : (swing ? -3 : 2))
                .accessibilityHidden(true)
                .padding(.bottom, -28)
                .zIndex(1)
            VStack(spacing: 12) {
                TabPopupPlaque(text: BagTitle.text(name: engine.profile.goobyName, language: engine.languageCode))
                tile(.mail, wide: true)
                HStack(spacing: 12) {
                    tile(.outfits, wide: false)
                    tile(.furniture, wide: false)
                }
                HStack(spacing: 12) {
                    tile(.colors, wide: false)
                    tile(.micropets, wide: false)
                }
                burrow
                    .padding(.top, 2)
            }
            .padding(.horizontal, 18)
            .padding(.top, 36)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity)
            .background(TabPopupShape().fill(BagColor.stage))
        }
        .onAppear {
            guard !still else { return }
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                swing = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func tile(_ route: BagRoute, wide: Bool) -> some View {
        let locked = TabBagLock.isLocked(route, engine)
        return Button { open(route) } label: {
            VStack(spacing: 2) {
                icon(route, locked: locked)
                    .frame(width: 36, height: 36)
                Text(title(route))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(locked ? Color.white : BagColor.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: wide ? 78 : 86)
            .background(
                locked ? BagColor.colorsTile : BagColor.tile,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
        .buttonStyle(TabPopupPress(still: still))
        .accessibilityLabel(title(route))
        .accessibilityHint(hint(route, locked: locked))
    }

    @ViewBuilder
    private func icon(_ route: BagRoute, locked: Bool) -> some View {
        switch route {
        case .mail: BagMailbox()
        case .outfits: BagOutfitsIcon()
        case .furniture: BagFurnitureIcon()
        case .colors:
            if locked { BagQuestion() } else { BagColorsIcon() }
        case .micropets:
            if locked { BagQuestion() } else { BagPaws() }
        default: EmptyView()
        }
    }

    private func title(_ route: BagRoute) -> String {
        switch route {
        case .mail: engine.t("bag.mail")
        case .outfits: engine.t("bag.outfits")
        case .furniture: engine.t("bag.furniture")
        case .colors: engine.t("bag.colors")
        case .micropets: engine.t("bag.micropets")
        default: ""
        }
    }

    private func hint(_ route: BagRoute, locked: Bool) -> String {
        guard locked, route == .colors else { return "" }
        return engine.t("bag.colors.locked")
    }

    private var burrow: some View {
        let trip = engine.todaysRun()
        let place = trip?.status == "traveling" ? trip.flatMap { engine.catalog.placesByID[$0.placeID] } : nil
        let name = place?.name.text(engine.languageCode) ?? BagTitle.house(name: engine.profile.goobyName, language: engine.languageCode)
        return Button {
            if let place {
                open(.place(place.id))
            } else {
                openHome()
            }
        } label: {
            HStack(spacing: 8) {
                BagPin()
                Text(name)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(BagColor.place)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(TabPopupPress(still: still))
        .accessibilityLabel(engine.t("bag.location"))
        .accessibilityValue(name)
    }
}

/// Same gates as the bag page: colors after the first return, mini-friends after one hatches.
@MainActor
enum TabBagLock {
    static func isLocked(_ route: BagRoute, _ engine: GoobyEngine) -> Bool {
        switch route {
        case .colors:
            return !BagColorsGate.isOpen(engine)
        case .micropets:
            #if DEBUG
            if GoobyScreenshotMode.screen == "bag" { return true }
            #endif
            return engine.all(MiniFriend.self).isEmpty
        default:
            return false
        }
    }
}

/// Root of a bag destination opened from the popup. Pages that already dismiss themselves keep that control.
struct TabBagCover: View {
    var route: BagRoute
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        BagDestination(route: route, engine: engine, reduceMotion: reduceMotion)
            .toolbar {
                if needsClose {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .heavy))
                        }
                        .accessibilityLabel(engine.t("common.close"))
                    }
                }
            }
    }

    private var needsClose: Bool {
        switch route {
        case .mail, .outfits, .furniture:
            return false
        case .colors:
            return !BagColorsGate.isOpen(engine)
        default:
            return true
        }
    }
}

struct TabPopupPlaque: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(BagColor.plaqueInk)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .padding(.horizontal, 18)
            .frame(minWidth: 148, minHeight: 42)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(BagColor.plaque)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(BagColor.dash, style: StrokeStyle(lineWidth: 2.2, dash: [6, 5.4]))
                        .padding(5)
                }
            }
            .rotationEffect(.degrees(BagMetric.plaqueTilt))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
    }
}

struct TabPopupShape: Shape {
    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(topLeading: 32, bottomLeading: 0, bottomTrailing: 0, topTrailing: 32),
            style: .continuous
        ).path(in: rect)
    }
}

private struct TabPopupPress: ButtonStyle {
    var still: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!still && configuration.isPressed ? 0.97 : 1)
            .animation(still ? nil : .spring(duration: 0.2), value: configuration.isPressed)
    }
}
