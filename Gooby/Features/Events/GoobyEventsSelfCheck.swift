import Foundation

enum GoobyEventsSelfCheck {
    static func failures(resourceDirectory: URL? = nil) -> [String] {
        let libraries = GoobyEventsLibraries.makeFallback()
        let calendar = GoobyDayKey.utc
        var failures: [String] = []
        checkCatalog(libraries, &failures)
        checkCalendar(libraries, calendar, &failures)
        checkQuests(libraries, calendar, &failures)
        checkEvents(libraries, calendar, &failures)
        checkEggs(libraries, calendar, &failures)
        checkCompanions(libraries, calendar, &failures)
        checkTimeAndReset(libraries, calendar, &failures)
        checkPersistence(&failures)
        checkNotifications(libraries, calendar, &failures)
        checkCopy(libraries, resourceDirectory, &failures)
        return failures
    }

    private static func checkCatalog(_ libraries: GoobyEventsLibraries, _ failures: inout [String]) {
        expect(libraries.events.count >= 11, "mindestens 11 Feste", &failures)
        expect(libraries.quests.count >= 10, "mindestens 10 Aufträge", &failures)
        expect(libraries.milestones.count >= 10, "mindestens 10 Meilensteine", &failures)
        expect(libraries.eggPool.count >= 12, "mindestens 12 Ei-Arten", &failures)
        expect(Set(libraries.events.map(\.id)).count == libraries.events.count, "Fest-IDs eindeutig", &failures)
        expect(Set(libraries.quests.map(\.id)).count == libraries.quests.count, "Auftrags-IDs eindeutig", &failures)
        expect(Set(libraries.species.map(\.id)).count == libraries.species.count, "Arten eindeutig", &failures)
        expect(Set(libraries.events.map(\.cosmeticID)).count == libraries.events.count, "Saisonstücke eindeutig", &failures)
        for event in libraries.events {
            expect(event.rewardSparks > 0, "Funken \(event.id)", &failures)
            expect(!event.cosmeticID.isEmpty, "Cosmetic \(event.id)", &failures)
            for objective in event.objectives {
                expect(GoobyEventCatalog.knownObjectiveKinds.contains(objective.kind), "Zielart \(objective.kind)", &failures)
                expect(objective.target > 0, "Ziel \(event.id)", &failures)
            }
            if let bonus = event.bonusSpeciesID {
                let species = libraries.species(bonus)
                expect(species != nil, "Bonusart \(bonus)", &failures)
                expect(species?.seasonalEventID == event.id, "Bonus gehört zum Fest \(event.id)", &failures)
            }
        }
        for species in libraries.species {
            expect(["common", "uncommon", "rare", "epic"].contains(species.rarity), "Seltenheit \(species.id)", &failures)
            expect(["bob", "hop", "drift", "flutter", "waddle", "twinkle"].contains(species.animation), "Animation \(species.id)", &failures)
            if let eventID = species.seasonalEventID {
                expect(libraries.event(eventID) != nil, "Saisonfest \(eventID)", &failures)
                expect(!libraries.eggPool.contains { $0.id == species.id }, "Saisonart nicht im Ei \(species.id)", &failures)
            }
        }
        for quest in libraries.quests {
            expect(quest.sparks > 0 && quest.target > 0, "Auftrag \(quest.id)", &failures)
        }
        expect(GoobyEventsLanguage.resolve(nil) == .german, "Standardsprache Deutsch", &failures)
        expect(GoobyEventsLanguage.resolve("de-DE") == .german, "de-DE", &failures)
        expect(GoobyEventsLanguage.resolve("fr") == .german, "unbekannte Sprache fällt auf Deutsch", &failures)
        expect(GoobyEventsLanguage.resolve("en-US") == .english, "en-US", &failures)
        expect(GoobyHabitIdentity.link(title: "Wasser trinken").id == "habit-wasser-trinken", "Gewohnheits-ID", &failures)
    }

