import SwiftUI

/// One flat spark bonus after the energy bar was already full.
struct HomeSparkFlight: Equatable {
    var token: Int
    var habitID: UUID
    var shownGain: Int
    var startBalance: Int
    var balance: Int
}

enum HomeSparkAnchor: Hashable {
    case row(UUID)
    case counter
}

struct HomeSparkAnchorKey: PreferenceKey {
    static var defaultValue: [HomeSparkAnchor: Anchor<CGRect>] = [:]
    static func reduce(value: inout [HomeSparkAnchor: Anchor<CGRect>], nextValue: () -> [HomeSparkAnchor: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

enum SparkCurve {
    static func control(from: CGPoint, to: CGPoint) -> CGPoint {
        CGPoint(x: (from.x + to.x) / 2, y: min(from.y, to.y) - 64)
    }

    static func point(from: CGPoint, to: CGPoint, t: CGFloat) -> CGPoint {
        let control = control(from: from, to: to)
        let clamped = min(1, max(0, t))
        let stay = 1 - clamped
        return CGPoint(
            x: stay * stay * from.x + 2 * stay * clamped * control.x + clamped * clamped * to.x,
            y: stay * stay * from.y + 2 * stay * clamped * control.y + clamped * clamped * to.y
        )
    }
}

struct HomeSparkChrome: ViewModifier {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var top: CGFloat
    var trailing: CGFloat

    @State private var active: HomeSparkFlight?
    @State private var played = 0
    @State private var shown = 0
    @State private var visible = false
    @State private var flying = false

    func body(content: Content) -> some View {
        let flight = engine.homeSparkFlight
        content
            .overlay(alignment: .topTrailing) {
                if active != nil {
                    HomeSparkCounter(count: shown, label: engine.t("home.sparks"))
                        .padding(.top, top)
                        .padding(.trailing, trailing)
                        .opacity(visible ? 1 : 0)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: visible)
                        .accessibilityHidden(!visible)
                        .allowsHitTesting(false)
                }
            }
            .overlayPreferenceValue(HomeSparkAnchorKey.self) { anchors in
                GeometryReader { proxy in
                    if flying, let active,
                       let row = anchors[.row(active.habitID)],
                       let counter = anchors[.counter] {
                        HomeSparkFlyer(
                            from: Self.center(proxy[row]),
                            to: Self.center(proxy[counter]),
                            token: active.token,
                            gain: active.shownGain
                        )
                        .id(active.token)
                        .allowsHitTesting(false)
                    }
                }
                .allowsHitTesting(false)
            }
            .task(id: flight?.token) {
                guard let flight else { return }
                await play(flight)
            }
    }

    @MainActor
    private func play(_ flight: HomeSparkFlight) async {
        guard flight.token != played else { return }
        played = flight.token
        active = flight
        shown = reduceMotion ? flight.balance : flight.startBalance
        flying = false
        visible = false
        AccessibilityNotification.Announcement(engine.tf("home.sparks.gain", flight.shownGain)).post()
        await Task.yield()
        guard !Task.isCancelled else { return }
        visible = true
        flying = !reduceMotion
        if reduceMotion {
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            hide(flight.token)
            return
        }
        try? await Task.sleep(for: .milliseconds(760))
        guard !Task.isCancelled, active?.token == flight.token else { return }
        flying = false
        withAnimation(.snappy(duration: 0.32)) { shown = flight.balance }
        try? await Task.sleep(for: .seconds(0.95))
        guard !Task.isCancelled else { return }
        hide(flight.token)
    }

    @MainActor
    private func hide(_ token: Int) {
        guard active?.token == token else { return }
        visible = false
    }

    private static func center(_ rect: CGRect) -> CGPoint {
        CGPoint(x: rect.midX, y: rect.midY)
    }
}

private struct HomeSparkCounter: View {
    var count: Int
    var label: String

    var body: some View {
        HStack(spacing: 6) {
            HomeSparkMark()
                .frame(width: 22, height: 22)
            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(HomePalette.ink)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(count)))
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .padding(.vertical, 5)
        .background(.white, in: Capsule())
        .shadow(color: Color.black.opacity(0.14), radius: 6, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(count)")
        .anchorPreference(key: HomeSparkAnchorKey.self, value: .bounds) { anchor in
            [HomeSparkAnchor.counter: anchor]
        }
    }
}

private struct SparkFlightPose: Animatable {
    var progress: CGFloat = 0
    var scale: CGFloat = 0.35
    var opacity: CGFloat = 0

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get { AnimatablePair(AnimatablePair(progress, scale), opacity) }
        set {
            progress = newValue.first.first
            scale = newValue.first.second
            opacity = newValue.second
        }
    }
}

private struct HomeSparkFlyer: View {
    var from: CGPoint
    var to: CGPoint
    var token: Int
    var gain: Int
    @State private var play = false
    @State private var lockedFrom: CGPoint
    @State private var lockedTo: CGPoint

    init(from: CGPoint, to: CGPoint, token: Int, gain: Int) {
        self.from = from
        self.to = to
        self.token = token
        self.gain = gain
        _lockedFrom = State(initialValue: from)
        _lockedTo = State(initialValue: to)
    }

    var body: some View {
        KeyframeAnimator(initialValue: SparkFlightPose(), trigger: play) { pose in
            HomeSparkBadge(gain: gain)
                .scaleEffect(pose.scale)
                .opacity(Double(pose.opacity))
                .position(SparkCurve.point(from: lockedFrom, to: lockedTo, t: pose.progress))
        } keyframes: { _ in
            KeyframeTrack(\.progress) {
                CubicKeyframe(CGFloat(1), duration: 0.74)
            }
            KeyframeTrack(\.scale) {
                SpringKeyframe(CGFloat(1.12), duration: 0.18, spring: .snappy)
                CubicKeyframe(CGFloat(0.62), duration: 0.56)
            }
            KeyframeTrack(\.opacity) {
                LinearKeyframe(CGFloat(1), duration: 0.1)
                LinearKeyframe(CGFloat(1), duration: 0.48)
                LinearKeyframe(CGFloat(0), duration: 0.16)
            }
        }
        .onAppear { play = true }
        .accessibilityHidden(true)
    }
}

private struct HomeSparkBadge: View {
    var gain: Int

    var body: some View {
        HStack(spacing: 4) {
            HomeSparkMark()
                .frame(width: 28, height: 28)
            Text("+\(gain)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8A4E08))
        }
        .padding(.leading, 4)
        .padding(.trailing, 8)
        .padding(.vertical, 3)
        .background(.white, in: Capsule())
        .shadow(color: Color(hex: 0xF0A53A).opacity(0.45), radius: 8, y: 2)
    }
}

struct HomeSparkMark: View {
    var body: some View {
        ZStack {
            Star(points: 4)
                .fill(Color(hex: 0xF0A53A))
            Star(points: 4)
                .fill(Color(hex: 0xFFE08A))
                .scaleEffect(0.55)
            Circle()
                .fill(.white)
                .frame(width: 4, height: 4)
        }
        .accessibilityHidden(true)
    }
}
