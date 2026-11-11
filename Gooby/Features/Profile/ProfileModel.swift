import SwiftUI

enum ProfilePalette {
    static var page: Color { Paint.pick(0xE5D7AA) { $0.profile } }
    static var card: Color { Paint.pick(0xFFFFFF) { $0.card } }
    static var well: Color { Paint.pick(0xFEF8EA) { $0.soft($0.profile, 0.75) } }
    static var ink: Color { Paint.pick(0x313131) { $0.ink } }
    static var brown: Color { Paint.pick(0x645737) { $0.profileInk } }
    static var brownSoft: Color { Paint.pick(0x8C7150) { HexMix.mix($0.profileInk, $0.profile, 0.25) } }
    static var muted: Color { Paint.pick(0x94846A) { HexMix.mix($0.profileInk, $0.card, 0.4) } }
    static let tabBand = Color(hex: 0xF9F5E2)
    static let gold = Color(hex: 0xC0A966)
    static let banner = Color(hex: 0xE3A31B)
    static let bannerDeep = Color(hex: 0xC98A12)
    static let clip = Color(hex: 0xAF7E56)
    static let ring = Color(hex: 0xC48758)
    static var headerFill: Color { Paint.pick(0xFBEECE) { $0.soft($0.profile, 0.55) } }
    static var headerIcon: Color { Paint.pick(0x7F6A35) { $0.profileInk } }
    static var paper: Color { Paint.pick(0xFEF5EE) { $0.soft($0.profile, 0.85) } }
    static var seeAll: Color { Paint.pick(0xF3E7CD) { $0.soft($0.profile, 0.45) } }
    static var cell: Color { Paint.pick(0xF3E6CC) { $0.soft($0.profile, 0.45) } }
    static var quietTile: Color { Paint.pick(0xF4EBE3) { $0.soft($0.profile, 0.6) } }
    static var silhouette: Color { Paint.pick(0xD2C4A4) { HexMix.mix($0.profile, $0.profileInk, 0.22) } }
    static var question: Color { Paint.pick(0xE0D3C6) { HexMix.mix($0.soft($0.profile, 0.45), $0.profileInk, 0.15) } }
    static let sun = Color(hex: 0xFDD35B)
    static let sunHot = Color(hex: 0xFB8F5E)
    static let leaf = Color(hex: 0x3F9A48)
    static let binder = Color(hex: 0xAF7E56)
    static let tileDark = Color(hex: 0x4E4E4E)
    static var tabPill: Color { Paint.pick(0xF7EAC7) { $0.soft($0.profile, 0.5) } }
    static var tabIdle: Color { Paint.pick(0xC9BBA0) { HexMix.mix($0.profile, $0.profileInk, 0.32) } }
    static var shadow: Color { Paint.shadow(0x8A6A3A, 0.12) }
    static var postmark: Color { Paint.pick(0xE7C4A4) { HexMix.mix($0.profile, $0.profileInk, 0.18) } }
    static var doodle: Color { Paint.pick(0xE4CFA8) { HexMix.mix($0.profile, $0.profileInk, 0.1) } }
    static var chevronWash: Color { Paint.pick(0xF4EFE6) { $0.well } }
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
    var visits: Int = 0
    var seasonal: Bool = false
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
    var pronounsLine: String
    var ageText: String
    var friendship: String
    var humanName: String
    var weightText: String
    var heightText: String
    var spanText: String
    var about: String
    var travelLocked: Bool

    var featured: PlaceSnap? { places.first { $0.id == featuredID } ?? places.first { $0.unlocked } ?? places.first }

    var hexTraits: [TraitSnap] {
        ProfilePassport.hexTraitIDs.compactMap { id in traits.first { $0.id == id } }
    }

    var forestFound: Int { places.filter { $0.visits > 0 }.count }
    var forestTotal: Int { places.count }
    var locationsFound: Int { places.filter(\.unlocked).count }

    var previewPetIDs: [String] {
        var ordered: [String] = []
        for id in ownedIDs where ProfileDex.entries.contains(where: { $0.id == id }) && !ordered.contains(id) {
            ordered.append(id)
        }
        for entry in ProfileDex.entries where found(entry.id) && !ordered.contains(entry.id) {
            ordered.append(entry.id)
        }
        for entry in ProfileDex.entries where !found(entry.id) {
            ordered.append(entry.id)
        }
        return Array(ordered.prefix(3))
    }

    var foundCount: Int { foundIDs.count }
    var dexTotal: Int { ProfileDex.entries.count }

    func found(_ id: String) -> Bool { foundIDs.contains(id) }

    @MainActor
    static func make(engine: GoobyEngine) -> ProfileSnapshot {
        let stageID = Growth.stage(of: engine.pet)
        let stageKey = "profile.stage.\(stageID)"
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
        var visitsByID: [String: Int] = [:]
        for row in engine.all(PlaceProgress.self) {
            visitsByID[row.placeID] = row.visits
        }
        let seasonal = ProfilePassport.seasonalIDs(places: engine.catalog.places, events: engine.catalog.events)
        let places = engine.catalog.places.map { place in
            PlaceSnap(
                id: place.id,
                name: place.name.text(engine.languageCode),
                found: byPlace[place.id]?.count ?? 0,
                total: place.discoveries.count,
                unlocked: engine.isPlaceUnlocked(place.id),
                visits: visitsByID[place.id] ?? 0,
                seasonal: seasonal.contains(place.id),
                skyTop: place.skyTop,
                skyBottom: place.skyBottom,
                accent: place.accent
            )
        }
        let age = ProfilePassport.ageDays(from: engine.profile.createdAt, to: engine.now())
        let measures = ProfilePassport.body(ageDays: age, fullEnergyDays: engine.pet.fullEnergyDays)
        let human = engine.profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
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
            energyGoal: max(1, engine.profile.energyGoal),
            pronounsLine: ProfileCopy.pronounsLine(engine.pet.pronouns, language: engine.languageCode),
            ageText: ProfileCopy.ageText(days: age, language: engine.languageCode),
            friendship: ProfilePassport.friendship(affection: engine.pet.affection, language: engine.languageCode),
            humanName: human,
            weightText: ProfilePassport.measure(measures.grams, unit: "g", language: engine.languageCode),
            heightText: ProfilePassport.measure(measures.heightCM, unit: "cm", language: engine.languageCode),
            spanText: ProfilePassport.measure(measures.spanCM, unit: "cm", language: engine.languageCode),
            about: ProfileCopy.about(stageKey: stageID, language: engine.languageCode),
            travelLocked: ProfilePassport.travelLocked(ageDays: age)
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
