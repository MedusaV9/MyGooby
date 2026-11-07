import Foundation

enum GoobyEventsPresenter {
    static func screen(
        save: GoobyEventsSave,
        language: GoobyEventsLanguage,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> GoobyEventsScreenModel {
        let date = GoobyEventsGame.effectiveDate(save: save, now: now)
        let day = GoobyDayKey.make(date, calendar: calendar)
        let companions = companionSnapshots(save: save, dayKey: day, language: language, libraries: libraries)
        return GoobyEventsScreenModel(
            language: language,
            dayKey: day,
            events: eventSnapshots(save: save, language: language, date: date, calendar: calendar, libraries: libraries),
            quests: questSnapshots(save: save, dayKey: day, language: language, libraries: libraries),
            milestones: milestoneSnapshots(save: save, language: language, libraries: libraries),
            eggs: eggSnapshots(save: save),
            companions: companions,
            pendingHatches: save.pendingHatchIDs.compactMap { id in companions.first { $0.id == id } },
            forcedEventID: save.forcedEventID
        )
    }

    static func banner(
        grants: [GoobyRewardGrant],
        language: GoobyEventsLanguage,
        libraries: GoobyEventsLibraries
    ) -> String? {
        let sparks = grants.reduce(0) { $0 + max(0, $1.starSparks) }
        let friendID = grants.compactMap(\.companionSpeciesID).first
        if sparks == 0, friendID == nil {
            return nil
        }
        var parts: [String] = []
        if sparks > 0 {
            parts.append(libraries.format("banner.sparks", language: language, tokens: ["count": "\(sparks)"]))
        }
        if let friendID, let species = libraries.species(friendID) {
            let name = language == .english ? species.nameEN : species.nameDE
            parts.append(libraries.format("banner.friend", language: language, tokens: ["name": name]))
        }
        return parts.joined(separator: " · ")
    }

    static func diagnostic(
        save: GoobyEventsSave,
        language: GoobyEventsLanguage,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries,
        filePath: String,
        lastError: String?
    ) -> String {
        let model = screen(save: save, language: language, now: now, calendar: calendar, libraries: libraries)
        let active = model.events.filter { $0.phase == "active" || $0.forced }.map(\.name).joined(separator: ", ")
        let lines: [String]
        if language == .english {
            lines = [
                "Gooby events \(GoobyEventsIntegration.sliceVersion)",
                "Save version \(save.version)",
                "App day \(model.dayKey)",
                "Time travel \(save.timeTravelISO ?? "off")",
                "Forced event \(save.forcedEventID ?? "none")",
                "Active \(active.isEmpty ? "none" : active)",
                "Quests \(model.quests.map { "\($0.title) \($0.progress)/\($0.target)" }.joined(separator: "; "))",
                "Eggs \(model.eggs.map { "\($0.habitTitle) \($0.validDays)/\($0.requiredDays)" }.joined(separator: "; "))",
                "Companions \(model.companions.count)",
                "Milestones claimed \(save.claimedMilestoneIDs.count)/\(libraries.milestones.count)",
                "File \(filePath)",
                "Last error \(lastError ?? "none")",
                "Log \(save.debugLog.suffix(8).joined(separator: " | "))"
            ]
        } else {
            lines = [
                "Gooby-Feste \(GoobyEventsIntegration.sliceVersion)",
                "Speicherversion \(save.version)",
                "App-Tag \(model.dayKey)",
                "Zeitreise \(save.timeTravelISO ?? "aus")",
                "Manuelles Fest \(save.forcedEventID ?? "keins")",
                "Aktiv \(active.isEmpty ? "keins" : active)",
                "Aufträge \(model.quests.map { "\($0.title) \($0.progress)/\($0.target)" }.joined(separator: "; "))",
                "Eier \(model.eggs.map { "\($0.habitTitle) \($0.validDays)/\($0.requiredDays)" }.joined(separator: "; "))",
                "Mini-Freunde \(model.companions.count)",
                "Meilensteine geholt \(save.claimedMilestoneIDs.count)/\(libraries.milestones.count)",
                "Datei \(filePath)",
                "Letzter Fehler \(lastError ?? "keiner")",
                "Protokoll \(save.debugLog.suffix(8).joined(separator: " | "))"
            ]
        }
        return lines.joined(separator: "\n")
    }

    private static func eventSnapshots(
        save: GoobyEventsSave,
        language: GoobyEventsLanguage,
        date: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> [GoobyEventSnapshot] {
        GoobyEventCalendar.entries(on: date, calendar: calendar, events: libraries.events).map { entry in
            let key = GoobyEventCalendar.occurrenceKey(entry.event, on: date, calendar: calendar) ?? "\(entry.event.id)#"
            let progress = save.eventProgress[key] ?? GoobyEventOccurrenceProgress(eventID: entry.event.id, occurrenceKey: key, credits: [])
            let english = language == .english
            let objectives = entry.event.objectives.map { objective in
                GoobyObjectiveSnapshot(
                    id: objective.id,
                    title: english ? objective.titleEN : objective.titleDE,
                    current: min(objective.target, GoobyEventEngine.creditCount(kind: objective.kind, credits: progress.credits)),
                    target: objective.target
                )
            }
            let bonusName = entry.event.bonusSpeciesID.flatMap { id in
                libraries.species(id).map { english ? $0.nameEN : $0.nameDE }
            }
            let forced = save.forcedEventID == entry.event.id && entry.phase != "active"
            return GoobyEventSnapshot(
                id: entry.event.id,
                name: english ? entry.event.nameEN : entry.event.nameDE,
                summary: english ? entry.event.summaryEN : entry.event.summaryDE,
                phase: entry.phase,
                dateText: "\(dayText(entry.window.start, language: language, calendar: calendar)) – \(dayText(entry.window.end, language: language, calendar: calendar))",
                accentHex: entry.event.accentHex,
                symbolName: entry.event.symbolName,
                objectives: objectives,
                rewardSparks: max(0, entry.event.rewardSparks),
                cosmeticID: entry.event.cosmeticID,
                bonusSpeciesName: bonusName,
                complete: GoobyEventEngine.isComplete(entry.event, progress: progress),
                claimed: save.claimedEventRewards.contains(key),
                forced: forced
            )
        }
    }

    private static func questSnapshots(
        save: GoobyEventsSave,
        dayKey: String,
        language: GoobyEventsLanguage,
        libraries: GoobyEventsLibraries
    ) -> [GoobyQuestSnapshot] {
        let board = save.dailyBoards[dayKey]
        return (board?.quests ?? []).compactMap { quest in
            guard let template = libraries.quest(quest.templateID) else {
                return nil
            }
            let english = language == .english
            return GoobyQuestSnapshot(
                id: quest.id,
                templateID: quest.templateID,
                title: english ? template.titleEN : template.titleDE,
                detail: english ? template.detailEN : template.detailDE,
                progress: min(quest.progress, template.target),
                target: template.target,
                sparks: max(0, template.sparks),
                claimed: quest.claimed
            )
        }
    }

    private static func milestoneSnapshots(
        save: GoobyEventsSave,
        language: GoobyEventsLanguage,
        libraries: GoobyEventsLibraries
    ) -> [GoobyMilestoneSnapshot] {
        libraries.milestones.map { milestone in
            let english = language == .english
            let current = min(milestone.target, GoobyMilestoneEngine.value(metric: milestone.metric, save: save))
            return GoobyMilestoneSnapshot(
                id: milestone.id,
                title: english ? milestone.titleEN : milestone.titleDE,
                detail: english ? milestone.detailEN : milestone.detailDE,
                current: current,
                target: milestone.target,
                sparks: max(0, milestone.sparks),
                claimed: save.claimedMilestoneIDs.contains(milestone.id)
            )
        }
    }

    private static func eggSnapshots(save: GoobyEventsSave) -> [GoobyEggSnapshot] {
        save.eggs.map { egg in
            GoobyEggSnapshot(
                id: egg.id,
                habitID: egg.habitID,
                habitTitle: egg.habitTitle,
                validDays: egg.validDays.count,
                requiredDays: GoobyCompanionGrowth.requiredEggDays,
                hatchedCompanionID: egg.hatchedCompanionID
            )
        }
    }

    private static func companionSnapshots(
        save: GoobyEventsSave,
        dayKey: String,
        language: GoobyEventsLanguage,
        libraries: GoobyEventsLibraries
    ) -> [GoobyCompanionSnapshot] {
        save.companions.compactMap { record in
            guard let species = libraries.species(record.speciesID) else {
                return nil
            }
            let english = language == .english
            let fallback = english ? species.nameEN : species.nameDE
            return GoobyCompanionSnapshot(
                id: record.id,
                speciesID: record.speciesID,
                name: record.customName ?? fallback,
                story: english ? species.storyEN : species.storyDE,
                rarity: species.rarity,
                stage: GoobyCompanionGrowth.stage(playCount: record.playCount),
                animation: species.animation,
                primaryHex: species.primaryHex,
                secondaryHex: species.secondaryHex,
                selected: save.selectedCompanionID == record.id,
                playCount: record.playCount,
                playedToday: record.playDays.contains(dayKey)
            )
        }
    }

    private static func dayText(_ date: Date, language: GoobyEventsLanguage, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: language == .english ? "en_US" : "de_DE")
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter.string(from: date)
    }
}
