import Foundation

struct QuestSeasonWindow: Equatable {
    var eventID: String
    var active: Bool
    var forced: Bool
    var starts: Date
    var ends: Date
    var daysUntilStart: Int
    var daysLeft: Int
}

extension GoobyEngine {
    func ensureDailyQuests(_ key: String) {
        let templates = catalog.quests.filter { $0.kind == "daily" }
        guard !templates.isEmpty else { return }
        for old in all(QuestRecord.self) where old.kind == "daily" && old.dayKey != key && !old.claimed {
            context.delete(old)
        }
        let existing = all(QuestRecord.self).filter { $0.kind == "daily" && $0.dayKey == key }
        if existing.count >= 3 { return }
        let ordered = ShopRotation.orderedIDs(templates.map(\.id), dayKey: key, category: "daily-quests", appSeed: profile.appSeed)
        for id in ordered.prefix(3) where !existing.contains(where: { $0.templateID == id }) {
            guard let template = catalog.questsByID[id] else { continue }
            let row = QuestRecord()
            row.templateID = template.id
            row.kind = "daily"
            row.dayKey = key
            row.goal = template.goal
            row.rewardSparks = template.rewardSparks
            row.rewardItemID = template.rewardItemID
            context.insert(row)
        }
    }

    func ensureMilestones() {
        let have = Set(all(QuestRecord.self).filter { $0.kind == "milestone" }.map(\.templateID))
        for template in catalog.quests where template.kind == "milestone" && !have.contains(template.id) {
            let row = QuestRecord()
            row.templateID = template.id
            row.kind = "milestone"
            row.goal = template.goal
            row.rewardSparks = template.rewardSparks
            row.rewardItemID = template.rewardItemID
            context.insert(row)
        }
    }

    func recomputeQuests() {
        for quest in all(QuestRecord.self) where !quest.claimed {
            quest.progress = metric(for: quest)
        }
    }

    func metric(for quest: QuestRecord) -> Int {
        guard let template = catalog.questsByID[quest.templateID] else { return quest.progress }
        let today = dayKey()
        switch template.metric {
        case "habits":
            let logs = all(HabitLog.self).filter { !$0.skipped && $0.count > 0 }
            let rows = template.kind == "daily" ? logs.filter { $0.dayKey == today } : logs
            return rows.reduce(0) { $0 + $1.count }
        case "mood":
            let rows = all(MoodEntry.self)
            return template.kind == "daily" ? rows.filter { $0.dayKey == today }.count : rows.count
        case "journal":
            let rows = all(JournalEntry.self)
            return template.kind == "daily" ? rows.filter { $0.dayKey == today }.count : rows.count
        case "breath":
            let rows = all(DailyStat.self)
            return template.kind == "daily" ? (rows.first { $0.dayKey == today }?.breathSessions ?? 0) : rows.reduce(0) { $0 + $1.breathSessions }
        case "focus":
            let rows = all(DailyStat.self)
            return template.kind == "daily" ? (rows.first { $0.dayKey == today }?.focusMinutes ?? 0) : rows.reduce(0) { $0 + $1.focusMinutes }
        case "movement":
            let rows = all(DailyStat.self)
            return template.kind == "daily" ? (rows.first { $0.dayKey == today }?.movementSessions ?? 0) : rows.reduce(0) { $0 + $1.movementSessions }
        case "pet":
            if template.kind == "daily" { return min(1, all(DailyStat.self).first { $0.dayKey == today }?.petActions ?? 0) }
            return pet.affection
        case "adventure":
            let rows = all(AdventureRun.self).filter { $0.status == "claimed" }
            return template.kind == "daily" ? rows.filter { $0.dayKey == today }.count : rows.count
        case "energy":
            return wallet.energy
        case "friend":
            return all(MiniFriend.self).count
        case "place":
            return all(PlaceProgress.self).filter(\.unlocked).count
        case "clothing":
            return all(OwnedItem.self).filter { $0.kind == "clothing" }.count
        case "decoration":
            return ownedDecorations()
        case "energyDays":
            return fullEnergyDays()
        case "streak":
            return streak()
        default:
            return quest.progress
        }
    }

