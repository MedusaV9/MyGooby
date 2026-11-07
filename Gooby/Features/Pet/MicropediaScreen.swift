import SwiftUI

// Owned by the pet slice. Foundation stub of the mini-friend album (screen 8): every catalog
// friend, owned ones drawn, the others as silhouettes.
struct MicropediaScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        let owned = Set(engine.all(MiniFriend.self).map(\.speciesID))
        let friends = engine.catalog.friends
        let found = friends.filter { owned.contains($0.id) }.count
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                RibbonTitle(text: engine.t("kit.pet.album"))
                NotebookCard(tabColor: Theme.Tab.pet.albumBinding) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(engine.tf("kit.pet.found", found, friends.count))
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.brown)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(friends) { friend in
                                tile(friend, owned: owned.contains(friend.id))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.vertical, Theme.Space.gap)
        }
        .background(Theme.Tab.pet.background.ignoresSafeArea())
    }

    private func tile(_ friend: FriendDef, owned: Bool) -> some View {
        VStack(spacing: 4) {
            Group {
                if owned {
                    MiniFriendBadge(species: friend.id)
                } else {
                    Theme.Tab.pet.albumSilhouette
                        .mask { MiniFriendBadge(species: friend.id) }
                }
            }
            .frame(width: 56, height: 56)
            Text(owned ? friend.name.text(engine.languageCode) : "?")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.brown)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.Tab.pet.albumTile, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(owned ? friend.name.text(engine.languageCode) : engine.t("kit.locked"))
    }
}
