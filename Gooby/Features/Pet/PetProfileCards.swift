import SwiftUI

// Pet slice: the cards of the pet tab (screenshot-reference.md sections 4 and 5).

fileprivate extension PetTint {
    /// White-cream face of the profile card.
    var paper: Color { Color(hex: 0xFFFCF4) }
    /// Unselected segment label on the beige band.
    var segmentText: Color { Color(hex: 0xA48D60) }
}

enum PetSegment: String, CaseIterable, Identifiable {
    case about, details, traits

    var id: String { rawValue }
}

enum PetText {
    /// "Baby Gooby": stage + name.
    @MainActor
    static func title(_ engine: GoobyEngine, stage: String) -> String {
        let name = displayName(engine)
        switch stage {
        case "little": return engine.txf("pet.title.little", de: "Mini-%@", en: "Little %@", name)
        case "young": return engine.txf("pet.title.young", de: "Jung-%@", en: "Young %@", name)
        case "teen": return engine.txf("pet.title.teen", de: "Teenie-%@", en: "Teen %@", name)
        case "adult": return engine.txf("pet.title.adult", de: "Groß-%@", en: "Grown-up %@", name)
        default: return engine.txf("pet.title.baby", de: "Baby %@", en: "Baby %@", name)
        }
    }

    @MainActor
    static func stageName(_ engine: GoobyEngine, _ stage: String) -> String {
        switch stage {
        case "little": return engine.tx("pet.stageName.little", de: "Knirps", en: "Little one")
        case "young": return engine.tx("pet.stageName.young", de: "Jungspund", en: "Youngster")
        case "teen": return engine.tx("pet.stageName.teen", de: "Teenie", en: "Teen")
        case "adult": return engine.tx("pet.stageName.adult", de: "Erwachsen", en: "Grown-up")
        default: return engine.tx("pet.stageName.baby", de: "Baby", en: "Baby")
        }
    }

    @MainActor
    static func displayName(_ engine: GoobyEngine) -> String {
        let name = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Gooby" : name
    }

    /// "Mia • 3 adventures"
    @MainActor
    static func subtitle(_ engine: GoobyEngine) -> String {
        let count = engine.petFinishedAdventures()
        let adventures = count == 1
            ? engine.tx("pet.adventures.one", de: "1 Abenteuer", en: "1 adventure")
            : engine.txf("pet.adventures.many", de: "%d Abenteuer", en: "%d adventures", count)
        let nickname = engine.profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return nickname.isEmpty ? adventures : "\(nickname) • \(adventures)"
    }

    @MainActor
    static func birthday(_ engine: GoobyEngine) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: engine.profile.createdAt)
    }

    @MainActor
    static func birthdayLabel(_ engine: GoobyEngine) -> String {
        engine.tx("pet.birthday", de: "Geburtstag", en: "Birthday")
    }
}

// MARK: - Profile card