    /// Days whose granted energy reached the daily goal. The wallet only keeps today, so older days come from the reward ledger.
    func fullEnergyDays() -> Int {
        let goal = max(1, profile.energyGoal)
        var totals: [String: Int] = [:]
        for row in all(RewardLedger.self) where row.energy > 0 {
            let key = DayKey.make(row.createdAt)
            totals[key, default: 0] += row.energy
        }
        if !wallet.energyDayKey.isEmpty {
            totals[wallet.energyDayKey] = max(totals[wallet.energyDayKey] ?? 0, max(0, wallet.energy))
        }
        return totals.values.filter { $0 >= goal }.count
    }

    private func ownedDecorations() -> Int {
        all(OwnedItem.self).filter { item in
            item.kind == "furniture" && catalog.itemsByID[item.catalogID]?.starter == false
        }.count
    }

    func featuredSeason() -> QuestSeasonWindow? {
        chooseSeason(among: catalog.events)
    }

    /// The gratitude jar follows the next event that asks for a journal note, so its date can differ from the hero.
    func gratitudeSeason() -> QuestSeasonWindow? {
        let journal = catalog.events.filter { event in
            event.tasks.contains { $0.metric == "journal" }
        }
        if let window = chooseSeason(among: journal) { return window }
        return featuredSeason()
    }

    private func chooseSeason(among events: [EventDef]) -> QuestSeasonWindow? {
        let spots = events.map { seasonSpot(for: $0, now: now()) }
        let forced = spots.filter(\.forced)
        let active = forced.isEmpty ? spots.filter(\.active) : forced
        if !active.isEmpty {
            return active.min { lhs, rhs in
                if lhs.starts != rhs.starts { return lhs.starts > rhs.starts }
                return lhs.eventID < rhs.eventID
            }
        }
        return spots.filter { $0.daysUntilStart > 0 }.min { lhs, rhs in
            if lhs.daysUntilStart != rhs.daysUntilStart { return lhs.daysUntilStart < rhs.daysUntilStart }
            return lhs.eventID < rhs.eventID
        }
    }

    private func seasonSpot(for event: EventDef, now: Date) -> QuestSeasonWindow {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        if let record = all(EventRecord.self).first(where: { $0.eventID == event.id }), record.forced {
            let start = calendar.startOfDay(for: record.forcedOn ?? now)
            return QuestSeasonWindow(
                eventID: event.id,
                active: true,
                forced: true,
                starts: start,
                ends: today,
                daysUntilStart: 0,
                daysLeft: 0
            )
        }
        let bounds = seasonBounds(event, now: now, calendar: calendar)
        let active = today >= bounds.start && today <= bounds.end
        let until = calendar.dateComponents([.day], from: today, to: bounds.start).day ?? 0
        let left = calendar.dateComponents([.day], from: today, to: bounds.end).day ?? 0
        return QuestSeasonWindow(
            eventID: event.id,
            active: active,
            forced: false,
            starts: bounds.start,
            ends: bounds.end,
            daysUntilStart: active ? 0 : max(0, until),
            daysLeft: max(0, left)
        )
    }

