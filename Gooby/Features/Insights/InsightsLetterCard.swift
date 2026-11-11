import SwiftUI

// The letter is built on this iPhone from the day's moods, goals and journal.
// There is no send button, no share sheet and no mail composer.

struct InsightsLetterIcon: View {
    var side: CGFloat = 72

    var body: some View {
        Group {
            if PackArt.image("pack-newsletter") != nil {
                PackImage(name: "pack-newsletter", side: side)
            } else {
                drawn
            }
        }
        .frame(width: side * 1.12, height: side * 1.12)
        .accessibilityHidden(true)
    }

    private var drawn: some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.24, style: .continuous)
                .fill(InsightsPalette.letter)
                .frame(width: side, height: side)
                .rotationEffect(.degrees(-8))
            RoundedRectangle(cornerRadius: side * 0.08, style: .continuous)
                .fill(Color.white)
                .frame(width: side * 0.5, height: side * 0.56)
            VStack(spacing: side * 0.04) {
                RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x8E9BA6)).frame(width: side * 0.32, height: side * 0.045)
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x55ACEE)).frame(width: side * 0.22, height: side * 0.12)
                RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0xC5CED6)).frame(width: side * 0.32, height: side * 0.03)
                RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0xC5CED6)).frame(width: side * 0.32, height: side * 0.03)
            }
        }
    }
}

enum InsightsLetterCopy {
    @MainActor
    static func lines(engine: GoobyEngine, facts: InsightsLetterFacts) -> (title: String, subtitle: String, body: [String], stays: String) {
        let trimmed = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let pet = trimmed.isEmpty ? "Gooby" : trimmed
        var body = [engine.tf("insights.letter.hello", pet)]
        if facts.done > 0 || facts.due > 0 {
            body.append(engine.tf("insights.letter.goals", facts.done, facts.due))
        } else if facts.quiet {
            body.append(engine.t("insights.letter.quiet"))
        } else {
            body.append(engine.t("insights.letter.goals.none"))
        }
        if let level = facts.moodLevel {
            body.append(engine.tf("insights.letter.mood", engine.t("mood.level.\(level)")))
        }
        if !facts.noteTitles.isEmpty {
            body.append(engine.tf("insights.letter.notes", facts.noteTitles.joined(separator: ", ")))
        }
        return (
            engine.tf("insights.letter.title", pet),
            engine.t("insights.letter.subtitle"),
            body,
            engine.t("insights.letter.stays")
        )
    }
}

struct InsightsLetterCard: View {
    var engine: GoobyEngine
    var facts: InsightsLetterFacts
    var still: Bool
    @State private var settled = false

    var body: some View {
        let copy = InsightsLetterCopy.lines(engine: engine, facts: facts)
        NavigationLink {
            InsightsLetterPage(engine: engine, facts: facts, still: still)
        } label: {
            InsightsCard {
                HStack(alignment: .top, spacing: 12) {
                    InsightsLetterIcon(side: 52)
                        .scaleEffect(still || settled ? 1 : 0.92)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(copy.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(InsightsPalette.ink)
                            .multilineTextAlignment(.leading)
                        Text(copy.subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsPalette.sub)
                        Text(copy.body.joined(separator: " "))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsPalette.ink.opacity(0.82))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        Text(copy.stays)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(InsightsPalette.sub)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(copy.stays)
        .onAppear {
            guard !still, !settled else { return }
            withAnimation(.easeOut(duration: 0.35)) { settled = true }
        }
    }
}

struct InsightsLetterPage: View {
    var engine: GoobyEngine
    var facts: InsightsLetterFacts
    var still: Bool
    @State private var settled = false
    @State private var about = false

    var body: some View {
        let copy = InsightsLetterCopy.lines(engine: engine, facts: facts)
        InsightsScreen(
            title: "",
            back: engine.t("look.back"),
            trailingSymbol: "bell.fill",
            trailingLabel: engine.t("insights.letter.bell"),
            trailingAction: { withAnimation(still ? nil : .spring(response: 0.35, dampingFraction: 0.8)) { about.toggle() } }
        ) {
            VStack(spacing: 14) {
                TimelineView(.animation(minimumInterval: still ? 8 : 1.0 / 30.0, paused: still)) { timeline in
                    let wave = still ? 0 : sin(timeline.date.timeIntervalSinceReferenceDate * 1.25)
                    InsightsLetterIcon(side: 88)
                        .scaleEffect(still || settled ? 1 : 0.92)
                        .offset(y: wave * 6)
                        .rotationEffect(.degrees(wave * 3))
                }
                .frame(height: 120)
                Text(copy.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                    .multilineTextAlignment(.center)
                Text(copy.subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
                if about {
                    Text(copy.stays)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(InsightsPalette.ink)
                        .multilineTextAlignment(.center)
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: 0xFFF3D6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(copy.body.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsPalette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(copy.stays)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(InsightsPalette.sub)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            guard !still, !settled else { return }
            withAnimation(.easeOut(duration: 0.35)) { settled = true }
        }
    }
}
