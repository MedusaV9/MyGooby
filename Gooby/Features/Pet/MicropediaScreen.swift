import SwiftUI

/// Friend album (screenshot-reference.md section 8): close button, mustard ribbon title, a
/// notebook with olive binding tabs, "found / total" and a link to the bag, then a 3-column grid
/// of every mini-friend. Found ones show their art and name and open a detail sheet; the others
/// are darker beige silhouettes.
struct MicropediaScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selected: FriendDef?

    var body: some View {
        let owned = engine.petOwnedFriends()
        let friends = engine.catalog.friends
        let found = friends.filter { owned[$0.id] != nil }.count
        ScrollView {
            VStack(spacing: 18) {
                RibbonTitle(text: engine.t("kit.pet.album"), color: Theme.Tab.pet.ribbon)
                    .padding(.top, 2)
                NotebookCard(tabColor: Theme.Tab.pet.albumBinding) {
                    VStack(alignment: .leading, spacing: 14) {
                        header(found: found, total: friends.count)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(friends) { friend in
                                tile(friend, owned: owned[friend.id] != nil)
                            }
                        }
                        Text(engine.t("egg.explain"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.brown.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 32)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                CloseCircleButton(label: engine.t("kit.close")) { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
            .background(Theme.Tab.pet.bgTop.ignoresSafeArea(edges: .top))
        }
        .background(Theme.Tab.pet.screen.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selected) { friend in
            PetFriendDetail(engine: engine, friend: friend)
        }
    }

    private func header(found: Int, total: Int) -> some View {
        HStack {
            Text(engine.tf("kit.pet.found", found, total))
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.brown)
            Spacer()
            NavigationLink {
                BagScreen(engine: engine, reduceMotion: reduceMotion)
            } label: {
                HStack(spacing: 4) {
                    Text(engine.t("kit.tab.bag"))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .heavy))
                }
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.brown)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -10)
        }
    }

    @ViewBuilder
    private func tile(_ friend: FriendDef, owned: Bool) -> some View {
        let name = friend.name.text(engine.languageCode)
        let content = VStack(spacing: 4) {
            PetFriendTile(friend: friend, owned: owned, number: 0, size: 76, style: .album)
            Text(owned ? name : "?")
                .font(Theme.Fonts.caption.weight(.heavy))
                .foregroundStyle(owned ? Theme.brown : Theme.Tab.pet.albumSilhouette)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.Tab.pet.albumTile, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        if owned {
            Button { selected = friend } label: { content }
                .buttonStyle(.plain)
                .accessibilityLabel(name)
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(engine.t("kit.locked"))
        }
    }
}

/// Detail sheet of a hatched mini-friend: art, name, rarity, blurb, hatch date and the companion
/// choice.
struct PetFriendDetail: View {
    var engine: GoobyEngine
    var friend: FriendDef
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let rows = engine.petOwnedFriends()[friend.id] ?? []
        let companion = rows.first { $0.isCompanion }
        let row = companion ?? rows.first
        ScrollView {
            VStack(spacing: 14) {
                MiniFriendBadge(species: friend.id)
                    .frame(width: 112, height: 112)
                    .frame(width: 150, height: 150)
                    .background(Theme.Tab.pet.tileOwned, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .accessibilityHidden(true)
                Text(friend.name.text(engine.languageCode))
                    .font(Theme.Fonts.title)
                    .foregroundStyle(Theme.brown)
                    .accessibilityAddTraits(.isHeader)
                Text(engine.t("rarity.\(friend.rarity)"))
                    .font(Theme.Fonts.caps)
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Theme.Tab.pet.ribbon, in: Capsule())
                Text(friend.blurb.text(engine.languageCode))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.brown.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if let row {
                    Text(engine.txf("pet.album.hatched", de: "Geschlüpft am %@", en: "Hatched on %@", hatchDate(row.hatchedAt)))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                    if rows.count > 1 {
                        Text(engine.txf("pet.album.count", de: "%d geschlüpft", en: "%d hatched", rows.count))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.greyText)
                    }
                    if companion != nil {
                        Label(engine.t("friends.with"), systemImage: "checkmark")
                            .font(Theme.Fonts.button)
                            .foregroundStyle(Theme.checkGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.top, 6)
                    } else {
                        Button(engine.t("friends.choose")) {
                            engine.setCompanion(row)
                            engine.haptics.soft()
                        }
                        .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.pet.stand, edge: nil, radius: 18, vertical: 14, expand: true))
                        .foregroundStyle(.white)
                        .padding(.top, 6)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                CloseCircleButton(label: engine.t("kit.close")) { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Tab.pet.bgTop.ignoresSafeArea(edges: .top))
        }
        .background(Theme.Tab.pet.screen.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    private func hatchDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
