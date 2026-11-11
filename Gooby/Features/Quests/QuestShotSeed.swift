#if DEBUG
import Foundation

/// `-GoobyScreenshot quests` pins the season hero, the jar and the daily quests to the states in the
/// Finch reference frame, so the screenshot compares layout instead of the calendar day it ran on.
@MainActor
enum QuestShotSeed {
    static var active: Bool { GoobyScreenshotMode.screen == "quests" }
    static let dailies = ["d-habits", "d-journal", "d-breath"]

    static func season(_ engine: GoobyEngine) -> QuestSeasonWindow? {
        window(engine, daysAway: 3)
    }

    static func jar(_ engine: GoobyEngine) -> QuestSeasonWindow? {
        window(engine, daysAway: 18)
    }

    /// Returns true when it replaced today's rows, so the caller can redraw.
    @discardableResult
    static func seedDailies(_ engine: GoobyEngine) -> Bool {
        guard active else { return false }
        let key = engine.dayKey()
        let today = engine.all(QuestRecord.self).filter { $0.kind == "daily" && $0.dayKey == key }
        var changed = false
        for row in today where !dailies.contains(row.templateID) {
            engine.context.delete(row)
            changed = true
        }
        for id in dailies where !today.contains(where: { $0.templateID == id }) {
            guard let template = engine.catalog.questsByID[id] else { continue }
            let row = QuestRecord()
            row.templateID = id
            row.kind = "daily"
            row.dayKey = key
            row.goal = template.goal
            row.rewardSparks = template.rewardSparks
            row.rewardItemID = template.rewardItemID
            engine.context.insert(row)
            changed = true
        }
        return changed
    }

    private static func window(_ engine: GoobyEngine, daysAway: Int) -> QuestSeasonWindow? {
        guard active, let event = engine.catalog.events.first(where: { $0.startMonth == 11 }) else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: engine.now())
        var parts = calendar.dateComponents([.year], from: today)
        parts.month = event.startMonth
        parts.day = event.startDay
        let start = calendar.date(from: parts) ?? today
        return QuestSeasonWindow(
            eventID: event.id,
            active: false,
            forced: false,
            starts: start,
            ends: start,
            daysUntilStart: daysAway,
            daysLeft: 0
        )
    }
}
#endif
