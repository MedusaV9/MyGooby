import Foundation

extension GoobyEngine {
    func placeProgress(_ id: String) -> PlaceProgress? {
        all(PlaceProgress.self).first { $0.placeID == id }
    }

    func isPlaceUnlocked(_ id: String) -> Bool { placeProgress(id)?.unlocked == true }

    func ensureWorld() {
        for place in catalog.places where placeProgress(place.id) == nil {
            let row = PlaceProgress()
            row.placeID = place.id
            row.unlocked = place.unlockAfterAdventures == 0
            context.insert(row)
        }
        ensureMilestones()
        ensureDailyQuests(dayKey())
    }

    func unlockPlacesIfEarned() {
        let done = all(AdventureRun.self).filter { $0.status == "claimed" }.count
        for place in catalog.places where done >= place.unlockAfterAdventures {
            placeProgress(place.id)?.unlocked = true
        }
    }

    /// Finch pace for the first outing of a day. Place durations stay on the place itself.
    static let dailyTripSeconds: TimeInterval = 8 * 60 * 60

    func todaysRun() -> AdventureRun? {
        let key = dayKey()
        return all(AdventureRun.self).first { $0.dayKey == key }
    }

    func syncRuns() {
        var changed = false
        for run in all(AdventureRun.self) where run.status == "traveling" && now() >= run.returnsAt {
            run.status = "ready"
            changed = true
        }
        if changed { animation = .arrive }
    }

    func startAdventure(placeID: String) -> String? {
        refreshDay()
        if todaysRun() != nil { return "adventure.already" }
        if wallet.energy < profile.energyGoal { return "adventure.needEnergy" }
        guard catalog.placesByID[placeID] != nil, isPlaceUnlocked(placeID) else { return "adventure.locked" }
        guard let story = pickStory(placeID: placeID) else { return "error.missing" }
        let run = AdventureRun()
        run.placeID = placeID
        run.storyID = story.id
        run.startedAt = now()
        // The day's outing is eight hours. The place still picks the story behind the question mark.
        run.returnsAt = now().addingTimeInterval(Self.dailyTripSeconds)
        run.status = "traveling"
        run.dayKey = dayKey()
        context.insert(run)
        animation = .depart
        save()
        rescheduleNotifications()
        return nil
    }

    func pickStory(placeID: String) -> StoryDef? {
        let pool = catalog.stories.filter { $0.placeID == placeID }
        guard !pool.isEmpty else { return nil }
        let recent = Set(pet.recentStoryIDs)
        let fresh = pool.filter { !recent.contains($0.id) }
        let choices = fresh.isEmpty ? pool : fresh
        let ids = ShopRotation.orderedIDs(choices.map(\.id), dayKey: dayKey(), category: "story-\(placeID)", appSeed: profile.appSeed)
        return catalog.storiesByID[ids.first ?? choices[0].id]
    }

    func choose(run: AdventureRun, choice: StoryChoice) {
        guard run.choiceID.isEmpty else { return }
        if run.status == "traveling" && now() >= run.returnsAt { run.status = "ready" }
        guard run.status == "ready" else { return }
        let stageBefore = Growth.stage(of: pet)
        run.status = "claimed"
        run.choiceID = choice.id
        run.claimedAt = now()
        run.rewardSparks = max(0, choice.sparks)
        run.discoveryID = choice.discoveryID
        Personality.apply(pet, deltas: choice.deltas)
        _ = grant(key: "adventure:\(run.id.uuidString)", sparks: max(0, choice.sparks), energy: 0)
        if !choice.discoveryID.isEmpty && !all(DiscoveryRecord.self).contains(where: { $0.discoveryID == choice.discoveryID }) {
            let found = DiscoveryRecord()
            found.discoveryID = choice.discoveryID
            found.placeID = run.placeID
            found.foundAt = now()
            context.insert(found)
        }
        pet.adventureDays += 1
        var recent = pet.recentStoryIDs
        recent.append(run.storyID)
        if recent.count > 16 { recent = Array(recent.suffix(16)) }
        pet.recentStoryIDs = recent
        placeProgress(run.placeID)?.visits += 1
        unlockPlacesIfEarned()
        animation = .arrive
        celebration += 1
        recomputeQuests()
        save()
        cueProgress(stageBefore: stageBefore, otherwise: .gift, countGoals: false)
    }

