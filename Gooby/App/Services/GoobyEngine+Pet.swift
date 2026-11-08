import Foundation

// Pet slice: read helpers for the pet tab, the friend album and the world screens, plus the
// profile rename. No new stored state (D4): everything is derived from existing records.
extension GoobyEngine {
    /// Adventures whose story has been answered.
    func petFinishedAdventures() -> Int {
        all(AdventureRun.self).filter { $0.status == "claimed" }.count
    }

    /// All goal check-offs ever (skipped days excluded).
    func petCompletions() -> Int {
        all(HabitLog.self).filter { !$0.skipped }.reduce(0) { $0 + $1.count }
    }

    /// Longest run of consecutive days with at least one checked goal.
    func petLongestStreak() -> Int {
        let keys = Set(all(HabitLog.self).filter { !$0.skipped && $0.count > 0 }.map(\.dayKey))
        let days = keys.compactMap { DayKey.parse($0) }.sorted()
        let calendar = Calendar.current
        var best = 0
        var run = 0
        var previous: Date?
        for day in days {
            if let previous,
               let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return max(best, streak())
    }

    /// IDs of every discovery found on adventures.
    func petFoundDiscoveries() -> Set<String> {
        Set(all(DiscoveryRecord.self).map(\.discoveryID))
    }

    /// Found and total discoveries of a place.
    func petExplored(_ place: PlaceDef, found: Set<String>) -> (found: Int, total: Int) {
        (place.discoveries.filter { found.contains($0.id) }.count, place.discoveries.count)
    }

    /// Explored share of a place in percent (0...100).
    func petExploredPercent(_ place: PlaceDef, found: Set<String>) -> Int {
        let explored = petExplored(place, found: found)
        guard explored.total > 0 else { return 0 }
        return Int((Double(explored.found) / Double(explored.total) * 100).rounded())
    }

    /// Place shown on the profile: today's adventure, else the latest one, else the first place.
    func petCurrentPlace() -> PlaceDef? {
        if let run = todaysRun(), let place = catalog.placesByID[run.placeID] { return place }
        let latest = all(AdventureRun.self).max { $0.startedAt < $1.startedAt }
        if let latest, let place = catalog.placesByID[latest.placeID] { return place }
        return catalog.places.first
    }

    /// Hatched mini-friends by species ID.
    func petOwnedFriends() -> [String: [MiniFriend]] {
        Dictionary(grouping: all(MiniFriend.self), by: \.speciesID)
    }

    /// Growth points (Growth.stage: adventure days x 2 + care days) and the point range of the
    /// current stage. `next` is nil for the last stage.
    func petGrowth() -> (stage: String, points: Int, floor: Int, next: Int?) {
        let stage = Growth.stage(of: pet)
        let points = pet.adventureDays * 2 + pet.careDays
        let floors = [0, 8, 20, 40, 70]
        let index = Growth.order.firstIndex(of: stage) ?? 0
        let next = index + 1 < floors.count ? floors[index + 1] : nil
        return (stage, points, floors[min(index, floors.count - 1)], next)
    }

    /// The travel ticket that unlocks a place early, if the shop sells one.
    func petTicket(for place: PlaceDef) -> ItemDef? {
        catalog.itemsByID["ticket-\(place.id)"]
    }

    /// Saves Gooby's name (never empty) and the player's nickname.
    func petRename(gooby: String, nickname: String) {
        let name = gooby.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.goobyName = name.isEmpty ? "Gooby" : String(name.prefix(24))
        profile.nickname = String(nickname.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
        log("profile renamed")
        save()
    }
}
