import Foundation

/// Whether a habit is scheduled on one civil day.
/// A completion never leaks into another day: records are stored per day key.
enum HabitSchedule {
    static func isPaused(_ habit: Habit, on day: String) -> Bool {
        guard let from = habit.pauseFrom else { return false }
        if let until = habit.pauseUntil, until < from { return false }
        if day < from { return false }
        if let until = habit.pauseUntil, day > until { return false }
        return true
    }

    static func isDue(habit: Habit, day: String, record: HabitDayRecord?, calendar: Calendar) -> Bool {
        if habit.archived { return false }
        if day < habit.startDay { return false }
        if let end = habit.endDay, day > end { return false }
        if isPaused(habit, on: day) { return false }
        if record?.removed == true { return false }
        if record?.movedFrom != nil { return true }
        return ruleMatches(habit.rule, day: day, startDay: habit.startDay, calendar: calendar)
    }

    static func ruleMatches(_ rule: HabitRule, day: String, startDay: String, calendar: Calendar) -> Bool {
        switch rule {
        case .once:
            return day == startDay
        case .daily:
            return true
        case .weekly(let weekday):
            guard (1...7).contains(weekday), let date = CareDay.date(from: day, calendar: calendar) else { return false }
            return calendar.component(.weekday, from: date) == weekday
        case .monthly(let anchor):
            return monthDayMatches(anchor, day: day, calendar: calendar)
        case .weekdays(let days):
            guard let date = CareDay.date(from: day, calendar: calendar) else { return false }
            let weekday = calendar.component(.weekday, from: date)
            return days.contains(weekday)
        case .every(let interval):
            guard let delta = dayDistance(from: startDay, to: day, calendar: calendar) else { return false }
            return (1...366).contains(interval) && delta >= 0 && delta % interval == 0
        case .custom(let interval, let weekdays, let monthDays):
            if interval == nil && weekdays.isEmpty && monthDays.isEmpty { return false }
            if let interval {
                guard let delta = dayDistance(from: startDay, to: day, calendar: calendar) else { return false }
                if !(1...366).contains(interval) || delta < 0 || delta % interval != 0 { return false }
            }
            if !weekdays.isEmpty {
                guard let date = CareDay.date(from: day, calendar: calendar) else { return false }
                if !weekdays.contains(calendar.component(.weekday, from: date)) { return false }
            }
            if !monthDays.isEmpty {
                let matched = monthDays.contains { monthDayMatches($0, day: day, calendar: calendar) }
                if !matched { return false }
            }
            return true
        }
    }

    /// Anchor 31 in a 30-day month, and in February, is the month's last day.
    static func monthDayMatches(_ anchor: Int, day: String, calendar: Calendar) -> Bool {
        guard (1...31).contains(anchor), let date = CareDay.date(from: day, calendar: calendar),
              let range = calendar.range(of: .day, in: .month, for: date) else { return false }
        let last = range.count
        let target = min(anchor, last)
        return calendar.component(.day, from: date) == target
    }

    static func dayDistance(from startDay: String, to day: String, calendar: Calendar) -> Int? {
        guard let start = CareDay.date(from: startDay, calendar: calendar),
              let date = CareDay.date(from: day, calendar: calendar) else { return nil }
        return calendar.dateComponents([.day], from: start, to: date).day
    }

