import ActivityKit
import Foundation

/// Live Activities for the adventure timer, the focus timer and breathing exercises
/// (GoobyTimerAttributes, UI in GoobyWidgets/LiveActivity). Local ActivityKit only: no push
/// token, no server. `enabled` mirrors Settings > Preferences > Live Activities.
/// Engine dates are app time (`engine.now()`); ActivityKit needs real device time, so subtract
/// `engine.profile.timeOffset` (see `realDate`).
@MainActor
final class GoobyLiveActivities {
    static let shared = GoobyLiveActivities()

    var enabled = true

    func handle(_ moment: GoobyMoment, engine: GoobyEngine) {
        guard enabled else { return }
        switch moment {
        case .adventureStarted:
            startAdventure(engine)
        case .adventureReturned(let runID), .storyAnswered(let runID, _):
            end(sessionID: runID)
        case .dataReset:
            endAll()
        default:
            break
        }
    }

    /// Ends every Gooby activity (the Settings switch turned off, data erased).
    func endAll() {
        for activity in Activity<GoobyTimerAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// Examples for the in-app preview (ExtrasGallery and the `widgets` screenshot route).
    func previewSamples(_ engine: GoobyEngine) -> [GoobyActivitySample] {
        let start = Date()
        let attributes = GoobyTimerAttributes(
            kind: .adventure,
            sessionID: "preview-adventure",
            language: engine.languageCode,
            goobyName: engine.profile.goobyName,
            fur: engine.pet.furStyle,
            stage: Growth.stage(of: engine.pet)
        )
        let state = GoobyTimerAttributes.ContentState(
            startedAt: start,
            endsAt: start.addingTimeInterval(25 * 60),
            pausedRemaining: nil,
            phase: "running",
            title: adventureTitle(engine),
            detail: engine.catalog.places.first?.name.text(engine.languageCode) ?? ""
        )
        return [GoobyActivitySample(id: attributes.sessionID, attributes: attributes, state: state)]
    }

    func realDate(_ appDate: Date, _ engine: GoobyEngine) -> Date {
        appDate.addingTimeInterval(-engine.profile.timeOffset)
    }

    private func adventureTitle(_ engine: GoobyEngine) -> String {
        engine.txf("extras.activity.adventure", de: "%@ ist auf Abenteuer", en: "%@ is on an adventure", engine.profile.goobyName)
    }

    private func startAdventure(_ engine: GoobyEngine) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled,
              let run = engine.todaysRun(), run.status == "traveling" else { return }
        let id = run.id.uuidString
        guard !Activity<GoobyTimerAttributes>.activities.contains(where: { $0.attributes.sessionID == id }) else { return }
        let attributes = GoobyTimerAttributes(
            kind: .adventure,
            sessionID: id,
            language: engine.languageCode,
            goobyName: engine.profile.goobyName,
            fur: engine.pet.furStyle,
            stage: Growth.stage(of: engine.pet)
        )
        let returns = realDate(run.returnsAt, engine)
        let state = GoobyTimerAttributes.ContentState(
            startedAt: realDate(run.startedAt, engine),
            endsAt: returns,
            pausedRemaining: nil,
            phase: "running",
            title: adventureTitle(engine),
            detail: engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode) ?? ""
        )
        _ = try? Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: returns.addingTimeInterval(3600)), pushType: nil)
    }

    private func end(sessionID: String) {
        for activity in Activity<GoobyTimerAttributes>.activities where activity.attributes.sessionID == sessionID {
            Task { await activity.end(nil, dismissalPolicy: .default) }
        }
    }
}