    private static func checkCalendar(
        _ libraries: GoobyEventsLibraries,
        _ calendar: Calendar,
        _ failures: inout [String]
    ) {
        let samples: [(String, Int, Int, Int, Bool)] = [
            ("lantern-festival", 2026, 2, 1, true),
            ("lantern-festival", 2026, 2, 14, true),
            ("lantern-festival", 2026, 2, 15, false),
            ("spring-meadow", 2026, 3, 19, false),
            ("spring-meadow", 2026, 3, 20, true),
            ("spring-meadow", 2026, 4, 12, true),
            ("blossom-week", 2026, 4, 13, true),
            ("rainbow-week", 2026, 5, 14, true),
            ("rainbow-week", 2026, 5, 15, false),
            ("summer-picnic", 2026, 6, 21, true),
            ("summer-picnic", 2026, 7, 20, true),
            ("summer-picnic", 2026, 7, 21, false),
            ("starry-nights", 2026, 8, 18, true),
            ("leaf-walk", 2026, 9, 22, true),
            ("lantern-eve", 2026, 10, 31, true),
            ("lantern-eve", 2026, 11, 1, false),
            ("cozy-evenings", 2026, 11, 14, true),
            ("winter-warmth", 2026, 12, 1, true),
            ("winter-warmth", 2026, 12, 26, true),
            ("winter-warmth", 2026, 12, 27, false),
            ("new-year-sparkle", 2025, 12, 27, true),
            ("new-year-sparkle", 2026, 1, 5, true),
            ("new-year-sparkle", 2026, 1, 6, false),
            ("new-year-sparkle", 2026, 12, 26, false),
            ("new-year-sparkle", 2026, 12, 27, true),
            ("new-year-sparkle", 2026, 12, 31, true)
        ]
        for sample in samples {
            guard let event = libraries.event(sample.0) else {
                failures.append("Fest fehlt \(sample.0)")
                continue
            }
            let date = utcDate(sample.1, sample.2, sample.3)
            let active = GoobyEventCalendar.isActive(event, on: date, calendar: calendar)
            expect(active == sample.4, "\(sample.0) \(sample.1)-\(sample.2)-\(sample.3)", &failures)
        }
        guard let sparkle = libraries.event("new-year-sparkle") else {
            failures.append("Neujahr fehlt")
            return
        }
        let january = GoobyEventCalendar.containingWindow(sparkle, on: utcDate(2026, 1, 4), calendar: calendar)
        expect(calendar.component(.year, from: january?.start ?? .distantPast) == 2025, "Neujahr startet im Vorjahr", &failures)
        expect(calendar.component(.year, from: january?.end ?? .distantFuture) == 2026, "Neujahr endet im neuen Jahr", &failures)
        let december = GoobyEventCalendar.containingWindow(sparkle, on: utcDate(2026, 12, 28), calendar: calendar)
        expect(calendar.component(.year, from: december?.start ?? .distantPast) == 2026, "Dezember-Fenster", &failures)

        var day = utcDate(2024, 1, 1)
        let end = utcDate(2028, 12, 31)
        while day <= end {
            let active = libraries.events.filter { GoobyEventCalendar.isActive($0, on: day, calendar: calendar) }
            if active.count > 1 {
                failures.append("Überlappung \(GoobyDayKey.make(day, calendar: calendar))")
                break
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else {
                failures.append("Kalender blieb stehen")
                break
            }
            day = next
        }
        for event in libraries.events {
            guard let window = GoobyEventCalendar.relevantWindow(event, on: utcDate(2026, 6, 15), calendar: calendar) else {
                failures.append("Fenster fehlt \(event.id)")
                continue
            }
            expect(window.start <= window.end, "Fensterreihenfolge \(event.id)", &failures)
        }
    }

    private static func checkQuests(
        _ libraries: GoobyEventsLibraries,
        _ calendar: Calendar,
        _ failures: inout [String]
    ) {
        let quiet = utcDate(2026, 1, 15)
        var first = GoobyEventsSave()
        var second = GoobyEventsSave()
        _ = GoobyEventsGame.refresh(save: &first, now: quiet, calendar: calendar, libraries: libraries)
        _ = GoobyEventsGame.refresh(save: &second, now: quiet, calendar: calendar, libraries: libraries)
        let day = GoobyDayKey.make(quiet, calendar: calendar)
        let left = first.dailyBoards[day]?.quests.map(\.templateID)
        let right = second.dailyBoards[day]?.quests.map(\.templateID)
        expect(left?.count == 3 && left == right, "Tagesaufträge stabil", &failures)
        expect(left?.contains("companion-1") == false, "ohne Freund kein Spielauftrag", &failures)

        var differed = false
        let baseline = left ?? []
        for salt in 1...6 {
            var save = GoobyEventsSave()
            save.questSalt = UInt64(salt)
            _ = GoobyEventsGame.refresh(save: &save, now: quiet, calendar: calendar, libraries: libraries)
            let ids = save.dailyBoards[day]?.quests.map(\.templateID) ?? []
            if ids != baseline {
                differed = true
            }
        }
        expect(differed, "Salz ändert die Aufträge", &failures)

        var boardSave = GoobyEventsSave()
        boardSave.dailyBoards[day] = GoobyDailyBoard(
            dayKey: day,
            quests: [
                GoobyDailyQuestProgress(id: "\(day)#care-1", templateID: "care-1", progress: 0, creditKeys: [], claimed: false)
            ]
        )
        let once = GoobyEventsGame.record(save: &boardSave, signal: .habitCompleted(habitID: "habit-wasser"), now: quiet, calendar: calendar, libraries: libraries)
        let again = GoobyEventsGame.record(save: &boardSave, signal: .habitCompleted(habitID: "habit-wasser"), now: quiet, calendar: calendar, libraries: libraries)
        expect(once.contains { $0.id == "quest|\(day)#care-1" }, "Auftrag einmal belohnen", &failures)
        expect(once.contains { $0.id == "milestone|first-quest" }, "erster Meilenstein", &failures)
        expect(!again.contains { $0.source == "quest" || $0.source == "milestone" }, "keine zweite Belohnung", &failures)
        expect(once.allSatisfy { $0.starSparks >= 0 }, "keine negativen Funken", &failures)

        var rollover = GoobyEventsSave()
        rollover.dailyBoards[day] = GoobyDailyBoard(
            dayKey: day,
            quests: [
                GoobyDailyQuestProgress(id: "\(day)#care-1", templateID: "care-1", progress: 1, creditKeys: ["habit-wasser"], claimed: false)
            ]
        )
        let nextDay = utcDate(2026, 1, 16)
        let settled = GoobyEventsGame.refresh(save: &rollover, now: nextDay, calendar: calendar, libraries: libraries)
        let settledAgain = GoobyEventsGame.refresh(save: &rollover, now: nextDay, calendar: calendar, libraries: libraries)
        expect(settled.contains { $0.id == "quest|\(day)#care-1" }, "gestern automatisch holen", &failures)
        expect(!settledAgain.contains { $0.source == "quest" }, "nicht doppelt holen", &failures)

        var reroll = GoobyEventsSave()
        let claimedID = "\(day)#care-1"
        reroll.dailyBoards[day] = GoobyDailyBoard(
            dayKey: day,
            quests: [
                GoobyDailyQuestProgress(id: claimedID, templateID: "care-1", progress: 1, creditKeys: ["x"], claimed: true),
                GoobyDailyQuestProgress(id: "\(day)#mood-1", templateID: "mood-1", progress: 0, creditKeys: [], claimed: false),
                GoobyDailyQuestProgress(id: "\(day)#calm-1", templateID: "calm-1", progress: 0, creditKeys: [], claimed: false)
            ]
        )
        reroll.claimedQuestIDs = [claimedID]
        reroll.totalQuestsCompleted = 1
        GoobyQuestEngine.reroll(save: &reroll, dayKey: day, libraries: libraries)
        expect(reroll.totalQuestsCompleted == 1, "Neu mischen zahlt nicht noch einmal", &failures)
        expect(reroll.dailyBoards[day]?.quests.contains { $0.id == claimedID && $0.claimed } == true, "geholter Auftrag bleibt", &failures)
    }

    private static func checkEvents(
        _ libraries: GoobyEventsLibraries,
        _ calendar: Calendar,
        _ failures: inout [String]
    ) {
        let quiet = utcDate(2026, 3, 1)
        var quietSave = GoobyEventsSave()
        _ = GoobyEventsGame.record(save: &quietSave, signal: .habitCompleted(habitID: "habit-wasser"), now: quiet, calendar: calendar, libraries: libraries)
        expect(quietSave.eventProgress.isEmpty, "außerhalb der Saison kein Fortschritt", &failures)

        var forced = GoobyEventsSave()
        forced.forcedEventID = "winter-warmth"
        _ = GoobyEventsGame.record(save: &forced, signal: .habitCompleted(habitID: "habit-wasser"), now: quiet, calendar: calendar, libraries: libraries)
        expect(forced.eventProgress.keys.contains { $0.hasPrefix("winter-warmth#") }, "manuelles Fest zählt", &failures)

        var spring = GoobyEventsSave()
        let start = utcDate(2026, 3, 21)
        let companion = GoobyCompanionEngine.addCompanion(
            save: &spring,
            speciesID: "chick",
            day: GoobyDayKey.make(start, calendar: calendar),
            origin: "debug",
            libraries: libraries
        )
        for offset in 0..<4 {
            let date = utcDate(2026, 3, 21 + offset)
            _ = GoobyEventsGame.record(
                save: &spring,
                signal: .habitCompleted(habitID: "habit-\(offset)"),
                now: date,
                calendar: calendar,
                libraries: libraries
            )
        }
        _ = GoobyEventsGame.record(save: &spring, signal: .moodLogged, now: start, calendar: calendar, libraries: libraries)
        _ = GoobyEventsGame.record(save: &spring, signal: .journalWritten, now: start, calendar: calendar, libraries: libraries)
        if let companion {
            _ = GoobyEventsGame.record(save: &spring, signal: .companionPlayed(companionID: companion.id), now: start, calendar: calendar, libraries: libraries)
        }
        guard let event = libraries.event("spring-meadow"), let key = GoobyEventCalendar.occurrenceKey(event, on: start, calendar: calendar) else {
            failures.append("Frühlingsfenster fehlt")
            return
        }
        let progress = spring.eventProgress[key] ?? GoobyEventOccurrenceProgress(eventID: event.id, occurrenceKey: key, credits: [])
        expect(GoobyEventEngine.isComplete(event, progress: progress), "Frühlingswiese vollständig", &failures)
        var emptyProgress = GoobyEventsSave()
        let tooSoon = GoobyEventEngine.claim(save: &emptyProgress, eventID: event.id, date: start, calendar: calendar, libraries: libraries, free: false)
        expect(tooSoon.isEmpty, "unfertig keine Belohnung", &failures)
        let claimed = GoobyEventEngine.claim(save: &spring, eventID: event.id, date: start, calendar: calendar, libraries: libraries, free: false)
        let claimedAgain = GoobyEventEngine.claim(save: &spring, eventID: event.id, date: start, calendar: calendar, libraries: libraries, free: false)
        expect(claimed.first?.starSparks == 45, "Frühlingsfunken", &failures)
        expect(claimed.first?.companionSpeciesID == "blossom-beetle", "Blütenkäfer", &failures)
        expect(claimedAgain.isEmpty, "Festbelohnung nur einmal", &failures)

        var freeSave = GoobyEventsSave()
        let free = GoobyEventEngine.claim(save: &freeSave, eventID: "lantern-festival", date: quiet, calendar: calendar, libraries: libraries, free: true)
        let freeAgain = GoobyEventEngine.claim(save: &freeSave, eventID: "lantern-festival", date: quiet, calendar: calendar, libraries: libraries, free: true)
        let afterFree = GoobyEventEngine.claim(save: &freeSave, eventID: "lantern-festival", date: quiet, calendar: calendar, libraries: libraries, free: false)
        expect(free.first?.starSparks == 40 && freeAgain.isEmpty && afterFree.isEmpty, "freie Belohnung bleibt einmalig", &failures)

        var simulated = GoobyEventsSave()
        GoobyEventEngine.simulate(save: &simulated, eventID: "cozy-evenings", steps: 30, date: utcDate(2026, 11, 3), calendar: calendar, libraries: libraries)
        if let cozy = libraries.event("cozy-evenings"), let cozyKey = GoobyEventCalendar.occurrenceKey(cozy, on: utcDate(2026, 11, 3), calendar: calendar) {
            let cozyProgress = simulated.eventProgress[cozyKey]!
            expect(GoobyEventEngine.isComplete(cozy, progress: cozyProgress), "Simulation schafft das Fest", &failures)
            for objective in cozy.objectives {
                let count = GoobyEventEngine.creditCount(kind: objective.kind, credits: cozyProgress.credits)
                expect(count == objective.target, "Simulation stoppt am Ziel \(objective.kind)", &failures)
            }
        } else {
            failures.append("Simulation ohne Fortschritt")
        }
    }

    private static func checkEggs(
        _ libraries: GoobyEventsLibraries,
        _ calendar: Calendar,
        _ failures: inout [String]
    ) {
        var save = GoobyEventsSave()
        let start = utcDate(2026, 1, 15)
        let habit = GoobyHabitLink(id: "habit-wasser", title: "Wasser")
        guard GoobyCompanionEngine.bindEgg(save: &save, habit: habit, day: GoobyDayKey.make(start, calendar: calendar)) != nil else {
            failures.append("Ei ließ sich nicht binden")
            return
        }
        _ = GoobyEventsGame.record(save: &save, signal: .habitCompleted(habitID: "habit-wasser"), now: utcDate(2026, 1, 14), calendar: calendar, libraries: libraries)
        expect(save.eggs[0].validDays.isEmpty, "vor dem Binden zählt nicht", &failures)
        _ = GoobyEventsGame.record(save: &save, signal: .habitCompleted(habitID: "habit-wasser"), now: start, calendar: calendar, libraries: libraries)
        _ = GoobyEventsGame.record(save: &save, signal: .habitCompleted(habitID: "habit-wasser"), now: start, calendar: calendar, libraries: libraries)
        _ = GoobyEventsGame.record(save: &save, signal: .habitCompleted(habitID: "habit-andere"), now: start, calendar: calendar, libraries: libraries)
        expect(save.eggs[0].validDays.count == 1, "ein Tag zählt einmal", &failures)
        for offset in 1..<6 {
            _ = GoobyEventsGame.record(
                save: &save,
                signal: .habitCompleted(habitID: "habit-wasser"),
                now: utcDate(2026, 1, 15 + offset),
                calendar: calendar,
                libraries: libraries
            )
        }
        expect(save.eggs[0].validDays.count == 6 && save.eggs[0].hatchedCompanionID == nil, "sechs Tage noch im Ei", &failures)
        let hatchGrants = GoobyEventsGame.record(
            save: &save,
            signal: .habitCompleted(habitID: "habit-wasser"),
            now: utcDate(2026, 1, 21),
            calendar: calendar,
            libraries: libraries
        )
        expect(save.eggs[0].validDays.count == 7, "sieben gültige Tage", &failures)
        expect(save.companions.count == 1, "geschlüpft", &failures)
        expect(libraries.eggPool.contains { $0.id == save.companions.first?.speciesID }, "Art aus dem Ei-Pool", &failures)
        expect(hatchGrants.contains { $0.source == "companion" }, "Schlüpf-Grant", &failures)
        expect(hatchGrants.contains { $0.id == "milestone|first-hatch" }, "Meilenstein Schlüpfen", &failures)
        let egg = save.eggs[0]
        let material = egg.rollSeed ^ GoobySeededGenerator.hash(egg.validDays.joined(separator: "|"))
        let picked = GoobyCompanionEngine.pickSpecies(seed: material, pool: libraries.eggPool)
        expect(picked?.id == save.companions.first?.speciesID, "Wurf bleibt gleich", &failures)
        _ = GoobyEventsGame.record(
            save: &save,
            signal: .habitCompleted(habitID: "habit-wasser"),
            now: utcDate(2026, 1, 22),
            calendar: calendar,
            libraries: libraries
        )
        expect(save.companions.count == 1, "kein zweites Schlüpfen", &failures)

        var seen = Set<String>()
        var duplicate = false
        for seed in 1...80 {
            guard let species = GoobyCompanionEngine.pickSpecies(seed: UInt64(seed), pool: libraries.eggPool) else {
                failures.append("leerer Wurf")
                break
            }
            if !seen.insert(species.id).inserted {
                duplicate = true
            }
        }
        expect(duplicate && seen.count > 1, "doppelte Mini-Freunde möglich", &failures)
    }

    private static func checkCompanions(
        _ libraries: GoobyEventsLibraries,
        _ calendar: Calendar,
        _ failures: inout [String]
    ) {
        var save = GoobyEventsSave()
        let day = "2026-01-15"
        _ = GoobyCompanionEngine.addCompanion(save: &save, speciesID: "chick", day: day, origin: "event", libraries: libraries)
        _ = GoobyCompanionEngine.addCompanion(save: &save, speciesID: "chick", day: day, origin: "event", libraries: libraries)
        expect(save.companions.filter { $0.speciesID == "chick" }.count == 2, "dieselbe Art zweimal", &failures)
        GoobyCompanionEngine.select(save: &save, companionID: save.companions[0].id)
        expect(save.selectedCompanionID == save.companions[0].id, "Auswahl", &failures)
        GoobyCompanionEngine.select(save: &save, companionID: nil)
        expect(save.selectedCompanionID == nil, "Auswahl leer", &failures)
        let friend = save.companions[0].id
        for offset in 0..<4 {
            _ = GoobyCompanionEngine.play(save: &save, companionID: friend, day: "2026-02-\(10 + offset)")
        }
        expect(GoobyCompanionGrowth.stage(playCount: save.companions[0].playCount) == "little", "Stufe vertraut", &failures)
        _ = GoobyCompanionEngine.play(save: &save, companionID: friend, day: "2026-02-10")
        expect(save.companions[0].playCount == 4, "derselbe Tag zählt nicht doppelt", &failures)
        for offset in 0..<6 {
            _ = GoobyCompanionEngine.play(save: &save, companionID: friend, day: "2026-03-\(offset + 1)")
        }
        expect(GoobyCompanionGrowth.stage(playCount: save.companions[0].playCount) == "grown", "Stufe zu Hause", &failures)
        let before = save.companions.count
        _ = GoobyCompanionEngine.unlockMissing(save: &save, day: day, libraries: libraries)
        let afterFirst = save.companions.count
        _ = GoobyCompanionEngine.unlockMissing(save: &save, day: day, libraries: libraries)
        let speciesIDs = Set(save.companions.map(\.speciesID))
        expect(afterFirst == before + libraries.species.count - 1, "fehlende Arten werden ergänzt", &failures)
        expect(save.companions.count == afterFirst && speciesIDs.count == libraries.species.count, "Freischalten bleibt stabil", &failures)
    }

    private static func checkTimeAndReset(
        _ libraries: GoobyEventsLibraries,
        _ calendar: Calendar,
        _ failures: inout [String]
    ) {
        var save = GoobyEventsSave()
        let quiet = utcDate(2026, 3, 1)
        GoobyEventsGame.setTimeTravel(save: &save, date: utcDate(2026, 3, 21), now: quiet, calendar: calendar, libraries: libraries)
        let effective = GoobyEventsGame.effectiveDate(save: save, now: quiet)
        expect(GoobyDayKey.make(effective, calendar: calendar) == "2026-03-21", "Zeitreise setzt den App-Tag", &failures)
        let active = GoobyEventEngine.activeEvents(on: effective, forcedEventID: save.forcedEventID, calendar: calendar, libraries: libraries)
        expect(active.contains { $0.id == "spring-meadow" }, "Zeitreise öffnet das Fest", &failures)
        let traveled = GoobyEventsGame.applyTimeTravel(save: &save, preset: .today, now: quiet, calendar: calendar, libraries: libraries)
        expect(GoobyDayKey.make(traveled, calendar: calendar) == "2026-03-01", "Heute beendet die Zeitreise", &failures)

        var seeded = GoobyEventsSave()
        GoobyEventsGame.configure(save: &seeded, seed: 99)
        expect(seeded.seed == 99, "Seed beim ersten Mal", &failures)
        GoobyEventsGame.configure(save: &seeded, seed: 100)
        expect(seeded.seed == 99, "Seed bleibt", &failures)

        GoobyEventsGame.resetAll(save: &save)
        _ = GoobyEventsGame.refresh(save: &save, now: quiet, calendar: calendar, libraries: libraries)
        expect(save.eventProgress.isEmpty && save.companions.isEmpty, "Reset ist leer und gültig", &failures)
        expect(save.dailyBoards[GoobyDayKey.make(quiet, calendar: calendar)]?.quests.count == 3, "nach Reset neue Aufträge", &failures)
        let model = GoobyEventsPresenter.screen(save: save, language: .german, now: quiet, calendar: calendar, libraries: libraries)
        expect(model.events.contains { $0.name == "Frühlingswiese" }, "deutscher Festname", &failures)
        let english = GoobyEventsPresenter.screen(save: save, language: .english, now: quiet, calendar: calendar, libraries: libraries)
        expect(english.events.contains { $0.name == "Spring Meadow" }, "englischer Festname", &failures)
    }

    private static func checkPersistence(_ failures: inout [String]) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("gooby-events-\(UUID().uuidString)", isDirectory: true)
        let url = directory.appendingPathComponent("events-world.json")
        let repository = GoobyEventsRepository(fileURL: url, loadFromDisk: false)
        repository.modify { save in
            save.eggsEverBound = 3
            save.log("Prüfung")
        }
        repository.modify { save in
            save.eggsEverBound = 4
        }
        let loaded = GoobyEventsRepository(fileURL: url)
        expect(loaded.save.eggsEverBound == 4, "Speicher kehrt zurück", &failures)
        try? Data("kaputt".utf8).write(to: url)
        let recovered = GoobyEventsRepository(fileURL: url)
        expect(recovered.save.eggsEverBound == 3, "Backup rettet den Stand", &failures)
        try? Data("auch-kaputt".utf8).write(to: recovered.backupURL)
        let empty = GoobyEventsRepository(fileURL: url)
        expect(empty.save.eggsEverBound == 0 && empty.save.version == GoobyEventsSave.currentVersion, "kaputter Speicher startet leer", &failures)
        try? FileManager.default.removeItem(at: directory)
    }

