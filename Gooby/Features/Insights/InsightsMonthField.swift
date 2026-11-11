import SwiftUI

struct InsightsMonthField: View {
    var engine: GoobyEngine
    var months: [InsightsMonth]
    @Binding var scope: InsightsScope
    var today: Date
    var still: Bool
    @State private var shown = false

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(engine.t("insights.mood.title"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                Spacer(minLength: 8)
                InsightsScopeMenu(engine: engine, scope: $scope)
            }
            grid
                .animation(still ? nil : .easeInOut(duration: 0.25), value: scope)
            legend
        }
        .onAppear {
            guard !still else { return }
            withAnimation(.easeOut(duration: 0.35)) { shown = true }
        }
    }

    private var todayKey: String { DayKey.make(calendar.startOfDay(for: today), calendar: calendar) }
    private var todayRow: Int { InsightsLedger.mondayRow(today, calendar: calendar) }

    private var grid: some View {
        GeometryReader { geo in
            let labelWidth: CGFloat = 38
            let gap: CGFloat = 6
            let monthWidth = max(CGFloat(40), (geo.size.width - labelWidth - gap * 4) / 4)
            let maxWeeks = CGFloat(max(1, months.map(\.weekCount).max() ?? 1))
            let cellGap: CGFloat = 2
            let rawCell = (monthWidth - cellGap * (maxWeeks - 1)) / maxWeeks
            let cell = min(CGFloat(12), max(CGFloat(4), rawCell.rounded(.down)))
            let gridHeight = cell * 7 + cellGap * 6
            HStack(alignment: .top, spacing: gap) {
                ForEach(months) { month in
                    VStack(spacing: 6) {
                        Text(InsightsFormat.monthTitle(month.start, language: engine.languageCode, calendar: calendar))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(InsightsPalette.sub)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(height: 16)
                        weekColumns(month, cell: cell, gap: cellGap)
                    }
                    .frame(width: monthWidth, alignment: .top)
                }
                VStack(alignment: .trailing, spacing: 6) {
                    Color.clear.frame(height: 16)
                    VStack(alignment: .trailing, spacing: cellGap) {
                        ForEach(0..<7, id: \.self) { row in
                            Text(weekdayName(row))
                                .font(.system(size: min(CGFloat(11), cell), weight: .semibold, design: .rounded))
                                .foregroundStyle(row == todayRow ? InsightsPalette.ink : InsightsPalette.sub)
                                .frame(height: cell, alignment: .trailing)
                        }
                    }
                    .frame(height: gridHeight, alignment: .top)
                }
                .frame(width: labelWidth, alignment: .trailing)
            }
        }
        .frame(height: 132)
        .accessibilityElement(children: .contain)
    }

    private func weekColumns(_ month: InsightsMonth, cell: CGFloat, gap: CGFloat) -> some View {
        HStack(alignment: .top, spacing: gap) {
            ForEach(0..<month.weekCount, id: \.self) { week in
                VStack(spacing: gap) {
                    ForEach(0..<7, id: \.self) { row in
                        dotView(month.cell(week: week, row: row), cell: cell, week: week, row: row)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func dotView(_ dot: InsightsDot?, cell: CGFloat, week: Int, row: Int) -> some View {
        let shownTone = visibleTone(dot)
        let hidden = dot?.inMonth == true && dot?.tone != nil && shownTone == nil
        let side = max(CGFloat(4), cell - 3)
        Circle()
            .fill(dot?.inMonth == true ? color(shownTone) : Color.clear)
            .frame(width: side, height: side)
            .scaleEffect(still || shown ? (hidden ? 0.35 : 1) : 0.15)
            .opacity(still || shown ? (hidden ? 0.25 : 1) : 0)
            .frame(width: cell, height: cell)
            .animation(
                still ? nil : .spring(response: 0.4, dampingFraction: 0.72).delay(Double(week) * 0.035 + Double(row) * 0.018),
                value: shown
            )
            .animation(still ? nil : .easeInOut(duration: 0.22), value: hidden)
            .accessibilityHidden(dot?.inMonth != true)
            .accessibilityLabel(dotLabel(dot, tone: shownTone))
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(.positive)
            legendItem(.neutral)
            legendItem(.negative)
        }
        .accessibilityElement(children: .combine)
    }

    private func legendItem(_ tone: InsightsTone) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color(tone))
                .frame(width: 14, height: 14)
            Text(engine.t("insights.legend.\(tone.rawValue)"))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(InsightsPalette.ink.opacity(0.8))
        }
    }

    private func visibleTone(_ dot: InsightsDot?) -> InsightsTone? {
        guard let dot, dot.inMonth, let tone = dot.tone, scope.allows(tone) else { return nil }
        return tone
    }

    private func color(_ tone: InsightsTone?) -> Color {
        switch tone {
        case .positive: return InsightsPalette.positive
        case .neutral: return InsightsPalette.neutral
        case .negative: return InsightsPalette.negative
        case nil: return InsightsPalette.emptyDot
        }
    }

    private func weekdayName(_ row: Int) -> String {
        var symbolsCalendar = calendar
        symbolsCalendar.locale = Locale(identifier: engine.languageCode)
        let symbols = symbolsCalendar.shortWeekdaySymbols
        let index = (row + 1) % 7
        let name = symbols.indices.contains(index) ? symbols[index] : ""
        if row == todayRow { return engine.tf("insights.weekday.today", name) }
        return name
    }

    private func dotLabel(_ dot: InsightsDot?, tone: InsightsTone?) -> String {
        guard let dot, dot.inMonth, let date = DayKey.parse(dot.dayKey, calendar: calendar) else { return "" }
        let day = InsightsFormat.medium(date, language: engine.languageCode, calendar: calendar)
        let toneName = tone.map { engine.t("insights.legend.\($0.rawValue)") } ?? engine.t("insights.dot.empty")
        return engine.tf("insights.dot.tone", day, toneName)
    }
}
