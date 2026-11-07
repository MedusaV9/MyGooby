import Foundation

enum MoodLevel: Int, Codable, CaseIterable, Identifiable {
    case veryBad = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case veryGood = 5
    var id: Int { rawValue }
}

enum MoodTag: String, Codable, CaseIterable, Identifiable {
    case happy
    case sad
    case tired
    case stressed
    case grateful
    case motivated
    case overwhelmed
    case relaxed
    var id: String { rawValue }
}

struct MoodEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var day: String
    var recordedAt: Date
    var level: MoodLevel
    var tags: [MoodTag]
    var note: String
    var journalEntryID: UUID?
}

struct MoodDayPoint: Equatable {
    var day: String
    var average: Double
}

struct MoodTagCount: Equatable {
    var tag: MoodTag
    var count: Int
}

struct MoodTrend: Equatable {
    var daily: [MoodDayPoint]
    var average: Double?
    var previousAverage: Double?
    var delta: Double?
    var entryCount: Int
    var tagCounts: [MoodTagCount]

    var direction: MoodDirection {
        guard let delta else { return .unknown }
        if delta > 0.15 { return .up }
        if delta < -0.15 { return .down }
        return .flat
    }
}

enum MoodDirection {
    case up
    case down
    case flat
    case unknown
}

enum MoodMath {
    static func trend(entries: [MoodEntry], days: [String], previousDays: [String]) -> MoodTrend {
        let daySet = Set(days)
        let inWindow = entries.filter { daySet.contains($0.day) }
        let daily = days.compactMap { day -> MoodDayPoint? in
            let values = inWindow.filter { $0.day == day }.map { Double($0.level.rawValue) }
            guard !values.isEmpty else { return nil }
            return MoodDayPoint(day: day, average: values.reduce(0, +) / Double(values.count))
        }
        let previousValues = previousDays.compactMap { day -> Double? in
            let values = entries.filter { $0.day == day }.map { Double($0.level.rawValue) }
            guard !values.isEmpty else { return nil }
            return values.reduce(0, +) / Double(values.count)
        }
        let average = mean(daily.map(\.average))
        let previous = mean(previousValues)
        let delta: Double?
        if let average, let previous {
            delta = average - previous
        } else {
            delta = nil
        }
        var counts: [MoodTag: Int] = [:]
        for entry in inWindow {
            for tag in entry.tags {
                counts[tag, default: 0] += 1
            }
        }
        let tags = MoodTag.allCases.compactMap { tag -> MoodTagCount? in
            guard let count = counts[tag], count > 0 else { return nil }
            return MoodTagCount(tag: tag, count: count)
        }.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.tag.rawValue < rhs.tag.rawValue
        }
        return MoodTrend(
            daily: daily,
            average: average,
            previousAverage: previous,
            delta: delta,
            entryCount: inWindow.count,
            tagCounts: tags
        )
    }

    static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    static func selfCheck() -> [String] {
        var failures: [String] = []
        let first = MoodEntry(id: UUID(), day: "2026-04-01", recordedAt: CareDay.timestamp(), level: .bad, tags: [.tired], note: "", journalEntryID: nil)
        let second = MoodEntry(id: UUID(), day: "2026-04-01", recordedAt: CareDay.timestamp(), level: .good, tags: [.tired, .grateful], note: "", journalEntryID: nil)
        let third = MoodEntry(id: UUID(), day: "2026-04-02", recordedAt: CareDay.timestamp(), level: .veryGood, tags: [.happy], note: "", journalEntryID: nil)
        let older = MoodEntry(id: UUID(), day: "2026-03-31", recordedAt: CareDay.timestamp(), level: .bad, tags: [.sad], note: "", journalEntryID: nil)
        let sample = Self.trend(
            entries: [first, second, third, older],
            days: ["2026-04-01", "2026-04-02"],
            previousDays: ["2026-03-31"]
        )
        let dayOne = sample.daily.first { $0.day == "2026-04-01" }?.average
        if dayOne != 3 {
            failures.append("daily mood average should be 3, was \(String(describing: dayOne))")
        }
        if sample.average != 4 {
            failures.append("period mood average should be 4, was \(String(describing: sample.average))")
        }
        if sample.previousAverage != 2 {
            failures.append("previous mood average should be 2")
        }
        if sample.delta != 2 {
            failures.append("mood delta should be 2")
        }
        if sample.entryCount != 3 {
            failures.append("mood window should count 3 entries")
        }
        if sample.tagCounts.first?.tag != .tired || sample.tagCounts.first?.count != 2 {
            failures.append("tired should be the most common tag")
        }
        if sample.direction != .up {
            failures.append("mood direction should be up")
        }
        let empty = Self.trend(entries: [], days: ["2026-04-01"], previousDays: [])
        if empty.average != nil || empty.direction != .unknown {
            failures.append("empty mood window should have no average")
        }
        return failures
    }
}
