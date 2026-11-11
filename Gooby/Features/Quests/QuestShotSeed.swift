#if DEBUG
import Foundation

/// `-GoobyScreenshot quests` pins the season hero, the jar and the daily quests to the states in the
/// Finch reference frame, so the screenshot compares layout instead of the calendar day it ran on.
@MainActor
enum QuestShotSeed {
    static var active: Bool { GoobyScreenshotMode.screen == "quests" }
    static let dailies = ["d-habits", "d-journal", "d-breath"]
    static let heroTitle = "Hidden Hollow"

    static func dailyTitle(_ id: String) -> String? {
        switch id {
        case "d-habits": return "Complete a goal"
        case "d-journal": return "Add a friend"
        case "d-breath": return "Save your progress"
        default: return nil
        }
    }

    /// Icon metric for the three reference dailies. The real metric stays on the record.
    static func dailyMark(_ id: String) -> String? {
        switch id {
        case "d-habits": return "shot-goal"
        case "d-journal": return "shot-friend"
        case "d-breath": return "shot-cloud"
        default: return nil
        }
    }

    /// The reference shows an arrow key on the friend and save rows only.
    static func showsKey(_ id: String) -> Bool {
        id == "d-journal" || id == "d-breath"
    }

    static func clock(_ now: Date) -> QuestDayClock.Reading? {
        guard active else { return nil }
        var reading = QuestDayClock.read(now)
        reading.hours = 23
        reading.minutes = 55
        reading.fraction = Double(23 * 60 + 55) / Double(24 * 60)
        return reading
    }

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
