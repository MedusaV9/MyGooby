import Foundation

enum GoobyQuestEngine {
    static func makeBoard(
        dayKey: String,
        seed: UInt64,
        salt: UInt64,
        hasCompanion: Bool,
        libraries: GoobyEventsLibraries
    ) -> GoobyDailyBoard {
        var pool = libraries.quests
        if !hasCompanion {
            pool.removeAll { $0.metric == "companionPlay" }
        }
        let mixed = GoobySeededGenerator.mix(GoobySeededGenerator.mix(seed, salt), GoobySeededGenerator.hash(dayKey))
        var generator = GoobySeededGenerator(state: mixed)
        var bag = pool
        var picked: [GoobyQuestTemplate] = []
        while picked.count < 3, !bag.isEmpty {
            let index = Int(generator.next() % UInt64(bag.count))
            picked.append(bag.remove(at: index))
        }
        let quests = picked.map { template in
            GoobyDailyQuestProgress(
                id: "\(dayKey)#\(template.id)",
                templateID: template.id,
                progress: 0,
                creditKeys: [],
                claimed: false
            )
        }
        return GoobyDailyBoard(dayKey: dayKey, quests: quests)
    }

    static func ensureBoard(
        save: inout GoobyEventsSave,
        dayKey: String,
        libraries: GoobyEventsLibraries
    ) {
        if save.dailyBoards[dayKey] == nil {
            save.dailyBoards[dayKey] = makeBoard(
                dayKey: dayKey,
                seed: save.seed,
                salt: save.questSalt,
                hasCompanion: !save.companions.isEmpty,
                libraries: libraries
            )
        }
        reconcileClaims(save: &save, dayKey: dayKey, libraries: libraries)
    }

    static func apply(
        save: inout GoobyEventsSave,
        dayKey: String,
        metric: String,
        credit: String,
        libraries: GoobyEventsLibraries
    ) {
        guard var board = save.dailyBoards[dayKey] else {
            return
        }
        var changed = false
        for index in board.quests.indices {
            guard let template = libraries.quest(board.quests[index].templateID) else {
                continue
            }
            guard template.metric == metric else {
                continue
            }
            guard !board.quests[index].claimed else {
                continue
            }
            guard !board.quests[index].creditKeys.contains(credit) else {
                continue
            }
            guard board.quests[index].progress < template.target else {
                continue
            }
            board.quests[index].creditKeys.append(credit)
            board.quests[index].progress += 1
            if board.quests[index].progress > template.target {
                board.quests[index].progress = template.target
            }
            changed = true
        }
        if changed {
            save.dailyBoards[dayKey] = board
        }
    }

    @discardableResult
    static func claimCompleted(
        save: inout GoobyEventsSave,
        dayKey: String,
        libraries: GoobyEventsLibraries
    ) -> [GoobyRewardGrant] {
        guard var board = save.dailyBoards[dayKey] else {
            return []
        }
        var grants: [GoobyRewardGrant] = []
        for index in board.quests.indices {
            guard let template = libraries.quest(board.quests[index].templateID) else {
                continue
            }
            guard board.quests[index].progress >= template.target else {
                continue
            }
            let questID = board.quests[index].id
            if save.claimedQuestIDs.contains(questID) {
                board.quests[index].claimed = true
                continue
            }
            guard !board.quests[index].claimed else {
                continue
            }
            board.quests[index].claimed = true
            save.claimedQuestIDs.append(questID)
            save.totalQuestsCompleted += 1
            if !save.questCompletionDays.contains(dayKey) {
                save.questCompletionDays.append(dayKey)
            }
            grants.append(
                GoobyRewardGrant.make(
                    id: "quest|\(questID)",
                    source: "quest",
                    starSparks: template.sparks,
                    titleDE: template.titleDE,
                    titleEN: template.titleEN,
                    dayKey: dayKey
                )
            )
        }
        save.dailyBoards[dayKey] = board
        return grants
    }

    static func reroll(save: inout GoobyEventsSave, dayKey: String, libraries: GoobyEventsLibraries) {
        guard let board = save.dailyBoards[dayKey] else {
            return
        }
        let claimed = board.quests.filter(\.claimed)
        if claimed.count == board.quests.count, !board.quests.isEmpty {
            return
        }
        save.questSalt += 1
        let fresh = makeBoard(
            dayKey: dayKey,
            seed: save.seed,
            salt: save.questSalt,
            hasCompanion: !save.companions.isEmpty,
            libraries: libraries
        )
        var result = claimed
        var used = Set(claimed.map(\.templateID))
        for quest in fresh.quests where result.count < 3 && !used.contains(quest.templateID) {
            var copy = quest
            if save.claimedQuestIDs.contains(copy.id), let template = libraries.quest(copy.templateID) {
                copy.progress = template.target
                copy.claimed = true
            }
            result.append(copy)
            used.insert(copy.templateID)
        }
        save.dailyBoards[dayKey] = GoobyDailyBoard(dayKey: dayKey, quests: result)
        save.log("Tagesaufträge neu gemischt")
    }

