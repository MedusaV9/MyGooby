import ActivityKit
import Foundation

/// Live Activities for the adventure timer, the focus timer and breathing exercises
/// (GoobyTimerAttributes; UI in GoobyShared/LiveActivityViews, shown by
/// GoobyWidgets/LiveActivity/GoobyTimerLiveActivity.swift). Local ActivityKit only: no push
/// token, no server; every start, update and end comes from a GoobyMoment in the running app.
/// `enabled` mirrors Settings > Preferences > Live Activities.
///
/// - Adventure: starts with the adventure and counts down to the return. When Gooby is back it
///   shows "Gooby is back! · New story" until the story is read, then it goes away.
/// - Focus: starts with the timer, stands still while paused, goes away when stopped, and shows
///   the reward for 15 minutes when the round is done.
/// - Breathing: starts with the exercise and counts the time up. Stop shows the cycles for
///   5 minutes; leaving the screen while it runs ends it at once.
/// A timer that runs out while the app is closed turns to its done look through the stale date;
/// the next launch or return to the app brings every activity in line with the save (`refresh`).
///
/// Engine dates are app time (`engine.now()`); ActivityKit needs real device time, so
/// `realDate` removes the developer time offset (`engine.profile.timeOffset`).
@MainActor
final class GoobyLiveActivities {
    static let shared = GoobyLiveActivities()

    private typealias Item = Activity<GoobyTimerAttributes>
    private typealias State = GoobyTimerAttributes.ContentState
    private typealias Kind = GoobyTimerAttributes.Kind

    /// Breathing has no planned end; after this long the activity counts as stale.
    private static let breathWindow: TimeInterval = 60 * 60
    /// How long a finished focus round or breathing exercise stays on the Lock Screen.
    private static let focusDoneStay: TimeInterval = 15 * 60
    private static let breathDoneStay: TimeInterval = 5 * 60
    /// Which activity the Dynamic Island prefers when several run: the exercise the user is
    /// doing right now before the adventure that runs on its own.
    private static let relevance: [Kind: Double] = [.breath: 100, .focus: 80, .adventure: 50]

    /// Settings > Preferences > Live Activities. Switching it on shows the timers that run right
    /// now; switching it off ends them (`GoobyEngine.setLiveActivities` calls `endAll`).
    var enabled = true {
        didSet {
            guard enabled != oldValue, enabled, let engine = MomentHub.shared.engine else { return }
            startRunning([.adventure, .focus, .breath], engine)
        }
    }

    /// The breathing exercise that runs in BreathingView right now (breathStarted to breathEnded).
    private var breath: BreathPlan?

    func handle(_ moment: GoobyMoment, engine: GoobyEngine) {
        switch moment {
        case .breathStarted(let plan):
            breath = plan
        case .breathEnded:
            breath = nil
        case .dataReset:
            endAll()
            return
        default:
            break
        }
        guard enabled else { return }
        switch moment {
        case .booted, .appActive:
            refresh(engine)
        case .languageChanged:
            restart(engine)
        case .adventureStarted(let runID):
            if let run = adventureRun(runID, engine) { startAdventure(run, engine) }
        case .adventureReturned(let runID):
            if let run = adventureRun(runID, engine) { finishAdventure(run, engine) }
        case .storyAnswered(let runID, _):
            end(sessionID: runID)
        case .focusStarted(let sessionID):
            // focusStart replaces an unfinished session without a moment of its own.
            endOthers(.focus, keeping: sessionID)
            if let session = focusSession(sessionID, engine) { startFocus(session, engine) }
        case .focusPaused(let sessionID), .focusResumed(let sessionID):
            if let session = focusSession(sessionID, engine) { updateFocus(session, engine) }
        case .focusStopped(let sessionID):
            end(sessionID: sessionID)
        case .focusFinished(let sessionID, let minutes):
            finishFocus(sessionID: sessionID, minutes: minutes, engine)
        case .breathStarted(let plan):
            endOthers(.breath, keeping: plan.sessionID)
            startBreath(plan, engine)
        case .breathEnded(let sessionID, let cycles, let completed):
            finishBreath(sessionID: sessionID, cycles: cycles, completed: completed, engine)
        default:
            break
        }
    }

