import SwiftUI

/// Friends tab (screen A): a periwinkle sky with the giant friendship tree, local NPC friends on
/// wooden signposts, Gooby on a light leaf clump in the middle, "Visit a friend", and a banner
/// that leads to the mini-friend eggs. Everything is local; there are no online friends, invites
/// or codes.
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
    /// Tap counters that wobble the signposts and Gooby.
    @State private var wiggles: [String: Int] = [:]
    @State private var goobyHops = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                FriendsTreeArt(reduceMotion: reduceMotion)
                    .frame(width: w, height: h)
                ForEach(Array(SocialNPC.all.prefix(FriendsTreePainter.spots.count).enumerated()), id: \.element.id) { index, npc in
                    let spot = FriendsTreePainter.spots[index]
                    signButton(npc, index: index)
                        .position(x: spot.x * w, y: spot.y * h - 70)
                }
                // Gooby's head center sits at `FriendsTreePainter.gooby`; the stack below it is
                // about 140 pt tall.
                center
                    .position(x: w / 2, y: FriendsTreePainter.gooby * h + 70)
                banner
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .frame(width: w, height: h, alignment: .bottom)
            }
            .frame(width: w, height: h)
        }
        .overlay(alignment: .top) { topRow }
        .background { Theme.Tab.friends.sky.ignoresSafeArea() }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSettings) { SettingsView(engine: engine) }
        .goobySheet(isPresented: $showVisits) {
            SocialVisitSheet(engine: engine, reduceMotion: reduceMotion, focus: nil)
                .goobyCelebrations(engine)
        }
        .goobySheet(item: $focus) { npc in
            SocialVisitSheet(engine: engine, reduceMotion: reduceMotion, focus: npc)
                .goobyCelebrations(engine)
        }
        .goobySheet(isPresented: $showEggs) {
            SocialEggSheet(engine: engine, reduceMotion: reduceMotion)
                .goobyCelebrations(engine)
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

    private func signButton(_ npc: SocialNPC, index: Int) -> some View {
        let unlocked = engine.socialIsUnlocked(npc)
        return Button {
            wiggles[npc.id, default: 0] += 1
            if unlocked { focus = npc } else { lockedNPC = npc }
        } label: {
            FriendsSignpost(npc: npc, unlocked: unlocked, level: unlocked ? engine.socialLevel(npc) : 0, index: index, reduceMotion: reduceMotion)
                .friendsWiggle(wiggles[npc.id, default: 0])
                .contentShape(Rectangle())
        }
        .buttonStyle(ShopPressStyle())
        .accessibilityLabel(unlocked ? engine.tx(npc.title) : engine.tx("social.sign.locked", de: "Unbekannter Freund", en: "Unknown friend"))
    }

    private var center: some View {
        let nickname = engine.profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tint = Theme.Tab.friends
        return VStack(spacing: 2) {
            // Gooby's head peeks out of a light leaf clump (the clump hides the cut at his chin);
            // tapping him makes him hop.
            ZStack {
                FriendsBushShape()
                    .fill(tint.canopyDark.opacity(0.45))
                    .frame(width: 136, height: 40)
                    .offset(y: 49)
                Button {
                    MomentHub.shared.emit(.tap)
                    goobyHops += 1
                } label: {
                    breathingAvatar
                        .friendsWiggle(goobyHops)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(name.isEmpty ? "Gooby" : name)
                FriendsBushShape()
                    .fill(tint.canopyLight)
                    .frame(width: 136, height: 40)
                    .offset(y: 44)
                    .allowsHitTesting(false)
            }
            .frame(width: 140, height: 84)
            Text(verbatim: name.isEmpty ? "Gooby" : name)
                .font(Theme.Fonts.headline)
                .foregroundStyle(.white)
                .shadow(color: tint.canopyDark.opacity(0.7), radius: 0, x: 0, y: 1.5)
                .padding(.top, 32)
            if !nickname.isEmpty {
                Text(verbatim: nickname)
                    .font(Theme.Fonts.body)
                    .foregroundStyle(tint.nameGreen)
            }
            Button {
                showVisits = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(tint.addCircle, in: Circle())
                    Text(engine.tx("social.visit.open", de: "Freund besuchen", en: "Visit a friend"))
                        .foregroundStyle(tint.addGreen)
                        .lineLimit(1)
                }
            }
            .buttonStyle(Press3DButtonStyle(fill: .white, edge: Color(hex: 0xD6D9D2), radius: 14, depth: 4, horizontal: 16, vertical: 11))
            .padding(.top, 12)
        }
        .frame(maxWidth: 240)
    }

    @ViewBuilder private var breathingAvatar: some View {
        let avatar = GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: 84)
        if reduceMotion {
            avatar
        } else {
            avatar.phaseAnimator([false, true]) { view, up in
                view.scaleEffect(x: up ? 0.985 : 1, y: up ? 1.03 : 1, anchor: .bottom)
            } animation: { _ in
                .easeInOut(duration: 1.6)
            }
        }
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
            title = engine.tx("social.banner.hatch", de: "Brüte ein Ei aus, dann lernt ihr euch kennen!", en: "Hatch an egg to meet them!")
        } else {
            caps = engine.tx("social.banner.all", de: "Alle Mini-Freunde gefunden", en: "Every mini-friend found")
            title = engine.tx("social.banner.choose", de: "Wähle, wer Gooby begleitet!", en: "Choose who goes along with Gooby!")
        }
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return Button {
            showEggs = true
        } label: {
            HStack(spacing: 12) {
                MiniFriendBadge(species: friend?.id ?? engine.companionSpecies() ?? "cloud", animated: !reduceMotion)
                    .frame(width: 60, height: 60)
                    .overlay { FriendsBannerHearts(reduceMotion: reduceMotion) }
                    .padding(.leading, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(caps.uppercased())
                        .font(Theme.Fonts.caps)
                        .tracking(1.4)
                        .foregroundStyle(Theme.Tab.friends.bannerLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(title)
                        .font(.system(.callout, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                CircleChevron(color: .white, fill: Color.white.opacity(0.35), size: 32)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(minHeight: 84)
            .background(Theme.Tab.friends.banner, in: shape)
            .contentShape(shape)
        }
        .buttonStyle(ShopPressStyle())
        .goobyEntrance(1)
    }
}
