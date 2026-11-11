import CryptoKit
import Foundation

extension GoobyEngine {
    func rescheduleNotifications() {
        guard profile.notificationsEnabled else { return }
        let title = profile.goobyName
        var reminders: [ReminderPlan] = []
        for habit in habits() where !habit.isArchived && !habit.isPaused && habit.reminderHour >= 0 {
            reminders.append(ReminderPlan(
                id: habit.id.uuidString,
                title: title,
                body: tf("notify.habit", habit.title),
                hour: habit.reminderHour,
                minute: habit.reminderMinute,
                weekdays: habit.recurrence == "weekdays" || habit.recurrence == "custom" ? habit.weekdays : []
            ))
        }
        var notices: [TimedNotice] = []
        if let run = all(AdventureRun.self).first(where: { $0.status == "traveling" }) {
            let seconds = run.returnsAt.timeIntervalSince(now())
            notices.append(TimedNotice(id: "adventure-\(run.id.uuidString)", title: title, body: GoobyAlerts.returnNotice(name: title, languageCode: languageCode), seconds: seconds))
        }
        let calendar = Calendar.current
        for event in catalog.events {
            guard let fire = nextEventFire(event, calendar: calendar) else { continue }
            let seconds = fire.timeIntervalSince(Date())
            guard seconds > 60, seconds < 21 * 24 * 3600 else { continue }
            notices.append(TimedNotice(id: "event-\(event.id)", title: title, body: tf("notify.event", event.title.text(languageCode)), seconds: seconds))
        }
        Task { await GoobyAlerts.sync(reminders: reminders, notices: notices) }
    }

    private func nextEventFire(_ event: EventDef, calendar: Calendar) -> Date? {
        let bounds = eventBounds(event)
        var parts = calendar.dateComponents([.year, .month, .day], from: bounds.0)
        parts.hour = 10
        parts.minute = 0
        return calendar.date(from: parts)
    }

    func applyStoryTest(_ story: StoryDef, _ choice: StoryChoice) {
        let key = "dev-story:\(story.id):\(choice.id)"
        guard !all(RewardLedger.self).contains(where: { $0.key == key }) else { return }
        Personality.apply(pet, deltas: choice.deltas)
        let row = RewardLedger()
        row.key = key
        row.createdAt = now()
        context.insert(row)
        save()
    }

    func testReward(sparks: Int) {
        _ = grant(key: "dev-reward:\(UUID().uuidString)", sparks: max(0, sparks), energy: 0)
        save()
    }

    func setStage(_ raw: String) {
        pet.stageOverride = raw
        save()
    }

    func setPersonality(_ key: String, _ value: Double) {
        Personality.set(pet, key, value)
        save()
    }

    func simulateGrowth() {
        pet.stageOverride = ""
        pet.adventureDays += 5
        pet.careDays += 3
        save()
    }

    func unlockAllItems() {
        for item in catalog.items where !item.starter && item.kind != "travel" && !owns(item.id) {
            let row = OwnedItem()
            row.catalogID = item.id
            row.kind = item.kind
            row.acquiredAt = now()
            context.insert(row)
        }
        save()
    }

    func unlockAllPlaces() {
        for place in catalog.places { placeProgress(place.id)?.unlocked = true }
        save()
    }

    func unlockAllFriends() {
        let have = Set(all(MiniFriend.self).map(\.speciesID))
        var created: [MiniFriend] = []
        for species in catalog.friends where !have.contains(species.id) {
            let friend = MiniFriend()
            friend.speciesID = species.id
            friend.givenName = species.name.text(languageCode)
            friend.rarity = species.rarity
            friend.hatchedAt = now()
            context.insert(friend)
            created.append(friend)
        }
        if !all(MiniFriend.self).contains(where: { $0.isCompanion }), let first = created.first ?? all(MiniFriend.self).first {
            first.isCompanion = true
        }
        save()
    }

    func resetHabits() {
        for row in all(HabitLog.self) { context.delete(row) }
        for row in all(Habit.self) { context.delete(row) }
        for row in all(EggBinding.self) where !row.hatched { context.delete(row) }
        save()
        rescheduleNotifications()
    }

