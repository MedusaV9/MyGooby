import ActivityKit
import SwiftUI
import WidgetKit

struct GoobyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoobyActivityAttributes.self) { context in
            GoobyLiveLockScreen(context: context)
        } dynamicIsland: { context in
            GoobyLiveIsland.make(context)
        }
    }
}

enum GoobyLiveLink {
    static func url(_ kind: GoobyActivityAttributes.Kind) -> URL {
        switch kind {
        case .adventure: return GoobyLink.adventure.url
        case .focus: return GoobyLink.focus.url
        case .breath: return GoobyLink.breath.url
        case .goals: return GoobyLink.goals.url
        }
    }
}

struct GoobyLiveCopy {
    var headline: String
    var detail: String
    var showDone: Bool

    init(_ context: ActivityViewContext<GoobyActivityAttributes>) {
        let state = context.state
        let kind = context.attributes.kind
        let paused = state.pausedRemaining != nil
        let ended = !paused && (context.isStale || Date() >= state.end)
        showDone = state.finished || ((kind == .adventure || kind == .focus) && ended)
        if kind == .adventure && showDone && !state.finished {
            headline = WidgetText.tf("back", state.language, context.attributes.goobyName)
            detail = WidgetText.t("done", state.language)
        } else if kind == .focus && showDone && !state.finished {
            headline = WidgetText.t("done", state.language)
            detail = state.detail
        } else {
            headline = state.headline
            detail = state.detail
        }
    }
}

struct GoobyLiveLockScreen: View {
    var context: ActivityViewContext<GoobyActivityAttributes>
    private var copy: GoobyLiveCopy { GoobyLiveCopy(context) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            GoobyPortrait(image: GoobyWidgetArt.badge())
                .frame(width: 52, height: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(copy.headline)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(WidgetPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(copy.detail)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(WidgetPalette.soft)
                    .lineLimit(2)
                GoobyLiveBar(context: context, copy: copy)
                HStack {
                    GoobyLiveValue(context: context, copy: copy, large: false)
                    Spacer(minLength: 0)
                    Text("\(context.state.goalsDone)/\(context.state.goalsTotal)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(WidgetPalette.lilac)
                }
            }
        }
        .padding(14)
        .environment(\.locale, Locale(identifier: context.state.language))
        .activityBackgroundTint(WidgetPalette.cream)
        .activitySystemActionForegroundColor(WidgetPalette.ink)
        .widgetURL(GoobyLiveLink.url(context.attributes.kind))
    }
}

struct GoobyLiveValue: View {
    var context: ActivityViewContext<GoobyActivityAttributes>
    var copy: GoobyLiveCopy
    var large: Bool

    private var state: GoobyActivityAttributes.ContentState { context.state }

    var body: some View {
        Group {
            if let remaining = state.pausedRemaining, !copy.showDone {
                Text(WidgetText.clock(remaining))
            } else if copy.showDone {
                Image(systemName: "checkmark.circle.fill")
            } else if context.attributes.kind == .goals {
                Text("\(state.goalsDone)/\(max(state.goalsTotal, 0))")
            } else if context.attributes.kind == .breath {
                Image(systemName: "wind")
            } else {
                Text(timerInterval: state.start...state.end, countsDown: true)
                    .multilineTextAlignment(large ? .trailing : .leading)
            }
        }
        .font(large ? .title2.weight(.bold) : .caption.weight(.bold))
        .monospacedDigit()
        .foregroundStyle(copy.showDone ? WidgetPalette.check : WidgetPalette.ink)
        .lineLimit(1)
    }
}

struct GoobyLiveBar: View {
    var context: ActivityViewContext<GoobyActivityAttributes>
    var copy: GoobyLiveCopy

    var body: some View {
        bar.tint(copy.showDone ? WidgetPalette.check : WidgetPalette.lilac)
    }

    @ViewBuilder private var bar: some View {
        if let progress = context.state.pausedProgress {
            ProgressView(value: min(1, max(0, progress)))
        } else if context.attributes.kind == .goals {
            ProgressView(value: Double(context.state.goalsDone), total: Double(max(context.state.goalsTotal, 1)))
        } else if copy.showDone || context.attributes.kind == .breath {
            ProgressView(value: copy.showDone ? 1 : 0.65)
        } else {
            ProgressView(timerInterval: context.state.start...context.state.end, countsDown: false)
        }
    }
}

enum GoobyLiveIsland {
    static func make(_ context: ActivityViewContext<GoobyActivityAttributes>) -> DynamicIsland {
        let copy = GoobyLiveCopy(context)
        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                GoobyPortrait(image: GoobyWidgetArt.badge())
                    .frame(width: 44, height: 52)
                    .padding(.leading, 4)
            }
            DynamicIslandExpandedRegion(.trailing) {
                GoobyLiveValue(context: context, copy: copy, large: true)
                    .padding(.trailing, 4)
            }
            DynamicIslandExpandedRegion(.bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(copy.headline)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(WidgetPalette.ink)
                        .lineLimit(1)
                    Text(copy.detail)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(WidgetPalette.soft)
                        .lineLimit(2)
                    GoobyLiveBar(context: context, copy: copy)
                }
                .widgetURL(GoobyLiveLink.url(context.attributes.kind))
            }
        } compactLeading: {
            GoobyPortrait(image: GoobyWidgetArt.badge())
                .frame(width: 24, height: 28)
        } compactTrailing: {
            GoobyLiveValue(context: context, copy: copy, large: false)
                .padding(.trailing, 4)
        } minimal: {
            if copy.showDone {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(WidgetPalette.check)
            } else {
                GoobyPortrait(image: GoobyWidgetArt.badge())
                    .frame(width: 18, height: 22)
            }
        }
        .keylineTint(WidgetPalette.backpack)
    }
}