    /// Ends every Gooby activity at once (the Settings switch turned off, data erased).
    func endAll() {
        for activity in Item.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// One example per kind for the in-app preview (ExtrasGallery and the `widgets` screenshot
    /// route): the real adventure and focus timer while they run, else typical values.
    func previewSamples(_ engine: GoobyEngine) -> [GoobyActivitySample] {
        let now = Date()
        var samples: [GoobyActivitySample] = []

        let adventure: State
        if let run = travelingRun(engine) {
            adventure = adventureState(run, engine)
        } else {
            let place = engine.catalog.places.first(where: { engine.isPlaceUnlocked($0.id) }) ?? engine.catalog.places.first
            adventure = adventureState(
                placeName: place?.name.text(engine.languageCode) ?? "",
                startedAt: now.addingTimeInterval(-18 * 60),
                endsAt: now.addingTimeInterval(17 * 60),
                appReturn: engine.now().addingTimeInterval(17 * 60),
                engine
            )
        }
        samples.append(GoobyActivitySample(id: "preview-adventure", attributes: attributes(.adventure, "preview-adventure", engine), state: adventure))

        let focus: State
        if let session = engine.currentFocus(), !session.finished {
            focus = focusState(session, engine)
        } else {
            let ends = now.addingTimeInterval(15 * 60)
            focus = runningFocusState(endsAt: ends, planned: 25 * 60, engine)
        }
        samples.append(GoobyActivitySample(id: "preview-focus", attributes: attributes(.focus, "preview-focus", engine), state: focus))

        let plan = breath ?? BreathPlan(sessionID: "preview-breath", pattern: "box", inhale: 4, hold: 4, exhale: 4, hold2: 4, startedAt: engine.now().addingTimeInterval(-96))
        samples.append(GoobyActivitySample(id: "preview-breath", attributes: breathAttributes(plan, id: "preview-breath", engine), state: breathState(plan, engine)))
        return samples
    }

    func realDate(_ appDate: Date, _ engine: GoobyEngine) -> Date {
        appDate.addingTimeInterval(-engine.profile.timeOffset)
    }

    // MARK: - Adventure

    private func startAdventure(_ run: AdventureRun, _ engine: GoobyEngine) {
        let id = run.id.uuidString
        guard run.status == "traveling", live(id).isEmpty else { return }
        request(attributes(.adventure, id, engine), adventureState(run, engine), stale: realDate(run.returnsAt, engine), engine)
    }

    /// Gooby is back: the done look stays until the story is read (`storyAnswered`) or iOS
    /// removes it.
    private func finishAdventure(_ run: AdventureRun, _ engine: GoobyEngine) {
        let state = State(
            startedAt: realDate(run.startedAt, engine),
            endsAt: realDate(run.returnsAt, engine),
            pausedRemaining: nil,
            phase: State.done,
            title: engine.txf("home.adventure.returned", de: "%@ ist zurück!", en: "%@ is back!", name(engine)),
            detail: placeName(run, engine),
            note: engine.tx("home.adventure.story", de: "Neue Geschichte", en: "New story")
        )
        for activity in live(run.id.uuidString) {
            Task { await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .default) }
        }
    }

    private func adventureState(_ run: AdventureRun, _ engine: GoobyEngine) -> State {
        adventureState(
            placeName: placeName(run, engine),
            startedAt: realDate(run.startedAt, engine),
            endsAt: realDate(run.returnsAt, engine),
            appReturn: run.returnsAt,
            engine
        )
    }