    private func seasonBounds(_ event: EventDef, now: Date, calendar: Calendar) -> (start: Date, end: Date) {
        let year = calendar.component(.year, from: now)
        let wraps = event.startMonth * 100 + event.startDay > event.endMonth * 100 + event.endDay
        func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
            var parts = DateComponents()
            parts.year = year
            parts.month = month
            parts.day = day
            return calendar.startOfDay(for: calendar.date(from: parts) ?? now)
        }
        var windows: [(Date, Date)] = []
        for offset in -1...1 {
            let start = day(year + offset, event.startMonth, event.startDay)
            let end = day(wraps ? year + offset + 1 : year + offset, event.endMonth, event.endDay)
            if end >= start { windows.append((start, end)) }
        }
        let today = calendar.startOfDay(for: now)
        if let inside = windows.first(where: { today >= $0.0 && today <= $0.1 }) {
            return (start: inside.0, end: inside.1)
        }
        if let next = windows.filter({ $0.0 > today }).min(by: { $0.0 < $1.0 }) {
            return (start: next.0, end: next.1)
        }
        if let last = windows.max(by: { $0.0 < $1.0 }) {
            return (start: last.0, end: last.1)
        }
        return (start: today, end: today)
    }

    @discardableResult
    func claimQuest(_ quest: QuestRecord) -> Bool {
        recomputeQuests()
        guard !quest.claimed, quest.progress >= quest.goal else { return false }
        quest.claimed = true
        _ = grant(key: "quest:\(quest.id.uuidString)", sparks: quest.rewardSparks, energy: 0)
        grantItem(quest.rewardItemID)
        celebration += 1
        save()
        cue(.questDone)
        return true
    }

    func eventRecord(_ id: String) -> EventRecord {
        if let found = all(EventRecord.self).first(where: { $0.eventID == id }) { return found }
        let row = EventRecord()
        row.eventID = id
        context.insert(row)
        return row
    }

    func eventBounds(_ event: EventDef) -> (Date, Date) {
        let record = all(EventRecord.self).first { $0.eventID == event.id }
        if record?.forced == true, let start = record?.forcedOn {
            return (start, now())
        }
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now())
        func make(_ year: Int, _ month: Int, _ day: Int) -> Date {
            var parts = DateComponents()
            parts.year = year
            parts.month = month
            parts.day = day
            return calendar.date(from: parts) ?? now()
        }
        let startValue = event.startMonth * 100 + event.startDay
        let endValue = event.endMonth * 100 + event.endDay
        let current = EventWindow.monthDay(now())
        if startValue <= endValue {
            return (make(year, event.startMonth, event.startDay), make(year, event.endMonth, event.endDay))
        }
        if current >= startValue {
            return (make(year, event.startMonth, event.startDay), make(year + 1, event.endMonth, event.endDay))
        }
        return (make(year - 1, event.startMonth, event.startDay), make(year, event.endMonth, event.endDay))
    }

    func eventProgress(_ event: EventDef, _ task: EventTaskDef) -> Int {
        let record = all(EventRecord.self).first { $0.eventID == event.id }
        let bonus = intMap(record?.bonusJSON ?? "{}")[task.id] ?? 0
        let bounds = eventBounds(event)
        return count(metric: task.metric, from: bounds.0, to: bounds.1) + bonus
    }

    func count(metric: String, from start: Date, to end: Date) -> Int {
        let startKey = DayKey.make(start)
        let endKey = DayKey.make(end)
        switch metric {
        case "habits":
            return all(HabitLog.self).filter { !$0.skipped && $0.count > 0 && $0.dayKey >= startKey && $0.dayKey <= endKey }.reduce(0) { $0 + $1.count }
        case "adventure":
            return all(AdventureRun.self).filter { $0.status == "claimed" && $0.dayKey >= startKey && $0.dayKey <= endKey }.count
        case "mood":
            return all(MoodEntry.self).filter { $0.dayKey >= startKey && $0.dayKey <= endKey }.count
        case "journal":
            return all(JournalEntry.self).filter { $0.dayKey >= startKey && $0.dayKey <= endKey }.count
        case "breath":
            return all(DailyStat.self).filter { $0.dayKey >= startKey && $0.dayKey <= endKey }.reduce(0) { $0 + $1.breathSessions }
        case "movement":
            return all(DailyStat.self).filter { $0.dayKey >= startKey && $0.dayKey <= endKey }.reduce(0) { $0 + $1.movementSessions }
        case "focus":
            return all(DailyStat.self).filter { $0.dayKey >= startKey && $0.dayKey <= endKey }.reduce(0) { $0 + $1.focusMinutes }
        case "pet":
            return all(DailyStat.self).filter { $0.dayKey >= startKey && $0.dayKey <= endKey }.reduce(0) { $0 + $1.petActions }
        default:
            return 0
        }
    }

    func claimedTasks(_ record: EventRecord) -> Set<String> {
        guard let data = record.claimedJSON.data(using: .utf8),
              let list = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return Set(list)
    }

    @discardableResult
    func claimEventTask(_ event: EventDef, _ task: EventTaskDef) -> Bool {
        let record = eventRecord(event.id)
        var claimed = claimedTasks(record)
        guard !claimed.contains(task.id) else { return false }
        guard eventProgress(event, task) >= task.goal else { return false }
        claimed.insert(task.id)
        record.claimedJSON = (try? String(data: JSONEncoder().encode(Array(claimed)), encoding: .utf8)) ?? "[]"
        _ = grant(key: "event:\(event.id):\(task.id)", sparks: task.rewardSparks, energy: 0)
        grantItem(task.rewardItemID)
        celebration += 1
        save()
        cue(.questDone)
        return true
    }

    func forceEvent(_ id: String, on: Bool) {
        let record = eventRecord(id)
        record.forced = on
        record.forcedOn = on ? now() : nil
        save()
        log("event \(id) forced \(on)")
    }

    func bumpEvent(_ eventID: String, taskID: String, by: Int) {
        let record = eventRecord(eventID)
        var map = intMap(record.bonusJSON)
        map[taskID, default: 0] += by
        record.bonusJSON = encode(map)
        save()
    }

    func resetEventProgress(_ id: String) {
        let record = eventRecord(id)
        record.bonusJSON = "{}"
        record.claimedJSON = "[]"
        record.forced = false
        record.forcedOn = nil
        for row in all(RewardLedger.self) where row.key.hasPrefix("event:\(id):") {
            revoke(key: row.key)
        }
        save()
    }

    func freeEventRewards(_ event: EventDef) {
        for task in event.tasks {
            let key = "event:\(event.id):\(task.id)"
            if grant(key: key, sparks: task.rewardSparks, energy: 0) {
                grantItem(task.rewardItemID)
            }
            let record = eventRecord(event.id)
            var claimed = claimedTasks(record)
            claimed.insert(task.id)
            record.claimedJSON = (try? String(data: JSONEncoder().encode(Array(claimed)), encoding: .utf8)) ?? "[]"
        }
        save()
    }

    private func intMap(_ json: String) -> [String: Int] {
        guard let data = json.data(using: .utf8),
              let map = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
        return map
    }

    private func encode(_ map: [String: Int]) -> String {
        (try? String(data: JSONEncoder().encode(map), encoding: .utf8)) ?? "{}"
    }
}

