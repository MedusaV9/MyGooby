import SwiftUI
import UIKit

enum ActivityArt {
    private static var cache: [String: UIImage] = [:]

    static func image(_ name: String) -> UIImage? {
        if let cached = cache[name] { return cached }
        guard let loaded = load(name) else { return nil }
        cache[name] = loaded
        return loaded
    }

    private static func load(_ name: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = UIImage(contentsOf: url) {
            return image
        }
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return nil }
        for case let url as URL in enumerator {
            if url.pathExtension == "png", url.deletingPathExtension().lastPathComponent == name {
                return UIImage(contentsOf: url)
            }
        }
        return nil
    }
}

struct ActivitySkyBackdrop: View {
    var reduceMotion: Bool

    var body: some View {
        Group {
            if reduceMotion {
                scene(time: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                    scene(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    private func scene(time: Double) -> some View {
        let drift = CGFloat(sin(time * 0.22)) * 26
        let driftBack = CGFloat(sin(time * 0.15 + 1.4)) * 34
        let gull = CGFloat(sin(time * 0.45)) * 16
        let gullLift = CGFloat(sin(time * 1.6)) * 5
        return LinearGradient(
            colors: [Color(hex: 0x2767A7), Color(hex: 0x217DBE), Color(hex: 0x1B98D8)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            ActivitySkyPlate(name: "activity-sky-clouds", widthFactor: 1.7, heightFactor: 0.42)
                .offset(x: drift, y: 8)
        }
        .overlay(alignment: .bottom) {
            ActivitySkyPlate(name: "activity-sky-clouds-b", widthFactor: 1.8, heightFactor: 0.46)
                .offset(x: -driftBack, y: 28)
        }
        .overlay(alignment: .topTrailing) {
            ActivitySkyPlate(name: "activity-sky-gulls", widthFactor: 0.72, heightFactor: 0.22)
                .offset(x: gull, y: 36 + gullLift)
        }
        .overlay(alignment: .center) {
            ActivitySkyPlate(name: "activity-sky-gulls", widthFactor: 0.46, heightFactor: 0.14)
                .offset(x: -70 - gull * 0.6, y: 10 - gullLift)
        }
    }
}

struct ActivitySkyPlate: View {
    var name: String
    var widthFactor: CGFloat
    var heightFactor: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * widthFactor
            let height = proxy.size.width * heightFactor
            Group {
                if let image = ActivityArt.image(name) {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: width, height: height)
                } else {
                    ActivityCloud(width: width * 0.45)
                        .frame(width: width, height: height, alignment: .leading)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .allowsHitTesting(false)
    }
}

struct ActivityCloud: View {
    var width: CGFloat

    var body: some View {
        ZStack {
            Capsule().frame(width: width, height: width * 0.36)
            Circle().frame(width: width * 0.38).offset(x: -width * 0.22, y: -width * 0.1)
            Circle().frame(width: width * 0.48).offset(x: width * 0.02, y: -width * 0.16)
            Circle().frame(width: width * 0.32).offset(x: width * 0.24, y: -width * 0.06)
        }
        .foregroundStyle(Color.white.opacity(0.95))
    }
}

struct ActivityPilot: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var arrived: Bool

    var body: some View {
        Group {
            if reduceMotion {
                craft(time: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                    craft(time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 214)
        .offset(x: arrived || reduceMotion ? 0 : -48)
        .opacity(arrived || reduceMotion ? 1 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(engine.t("activity.sky"))
    }

    private func craft(time: Double) -> some View {
        let bob = reduceMotion ? 0 : CGFloat(sin(time * .pi)) * 5
        let tilt = reduceMotion ? 0 : ActivityFlight.gust(time)
        let spin = reduceMotion ? 0 : time * 1400
        let width: CGFloat = 308
        let height = width * 512 / 840
        return ZStack {
            if ActivityArt.image("activity-plane-back") != nil {
                ActivityPlanePlate(name: "activity-plane-back")
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: reduceMotion ? .sit : .idle,
                    reduceMotion: reduceMotion,
                    companion: nil,
                    showCompanion: false
                )
                .frame(width: width * 0.34, height: width * 0.40)
                .offset(x: width * 0.09, y: -height * 0.08)
                ActivityPlanePlate(name: "activity-plane-front")
                ActivityPlanePlate(name: "activity-plane-prop")
                    .rotationEffect(.degrees(spin), anchor: UnitPoint(x: CGFloat(124.0 / 840.0), y: CGFloat(228.0 / 512.0)))
            } else {
                ActivityPlaneBody(gust: tilt)
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: reduceMotion ? .sit : .idle,
                    reduceMotion: reduceMotion,
                    companion: nil,
                    showCompanion: false
                )
                .frame(width: 96, height: 96)
                .offset(x: 6, y: -40)
                ActivityPropeller(angle: spin, spinning: !reduceMotion)
                    .offset(x: -108, y: 4)
            }
        }
        .frame(width: width, height: height)
        .rotationEffect(.degrees(tilt))
        .offset(y: bob)
        .allowsHitTesting(false)
    }
}

struct ActivityPlanePlate: View {
    var name: String

    var body: some View {
        if let image = ActivityArt.image(name) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        }
    }
}

enum ActivityFlight {
    /// Wind gust from the plane loop: level, then +11°, then −8°, then level, every 12 seconds.
    static func gust(_ time: Double) -> Double {
        let t = time.truncatingRemainder(dividingBy: 12)
        if t < 7.75 { return 0 }
        if t < 8.54 { return lerp(0, 11, (t - 7.75) / 0.79) }
        if t < 9.67 { return 11 }
        if t < 10.46 { return lerp(11, -8, (t - 9.67) / 0.79) }
        if t < 11.25 { return -8 }
        if t < 11.75 { return lerp(-8, 0, (t - 11.25) / 0.5) }
        return 0
    }

    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * min(1, max(0, t))
    }
}

struct ActivityPlaneBody: View {
    var gust: Double

    var body: some View {
        ZStack {
            ActivityTail()
                .fill(Color(hex: 0xF08A12))
                .frame(width: 42, height: 36)
                .offset(x: 92, y: -20)
            Capsule()
                .fill(Color(hex: 0xFFC44D))
                .frame(width: 158, height: 22)
                .rotationEffect(.degrees(8))
                .offset(y: 16)
            Capsule()
                .fill(Color(hex: 0xFF9E1B))
                .frame(width: 176, height: 42)
            Circle()
                .fill(Color(hex: 0xFF9E1B))
                .frame(width: 40, height: 40)
                .offset(x: -84)
            Capsule()
                .fill(Color.white.opacity(0.28))
                .frame(width: 64, height: 8)
                .offset(x: 8, y: -8)
            Circle()
                .fill(Color(hex: 0xD7F0FA))
                .frame(width: 14, height: 14)
                .offset(x: -18, y: -6)
            ActivityScarf()
                .rotationEffect(.degrees(gust * 0.45))
                .offset(x: 18, y: -6)
        }
        .accessibilityHidden(true)
    }
}

struct ActivityScarf: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0xE23B3B))
                .frame(width: 28, height: 10)
                .rotationEffect(.degrees(-18))
            Capsule()
                .fill(Color(hex: 0xC42137))
                .frame(width: 16, height: 8)
                .rotationEffect(.degrees(24))
                .offset(x: 12, y: 4)
        }
    }
}

