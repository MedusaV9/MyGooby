import SwiftUI

struct MoreScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                link(engine.t("tab.shop"), "bag.fill") {
                    if let make = FeatureHost.shared.shopScreen { make(engine) } else { ShopScreen(engine: engine, reduceMotion: reduceMotion) }
                }
                link(engine.t("mood.title"), "face.smiling.fill") {
                    if let make = FeatureHost.shared.moodScreen { make(engine) } else { MoodScreen(engine: engine) }
                }
                link(engine.t("journal.title"), "book.fill") {
                    if let make = FeatureHost.shared.journalScreen { make(engine) } else { JournalScreen(engine: engine) }
                }
                link(engine.t("friends.title"), "pawprint.fill") {
                    if let make = FeatureHost.shared.companionsScreen { make(engine) } else { FriendsScreen(engine: engine, reduceMotion: reduceMotion) }
                }
                link(engine.t("quests.title"), "flag.fill") {
                    if let make = FeatureHost.shared.questsScreen { make(engine) } else { QuestScreen(engine: engine) }
                }
                link(engine.t("events.title"), "calendar") {
                    if let make = FeatureHost.shared.eventsScreen { make(engine) } else { EventScreen(engine: engine) }
                }
                link(engine.t("stats.title"), "chart.bar.fill") { StatsScreen(engine: engine) }
                link(engine.t("settings.title"), "gearshape.fill") { SettingsView(engine: engine) }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("tab.more"))
    }

    private func link<Destination: View>(_ title: String, _ symbol: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink { destination() } label: {
            HStack {
                Image(systemName: symbol).frame(width: 36, height: 36).background(Theme.pink, in: Circle())
                Text(title).font(.system(.headline, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(Theme.ink)
            .padding(14)
            .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
