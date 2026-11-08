import Foundation
import UserNotifications

/// Local notifications (masterprompt 26) through UNUserNotificationCenter: permission, applying
/// the plan from `GoobyEngine.notificationPlan()` (GoobyEngine+Notifications.swift), the
/// notification categories with their actions, and what a tap or an action does in the app.
/// Only local notifications: no push token, no server.
@MainActor
enum GoobyAlerts {
    enum Category {
        static let goal = "gooby.goal"
        static let daily = "gooby.daily"
        static let adventure = "gooby.adventure"
        static let event = "gooby.event"
        static let focus = "gooby.focus"
    }

    enum Action {
        /// Checks the goal off (opens Gooby, which celebrates).
        static let done = "gooby.done"
        /// The same notification again in `snoozeMinutes`, without opening the app.
        static let snooze = "gooby.snooze"
        /// "gooby.open.<GoobyLink>" opens that screen.
        static let openPrefix = "gooby.open."
    }

    static let snoozeMinutes = 30
    /// Snoozed and developer test requests survive re-planning (see `survives`).
    static let snoozePrefix = "gooby.snooze."
    static let testPrefix = "gooby.test."

    /// The delegate must live as long as the app: UNUserNotificationCenter holds it weakly.
    private static let delegate = GoobyNotificationDelegate()
    private static weak var planEngine: GoobyEngine?
    private static var queued = false
    private static var applying = false
    private static var again = false
    /// "Done" actions that arrived before the engine existed (cold launch); run after `.booted`.
    private static var pendingDone: [NoticeResponse] = []

    // MARK: Permission

    /// Sets Gooby as the notification delegate. Safe to call more than once; called on `.booted`
    /// and as early as possible at launch so a tap that launched the app is not missed.
    static func installDelegate() {
        let center = UNUserNotificationCenter.current()
        if center.delegate !== delegate { center.delegate = delegate }
    }

    /// Asks iOS for permission. iOS shows its prompt once; afterwards this returns the stored answer.
    static func request() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func status() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func isAllowed(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }

    // MARK: Moments

    /// Every moment from `MomentHub`: returns at once, the work runs in a task afterwards.
    static func handle(_ moment: GoobyMoment, engine: GoobyEngine) {
        switch moment {
        case .booted:
            installDelegate()
            registerCategories(engine)
            ReminderDevTools.register()
            runPendingDone(engine)
        case .languageChanged:
            registerCategories(engine)
        case .goalDone(let habitID, _, _):
            clearDelivered(habitID: habitID)
            replan(engine)
        case .appActive, .appBackground, .goalUndone, .goalSkipped, .adventureReturned,
             .focusStarted, .focusPaused, .focusResumed, .focusStopped, .focusFinished, .dataReset:
            replan(engine)
        default:
            break
        }
    }

    // MARK: Planning

    /// Coalesces re-planning: one run at a time, and one more run if something changed meanwhile.
    /// The plan is built when the run starts, so it always uses the newest state.
    static func replan(_ engine: GoobyEngine) {
        planEngine = engine
        if applying {
            again = true
            return
        }
        guard !queued else { return }
        queued = true
        Task { @MainActor in
            GoobyAlerts.queued = false
            GoobyAlerts.applying = true
            repeat {
                GoobyAlerts.again = false
                guard let engine = GoobyAlerts.planEngine else { break }
                await GoobyAlerts.apply(engine.notificationPlan())
            } while GoobyAlerts.again
            GoobyAlerts.applying = false
        }
    }