    func resetInventory() {
        for row in all(OwnedItem.self) { context.delete(row) }
        for row in all(SavedOutfit.self) { context.delete(row) }
        pet.furStyle = "fur-cream"
        room.wall = "wall-cream"
        room.floor = "floor-blush"
        room.bed = "bed-cream"
        room.rug = "rug-cloud"
        room.lamp = "lamp-blossom"
        room.windowItem = "window-round"
        room.plant = "plant-sprout"
        room.shelf = ""
        room.picture = ""
        room.sofa = ""
        room.tableItem = ""
        room.cushion = "cushion-peach"
        room.seasonal = ""
        grantStarterItems()
        save()
    }

    func resetAdventures() {
        for row in all(AdventureRun.self) { context.delete(row) }
        for row in all(DiscoveryRecord.self) { context.delete(row) }
        pet.adventureDays = 0
        pet.recentStoryIDs = []
        for place in catalog.places {
            placeProgress(place.id)?.unlocked = place.unlockAfterAdventures == 0
            placeProgress(place.id)?.visits = 0
        }
        save()
    }

    func resetQuests() {
        for row in all(QuestRecord.self) { context.delete(row) }
        ensureMilestones()
        ensureDailyQuests(dayKey())
        recomputeQuests()
        save()
    }

    func resetEvents() {
        for row in all(EventRecord.self) { context.delete(row) }
        save()
    }

    func resetMoodJournal() {
        for row in all(MoodEntry.self) { context.delete(row) }
        for row in all(JournalEntry.self) { context.delete(row) }
        save()
    }

    func regenerateDailyQuests() {
        for row in all(QuestRecord.self) where row.kind == "daily" && row.dayKey == dayKey() && !row.claimed {
            context.delete(row)
        }
        ensureDailyQuests(dayKey())
        recomputeQuests()
        save()
    }

    func completeQuestNow(_ quest: QuestRecord) {
        quest.progress = max(quest.progress, quest.goal)
        _ = claimQuest(quest)
    }

    func resetAll() {
        sound.stop()
        all(HabitLog.self).forEach(context.delete)
        all(Habit.self).forEach(context.delete)
        all(RewardLedger.self).forEach(context.delete)
        all(AdventureRun.self).forEach(context.delete)
        all(OwnedItem.self).forEach(context.delete)
        all(SavedOutfit.self).forEach(context.delete)
        all(MoodEntry.self).forEach(context.delete)
        all(JournalEntry.self).forEach(context.delete)
        all(QuestRecord.self).forEach(context.delete)
        all(EventRecord.self).forEach(context.delete)
        all(MiniFriend.self).forEach(context.delete)
        all(EggBinding.self).forEach(context.delete)
        all(PlaceProgress.self).forEach(context.delete)
        all(DiscoveryRecord.self).forEach(context.delete)
        all(FocusSession.self).forEach(context.delete)
        all(DailyStat.self).forEach(context.delete)
        all(AppLogEntry.self).forEach(context.delete)
        all(RoomLayout.self).forEach(context.delete)
        all(GoobyPet.self).forEach(context.delete)
        all(Wallet.self).forEach(context.delete)
        all(PlayerProfile.self).forEach(context.delete)
        try? context.save()
        let created = PlayerProfile()
        created.appSeed = Int64.random(in: 1...9_000_000_000_000)
        created.languageCode = "de"
        created.goobyName = "Gooby"
        created.energyGoal = 12
        let nextWallet = Wallet()
        let nextPet = GoobyPet()
        let nextRoom = RoomLayout()
        context.insert(created)
        context.insert(nextWallet)
        context.insert(nextPet)
        context.insert(nextRoom)
        profile = created
        wallet = nextWallet
        pet = nextPet
        room = nextRoom
        languageCode = "de"
        reduceMotion = false
        animation = .idle
        grantStarterItems()
        ensureWorld()
        save()
        log("reset all")
    }

