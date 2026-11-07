import Foundation

// Local notification plans (masterprompt 26), moved here from GoobyEngineDev.swift for the
// notifications extra. `GoobyAlerts` (GoobyAlerts.swift) talks to UNUserNotificationCenter.
extension GoobyEngine {
    func rescheduleNotifications() {
        guard profile.notificationsEnabled else { return }
        let title = profile.goobyName
        var reminders: [ReminderPlan] = []
        for habit in habits() where !habit.isArchived && !habit.isPaused && habit.reminderHour >= 0 {
            reminders.append(ReminderPlan(
                id: habit.id.uuidString,
                title: title,
                body: tf("notify.habit", habit.title),
                hour: habit.reminderHour,
                minute: habit.reminderMinute,
                weekdays: habit.recurrence == "weekdays" || habit.recurrence == "custom" ? habit.weekdays : []
            ))
        }
        var notices: [TimedNotice] = []
        if let run = all(AdventureRun.self).first(where: { $0.status == "traveling" }) {
            let seconds = run.returnsAt.timeIntervalSince(now())
            notices.append(TimedNotice(id: "adventure-\(run.id.uuidString)", title: title, body: t("notify.return"), seconds: seconds))
        }
        let calendar = Calendar.current
        for event in catalog.events {
            guard let fire = nextEventFire(event, calendar: calendar) else { continue }
            let seconds = fire.timeIntervalSince(Date())
            guard seconds > 60, seconds < 21 * 24 * 3600 else { continue }
            notices.append(TimedNotice(id: "event-\(event.id)", title: title, body: tf("notify.event", event.title.text(languageCode)), seconds: seconds))
        }
        Task { await GoobyAlerts.sync(reminders: reminders, notices: notices) }
    }

    private func nextEventFire(_ event: EventDef, calendar: Calendar) -> Date? {
        let bounds = eventBounds(event)
        var parts = calendar.dateComponents([.year, .month, .day], from: bounds.0)
        parts.hour = 10
        parts.minute = 0
        return calendar.date(from: parts)
    }
}
