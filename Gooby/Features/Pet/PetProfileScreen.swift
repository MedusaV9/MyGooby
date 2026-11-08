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
    @State private var showWorld = false

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
                        Color.clear.preference(key: PetScrollOffsetKey.self, value: geo.frame(in: .global).minY)
                    }
                }
            }
            .modifier(PetScrollTitleTracker(showTitle: $showTitle))
            .task { await openShotRoute(proxy) }
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .background(PetLook.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showWorld) {
            if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
        }
        .goobyCover(isPresented: $showMenu) {
            NavigationStack { MoreScreen(engine: engine, reduceMotion: reduceMotion) }
                .goobyCelebrations(engine)
        }
        .goobySheet(isPresented: $showEdit) {
            PetEditSheet(engine: engine)
        }
        .goobySheet(item: $selectedPlace) { place in
            PlaceDetail(engine: engine, place: place, reduceMotion: reduceMotion)
        }
        .goobySheet(item: $selectedFriend) { friend in
            PetFriendDetail(engine: engine, friend: friend)
        }
        .goobyCover(isPresented: $showAlbum) {
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
        .background(PetLook.top.ignoresSafeArea(edges: .top))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.black.opacity(showTitle ? 0.06 : 0)).frame(height: 1)
        }
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

    /// The cards of the selected segment; switching segments lets the new cards rise in.
    @ViewBuilder private var segmentContent: some View {
        switch segment {
        case .about:
            VStack(spacing: Theme.Space.gap) {
                PetStreakCard(engine: engine, reduceMotion: reduceMotion)
                    .goobyEntrance(1)
                PetJourneyCard(engine: engine, reduceMotion: reduceMotion, open: $journeyOpen)
                    .goobyEntrance(2)
                PetFriendsNotebook(
                    engine: engine,
                    openAlbum: { showAlbum = true },
                    openFriend: { selectedFriend = $0 }
                )
                .goobyEntrance(3)
                PetPlacesCard(
                    engine: engine,
                    reduceMotion: reduceMotion,
                    openPlace: { selectedPlace = $0 },
                    openWorld: { showWorld = true }
                )
                .goobyEntrance(4)
                PetGrowthCard(engine: engine)
                    .goobyEntrance(5)
            }
            .transition(.goobyRise(reduceMotion))
        case .details:
            PetDetailsCard(engine: engine)
                .transition(.goobyRise(reduceMotion))
        case .traits:
            PetTraitsCard(engine: engine)
                .transition(.goobyRise(reduceMotion))
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

    /// `petCollections` scrolls to the mini-friend notebook, `micropedia` opens the album, the
    /// self-care routes open the menu, which pushes their screen (MoreScreen).
    private func openShotRoute(_ proxy: ScrollViewProxy) async {
        guard let route = ShotMode.route else { return }
        switch route {
        case .petCollections:
            try? await Task.sleep(nanoseconds: 700_000_000)
            proxy.scrollTo(PetScrollOffsetKey.collections, anchor: .top)
        case .micropedia:
            try? await Task.sleep(nanoseconds: 700_000_000)
            showAlbum = true
        case .activities, .mood, .journal, .insights:
            try? await Task.sleep(nanoseconds: 300_000_000)
            showMenu = true
        default:
            break
        }
    }
}

/// Global top of the pet tab's scroll content (iOS 17 fallback of PetScrollTitleTracker).
struct PetScrollOffsetKey: PreferenceKey {
    static let collections = "pet.collections"
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Sets `showTitle` once the profile card has scrolled about 130 pt up.
struct PetScrollTitleTracker: ViewModifier {
    @Binding var showTitle: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 130
            } action: { _, show in
                if show != showTitle { showTitle = show }
            }
        } else {
            // Content top sits near y = 120 at rest (status bar + top row).
            content.onPreferenceChange(PetScrollOffsetKey.self) { top in
                let show = top < -10
                if show != showTitle { showTitle = show }
            }
        }
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
            .animation(.easeOut(duration: 0.08), value: pressed)
            .frame(minWidth: 44, minHeight: 44)
            .onChange(of: pressed) { _, down in
                if down { MomentHub.shared.emit(.tap) }
            }
    }
}
