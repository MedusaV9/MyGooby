import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct GoobyControlFocusIntent: AppIntent {
    static let title: LocalizedStringResource = "Fokus starten"
    static let openAppWhenRun = false
    static var isDiscoverable: Bool { false }

    func perform() async throws -> some IntentResult & OpensIntent {
        GoobySharedStore.saveRoute(link: GoobyLink.focus.rawValue, minutes: 10)
        return .result(opensIntent: OpenURLIntent(GoobyLink.focusURL(minutes: 10)))
    }
}

@available(iOS 18.0, *)
struct GoobyControlBreathIntent: AppIntent {
    static let title: LocalizedStringResource = "Atmen mit Gooby"
    static let openAppWhenRun = false
    static var isDiscoverable: Bool { false }

    func perform() async throws -> some IntentResult & OpensIntent {
        GoobySharedStore.saveRoute(link: GoobyLink.breath.rawValue)
        return .result(opensIntent: OpenURLIntent(GoobyLink.breath.url))
    }
}

@available(iOS 18.0, *)
struct GoobyControlGoalsIntent: AppIntent {
    static let title: LocalizedStringResource = "Tagesziele"
    static let openAppWhenRun = false
    static var isDiscoverable: Bool { false }

    func perform() async throws -> some IntentResult & OpensIntent {
        GoobySharedStore.saveRoute(link: GoobyLink.goals.rawValue)
        return .result(opensIntent: OpenURLIntent(GoobyLink.goals.url))
    }
}

@available(iOS 18.0, *)
struct GoobyFocusControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "app.mygooby.gooby.control.focus") {
            ControlWidgetButton(action: GoobyControlFocusIntent()) {
                Label("Fokus starten", systemImage: "timer")
            }
        }
        .displayName("Fokus starten")
        .description("Startet zehn ruhige Minuten mit Gooby.")
    }
}

@available(iOS 18.0, *)
struct GoobyBreathControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "app.mygooby.gooby.control.breath") {
            ControlWidgetButton(action: GoobyControlBreathIntent()) {
                Label("Atmen mit Gooby", systemImage: "wind")
            }
        }
        .displayName("Atmen mit Gooby")
        .description("Öffnet die Atemübung.")
    }
}

@available(iOS 18.0, *)
struct GoobyGoalsControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "app.mygooby.gooby.control.goals") {
            ControlWidgetButton(action: GoobyControlGoalsIntent()) {
                Label("Tagesziele", systemImage: "list.bullet.circle.fill")
            }
        }
        .displayName("Tagesziele")
        .description("Öffnet Gooby bei deinen Zielen.")
    }
}
