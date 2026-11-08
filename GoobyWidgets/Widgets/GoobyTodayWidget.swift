import SwiftUI
import WidgetKit

struct GoobyTodayEntry: TimelineEntry {
    var date: Date
    var snapshot: GoobyWidgetSnapshot?
}

/// Reads the app's snapshot from the App Group container (nil without the group) and refreshes
/// every 30 minutes; the app also reloads the timelines whenever its data changes.
struct GoobyTodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoobyTodayEntry {
        GoobyTodayEntry(date: Date(), snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (GoobyTodayEntry) -> Void) {
        completion(GoobyTodayEntry(date: Date(), snapshot: GoobyWidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoobyTodayEntry>) -> Void) {
        let now = Date()
        let entry = GoobyTodayEntry(date: now, snapshot: GoobyWidgetSnapshot.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct GoobyTodayWidget: Widget {
    static let kind = "GoobyToday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: GoobyTodayWidget.kind, provider: GoobyTodayProvider()) { entry in
            GoobyTodayWidgetView(snapshot: entry.snapshot, date: entry.date)
                .containerBackground(for: .widget) { GoobyTokens.cream }
                .widgetURL(GoobyLink.home.url)
        }
        .configurationDisplayName(GoobyText.pick(nil, de: "Gooby heute", en: "Gooby today"))
        .description(GoobyText.pick(nil, de: "Deine Ziele für heute auf einen Blick.", en: "Today's goals at a glance."))
        .supportedFamilies([.systemSmall])
    }
}
