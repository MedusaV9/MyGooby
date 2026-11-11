import SwiftUI

enum ShopFloor: String, CaseIterable, Identifiable {
    case clothes
    case furniture

    var id: String { rawValue }
}

struct ShopFloorPaint {
    var screen: Color
    var sheet: Color
    var cell: Color
    var ink: Color
    var badge: Color
    var lightStatus: Bool
    var pill: Color = .white.opacity(0.3)

    static let clothes = ShopFloorPaint(
        screen: Color(hex: 0x3FD2F7),
        sheet: Color(hex: 0x4E328B),
        cell: Color(hex: 0x6F50BB),
        ink: .white,
        badge: Color(hex: 0xEC6B19),
        lightStatus: true,
        pill: Color(hex: 0x8971B6)
    )

    static let furniture = ShopFloorPaint(
        screen: Color(hex: 0xE5D244),
        sheet: Color(hex: 0x895A3A),
        cell: Color(hex: 0xBC835D),
        ink: .white,
        badge: Color(hex: 0xEC6B19),
        lightStatus: true,
        pill: Color(hex: 0xAE9077)
    )

    static func season(_ id: String) -> ShopFloorPaint {
        switch id {
        case "starry-nights":
            return dark(screen: 0x2C3A78, sheet: 0x243268, cell: 0x3A4C96, badge: 0xF0B429)
        case "winter", "winter-warmth":
            return light(screen: 0xD7ECFF, sheet: 0xB9D8F5, cell: 0xE7F4FF, ink: 0x1C3E5C, badge: 0x5E97D4)
        case "spring", "spring-meadow", "cherry", "blossom-week":
            return light(screen: 0xFFD0E4, sheet: 0xF3B0D0, cell: 0xFFE3F0, ink: 0x5A2444, badge: 0xE07AA8)
        case "rainbow-week":
            return light(screen: 0xE7D6FF, sheet: 0xD4C2F8, cell: 0xF3EAFF, ink: 0x3A2A55, badge: 0x8A6AD4)
        case "autumn", "harvest", "leaf-walk":
            return light(screen: 0xFFC27A, sheet: 0xF0A24A, cell: 0xFFD7A8, ink: 0x4A2A10, badge: 0xE07A20)
        case "newyear", "new-year-sparkle":
            return light(screen: 0xFFE7A0, sheet: 0xF0D060, cell: 0xFFF4CC, ink: 0x4A3810, badge: 0xE0A020)
        default:
            return light(screen: 0xFFE38A, sheet: 0xF6D15A, cell: 0xFFF1B8, ink: 0x4A3412, badge: 0xFF8A34)
        }
    }

    private static func light(screen: UInt32, sheet: UInt32, cell: UInt32, ink: UInt32, badge: UInt32) -> ShopFloorPaint {
        ShopFloorPaint(
            screen: Color(hex: screen),
            sheet: Color(hex: sheet),
            cell: Color(hex: cell),
            ink: Color(hex: ink),
            badge: Color(hex: badge),
            lightStatus: false
        )
    }

    private static func dark(screen: UInt32, sheet: UInt32, cell: UInt32, badge: UInt32) -> ShopFloorPaint {
        ShopFloorPaint(
            screen: Color(hex: screen),
            sheet: Color(hex: sheet),
            cell: Color(hex: cell),
            ink: .white,
            badge: Color(hex: badge),
            lightStatus: true
        )
    }
}

struct ShopGem: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let midY = rect.midY
        let width = rect.width * 0.42
        let height = rect.height * 0.48
        path.move(to: CGPoint(x: midX, y: midY - height))
        path.addLine(to: CGPoint(x: midX + width, y: midY - height * 0.15))
        path.addLine(to: CGPoint(x: midX + width * 0.62, y: midY + height))
        path.addLine(to: CGPoint(x: midX - width * 0.62, y: midY + height))
        path.addLine(to: CGPoint(x: midX - width, y: midY - height * 0.15))
        path.closeSubpath()
        return path
    }
}

/// The rainbow stone: a hexagon with a pastel left half, a cool right half and a white rim.
struct ShopStoneGlyph: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            context.translateBy(x: (size.width - s) / 2, y: (size.height - s) / 2)
            context.scaleBy(x: s / 24, y: s / 24)
            let rim: [CGPoint] = [.init(x: 12, y: 0.5), .init(x: 22.5, y: 6), .init(x: 22.5, y: 18), .init(x: 12, y: 23.5), .init(x: 1.5, y: 18), .init(x: 1.5, y: 6)]
            context.fill(poly(rim), with: .color(.white))
            let inner: [CGPoint] = [.init(x: 12, y: 3), .init(x: 20.3, y: 7.4), .init(x: 20.3, y: 16.6), .init(x: 12, y: 21), .init(x: 3.7, y: 16.6), .init(x: 3.7, y: 7.4)]
            context.fill(poly(inner), with: .linearGradient(
                Gradient(colors: [Color(hex: 0xFF9FC4), Color(hex: 0xFFE27A), Color(hex: 0x9FE7A0)]),
                startPoint: CGPoint(x: 4, y: 6), endPoint: CGPoint(x: 10, y: 20)))
            let right: [CGPoint] = [.init(x: 12, y: 3), .init(x: 20.3, y: 7.4), .init(x: 20.3, y: 16.6), .init(x: 12, y: 21), .init(x: 12, y: 12)]
            context.fill(poly(right), with: .linearGradient(
                Gradient(colors: [Color(hex: 0x7FD8FF), Color(hex: 0x6F9BFF), Color(hex: 0xB78CFF)]),
                startPoint: CGPoint(x: 14, y: 4), endPoint: CGPoint(x: 18, y: 20)))
            let top: [CGPoint] = [.init(x: 12, y: 3), .init(x: 20.3, y: 7.4), .init(x: 12, y: 12), .init(x: 3.7, y: 7.4)]
            context.fill(poly(top), with: .color(.white.opacity(0.35)))
        }
        .accessibilityHidden(true)
    }

    private func poly(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }
}

