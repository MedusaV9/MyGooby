import SwiftUI
import UIKit

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
    @State private var copied = false
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
                    shareText: engine.tf("profile.share.text", snap.friendCode)
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
        .sheet(isPresented: $showStreak) { streakSheet }
    }

    private var cardPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ProfileHeader(
                    title: nil,
                    menuLabel: engine.t("profile.menu"),
                    shareLabel: engine.t("profile.share"),
                    editLabel: engine.t("profile.edit"),
                    shareText: engine.tf("profile.share.text", snap.friendCode),
                    onMenu: openMenu,
                    onEdit: openEdit
                )
                identityCard
                streakCard
                forestNotebook
                    .padding(.top, 18)
                petsNotebook
                locationsNotebook
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 18)
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(ProfilePalette.well)
                    GoobyCharacterView(
                        look: engine.wornLook(),
                        stage: Growth.stage(of: engine.pet),
                        animation: calm ? .sit : .breathe,
                        reduceMotion: calm,
                        companion: nil,
                        showCompanion: false
                    )
                    .padding(4)
                }
                .frame(width: 112, height: 112)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(snap.stage) \(snap.name)")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(snap.pronounsLine.isEmpty ? "—" : snap.pronounsLine)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(ProfilePalette.muted)
                        .accessibilityLabel(snap.pronounsLine.isEmpty ? ProfileCopy.pronounsMissing(engine.languageCode) : snap.pronounsLine)
                    if tab != .details {
                        friendCode
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if tab == .about {
                Text(snap.about)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(ProfilePalette.brown)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if tab == .details {
                detailsBlock
            }
            if tab == .traits {
                TraitHexagon(traits: snap.hexTraits)
            }
            tabRow
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(ProfilePalette.tabBand)
                .padding(.horizontal, -14)
                .padding(.bottom, -12)
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .top)
        .background(ProfilePalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: ProfilePalette.shadow, radius: 12, y: 6)
        .overlay(alignment: .top) { ProfileCardClip().offset(y: -8) }
        .overlay(alignment: .topTrailing) { Postmark().padding(.top, 8).padding(.trailing, 8) }
        .padding(.top, 10)
    }

    private var friendCode: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(engine.t("profile.friendCode"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.05)
                .textCase(.uppercase)
                .foregroundStyle(ProfilePalette.muted)
            HStack(spacing: 6) {
                Text(snap.friendCode)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(ProfilePalette.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Button {
                    UIPasteboard.general.string = snap.friendCode
                    engine.cue(.select)
                    copied = true
                } label: {
                    CopyGlyph(copied: copied)
                        .foregroundStyle(ProfilePalette.gold)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t(copied ? "profile.copied" : "profile.friendCode"))
            }
        }
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

    private func detail(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ProfilePalette.muted)
            Spacer(minLength: 6)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(ProfilePalette.brown)
                .lineLimit(1)
        }
    }

    private var tabRow: some View {
        HStack(spacing: 6) {
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
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(selected ? ProfilePalette.brown : ProfilePalette.tabIdle)
                .frame(maxWidth: .infinity)
                .frame(height: 33)
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
            HStack(spacing: 12) {
                SunCheck()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(snap.streak)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                        Text(snap.streak == 1 ? engine.t("profile.streak.unit.one") : engine.t("profile.streak.unit.many"))
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(ProfilePalette.brown)
                    Text(streakSubtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(ProfilePalette.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                ChevronGlyph()
                    .foregroundStyle(ProfilePalette.brownSoft)
                    .frame(width: 28, height: 28)
                    .background(ProfilePalette.chevronWash, in: Circle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(ProfilePalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: ProfilePalette.shadow, radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var forestNotebook: some View {
        Button { showForest = true } label: {
            NotebookShell {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ProfileLeafGlyph()
                        Text(ProfileCopy.forestTitle(engine.languageCode))
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(ProfilePalette.brown)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(engine.tf("profile.count", snap.forestFound, snap.forestTotal))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(ProfilePalette.brownSoft)
                    }
                    Rectangle()
                        .fill(Color(hex: 0xE4D2B0))
                        .frame(height: 1)
                    ForestMap(places: snap.places)
                        .frame(height: 168)
                    HStack {
                        Spacer()
                        Text(engine.t("profile.seeAll"))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(ProfilePalette.brown)
                        Spacer()
                    }
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

    private var streakSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(engine.t("profile.streak.detail"))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
            detail(engine.t("profile.streak.now"), "\(snap.streak)")
            detail(engine.t("profile.streak.best"), "\(snap.longest)")
            Text(streakSubtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(ProfilePalette.muted)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ProfilePalette.page.ignoresSafeArea())
        .presentationDetents([.medium])
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
