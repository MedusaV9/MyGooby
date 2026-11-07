import SwiftUI

// The 12 mini-friends (masterprompt 17) as small original plush creatures in Gooby's style:
// round bodies, soft elliptical shading, a warm outline, glossy black eyes and pink cheeks.
// Every creature is drawn in a 100 x 100 design box (origin in the center, y down) and scaled to
// the frame it gets. Species ids come from content-shell.json ("friends").

/// A mini-friend that bobs gently. Pass `animated: false` (or turn on Reduce Motion) for a still.
struct MiniFriendBadge: View {
    var species: String
    var animated: Bool = true
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    var body: some View {
        Group {
            if animated && !systemReduce {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    MiniFriendArt(species: species, time: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                MiniFriendArt(species: species)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(species)
    }
}

/// The same creature as one flat `color` shape, for locked collection tiles.
struct MiniFriendSilhouette: View {
    var species: String
    var color: Color

    var body: some View {
        color
            .mask { MiniFriendArt(species: species) }
            .accessibilityHidden(true)
    }
}

/// Still (time == nil) or moving drawing of one mini-friend, scaled to fit its frame.
struct MiniFriendArt: View {
    var species: String
    var time: Double?

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let t = time ?? 0
            let moving = time != nil
            let bob: CGFloat = moving ? CGFloat(sin(t * 2.2)) * 2.5 : 0
            let breathe: CGFloat = moving ? 1 + 0.025 * CGFloat(sin(t * 4.4)) : 1
            let phase = Double(species.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 10) * 0.37
            let blink = moving && (t + phase).truncatingRemainder(dividingBy: 3.6) > 3.45
            MiniFriendFigure(species: species, blink: blink)
                .frame(width: 100, height: 100)
                .scaleEffect(x: 2 - breathe, y: breathe, anchor: .bottom)
                .offset(y: bob)
                .scaleEffect(side / 100)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Plush shading for one part of a mini-friend.
struct MiniFriendPaint {
    var light: Color
    var base: Color
    var shade: Color
    var line: Color

    var fill: EllipticalGradient {
        EllipticalGradient(
            stops: [.init(color: light, location: 0), .init(color: base, location: 0.45), .init(color: shade, location: 1)],
            center: UnitPoint(x: 0.38, y: 0.3),
            startRadiusFraction: 0,
            endRadiusFraction: 0.8
        )
    }

    init(_ light: UInt32, _ base: UInt32, _ shade: UInt32, _ line: UInt32) {
        self.light = Color(hex: light)
        self.base = Color(hex: base)
        self.shade = Color(hex: shade)
        self.line = Color(hex: line)
    }
}

extension Shape {
    /// Fills a mini-friend part with its plush gradient and outline.
    func miniFriendPaint(_ paint: MiniFriendPaint, line: CGFloat = 2) -> some View {
        fill(paint.fill).overlay(stroke(paint.line, lineWidth: line))
    }
}

/// Eyes, cheeks and a tiny smile.
struct MiniFriendFace: View {
    var y: CGFloat = 0
    var gap: CGFloat = 24
    var eye: CGFloat = 9
    var blink: Bool = false
    var sleepy: Bool = false
    var mouth: Bool = true
    var blush = Color(hex: 0xFF9DB6)

    private var ink: Color { Color(hex: 0x2A2130) }

    var body: some View {
        ZStack {
            eyeView.offset(x: -gap / 2, y: y)
            eyeView.offset(x: gap / 2, y: y)
            Ellipse().fill(blush.opacity(0.7)).goobyAt(-(gap / 2 + eye * 0.95), y + eye * 0.95, eye * 1.35, eye * 0.8)
            Ellipse().fill(blush.opacity(0.7)).goobyAt(gap / 2 + eye * 0.95, y + eye * 0.95, eye * 1.35, eye * 0.8)
            if mouth {
                GoobyClosedEyeShape()
                    .stroke(ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .goobyAt(0, y + eye * 0.85, eye * 0.7, eye * 0.32)
            }
        }
    }

    @ViewBuilder private var eyeView: some View {
        if sleepy || blink {
            GoobyClosedEyeShape()
                .stroke(ink, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .frame(width: eye * 1.1, height: eye * 0.4)
                .offset(y: eye * 0.1)
        } else {
            ZStack {
                Ellipse().fill(ink)
                Circle().fill(Color.white).frame(width: eye * 0.42, height: eye * 0.42).offset(x: -eye * 0.16, y: -eye * 0.2)
                Circle().fill(Color.white.opacity(0.9)).frame(width: eye * 0.18, height: eye * 0.18).offset(x: eye * 0.2, y: eye * 0.2)
            }
            .frame(width: eye, height: eye * 1.12)
        }
    }
}

struct MiniFriendFigure: View {
    var species: String
    var blink: Bool = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(EllipticalGradient(colors: [Color(hex: 0x3D3656).opacity(0.2), Color(hex: 0x3D3656).opacity(0)], center: .center, endRadiusFraction: 0.5))
                .goobyAt(0, 45, 64, 10)
            creature
        }
        .frame(width: 100, height: 100)
    }

    @ViewBuilder private var creature: some View {
        switch species {
        case "chick": chick
        case "cloud": cloud
        case "dragon": dragon
        case "fox": fox
        case "starling": starling
        case "penguin": penguin
        case "bear": bear
        case "cat": cat
        case "ghost": ghost
        case "unicorn": unicorn
        case "moon": moon
        case "mushroom": mushroom
        default: mochi
        }
    }

    // MARK: Creatures

    private var chick: some View {
        let skin = MiniFriendPaint(0xFFF6C8, 0xFFE070, 0xF5BE3A, 0xD9A030)
        let orange = MiniFriendPaint(0xFFC27A, 0xFF9F43, 0xE9822A, 0xC86A1E)
        return ZStack {
            Ellipse().miniFriendPaint(orange, line: 1.5).goobyAt(-11, 42, 15, 8)
            Ellipse().miniFriendPaint(orange, line: 1.5).goobyAt(11, 42, 15, 8)
            Ellipse().miniFriendPaint(skin).frame(width: 16, height: 22).rotationEffect(.degrees(25)).offset(x: -34, y: 12)
            Ellipse().miniFriendPaint(skin).frame(width: 16, height: 22).rotationEffect(.degrees(-25)).offset(x: 34, y: 12)
            Ellipse().miniFriendPaint(skin).frame(width: 7, height: 15).rotationEffect(.degrees(-28)).offset(x: -5, y: -30)
            Ellipse().miniFriendPaint(skin).frame(width: 7, height: 16).offset(x: 0, y: -32)
            Ellipse().miniFriendPaint(skin).goobyAt(0, 6, 72, 70)
            MiniFriendFace(y: 0, gap: 26, eye: 10, blink: blink, mouth: false)
            Triangle().miniFriendPaint(orange, line: 1.5).frame(width: 13, height: 10).rotationEffect(.degrees(180)).offset(y: 10)
        }
    }

    private var cloud: some View {
        let puff = MiniFriendPaint(0xFFFFFF, 0xFFFFFF, 0xD7E5F7, 0xB4C8E4)
        return ZStack {
            MiniFriendCloudShape().miniFriendPaint(puff).goobyAt(0, 8, 84, 64)
            MiniFriendFace(y: 12, gap: 22, eye: 9, blink: blink)
            Capsule().fill(Color(hex: 0x9FD3F5)).goobyAt(-20, 48, 4, 9)
            Capsule().fill(Color(hex: 0x9FD3F5)).goobyAt(18, 50, 4, 9)
        }
    }

    private var dragon: some View {
        let skin = MiniFriendPaint(0xE2F9EA, 0x9EE3B8, 0x6CC892, 0x4FA874)
        let wing = MiniFriendPaint(0xEDE6FF, 0xC8B6FF, 0xA690EE, 0x8C74D6)
        let horn = MiniFriendPaint(0xFFF8E6, 0xFFE9B8, 0xF2CF84, 0xD6AE5E)
        return ZStack {
            Triangle().miniFriendPaint(wing).frame(width: 24, height: 24).rotationEffect(.degrees(-50)).offset(x: -34, y: -4)
            Triangle().miniFriendPaint(wing).frame(width: 24, height: 24).rotationEffect(.degrees(50)).offset(x: 34, y: -4)
            Ellipse().miniFriendPaint(skin).frame(width: 28, height: 12).rotationEffect(.degrees(-30)).offset(x: 34, y: 30)
            Capsule().miniFriendPaint(horn, line: 1.5).frame(width: 7, height: 15).rotationEffect(.degrees(-20)).offset(x: -14, y: -32)
            Capsule().miniFriendPaint(horn, line: 1.5).frame(width: 7, height: 15).rotationEffect(.degrees(20)).offset(x: 14, y: -32)
            Ellipse().miniFriendPaint(skin).goobyAt(0, 6, 70, 72)
            Ellipse().fill(Color(hex: 0xF3FBD8)).goobyAt(0, 22, 40, 32)
            MiniFriendFace(y: -2, gap: 26, eye: 10, blink: blink)
            Circle().fill(Color(hex: 0x4FA874)).goobyAt(-3, 9, 2.5, 2.5)
            Circle().fill(Color(hex: 0x4FA874)).goobyAt(3, 9, 2.5, 2.5)
        }
    }

    private var fox: some View {
        let skin = MiniFriendPaint(0xFFD2A8, 0xFFA25C, 0xF07F3A, 0xD06A2C)
        let white = MiniFriendPaint(0xFFFFFF, 0xFFF8F0, 0xF3E3D3, 0xE0C7AE)
        return ZStack {
            Ellipse().miniFriendPaint(skin).frame(width: 26, height: 44).rotationEffect(.degrees(40)).offset(x: 32, y: 20)
            Ellipse().miniFriendPaint(white, line: 1.5).frame(width: 14, height: 14).offset(x: 45, y: 6)
            ear(skin, inner: Color(hex: 0x5A3A2E), x: -20, tilt: -12)
            ear(skin, inner: Color(hex: 0x5A3A2E), x: 20, tilt: 12)
            Ellipse().miniFriendPaint(skin).goobyAt(0, 6, 72, 66)
            Ellipse().miniFriendPaint(white, line: 1.5).goobyAt(0, 20, 48, 28)
            MiniFriendFace(y: 0, gap: 26, eye: 9, blink: blink, mouth: false)
            Ellipse().fill(Color(hex: 0x2A2130)).goobyAt(0, 12, 7, 5)
        }
    }

    private var starling: some View {
        let skin = MiniFriendPaint(0xFFF4C2, 0xFFDA5E, 0xF4B92E, 0xD9982A)
        return ZStack {
            MiniFriendSparkle(color: Color(hex: 0xFFD34E)).goobyAt(-38, -30, 12, 12)
            MiniFriendSparkle(color: Color(hex: 0xFFB3CF)).goobyAt(38, -36, 10, 10)
            Star(points: 5, inner: 0.56)
                .stroke(skin.line, style: StrokeStyle(lineWidth: 12, lineJoin: .round))
                .goobyAt(0, 4, 78, 78)
            Star(points: 5, inner: 0.56)
                .stroke(skin.base, style: StrokeStyle(lineWidth: 8, lineJoin: .round))
                .goobyAt(0, 4, 78, 78)
            Star(points: 5, inner: 0.56).fill(skin.fill).goobyAt(0, 4, 78, 78)
            MiniFriendFace(y: 8, gap: 18, eye: 8, blink: blink)
        }
    }

    private var penguin: some View {
        let skin = MiniFriendPaint(0x7280A6, 0x4A5578, 0x2F3757, 0x262D47)
        let belly = MiniFriendPaint(0xFFFFFF, 0xFFFFFF, 0xE6EAF2, 0xCED5E3)
        let orange = MiniFriendPaint(0xFFC27A, 0xFF9F43, 0xE9822A, 0xC86A1E)
        return ZStack {
            Ellipse().miniFriendPaint(orange, line: 1.5).goobyAt(-12, 42, 17, 8)
            Ellipse().miniFriendPaint(orange, line: 1.5).goobyAt(12, 42, 17, 8)
            Ellipse().miniFriendPaint(skin).frame(width: 12, height: 28).rotationEffect(.degrees(20)).offset(x: -33, y: 10)
            Ellipse().miniFriendPaint(skin).frame(width: 12, height: 28).rotationEffect(.degrees(-20)).offset(x: 33, y: 10)
            Ellipse().miniFriendPaint(skin).goobyAt(0, 3, 66, 80)
            GoobyHeartShape().miniFriendPaint(belly, line: 1.5).goobyAt(0, 10, 50, 56)
            MiniFriendFace(y: 2, gap: 20, eye: 8, blink: blink, mouth: false)
            Triangle().miniFriendPaint(orange, line: 1.5).frame(width: 11, height: 8).rotationEffect(.degrees(180)).offset(y: 10)
        }
    }

    private var bear: some View {
        let skin = MiniFriendPaint(0xE8C4A0, 0xC99368, 0xA9744C, 0x8E5E3C)
        let muzzle = MiniFriendPaint(0xFFF6EA, 0xF6E2C8, 0xE8CBA8, 0xD2AF8A)
        return ZStack {
            Circle().miniFriendPaint(skin).goobyAt(-24, -24, 22, 22)
            Circle().fill(Color(hex: 0xF4B6B6)).goobyAt(-24, -24, 11, 11)
            Circle().miniFriendPaint(skin).goobyAt(24, -24, 22, 22)
            Circle().fill(Color(hex: 0xF4B6B6)).goobyAt(24, -24, 11, 11)
            Ellipse().miniFriendPaint(skin).goobyAt(0, 6, 74, 68)
            Ellipse().miniFriendPaint(muzzle, line: 1.5).goobyAt(0, 17, 30, 22)
            MiniFriendFace(y: 0, gap: 30, eye: 9, blink: blink, mouth: false)
            Ellipse().fill(Color(hex: 0x4A3226)).goobyAt(0, 12, 9, 6)
            GoobyClosedEyeShape().stroke(Color(hex: 0x4A3226), style: StrokeStyle(lineWidth: 1.8, lineCap: .round)).goobyAt(0, 19, 8, 3)
        }
    }

    private var cat: some View {
        let skin = MiniFriendPaint(0xFFFBF6, 0xF2E6DA, 0xDCC8B6, 0xBFA894)
        let ginger = MiniFriendPaint(0xFFD3A8, 0xF4B27A, 0xE09456, 0xC47A40)
        return ZStack {
            Capsule().miniFriendPaint(ginger).frame(width: 11, height: 38).rotationEffect(.degrees(32)).offset(x: 33, y: 20)
            ear(skin, inner: Color(hex: 0xFFB7CC), x: -21, tilt: -10)
            ear(ginger, inner: Color(hex: 0xFFB7CC), x: 21, tilt: 10)
            Ellipse().miniFriendPaint(skin).goobyAt(0, 6, 72, 66)
            Ellipse().fill(ginger.base).goobyAt(14, -10, 18, 12)
            MiniFriendFace(y: 2, gap: 26, eye: 9, blink: blink, mouth: false)
            Triangle().fill(Color(hex: 0xFF9DB6)).frame(width: 7, height: 5).rotationEffect(.degrees(180)).offset(y: 11)
            whiskers
        }
    }

    private var whiskers: some View {
        let ink = Color(hex: 0xBFA894)
        return ZStack {
            Capsule().fill(ink).frame(width: 12, height: 1.5).rotationEffect(.degrees(8)).offset(x: -30, y: 12)
            Capsule().fill(ink).frame(width: 12, height: 1.5).rotationEffect(.degrees(-6)).offset(x: -30, y: 17)
            Capsule().fill(ink).frame(width: 12, height: 1.5).rotationEffect(.degrees(-8)).offset(x: 30, y: 12)
            Capsule().fill(ink).frame(width: 12, height: 1.5).rotationEffect(.degrees(6)).offset(x: 30, y: 17)
        }
    }

    private var ghost: some View {
        let skin = MiniFriendPaint(0xFFFFFF, 0xFFFFFF, 0xE2DCF5, 0xC4BAE6)
        return ZStack {
            Ellipse().miniFriendPaint(skin).frame(width: 12, height: 17).rotationEffect(.degrees(30)).offset(x: -33, y: 10)
            Ellipse().miniFriendPaint(skin).frame(width: 12, height: 17).rotationEffect(.degrees(-30)).offset(x: 33, y: 10)
            MiniFriendGhostShape().miniFriendPaint(skin).goobyAt(0, 2, 64, 78)
            MiniFriendFace(y: -2, gap: 20, eye: 9, blink: blink, mouth: false, blush: Color(hex: 0xFFB0CC))
            Ellipse().fill(Color(hex: 0x2A2130)).goobyAt(0, 10, 6, 7)
        }
        .opacity(0.96)
    }

    private var unicorn: some View {
        let skin = MiniFriendPaint(0xFFFFFF, 0xFFFFFF, 0xE9E1F2, 0xC9BEDD)
        let horn = MiniFriendPaint(0xFFF2C2, 0xFFD66B, 0xEDB642, 0xCF9A2C)
        return ZStack {
            Circle().miniFriendPaint(MiniFriendPaint(0xFFD6E7, 0xFFB3D1, 0xF08DB5, 0xD9709B)).goobyAt(-17, -23, 24, 24)
            Circle().miniFriendPaint(MiniFriendPaint(0xE9E0FF, 0xC9B6FF, 0xA891F0, 0x8F78D8)).goobyAt(0, -29, 24, 24)
            Circle().miniFriendPaint(MiniFriendPaint(0xD8F7EA, 0xA8E8CF, 0x7FD3B2, 0x5DBA96)).goobyAt(17, -23, 24, 24)
            ear(skin, inner: Color(hex: 0xFFC2D6), x: -24, tilt: -14)
            ear(skin, inner: Color(hex: 0xFFC2D6), x: 24, tilt: 14)
            Ellipse().miniFriendPaint(skin).goobyAt(0, 6, 70, 66)
            Ellipse().fill(Color(hex: 0xFFB3D1)).frame(width: 18, height: 10).rotationEffect(.degrees(-20)).offset(x: -10, y: -21)
            Triangle().miniFriendPaint(horn, line: 1.5).goobyAt(0, -38, 12, 22)
            Capsule().fill(Color.white.opacity(0.75)).frame(width: 8, height: 2).rotationEffect(.degrees(-20)).offset(y: -38)
            MiniFriendFace(y: 2, gap: 26, eye: 9, blink: blink, blush: Color(hex: 0xFFA6C8))
        }
    }

    private var moon: some View {
        let skin = MiniFriendPaint(0xFFFBE6, 0xFFF1B0, 0xF2D677, 0xD9B95A)
        return ZStack {
            MiniFriendSparkle(color: Color(hex: 0xFFD34E)).goobyAt(32, -36, 14, 14)
            Circle().miniFriendPaint(skin).goobyAt(0, 4, 74, 74)
            Ellipse().fill(Color(hex: 0xF2D677).opacity(0.7)).goobyAt(-18, 24, 11, 7)
            Ellipse().fill(Color(hex: 0xF2D677).opacity(0.7)).goobyAt(20, -16, 9, 6)
            Ellipse().fill(Color(hex: 0xF2D677).opacity(0.7)).goobyAt(-20, -18, 7, 5)
            MiniFriendFace(y: 4, gap: 24, eye: 9, sleepy: true)
        }
    }

    private var mushroom: some View {
        let cap = MiniFriendPaint(0xFF9C9A, 0xF2696B, 0xD24E52, 0xB23D42)
        let stem = MiniFriendPaint(0xFFFBF3, 0xFFF1DC, 0xF0D8B8, 0xD6B994)
        return ZStack {
            Ellipse().miniFriendPaint(stem, line: 1.5).goobyAt(-10, 44, 14, 8)
            Ellipse().miniFriendPaint(stem, line: 1.5).goobyAt(10, 44, 14, 8)
            RoundedRectangle(cornerRadius: 18, style: .continuous).miniFriendPaint(stem).goobyAt(0, 21, 52, 46)
            MiniFriendCapShape().miniFriendPaint(cap).goobyAt(0, -13, 86, 52)
            Circle().fill(Color.white).goobyAt(-23, -18, 13, 13)
            Circle().fill(Color.white).goobyAt(6, -28, 11, 11)
            Circle().fill(Color.white).goobyAt(26, -12, 9, 9)
            Circle().fill(Color.white).goobyAt(-4, -9, 7, 7)
            MiniFriendFace(y: 22, gap: 18, eye: 8, blink: blink)
        }
    }

    /// Fallback for an unknown species: a pink mochi.
    private var mochi: some View {
        let skin = MiniFriendPaint(0xFFE3EE, 0xF6C3D7, 0xE6A0BD, 0xCF84A4)
        return ZStack {
            GoobyBlobShape(widest: 0.62).miniFriendPaint(skin).goobyAt(0, 8, 74, 62)
            MiniFriendFace(y: 8, gap: 24, eye: 9, blink: blink)
        }
    }

    private func ear(_ paint: MiniFriendPaint, inner: Color, x: CGFloat, tilt: Double) -> some View {
        ZStack {
            Triangle().miniFriendPaint(paint)
            Triangle().fill(inner).frame(width: 10, height: 12).offset(y: 3)
        }
        .frame(width: 20, height: 24)
        .rotationEffect(.degrees(tilt))
        .offset(x: x, y: -27)
    }
}

// MARK: - Shapes

/// Puffy cloud merged from overlapping circles (one outline, no inner seams).
struct MiniFriendCloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath {
            CGPath(ellipseIn: CGRect(x: rect.minX + (cx - r) * w, y: rect.minY + (cy - r) * h, width: 2 * r * w, height: 2 * r * h), transform: nil)
        }
        let base = CGPath(roundedRect: CGRect(x: rect.minX + 0.08 * w, y: rect.minY + 0.5 * h, width: 0.84 * w, height: 0.5 * h), cornerWidth: 0.2 * w, cornerHeight: 0.24 * h, transform: nil)
        let merged = base
            .union(circle(0.27, 0.56, 0.24))
            .union(circle(0.52, 0.38, 0.34))
            .union(circle(0.76, 0.56, 0.24))
        return Path(merged)
    }
}

/// Ghost: round dome with a wavy hem.
struct MiniFriendGhostShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + h * 0.45))
        path.addCurve(to: CGPoint(x: x + w / 2, y: y), control1: CGPoint(x: x, y: y + h * 0.2), control2: CGPoint(x: x + w * 0.22, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: y + h * 0.45), control1: CGPoint(x: x + w * 0.78, y: y), control2: CGPoint(x: x + w, y: y + h * 0.2))
        path.addLine(to: CGPoint(x: x + w, y: y + h * 0.88))
        path.addQuadCurve(to: CGPoint(x: x + w * 0.75, y: y + h * 0.88), control: CGPoint(x: x + w * 0.875, y: y + h * 1.04))
        path.addQuadCurve(to: CGPoint(x: x + w * 0.5, y: y + h * 0.88), control: CGPoint(x: x + w * 0.625, y: y + h * 0.74))
        path.addQuadCurve(to: CGPoint(x: x + w * 0.25, y: y + h * 0.88), control: CGPoint(x: x + w * 0.375, y: y + h * 1.04))
        path.addQuadCurve(to: CGPoint(x: x, y: y + h * 0.88), control: CGPoint(x: x + w * 0.125, y: y + h * 0.74))
        path.closeSubpath()
        return path
    }
}

/// Mushroom cap: a dome with a softly curved underside.
struct MiniFriendCapShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + h * 0.82))
        path.addCurve(to: CGPoint(x: x + w / 2, y: y), control1: CGPoint(x: x, y: y + h * 0.3), control2: CGPoint(x: x + w * 0.2, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: y + h * 0.82), control1: CGPoint(x: x + w * 0.8, y: y), control2: CGPoint(x: x + w, y: y + h * 0.3))
        path.addQuadCurve(to: CGPoint(x: x, y: y + h * 0.82), control: CGPoint(x: x + w / 2, y: y + h * 1.12))
        path.closeSubpath()
        return path
    }
}

/// Four-point twinkle.
struct MiniFriendSparkle: View {
    var color: Color

    var body: some View {
        ZStack {
            Star(points: 4, inner: 0.36).fill(color)
            Star(points: 4, inner: 0.36).fill(Color.white).scaleEffect(0.4)
        }
    }
}
