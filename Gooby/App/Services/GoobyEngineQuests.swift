import Foundation

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
        case "streak":
            return streak()
        default:
            return quest.progress
        }
    }

    @discardableResult
    func claimQuest(_ quest: QuestRecord) -> Bool {
        recomputeQuests()
        guard !quest.claimed, quest.progress >= quest.goal else { return false }
        quest.claimed = true
        _ = grant(key: "quest:\(quest.id.uuidString)", sparks: quest.rewardSparks, energy: 0)
        grantItem(quest.rewardItemID)
        celebration += 1
        haptics.celebrate()
        save()
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
    }

    func focusPause() {
        guard let session = currentFocus(), session.runningSince != nil else { return }
        session.accumulated = min(Double(session.plannedSeconds), focusElapsed(session))
        session.runningSince = nil
        save()
    }

    func focusResume() {
        guard let session = currentFocus(), !session.finished else { return }
        if session.runningSince == nil { session.runningSince = now() }
        save()
    }

    func focusStop() {
        guard let session = currentFocus() else { return }
        session.runningSince = nil
        session.finished = true
        save()
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
            haptics.celebrate()
        }
        recomputeQuests()
        save()
    }
}
