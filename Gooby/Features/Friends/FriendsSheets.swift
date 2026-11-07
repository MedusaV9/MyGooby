import SwiftUI

/// What a visit showed: the friend and the day's story.
struct SocialVisitStory: Identifiable, Equatable {
    var id: String { npc.id }
    var npc: SocialNPC
    var text: String
}

/// Sheet with the local friends: visit each one once per day for a short friendship story and a
/// small star-spark gift; friendship grows with every visit. `focus` shows a single friend.
struct SocialVisitSheet: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var focus: SocialNPC?
    @Environment(\.dismiss) private var dismiss
    @State private var story: SocialVisitStory?
    @State private var refresh = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                ForEach(friends) { npc in
                    if engine.socialIsUnlocked(npc) {
                        friendCard(npc)
                    } else {
                        lockedCard(npc)
                    }
                }
                Text(engine.tx("social.visit.note", de: "Jeder Freund freut sich einmal am Tag über deinen Besuch.", en: "Each friend is happy to see you once a day."))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 24)
            .id(refresh)
        }
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .background { Theme.Tab.friends.sky.ignoresSafeArea() }
        .overlay {
            if let story {
                storyCard(story)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: story)
    }

    private var friends: [SocialNPC] {
        if let focus { return [focus] }
        return SocialNPC.all
    }

    private var header: some View {
        ZStack {
            Text(focus.map { engine.tx($0.title) } ?? engine.tx("social.visit.title", de: "Freunde besuchen", en: "Visit friends"))
                .font(Theme.Fonts.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 56)
            HStack {
                CloseCircleButton(label: engine.t("kit.close")) { dismiss() }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private func friendCard(_ npc: SocialNPC) -> some View {
        let visited = engine.socialVisitedToday(npc)
        let level = engine.socialLevel(npc)
        return GCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    IconTile(color: Color(hex: npc.color), size: 64, radius: 18) {
                        SocialNPCHead(species: npc.species, size: 56)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: npc.name)
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                        Text(engine.tx(npc.title))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.greyText)
                        hearts(level)
                    }
                    Spacer(minLength: 0)
                }
                Text(engine.txf("social.level", de: "Freundschaft Stufe %d von 5", en: "Friendship level %d of 5", level))
                    .font(Theme.Fonts.caps)
                    .tracking(0.8)
                    .foregroundStyle(Theme.capsGrey)
                if visited {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(Theme.checkGreen)
                        Text(engine.tx("social.visit.done", de: "Heute schon besucht", en: "Visited today"))
                            .foregroundStyle(Theme.greyText)
                    }
                    .font(Theme.Fonts.button)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.keyFace, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Button {
                        if engine.socialVisit(npc) {
                            story = SocialVisitStory(npc: npc, text: engine.socialStory(npc, dayKey: engine.dayKey()))
                            refresh += 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                            Text(engine.txf("social.visit.button", de: "%@ besuchen", en: "Visit %@", npc.name))
                        }
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(Press3DButtonStyle(fill: Theme.checkGreen, edge: Theme.checkGreenEdge, radius: 16, vertical: 12, expand: true))
                }
            }
        }
    }

    private func lockedCard(_ npc: SocialNPC) -> some View {
        GCard {
            HStack(spacing: 12) {
                IconTile(color: Theme.keyFace, size: 64, radius: 18) {
                    Text(verbatim: "?")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.greyText)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: "???")
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                    Text(engine.txf(
                        "social.locked.hint",
                        de: "Geh auf Abenteuer, um diesen Freund zu treffen: %d/%d",
                        en: "Go on adventures to meet this friend: %d/%d",
                        min(engine.socialFinishedAdventures(), npc.unlockAdventures),
                        npc.unlockAdventures
                    ))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.greyText)
                    .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func hearts(_ level: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < level ? "heart.fill" : "heart")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(index < level ? FriendsArtInk.heart : Theme.line)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(engine.txf("social.level", de: "Freundschaft Stufe %d von 5", en: "Friendship level %d of 5", level))
    }

    private func storyCard(_ story: SocialVisitStory) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { self.story = nil }
            VStack(spacing: 14) {
                HStack(alignment: .bottom, spacing: -6) {
                    GoobyCharacterView(
                        look: engine.wornLook(),
                        stage: Growth.stage(of: engine.pet),
                        animation: .hearts,
                        reduceMotion: reduceMotion,
                        companion: nil,
                        showCompanion: false
                    )
                    .frame(width: 130, height: 140)
                    SocialBouncingHead(species: story.npc.species, size: 78, reduceMotion: reduceMotion)
                        .padding(.bottom, 8)
                }
                Text(engine.txf("social.visit.with", de: "Besuch bei %@", en: "Visiting %@", story.npc.name))
                    .font(Theme.Fonts.title)
                    .foregroundStyle(Theme.text)
                Text(story.text)
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.text.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    GoobyIcon("sparkles", size: 22)
                    Text(engine.txf("social.visit.gift", de: "%@ schenkt dir %d Sternenfunken", en: "%@ gives you %d star sparks", story.npc.name, SocialNPC.visitSparks))
                        .font(Theme.Fonts.button)
                        .foregroundStyle(Theme.ochre)
                }
                Button(engine.tx("social.visit.close", de: "Schön!", en: "Lovely!")) { self.story = nil }
                    .buttonStyle(Press3DButtonStyle(fill: Theme.checkGreen, edge: Theme.checkGreenEdge, radius: 18, vertical: 12, expand: true))
                    .foregroundStyle(.white)
            }
            .padding(20)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .padding(.horizontal, 28)
        }
    }
}

