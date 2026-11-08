import ActivityKit
import SwiftUI
import WidgetKit

/// The timer Live Activity on the Lock Screen and in the Dynamic Island (adventure, focus,
/// breathing). Views come from GoobyShared/LiveActivityViews so the app can preview them.
/// The app starts, updates and ends it locally (Gooby/App/Services/GoobyLiveActivities.swift);
/// when a timer runs out while the app is closed, the stale date flips it to its done look.
/// A tap opens the activity's screen through gooby://adventure, gooby://focus or gooby://breath.
struct GoobyTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoobyTimerAttributes.self) { context in
            GoobyTimerLockView(attributes: context.attributes, state: context.state, isStale: context.isStale)
                .activityBackgroundTint(GoobyTimerLockView.tint(context.attributes.kind))
                .activitySystemActionForegroundColor(GoobyTimerLockView.actionInk(context.attributes.kind))
                .widgetURL(context.attributes.kind.link.url)
        } dynamicIsland: { context in
            let look = GoobyActivityLook(attributes: context.attributes, state: context.state, isStale: context.isStale)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    GoobyIslandLeading(look: look)
                        .padding(.leading, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    GoobyIslandTrailing(look: look)
                        .padding(.trailing, 2)
                }
                DynamicIslandExpandedRegion(.center) {
                    GoobyIslandCenter(look: look)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    GoobyIslandBottom(look: look)
                }
            } compactLeading: {
                GoobyIslandCompactLeading(look: look)
            } compactTrailing: {
                GoobyIslandCompactTrailing(look: look)
            } minimal: {
                GoobyIslandMinimal(look: look)
            }
            .widgetURL(context.attributes.kind.link.url)
            .keylineTint(look.accent)
        }
    }
}
