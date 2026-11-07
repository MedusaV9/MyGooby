import LocalAuthentication
import SwiftData
import SwiftUI

@main
struct GoobyApp: App {
    let container: ModelContainer

    init() {
        let directory = GoobyFiles.supportDirectory()
        GoobyFiles.excludeRecursively(directory)
        let schema = Schema([
            PlayerProfile.self, Wallet.self, GoobyPet.self, Habit.self, HabitLog.self, RewardLedger.self,
            AdventureRun.self, OwnedItem.self, SavedOutfit.self, RoomLayout.self, MoodEntry.self,
            JournalEntry.self, QuestRecord.self, EventRecord.self, MiniFriend.self, EggBinding.self,
            PlaceProgress.self, DiscoveryRecord.self, FocusSession.self, DailyStat.self, AppLogEntry.self
        ])
        // Screenshot mode (DEBUG only) never touches the real store.
        let configuration = ShotMode.route != nil
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            : ModelConfiguration(schema: schema, url: GoobyFiles.storeURL(), cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Gooby could not open its local store: \(error)")
        }
        GoobyFiles.excludeRecursively(directory)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var engine: GoobyEngine?
    @State private var unlocked = false

    var body: some View {
        Group {
            if let engine {
                shell(engine)
                    .environment(engine)
            } else {
                splash
            }
        }
        .task {
            guard engine == nil else { return }
            let created = GoobyEngine(context: context)
            created.boot()
            ModuleBootstrap.boot()
            #if DEBUG
            if ShotMode.route != nil { ShotMode.seed(created) }
            #endif
            engine = created
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .background, engine?.profile.faceIDEnabled == true {
                unlocked = false
            }
            if newPhase == .active {
                engine?.refreshDay()
            }
        }
        // Extras contract: deep links from widgets, Live Activities and notifications.
        .onOpenURL { GoobyRouter.shared.open($0) }
        .preferredColorScheme(.light)
        .environment(\.font, .system(.body, design: .rounded))
    }

    private var splash: some View {
        Theme.cream.ignoresSafeArea()
            .overlay {
                GoobyCharacterView(look: WornLook(), stage: "baby", animation: .breathe, reduceMotion: true, companion: nil)
                    .frame(width: 240, height: 280)
            }
    }

    @ViewBuilder
    private func shell(_ engine: GoobyEngine) -> some View {
        let reduce = systemReduce || engine.reduceMotion
        if engine.profile.faceIDEnabled && !unlocked {
            LockScreen(engine: engine) { unlocked = true }
        } else if !engine.profile.onboardingDone {
            OnboardingView(engine: engine, reduceMotion: reduce)
        } else {
            MainTabs(engine: engine, reduceMotion: reduce)
        }
    }
}

/// Six tabs with a custom tab bar tinted by the selected tab. A system TabView would move tabs 5
/// and 6 into a "More" list on iPhone, so the tabs are a ZStack of NavigationStacks instead: a
/// tab is created on its first visit and then kept (navigation and scroll state survive), hidden
/// tabs are invisible, untappable, hidden from VoiceOver and get `reduceMotion: true` so their
/// animations pause. Habits, World, Calm and the menu are reached from the screens.
struct MainTabs: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var selection: GoobyTab = ShotMode.route?.tab ?? .home
    @State private var opened: Set<GoobyTab> = []
    /// Screen opened by a deep link (focus, breathing, adventure, activities).
    @State private var linked: GoobyLink?
    @State private var showGallery = ShotMode.route == .widgets

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(GoobyTab.allCases) { tab in
                    if tab == selection || opened.contains(tab) {
                        let active = tab == selection
                        NavigationStack { screen(tab, reduce: reduceMotion || !active) }
                            .opacity(active ? 1 : 0)
                            .allowsHitTesting(active)
                            .accessibilityHidden(!active)
                    }
                }
            }
            GoobyTabBar(engine: engine, selection: $selection, reduceMotion: reduceMotion)
        }
        .onAppear {
            _ = opened.insert(selection)
            route(GoobyRouter.shared.pending)
        }
        .onChange(of: selection) { _, tab in _ = opened.insert(tab) }
        // Extras contract: deep links and the widget preview screenshot route.
        .onChange(of: GoobyRouter.shared.pending) { _, link in route(link) }
        .goobySheet(item: $linked) { link in
            GoobyLinkedScreen(engine: engine, link: link, reduceMotion: reduceMotion)
        }
        .goobyCover(isPresented: $showGallery) {
            NavigationStack { ExtrasGallery(engine: engine, presented: true) }
        }
        .tint(Theme.text)
    }

    private func route(_ link: GoobyLink?) {
        guard let link else { return }
        GoobyRouter.shared.pending = nil
        if let tab = link.tab {
            linked = nil
            selection = tab
        } else {
            selection = .home
            linked = link
        }
    }

    @ViewBuilder private func screen(_ tab: GoobyTab, reduce: Bool) -> some View {
        switch tab {
        case .home:
            TodayView(engine: engine, reduceMotion: reduce)
        case .quests:
            if let make = FeatureHost.shared.questsScreen { make(engine) } else { QuestScreen(engine: engine) }
        case .shop:
            if let make = FeatureHost.shared.shopScreen { make(engine) } else { ShopScreen(engine: engine, reduceMotion: reduce) }
        case .friends:
            if let make = FeatureHost.shared.companionsScreen { make(engine) } else { FriendsScreen(engine: engine, reduceMotion: reduce) }
        case .bag:
            BagScreen(engine: engine, reduceMotion: reduce)
        case .pet:
            PetProfileScreen(engine: engine, reduceMotion: reduce)
        }
    }
}

