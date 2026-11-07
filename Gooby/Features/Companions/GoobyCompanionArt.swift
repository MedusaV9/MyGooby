#if canImport(SwiftUI)
import SwiftUI

struct GoobyEggArt: View {
    var progress: Int
    var size: CGFloat = 86

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.white, GoobyEventsPalette.cream, GoobyEventsPalette.blush.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(Ellipse().stroke(GoobyEventsPalette.ink.opacity(0.12), lineWidth: 2))
            Circle()
                .fill(GoobyEventsPalette.blush)
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(x: -size * 0.12, y: -size * 0.02)
            Circle()
                .fill(GoobyEventsPalette.butter)
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: size * 0.16, y: size * 0.12)
            Ellipse()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.18, height: size * 0.1)
                .offset(x: -size * 0.12, y: -size * 0.24)
            if progress >= 5 {
                GoobyEggCrack()
                    .stroke(GoobyEventsPalette.ink.opacity(0.45), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: size * 0.28, height: size * 0.34)
                    .offset(y: -size * 0.02)
            }
        }
        .frame(width: size * 0.72, height: size)
        .accessibilityHidden(true)
    }
}

struct GoobyCompanionArt: View {
    var speciesID: String
    var primaryHex: String
    var secondaryHex: String
    var animation: String
    var size: CGFloat = 96
    var animate: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var moving = false
    @State private var blink = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(GoobyEventsPalette.ink.opacity(0.08))
                .frame(width: size * 0.46, height: size * 0.1)
                .offset(y: size * 0.36)
            creature
                .frame(width: size * 0.84, height: size * 0.84)
        }
        .frame(width: size, height: size)
        .offset(x: drift, y: bob)
        .rotationEffect(.degrees(tilt))
        .onAppear {
            guard animate, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                moving = true
            }
        }
        .task(id: animate) {
            guard animate, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                blink = true
                try? await Task.sleep(nanoseconds: 130_000_000)
                blink = false
            }
        }
        .accessibilityHidden(true)
    }

    private var primary: Color { GoobyEventsPalette.color(hex: primaryHex) }
    private var secondary: Color { GoobyEventsPalette.color(hex: secondaryHex) }
    private var animated: Bool { animate && !reduceMotion && moving }

    private var bob: CGFloat {
        guard animated else { return 0 }
        switch animation {
        case "hop":
            return -7
        case "flutter":
            return -5
        default:
            return -3
        }
    }

    private var drift: CGFloat {
        guard animated, animation == "drift" else { return 0 }
        return 4
    }

    private var tilt: Double {
        guard animated else { return 0 }
        switch animation {
        case "waddle":
            return 7
        case "flutter":
            return -4
        default:
            return 0
        }
    }

    private var duration: Double {
        switch animation {
        case "hop":
            return 0.7
        case "twinkle":
            return 1.1
        default:
            return 1.5
        }
    }

    @ViewBuilder
    private var creature: some View {
        switch speciesID {
        case "chick":
            chick
        case "mini-cloud":
            cloud
        case "baby-dragon":
            dragon
        case "fox":
            fox
        case "star-being":
            star
        case "baby-penguin":
            penguin
        case "bear":
            bear
        case "mini-cat":
            cat
        case "ghost":
            ghost
        case "mini-unicorn":
            unicorn
        case "moon-being":
            moon
        case "mushroom-friend":
            mushroom
        case "blossom-beetle":
            beetle
        case "rainbow-wisp":
            wisp
        case "picnic-bee":
            bee
        case "lantern-sprite":
            lantern
        case "snow-puff":
            snow
        default:
            bear
        }
    }

    private var chick: some View {
        ZStack {
            Circle().fill(primary)
            Capsule().fill(secondary).frame(width: 18, height: 12).offset(x: -22, y: 8).rotationEffect(.degrees(-20))
            Capsule().fill(secondary).frame(width: 18, height: 12).offset(x: 22, y: 8).rotationEffect(.degrees(20))
            Capsule().fill(secondary).frame(width: 8, height: 14).offset(y: -34)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush, beak: secondary)
        }
    }

    private var cloud: some View {
        ZStack {
            Circle().fill(primary).frame(width: 34, height: 34).offset(x: -16, y: 8)
            Circle().fill(primary).frame(width: 42, height: 42).offset(x: 12, y: 6)
            Circle().fill(secondary).frame(width: 28, height: 28).offset(x: 0, y: -8)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.sky, scale: 0.85).offset(y: 4)
        }
    }

    private var dragon: some View {
        ZStack {
            Capsule().fill(secondary.opacity(0.85)).frame(width: 28, height: 18).offset(x: -30, y: -4).rotationEffect(.degrees(-24))
            Capsule().fill(secondary.opacity(0.85)).frame(width: 28, height: 18).offset(x: 30, y: -4).rotationEffect(.degrees(24))
            Circle().fill(primary)
            Capsule().fill(secondary).frame(width: 8, height: 16).offset(x: -12, y: -32).rotationEffect(.degrees(-18))
            Capsule().fill(secondary).frame(width: 8, height: 16).offset(x: 12, y: -32).rotationEffect(.degrees(18))
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush)
        }
    }

    private var fox: some View {
        ZStack {
            Circle().fill(primary)
            GoobyEar().fill(primary).frame(width: 22, height: 26).offset(x: -18, y: -30)
            GoobyEar().fill(primary).frame(width: 22, height: 26).offset(x: 18, y: -30)
            GoobyEar().fill(Color.white).frame(width: 10, height: 12).offset(x: -18, y: -26)
            GoobyEar().fill(Color.white).frame(width: 10, height: 12).offset(x: 18, y: -26)
            Ellipse().fill(secondary).frame(width: 28, height: 22).offset(y: 16)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush)
        }
    }

    private var star: some View {
        ZStack {
            GoobyStarShape().fill(primary)
            Circle().fill(secondary.opacity(0.9)).frame(width: 14, height: 14).offset(x: 24, y: -24)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush, scale: 0.8)
        }
    }

    private var penguin: some View {
        ZStack {
            Capsule().fill(primary).frame(width: 58, height: 70)
            Ellipse().fill(secondary).frame(width: 32, height: 40).offset(y: 8)
            Capsule().fill(GoobyEventsPalette.butter).frame(width: 16, height: 8).offset(x: -10, y: 36)
            Capsule().fill(GoobyEventsPalette.butter).frame(width: 16, height: 8).offset(x: 10, y: 36)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.peach, beak: GoobyEventsPalette.butter).offset(y: -8)
        }
    }

    private var bear: some View {
        ZStack {
            Circle().fill(primary).frame(width: 24, height: 24).offset(x: -24, y: -28)
            Circle().fill(primary).frame(width: 24, height: 24).offset(x: 24, y: -28)
            Circle().fill(secondary).frame(width: 12, height: 12).offset(x: -24, y: -28)
            Circle().fill(secondary).frame(width: 12, height: 12).offset(x: 24, y: -28)
            Circle().fill(primary)
            Ellipse().fill(secondary.opacity(0.85)).frame(width: 30, height: 22).offset(y: 14)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush)
        }
    }

    private var cat: some View {
        ZStack {
            Circle().fill(primary)
            GoobyEar().fill(primary).frame(width: 20, height: 22).offset(x: -18, y: -32)
            GoobyEar().fill(primary).frame(width: 20, height: 22).offset(x: 18, y: -32)
            Capsule().fill(secondary).frame(width: 10, height: 28).offset(x: 34, y: 10).rotationEffect(.degrees(28))
            GoobyCreatureFace(blink: blink, blush: secondary)
        }
    }

    private var ghost: some View {
        ZStack {
            GoobyGhostShape().fill(primary)
            GoobyCreatureFace(blink: blink, blush: secondary, scale: 0.9).offset(y: -6)
        }
    }

    private var unicorn: some View {
        ZStack {
            Capsule().fill(secondary).frame(width: 16, height: 22).offset(x: -20, y: -8).rotationEffect(.degrees(-40))
            Capsule().fill(GoobyEventsPalette.lavender).frame(width: 14, height: 18).offset(x: -10, y: -16).rotationEffect(.degrees(-16))
            Circle().fill(primary)
            GoobyEar().fill(GoobyEventsPalette.butter).frame(width: 12, height: 22).offset(y: -36)
            GoobyCreatureFace(blink: blink, blush: secondary)
        }
    }

    private var moon: some View {
        ZStack {
            Circle().fill(primary)
            Circle().fill(GoobyEventsPalette.cream).frame(width: 48, height: 48).offset(x: 16)
            Circle().fill(secondary).frame(width: 10, height: 10).offset(x: -18, y: -22)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush, scale: 0.75).offset(x: -8)
        }
    }

    private var mushroom: some View {
        ZStack {
            Capsule().fill(secondary).frame(width: 24, height: 32).offset(y: 16)
            Capsule().fill(primary).frame(width: 70, height: 40).offset(y: -8)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 10, height: 10).offset(x: -16, y: -16)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 8, height: 8).offset(x: 14, y: -10)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush, scale: 0.7).offset(y: 16)
        }
    }

    private var beetle: some View {
        ZStack {
            Capsule().fill(primary).frame(width: 62, height: 40)
            Capsule().fill(secondary).frame(width: 24, height: 28).offset(y: -8)
            Capsule().fill(GoobyEventsPalette.ink.opacity(0.8)).frame(width: 2, height: 16).offset(x: -8, y: -28)
            Capsule().fill(GoobyEventsPalette.ink.opacity(0.8)).frame(width: 2, height: 16).offset(x: 8, y: -28)
            Circle().fill(secondary.opacity(0.7)).frame(width: 18, height: 12).offset(x: -20, y: -10)
            Circle().fill(secondary.opacity(0.7)).frame(width: 18, height: 12).offset(x: 20, y: -10)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush, scale: 0.65)
        }
    }

    private var wisp: some View {
        ZStack {
            Circle().fill(primary.opacity(0.9)).frame(width: 46, height: 46).offset(x: -8, y: 4)
            Circle().fill(secondary.opacity(0.9)).frame(width: 28, height: 28).offset(x: 16, y: -12)
            Circle().fill(GoobyEventsPalette.mint.opacity(0.9)).frame(width: 22, height: 22).offset(x: 8, y: 16)
            GoobyCreatureFace(blink: blink, blush: Color.white.opacity(0.8), scale: 0.75)
        }
    }

    private var bee: some View {
        ZStack {
            Capsule().fill(secondary.opacity(0.55)).frame(width: 26, height: 16).offset(x: -24, y: -12)
            Capsule().fill(secondary.opacity(0.55)).frame(width: 26, height: 16).offset(x: 24, y: -12)
            Capsule().fill(primary).frame(width: 54, height: 38)
            Capsule().fill(GoobyEventsPalette.ink).frame(width: 10, height: 30).offset(x: -8)
            Capsule().fill(GoobyEventsPalette.ink).frame(width: 10, height: 30).offset(x: 8)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.peach, scale: 0.7)
        }
    }

    private var lantern: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(GoobyEventsPalette.ink)
                .frame(width: 16, height: 8)
                .offset(y: -36)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(primary)
                .frame(width: 48, height: 58)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(secondary.opacity(0.35))
                .frame(width: 28, height: 34)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush, scale: 0.75)
        }
    }

    private var snow: some View {
        ZStack {
            Circle().fill(primary)
            Circle().fill(secondary).frame(width: 10, height: 10).offset(x: -24, y: -20)
            Circle().fill(secondary).frame(width: 8, height: 8).offset(x: 26, y: -8)
            Circle().fill(secondary).frame(width: 7, height: 7).offset(x: 16, y: 24)
            Capsule().fill(GoobyEventsPalette.blush).frame(width: 34, height: 10).offset(y: 8)
            GoobyCreatureFace(blink: blink, blush: GoobyEventsPalette.blush, scale: 0.8).offset(y: -4)
        }
    }
}

