import Foundation

enum AdventureEngine {
    static let traitBaseline = 8
    static let traitMaximum = 100

    static func initialTraits() -> [String: Int] {
        Dictionary(uniqueKeysWithValues: AdventureTrait.allCases.map { ($0.rawValue, traitBaseline) })
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func isUnlocked(_ place: AdventurePlaceDefinition, save: AdventureSave) -> Bool {
        save.allPlacesUnlocked || save.completedCount >= place.unlockAfterAdventures
    }

    static func phase(
        save: AdventureSave,
        energy: Int,
        energyGoal: Int,
        appNow: Date,
        wallNow: Date,
        calendar: Calendar = .current
    ) -> AdventurePhase {
        let today = dayKey(for: appNow, calendar: calendar)
        if let active = save.active {
            if wallNow >= active.returnsAt {
                return .storyReady(active)
            }
            return .traveling(active, remaining: active.returnsAt.timeIntervalSince(wallNow))
        }
        if save.lastResolvedDayKey == today {
            return .rested(dayKey: today)
        }
        let goal = max(energyGoal, 0)
        if goal > 0, energy < goal {
            return .needsEnergy(current: max(energy, 0), goal: goal)
        }
        return .ready
    }

    static func destinationID(save: AdventureSave, catalog: AdventureCatalog) -> String {
        if let selected = catalog.place(id: save.selectedPlaceID), isUnlocked(selected, save: save) {
            return selected.id
        }
        return recommendedPlaceID(save: save, catalog: catalog)
    }

    static func recommendedPlaceID(save: AdventureSave, catalog: AdventureCatalog) -> String {
        let unlocked = catalog.places.filter { isUnlocked($0, save: save) }
        if let fresh = unlocked.first(where: { place in
            catalog.stories.contains { $0.placeID == place.id && !save.seenStoryIDs.contains($0.id) }
        }) {
            return fresh.id
        }
        return unlocked.last?.id ?? catalog.places.first?.id ?? "flower-meadow"
    }

    static func storyForStart(placeID: String, save: AdventureSave, catalog: AdventureCatalog) -> AdventureStoryDefinition? {
        let pool = catalog.stories.filter { $0.placeID == placeID }
        if let queued = save.queuedStoryID,
           let story = catalog.story(id: queued),
           story.placeID == placeID {
            return story
        }
        let unseen = pool.filter { !save.seenStoryIDs.contains($0.id) }
        if let next = unseen.first {
            return next
        }
        guard !pool.isEmpty else { return nil }
        let visits = save.placeVisits[placeID, default: 0]
        return pool[visits % pool.count]
    }

    static func apply(deltas: [String: Int], to traits: inout [String: Int]) -> [String: Int] {
        var applied: [String: Int] = [:]
        for (key, delta) in deltas where AdventureTrait(rawValue: key) != nil && delta != 0 {
            let current = traits[key, default: traitBaseline]
            let next = min(traitMaximum, max(0, current + delta))
            let change = next - current
            traits[key] = next
            if change != 0 {
                applied[key] = change
            }
        }
        return applied
    }

    static func adventuresUntilUnlock(_ place: AdventurePlaceDefinition, save: AdventureSave) -> Int {
        if isUnlocked(place, save: save) {
            return 0
        }
        return max(0, place.unlockAfterAdventures - save.completedCount)
    }
}
