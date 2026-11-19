import SwiftUI

/// Scroll math for the home scene. The list moves with the finger. The scene stays,
/// drifting upward only by `parallax`, and a scrim darkens it as the list covers it.
enum HomeMotion {
    static let space = "homeScroll"
    /// Fraction of the scroll the scene still travels. The rest is pinned.
    static let parallax: CGFloat = 0.18
    static let scrimMax = 0.4
    static let scrimSpan: CGFloat = 280

    static func covered(_ minY: CGFloat, resting: CGFloat) -> CGFloat {
        max(0, resting - minY)
    }

    static func pinOffset(covered: CGFloat, reduceMotion: Bool) -> CGFloat {
        let drift = reduceMotion ? CGFloat(0) : covered * parallax
        return covered - drift
    }

    static func scrim(covered: CGFloat) -> Double {
        guard scrimSpan > 0 else { return 0 }
        return min(scrimMax, Double(covered / scrimSpan) * scrimMax)
    }
}

struct HomeScrollMinYKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeScrollProbe: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: HomeScrollMinYKey.self,
                value: geo.frame(in: .named(HomeMotion.space)).minY
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct HomeScrollTracking: ViewModifier {
    @Binding var covered: CGFloat
    @State private var resting: CGFloat?

    func body(content: Content) -> some View {
        content
            .coordinateSpace(.named(HomeMotion.space))
            .onPreferenceChange(HomeScrollMinYKey.self) { minY in
                let base: CGFloat
                if let resting {
                    base = resting
                } else {
                    resting = minY
                    base = minY
                }
                let next = HomeMotion.covered(minY, resting: base)
                guard next != covered else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    covered = next
                }
            }
    }
}