    func completeAdventureNow() -> String? {
        syncRuns()
        guard let run = all(AdventureRun.self).first(where: { $0.status == "traveling" }) else { return "dev.noAdventure" }
        run.returnsAt = now()
        run.status = "ready"
        animation = .arrive
        save()
        return nil
    }

    func wornLook(preview: ItemDef? = nil) -> WornLook {
        var slots: [String: ItemDef] = [:]
        for row in all(OwnedItem.self) where !row.equippedSlot.isEmpty {
            if let item = catalog.itemsByID[row.catalogID] { slots[row.equippedSlot] = item }
        }
        var fur = pet.furStyle
        if let preview {
            if preview.kind == "color" || preview.slot == "fur" {
                fur = preview.id
            } else {
                slots[preview.slot] = preview
            }
        }
        return WornLook(fur: fur, slots: slots)
    }

    func dailyOfferIDs(shop: String) -> [String] {
        let pool: [ItemDef]
        if shop == "seasonal" {
            pool = catalog.items.filter { !$0.seasonalEvent.isEmpty && !$0.starter }
        } else {
            pool = catalog.items.filter { $0.shop == shop && $0.seasonalEvent.isEmpty && !$0.starter }
        }
        let ordered = ShopRotation.orderedIDs(pool.map(\.id), dayKey: dayKey(), category: shop, appSeed: profile.appSeed)
        return Array(ordered.prefix(4))
    }

    func price(of item: ItemDef) -> Int {
        let offer = dailyOfferIDs(shop: item.shop == "" ? "seasonal" : item.shop)
        if offer.contains(item.id) { return max(1, item.price * 85 / 100) }
        return max(0, item.price)
    }

    func isEventActive(_ id: String) -> Bool {
        guard let event = catalog.events.first(where: { $0.id == id }) else { return false }
        if all(EventRecord.self).first(where: { $0.eventID == id })?.forced == true { return true }
        return EventWindow.contains(now(), startMonth: event.startMonth, startDay: event.startDay, endMonth: event.endMonth, endDay: event.endDay)
    }

    func buy(_ item: ItemDef) -> String? {
        if owns(item.id) { return cueFailure("shop.owned") }
        if !item.seasonalEvent.isEmpty && !isEventActive(item.seasonalEvent) { return cueFailure("shop.season") }
        let cost = price(of: item)
        guard wallet.sparks >= cost else { return cueFailure("shop.poor") }
        wallet.sparks -= cost
        wallet.lifetimeSparksSpent += cost
        let row = OwnedItem()
        row.catalogID = item.id
        row.kind = item.kind
        row.acquiredAt = now()
        context.insert(row)
        if item.kind == "travel" {
            let placeID = String(item.id.dropFirst("ticket-".count))
            placeProgress(placeID)?.unlocked = true
        }
        recomputeQuests()
        save()
        cue(.purchase)
        return nil
    }

    func sell(_ item: ItemDef) -> String? {
        guard let row = ownedRow(item.id) else { return cueFailure("shop.missing") }
        if item.starter { return cueFailure("shop.starter") }
        if !row.equippedSlot.isEmpty { return cueFailure("shop.equipped") }
        wallet.sparks += max(0, item.price / 2)
        context.delete(row)
        save()
        cue(.coins)
        return nil
    }

    func equip(_ item: ItemDef) {
        guard let row = ownedRow(item.id) else { return }
        if item.kind == "color" || item.slot == "fur" {
            pet.furStyle = item.id
            for other in all(OwnedItem.self) where other.equippedSlot == "fur" { other.equippedSlot = "" }
            row.equippedSlot = "fur"
            animation = .present
            save()
            cue(.select)
            return
        }
        for other in all(OwnedItem.self) where other.equippedSlot == item.slot { other.equippedSlot = "" }
        row.equippedSlot = item.slot
        if item.kind == "furniture" { setRoomSlot(item.slot, item.id) }
        animation = .present
        save()
        cue(.select)
    }

