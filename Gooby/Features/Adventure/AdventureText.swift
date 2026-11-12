import Foundation

@MainActor
enum AdventureText {
    static func line(_ engine: GoobyEngine, _ key: String, _ pairs: [String: String] = [:]) -> String {
        var text = engine.t(key)
        for (token, value) in pairs {
            text = text.replacingOccurrences(of: "{\(token)}", with: value)
        }
        return text
    }

    static func petName(_ engine: GoobyEngine) -> String {
        let trimmed = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Gooby" : trimmed
    }

    /// Empty and unknown pronouns use the neutral line. "her" is checked before "he".
    static func pronounKey(_ raw: String) -> String {
        let folded = raw.folding(options: .diacriticInsensitive, locale: Locale(identifier: "de"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if folded.isEmpty || folded.hasPrefix("they") || folded.hasPrefix("them") || folded.hasPrefix("their") { return "they" }
        if folded.hasPrefix("she") || folded.hasPrefix("sie") || folded.contains("her") { return "she" }
        if folded.hasPrefix("he") || folded.hasPrefix("er") || folded.contains("him") { return "he" }
        return "they"
    }

    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    static func remaining(_ engine: GoobyEngine) -> TimeInterval {
        guard let run = engine.todaysRun(), run.status == "traveling" else { return 0 }
        return run.returnsAt.timeIntervalSince(engine.now())
    }

    static func share(_ engine: GoobyEngine, remaining: TimeInterval) -> String {
        let name = petName(engine)
        if remaining <= 0 {
            return line(engine, "adventure.here", ["name": name])
        }
        let key = "adventure.share.\(pronounKey(engine.pet.pronouns))"
        return line(engine, key, ["name": name, "clock": clock(remaining)])
    }

    static func visits(_ engine: GoobyEngine, _ place: PlaceDef) -> String {
        if engine.isPlaceUnlocked(place.id) {
            let count = engine.placeProgress(place.id)?.visits ?? 0
            if count == 0 { return engine.t("adventure.visits.none") }
            if count == 1 { return engine.t("adventure.visits.one") }
            return line(engine, "adventure.visits.count", ["count": "\(count)"])
        }
        return lockedLine(engine, place)
    }

    static func lockedLine(_ engine: GoobyEngine, _ place: PlaceDef) -> String {
        let left = tripsLeft(engine, place)
        if left == 1 { return engine.t("adventure.locked.one") }
        return line(engine, "adventure.locked.count", ["count": "\(left)"])
    }

    static func tripsLeft(_ engine: GoobyEngine, _ place: PlaceDef) -> Int {
        let done = engine.all(AdventureRun.self).filter { $0.status == "claimed" }.count
        return max(0, place.unlockAfterAdventures - done)
    }
}
