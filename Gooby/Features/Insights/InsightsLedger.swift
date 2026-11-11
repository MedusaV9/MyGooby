import Foundation

// Local arithmetic for the Insights screen. Reads copies of MoodEntry, HabitLog
// and JournalEntry. Nothing here sends mail or opens a network.

enum InsightsTone: String, Equatable {
    case positive
    case neutral
    case negative
}

enum InsightsScope: String, CaseIterable, Equatable {
    case overall
    case positive
    case neutral
    case negative

    func allows(_ tone: InsightsTone) -> Bool {
        switch self {
        case .overall: return true
        case .positive: return tone == .positive
        case .neutral: return tone == .neutral
        case .negative: return tone == .negative
        }
    }
}

enum InsightsWindow: Int, CaseIterable, Equatable {
    case week = 7
    case fortnight = 14
    case month = 30
}

struct InsightsMoodMark: Equatable {
    var dayKey: String
    var recordedAt: Date
    var level: Int
    var tags: [String]
}

struct InsightsNoteMark: Equatable, Identifiable {
    var id: String
    var dayKey: String
    var title: String
    var body: String
    var tags: [String]
    var theme: String

    var written: Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct InsightsHabitMark: Equatable {
    var id: UUID
    var ordinal: Int
    var title: String
    var icon: String
    var recurrence: String
    var archived: Bool
    var paused: Bool
    var startDate: Date
    var endDate: Date?
    var weekdays: [Int]
    var intervalDays: Int
    var timesPerDay: Int
    var movedFromKey: String
    var movedToKey: String
}

struct InsightsLogMark: Equatable {
    var habitID: UUID
    var dayKey: String
    var count: Int
    var skipped: Bool
}

struct InsightsSnapshot: Equatable {
    var now: Date
    var moods: [InsightsMoodMark]
    var notes: [InsightsNoteMark]
    var habits: [InsightsHabitMark]
    var logs: [InsightsLogMark]
}

struct InsightsDot: Equatable, Identifiable {
    var id: String
    var dayKey: String
    var week: Int
    var row: Int
    var tone: InsightsTone?
    var inMonth: Bool
}

struct InsightsMonth: Equatable, Identifiable {
    var id: String
    var start: Date
    var weekCount: Int
    var cells: [InsightsDot]

    func cell(week: Int, row: Int) -> InsightsDot? {
        let index = week * 7 + row
        guard cells.indices.contains(index) else { return nil }
        return cells[index]
    }
}

struct InsightsBreakdown: Equatable {
    var positive: Int
    var neutral: Int
    var negative: Int

    var total: Int { positive + neutral + negative }

    func count(_ tone: InsightsTone) -> Int {
        switch tone {
        case .positive: return positive
        case .neutral: return neutral
        case .negative: return negative
        }
    }

    /// Percentages that add up to 100 when there is at least one day.
    func shares() -> [InsightsTone: Int] {
        let tones: [InsightsTone] = [.positive, .neutral, .negative]
        let counts = tones.map { count($0) }
        guard total > 0 else {
            return [.positive: 0, .neutral: 0, .negative: 0]
        }
        let raw = counts.map { Double($0) / Double(total) * 100 }
        var floors = raw.map { Int($0.rounded(.down)) }
        var left = 100 - floors.reduce(0, +)
        let order = raw.enumerated().sorted { lhs, rhs in
            let leftRemainder = lhs.element - Double(floors[lhs.offset])
            let rightRemainder = rhs.element - Double(floors[rhs.offset])
            if leftRemainder != rightRemainder { return leftRemainder > rightRemainder }
            return lhs.offset < rhs.offset
        }
        var index = 0
        while left > 0 && index < order.count {
            floors[order[index].offset] += 1
            left -= 1
            index += 1
        }
        return [.positive: floors[0], .neutral: floors[1], .negative: floors[2]]
    }
}

struct InsightsTagCount: Equatable, Identifiable {
    var tag: String
    var count: Int
    var positive: Int
    var neutral: Int
    var negative: Int

