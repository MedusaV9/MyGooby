import SwiftUI

enum BagRoute: Hashable {
    case mail
    case outfits
    case furniture
    case colors
    case micropets
    case settings
    case place(String)
    case letter(String)
}

struct BagScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool = false

    var body: some View {
        GeometryReader { geo in
            let raw = min(geo.size.width / BagMetric.designWidth, max(geo.size.height, 1) / 700)
            let scale = raw.isFinite && raw > 0.01 ? raw : 1
            let top = geo.safeAreaInsets.top
            let inset = top.isFinite ? top / scale : 0
            let laid = geo.size.height.isFinite && geo.size.height > 0 ? geo.size.height / scale : 700
            BagCanvas(engine: engine, reduceMotion: reduceMotion || engine.reduceMotion, inset: inset, height: laid)
                .frame(width: BagMetric.designWidth, height: laid, alignment: .top)
                .scaleEffect(scale, anchor: .top)
                .frame(width: geo.size.width.isFinite ? geo.size.width : BagMetric.designWidth, height: geo.size.height.isFinite && geo.size.height > 0 ? geo.size.height : 700, alignment: .top)
        }
        .background(
            LinearGradient(colors: [BagColor.skyTop, BagColor.sky], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.13))
                .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: BagRoute.self) { route in
            BagDestination(route: route, engine: engine, reduceMotion: reduceMotion || engine.reduceMotion)
        }
    }
}