/// NPC head that hops gently next to Gooby while they play (still with reduce motion).
struct SocialBouncingHead: View {
    var species: String
    var size: CGFloat
    var reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            SocialNPCHead(species: species, size: size)
        } else {
            SocialNPCHead(species: species, size: size)
                .phaseAnimator([false, true]) { content, up in
                    content
                        .offset(y: up ? -10 : 0)
                        .rotationEffect(.degrees(up ? 4 : -4))
                } animation: { _ in
                    .easeInOut(duration: 0.42)
                }
        }
    }
}

/// Mini-friend eggs and companions (moved from the old friends screen, logic unchanged):
/// bind an egg to a habit, watch it hatch after seven completions, pick who goes along.
struct SocialEggSheet: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                GCard {
                    VStack(spacing: 10) {
                        GoobyCharacterView(
                            look: engine.wornLook(),
                            stage: Growth.stage(of: engine.pet),
                            animation: .play,
                            reduceMotion: reduceMotion,
                            companion: engine.companionSpecies()
                        )
                        .frame(height: 200)
                        Text(engine.t("egg.explain"))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.greyText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
                SectionCaps(engine.tx("social.eggs", de: "Eier", en: "Eggs"), color: Color.white.opacity(0.9))
                    .padding(.top, 6)
                let habits = engine.habits().filter { !$0.isArchived }
                if habits.isEmpty {
                    GCard {
                        Text(engine.tx("social.eggs.none", de: "Leg zuerst eine Gewohnheit an, dann kannst du ihr ein Ei geben.", en: "Add a habit first, then you can give it an egg."))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.greyText)
                    }
                } else {
                    GCard(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                                if index > 0 {
                                    Rectangle().fill(Theme.line).frame(height: 1).padding(.leading, 70)
                                }
                                eggRow(habit)
                            }
                        }
                    }
                }
                SectionCaps(engine.tx("social.friends.mine", de: "Deine Mini-Freunde", en: "Your mini-friends"), color: Color.white.opacity(0.9))
                    .padding(.top, 6)
                let friends = engine.all(MiniFriend.self).sorted { $0.hatchedAt < $1.hatchedAt }
                if friends.isEmpty {
                    GCard {
                        Text(engine.tx("social.friends.none", de: "Noch keine Mini-Freunde. Gib einer Gewohnheit ein Ei!", en: "No mini-friends yet. Give a habit an egg!"))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.greyText)
                    }
                } else {
                    ForEach(friends) { friend in
                        friendRow(friend)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .background { Theme.Tab.friends.sky.ignoresSafeArea() }
    }

    private var header: some View {
        ZStack {
            Text(engine.t("friends.title"))
                .font(Theme.Fonts.headline)
                .foregroundStyle(.white)
            HStack {
                CloseCircleButton(label: engine.t("kit.close")) { dismiss() }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private func eggRow(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            IconTile(color: Theme.keyFace, size: 46, radius: 14) {
                GoobyIcon(habit.icon, size: 30)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                if let egg = engine.activeEgg(for: habit.id) {
                    StripedProgressBar(value: egg.progress, goal: egg.requiredCount, height: 22)
                }
            }
            Spacer(minLength: 0)
            if engine.activeEgg(for: habit.id) == nil {
                Button {
                    engine.bindEgg(to: habit)
                } label: {
                    HStack(spacing: 4) {
                        GoobyIcon("🥚", size: 20)
                        Text(engine.tx("social.egg.bind", de: "Ei geben", en: "Add egg"))
                    }
                    .foregroundStyle(Theme.text)
                }
                .buttonStyle(Press3DButtonStyle(radius: 14, horizontal: 12, vertical: 8))
                .accessibilityLabel(engine.tf("egg.bindTo", habit.title))
            }
        }
        .padding(.horizontal, Theme.Space.inner)
        .padding(.vertical, 12)
    }

    private func friendRow(_ friend: MiniFriend) -> some View {
        GCard {
            HStack(spacing: 12) {
                IconTile(color: Theme.Tab.pet.tileOwned, size: 56, radius: 16) {
                    MiniFriendBadge(species: friend.speciesID)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(friend.givenName)
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                    Text(engine.t("rarity.\(friend.rarity)"))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                }
                Spacer(minLength: 0)
                if friend.isCompanion {
                    Text(engine.t("friends.with"))
                        .font(Theme.Fonts.button)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.checkGreen, in: Capsule())
                } else {
                    Button(engine.t("friends.choose")) { engine.setCompanion(friend) }
                        .buttonStyle(Press3DButtonStyle(radius: 14, horizontal: 12, vertical: 8))
                        .foregroundStyle(Theme.text)
                }
            }
        }
    }
}
