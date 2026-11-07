import Foundation

/// Time-of-day sections of the Home goal list, derived from the habit category.
enum HomeGoalSection: String, CaseIterable, Identifiable {
    case morning, anytime, evening

    var id: String { rawValue }

    static func of(_ habit: Habit) -> HomeGoalSection {
        switch habit.category {
        case "morning": return .morning
        case "evening", "sleep": return .evening
        default: return .anytime
        }
    }

    /// Category preset for a goal added with this section's "+".
    var presetCategory: String? {
        switch self {
        case .morning: return "morning"
        case .evening: return "evening"
        case .anytime: return nil
        }
    }
}

/// Today's adventure as the Home card shows it.
enum HomeAdventureState: Equatable {
    /// No run today, energy below the goal.
    case gathering(energy: Int, goal: Int)
    /// No run today, energy goal reached.
    case ready
    /// On the way; `progress` runs from 0 at the start to 1 at the return time.
    case traveling(progress: Double, returnsAt: Date)
    /// Back home, the story is waiting.
    case returned
    /// Today's story has been answered.
    case told
}

extension GoobyEngine {
    func homeAdventureState(at date: Date) -> HomeAdventureState {
        if let run = todaysRun() {
            if run.status == "claimed" { return .told }
            if run.status == "ready" || date >= run.returnsAt { return .returned }
            let total = run.returnsAt.timeIntervalSince(run.startedAt)
            let elapsed = date.timeIntervalSince(run.startedAt)
            let fraction = total > 0 ? min(1, max(0, elapsed / total)) : 1
            return .traveling(progress: fraction, returnsAt: run.returnsAt)
        }
        let goal = max(1, profile.energyGoal)
        if wallet.energy >= goal { return .ready }
        return .gathering(energy: max(0, wallet.energy), goal: goal)
    }

    /// True while Gooby is out on today's adventure (the Home scene shows the forest).
    func homeIsOutside(at date: Date) -> Bool {
        if case .traveling = homeAdventureState(at: date) { return true }
        return false
    }

    func homeIsDone(_ habit: Habit, on date: Date) -> Bool {
        (habitLog(habit.id, DayKey.make(date))?.count ?? 0) >= max(1, habit.timesPerDay)
    }

    /// Goals due today that are not finished yet.
    func homeGoalsLeft() -> Int {
        let today = now()
        return dueHabits(on: today).filter { !homeIsDone($0, on: today) }.count
    }

    /// Latest mood entry of today, if any.
    func homeMoodToday() -> MoodEntry? {
        let key = dayKey()
        return all(MoodEntry.self).filter { $0.dayKey == key }.max { $0.recordedAt < $1.recordedAt }
    }

    /// Moves `habit` onto the place of `target` in the goal order (after it when dragged down,
    /// before it when dragged up) and renumbers `sortIndex`. Priority sorts before `sortIndex`, so
    /// the moved goal takes the target's priority; otherwise it would jump back to its old place.
    func homeMove(_ habit: Habit, onto target: Habit) {
        guard habit.id != target.id else { return }
        let current = habits()
        let from = current.firstIndex { $0.id == habit.id } ?? 0
        let to = current.firstIndex { $0.id == target.id } ?? current.count
        var ordered = current.filter { $0.id != habit.id }
        let anchor = ordered.firstIndex { $0.id == target.id } ?? ordered.count
        let index = from < to ? min(ordered.count, anchor + 1) : anchor
        habit.priority = target.priority
        ordered.insert(habit, at: index)
        for (position, row) in ordered.enumerated() where row.sortIndex != position {
            row.sortIndex = position
        }
        save()
    }
}
