import SwiftUI

// Motion kit (masterprompt 1.3 and 6.3): the shared animations, transitions and small effects of
// the app. Every helper honors reduced motion, which is the in-app switch (Settings > Reduce
// animations, `engine.reduceMotion`) or the system setting: movement is dropped, state changes
// happen at once and only plain fades remain.

// MARK: - Reduced motion

private struct GoobyReduceMotionKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// `engine.reduceMotion || accessibilityReduceMotion`, set once by RootView for the whole app
    /// (sheets and covers inherit it).
    var goobyReduceMotion: Bool {
        get { self[GoobyReduceMotionKey.self] }
        set { self[GoobyReduceMotionKey.self] = newValue }
    }
}

// MARK: - Curves

enum GoobyMotion {
    /// Springy settle for pops, toggles and list changes.
    static let springy = Animation.spring(response: 0.42, dampingFraction: 0.72)
    /// Soft ease for cards fading in and screens swapping.
    static let soft = Animation.easeOut(duration: 0.34)
    /// Short cross-fade (the only animation left with reduced motion).
    static let fade = Animation.easeInOut(duration: 0.2)
    /// Key press feedback.
    static let press = Animation.easeOut(duration: 0.08)

    /// `animation`, or nil (no animation) with reduced motion.
    static func motion(_ reduce: Bool, _ animation: Animation = springy) -> Animation? {
        reduce ? nil : animation
    }

    /// `animation`, or a short fade with reduced motion (for opacity-only changes).
    static func fadeable(_ reduce: Bool, _ animation: Animation = soft) -> Animation {
        reduce ? fade : animation
    }
}

/// `withAnimation` that skips the animation with reduced motion.
@MainActor
@discardableResult
func goobyAnimate<Result>(_ reduce: Bool, _ animation: Animation = GoobyMotion.springy, _ body: () throws -> Result) rethrows -> Result {
    try withAnimation(GoobyMotion.motion(reduce, animation), body)
}

// MARK: - Transitions

extension AnyTransition {
    /// Cards and tiles: grow in from 94 % with a fade; fade only with reduced motion.
    static func goobyCard(_ reduce: Bool) -> AnyTransition {
        reduce ? .opacity : .scale(scale: 0.94).combined(with: .opacity)
    }

    /// Rows unfolding under a header: slide down a little and fade.
    static func goobyUnfold(_ reduce: Bool) -> AnyTransition {
        reduce ? .opacity : .offset(y: -12).combined(with: .opacity)
    }

    /// Banners and toasts from the top edge.
    static func goobyDrop(_ reduce: Bool) -> AnyTransition {
        reduce ? .opacity : .move(edge: .top).combined(with: .opacity)
    }

    /// Content that rises into place (outcomes, results).
    static func goobyRise(_ reduce: Bool) -> AnyTransition {
        reduce ? .opacity : .offset(y: 18).combined(with: .opacity)
    }

    /// Whole screens swapping (splash, lock, onboarding, tabs): fade with a slight zoom.
    static func goobyScreen(_ reduce: Bool) -> AnyTransition {
        reduce ? .opacity : .scale(scale: 1.03).combined(with: .opacity)
    }
}

// MARK: - Entrance

/// Fades a card in and lets it rise into place the first time it appears; `index` staggers the
/// cards of a list (the first ten, later ones come at once).
private struct GoobyEntrance: ViewModifier {
    var index: Int
    @Environment(\.goobyReduceMotion) private var appReduce
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var shown = false

    func body(content: Content) -> some View {
        let still = shown || appReduce || systemReduce
        content
            .opacity(still ? 1 : 0)
            .offset(y: still ? 0 : 14)
            .scaleEffect(still ? 1 : 0.97, anchor: .top)
            .onAppear {
                guard !shown else { return }
                if appReduce || systemReduce {
                    shown = true
                    return
                }
                let delay = index < 10 ? Double(max(0, index)) * 0.045 : 0
                withAnimation(GoobyMotion.soft.delay(delay)) { shown = true }
            }
    }
}

// MARK: - Pop

private enum GoobyPopPhase {
    case rest, up
}

/// A quick springy scale-up and settle each time `trigger` changes (checks, claims, counters).
private struct GoobyPop<Trigger: Equatable>: ViewModifier {
    var trigger: Trigger
    var amount: CGFloat
    @Environment(\.goobyReduceMotion) private var appReduce
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    func body(content: Content) -> some View {
        if appReduce || systemReduce {
            content
        } else {
            let peak = amount
            content.phaseAnimator([GoobyPopPhase.rest, GoobyPopPhase.up], trigger: trigger) { view, phase in
                view.scaleEffect(phase == .up ? peak : 1)
            } animation: { phase in
                phase == .up ? .spring(response: 0.16, dampingFraction: 0.6) : .spring(response: 0.42, dampingFraction: 0.5)
            }
        }
    }
}

// MARK: - Counters

