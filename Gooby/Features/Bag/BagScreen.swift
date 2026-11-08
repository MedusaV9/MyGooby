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
            let scale = min(geo.size.width / BagMetric.designWidth, max(geo.size.height, 1) / 700)
            let inset = geo.safeAreaInsets.top / scale
            BagCanvas(engine: engine, reduceMotion: reduceMotion || engine.reduceMotion, inset: inset, height: geo.size.height / scale)
                .frame(width: BagMetric.designWidth, height: geo.size.height / scale, alignment: .top)
                .scaleEffect(scale, anchor: .top)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .background(BagColor.sky.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: BagRoute.self) { route in
            BagDestination(route: route, engine: engine, reduceMotion: reduceMotion || engine.reduceMotion)
                .toolbar(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
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
            BagHills()
                .offset(y: -inset)
                .allowsHitTesting(false)
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
                .position(x: BagMetric.satchelCenter.x, y: y(BagMetric.satchelCenter.y) + (bob && !reduceMotion ? -2 : 0))
                .accessibilityLabel(engine.t("bag.satchel"))
            NavigationLink(value: BagRoute.settings) {
                BagGear()
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .position(x: BagMetric.gearCenter.x, y: max(y(BagMetric.gearCenter.y), 22))
            .accessibilityLabel(engine.t("bag.gear"))
            .simultaneousGesture(TapGesture().onEnded { engine.haptics.soft() })

            plaque
                .position(x: width / 2, y: y(BagMetric.plaque.midY))

            tile(.mail, width: width - BagMetric.margin * 2)
                .position(x: width / 2, y: y(BagMetric.mailY + BagMetric.tileHeight / 2))
            HStack(spacing: BagMetric.gap) {
                tile(.outfits, width: columnWidth)
                tile(.furniture, width: columnWidth)
            }
            .position(x: width / 2, y: y(BagMetric.row2Y + BagMetric.tileHeight / 2))
            HStack(spacing: BagMetric.gap) {
                tile(.colors, width: columnWidth)
                tile(.micropets, width: columnWidth)
            }
            .position(x: width / 2, y: y(BagMetric.row3Y + BagMetric.tileHeight / 2))

            location
                .position(x: width / 2, y: y(BagMetric.locationY))
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

    private func y(_ phone: CGFloat) -> CGFloat { phone - inset }

    private var plaque: some View {
        let title = BagTitle.text(name: engine.profile.goobyName, language: engine.languageCode)
        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(BagColor.plaque)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(BagColor.dash, style: StrokeStyle(lineWidth: 1.7, dash: [7, 5]))
                .padding(7)
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(BagColor.plaqueInk)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 16)
        }
        .frame(width: BagMetric.plaque.width, height: BagMetric.plaque.height)
        .accessibilityLabel(title)
    }

    private func tile(_ route: BagRoute, width: CGFloat) -> some View {
        let highlighted = route == .colors
        return NavigationLink(value: route) {
            VStack(spacing: 6) {
                icon(route)
                Text(title(route))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(highlighted ? Color.white : BagColor.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: width, height: BagMetric.tileHeight)
            .background(highlighted ? BagColor.colorsTile : Color.white, in: RoundedRectangle(cornerRadius: BagMetric.corner, style: .continuous))
        }
        .buttonStyle(BagPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(title(route))
        .simultaneousGesture(TapGesture().onEnded { engine.haptics.soft() })
    }

    @ViewBuilder
    private func icon(_ route: BagRoute) -> some View {
        switch route {
        case .mail: BagMailbox()
        case .outfits: BagOutfitsIcon()
        case .furniture: BagFurnitureIcon()
        case .colors: BagQuestion()
        case .micropets: BagPaws()
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

    @ViewBuilder
    private var location: some View {
        let place = BagPlace.current(engine)
        let name = place?.name.text(engine.languageCode) ?? (engine.languageCode == "en" ? "Flower Meadow" : "Blumenwiese")
        if let place {
            NavigationLink(value: BagRoute.place(place.id)) {
                locationRow(name)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { engine.haptics.soft() })
        } else {
            locationRow(name)
        }
    }

    private func locationRow(_ name: String) -> some View {
        HStack(spacing: 8) {
            BagPin()
            Text(name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
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
    }
}
