import Combine
import Foundation

struct CareDatabase: Codable, Equatable {
    var schema: Int = 1
    var nextEventID: Int = 1
    var habits: [Habit] = []
    var records: [HabitDayRecord] = []
    var moods: [MoodEntry] = []
    var journal: [JournalEntry] = []
    var focus: FocusSession?
    var grants: [StoredGrant] = []
    var outbox: [CareReward] = []
}

@MainActor
final class CareStore: ObservableObject {
    static let shared = CareStore(fileURL: CareStore.defaultFileURL(), loadFromDisk: true)

    @Published private(set) var database = CareDatabase()
    private(set) var lastPersistError: String?
    private(set) var quarantinedURL: URL?
    private let fileURL: URL?
    private var rewardHandler: ((CareReward) -> Void)?
    private var flushing = false

    init(fileURL: URL?, loadFromDisk: Bool) {
        self.fileURL = fileURL
        guard loadFromDisk, let fileURL else { return }
        switch Self.read(fileURL) {
        case .missing:
            database = CareDatabase()
        case .loaded(let stored):
            database = stored
        case .failed:
            let badURL = fileURL.appendingPathExtension("bad")
            try? FileManager.default.removeItem(at: badURL)
            try? FileManager.default.moveItem(at: fileURL, to: badURL)
            quarantinedURL = badURL
            database = CareDatabase()
        }
    }