extension GoobyEngine {
    func currentFocus() -> FocusSession? { all(FocusSession.self).first { !$0.finished } }

    func focusElapsed(_ session: FocusSession) -> Double {
        let extra = session.runningSince.map { max(0, now().timeIntervalSince($0)) } ?? 0
        return session.accumulated + extra
    }

    func focusRemaining() -> Int {
        guard let session = currentFocus() else { return 0 }
        return max(0, session.plannedSeconds - Int(focusElapsed(session)))
    }

    func focusStart(seconds: Int) {
        if let existing = currentFocus() { context.delete(existing) }
        let session = FocusSession()
        session.plannedSeconds = max(60, seconds)
        session.runningSince = now()
        session.dayKey = dayKey()
        context.insert(session)
        save()
        cue(.select)
    }

    func focusPause() {
        guard let session = currentFocus(), session.runningSince != nil else { return }
        session.accumulated = min(Double(session.plannedSeconds), focusElapsed(session))
        session.runningSince = nil
        save()
        cue(.select)
    }

    func focusResume() {
        guard let session = currentFocus(), !session.finished else { return }
        if session.runningSince == nil { session.runningSince = now() }
        save()
        cue(.select)
    }

    func focusStop() {
        guard let session = currentFocus() else { return }
        session.runningSince = nil
        session.finished = true
        save()
        cue(.select)
    }

    func reconcileFocus() {
        guard let session = currentFocus(), !session.finished else { return }
        guard focusElapsed(session) >= Double(session.plannedSeconds) else { return }
        session.accumulated = Double(session.plannedSeconds)
        session.runningSince = nil
        session.finished = true
        if !session.rewarded {
            session.rewarded = true
            let minutes = max(1, session.plannedSeconds / 60)
            _ = grant(key: "focus:\(session.id.uuidString)", sparks: 6 + minutes, energy: 5)
            dailyStat(session.dayKey).focusMinutes += minutes
            celebration += 1
            animation = .celebrate
            cue(.calm)
        }
        recomputeQuests()
        save()
    }
}
