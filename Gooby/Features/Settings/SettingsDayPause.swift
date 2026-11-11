import Foundation
import SwiftData

/// Pause for the current day. Habits that would be on today's list get `Habit.isPaused`,
/// which the existing day list and reminders already skip. A habit paused on its own stays paused.
/// Habits this mode paused, and that are not due today, are released so the next day can take them again.
@MainActor
enum SettingsDayPause {
    static func apply(_ engine: GoobyEngine) {
        guard LookMark.isOn(engine, LookMark.pause) else { return }
        if (UserDefaults.standard.string(forKey: LookMark.pauseStart) ?? "").isEmpty {
            UserDefaults.standard.set(engine.dayKey(), forKey: LookMark.pauseStart)
        }

        var owned = Set(UserDefaults.standard.stringArray(forKey: LookMark.pauseIDs) ?? [])
        var changed = false
        let live = engine.habits()
        for habit in live where !habit.isArchived {
            let id = habit.id.uuidString
            let ownedByPause = owned.contains(id)
            if habit.isPaused && !ownedByPause { continue }
            if dueIfAwake(engine, habit) {
                if !habit.isPaused {
                    habit.isPaused = true
                    changed = true
                }
                owned.insert(id)
            } else if ownedByPause {
                if habit.isPaused {
                    habit.isPaused = false
                    changed = true
                }
                owned.remove(id)
            }
        }

        let stillHere = Set(live.filter { !$0.isArchived }.map(\.id.uuidString))
        owned = owned.intersection(stillHere)
        let next = owned.sorted()
        let stored = (UserDefaults.standard.stringArray(forKey: LookMark.pauseIDs) ?? []).sorted()
        if stored != next {
            UserDefaults.standard.set(next, forKey: LookMark.pauseIDs)
        }
        if holdStreak(engine) { changed = true }
        guard changed else { return }
        engine.save()
        engine.rescheduleNotifications()
    }

    static func setOn(_ engine: GoobyEngine, _ on: Bool) {
        if on {
            if (UserDefaults.standard.string(forKey: LookMark.pauseStart) ?? "").isEmpty {
                UserDefaults.standard.set(engine.dayKey(), forKey: LookMark.pauseStart)
            }
            LookMark.set(engine, LookMark.pause, true)
            apply(engine)
            engine.rescheduleNotifications()
            return
        }
        let owned = Set(UserDefaults.standard.stringArray(forKey: LookMark.pauseIDs) ?? [])
        for habit in engine.habits() where owned.contains(habit.id.uuidString) {
            habit.isPaused = false
        }
        LookMark.set(engine, LookMark.pause, false)
        UserDefaults.standard.removeObject(forKey: LookMark.pauseIDs)
        UserDefaults.standard.removeObject(forKey: LookMark.pauseStart)
        engine.rescheduleNotifications()
    }

    private static func dueIfAwake(_ engine: GoobyEngine, _ habit: Habit) -> Bool {
        let was = habit.isPaused
        habit.isPaused = false
        let due = engine.isDue(habit, on: engine.now())
        habit.isPaused = was
        return due
    }

    private static func holdStreak(_ engine: GoobyEngine) -> Bool {
        let startKey = UserDefaults.standard.string(forKey: LookMark.pauseStart) ?? engine.dayKey()
        guard var day = DayKey.parse(startKey) else { return false }
        let end = Calendar.current.startOfDay(for: engine.now())
        var inserted = false
        while day <= end {
            let key = DayKey.make(day)
            let real = engine.all(HabitLog.self).contains { log in
                log.dayKey == key && !log.skipped && log.count > 0 && log.habitID != LookMark.holdHabit
            }
            if !real && engine.habitLog(LookMark.holdHabit, key) == nil {
                let log = HabitLog()
                log.habitID = LookMark.holdHabit
                log.dayKey = key
                log.count = 1
                log.skipped = false
                log.createdAt = engine.now()
                engine.context.insert(log)
                inserted = true
            }
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return inserted
    }
}
