import Foundation

// Local notifications (masterprompt 26): what Gooby sends in the next days, the reminder
// preferences and the permission flow. `GoobyAlerts` (GoobyAlerts.swift) hands the plan to
// UNUserNotificationCenter. Only local notifications, no push service, no server.
//
// Everything is planned as one-shot notifications for the next 7 days and planned again on every
// launch, every time the app becomes active or goes to the background, and after every change
// that matters (goals, adventures, focus timer, pause mode, language, preferences). One-shots let
// Gooby skip a goal that is already done today, follow every repeat rule (monthly, every X days,
// custom) and keep quiet hours, which repeating triggers cannot.

/// One planned local notification. `fireAt` is real device time (the developer time offset is
/// removed), so notifications arrive when the iPhone's clock says so.
struct GoobyNotice: Equatable, Sendable {
    enum Kind: String, Sendable {
        case goal, daily, adventure, event, focus
    }

    /// Request identifier, always "gooby.<kind>.<...>".
    var id: String
    var kind: Kind
    var title: String
    var body: String
    var fireAt: Date
    /// Wall-clock time (calendar trigger, follows time zone changes) or a countdown (interval).
    var wallClock: Bool
    /// Inside quiet hours: delivered without sound and without lighting up the screen.
    var quiet: Bool
    var link: GoobyLink
    var habitID: String = ""
    /// App day the notification belongs to (goal and daily reminders).
    var dayKey: String = ""
}

/// The complete plan `GoobyAlerts` applies. Disabled removes everything pending and delivered.
struct GoobyNoticePlan: Sendable {
    var enabled: Bool
    var notices: [GoobyNotice]
    /// Goals due today and still open: snoozed reminders of other goals are dropped.
    var openHabitIDs: Set<String>
    /// A snoozed daily reminder stays only while the daily reminder is on and today is not done.
    var keepDailySnooze: Bool

    static let off = GoobyNoticePlan(enabled: false, notices: [], openHabitIDs: [], keepDailySnooze: false)
}

/// Reminder preferences, stored as `pref.<name>=<value>` ledger rows (GoobyPrefs.swift), so they
/// are exported, imported and erased with the save.
enum NotifyPref {
    /// Daily reminder on/off (default on) and its time "HH:MM" (default 18:00).
    static let daily = "notify.daily"
    static let dailyAt = "notify.dailyAt"
    /// Goal reminders, adventure finished, event start, focus timer finished (default on).
    static let goals = "notify.goals"
    static let adventure = "notify.adventure"
    static let events = "notify.events"
    static let focus = "notify.focus"
    /// Quiet hours on/off (default on), from and to "HH:MM" (default 22:00 to 07:00).
    static let quiet = "notify.quiet"
    static let quietFrom = "notify.quietFrom"
    static let quietTo = "notify.quietTo"

    static let dailyDefault = 18 * 60
    static let quietFromDefault = 22 * 60
    static let quietToDefault = 7 * 60

    /// Minutes after midnight from "HH:MM".
    static func minutes(_ text: String?, default fallback: Int) -> Int {
        guard let text else { return fallback }
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2, (0..<24).contains(parts[0]), (0..<60).contains(parts[1]) else { return fallback }
        return parts[0] * 60 + parts[1]
    }

