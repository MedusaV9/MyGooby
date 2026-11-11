import AppIntents
import SwiftUI
import WidgetKit

struct GoobyCompanionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "app.mygooby.gooby.widget.companion", provider: GoobyProvider()) { entry in
            GoobyCompanionView(entry: entry)
        }
        .configurationDisplayName("Gooby")
        .description("Goobys Energie, deine Ziele und das Abenteuer auf einen Blick.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct GoobyGoalsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "app.mygooby.gooby.widget.goals", provider: GoobyProvider()) { entry in
            GoobyGoalsView(entry: entry)
        }
        .configurationDisplayName("Tagesziele")
        .description("Hake deine Ziele direkt auf dem Home-Bildschirm ab.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct GoobyCompanionView: View {
    @Environment(\.widgetFamily) private var family
    var entry: GoobyEntry

    private var accessory: Bool {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return true
        default: return false
        }
    }

    var body: some View {
        content
            .environment(\.locale, Locale(identifier: entry.language))
            .widgetURL(entry.link)
            .containerBackground(for: .widget) { backdrop }
    }

    @ViewBuilder private var backdrop: some View {
        if accessory { Color.clear } else { WidgetPalette.background }
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .systemMedium: GoobyCompanionMedium(entry: entry)
        case .accessoryCircular: GoobyEnergyGauge(entry: entry)
        case .accessoryRectangular: GoobyCompanionRectangular(entry: entry)
        case .accessoryInline: Text(inline).lineLimit(1)
        default: GoobyCompanionSmall(entry: entry)
        }
    }

    private var inline: String {
        guard entry.snapshot != nil else { return "Gooby" }
        if !entry.isCurrentDay { return WidgetText.t("newDay", entry.language) }
        return "\(entry.name) \(entry.energy)/\(entry.energyGoal)"
    }
}

struct GoobyCompanionSmall: View {
    var entry: GoobyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                GoobyPortrait(image: entry.portrait)
                    .frame(width: 46, height: 54)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetPalette.ink)
                        .lineLimit(1)
                    Text(WidgetText.tf("goalsCount", entry.language, entry.goalsDone, entry.goalsTotal))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.soft)
                        .lineLimit(1)
                }
            }
            GoobyEnergyBar(fraction: entry.energyFraction)
            Text("\(entry.energy)/\(entry.energyGoal) \(WidgetText.t("energy", entry.language))")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetPalette.ink)
            Text(GoobyStatusLine.text(entry))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.soft)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct GoobyCompanionMedium: View {
    var entry: GoobyEntry

    var body: some View {
        HStack(spacing: 12) {
            GoobyPortrait(image: entry.portrait)
                .frame(width: 92, height: 108)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.ink)
                    .lineLimit(1)
                GoobyEnergyBar(fraction: entry.energyFraction)
                Text("\(entry.energy)/\(entry.energyGoal) \(WidgetText.t("energy", entry.language))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.ink)
                Text(WidgetText.tf("goalsCount", entry.language, entry.goalsDone, entry.goalsTotal))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.soft)
                if let streak = entry.snapshot?.streak, streak > 0, entry.isCurrentDay {
                    Text(WidgetText.tf("streak", entry.language, streak))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.lilac)
                }
                GoobyStatusLine(entry: entry)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct GoobyCompanionRectangular: View {
    var entry: GoobyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.name).font(.headline).lineLimit(1)
            Text(WidgetText.tf("goalsCount", entry.language, entry.goalsDone, entry.goalsTotal))
                .font(.caption)
                .lineLimit(1)
            Text(GoobyStatusLine.text(entry))
                .font(.caption2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GoobyEnergyGauge: View {
    var entry: GoobyEntry

    var body: some View {
        if entry.snapshot == nil {
            GoobyBunnyMark()
        } else {
            Gauge(value: entry.energyFraction) {
                Text(WidgetText.t("energy", entry.language))
            } currentValueLabel: {
                Text("\(entry.energy)")
            }
            .gaugeStyle(.accessoryCircular)
        }
    }
}

struct GoobyEnergyBar: View {
    var fraction: Double

    var body: some View {
        GeometryReader { geo in
            Capsule().fill(WidgetPalette.well)
            HStack(spacing: 0) {
                Capsule()
                    .fill(WidgetPalette.bolt)
                    .frame(width: max(8, geo.size.width * min(1, max(0, fraction))))
                Spacer(minLength: 0)
            }
        }
        .frame(height: 8)
    }
}

struct GoobyStatusLine: View {
    var entry: GoobyEntry

    var body: some View {
        if let focus = entry.runningFocus, let end = focus.endsAt, end > entry.date {
            HStack(spacing: 4) {
                Text(WidgetText.t("focus", entry.language))
                Text(timerInterval: end.addingTimeInterval(-Double(max(1, focus.plannedSeconds)))...end, countsDown: true)
                    .monospacedDigit()
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(WidgetPalette.ink)
            .lineLimit(1)
        } else {
            Text(GoobyStatusLine.text(entry))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.soft)
                .lineLimit(2)
        }
    }

    static func text(_ entry: GoobyEntry) -> String {
        let language = entry.language
        guard entry.snapshot != nil else { return WidgetText.t("openOnce", language) }
        if !entry.isCurrentDay { return WidgetText.t("newDay", language) }
        if let focus = entry.runningFocus {
            if focus.endsAt == nil { return "\(WidgetText.t("focus", language)) · \(WidgetText.t("paused", language)) \(WidgetText.clock(focus.remainingSeconds))" }
            return WidgetText.t("focus", language)
        }
        if let trip = entry.activeTrip {
            if entry.date >= trip.returnsAt { return WidgetText.tf("back", language, entry.name) }
            return WidgetText.tf("away", language, entry.name)
        }
        if entry.goalsTotal > 0, entry.goalsDone >= entry.goalsTotal { return WidgetText.t("allDone", language) }
        if entry.energy >= entry.energyGoal { return WidgetText.t("ready", language) }
        return WidgetText.tf("needEnergy", language, entry.energyGoal - entry.energy)
    }
}

struct GoobyGoalsView: View {
    @Environment(\.widgetFamily) private var family
    var entry: GoobyEntry

    private var accessory: Bool {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: return true
        default: return false
        }
    }

    var body: some View {
        content
            .environment(\.locale, Locale(identifier: entry.language))
            .containerBackground(for: .widget) { backdrop }
    }

    @ViewBuilder private var backdrop: some View {
        if accessory { Color.clear } else { WidgetPalette.background }
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .accessoryCircular:
            GoobyGoalsGauge(entry: entry).widgetURL(GoobyLink.goals.url)
        case .accessoryRectangular:
            GoobyGoalsRectangular(entry: entry).widgetURL(GoobyLink.goals.url)
        case .accessoryInline:
            Text(inline).widgetURL(GoobyLink.goals.url)
        default:
            GoobyGoalsHome(entry: entry, compact: family == .systemSmall)
        }
    }

    private var inline: String {
        guard entry.snapshot != nil, entry.isCurrentDay else { return WidgetText.t("goals", entry.language) }
        return WidgetText.tf("goalsCount", entry.language, entry.goalsDone, entry.goalsTotal)
    }
}

