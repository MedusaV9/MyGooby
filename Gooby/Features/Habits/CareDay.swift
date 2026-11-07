import Foundation

/// Civil day keys (`yyyy-MM-dd`) in a Gregorian calendar. Keys sort in calendar order.
enum CareDay {
    static func timestamp(_ date: Date = Date()) -> Date {
        Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded())
    }

    static func key(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Noon, so a daylight-saving midnight cannot slide the key into another day.
    static func date(from key: String, calendar: Calendar) -> Date? {
        let pieces = key.split(separator: "-")
        guard pieces.count == 3,
              let year = Int(pieces[0]),
              let month = Int(pieces[1]),
              let day = Int(pieces[2]),
              (1...12).contains(month),
              (1...31).contains(day) else { return nil }
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        parts.minute = 0
        parts.second = 0
        guard let date = calendar.date(from: parts) else { return nil }
        let check = calendar.dateComponents([.year, .month, .day], from: date)
        guard check.year == year, check.month == month, check.day == day else { return nil }
        return date
    }

    static func addingDays(_ days: Int, to key: String, calendar: Calendar) -> String? {
        guard let date = date(from: key, calendar: calendar),
              let shifted = calendar.date(byAdding: .day, value: days, to: date) else { return nil }
        return self.key(for: shifted, calendar: calendar)
    }

    static func trailingDays(ending key: String, count: Int, calendar: Calendar) -> [String] {
        guard count > 0 else { return [] }
        return (0..<count).reversed().compactMap { offset in
            addingDays(-offset, to: key, calendar: calendar)
        }
    }

    static func weekKeys(containing key: String, calendar: Calendar) -> [String] {
        guard let date = date(from: key, calendar: calendar) else { return [] }
        let weekday = calendar.component(.weekday, from: date)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        guard let start = calendar.date(byAdding: .day, value: -leading, to: date) else { return [] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start).map { self.key(for: $0, calendar: calendar) }
        }
    }

    static func shiftMonth(containing key: String, by months: Int, calendar: Calendar) -> String? {
        guard let date = date(from: key, calendar: calendar) else { return nil }
        var parts = calendar.dateComponents([.year, .month], from: date)
        parts.day = 1
        parts.hour = 12
        guard let start = calendar.date(from: parts),
              let shifted = calendar.date(byAdding: .month, value: months, to: start) else { return nil }
        return self.key(for: shifted, calendar: calendar)
    }

    /// `nil` marks a leading blank. Day keys are noon-stable.
    static func monthCells(containing key: String, calendar: Calendar) -> [String?] {
        guard let date = date(from: key, calendar: calendar) else { return [] }
        var parts = calendar.dateComponents([.year, .month], from: date)
        parts.day = 1
        parts.hour = 12
        guard let monthStart = calendar.date(from: parts),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var cells: [String?] = Array(repeating: nil, count: leading)
        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            cells.append(self.key(for: date, calendar: calendar))
        }
        return cells
    }

    static func daysInMonth(containing key: String, calendar: Calendar) -> [String] {
        monthCells(containing: key, calendar: calendar).compactMap { $0 }
    }

    static func format(_ key: String, language: CareLanguage, calendar: Calendar, template: String) -> String {
        guard let date = date(from: key, calendar: calendar) else { return key }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }

    static func gregorian(timeZone: TimeZone = .current, firstWeekday: Int? = nil, locale: String = "en_US_POSIX") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: locale)
        if let firstWeekday {
            calendar.firstWeekday = firstWeekday
        }
        return calendar
    }
}
