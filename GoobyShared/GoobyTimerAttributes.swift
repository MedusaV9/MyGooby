import ActivityKit
import Foundation

/// Live Activity of Gooby's timed systems: adventure timer, focus timer and breathing exercise
/// (masterprompt 13 and 20). One attributes type with a `kind`, so the widget extension needs a
/// single ActivityConfiguration. The app starts, updates and ends the activities locally through
/// ActivityKit (GoobyLiveActivities); there is no push token and no server.
struct GoobyTimerAttributes: ActivityAttributes {
    enum Kind: String, Codable, Hashable, Sendable {
        case adventure, focus, breath
    }

    struct ContentState: Codable, Hashable, Sendable {
        /// Real device time of the timer interval (without the developer time offset). For the
        /// focus timer `startedAt` is `endsAt` minus the planned length, so the bar shows the
        /// share of the planned time that is done, also after a pause.
        var startedAt: Date
        var endsAt: Date
        /// Seconds left while paused; nil while the timer runs.
        var pausedRemaining: Int?
        /// "running", "paused" or "done".
        var phase: String
        /// Lines prepared by the app in its language.
        var title: String
        var detail: String
        /// Short extra line: the adventure's return time ("back at 01:41"), the planned focus
        /// length, the reward when done. Empty when there is none.
        var note: String = ""
        /// True for breathing: the timer counts the time up from `startedAt`. The adventure and
        /// focus timers count down to `endsAt`.
        var countsUp: Bool = false
    }

    var kind: Kind
    /// AdventureRun or FocusSession id, or a fresh id for a breathing session.
    var sessionID: String
    /// "de" or "en".
    var language: String
    var goobyName: String
    /// Fur style and growth stage for `GoobyMiniHead`.
    var fur: String
    var stage: String
    /// Breathing only: seconds of breathing in, holding, breathing out and resting per cycle.
    var breathSteps: [Int] = []
}

extension GoobyTimerAttributes.Kind {
    /// Screen a tap on the activity opens.
    var link: GoobyLink {
        switch self {
        case .adventure: return .adventure
        case .focus: return .focus
        case .breath: return .breath
        }
    }
}

extension GoobyTimerAttributes.ContentState {
    static let running = "running"
    static let paused = "paused"
    static let done = "done"

    /// A valid range for `Text(timerInterval:)` and `ProgressView(timerInterval:)`, also when
    /// the end lies before the start.
    var interval: ClosedRange<Date> { startedAt...max(startedAt, endsAt) }

    /// Length of the timer in seconds (at least 1).
    var length: TimeInterval { max(1, endsAt.timeIntervalSince(startedAt)) }

    /// Share of the timer that is done: from the paused rest while paused, else at `date`.
    func fraction(at date: Date = Date()) -> Double {
        if phase == Self.done { return 1 }
        if let left = pausedRemaining {
            return min(1, max(0, 1 - Double(left) / length))
        }
        return min(1, max(0, date.timeIntervalSince(startedAt) / length))
    }
}
