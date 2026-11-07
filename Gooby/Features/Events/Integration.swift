import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Einziger Einstieg für die App-Hülle.
///
/// Feste, Tagesaufträge und Mini-Freunde bleiben lokal. Es gibt keine Event-API.
/// Die Hülle schreibt `starSparks` aus den Grants auf das lokale Konto. Grants sind
/// nie negativ. Ein Grant mit 0 Funken und einer `companionSpeciesID` bedeutet ein
/// neues Schlüpfen. Kosmetik-IDs trägt `cosmeticIDs` für den Shop.
///
/// Signale, die aus Gewohnheiten, Stimmung, Tagebuch, Ruhe, Gooby, Abenteuer und
/// dem Tagesziel kommen, schickt die Hülle an `record`. Besuch, Spiel, Ei und
/// Festbelohnung entstehen in `hubView`. Dafür `onRewards` setzen, dieselbe Funktion
/// wie für die Rückgaben von `record`. Den Mini-Freund neben Gooby zeigt
/// `companionBadge`.
///
/// Der Spielstand liegt unter Application Support/Gooby/events-world.json, mit
/// Backup events-world.bak, und ist vom iCloud-Backup ausgenommen.
///
/// Zeitreise über `debug().setTimeTravel` gilt nur für diese Systeme.
/// `scheduleLocalNotifications` nutzt die übergebene Uhr, standardmäßig `Date()`,
/// und stellt die Systemuhr nicht um. Dafür braucht die Hülle in Info.plist
/// `NSUserNotificationsUsageDescription`, zum Beispiel:
/// „Gooby erinnert dich an Feste, Tagesaufträge und Eier, die bald schlüpfen.“
enum GoobyEventsIntegration {
    static let sliceVersion = "1.0.0"
    static let didChangeNotification = Notification.Name.goobyEventsDidChange

    nonisolated(unsafe) private static var didLoadResources = false

    static func ensureResources() {
        if didLoadResources {
            return
        }
        didLoadResources = true
        GoobyEventsResourceLoader.loadFromBundle()
    }

    @discardableResult
    static func configure(seed: UInt64) -> UInt64 {
        ensureResources()
        GoobyEventsRepository.shared.modify { save in
            GoobyEventsGame.configure(save: &save, seed: seed)
        }
        return GoobyEventsRepository.shared.save.seed
    }