    static func text(_ minutes: Int) -> String {
        let value = ((minutes % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}

/// Quiet hours as minutes after midnight; `from > to` runs over midnight.
struct QuietHours: Sendable {
    var from: Int
    var to: Int

    func contains(_ date: Date, calendar: Calendar) -> Bool {
        guard from != to else { return false }
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        return from < to ? (minute >= from && minute < to) : (minute >= from || minute < to)
    }

    /// The first moment after `date` when the quiet hours are over.
    func end(after date: Date, calendar: Calendar) -> Date {
        let parts = DateComponents(hour: to / 60, minute: to % 60, second: 0)
        return calendar.nextDate(after: date, matching: parts, matchingPolicy: .nextTime) ?? date
    }
}

extension GoobyEngine {
    /// Days planned ahead, and the most requests Gooby keeps pending (iOS allows 64 per app; the
    /// rest is left for snoozed and test notifications).
    static let noticeHorizonDays = 7
    static let noticeBudget = 58

    // MARK: Preferences

    func notifyOn(_ name: String) -> Bool { prefFlag(name, default: true) }

    func setNotify(_ name: String, _ on: Bool) {
        setPrefFlag(name, on)
        rescheduleNotifications()
    }

    func notifyMinutes(_ name: String) -> Int {
        let fallback: Int
        switch name {
        case NotifyPref.quietFrom: fallback = NotifyPref.quietFromDefault
        case NotifyPref.quietTo: fallback = NotifyPref.quietToDefault
        default: fallback = NotifyPref.dailyDefault
        }
        return NotifyPref.minutes(prefValue(name), default: fallback)
    }

    func setNotifyMinutes(_ name: String, _ minutes: Int) {
        setPrefValue(name, NotifyPref.text(minutes))
        rescheduleNotifications()
    }

    var quietHours: QuietHours? {
        guard notifyOn(NotifyPref.quiet) else { return nil }
        return QuietHours(from: notifyMinutes(NotifyPref.quietFrom), to: notifyMinutes(NotifyPref.quietTo))
    }

    // MARK: Permission

    /// Turns all notifications on and asks iOS for permission (iOS shows its prompt only once).
    /// Returns false when iOS says no; the switch is then off again.
    @discardableResult
    func enableNotifications() async -> Bool {
        profile.notificationsEnabled = true
        save()
        let granted = await GoobyAlerts.request()
        if !granted {
            profile.notificationsEnabled = false
            save()
        }
        rescheduleNotifications()
        return granted
    }

    /// "All notifications off": removes everything pending and delivered.
    func disableNotifications() {
        profile.notificationsEnabled = false
        save()
        rescheduleNotifications()
    }

    // MARK: Plan

    /// Plans again (coalesced; GoobyAlerts builds the plan once the current run is done).
    func rescheduleNotifications() {
        GoobyAlerts.replan(self)
    }

    func notificationPlan() -> GoobyNoticePlan {
        guard profile.notificationsEnabled else { return .off }
        let calendar = Calendar.current
        let realNow = Date()
        let offset = profile.timeOffset
        let appNow = now()
        let todayKey = dayKey()
        let name = notifyName
        let quiet = quietHours
        let paused = pauseModeOn
        var notices: [GoobyNotice] = []
        var open: Set<String> = []
        var keepDailySnooze = false

        var logs: [String: HabitLog] = [:]
        for log in all(HabitLog.self) { logs["\(log.habitID.uuidString)|\(log.dayKey)"] = log }
        func settled(_ habit: Habit, _ key: String) -> Bool {
            guard let log = logs["\(habit.id.uuidString)|\(key)"] else { return false }
            return log.skipped || log.count >= max(1, habit.timesPerDay)
        }

        // Goal reminders at the time set on the goal (masterprompt: individual goal reminders).
        if notifyOn(NotifyPref.goals) {
            for habit in habits() where !habit.isArchived && !habit.isPaused {
                if isDue(habit, on: appNow), !settled(habit, todayKey) { open.insert(habit.id.uuidString) }
                guard habit.reminderHour >= 0 else { continue }
                for fire in upcoming(habit.reminderHour * 60 + habit.reminderMinute, from: realNow, calendar: calendar) {
                    let appDate = fire.addingTimeInterval(offset)
                    guard isDue(habit, on: appDate) else { continue }
                    let key = DayKey.make(appDate)
                    guard !settled(habit, key) else { continue }
                    notices.append(GoobyNotice(
                        id: "gooby.goal.\(habit.id.uuidString).\(key)",
                        kind: .goal,
                        title: name,
                        body: txf("extras.notify.goal.body", de: "Eine deiner Aufgaben wartet auf dich: %@", en: "One of your tasks is waiting for you: %@", habit.title),
                        fireAt: fire,
                        wallClock: true,
                        quiet: quiet?.contains(fire, calendar: calendar) ?? false,
                        link: .home,
                        habitID: habit.id.uuidString,
                        dayKey: key
                    ))
                }
            }
        }

        // Daily reminder; skipped today once every goal due today is done, rests in pause mode.
        if notifyOn(NotifyPref.daily) && !paused {
            let progress = todayProgress()
            let allDone = progress.total > 0 && progress.done >= progress.total
            keepDailySnooze = !allDone
            for fire in upcoming(notifyMinutes(NotifyPref.dailyAt), from: realNow, calendar: calendar) {
                let appDate = fire.addingTimeInterval(offset)
                let key = DayKey.make(appDate)
                if key == todayKey && allDone { continue }
                notices.append(GoobyNotice(
                    id: "gooby.daily.\(key)",
                    kind: .daily,
                    title: name,
                    body: dailyLine(for: appDate, hasGoals: !dueHabits(on: appDate).isEmpty, calendar: calendar),
                    fireAt: fire,
                    wallClock: true,
                    quiet: quiet?.contains(fire, calendar: calendar) ?? false,
                    link: .home,
                    dayKey: key
                ))
            }
        }

        // Adventure finished; waits for the end of quiet hours.
        if notifyOn(NotifyPref.adventure), let run = all(AdventureRun.self).first(where: { $0.status == "traveling" }) {
            var fire = realNow.addingTimeInterval(run.returnsAt.timeIntervalSince(appNow))
            if fire > realNow.addingTimeInterval(2) {
                var shifted = false
                if let quiet, quiet.contains(fire, calendar: calendar) {
                    fire = quiet.end(after: fire, calendar: calendar)
                    shifted = true
                }
                let place = catalog.placesByID[run.placeID]?.name.text(languageCode) ?? ""
                notices.append(GoobyNotice(
                    id: "gooby.adventure.\(run.id.uuidString)",
                    kind: .adventure,
                    title: tx("extras.notify.adventure.title", de: "Dein kleines Abenteuer ist beendet!", en: "Your little adventure is over!"),
                    body: txf("extras.notify.adventure.body", de: "%@ ist zurück und hat aus „%@“ eine Geschichte mitgebracht.", en: "%@ is back with a story from %@.", name, place),
                    fireAt: fire,
                    wallClock: shifted,
                    quiet: false,
                    link: .adventure
                ))
            }
        }

        // Event start at 10:00 on its first day, up to three weeks ahead; rests in pause mode.
        if notifyOn(NotifyPref.events) && !paused {
            let forced = Set(all(EventRecord.self).filter(\.forced).map(\.eventID))
            for event in catalog.events where !forced.contains(event.id) {
                let parts = DateComponents(month: event.startMonth, day: event.startDay, hour: 10, minute: 0, second: 0)
                guard let startApp = calendar.nextDate(after: appNow, matching: parts, matchingPolicy: .nextTime) else { continue }
                var fire = startApp.addingTimeInterval(-offset)
                guard fire > realNow.addingTimeInterval(60), fire < realNow.addingTimeInterval(21 * 24 * 3600) else { continue }
                if let quiet, quiet.contains(fire, calendar: calendar) { fire = quiet.end(after: fire, calendar: calendar) }
                notices.append(GoobyNotice(
                    id: "gooby.event.\(event.id).\(DayKey.make(startApp))",
                    kind: .event,
                    title: tx("extras.notify.event.title", de: "Heute beginnt ein neues Event!", en: "A new event starts today!"),
                    body: txf("extras.notify.event.body", de: "„%@“ ist da. %@", en: "%@ is here. %@", event.title.text(languageCode), event.blurb.text(languageCode)),
                    fireAt: fire,
                    wallClock: true,
                    quiet: false,
                    link: .quests
                ))
            }
        }

        // Focus timer finished (only while it runs; a paused timer has no end yet).
        if notifyOn(NotifyPref.focus), let session = currentFocus(), session.runningSince != nil {
            let remaining = focusRemaining()
            if remaining > 2 {
                let fire = realNow.addingTimeInterval(TimeInterval(remaining))
                notices.append(GoobyNotice(
                    id: "gooby.focus.\(session.id.uuidString)",
                    kind: .focus,
                    title: tx("extras.notify.focus.title", de: "Fokuszeit geschafft! ⏱️", en: "Focus time done! ⏱️"),
                    body: txf("extras.notify.focus.body", de: "%@ Minuten am Stück. %@ ist stolz auf dich.", en: "%@ minutes in a row. %@ is proud of you.", String(max(1, session.plannedSeconds / 60)), name),
                    fireAt: fire,
                    wallClock: false,
                    quiet: quiet?.contains(fire, calendar: calendar) ?? false,
                    link: .focus
                ))
            }
        }

        notices.sort { $0.fireAt < $1.fireAt }
        return GoobyNoticePlan(
            enabled: true,
            notices: Array(notices.prefix(GoobyEngine.noticeBudget)),
            openHabitIDs: open,
            keepDailySnooze: keepDailySnooze
        )
    }

    /// A notification of `kind` for right now, for the developer menu's test buttons. The goal
    /// test uses the first goal still open today (its "Done" action checks it off).
    func sampleNotice(_ kind: GoobyNotice.Kind) -> GoobyNotice? {
        let fire = Date().addingTimeInterval(5)
        let key = dayKey()
        switch kind {
        case .goal:
            let due = dueHabits(on: now())
            let open = due.first { (habitLog($0.id, key)?.count ?? 0) < max(1, $0.timesPerDay) }
            guard let habit = open ?? due.first ?? habits().first(where: { !$0.isArchived }) else { return nil }
            return GoobyNotice(
                id: "gooby.test.goal",
                kind: .goal,
                title: notifyName,
                body: txf("extras.notify.goal.body", de: "Eine deiner Aufgaben wartet auf dich: %@", en: "One of your tasks is waiting for you: %@", habit.title),
                fireAt: fire,
                wallClock: false,
                quiet: false,
                link: .home,
                habitID: habit.id.uuidString,
                dayKey: key
            )
        case .daily:
            return GoobyNotice(
                id: "gooby.test.daily",
                kind: .daily,
                title: notifyName,
                body: dailyLine(for: now(), hasGoals: !dueHabits(on: now()).isEmpty, calendar: .current),
                fireAt: fire,
                wallClock: false,
                quiet: false,
                link: .home,
                dayKey: key
            )
        default:
            return nil
        }
    }

    /// Gooby's name for titles; never empty.
    var notifyName: String {
        let name = profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Gooby" : name
    }

    /// The daily reminder's line, one of four kind sentences that change from day to day.
    private func dailyLine(for date: Date, hasGoals: Bool, calendar: Calendar) -> String {
        var index = (calendar.ordinality(of: .day, in: .era, for: date) ?? 0) % 4
        if index == 2 && !hasGoals { index = 0 }
        switch index {
        case 1:
            return tx("extras.notify.daily.moment", de: "Zeit für einen kleinen Moment für dich.", en: "Time for a little moment for yourself.")
        case 2:
            return tx("extras.notify.daily.task", de: "Eine deiner Aufgaben wartet auf dich.", en: "One of your tasks is waiting for you.")
        case 3:
            return txf("extras.notify.daily.thought", de: "%@ hat heute schon an dich gedacht. 💛", en: "%@ has been thinking of you today. 💛", notifyName)
        default:
            return txf("extras.notify.daily.glad", de: "%@ freut sich auf dich! 🐰", en: "%@ is looking forward to seeing you! 🐰", notifyName)
        }
    }

    /// Today and the next days at `minutes` after midnight, real device time, still ahead.
    private func upcoming(_ minutes: Int, from start: Date, calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: start)
        return (0..<GoobyEngine.noticeHorizonDays).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fire = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day),
                  fire > start.addingTimeInterval(5) else { return nil }
            return fire
        }
    }
}