    private static func checkNotifications(
        _ libraries: GoobyEventsLibraries,
        _ calendar: Calendar,
        _ failures: inout [String]
    ) {
        var save = GoobyEventsSave()
        let now = utcDate(2026, 4, 10, 8)
        let day = GoobyDayKey.make(now, calendar: calendar)
        save.dailyBoards[day] = GoobyDailyBoard(
            dayKey: day,
            quests: [GoobyDailyQuestProgress(id: "\(day)#care-1", templateID: "care-1", progress: 0, creditKeys: [], claimed: false)]
        )
        save.eggs = [
            GoobyEggRecord(
                id: "egg-1",
                habitID: "habit-wasser",
                habitTitle: "Wasser",
                boundDay: "2026-04-01",
                validDays: ["1", "2", "3", "4", "5", "6"],
                rollSeed: 1,
                hatchedCompanionID: nil
            )
        ]
        let planned = GoobyNotificationPlanner.plan(save: save, language: .german, now: now, calendar: calendar, libraries: libraries)
        let ids = Set(planned.map(\.id))
        expect(ids.contains(GoobyNotificationPlanner.dailyID), "Auftragserinnerung", &failures)
        expect(ids.contains(GoobyNotificationPlanner.eggID), "Eierinnerung", &failures)
        expect(ids.contains(GoobyNotificationPlanner.startID), "Festbeginn", &failures)
        expect(ids.contains(GoobyNotificationPlanner.endingID), "Festende", &failures)
        expect(planned.allSatisfy { $0.fireDate > now }, "Erinnerungen liegen in der Zukunft", &failures)
        expect(planned.contains { $0.body.contains("Blütenwoche") || $0.body.contains("Frühlingswiese") }, "Festname in der Erinnerung", &failures)

        if var board = save.dailyBoards[day], !board.quests.isEmpty {
            board.quests[0].claimed = true
            save.dailyBoards[day] = board
        }
        save.eggs[0].validDays = ["1", "2", "3", "4", "5"]
        let quieter = GoobyNotificationPlanner.plan(save: save, language: .english, now: now, calendar: calendar, libraries: libraries)
        let quietIDs = Set(quieter.map(\.id))
        expect(!quietIDs.contains(GoobyNotificationPlanner.dailyID), "erledigte Aufträge erinnern nicht", &failures)
        expect(!quietIDs.contains(GoobyNotificationPlanner.eggID), "fünf Tage erinnern noch nicht", &failures)
    }

