import SwiftUI

/// Friends tab (screen 6): a sky with the big friendship tree, local NPC friends on wooden
/// signposts, Gooby in the middle, "Visit a friend", and a banner that leads to the mini-friend
/// eggs. Everything is local; there are no online friends, invites or codes.
struct FriendsScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.isPresented) private var isPresented
    @Environment(\.dismiss) private var dismiss
    @State private var showVisits = false
    @State private var focus: SocialNPC?
    @State private var lockedNPC: SocialNPC?
    @State private var showEggs = false
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                FriendsTreeArt()
                    .frame(width: w, height: h)
                ForEach(Array(SocialNPC.all.prefix(FriendsTreePainter.spots.count).enumerated()), id: \.element.id) { index, npc in
                    let spot = FriendsTreePainter.spots[index]
                    signButton(npc)
                        .position(x: spot.x * w, y: spot.y * h - 56)
                }
                center
                    .position(x: w / 2, y: h * 0.40)
                banner
                    .padding(.horizontal, Theme.Space.margin)
                    .padding(.bottom, 14)
                    .frame(width: w, height: h, alignment: .bottom)
            }
            .frame(width: w, height: h)
        }
        .overlay(alignment: .top) { topRow }
        .background { Theme.Tab.friends.sky.ignoresSafeArea() }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSettings) { SettingsView(engine: engine) }
        .sheet(isPresented: $showVisits) {
            SocialVisitSheet(engine: engine, reduceMotion: reduceMotion, focus: nil)
        }
        .sheet(item: $focus) { npc in
            SocialVisitSheet(engine: engine, reduceMotion: reduceMotion, focus: npc)
        }
        .sheet(isPresented: $showEggs) {
            SocialEggSheet(engine: engine, reduceMotion: reduceMotion)
        }
        .alert(
            engine.tx("social.locked.title", de: "Noch nicht getroffen", en: "Not met yet"),
            isPresented: Binding(get: { lockedNPC != nil }, set: { if !$0 { lockedNPC = nil } })
        ) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: {
            Text(lockedHint)
        }
    }

    private var topRow: some View {
        HStack {
            if isPresented {
                BackChevronButton(label: engine.t("kit.back")) { dismiss() }
            }
            Spacer()
            GearButton(label: engine.t("kit.settings.open")) { showSettings = true }
        }
        .padding(.horizontal, 12)
    }

    private var lockedHint: String {
        guard let npc = lockedNPC else { return "" }
        return engine.txf(
            "social.locked.hint",
            de: "Geh auf Abenteuer, um diesen Freund zu treffen: %d/%d",
            en: "Go on adventures to meet this friend: %d/%d",
            min(engine.socialFinishedAdventures(), npc.unlockAdventures),
            npc.unlockAdventures
        )
    }

    private func signButton(_ npc: SocialNPC) -> some View {
        let unlocked = engine.socialIsUnlocked(npc)
        return Button {
            if unlocked { focus = npc } else { lockedNPC = npc }
        } label: {
            FriendsSignpost(npc: npc, unlocked: unlocked, level: unlocked ? engine.socialLevel(npc) : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(unlocked ? engine.tx(npc.title) : engine.tx("social.sign.locked", de: "Unbekannter Freund", en: "Unknown friend"))
    }

    private var center: some View {
        let nickname = engine.profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return VStack(spacing: 4) {
            GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: 96)
                .offset(y: 8)
                .frame(width: 104, height: 104)
                .background(Color.white.opacity(0.22))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.55), lineWidth: 3))
            Text(verbatim: name.isEmpty ? "Gooby" : name)
                .font(Theme.Fonts.title)
                .foregroundStyle(.white)
                .shadow(color: Theme.Tab.friends.canopyDark.opacity(0.6), radius: 0, x: 0, y: 2)
                .padding(.top, 4)
            if !nickname.isEmpty {
                Text(verbatim: nickname)
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Tab.friends.nameGreen)
            }
            Button {
                showVisits = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.checkGreen)
                    Text(engine.tx("social.visit.open", de: "Freund besuchen", en: "Visit a friend"))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                }
            }
            .buttonStyle(Press3DButtonStyle(fill: .white, edge: Theme.keyEdge, radius: 22, horizontal: 16, vertical: 10))
            .padding(.top, 10)
        }
        .frame(maxWidth: 230)
    }

    /// Species shown in the banner: one Gooby has not hatched yet (rotates daily).
    private var bannerFriend: FriendDef? {
        let owned = Set(engine.all(MiniFriend.self).map(\.speciesID))
        let ids = ShopRotation.orderedIDs(engine.catalog.friends.map(\.id), dayKey: engine.dayKey(), category: "social-banner", appSeed: engine.profile.appSeed)
        let pick = ids.first { !owned.contains($0) }
        return pick.flatMap { engine.catalog.friendsByID[$0] }
    }

    private var banner: some View {
        let friend = bannerFriend
        let caps: String
        let title: String
        if let friend {
            caps = engine.txf("social.banner.meet", de: "Triff %@", en: "Meet %@", friend.name.text(engine.languageCode))
            title = engine.tx("social.banner.hatch", de: "Brüte ein Ei aus, um ihn zu treffen!", en: "Hatch an egg to meet them!")
        } else {
            caps = engine.tx("social.banner.all", de: "Alle Mini-Freunde gefunden", en: "Every mini-friend found")
            title = engine.tx("social.banner.choose", de: "Wähle, wer Gooby begleitet!", en: "Choose who goes along with Gooby!")
        }
        return Button {
            showEggs = true
        } label: {
            HStack(spacing: 12) {
                MiniFriendBadge(species: friend?.id ?? engine.companionSpecies() ?? "cloud")
                    .scaleEffect(1.25)
                    .frame(width: 58, height: 58)
                    .background(Color.white.opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(caps.uppercased())
                        .font(Theme.Fonts.caps)
                        .tracking(1.1)
                        .foregroundStyle(Theme.Tab.friends.bannerLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(title)
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                CircleChevron(color: Theme.Tab.friends.canopyDark, fill: .white, size: 30)
            }
            .padding(14)
            .background(Theme.Tab.friends.banner, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
