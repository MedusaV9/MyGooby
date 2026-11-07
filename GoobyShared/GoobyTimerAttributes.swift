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
        /// Real device time of the timer interval (without the developer time offset).
        var startedAt: Date
        var endsAt: Date
        /// Seconds left while paused; nil while the timer runs.
        var pausedRemaining: Int?
        /// "running", "paused" or "done".
        var phase: String
        /// Lines prepared by the app in its language.
        var title: String
        var detail: String
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
    /// A valid range for `Text(timerInterval:)` and `ProgressView(timerInterval:)`, also when
    /// the end lies before the start.
    var interval: ClosedRange<Date> { startedAt...max(startedAt, endsAt) }
}
