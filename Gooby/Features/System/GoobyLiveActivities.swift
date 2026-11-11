import ActivityKit
import Foundation

@MainActor
final class GoobyLiveActivities {
    typealias State = GoobyActivityAttributes.ContentState
    typealias Kind = GoobyActivityAttributes.Kind

    private static let pinKey = "system.goals.pinned"
    private var pushed: [String: State] = [:]

    static var goalsPinned: Bool {
        get { UserDefaults.standard.bool(forKey: pinKey) }
        set { UserDefaults.standard.set(newValue, forKey: pinKey) }
    }

    var enabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    func sync(engine: GoobyEngine, snapshot: GoobyWidgetSnapshot, breath: GoobyBreathRun?) {
        guard enabled else { return }
        syncAdventure(engine, snapshot)
        syncFocus(engine, snapshot)
        syncBreath(engine, snapshot, breath)
        syncGoals(engine, snapshot)
    }

    func endAll(_ kind: Kind) {
        for activity in live(kind) { end(activity, final: nil, linger: 0) }
    }

    private func syncAdventure(_ engine: GoobyEngine, _ snapshot: GoobyWidgetSnapshot) {
        guard let trip = snapshot.trip else {
            endAll(.adventure)
            return
        }
        let name = snapshot.goobyName
        let back = Date() >= trip.returnsAt
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: snapshot.language)
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let content = state(
            snapshot,
            headline: back ? engine.tf("system.live.tripBack", name) : engine.tf("system.live.tripAway", name, trip.placeName),
            detail: back ? engine.t("system.live.tripBackDetail") : engine.tf("system.live.tripReturns", formatter.string(from: trip.returnsAt)),
            start: trip.startedAt,
            end: trip.returnsAt,
            finished: back
        )
        show(.adventure, reference: "trip-\(Int(trip.startedAt.timeIntervalSince1970))", state: content, stale: back ? nil : trip.returnsAt, name: name)
    }

    private func syncFocus(_ engine: GoobyEngine, _ snapshot: GoobyWidgetSnapshot) {
        let name = snapshot.goobyName
        guard let session = engine.currentFocus(), !session.finished, let focus = snapshot.focus else {
            for activity in live(.focus) {
                let stored = engine.all(FocusSession.self).first { $0.id.uuidString == activity.attributes.reference }
                if stored?.rewarded == true {
                    var final = activity.content.state
                    final.headline = engine.t("system.live.focusDone")
                    final.detail = engine.tf("system.live.focusDoneDetail", name)
                    final.pausedRemaining = nil
                    final.pausedProgress = nil
                    final.finished = true
                    end(activity, final: final, linger: 15 * 60)
                } else {
                    end(activity, final: nil, linger: 0)
                }
            }
            return
        }
        let planned = max(1, focus.plannedSeconds)
        let endDate = focus.endsAt ?? Date().addingTimeInterval(Double(focus.remainingSeconds))
        let start = endDate.addingTimeInterval(-Double(planned))
        let paused = focus.endsAt == nil
        let content = state(
            snapshot,
            headline: engine.tf("system.live.focus", name),
            detail: paused ? engine.t("system.live.paused") : engine.tf("system.live.focusMinutes", max(1, planned / 60)),
            start: start,
            end: endDate,
            pausedRemaining: paused ? focus.remainingSeconds : nil,
            pausedProgress: paused ? 1 - Double(focus.remainingSeconds) / Double(planned) : nil
        )
        show(.focus, reference: session.id.uuidString, state: content, stale: paused ? nil : endDate, name: name)
    }

    private func syncBreath(_ engine: GoobyEngine, _ snapshot: GoobyWidgetSnapshot, _ breath: GoobyBreathRun?) {
        guard let breath else {
            endAll(.breath)
            return
        }
        let rhythm = breath.seconds.filter { $0 > 0 }.map(String.init).joined(separator: "–")
        let content = state(
            snapshot,
            headline: engine.tf("system.live.breath", snapshot.goobyName),
            detail: "\(engine.t("breath.\(breath.pattern)")) · \(rhythm)",
            start: breath.start,
            end: breath.start.addingTimeInterval(20 * 60)
        )
        show(.breath, reference: "breath-\(Int(breath.start.timeIntervalSince1970))", state: content, stale: breath.start.addingTimeInterval(20 * 60), name: snapshot.goobyName)
    }

    private func syncGoals(_ engine: GoobyEngine, _ snapshot: GoobyWidgetSnapshot) {
        guard GoobyLiveActivities.goalsPinned else {
            endAll(.goals)
            return
        }
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86_400)
        let next = snapshot.goals.first { !$0.done }
        let detail: String
        if let next {
            detail = engine.tf("system.live.next", next.title)
        } else if snapshot.goals.isEmpty {
            detail = engine.t("system.live.noGoals")
        } else {
            detail = engine.t("system.live.allDone")
        }
        let content = state(
            snapshot,
            headline: engine.t("system.live.goals"),
            detail: detail,
            start: dayStart,
            end: dayEnd,
            finished: !snapshot.goals.isEmpty && next == nil
        )
        show(.goals, reference: "goals-\(snapshot.dayKey)", state: content, stale: dayEnd, name: snapshot.goobyName)
    }

    private func state(_ snapshot: GoobyWidgetSnapshot, headline: String, detail: String, start: Date, end: Date,
                       pausedRemaining: Int? = nil, pausedProgress: Double? = nil, finished: Bool = false) -> State {
        State(
            language: snapshot.language,
            headline: headline,
            detail: detail,
            start: start,
            end: max(end, start.addingTimeInterval(1)),
            pausedRemaining: pausedRemaining,
            pausedProgress: pausedProgress,
            finished: finished,
            goalsDone: snapshot.goalsDone,
            goalsTotal: snapshot.goals.count,
            energy: snapshot.energy,
            energyGoal: max(1, snapshot.energyGoal)
        )
    }

    private func live(_ kind: Kind) -> [Activity<GoobyActivityAttributes>] {
        Activity<GoobyActivityAttributes>.activities.filter { activity in
            activity.attributes.kind == kind && activity.activityState != .ended && activity.activityState != .dismissed
        }
    }

    private func show(_ kind: Kind, reference: String, state: State, stale: Date?, name: String) {
        let existing = live(kind)
        if let current = existing.first(where: { $0.attributes.reference == reference }) {
            for other in existing where other.id != current.id { end(other, final: nil, linger: 0) }
            guard pushed[current.id] != state else { return }
            pushed[current.id] = state
            let content = ActivityContent(state: state, staleDate: stale)
            Task { await current.update(content) }
            return
        }
        for other in existing { end(other, final: nil, linger: 0) }
        let attributes = GoobyActivityAttributes(kind: kind, reference: reference, goobyName: name)
        // Requests fail while the app is in the background; the next foreground sync tries again.
        guard let activity = try? Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: stale), pushType: nil) else { return }
        pushed[activity.id] = state
    }

    private func end(_ activity: Activity<GoobyActivityAttributes>, final: State?, linger: TimeInterval) {
        pushed[activity.id] = nil
        let content = final.map { ActivityContent(state: $0, staleDate: nil) }
        let policy: ActivityUIDismissalPolicy = final == nil ? .immediate : .after(Date().addingTimeInterval(linger))
        Task { await activity.end(content, dismissalPolicy: policy) }
    }
}