    /// "Gooby is on an adventure", the place and "back at 01:41" like the Home adventure card
    /// (the clock in app time, like Home).
    private func adventureState(placeName: String, startedAt: Date, endsAt: Date, appReturn: Date, _ engine: GoobyEngine) -> State {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let time = formatter.string(from: appReturn)
        let note = Calendar.current.isDate(appReturn, inSameDayAs: engine.now())
            ? engine.txf("home.adventure.backAt", de: "zurück um %@", en: "back at %@", time)
            : engine.txf("home.adventure.backTomorrow", de: "zurück morgen um %@", en: "back tomorrow at %@", time)
        return State(
            startedAt: startedAt,
            endsAt: endsAt,
            pausedRemaining: nil,
            phase: State.running,
            title: engine.txf("extras.activity.adventure", de: "%@ ist auf Abenteuer", en: "%@ is on an adventure", name(engine)),
            detail: placeName,
            note: note
        )
    }

    private func adventureRun(_ id: String, _ engine: GoobyEngine) -> AdventureRun? {
        engine.all(AdventureRun.self).first { $0.id.uuidString == id }
    }

    private func travelingRun(_ engine: GoobyEngine) -> AdventureRun? {
        engine.all(AdventureRun.self).first { $0.status == "traveling" && engine.now() < $0.returnsAt }
    }

