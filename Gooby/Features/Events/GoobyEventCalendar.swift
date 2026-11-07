import Foundation

enum GoobyEventCalendar {
    static func isActive(_ event: GoobySeasonalEventDefinition, on date: Date, calendar: Calendar) -> Bool {
        let current = monthDay(date, calendar: calendar)
        let start = event.startMonth * 100 + event.startDay
        let end = event.endMonth * 100 + event.endDay
        if start <= end {
            return current >= start && current <= end
        }
        return current >= start || current <= end
    }

    static func containingWindow(
        _ event: GoobySeasonalEventDefinition,
        on date: Date,
        calendar: Calendar
    ) -> GoobyEventWindow? {
        guard isActive(event, on: date, calendar: calendar) else {
            return nil
        }
        let year = calendar.component(.year, from: date)
        let current = monthDay(date, calendar: calendar)
        let start = event.startMonth * 100 + event.startDay
        let end = event.endMonth * 100 + event.endDay
        if start <= end {
            return window(event, startYear: year, endYear: year, calendar: calendar)
        }
        if current <= end {
            return window(event, startYear: year - 1, endYear: year, calendar: calendar)
        }
        return window(event, startYear: year, endYear: year + 1, calendar: calendar)
    }

    static func relevantWindow(
        _ event: GoobySeasonalEventDefinition,
        on date: Date,
        calendar: Calendar
    ) -> GoobyEventWindow? {
        if let containing = containingWindow(event, on: date, calendar: calendar) {
            return containing
        }
        let year = calendar.component(.year, from: date)
        let current = monthDay(date, calendar: calendar)
        let start = event.startMonth * 100 + event.startDay
        let wraps = start > (event.endMonth * 100 + event.endDay)
        let startYear = current < start ? year : year + 1
        let endYear = wraps ? startYear + 1 : startYear
        return window(event, startYear: startYear, endYear: endYear, calendar: calendar)
    }

    static func occurrenceKey(
        _ event: GoobySeasonalEventDefinition,
        on date: Date,
        calendar: Calendar
    ) -> String? {
        guard let window = relevantWindow(event, on: date, calendar: calendar) else {
            return nil
        }
        let year = calendar.component(.year, from: window.start)
        return "\(event.id)#\(year)"
    }

    static func entries(
        on date: Date,
        calendar: Calendar,
        events: [GoobySeasonalEventDefinition]
    ) -> [GoobyEventCalendarEntry] {
        events.compactMap { event in
            guard let window = relevantWindow(event, on: date, calendar: calendar) else {
                return nil
            }
            let phase = isActive(event, on: date, calendar: calendar) ? "active" : "upcoming"
            return GoobyEventCalendarEntry(event: event, window: window, phase: phase)
        }
        .sorted { $0.window.start < $1.window.start }
    }

    private static func monthDay(_ date: Date, calendar: Calendar) -> Int {
        calendar.component(.month, from: date) * 100 + calendar.component(.day, from: date)
    }

    private static func window(
        _ event: GoobySeasonalEventDefinition,
        startYear: Int,
        endYear: Int,
        calendar: Calendar
    ) -> GoobyEventWindow? {
        guard
            let start = makeDate(
                year: startYear,
                month: event.startMonth,
                day: event.startDay,
                hour: 0,
                minute: 0,
                second: 0,
                calendar: calendar
            ),
            let end = makeDate(
                year: endYear,
                month: event.endMonth,
                day: event.endDay,
                hour: 23,
                minute: 59,
                second: 59,
                calendar: calendar
            ),
            start <= end
        else {
            return nil
        }
        return GoobyEventWindow(start: start, end: end)
    }

    private static func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        calendar: Calendar
    ) -> Date? {
        var parts = DateComponents()
        parts.calendar = calendar
        parts.timeZone = calendar.timeZone
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.minute = minute
        parts.second = second
        return calendar.date(from: parts)
    }
}
