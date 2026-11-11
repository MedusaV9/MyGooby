import SwiftUI

enum ShellTab: String, CaseIterable, Identifiable {
    case home, quests, shop, friends, bag, gooby

    var id: String { rawValue }

    @MainActor
    func title(_ engine: GoobyEngine) -> String {
        switch self {
        case .home: return engine.t("tab.home")
        case .quests: return engine.t("tab.quests")
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
        case .home, .friends, .bag: return .white
        case .quests, .shop, .gooby: return HomePalette.labelDark
        }
    }
}

struct HomeTabBar: View {
    @Binding var selection: ShellTab
    var engine: GoobyEngine

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ShellTab.allCases) { tab in
                Button {
                    if selection != tab { GoobyFeedback.play(.tab) }
                    selection = tab
                } label: {
                    VStack(spacing: 1) {
                        icon(tab)
                            .frame(width: 36, height: 34)
                        Text(tab.title(engine))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selection.label)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(tab.pill)
                                .padding(.horizontal, 3)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title(engine))
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.top, 2)
        .frame(height: HomeMetrics.tabBody)
        .background(selection.bar.ignoresSafeArea(edges: .bottom))
    }

    @ViewBuilder private func icon(_ tab: ShellTab) -> some View {
        switch tab {
        case .home: TabHomeIcon()
        case .quests: TabQuestIcon()
        case .shop: TabShopIcon()
        case .friends: TabTreeIcon()
        case .bag: TabBagIcon()
        case .gooby: TabGoobyIcon()
        }
    }
}

struct TabHouse: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let roof = rect.height * 0.46
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: roof))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: roof))
        path.closeSubpath()
        return path
    }
}

struct TabHomeIcon: View {
    var body: some View {
        ZStack {
            TabHouse().fill(.white).frame(width: 32, height: 28)
            TabHouse().fill(HomePalette.house).frame(width: 24, height: 20)
            Circle().fill(HomePalette.houseDoor).frame(width: 8, height: 8).offset(y: 2)
        }
    }
}

struct TabQuestIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.white).frame(width: 30, height: 32)
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color(hex: 0xE0A15A)).frame(width: 25, height: 27)
            RoundedRectangle(cornerRadius: 3, style: .continuous).fill(Color(hex: 0xFFF3D4)).frame(width: 18, height: 20)
            Star(points: 5).fill(Color(hex: 0x3C8DDE)).frame(width: 12, height: 12)
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Color(hex: 0x8B5A3C)).frame(width: 10, height: 6).offset(y: -14)
        }
        .rotationEffect(.degrees(-14))
    }
}

struct TabShopIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.white).frame(width: 32, height: 24).offset(y: 5)
            Capsule().fill(.white).frame(width: 36, height: 14).offset(y: -8)
            RoundedRectangle(cornerRadius: 3, style: .continuous).fill(Color(hex: 0xFFE27A)).frame(width: 26, height: 18).offset(y: 6)
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(.white).frame(width: 7, height: 11).offset(x: 6, y: 8)
            window.offset(x: -7, y: 4)
            awning
        }
    }

    private var window: some View {
        VStack(spacing: 1.5) {
            HStack(spacing: 1.5) {
                pane
                pane
            }
            HStack(spacing: 1.5) {
                pane
                pane
            }
        }
    }

    private var pane: some View {
        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.9)).frame(width: 4, height: 3.5)
    }

    private var awning: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xE24B4B)).frame(width: 32, height: 12).offset(y: -8)
            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.95)).frame(width: 3, height: 9)
                }
            }
            .offset(y: -8)
        }
    }
}