    private func placeName(_ run: AdventureRun, _ engine: GoobyEngine) -> String {
        engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode) ?? ""
    }

    // MARK: - Focus

    private func startFocus(_ session: FocusSession, _ engine: GoobyEngine) {
        let id = session.id.uuidString
        guard !session.finished, live(id).isEmpty else { return }
        let state = focusState(session, engine)
        request(attributes(.focus, id, engine), state, stale: state.pausedRemaining == nil ? state.endsAt : nil, engine)
    }

    /// Pause and resume. An activity the user removed stays removed.
    private func updateFocus(_ session: FocusSession, _ engine: GoobyEngine) {
        guard !session.finished else { return }
        let state = focusState(session, engine)
        for activity in live(session.id.uuidString) {
            update(activity, state, stale: state.pausedRemaining == nil ? state.endsAt : nil)
        }
    }

    /// The round is done (reconcileFocus): the reward from the ledger, shown for 15 minutes.
    private func finishFocus(sessionID: String, minutes: Int, _ engine: GoobyEngine) {
        let targets = live(sessionID)
        guard !targets.isEmpty else { return }
        let detail: String
        if let row = engine.all(RewardLedger.self).first(where: { $0.key == "focus:\(sessionID)" }) {
            detail = engine.txf("extras.activity.focusReward", de: "+%d Sternenfunken · +%d Energie", en: "+%d star sparks · +%d energy", row.sparks, row.energy)
        } else {
            detail = engine.tf("focus.minutes", max(1, minutes))
        }
        let ends = Date()
        let state = State(
            startedAt: ends.addingTimeInterval(-Double(max(1, minutes) * 60)),
            endsAt: ends,
            pausedRemaining: nil,
            phase: State.done,
            title: engine.tx("extras.activity.focusDone", de: "Fokus geschafft!", en: "Focus done!"),
            detail: detail
        )
        for activity in targets {
            Task { await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .after(ends.addingTimeInterval(Self.focusDoneStay))) }
        }
    }

    /// Running: `endsAt` from the save (real time), `startedAt` the planned length before it, so
    /// the bar shows the planned share that is done. Paused: the clock stands at the rest.
    private func focusState(_ session: FocusSession, _ engine: GoobyEngine) -> State {
        let planned = max(60, session.plannedSeconds)
        if let since = session.runningSince {
            let ends = realDate(since, engine).addingTimeInterval(Double(planned) - session.accumulated)
            return runningFocusState(endsAt: ends, planned: planned, engine)
        }
        let left = max(0, planned - Int(session.accumulated))
        let ends = Date().addingTimeInterval(Double(left))
        return State(
            startedAt: ends.addingTimeInterval(-Double(planned)),
            endsAt: ends,
            pausedRemaining: left,
            phase: State.paused,
            title: engine.tx("extras.activity.focusPaused", de: "Fokus pausiert", en: "Focus paused"),
            detail: engine.txf("extras.activity.focusWaiting", de: "%@ wartet auf dich", en: "%@ is waiting for you", name(engine)),
            note: engine.tf("focus.minutes", planned / 60)
        )
    }

    private func runningFocusState(endsAt: Date, planned: Int, _ engine: GoobyEngine) -> State {
        State(
            startedAt: endsAt.addingTimeInterval(-Double(planned)),
            endsAt: endsAt,
            pausedRemaining: nil,
            phase: State.running,
            title: engine.t("focus.title"),
            detail: engine.txf("extras.activity.focusWith", de: "%@ konzentriert sich mit dir", en: "%@ is focusing with you", name(engine)),
            note: engine.tf("focus.minutes", planned / 60)
        )
    }

    private func focusSession(_ id: String, _ engine: GoobyEngine) -> FocusSession? {
        engine.all(FocusSession.self).first { $0.id.uuidString == id }
    }

    // MARK: - Breathing

    private func startBreath(_ plan: BreathPlan, _ engine: GoobyEngine) {
        guard live(plan.sessionID).isEmpty else { return }
        let state = breathState(plan, engine)
        request(breathAttributes(plan, id: plan.sessionID, engine), state, stale: state.endsAt, engine)
    }

    /// Stop with finished cycles: "Nicely breathed! · Cycles: 4" for 5 minutes. Stop without a
    /// cycle or leaving the screen: gone at once.
    private func finishBreath(sessionID: String, cycles: Int, completed: Bool, _ engine: GoobyEngine) {
        let targets = live(sessionID)
        guard completed, cycles > 0 else {
            end(sessionID: sessionID)
            return
        }
        let ends = Date()
        let state = State(
            startedAt: targets.first?.content.state.startedAt ?? ends,
            endsAt: ends,
            pausedRemaining: nil,
            phase: State.done,
            title: engine.tx("extras.activity.breathDone", de: "Schön geatmet!", en: "Nicely breathed!"),
            detail: engine.tf("breath.cycles", cycles),
            countsUp: true
        )
        for activity in targets {
            Task { await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .after(ends.addingTimeInterval(Self.breathDoneStay))) }
        }
    }

    private func breathState(_ plan: BreathPlan, _ engine: GoobyEngine) -> State {
        let start = realDate(plan.startedAt, engine)
        return State(
            startedAt: start,
            endsAt: start.addingTimeInterval(Self.breathWindow),
            pausedRemaining: nil,
            phase: State.running,
            title: engine.t("breath.\(plan.pattern)"),
            detail: engine.txf("extras.activity.breathWith", de: "Atme ruhig mit %@", en: "Breathe calmly with %@", name(engine)),
            countsUp: true
        )
    }

    private func breathAttributes(_ plan: BreathPlan, id: String, _ engine: GoobyEngine) -> GoobyTimerAttributes {
        var made = attributes(.breath, id, engine)
        made.breathSteps = [plan.inhale, plan.hold, plan.exhale, plan.hold2]
        return made
    }

    // MARK: - Keeping in line with the save

    /// At launch and on return to the app: running timers get fresh content, finished ones their
    /// done look, gone ones (story read, timer stopped or replaced, data erased, breathing screen
    /// gone with the last launch) are removed. Never starts activities the user removed.
    private func refresh(_ engine: GoobyEngine) {
        for activity in Item.activities {
            let id = activity.attributes.sessionID
            let running = isLive(activity)
            switch activity.attributes.kind {
            case .adventure:
                guard let run = adventureRun(id, engine), run.status != "claimed" else {
                    dismiss(activity)
                    continue
                }
                guard running else { continue }
                if run.status == "traveling" {
                    update(activity, adventureState(run, engine), stale: realDate(run.returnsAt, engine))
                } else {
                    finishAdventure(run, engine)
                }
            case .focus:
                guard let session = focusSession(id, engine), !(session.finished && !session.rewarded) else {
                    dismiss(activity)
                    continue
                }
                guard running else { continue }
                if session.finished {
                    finishFocus(sessionID: id, minutes: max(1, session.plannedSeconds / 60), engine)
                } else {
                    updateFocus(session, engine)
                }
            case .breath:
                if running && breath?.sessionID != id { dismiss(activity) }
            }
        }
    }

    /// New language: the running activities start again with the new language (their labels
    /// and the attributes' language are fixed per activity).
    private func restart(_ engine: GoobyEngine) {
        let running = Item.activities.filter { isLive($0) }
        guard !running.isEmpty else { return }
        let kinds = Set(running.map { $0.attributes.kind })
        Task { @MainActor in
            for activity in running {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.startRunning(kinds, engine)
        }
    }

    private func startRunning(_ kinds: Set<Kind>, _ engine: GoobyEngine) {
        if kinds.contains(.adventure), let run = travelingRun(engine) {
            startAdventure(run, engine)
        }
        if kinds.contains(.focus), let session = engine.currentFocus(), !session.finished {
            startFocus(session, engine)
        }
        if kinds.contains(.breath), let plan = breath {
            startBreath(plan, engine)
        }
    }

    // MARK: - ActivityKit

    private func attributes(_ kind: Kind, _ id: String, _ engine: GoobyEngine) -> GoobyTimerAttributes {
        GoobyTimerAttributes(
            kind: kind,
            sessionID: id,
            language: engine.languageCode,
            goobyName: name(engine),
            fur: engine.pet.furStyle,
            stage: Growth.stage(of: engine.pet)
        )
    }

    private func name(_ engine: GoobyEngine) -> String {
        engine.profile.goobyName.isEmpty ? "Gooby" : engine.profile.goobyName
    }

    private func request(_ attributes: GoobyTimerAttributes, _ state: State, stale: Date?, _ engine: GoobyEngine) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = ActivityContent(state: state, staleDate: stale, relevanceScore: Self.relevance[attributes.kind] ?? 0)
        do {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            engine.log("live activity \(attributes.kind.rawValue): \(error.localizedDescription)")
        }
    }

    /// Skips updates that change nothing visible (dates within a second).
    private func update(_ activity: Item, _ state: State, stale: Date?) {
        let current = activity.content
        if same(current.state, state) && close(current.staleDate, stale) { return }
        let content = ActivityContent(state: state, staleDate: stale, relevanceScore: Self.relevance[activity.attributes.kind] ?? 0)
        Task { await activity.update(content) }
    }

    private func same(_ a: State, _ b: State) -> Bool {
        a.phase == b.phase && a.pausedRemaining == b.pausedRemaining && a.title == b.title && a.detail == b.detail
            && a.note == b.note && a.countsUp == b.countsUp && close(a.startedAt, b.startedAt) && close(a.endsAt, b.endsAt)
    }

    private func close(_ a: Date?, _ b: Date?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (a?, b?): return abs(a.timeIntervalSince(b)) < 1
        default: return false
        }
    }

    private func isLive(_ activity: Item) -> Bool {
        activity.activityState == .active || activity.activityState == .stale
    }

    /// Activities of a session that still run (not ended, not removed).
    private func live(_ sessionID: String) -> [Item] {
        Item.activities.filter { $0.attributes.sessionID == sessionID && isLive($0) }
    }

    /// Ends the activities of a session at once (also removes a done look from the Lock Screen).
    private func end(sessionID: String) {
        for activity in Item.activities where activity.attributes.sessionID == sessionID {
            dismiss(activity)
        }
    }

    private func endOthers(_ kind: Kind, keeping sessionID: String) {
        for activity in Item.activities where activity.attributes.kind == kind && activity.attributes.sessionID != sessionID {
            dismiss(activity)
        }
    }

    private func dismiss(_ activity: Item) {
        guard activity.activityState != .dismissed else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
