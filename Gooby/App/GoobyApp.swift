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

    var body: some View {
        TabView {
            NavigationStack { today }
                .tabItem { Label(engine.t("tab.today"), systemImage: "sun.max.fill") }
            NavigationStack { habits }
                .tabItem { Label(engine.t("tab.habits"), systemImage: "checkmark.circle.fill") }
            NavigationStack { world }
                .tabItem { Label(engine.t("tab.world"), systemImage: "map.fill") }
            NavigationStack { calm }
                .tabItem { Label(engine.t("tab.calm"), systemImage: "wind") }
            NavigationStack { more }
                .tabItem { Label(engine.t("tab.more"), systemImage: "sparkles") }
        }
        .tint(Theme.ink)
    }

    @ViewBuilder private var today: some View {
        TodayView(engine: engine, reduceMotion: reduceMotion)
    }

    @ViewBuilder private var habits: some View {
        if let make = FeatureHost.shared.habitsScreen { make(engine) } else { HabitListScreen(engine: engine) }
    }

    @ViewBuilder private var world: some View {
        if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
    }

    @ViewBuilder private var calm: some View {
        if let make = FeatureHost.shared.calmScreen { make(engine) } else { CalmScreen(engine: engine, reduceMotion: reduceMotion) }
    }

    @ViewBuilder private var more: some View {
        MoreScreen(engine: engine, reduceMotion: reduceMotion)
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