/// Rolling digits when a number changes (sparks, streak); plain swap with reduced motion.
private struct GoobyCounter: ViewModifier {
    var value: Int
    @Environment(\.goobyReduceMotion) private var appReduce
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    func body(content: Content) -> some View {
        let reduce = appReduce || systemReduce
        content
            .contentTransition(reduce ? .identity : .numericText(value: Double(value)))
            .animation(GoobyMotion.motion(reduce, .spring(response: 0.45, dampingFraction: 0.8)), value: value)
    }
}

private struct GoobyGainBubble: Identifiable {
    let id = UUID()
    var amount: Int
}

/// "+N" chips that float up into a counter whenever `value` grows (currency added).
private struct GoobyGainFloat: ViewModifier {
    var value: Int
    var symbol: String
    var color: Color
    @State private var bubbles: [GoobyGainBubble] = []

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                ZStack {
                    ForEach(bubbles) { bubble in
                        GoobyGainBubbleView(text: "+\(bubble.amount) \(symbol)", color: color)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .onChange(of: value) { old, new in
                guard new > old else { return }
                let bubble = GoobyGainBubble(amount: new - old)
                bubbles.append(bubble)
                if bubbles.count > 3 { bubbles.removeFirst() }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_400_000_000)
                    bubbles.removeAll { $0.id == bubble.id }
                }
            }
    }
}

private struct GoobyGainFrame {
    var y: CGFloat = 30
    var opacity: Double = 0
    var scale: CGFloat = 0.7
}

private struct GoobyGainBubbleView: View {
    var text: String
    var color: Color
    @Environment(\.goobyReduceMotion) private var appReduce
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var started = false

    var body: some View {
        let reduce = appReduce || systemReduce
        label
            .keyframeAnimator(initialValue: GoobyGainFrame(), trigger: started) { view, frame in
                view
                    .offset(y: reduce ? 26 : frame.y)
                    .scaleEffect(reduce ? 1 : frame.scale)
                    .opacity(frame.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    CubicKeyframe(30, duration: 0.01)
                    SpringKeyframe(4, duration: 0.85, spring: .smooth)
                    CubicKeyframe(-2, duration: 0.3)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: 0.15)
                    LinearKeyframe(1, duration: 0.65)
                    LinearKeyframe(0, duration: 0.35)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.08, duration: 0.3, spring: .bouncy)
                    SpringKeyframe(1, duration: 0.3)
                    CubicKeyframe(0.85, duration: 0.5)
                }
            }
            .onAppear { started = true }
    }

    private var label: some View {
        Text(verbatim: text)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(color, in: Capsule())
            .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
            .fixedSize()
    }
}

// MARK: - Idle sway

/// Slow back-and-forth tilt for decorations (bag sack, banners); still with reduced motion.
private struct GoobySway: ViewModifier {
    var degrees: Double
    var duration: Double
    var anchor: UnitPoint
    @Environment(\.goobyReduceMotion) private var appReduce
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    func body(content: Content) -> some View {
        if appReduce || systemReduce {
            content
        } else {
            let tilt = degrees
            let anchorPoint = anchor
            let length = duration
            content.phaseAnimator([false, true]) { view, right in
                view.rotationEffect(.degrees(right ? tilt : -tilt), anchor: anchorPoint)
            } animation: { _ in
                .easeInOut(duration: length)
            }
        }
    }
}

// MARK: - API

extension View {
    /// Card fades and rises in on first appearance; `index` staggers a list.
    func goobyEntrance(_ index: Int = 0) -> some View {
        modifier(GoobyEntrance(index: index))
    }

    /// Springy pop whenever `trigger` changes.
    func goobyPop<Trigger: Equatable>(on trigger: Trigger, amount: CGFloat = 1.16) -> some View {
        modifier(GoobyPop(trigger: trigger, amount: amount))
    }

    /// Rolling digits for a counter showing `value`.
    func goobyCounter(_ value: Int) -> some View {
        modifier(GoobyCounter(value: value))
    }

    /// "+N symbol" chips rising into the view whenever `value` grows.
    func goobyGainFloat(_ value: Int, symbol: String = "✨", color: Color = Color(hex: 0xF2A93B)) -> some View {
        modifier(GoobyGainFloat(value: value, symbol: symbol, color: color))
    }

    /// Gentle endless tilt (decorations).
    func goobySway(_ degrees: Double = 2.5, duration: Double = 1.8, anchor: UnitPoint = .bottom) -> some View {
        modifier(GoobySway(degrees: degrees, duration: duration, anchor: anchor))
    }

    /// Source of a zoom push (iOS 18 and later): the tapped tile grows into the next screen.
    @ViewBuilder
    func goobyZoomSource(_ id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Destination of a zoom push from `goobyZoomSource`; the system push on iOS 17 and with
    /// reduced motion (the system turns the zoom into a fade itself when its setting is on).
    @ViewBuilder
    func goobyZoomDestination(_ id: String, in namespace: Namespace.ID, reduce: Bool) -> some View {
        if #available(iOS 18.0, *) {
            if reduce {
                self
            } else {
                navigationTransition(.zoom(sourceID: id, in: namespace))
            }
        } else {
            self
        }
    }
}
