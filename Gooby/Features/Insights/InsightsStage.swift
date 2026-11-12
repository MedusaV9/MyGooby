import SwiftUI

struct InsightsStage: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var scope: InsightsScope = .overall

    private let calendar = Calendar.current
    private var still: Bool { reduceMotion || systemReduce || engine.reduceMotion }

    var body: some View {
        let snapshot = InsightsReader.snapshot(engine)
        let months = InsightsLedger.months(ending: snapshot.now, marks: snapshot.moods, calendar: calendar)
        let moodTags = InsightsLedger.tags(marks: snapshot.moods, months: months)
        let range = rangeTitle(months)
        let facts = InsightsLedger.letter(snapshot, on: snapshot.now, calendar: calendar)
        InsightsScreen(title: engine.t("insights.title"), back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 16) {
                PackBanner(name: "pack-sky", height: 88)
                InsightsMonthField(
                    engine: engine,
                    months: months,
                    scope: $scope,
                    today: snapshot.now,
                    still: still
                )
                .modifier(InsightsRise(index: 0, still: still))
                NavigationLink {
                    InsightsBreakdownPage(
                        engine: engine,
                        breakdown: InsightsLedger.breakdown(marks: snapshot.moods, months: months),
                        range: range,
                        still: still
                    )
                } label: {
                    InsightsPill(title: engine.t("insights.breakdown"), fill: InsightsPalette.positive, ink: .white)
                }
                .buttonStyle(.plain)
                .modifier(InsightsRise(index: 1, still: still))
                tagButton(moodTags, range: range)
                    .modifier(InsightsRise(index: 2, still: still))
                InsightsRankCard(engine: engine, habits: snapshot.habits, logs: snapshot.logs, ending: snapshot.now)
                    .modifier(InsightsRise(index: 3, still: still))
                InsightsReflectionCard(engine: engine, notes: snapshot.notes, moods: snapshot.moods, ending: snapshot.now)
                    .modifier(InsightsRise(index: 4, still: still))
                NavigationLink {
                    InsightsDayHistory(engine: engine, reduceMotion: still)
                } label: {
                    InsightsCard {
                        HStack(spacing: 12) {
                            LookIcon(kind: .history)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(engine.t("insights.history"))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(InsightsPalette.ink)
                                Text(engine.tf("insights.history.today", InsightsFormat.dayMonth(snapshot.now, language: engine.languageCode, calendar: calendar)))
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(InsightsPalette.sub)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(InsightsPalette.sub)
                        }
                    }
                }
                .buttonStyle(.plain)
                .modifier(InsightsRise(index: 5, still: still))
                YearReview.open(engine: engine, reduceMotion: still)
                    .modifier(InsightsRise(index: 6, still: still))
                InsightsLetterCard(engine: engine, facts: facts, still: still)
                    .modifier(InsightsRise(index: 7, still: still))
            }
        }
    }

    @ViewBuilder
    private func tagButton(_ tags: [InsightsTagCount], range: String) -> some View {
        if tags.isEmpty {
            InsightsPill(title: engine.t("insights.tags"), fill: InsightsPalette.tagFill, ink: InsightsPalette.tagInk)
                .accessibilityLabel(engine.t("insights.tags"))
                .accessibilityValue(engine.t("insights.tags.empty"))
        } else {
            NavigationLink {
                InsightsTagPage(engine: engine, tags: tags, range: range)
            } label: {
                InsightsPill(title: engine.t("insights.tags"), fill: InsightsPalette.tagFill, ink: InsightsPalette.ink)
            }
            .buttonStyle(.plain)
        }
    }

    private func rangeTitle(_ months: [InsightsMonth]) -> String {
        guard let first = months.first, let last = months.last else { return "" }
        let start = InsightsFormat.monthTitle(first.start, language: engine.languageCode, calendar: calendar)
        let end = InsightsFormat.monthTitle(last.start, language: engine.languageCode, calendar: calendar)
        if start == end { return start }
        return "\(start) – \(end)"
    }
}
