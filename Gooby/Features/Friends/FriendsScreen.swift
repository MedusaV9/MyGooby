import SwiftUI

struct FriendsScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("egg.explain")).foregroundStyle(Theme.ink.opacity(0.75))
                ForEach(engine.habits().filter { !$0.isArchived }) { habit in
                    if let egg = engine.activeEgg(for: habit.id) {
                        Text(engine.tf("egg.bound", habit.title, egg.progress, egg.requiredCount)).foregroundStyle(Theme.ink)
                        ProgressRibbon(value: Double(egg.progress) / Double(max(1, egg.requiredCount)))
                    } else {
                        Button(engine.tf("egg.bindTo", habit.title)) { engine.bindEgg(to: habit) }
                            .buttonStyle(.bordered)
                    }
                }
                ForEach(engine.all(MiniFriend.self)) { friend in
                    HStack {
                        MiniFriendBadge(species: friend.speciesID).frame(width: 54, height: 54)
                        VStack(alignment: .leading) {
                            Text(friend.givenName).font(.system(.headline, design: .rounded))
                            Text(engine.t("rarity.\(friend.rarity)"))
                        }
                        Spacer()
                        if friend.isCompanion {
                            Text(engine.t("friends.with"))
                        } else {
                            Button(engine.t("friends.choose")) { engine.setCompanion(friend) }
                        }
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(10)
                    .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                GoobyCharacterView(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), animation: .play, reduceMotion: reduceMotion, companion: engine.companionSpecies())
                    .frame(height: 240)
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("friends.title"))
    }
}
