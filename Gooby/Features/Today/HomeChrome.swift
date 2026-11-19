import SwiftUI

/// Chest at the end of the energy capsule, and the activity fan in the top corner.
enum HomeFanLeaf: String, CaseIterable, Identifiable, Hashable {
    case aid, write, goals, sheet

    var id: String { rawValue }
    var titleKey: String { "home.fan.\(rawValue)" }

    /// Offset from the bolt's center. The arc opens down and to the left.
    var burst: CGSize {
        switch self {
        case .aid: return CGSize(width: -16, height: 78)
        case .write: return CGSize(width: -86, height: 118)
        case .goals: return CGSize(width: -156, height: 92)
        case .sheet: return CGSize(width: -200, height: 24)
        }
    }

    var tilt: Double {
        switch self {
        case .aid: return -8
        case .write: return -16
        case .goals: return -26
        case .sheet: return 10
        }
    }
}

struct HomeEnergyChest: View {
    var full: Bool
    var reduceMotion: Bool
    var title: String
    var value: String
    var hint: String
    var action: () -> Void

    var body: some View {
        Button {
            guard full else { return }
            action()
        } label: {
            HomeChestMark(full: full, reduceMotion: reduceMotion)
                .frame(width: 36, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityHint(hint)
    }
}

struct HomeChestMark: View {
    var full: Bool
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                .fill(Color(hex: 0x8F6243))
                .frame(width: 30, height: 16)
                .offset(y: 7)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: 0xC4894A))
                .frame(width: 30, height: 13)
                .offset(y: 6)
            if full {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(hex: 0x5C3A22))
                    .frame(width: 22, height: 5)
                    .offset(y: 1)
            }
            Capsule()
                .fill(Color(hex: 0xE7B56A))
                .frame(width: 30, height: 3.5)
                .offset(y: 5)
            RoundedRectangle(cornerRadius: 1.4, style: .continuous)
                .fill(Color(hex: 0xF5BA25))
                .frame(width: 7, height: 8)
                .offset(y: 8)
            Circle()
                .fill(Color(hex: 0x6B4128))
                .frame(width: 2.2, height: 2.2)
                .offset(y: 8.4)
            HomeChestLid()
                .fill(full ? Color(hex: 0xF6D7A4) : Color(hex: 0xE7C48A))
                .overlay {
                    HomeChestLid()
                        .stroke(Color(hex: 0xC4894A), lineWidth: 1)
                }
                .frame(width: 32, height: 13)
                .rotationEffect(.degrees(full ? -42 : 0), anchor: .bottom)
                .offset(y: full ? -1 : -6)
                .animation(reduceMotion ? nil : .spring(duration: 0.35), value: full)
            if full {
                HomeSparkMark()
                    .frame(width: 11, height: 11)
                    .offset(x: 13, y: -13)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHidden(true)
    }
}

struct HomeChestLid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.15)
        )
        path.closeSubpath()
        return path
    }
}

struct HomeFanButton: View {
    var open: Bool
    var reduceMotion: Bool
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color(hex: 0x5C6E80).opacity(0.4), radius: 1.5, y: 1)
                BoltShape()
                    .fill(HomePalette.bolt)
                    .frame(width: 16, height: 22)
                BoltShape()
                    .stroke(HomePalette.boltDeep, lineWidth: 0.8)
                    .frame(width: 16, height: 22)
            }
            .frame(width: 40, height: 40)
            .rotationEffect(.degrees(open ? 8 : 0))
            .animation(reduceMotion ? nil : .spring(duration: 0.3), value: open)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct HomeFanPetals: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var onPick: (HomeFanLeaf) -> Void
    @State private var sprung = false

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .overlay {
                petals
            }
    }

    private var petals: some View {
        ZStack {
            ForEach(Array(HomeFanLeaf.allCases.enumerated()), id: \.element) { index, leaf in
                Button {
                    onPick(leaf)
                } label: {
                    HomeFanPetal(leaf: leaf, title: engine.t(leaf.titleKey))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t(leaf.titleKey))
                .offset(sprung || reduceMotion ? leaf.burst : .zero)
                .scaleEffect(sprung || reduceMotion ? 1 : 0.25)
                .opacity(sprung || reduceMotion ? 1 : 0)
                .rotationEffect(.degrees(sprung || reduceMotion ? leaf.tilt : 0))
                .animation(
                    reduceMotion ? nil : .spring(duration: 0.42, bounce: 0.2).delay(0.04 * Double(index)),
                    value: sprung
                )
            }
        }
        .task {
            guard !reduceMotion else {
                sprung = true
                return
            }
            try? await Task.sleep(for: .milliseconds(20))
            sprung = true
        }
    }
}