    @discardableResult
    static func refresh(
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> [GoobyRewardGrant] {
        mutate { save in
            GoobyEventsGame.refresh(save: &save, now: now, calendar: calendar, libraries: libraries)
        }
    }

    @discardableResult
    static func record(
        _ signal: GoobyCareSignal,
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> [GoobyRewardGrant] {
        mutate { save in
            GoobyEventsGame.record(save: &save, signal: signal, now: now, calendar: calendar, libraries: libraries)
        }
    }

    @discardableResult
    static func bindEgg(
        habit: GoobyHabitLink,
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> GoobyEggBindResult {
        var snapshot: GoobyEggSnapshot?
        let grants = mutate { save in
            let day = GoobyDayKey.make(GoobyEventsGame.effectiveDate(save: save, now: now), calendar: calendar)
            guard let egg = GoobyCompanionEngine.bindEgg(save: &save, habit: habit, day: day) else {
                return []
            }
            snapshot = GoobyEggSnapshot(
                id: egg.id,
                habitID: egg.habitID,
                habitTitle: egg.habitTitle,
                validDays: egg.validDays.count,
                requiredDays: GoobyCompanionGrowth.requiredEggDays,
                hatchedCompanionID: nil
            )
            return GoobyMilestoneEngine.evaluate(save: &save, dayKey: day, libraries: libraries)
        }
        return GoobyEggBindResult(egg: snapshot, grants: grants)
    }

    @discardableResult
    static func bindEgg(
        habitTitle: String,
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> GoobyEggBindResult {
        bindEgg(habit: GoobyHabitIdentity.link(title: habitTitle), now: now, calendar: calendar)
    }

    static func selectCompanion(id: String?) {
        GoobyEventsRepository.shared.modify { save in
            GoobyCompanionEngine.select(save: &save, companionID: id)
        }
    }

    static func renameCompanion(id: String, name: String) {
        GoobyEventsRepository.shared.modify { save in
            GoobyCompanionEngine.rename(save: &save, companionID: id, name: name)
        }
    }

    static func dismissHatch(id: String) {
        GoobyEventsRepository.shared.modify { save in
            GoobyCompanionEngine.dismissHatch(save: &save, companionID: id)
        }
    }

    @discardableResult
    static func claimEvent(
        id: String,
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> [GoobyRewardGrant] {
        mutate { save in
            let date = GoobyEventsGame.effectiveDate(save: save, now: now)
            let grants = GoobyEventEngine.claim(
                save: &save,
                eventID: id,
                date: date,
                calendar: calendar,
                libraries: libraries,
                free: false
            )
            let day = GoobyDayKey.make(date, calendar: calendar)
            return grants + GoobyMilestoneEngine.evaluate(save: &save, dayKey: day, libraries: libraries)
        }
    }

    static func screen(
        languageCode: String = "de",
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> GoobyEventsScreenModel {
        ensureResources()
        let save = GoobyEventsRepository.shared.save
        return GoobyEventsPresenter.screen(
            save: save,
            language: GoobyEventsLanguage.resolve(languageCode),
            now: now,
            calendar: calendar,
            libraries: libraries
        )
    }

    static func selectedCompanion(languageCode: String = "de") -> GoobyCompanionSnapshot? {
        screen(languageCode: languageCode).companions.first(where: \.selected)
    }

    static func plannedNotifications(
        languageCode: String = "de",
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> [GoobyPlannedNotification] {
        ensureResources()
        return GoobyNotificationPlanner.plan(
            save: GoobyEventsRepository.shared.save,
            language: GoobyEventsLanguage.resolve(languageCode),
            now: now,
            calendar: calendar,
            libraries: libraries
        )
    }

    static func scheduleLocalNotifications(
        languageCode: String = "de",
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) async -> GoobyNotificationScheduleResult {
        ensureResources()
        #if canImport(UserNotifications)
        let planned = plannedNotifications(languageCode: languageCode, now: now, calendar: calendar)
        return await GoobyNotificationPlanner.schedule(planned: planned, libraries: libraries)
        #else
        return unavailableNotifications()
        #endif
    }

    static func debug() -> GoobyEventsDebugHooks {
        ensureResources()
        return GoobyEventsDebugHooks()
    }

    static func diagnosticReport(
        languageCode: String = "de",
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> String {
        ensureResources()
        let repository = GoobyEventsRepository.shared
        return GoobyEventsPresenter.diagnostic(
            save: repository.save,
            language: GoobyEventsLanguage.resolve(languageCode),
            now: now,
            calendar: calendar,
            libraries: libraries,
            filePath: repository.fileURL.path,
            lastError: repository.lastError
        )
    }

    #if canImport(SwiftUI)
    @MainActor
    static func hubView(
        languageCode: String = "de",
        now: Date = Date(),
        habits: [GoobyHabitLink] = [],
        calendar: Calendar = GoobyDayKey.calendar(),
        onRewards: @escaping ([GoobyRewardGrant]) -> Void = { _ in }
    ) -> some View {
        GoobyEventsHubView(
            languageCode: languageCode,
            now: now,
            habits: habits,
            calendar: calendar,
            onRewards: onRewards
        )
    }

    @MainActor
    static func companionBadge(
        languageCode: String = "de",
        now: Date = Date()
    ) -> some View {
        GoobyCompanionBadgeSlot(languageCode: languageCode, now: now)
    }
    #endif

    static var libraries: GoobyEventsLibraries {
        GoobyEventsLibraries.current
    }

    @discardableResult
    private static func mutate(_ body: (inout GoobyEventsSave) -> [GoobyRewardGrant]) -> [GoobyRewardGrant] {
        ensureResources()
        return GoobyEventsRepository.shared.update { save in
            body(&save)
        }
    }

    private static func unavailableNotifications() -> GoobyNotificationScheduleResult {
        GoobyNotificationScheduleResult(
            scheduledIDs: [],
            authorization: "unavailable",
            messageDE: libraries.text("note.unavailable", language: .german),
            messageEN: libraries.text("note.unavailable", language: .english)
        )
    }
}

struct GoobyEventsDebugHooks {
    func snapshot(
        languageCode: String = "de",
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> GoobyEventsScreenModel {
        GoobyEventsIntegration.screen(languageCode: languageCode, now: now, calendar: calendar)
    }

    func events() -> [GoobySeasonalEventDefinition] {
        GoobyEventsIntegration.libraries.events
    }

    func startEvent(id: String?) {
        GoobyEventsRepository.shared.modify { save in
            GoobyEventsGame.setForcedEvent(save: &save, eventID: id, libraries: GoobyEventsIntegration.libraries)
        }
    }

    func simulate(
        eventID: String,
        steps: Int,
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) {
        GoobyEventsRepository.shared.modify { save in
            let date = GoobyEventsGame.effectiveDate(save: save, now: now)
            GoobyEventEngine.simulate(
                save: &save,
                eventID: eventID,
                steps: steps,
                date: date,
                calendar: calendar,
                libraries: GoobyEventsIntegration.libraries
            )
        }
    }

    @discardableResult
    func grantEventRewards(
        eventID: String,
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> [GoobyRewardGrant] {
        GoobyEventsRepository.shared.update { save in
            let date = GoobyEventsGame.effectiveDate(save: save, now: now)
            let grants = GoobyEventEngine.claim(
                save: &save,
                eventID: eventID,
                date: date,
                calendar: calendar,
                libraries: GoobyEventsIntegration.libraries,
                free: true
            )
            let day = GoobyDayKey.make(date, calendar: calendar)
            return grants + GoobyMilestoneEngine.evaluate(save: &save, dayKey: day, libraries: GoobyEventsIntegration.libraries)
        }
    }

    func resetEventProgress(eventID: String? = nil) {
        GoobyEventsRepository.shared.modify { save in
            GoobyEventEngine.reset(save: &save, eventID: eventID)
        }
    }

    func calendar(
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> [GoobyEventCalendarEntry] {
        let save = GoobyEventsRepository.shared.save
        let date = GoobyEventsGame.effectiveDate(save: save, now: now)
        return GoobyEventCalendar.entries(on: date, calendar: calendar, events: GoobyEventsIntegration.libraries.events)
    }

    func setTimeTravel(_ date: Date?, now: Date = Date(), calendar: Calendar = GoobyDayKey.calendar()) {
        GoobyEventsRepository.shared.modify { save in
            GoobyEventsGame.setTimeTravel(save: &save, date: date, now: now, calendar: calendar, libraries: GoobyEventsIntegration.libraries)
        }
    }

    @discardableResult
    func applyTimeTravel(
        _ preset: GoobyTimeTravelPreset,
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> Date {
        var resolved = now
        GoobyEventsRepository.shared.modify { save in
            resolved = GoobyEventsGame.applyTimeTravel(
                save: &save,
                preset: preset,
                now: now,
                calendar: calendar,
                libraries: GoobyEventsIntegration.libraries
            )
        }
        return resolved
    }

    func resetQuests(now: Date = Date(), calendar: Calendar = GoobyDayKey.calendar()) {
        GoobyEventsRepository.shared.modify { save in
            GoobyQuestEngine.reset(save: &save, libraries: GoobyEventsIntegration.libraries)
            _ = GoobyEventsGame.refresh(save: &save, now: now, calendar: calendar, libraries: GoobyEventsIntegration.libraries)
        }
    }

    @discardableResult
    func completeQuest(
        id: String,
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> [GoobyRewardGrant] {
        GoobyEventsRepository.shared.update { save in
            let date = GoobyEventsGame.effectiveDate(save: save, now: now)
            let day = GoobyDayKey.make(date, calendar: calendar)
            let grants = GoobyQuestEngine.complete(save: &save, questID: id, dayKey: day, libraries: GoobyEventsIntegration.libraries)
            return grants + GoobyMilestoneEngine.evaluate(save: &save, dayKey: day, libraries: GoobyEventsIntegration.libraries)
        }
    }

    func rerollDailyQuests(now: Date = Date(), calendar: Calendar = GoobyDayKey.calendar()) {
        GoobyEventsRepository.shared.modify { save in
            let date = GoobyEventsGame.effectiveDate(save: save, now: now)
            let day = GoobyDayKey.make(date, calendar: calendar)
            GoobyQuestEngine.ensureBoard(save: &save, dayKey: day, libraries: GoobyEventsIntegration.libraries)
            GoobyQuestEngine.reroll(save: &save, dayKey: day, libraries: GoobyEventsIntegration.libraries)
        }
    }

    @discardableResult
    func testQuestRewards(
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> [GoobyRewardGrant] {
        GoobyEventsRepository.shared.update { save in
            let date = GoobyEventsGame.effectiveDate(save: save, now: now)
            let day = GoobyDayKey.make(date, calendar: calendar)
            GoobyQuestEngine.ensureBoard(save: &save, dayKey: day, libraries: GoobyEventsIntegration.libraries)
            let grants = GoobyQuestEngine.testRewards(save: &save, dayKey: day, libraries: GoobyEventsIntegration.libraries)
            return grants + GoobyMilestoneEngine.evaluate(save: &save, dayKey: day, libraries: GoobyEventsIntegration.libraries)
        }
    }

    @discardableResult
    func unlockAllCompanions(
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> GoobyCompanionUnlockResult {
        let grants = GoobyEventsRepository.shared.update { save in
            let date = GoobyEventsGame.effectiveDate(save: save, now: now)
            let day = GoobyDayKey.make(date, calendar: calendar)
            _ = GoobyCompanionEngine.unlockMissing(save: &save, day: day, libraries: GoobyEventsIntegration.libraries)
            return GoobyMilestoneEngine.evaluate(save: &save, dayKey: day, libraries: GoobyEventsIntegration.libraries)
        }
        return GoobyCompanionUnlockResult(
            companions: GoobyEventsIntegration.screen(now: now, calendar: calendar).companions,
            grants: grants
        )
    }

    func resetCompanions() {
        GoobyEventsRepository.shared.modify { save in
            GoobyCompanionEngine.reset(save: &save)
        }
    }

    func resetAll() {
        GoobyEventsRepository.shared.modify { save in
            GoobyEventsGame.resetAll(save: &save)
        }
    }

    func forceHatch(
        eggID: String,
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> GoobyForcedHatchResult {
        let grants = GoobyEventsRepository.shared.update { save in
            let date = GoobyEventsGame.effectiveDate(save: save, now: now)
            let day = GoobyDayKey.make(date, calendar: calendar)
            _ = GoobyCompanionEngine.forceHatch(save: &save, eggID: eggID, day: day, libraries: GoobyEventsIntegration.libraries)
            return GoobyMilestoneEngine.evaluate(save: &save, dayKey: day, libraries: GoobyEventsIntegration.libraries)
        }
        let companion = GoobyEventsIntegration.screen(now: now, calendar: calendar).companions.first { companion in
            GoobyEventsRepository.shared.save.eggs.contains { $0.id == eggID && $0.hatchedCompanionID == companion.id }
        }
        return GoobyForcedHatchResult(companion: companion, grants: grants)
    }

    func runSelfCheck(resourceDirectory: URL? = nil) -> [String] {
        GoobyEventsSelfCheck.failures(resourceDirectory: resourceDirectory)
    }

    func diagnosticReport(
        languageCode: String = "de",
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> String {
        GoobyEventsIntegration.diagnosticReport(languageCode: languageCode, now: now, calendar: calendar)
    }

    func plannedNotifications(
        languageCode: String = "de",
        now: Date = Date(),
        calendar: Calendar = GoobyDayKey.calendar()
    ) -> [GoobyPlannedNotification] {
        GoobyEventsIntegration.plannedNotifications(languageCode: languageCode, now: now, calendar: calendar)
    }

    func scheduleTestNotification(languageCode: String = "de") async -> GoobyNotificationScheduleResult {
        #if canImport(UserNotifications)
        return await GoobyNotificationPlanner.scheduleTest(
            language: GoobyEventsLanguage.resolve(languageCode),
            libraries: GoobyEventsIntegration.libraries
        )
        #else
        return GoobyNotificationScheduleResult(
            scheduledIDs: [],
            authorization: "unavailable",
            messageDE: GoobyEventsIntegration.libraries.text("note.unavailable", language: .german),
            messageEN: GoobyEventsIntegration.libraries.text("note.unavailable", language: .english)
        )
        #endif
    }
}