    var id: String { tag }
}

struct InsightsRank: Equatable, Identifiable {
    var id: UUID
    var title: String
    var icon: String
    var done: Int
    var due: Int
    var percent: Int
}

struct InsightsGoalReport: Equatable {
    var completed: Int
    var ranks: [InsightsRank]
    var missed: [InsightsRank]
}

struct InsightsReflectionReport: Equatable {
    var total: Int
    var positive: Int
    var negative: Int
}

enum InsightsDayState: Equatable {
    case first
    case done
    case skipped
    case open
}

struct InsightsDayGoal: Equatable, Identifiable {
    var id: UUID
    var title: String
    var icon: String
    var recurrence: String
    var state: InsightsDayState
}

struct InsightsDaySnapshot: Equatable {
    var goals: [InsightsDayGoal]
    var notes: [InsightsNoteMark]
}

struct InsightsLetterFacts: Equatable {
    var done: Int
    var due: Int
    var moodLevel: Int?
    var noteTitles: [String]

    var quiet: Bool {
        done == 0 && due == 0 && moodLevel == nil && noteTitles.isEmpty
    }
}

enum InsightsLedger {
    static let positiveWords: Set<String> = ["happy", "grateful", "motivated", "calm", "gratitude", "worth", "motive"]
    static let negativeWords: Set<String> = ["sad", "stressed", "overwhelmed", "tired", "stress"]

    static func tone(level: Int) -> InsightsTone? {
        switch level {
        case 4...5: return .positive
        case 3: return .neutral
        case 1...2: return .negative
        default: return nil
        }
    }

    static func mondayRow(_ date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    static func monthID(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    static func dayKeys(ending: Date, days: Int, calendar: Calendar) -> [String] {
        let end = calendar.startOfDay(for: ending)
        let count = max(1, days)
        return (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(count - 1 - offset), to: end) else { return nil }
            return DayKey.make(date, calendar: calendar)
        }
    }

    static func weekDates(containing date: Date, calendar: Calendar) -> [Date] {
        let day = calendar.startOfDay(for: date)
        let row = mondayRow(day, calendar: calendar)
        guard let start = calendar.date(byAdding: .day, value: -row, to: day) else { return [day] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    static func months(ending: Date, marks: [InsightsMoodMark], calendar: Calendar, count: Int = 4) -> [InsightsMonth] {
        let parts = calendar.dateComponents([.year, .month], from: ending)
        guard let anchor = calendar.date(from: parts) else { return [] }
        var result: [InsightsMonth] = []
        let span = max(1, count)
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: anchor) else { continue }
            result.append(makeMonth(monthDate, marks: marks, calendar: calendar))
        }
        return result
    }

    static func breakdown(marks: [InsightsMoodMark], months: [InsightsMonth]) -> InsightsBreakdown {
        let ids = Set(months.map(\.id))
        let relevant = marks.filter { ids.contains(String($0.dayKey.prefix(7))) }
        let grouped = Dictionary(grouping: relevant, by: \.dayKey)
        var positive = 0
        var neutral = 0
        var negative = 0
        for rows in grouped.values {
            guard let last = rows.max(by: { $0.recordedAt < $1.recordedAt }),
                  let tone = tone(level: last.level) else { continue }
            switch tone {
            case .positive: positive += 1
            case .neutral: neutral += 1
            case .negative: negative += 1
            }
        }
        return InsightsBreakdown(positive: positive, neutral: neutral, negative: negative)
    }

    static func tags(marks: [InsightsMoodMark], months: [InsightsMonth]) -> [InsightsTagCount] {
        let ids = Set(months.map(\.id))
        var buckets: [String: InsightsTagCount] = [:]
        for mark in marks where ids.contains(String(mark.dayKey.prefix(7))) {
            guard let tone = tone(level: mark.level) else { continue }
            for raw in mark.tags {
                let tag = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !tag.isEmpty else { continue }
                var bucket = buckets[tag] ?? InsightsTagCount(tag: tag, count: 0, positive: 0, neutral: 0, negative: 0)
                bucket.count += 1
                switch tone {
                case .positive: bucket.positive += 1
                case .neutral: bucket.neutral += 1
                case .negative: bucket.negative += 1
                }
                buckets[tag] = bucket
            }
        }
        return buckets.values.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.tag.localizedCaseInsensitiveCompare(rhs.tag) == .orderedAscending
        }
    }

