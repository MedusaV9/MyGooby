import SwiftUI

enum ShellTab: String, CaseIterable, Identifiable {
    case home, quests, shop, friends, bag, gooby

    var id: String { rawValue }

    @MainActor
    func title(_ engine: GoobyEngine) -> String {
        switch self {
        case .home: return engine.t("tab.home")
        case .quests: return engine.t("tab.event")
        case .shop: return engine.t("tab.shop")
        case .friends: return engine.t("tab.friends")
        case .bag: return engine.t("tab.bag")
        case .gooby:
            let name = engine.profile.goobyName.trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? "Gooby" : name
        }
    }

    var bar: Color {
        switch self {
        case .home, .friends: return HomePalette.tabBar
        case .quests: return HomePalette.questsBar
        case .shop: return HomePalette.shopBar
        case .bag: return HomePalette.bagBar
        case .gooby: return HomePalette.goobyBar
        }
    }

    var pill: Color {
        switch self {
        case .home, .friends: return HomePalette.pill
        case .quests: return HomePalette.questsPill
        case .shop: return HomePalette.shopPill
        case .bag: return HomePalette.bagPill
        case .gooby: return HomePalette.creamPill
        }
    }

    var label: Color {
        switch self {
        case .home, .friends, .bag, .shop: return .white
        case .quests, .gooby: return HomePalette.labelDark
        }
    }
}