struct TabTreeIcon: View {
    var body: some View {
        ZStack {
            Circle().fill(.white).frame(width: 28, height: 28).offset(y: -4)
            Capsule().fill(.white).frame(width: 10, height: 12).offset(y: 12)
            Circle().fill(HomePalette.treeIcon).frame(width: 22, height: 22).offset(y: -4)
            Capsule().fill(Color(hex: 0x7A4A32)).frame(width: 6, height: 8).offset(y: 12)
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    dash
                    dash
                    dash
                }
                HStack(spacing: 4) {
                    dash
                    dash
                }
            }
            .offset(y: -4)
        }
    }

    private var dash: some View {
        Capsule().fill(Color(hex: 0x3E6E28)).frame(width: 4, height: 2)
    }
}

struct BindleSack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: width * 0.38, y: height * 0.42))
        path.addLine(to: CGPoint(x: width * 0.16, y: height * 0.12))
        path.addLine(to: CGPoint(x: width * 0.36, y: height * 0.34))
        path.addLine(to: CGPoint(x: width * 0.48, y: height * 0.04))
        path.addLine(to: CGPoint(x: width * 0.60, y: height * 0.34))
        path.addLine(to: CGPoint(x: width * 0.84, y: height * 0.16))
        path.addLine(to: CGPoint(x: width * 0.68, y: height * 0.44))
        path.addLine(to: CGPoint(x: width * 0.86, y: height * 0.62))
        path.addQuadCurve(to: CGPoint(x: width * 0.62, y: height * 0.94), control: CGPoint(x: width * 0.96, y: height * 0.88))
        path.addQuadCurve(to: CGPoint(x: width * 0.18, y: height * 0.90), control: CGPoint(x: width * 0.40, y: height * 1.04))
        path.addQuadCurve(to: CGPoint(x: width * 0.14, y: height * 0.58), control: CGPoint(x: width * 0.02, y: height * 0.78))
        path.closeSubpath()
        return path
    }
}

struct TabBagIcon: View {
    var body: some View {
        ZStack {
            BindleSack().fill(.white).frame(width: 28, height: 30).offset(y: 3)
            Capsule().fill(.white).frame(width: 34, height: 7).rotationEffect(.degrees(-26)).offset(y: -6)
            BindleSack().fill(HomePalette.bag).frame(width: 22, height: 24).offset(y: 4)
            Capsule().fill(Color(hex: 0x8A5A32)).frame(width: 30, height: 3.4).rotationEffect(.degrees(-26)).offset(y: -6)
            Capsule().fill(Color(hex: 0xF0C14A)).frame(width: 9, height: 3.2).rotationEffect(.degrees(-26)).offset(x: 3, y: -5)
        }
    }
}

struct TabGoobyIcon: View {
    var body: some View {
        ZStack {
            Circle().fill(.white).frame(width: 32, height: 32)
            Circle().fill(HomePalette.fur).frame(width: 26, height: 26)
            Capsule().fill(.white).frame(width: 8, height: 12).offset(x: -8, y: -14)
            Capsule().fill(.white).frame(width: 8, height: 12).offset(x: 8, y: -14)
            Capsule().fill(HomePalette.fur).frame(width: 7, height: 11).offset(x: -8, y: -15)
            Capsule().fill(HomePalette.fur).frame(width: 7, height: 11).offset(x: 8, y: -15)
            Capsule().fill(HomePalette.innerEar).frame(width: 3.5, height: 7).offset(x: -8, y: -14)
            Capsule().fill(HomePalette.innerEar).frame(width: 3.5, height: 7).offset(x: 8, y: -14)
            Circle().fill(HomePalette.eye).frame(width: 4, height: 4).offset(x: -4.5, y: -1)
            Circle().fill(HomePalette.eye).frame(width: 4, height: 4).offset(x: 4.5, y: -1)
            Circle().fill(.white).frame(width: 1.5, height: 1.5).offset(x: -5.2, y: -2)
            Circle().fill(.white).frame(width: 1.5, height: 1.5).offset(x: 3.8, y: -2)
            Ellipse().fill(HomePalette.nose).frame(width: 4, height: 3).offset(y: 4)
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
