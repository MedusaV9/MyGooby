import SwiftUI

struct StatsScreen: View {
    var engine: GoobyEngine

    var body: some View {
        let runs = engine.all(AdventureRun.self).filter { $0.status == "claimed" }.count
        let completions = engine.all(HabitLog.self).filter { !$0.skipped }.reduce(0) { $0 + $1.count }
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                stat(engine.t("today.streak"), "\(engine.streak())")
                stat(engine.t("stats.completions"), "\(completions)")
                stat(engine.t("stats.adventures"), "\(runs)")
                stat(engine.t("stats.earned"), "\(engine.wallet.lifetimeSparksEarned)")
                stat(engine.t("stats.spent"), "\(engine.wallet.lifetimeSparksSpent)")
                stat(engine.t("journal.title"), "\(engine.all(JournalEntry.self).count)")
                stat(engine.t("friends.title"), "\(engine.all(MiniFriend.self).count)")
                stat(engine.t("stats.places"), "\(engine.all(PlaceProgress.self).filter(\.unlocked).count)")
                stat(engine.t("stats.discoveries"), "\(engine.all(DiscoveryRecord.self).count)")
                stat(engine.t("pet.stage"), engine.t("pet.stage.\(Growth.stage(of: engine.pet))"))
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("stats.title"))
    }

    private func stat(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).font(.system(.headline, design: .rounded))
        }
        .foregroundStyle(Theme.ink)
        .padding(12)
        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
