#if canImport(SwiftUI)
import SwiftUI

struct GoobyQuestBoard: View {
    var model: GoobyEventsScreenModel
    var libraries: GoobyEventsLibraries

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(libraries.text("quests.lead", language: model.language))
                .font(.subheadline)
                .foregroundStyle(GoobyEventsPalette.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                Text(libraries.text("quests.today", language: model.language))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(GoobyEventsPalette.ink)
                if model.quests.isEmpty {
                    Text(libraries.text("quests.lead", language: model.language))
                        .foregroundStyle(GoobyEventsPalette.ink.opacity(0.7))
                } else if model.quests.allSatisfy(\.claimed) {
                    Label(libraries.text("quests.allDone", language: model.language), systemImage: "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(GoobyEventsPalette.ink)
                }
                ForEach(model.quests) { quest in
                    questCard(quest)
                }
            }
            .goobyCard(fill: Color.white.opacity(0.94))

            VStack(alignment: .leading, spacing: 14) {
                Text(libraries.text("quests.milestones", language: model.language))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(GoobyEventsPalette.ink)
                ForEach(model.milestones) { milestone in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(milestone.title)
                                .font(.headline)
                                .foregroundStyle(GoobyEventsPalette.ink)
                            Spacer(minLength: 8)
                            Text(libraries.format("quests.sparks", language: model.language, tokens: ["count": "\(milestone.sparks)"]))
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(milestone.claimed ? GoobyEventsPalette.mint : GoobyEventsPalette.butter)
                                .clipShape(Capsule())
                        }
                        Text(milestone.detail)
                            .font(.subheadline)
                            .foregroundStyle(GoobyEventsPalette.ink.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                        GoobyProgressBar(value: milestone.current, total: milestone.target, tint: GoobyEventsPalette.lavender)
                        Text(libraries.format("progress.of", language: model.language, tokens: [
                            "current": "\(milestone.current)",
                            "target": "\(milestone.target)"
                        ]))
                        .font(.caption)
                        .foregroundStyle(GoobyEventsPalette.ink.opacity(0.62))
                    }
                }
            }
            .goobyCard(fill: GoobyEventsPalette.sky.opacity(0.45))
        }
    }

    private func questCard(_ quest: GoobyQuestSnapshot) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: quest.claimed ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(quest.claimed ? GoobyEventsPalette.ink : GoobyEventsPalette.ink.opacity(0.35))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .font(.headline)
                    .foregroundStyle(GoobyEventsPalette.ink)
                Text(quest.detail)
                    .font(.subheadline)
                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                GoobyProgressBar(value: quest.progress, total: quest.target, tint: GoobyEventsPalette.mint)
                Text(quest.claimed ? libraries.text("quests.done", language: model.language) : libraries.format("progress.of", language: model.language, tokens: [
                    "current": "\(quest.progress)",
                    "target": "\(quest.target)"
                ]))
                .font(.caption.weight(.semibold))
                .foregroundStyle(GoobyEventsPalette.ink.opacity(0.66))
            }
            Spacer(minLength: 0)
            Text(libraries.format("quests.sparks", language: model.language, tokens: ["count": "\(quest.sparks)"]))
                .font(.caption.weight(.bold))
                .foregroundStyle(GoobyEventsPalette.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(GoobyEventsPalette.butter)
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
    }
}
#endif
