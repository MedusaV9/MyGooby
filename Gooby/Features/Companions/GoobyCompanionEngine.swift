import Foundation

enum GoobyCompanionEngine {
    static let activeEggCap = 12

    @discardableResult
    static func bindEgg(
        save: inout GoobyEventsSave,
        habit: GoobyHabitLink,
        day: String
    ) -> GoobyEggRecord? {
        let habitID = habit.id.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = habit.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !habitID.isEmpty, !title.isEmpty else {
            return nil
        }
        let active = save.eggs.filter { $0.hatchedCompanionID == nil }.count
        guard active < activeEggCap else {
            return nil
        }
        let eggID = UUID().uuidString
        let egg = GoobyEggRecord(
            id: eggID,
            habitID: habitID,
            habitTitle: String(title.prefix(40)),
            boundDay: day,
            validDays: [],
            rollSeed: GoobySeededGenerator.mix(save.seed, GoobySeededGenerator.hash(eggID)),
            hatchedCompanionID: nil
        )
        save.eggs.append(egg)
        save.eggsEverBound += 1
        save.log("Ei gebunden: \(egg.habitTitle)")
        return egg
    }

    static func recordHabit(
        save: inout GoobyEventsSave,
        habitID: String,
        day: String,
        libraries: GoobyEventsLibraries
    ) -> [GoobyRewardGrant] {
        var grants: [GoobyRewardGrant] = []
        for index in save.eggs.indices {
            guard save.eggs[index].hatchedCompanionID == nil else {
                continue
            }
            guard save.eggs[index].habitID == habitID else {
                continue
            }
            guard day >= save.eggs[index].boundDay else {
                continue
            }
            guard !save.eggs[index].validDays.contains(day) else {
                continue
            }
            save.eggs[index].validDays.append(day)
            save.eggs[index].validDays.sort()
            if save.eggs[index].validDays.count >= GoobyCompanionGrowth.requiredEggDays {
                if let grant = hatch(save: &save, eggIndex: index, day: day, libraries: libraries) {
                    grants.append(grant)
                }
            }
        }
        return grants
    }

    @discardableResult
    static func forceHatch(
        save: inout GoobyEventsSave,
        eggID: String,
        day: String,
        libraries: GoobyEventsLibraries
    ) -> GoobyCompanionRecord? {
        guard let index = save.eggs.firstIndex(where: { $0.id == eggID }) else {
            return nil
        }
        if let existing = save.eggs[index].hatchedCompanionID {
            return save.companions.first { $0.id == existing }
        }
        while save.eggs[index].validDays.count < GoobyCompanionGrowth.requiredEggDays {
            let filler = String(format: "debug-day-%02d", save.eggs[index].validDays.count + 1)
            save.eggs[index].validDays.append(filler)
        }
        _ = hatch(save: &save, eggIndex: index, day: day, libraries: libraries)
        guard let companionID = save.eggs[index].hatchedCompanionID else {
            return nil
        }
        return save.companions.first { $0.id == companionID }
    }

    @discardableResult
    static func addCompanion(
        save: inout GoobyEventsSave,
        speciesID: String,
        day: String,
        origin: String,
        libraries: GoobyEventsLibraries
    ) -> GoobyCompanionRecord? {
        guard libraries.species(speciesID) != nil else {
            return nil
        }
        guard save.companions.count < 200 else {
            return nil
        }
        let record = GoobyCompanionRecord(
            id: UUID().uuidString,
            speciesID: speciesID,
            customName: nil,
            hatchedDay: day,
            playDays: [],
            playCount: 0,
            origin: origin
        )
        save.companions.append(record)
        if origin == "egg" || origin == "event" {
            save.companionsHatchedEver += 1
            save.pendingHatchIDs.append(record.id)
        }
        if !save.speciesHatched.contains(speciesID) {
            save.speciesHatched.append(speciesID)
        }
        if save.selectedCompanionID == nil {
            save.selectedCompanionID = record.id
        }
        return record
    }