    private static func checkCopy(
        _ libraries: GoobyEventsLibraries,
        _ resourceDirectory: URL?,
        _ failures: inout [String]
    ) {
        expect(Set(libraries.copyDE.keys) == Set(libraries.copyEN.keys), "gleiche Textschlüssel", &failures)
        let required = [
            "hub.title", "hub.events", "hub.quests", "hub.nest", "nest.lead", "events.claim",
            "quests.lead", "note.daily.title", "note.egg.body", "banner.sparks", "stage.baby"
        ]
        for key in required {
            expect(libraries.copyDE[key] != nil && libraries.copyEN[key] != nil, "Text \(key)", &failures)
        }
        guard let resourceDirectory else {
            return
        }
        guard let loaded = GoobyEventsResourceLoader.load(directory: resourceDirectory) else {
            failures.append("Ressourcen lassen sich nicht lesen")
            return
        }
        expect(loaded == libraries, "JSON entspricht dem Katalog", &failures)
    }

    private static func utcDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        var parts = DateComponents()
        parts.calendar = GoobyDayKey.utc
        parts.timeZone = TimeZone(secondsFromGMT: 0)
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.minute = 0
        parts.second = 0
        return GoobyDayKey.utc.date(from: parts) ?? .distantPast
    }

    private static func expect(_ condition: Bool, _ message: String, _ failures: inout [String]) {
        if !condition {
            failures.append(message)
        }
    }
}
