import Foundation
import UserNotifications

struct ReminderPlan: Sendable {
    var id: String
    var title: String
    var body: String
    var hour: Int
    var minute: Int
    var weekdays: [Int]
}

struct TimedNotice: Sendable {
    var id: String
    var title: String
    var body: String
    var seconds: TimeInterval
}

@MainActor
enum GoobyAlerts {
    static func request() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func status() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func sync(reminders: [ReminderPlan], notices: [TimedNotice]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional || settings.authorizationStatus == .ephemeral else { return }
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix("gooby.") })
        var budget = 48
        for reminder in reminders where budget > 0 {
            let days = reminder.weekdays.isEmpty ? [0] : reminder.weekdays
            for weekday in days where budget > 0 {
                var components = DateComponents()
                components.hour = reminder.hour
                components.minute = reminder.minute
                if weekday != 0 { components.weekday = weekday }
                let content = UNMutableNotificationContent()
                content.title = reminder.title
                content.body = reminder.body
                content.sound = GoobyFeedback.shared.notificationSound
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let suffix = weekday == 0 ? "daily" : "d\(weekday)"
                let request = UNNotificationRequest(identifier: "gooby.habit.\(reminder.id).\(suffix)", content: content, trigger: trigger)
                try? await center.add(request)
                budget -= 1
            }
        }
        for notice in notices where budget > 0 && notice.seconds >= 2 {
            let content = UNMutableNotificationContent()
            content.title = notice.title
            content.body = notice.body
            content.sound = GoobyFeedback.shared.notificationSound
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: notice.seconds, repeats: false)
            let request = UNNotificationRequest(identifier: "gooby.notice.\(notice.id)", content: content, trigger: trigger)
            try? await center.add(request)
            budget -= 1
        }
    }
}
