import SwiftUI

/// Friend album (screen C): cream close button, mustard ribbon title, a cream notebook with five
/// dark brown binder tabs, "found / total" and a link to the bag, then a 3-column grid of square
/// tiles with every mini-friend. Found ones show their art and name and open a detail sheet;
/// the others are flat tan silhouettes.
struct MicropediaScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    /// True when the bag pushed the album; its "Bag" link then pops back.
    var fromBag: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var selected: FriendDef?

    var body: some View {
        let owned = engine.petOwnedFriends()
        let friends = engine.catalog.friends
        let found = friends.filter { owned[$0.id] != nil }.count
        ScrollView {
            VStack(spacing: 20) {
                RibbonTitle(text: engine.t("kit.pet.album"), color: Theme.Tab.pet.ribbon)
                    .padding(.top, 4)
                AlbumNotebook {
                    VStack(alignment: .leading, spacing: 14) {
                        header(found: found, total: friends.count)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                                tile(friend, owned: owned[friend.id] != nil)
                                    .goobyEntrance(index)
                            }
                        }
                        Text(engine.t("egg.explain"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Tab.pet.albumInk.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 32)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                AlbumCloseButton(label: engine.t("kit.close")) { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
            .background(Theme.Tab.pet.albumBg.ignoresSafeArea(edges: .top))
        }
        .background(Theme.Tab.pet.albumBg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .goobySheet(item: $selected) { friend in
            PetFriendDetail(engine: engine, friend: friend)
        }
    }

    private func header(found: Int, total: Int) -> some View {
        HStack {
            Text(engine.tf("kit.pet.found", found, total))
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Tab.pet.albumInk)
            Spacer()
            Group {
                if fromBag {
                    // Pushed from the bag: go back to it instead of stacking a second bag.
                    Button { dismiss() } label: { bagLabel }
                } else {
                    NavigationLink {
                        BagScreen(engine: engine, reduceMotion: reduceMotion)
                    } label: {
                        bagLabel
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, -10)
        }
    }

    private var bagLabel: some View {
        HStack(spacing: 4) {
            Text(engine.t("kit.tab.bag"))
            Image(systemName: "arrow.up.right")
                .font(.system(size: 13, weight: .heavy))
        }
        .font(.system(.headline, design: .rounded, weight: .bold))
        .foregroundStyle(Theme.Tab.pet.albumInk)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    /// Square tile: the found mini-friend bobbing with its name, or a flat tan silhouette.
    @ViewBuilder
    private func tile(_ friend: FriendDef, owned: Bool) -> some View {
        let name = friend.name.text(engine.languageCode)
        let tint = Theme.Tab.pet
        let content = ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(tint.albumTile)
            Group {
                if owned {
                    MiniFriendBadge(species: friend.id, animated: !reduceMotion)
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .padding(.bottom, 24)
                } else {
                    MiniFriendSilhouette(species: friend.id, color: tint.albumSilhouette)
                        .padding(16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if owned {
                Text(name)
                    .font(Theme.Fonts.caption.weight(.heavy))
                    .foregroundStyle(tint.albumInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 7)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        if owned {
            Button {
                selected = friend
            } label: { content }
                .buttonStyle(ShopPressStyle())
                .accessibilityLabel(name)
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(engine.t("kit.locked"))
        }
    }
}

/// Notebook of the friend album: cream page, radius 24, five dark brown binder tabs sticking up
/// from the top edge.
struct AlbumNotebook<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let tint = Theme.Tab.pet
        content
            .padding(.horizontal, Theme.Space.inner)
            .padding(.top, 22)
            .padding(.bottom, Theme.Space.inner)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.albumPaper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .top) {
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        Spacer(minLength: 0)
                        Capsule()
                            .fill(tint.albumBinding)
                            .frame(width: 10, height: 26)
                            .overlay(alignment: .top) {
                                Capsule().fill(Color.white.opacity(0.2)).frame(width: 4, height: 6).padding(.top, 4)
                            }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 30)
                .offset(y: -13)
                .accessibilityHidden(true)
            }
            .padding(.top, 13)
    }
}

/// Cream circle with a dark brown cross (top-left close of the album screens).
struct AlbumCloseButton: View {
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(Theme.Tab.pet.albumCross)
                .frame(width: 40, height: 40)
                .background(Theme.Tab.pet.albumClose, in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(ShopPressStyle())
        .accessibilityLabel(label)
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
                AlbumCloseButton(label: engine.t("kit.close")) { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Tab.pet.albumBg.ignoresSafeArea(edges: .top))
        }
        .background(Theme.Tab.pet.albumBg.ignoresSafeArea())
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