struct HomeTabBar: View {
    @Binding var selection: ShellTab
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    var body: some View {
        let kind = HomeStageTone.shared.kind
        HStack(spacing: 0) {
            ForEach(ShellTab.allCases) { tab in
                Button {
                    let dock = tab == .shop || tab == .bag
                    if !dock, selection != tab { GoobyFeedback.play(.tab) }
                    selection = tab
                } label: {
                    VStack(spacing: 2) {
                        ShellTabIcon(tab: tab)
                            .frame(width: 34, height: 32)
                            .overlay(alignment: .topTrailing) { badge(for: tab) }
                        Text(tab.title(engine))
                            .font(.system(size: 11.5, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .foregroundStyle(selection.label)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .padding(.bottom, 5)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: HomeMetrics.tabPillRadius, style: .continuous)
                                .fill(selection == .home ? kind.pill : tab.pill)
                                .padding(.horizontal, 1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title(engine))
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .frame(height: HomeMetrics.tabBody)
        .background((selection == .home ? kind.bar : selection.bar).ignoresSafeArea(edges: .bottom))
        .animation((systemReduce || engine.reduceMotion) ? nil : .easeInOut(duration: 0.35), value: kind)
        .onAppear { refreshFriendsDot() }
        .onChange(of: selection) { _, _ in refreshFriendsDot() }
    }

    @State private var friendsDot = false

    /// Quests that are finished but not yet claimed. The event tab still carries the count, because the quest list opens from there.
    private var readyQuests: Int {
        let key = engine.dayKey()
        let ready = engine.all(QuestRecord.self).filter { quest in
            !quest.claimed && quest.progress >= max(1, quest.goal) && (quest.kind != "daily" || quest.dayKey == key)
        }
        return min(9, ready.count)
    }

    /// Friends carries a dot while Home still invites the player to buddy up.
    private func refreshFriendsDot() {
        friendsDot = !UserDefaults.standard.bool(forKey: HomeStage.buddyDismissedKey) && FriendsBook.load().pals.isEmpty
    }

    @ViewBuilder private func badge(for tab: ShellTab) -> some View {
        let dot = Color(hex: 0xE8475F)
        if tab == .quests, readyQuests > 0 {
            Text("\(readyQuests)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 17, minHeight: 17)
                .background(dot, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                .offset(x: 7, y: -3)
                .accessibilityHidden(true)
        } else if tab == .friends, friendsDot {
            Circle()
                .fill(dot)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .offset(x: 7, y: -3)
                .accessibilityHidden(true)
        }
    }
}

struct ShellTabIcon: View {
    var tab: ShellTab

    var body: some View {
        switch tab {
        case .home: TabHomeIcon()
        case .quests: TabEventIcon()
        case .shop: TabShopIcon()
        case .friends: TabTreeIcon()
        case .bag: TabBagIcon()
        case .gooby: TabGoobyIcon()
        }
    }
}

struct WideTabRail: View {
    @Binding var selection: ShellTab
    var engine: GoobyEngine
    var night: Bool
    var questBadge: Int

    var body: some View {
        VStack(spacing: 8) {
            ForEach(ShellTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    railItem(tab)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title(engine))
                .accessibilityValue(tab == .quests && questBadge > 0 ? "\(questBadge)" : "")
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(width: GoobySize.sideRailWidth)
        .frame(maxHeight: .infinity)
        .background(rail.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(engine.t("pad.tabs"))
    }

    private func railItem(_ tab: ShellTab) -> some View {
        let selected = selection == tab
        return VStack(spacing: 3) {
            ShellTabIcon(tab: tab)
                .frame(width: 34, height: 32)
                .overlay(alignment: .topTrailing) {
                    if tab == .quests, questBadge > 0 {
                        Text("\(questBadge)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .padding(.horizontal, 3)
                            .background(Color(hex: 0xE24B4B), in: Capsule())
                            .offset(x: 8, y: -6)
                    }
                }
            Text(tab.title(engine))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .foregroundStyle(label(selected))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .padding(.horizontal, 2)
        .background {
            if selected {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(pill)
            }
        }
    }

    private var rail: Color { night ? Color(hex: 0x16141C) : Color(hex: 0xE4F6D4) }
    private var pill: Color { night ? Color(hex: 0x6E5CB8) : Color(hex: 0x8ED45C) }

    private func label(_ selected: Bool) -> Color {
        if night { return Color.white.opacity(selected ? 1 : 0.88) }
        return HomePalette.ink
    }
}

/// Sticker icons measured from the PR 34 tab bar: a thick white rim, then the flat color.
enum TabSticker {
    static let rim: CGFloat = 4.8

    static func paint(_ context: inout GraphicsContext, _ path: Path, fill: Color, rim: CGFloat = TabSticker.rim) {
        context.stroke(
            path,
            with: .color(.white),
            style: StrokeStyle(lineWidth: rim, lineCap: .round, lineJoin: .round)
        )
        context.fill(path, with: .color(.white))
        context.fill(path, with: .color(fill))
    }
}

struct TabHomeIcon: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 32
            context.scaleBy(x: s, y: s)
            TabSticker.paint(&context, house, fill: Color(hex: 0xF6B14A))
            context.fill(Path(ellipseIn: CGRect(x: 12.2, y: 16.2, width: 7.6, height: 7.6)), with: .color(Color(hex: 0xE07F1E)))
        }
    }

    /// Birdhouse: peaked roof, square body, round entrance in the middle.
    private var house: Path {
        var path = Path()
        path.move(to: CGPoint(x: 16, y: 3.2))
        path.addLine(to: CGPoint(x: 28.4, y: 13.2))
        path.addLine(to: CGPoint(x: 24.6, y: 13.2))
        path.addLine(to: CGPoint(x: 24.6, y: 27.4))
        path.addLine(to: CGPoint(x: 7.4, y: 27.4))
        path.addLine(to: CGPoint(x: 7.4, y: 13.2))
        path.addLine(to: CGPoint(x: 3.6, y: 13.2))
        path.closeSubpath()
        return path
    }
}

/// Ship with a small clock. Original tab mark for the seasonal event.
struct TabEventIcon: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 32
            context.scaleBy(x: s, y: s)
            TabSticker.paint(&context, hull, fill: Color(hex: 0xC08946))
            TabSticker.paint(&context, sail, fill: Color(hex: 0xFFF6EA), rim: 3.2)
            context.fill(mast, with: .color(Color(hex: 0x8F6243)))
            TabSticker.paint(&context, clock, fill: Color(hex: 0xF5BA25), rim: 3.2)
            context.stroke(
                hands,
                with: .color(Color(hex: 0x6B4128)),
                style: StrokeStyle(lineWidth: 1.25, lineCap: .round)
            )
        }
    }

    private var hull: Path {
        var path = Path()
        path.move(to: CGPoint(x: 3.4, y: 20.6))
        path.addQuadCurve(to: CGPoint(x: 22.4, y: 20.6), control: CGPoint(x: 13, y: 29.2))
        path.addLine(to: CGPoint(x: 19.6, y: 17.2))
        path.addLine(to: CGPoint(x: 6.2, y: 17.2))
        path.closeSubpath()
        return path
    }

    private var sail: Path {
        var path = Path()
        path.move(to: CGPoint(x: 13.2, y: 4.6))
        path.addLine(to: CGPoint(x: 13.2, y: 16.6))
        path.addLine(to: CGPoint(x: 5.4, y: 16.6))
        path.closeSubpath()
        return path
    }

    private var mast: Path {
        Path(roundedRect: CGRect(x: 12.4, y: 4.8, width: 1.7, height: 13.2), cornerRadius: 0.8)
    }

    private var clock: Path {
        Path(ellipseIn: CGRect(x: 16.6, y: 15.2, width: 13.2, height: 13.2))
    }

    private var hands: Path {
        var path = Path()
        path.move(to: CGPoint(x: 23.2, y: 21.8))
        path.addLine(to: CGPoint(x: 23.2, y: 17.6))
        path.move(to: CGPoint(x: 23.2, y: 21.8))
        path.addLine(to: CGPoint(x: 26.4, y: 21.8))
        return path
    }
}

struct TabShopIcon: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 32
            context.scaleBy(x: s, y: s)
            let shop = Path(roundedRect: CGRect(x: 7.2, y: 13.2, width: 17.6, height: 13.4), cornerRadius: 2.4)
            TabSticker.paint(&context, shop, fill: Color(hex: 0xF6D25A), rim: 4.4)
            TabSticker.paint(&context, awning, fill: Color(hex: 0xE23B3C), rim: 5.2)
            context.drawLayer { layer in
                layer.clip(to: awning)
                for x in [9.4, 14.2, 19.0] as [CGFloat] {
                    layer.fill(Path(CGRect(x: x, y: 5.5, width: 2.3, height: 9)), with: .color(.white))
                }
            }
            context.fill(Path(roundedRect: CGRect(x: 18.6, y: 17.2, width: 4.6, height: 9.2), cornerRadius: 1), with: .color(.white))
            for row in 0..<2 {
                for col in 0..<2 {
                    let pane = CGRect(x: 9.2 + CGFloat(col) * 3.5, y: 16.2 + CGFloat(row) * 3.3, width: 2.6, height: 2.4)
                    context.fill(Path(roundedRect: pane, cornerRadius: 0.4), with: .color(.white))
                }
            }
        }
    }

    private var awning: Path {
        var path = Path()
        path.move(to: CGPoint(x: 5.2, y: 14.2))
        path.addQuadCurve(to: CGPoint(x: 26.8, y: 14.2), control: CGPoint(x: 16, y: 3.6))
        path.closeSubpath()
        return path
    }
}

struct TabTreeIcon: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 32
            context.scaleBy(x: s, y: s)
            let trunk = Path(roundedRect: CGRect(x: 11.4, y: 21.2, width: 4.4, height: 6.6), cornerRadius: 1.2)
            let crown = Path(ellipseIn: CGRect(x: 3.4, y: 8.4, width: 18.6, height: 16.4))
            TabSticker.paint(&context, trunk, fill: Color(hex: 0x6A3E2A), rim: 3.2)
            TabSticker.paint(&context, crown, fill: Color(hex: 0x3E9A32))
            for dot in [CGPoint(x: 8.2, y: 13), CGPoint(x: 13.4, y: 12.2), CGPoint(x: 10.6, y: 16.6), CGPoint(x: 16.2, y: 16), CGPoint(x: 13, y: 19.4)] {
                context.fill(Path(ellipseIn: CGRect(x: dot.x, y: dot.y, width: 2.2, height: 1.8)), with: .color(Color(hex: 0x2C7424)))
            }
            let fruit = Path(ellipseIn: CGRect(x: 17.4, y: 4.6, width: 8.4, height: 8.4))
            TabSticker.paint(&context, fruit, fill: Color(hex: 0xE23A5C), rim: 2.8)
        }
    }
}