/// Tab bar: colorful drawn icons with a small bold label; the bar takes the selected tab's tint
/// and the selected item sits on a lighter rounded rect. The pet tab shows Gooby's head and name.
struct GoobyTabBar: View {
    var engine: GoobyEngine
    @Binding var selection: GoobyTab
    var reduceMotion: Bool

    var body: some View {
        let tint = selection.tint
        HStack(spacing: 2) {
            ForEach(GoobyTab.allCases) { tab in
                Button {
                    if selection != tab { MomentHub.shared.emit(.tabChanged(tab)) }
                    selection = tab
                } label: {
                    item(tab, tint: tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label(tab))
                .accessibilityAddTraits(selection == tab ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(tint.bar.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: selection)
    }

    private func item(_ tab: GoobyTab, tint: TabBarTint) -> some View {
        let selected = selection == tab
        return VStack(spacing: 2) {
            icon(tab, selected: selected)
                .frame(width: 32, height: 32)
            Text(label(tab))
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(tint.label)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background {
            if selected {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.highlight)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder private func icon(_ tab: GoobyTab, selected: Bool) -> some View {
        if tab == .pet {
            GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: 32)
                .scaleEffect(selected ? 1.08 : 1)
        } else {
            TabIconView(kind: tab, selected: selected, size: 30)
        }
    }

    private func label(_ tab: GoobyTab) -> String {
        if tab == .pet {
            let name = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? "Gooby" : name
        }
        return engine.t("kit.tab.\(tab.rawValue)")
    }
}

struct LockScreen: View {
    var engine: GoobyEngine
    var unlock: () -> Void
    @State private var message = ""

    var body: some View {
        VStack(spacing: 22) {
            GoobyCharacterView(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), animation: .sleep, reduceMotion: engine.reduceMotion, companion: nil)
                .frame(height: 260)
            Text(engine.t("lock.title"))
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.text)
            if !message.isEmpty {
                Text(message)
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.greyText)
            }
            Button(engine.t("lock.open")) { authenticate() }
                .buttonStyle(Press3DButtonStyle(fill: .white, radius: 22, vertical: 14, expand: true))
                .foregroundStyle(Theme.Tab.menu.banner)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .goobyScreen(Theme.Tab.menu.bg)
        .onAppear { authenticate() }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            message = engine.t("lock.unavailable")
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: engine.t("lock.reason")) { success, _ in
            Task { @MainActor in
                if success { unlock() } else { message = engine.t("lock.failed") }
            }
        }
    }
}