struct ShopStonePill: View {
    var count: Int
    var spoken: String

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 28)
            Text("\(count)")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x2B3B8F))
                .monospacedDigit()
                .frame(minWidth: 34)
                .padding(.trailing, 9)
        }
        .frame(height: 25)
        .background(Color.white, in: Capsule())
        .overlay(alignment: .leading) {
            ShopStoneGlyph()
                .frame(width: 34, height: 34)
                .rotationEffect(.degrees(-12))
                .offset(x: -6, y: -2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}

struct ShopSparkle: View {
    var color: Color

    var body: some View {
        Canvas { context, size in
            func star(_ c: CGPoint, _ r: CGFloat) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: c.x, y: c.y - r))
                p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: c)
                p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: c)
                p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: c)
                p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: c)
                return p
            }
            let s = size.width / 30
            context.fill(star(CGPoint(x: 13 * s, y: 17 * s), 12 * s), with: .color(color))
            context.fill(star(CGPoint(x: 24 * s, y: 6 * s), 5.5 * s), with: .color(color))
            context.fill(star(CGPoint(x: 25 * s, y: 25 * s), 4 * s), with: .color(color))
        }
        .accessibilityHidden(true)
    }
}

struct ShopRefreshMark: View {
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.12, to: 0.78)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            Circle()
                .fill(Color.white)
                .frame(width: 3.2, height: 3.2)
                .offset(x: 4.6, y: -2.4)
        }
        .frame(width: 13, height: 13)
        .accessibilityHidden(true)
    }
}

/// Yellow round button with two chasing orange arrows, as on the special collection.
struct ShopRefreshDisc: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF5B730))
            Circle().trim(from: 0.05, to: 0.4)
                .stroke(Color(hex: 0xD9761A), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 20, height: 20)
            Circle().trim(from: 0.55, to: 0.9)
                .stroke(Color(hex: 0xD9761A), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 20, height: 20)
            ShopArrowHead().fill(Color(hex: 0xD9761A)).frame(width: 8, height: 6).rotationEffect(.degrees(200)).offset(x: -8, y: 4)
            ShopArrowHead().fill(Color(hex: 0xD9761A)).frame(width: 8, height: 6).rotationEffect(.degrees(20)).offset(x: 8, y: -4)
        }
        .accessibilityHidden(true)
    }
}

struct ShopCheckMark: View {
    var ink: Color

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 2, y: 7))
            path.addLine(to: CGPoint(x: 6, y: 11))
            path.addLine(to: CGPoint(x: 13, y: 3))
        }
        .stroke(ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: 14, height: 14)
        .accessibilityHidden(true)
    }
}

struct ShopLockMark: View {
    var ink: Color

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 8, height: 8)
                .offset(y: -4)
            RoundedRectangle(cornerRadius: 2)
                .fill(ink)
                .frame(width: 12, height: 8)
                .offset(y: 3)
        }
        .frame(width: 14, height: 16)
        .accessibilityHidden(true)
    }
}

/// Folded map tucked into the first cell of the special collection.
struct ShopMapTag: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x8ED3F2))
            Path { p in
                p.addEllipse(in: CGRect(x: 6, y: 5, width: 9, height: 7))
                p.addEllipse(in: CGRect(x: 17, y: 11, width: 9, height: 8))
                p.addEllipse(in: CGRect(x: 9, y: 15, width: 6, height: 5))
            }
            .fill(Color(hex: 0x6BBF59))
            Rectangle().fill(Color.black.opacity(0.12)).frame(width: 1).offset(x: -5)
            Rectangle().fill(Color.black.opacity(0.12)).frame(width: 1).offset(x: 5)
        }
        .frame(width: 31, height: 24)
        .rotationEffect(.degrees(-6))
        .accessibilityHidden(true)
    }
}

/// Small confetti diamond around the Plus banner mascot.
struct ShopConfetti: View {
    var color: Color
    var body: some View {
        Rectangle().fill(color).frame(width: 8, height: 8).rotationEffect(.degrees(45))
            .accessibilityHidden(true)
    }
}

struct ShopCatalogIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xB33A2E)).frame(width: 20, height: 24)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xF2E3C9)).frame(width: 14, height: 17).offset(x: 1)
            Circle().stroke(Color(hex: 0x3B2A26), lineWidth: 2).frame(width: 8, height: 8).offset(x: 1, y: -1)
            Capsule().fill(Color(hex: 0x3B2A26)).frame(width: 2.2, height: 6).rotationEffect(.degrees(-45)).offset(x: 5.5, y: 4.5)
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }
}

struct ShopSellIcon: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xC9D5DC)).frame(width: 22, height: 20).offset(y: 3)
            Capsule().fill(Color(hex: 0xC9D5DC)).frame(width: 12, height: 6).offset(y: -9)
            Capsule().fill(Color(hex: 0xE88F3A)).frame(width: 12, height: 3).offset(y: -6)
            ShopStoneGlyph().frame(width: 12, height: 12).offset(y: 4)
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }
}

private struct ShopArrowHead: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
