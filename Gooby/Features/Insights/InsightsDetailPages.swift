import SwiftUI

struct InsightsBreakdownPage: View {
    var engine: GoobyEngine
    var breakdown: InsightsBreakdown
    var range: String
    var still: Bool
    @State private var filled = false

    private let tones: [InsightsTone] = [.positive, .neutral, .negative]

    var body: some View {
        let shares = breakdown.shares()
        InsightsScreen(title: engine.t("insights.breakdown.title"), back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 16) {
                Text(range)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
                Text(engine.tf("insights.breakdown.count", breakdown.total))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                if breakdown.total == 0 {
                    Text(engine.t("insights.breakdown.empty"))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(InsightsPalette.sub)
                } else {
                    ForEach(tones, id: \.rawValue) { tone in
                        bar(tone, share: shares[tone] ?? 0)
                    }
                }
            }
        }
        .onAppear {
            guard !still, !filled else { return }
            withAnimation(.easeOut(duration: 0.45)) { filled = true }
        }
    }

    private func bar(_ tone: InsightsTone, share: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(swatch(tone))
                    .frame(width: 14, height: 14)
                Text(engine.t("insights.legend.\(tone.rawValue)"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                Spacer()
                Text(engine.tf("insights.breakdown.share", breakdown.count(tone), share))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(InsightsPalette.track)
                    Capsule()
                        .fill(swatch(tone))
                        .frame(width: geo.size.width * CGFloat(still || filled ? share : 0) / 100)
                }
            }
            .frame(height: 12)
            .accessibilityLabel(engine.tf("insights.dot.tone", engine.t("insights.legend.\(tone.rawValue)"), engine.tf("insights.breakdown.share", breakdown.count(tone), share)))
        }
    }

    private func swatch(_ tone: InsightsTone) -> Color {
        switch tone {
        case .positive: return InsightsPalette.positive
        case .neutral: return InsightsPalette.neutral
        case .negative: return InsightsPalette.negative
        }
    }
}

struct InsightsTagPage: View {
    var engine: GoobyEngine
    var tags: [InsightsTagCount]
    var range: String

    var body: some View {
        InsightsScreen(title: engine.t("insights.tags.title"), back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(range)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
                if tags.isEmpty {
                    Text(engine.t("insights.tags.empty"))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(InsightsPalette.sub)
                } else {
                    ForEach(tags) { tag in
                        InsightsCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(tagTitle(tag.tag))
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(InsightsPalette.ink)
                                    Spacer()
                                    Text(engine.tf("insights.tags.count", tag.count))
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(InsightsPalette.sub)
                                }
                                mix(tag)
                            }
                        }
                    }
                }
            }
        }
    }

    private func mix(_ tag: InsightsTagCount) -> some View {
        let total = CGFloat(max(1, tag.positive + tag.neutral + tag.negative))
        return GeometryReader { geo in
            HStack(spacing: 2) {
                mixPiece(tag.positive, total: total, width: geo.size.width, color: InsightsPalette.positive)
                mixPiece(tag.neutral, total: total, width: geo.size.width, color: InsightsPalette.neutral)
                mixPiece(tag.negative, total: total, width: geo.size.width, color: InsightsPalette.negative)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func mixPiece(_ count: Int, total: CGFloat, width: CGFloat, color: Color) -> some View {
        if count > 0 {
            Capsule()
                .fill(color)
                .frame(width: max(CGFloat(4), width * CGFloat(count) / total - 2))
        }
    }

    private func tagTitle(_ tag: String) -> String {
        let moodKey = "mood.tag.\(tag)"
        let mood = engine.t(moodKey)
        if mood != moodKey { return mood }
        let themeKey = "theme.\(tag)"
        let theme = engine.t(themeKey)
        if theme != themeKey { return theme }
        return tag
    }
}