struct HomeFanPetal: View {
    var leaf: HomeFanLeaf
    var title: String

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().fill(Color.white)
                leafMark
            }
            .frame(width: 46, height: 46)
            .shadow(color: Color.black.opacity(0.16), radius: 4, y: 2)
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: Color(hex: 0x1E3A5F).opacity(0.55), radius: 1, y: 1)
                .lineLimit(1)
                .fixedSize()
        }
    }

    @ViewBuilder private var leafMark: some View {
        switch leaf {
        case .aid: HomeFanAidMark()
        case .write: HomeFanPenMark()
        case .goals: HomeFanGoalsMark()
        case .sheet: HomeFanSheetMark()
        }
    }
}

struct HomeFanAidMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white)
                .frame(width: 24, height: 16)
                .offset(y: 3)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0xF7B4C4))
                .frame(width: 11, height: 5)
                .offset(y: -7)
            Rectangle().fill(Color(hex: 0xE4534A)).frame(width: 9, height: 2.6)
            Rectangle().fill(Color(hex: 0xE4534A)).frame(width: 2.6, height: 9)
        }
        .accessibilityHidden(true)
    }
}

struct HomeFanPenMark: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0x2A2E35))
                .frame(width: 8, height: 22)
                .rotationEffect(.degrees(-38))
            Capsule()
                .fill(Color(hex: 0xF2C14E))
                .frame(width: 8, height: 7)
                .rotationEffect(.degrees(-38))
                .offset(x: 7, y: -8)
            Circle()
                .fill(Color(hex: 0xE4534A))
                .frame(width: 4, height: 4)
                .offset(x: -9, y: 9)
        }
        .accessibilityHidden(true)
    }
}

struct HomeFanGoalsMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0xF4F7FB))
                .frame(width: 22, height: 18)
            Capsule().fill(Color(hex: 0xC5CDD6)).frame(width: 12, height: 2).offset(x: 2, y: -4)
            Capsule().fill(Color(hex: 0xC5CDD6)).frame(width: 12, height: 2).offset(x: 2, y: 2)
            HomeFanCheck()
                .stroke(Color(hex: 0x3EAE45), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .frame(width: 8, height: 6)
                .offset(x: -7, y: -4)
        }
        .accessibilityHidden(true)
    }
}

struct HomeFanCheck: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

struct HomeFanSheetMark: View {
    var body: some View {
        ZStack {
            HomeFanPage()
                .fill(Color(hex: 0xFFF6EA))
                .frame(width: 18, height: 22)
            HomeFanPage()
                .stroke(Color(hex: 0xE7C9A8), lineWidth: 1)
                .frame(width: 18, height: 22)
            Capsule().fill(Color(hex: 0xE7C9A8)).frame(width: 9, height: 1.6).offset(y: -2)
            Capsule().fill(Color(hex: 0xE7C9A8)).frame(width: 9, height: 1.6).offset(y: 2)
            HomeFanFold()
                .fill(Color(hex: 0xF0D8C4))
                .frame(width: 6, height: 6)
                .offset(x: 6, y: -8)
        }
        .accessibilityHidden(true)
    }
}

struct HomeFanPage: Shape {
    func path(in rect: CGRect) -> Path {
        let fold = min(rect.width, rect.height) * 0.32
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + fold))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct HomeFanFold: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
