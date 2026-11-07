import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

enum GoobyNotificationPlanner {
    static let dailyID = "gooby.events.daily-quests"
    static let eggID = "gooby.events.egg-ready"
    static let startID = "gooby.events.next-start"
    static let endingID = "gooby.events.ending"
    static let testID = "gooby.events.debug-test"
    static let managedIDs = [dailyID, eggID, startID, endingID]

    static func plan(
        save: GoobyEventsSave,
        language: GoobyEventsLanguage,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> [GoobyPlannedNotification] {
        var planned: [GoobyPlannedNotification] = []
        if let daily = dailyReminder(save: save, language: language, now: now, calendar: calendar, libraries: libraries) {
            planned.append(daily)
        }
        if let egg = eggReminder(save: save, language: language, now: now, calendar: calendar, libraries: libraries) {
            planned.append(egg)
        }
        planned.append(contentsOf: eventReminders(language: language, now: now, calendar: calendar, libraries: libraries))
        return planned.filter { $0.fireDate.timeIntervalSince(now) > 1 }
    }

    #if canImport(UserNotifications)
    static func schedule(
        planned: [GoobyPlannedNotification],
        libraries: GoobyEventsLibraries
    ) async -> GoobyNotificationScheduleResult {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        var status = settings.authorizationStatus
        if status == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            status = granted ? .authorized : .denied
        }
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            return GoobyNotificationScheduleResult(
                scheduledIDs: [],
                authorization: "denied",
                messageDE: libraries.text("note.denied", language: .german) + " " + libraries.text("note.usage", language: .german),
                messageEN: libraries.text("note.denied", language: .english) + " " + libraries.text("note.usage", language: .english)
            )
        }
        center.removePendingNotificationRequests(withIdentifiers: managedIDs)
        var scheduled: [String] = []
        for item in planned {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            let request = UNNotificationRequest(identifier: item.id, content: content, trigger: trigger)
            do {
                try await center.add(request)
                scheduled.append(item.id)
            } catch {
                continue
            }
        }
        return GoobyNotificationScheduleResult(
            scheduledIDs: scheduled,
            authorization: status == .provisional ? "provisional" : "authorized",
            messageDE: libraries.format("note.scheduled", language: .german, tokens: ["count": "\(scheduled.count)"]),
            messageEN: libraries.format("note.scheduled", language: .english, tokens: ["count": "\(scheduled.count)"])
        )
    }

    static func scheduleTest(language: GoobyEventsLanguage, libraries: GoobyEventsLibraries) async -> GoobyNotificationScheduleResult {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        var status = settings.authorizationStatus
        if status == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            status = granted ? .authorized : .denied
        }
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            return GoobyNotificationScheduleResult(
                scheduledIDs: [],
                authorization: "denied",
                messageDE: libraries.text("note.denied", language: .german),
                messageEN: libraries.text("note.denied", language: .english)
            )
        }
        let content = UNMutableNotificationContent()
        content.title = libraries.text("note.test.title", language: language)
        content.body = libraries.text("note.test.body", language: language)
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: testID, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            return GoobyNotificationScheduleResult(
                scheduledIDs: [],
                authorization: "failed",
                messageDE: libraries.text("note.usage", language: .german),
                messageEN: libraries.text("note.usage", language: .english)
            )
        }
        return GoobyNotificationScheduleResult(
            scheduledIDs: [testID],
            authorization: "authorized",
            messageDE: libraries.text("note.test.body", language: .german),
            messageEN: libraries.text("note.test.body", language: .english)
        )
    }
    #endif

    private static func dailyReminder(
        save: GoobyEventsSave,
        language: GoobyEventsLanguage,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> GoobyPlannedNotification? {
        let day = GoobyDayKey.make(now, calendar: calendar)
        if let board = save.dailyBoards[day], !board.quests.isEmpty, board.quests.allSatisfy(\.claimed) {
            return nil
        }
        guard let fireDate = nextDate(hour: 18, minute: 0, after: now, calendar: calendar) else {
            return nil
        }
        return GoobyPlannedNotification(
            id: dailyID,
            title: libraries.text("note.daily.title", language: language),
            body: libraries.text("note.daily.body", language: language),
            fireDate: fireDate
        )
    }

    private static func eggReminder(
        save: GoobyEventsSave,
        language: GoobyEventsLanguage,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> GoobyPlannedNotification? {
        let almost = save.eggs.contains { $0.hatchedCompanionID == nil && $0.validDays.count == GoobyCompanionGrowth.requiredEggDays - 1 }
        guard almost, let fireDate = nextDate(hour: 9, minute: 0, after: now, calendar: calendar) else {
            return nil
        }
        return GoobyPlannedNotification(
            id: eggID,
            title: libraries.text("note.egg.title", language: language),
            body: libraries.text("note.egg.body", language: language),
            fireDate: fireDate
        )
    }

    private static func eventReminders(
        language: GoobyEventsLanguage,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> [GoobyPlannedNotification] {
        var planned: [GoobyPlannedNotification] = []
        let entries = GoobyEventCalendar.entries(on: now, calendar: calendar, events: libraries.events)
        if let upcoming = entries.first(where: { $0.phase == "upcoming" && $0.window.start.timeIntervalSince(now) <= 7 * 86_400 }) {
            let name = language == .english ? upcoming.event.nameEN : upcoming.event.nameDE
            if let morning = dateOn(upcoming.window.start, hour: 9, minute: 0, calendar: calendar), morning > now {
                planned.append(
                    GoobyPlannedNotification(
                        id: startID,
                        title: libraries.text("note.start.title", language: language),
                        body: libraries.format("note.start.body", language: language, tokens: ["name": name]),
                        fireDate: morning
                    )
                )
            }
        }
        if let ending = entries.first(where: { entry in
            entry.phase == "active" && entry.window.end.timeIntervalSince(now) <= 3 * 86_400 && entry.window.end > now
        }) {
            let name = language == .english ? ending.event.nameEN : ending.event.nameDE
            if let morning = dateOn(ending.window.end, hour: 10, minute: 0, calendar: calendar), morning > now {
                planned.append(
                    GoobyPlannedNotification(
                        id: endingID,
                        title: libraries.text("note.end.title", language: language),
                        body: libraries.format("note.end.body", language: language, tokens: ["name": name]),
                        fireDate: morning
                    )
                )
            }
        }
        return planned
    }

    private static func nextDate(hour: Int, minute: Int, after now: Date, calendar: Calendar) -> Date? {
        let today = dateOn(now, hour: hour, minute: minute, calendar: calendar)
        if let today, today > now {
            return today
        }
        let tomorrow = GoobyDayKey.adding(days: 1, to: now, calendar: calendar)
        return dateOn(tomorrow, hour: hour, minute: minute, calendar: calendar)
    }

    private static func dateOn(_ date: Date, hour: Int, minute: Int, calendar: Calendar) -> Date? {
        var parts = calendar.dateComponents([.year, .month, .day], from: date)
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        return calendar.date(from: parts)
    }
}
