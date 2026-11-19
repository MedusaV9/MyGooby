import SwiftUI

struct MarkPart {
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat
    var hex: UInt32
    var turn: Double = 0
    var shape: Int = 0
    var eye: Bool = false
}

enum MicropetRecipes {
    static func parts(for id: String) -> [MarkPart] {
        switch id {
        case "chick": return chick
        case "cloud": return cloud
        case "dragon": return dragon
        case "fox": return fox
        case "penguin": return penguin
        case "bear": return bear
        case "cat": return cat
        case "ghost": return ghost
        case "unicorn": return unicorn
        case "mushroom": return mushroom
        case "sprout": return sprout
        case "lantern": return lantern
        case "pebble": return pebble
        case "kite": return kite
        case "teacup": return teacup
        case "comet": return comet
        default: return pebble
        }
    }

    private static let chick: [MarkPart] = [
        MarkPart(x: 0, y: 10, w: 48, h: 40, hex: 0xF6D56A),
        MarkPart(x: 0, y: -16, w: 34, h: 32, hex: 0xF8DC78),
        MarkPart(x: 18, y: -12, w: 14, h: 10, hex: 0xE09040, turn: 90, shape: 3),
        MarkPart(x: -7, y: -18, w: 5, h: 5, hex: 0x3A2416, eye: true),
        MarkPart(x: 7, y: -18, w: 5, h: 5, hex: 0x3A2416, eye: true),
        MarkPart(x: -10, y: 28, w: 14, h: 7, hex: 0xE09040),
        MarkPart(x: 10, y: 28, w: 14, h: 7, hex: 0xE09040)
    ]

    private static let cloud: [MarkPart] = [
        MarkPart(x: -14, y: 6, w: 28, h: 28, hex: 0xF7FBFF),
        MarkPart(x: 4, y: -2, w: 36, h: 36, hex: 0xF7FBFF),
        MarkPart(x: 18, y: 8, w: 24, h: 24, hex: 0xF7FBFF),
        MarkPart(x: -4, y: 2, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 8, y: 2, w: 4, h: 4, hex: 0x3A2416, eye: true)
    ]

    private static let dragon: [MarkPart] = [
        MarkPart(x: -22, y: 14, w: 28, h: 14, hex: 0x7FCBB0, turn: -24),
        MarkPart(x: 2, y: 12, w: 46, h: 34, hex: 0x8FCBB0),
        MarkPart(x: 8, y: -12, w: 28, h: 26, hex: 0x8FCBB0),
        MarkPart(x: -2, y: -28, w: 8, h: 16, hex: 0x6BB89A, turn: -16, shape: 1),
        MarkPart(x: 12, y: -30, w: 8, h: 18, hex: 0x6BB89A, turn: 18, shape: 1),
        MarkPart(x: 22, y: -4, w: 18, h: 12, hex: 0x8FCBB0),
        MarkPart(x: 2, y: -12, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 12, y: -12, w: 4, h: 4, hex: 0x3A2416, eye: true)
    ]

    private static let fox: [MarkPart] = [
        MarkPart(x: -24, y: 16, w: 30, h: 16, hex: 0xF09A4A, turn: -28),
        MarkPart(x: 0, y: 12, w: 44, h: 34, hex: 0xF09A4A),
        MarkPart(x: 6, y: -10, w: 30, h: 28, hex: 0xF09A4A),
        MarkPart(x: -6, y: -26, w: 14, h: 18, hex: 0xF09A4A, shape: 3),
        MarkPart(x: 16, y: -28, w: 14, h: 20, hex: 0xF09A4A, shape: 3),
        MarkPart(x: 8, y: 0, w: 18, h: 12, hex: 0xFFF6EA),
        MarkPart(x: 0, y: -12, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 12, y: -12, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 20, y: -2, w: 6, h: 4, hex: 0x3A2416, eye: true)
    ]

    private static let penguin: [MarkPart] = [
        MarkPart(x: 0, y: 8, w: 40, h: 46, hex: 0x3E4A5A),
        MarkPart(x: 0, y: 12, w: 22, h: 28, hex: 0xFFF6EA),
        MarkPart(x: 0, y: -18, w: 24, h: 22, hex: 0x3E4A5A),
        MarkPart(x: 14, y: -16, w: 12, h: 8, hex: 0xF09A4A, turn: 90, shape: 3),
        MarkPart(x: -6, y: -18, w: 4, h: 4, hex: 0xFFF6EA, eye: true),
        MarkPart(x: 4, y: -18, w: 4, h: 4, hex: 0xFFF6EA, eye: true),
        MarkPart(x: -10, y: 30, w: 14, h: 7, hex: 0xF09A4A),
        MarkPart(x: 10, y: 30, w: 14, h: 7, hex: 0xF09A4A)
    ]

