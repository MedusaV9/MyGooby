import SwiftUI

struct QuestScreen: View {
    var engine: GoobyEngine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("quests.daily")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                questList(engine.all(QuestRecord.self).filter { $0.kind == "daily" && $0.dayKey == engine.dayKey() })
                Text(engine.t("quests.milestones")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                questList(engine.all(QuestRecord.self).filter { $0.kind == "milestone" })
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("quests.title"))
        .onAppear { engine.recomputeQuests(); engine.save() }
    }

    private func questList(_ rows: [QuestRecord]) -> some View {
        ForEach(rows) { quest in
            let template = engine.catalog.questsByID[quest.templateID]
            VStack(alignment: .leading, spacing: 6) {
                Text(template?.title.text(engine.languageCode) ?? quest.templateID).font(.system(.headline, design: .rounded))
                Text(template?.detail.text(engine.languageCode) ?? "").font(.system(.caption, design: .rounded))
                ProgressRibbon(value: Double(quest.progress) / Double(max(1, quest.goal)))
                Text("\(quest.progress)/\(quest.goal)").font(.system(.caption, design: .rounded))
                if quest.claimed {
                    Text(engine.t("quests.claimed"))
                } else if quest.progress >= quest.goal {
                    Button(engine.tf("quests.claim", quest.rewardSparks)) { _ = engine.claimQuest(quest) }
                        .buttonStyle(GoobyButtonStyle(fill: Theme.yellow, ink: Theme.ink))
                }
            }
            .foregroundStyle(Theme.ink)
            .padding(12)
            .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
