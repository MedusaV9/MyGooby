import SwiftUI

/// Local recap of the current calendar year.
/// Hook: `YearReview.open`, called from `InsightsStage`.
enum YearReview {
    @MainActor
    static func open(engine: GoobyEngine, reduceMotion: Bool) -> YearReviewLink {
        YearReviewLink(engine: engine, reduceMotion: reduceMotion)
    }
}

struct YearReviewLink: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        let facts = YearReviewLedger.read(engine)
        NavigationLink {
            YearReviewScreen(engine: engine, reduceMotion: reduceMotion)
        } label: {
            InsightsCard {
                HStack(spacing: 12) {
                    YearReviewMark()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.t("year.title"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(InsightsPalette.ink)
                        Text(YearReviewCopy.rowDetail(engine, facts))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsPalette.sub)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(InsightsPalette.sub)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

struct YearReviewScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    private var still: Bool { reduceMotion || systemReduce || engine.reduceMotion }

    var body: some View {
        let facts = YearReviewLedger.read(engine)
        InsightsScreen(title: engine.t("year.title"), back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 16) {
                yearBand(facts)
                if facts.isEmpty {
                    emptyBand
                } else {
                    factsCard(facts)
                    monthCard(facts)
                }
            }
        }
    }

    private func yearBand(_ facts: YearReviewFacts) -> some View {
        InsightsCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text(String(facts.year))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(InsightsPalette.ink)
                        .accessibilityLabel(String(facts.year))
                    Spacer(minLength: 0)
                    gooby
                }
                Text(engine.t("year.lead"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(engine.t("year.stays"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var emptyBand: some View {
        InsightsCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(engine.t("year.empty.title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(engine.t("year.empty.body"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func factsCard(_ facts: YearReviewFacts) -> some View {
        InsightsCard {
            VStack(alignment: .leading, spacing: 12) {
                habitRow(facts)
                rowRule
                adventureRow(facts)
                rowRule
                sparkRow(facts)
            }
        }
    }

    private func habitRow(_ facts: YearReviewFacts) -> some View {
        factRow(title: engine.t("year.habits"), tint: Color(hex: 0x34C759)) {
            VStack(alignment: .leading, spacing: 2) {
                if facts.habitChecks == 0 {
                    Text(engine.t("year.habits.zero")).foregroundStyle(InsightsPalette.sub)
                } else {
                    Text(YearReviewCopy.count(engine, facts.habitDays, one: "year.days.one", many: "year.days.many"))
                        .foregroundStyle(InsightsPalette.ink)
                    Text(YearReviewCopy.count(engine, facts.habitChecks, one: "year.checks.one", many: "year.checks.many"))
                        .foregroundStyle(InsightsPalette.sub)
                }
            }
        }
    }

    private func adventureRow(_ facts: YearReviewFacts) -> some View {
        let places = YearReviewCopy.places(engine, facts.placeIDs)
        return factRow(title: engine.t("year.adventures"), tint: Color(hex: 0x3CB4F5)) {
            VStack(alignment: .leading, spacing: 2) {
                if facts.adventures == 0 {
                    Text(engine.t("year.adventures.zero")).foregroundStyle(InsightsPalette.sub)
                } else {
                    Text(YearReviewCopy.count(engine, facts.adventures, one: "year.trips.one", many: "year.trips.many"))
                        .foregroundStyle(InsightsPalette.ink)
                    if !places.isEmpty {
                        Text(places)
                            .foregroundStyle(InsightsPalette.sub)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func sparkRow(_ facts: YearReviewFacts) -> some View {
        factRow(title: engine.t("year.sparks"), tint: Color(hex: 0xE39A1A)) {
            VStack(alignment: .leading, spacing: 2) {
                if facts.sparks == 0 {
                    Text(engine.t("year.sparks.zero")).foregroundStyle(InsightsPalette.sub)
                } else {
                    Text(engine.tf("year.sparks.count", facts.sparks))
                        .foregroundStyle(InsightsPalette.ink)
                    Text(engine.t("year.sparks.note"))
                        .foregroundStyle(InsightsPalette.sub)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func monthCard(_ facts: YearReviewFacts) -> some View {
        InsightsCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(engine.t("year.months"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                Text(engine.t("year.months.hint"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
                YearMonthStrip(engine: engine, facts: facts, still: still)
            }
        }
    }

    private func factRow<Content: View>(title: String, tint: Color, @ViewBuilder lines: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint)
                .frame(width: 12, height: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                lines()
                    .font(.system(size: 15, weight: .medium, design: .rounded))
            }
        }
    }

    private var rowRule: some View {
        Rectangle()
            .fill(InsightsPalette.track)
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private var gooby: some View {
        GoobyCharacterView(
            look: engine.wornLook(),
            stage: Growth.stage(of: engine.pet),
            animation: still ? .sit : .breathe,
            reduceMotion: still,
            companion: nil,
            showCompanion: false
        )
        .frame(width: 88, height: 88)
        .accessibilityHidden(true)
    }
}

struct YearReviewMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: 0xF6C656))
            VStack(spacing: 3) {
                Circle()
                    .fill(Color(hex: 0xFFF6EA))
                    .frame(width: 10, height: 10)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 22, height: 14)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color(hex: 0xE39A1A))
                            .frame(width: 1.5)
                    }
            }
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }
}

struct YearMonthStrip: View {
    var engine: GoobyEngine
    var facts: YearReviewFacts
    var still: Bool
    @State private var grown = false

    private let calendar = Calendar.current

    var body: some View {
        let peak = max(facts.monthDays.max() ?? 0, 1)
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<12, id: \.self) { index in
                let days = index < facts.monthDays.count ? facts.monthDays[index] : 0
                let name = YearReviewCopy.monthName(index + 1, language: engine.languageCode, calendar: calendar)
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(days == 0 ? InsightsPalette.emptyDot : Color(hex: 0x34C759))
                        .frame(height: barHeight(days: days, peak: peak))
                    Text(name)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(InsightsPalette.sub)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(YearReviewCopy.monthAccess(engine, name: name, days: days))
            }
        }
        .frame(height: 72, alignment: .bottom)
        .onAppear {
            guard !still else {
                grown = true
                return
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) { grown = true }
        }
    }

    private func barHeight(days: Int, peak: Int) -> CGFloat {
        let full: CGFloat = days == 0 ? 4 : 8 + 36 * CGFloat(days) / CGFloat(peak)
        return grown || still ? full : 4
    }
}

enum YearReviewCopy {
    @MainActor
    static func rowDetail(_ engine: GoobyEngine, _ facts: YearReviewFacts) -> String {
        if facts.isEmpty { return "\(facts.year) · \(engine.t("year.row.empty"))" }
        var parts = ["\(facts.year)"]
        if facts.habitDays > 0 {
            parts.append(count(engine, facts.habitDays, one: "year.days.short.one", many: "year.days.short.many"))
        }
        if facts.adventures > 0 {
            parts.append(count(engine, facts.adventures, one: "year.trips.one", many: "year.trips.many"))
        }
        if facts.sparks > 0 {
            parts.append(engine.tf("year.sparks.count", facts.sparks))
        }
        return parts.joined(separator: " · ")
    }

    @MainActor
    static func count(_ engine: GoobyEngine, _ value: Int, one: String, many: String) -> String {
        value == 1 ? engine.t(one) : engine.tf(many, value)
    }

    @MainActor
    static func places(_ engine: GoobyEngine, _ ids: [String]) -> String {
        let names = ids.compactMap { id -> String? in
            let name = engine.catalog.placesByID[id]?.name.text(engine.languageCode)
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? nil : name
        }
        guard !names.isEmpty else { return "" }
        let shown = Array(names.prefix(3))
        var pieces = shown
        let extra = names.count - shown.count
        if extra == 1 { pieces.append(engine.t("year.places.more.one")) }
        if extra > 1 { pieces.append(engine.tf("year.places.more.many", extra)) }
        return join(pieces, and: engine.t("year.and"))
    }

    static func join(_ names: [String], and: String) -> String {
        switch names.count {
        case 0: return ""
        case 1: return names[0]
        case 2: return "\(names[0]) \(and) \(names[1])"
        default:
            let head = names.dropLast().joined(separator: ", ")
            return "\(head) \(and) \(names[names.count - 1])"
        }
    }

    static func monthName(_ month: Int, language: String, calendar: Calendar) -> String {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = month
        parts.day = 1
        let date = calendar.date(from: parts) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        var name = formatter.string(from: date)
        if name.hasSuffix(".") { name.removeLast() }
        return name
    }

    @MainActor
    static func monthAccess(_ engine: GoobyEngine, name: String, days: Int) -> String {
        if days == 1 { return engine.tf("year.month.one", name) }
        return engine.tf("year.month.many", name, days)
    }
}
