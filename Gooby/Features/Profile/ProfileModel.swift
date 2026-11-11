import SwiftUI

enum ProfilePalette {
    static let page = Color(hex: 0xEEDCB6)
    static let card = Color.white
    static let well = Color(hex: 0xFEF8EA)
    static let ink = Color(hex: 0x313131)
    static let brown = Color(hex: 0x645737)
    static let brownSoft = Color(hex: 0x8C7150)
    static let muted = Color(hex: 0x94846A)
    static let gold = Color(hex: 0xC0A966)
    static let banner = Color(hex: 0xE3A31B)
    static let bannerDeep = Color(hex: 0xC98A12)
    static let clip = Color(hex: 0xAF7E56)
    static let ring = Color(hex: 0xC48758)
    static let headerFill = Color(hex: 0xFBEECE)
    static let headerIcon = Color(hex: 0x7F6A35)
    static let paper = Color(hex: 0xFEF5EE)
    static let seeAll = Color(hex: 0xF3E7CD)
    static let cell = Color(hex: 0xF3E6CC)
    static let quietTile = Color(hex: 0xF4EBE3)
    static let silhouette = Color(hex: 0xD2C4A4)
    static let question = Color(hex: 0xE0D3C6)
    static let sun = Color(hex: 0xFDD35B)
    static let sunHot = Color(hex: 0xFB8F5E)
    static let leaf = Color(hex: 0x3F9A48)
    static let binder = Color(hex: 0xAF7E56)
    static let tileDark = Color(hex: 0x4E4E4E)
    static let tabPill = Color(hex: 0xF4E6C8)
    static let tabIdle = Color(hex: 0xC9BBA0)
    static let shadow = Color(hex: 0x8A6A3A).opacity(0.12)
    static let postmark = Color(hex: 0xE7C4A4)
    static let doodle = Color(hex: 0xE4CFA8)
    static let chevronWash = Color(hex: 0xF4EFE6)
}

enum ProfileDex {
    struct Entry: Identifiable, Hashable {
        var id: String
        var catalog: Bool
        var careDays: Int = 0
        var adventureDays: Int = 0
        var sparks: Int = 0
        var discoveries: Int = 0
    }

    static let entries: [Entry] = [
        Entry(id: "chick", catalog: true),
        Entry(id: "cloud", catalog: true),
        Entry(id: "dragon", catalog: true),
        Entry(id: "fox", catalog: true),
        Entry(id: "starling", catalog: true),
        Entry(id: "penguin", catalog: true),
        Entry(id: "bear", catalog: true),
        Entry(id: "cat", catalog: true),
        Entry(id: "ghost", catalog: true),
        Entry(id: "unicorn", catalog: true),
        Entry(id: "moon", catalog: true),
        Entry(id: "mushroom", catalog: true),
        Entry(id: "sprout", catalog: false, careDays: 3),
        Entry(id: "lantern", catalog: false, careDays: 7),
        Entry(id: "pebble", catalog: false, adventureDays: 2),
        Entry(id: "kite", catalog: false, adventureDays: 5),
        Entry(id: "teacup", catalog: false, sparks: 20),
        Entry(id: "comet", catalog: false, discoveries: 3)
    ]

    static func number(for id: String) -> Int {
        (entries.firstIndex { $0.id == id } ?? 0) + 1
    }
}

struct PlaceSnap: Identifiable, Hashable {
    var id: String
    var name: String
    var found: Int
    var total: Int
    var unlocked: Bool
    var skyTop: String
    var skyBottom: String
    var accent: String

    var percent: Int {
        guard total > 0 else { return unlocked ? 0 : 0 }
        return Int((Double(found) / Double(total) * 100).rounded())
    }
}

struct TraitSnap: Identifiable, Hashable {
    var id: String
    var name: String
    var value: Double
}

struct ProfileSnapshot {
    var name: String
    var stage: String
    var adventures: Int
    var friendCode: String
    var streak: Int
    var longest: Int
    var ownedIDs: [String]
    var foundIDs: Set<String>
    var places: [PlaceSnap]
    var featuredID: String
    var traits: [TraitSnap]
    var joined: String
    var sparks: Int
    var careDays: Int
    var energy: Int
    var energyGoal: Int

