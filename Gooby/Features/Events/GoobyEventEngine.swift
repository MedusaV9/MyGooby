import Foundation

enum GoobyEventEngine {
    static func activeEvents(
        on date: Date,
        forcedEventID: String?,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) -> [GoobySeasonalEventDefinition] {
        var active = libraries.events.filter { GoobyEventCalendar.isActive($0, on: date, calendar: calendar) }
        if let forcedEventID, let forced = libraries.event(forcedEventID), !active.contains(where: { $0.id == forced.id }) {
            active.append(forced)
        }
        return active
    }

    static func creditCount(kind: String, credits: [String]) -> Int {
        credits.reduce(0) { count, credit in
            count + (matches(kind: kind, credit: credit) ? 1 : 0)
        }
    }

    static func isComplete(_ event: GoobySeasonalEventDefinition, progress: GoobyEventOccurrenceProgress) -> Bool {
        event.objectives.allSatisfy { objective in
            creditCount(kind: objective.kind, credits: progress.credits) >= objective.target
        }
    }

    static func applyHabit(
        save: inout GoobyEventsSave,
        habitID: String,
        day: String,
        date: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) {
        let credits = ["habitDay|\(day)", "habit|\(day)|\(habitID)"]
        add(credits, on: date, calendar: calendar, libraries: libraries, save: &save)
    }

    static func applyPrefixed(
        _ prefix: String,
        day: String,
        date: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries,
        save: inout GoobyEventsSave
    ) {
        add(["\(prefix)|\(day)"], on: date, calendar: calendar, libraries: libraries, save: &save)
    }

    static func applyVisit(
        eventID: String,
        date: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries,
        save: inout GoobyEventsSave
    ) {
        guard let event = libraries.event(eventID) else {
            return
        }
        let active = activeEvents(on: date, forcedEventID: save.forcedEventID, calendar: calendar, libraries: libraries)
        guard active.contains(where: { $0.id == event.id }) else {
            return
        }
        mutate(event, on: date, calendar: calendar, save: &save) { progress in
            let credit = "visit|once"
            if !progress.credits.contains(credit) {
                progress.credits.append(credit)
            }
        }
    }

    static func applyCompanionPlay(
        companionID: String,
        day: String,
        date: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries,
        save: inout GoobyEventsSave
    ) {
        add(["play|\(day)|\(companionID)"], on: date, calendar: calendar, libraries: libraries, save: &save)
    }

    @discardableResult
    static func claim(
        save: inout GoobyEventsSave,
        eventID: String,
        date: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries,
        free: Bool
    ) -> [GoobyRewardGrant] {
        guard let event = libraries.event(eventID) else {
            return []
        }
        guard let key = GoobyEventCalendar.occurrenceKey(event, on: date, calendar: calendar) else {
            return []
        }
        let progress = save.eventProgress[key] ?? GoobyEventOccurrenceProgress(eventID: event.id, occurrenceKey: key, credits: [])
        if !free && !isComplete(event, progress: progress) {
            return []
        }
        if save.claimedEventRewards.contains(key) {
            return []
        }
        save.claimedEventRewards.append(key)
        if free {
            save.debugEventGrants.append(key)
        }
        var speciesID: String?
        if let bonus = event.bonusSpeciesID {
            if GoobyCompanionEngine.addCompanion(save: &save, speciesID: bonus, day: GoobyDayKey.make(date, calendar: calendar), origin: "event", libraries: libraries) != nil {
                speciesID = bonus
            }
        }
        if !save.eventsTouched.contains(event.id) {
            save.eventsTouched.append(event.id)
        }
        save.log("Festbelohnung: \(event.nameDE)")
        return [
            GoobyRewardGrant.make(
                id: "event|\(key)",
                source: free ? "event-debug" : "event",
                starSparks: event.rewardSparks,
                cosmeticIDs: [event.cosmeticID],
                companionSpeciesID: speciesID,
                titleDE: event.nameDE,
                titleEN: event.nameEN,
                dayKey: GoobyDayKey.make(date, calendar: calendar)
            )
        ]
    }

