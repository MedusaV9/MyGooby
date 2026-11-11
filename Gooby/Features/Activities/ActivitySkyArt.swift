import SwiftUI

struct ActivitySkyBackdrop: View {
    var reduceMotion: Bool

    var body: some View {
        Group {
            if reduceMotion {
                scene(drift: 0, lift: 6)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    scene(
                        drift: CGFloat(sin(time * 0.35) * 16),
                        lift: CGFloat(6 + sin(time * 2.6) * 3)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    private func scene(drift: CGFloat, lift: CGFloat) -> some View {
        LinearGradient(
            colors: [Color(hex: 0x79C4F6), Color(hex: 0x3E93DC), Color(hex: 0x2A72C2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topLeading) {
            ActivityCloud(width: 150).offset(x: -20 + drift, y: 28)
        }
        .overlay(alignment: .topTrailing) {
            ZStack(alignment: .topTrailing) {
                ActivityCloud(width: 110).offset(x: 18 - drift, y: 78)
                ActivityBird(lift: lift).offset(x: -28, y: 58)
            }
        }
        .overlay(alignment: .center) {
            ActivityBird(lift: lift).offset(x: 96 + drift * 0.35, y: -30)
        }
        .overlay(alignment: .bottomLeading) {
            ActivityCloud(width: 170).offset(x: -36 - drift * 0.25, y: 16)
        }
        .overlay(alignment: .bottom) {
            ActivityCloud(width: 230).offset(x: drift * 0.4, y: 36)
        }
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

struct ActivityBird: View {
    var lift: CGFloat

    var body: some View {
        ActivityBirdShape(lift: lift)
            .stroke(Color.white.opacity(0.92), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            .frame(width: 26, height: 16)
    }
}

struct ActivityBirdShape: Shape {
    var lift: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: y),
            control: CGPoint(x: rect.minX + rect.width * 0.25, y: y - lift)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: y),
            control: CGPoint(x: rect.midX + rect.width * 0.25, y: y - lift)
        )
        return path
    }
}

struct ActivityPilot: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        Group {
            if reduceMotion {
                craft(bob: 0, spin: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    craft(bob: CGFloat(sin(time * 1.15) * 6), spin: time * 640)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(engine.t("activity.sky"))
    }

    private func craft(bob: CGFloat, spin: Double) -> some View {
        ZStack {
            ActivityPlaneBody()
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: reduceMotion ? .sit : .idle,
                reduceMotion: reduceMotion,
                companion: nil,
                showCompanion: false
            )
            .frame(width: 88, height: 88)
            .offset(x: -8, y: -38)
            ActivityPropeller(angle: spin)
                .offset(x: 98, y: 2)
        }
        .offset(y: bob)
        .allowsHitTesting(false)
    }
}

struct ActivityPlaneBody: View {
    var body: some View {
        ZStack {
            ActivityTail()
                .fill(Color(hex: 0xE8901A))
                .frame(width: 34, height: 28)
                .offset(x: -78, y: -16)
            Capsule()
                .fill(Color(hex: 0xF6C453))
                .frame(width: 156, height: 26)
                .rotationEffect(.degrees(-8))
                .offset(y: 10)
            Capsule()
                .fill(Color(hex: 0xF39B22))
                .frame(width: 168, height: 42)
            Circle()
                .fill(Color(hex: 0xF39B22))
                .frame(width: 40, height: 40)
                .offset(x: 78)
            Circle()
                .fill(Color(hex: 0xD7F0FA))
                .frame(width: 16, height: 16)
                .offset(x: 24, y: -6)
            Capsule()
                .fill(Color(hex: 0xE4534A))
                .frame(width: 18, height: 8)
                .rotationEffect(.degrees(18))
                .offset(x: -6, y: -4)
        }
        .accessibilityHidden(true)
    }
}

struct ActivityTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct ActivityPropeller: View {
    var angle: Double

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.94))
                .frame(width: 7, height: 36)
            Capsule()
                .fill(Color.white.opacity(0.94))
                .frame(width: 7, height: 36)
                .rotationEffect(.degrees(90))
            Circle()
                .fill(Color(hex: 0xF4E2B0))
                .frame(width: 10, height: 10)
        }
        .rotationEffect(.degrees(angle))
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
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }
}

private struct ActivityFlagMark: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x8FD36A)).frame(width: 26, height: 12).offset(y: 8)
            Ellipse().fill(Color(hex: 0x6BB84A)).frame(width: 14, height: 6).offset(y: 9)
            Rectangle().fill(Color.white).frame(width: 2.5, height: 16).offset(y: -1)
            ActivityFlagTriangle().fill(Color(hex: 0xE4534A)).frame(width: 12, height: 8).offset(x: 7, y: -7)
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
            Capsule().fill(Color(hex: 0x2A2E35)).frame(width: 7, height: 22).rotationEffect(.degrees(-38))
            Capsule().fill(Color(hex: 0xF2C14E)).frame(width: 7, height: 6).rotationEffect(.degrees(-38)).offset(x: 7, y: -7)
            Circle().fill(Color(hex: 0xE4534A)).frame(width: 5, height: 5).offset(x: -8, y: 8)
        }
    }
}

private struct ActivityLeafMark: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x7ED57A)).frame(width: 14, height: 22).rotationEffect(.degrees(-28))
            Capsule().fill(Color.white.opacity(0.85)).frame(width: 2, height: 12).rotationEffect(.degrees(-28))
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
            Capsule().fill(Color(hex: 0xE4534A)).frame(width: 22, height: 10).offset(y: 4)
            Circle().fill(Color(hex: 0xE4534A)).frame(width: 12, height: 12).offset(x: 6, y: 1)
            Capsule().fill(Color.white).frame(width: 10, height: 3).offset(x: -1, y: 6)
        }
    }
}

private struct ActivityClockMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF4F7FB)).frame(width: 22, height: 22)
            Circle().stroke(Color(hex: 0x5C6B7A), lineWidth: 2.4).frame(width: 22, height: 22)
            Rectangle().fill(Color(hex: 0x5C6B7A)).frame(width: 2, height: 7).offset(y: -2)
            Rectangle().fill(Color(hex: 0xE4534A)).frame(width: 6, height: 2).offset(x: 2)
        }
    }
}

private struct ActivityDaisyMark: View {
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 8, height: 12)
                    .offset(y: -7)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
            Circle().fill(Color(hex: 0xF2C14E)).frame(width: 8, height: 8)
            Capsule().fill(Color(hex: 0x3EAE45)).frame(width: 2, height: 8).offset(y: 11)
        }
    }
}

private struct ActivityKitMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.white).frame(width: 22, height: 16).offset(y: 3)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xE4534A)).frame(width: 10, height: 5).offset(y: -7)
            Rectangle().fill(Color(hex: 0xE4534A)).frame(width: 8, height: 2)
            Rectangle().fill(Color(hex: 0xE4534A)).frame(width: 2, height: 8)
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
                .foregroundStyle(Color(hex: 0x243041))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color(hex: 0x1D4E89).opacity(0.16), radius: 8, y: 4)
    }
}

struct ActivityPressStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.2), value: configuration.isPressed)
    }
}
