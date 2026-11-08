import SwiftUI

/// Hamburger menu (reference J), a full-screen cover from Home and the pet tab: name card, the
/// purple widget banner, a 2-column grid of the self-care tools, the seasonal event banner in
/// the event's color and a grouped list.
struct MoreScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var showWidgets = false
    @State private var autoOpened = false

    var body: some View {
        MenuScroll {
            nameCard
                .goobyEntrance(0)
            widgetBanner
                .goobyEntrance(1)
            grid
            eventBanner
                .goobyEntrance(8)
            MenuSectionHeader(text: "Gooby")
                .goobyEntrance(9)
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
            .goobyEntrance(10)
        }
        .menuChrome(engine, title: "")
        .navigationDestination(isPresented: $showSettings) { SettingsView(engine: engine) }
        .navigationDestination(isPresented: $showWidgets) { MenuWidgetGuide(engine: engine) }
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

    // MARK: Widget banner

    /// "Add the widget" (reference J). iOS lets only the user place widgets, so "Add" opens the
    /// widget previews and the steps for the Home Screen and the Lock Screen.
    private var widgetBanner: some View {
        MenuBanner(
            color: Theme.Tab.menu.banner,
            edge: Color(hex: 0x5D50A8),
            title: engine.tx("menu.widget.title", de: "Hol dir das Widget", en: "Add the widget"),
            subtitle: engine.tx("menu.widget.sub", de: "Gooby und deine Ziele auf dem Home-Bildschirm", en: "Gooby and your goals on your Home Screen"),
            button: engine.tx("menu.widget.add", de: "Los", en: "Add"),
            action: { showWidgets = true }
        ) {
            MenuWidgetArt(engine: engine)
        }
    }

    // MARK: Event banner

    /// Seasonal event in its own color, in the slot below the grid.
    @ViewBuilder
    private var eventBanner: some View {
        if let event = MenuEvents.featured(engine) {
            let active = engine.isEventActive(event.id)
            let color = MenuEvents.theme(event).color
            HStack(spacing: 12) {
                MenuEventBadge(event: event, size: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(active
                         ? engine.tx("menu.event.now", de: "Jetzt", en: "Now on")
                         : engine.tx("menu.event.soon", de: "Bald", en: "Coming up"))
                        .font(Theme.Fonts.caps)
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundStyle(Color(hex: 0xFFE38A))
                    Text(event.title.text(engine.languageCode))
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(active ? MenuEvents.untilText(engine, event) : MenuEvents.startsText(engine, event))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                NavigationLink {
                    if let make = FeatureHost.shared.eventsScreen { make(engine) } else { EventScreen(engine: engine) }
                } label: {
                    Text(engine.tx("menu.event.open", de: "Öffnen", en: "Open"))
                        .foregroundStyle(color)
                        .lineLimit(1)
                }
                .buttonStyle(Press3DButtonStyle(fill: .white, edge: Color.black.opacity(0.2), radius: 16, depth: 4, horizontal: 14, vertical: 8))
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .cardShadow()
        }
    }

    // MARK: Grid

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            NavigationLink {
                if let make = FeatureHost.shared.calmScreen { make(engine) } else { CalmScreen(engine: engine, reduceMotion: reduceMotion) }
            } label: {
                MenuTile(icon: "", title: engine.tx("menu.activities", de: "Aktivitäten", en: "Activities"), leading: AnyView(MenuActivitiesIcon()))
            }
            .goobyEntrance(2)
            NavigationLink {
                if let make = FeatureHost.shared.moodScreen { make(engine) } else { MoodScreen(engine: engine) }
            } label: {
                MenuTile(icon: "😊", title: engine.t("mood.title"))
            }
            .goobyEntrance(3)
            NavigationLink {
                if let make = FeatureHost.shared.habitsScreen { make(engine) } else { HabitListScreen(engine: engine) }
            } label: {
                MenuTile(icon: "📋", title: engine.tx("menu.goals", de: "Meine Ziele", en: "My goals"))
            }
            .goobyEntrance(4)
            NavigationLink {
                StatsScreen(engine: engine)
            } label: {
                MenuTile(icon: "📊", title: engine.tx("menu.insights", de: "Einblicke", en: "Insights"))
            }
            .goobyEntrance(5)
            NavigationLink {
                if let make = FeatureHost.shared.journalScreen { make(engine) } else { JournalScreen(engine: engine) }
            } label: {
                MenuTile(icon: "📔", title: engine.t("journal.title"))
            }
            .goobyEntrance(6)
            NavigationLink {
                if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
            } label: {
                MenuTile(icon: "🗺️", title: engine.tx("menu.places", de: "Orte", en: "Places"))
            }
            .goobyEntrance(7)
        }
        .buttonStyle(MenuTilePressStyle())
    }
}

/// "Add the widget": the widget previews with today's data and the steps to place them. iOS has
/// no API to add a widget for the user, so the screen explains the system steps.
struct MenuWidgetGuide: View {
    var engine: GoobyEngine

    var body: some View {
        MenuScroll(spacing: 14) {
            GoobyWidgetGallery(snapshot: GoobyWidgetBridge.shared.makeSnapshot(engine))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .goobyEntrance(0)
            MenuSectionHeader(text: engine.tx("menu.widget.home", de: "Home-Bildschirm", en: "Home Screen"))
            MenuListGroup {
                step(1, engine.tx("menu.widget.step1", de: "Halte eine freie Stelle auf dem Home-Bildschirm gedrückt, bis die Apps wackeln.", en: "Touch and hold an empty spot on your Home Screen until the apps jiggle."))
                MenuListDivider()
                step(2, engine.tx("menu.widget.step2", de: "Tippe oben links auf „+“ oder „Bearbeiten“ › „Widget hinzufügen“.", en: "Tap “+” or “Edit” › “Add Widget” in the top left corner."))
                MenuListDivider()
                step(3, engine.tx("menu.widget.step3", de: "Suche nach „Gooby“, wähle eine Größe und tippe auf „Widget hinzufügen“.", en: "Search for “Gooby”, pick a size and tap “Add Widget”."))
            }
            .goobyEntrance(1)
            MenuSectionHeader(text: engine.tx("menu.widget.lock", de: "Sperrbildschirm", en: "Lock Screen"))
            MenuListGroup {
                step(1, engine.tx("menu.widget.lock1", de: "Halte den Sperrbildschirm gedrückt und tippe auf „Anpassen“.", en: "Touch and hold the Lock Screen and tap “Customize”."))
                MenuListDivider()
                step(2, engine.tx("menu.widget.lock2", de: "Wähle den Sperrbildschirm, tippe auf das Widget-Feld und dann auf Gooby.", en: "Choose the Lock Screen, tap the widget area, then tap Gooby."))
            }
            .goobyEntrance(2)
        }
        .menuChrome(engine, title: engine.tx("menu.widget.screen", de: "Widget", en: "Widget"))
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(verbatim: "\(number)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Theme.Tab.menu.banner, in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
        .accessibilityElement(children: .combine)
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
