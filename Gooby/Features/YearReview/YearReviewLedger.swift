import Foundation

/// One habit log already stored on this iPhone.
struct YearHabitMark: Equatable {
    var dayKey: String
    var count: Int
    var skipped: Bool
    var habitID: UUID
}

/// One outing already stored on this iPhone.
struct YearAdventureMark: Equatable {
    var placeID: String
    var dayKey: String
    var startedAt: Date
}

/// One spark row already stored in the reward ledger.
struct YearSparkMark: Equatable {
    var sparks: Int
    var createdAt: Date
}

/// Totals for one calendar year. `monthDays` is January through December.
struct YearReviewFacts: Equatable {
    var year: Int
    var habitDays: Int
    var habitChecks: Int
    var adventures: Int
    var placeIDs: [String]
    var sparks: Int
    var monthDays: [Int]

    var isEmpty: Bool { habitChecks == 0 && adventures == 0 && sparks == 0 }
}

/// Counts the current year from habit logs, adventures, and spark rows that already exist.
/// A pause marker is not a habit check. A ledger row with no sparks is not earnings.
enum YearReviewLedger {
    @MainActor
    static func read(_ engine: GoobyEngine, calendar: Calendar = .current) -> YearReviewFacts {
        let habits = engine.all(HabitLog.self).map {
            YearHabitMark(dayKey: $0.dayKey, count: $0.count, skipped: $0.skipped, habitID: $0.habitID)
        }
        let adventures = engine.all(AdventureRun.self).map {
            YearAdventureMark(placeID: $0.placeID, dayKey: $0.dayKey, startedAt: $0.startedAt)
        }
        let sparks = engine.all(RewardLedger.self).map {
            YearSparkMark(sparks: $0.sparks, createdAt: $0.createdAt)
        }
        let year = calendar.component(.year, from: engine.now())
        return facts(
            year: year,
            habits: habits,
            adventures: adventures,
            sparks: sparks,
            holdHabit: LookMark.holdHabit,
            calendar: calendar
        )
    }

    static func facts(
        year: Int,
        habits: [YearHabitMark],
        adventures: [YearAdventureMark],
        sparks: [YearSparkMark],
        holdHabit: UUID,
        calendar: Calendar
    ) -> YearReviewFacts {
        var days = Set<String>()
        var checks = 0
        var monthDays = Array(repeating: 0, count: 12)
        for mark in habits {
            guard mark.habitID != holdHabit, !mark.skipped, mark.count > 0 else { continue }
            guard year(ofDayKey: mark.dayKey) == year else { continue }
            checks += mark.count
            if days.insert(mark.dayKey).inserted, let month = month(ofDayKey: mark.dayKey) {
                monthDays[month - 1] += 1
            }
        }

        let trips = adventures
            .filter { adventureYear($0, calendar: calendar) == year }
            .sorted { lhs, rhs in
                let left = sortKey(lhs, calendar: calendar)
                let right = sortKey(rhs, calendar: calendar)
                if left != right { return left < right }
                return lhs.placeID < rhs.placeID
            }
        var placeIDs: [String] = []
        for trip in trips where !trip.placeID.isEmpty && !placeIDs.contains(trip.placeID) {
            placeIDs.append(trip.placeID)
        }

        let earned = sparks.reduce(0) { sum, mark in
            guard mark.sparks > 0, calendar.component(.year, from: mark.createdAt) == year else { return sum }
            return sum + mark.sparks
        }

        return YearReviewFacts(
            year: year,
            habitDays: days.count,
            habitChecks: checks,
            adventures: trips.count,
            placeIDs: placeIDs,
            sparks: earned,
            monthDays: monthDays
        )
    }

    static func year(ofDayKey key: String) -> Int? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              parts[0].count == 4,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              year >= 1,
              (1...12).contains(month),
              (1...31).contains(day) else { return nil }
        return year
    }

    static func month(ofDayKey key: String) -> Int? {
        guard year(ofDayKey: key) != nil else { return nil }
        return Int(key.split(separator: "-")[1])
    }

    static func adventureYear(_ mark: YearAdventureMark, calendar: Calendar) -> Int {
        if let year = year(ofDayKey: mark.dayKey) { return year }
        return calendar.component(.year, from: mark.startedAt)
    }

    private static func sortKey(_ mark: YearAdventureMark, calendar: Calendar) -> String {
        if year(ofDayKey: mark.dayKey) != nil { return mark.dayKey }
        return DayKey.make(mark.startedAt, calendar: calendar)
    }
}