    private static let bear: [MarkPart] = [
        MarkPart(x: -16, y: -22, w: 16, h: 16, hex: 0xC9956A),
        MarkPart(x: 16, y: -22, w: 16, h: 16, hex: 0xC9956A),
        MarkPart(x: 0, y: 2, w: 48, h: 46, hex: 0xE7C4A8),
        MarkPart(x: 0, y: 10, w: 20, h: 14, hex: 0xFFD0DC),
        MarkPart(x: -8, y: -4, w: 5, h: 5, hex: 0x3A2416, eye: true),
        MarkPart(x: 8, y: -4, w: 5, h: 5, hex: 0x3A2416, eye: true),
        MarkPart(x: 0, y: 8, w: 6, h: 4, hex: 0x3A2416, eye: true)
    ]

    private static let cat: [MarkPart] = [
        MarkPart(x: -26, y: 4, w: 22, h: 8, hex: 0xF4E4D4, turn: 30, shape: 1),
        MarkPart(x: 0, y: 12, w: 46, h: 32, hex: 0xF4E4D4),
        MarkPart(x: 8, y: -8, w: 28, h: 26, hex: 0xF4E4D4),
        MarkPart(x: 0, y: -22, w: 10, h: 12, hex: 0xF4E4D4, shape: 3),
        MarkPart(x: 14, y: -22, w: 10, h: 12, hex: 0xF4E4D4, shape: 3),
        MarkPart(x: 4, y: -8, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 14, y: -8, w: 4, h: 4, hex: 0x3A2416, eye: true)
    ]

    private static let ghost: [MarkPart] = [
        MarkPart(x: -14, y: 22, w: 16, h: 16, hex: 0xE4D8C4),
        MarkPart(x: 2, y: 24, w: 16, h: 16, hex: 0xE4D8C4),
        MarkPart(x: 16, y: 22, w: 16, h: 16, hex: 0xE4D8C4),
        MarkPart(x: 0, y: -4, w: 44, h: 40, hex: 0xE4D8C4, shape: 2),
        MarkPart(x: -8, y: -8, w: 6, h: 8, hex: 0x3A2416, eye: true),
        MarkPart(x: 8, y: -8, w: 6, h: 8, hex: 0x3A2416, eye: true)
    ]

    private static let unicorn: [MarkPart] = [
        MarkPart(x: 16, y: -6, w: 16, h: 22, hex: 0xFFD6E7, turn: 18),
        MarkPart(x: 0, y: 4, w: 42, h: 40, hex: 0xF7F4EF),
        MarkPart(x: 0, y: -28, w: 8, h: 22, hex: 0xD3C2FF, shape: 1),
        MarkPart(x: -6, y: 0, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 8, y: 0, w: 4, h: 4, hex: 0x3A2416, eye: true)
    ]

    private static let mushroom: [MarkPart] = [
        MarkPart(x: 0, y: 16, w: 16, h: 28, hex: 0xFFF1E4, shape: 1),
        MarkPart(x: 0, y: -8, w: 52, h: 30, hex: 0xF3A0B5),
        MarkPart(x: -10, y: -10, w: 8, h: 8, hex: 0xFFF6EA),
        MarkPart(x: 8, y: -14, w: 6, h: 6, hex: 0xFFF6EA),
        MarkPart(x: -4, y: -6, w: 3, h: 3, hex: 0x3A2416, eye: true),
        MarkPart(x: 6, y: -6, w: 3, h: 3, hex: 0x3A2416, eye: true)
    ]

    private static let sprout: [MarkPart] = [
        MarkPart(x: 0, y: 16, w: 6, h: 28, hex: 0x7EC8A4, shape: 1),
        MarkPart(x: -14, y: 6, w: 22, h: 10, hex: 0x7EC8A4, turn: -36),
        MarkPart(x: 14, y: 8, w: 22, h: 10, hex: 0x7EC8A4, turn: 34),
        MarkPart(x: 0, y: -16, w: 16, h: 18, hex: 0x8FD8B4),
        MarkPart(x: -2, y: -14, w: 3, h: 3, hex: 0x3A2416, eye: true),
        MarkPart(x: 4, y: -14, w: 3, h: 3, hex: 0x3A2416, eye: true)
    ]

    private static let lantern: [MarkPart] = [
        MarkPart(x: 0, y: 4, w: 32, h: 40, hex: 0xFFE08A, shape: 2),
        MarkPart(x: 0, y: -20, w: 22, h: 8, hex: 0xC9956A, shape: 1),
        MarkPart(x: 0, y: -28, w: 8, h: 10, hex: 0xC9956A, shape: 1),
        MarkPart(x: 0, y: 26, w: 8, h: 10, hex: 0xC9956A, shape: 1),
        MarkPart(x: -6, y: 2, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 6, y: 2, w: 4, h: 4, hex: 0x3A2416, eye: true)
    ]

    private static let pebble: [MarkPart] = [
        MarkPart(x: 0, y: 4, w: 52, h: 38, hex: 0xD7CBBA),
        MarkPart(x: -8, y: 0, w: 5, h: 5, hex: 0x3A2416, eye: true),
        MarkPart(x: 8, y: 0, w: 5, h: 5, hex: 0x3A2416, eye: true)
    ]

