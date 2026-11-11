import SwiftUI
import WidgetKit

@main
struct GoobyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GoobyCompanionWidget()
        GoobyGoalsWidget()
        GoobyLiveActivityWidget()
        if #available(iOS 18.0, *) {
            GoobyFocusControl()
            GoobyBreathControl()
            GoobyGoalsControl()
        }
    }
}
