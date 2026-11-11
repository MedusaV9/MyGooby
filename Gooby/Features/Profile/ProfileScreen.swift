import SwiftUI
import UIKit

struct ProfileScreen: View {
    var engine: GoobyEngine
    var onMenu: (() -> Void)? = nil
    var onBag: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var showCollection = false
    @State private var showMicropedia = false
    @State private var showEdit = false
    @State private var showMenu = false
    @State private var showStreak = false
    @State private var tab: CardTab = .about
    @State private var draft = ""
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
        .sheet(isPresented: $showEdit) { editSheet }
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
                locationNotebook
                    .padding(.top, 18)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 18)
        }
    }

    private var identityCard: some View {
        VStack(spacing: 0) {
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
                    Text(snap.name)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(ProfilePalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    tabBody
                        .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            Spacer(minLength: 14)
            tabRow
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .frame(minHeight: 214)
        .background(ProfilePalette.card, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: ProfilePalette.shadow, radius: 12, y: 6)
        .overlay(alignment: .top) { ProfileCardClip().offset(y: -8) }
        .overlay(alignment: .topTrailing) { Postmark().padding(.top, 8).padding(.trailing, 8) }
        .padding(.top, 10)
    }

    @ViewBuilder private var tabBody: some View {
        switch tab {
        case .about:
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.t("profile.friendCode"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.15)
                    .textCase(.uppercase)
                    .foregroundStyle(ProfilePalette.muted)
                HStack(spacing: 6) {
                    Text(snap.friendCode)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Button {
                        UIPasteboard.general.string = snap.friendCode
                        engine.haptics.soft()
                        copied = true
                    } label: {
                        CopyGlyph(copied: copied)
                            .foregroundStyle(ProfilePalette.gold)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.t(copied ? "profile.copied" : "profile.friendCode"))
                }
            }
        case .details:
            VStack(alignment: .leading, spacing: 3) {
                detail(engine.t("profile.detail.joined"), snap.joined)
                detail(engine.t("profile.detail.adventures"), "\(snap.adventures)")
                detail(engine.t("profile.detail.sparks"), "\(snap.sparks)")
                detail(engine.t("profile.detail.care"), "\(snap.careDays)")
                detail(engine.t("profile.detail.energy"), "\(snap.energy)/\(snap.energyGoal)")
            }
        case .traits:
            VStack(alignment: .leading, spacing: 4) {
                ForEach(snap.traits) { trait in
                    HStack(spacing: 8) {
                        Text(trait.name)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(ProfilePalette.brown)
                            .frame(width: 78, alignment: .leading)
                            .lineLimit(1)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(ProfilePalette.tabPill)
                                Capsule().fill(ProfilePalette.gold).frame(width: max(6, geo.size.width * min(1, trait.value)))
                            }
                        }
                        .frame(height: 7)
                    }
                }
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
        HStack {
            tabButton(.about)
            Spacer(minLength: 8)
            tabButton(.details)
            Spacer(minLength: 8)
            tabButton(.traits)
        }
    }

    private func tabButton(_ item: CardTab) -> some View {
        let selected = tab == item
        return Button {
            tab = item
        } label: {
            Text(engine.t(item.key))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(selected ? ProfilePalette.brown : ProfilePalette.tabIdle)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    if selected {
                        Capsule().fill(ProfilePalette.tabPill)
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
            .background(ProfilePalette.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: ProfilePalette.shadow, radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var locationNotebook: some View {
        let place = snap.featured
        return Button { showCollection = true } label: {
            NotebookShell {
                ZStack {
                    NotebookDoodles()
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            ProfileLeafGlyph()
                            Text(place?.name ?? engine.t("profile.locations"))
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundStyle(ProfilePalette.brown)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text(engine.tf("profile.count", place?.found ?? 0, place?.total ?? 0))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(ProfilePalette.brownSoft)
                        }
                        Rectangle()
                            .fill(Color(hex: 0xE4D2B0))
                            .frame(height: 1)
                            .padding(.top, 2)
                        Spacer(minLength: 0)
                        HStack {
                            Spacer()
                            GoobySticker(engine: engine, calm: calm)
                            Spacer()
                        }
                        Spacer(minLength: 0)
                    }
                }
                .frame(minHeight: 228)
            }
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        if snap.adventures == 1 {
            return engine.tf("profile.subtitle.one", snap.stage)
        }
        return engine.tf("profile.subtitle.many", snap.stage, snap.adventures)
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
        draft = snap.name
        showEdit = true
    }

    private var editSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(engine.t("profile.edit.title"))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
            TextField(engine.t("profile.edit.placeholder"), text: $draft)
                .font(.system(.body, design: .rounded))
                .padding(12)
                .background(ProfilePalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Button(engine.t("profile.edit.save")) {
                let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                engine.profile.goobyName = trimmed.isEmpty ? "Gooby" : String(trimmed.prefix(24))
                engine.save()
                revision += 1
                showEdit = false
            }
            .buttonStyle(ProfileSaveStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ProfilePalette.page.ignoresSafeArea())
        .presentationDetents([.medium])
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