    func unequip(slot: String) {
        for row in all(OwnedItem.self) where row.equippedSlot == slot { row.equippedSlot = "" }
        if slot != "fur" { setRoomSlot(slot, "") }
        save()
    }

    func setRoomSlot(_ slot: String, _ id: String) {
        switch slot {
        case "wall": room.wall = id
        case "floor": room.floor = id
        case "bed": room.bed = id
        case "rug": room.rug = id
        case "lamp": room.lamp = id
        case "window": room.windowItem = id
        case "plant": room.plant = id
        case "shelf": room.shelf = id
        case "picture": room.picture = id
        case "sofa": room.sofa = id
        case "table": room.tableItem = id
        case "cushion": room.cushion = id
        case "seasonal": room.seasonal = id
        default: break
        }
    }

    func roomItem(_ slot: String) -> String {
        switch slot {
        case "wall": return room.wall
        case "floor": return room.floor
        case "bed": return room.bed
        case "rug": return room.rug
        case "lamp": return room.lamp
        case "window": return room.windowItem
        case "plant": return room.plant
        case "shelf": return room.shelf
        case "picture": return room.picture
        case "sofa": return room.sofa
        case "table": return room.tableItem
        case "cushion": return room.cushion
        case "seasonal": return room.seasonal
        default: return ""
        }
    }

    func saveOutfit(name: String) {
        var map: [String: String] = [:]
        for row in all(OwnedItem.self) where !row.equippedSlot.isEmpty {
            map[row.equippedSlot] = row.catalogID
        }
        map["fur"] = pet.furStyle
        let outfit = SavedOutfit()
        outfit.name = name.isEmpty ? t("wardrobe.outfit") : name
        outfit.slotsJSON = (try? String(data: JSONEncoder().encode(map), encoding: .utf8)) ?? "{}"
        outfit.createdAt = now()
        context.insert(outfit)
        save()
    }

    func apply(outfit: SavedOutfit) {
        guard let data = outfit.slotsJSON.data(using: .utf8),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else { return }
        for row in all(OwnedItem.self) { row.equippedSlot = "" }
        for (slot, id) in map {
            if slot == "fur" {
                if owns(id) { pet.furStyle = id }
                continue
            }
            if let row = ownedRow(id) {
                row.equippedSlot = slot
                if catalog.itemsByID[id]?.kind == "furniture" { setRoomSlot(slot, id) }
            }
        }
        animation = .present
        save()
        cue(.select)
    }

    func toggleFavoriteItem(_ id: String) {
        guard let row = ownedRow(id) else { return }
        row.favorite.toggle()
        save()
    }

    func toggleFavoriteOutfit(_ outfit: SavedOutfit) {
        outfit.favorite.toggle()
        save()
    }
}

extension GoobyEngine {
    func activeEgg(for habitID: UUID) -> EggBinding? {
        all(EggBinding.self).first { $0.habitID == habitID && !$0.hatched }
    }

    func bindEgg(to habit: Habit) {
        guard activeEgg(for: habit.id) == nil else { return }
        let egg = EggBinding()
        egg.habitID = habit.id
        egg.requiredCount = 7
        egg.createdAt = now()
        context.insert(egg)
        save()
    }

    func advanceEgg(for habit: Habit) {
        guard let egg = activeEgg(for: habit.id) else { return }
        egg.progress += 1
        if egg.progress >= max(7, egg.requiredCount) { hatch(egg) }
    }

    func hatch(_ egg: EggBinding) {
        let species = pickSpecies()
        let friend = MiniFriend()
        friend.speciesID = species.id
        friend.givenName = species.name.text(languageCode)
        friend.rarity = species.rarity
        friend.hatchedAt = now()
        friend.isCompanion = !all(MiniFriend.self).contains { $0.isCompanion }
        context.insert(friend)
        egg.hatched = true
        egg.friendID = friend.id
        egg.progress = max(egg.progress, egg.requiredCount)
        animation = .play
        celebration += 1
        cue(.hatch)
    }

