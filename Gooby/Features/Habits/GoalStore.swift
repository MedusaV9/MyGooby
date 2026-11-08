import Foundation

struct CustomCareArea: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var glyph: String
    var tint: UInt32
}

struct CareGoalMeta: Codable {
    var links: [String: String] = [:]
    var dayparts: [String: String] = [:]
    var customAreas: [CustomCareArea] = []
    var focused: [String] = []
    var didSeed: Bool = false
}

@MainActor
final class GoalMetaStore {
    private(set) var meta = CareGoalMeta()
    private let url: URL

    init() {
        url = GoobyFiles.supportDirectory().appendingPathComponent("care-goal-meta.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(CareGoalMeta.self, from: data) else { return }
        meta = decoded
    }

    func replace(_ next: CareGoalMeta) {
        meta = next
        persist()
    }

    func update(_ body: (inout CareGoalMeta) -> Void) {
        body(&meta)
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(meta) else { return }
        try? data.write(to: url, options: .atomic)
        GoobyFiles.exclude(url)
    }

    func custom(_ id: String) -> CustomCareArea? {
        meta.customAreas.first { $0.id == id }
    }
}

enum GoalDaypart {
    static let order = ["any", "morning", "afternoon", "evening", "night"]

    static func hour(for part: String) -> Int {
        switch part {
        case "morning": return 8
        case "afternoon": return 14
        case "evening": return 19
        case "night": return 22
        default: return -1
        }
    }
}

@MainActor
enum GoalActions {
    static func ensureReferenceGoals(engine: GoobyEngine, store: GoalMetaStore) {
        guard !store.meta.didSeed else { return }
        var meta = store.meta
        let existing = engine.habits()
        for habit in existing {
            habit.sortIndex += GoalCatalog.starters.count
        }
        for (index, starter) in GoalCatalog.starters.enumerated() {
            guard let suggestion = GoalCatalog.suggestion(starter.id) else { continue }
            if let found = existing.first(where: { GoalCatalog.matches($0, suggestion) }) {
                meta.links[found.id.uuidString] = suggestion.id
                meta.dayparts[found.id.uuidString] = meta.dayparts[found.id.uuidString] ?? "any"
                found.sortIndex = index
                if starter.showArea {
                    found.category = suggestion.areaID
                }
                continue
            }
            let habit = insert(
                engine: engine,
                title: suggestion.title(engine.languageCode),
                suggestion: suggestion,
                areaID: starter.showArea ? suggestion.areaID : "",
                daypart: "any",
                energy: suggestion.energy,
                sortIndex: index,
                save: false
            )
            meta.links[habit.id.uuidString] = suggestion.id
            meta.dayparts[habit.id.uuidString] = "any"
        }
        meta.didSeed = true
        store.replace(meta)
        engine.save()
    }

    @discardableResult
    static func addSuggestion(_ suggestion: GoalSuggestion, engine: GoobyEngine, store: GoalMetaStore) -> Habit? {
        if let existing = habit(for: suggestion, engine: engine, store: store) {
            return existing
        }
        let habit = insert(
            engine: engine,
            title: suggestion.title(engine.languageCode),
            suggestion: suggestion,
            areaID: suggestion.areaID,
            daypart: "any",
            energy: suggestion.energy,
            sortIndex: (engine.habits().map(\.sortIndex).max() ?? -1) + 1,
            save: true
        )
        store.update { meta in
            meta.links[habit.id.uuidString] = suggestion.id
            meta.dayparts[habit.id.uuidString] = "any"
        }
        return habit
    }

    @discardableResult
    static func addCustom(title: String, areaID: String, daypart: String, energy: Int, remind: Bool, engine: GoobyEngine, store: GoalMetaStore) -> Habit? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let glyph = GoalCatalog.area(areaID)?.glyph ?? "star"
        let suggestion = GoalSuggestion(id: "custom", areaID: areaID, glyph: glyph, energy: energy, en: trimmed, de: trimmed)
        let habit = insert(
            engine: engine,
            title: trimmed,
            suggestion: suggestion,
            areaID: areaID,
            daypart: daypart,
            energy: energy,
            sortIndex: (engine.habits().map(\.sortIndex).max() ?? -1) + 1,
            save: false
        )
        applyReminder(habit, daypart: daypart, remind: remind)
        engine.save()
        engine.rescheduleNotifications()
        store.update { meta in
            meta.dayparts[habit.id.uuidString] = daypart
        }
        return habit
    }

    static func update(
        _ habit: Habit,
        title: String,
        areaID: String,
        daypart: String,
        energy: Int,
        remind: Bool,
        engine: GoobyEngine,
        store: GoalMetaStore
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        habit.title = trimmed
        habit.category = areaID
        habit.energyReward = min(20, max(0, energy))
        if let link = store.meta.links[habit.id.uuidString], let suggestion = GoalCatalog.suggestion(link) {
            habit.icon = GoalArt.symbol(for: suggestion.glyph)
        } else if let area = GoalCatalog.area(areaID) {
            habit.icon = GoalArt.symbol(for: area.glyph)
        } else if let custom = store.custom(areaID) {
            habit.icon = GoalArt.symbol(for: custom.glyph)
        }
        if let area = GoalCatalog.area(areaID) {
            habit.colorHex = String(format: "%06X", area.tint)
        } else if let custom = store.custom(areaID) {
            habit.colorHex = String(format: "%06X", custom.tint)
        }
        applyReminder(habit, daypart: daypart, remind: remind)
        engine.save()
        engine.rescheduleNotifications()
        store.update { meta in
            meta.dayparts[habit.id.uuidString] = daypart
        }
    }

