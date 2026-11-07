import Foundation

enum HabitCategory: String, Codable, CaseIterable, Identifiable {
    case morning
    case evening
    case hygiene
    case movement
    case sleep
    case learning
    case household
    case mindfulness
    case health
    case creativity
    case custom
    var id: String { rawValue }
}

enum HabitPriority: Int, Codable, CaseIterable, Identifiable {
    case low = 0
    case normal = 1
    case high = 2
    var id: Int { rawValue }
}

enum HabitSymbol: String, CaseIterable, Identifiable {
    case drop = "drop.fill"
    case bed = "bed.double.fill"
    case sparkles = "sparkles"
    case walk = "figure.walk"
    case book = "book.closed.fill"
    case heart = "heart.fill"
    case moon = "moon.stars.fill"
    case sun = "sun.max.fill"
    case leaf = "leaf.fill"
    case pencil = "pencil"
    case house = "house.fill"
    case cup = "cup.and.saucer.fill"
    case shower = "shower.fill"
    case wind = "wind"
    case music = "music.note"
    case star = "star.fill"
    var id: String { rawValue }
}

enum HabitColor: String, CaseIterable, Identifiable {
    case pink = "FFD6E7"
    case lavender = "D3C2FF"
    case mint = "C6EFDC"
    case yellow = "FFE7AD"
    case peach = "FFD6B3"
    case sky = "C8E9FF"
    var id: String { rawValue }
}

enum HabitRule: Codable, Equatable {
    case once
    case daily
    case weekly(weekday: Int)
    case monthly(day: Int)
    case weekdays(days: [Int])
    case every(days: Int)
    /// All set constraints must match. An empty custom rule matches nothing.
    /// A month day past the length of a short month lands on that month's last day.
    case custom(interval: Int?, weekdays: [Int], monthDays: [Int])
}

struct HabitReminder: Codable, Equatable {
    var hour: Int
    var minute: Int
}

struct Habit: Identifiable, Codable, Equatable {
    var id: UUID
    var starterKey: String?
    var title: String
    var details: String
    var symbol: String
    var colorHex: String
    var category: HabitCategory
    var customCategory: String
    var priority: HabitPriority
    var startDay: String
    var endDay: String?
    var rule: HabitRule
    var reminder: HabitReminder?
    var repetitions: Int
    var rewardValue: Int
    var isDailyGoal: Bool
    var archived: Bool
    var pauseFrom: String?
    var pauseUntil: String?
    var createdAt: Date
    var updatedAt: Date

    static func makeNew(today: String) -> Habit {
        Habit(
            id: UUID(),
            starterKey: nil,
            title: "",
            details: "",
            symbol: HabitSymbol.star.rawValue,
            colorHex: HabitColor.pink.rawValue,
            category: .mindfulness,
            customCategory: "",
            priority: .normal,
            startDay: today,
            endDay: nil,
            rule: .daily,
            reminder: nil,
            repetitions: 1,
            rewardValue: 5,
            isDailyGoal: false,
            archived: false,
            pauseFrom: nil,
            pauseUntil: nil,
            createdAt: CareDay.timestamp(),
            updatedAt: CareDay.timestamp()
        )
    }
}

struct HabitDayRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var habitID: UUID
    var day: String
    var completedCount: Int
    var skipped: Bool
    var removed: Bool
    var movedFrom: String?
    var updatedAt: Date
}

struct HabitProgress: Equatable {
    var due: Bool
    var completed: Int
    var repetitions: Int
    var skipped: Bool
    var isDailyGoal: Bool
    var paused: Bool

    var isComplete: Bool { due && repetitions > 0 && completed >= repetitions }
}

enum HabitValidator {
    static func issue(for habit: Habit) -> CareIssue? {
        if habit.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyTitle
        }
        if !(1...24).contains(habit.repetitions) { return .reps }
        if !(0...100).contains(habit.rewardValue) { return .reward }
        if HabitSymbol(rawValue: habit.symbol) == nil { return .symbol }
        if HabitColor(rawValue: habit.colorHex) == nil { return .color }
        if let end = habit.endDay, end < habit.startDay { return .dates }
        if habit.category == .custom,
           habit.customCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .customName
        }
        if let reminder = habit.reminder {
            if !(0...23).contains(reminder.hour) || !(0...59).contains(reminder.minute) {
                return .reminder
            }
        }
        if let from = habit.pauseFrom, let until = habit.pauseUntil, until < from {
            return .pause
        }
        return ruleIssue(habit.rule)
    }

    static func ruleIssue(_ rule: HabitRule) -> CareIssue? {
        switch rule {
        case .once, .daily:
            return nil
        case .weekly(let weekday):
            return (1...7).contains(weekday) ? nil : .weekdays
        case .monthly(let day):
            return (1...31).contains(day) ? nil : .monthDay
        case .weekdays(let days):
            let clean = days.filter { (1...7).contains($0) }
            return clean.isEmpty ? .weekdays : nil
        case .every(let days):
            return (1...366).contains(days) ? nil : .interval
        case .custom(let interval, let weekdays, let monthDays):
            if let interval, !(1...366).contains(interval) { return .interval }
            if weekdays.contains(where: { !(1...7).contains($0) }) { return .weekdays }
            if monthDays.contains(where: { !(1...31).contains($0) }) { return .monthDay }
            let hasInterval = interval != nil
            let hasWeekdays = !weekdays.isEmpty
            let hasMonth = !monthDays.isEmpty
            return (hasInterval || hasWeekdays || hasMonth) ? nil : .custom
        }
    }
}