    func entityCounts() -> [(String, Int)] {
        [
            ("profile", all(PlayerProfile.self).count),
            ("habits", all(Habit.self).count),
            ("logs", all(HabitLog.self).count),
            ("ledger", all(RewardLedger.self).count),
            ("adventures", all(AdventureRun.self).count),
            ("items", all(OwnedItem.self).count),
            ("outfits", all(SavedOutfit.self).count),
            ("moods", all(MoodEntry.self).count),
            ("journal", all(JournalEntry.self).count),
            ("quests", all(QuestRecord.self).count),
            ("events", all(EventRecord.self).count),
            ("friends", all(MiniFriend.self).count),
            ("eggs", all(EggBinding.self).count),
            ("places", all(PlaceProgress.self).count),
            ("discoveries", all(DiscoveryRecord.self).count),
            ("focus", all(FocusSession.self).count)
        ]
    }

    func diagnostics() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        var lines = [
            "Gooby \(version) (\(build))",
            "language \(languageCode)",
            "real \(Date())",
            "app \(now())",
            "offset \(profile.timeOffset)",
            "sparks \(wallet.sparks)",
            "energy \(wallet.energy)/\(profile.energyGoal)",
            "storeBytes \(GoobyFiles.directorySize(GoobyFiles.supportDirectory()))",
            "seed \(profile.appSeed)",
            "onboarding \(profile.onboardingDone)",
            "stories \(catalog.stories.count)",
            "places \(catalog.places.count)",
            "items \(catalog.items.count)"
        ]
        for row in entityCounts() { lines.append("\(row.0) \(row.1)") }
        let logs = all(AppLogEntry.self).sorted { $0.at > $1.at }.prefix(40)
        for entry in logs { lines.append("\(entry.at) \(entry.message)") }
        return lines.joined(separator: "\n")
    }

    func versionString() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    func buildString() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    func exportData(password: String?) throws -> Data {
        let payload = try JSONSerialization.data(withJSONObject: snapshot(), options: [.prettyPrinted, .sortedKeys])
        if let password, !password.isEmpty {
            let key = SymmetricKey(data: Data(SHA256.hash(data: Data(password.utf8))))
            let sealed = try AES.GCM.seal(payload, using: key)
            let box: [String: String] = ["format": "gooby-aes", "payload": sealed.combined?.base64EncodedString() ?? ""]
            return try JSONSerialization.data(withJSONObject: box, options: [.prettyPrinted])
        }
        let box: [String: String] = ["format": "gooby-plain", "payload": payload.base64EncodedString()]
        return try JSONSerialization.data(withJSONObject: box, options: [.prettyPrinted])
    }

    func importData(_ data: Data, password: String?) throws {
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let format = root?["format"] as? String, let payloadText = root?["payload"] as? String, let raw = Data(base64Encoded: payloadText) else {
            throw BackupError.unreadable
        }
        let json: Data
        if format == "gooby-aes" {
            guard let password, !password.isEmpty else { throw BackupError.password }
            let key = SymmetricKey(data: Data(SHA256.hash(data: Data(password.utf8))))
            let box = try AES.GCM.SealedBox(combined: raw)
            json = try AES.GCM.open(box, using: key)
        } else {
            json = raw
        }
        guard let snapshot = try JSONSerialization.jsonObject(with: json) as? [String: Any] else { throw BackupError.unreadable }
        apply(snapshot)
    }

    private func snapshot() -> [String: Any] {
        var photo = ""
        if !profile.photoFilename.isEmpty {
            let url = GoobyFiles.supportDirectory().appendingPathComponent(profile.photoFilename)
            if let data = try? Data(contentsOf: url) { photo = data.base64EncodedString() }
        }
        return [
            "version": 1,
            "photo": photo,
            "profile": [
                "nickname": profile.nickname,
                "goobyName": profile.goobyName,
                "goals": profile.goals,
                "onboardingDone": profile.onboardingDone,
                "faceIDEnabled": profile.faceIDEnabled,
                "languageCode": profile.languageCode,
                "reduceMotion": profile.reduceMotion,
                "appSeed": String(profile.appSeed),
                "timeOffset": profile.timeOffset,
                "createdAt": profile.createdAt.timeIntervalSince1970,
                "notificationsEnabled": profile.notificationsEnabled,
                "energyGoal": profile.energyGoal
            ],
            "wallet": [
                "sparks": wallet.sparks,
                "energy": wallet.energy,
                "energyDayKey": wallet.energyDayKey,
                "lifetimeSparksEarned": wallet.lifetimeSparksEarned,
                "lifetimeSparksSpent": wallet.lifetimeSparksSpent
            ],
            "pet": [
                "curiosity": pet.curiosity, "courage": pet.courage, "kindness": pet.kindness,
                "playfulness": pet.playfulness, "confidence": pet.confidence, "calm": pet.calm, "empathy": pet.empathy,
                "stageOverride": pet.stageOverride, "adventureDays": pet.adventureDays, "careDays": pet.careDays,
                "lastCareDayKey": pet.lastCareDayKey, "affection": pet.affection, "furStyle": pet.furStyle,
                "recentStoryIDs": pet.recentStoryIDs
            ],
            "room": [
                "wall": room.wall, "floor": room.floor, "bed": room.bed, "rug": room.rug, "lamp": room.lamp,
                "windowItem": room.windowItem, "plant": room.plant, "shelf": room.shelf, "picture": room.picture,
                "sofa": room.sofa, "tableItem": room.tableItem, "cushion": room.cushion, "seasonal": room.seasonal
            ],
            "habits": habits().map { habit -> [String: Any] in
                [
                    "id": habit.id.uuidString, "title": habit.title, "details": habit.details, "icon": habit.icon,
                    "colorHex": habit.colorHex, "category": habit.category, "priority": habit.priority,
                    "startDate": habit.startDate.timeIntervalSince1970,
                    "endDate": habit.endDate?.timeIntervalSince1970 ?? -1,
                    "recurrence": habit.recurrence, "weekdays": habit.weekdays, "intervalDays": habit.intervalDays,
                    "timesPerDay": habit.timesPerDay, "reminderHour": habit.reminderHour, "reminderMinute": habit.reminderMinute,
                    "energyReward": habit.energyReward, "sparkReward": habit.sparkReward, "isDailyGoal": habit.isDailyGoal,
                    "isArchived": habit.isArchived, "isPaused": habit.isPaused, "movedFromKey": habit.movedFromKey,
                    "movedToKey": habit.movedToKey, "sortIndex": habit.sortIndex, "createdAt": habit.createdAt.timeIntervalSince1970
                ]
            },
            "logs": all(HabitLog.self).map { [
                "id": $0.id.uuidString, "habitID": $0.habitID.uuidString, "dayKey": $0.dayKey,
                "count": $0.count, "skipped": $0.skipped, "createdAt": $0.createdAt.timeIntervalSince1970
            ] },
            "ledger": all(RewardLedger.self).map { [
                "key": $0.key, "sparks": $0.sparks, "energy": $0.energy, "createdAt": $0.createdAt.timeIntervalSince1970
            ] },
            "runs": all(AdventureRun.self).map { [
                "id": $0.id.uuidString, "placeID": $0.placeID, "storyID": $0.storyID,
                "startedAt": $0.startedAt.timeIntervalSince1970, "returnsAt": $0.returnsAt.timeIntervalSince1970,
                "claimedAt": $0.claimedAt?.timeIntervalSince1970 ?? -1, "status": $0.status, "dayKey": $0.dayKey,
                "choiceID": $0.choiceID, "rewardSparks": $0.rewardSparks, "discoveryID": $0.discoveryID
            ] },
            "items": all(OwnedItem.self).map { [
                "catalogID": $0.catalogID, "kind": $0.kind, "acquiredAt": $0.acquiredAt.timeIntervalSince1970,
                "favorite": $0.favorite, "equippedSlot": $0.equippedSlot
            ] },
            "outfits": all(SavedOutfit.self).map { [
                "id": $0.id.uuidString, "name": $0.name, "slotsJSON": $0.slotsJSON,
                "favorite": $0.favorite, "createdAt": $0.createdAt.timeIntervalSince1970
            ] },
            "moods": all(MoodEntry.self).map { [
                "id": $0.id.uuidString, "recordedAt": $0.recordedAt.timeIntervalSince1970, "dayKey": $0.dayKey,
                "level": $0.level, "tags": $0.tags, "note": $0.note
            ] },
            "journals": all(JournalEntry.self).map { [
                "id": $0.id.uuidString, "createdAt": $0.createdAt.timeIntervalSince1970,
                "updatedAt": $0.updatedAt.timeIntervalSince1970, "title": $0.title, "body": $0.body,
                "tags": $0.tags, "promptID": $0.promptID, "dayKey": $0.dayKey
            ] },
            "quests": all(QuestRecord.self).map { [
                "id": $0.id.uuidString, "templateID": $0.templateID, "kind": $0.kind, "dayKey": $0.dayKey,
                "progress": $0.progress, "goal": $0.goal, "claimed": $0.claimed,
                "rewardSparks": $0.rewardSparks, "rewardItemID": $0.rewardItemID
            ] },
            "events": all(EventRecord.self).map { [
                "eventID": $0.eventID, "forced": $0.forced, "forcedOn": $0.forcedOn?.timeIntervalSince1970 ?? -1,
                "bonusJSON": $0.bonusJSON, "claimedJSON": $0.claimedJSON
            ] },
            "friends": all(MiniFriend.self).map { [
                "id": $0.id.uuidString, "speciesID": $0.speciesID, "givenName": $0.givenName, "rarity": $0.rarity,
                "stage": $0.stage, "hatchedAt": $0.hatchedAt.timeIntervalSince1970, "isCompanion": $0.isCompanion
            ] },
            "eggs": all(EggBinding.self).map { [
                "id": $0.id.uuidString, "habitID": $0.habitID.uuidString, "progress": $0.progress,
                "requiredCount": $0.requiredCount, "hatched": $0.hatched, "friendID": $0.friendID?.uuidString ?? "",
                "createdAt": $0.createdAt.timeIntervalSince1970
            ] },
            "places": all(PlaceProgress.self).map { [
                "placeID": $0.placeID, "unlocked": $0.unlocked, "visits": $0.visits
            ] },
            "discoveries": all(DiscoveryRecord.self).map { [
                "discoveryID": $0.discoveryID, "placeID": $0.placeID, "foundAt": $0.foundAt.timeIntervalSince1970
            ] },
            "stats": all(DailyStat.self).map { [
                "dayKey": $0.dayKey, "breathSessions": $0.breathSessions, "focusMinutes": $0.focusMinutes,
                "movementSessions": $0.movementSessions, "petActions": $0.petActions, "journalRewards": $0.journalRewards
            ] }
        ]
    }

    private func apply(_ snapshot: [String: Any]) {
        resetAll()
        let profileBox = snapshot["profile"] as? [String: Any] ?? [:]
        profile.nickname = profileBox["nickname"] as? String ?? ""
        profile.goobyName = profileBox["goobyName"] as? String ?? "Gooby"
        profile.goals = profileBox["goals"] as? [String] ?? []
        profile.onboardingDone = profileBox["onboardingDone"] as? Bool ?? true
        profile.faceIDEnabled = profileBox["faceIDEnabled"] as? Bool ?? false
        profile.languageCode = profileBox["languageCode"] as? String ?? "de"
        profile.reduceMotion = profileBox["reduceMotion"] as? Bool ?? false
        if let seedText = profileBox["appSeed"] as? String, let seed = Int64(seedText) {
            profile.appSeed = seed
        } else if let seedNumber = profileBox["appSeed"] as? NSNumber {
            profile.appSeed = seedNumber.int64Value
        }
        profile.timeOffset = profileBox["timeOffset"] as? Double ?? 0
        profile.createdAt = Date(timeIntervalSince1970: profileBox["createdAt"] as? Double ?? Date().timeIntervalSince1970)
        profile.notificationsEnabled = profileBox["notificationsEnabled"] as? Bool ?? false
        profile.energyGoal = profileBox["energyGoal"] as? Int ?? 12
        languageCode = profile.languageCode
        reduceMotion = profile.reduceMotion
        let walletBox = snapshot["wallet"] as? [String: Any] ?? [:]
        wallet.sparks = max(0, walletBox["sparks"] as? Int ?? 0)
        wallet.energy = max(0, walletBox["energy"] as? Int ?? 0)
        wallet.energyDayKey = walletBox["energyDayKey"] as? String ?? ""
        wallet.lifetimeSparksEarned = walletBox["lifetimeSparksEarned"] as? Int ?? 0
        wallet.lifetimeSparksSpent = walletBox["lifetimeSparksSpent"] as? Int ?? 0
        let petBox = snapshot["pet"] as? [String: Any] ?? [:]
        pet.curiosity = petBox["curiosity"] as? Double ?? 0.35
        pet.courage = petBox["courage"] as? Double ?? 0.35
        pet.kindness = petBox["kindness"] as? Double ?? 0.4
        pet.playfulness = petBox["playfulness"] as? Double ?? 0.4
        pet.confidence = petBox["confidence"] as? Double ?? 0.3
        pet.calm = petBox["calm"] as? Double ?? 0.35
        pet.empathy = petBox["empathy"] as? Double ?? 0.4
        pet.stageOverride = petBox["stageOverride"] as? String ?? ""
        pet.adventureDays = petBox["adventureDays"] as? Int ?? 0
        pet.careDays = petBox["careDays"] as? Int ?? 0
        pet.lastCareDayKey = petBox["lastCareDayKey"] as? String ?? ""
        pet.affection = petBox["affection"] as? Int ?? 0
        pet.furStyle = petBox["furStyle"] as? String ?? "fur-cream"
        pet.recentStoryIDs = petBox["recentStoryIDs"] as? [String] ?? []
        let roomBox = snapshot["room"] as? [String: Any] ?? [:]
        room.wall = roomBox["wall"] as? String ?? room.wall
        room.floor = roomBox["floor"] as? String ?? room.floor
        room.bed = roomBox["bed"] as? String ?? room.bed
        room.rug = roomBox["rug"] as? String ?? room.rug
        room.lamp = roomBox["lamp"] as? String ?? room.lamp
        room.windowItem = roomBox["windowItem"] as? String ?? room.windowItem
        room.plant = roomBox["plant"] as? String ?? room.plant
        room.shelf = roomBox["shelf"] as? String ?? ""
        room.picture = roomBox["picture"] as? String ?? ""
        room.sofa = roomBox["sofa"] as? String ?? ""
        room.tableItem = roomBox["tableItem"] as? String ?? ""
        room.cushion = roomBox["cushion"] as? String ?? room.cushion
        room.seasonal = roomBox["seasonal"] as? String ?? ""
        for habit in all(Habit.self) { context.delete(habit) }
        for item in all(OwnedItem.self) { context.delete(item) }
        for row in (snapshot["habits"] as? [[String: Any]] ?? []) {
            let habit = Habit()
            habit.id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            habit.title = row["title"] as? String ?? ""
            habit.details = row["details"] as? String ?? ""
            habit.icon = row["icon"] as? String ?? "sparkles"
            habit.colorHex = row["colorHex"] as? String ?? "FFD6E7"
            habit.category = row["category"] as? String ?? "mindful"
            habit.priority = row["priority"] as? Int ?? 1
            habit.startDate = Date(timeIntervalSince1970: row["startDate"] as? Double ?? Date().timeIntervalSince1970)
            if let end = row["endDate"] as? Double, end > 0 { habit.endDate = Date(timeIntervalSince1970: end) }
            habit.recurrence = row["recurrence"] as? String ?? "daily"
            habit.weekdays = row["weekdays"] as? [Int] ?? []
            habit.intervalDays = row["intervalDays"] as? Int ?? 1
            habit.timesPerDay = row["timesPerDay"] as? Int ?? 1
            habit.reminderHour = row["reminderHour"] as? Int ?? -1
            habit.reminderMinute = row["reminderMinute"] as? Int ?? 0
            habit.energyReward = row["energyReward"] as? Int ?? 5
            habit.sparkReward = row["sparkReward"] as? Int ?? 2
            habit.isDailyGoal = row["isDailyGoal"] as? Bool ?? false
            habit.isArchived = row["isArchived"] as? Bool ?? false
            habit.isPaused = row["isPaused"] as? Bool ?? false
            habit.movedFromKey = row["movedFromKey"] as? String ?? ""
            habit.movedToKey = row["movedToKey"] as? String ?? ""
            habit.sortIndex = row["sortIndex"] as? Int ?? 0
            habit.createdAt = Date(timeIntervalSince1970: row["createdAt"] as? Double ?? Date().timeIntervalSince1970)
            context.insert(habit)
        }
        for row in (snapshot["logs"] as? [[String: Any]] ?? []) {
            let log = HabitLog()
            log.id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            log.habitID = UUID(uuidString: row["habitID"] as? String ?? "") ?? UUID()
            log.dayKey = row["dayKey"] as? String ?? ""
            log.count = row["count"] as? Int ?? 0
            log.skipped = row["skipped"] as? Bool ?? false
            log.createdAt = Date(timeIntervalSince1970: row["createdAt"] as? Double ?? 0)
            context.insert(log)
        }
        for row in (snapshot["ledger"] as? [[String: Any]] ?? []) {
            let key = row["key"] as? String ?? ""
            guard !key.isEmpty, !all(RewardLedger.self).contains(where: { $0.key == key }) else { continue }
            let ledger = RewardLedger()
            ledger.key = key
            ledger.sparks = row["sparks"] as? Int ?? 0
            ledger.energy = row["energy"] as? Int ?? 0
            ledger.createdAt = Date(timeIntervalSince1970: row["createdAt"] as? Double ?? 0)
            context.insert(ledger)
        }
        for row in (snapshot["runs"] as? [[String: Any]] ?? []) {
            let run = AdventureRun()
            run.id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            run.placeID = row["placeID"] as? String ?? ""
            run.storyID = row["storyID"] as? String ?? ""
            run.startedAt = Date(timeIntervalSince1970: row["startedAt"] as? Double ?? 0)
            run.returnsAt = Date(timeIntervalSince1970: row["returnsAt"] as? Double ?? 0)
            if let claimed = row["claimedAt"] as? Double, claimed > 0 { run.claimedAt = Date(timeIntervalSince1970: claimed) }
            run.status = row["status"] as? String ?? "claimed"
            run.dayKey = row["dayKey"] as? String ?? ""
            run.choiceID = row["choiceID"] as? String ?? ""
            run.rewardSparks = row["rewardSparks"] as? Int ?? 0
            run.discoveryID = row["discoveryID"] as? String ?? ""
            context.insert(run)
        }
        for row in (snapshot["items"] as? [[String: Any]] ?? []) {
            let item = OwnedItem()
            item.catalogID = row["catalogID"] as? String ?? ""
            item.kind = row["kind"] as? String ?? ""
            item.acquiredAt = Date(timeIntervalSince1970: row["acquiredAt"] as? Double ?? 0)
            item.favorite = row["favorite"] as? Bool ?? false
            item.equippedSlot = row["equippedSlot"] as? String ?? ""
            context.insert(item)
        }
        for row in (snapshot["outfits"] as? [[String: Any]] ?? []) {
            let outfit = SavedOutfit()
            outfit.id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            outfit.name = row["name"] as? String ?? ""
            outfit.slotsJSON = row["slotsJSON"] as? String ?? "{}"
            outfit.favorite = row["favorite"] as? Bool ?? false
            outfit.createdAt = Date(timeIntervalSince1970: row["createdAt"] as? Double ?? 0)
            context.insert(outfit)
        }
        for row in (snapshot["moods"] as? [[String: Any]] ?? []) {
            let mood = MoodEntry()
            mood.id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            mood.recordedAt = Date(timeIntervalSince1970: row["recordedAt"] as? Double ?? 0)
            mood.dayKey = row["dayKey"] as? String ?? ""
            mood.level = row["level"] as? Int ?? 3
            mood.tags = row["tags"] as? [String] ?? []
            mood.note = row["note"] as? String ?? ""
            context.insert(mood)
        }
        for row in (snapshot["journals"] as? [[String: Any]] ?? []) {
            let entry = JournalEntry()
            entry.id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            entry.createdAt = Date(timeIntervalSince1970: row["createdAt"] as? Double ?? 0)
            entry.updatedAt = Date(timeIntervalSince1970: row["updatedAt"] as? Double ?? 0)
            entry.title = row["title"] as? String ?? ""
            entry.body = row["body"] as? String ?? ""
            entry.tags = row["tags"] as? [String] ?? []
            entry.promptID = row["promptID"] as? String ?? ""
            entry.dayKey = row["dayKey"] as? String ?? ""
            context.insert(entry)
        }
        for row in all(QuestRecord.self) { context.delete(row) }
        for row in (snapshot["quests"] as? [[String: Any]] ?? []) {
            let quest = QuestRecord()
            quest.id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            quest.templateID = row["templateID"] as? String ?? ""
            quest.kind = row["kind"] as? String ?? "daily"
            quest.dayKey = row["dayKey"] as? String ?? ""
            quest.progress = row["progress"] as? Int ?? 0
            quest.goal = row["goal"] as? Int ?? 1
            quest.claimed = row["claimed"] as? Bool ?? false
            quest.rewardSparks = row["rewardSparks"] as? Int ?? 0
            quest.rewardItemID = row["rewardItemID"] as? String ?? ""
            context.insert(quest)
        }
        for row in all(EventRecord.self) { context.delete(row) }
        for row in (snapshot["events"] as? [[String: Any]] ?? []) {
            let event = EventRecord()
            event.eventID = row["eventID"] as? String ?? ""
            event.forced = row["forced"] as? Bool ?? false
            if let forced = row["forcedOn"] as? Double, forced > 0 { event.forcedOn = Date(timeIntervalSince1970: forced) }
            event.bonusJSON = row["bonusJSON"] as? String ?? "{}"
            event.claimedJSON = row["claimedJSON"] as? String ?? "[]"
            context.insert(event)
        }
        for row in all(MiniFriend.self) { context.delete(row) }
        for row in (snapshot["friends"] as? [[String: Any]] ?? []) {
            let friend = MiniFriend()
            friend.id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            friend.speciesID = row["speciesID"] as? String ?? ""
            friend.givenName = row["givenName"] as? String ?? ""
            friend.rarity = row["rarity"] as? String ?? "common"
            friend.stage = row["stage"] as? Int ?? 1
            friend.hatchedAt = Date(timeIntervalSince1970: row["hatchedAt"] as? Double ?? 0)
            friend.isCompanion = row["isCompanion"] as? Bool ?? false
            context.insert(friend)
        }
        for row in all(EggBinding.self) { context.delete(row) }
        for row in (snapshot["eggs"] as? [[String: Any]] ?? []) {
            let egg = EggBinding()
            egg.id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            egg.habitID = UUID(uuidString: row["habitID"] as? String ?? "") ?? UUID()
            egg.progress = row["progress"] as? Int ?? 0
            egg.requiredCount = row["requiredCount"] as? Int ?? 7
            egg.hatched = row["hatched"] as? Bool ?? false
            let friend = row["friendID"] as? String ?? ""
            egg.friendID = UUID(uuidString: friend)
            egg.createdAt = Date(timeIntervalSince1970: row["createdAt"] as? Double ?? 0)
            context.insert(egg)
        }
        for row in (snapshot["places"] as? [[String: Any]] ?? []) {
            let id = row["placeID"] as? String ?? ""
            let place = placeProgress(id)
            place?.unlocked = row["unlocked"] as? Bool ?? false
            place?.visits = row["visits"] as? Int ?? 0
        }
        for row in all(DiscoveryRecord.self) { context.delete(row) }
        for row in (snapshot["discoveries"] as? [[String: Any]] ?? []) {
            let found = DiscoveryRecord()
            found.discoveryID = row["discoveryID"] as? String ?? ""
            found.placeID = row["placeID"] as? String ?? ""
            found.foundAt = Date(timeIntervalSince1970: row["foundAt"] as? Double ?? 0)
            context.insert(found)
        }
        for row in all(DailyStat.self) { context.delete(row) }
        for row in (snapshot["stats"] as? [[String: Any]] ?? []) {
            let stat = DailyStat()
            stat.dayKey = row["dayKey"] as? String ?? ""
            stat.breathSessions = row["breathSessions"] as? Int ?? 0
            stat.focusMinutes = row["focusMinutes"] as? Int ?? 0
            stat.movementSessions = row["movementSessions"] as? Int ?? 0
            stat.petActions = row["petActions"] as? Int ?? 0
            stat.journalRewards = row["journalRewards"] as? Int ?? 0
            context.insert(stat)
        }
        if let photo = snapshot["photo"] as? String, let data = Data(base64Encoded: photo), !data.isEmpty {
            let url = GoobyFiles.supportDirectory().appendingPathComponent("profile.jpg")
            try? data.write(to: url)
            GoobyFiles.exclude(url)
            profile.photoFilename = "profile.jpg"
        }
        ensureWorld()
        save()
        rescheduleNotifications()
        log("import")
    }
}

enum BackupError: Error {
    case unreadable
    case password
}
