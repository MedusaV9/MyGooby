import SwiftUI

/// Einziger Einstieg für das App-Gerüst.
///
/// Einbinden:
/// ```swift
/// let bridge = AdventuresIntegration.makeBridge(
///     energy: model.energy,
///     energyGoal: model.energyGoal,
///     appNow: model.appNow,
///     languageCode: settings.languageCode,
///     bunnyName: profile.bunnyName,
///     prefersReducedMotion: settings.reducedMotion,
///     onGrantSparks: { amount in model.grantSparks(amount) },
///     onSpendEnergy: { amount in model.spendEnergy(amount) },
///     onPersonalityShift: { delta in /* nur Hinweis, kein zweites Konto */ }
/// )
/// AdventuresIntegration.rootView(bridge: bridge)
/// ```
///
/// Dieselbe Bridge behalten und Werte mit `bridge.applyHost(...)` nachziehen.
/// `onSpendEnergy` zieht die Energie im Spielstand ab und gibt zurück, ob das geklappt hat.
/// Die sieben Eigenschaften gehören diesem Modul. `onPersonalityShift` ist nur eine Mitteilung.
/// Sternenfunken werden einmal pro abgeschlossener Geschichte gutgeschrieben.
/// Die Rückkehr hängt an echten Zeitstempeln (`startedAt`, `returnsAt`), der eine Ausflug pro Tag am App-Tag.
/// Der Spielstand liegt unter Application Support/GoobyAdventures und ist vom iCloud-Backup ausgenommen.
@MainActor
enum AdventuresIntegration {
    private static var energyFillHandler: ((Int) -> Void)?

    static func makeBridge(
        energy: Int,
        energyGoal: Int,
        appNow: Date,
        languageCode: String,
        bunnyName: String,
        prefersReducedMotion: Bool,
        onGrantSparks: @escaping (Int) -> Void,
        onSpendEnergy: @escaping (Int) -> Bool,
        onPersonalityShift: @escaping (AdventurePersonalityDelta) -> Void
    ) -> AdventureBridge {
        AdventureBridge(
            energy: energy,
            energyGoal: energyGoal,
            appNow: appNow,
            languageCode: languageCode,
            bunnyName: bunnyName,
            prefersReducedMotion: prefersReducedMotion,
            onGrantSparks: onGrantSparks,
            onSpendEnergy: onSpendEnergy,
            onPersonalityShift: onPersonalityShift
        )
    }

    static func rootView(bridge: AdventureBridge) -> AdventureRootView {
        attach(bridge)
        return AdventureRootView(bridge: bridge, store: .shared)
    }

    static func attach(_ bridge: AdventureBridge) {
        self.bridge = bridge
    }

    static func registerDebugEnergyFill(_ handler: @escaping (Int) -> Void) {
        energyFillHandler = handler
    }

    static var bridge: AdventureBridge?

    static func debugFillEnergy() {
        let goal = max(bridge?.energyGoal ?? 0, 20)
        energyFillHandler?(goal)
        if let bridge, bridge.energy < goal {
            bridge.energy = goal
        }
    }

    static func debugCompleteCurrentAdventure() {
        AdventureStore.shared.completeCurrent(wallNow: Date())
    }

    static func debugResetProgress() {
        AdventureStore.shared.resetProgress()
    }

    static func debugSetAllPlacesUnlocked(_ unlocked: Bool) {
        AdventureStore.shared.setAllPlacesUnlocked(unlocked)
    }

    static func debugQueueStory(id: String?) {
        AdventureStore.shared.queueStory(id: id)
    }

    static func debugBeginStoryPreview(id: String) {
        AdventureStore.shared.beginPreview(storyID: id)
    }

    static func debugEndStoryPreview() {
        AdventureStore.shared.endPreview()
    }

    static func debugStoryCatalog() -> [AdventureStorySummary] {
        let store = AdventureStore.shared
        return store.catalog.stories.map {
            AdventureStorySummary(id: $0.id, placeID: $0.placeID, titleDE: $0.title.de, titleEN: $0.title.en)
        }
    }

    static func debugPlaceIDs() -> [String] {
        AdventureStore.shared.catalog.places.map(\.id)
    }

    static func currentTraits() -> [String: Int] {
        AdventureStore.shared.save.traits
    }

    static func debugSetTrait(_ key: String, value: Int) {
        AdventureStore.shared.setTrait(key, value: value)
    }

    static func validateCatalog() -> [String] {
        AdventureStore.shared.catalogLoad.issues
    }

    static func debugSnapshot() -> AdventureDebugSnapshot {
        let store = AdventureStore.shared
        let unlocked = store.catalog.places
            .filter { AdventureEngine.isUnlocked($0, save: store.save) }
            .map(\.id)
        return AdventureDebugSnapshot(
            completedCount: store.save.completedCount,
            activePlaceID: store.save.active?.placeID,
            activeStoryID: store.save.active?.storyID,
            startedAt: store.save.active?.startedAt,
            returnsAt: store.save.active?.returnsAt,
            unlockedPlaceIDs: unlocked,
            discoveryCount: store.save.foundDiscoveryIDs.count,
            traits: store.save.traits,
            savePath: store.savePath,
            storyCount: store.catalog.stories.count,
            placeCount: store.catalog.places.count,
            validationIssues: store.catalogLoad.issues,
            energyFillHandlerRegistered: energyFillHandler != nil,
            queuedStoryID: store.save.queuedStoryID,
            allPlacesUnlocked: store.save.allPlacesUnlocked,
            lastResolvedDayKey: store.save.lastResolvedDayKey
        )
    }

    static func previewBridge() -> AdventureBridge {
        let bridge = makeBridge(
            energy: 20,
            energyGoal: 20,
            appNow: Date(),
            languageCode: "de",
            bunnyName: "Gooby",
            prefersReducedMotion: false,
            onGrantSparks: { _ in },
            onSpendEnergy: { _ in true },
            onPersonalityShift: { _ in }
        )
        bridge.onSpendEnergy = { [weak bridge] amount in
            guard let bridge, bridge.energy >= amount else { return false }
            bridge.energy -= amount
            return true
        }
        return bridge
    }
}