    private static let kite: [MarkPart] = [
        MarkPart(x: 0, y: -4, w: 36, h: 36, hex: 0xF3A0B5, turn: 45, shape: 2),
        MarkPart(x: 0, y: 28, w: 3, h: 18, hex: 0xC9956A, shape: 1),
        MarkPart(x: -6, y: -6, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 6, y: -6, w: 4, h: 4, hex: 0x3A2416, eye: true)
    ]

    private static let teacup: [MarkPart] = [
        MarkPart(x: 0, y: 8, w: 40, h: 26, hex: 0xF7C9D8, shape: 2),
        MarkPart(x: 0, y: -8, w: 36, h: 10, hex: 0xFFF6EA, shape: 2),
        MarkPart(x: 24, y: 8, w: 12, h: 16, hex: 0xE7A0B8),
        MarkPart(x: 24, y: 8, w: 6, h: 8, hex: 0xFFF8EF),
        MarkPart(x: -6, y: 6, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 6, y: 6, w: 4, h: 4, hex: 0x3A2416, eye: true)
    ]

    private static let comet: [MarkPart] = [
        MarkPart(x: -10, y: 8, w: 40, h: 14, hex: 0xD3C2FF, turn: -32, shape: 1),
        MarkPart(x: 12, y: -10, w: 26, h: 26, hex: 0xFFE08A),
        MarkPart(x: 8, y: -12, w: 4, h: 4, hex: 0x3A2416, eye: true),
        MarkPart(x: 16, y: -12, w: 4, h: 4, hex: 0x3A2416, eye: true)
    ]
}

struct MicropetMark: View {
    var id: String
    var ink: Color?

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    let scale = side / 100
                    let parts = MicropetRecipes.parts(for: id).filter { ink == nil || !$0.eye }
                    ZStack {
                        if id == "moon" {
                            moon(scale)
                        } else if id == "starling" {
                            star(scale)
                        } else {
                            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                                piece(part, scale: scale)
                            }
                        }
                    }
                    .frame(width: side, height: side)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .accessibilityHidden(true)
    }

    private func piece(_ part: MarkPart, scale: CGFloat) -> some View {
        let fill = ink ?? Color(hex: part.hex)
        return Group {
            switch part.shape {
            case 1:
                Capsule().fill(fill)
            case 2:
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(fill)
            case 3:
                MicropetTriangle().fill(fill)
            default:
                Ellipse().fill(fill)
            }
        }
        .frame(width: part.w * scale, height: part.h * scale)
        .rotationEffect(.degrees(part.turn))
        .offset(x: part.x * scale, y: part.y * scale)
    }

    private func moon(_ scale: CGFloat) -> some View {
        let fill = ink ?? Color(hex: 0xFFE7A0)
        return ZStack {
            MicropetMoon().fill(fill, style: FillStyle(eoFill: true))
                .frame(width: 52 * scale, height: 52 * scale)
            if ink == nil {
                Circle().fill(Color(hex: 0x3A2416)).frame(width: 4 * scale, height: 4 * scale).offset(x: -6 * scale, y: -2 * scale)
            }
        }
    }

    private func star(_ scale: CGFloat) -> some View {
        let fill = ink ?? Color(hex: 0xFFE08A)
        return ZStack {
            MicropetStar().fill(fill).frame(width: 58 * scale, height: 58 * scale)
            if ink == nil {
                Circle().fill(Color(hex: 0x3A2416)).frame(width: 4 * scale, height: 4 * scale).offset(x: -6 * scale, y: 2 * scale)
                Circle().fill(Color(hex: 0x3A2416)).frame(width: 4 * scale, height: 4 * scale).offset(x: 6 * scale, y: 2 * scale)
            }
        }
    }
}

struct MicropetEgg: View {
    var fraction: CGFloat
    var ready: Bool

    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xF7E7C8))
            Ellipse().stroke(Color(hex: 0xE7C99A), lineWidth: 2)
            Circle().fill(Color(hex: 0xF3C1D0)).frame(width: 8, height: 8).offset(x: -8, y: -6)
            Circle().fill(Color(hex: 0xF6D78A)).frame(width: 6, height: 6).offset(x: 10, y: 4)
            if fraction > 0.45 {
                Capsule().fill(Color(hex: 0xC9956A)).frame(width: 2, height: 16).rotationEffect(.degrees(-18)).offset(y: -6)
            }
            if ready {
                Capsule().fill(Color(hex: 0xC9956A)).frame(width: 2, height: 12).rotationEffect(.degrees(22)).offset(x: 6, y: 0)
            }
        }
        .accessibilityHidden(true)
    }
}

struct MicropetMoon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        let cut = rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.12)
            .offsetBy(dx: rect.width * 0.28, dy: -rect.height * 0.04)
        path.addEllipse(in: cut)
        return path
    }
}

struct MicropetStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<10 {
            let angle = CGFloat(index) * .pi / 5 - .pi / 2
            let length = index.isMultiple(of: 2) ? radius : radius * 0.42
            let point = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct MicropetTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