    var featured: PlaceSnap? { places.first { $0.id == featuredID } ?? places.first { $0.unlocked } ?? places.first }

    var foundCount: Int { foundIDs.count }
    var dexTotal: Int { ProfileDex.entries.count }

    func found(_ id: String) -> Bool { foundIDs.contains(id) }

    static func make(engine: GoobyEngine) -> ProfileSnapshot {
        let stageKey = "profile.stage.\(Growth.stage(of: engine.pet))"
        let ownedOrdered = engine.all(MiniFriend.self)
            .sorted { $0.hatchedAt > $1.hatchedAt }
            .map(\.speciesID)
        var seen = Set<String>()
        let owned = ownedOrdered.filter { seen.insert($0).inserted }
        let ownedSet = Set(owned)
        let discoveryRows = engine.all(DiscoveryRecord.self)
        let discoveryTotal = discoveryRows.count
        let care = engine.pet.careDays
        let trips = max(engine.all(AdventureRun.self).count, engine.pet.adventureDays)
        let sparks = engine.wallet.lifetimeSparksEarned
        var found = ownedSet
        for entry in ProfileDex.entries where !entry.catalog {
            let ready = (entry.careDays == 0 || care >= entry.careDays)
                && (entry.adventureDays == 0 || trips >= entry.adventureDays)
                && (entry.sparks == 0 || sparks >= entry.sparks)
                && (entry.discoveries == 0 || discoveryTotal >= entry.discoveries)
            if ready { found.insert(entry.id) }
        }
        let byPlace = Dictionary(grouping: discoveryRows, by: \.placeID)
        let places = engine.catalog.places.map { place in
            PlaceSnap(
                id: place.id,
                name: place.name.text(engine.languageCode),
                found: byPlace[place.id]?.count ?? 0,
                total: place.discoveries.count,
                unlocked: engine.isPlaceUnlocked(place.id),
                skyTop: place.skyTop,
                skyBottom: place.skyBottom,
                accent: place.accent
            )
        }
        let latest = engine.all(AdventureRun.self).sorted { $0.startedAt > $1.startedAt }.first?.placeID
        let featured = latest.flatMap { id in places.first { $0.id == id }?.id } ?? places.first { $0.unlocked }?.id ?? places.first?.id ?? ""
        let traits = [
            TraitSnap(id: "curiosity", name: engine.t("profile.trait.curiosity"), value: engine.pet.curiosity),
            TraitSnap(id: "courage", name: engine.t("profile.trait.courage"), value: engine.pet.courage),
            TraitSnap(id: "kindness", name: engine.t("profile.trait.kindness"), value: engine.pet.kindness),
            TraitSnap(id: "playfulness", name: engine.t("profile.trait.playfulness"), value: engine.pet.playfulness),
            TraitSnap(id: "confidence", name: engine.t("profile.trait.confidence"), value: engine.pet.confidence),
            TraitSnap(id: "calm", name: engine.t("profile.trait.calm"), value: engine.pet.calm),
            TraitSnap(id: "empathy", name: engine.t("profile.trait.empathy"), value: engine.pet.empathy)
        ]
        let current = engine.streak()
        let best = max(current, longestStreak(engine.all(HabitLog.self)))
        return ProfileSnapshot(
            name: engine.profile.goobyName.isEmpty ? "Gooby" : engine.profile.goobyName,
            stage: engine.t(stageKey),
            adventures: trips,
            friendCode: GoobyFriendCode.make(profileID: engine.profile.id),
            streak: current,
            longest: best,
            ownedIDs: owned,
            foundIDs: found,
            places: places,
            featuredID: featured,
            traits: traits,
            joined: engine.formatDate(engine.profile.createdAt),
            sparks: engine.wallet.sparks,
            careDays: care,
            energy: engine.wallet.energy,
            energyGoal: max(1, engine.profile.energyGoal)
        )
    }

    static func longestStreak(_ logs: [HabitLog]) -> Int {
        let days = Set(logs.filter { !$0.skipped && $0.count > 0 }.compactMap { DayKey.parse($0.dayKey) }).sorted()
        let calendar = Calendar.current
        var best = 0
        var run = 0
        var previous: Date?
        for day in days {
            if let previous, let next = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: previous)), calendar.isDate(day, inSameDayAs: next) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }
}