struct GoobyGoalsHome: View {
    var entry: GoobyEntry
    var compact: Bool

    private var rows: [GoobyWidgetSnapshot.Goal] {
        Array(entry.goals.prefix(compact ? 2 : 4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            HStack {
                Text(WidgetText.t("goals", entry.language))
                    .font(.system(size: compact ? 14 : 16, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.ink)
                Spacer(minLength: 4)
                Text("\(entry.goalsDone)/\(entry.goalsTotal)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.lilac)
                    .monospacedDigit()
            }
            if entry.snapshot == nil || !entry.isCurrentDay {
                Text(entry.snapshot == nil ? WidgetText.t("openOnce", entry.language) : WidgetText.t("newDay", entry.language))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.soft)
                Spacer(minLength: 0)
            } else if rows.isEmpty {
                Text(WidgetText.t("noGoals", entry.language))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.soft)
                Spacer(minLength: 0)
            } else {
                ForEach(rows) { goal in
                    Button(intent: GoobyToggleGoalIntent(habitID: goal.id)) {
                        GoobyGoalRow(goal: goal)
                    }
                    .buttonStyle(.plain)
                }
                let extra = entry.goalsTotal - rows.count
                if extra > 0 {
                    Text(WidgetText.tf("more", entry.language, extra))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.soft)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct GoobyGoalRow: View {
    var goal: GoobyWidgetSnapshot.Goal

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: goal.done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(goal.done ? WidgetPalette.check : WidgetPalette.soft)
            Image(systemName: GoobyWidgetArt.symbol(goal.icon))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(widgetHexString: goal.colorHex))
                .frame(width: 16)
            Text(goal.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.ink)
                .strikethrough(goal.done, color: WidgetPalette.soft)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .accessibilityLabel(goal.title)
    }
}

struct GoobyGoalsGauge: View {
    var entry: GoobyEntry

    var body: some View {
        Gauge(value: entry.goalsTotal == 0 ? 0 : Double(entry.goalsDone) / Double(entry.goalsTotal)) {
            Text(WidgetText.t("goals", entry.language))
        } currentValueLabel: {
            Text("\(entry.goalsDone)")
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct GoobyGoalsRectangular: View {
    var entry: GoobyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(WidgetText.tf("goalsCount", entry.language, entry.goalsDone, entry.goalsTotal))
                .font(.headline)
                .lineLimit(1)
            if let next = entry.goals.first(where: { !$0.done }) {
                Text(next.title).font(.caption).lineLimit(1)
            } else {
                Text(entry.goals.isEmpty ? WidgetText.t("noGoals", entry.language) : WidgetText.t("allDone", entry.language))
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
