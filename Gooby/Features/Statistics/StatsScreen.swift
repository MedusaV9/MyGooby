import SwiftUI

/// Insights: completed goals of the last 7 days as a bar chart and the lifetime numbers as tiles.
struct StatsScreen: View {
    var engine: GoobyEngine

    var body: some View {
        let logs = engine.all(HabitLog.self).filter { !$0.skipped }
        let runs = engine.all(AdventureRun.self).filter { $0.status == "claimed" }.count
        let completions = logs.reduce(0) { $0 + $1.count }
        let stage = Growth.stage(of: engine.pet)
        MenuScroll {
            weekChart(logs)
            MenuSectionHeader(text: engine.tx("menu.stats.all", de: "Insgesamt", en: "All time"))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                tile("🔥", engine.tx("menu.stats.streak", de: "Tage in Folge", en: "Day streak"), "\(engine.streak())")
                tile("✅", engine.t("stats.completions"), "\(completions)")
                tile("🎒", engine.t("stats.adventures"), "\(runs)")
                tile("✨", engine.t("stats.earned"), "\(engine.wallet.lifetimeSparksEarned)")
                tile("🛍️", engine.t("stats.spent"), "\(engine.wallet.lifetimeSparksSpent)")
                tile("📔", engine.t("journal.title"), "\(engine.all(JournalEntry.self).count)")
                tile("🐾", engine.t("friends.title"), "\(engine.all(MiniFriend.self).count)")
                tile("🗺️", engine.t("stats.places"), "\(engine.all(PlaceProgress.self).filter(\.unlocked).count)")
                tile("🔍", engine.t("stats.discoveries"), "\(engine.all(DiscoveryRecord.self).count)")
                tile("🐰", engine.t("pet.stage"), engine.t("pet.stage.\(stage)"))
            }
        }
        .menuChrome(engine, title: engine.tx("menu.insights", de: "Einblicke", en: "Insights"))
    }

    private func weekChart(_ logs: [HabitLog]) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: engine.now())
        let days: [Date] = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        let byDay = Dictionary(grouping: logs, by: \.dayKey).mapValues { $0.reduce(0) { $0 + $1.count } }
        let values = days.map { byDay[DayKey.make($0)] ?? 0 }
        let top = max(1, values.max() ?? 1)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.setLocalizedDateFormatFromTemplate("EEEEE")
        return GCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    GoobyIcon("📊", size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.tx("menu.stats.week", de: "Letzte 7 Tage", en: "Last 7 days"))
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                        Text(engine.txf("menu.stats.weekTotal", de: "%d Ziele geschafft", en: "%d goals done", values.reduce(0, +)))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.greyText)
                    }
                }
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        let value = values[index]
                        VStack(spacing: 6) {
                            Text("\(value)")
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(value > 0 ? Theme.text : Theme.greyText)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(value > 0 ? Theme.Tab.quests.sky : Theme.line)
                                .overlay(alignment: .top) {
                                    if value > 0 {
                                        Capsule().fill(Color.white.opacity(0.35)).frame(height: 4).padding(.horizontal, 6).padding(.top, 4)
                                    }
                                }
                                .frame(height: max(10, 110 * CGFloat(value) / CGFloat(top)))
                            Text(formatter.string(from: day))
                                .font(Theme.Fonts.caps)
                                .foregroundStyle(index == days.count - 1 ? Theme.text : Theme.greyText)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(engine.formatDate(day)): \(value)")
                    }
                }
                .frame(height: 160, alignment: .bottom)
            }
        }
    }

    private func tile(_ icon: String, _ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GoobyIcon(icon, size: 30)
            Text(value)
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.greyText)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
        .cardShadow()
        .accessibilityElement(children: .combine)
    }
}
