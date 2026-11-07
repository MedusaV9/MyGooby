import SwiftUI

/// Sheets Home can present.
enum HomeSheet: Identifiable {
    case mood, room, habits, world, calm
    case addGoal(String?)

    var id: String {
        switch self {
        case .mood: return "mood"
        case .room: return "room"
        case .habits: return "habits"
        case .world: return "world"
        case .calm: return "calm"
        case .addGoal(let category): return "add-\(category ?? "")"
        }
    }
}

/// Home tab (screenshot-reference.md, screens 1 and 2): full-bleed scene with Gooby, the adventure
/// card, today's goals by time of day on the green background, "Add a goal" and the pause card.
struct TodayView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var sheet: HomeSheet?
    @State private var showMenu = false
    @State private var anytimeOpen = true
    @State private var openHabit: Habit?
    @State private var routed = false
    /// The scene has scrolled away: a green strip covers the status bar.
    @State private var stripShown = false

    private static let headerAnchor = "home.header"

    var body: some View {
        GeometryReader { outer in
            let top = outer.safeAreaInsets.top
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        scene(top: top, height: outer.size.height)
                        goalsArea
                            .padding(.horizontal, Theme.Space.margin)
                            .padding(.top, 2)
                            .padding(.bottom, 14)
                            .background(Theme.Tab.home.bg)
                        HomePauseFooter(
                            title: engine.t("today.pause"),
                            subtitle: engine.tx("home.pause.subtitle", de: "Atmen, Fokus und ruhige Klänge", en: "Breathing, focus and calm sounds")
                        ) {
                            sheet = .calm
                        }
                    }
                    .frame(minHeight: outer.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
                .background(backdrop)
                .overlay(alignment: .top) {
                    Theme.Tab.home.bg
                        .frame(height: top)
                        .offset(y: -top)
                        .opacity(stripShown ? 1 : 0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .onPreferenceChange(HomeSceneBottomKey.self) { bottom in
                    let covered = bottom < top + 8
                    if covered != stripShown { stripShown = covered }
                }
                .onAppear { route(proxy) }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $openHabit) { habit in
            HabitDetail(engine: engine, habit: habit)
        }
        .goobySheet(item: $sheet) { item in
            sheetContent(item)
        }
        .goobyCover(isPresented: $showMenu) {
            NavigationStack { MoreScreen(engine: engine, reduceMotion: reduceMotion) }
        }
        .overlay { SparkleOverlay(token: engine.celebration, enabled: !reduceMotion).allowsHitTesting(false) }
        .overlay(alignment: .top) { banner }
    }

    // MARK: Scene

    /// The scene runs up under the status bar: its frame includes `top`, the negative padding
    /// keeps the layout below the safe area so scrolling and `scrollTo` stay inside it.
    private func scene(top: CGFloat, height: CGFloat) -> some View {
        HomeSceneView(engine: engine, reduceMotion: reduceMotion, topInset: top)
            .frame(height: top + max(300, height * 0.47))
            .overlay(alignment: .top) {
                HomeTopBar(engine: engine, openMenu: { showMenu = true }, openMood: { sheet = .mood })
                    .padding(.top, top)
            }
            .background {
                GeometryReader { geo in
                    Color.clear.preference(key: HomeSceneBottomKey.self, value: geo.frame(in: .global).maxY)
                }
            }
            .padding(.top, -top)
    }

    /// Sky (or wall) color above the scene and the footer green below, for the scroll bounce.
    private var backdrop: some View {
        VStack(spacing: 0) {
            HomeSceneView.topColor(engine: engine)
            Theme.Tab.home.wave
        }
        .ignoresSafeArea()
    }

    // MARK: Goals

    private var goalsArea: some View {
        VStack(alignment: .leading, spacing: Theme.Space.gap) {
            HomeAdventureCard(engine: engine) { sheet = .world }
            Text(greeting)
                .font(Theme.Fonts.body)
                .foregroundStyle(Color.white.opacity(0.92))
                .padding(.top, 6)
            headerRow
                .id(TodayView.headerAnchor)
            sections
            HomeAddGoalCard(title: engine.tx("home.goal.add", de: "Ziel hinzufügen", en: "Add a goal")) {
                sheet = .addGoal(nil)
            }
            .padding(.top, 4)
        }
    }

    private var greeting: String {
        let name = engine.profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let hello = name.isEmpty
            ? engine.tx("home.hello.noname", de: "Hallo!", en: "Hello!")
            : engine.txf("home.hello", de: "Hallo, %@!", en: "Hello, %@!", name)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return hello + " · " + formatter.string(from: engine.now())
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            GoobyIcon("calendar", size: 26)
            Text(goalsLeftText)
                .font(Theme.Fonts.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            Button { sheet = .habits } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.tx("home.goals.manage", de: "Ziele verwalten", en: "Manage goals"))
            Button { sheet = .room } label: {
                Image(systemName: "circle.grid.2x2.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                            .offset(x: 7, y: -7)
                    }
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.tx("home.room.edit", de: "Zimmer einrichten", en: "Decorate the room"))
        }
    }

    private var goalsLeftText: String {
        let total = engine.dueHabits(on: engine.now()).count
        let left = engine.homeGoalsLeft()
        if total == 0 { return engine.tx("home.goals.none", de: "Heute ist nichts fällig", en: "Nothing due today") }
        if left == 0 { return engine.tx("home.goals.allDone", de: "Alle Ziele geschafft! 🎉", en: "All goals done! 🎉") }
        if left == 1 { return engine.tx("home.goals.leftOne", de: "Noch 1 Ziel für heute!", en: "1 goal left for today!") }
        return engine.txf("home.goals.left", de: "Noch %d Ziele für heute!", en: "%d goals left for today!", left)
    }

    @ViewBuilder private var sections: some View {
        let due = engine.dueHabits(on: engine.now())
        let grouped = Dictionary(grouping: due, by: HomeGoalSection.of)
        if due.isEmpty {
            sectionLabel(.anytime)
            Text(engine.t("today.tasks.empty"))
                .font(Theme.Fonts.body)
                .foregroundStyle(Color.white.opacity(0.9))
                .padding(.horizontal, 4)
        } else {
            ForEach(HomeGoalSection.allCases) { section in
                if let rows = grouped[section], !rows.isEmpty {
                    sectionView(section, rows: rows)
                }
            }
        }
    }

    private func sectionView(_ section: HomeGoalSection, rows: [Habit]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(section)
            if section != .anytime || anytimeOpen {
                ForEach(rows) { habit in
                    HomeGoalCard(engine: engine, habit: habit, day: engine.now()) { openHabit = habit }
                        .dropDestination(for: String.self) { items, _ in
                            drop(items, on: habit)
                        }
                }
            }
        }
        .padding(.top, 4)
        .id(sectionAnchor(section))
    }

    @ViewBuilder private func sectionLabel(_ section: HomeGoalSection) -> some View {
        let addLabel = engine.txf("home.goal.addTo", de: "Ziel zu „%@“ hinzufügen", en: "Add a goal to “%@”", sectionTitle(section))
        if section == .anytime {
            LineSectionLabel(title: sectionTitle(section), expanded: $anytimeOpen, addLabel: addLabel) {
                sheet = .addGoal(section.presetCategory)
            }
        } else {
            LineSectionLabel(title: sectionTitle(section), addLabel: addLabel) {
                sheet = .addGoal(section.presetCategory)
            }
        }
    }

    private func sectionTitle(_ section: HomeGoalSection) -> String {
        switch section {
        case .morning: return engine.tx("home.section.morning", de: "Start in den Tag", en: "Start the day")
        case .anytime: return engine.tx("home.section.anytime", de: "Jederzeit", en: "Any time")
        case .evening: return engine.tx("home.section.evening", de: "Am Abend", en: "In the evening")
        }
    }

    private func sectionAnchor(_ section: HomeGoalSection) -> String { "home.section.\(section.rawValue)" }

    private func drop(_ items: [String], on target: Habit) -> Bool {
        guard let raw = items.first, let id = UUID(uuidString: raw),
              let moving = engine.habits().first(where: { $0.id == id }),
              moving.id != target.id,
              HomeGoalSection.of(moving) == HomeGoalSection.of(target) else { return false }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            engine.homeMove(moving, onto: target)
        }
        return true
    }

    // MARK: Sheets and routes

    @ViewBuilder private func sheetContent(_ item: HomeSheet) -> some View {
        switch item {
        case .mood:
            if let mood = FeatureHost.shared.moodScreen { mood(engine) } else { MoodComposer(engine: engine) }
        case .room:
            if let room = FeatureHost.shared.roomScreen { room(engine) } else { RoomEditorSheet(engine: engine) }
        case .habits:
            NavigationStack {
                if let make = FeatureHost.shared.habitsScreen { make(engine) } else { HabitListScreen(engine: engine) }
            }
        case .world:
            NavigationStack {
                if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
            }
        case .calm:
            NavigationStack {
                if let make = FeatureHost.shared.calmScreen { make(engine) } else { CalmScreen(engine: engine, reduceMotion: reduceMotion) }
            }
        case .addGoal(let category):
            NavigationStack { HabitEditor(engine: engine, habit: nil, presetCategory: category) }
        }
    }

    /// Screenshot routes (DEBUG only): `menu`/`settings` open the menu, `homeGoals` scrolls to the goals.
    private func route(_ proxy: ScrollViewProxy) {
        guard !routed else { return }
        routed = true
        switch ShotMode.route {
        case .menu?, .settings?:
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                showMenu = true
            }
        case .homeGoals?:
            let due = engine.dueHabits(on: engine.now())
            let anchor = due.contains { HomeGoalSection.of($0) == .anytime } ? sectionAnchor(.anytime) : TodayView.headerAnchor
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000)
                proxy.scrollTo(anchor, anchor: .top)
            }
        default:
            break
        }
    }

    @ViewBuilder private var banner: some View {
        if let text = engine.banner {
            Text(text)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white, in: Capsule())
                .cardShadow()
                .padding(.top, 8)
                .task(id: text) {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if engine.banner == text { engine.banner = nil }
                }
        }
    }
}

/// Bottom edge of the Home scene in global coordinates.
private struct HomeSceneBottomKey: PreferenceKey {
    static let defaultValue: CGFloat = 10_000

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

/// A goal row outside Home (lists, details): the Home goal card without the drag handle.
struct HabitRow: View {
    var engine: GoobyEngine
    var habit: Habit
    var day: Date

    var body: some View {
        HomeGoalCard(engine: engine, habit: habit, day: day, showsHandle: false)
    }
}