    nonisolated static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = base.appendingPathComponent("Gooby", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var excluded = folder
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)
        return folder.appendingPathComponent("care-store.json")
    }

    func setRewardHandler(_ handler: ((CareReward) -> Void)?) {
        rewardHandler = handler
        flush()
    }

    func habit(_ id: UUID) -> Habit? {
        database.habits.first { $0.id == id }
    }

    func sortedHabits(archived: Bool) -> [Habit] {
        database.habits.filter { $0.archived == archived }.sorted(by: Self.habitSort)
    }

    func pausedHabits(on day: String) -> [Habit] {
        database.habits.filter { !$0.archived && HabitSchedule.isPaused($0, on: day) }.sorted(by: Self.habitSort)
    }

    func dueHabits(on day: String, calendar: Calendar) -> [Habit] {
        database.habits.filter { habit in
            HabitSchedule.isDue(habit: habit, day: day, record: record(habitID: habit.id, day: day), calendar: calendar)
        }.sorted(by: Self.habitSort)
    }

    func progress(for habit: Habit, day: String, calendar: Calendar) -> HabitProgress {
        let existing = record(habitID: habit.id, day: day)
        return HabitProgress(
            due: HabitSchedule.isDue(habit: habit, day: day, record: existing, calendar: calendar),
            completed: existing?.completedCount ?? 0,
            repetitions: habit.repetitions,
            skipped: (existing?.skipped ?? false) && (existing?.completedCount ?? 0) == 0,
            isDailyGoal: habit.isDailyGoal,
            paused: HabitSchedule.isPaused(habit, on: day)
        )
    }

    func completionTotal(for habitID: UUID) -> Int {
        database.records.filter { $0.habitID == habitID }.reduce(0) { $0 + $1.completedCount }
    }

    @discardableResult
    func saveHabit(_ habit: Habit) -> CareIssue? {
        let cleaned = normalized(habit)
        if let issue = HabitValidator.issue(for: cleaned) { return issue }
        if let index = database.habits.firstIndex(where: { $0.id == cleaned.id }) {
            var updated = cleaned
            updated.createdAt = database.habits[index].createdAt
            updated.starterKey = database.habits[index].starterKey
            database.habits[index] = updated
        } else {
            database.habits.append(cleaned)
        }
        if cleaned.isDailyGoal {
            for index in database.habits.indices where database.habits[index].id != cleaned.id {
                database.habits[index].isDailyGoal = false
            }
        }
        commit()
        return nil
    }

    func deleteHabit(id: UUID) {
        database.habits.removeAll { $0.id == id }
        database.records.removeAll { $0.habitID == id }
        commit()
    }

    func setArchived(id: UUID, archived: Bool) -> CareIssue? {
        guard let index = database.habits.firstIndex(where: { $0.id == id }) else { return .missing }
        database.habits[index].archived = archived
        database.habits[index].updatedAt = CareDay.timestamp()
        commit()
        return nil
    }

    func pause(id: UUID, from: String, until: String?) -> CareIssue? {
        guard let index = database.habits.firstIndex(where: { $0.id == id }) else { return .missing }
        if let until, until < from { return .pause }
        database.habits[index].pauseFrom = from
        database.habits[index].pauseUntil = until
        database.habits[index].updatedAt = CareDay.timestamp()
        commit()
        return nil
    }

    func resume(id: UUID) -> CareIssue? {
        guard let index = database.habits.firstIndex(where: { $0.id == id }) else { return .missing }
        database.habits[index].pauseFrom = nil
        database.habits[index].pauseUntil = nil
        database.habits[index].updatedAt = CareDay.timestamp()
        commit()
        return nil
    }

    func completeRep(habitID: UUID, day: String, now: Date, calendar: Calendar) -> Result<[CareReward], CareIssue> {
        guard let habit = habit(habitID) else { return .failure(.missing) }
        if day > CareDay.key(for: now, calendar: calendar) { return .failure(.future) }
        let existing = record(habitID: habitID, day: day)
        if !HabitSchedule.isDue(habit: habit, day: day, record: existing, calendar: calendar) {
            return .failure(.notDue)
        }
        if (existing?.completedCount ?? 0) >= habit.repetitions { return .failure(.alreadyDone) }
        let index = ensureRecord(habitID: habitID, day: day, now: now)
        database.records[index].skipped = false
        database.records[index].completedCount += 1
        database.records[index].updatedAt = CareDay.timestamp(now)
        let count = database.records[index].completedCount
        var rewards: [CareReward] = []
        let repKey = "habit:\(habit.id.uuidString):\(day):rep:\(count)"
        if let reward = enqueue(key: repKey, energy: habit.rewardValue, sparks: habit.rewardValue, reason: "habit", title: habit.title, reversal: false) {
            rewards.append(reward)
        }
        if habit.isDailyGoal && count >= habit.repetitions {
            let goalKey = "habit:\(habit.id.uuidString):\(day):goal"
            if let reward = enqueue(
                key: goalKey,
                energy: CareRewards.dailyGoalEnergy,
                sparks: CareRewards.dailyGoalSparks,
                reason: "daily-goal",
                title: habit.title,
                reversal: false
            ) {
                rewards.append(reward)
            }
        }
        commit()
        return .success(rewards)
    }

    func undoRep(habitID: UUID, day: String, now: Date) -> Result<[CareReward], CareIssue> {
        guard let habit = habit(habitID) else { return .failure(.missing) }
        guard let index = recordIndex(habitID: habitID, day: day), database.records[index].completedCount > 0 else {
            return .failure(.notDue)
        }
        let count = database.records[index].completedCount
        database.records[index].completedCount -= 1
        database.records[index].updatedAt = CareDay.timestamp(now)
        var rewards: [CareReward] = []
        let repKey = "habit:\(habit.id.uuidString):\(day):rep:\(count)"
        if let reward = enqueue(key: repKey, energy: 0, sparks: 0, reason: "habit", title: habit.title, reversal: true) {
            rewards.append(reward)
        }
        if habit.isDailyGoal && count >= habit.repetitions && database.records[index].completedCount < habit.repetitions {
            let goalKey = "habit:\(habit.id.uuidString):\(day):goal"
            if let reward = enqueue(key: goalKey, energy: 0, sparks: 0, reason: "daily-goal", title: habit.title, reversal: true) {
                rewards.append(reward)
            }
        }
        commit()
        return .success(rewards)
    }

    func skip(habitID: UUID, day: String, now: Date, calendar: Calendar) -> CareIssue? {
        guard let habit = habit(habitID) else { return .missing }
        if day > CareDay.key(for: now, calendar: calendar) { return .future }
        let existing = record(habitID: habitID, day: day)
        if !HabitSchedule.isDue(habit: habit, day: day, record: existing, calendar: calendar) { return .notDue }
        if (existing?.completedCount ?? 0) > 0 { return .alreadyDone }
        let index = ensureRecord(habitID: habitID, day: day, now: now)
        database.records[index].skipped = true
        database.records[index].updatedAt = CareDay.timestamp(now)
        commit()
        return nil
    }

    func undoSkip(habitID: UUID, day: String, now: Date) -> CareIssue? {
        guard let index = recordIndex(habitID: habitID, day: day) else { return .notDue }
        database.records[index].skipped = false
        database.records[index].updatedAt = CareDay.timestamp(now)
        commit()
        return nil
    }

    func reschedule(habitID: UUID, from: String, to: String, now: Date, calendar: Calendar) -> CareIssue? {
        guard let habit = habit(habitID) else { return .missing }
        if from == to { return .sameDay }
        let source = record(habitID: habitID, day: from)
        if !HabitSchedule.isDue(habit: habit, day: from, record: source, calendar: calendar) { return .notDue }
        if (source?.completedCount ?? 0) > 0 { return .alreadyDone }
        if to < habit.startDay { return .outOfRange }
        if let end = habit.endDay, to > end { return .outOfRange }
        if HabitSchedule.isPaused(habit, on: to) { return .paused }
        let target = record(habitID: habitID, day: to)
        if HabitSchedule.isDue(habit: habit, day: to, record: target, calendar: calendar) { return .targetDue }
        let sourceIndex = ensureRecord(habitID: habitID, day: from, now: now)
        database.records[sourceIndex].removed = true
        database.records[sourceIndex].skipped = false
        database.records[sourceIndex].movedFrom = nil
        database.records[sourceIndex].completedCount = 0
        database.records[sourceIndex].updatedAt = CareDay.timestamp(now)
        let targetIndex = ensureRecord(habitID: habitID, day: to, now: now)
        database.records[targetIndex].removed = false
        database.records[targetIndex].skipped = false
        database.records[targetIndex].movedFrom = from
        database.records[targetIndex].completedCount = 0
        database.records[targetIndex].updatedAt = CareDay.timestamp(now)
        commit()
        return nil
    }

    func summary(for habit: Habit, day: String, calendar: Calendar) -> CareHabitSummary {
        let state = progress(for: habit, day: day, calendar: calendar)
        return CareHabitSummary(
            id: habit.id,
            title: habit.title,
            symbol: habit.symbol,
            colorHex: habit.colorHex,
            completed: state.completed,
            repetitions: state.repetitions,
            skipped: state.skipped,
            isDailyGoal: habit.isDailyGoal,
            rewardValue: habit.rewardValue,
            paused: state.paused
        )
    }

    func snapshot(on day: String, calendar: Calendar) -> CareDaySnapshot {
        let habits = dueHabits(on: day, calendar: calendar).map { summary(for: $0, day: day, calendar: calendar) }
        let moods = database.moods.filter { $0.day == day }
        return CareDaySnapshot(
            day: day,
            habits: habits,
            moodAverage: MoodMath.mean(moods.map { Double($0.level.rawValue) }),
            moodEntryCount: moods.count,
            journalCount: database.journal.filter { $0.day == day }.count
        )
    }

    func reminderRequests(from day: String, count: Int, now: Date, calendar: Calendar, body: String) -> [CareReminderRequest] {
        guard count > 0 else { return [] }
        var requests: [CareReminderRequest] = []
        for offset in 0..<count {
            guard let key = CareDay.addingDays(offset, to: day, calendar: calendar) else { continue }
            for habit in database.habits {
                guard let reminder = habit.reminder else { continue }
                let existing = record(habitID: habit.id, day: key)
                guard HabitSchedule.isDue(habit: habit, day: key, record: existing, calendar: calendar) else { continue }
                if (existing?.completedCount ?? 0) >= habit.repetitions { continue }
                if existing?.skipped == true && (existing?.completedCount ?? 0) == 0 { continue }
                guard let fireAt = fireDate(day: key, hour: reminder.hour, minute: reminder.minute, calendar: calendar) else { continue }
                if fireAt < now { continue }
                requests.append(CareReminderRequest(
                    id: "\(habit.id.uuidString)-\(key)",
                    habitID: habit.id,
                    day: key,
                    title: habit.title,
                    body: body,
                    hour: reminder.hour,
                    minute: reminder.minute,
                    fireAt: fireAt
                ))
            }
        }
        return requests.sorted { $0.fireAt < $1.fireAt }
    }

    @discardableResult
    func createStarterHabits(now: Date, calendar: Calendar, language: CareLanguage) -> Int {
        let today = CareDay.key(for: now, calendar: calendar)
        let specs: [(String, CareString, HabitSymbol, HabitColor, HabitCategory)] = [
            ("water", .starterWater, .drop, .sky, .health),
            ("bed", .starterBed, .bed, .yellow, .morning),
            ("teeth", .starterTeeth, .sparkles, .mint, .hygiene),
            ("walk", .starterWalk, .walk, .peach, .movement),
            ("relax", .starterRelax, .wind, .lavender, .mindfulness),
            ("note", .starterNote, .pencil, .pink, .creativity)
        ]
        var added = 0
        for spec in specs where !database.habits.contains(where: { $0.starterKey == spec.0 }) {
            var habit = Habit.makeNew(today: today)
            habit.starterKey = spec.0
            habit.title = CareCopy.text(spec.1, language)
            habit.symbol = spec.2.rawValue
            habit.colorHex = spec.3.rawValue
            habit.category = spec.4
            habit.rule = .daily
            database.habits.append(habit)
            added += 1
        }
        if added > 0 { commit() }
        return added
    }

    func addMood(day: String, level: MoodLevel, tags: [MoodTag], note: String, now: Date) -> MoodEntry {
        let entry = MoodEntry(
            id: UUID(),
            day: day,
            recordedAt: CareDay.timestamp(now),
            level: level,
            tags: Array(Set(tags)).sorted { $0.rawValue < $1.rawValue },
            note: String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(4000)),
            journalEntryID: nil
        )
        database.moods.append(entry)
        commit()
        return entry
    }

    func moods(on day: String) -> [MoodEntry] {
        database.moods.filter { $0.day == day }.sorted { $0.recordedAt > $1.recordedAt }
    }

    func weekTrend(ending day: String, calendar: Calendar) -> MoodTrend {
        moodTrend(ending: day, days: 7, calendar: calendar)
    }

    func monthTrend(containing day: String, calendar: Calendar) -> MoodTrend {
        let days = CareDay.daysInMonth(containing: day, calendar: calendar)
        let previousKey = CareDay.shiftMonth(containing: day, by: -1, calendar: calendar) ?? day
        let previous = CareDay.daysInMonth(containing: previousKey, calendar: calendar)
        return MoodMath.trend(entries: database.moods, days: days, previousDays: previous)
    }

    func createJournal(from moodID: UUID, language: CareLanguage, now: Date) -> JournalEntry? {
        guard let index = database.moods.firstIndex(where: { $0.id == moodID }) else { return nil }
        if let existingID = database.moods[index].journalEntryID,
           let existing = database.journal.first(where: { $0.id == existingID }) {
            return existing
        }
        let mood = database.moods[index]
        let note = mood.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let level = CareCopy.mood(mood.level, language)
        let tagText = mood.tags.map { CareCopy.tag($0, language) }.joined(separator: ", ")
        let body = [level, tagText, note].filter { !$0.isEmpty }.joined(separator: "\n")
        let entry = JournalEntry(
            id: UUID(),
            day: mood.day,
            createdAt: CareDay.timestamp(now),
            updatedAt: CareDay.timestamp(now),
            title: CareCopy.text(.moodJournalTitle, language),
            body: body,
            tags: [CareCopy.text(.tabMood, language)],
            reflection: nil,
            rewarded: false
        )
        database.journal.append(entry)
        database.moods[index].journalEntryID = entry.id
        commit()
        return entry
    }

    func journalEntries(query: String, tag: String?) -> [JournalEntry] {
        database.journal.filter { JournalSearch.matches(entry: $0, query: query, tag: tag) }
            .sorted { lhs, rhs in
                if lhs.day != rhs.day { return lhs.day > rhs.day }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    func journalTags() -> [String] {
        var seen = Set<String>()
        var tags: [String] = []
        for entry in database.journal {
            for tag in entry.tags where !seen.contains(tag.lowercased()) {
                seen.insert(tag.lowercased())
                tags.append(tag)
            }
        }
        return tags.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func saveJournal(_ entry: JournalEntry, now: Date) -> Result<CareReward?, CareIssue> {
        var entry = entry
        entry.title = String(entry.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        entry.body = String(entry.body.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20_000))
        entry.tags = JournalSearch.cleanedTags(entry.tags)
        if entry.title.isEmpty && entry.body.isEmpty { return .failure(.emptyEntry) }
        if entry.reflection != nil && !hasReflectionAnswer(entry.body) { return .failure(.emptyReflection) }
        entry.updatedAt = CareDay.timestamp(now)
        var reward: CareReward?
        if let index = database.journal.firstIndex(where: { $0.id == entry.id }) {
            entry.createdAt = database.journal[index].createdAt
            entry.rewarded = database.journal[index].rewarded
            entry.reflection = database.journal[index].reflection
            database.journal[index] = entry
        } else {
            entry.createdAt = CareDay.timestamp(now)
            if entry.reflection != nil {
                reward = enqueue(
                    key: "reflection:\(entry.id.uuidString)",
                    energy: CareRewards.reflectionEnergy,
                    sparks: CareRewards.reflectionSparks,
                    reason: "reflection",
                    title: entry.title,
                    reversal: false
                )
                entry.rewarded = true
            }
            database.journal.append(entry)
        }
        commit()
        return .success(reward)
    }

    func deleteJournal(id: UUID) {
        database.journal.removeAll { $0.id == id }
        for index in database.moods.indices where database.moods[index].journalEntryID == id {
            database.moods[index].journalEntryID = nil
        }
        commit()
    }

    func grantCalm(key: String, energy: Int, sparks: Int, reason: String, title: String) -> CareReward? {
        let reward = enqueue(key: key, energy: energy, sparks: sparks, reason: reason, title: title, reversal: false)
        if reward != nil { commit() }
        return reward
    }

    func startFocus(seconds: Int, now: Date) {
        let length = min(120 * 60, max(60, seconds))
        database.focus = FocusSession(
            id: UUID(),
            plannedSeconds: length,
            endsAt: now.addingTimeInterval(Double(length)),
            pausedRemaining: nil,
            finished: false
        )
        commit()
    }

    func pauseFocus(now: Date) {
        guard var session = database.focus, !session.finished else { return }
        session.pausedRemaining = FocusMath.remaining(session: session, now: now)
        session.endsAt = nil
        database.focus = session
        commit()
    }

    func resumeFocus(now: Date) {
        guard var session = database.focus, !session.finished else { return }
        let left = session.pausedRemaining ?? Double(session.plannedSeconds)
        session.pausedRemaining = nil
        session.endsAt = now.addingTimeInterval(left)
        database.focus = session
        commit()
    }

    func cancelFocus() {
        database.focus = nil
        commit()
    }

    func clearFinishedFocus() {
        guard database.focus?.finished == true else { return }
        database.focus = nil
        commit()
    }

    @discardableResult
    func refreshFocus(now: Date, title: String) -> CareReward? {
        guard var session = database.focus, !session.finished else { return nil }
        guard session.endsAt != nil else { return nil }
        if FocusMath.remaining(session: session, now: now) > 0 { return nil }
        session.finished = true
        session.endsAt = nil
        session.pausedRemaining = 0
        database.focus = session
        let reward = enqueue(
            key: "focus:\(session.id.uuidString)",
            energy: CareRewards.focusEnergy,
            sparks: CareRewards.focusSparks,
            reason: "focus",
            title: title,
            reversal: false
        )
        commit()
        return reward
    }

    func resetAll() {
        database = CareDatabase()
        commit()
    }

    func seedSampleContent(now: Date, calendar: Calendar, language: CareLanguage) {
        _ = createStarterHabits(now: now, calendar: calendar, language: language)
        let today = CareDay.key(for: now, calendar: calendar)
        let levels: [MoodLevel] = [.good, .neutral, .veryGood, .bad, .good, .good, .veryGood]
        let tags: [[MoodTag]] = [[.happy], [.tired], [.grateful, .relaxed], [.sad], [.motivated], [.relaxed], [.happy]]
        for offset in 0..<7 {
            guard let day = CareDay.addingDays(-offset, to: today, calendar: calendar) else { continue }
            let id = Self.seedID(200 + offset)
            if database.moods.contains(where: { $0.id == id }) { continue }
            database.moods.append(MoodEntry(
                id: id,
                day: day,
                recordedAt: CareDay.timestamp(now),
                level: levels[offset],
                tags: tags[offset],
                note: "",
                journalEntryID: nil
            ))
        }
        let journalID = Self.seedID(300)
        if !database.journal.contains(where: { $0.id == journalID }) {
            database.journal.append(JournalEntry(
                id: journalID,
                day: today,
                createdAt: CareDay.timestamp(now),
                updatedAt: CareDay.timestamp(now),
                title: CareCopy.text(.kindGratitude, language),
                body: CareCopy.text(.promptGratitude1, language),
                tags: [CareCopy.text(.kindGratitude, language)],
                reflection: nil,
                rewarded: false
            ))
        }
        commit()
    }

    func diagnostics(now: Date, calendar: Calendar) -> String {
        let active = database.habits.filter { !$0.archived }.count
        let archived = database.habits.filter(\.archived).count
        let bytes = fileURL.flatMap { try? Data(contentsOf: $0).count } ?? 0
        var lines = [
            "care schema \(database.schema)",
            "habits \(active) active, \(archived) archived",
            "records \(database.records.count)",
            "moods \(database.moods.count)",
            "journal \(database.journal.count)",
            "focus \(database.focus == nil ? "idle" : "set")",
            "grants \(database.grants.count)",
            "outbox \(database.outbox.count)",
            "next event \(database.nextEventID)",
            "today \(CareDay.key(for: now, calendar: calendar))",
            "file bytes \(bytes)"
        ]
        if let lastPersistError { lines.append("persist error \(lastPersistError)") }
        if let quarantinedURL { lines.append("quarantine \(quarantinedURL.path)") }
        let failures = Self.logicCheck() + HabitSchedule.selfCheck() + MoodMath.selfCheck() + BreathEngine.selfCheck() + FocusMath.selfCheck()
        lines.append(failures.isEmpty ? "self-check pass" : "self-check fail \(failures.count)")
        return lines.joined(separator: "\n")
    }

    static func logicCheck() -> [String] {
        var failures: [String] = []
        func expect(_ condition: Bool, _ message: String) {
            if !condition { failures.append(message) }
        }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("gooby-care-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("care-store.json")
        let calendar = CareDay.gregorian(timeZone: TimeZone(secondsFromGMT: 0) ?? .current, firstWeekday: 2)
        guard let now = CareDay.date(from: "2026-04-15", calendar: calendar) else {
            return ["could not build the logic-check clock"]
        }
        let store = CareStore(fileURL: url, loadFromDisk: false)
        var habit = Habit.makeNew(today: "2026-04-01")
        habit.title = "Wasser"
        habit.rule = .daily
        habit.repetitions = 2
        habit.rewardValue = 5
        habit.isDailyGoal = true
        habit.reminder = HabitReminder(hour: 18, minute: 0)
        expect(store.saveHabit(habit) == nil, "habit should save")
        var other = Habit.makeNew(today: "2026-04-01")
        other.title = "Zweites Ziel"
        other.isDailyGoal = true
        expect(store.saveHabit(other) == nil, "second habit should save")
        expect(store.habit(habit.id)?.isDailyGoal == false, "only one daily goal stays set")
        expect(store.habit(other.id)?.isDailyGoal == true, "the newer daily goal is kept")
        habit.isDailyGoal = true
        expect(store.saveHabit(habit) == nil, "the daily goal can move back")
        expect(store.habit(habit.id)?.isDailyGoal == true, "the first habit is the daily goal again")
        expect(store.habit(other.id)?.isDailyGoal == false, "the other habit lost the daily goal")

        let today = "2026-04-15"
        let yesterday = "2026-04-14"
        switch store.completeRep(habitID: habit.id, day: yesterday, now: now, calendar: calendar) {
        case .success(let rewards):
            expect(rewards.count == 1, "the first rep of a two-rep goal grants one reward")
            expect(rewards.first?.energy == 5, "rep reward uses the habit value")
        case .failure:
            failures.append("past day completion should succeed")
        }
        expect(store.progress(for: habit, day: today, calendar: calendar).completed == 0, "a completion stays on its own day")
        _ = store.completeRep(habitID: habit.id, day: yesterday, now: now, calendar: calendar)
        let finished = store.progress(for: habit, day: yesterday, calendar: calendar)
        expect(finished.isComplete, "two reps complete the day")
        expect(store.database.grants.contains { $0.reason == "daily-goal" }, "the daily goal bonus is granted once")
        if case .success = store.completeRep(habitID: habit.id, day: yesterday, now: now, calendar: calendar) {
            failures.append("a full day must not grant another rep")
        }
        let grantCount = store.database.grants.count
        _ = store.undoRep(habitID: habit.id, day: yesterday, now: now)
        expect(store.database.grants.count == grantCount - 2, "undo removes the last rep and the daily-goal bonus")
        expect(store.progress(for: habit, day: yesterday, calendar: calendar).completed == 1, "undo removes one rep")
        if case .failure = store.completeRep(habitID: habit.id, day: "2026-04-16", now: now, calendar: calendar) {
        } else {
            failures.append("a future day must be rejected")
        }

        expect(store.skip(habitID: other.id, day: today, now: now, calendar: calendar) == nil, "skip should succeed")
        expect(store.progress(for: other, day: today, calendar: calendar).skipped, "skip is stored on that day")
        expect(store.skip(habitID: other.id, day: yesterday, now: now, calendar: calendar) == nil, "another day can be skipped on its own")
        expect(store.progress(for: other, day: today, calendar: calendar).skipped, "today stays skipped")

        var movable = Habit.makeNew(today: "2026-04-01")
        movable.title = "Einmal"
        movable.rule = .once
        movable.startDay = "2026-04-10"
        expect(store.saveHabit(movable) == nil, "once habit should save")
        expect(store.reschedule(habitID: movable.id, from: "2026-04-10", to: "2026-04-12", now: now, calendar: calendar) == nil, "reschedule should succeed")
        expect(!store.progress(for: store.habit(movable.id) ?? movable, day: "2026-04-10", calendar: calendar).due, "the original day is no longer due")
        expect(store.progress(for: store.habit(movable.id) ?? movable, day: "2026-04-12", calendar: calendar).due, "the target day is due")
        if case .success = store.completeRep(habitID: movable.id, day: "2026-04-12", now: now, calendar: calendar) {
        } else {
            failures.append("the moved day should accept a completion")
        }
        if case .success = store.completeRep(habitID: movable.id, day: "2026-04-10", now: now, calendar: calendar) {
            failures.append("the original day must not accept a completion after the move")
        }

        let before = store.database.grants.count
        let added = store.createStarterHabits(now: now, calendar: calendar, language: .german)
        expect(added == 6, "starters should add six habits")
        expect(store.createStarterHabits(now: now, calendar: calendar, language: .english) == 0, "starters are idempotent")
        expect(store.database.grants.count == before, "starters do not grant rewards")

        let entry = JournalEntry(
            id: UUID(), day: today, createdAt: now, updatedAt: now,
            title: "Fenster", body: "Regen auf dem Glas", tags: ["Ruhe"], reflection: .gratitude, rewarded: false
        )
        if case .success(let reward) = store.saveJournal(entry, now: now) {
            expect(reward?.reason == "reflection", "a guided reflection grants once")
        } else {
            failures.append("journal save should succeed")
        }
        var edited = entry
        edited.body = "Regen auf dem Glas und ein Tee"
        if case .success(let reward) = store.saveJournal(edited, now: now) {
            expect(reward == nil, "editing a reflection does not grant again")
        } else {
            failures.append("journal edit should succeed")
        }
        expect(store.journalEntries(query: "regen", tag: nil).count == 1, "search finds the body")
        expect(store.journalEntries(query: "fenster", tag: "ruhe").count == 1, "search finds title and tag")
        expect(store.journalEntries(query: "fenster", tag: "andere").isEmpty, "a different tag excludes the entry")
        store.deleteJournal(id: entry.id)
        expect(store.journalEntries(query: "", tag: nil).contains { $0.id == entry.id } == false, "deleted entries disappear")

        let requests = store.reminderRequests(from: today, count: 1, now: now, calendar: calendar, body: "Erinnerung")
        expect(requests.contains { $0.habitID == habit.id }, "an incomplete due habit with a reminder is listed")
        _ = store.completeRep(habitID: habit.id, day: today, now: now, calendar: calendar)
        _ = store.completeRep(habitID: habit.id, day: today, now: now, calendar: calendar)
        let after = store.reminderRequests(from: today, count: 1, now: now, calendar: calendar, body: "Erinnerung")
        expect(!after.contains { $0.habitID == habit.id }, "a finished habit does not request a reminder")

        store.persist()
        let reloaded = CareStore(fileURL: url, loadFromDisk: true)
        expect(reloaded.habit(habit.id)?.title == "Wasser", "a relaunch keeps the habit")
        expect(reloaded.progress(for: habit, day: yesterday, calendar: calendar).completed == 1, "a relaunch keeps that day's count")

        let rules: [HabitRule] = [
            .once, .daily, .weekly(weekday: 2), .monthly(day: 31), .weekdays(days: [2, 5]),
            .every(days: 3), .custom(interval: 2, weekdays: [2], monthDays: [31])
        ]
        for rule in rules {
            var item = Habit.makeNew(today: "2026-01-31")
            item.title = "Regel"
            item.rule = rule
            item.endDay = "2026-12-31"
            expect(store.saveHabit(item) == nil, "rule \(rule) should save")
        }
        store.persist()
        let roundTrip = CareStore(fileURL: url, loadFromDisk: true)
        expect(roundTrip.database.habits.contains { $0.rule == .monthly(day: 31) }, "monthly rules survive a relaunch")
        expect(roundTrip.database.habits.contains { $0.rule == .custom(interval: 2, weekdays: [2], monthDays: [31]) }, "custom rules survive a relaunch")

        let ids = store.database.outbox.map(\.eventID) + store.database.grants.map { _ in 0 }
        let eventIDs = (1..<store.database.nextEventID)
        expect(Set(eventIDs).count == eventIDs.count, "event ids stay unique")
        _ = ids

        store.deleteHabit(id: habit.id)
        expect(store.habit(habit.id) == nil, "delete removes the habit")
        expect(!store.database.records.contains { $0.habitID == habit.id }, "delete removes that habit's records")
        return failures
    }

    private func moodTrend(ending day: String, days: Int, calendar: Calendar) -> MoodTrend {
        let window = CareDay.trailingDays(ending: day, count: days, calendar: calendar)
        let previousEnd = CareDay.addingDays(-days, to: day, calendar: calendar) ?? day
        let previous = CareDay.trailingDays(ending: previousEnd, count: days, calendar: calendar)
        return MoodMath.trend(entries: database.moods, days: window, previousDays: previous)
    }

    private func hasReflectionAnswer(_ body: String) -> Bool {
        let lines = body.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        return lines.contains { !$0.isEmpty && $0 != "—" }
    }

    private func normalized(_ habit: Habit) -> Habit {
        var habit = habit
        habit.title = String(habit.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        habit.details = String(habit.details.trimmingCharacters(in: .whitespacesAndNewlines).prefix(280))
        habit.customCategory = String(habit.customCategory.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        habit.updatedAt = CareDay.timestamp()
        switch habit.rule {
        case .weekdays(let days):
            habit.rule = .weekdays(days: Array(Set(days.filter { (1...7).contains($0) })).sorted())
        case .custom(let interval, let weekdays, let monthDays):
            habit.rule = .custom(
                interval: interval,
                weekdays: Array(Set(weekdays.filter { (1...7).contains($0) })).sorted(),
                monthDays: Array(Set(monthDays.filter { (1...31).contains($0) })).sorted()
            )
        default:
            break
        }
        return habit
    }

    private func record(habitID: UUID, day: String) -> HabitDayRecord? {
        database.records.first { $0.habitID == habitID && $0.day == day }
    }

    private func recordIndex(habitID: UUID, day: String) -> Int? {
        database.records.firstIndex { $0.habitID == habitID && $0.day == day }
    }

    private func ensureRecord(habitID: UUID, day: String, now: Date) -> Int {
        if let index = recordIndex(habitID: habitID, day: day) { return index }
        database.records.append(HabitDayRecord(
            id: UUID(),
            habitID: habitID,
            day: day,
            completedCount: 0,
            skipped: false,
            removed: false,
            movedFrom: nil,
            updatedAt: CareDay.timestamp(now)
        ))
        return database.records.count - 1
    }

    private func fireDate(day: String, hour: Int, minute: Int, calendar: Calendar) -> Date? {
        guard let noon = CareDay.date(from: day, calendar: calendar) else { return nil }
        var parts = calendar.dateComponents([.year, .month, .day], from: noon)
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        return calendar.date(from: parts)
    }

    private func enqueue(key: String, energy: Int, sparks: Int, reason: String, title: String, reversal: Bool) -> CareReward? {
        if reversal {
            guard let stored = database.grants.first(where: { $0.key == key }) else { return nil }
            database.grants.removeAll { $0.key == key }
            let reward = CareReward(
                eventID: database.nextEventID,
                key: key,
                energy: stored.energy,
                sparks: stored.sparks,
                reversal: true,
                reason: stored.reason,
                title: stored.title
            )
            database.nextEventID += 1
            database.outbox.append(reward)
            return reward
        }
        if database.grants.contains(where: { $0.key == key }) { return nil }
        let reward = CareReward(
            eventID: database.nextEventID,
            key: key,
            energy: energy,
            sparks: sparks,
            reversal: false,
            reason: reason,
            title: title
        )
        database.nextEventID += 1
        database.grants.append(StoredGrant(key: key, energy: energy, sparks: sparks, reason: reason, title: title))
        database.outbox.append(reward)
        return reward
    }

    private func commit() {
        let snapshot = database
        database = snapshot
        persist()
        flush()
    }

    private func flush() {
        guard !flushing, let rewardHandler else { return }
        flushing = true
        defer { flushing = false }
        while let reward = database.outbox.first {
            rewardHandler(reward)
            if database.outbox.first?.eventID == reward.eventID {
                database.outbox.removeFirst()
            }
            persist()
        }
    }

    private func persist() {
        guard let fileURL else { return }
        do {
            let data = try CareJSON.encoder().encode(database)
            try data.write(to: fileURL, options: .atomic)
            var stored = fileURL
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? stored.setResourceValues(values)
            lastPersistError = nil
        } catch {
            lastPersistError = error.localizedDescription
        }
    }

    private static func habitSort(_ lhs: Habit, _ rhs: Habit) -> Bool {
        if lhs.priority != rhs.priority { return lhs.priority.rawValue > rhs.priority.rawValue }
        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }

    private static func seedID(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", number)) ?? UUID()
    }

    private enum LoadResult {
        case missing
        case loaded(CareDatabase)
        case failed
    }

    private static func read(_ url: URL) -> LoadResult {
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        guard let data = try? Data(contentsOf: url),
              let stored = try? CareJSON.decoder().decode(CareDatabase.self, from: data) else { return .failed }
        return .loaded(stored)
    }
}

private enum CareJSON {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
