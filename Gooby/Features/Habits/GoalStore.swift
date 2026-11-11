import Foundation

struct CustomCareArea: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var glyph: String
    var tint: UInt32
}

struct CareBucket: Codable, Identifiable, Hashable {
    var id: String
    var name: String
}

struct GoalSectionModel: Identifiable {
    var id: String
    var title: String
    var habits: [Habit]
}

struct GoalCommit {
    var title: String
    var areaID: String = ""
    var daypart: String = "any"
    var recurrence: String = "daily"
    var weekdays: [Int] = []
    var timesPerDay: Int = 1
    var remind: Bool = false
    var energy: Int = 5
    var exerciseID: String = ""
    var suggestionID: String = ""
    var glyph: String = "star"
    var preserveSchedule: Bool = false
}

struct CareGoalMeta: Codable {
    var links: [String: String] = [:]
    var dayparts: [String: String] = [:]
    var customAreas: [CustomCareArea] = []
    var focused: [String] = []
    var didSeed: Bool = false
    var exercises: [String: String] = [:]
    var groupMode: String = "time"
    var expandSections: Bool = true
    var buckets: [CareBucket] = []
    var customBuckets: [String: String] = [:]
    var started: [String] = []
    var starredExercises: [String] = []
    var didLinkStarters: Bool = false

    private enum CodingKeys: String, CodingKey {
        case links, dayparts, customAreas, focused, didSeed, exercises, groupMode
        case expandSections, buckets, customBuckets, started, starredExercises, didLinkStarters
    }

    init() {}

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        links = try box.decodeIfPresent([String: String].self, forKey: .links) ?? [:]
        dayparts = try box.decodeIfPresent([String: String].self, forKey: .dayparts) ?? [:]
        customAreas = try box.decodeIfPresent([CustomCareArea].self, forKey: .customAreas) ?? []
        focused = try box.decodeIfPresent([String].self, forKey: .focused) ?? []
        didSeed = try box.decodeIfPresent(Bool.self, forKey: .didSeed) ?? false
        exercises = try box.decodeIfPresent([String: String].self, forKey: .exercises) ?? [:]
        groupMode = try box.decodeIfPresent(String.self, forKey: .groupMode) ?? "time"
        expandSections = try box.decodeIfPresent(Bool.self, forKey: .expandSections) ?? true
        buckets = try box.decodeIfPresent([CareBucket].self, forKey: .buckets) ?? []
        customBuckets = try box.decodeIfPresent([String: String].self, forKey: .customBuckets) ?? [:]
        started = try box.decodeIfPresent([String].self, forKey: .started) ?? []
        starredExercises = try box.decodeIfPresent([String].self, forKey: .starredExercises) ?? []
        didLinkStarters = try box.decodeIfPresent(Bool.self, forKey: .didLinkStarters) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        try box.encode(links, forKey: .links)
        try box.encode(dayparts, forKey: .dayparts)
        try box.encode(customAreas, forKey: .customAreas)
        try box.encode(focused, forKey: .focused)
        try box.encode(didSeed, forKey: .didSeed)
        try box.encode(exercises, forKey: .exercises)
        try box.encode(groupMode, forKey: .groupMode)
        try box.encode(expandSections, forKey: .expandSections)
        try box.encode(buckets, forKey: .buckets)
        try box.encode(customBuckets, forKey: .customBuckets)
        try box.encode(started, forKey: .started)
        try box.encode(starredExercises, forKey: .starredExercises)
        try box.encode(didLinkStarters, forKey: .didLinkStarters)
    }
}

@MainActor
final class GoalMetaStore {
    private(set) var meta = CareGoalMeta()
    private let url: URL
    private static var memory: CareGoalMeta?
    private static var memoryStamp: Date?

    init() {
        url = GoobyFiles.supportDirectory().appendingPathComponent("care-goal-meta.json")
        load()
    }

    static func peek() -> CareGoalMeta {
        let url = GoobyFiles.supportDirectory().appendingPathComponent("care-goal-meta.json")
        let stamp = fileStamp(url)
        if let memory, memoryStamp == stamp { return memory }
        let loaded: CareGoalMeta
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(CareGoalMeta.self, from: data) {
            loaded = decoded
        } else {
            loaded = CareGoalMeta()
        }
        memory = loaded
        memoryStamp = stamp
        return loaded
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
        Self.memory = meta
        Self.memoryStamp = Self.fileStamp(url)
    }