    static func unlockMissing(
        save: inout GoobyEventsSave,
        day: String,
        libraries: GoobyEventsLibraries
    ) -> [GoobyCompanionRecord] {
        var created: [GoobyCompanionRecord] = []
        for species in libraries.species where !save.companions.contains(where: { $0.speciesID == species.id }) {
            if let record = addCompanion(save: &save, speciesID: species.id, day: day, origin: "debug", libraries: libraries) {
                created.append(record)
            }
        }
        if !created.isEmpty {
            save.log("Mini-Freunde ergänzt: \(created.count)")
        }
        return created
    }

    @discardableResult
    static func play(
        save: inout GoobyEventsSave,
        companionID: String,
        day: String
    ) -> Bool {
        guard let index = save.companions.firstIndex(where: { $0.id == companionID }) else {
            return false
        }
        guard !save.companions[index].playDays.contains(day) else {
            return false
        }
        save.companions[index].playDays.append(day)
        save.companions[index].playCount += 1
        save.companionPlayTotal += 1
        return true
    }

    static func select(save: inout GoobyEventsSave, companionID: String?) {
        if let companionID {
            guard save.companions.contains(where: { $0.id == companionID }) else {
                return
            }
            save.selectedCompanionID = companionID
        } else {
            save.selectedCompanionID = nil
        }
    }

    static func rename(save: inout GoobyEventsSave, companionID: String, name: String) {
        guard let index = save.companions.firstIndex(where: { $0.id == companionID }) else {
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        save.companions[index].customName = trimmed.isEmpty ? nil : String(trimmed.prefix(24))
    }

    static func dismissHatch(save: inout GoobyEventsSave, companionID: String) {
        save.pendingHatchIDs.removeAll { $0 == companionID }
    }

    static func reset(save: inout GoobyEventsSave) {
        save.eggs = []
        save.companions = []
        save.selectedCompanionID = nil
        save.pendingHatchIDs = []
        save.log("Mini-Freunde zurückgesetzt")
    }

    static func pickSpecies(seed: UInt64, pool: [GoobyCompanionSpeciesDefinition]) -> GoobyCompanionSpeciesDefinition? {
        guard !pool.isEmpty else {
            return nil
        }
        let total = pool.reduce(0) { $0 + GoobyCompanionGrowth.rarityWeight($1.rarity) }
        guard total > 0 else {
            return pool[0]
        }
        var generator = GoobySeededGenerator(state: seed == 0 ? 0xA5A5_A5A5_A5A5_A5A5 : seed)
        var roll = Int(generator.next() % UInt64(total))
        for species in pool {
            roll -= GoobyCompanionGrowth.rarityWeight(species.rarity)
            if roll < 0 {
                return species
            }
        }
        return pool[pool.count - 1]
    }

    private static func hatch(
        save: inout GoobyEventsSave,
        eggIndex: Int,
        day: String,
        libraries: GoobyEventsLibraries
    ) -> GoobyRewardGrant? {
        let egg = save.eggs[eggIndex]
        guard egg.hatchedCompanionID == nil else {
            return nil
        }
        let material = egg.rollSeed ^ GoobySeededGenerator.hash(egg.validDays.joined(separator: "|"))
        guard let species = pickSpecies(seed: material, pool: libraries.eggPool) else {
            return nil
        }
        guard let record = addCompanion(save: &save, speciesID: species.id, day: day, origin: "egg", libraries: libraries) else {
            return nil
        }
        if let index = save.eggs.firstIndex(where: { $0.id == egg.id }) {
            save.eggs[index].hatchedCompanionID = record.id
        }
        save.log("Geschlüpft: \(species.nameDE)")
        return GoobyRewardGrant.make(
            id: "hatch|\(record.id)",
            source: "companion",
            starSparks: 0,
            companionSpeciesID: species.id,
            titleDE: species.nameDE,
            titleEN: species.nameEN,
            dayKey: day
        )
    }
}
