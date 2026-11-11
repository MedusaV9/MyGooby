import SwiftUI

struct InsightsRankCard: View {
    var engine: GoobyEngine
    var habits: [InsightsHabitMark]
    var logs: [InsightsLogMark]
    var ending: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var window: InsightsWindow = .fortnight
    @State private var expanded = false

    private let calendar = Calendar.current

    var body: some View {
        let report = InsightsLedger.goalReport(habits: habits, logs: logs, ending: ending, days: window.rawValue, calendar: calendar)
        InsightsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(engine.t("insights.goals"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(InsightsPalette.ink)
                    Spacer(minLength: 8)
                    InsightsWindowMenu(engine: engine, window: $window)
                }
                Text(engine.tf("insights.completed", report.completed))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
                Text(engine.t("insights.most.done"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                if report.ranks.isEmpty {
                    Text(engine.t("insights.goals.empty"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(InsightsPalette.sub)
                } else {
                    let shown = expanded ? report.ranks : Array(report.ranks.prefix(3))
                    ForEach(shown) { rank in
                        rankRow(rank)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    if report.ranks.count > 3 {
                        Button(expanded ? engine.t("insights.viewLess") : engine.t("insights.viewMore")) {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.86)) {
                                expanded.toggle()
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(InsightsPalette.sub)
                        .frame(maxWidth: .infinity)
                    }
                }
                Text(engine.t("insights.most.missed"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                    .padding(.top, 4)
                if report.missed.isEmpty {
                    Text(engine.t("insights.missed.empty"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(InsightsPalette.sub)
                } else {
                    let shown = expanded ? report.missed : Array(report.missed.prefix(3))
                    ForEach(shown) { rank in
                        rankRow(rank)
                    }
                }
            }
        }
    }

    private func rankRow(_ rank: InsightsRank) -> some View {
        HStack(alignment: .center, spacing: 10) {
            GoalGlyph(glyph: GoalArt.glyph(forSymbol: rank.icon))
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(rank.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                    .lineLimit(2)
                Text(engine.tf("insights.rate", rank.percent, rank.done, rank.due))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct InsightsReflectionCard: View {
    var engine: GoobyEngine
    var notes: [InsightsNoteMark]
    var moods: [InsightsMoodMark]
    var ending: Date
    @State private var window: InsightsWindow = .fortnight

    private let calendar = Calendar.current

    var body: some View {
        let report = InsightsLedger.reflections(notes: notes, moods: moods, ending: ending, days: window.rawValue, calendar: calendar)
        InsightsCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(engine.t("insights.reflections"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(InsightsPalette.ink)
                    Spacer(minLength: 8)
                    InsightsWindowMenu(engine: engine, window: $window)
                }
                Text(line(report))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func line(_ report: InsightsReflectionReport) -> String {
        if report.total == 0 {
            return engine.tf("insights.reflections.zero", report.positive, report.negative)
        }
        if report.total == 1 {
            return engine.tf("insights.reflections.one", report.positive, report.negative)
        }
        return engine.tf("insights.reflections.many", report.total, report.positive, report.negative)
    }
}