/// White-cream card with a brown clip on top, a postmark watermark, the portrait, name, owner line,
/// birthday, and the ABOUT / DETAILS / TRAITS segments on a beige band.
struct PetProfileCard: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Binding var segment: PetSegment

    var body: some View {
        let stage = Growth.stage(of: engine.pet)
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                portrait(stage)
                info(stage)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topTrailing) {
                PetPostmark()
                    .padding(.top, 10)
                    .padding(.trailing, 8)
            }
            segments
        }
        .background(Theme.Tab.pet.paper)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .cardShadow()
        .overlay(alignment: .top) {
            PetClip().offset(y: -16)
        }
        .padding(.top, 16)
    }

    private func portrait(_ stage: String) -> some View {
        GoobyCharacterView(
            look: engine.wornLook(),
            stage: stage,
            animation: .idle,
            reduceMotion: reduceMotion,
            companion: nil,
            adventuring: engine.todaysRun()?.status == "traveling"
        )
        .frame(width: 100, height: 100)
        .frame(width: 110, height: 110)
        .background(Theme.Tab.pet.cream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func info(_ stage: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(PetText.title(engine, stage: stage))
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(PetText.subtitle(engine))
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.greyText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(PetText.birthdayLabel(engine).uppercased())
                .font(Theme.Fonts.caps)
                .tracking(1.1)
                .foregroundStyle(Theme.greyText)
                .padding(.top, 10)
            HStack(spacing: 6) {
                Text(PetText.birthday(engine))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.ochre)
                Text(verbatim: "🎂")
                    .font(.system(size: 15))
                    .accessibilityHidden(true)
            }
        }
    }

    private var segments: some View {
        HStack(spacing: 6) {
            ForEach(PetSegment.allCases) { item in
                segmentButton(item)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Tab.pet.band)
    }

    private func segmentButton(_ item: PetSegment) -> some View {
        let selected = item == segment
        return Button {
            segment = item
            engine.haptics.soft()
        } label: {
            Text(label(item).uppercased())
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(selected ? Theme.brown : Theme.Tab.pet.segmentText)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.Tab.pet.pill)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func label(_ item: PetSegment) -> String {
        switch item {
        case .about: return engine.tx("pet.segment.about", de: "Über", en: "About")
        case .details: return engine.tx("pet.segment.details", de: "Details", en: "Details")
        case .traits: return engine.tx("pet.segment.traits", de: "Eigenschaften", en: "Traits")
        }
    }
}

// MARK: - Streak

/// Sun badge, "N day streak", longest-streak subtitle and a chevron to the statistics.
struct PetStreakCard: View {
    var engine: GoobyEngine

    var body: some View {
        let streak = engine.streak()
        let longest = engine.petLongestStreak()
        NavigationLink {
            StatsScreen(engine: engine)
        } label: {
            HStack(spacing: 14) {
                PetSunBadge(size: 58)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(streak)")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                        Text(streak == 1
                             ? engine.tx("pet.streak.one", de: "Tag in Folge", en: "day streak")
                             : engine.tx("pet.streak.many", de: "Tage in Folge", en: "day streak"))
                            .font(Theme.Fonts.title3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(Theme.text)
                    Text(subtitle(streak: streak, longest: longest))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                CircleChevron(color: Theme.greyText, fill: Theme.keyFace, size: 32)
            }
            .padding(Theme.Space.inner)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .cardShadow()
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func subtitle(streak: Int, longest: Int) -> String {
        if streak == 0 {
            return engine.tx("pet.streak.start", de: "Hake ein Ziel ab, um eine Serie zu starten.", en: "Check off a goal to start a streak.")
        }
        if streak >= longest {
            return engine.tx("pet.streak.best", de: "Deine längste Self-Care-Serie!", en: "Longest self-care streak ever!")
        }
        return engine.txf("pet.streak.longest", de: "Längste Serie: %d Tage", en: "Longest streak: %d days", longest)
    }
}

// MARK: - Journey notebook

/// Notebook with the current place and its discoveries, the meadow sticker over faint doodles,
/// and a "See all" tab under it that unfolds the place's discoveries.
struct PetJourneyCard: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Binding var open: Bool

    var body: some View {
        let found = engine.petFoundDiscoveries()
        let place = engine.petCurrentPlace()
        VStack(spacing: 0) {
            NotebookCard {
                VStack(spacing: 10) {
                    header(place, found: found)
                    Rectangle()
                        .fill(Theme.Tab.pet.watermark.opacity(0.7))
                        .frame(height: 1.5)
                    ZStack {
                        PetDoodles()
                        PetSticker(look: engine.wornLook(), stage: Growth.stage(of: engine.pet))
                    }
                    .frame(height: 214)
                    .frame(maxWidth: .infinity)
                    if open, let place {
                        discoveries(place, found: found)
                    }
                }
            }
            .zIndex(1)
            seeAllTab
        }
    }

    private func header(_ place: PlaceDef?, found: Set<String>) -> some View {
        HStack(spacing: 8) {
            GoobyIcon("🍃", size: 24)
            Text(place?.name.text(engine.languageCode) ?? engine.t("world.map"))
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.brown)
                .lineLimit(1)
            Spacer(minLength: 6)
            if let place {
                let explored = engine.petExplored(place, found: found)
                Text(verbatim: "\(explored.found)/\(explored.total)")
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.brown.opacity(0.75))
                    .accessibilityLabel(engine.t("world.discoveries") + " \(explored.found)/\(explored.total)")
            }
        }
    }

    private func discoveries(_ place: PlaceDef, found: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionCaps(engine.t("world.discoveries"), color: Theme.brown.opacity(0.65))
            ForEach(place.discoveries) { discovery in
                let known = found.contains(discovery.id)
                HStack(alignment: .top, spacing: 10) {
                    GoobyIcon(known ? "✨" : "❔", size: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(known ? discovery.name.text(engine.languageCode) : engine.t("world.unknown"))
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(known ? Theme.brown : Theme.brown.opacity(0.55))
                        if known {
                            Text(discovery.detail.text(engine.languageCode))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.greyText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(Theme.Tab.pet.band.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.top, 4)
    }

    private var seeAllTab: some View {
        Button {
            if reduceMotion { open.toggle() } else { withAnimation(.easeInOut(duration: 0.25)) { open.toggle() } }
        } label: {
            HStack(spacing: 6) {
                Text(open
                     ? engine.tx("pet.journey.less", de: "Weniger", en: "Show less")
                     : engine.tx("pet.journey.seeAll", de: "Alle ansehen", en: "See all"))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .heavy))
                    .rotationEffect(.degrees(open ? 180 : 0))
            }
            .font(Theme.Fonts.button)
            .foregroundStyle(Theme.brown)
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .background(
                Theme.notebook,
                in: UnevenRoundedRectangle(bottomLeadingRadius: 14, bottomTrailingRadius: 14, style: .continuous)
            )
            .cardShadow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, -8)
        .id(PetScrollOffsetKey.collections)
        .accessibilityAddTraits(open ? [.isSelected] : [])
    }
}

// MARK: - Mini-friends notebook

/// Notebook with the mini-friend tiles and a stand "found / total" that opens the album.
struct PetFriendsNotebook: View {
    var engine: GoobyEngine
    var openAlbum: () -> Void
    var openFriend: (FriendDef) -> Void
    @State private var showInfo = false

    var body: some View {
        let owned = engine.petOwnedFriends()
        let friends = engine.catalog.friends
        let found = friends.filter { owned[$0.id] != nil }.count
        let ordered = friends.filter { owned[$0.id] != nil } + friends.filter { owned[$0.id] == nil }
        NotebookCard(standText: "\(found) / \(friends.count)", onStand: openAlbum) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(engine.t("friends.title"))
                        .font(Theme.Fonts.title3)
                        .foregroundStyle(Theme.brown)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Theme.brown)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(Theme.brown, lineWidth: 2.5))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, -10)
                    .accessibilityLabel(engine.tx("pet.friends.info", de: "Über Mini-Freunde", en: "About mini-friends"))
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ordered) { friend in
                            tile(friend, owned: owned[friend.id] != nil, number: (friends.firstIndex(of: friend) ?? 0) + 1)
                        }
                    }
                }
            }
        }
        .alert(engine.t("friends.title"), isPresented: $showInfo) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: {
            Text(engine.t("egg.explain"))
        }
    }

    private func tile(_ friend: FriendDef, owned: Bool, number: Int) -> some View {
        Button {
            if owned { openFriend(friend) } else { openAlbum() }
        } label: {
            PetFriendTile(friend: friend, owned: owned, number: number, size: 96, style: .profile)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(owned ? friend.name.text(engine.languageCode) : engine.t("kit.locked"))
    }
}