    static func selfCheck() -> [String] {
        var failures: [String] = []
        let calendar = CareDay.gregorian(timeZone: TimeZone(secondsFromGMT: 0) ?? .current, firstWeekday: 2)
        func expect(_ condition: Bool, _ message: String) {
            if !condition { failures.append(message) }
        }
        func habit(start: String, end: String? = nil, rule: HabitRule, archived: Bool = false, pauseFrom: String? = nil, pauseUntil: String? = nil) -> Habit {
            var item = Habit.makeNew(today: start)
            item.endDay = end
            item.rule = rule
            item.archived = archived
            item.pauseFrom = pauseFrom
            item.pauseUntil = pauseUntil
            item.title = "Check"
            return item
        }
        func due(_ item: Habit, _ day: String, record: HabitDayRecord? = nil) -> Bool {
            isDue(habit: item, day: day, record: record, calendar: calendar)
        }

        let daily = habit(start: "2026-04-01", end: "2026-04-03", rule: .daily)
        expect(due(daily, "2026-04-01"), "daily includes start")
        expect(due(daily, "2026-04-03"), "daily includes end")
        expect(!due(daily, "2026-03-31"), "daily excludes the day before start")
        expect(!due(daily, "2026-04-04"), "daily excludes the day after end")

        let once = habit(start: "2026-04-02", rule: .once)
        expect(due(once, "2026-04-02"), "once is due on the start day")
        expect(!due(once, "2026-04-03"), "once is not due the next day")

        let weekly = habit(start: "2026-01-01", rule: .weekly(weekday: 5))
        expect(due(weekly, "2026-01-01"), "weekly Thursday includes 1 Jan 2026")
        expect(!due(weekly, "2026-01-02"), "weekly Thursday skips Friday")
        expect(due(weekly, "2026-04-30"), "weekly Thursday includes 30 Apr 2026")

        let days = habit(start: "2026-01-01", rule: .weekdays(days: [2, 4, 6]))
        expect(due(days, "2026-01-02"), "weekday set includes Friday 2 Jan")
        expect(!due(days, "2026-01-03"), "weekday set skips Saturday")
        expect(due(days, "2026-01-05"), "weekday set includes Monday")

        let every = habit(start: "2026-01-30", rule: .every(days: 3))
        expect(due(every, "2026-01-30"), "every 3 days includes the anchor")
        expect(!due(every, "2026-01-31"), "every 3 days skips the next day")
        expect(!due(every, "2026-02-01"), "every 3 days skips the second day")
        expect(due(every, "2026-02-02"), "every 3 days crosses into February")
        expect(due(every, "2026-02-05"), "every 3 days keeps the interval")
        expect(!due(every, "2026-02-04"), "every 3 days does not match an off day")

        let month = habit(start: "2026-01-01", rule: .monthly(day: 31))
        expect(due(month, "2026-01-31"), "monthly 31 is 31 January")
        expect(!due(month, "2026-01-30"), "monthly 31 is not 30 January")
        expect(due(month, "2026-02-28"), "monthly 31 clamps to 28 Feb 2026")
        expect(!due(month, "2026-02-27"), "monthly 31 is not 27 February")
        expect(due(month, "2026-03-31"), "monthly 31 is 31 March")
        expect(due(month, "2026-04-30"), "monthly 31 clamps to 30 April")
        expect(!due(month, "2026-04-29"), "monthly 31 is not 29 April")
        expect(due(month, "2028-02-29"), "monthly 31 clamps to 29 Feb 2028")
        expect(!due(month, "2028-02-28"), "monthly 31 is not 28 Feb in a leap year")

        let paused = habit(start: "2026-04-01", rule: .daily, pauseFrom: "2026-04-03", pauseUntil: "2026-04-04")
        expect(due(paused, "2026-04-02"), "pause has not started")
        expect(!due(paused, "2026-04-03"), "pause covers the first paused day")
        expect(!due(paused, "2026-04-04"), "pause includes the last paused day")
        expect(due(paused, "2026-04-05"), "the day after pause is due again")

        let openPause = habit(start: "2026-04-01", rule: .daily, pauseFrom: "2026-04-10", pauseUntil: nil)
        expect(!due(openPause, "2026-04-10"), "open pause hides the start day")
        expect(!due(openPause, "2026-12-01"), "open pause hides later days")
        expect(due(openPause, "2026-04-09"), "open pause does not hide earlier days")

        let archived = habit(start: "2026-04-01", rule: .daily, archived: true)
        expect(!due(archived, "2026-04-01"), "archived habits are not due")

        var moved = HabitDayRecord(
            id: UUID(), habitID: UUID(), day: "2026-04-08",
            completedCount: 0, skipped: false, removed: false, movedFrom: "2026-04-07", updatedAt: CareDay.timestamp()
        )
        let onceMoved = habit(start: "2026-04-07", rule: .once)
        expect(!due(onceMoved, "2026-04-08"), "a once habit is not due the next day by rule")
        expect(due(onceMoved, "2026-04-08", record: moved), "an explicit move makes the target day due")
        moved.removed = true
        moved.movedFrom = nil
        expect(!due(onceMoved, "2026-04-07", record: moved), "a removed occurrence is not due")

        let pausedMove = habit(start: "2026-04-01", rule: .daily, pauseFrom: "2026-04-08", pauseUntil: nil)
        let extra = HabitDayRecord(
            id: UUID(), habitID: UUID(), day: "2026-04-08",
            completedCount: 0, skipped: false, removed: false, movedFrom: "2026-04-07", updatedAt: CareDay.timestamp()
        )
        expect(!due(pausedMove, "2026-04-08", record: extra), "pause still hides a moved day")

        let custom = habit(start: "2026-01-01", rule: .custom(interval: 2, weekdays: [2], monthDays: []))
        expect(ruleMatches(custom.rule, day: "2026-01-05", startDay: custom.startDay, calendar: calendar), "custom matches Monday on the interval")
        expect(!ruleMatches(custom.rule, day: "2026-01-06", startDay: custom.startDay, calendar: calendar), "custom rejects Tuesday")
        expect(!ruleMatches(custom.rule, day: "2026-01-07", startDay: custom.startDay, calendar: calendar), "custom rejects an off-interval Monday")
        expect(!ruleMatches(.custom(interval: nil, weekdays: [], monthDays: []), day: "2026-01-01", startDay: "2026-01-01", calendar: calendar), "empty custom matches nothing")
        expect(ruleMatches(.custom(interval: nil, weekdays: [], monthDays: [31]), day: "2026-02-28", startDay: "2026-01-01", calendar: calendar), "custom month day clamps")

        let newYork = CareDay.gregorian(
            timeZone: TimeZone(identifier: "America/New_York") ?? TimeZone(secondsFromGMT: 0) ?? .current,
            firstWeekday: 1
        )
        if let delta = dayDistance(from: "2026-03-08", to: "2026-03-09", calendar: newYork) {
            expect(delta == 1, "day distance across US spring-forward is one civil day, was \(delta)")
        } else {
            failures.append("day distance across DST failed to parse")
        }
        let dst = habit(start: "2026-03-08", rule: .every(days: 1))
        expect(isDue(habit: dst, day: "2026-03-09", record: nil, calendar: newYork), "every 1 day stays due after spring-forward")

        var monday = calendar
        monday.firstWeekday = 2
        var sunday = calendar
        sunday.firstWeekday = 1
        let mondayCells = CareDay.monthCells(containing: "2026-03-15", calendar: monday)
        let sundayCells = CareDay.monthCells(containing: "2026-03-15", calendar: sunday)
        expect(mondayCells.prefix(6).allSatisfy { $0 == nil }, "March 2026 has six leading blanks when weeks start Monday")
        expect(mondayCells.compactMap { $0 }.first == "2026-03-01", "Monday grid still starts on 1 March")
        expect(mondayCells.compactMap { $0 }.count == 31, "March has 31 days")
        expect(sundayCells.first == "2026-03-01", "Sunday-first March 2026 starts on the first cell")
        expect(CareDay.weekKeys(containing: "2026-03-04", calendar: monday).first == "2026-03-02", "Monday week containing 4 Mar starts 2 Mar")
        expect("2026-12-31" < "2027-01-01", "day keys sort across the new year")
        expect(CareDay.date(from: "2026-02-31", calendar: calendar) == nil, "31 February is not a day")
        expect(CareDay.addingDays(1, to: "2026-12-31", calendar: calendar) == "2027-01-01", "adding a day rolls the year")

        return failures
    }
}