    private static func apply(_ plan: GoobyNoticePlan) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().filter { $0.identifier.hasPrefix("gooby.") }
        guard plan.enabled else {
            // All notifications off: nothing stays planned and Notification Center is cleared.
            center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier))
            let delivered = await center.deliveredNotifications().map(\.request.identifier).filter { $0.hasPrefix("gooby.") }
            center.removeDeliveredNotifications(withIdentifiers: delivered)
            return
        }
        guard isAllowed(await status()) else { return }
        center.removePendingNotificationRequests(withIdentifiers: pending.filter { !survives($0, plan) }.map(\.identifier))
        for notice in plan.notices {
            try? await center.add(makeRequest(notice))
        }
    }

    /// Snoozes stay while their goal is still open today (or today's goals are not all done for
    /// the daily reminder); developer tests always stay. Everything else is planned anew.
    private static func survives(_ request: UNNotificationRequest, _ plan: GoobyNoticePlan) -> Bool {
        if request.identifier.hasPrefix(testPrefix) { return true }
        guard request.identifier.hasPrefix(snoozePrefix) else { return false }
        let info = request.content.userInfo
        switch info["kind"] as? String {
        case GoobyNotice.Kind.goal.rawValue:
            return plan.openHabitIDs.contains(info["habitID"] as? String ?? "")
        case GoobyNotice.Kind.daily.rawValue:
            return plan.keepDailySnooze
        default:
            return true
        }
    }

    static func makeRequest(_ notice: GoobyNotice) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = notice.title
        content.body = notice.body
        content.categoryIdentifier = category(for: notice.kind)
        content.threadIdentifier = "gooby.\(notice.kind.rawValue)"
        content.userInfo = ["kind": notice.kind.rawValue, "link": notice.link.rawValue, "habitID": notice.habitID, "day": notice.dayKey]
        content.sound = notice.quiet ? nil : sound
        content.interruptionLevel = notice.quiet ? .passive : .active
        content.relevanceScore = relevance(notice.kind)
        let trigger: UNNotificationTrigger
        if notice.wallClock {
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notice.fireAt)
            trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, notice.fireAt.timeIntervalSinceNow), repeats: false)
        }
        return UNNotificationRequest(identifier: notice.id, content: content, trigger: trigger)
    }

    private static func category(for kind: GoobyNotice.Kind) -> String {
        switch kind {
        case .goal: return Category.goal
        case .daily: return Category.daily
        case .adventure: return Category.adventure
        case .event: return Category.event
        case .focus: return Category.focus
        }
    }

    /// Order in the notification summary: results of the user's own timers first.
    private static func relevance(_ kind: GoobyNotice.Kind) -> Double {
        switch kind {
        case .focus, .adventure: return 0.8
        case .goal: return 0.6
        case .event: return 0.5
        case .daily: return 0.3
        }
    }

    /// Gooby's own chime when the app bundles one (Gooby/Resources/Sounds, rendered with earshot;
    /// iOS plays bundled .caf/.wav/.aiff files up to 30 s), otherwise the iOS default sound.
    static let sound: UNNotificationSound = {
        let name = "sfx-notify"
        for ext in ["caf", "wav", "aiff"] where Bundle.main.url(forResource: name, withExtension: ext) != nil {
            return UNNotificationSound(named: UNNotificationSoundName("\(name).\(ext)"))
        }
        return .default
    }()

    // MARK: Categories

    /// Actions per kind, in the app's language (registered again when the language changes).
    /// "Done" and the open actions bring the app to the front; snoozing works in the background.
    static func registerCategories(_ engine: GoobyEngine) {
        func openAction(_ link: GoobyLink, _ title: String, _ symbol: String) -> UNNotificationAction {
            UNNotificationAction(identifier: Action.openPrefix + link.rawValue, title: title, options: [.foreground], icon: UNNotificationActionIcon(systemImageName: symbol))
        }
        let done = UNNotificationAction(
            identifier: Action.done,
            title: engine.tx("extras.notify.action.done", de: "Erledigt", en: "Done"),
            options: [.foreground],
            icon: UNNotificationActionIcon(systemImageName: "checkmark.circle.fill")
        )
        let snooze = UNNotificationAction(
            identifier: Action.snooze,
            title: engine.tx("extras.notify.action.snooze", de: "In 30 Minuten erinnern", en: "Remind me in 30 minutes"),
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "clock")
        )
        let breath = openAction(.breath, engine.tx("extras.notify.action.breath", de: "Kurz durchatmen", en: "Take a breath"), "wind")
        let story = openAction(.adventure, engine.tx("extras.notify.action.story", de: "Geschichte ansehen", en: "See the story"), "book")
        let focus = openAction(.focus, engine.tx("extras.notify.action.focus", de: "Neue Fokusrunde", en: "New focus round"), "timer")
        let event = openAction(.quests, engine.tx("extras.notify.action.event", de: "Zum Fest", en: "Open the event"), "sparkles")
        // Shown instead of the text when the iPhone hides notification previews (goal titles stay private).
        let hidden = engine.tx("extras.notify.hidden", de: "Gooby hat etwas für dich", en: "Gooby has something for you")
        func makeCategory(_ id: String, _ actions: [UNNotificationAction]) -> UNNotificationCategory {
            UNNotificationCategory(identifier: id, actions: actions, intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: hidden, options: [])
        }
        let categories: Set<UNNotificationCategory> = [
            makeCategory(Category.goal, [done, snooze]),
            makeCategory(Category.daily, [breath, snooze]),
            makeCategory(Category.adventure, [story]),
            makeCategory(Category.event, [event]),
            makeCategory(Category.focus, [focus, breath])
        ]
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }

    // MARK: Responses

    /// A tap or an action on a Gooby notification.
    static func respond(_ response: NoticeResponse) async {
        switch response.action {
        case Action.done:
            GoobyRouter.shared.open(.home)
            if let engine = MomentHub.shared.engine {
                complete(response, engine)
            } else {
                pendingDone.append(response)
            }
        case Action.snooze:
            await snooze(response)
        case let action where action.hasPrefix(Action.openPrefix):
            if let link = GoobyLink(rawValue: String(action.dropFirst(Action.openPrefix.count))) {
                GoobyRouter.shared.open(link)
            }
        case UNNotificationDefaultActionIdentifier:
            GoobyRouter.shared.open(GoobyLink(rawValue: response.link) ?? .home)
        default:
            break
        }
    }

    /// Checks off the goal of a reminder from today. A reminder from another day only opens Home.
    private static func complete(_ response: NoticeResponse, _ engine: GoobyEngine) {
        guard response.dayKey.isEmpty || response.dayKey == engine.dayKey(),
              let habit = engine.habits().first(where: { $0.id.uuidString == response.habitID }),
              !habit.isArchived else { return }
        engine.completeHabit(habit, on: engine.now())
    }

    private static func runPendingDone(_ engine: GoobyEngine) {
        guard !pendingDone.isEmpty else { return }
        let waiting = pendingDone
        pendingDone = []
        // After the moment handler has returned (handlers must not save or emit).
        Task { @MainActor in
            for response in waiting { GoobyAlerts.complete(response, engine) }
        }
    }

    private static func snooze(_ response: NoticeResponse) async {
        let content = UNMutableNotificationContent()
        content.title = response.title
        content.body = response.body
        content.categoryIdentifier = response.category
        content.threadIdentifier = "gooby.\(response.kind)"
        content.userInfo = ["kind": response.kind, "link": response.link, "habitID": response.habitID, "day": response.dayKey]
        content.sound = response.quiet ? nil : sound
        content.interruptionLevel = response.quiet ? .passive : .active
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(snoozeMinutes * 60), repeats: false)
        let target = response.habitID.isEmpty ? response.dayKey : response.habitID
        let request = UNNotificationRequest(identifier: snoozePrefix + "\(response.kind).\(target)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Removes a goal's delivered reminders from Notification Center once it is checked off.
    private static func clearDelivered(habitID: String) {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            let ids = await center.deliveredNotifications()
                .filter { ($0.request.content.userInfo["habitID"] as? String) == habitID }
                .map(\.request.identifier)
            center.removeDeliveredNotifications(withIdentifiers: ids)
        }
    }

    // MARK: Developer menu

    /// Sends a goal or daily reminder in 5 seconds (asks for permission first). False without
    /// permission or without a goal for the goal test.
    static func sendTest(_ kind: GoobyNotice.Kind, engine: GoobyEngine) async -> Bool {
        guard await request(), let notice = engine.sampleNotice(kind) else { return false }
        registerCategories(engine)
        do {
            try await UNUserNotificationCenter.current().add(makeRequest(notice))
            return true
        } catch {
            return false
        }
    }
}

/// The values of a notification response the app needs, read on the delegate's thread.
struct NoticeResponse: Sendable {
    var action: String
    var title: String
    var body: String
    var category: String
    var kind: String
    var link: String
    var habitID: String
    var dayKey: String
    var quiet: Bool

    init(_ response: UNNotificationResponse) {
        let content = response.notification.request.content
        let info = content.userInfo
        action = response.actionIdentifier
        title = content.title
        body = content.body
        category = content.categoryIdentifier
        kind = info["kind"] as? String ?? ""
        link = info["link"] as? String ?? ""
        habitID = info["habitID"] as? String ?? ""
        dayKey = info["day"] as? String ?? ""
        quiet = content.interruptionLevel == .passive
    }
}

/// Shows Gooby's notifications while the app is open and passes taps and actions to GoobyAlerts.
final class GoobyNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Quiet-hours notifications go to Notification Center only, like on the Lock Screen.
        let quiet = notification.request.content.interruptionLevel == .passive
        completionHandler(quiet ? [.list] : [.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let reply = NoticeResponse(response)
        Task { @MainActor in
            await GoobyAlerts.respond(reply)
            completionHandler()
        }
    }
}
