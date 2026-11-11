import SwiftUI
import WidgetKit

struct GoobyEntry: TimelineEntry {
    var date: Date
    var snapshot: GoobyWidgetSnapshot?
    var portrait: UIImage?

    var language: String { WidgetText.language(snapshot) }
    var name: String { snapshot?.goobyName ?? "Gooby" }

    var isCurrentDay: Bool {
        guard let snapshot else { return false }
        return snapshot.dayKey == GoobyWidgetSnapshot.dayKey(for: date, offset: snapshot.timeOffset)
    }

    var goals: [GoobyWidgetSnapshot.Goal] { isCurrentDay ? (snapshot?.goals ?? []) : [] }
    var goalsDone: Int { goals.filter(\.done).count }
    var goalsTotal: Int { goals.count }
    var energy: Int { isCurrentDay ? (snapshot?.energy ?? 0) : 0 }
    var energyGoal: Int { max(1, snapshot?.energyGoal ?? 12) }
    var energyFraction: Double { min(1, Double(energy) / Double(energyGoal)) }

    var activeTrip: GoobyWidgetSnapshot.Trip? { isCurrentDay ? snapshot?.trip : nil }

    var runningFocus: GoobyWidgetSnapshot.Focus? {
        guard isCurrentDay, let focus = snapshot?.focus else { return nil }
        if let end = focus.endsAt, end <= date { return nil }
        return focus
    }

    var link: URL {
        if runningFocus != nil { return GoobyLink.focus.url }
        if let trip = activeTrip, date < trip.returnsAt { return GoobyLink.adventure.url }
        if let trip = activeTrip, date >= trip.returnsAt { return GoobyLink.adventure.url }
        return GoobyLink.home.url
    }
}

struct GoobyProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoobyEntry {
        GoobyEntry(date: Date(), snapshot: .sample(WidgetText.deviceLanguage()), portrait: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (GoobyEntry) -> Void) {
        let stored = GoobySharedStore.loadSnapshot()
        let snapshot = stored ?? (context.isPreview ? .sample(WidgetText.deviceLanguage()) : nil)
        completion(GoobyEntry(date: Date(), snapshot: snapshot, portrait: GoobyWidgetArt.portrait()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoobyEntry>) -> Void) {
        let now = Date()
        let snapshot = GoobySharedStore.loadSnapshot()
        let portrait = GoobyWidgetArt.portrait()
        let offset = snapshot?.timeOffset ?? 0
        let calendar = Calendar.current
        let appDayStart = calendar.startOfDay(for: now.addingTimeInterval(offset))
        let nextDay = (calendar.date(byAdding: .day, value: 1, to: appDayStart) ?? appDayStart.addingTimeInterval(86_400))
            .addingTimeInterval(-offset + 30)
        var dates = [now]
        if let trip = snapshot?.trip, trip.returnsAt > now, trip.returnsAt < nextDay {
            dates.append(trip.returnsAt)
        }
        if let end = snapshot?.focus?.endsAt, end > now, end < nextDay {
            dates.append(end)
        }
        dates.append(nextDay)
        let entries = dates.sorted().map { GoobyEntry(date: $0, snapshot: snapshot, portrait: portrait) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

extension GoobyWidgetSnapshot {
    static func sample(_ language: String) -> GoobyWidgetSnapshot {
        let english = language == "en"
        let goals = [
            Goal(id: "sample-water", title: english ? "Drink water" : "Wasser trinken", icon: "drop.fill", colorHex: "C8E9FF", count: 1, target: 1, isDailyGoal: false),
            Goal(id: "sample-stretch", title: english ? "Stretch a little" : "Kurz strecken", icon: "figure.walk", colorHex: "C6EFDC", count: 0, target: 1, isDailyGoal: true),
            Goal(id: "sample-journal", title: english ? "Write one line" : "Eine Zeile schreiben", icon: "pencil", colorHex: "FFD6E7", count: 0, target: 1, isDailyGoal: false)
        ]
        return GoobyWidgetSnapshot(
            dayKey: GoobyWidgetSnapshot.dayKey(for: Date(), offset: 0),
            timeOffset: 0,
            language: english ? "en" : "de",
            goobyName: "Gooby",
            stage: "baby",
            energy: 8,
            energyGoal: 12,
            sparks: 40,
            streak: 3,
            goals: goals,
            trip: nil,
            focus: nil,
            updatedAt: Date()
        )
    }
}