struct ActivityTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct ActivityPropeller: View {
    var angle: Double
    var spinning: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.white.opacity(spinning ? 0.72 : 0.92))
                .frame(width: 16, height: 36)
                .rotationEffect(.degrees(spinning ? angle * 0.15 : 0))
            if spinning {
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 6, height: 34)
                    .rotationEffect(.degrees(angle))
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 6, height: 34)
                    .rotationEffect(.degrees(angle + 90))
            }
            Circle()
                .fill(Color(hex: 0xFF9E1B))
                .frame(width: 11, height: 11)
        }
        .accessibilityHidden(true)
    }
}

struct ActivityMark: View {
    var lane: ActivityLane

    var body: some View {
        ZStack {
            switch lane {
            case .ideas: ActivityFlagMark()
            case .reflections: ActivityPenMark()
            case .breathe: ActivityLeafMark()
            case .soundscapes: ActivityNoteMark()
            case .movements: ActivityShoeMark()
            case .timers: ActivityClockMark()
            case .kindness: ActivityDaisyMark()
            case .aid: ActivityKitMark()
            }
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

private struct ActivityFlagMark: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x7ED06A)).frame(width: 26, height: 12).offset(y: 9)
            Ellipse().fill(Color(hex: 0x3E9A32)).frame(width: 16, height: 7).offset(y: 10)
            Rectangle().fill(Color(hex: 0xF4F7FB)).frame(width: 2.4, height: 18).offset(x: -6, y: -1)
            ActivityFlagTriangle().fill(Color(hex: 0xE23B3B)).frame(width: 13, height: 9).offset(x: 2, y: -8)
        }
    }
}