    static func complete(
        save: inout GoobyEventsSave,
        questID: String,
        dayKey: String,
        libraries: GoobyEventsLibraries
    ) -> [GoobyRewardGrant] {
        let keys = save.dailyBoards.keys.filter { day in
            save.dailyBoards[day]?.quests.contains { quest in
                quest.id == questID || (day == dayKey && quest.templateID == questID)
            } ?? false
        }
        let targetDays = keys.isEmpty ? [dayKey] : keys.sorted()
        var grants: [GoobyRewardGrant] = []
        for day in targetDays {
            guard var board = save.dailyBoards[day] else {
                continue
            }
            var changed = false
            for index in board.quests.indices {
                let matches = board.quests[index].id == questID || (day == dayKey && board.quests[index].templateID == questID)
                guard matches, let template = libraries.quest(board.quests[index].templateID) else {
                    continue
                }
                if board.quests[index].progress < template.target {
                    board.quests[index].progress = template.target
                    changed = true
                }
            }
            if changed {
                save.dailyBoards[day] = board
            }
            grants.append(contentsOf: claimCompleted(save: &save, dayKey: day, libraries: libraries))
        }
        return grants
    }

    static func testRewards(
        save: inout GoobyEventsSave,
        dayKey: String,
        libraries: GoobyEventsLibraries
    ) -> [GoobyRewardGrant] {
        guard let board = save.dailyBoards[dayKey] else {
            return []
        }
        var grants: [GoobyRewardGrant] = []
        for quest in board.quests where !quest.claimed {
            grants.append(contentsOf: complete(save: &save, questID: quest.id, dayKey: dayKey, libraries: libraries))
        }
        return grants
    }

    static func reset(save: inout GoobyEventsSave, libraries: GoobyEventsLibraries) {
        save.dailyBoards = [:]
        save.questSalt = 0
        save.claimedQuestIDs = []
        save.totalQuestsCompleted = 0
        save.questCompletionDays = []
        let questMetrics: Set<String> = ["questsCompleted", "questDays"]
        let questMilestoneIDs = Set(libraries.milestones.filter { questMetrics.contains($0.metric) }.map(\.id))
        save.claimedMilestoneIDs.removeAll { questMilestoneIDs.contains($0) }
        save.log("Aufträge zurückgesetzt")
    }

    static func trimBoards(
        save: inout GoobyEventsSave,
        keeping dayKey: String,
        libraries: GoobyEventsLibraries
    ) -> [GoobyRewardGrant] {
        var grants: [GoobyRewardGrant] = []
        let extras = save.dailyBoards.keys.filter { $0 != dayKey }.sorted()
        guard extras.count > 40 else {
            return grants
        }
        for key in extras.prefix(extras.count - 40) {
            grants.append(contentsOf: claimCompleted(save: &save, dayKey: key, libraries: libraries))
            save.dailyBoards.removeValue(forKey: key)
        }
        return grants
    }

    private static func reconcileClaims(
        save: inout GoobyEventsSave,
        dayKey: String,
        libraries: GoobyEventsLibraries
    ) {
        guard var board = save.dailyBoards[dayKey] else {
            return
        }
        var changed = false
        for index in board.quests.indices where save.claimedQuestIDs.contains(board.quests[index].id) {
            if let template = libraries.quest(board.quests[index].templateID) {
                board.quests[index].progress = template.target
            }
            board.quests[index].claimed = true
            changed = true
        }
        if changed {
            save.dailyBoards[dayKey] = board
        }
    }
}

enum GoobyMilestoneEngine {
    static func value(metric: String, save: GoobyEventsSave) -> Int {
        switch metric {
        case "questsCompleted":
            return save.totalQuestsCompleted
        case "questDays":
            return save.questCompletionDays.count
        case "eggsBound":
            return save.eggsEverBound
        case "hatches":
            return save.companionsHatchedEver
        case "companions":
            return save.companions.count
        case "species":
            return save.speciesHatched.count
        case "eventsClaimed":
            return save.claimedEventRewards.count
        case "eventsTouched":
            return save.eventsTouched.count
        case "plays":
            return save.companionPlayTotal
        default:
            return 0
        }
    }

    static func evaluate(
        save: inout GoobyEventsSave,
        dayKey: String,
        libraries: GoobyEventsLibraries
    ) -> [GoobyRewardGrant] {
        var grants: [GoobyRewardGrant] = []
        for milestone in libraries.milestones where !save.claimedMilestoneIDs.contains(milestone.id) {
            guard value(metric: milestone.metric, save: save) >= milestone.target else {
                continue
            }
            save.claimedMilestoneIDs.append(milestone.id)
            grants.append(
                GoobyRewardGrant.make(
                    id: "milestone|\(milestone.id)",
                    source: "milestone",
                    starSparks: milestone.sparks,
                    titleDE: milestone.titleDE,
                    titleEN: milestone.titleEN,
                    dayKey: dayKey
                )
            )
        }
        return grants
    }
}