struct GoobyCreatureFace: View {
    var blink: Bool
    var blush: Color
    var beak: Color? = nil
    var scale: CGFloat = 1

    var body: some View {
        ZStack {
            HStack(spacing: 18 * scale) {
                Circle().fill(blush.opacity(0.95)).frame(width: 8 * scale, height: 6 * scale)
                Circle().fill(blush.opacity(0.95)).frame(width: 8 * scale, height: 6 * scale)
            }
            .offset(y: 8 * scale)
            VStack(spacing: 1) {
                HStack(spacing: 9 * scale) {
                    eye
                    eye
                }
                if let beak {
                    Capsule().fill(beak).frame(width: 10 * scale, height: 6 * scale)
                } else {
                    Circle().fill(Color(red: 1, green: 0.55, blue: 0.64)).frame(width: 6 * scale, height: 5 * scale)
                }
                GoobySmile()
                    .stroke(GoobyEventsPalette.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                    .frame(width: 12 * scale, height: 6 * scale)
            }
        }
    }

    private var eye: some View {
        ZStack {
            Capsule()
                .fill(GoobyEventsPalette.ink)
                .frame(width: 7 * scale, height: (blink ? 1.4 : 8) * scale)
            if !blink {
                Circle()
                    .fill(Color.white)
                    .frame(width: 2.2 * scale, height: 2.2 * scale)
                    .offset(x: 1.2 * scale, y: -1.5 * scale)
            }
        }
        .frame(width: 8 * scale, height: 8 * scale)
    }
}

struct GoobySmile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

struct GoobyEar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        return path
    }
}

struct GoobyStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<10 {
            let angle = (Double(index) * .pi / 5) - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : outer * 0.46
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct GoobyGhostShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.72)
        path.addArc(
            center: CGPoint(x: top.midX, y: top.midY),
            radius: top.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 8))
        let bumps = 3
        let bump = rect.width / CGFloat(bumps)
        for index in 0..<bumps {
            let startX = rect.maxX - CGFloat(index) * bump
            path.addQuadCurve(
                to: CGPoint(x: startX - bump, y: rect.maxY - 8),
                control: CGPoint(x: startX - bump / 2, y: rect.maxY + 6)
            )
        }
        path.closeSubpath()
        return path
    }
}

struct GoobyEggCrack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.25, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY))
        return path
    }
}
#endif
