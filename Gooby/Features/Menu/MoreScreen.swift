import SwiftUI

/// Hamburger menu (screenshot-reference.md section 9), shown as a sheet from Home and the pet tab.
/// Name card, seasonal event banner, a 2-column grid of the self-care tools and a grouped list.
struct MoreScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var autoOpened = false

    var body: some View {
        MenuScroll {
            nameCard
            eventBanner
            grid
            MenuSectionHeader(text: "Gooby")
            MenuListGroup {
                NavigationLink {
                    GroundingView(engine: engine)
                } label: {
                    MenuListRow(icon: "💗", title: engine.tx("menu.firstAid", de: "Erste Hilfe", en: "First aid"), subtitle: engine.t("ground.subtitle"))
                }
                .buttonStyle(MenuRowButtonStyle())
                MenuListDivider()
                Button {
                    showSettings = true
                } label: {
                    MenuListRow(icon: "⚙️", title: engine.t("settings.title"))
                }
                .buttonStyle(MenuRowButtonStyle())
                MenuListDivider()
                Button {
                    showHelp = true
                } label: {
                    MenuListRow(icon: "❓", title: engine.t("settings.help"))
                }
                .buttonStyle(MenuRowButtonStyle())
            }
        }
        .menuChrome(engine, title: "")
        .navigationDestination(isPresented: $showSettings) { SettingsView(engine: engine) }
        .goobySheet(isPresented: $showHelp) { HelpView(engine: engine) }
        .onAppear {
            // Screenshot route "settings" opens the settings list on top of the menu.
            if ShotMode.route == .settings, !autoOpened {
                autoOpened = true
                showSettings = true
            }
        }
    }

    // MARK: Name card

    private var nameCard: some View {
        NavigationLink {
            MenuProfileScreen(engine: engine)
        } label: {
            GCard {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        names
                            .font(Theme.Fonts.title)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        Text(togetherText)
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.greyText)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Theme.greyText)
                        .frame(width: 34, height: 34)
                        .background(Theme.keyFace, in: Circle())
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint(engine.tx("menu.profile.edit", de: "Namen bearbeiten", en: "Edit names"))
    }

    private var names: Text {
        let gooby = goobyName
        let nickname = engine.profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nickname.isEmpty else { return Text(gooby).foregroundStyle(Theme.text) }
        return Text(gooby).foregroundStyle(Theme.text)
            + Text(" & ").foregroundStyle(Theme.greyText.opacity(0.8))
            + Text(nickname).foregroundStyle(Theme.text)
    }

    private var goobyName: String {
        let name = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Gooby" : name
    }

    private var togetherText: String {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: engine.profile.createdAt)
        let today = calendar.startOfDay(for: engine.now())
        let days = max(1, (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1)
        if days == 1 {
            return engine.tx("menu.together.one", de: "Seit heute zusammen", en: "Together since today")
        }
        return engine.txf("menu.together.other", de: "Seit %d Tagen zusammen", en: "Together for %d days", days)
    }

    // MARK: Event banner

    @ViewBuilder
    private var eventBanner: some View {
        if let event = MenuEvents.featured(engine) {
            let active = engine.isEventActive(event.id)
            HStack(spacing: 14) {
                MenuEventBadge(event: event, size: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title.text(engine.languageCode))
                        .font(Theme.Fonts.title3)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(active ? MenuEvents.untilText(engine, event) : MenuEvents.startsText(engine, event))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                NavigationLink {
                    if let make = FeatureHost.shared.eventsScreen { make(engine) } else { EventScreen(engine: engine) }
                } label: {
                    Text(engine.tx("menu.event.open", de: "Öffnen", en: "Open"))
                        .foregroundStyle(Theme.Tab.menu.banner)
                }
                .buttonStyle(Press3DButtonStyle(fill: .white, edge: Color(hex: 0x5D50A8), radius: 18, depth: 4, horizontal: 14, vertical: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Tab.menu.banner, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .cardShadow()
        }
    }

    // MARK: Grid

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            NavigationLink {
                if let make = FeatureHost.shared.calmScreen { make(engine) } else { CalmScreen(engine: engine, reduceMotion: reduceMotion) }
            } label: {
                MenuTile(icon: "🧘", title: engine.tx("menu.activities", de: "Aktivitäten", en: "Activities"))
            }
            NavigationLink {
                if let make = FeatureHost.shared.moodScreen { make(engine) } else { MoodScreen(engine: engine) }
            } label: {
                MenuTile(icon: "😊", title: engine.t("mood.title"))
            }
            NavigationLink {
                if let make = FeatureHost.shared.habitsScreen { make(engine) } else { HabitListScreen(engine: engine) }
            } label: {
                MenuTile(icon: "📋", title: engine.tx("menu.goals", de: "Meine Ziele", en: "My goals"))
            }
            NavigationLink {
                StatsScreen(engine: engine)
            } label: {
                MenuTile(icon: "📊", title: engine.tx("menu.insights", de: "Einblicke", en: "Insights"))
            }
            NavigationLink {
                if let make = FeatureHost.shared.journalScreen { make(engine) } else { JournalScreen(engine: engine) }
            } label: {
                MenuTile(icon: "📔", title: engine.t("journal.title"))
            }
            NavigationLink {
                if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
            } label: {
                MenuTile(icon: "🗺️", title: engine.tx("menu.places", de: "Orte", en: "Places"))
            }
        }
        .buttonStyle(.plain)
    }
}

/// Profile editor reached from the menu name card and Settings > Profile. Same fields and save
/// logic as the former settings profile card.
struct MenuProfileScreen: View {
    var engine: GoobyEngine
    @State private var nickname = ""
    @State private var goobyName = ""
    @State private var saved = false

    var body: some View {
        MenuScroll {
            HStack {
                Spacer()
                GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: 96)
                    .frame(width: 120, height: 120)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    .cardShadow()
                Spacer()
            }
            .padding(.vertical, 8)
            .accessibilityHidden(true)
            MenuSectionHeader(text: engine.t("settings.nickname"))
            MenuField(placeholder: engine.t("settings.nickname"), text: $nickname)
            MenuSectionHeader(text: engine.t("settings.goobyName"))
            MenuField(placeholder: engine.t("settings.goobyName"), text: $goobyName)
            MenuSectionHeader(text: engine.t("settings.photo"))
            MenuListGroup {
                MenuProfilePhotoRow(engine: engine)
            }
            Button {
                engine.profile.nickname = nickname.trimmingCharacters(in: .whitespaces)
                let name = goobyName.trimmingCharacters(in: .whitespaces)
                engine.profile.goobyName = name.isEmpty ? "Gooby" : name
                engine.save()
                saved = true
            } label: {
                Text(engine.t("common.save"))
            }
            .menuPrimaryButton()
            .padding(.top, 8)
            if saved {
                Text(engine.tx("menu.profile.saved", de: "Gespeichert.", en: "Saved."))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.checkGreen)
                    .frame(maxWidth: .infinity)
            }
        }
        .menuChrome(engine, title: engine.tx("menu.profile", de: "Profil", en: "Profile"))
        .onAppear {
            nickname = engine.profile.nickname
            goobyName = engine.profile.goobyName
        }
        .onChange(of: nickname) { _, _ in saved = false }
        .onChange(of: goobyName) { _, _ in saved = false }
    }
}