    func pickSpecies() -> FriendDef {
        let pool = catalog.friends
        guard !pool.isEmpty else {
            return FriendDef(id: "cloud", name: LocText(de: "Wölkchen", en: "Little Cloud"), rarity: "common", weight: 1, blurb: LocText(de: "", en: ""))
        }
        let total = pool.reduce(0) { $0 + max(1, $1.weight) }
        var rng = SeededRNG(state: UInt64(bitPattern: profile.appSeed) ^ UInt64(now().timeIntervalSince1970))
        var roll = rng.int(max(1, total))
        for friend in pool {
            roll -= max(1, friend.weight)
            if roll < 0 { return friend }
        }
        return pool[0]
    }

    func setCompanion(_ friend: MiniFriend) {
        for other in all(MiniFriend.self) { other.isCompanion = false }
        friend.isCompanion = true
        animation = .play
        save()
        cue(.giggle)
    }

    func companionSpecies() -> String? { all(MiniFriend.self).first { $0.isCompanion }?.speciesID }

    func addMood(level: Int, tags: [String], note: String) {
        let entry = MoodEntry()
        entry.level = min(5, max(1, level))
        entry.tags = tags
        entry.note = note
        entry.recordedAt = now()
        entry.dayKey = dayKey()
        context.insert(entry)
        recomputeQuests()
        save()
        cue(.save)
    }

    func deleteMood(_ entry: MoodEntry) {
        context.delete(entry)
        save()
    }

    @discardableResult
    func addJournal(title: String, body: String, tags: [String], promptID: String) -> JournalEntry {
        let entry = JournalEntry()
        entry.title = title
        entry.body = body
        entry.tags = tags
        entry.promptID = promptID
        entry.createdAt = now()
        entry.updatedAt = now()
        entry.dayKey = dayKey()
        context.insert(entry)
        recomputeQuests()
        save()
        if !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { cue(.save) }
        return entry
    }

    func updateJournal(_ entry: JournalEntry, title: String, body: String, tags: [String]) {
        entry.title = title
        entry.body = body
        entry.tags = tags
        entry.updatedAt = now()
        defer { cue(.save) }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let stat = dailyStat(entry.dayKey.isEmpty ? dayKey() : entry.dayKey)
            if stat.journalRewards < 3, grant(key: "journal:\(entry.id.uuidString)", sparks: 3, energy: 5) {
                stat.journalRewards += 1
            }
        }
        recomputeQuests()
        save()
    }

    func deleteJournal(_ entry: JournalEntry) {
        context.delete(entry)
        save()
    }

    func finishBreath() {
        let stat = dailyStat(dayKey())
        stat.breathSessions += 1
        if stat.breathSessions <= 4 {
            _ = grant(key: "breath:\(UUID().uuidString)", sparks: 2, energy: 3)
        }
        recomputeQuests()
        animation = .breathe
        save()
        cue(.calm)
    }

    func finishMovement(_ id: String) {
        if grant(key: "move:\(id):\(dayKey())", sparks: 2, energy: 4) {
            dailyStat(dayKey()).movementSessions += 1
            recomputeQuests()
            celebration += 1
            cue(.coins)
        }
        save()
    }

    func petAction(_ next: GoobyAnimation) {
        animation = next
        pet.affection += 1
        _ = grant(key: "pet:\(dayKey())", sparks: 1, energy: 0)
        dailyStat(dayKey()).petActions += 1
        recomputeQuests()
        save()
        cue(next == .laugh ? .giggle : .boop)
    }

    func dailyStat(_ key: String) -> DailyStat {
        if let found = all(DailyStat.self).first(where: { $0.dayKey == key }) { return found }
        let row = DailyStat()
        row.dayKey = key
        context.insert(row)
        return row
    }
}
