import SwiftUI

/// Pet tab (screenshot-reference.md sections 4 and 5). Top row: hamburger, share and pencil; the
/// pet's name fades in centered once the profile card scrolls away. Below the profile card the
/// selected segment shows About (streak, journey notebook, mini-friends, places, growth), Details
/// (numbers) or Traits (personality bars).
struct PetProfileScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var segment: PetSegment = .about
    @State private var showMenu = false
    @State private var showEdit = false
    @State private var showAlbum = false
    @State private var showTitle = false
    @State private var journeyOpen = false
    @State private var selectedPlace: PlaceDef?
    @State private var selectedFriend: FriendDef?
    @State private var shareImage: Image?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: Theme.Space.gap) {
                    PetProfileCard(engine: engine, reduceMotion: reduceMotion, segment: $segment)
                    segmentContent
                }
                .padding(.horizontal, Theme.Space.margin)
                .padding(.top, 6)
                .padding(.bottom, 32)
                .background(alignment: .top) {
                    GeometryReader { geo in
                        Color.clear.preference(key: PetScrollOffsetKey.self, value: geo.frame(in: PetScrollOffsetKey.coordinateSpace).minY)
                    }
                }
            }
            .coordinateSpace(PetScrollOffsetKey.coordinateSpace)
            .onPreferenceChange(PetScrollOffsetKey.self) { offset in
                let show = offset < -120
                if show != showTitle { showTitle = show }
            }
            .task { await openShotRoute(proxy) }
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .background(Theme.Tab.pet.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showMenu) {
            NavigationStack { MoreScreen(engine: engine, reduceMotion: reduceMotion) }
        }
        .sheet(isPresented: $showEdit) {
            PetEditSheet(engine: engine)
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetail(engine: engine, place: place, reduceMotion: reduceMotion)
        }
        .sheet(item: $selectedFriend) { friend in
            PetFriendDetail(engine: engine, friend: friend)
        }
        .fullScreenCover(isPresented: $showAlbum) {
            NavigationStack { MicropediaScreen(engine: engine, reduceMotion: reduceMotion) }
        }
        .task(id: shareKey) { await renderShareImage() }
    }

    // MARK: Top row

    private var topBar: some View {
        ZStack {
            Text(PetText.displayName(engine))
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.brown)
                .lineLimit(1)
                .padding(.horizontal, 110)
                .opacity(showTitle ? 1 : 0)
                .accessibilityHidden(!showTitle)
            HStack(spacing: 10) {
                HamburgerButton(label: engine.t("kit.menu.open")) { showMenu = true }
                Spacer()
                shareButton
                Button {
                    showEdit = true
                } label: {
                    squareGlyph("pencil")
                }
                .buttonStyle(PetSquareButtonStyle())
                .accessibilityLabel(engine.tx("pet.edit", de: "Namen bearbeiten", en: "Edit names"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 2)
        .padding(.bottom, 6)
        .background(Theme.Tab.pet.bgTop.opacity(showTitle ? 1 : 0).ignoresSafeArea(edges: .top))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: showTitle)
    }

    @ViewBuilder private var shareButton: some View {
        let label = engine.tx("pet.share", de: "Profil teilen", en: "Share profile")
        if let shareImage {
            ShareLink(item: shareImage, preview: SharePreview(PetText.displayName(engine), image: shareImage)) {
                squareGlyph("square.and.arrow.up")
            }
            .buttonStyle(PetSquareButtonStyle())
            .accessibilityLabel(label)
        } else {
            Button {} label: { squareGlyph("square.and.arrow.up") }
                .buttonStyle(PetSquareButtonStyle())
                .disabled(true)
                .accessibilityLabel(label)
        }
    }

    private func squareGlyph(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(Theme.brown)
            .frame(width: 42, height: 38)
    }

    // MARK: Segments

    @ViewBuilder private var segmentContent: some View {
        switch segment {
        case .about:
            PetStreakCard(engine: engine)
            PetJourneyCard(engine: engine, reduceMotion: reduceMotion, open: $journeyOpen)
            PetFriendsNotebook(
                engine: engine,
                openAlbum: { showAlbum = true },
                openFriend: { selectedFriend = $0 }
            )
            PetPlacesCard(engine: engine, reduceMotion: reduceMotion) { selectedPlace = $0 }
            PetGrowthCard(engine: engine)
        case .details:
            PetDetailsCard(engine: engine)
        case .traits:
            PetTraitsCard(engine: engine)
        }
    }

    // MARK: Share image

    private var shareKey: String {
        let look = engine.wornLook()
        let gear = look.slots.values.map(\.id).sorted().joined(separator: ",")
        return [
            engine.profile.goobyName, engine.profile.nickname, engine.languageCode, look.fur, gear,
            Growth.stage(of: engine.pet), "\(engine.petFinishedAdventures())", "\(engine.streak())"
        ].joined(separator: "|")
    }

    private func renderShareImage() async {
        let stage = Growth.stage(of: engine.pet)
        let streak = engine.streak()
        let streakLine = streak == 1
            ? engine.tx("pet.share.streak.one", de: "🔥 1 Tag in Folge", en: "🔥 1 day streak")
            : engine.txf("pet.share.streak.many", de: "🔥 %d Tage in Folge", en: "🔥 %d day streak", streak)
        let card = PetShareCard(
            look: engine.wornLook(),
            stage: stage,
            title: PetText.title(engine, stage: stage),
            subtitle: PetText.subtitle(engine),
            birthdayLabel: PetText.birthdayLabel(engine),
            birthday: PetText.birthday(engine),
            streakLine: streakLine,
            footer: engine.tx("pet.share.footer", de: "Selbstfürsorge mit Gooby", en: "Self-care with Gooby")
        )
        shareImage = card.render()
    }

    // MARK: Screenshot routes

    /// `petCollections` scrolls to the mini-friend notebook, `micropedia` opens the album.
    private func openShotRoute(_ proxy: ScrollViewProxy) async {
        guard let route = ShotMode.route, route == .petCollections || route == .micropedia else { return }
        try? await Task.sleep(nanoseconds: 700_000_000)
        if route == .petCollections {
            proxy.scrollTo(PetScrollOffsetKey.collections, anchor: .top)
        } else {
            showAlbum = true
        }
    }
}

/// Top offset of the pet tab's scroll content.
struct PetScrollOffsetKey: PreferenceKey {
    static let space = "pet.scroll"
    static var coordinateSpace: NamedCoordinateSpace { NamedCoordinateSpace.named(space) }
    static let collections = "pet.collections"
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Square cream top-bar key with a brown glyph and a slightly darker bottom edge.
struct PetSquareButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let pressed = configuration.isPressed
        configuration.label
            .background(shape.fill(Theme.Tab.pet.cream))
            .offset(y: pressed ? 3 : 0)
            .background(shape.fill(Theme.Tab.pet.pill).offset(y: 3))
            .padding(.bottom, 3)
            .contentShape(shape)
            .opacity(enabled ? 1 : 0.6)
            .frame(minWidth: 44, minHeight: 44)
    }
}
