import Foundation

@MainActor
enum InsightsReader {
    static func snapshot(_ engine: GoobyEngine) -> InsightsSnapshot {
        let hold = LookMark.holdHabit
        let moods = engine.all(MoodEntry.self).map { entry in
            InsightsMoodMark(
                dayKey: entry.dayKey.isEmpty ? DayKey.make(entry.recordedAt) : entry.dayKey,
                recordedAt: entry.recordedAt,
                level: entry.level,
                tags: entry.tags
            )
        }
        let notes = engine.all(JournalEntry.self).map { entry in
            let tags = entry.tags
            return InsightsNoteMark(
                id: entry.id.uuidString,
                dayKey: entry.dayKey.isEmpty ? DayKey.make(entry.createdAt) : entry.dayKey,
                title: entry.title,
                body: entry.body,
                tags: tags,
                theme: theme(promptID: entry.promptID, tags: tags)
            )
        }
        let habits = engine.habits().filter { $0.id != hold }.enumerated().map { index, habit in
            InsightsHabitMark(
                id: habit.id,
                ordinal: index,
                title: habit.title,
                icon: habit.icon,
                recurrence: habit.recurrence,
                archived: habit.isArchived,
                paused: habit.isPaused,
                startDate: habit.startDate,
                endDate: habit.endDate,
                weekdays: habit.weekdays,
                intervalDays: habit.intervalDays,
                timesPerDay: habit.timesPerDay,
                movedFromKey: habit.movedFromKey,
                movedToKey: habit.movedToKey
            )
        }
        let logs = engine.all(HabitLog.self).compactMap { log -> InsightsLogMark? in
            guard log.habitID != hold, !log.dayKey.isEmpty else { return nil }
            return InsightsLogMark(habitID: log.habitID, dayKey: log.dayKey, count: log.count, skipped: log.skipped)
        }
        return InsightsSnapshot(now: engine.now(), moods: moods, notes: notes, habits: habits, logs: logs)
    }

    private static func theme(promptID: String, tags: [String]) -> String {
        let known = ["gratitude", "worth", "motive", "stress", "day", "feel", "grounding", "mind"]
        if let tag = tags.first(where: { known.contains($0.lowercased()) }) {
            return tag.lowercased()
        }
        let head = promptID.split(separator: "-").first.map(String.init) ?? ""
        return known.contains(head) ? head : ""
    }
}