struct TabBagIcon: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 32
            context.scaleBy(x: s, y: s)
            context.drawLayer { layer in
                layer.translateBy(x: 16, y: 13)
                layer.rotate(by: .degrees(-22))
                layer.translateBy(x: -16, y: -13)
                let stick = Path(roundedRect: CGRect(x: 2.4, y: 11.6, width: 27.2, height: 3.4), cornerRadius: 1.7)
                TabSticker.paint(&layer, stick, fill: Color(hex: 0x8A5A32), rim: 2.8)
            }
            TabSticker.paint(&context, sack, fill: Color(hex: 0xE23B3B))
            context.fill(Path(roundedRect: CGRect(x: 13.4, y: 12.6, width: 5.4, height: 2.8), cornerRadius: 1.2), with: .color(Color(hex: 0xF0C14A)))
        }
    }

    private var sack: Path {
        var path = Path()
        path.move(to: CGPoint(x: 12.2, y: 15.4))
        path.addLine(to: CGPoint(x: 13.6, y: 11.4))
        path.addQuadCurve(to: CGPoint(x: 18.4, y: 11.4), control: CGPoint(x: 16, y: 8.2))
        path.addLine(to: CGPoint(x: 19.8, y: 15.4))
        path.addQuadCurve(to: CGPoint(x: 26.4, y: 22.4), control: CGPoint(x: 28.2, y: 17.2))
        path.addQuadCurve(to: CGPoint(x: 16, y: 29.6), control: CGPoint(x: 25.2, y: 31))
        path.addQuadCurve(to: CGPoint(x: 5.6, y: 22.4), control: CGPoint(x: 6.8, y: 31))
        path.addQuadCurve(to: CGPoint(x: 12.2, y: 15.4), control: CGPoint(x: 4.2, y: 17.2))
        path.closeSubpath()
        return path
    }
}