    static func simulate(
        save: inout GoobyEventsSave,
        eventID: String,
        steps: Int,
        date: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries
    ) {
        guard steps > 0, let event = libraries.event(eventID) else {
            return
        }
        guard let key = GoobyEventCalendar.occurrenceKey(event, on: date, calendar: calendar) else {
            return
        }
        var progress = save.eventProgress[key] ?? GoobyEventOccurrenceProgress(eventID: event.id, occurrenceKey: key, credits: [])
        var remaining = steps
        for objective in event.objectives {
            var guardrail = 0
            while creditCount(kind: objective.kind, credits: progress.credits) < objective.target && remaining > 0 && guardrail < 80 {
                let credit = "debug-\(objective.kind)|\(progress.credits.count)"
                if !progress.credits.contains(credit) {
                    progress.credits.append(credit)
                    remaining -= 1
                }
                guardrail += 1
            }
        }
        save.eventProgress[key] = progress
        if !save.eventsTouched.contains(event.id) {
            save.eventsTouched.append(event.id)
        }
    }

    static func reset(save: inout GoobyEventsSave, eventID: String?) {
        if let eventID {
            save.eventProgress = save.eventProgress.filter { $0.value.eventID != eventID }
            save.claimedEventRewards.removeAll { $0.hasPrefix("\(eventID)#") }
            save.debugEventGrants.removeAll { $0.hasPrefix("\(eventID)#") }
            save.eventsTouched.removeAll { $0 == eventID }
            if save.forcedEventID == eventID {
                save.forcedEventID = nil
            }
            save.log("Fest zurückgesetzt: \(eventID)")
        } else {
            save.eventProgress = [:]
            save.claimedEventRewards = []
            save.debugEventGrants = []
            save.eventsTouched = []
            save.forcedEventID = nil
            save.log("Alle Feste zurückgesetzt")
        }
    }

    private static func add(
        _ credits: [String],
        on date: Date,
        calendar: Calendar,
        libraries: GoobyEventsLibraries,
        save: inout GoobyEventsSave
    ) {
        let active = activeEvents(on: date, forcedEventID: save.forcedEventID, calendar: calendar, libraries: libraries)
        for event in active {
            mutate(event, on: date, calendar: calendar, save: &save) { progress in
                for credit in credits where !progress.credits.contains(credit) {
                    progress.credits.append(credit)
                }
            }
        }
    }

    private static func mutate(
        _ event: GoobySeasonalEventDefinition,
        on date: Date,
        calendar: Calendar,
        save: inout GoobyEventsSave,
        change: (inout GoobyEventOccurrenceProgress) -> Void
    ) {
        guard let key = GoobyEventCalendar.occurrenceKey(event, on: date, calendar: calendar) else {
            return
        }
        var progress = save.eventProgress[key] ?? GoobyEventOccurrenceProgress(eventID: event.id, occurrenceKey: key, credits: [])
        let before = progress.credits.count
        change(&progress)
        guard progress.credits.count != before else {
            return
        }
        save.eventProgress[key] = progress
        if !save.eventsTouched.contains(event.id) {
            save.eventsTouched.append(event.id)
        }
    }

    private static func matches(kind: String, credit: String) -> Bool {
        if credit.hasPrefix("debug-\(kind)|") {
            return true
        }
        switch kind {
        case "habitDays":
            return credit.hasPrefix("habitDay|")
        case "habitCount":
            return credit.hasPrefix("habit|")
        case "reflections":
            return credit.hasPrefix("mood|") || credit.hasPrefix("journal|")
        case "calmSessions":
            return credit.hasPrefix("calm|")
        case "companionPlays":
            return credit.hasPrefix("play|")
        case "visits":
            return credit.hasPrefix("visit|")
        default:
            return false
        }
    }
}
