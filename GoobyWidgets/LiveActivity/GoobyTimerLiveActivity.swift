import ActivityKit
import SwiftUI
import WidgetKit

/// The timer Live Activity on the Lock Screen and in the Dynamic Island (adventure, focus,
/// breathing). Views come from GoobyShared/LiveActivityViews so the app can preview them.
struct GoobyTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoobyTimerAttributes.self) { context in
            GoobyTimerLockView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(GoobyTokens.cream)
                .activitySystemActionForegroundColor(GoobyTokens.text)
                .widgetURL(context.attributes.kind.link.url)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    GoobyMiniHead(fur: context.attributes.fur, stage: context.attributes.stage)
                        .frame(width: 44, height: 44)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    GoobyTimerText(state: context.state)
                        .font(GoobyTokens.Fonts.rounded(22))
                        .foregroundStyle(GoobyTokens.progressFill)
                        .frame(maxWidth: 90, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.title)
                        .font(GoobyTokens.Fonts.rounded(15))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            } compactLeading: {
                GoobyMiniHead(fur: context.attributes.fur, stage: context.attributes.stage)
                    .frame(width: 22, height: 22)
            } compactTrailing: {
                GoobyTimerText(state: context.state)
                    .font(GoobyTokens.Fonts.rounded(14))
                    .foregroundStyle(GoobyTokens.progressFill)
                    .frame(maxWidth: 52)
            } minimal: {
                GoobyMiniHead(fur: context.attributes.fur, stage: context.attributes.stage)
                    .frame(width: 22, height: 22)
            }
            .widgetURL(context.attributes.kind.link.url)
        }
    }
}
