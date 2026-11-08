import Foundation

// Engine entry points the extras need beyond the existing game logic: breathing sessions (the
// exercise itself runs in BreathingView) and growth stage changes.
extension GoobyEngine {
    /// Start of a breathing exercise. Returns the plan; pass its `sessionID` to `breathEnd`.
    @discardableResult
    func breathBegin(pattern: String, inhale: Int, hold: Int, exhale: Int, hold2: Int) -> BreathPlan {
        let plan = BreathPlan(sessionID: UUID().uuidString, pattern: pattern, inhale: inhale, hold: hold, exhale: exhale, hold2: hold2, startedAt: now())
        emit(.breathStarted(plan))
        return plan
    }

    /// End of a breathing exercise. `completed` (Stop button) rewards finished cycles through
    /// `finishBreath()` as before; leaving the screen while it runs ends it without a reward.
    func breathEnd(sessionID: String, cycles: Int, completed: Bool) {
        if completed && cycles > 0 { finishBreath() }
        emit(.breathEnded(sessionID: sessionID, cycles: cycles, completed: completed))
    }

    /// Emits `.levelUp` when Gooby grew past `before` (a later stage in `Growth.order`).
    func noteGrowth(from before: String) {
        let after = Growth.stage(of: pet)
        let old = Growth.order.firstIndex(of: before) ?? 0
        let new = Growth.order.firstIndex(of: after) ?? 0
        if new > old { emit(.levelUp(stage: after)) }
    }
}