struct TabGoobyIcon: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 32
            context.scaleBy(x: s, y: s)
            for x in [11.2, 20.8] as [CGFloat] {
                let ear = Path(ellipseIn: CGRect(x: x - 2.5, y: 3.2, width: 5, height: 9.2))
                TabSticker.paint(&context, ear, fill: Color(hex: 0xFFF3E4), rim: 3.2)
                context.fill(Path(ellipseIn: CGRect(x: x - 1.2, y: 5.4, width: 2.4, height: 5.2)), with: .color(Color(hex: 0xFFC2D6)))
            }
            let face = Path(ellipseIn: CGRect(x: 6.4, y: 8.6, width: 19.2, height: 19.2))
            TabSticker.paint(&context, face, fill: Color(hex: 0xFFF3E4), rim: 4.2)
            context.fill(Path(ellipseIn: CGRect(x: 11.2, y: 15.2, width: 2.5, height: 3.1)), with: .color(Color(hex: 0x4A3428)))
            context.fill(Path(ellipseIn: CGRect(x: 18.2, y: 15.2, width: 2.5, height: 3.1)), with: .color(Color(hex: 0x4A3428)))
            context.fill(Path(ellipseIn: CGRect(x: 14.6, y: 18.6, width: 2.8, height: 2.1)), with: .color(Color(hex: 0xFF9BB8)))
        }
    }
}

struct BoltShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.4))
        path.addLine(to: CGPoint(x: rect.midX + 1, y: rect.height * 0.4))
        path.closeSubpath()
        return path
    }
}

struct TrackBunny: View {
    var body: some View {
        ZStack {
            Circle().fill(.white).frame(width: 30, height: 30)
            Circle().fill(HomePalette.fur).frame(width: 24, height: 24)
            Capsule().fill(HomePalette.fur).frame(width: 6, height: 9).offset(x: -7, y: -13)
            Capsule().fill(HomePalette.fur).frame(width: 6, height: 9).offset(x: 7, y: -13)
            Capsule().fill(HomePalette.innerEar).frame(width: 3, height: 5).offset(x: -7, y: -12)
            Capsule().fill(HomePalette.innerEar).frame(width: 3, height: 5).offset(x: 7, y: -12)
            Circle().fill(HomePalette.eye).frame(width: 3.5, height: 3.5).offset(x: -4, y: -1)
            Circle().fill(HomePalette.eye).frame(width: 3.5, height: 3.5).offset(x: 4, y: -1)
            Ellipse().fill(HomePalette.nose).frame(width: 3.5, height: 2.5).offset(y: 4)
        }
    }
}