    private static func fileStamp(_ url: URL) -> Date? {
        guard let values = try? FileManager.default.attributesOfItem(atPath: url.path) else { return nil }
        return values[.modificationDate] as? Date
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
        if store.meta.didSeed {
            ensureStarterLinks(engine: engine, store: store)
            return
        }
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
        ensureStarterLinks(engine: engine, store: store)
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

    static func ensureStarterLinks(engine: GoobyEngine, store: GoalMetaStore) {
        guard !store.meta.didLinkStarters else { return }
        var meta = store.meta
        var changed = false
        for habit in engine.habits() where !habit.isArchived {
            let key = habit.id.uuidString
            let suggestionID = meta.links[key] ?? GoalCatalog.suggestions.first { GoalCatalog.matches(habit, $0) }?.id
            guard let suggestionID, let exerciseID = GoalExerciseCatalog.starterLink(for: suggestionID) else { continue }
            if meta.exercises[key] == nil {
                meta.exercises[key] = exerciseID
                habit.energyReward = GoalExerciseCatalog.energy(for: exerciseID)
                changed = true
            }
        }
        meta.didLinkStarters = true
        store.replace(meta)
        if changed { engine.save() }
    }

    @discardableResult
    static func commit(_ draft: GoalCommit, habit existing: Habit?, engine: GoobyEngine, store: GoalMetaStore) -> Habit? {
        let trimmed = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let habit: Habit
        let isNew: Bool
        if let existing {
            habit = existing
            isNew = false
        } else if !draft.suggestionID.isEmpty,
                  let suggestion = GoalCatalog.suggestion(draft.suggestionID),
                  let found = Self.habit(for: suggestion, engine: engine, store: store) {
            habit = found
            isNew = false
        } else {
            habit = Habit()
            habit.sparkReward = 2
            habit.priority = 1
            habit.sortIndex = (engine.habits().map(\.sortIndex).max() ?? -1) + 1
            habit.reminderHour = -1
            engine.context.insert(habit)
            isNew = true
        }
        habit.title = trimmed
        habit.category = draft.areaID
        habit.timesPerDay = min(8, max(1, draft.timesPerDay))
        if draft.exerciseID.isEmpty {
            habit.energyReward = min(20, max(0, draft.energy))
        } else {
            habit.energyReward = min(20, max(0, GoalExerciseCatalog.energy(for: draft.exerciseID)))
        }
        if !draft.preserveSchedule {
            habit.recurrence = draft.recurrence
            habit.weekdays = draft.weekdays.sorted()
            habit.intervalDays = 1
            if draft.recurrence == "once" || isNew {
                habit.startDate = Calendar.current.startOfDay(for: engine.now())
            }
        } else if isNew {
            habit.startDate = Calendar.current.startOfDay(for: engine.now())
            habit.recurrence = "daily"
        }
        let glyph = resolvedGlyph(draft, store: store)
        habit.icon = GoalArt.symbol(for: glyph)
        habit.colorHex = String(format: "%06X", tint(for: draft.areaID, store: store))
        applyReminder(habit, daypart: draft.daypart, remind: draft.remind)
        engine.save()
        engine.rescheduleNotifications()
        store.update { meta in
            if !draft.suggestionID.isEmpty {
                meta.links[habit.id.uuidString] = draft.suggestionID
            }
            meta.dayparts[habit.id.uuidString] = draft.daypart
            if draft.exerciseID.isEmpty {
                meta.exercises.removeValue(forKey: habit.id.uuidString)
            } else {
                meta.exercises[habit.id.uuidString] = draft.exerciseID
            }
            if !draft.areaID.isEmpty && !meta.started.contains(draft.areaID) {
                meta.started.append(draft.areaID)
            }
        }
        return habit
    }

    static func forget(_ habit: Habit, engine: GoobyEngine, store: GoalMetaStore) {
        let key = habit.id.uuidString
        engine.deleteHabit(habit)
        store.update { meta in
            meta.links.removeValue(forKey: key)
            meta.dayparts.removeValue(forKey: key)
            meta.exercises.removeValue(forKey: key)
            meta.customBuckets.removeValue(forKey: key)
        }
    }

    static func tint(for areaID: String, store: GoalMetaStore) -> UInt32 {
        if let area = GoalCatalog.area(areaID) { return area.tint }
        if let custom = store.custom(areaID) { return custom.tint }
        return 0xC9B7F5
    }

    static func glyphName(for areaID: String, store: GoalMetaStore) -> String {
        if let area = GoalCatalog.area(areaID) { return area.glyph }
        if let custom = store.custom(areaID) { return custom.glyph }
        return "star"
    }

    static func markStarted(_ id: String, store: GoalMetaStore) {
        guard !id.isEmpty else { return }
        store.update { meta in
            if !meta.started.contains(id) { meta.started.append(id) }
        }
    }

    static func addBucket(name: String, store: GoalMetaStore) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let bucket = CareBucket(id: "bucket-\(UUID().uuidString)", name: String(trimmed.prefix(40)))
        store.update { $0.buckets.append(bucket) }
    }

