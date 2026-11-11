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
        let configuration = ModelConfiguration(schema: schema, url: GoobyFiles.storeURL(), cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Gooby could not open its local store: \(error)")
        }
        GoobyFiles.excludeRecursively(directory)
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if GoobyCharacterShots.requested {
                GoobyCharacterShotsScreen()
            } else {
                RootView()
            }
            #else
            RootView()
            #endif
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

struct MainTabs: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var tab = ShellTab.home
    @State private var showMenu = false

    var body: some View {
        Group {
            switch tab {
            case .home:
                NavigationStack { TodayView(engine: engine, reduceMotion: reduceMotion) }
            case .quests:
                NavigationStack { quests }
            case .shop:
                NavigationStack { shop }
            case .friends:
                NavigationStack { friends }
            case .bag:
                NavigationStack { bag }
            case .gooby:
                NavigationStack { gooby }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HomeTabBar(selection: $tab, engine: engine)
        }
        .sheet(isPresented: $showMenu) {
            NavigationStack { MoreScreen(engine: engine, reduceMotion: reduceMotion) }
        }
        .goobyCue(.sheet, opening: showMenu)
    }

    @ViewBuilder private var quests: some View {
        if let make = FeatureHost.shared.questsScreen { make(engine) } else { QuestScreen(engine: engine) }
    }

    @ViewBuilder private var shop: some View {
        if let make = FeatureHost.shared.shopScreen { make(engine) } else { ShopScreen(engine: engine, reduceMotion: reduceMotion) }
    }

    @ViewBuilder private var friends: some View {
        if let make = FeatureHost.shared.companionsScreen { make(engine) } else { FriendsScreen(engine: engine, reduceMotion: reduceMotion) }
    }

    @ViewBuilder private var bag: some View {
        BagScreen(engine: engine, reduceMotion: reduceMotion)
    }

    @ViewBuilder private var gooby: some View {
        ProfileScreen(engine: engine, onMenu: { showMenu = true }, onBag: { tab = .bag })
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
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
            if !message.isEmpty {
                Text(message).foregroundStyle(Theme.ink.opacity(0.7))
            }
            Button(engine.t("lock.open")) { authenticate() }
                .buttonStyle(GoobyButtonStyle())
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .goobyScreen()
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
