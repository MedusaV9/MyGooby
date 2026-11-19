import SwiftUI
import UserNotifications
import WidgetKit

enum GoobyRoute: Equatable {
    case home, breath, adventure
    case focus(minutes: Int?)
}

@MainActor
@Observable
final class GoobyLinkRouter {
    static let shared = GoobyLinkRouter()
    var pending: GoobyRoute?

    func open(_ url: URL) {
        guard let link = GoobyLink(url: url) else { return }
        switch link {
        case .home, .goals:
            pending = .home
        case .breath:
            pending = .breath
        case .adventure:
            pending = .adventure
        case .focus:
            let minutes = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "minutes" }?.value.flatMap(Int.init)
            pending = .focus(minutes: minutes)
        }
    }

    func consumeStoredRoute() {
        guard let route = GoobySharedStore.takeRoute() else { return }
        switch route.link {
        case GoobyLink.breath.rawValue:
            pending = .breath
        case GoobyLink.adventure.rawValue:
            pending = .adventure
        case GoobyLink.focus.rawValue:
            pending = .focus(minutes: route.minutes)
        default:
            pending = .home
        }
    }
}

struct GoobyBreathRun {
    var pattern: String
    var seconds: [Int]
    var start: Date
}

@MainActor
final class GoobySystem {
    static let shared = GoobySystem()
    static let habitCategory = "gooby.habit"
    static let habitDoneAction = "gooby.habit.done"
    static let focusNoticeID = "goobysys.focus"

    private let notifications = GoobyNotificationDelegate()
    private(set) weak var engine: GoobyEngine?
    private let live = GoobyLiveActivities()
    private var pendingSync: Task<Void, Never>?
    private var breath: GoobyBreathRun?
    private var focusNoticeKey = ""

    func launch() {
        UNUserNotificationCenter.current().delegate = notifications
    }

    func handle(_ engine: GoobyEngine, _ event: ShellEvent) {
        self.engine = engine
        switch event {
        case .booted:
            registerCategories(engine)
            live.endAll(.breath)
            GoobyLinkRouter.shared.consumeStoredRoute()
            applyPending(engine)
            sync(engine)
        case .active:
            registerCategories(engine)
            GoobyLinkRouter.shared.consumeStoredRoute()
            applyPending(engine)
            sync(engine)
        case .background:
            sync(engine)
        case .saved:
            scheduleSync(engine)
        case .breathStarted(let pattern, let seconds):
            breath = GoobyBreathRun(pattern: pattern, seconds: seconds, start: Date())
            sync(engine)
        case .breathStopped:
            breath = nil
            sync(engine)
        }
    }

    var goalsPinned: Bool { GoobyLiveActivities.goalsPinned }

    func pinGoals(_ on: Bool) {
        GoobyLiveActivities.goalsPinned = on
        if let engine { sync(engine) }
    }

    func liveActivitiesEnabled() -> Bool { live.enabled }

    // Siri and notification actions can run before the shell has created its engine.
    func completeGoal(_ habitID: String) -> (title: String, wasDone: Bool)? {
        if let engine, let id = UUID(uuidString: habitID), let habit = engine.habits().first(where: { $0.id == id }), !habit.isArchived {
            let count = engine.habitLog(id, engine.dayKey())?.count ?? 0
            let done = count >= max(1, habit.timesPerDay)
            if !done { engine.completeHabit(habit, on: engine.now()) }
            return (habit.title, done)
        }
        guard let snapshot = GoobySharedStore.loadSnapshot(), snapshot.isCurrentDay,
              let goal = snapshot.goals.first(where: { $0.id == habitID }) else { return nil }
        if goal.done { return (goal.title, true) }
        GoobySharedStore.toggleGoal(habitID)
        WidgetCenter.shared.reloadAllTimelines()
        return (goal.title, false)
    }

    private func scheduleSync(_ engine: GoobyEngine) {
        pendingSync?.cancel()
        pendingSync = Task { @MainActor [weak engine] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled, let engine else { return }
            self.sync(engine)
        }
    }

    private func sync(_ engine: GoobyEngine) {
        pendingSync?.cancel()
        pendingSync = nil
        let snapshot = GoobyWidgetFeed.snapshot(engine)
        var reload = false
        if !snapshot.sameContent(as: GoobySharedStore.loadSnapshot()) {
            GoobySharedStore.saveSnapshot(snapshot)
            reload = true
        }
        if GoobyWidgetFeed.renderPortraitIfNeeded(engine) { reload = true }
        if reload { WidgetCenter.shared.reloadAllTimelines() }
        live.sync(engine: engine, snapshot: snapshot, breath: breath)
        scheduleFocusNotice(engine)
        GoobyGentleReminders.refresh(engine)
    }

    private func applyPending(_ engine: GoobyEngine) {
        let actions = GoobySharedStore.takeActions()
        guard !actions.isEmpty else { return }
        let today = engine.dayKey()
        for action in actions where action.dayKey == today {
            guard let id = UUID(uuidString: action.habitID),
                  let habit = engine.habits().first(where: { $0.id == id }) else { continue }
            let count = engine.habitLog(id, today)?.count ?? 0
            if action.complete {
                if count < max(1, habit.timesPerDay) { engine.completeHabit(habit, on: engine.now()) }
            } else if count > 0 {
                engine.undoHabit(habit, on: engine.now())
            }
        }
        engine.log("system applied \(actions.count) widget actions")
    }

    private func registerCategories(_ engine: GoobyEngine) {
        let done = UNNotificationAction(identifier: GoobySystem.habitDoneAction, title: engine.t("system.notify.done"), options: [])
        let category = UNNotificationCategory(identifier: GoobySystem.habitCategory, actions: [done], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private func scheduleFocusNotice(_ engine: GoobyEngine) {
        var key = ""
        var seconds = 0
        if engine.profile.notificationsEnabled, let session = engine.currentFocus(), !session.finished, session.runningSince != nil {
            seconds = engine.focusRemaining()
            let end = Int(Date().timeIntervalSince1970) + seconds
            key = "\(session.id.uuidString)-\(end / 5)"
        }
        guard key != focusNoticeKey else { return }
        focusNoticeKey = key
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [GoobySystem.focusNoticeID])
        guard !key.isEmpty, seconds > 2 else { return }
        let content = UNMutableNotificationContent()
        content.title = engine.profile.goobyName
        content.body = engine.tf("system.notify.focus", engine.profile.goobyName)
        content.sound = .default
        content.userInfo = ["link": GoobyLink.focus.rawValue]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        center.add(UNNotificationRequest(identifier: GoobySystem.focusNoticeID, content: content, trigger: trigger))
    }
}

final class GoobyNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        let habitID = info["habitID"] as? String
        let link = info["link"] as? String
        let action = response.actionIdentifier
        await MainActor.run {
            if action == GoobySystem.habitDoneAction, let habitID {
                _ = GoobySystem.shared.completeGoal(habitID)
            } else if action == UNNotificationDefaultActionIdentifier {
                if link == GoobyLink.focus.rawValue {
                    GoobyLinkRouter.shared.pending = .focus(minutes: nil)
                } else if link == GoobyLink.adventure.rawValue {
                    GoobyLinkRouter.shared.pending = .adventure
                } else if habitID != nil {
                    GoobyLinkRouter.shared.pending = .home
                }
            }
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
