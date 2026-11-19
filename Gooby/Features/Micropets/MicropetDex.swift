import Foundation

struct MicropetSpot: Identifiable, Hashable {
    var id: String
    var hatchable: Bool
    var careDays: Int = 0
    var adventureDays: Int = 0
    var sparks: Int = 0
    var discoveries: Int = 0
}

enum MicropetDex {
    static let spots: [MicropetSpot] = [
        MicropetSpot(id: "chick", hatchable: true),
        MicropetSpot(id: "cloud", hatchable: true),
        MicropetSpot(id: "dragon", hatchable: true),
        MicropetSpot(id: "fox", hatchable: true),
        MicropetSpot(id: "starling", hatchable: true),
        MicropetSpot(id: "penguin", hatchable: true),
        MicropetSpot(id: "bear", hatchable: true),
        MicropetSpot(id: "cat", hatchable: true),
        MicropetSpot(id: "ghost", hatchable: true),
        MicropetSpot(id: "unicorn", hatchable: true),
        MicropetSpot(id: "moon", hatchable: true),
        MicropetSpot(id: "mushroom", hatchable: true),
        MicropetSpot(id: "sprout", hatchable: false, careDays: 3),
        MicropetSpot(id: "lantern", hatchable: false, careDays: 7),
        MicropetSpot(id: "pebble", hatchable: false, adventureDays: 2),
        MicropetSpot(id: "kite", hatchable: false, adventureDays: 5),
        MicropetSpot(id: "teacup", hatchable: false, sparks: 20),
        MicropetSpot(id: "comet", hatchable: false, discoveries: 3)
    ]

    static func roster() -> [MicropetSpot] {
        var rows = spots
        let known = Set(spots.map(\.id))
        for friend in ContentCatalog.shared.friends where !known.contains(friend.id) {
            rows.append(MicropetSpot(id: friend.id, hatchable: true))
        }
        return rows
    }

    @MainActor
    static func foundIDs(_ engine: GoobyEngine) -> Set<String> {
        var found = Set(engine.all(MiniFriend.self).map(\.speciesID))
        let care = engine.pet.careDays
        let trips = max(engine.all(AdventureRun.self).count, engine.pet.adventureDays)
        let sparks = engine.wallet.lifetimeSparksEarned
        let discoveries = engine.all(DiscoveryRecord.self).count
        for spot in roster() where !spot.hatchable {
            let ready = (spot.careDays == 0 || care >= spot.careDays)
                && (spot.adventureDays == 0 || trips >= spot.adventureDays)
                && (spot.sparks == 0 || sparks >= spot.sparks)
                && (spot.discoveries == 0 || discoveries >= spot.discoveries)
            if ready { found.insert(spot.id) }
        }
        return found
    }

    @MainActor
    static func title(_ engine: GoobyEngine, id: String, found: Bool) -> String {
        guard found else { return engine.t("micropets.locked") }
        if let friend = engine.catalog.friendsByID[id] {
            let name = friend.name.text(engine.languageCode)
            if !name.isEmpty { return name }
        }
        let key = "micropets.dex.\(id)"
        let local = engine.t(key)
        return local == key ? id : local
    }

    @MainActor
    static func blurb(_ engine: GoobyEngine, id: String, found: Bool) -> String {
        guard found else { return engine.t("micropets.locked") }
        if let friend = engine.catalog.friendsByID[id] {
            let text = friend.blurb.text(engine.languageCode)
            if !text.isEmpty { return text }
        }
        let key = "micropets.dex.\(id).blurb"
        let local = engine.t(key)
        return local == key ? engine.t("micropets.found") : local
    }

    @MainActor
    static func rarity(_ engine: GoobyEngine, id: String, found: Bool) -> String {
        guard found, let friend = engine.catalog.friendsByID[id], !friend.rarity.isEmpty else { return "" }
        return engine.t("rarity.\(friend.rarity)")
    }
}
