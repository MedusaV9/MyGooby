import Foundation

#if DEBUG
/// Content for the Home screenshots, matching reference/finch-frames 081.5s (nest) and 190.0s (adventuring).
enum HomeScreenshotSeed {
    @MainActor
    static func apply(_ screen: String, engine: GoobyEngine) {
        switch screen {
        case "home":
            renameStarters(engine)
            UserDefaults.standard.set(false, forKey: HomeStage.buddyDismissedKey)
        case "home-adventure":
            renameStarters(engine)
            UserDefaults.standard.set(true, forKey: HomeStage.buddyDismissedKey)
            let store = GoalMetaStore()
            let today = engine.now()
            for habit in engine.dueHabits(on: today) where store.meta.dayparts[habit.id.uuidString] == "morning" {
                engine.completeHabit(habit, on: today)
                habit.isArchived = true
            }
            if let tea = GoalCatalog.suggestion("tea"), let habit = GoalActions.addSuggestion(tea, engine: engine, store: store) {
                habit.sortIndex = (engine.habits().map(\.sortIndex).max() ?? 0) + 1
            }
            engine.banner = nil
        default:
            break
        }
    }

    @MainActor
    private static func renameStarters(_ engine: GoobyEngine) {
        guard engine.languageCode == "en" else { return }
        for habit in engine.habits() where habit.title == "Brush my teeth" {
            habit.title = "Brush teeth"
        }
    }
}
#endif
