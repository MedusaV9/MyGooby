import Foundation

/// Screens the CI `screenshots` job captures, one launch each:
/// `simctl launch ... -GoobyShot <route> -GoobyLang <de|en>`.
/// `widgets` shows ExtrasGallery (widget and Live Activity previews). `gooby` shows Gooby's pose
/// sheet (GoobyPoseSheet: every animation, outfits, avatars). `activity` opens Home with
/// today's adventure running; the job then sends the app to the background so the simulator
/// shows the adventure Live Activity in the Dynamic Island.
enum ShotRoute: String, CaseIterable {
    case home, homeGoals, quests, shop, friends, bag, pet, petCollections, micropedia, menu, settings, onboarding
    case widgets, activity, gooby
    /// Pushed from the bag: the world map and the event screen.
    case world, events
    /// Self-care screens pushed from the menu (opened over the pet tab).
    case activities, mood, journal, insights

    /// Tab selected at launch. Screens react to their own routes (scrolling, presenting the menu).
    var tab: GoobyTab {
        switch self {
        case .home, .homeGoals, .menu, .settings, .onboarding, .widgets, .activity, .gooby: return .home
        case .quests: return .quests
        case .shop: return .shop
        case .friends: return .friends
        case .bag, .world, .events: return .bag
        case .pet, .petCollections, .micropedia: return .pet
        case .activities, .mood, .journal, .insights: return .pet
        }
    }
}

/// DEBUG-only screenshot mode. With a route the app runs on an in-memory store seeded with demo
/// data, so real saves are never touched. Release builds always have `route == nil`.
enum ShotMode {
    static let route: ShotRoute? = {
        #if DEBUG
        return ShotMode.argument("-GoobyShot").flatMap(ShotRoute.init(rawValue:))
        #else
        return nil
        #endif
    }()

    static let language: String = {
        #if DEBUG
        return ShotMode.argument("-GoobyLang") == "de" ? "de" : "en"
        #else
        return "de"
        #endif
    }()

    #if DEBUG
    private static func argument(_ name: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    /// Demo state built through engine APIs only: onboarding done, 6 goals with 1 done, Gooby on
    /// today's adventure, some sparks, one hatched mini-friend as companion, quests in progress.
    @MainActor
    static func seed(_ engine: GoobyEngine) {
        engine.setLanguage(language)
        guard let route, route != .onboarding else { return }
        let de = language == "de"
        engine.profile.onboardingDone = true
        engine.profile.helpSeen = true
        engine.profile.nickname = "Mia"
        engine.profile.goobyName = "Gooby"
        let goals: [(String, String, String, String)] = [
            (de ? "Aufstehen" : "Get out of bed", "sun.max.fill", "morning", ""),
            (de ? "Tee trinken" : "Drink tea", "cup.and.saucer.fill", "health", ""),
            (de ? "Zähne putzen" : "Brush teeth", "sparkles", "hygiene", ""),
            (de ? "Spaziergang" : "Take a walk", "figure.walk", "movement", ""),
            (de ? "Wasser trinken" : "Drink water", "drop.fill", "health", ""),
            (de ? "Tagebuch" : "Journal", "pencil", "creative", "")
        ]
        var made: [Habit] = []
        for (index, goal) in goals.enumerated() {
            made.append(engine.makeHabit(title: goal.0, details: goal.3, icon: goal.1, category: goal.2, dailyGoal: index == 3))
        }
        engine.completeHabit(made[0], on: engine.now())
        engine.bindEgg(to: made[1])
        if let egg = engine.activeEgg(for: made[1].id) {
            engine.hatch(egg)
        }
        engine.addMood(level: 4, tags: ["happy", "calm"], note: "")
        _ = engine.grant(key: "shot:seed", sparks: 240, energy: 0)
        engine.fillEnergy()
        if let place = engine.catalog.places.first(where: { engine.isPlaceUnlocked($0.id) }) {
            _ = engine.startAdventure(placeID: place.id)
        }
        engine.recomputeQuests()
        engine.animation = .idle
        engine.banner = nil
        engine.save()
    }
    #endif
}