    static func toggleComplete(_ habit: Habit, engine: GoobyEngine) {
        let key = engine.dayKey()
        let log = engine.habitLog(habit.id, key)
        let cap = max(1, habit.timesPerDay)
        if (log?.count ?? 0) >= cap {
            engine.undoHabit(habit, on: engine.now())
        } else {
            engine.completeHabit(habit, on: engine.now())
        }
    }

    static func move(_ habit: Habit, direction: Int, engine: GoobyEngine, rows: [Habit]) {
        guard let index = rows.firstIndex(where: { $0.id == habit.id }) else { return }
        let next = index + direction
        guard rows.indices.contains(next) else { return }
        let other = rows[next]
        let saved = habit.sortIndex
        habit.sortIndex = other.sortIndex
        other.sortIndex = saved
        if habit.sortIndex == other.sortIndex {
            for (offset, row) in rows.enumerated() {
                row.sortIndex = offset * 10
            }
            let swapped = rows[index].sortIndex
            rows[index].sortIndex = rows[next].sortIndex
            rows[next].sortIndex = swapped
        }
        engine.save()
    }

    static func createArea(name: String, store: GoalMetaStore) -> CustomCareArea? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let palette: [UInt32] = [0xF7B4C8, 0xC9B7F5, 0x9FD9C8, 0xF6D56A, 0x8EC8F5, 0xF3B56A]
        let glyphs = ["star", "heart", "flower", "sun", "home", "leaf"]
        let index = trimmed.unicodeScalars.reduce(0) { $0 + Int($1.value) } % palette.count
        let area = CustomCareArea(id: "custom-\(UUID().uuidString)", name: String(trimmed.prefix(40)), glyph: glyphs[index], tint: palette[index])
        store.update { $0.customAreas.append(area) }
        return area
    }

    static func deleteArea(_ id: String, engine: GoobyEngine, store: GoalMetaStore) {
        for habit in engine.habits() where habit.category == id {
            habit.category = ""
        }
        engine.save()
        store.update { meta in
            meta.customAreas.removeAll { $0.id == id }
            meta.focused.removeAll { $0 == id }
        }
    }

    static func toggleFocus(_ id: String, store: GoalMetaStore) {
        store.update { meta in
            if let index = meta.focused.firstIndex(of: id) {
                meta.focused.remove(at: index)
            } else {
                meta.focused.append(id)
            }
        }
    }

    static func areaName(for habit: Habit, language: String, store: GoalMetaStore) -> String? {
        let id = habit.category
        guard !id.isEmpty else { return nil }
        if let area = GoalCatalog.area(id) { return area.name(language) }
        if let custom = store.custom(id) { return custom.name }
        return nil
    }

    static func glyph(for habit: Habit, store: GoalMetaStore) -> String {
        if let link = store.meta.links[habit.id.uuidString], let suggestion = GoalCatalog.suggestion(link) {
            return suggestion.glyph
        }
        if let area = GoalCatalog.area(habit.category) { return area.glyph }
        if let custom = store.custom(habit.category) { return custom.glyph }
        return GoalArt.glyph(forSymbol: habit.icon)
    }

    static func isAdded(_ suggestion: GoalSuggestion, engine: GoobyEngine, store: GoalMetaStore) -> Bool {
        habit(for: suggestion, engine: engine, store: store) != nil
    }

    static func habit(for suggestion: GoalSuggestion, engine: GoobyEngine, store: GoalMetaStore) -> Habit? {
        let habits = engine.habits().filter { !$0.isArchived }
        if let linked = habits.first(where: { store.meta.links[$0.id.uuidString] == suggestion.id }) {
            return linked
        }
        return habits.first { GoalCatalog.matches($0, suggestion) }
    }

    static func matches(daypart filter: String, habit: Habit, store: GoalMetaStore) -> Bool {
        if filter == "any" { return true }
        let stored = store.meta.dayparts[habit.id.uuidString] ?? "any"
        if stored == filter { return true }
        let hour = habit.reminderHour
        guard hour >= 0 else { return false }
        switch filter {
        case "morning": return (5..<12).contains(hour)
        case "afternoon": return (12..<17).contains(hour)
        case "evening": return (17..<21).contains(hour)
        case "night": return hour >= 21 || hour < 5
        default: return true
        }
    }

    private static func applyReminder(_ habit: Habit, daypart: String, remind: Bool) {
        if remind {
            let hour = GoalDaypart.hour(for: daypart)
            habit.reminderHour = hour >= 0 ? hour : 9
            habit.reminderMinute = 0
        } else if habit.reminderHour >= 0 && !remind {
            habit.reminderHour = -1
        }
    }

    @discardableResult
    private static func insert(
        engine: GoobyEngine,
        title: String,
        suggestion: GoalSuggestion,
        areaID: String,
        daypart: String,
        energy: Int,
        sortIndex: Int,
        save: Bool
    ) -> Habit {
        let habit = Habit()
        habit.title = title
        habit.details = ""
        habit.icon = GoalArt.symbol(for: suggestion.glyph)
        let tint = GoalCatalog.area(suggestion.areaID)?.tint ?? 0xC6EFDC
        habit.colorHex = String(format: "%06X", tint)
        habit.category = areaID
        habit.priority = 1
        habit.startDate = Calendar.current.startOfDay(for: engine.now())
        habit.recurrence = "daily"
        habit.timesPerDay = 1
        habit.energyReward = energy
        habit.sparkReward = 2
        habit.sortIndex = sortIndex
        habit.reminderHour = -1
        _ = daypart
        engine.context.insert(habit)
        if save {
            engine.save()
            engine.rescheduleNotifications()
        }
        return habit
    }
}