    static func assign(_ habit: Habit, bucket: String, store: GoalMetaStore) {
        store.update { meta in
            if bucket.isEmpty {
                meta.customBuckets.removeValue(forKey: habit.id.uuidString)
            } else {
                meta.customBuckets[habit.id.uuidString] = bucket
            }
        }
    }

    static func toggleStar(_ id: String, store: GoalMetaStore) {
        store.update { meta in
            if let index = meta.starredExercises.firstIndex(of: id) {
                meta.starredExercises.remove(at: index)
            } else {
                meta.starredExercises.append(id)
            }
        }
    }

    static func sections(for habits: [Habit], engine: GoobyEngine, store: GoalMetaStore) -> [GoalSectionModel] {
        switch store.meta.groupMode {
        case "area":
            return areaSections(habits, engine: engine, store: store)
        case "custom":
            return customSections(habits, engine: engine, store: store)
        default:
            return timeSections(habits, engine: engine, store: store)
        }
    }

    static func linkedExerciseID(_ habit: Habit, store: GoalMetaStore) -> String {
        store.meta.exercises[habit.id.uuidString] ?? ""
    }

    private static func resolvedGlyph(_ draft: GoalCommit, store: GoalMetaStore) -> String {
        if !draft.suggestionID.isEmpty, let suggestion = GoalCatalog.suggestion(draft.suggestionID) {
            return suggestion.glyph
        }
        if !draft.glyph.isEmpty && draft.glyph != "star" { return draft.glyph }
        return glyphName(for: draft.areaID, store: store)
    }

    private static func timeSections(_ habits: [Habit], engine: GoobyEngine, store: GoalMetaStore) -> [GoalSectionModel] {
        GoalDaypart.order.compactMap { part in
            let rows = habits.filter { (store.meta.dayparts[$0.id.uuidString] ?? "any") == part }
            guard !rows.isEmpty else { return nil }
            return GoalSectionModel(id: part, title: engine.t("care.filter.\(part)"), habits: rows)
        }
    }

    private static func areaSections(_ habits: [Habit], engine: GoobyEngine, store: GoalMetaStore) -> [GoalSectionModel] {
        var result: [GoalSectionModel] = []
        for area in GoalCatalog.areas {
            let rows = habits.filter { $0.category == area.id }
            guard !rows.isEmpty else { continue }
            result.append(GoalSectionModel(id: area.id, title: area.name(engine.languageCode), habits: rows))
        }
        for area in store.meta.customAreas {
            let rows = habits.filter { $0.category == area.id }
            guard !rows.isEmpty else { continue }
            result.append(GoalSectionModel(id: area.id, title: area.name, habits: rows))
        }
        let known = Set(GoalCatalog.areas.map(\.id) + store.meta.customAreas.map(\.id))
        let loose = habits.filter { $0.category.isEmpty || !known.contains($0.category) }
        if !loose.isEmpty {
            result.append(GoalSectionModel(id: "none", title: engine.t("care.area.none"), habits: loose))
        }
        return result
    }

    private static func customSections(_ habits: [Habit], engine: GoobyEngine, store: GoalMetaStore) -> [GoalSectionModel] {
        var result: [GoalSectionModel] = []
        let known = Set(store.meta.buckets.map(\.id))
        for bucket in store.meta.buckets {
            let rows = habits.filter { store.meta.customBuckets[$0.id.uuidString] == bucket.id }
            result.append(GoalSectionModel(id: bucket.id, title: bucket.name, habits: rows))
        }
        let loose = habits.filter { habit in
            let bucket = store.meta.customBuckets[habit.id.uuidString] ?? ""
            return bucket.isEmpty || !known.contains(bucket)
        }
        if !loose.isEmpty {
            result.append(GoalSectionModel(id: "loose", title: engine.t("care.group.loose"), habits: loose))
        }
        return result
    }
}
