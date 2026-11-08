import SwiftUI

/// Living detail over an illustrated daytime scene (screen F's forest while Gooby is out): tiny
/// pollen specks that float up through the band above the meadow, sway and fade at its edges
/// (the evening and night forest has HomeFireflies instead). One Canvas draws every speck per
/// frame (30 fps); positions are pure functions of time and the speck's index, so nothing is
/// stored. Nothing is drawn with reduced motion (in-app switch or system setting).
struct GoobyPollenMotes: View {
    var count = 8
    /// Where the specks live, in unit coordinates of the view (default: the band above the meadow).
    var area = CGRect(x: 0.04, y: 0.34, width: 0.92, height: 0.42)
    @Environment(\.goobyReduceMotion) private var appReduce
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    var body: some View {
        Group {
            if appReduce || systemReduce {
                Color.clear
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
                        for index in 0..<count {
                            draw(index, at: time, in: context, size: size)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// A stable pseudo-random number in 0..<1 for (speck, slot).
    private static func unit(_ index: Int, _ slot: Int) -> Double {
        let x = sin(Double(index * 97 + slot * 31) * 12.9898) * 43758.5453
        return x - x.rounded(.down)
    }

    private func draw(_ index: Int, at time: TimeInterval, in context: GraphicsContext, size: CGSize) {
        let u = { (slot: Int) -> Double in GoobyPollenMotes.unit(index, slot) }
        let width = Double(size.width)
        let height = Double(size.height)
        // Rises through the band in 9-15 s and sways sideways on a 7-12 s period.
        let rise = 9 + 6 * u(5)
        let progress = (time / rise + u(6)).truncatingRemainder(dividingBy: 1)
        let sway = 12 * sin(2 * Double.pi * time / (7 + 5 * u(2)) + 2 * Double.pi * u(4))
        let x = (Double(area.minX) + Double(area.width) * u(0)) * width + sway
        let y = (Double(area.maxY) - Double(area.height) * progress) * height
        let fade = min(1.0, min(progress, 1 - progress) * 5)
        let radius = 1.3 + 0.8 * u(7)
        context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                     with: .color(Color.white.opacity(0.7 * fade)))
    }
}
