import SwiftUI

struct ProfileScreen: View {
    var engine: GoobyEngine
    var onMenu: (() -> Void)? = nil
    var onBag: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var showCollection = false
    @State private var showMicropedia = false
    @State private var showForest = false
    @State private var showLocations = false
    @State private var showEdit = false
    @State private var showMenu = false
    @State private var showStreak = false
    @State private var tab: CardTab = .about
    @State private var revision = 0

    private var calm: Bool { systemReduce || engine.reduceMotion }

    private var snap: ProfileSnapshot {
        _ = revision
        return ProfileSnapshot.make(engine: engine)
    }

    var body: some View {
        ZStack {
            ProfilePalette.page.ignoresSafeArea()
            if showCollection {
                CollectionScreen(
                    engine: engine,
                    snap: snap,
                    calm: calm,
                    onBack: { showCollection = false },
                    onMenu: openMenu,
                    onEdit: openEdit,
                    onMicropedia: { showMicropedia = true },
                    shareText: shareLine
                )
                .transition(.opacity)
            } else {
                cardPage
                    .transition(.opacity)
            }
        }
        .animation(calm ? nil : .easeInOut(duration: 0.2), value: showCollection)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showMicropedia) {
            MicropediaScreen(engine: engine, snap: snap, onBag: {
                showMicropedia = false
                onBag?()
            })
        }
        .fullScreenCover(isPresented: $showForest) {
            ForestMapScreen(
                title: ProfileCopy.forestTitle(engine.languageCode),
                count: engine.tf("profile.binder", snap.forestFound, snap.forestTotal),
                closeLabel: engine.t("profile.close"),
                places: snap.places,
                onClose: { showForest = false }
            )
        }
        .fullScreenCover(isPresented: $showLocations) {
            LocationsScreen(engine: engine, snap: snap, calm: calm, onBack: { showLocations = false })
        }
        .sheet(isPresented: $showEdit) {
            ProfileEditSheet(engine: engine, calm: calm) { revision += 1 }
        }
        .sheet(isPresented: $showMenu) { menuSheet }
        .sheet(isPresented: $showStreak) {
            StreakCalendarSheet(engine: engine, snap: snap, calm: calm, subtitle: streakSubtitle)
        }
    }

    private var cardPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ProfileHeader(
                    title: nil,
                    menuLabel: engine.t("profile.menu"),
                    shareLabel: engine.t("profile.share"),
                    editLabel: engine.t("profile.edit"),
                    shareText: shareLine,
                    onMenu: openMenu,
                    onEdit: openEdit
                )
                .padding(.horizontal, -2.5)
                identityCard
                    .padding(.top, 6.5)
                streakCard
                    .padding(.top, 16)
                VStack(spacing: 12) {
                    forestNotebook
                    petsNotebook
                    locationsNotebook
                }
                .background(alignment: .top) {
                    ProfileGround()
                        .fill(ProfilePalette.ground)
                        .padding(.horizontal, -14.7)
                        .padding(.top, -26)
                        .padding(.bottom, -400)
                }
                .padding(.top, 47.5)
            }
            .padding(.horizontal, 14.7)
            .padding(.bottom, 18)
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                avatarWell
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(snap.stage) \(snap.name)")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(ProfilePalette.nameInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(snap.pronounsLine.isEmpty ? "—" : snap.pronounsLine)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(ProfilePalette.pronoun)
                        .accessibilityLabel(snap.pronounsLine.isEmpty ? ProfileCopy.pronounsMissing(engine.languageCode) : snap.pronounsLine)
                    if tab != .details {
                        hatchday
                            .padding(.top, 13)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 15.3)
            .padding(.trailing, 14)
            .padding(.top, 14)
            if tab == .details {
                detailsBlock
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
            }
            if tab == .traits {
                TraitHexagon(traits: snap.hexTraits)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
            }
            tabRow
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ProfilePalette.tabBand)
                .padding(.top, 14.5)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    ProfilePalette.card
                    Postmark()
                        .position(x: geo.size.width - 77.6, y: 52.3)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(calm ? nil : .easeInOut(duration: 0.22), value: tab)
        .shadow(color: ProfilePalette.shadow, radius: 10, y: 4)
        .overlay(alignment: .top) { ProfileCardClip().offset(y: -12) }
    }

    private var avatarWell: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ProfilePalette.well)
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: calm ? .sit : .breathe,
                reduceMotion: calm,
                companion: nil,
                showCompanion: false
            )
            .frame(width: 172, height: 172)
            .offset(y: 16)
        }
        .frame(width: 109, height: 139)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var shareLine: String {
        engine.tf("profile.share.text", snap.name, snap.hatchday)
    }

    private var hatchday: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(engine.t("profile.hatchday"))
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .tracking(1.05)
                .textCase(.uppercase)
                .foregroundStyle(ProfilePalette.pronoun)
            Text(snap.hatchday)
                .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                .foregroundStyle(ProfilePalette.gold)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(engine.t("profile.hatchday")), \(snap.hatchday)")
    }

    private var detailsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            passportRow(ProfileCopy.ageLabel(engine.languageCode), snap.ageText)
            passportRow(ProfileCopy.friendshipLabel(engine.languageCode), snap.friendship, heart: true)
            passportRow(ProfileCopy.humanLabel(engine.languageCode), snap.humanName.isEmpty ? "—" : snap.humanName)
            PassportMeasures(
                weight: snap.weightText,
                height: snap.heightText,
                span: snap.spanText,
                weightName: ProfileCopy.weightName(engine.languageCode),
                heightName: ProfileCopy.heightName(engine.languageCode),
                spanName: ProfileCopy.spanName(engine.languageCode)
            )
        }
    }

    private func passportRow(_ label: String, _ value: String, heart: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.7)
                .textCase(.uppercase)
                .foregroundStyle(ProfilePalette.muted)
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(ProfilePalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if heart { ProfileHeart() }
            }
        }
    }

    private var tabRow: some View {
        HStack(spacing: 1.5) {
            tabButton(.about)
            tabButton(.details)
            tabButton(.traits)
        }
    }

    private func tabButton(_ item: CardTab) -> some View {
        let selected = tab == item
        return Button {
            tab = item
        } label: {
            Text(engine.t(item.key))
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .tracking(1.1)
                .textCase(.uppercase)
                .foregroundStyle(selected ? ProfilePalette.nameInk : ProfilePalette.tabIdle)
                .frame(maxWidth: .infinity)
                .frame(height: 35.6)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous).fill(ProfilePalette.tabPill)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var streakCard: some View {
        Button { showStreak = true } label: {
            HStack(spacing: 11.4) {
                SunCheck()
                    .frame(width: 39, height: 39)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(snap.streak)")
                            .font(.system(size: 25, weight: .heavy, design: .rounded))
                        Text(snap.streak == 1 ? engine.t("profile.streak.unit.one") : engine.t("profile.streak.unit.many"))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(ProfilePalette.brown)
                    Text(streakSubtitle)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(ProfilePalette.streakSub)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                ChevronGlyph()
                    .scaleEffect(0.62)
                    .foregroundStyle(Color.white)
                    .frame(width: 16.7, height: 16.7)
                    .background(ProfilePalette.chevronDot, in: Circle())
            }
            .padding(.leading, 15.3)
            .padding(.trailing, 15)
            .frame(maxWidth: .infinity, minHeight: 62.3)
            .background(ProfilePalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: ProfilePalette.shadow, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var forestNotebook: some View {
        Button { showForest = true } label: {
            NotebookShell(inset: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        ProfileLeafGlyph()
                            .scaleEffect(1.4)
                        Text(ProfileCopy.forestTitle(engine.languageCode))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(ProfilePalette.notebookTitle)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(engine.tf("profile.count", snap.forestFound, snap.forestTotal))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(ProfilePalette.notebookCount)
                    }
                    .frame(height: 36)
                    .padding(.leading, 16.5)
                    .padding(.trailing, 15)
                    .padding(.top, 16)
                    Rectangle()
                        .fill(ProfilePalette.notebookRule)
                        .frame(height: 1)
                        .padding(.horizontal, 14.3)
                        .padding(.top, 3.5)
                    ProfileForestPreview(seeAll: engine.t("profile.seeAll"))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(engine.t("profile.seeAll"))
    }

    private var petsNotebook: some View {
        NotebookShell(binder: engine.tf("profile.binder", snap.foundCount, snap.dexTotal), binderAction: { showMicropedia = true }) {
            Button { showMicropedia = true } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(engine.t("profile.micropets"))
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(ProfilePalette.ink)
                        Spacer()
                        Text(ProfileCopy.foundLine(snap.foundCount, snap.dexTotal, engine.languageCode))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(ProfilePalette.brownSoft)
                    }
                    HStack(spacing: 10) {
                        ForEach(snap.previewPetIDs, id: \.self) { id in
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(snap.found(id) ? ProfilePalette.tileDark : ProfilePalette.quietTile)
                                MicropetGlyph(id: id, ink: snap.found(id) ? nil : ProfilePalette.silhouette)
                                    .frame(width: 64, height: 64)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 88)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var locationsNotebook: some View {
        NotebookShell(binder: engine.tf("profile.binder", snap.locationsFound, snap.places.count), binderAction: { showLocations = true }) {
            Button { showLocations = true } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Text(engine.t("profile.locations"))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.ink)
                    HStack(spacing: 10) {
                        ForEach(Array(snap.places.prefix(3))) { place in
                            QuestionPlaceTile(place: place, unknown: ProfileCopy.unknownPlace(engine.languageCode))
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var streakSubtitle: String {
        if snap.streak == 0 { return engine.t("profile.streak.start") }
        if snap.streak >= snap.longest { return engine.t("profile.streak.longest") }
        return engine.tf("profile.streak.shorter", snap.longest)
    }

    private func openMenu() {
        if let onMenu {
            onMenu()
        } else {
            showMenu = true
        }
    }

    private func openEdit() {
        showEdit = true
    }

    private var menuSheet: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(snap.name)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
                .padding(.bottom, 6)
            menuRow(engine.t("profile.menu.card")) {
                showMenu = false
                showCollection = false
            }
            menuRow(engine.t("profile.menu.collection")) {
                showMenu = false
                showCollection = true
            }
            menuRow(engine.t("profile.menu.micropedia")) {
                showMenu = false
                showMicropedia = true
            }
            menuRow(engine.t("profile.locations")) {
                showMenu = false
                showLocations = true
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ProfilePalette.page.ignoresSafeArea())
        .sheetRise(calm: calm)
        .presentationDetents([.medium])
    }

    private func menuRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Spacer()
                ChevronGlyph().foregroundStyle(ProfilePalette.brownSoft)
            }
            .foregroundStyle(ProfilePalette.brown)
            .padding(14)
            .background(ProfilePalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

}

private enum CardTab: String {
    case about, details, traits
    var key: String { "profile.\(rawValue)" }
}

struct ProfileSaveStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(ProfilePalette.page)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(ProfilePalette.brown, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
