import SwiftUI

/// Picks the celebration layer that plays a burst: the newest one on screen. MainTabs has one and
/// every sheet or cover that can hand out rewards adds its own, so a burst never plays hidden
/// behind a sheet.
@MainActor
@Observable
final class CelebrationStage {
    static let shared = CelebrationStage()

    @ObservationIgnored private var layers: [UUID] = []
    /// Bursts asked for by a screen (a purchase, a departure) rather than by `engine.celebration`.
    private(set) var request = 0
    @ObservationIgnored private(set) var requestStyle: CelebrationStyle = .sparkle

    func enter(_ id: UUID) {
        layers.removeAll { $0 == id }
        layers.append(id)
    }

    func leave(_ id: UUID) {
        layers.removeAll { $0 == id }
    }

    func isTop(_ id: UUID) -> Bool { layers.last == id }

    /// Plays `style` on the top layer.
    func play(_ style: CelebrationStyle) {
        requestStyle = style
        request += 1
    }
}

/// Reward particles over a screen. Every `engine.celebration` bump plays a burst whose style
/// follows the moment: confetti when the growth stage changes, the last goal of the day is
/// checked, an adventure story is answered or an egg hatches; hearts for a friend's visit;
/// sparkles otherwise. Nothing runs with reduced motion.
private struct GoobyCelebrationLayer: ViewModifier {
    var engine: GoobyEngine
    @Environment(\.goobyReduceMotion) private var appReduce
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var id = UUID()
    @State private var token = 0
    @State private var style: CelebrationStyle = .sparkle
    @State private var stage = ""
    @State private var allDone = false

    func body(content: Content) -> some View {
        let reduce = appReduce || systemReduce || engine.reduceMotion
        content
            .overlay {
                SparkleOverlay(token: token, enabled: !reduce, style: style)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .onAppear {
                CelebrationStage.shared.enter(id)
                stage = Growth.stage(of: engine.pet)
                allDone = GoobyCelebrationLayer.allGoalsDone(engine)
            }
            .onDisappear { CelebrationStage.shared.leave(id) }
            .onChange(of: engine.celebration) { _, _ in
                fire(nextStyle())
            }
            .onChange(of: CelebrationStage.shared.request) { _, _ in
                fire(CelebrationStage.shared.requestStyle)
            }
    }

    /// Style of the burst for the celebration that just happened; every layer keeps its memory
    /// of the stage and the goals current, also when another layer plays.
    private func nextStyle() -> CelebrationStyle {
        let newStage = Growth.stage(of: engine.pet)
        let done = GoobyCelebrationLayer.allGoalsDone(engine)
        defer {
            stage = newStage
            allDone = done
        }
        if !stage.isEmpty && newStage != stage { return .confetti }
        if done && !allDone { return .confetti }
        switch engine.animation {
        case .arrive, .play: return .confetti
        case .hearts, .petting: return .hearts
        default: return .sparkle
        }
    }

    private func fire(_ next: CelebrationStyle) {
        guard CelebrationStage.shared.isTop(id) else { return }
        style = next
        token += 1
    }

    static func allGoalsDone(_ engine: GoobyEngine) -> Bool {
        let progress = engine.todayProgress()
        return progress.total > 0 && progress.done >= progress.total
    }
}

extension View {
    /// Reward particles for this screen: MainTabs and the root of every sheet or cover where
    /// rewards can happen (apply it outside the sheet's NavigationStack).
    func goobyCelebrations(_ engine: GoobyEngine) -> some View {
        modifier(GoobyCelebrationLayer(engine: engine))
    }
}
