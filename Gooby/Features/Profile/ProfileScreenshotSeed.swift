import Foundation

#if DEBUG
extension GoobyScreenshotMode {
    /// Matches the reference profile frame: He/Him and a one-day streak that ended yesterday,
    /// so today's goals on Home stay untouched.
    @MainActor
    static func seedProfile(_ engine: GoobyEngine) {
        guard screen == "profile" else { return }
        if engine.pet.pronouns.isEmpty { engine.pet.pronouns = PetPronounChoice.he.stored }
        guard engine.all(HabitLog.self).isEmpty,
              let habit = engine.habits().first,
              let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: engine.now()) else { return }
        let log = HabitLog()
        log.habitID = habit.id
        log.dayKey = DayKey.make(Calendar.current.startOfDay(for: yesterday))
        log.count = max(1, habit.timesPerDay)
        log.createdAt = yesterday
        engine.context.insert(log)
    }
}
#endif
