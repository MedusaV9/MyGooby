import SwiftUI
import WidgetKit

/// Entry point of the widget extension (embedded in Gooby.app/PlugIns). Home and Lock Screen
/// widgets come from the widgets extra; `GoobyTimerLiveActivity` is the one Live Activity
/// configuration and must stay in the bundle.
@main
struct GoobyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GoobyTodayWidget()
        GoobyTimerLiveActivity()
    }
}