private struct BagCanvas: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var inset: CGFloat
    var height: CGFloat
    @State private var bob = false

    var body: some View {
        let width = BagMetric.designWidth
        ZStack(alignment: .topLeading) {
            BagGroveLayer(blobs: BagGrove.back, signs: BagGrove.signs, top: inset)
                .frame(width: width, height: BagMetric.groveHeight)
                .themedScene()
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: .idle,
                reduceMotion: true,
                companion: nil
            )
            .colorMultiply(BagGrove.petTint)
            .frame(width: BagGrove.petSize, height: BagGrove.petSize)
            .offset(x: BagGrove.petCenter.x - BagGrove.petSize / 2, y: y(BagGrove.petCenter.y) - BagGrove.petSize / 2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            BagGroveLayer(blobs: BagGrove.front, top: inset)
                .frame(width: width, height: BagMetric.groveHeight)
                .themedScene()
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(topLeading: BagMetric.stageRadius, bottomLeading: 0, bottomTrailing: 0, topTrailing: BagMetric.stageRadius),
                style: .continuous
            )
            .fill(BagColor.stage)
            .frame(width: width, height: max(0, height - y(BagMetric.stageTop) + 120))
            .offset(y: y(BagMetric.stageTop))
            .allowsHitTesting(false)
            BagSatchel()
                .frame(width: BagMetric.satchelSize.width, height: BagMetric.satchelSize.height)
                .offset(
                    x: BagMetric.satchelCenter.x - BagMetric.satchelSize.width / 2,
                    y: y(BagMetric.satchelCenter.y) + (bob && !reduceMotion ? -2 : 0) - BagMetric.satchelSize.height / 2
                )
                .accessibilityLabel(engine.t("bag.satchel"))
            NavigationLink(value: BagRoute.settings) {
                BagGear()
                    .frame(width: BagMetric.gearSize, height: BagMetric.gearSize)
                    .contentShape(Circle())
            }
            .buttonStyle(BagPressStyle(reduceMotion: reduceMotion))
            .frame(width: 44, height: 44)
            .offset(x: BagMetric.gearCenter.x - 22, y: max(y(BagMetric.gearCenter.y), 22) - 22)
            .accessibilityLabel(engine.t("bag.gear"))

            plaque
                .offset(
                    x: (width - BagMetric.plaque.width) / 2,
                    y: y(BagMetric.plaque.midY) - BagMetric.plaque.height / 2
                )

            tile(.mail, width: width - BagMetric.margin * 2)
                .offset(x: BagMetric.margin, y: y(BagMetric.mailY))
            HStack(spacing: BagMetric.gap) {
                tile(.outfits, width: columnWidth)
                tile(.furniture, width: columnWidth)
            }
            .frame(width: width - BagMetric.margin * 2, height: BagMetric.tileHeight)
            .offset(x: BagMetric.margin, y: y(BagMetric.row2Y))
            HStack(spacing: BagMetric.gap) {
                tile(.colors, width: columnWidth)
                tile(.micropets, width: columnWidth)
            }
            .frame(width: width - BagMetric.margin * 2, height: BagMetric.tileHeight)
            .offset(x: BagMetric.margin, y: y(BagMetric.row3Y))

            location
                .frame(width: width, height: 28)
                .offset(y: y(BagMetric.locationY) - 14)
        }
        .frame(width: width, height: height, alignment: .top)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
    }

    private var columnWidth: CGFloat {
        (BagMetric.designWidth - BagMetric.margin * 2 - BagMetric.gap) / 2
    }

    private func y(_ phone: CGFloat) -> CGFloat {
        let value = phone - inset
        return value.isFinite ? value : phone
    }

    private var plaque: some View {
        let title = BagTitle.text(name: engine.profile.goobyName, language: engine.languageCode)
        return ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(BagColor.plaque)
            Rectangle()
                .stroke(BagColor.dash, style: StrokeStyle(lineWidth: 2.4, dash: [6.2, 5.6]))
                .padding(BagMetric.plaqueInset)
            Text(title)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(BagColor.plaqueInk)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 18)
        }
        .frame(width: BagMetric.plaque.width, height: BagMetric.plaque.height)
        .rotationEffect(.degrees(BagMetric.plaqueTilt))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }

    private func tile(_ route: BagRoute, width: CGFloat) -> some View {
        let highlighted = locked(route)
        return NavigationLink(value: route) {
            ZStack {
                icon(route)
                    .frame(width: BagMetric.iconBox, height: BagMetric.iconBox)
                    .position(x: width / 2, y: BagMetric.iconY)
                Text(title(route))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(highlighted ? Color.white : BagColor.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 10)
                    .position(x: width / 2, y: BagMetric.labelY)
            }
            .frame(width: width, height: BagMetric.tileHeight)
            .contentShape(RoundedRectangle(cornerRadius: BagMetric.corner, style: .continuous))
            .background(highlighted ? BagColor.colorsTile : BagColor.tile, in: RoundedRectangle(cornerRadius: BagMetric.corner, style: .continuous))
        }
        .buttonStyle(BagPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(title(route))
    }

    @ViewBuilder
    private func icon(_ route: BagRoute) -> some View {
        switch route {
        case .mail: BagMailbox()
        case .outfits: BagOutfitsIcon()
        case .furniture: BagFurnitureIcon()
        case .colors:
            if locked(.colors) { BagQuestion() } else { BagColorSwatch() }
        case .micropets:
            if locked(.micropets) { BagQuestion() } else { BagPaws() }
        default: EmptyView()
        }
    }

    private func locked(_ route: BagRoute) -> Bool {
        switch route {
        case .colors:
            #if DEBUG
            if GoobyScreenshotMode.screen == "bag" { return true }
            #endif
            return !engine.catalog.items.contains { item in
                (item.kind == "color" || item.slot == "fur") && engine.owns(item.id)
            }
        case .micropets:
            #if DEBUG
            if GoobyScreenshotMode.screen == "bag" { return true }
            #endif
            return engine.all(MiniFriend.self).isEmpty
        default:
            return false
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

    @ViewBuilder
    private var location: some View {
        let trip = engine.todaysRun()
        let traveling = trip?.status == "traveling"
        let place = traveling ? trip.flatMap { engine.catalog.placesByID[$0.placeID] } : nil
        let name = place?.name.text(engine.languageCode) ?? BagTitle.house(name: engine.profile.goobyName, language: engine.languageCode)
        if let place {
            NavigationLink(value: BagRoute.place(place.id)) {
                locationRow(name)
            }
            .buttonStyle(BagPressStyle(reduceMotion: reduceMotion))
        } else {
            locationRow(name)
        }
    }

    private func locationRow(_ name: String) -> some View {
        HStack(spacing: 9) {
            BagPin()
            Text(name)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(BagColor.place)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(engine.t("bag.location"))
        .accessibilityValue(name)
    }
}

private struct BagPressStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.2), value: configuration.isPressed)
            .goobyCue(.tap, opening: configuration.isPressed)
    }
}
