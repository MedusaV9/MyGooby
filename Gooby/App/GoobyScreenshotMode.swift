import SwiftUI

#if DEBUG
/// Debug builds launched with `-GoobyScreenshot <screen>` skip the first-run flow and open one screen,
/// so `.github/workflows/gooby-screens.yml` can capture it with `simctl io screenshot`.
/// Screens: home, home-adventure, quests, shop, friends, bag, profile, menu.
enum GoobyScreenshotMode {
    static var screen: String? {
        let value = UserDefaults.standard.string(forKey: "GoobyScreenshot") ?? ""
        return value.isEmpty ? nil : value
    }

    static var tab: ShellTab {
        switch screen {
        case "quests": return .quests
        case "shop": return .shop
        case "friends": return .friends
        case "friends-intro": return .friends
        case "bag": return .bag
        case "profile": return .gooby
        default: return .home
        }
    }

    @MainActor
    static func prepare(_ engine: GoobyEngine) {
        guard let screen else { return }
        if engine.languageCode != "en" { engine.setLanguage("en") }
        engine.profile.faceIDEnabled = false
        if !engine.profile.onboardingDone {
            engine.profile.goobyName = "Squiggles"
            engine.profile.nickname = "Hey"
            OnboardingScript.plantStarterPlan(engine: engine)
            engine.profile.onboardingDone = true
        }
        engine.markAffirmationShownToday()
        if screen == "shop" { engine.wallet.sparks = 100 }
        var lane = FriendsPostBook.load()
        if !lane.funSeen {
            lane.funSeen = true
            lane.save()
        }
        seedProfile(engine)
        // Morning checks in the reference frame are already done when the outing starts.
        // Fill the bar, mark those goals, then depart, so the captured trip stays eight hours.
        if screen == "home-adventure", engine.todaysRun() == nil {
            engine.wallet.energy = max(engine.wallet.energy, engine.profile.energyGoal)
        }
        HomeScreenshotSeed.apply(screen, engine: engine)
        if screen == "home-adventure", engine.todaysRun() == nil {
            if let place = engine.catalog.places.first(where: { engine.isPlaceUnlocked($0.id) }) {
                _ = engine.startAdventure(placeID: place.id)
            }
        }
        engine.save()
    }
}
#endif