/// Square mini-friend tile. Profile style: charcoal when owned, light beige with a silhouette when
/// not. Album style: beige in both states with a darker silhouette.
struct PetFriendTile: View {
    enum Style { case profile, album }

    var friend: FriendDef
    var owned: Bool
    var number: Int
    var size: CGFloat
    var style: Style

    var body: some View {
        let fill: Color = style == .album ? Theme.Tab.pet.albumTile : (owned ? Theme.Tab.pet.tileOwned : Theme.Tab.pet.tileLocked)
        let shade: Color = style == .album ? Theme.Tab.pet.albumSilhouette : Theme.Tab.pet.silhouette
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill)
            if owned {
                art
            } else {
                // Solid silhouette: the badge's alpha masks a flat fill.
                shade
                    .frame(width: size, height: size)
                    .mask { art }
            }
            if owned && style == .profile {
                Text(verbatim: "#\(number)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x9A9A9A))
                    .padding(.top, 8)
                    .padding(.trailing, 10)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var art: some View {
        MiniFriendBadge(species: friend.id)
            .frame(width: 44, height: 44)
            .scaleEffect(size / 66)
            .frame(width: size, height: size)
    }
}

// MARK: - Places

/// "Places" card: tiles in each place's colors with name and explored %, locked tiles a large "?".
struct PetPlacesCard: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var openPlace: (PlaceDef) -> Void

    var body: some View {
        let found = engine.petFoundDiscoveries()
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(engine.t("kit.pet.places"))
                    .font(Theme.Fonts.title3)
                    .foregroundStyle(Theme.brown)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                NavigationLink {
                    if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
                } label: {
                    CircleChevron(color: .white, fill: Theme.Tab.pet.stand, size: 28)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -10)
                .accessibilityLabel(engine.t("today.adventure.open"))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(engine.catalog.places) { place in
                        tile(place, found: found)
                    }
                }
            }
        }
        .padding(Theme.Space.inner)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.notebook, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .cardShadow()
    }

    private func tile(_ place: PlaceDef, found: Set<String>) -> some View {
        let unlocked = engine.isPlaceUnlocked(place.id)
        let name = place.name.text(engine.languageCode)
        let percent = engine.petExploredPercent(place, found: found)
        return Button {
            openPlace(place)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                if unlocked {
                    PetPlaceArt(place: place, size: 96)
                } else {
                    PetLockedTile(size: 96)
                }
                Text(unlocked ? name : engine.tx("pet.places.locked", de: "Gesperrt", en: "Locked"))
                    .font(Theme.Fonts.caption.weight(.heavy))
                    .foregroundStyle(unlocked ? Theme.brown : Theme.brown.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if unlocked {
                    Text(verbatim: "\(percent)%")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                }
            }
            .frame(width: 96, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(unlocked ? "\(name), \(percent)%" : "\(name), \(engine.tx("pet.places.locked", de: "Gesperrt", en: "Locked"))")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Growth

/// Stage, progress to the next stage and the current companion.
struct PetGrowthCard: View {
    var engine: GoobyEngine

    var body: some View {
        let growth = engine.petGrowth()
        GCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    IconTile(color: Theme.Tab.quests.green, size: 48, radius: 14) {
                        GoobyIcon("🌱", size: 30)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.tx("pet.growth.title", de: "Wachstum", en: "Growth"))
                            .font(Theme.Fonts.caps)
                            .tracking(1.1)
                            .foregroundStyle(Theme.greyText)
                            .textCase(.uppercase)
                        Text(PetText.stageName(engine, growth.stage))
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                    }
                    Spacer(minLength: 0)
                }
                if let next = growth.next {
                    StripedProgressBar(value: growth.points - growth.floor, goal: next - growth.floor, height: 22)
                    Text(engine.txf("pet.growth.next", de: "Noch %d Punkte bis zur nächsten Stufe", en: "%d points to the next stage", max(0, next - growth.points)))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                } else {
                    Text(engine.tx("pet.growth.max", de: "Ausgewachsen und immer noch rund.", en: "Fully grown, still round."))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                }
                Text(engine.tx("pet.growth.how", de: "Jeder Pflegetag zählt 1 Punkt, jeder Abenteuertag 2.", en: "Every care day counts 1 point, every adventure day 2."))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.greyText.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle().fill(Theme.line).frame(height: 1)
                companion
            }
        }
    }

    @ViewBuilder private var companion: some View {
        if let species = engine.companionSpecies() {
            let given = engine.all(MiniFriend.self).first(where: { $0.isCompanion })?.givenName ?? ""
            let name = given.isEmpty ? (engine.catalog.friendsByID[species]?.name.text(engine.languageCode) ?? species) : given
            HStack(spacing: 12) {
                MiniFriendBadge(species: species)
                    .frame(width: 44, height: 44)
                    .frame(width: 48, height: 48)
                    .background(Theme.Tab.pet.tileOwned, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)
                Text(engine.txf("pet.companion", de: "Dabei: %@", en: "Along: %@", name))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 0)
            }
        } else {
            HStack(spacing: 12) {
                GoobyIcon("🥚", size: 32)
                Text(engine.tx("pet.companion.none", de: "Noch kein Mini-Freund dabei.", en: "No mini-friend along yet."))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.greyText)
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Details

/// Numbers about Gooby and the player, with a link to the full statistics.
struct PetDetailsCard: View {
    var engine: GoobyEngine

    var body: some View {
        let rows: [(String, String, String)] = [
            ("✅", engine.t("stats.completions"), "\(engine.petCompletions())"),
            ("🔥", engine.tx("pet.details.streak", de: "Aktuelle Serie", en: "Current streak"), "\(engine.streak())"),
            ("🏆", engine.tx("pet.details.longest", de: "Längste Serie", en: "Longest streak"), "\(engine.petLongestStreak())"),
            ("🌿", engine.tx("pet.details.careDays", de: "Pflegetage", en: "Care days"), "\(engine.pet.careDays)"),
            ("🎒", engine.tx("pet.details.adventureDays", de: "Abenteuertage", en: "Adventure days"), "\(engine.pet.adventureDays)"),
            ("🗺️", engine.t("stats.places"), "\(engine.all(PlaceProgress.self).filter(\.unlocked).count)"),
            ("🔍", engine.t("stats.discoveries"), "\(engine.all(DiscoveryRecord.self).count)"),
            ("🐾", engine.t("friends.title"), "\(engine.all(MiniFriend.self).count)"),
            ("😊", engine.tx("pet.details.moods", de: "Stimmungen", en: "Moods logged"), "\(engine.all(MoodEntry.self).count)"),
            ("📔", engine.t("journal.title"), "\(engine.all(JournalEntry.self).count)"),
            ("✨", engine.t("stats.earned"), "\(engine.wallet.lifetimeSparksEarned)")
        ]
        VStack(spacing: Theme.Space.gap) {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(spacing: 12) {
                        GoobyIcon(row.0, size: 28)
                        Text(row.1)
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                        Spacer(minLength: 8)
                        Text(row.2)
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.brown)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, Theme.Space.inner)
                    .frame(minHeight: 54)
                    .accessibilityElement(children: .combine)
                    if index < rows.count - 1 {
                        Rectangle().fill(Theme.line).frame(height: 1).padding(.leading, 56)
                    }
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
            .cardShadow()
            NavigationLink {
                StatsScreen(engine: engine)
            } label: {
                HStack {
                    Text(engine.tx("pet.details.all", de: "Alle Statistiken", en: "All statistics"))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .heavy))
                }
                .foregroundStyle(Theme.brown)
            }
            .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.pet.cream, edge: Theme.Tab.pet.pill, radius: 18, vertical: 14, expand: true))
        }
    }
}

// MARK: - Traits

/// The seven personality values as small bars.
struct PetTraitsCard: View {
    var engine: GoobyEngine

    private static let colors: [Color] = [
        Color(hex: 0xF47B4F), Color(hex: 0x8B4FE0), Color(hex: 0xF7C540), Color(hex: 0x6DB45A),
        Color(hex: 0x3EB5E8), Color(hex: 0xE54C8B), Color(hex: 0xD4A53C)
    ]

    var body: some View {
        GCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(engine.tx("pet.traits.title", de: "Persönlichkeit", en: "Personality"))
                    .font(Theme.Fonts.title3)
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(Personality.keys.enumerated()), id: \.offset) { index, key in
                    let value = Personality.value(engine.pet, key)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(engine.t("stat.\(key)"))
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Text(verbatim: "\(Int((value * 100).rounded()))")
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.greyText)
                                .monospacedDigit()
                        }
                        ProgressRibbon(value: value, tint: Self.colors[index % Self.colors.count])
                    }
                    .accessibilityElement(children: .combine)
                }
                Text(engine.tx("pet.traits.hint", de: "Goobys Entscheidungen auf Abenteuern formen diese Eigenschaften.", en: "Gooby's choices on adventures shape these traits."))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.greyText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
