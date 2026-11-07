import Foundation

enum GoobyEventsGame {
    static func effectiveDate(save: GoobyEventsSave, now: Date) -> Date {
        if let iso = save.timeTravelISO, let date = GoobyDayKey.date(fromISO: iso) {
            return date
        }
        return now
    }

    static func configure(save: inout GoobyEventsSave, seed: UInt64) {
        let untouched = save.dailyBoards.isEmpty && save.eggs.isEmpty && save.companions.isEmpty && save.eventProgress.isEmpty
        guard !save.seedConfigured, untouched else {
            save.seedConfigured = true
            return
        }
        save.seed = seed == 0 ? GoobyEventsSave.defaultSeed : seed
        save.seedConfigured = true
    }

    @discardableResult
    static func refresh(
        save: inout GoobyEventsSave,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> [GoobyRewardGrant] {
        let date = effectiveDate(save: save, now: now)
        let day = GoobyDayKey.make(date, calendar: calendar)
        var grants: [GoobyRewardGrant] = []
        for key in save.dailyBoards.keys.filter({ $0 < day }).sorted() {
            grants.append(contentsOf: GoobyQuestEngine.claimCompleted(save: &save, dayKey: key, libraries: libraries))
        }
        GoobyQuestEngine.ensureBoard(save: &save, dayKey: day, libraries: libraries)
        grants.append(contentsOf: GoobyQuestEngine.trimBoards(save: &save, keeping: day, libraries: libraries))
        grants.append(contentsOf: GoobyMilestoneEngine.evaluate(save: &save, dayKey: day, libraries: libraries))
        return grants
    }

    @discardableResult
    static func record(
        save: inout GoobyEventsSave,
        signal: GoobyCareSignal,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> [GoobyRewardGrant] {
        var grants = refresh(save: &save, now: now, calendar: calendar, libraries: libraries)
        let date = effectiveDate(save: save, now: now)
        let day = GoobyDayKey.make(date, calendar: calendar)
        switch signal {
        case .habitCompleted(let habitID):
            let habit = habitID.trimmingCharacters(in: .whitespacesAndNewlines)
            if !habit.isEmpty {
                grants.append(contentsOf: GoobyCompanionEngine.recordHabit(save: &save, habitID: habit, day: day, libraries: libraries))
                GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "habitCount", credit: habit, libraries: libraries)
                GoobyEventEngine.applyHabit(save: &save, habitID: habit, day: day, date: date, calendar: calendar, libraries: libraries)
            }
        case .moodLogged:
            GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "mood", credit: "mood", libraries: libraries)
            GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "reflection", credit: "mood", libraries: libraries)
            GoobyEventEngine.applyPrefixed("mood", day: day, date: date, calendar: calendar, libraries: libraries, save: &save)
        case .journalWritten:
            GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "journal", credit: "journal", libraries: libraries)
            GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "reflection", credit: "journal", libraries: libraries)
            GoobyEventEngine.applyPrefixed("journal", day: day, date: date, calendar: calendar, libraries: libraries, save: &save)
        case .calmSessionCompleted:
            GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "calm", credit: "calm", libraries: libraries)
            GoobyEventEngine.applyPrefixed("calm", day: day, date: date, calendar: calendar, libraries: libraries, save: &save)
        case .goobyPetted:
            GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "pet", credit: "pet", libraries: libraries)
        case .adventureStarted, .adventureCompleted:
            GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "adventure", credit: "adventure", libraries: libraries)
        case .dailyGoalCompleted:
            GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "dailyGoal", credit: "goal", libraries: libraries)
        case .eventVisited(let eventID):
            GoobyEventEngine.applyVisit(eventID: eventID, date: date, calendar: calendar, libraries: libraries, save: &save)
        case .companionPlayed(let companionID):
            guard save.companions.contains(where: { $0.id == companionID }) else {
                break
            }
            _ = GoobyCompanionEngine.play(save: &save, companionID: companionID, day: day)
            GoobyQuestEngine.apply(save: &save, dayKey: day, metric: "companionPlay", credit: companionID, libraries: libraries)
            GoobyEventEngine.applyCompanionPlay(companionID: companionID, day: day, date: date, calendar: calendar, libraries: libraries, save: &save)
        }
        grants.append(contentsOf: GoobyQuestEngine.claimCompleted(save: &save, dayKey: day, libraries: libraries))
        grants.append(contentsOf: GoobyMilestoneEngine.evaluate(save: &save, dayKey: day, libraries: libraries))
        return grants
    }

    static func setForcedEvent(save: inout GoobyEventsSave, eventID: String?, libraries: GoobyEventsLibraries) {
        if let eventID {
            guard libraries.event(eventID) != nil else {
                return
            }
            save.forcedEventID = eventID
            save.log("Fest manuell gestartet: \(eventID)")
        } else {
            save.forcedEventID = nil
            save.log("Manuelles Fest beendet")
        }
    }

    @discardableResult
    static func applyTimeTravel(
        save: inout GoobyEventsSave,
        preset: GoobyTimeTravelPreset,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> Date {
        let date: Date
        switch preset {
        case .today:
            save.timeTravelISO = nil
            date = now
        case .tomorrow:
            date = GoobyDayKey.adding(days: 1, to: now, calendar: calendar)
            save.timeTravelISO = GoobyDayKey.isoString(date)
        case .nextWeek:
            date = GoobyDayKey.adding(days: 7, to: now, calendar: calendar)
            save.timeTravelISO = GoobyDayKey.isoString(date)
        case .nextMonth:
            date = GoobyDayKey.adding(months: 1, to: now, calendar: calendar)
            save.timeTravelISO = GoobyDayKey.isoString(date)
        }
        save.log("Zeitreise: \(GoobyDayKey.make(date, calendar: calendar))")
        _ = refresh(save: &save, now: now, calendar: calendar, libraries: libraries)
        return effectiveDate(save: save, now: now)
    }

    static func setTimeTravel(
        save: inout GoobyEventsSave,
        date: Date?,
        now: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) {
        if let date {
            save.timeTravelISO = GoobyDayKey.isoString(date)
            save.log("Zeitreise: \(GoobyDayKey.make(date, calendar: calendar))")
        } else {
            save.timeTravelISO = nil
            save.log("Zeitreise aus")
        }
        _ = refresh(save: &save, now: now, calendar: calendar, libraries: libraries)
    }

    static func resetAll(save: inout GoobyEventsSave) {
        let seed = save.seed
        let configured = save.seedConfigured
        save = GoobyEventsSave()
        save.seed = seed
        save.seedConfigured = configured
        save.log("Events, Aufträge und Mini-Freunde zurückgesetzt")
    }
}