private struct ActivityFlagTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ActivityPenMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x2A2E35)).frame(width: 8, height: 22).rotationEffect(.degrees(-38))
            Capsule().fill(Color(hex: 0xF2C14E)).frame(width: 8, height: 7).rotationEffect(.degrees(-38)).offset(x: 7, y: -8)
            Circle().fill(Color(hex: 0xE4534A)).frame(width: 4, height: 4).offset(x: -9, y: 9)
        }
    }
}

private struct ActivityLeafMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xB7E7A4)).frame(width: 3, height: 10).rotationEffect(.degrees(-50)).offset(x: -8, y: -2)
            Capsule().fill(Color(hex: 0xB7E7A4)).frame(width: 3, height: 8).rotationEffect(.degrees(40)).offset(x: 8, y: 1)
            Ellipse().fill(Color(hex: 0x7ED57A)).frame(width: 15, height: 22).rotationEffect(.degrees(-24))
            Capsule().fill(Color.white.opacity(0.9)).frame(width: 2, height: 12).rotationEffect(.degrees(-24))
        }
    }
}

private struct ActivityNoteMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x5B6CFF)).frame(width: 8, height: 8).offset(x: -6, y: 6)
            Circle().fill(Color(hex: 0x7A4DFF)).frame(width: 8, height: 8).offset(x: 6, y: 4)
            Rectangle().fill(Color(hex: 0x5B6CFF)).frame(width: 2, height: 14).offset(x: -3, y: -2)
            Rectangle().fill(Color(hex: 0x7A4DFF)).frame(width: 2, height: 14).offset(x: 9, y: -4)
            Capsule().fill(Color(hex: 0x5B6CFF)).frame(width: 16, height: 3).offset(y: -10)
        }
    }
}

private struct ActivityShoeMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xE23B3B)).frame(width: 24, height: 11).rotationEffect(.degrees(-18)).offset(y: 3)
            Circle().fill(Color(hex: 0xE23B3B)).frame(width: 12, height: 12).offset(x: 7, y: -1)
            Capsule().fill(Color.white).frame(width: 16, height: 4).rotationEffect(.degrees(-12)).offset(x: 1, y: 7)
            Capsule().fill(Color.white.opacity(0.85)).frame(width: 6, height: 2).offset(x: 2, y: 1)
        }
    }
}

private struct ActivityClockMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF4F7FB))
            Circle().stroke(Color(hex: 0x5C6B7A), lineWidth: 2.2)
            Rectangle().fill(Color(hex: 0x5C6B7A)).frame(width: 2, height: 7).offset(y: -2)
            Rectangle().fill(Color(hex: 0xE4534A)).frame(width: 6, height: 2).offset(x: 2)
        }
        .frame(width: 22, height: 22)
    }
}

private struct ActivityDaisyMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x3EAE45)).frame(width: 2.4, height: 10).offset(y: 12)
            Ellipse().fill(Color(hex: 0x7ED06A)).frame(width: 8, height: 5).rotationEffect(.degrees(-30)).offset(x: 6, y: 10)
            ForEach(0..<8, id: \.self) { index in
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 7, height: 11)
                    .offset(y: -7)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            Circle().fill(Color(hex: 0xF2C14E)).frame(width: 8, height: 8)
        }
    }
}

private struct ActivityKitMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color.white).frame(width: 22, height: 16).offset(y: 3)
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Color(hex: 0xF7B4C4)).frame(width: 10, height: 5).offset(y: -7)
            Rectangle().fill(Color(hex: 0xE4534A)).frame(width: 8, height: 2.4)
            Rectangle().fill(Color(hex: 0xE4534A)).frame(width: 2.4, height: 8)
        }
    }
}

struct ActivitySkyTile: View {
    var title: String
    var lane: ActivityLane

    var body: some View {
        HStack(spacing: 8) {
            ActivityMark(lane: lane)
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x1E2A3A))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: 0x1A4E86).opacity(0.14), radius: 7, y: 3)
    }
}

struct ActivityPressStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.2), value: configuration.isPressed)
    }
}