    static func goalReport(habits: [InsightsHabitMark], logs: [InsightsLogMark], ending: Date, days: Int, calendar: Calendar) -> InsightsGoalReport {
        let keys = dayKeys(ending: ending, days: days, calendar: calendar)
        var ranks: [InsightsRank] = []
        var completed = 0
        for habit in habits where !habit.archived && !habit.paused {
            var due = 0
            var done = 0
            for key in keys {
                guard let date = DayKey.parse(key, calendar: calendar) else { continue }
                let scheduled = wasDue(habit, on: date, calendar: calendar)
                let hit = satisfied(habit, key: key, logs: logs)
                if scheduled || hit {
                    due += 1
                    if hit { done += 1 }
                }
            }
            guard due > 0 else { continue }
            completed += done
            ranks.append(InsightsRank(
                id: habit.id,
                title: habit.title,
                icon: habit.icon,
                done: done,
                due: due,
                percent: percent(done: done, due: due)
            ))
        }
        let best = ranks.sorted { lhs, rhs in
            if lhs.percent != rhs.percent { return lhs.percent > rhs.percent }
            if lhs.done != rhs.done { return lhs.done > rhs.done }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        let missed = ranks.filter { $0.percent < 100 }.sorted { lhs, rhs in
            if lhs.percent != rhs.percent { return lhs.percent < rhs.percent }
            let leftMissed = lhs.due - lhs.done
            let rightMissed = rhs.due - rhs.done
            if leftMissed != rightMissed { return leftMissed > rightMissed }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        return InsightsGoalReport(completed: completed, ranks: best, missed: missed)
    }

    static func reflections(notes: [InsightsNoteMark], moods: [InsightsMoodMark], ending: Date, days: Int, calendar: Calendar) -> InsightsReflectionReport {
        let allowed = Set(dayKeys(ending: ending, days: days, calendar: calendar))
        var total = 0
        var positive = 0
        var negative = 0
        for note in notes where note.written && allowed.contains(note.dayKey) {
            total += 1
            switch polarity(note, mood: latestTone(on: note.dayKey, marks: moods)) {
            case .positive: positive += 1
            case .negative: negative += 1
            default: break
            }
        }
        return InsightsReflectionReport(total: total, positive: positive, negative: negative)
    }

    static func daySnapshot(_ snapshot: InsightsSnapshot, on date: Date, calendar: Calendar) -> InsightsDaySnapshot {
        let day = calendar.startOfDay(for: date)
        let key = DayKey.make(day, calendar: calendar)
        var goals: [InsightsDayGoal] = []
        for habit in snapshot.habits.sorted(by: { $0.ordinal < $1.ordinal }) {
            let scheduled = !habit.archived && !habit.paused && wasDue(habit, on: day, calendar: calendar)
            let entry = log(habit.id, key, snapshot.logs)
            let hit = satisfied(habit, key: key, logs: snapshot.logs)
            let logged = entry != nil && ((entry?.count ?? 0) > 0 || entry?.skipped == true)
            guard scheduled || logged else { continue }
            let state: InsightsDayState
            if hit {
                let prior = snapshot.logs.contains { row in
                    row.habitID == habit.id && row.dayKey < key && !row.skipped && row.count >= max(1, habit.timesPerDay)
                }
                state = prior ? .done : .first
            } else if entry?.skipped == true {
                state = .skipped
            } else {
                state = .open
            }
            goals.append(InsightsDayGoal(id: habit.id, title: habit.title, icon: habit.icon, recurrence: habit.recurrence, state: state))
        }
        let notes = snapshot.notes.filter { note in
            note.dayKey == key && (note.written || !note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        return InsightsDaySnapshot(goals: goals, notes: notes)
    }

    static func letter(_ snapshot: InsightsSnapshot, on date: Date, calendar: Calendar) -> InsightsLetterFacts {
        let day = daySnapshot(snapshot, on: date, calendar: calendar)
        let key = DayKey.make(calendar.startOfDay(for: date), calendar: calendar)
        let done = day.goals.filter { $0.state == .first || $0.state == .done }.count
        let titles = day.notes.filter(\.written).prefix(3).map { noteTitle($0) }
        return InsightsLetterFacts(
            done: done,
            due: day.goals.count,
            moodLevel: latestLevel(on: key, marks: snapshot.moods),
            noteTitles: Array(titles)
        )
    }

    static func wasDue(_ habit: InsightsHabitMark, on date: Date, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: date)
        let key = DayKey.make(day, calendar: calendar)
        if !habit.movedFromKey.isEmpty, habit.movedFromKey == key { return false }
        if !habit.movedToKey.isEmpty, habit.movedToKey == key { return true }

        let start = calendar.startOfDay(for: habit.startDate)
        if day < start { return false }
        if let end = habit.endDate, day > calendar.startOfDay(for: end) { return false }

        switch habit.recurrence {
        case "once":
            return calendar.isDate(day, inSameDayAs: start)
        case "daily":
            return true
        case "weekly":
            return calendar.component(.weekday, from: day) == calendar.component(.weekday, from: start)
        case "monthly":
            let wanted = calendar.component(.day, from: start)
            let actual = calendar.component(.day, from: day)
            let last = calendar.range(of: .day, in: .month, for: day)?.count ?? 28
            return actual == min(wanted, last)
        case "weekdays":
            return habit.weekdays.contains(calendar.component(.weekday, from: day))
        case "everyX":
            let step = max(1, habit.intervalDays)
            let delta = calendar.dateComponents([.day], from: start, to: day).day ?? 0
            return delta >= 0 && delta % step == 0
        case "custom":
            let delta = calendar.dateComponents([.day], from: start, to: day).day ?? 0
            let stepOK = habit.intervalDays <= 1 || (delta >= 0 && delta % max(1, habit.intervalDays) == 0)
            let daysOK = habit.weekdays.isEmpty || habit.weekdays.contains(calendar.component(.weekday, from: day))
            return stepOK && daysOK
        default:
            return false
        }
    }

    static func latestTone(on dayKey: String, marks: [InsightsMoodMark]) -> InsightsTone? {
        guard let level = latestLevel(on: dayKey, marks: marks) else { return nil }
        return tone(level: level)
    }

    static func noteTitle(_ note: InsightsNoteMark) -> String {
        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }
        let body = note.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.count <= 42 { return body }
        return String(body.prefix(42)) + "…"
    }

    private static func latestLevel(on dayKey: String, marks: [InsightsMoodMark]) -> Int? {
        guard let last = marks.filter({ $0.dayKey == dayKey }).max(by: { $0.recordedAt < $1.recordedAt }) else { return nil }
        return tone(level: last.level) == nil ? nil : last.level
    }

    private static func polarity(_ note: InsightsNoteMark, mood: InsightsTone?) -> InsightsTone? {
        var bag = Set(note.tags.map { $0.lowercased() })
        if !note.theme.isEmpty { bag.insert(note.theme.lowercased()) }
        let positive = !bag.isDisjoint(with: positiveWords)
        let negative = !bag.isDisjoint(with: negativeWords)
        if positive && !negative { return .positive }
        if negative && !positive { return .negative }
        if mood == .positive || mood == .negative { return mood }
        return nil
    }

    private static func satisfied(_ habit: InsightsHabitMark, key: String, logs: [InsightsLogMark]) -> Bool {
        guard let entry = log(habit.id, key, logs), !entry.skipped else { return false }
        return entry.count >= max(1, habit.timesPerDay)
    }

    private static func log(_ habitID: UUID, _ key: String, _ logs: [InsightsLogMark]) -> InsightsLogMark? {
        logs.filter { $0.habitID == habitID && $0.dayKey == key }.max { $0.count < $1.count }
    }

    private static func percent(done: Int, due: Int) -> Int {
        guard due > 0 else { return 0 }
        return Int((Double(done) / Double(due) * 100).rounded())
    }

    private static func makeMonth(_ monthDate: Date, marks: [InsightsMoodMark], calendar: Calendar) -> InsightsMonth {
        let monthID = monthID(monthDate, calendar: calendar)
        guard let range = calendar.range(of: .day, in: .month, for: monthDate) else {
            return InsightsMonth(id: monthID, start: monthDate, weekCount: 1, cells: [])
        }
        let leading = mondayRow(monthDate, calendar: calendar)
        let weeks = max(1, Int(ceil(Double(leading + range.count) / 7.0)))
        var cells: [InsightsDot] = []
        for week in 0..<weeks {
            for row in 0..<7 {
                let dayNumber = week * 7 + row - leading + 1
                if dayNumber < 1 || dayNumber > range.count {
                    cells.append(InsightsDot(id: "\(monthID)-\(week)-\(row)", dayKey: "", week: week, row: row, tone: nil, inMonth: false))
                } else {
                    let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthDate) ?? monthDate
                    let key = DayKey.make(date, calendar: calendar)
                    cells.append(InsightsDot(
                        id: key,
                        dayKey: key,
                        week: week,
                        row: row,
                        tone: InsightsLedger.latestTone(on: key, marks: marks),
                        inMonth: true
                    ))
                }
            }
        }
        return InsightsMonth(id: monthID, start: monthDate, weekCount: weeks, cells: cells)
    }
}
