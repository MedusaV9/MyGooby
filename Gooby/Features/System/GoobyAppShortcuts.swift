import AppIntents
import Foundation

enum GoobyIntentText {
    static func language() -> String {
        if let snapshot = GoobySharedStore.loadSnapshot() { return snapshot.language }
        return Locale.preferredLanguages.first?.hasPrefix("en") == true ? "en" : "de"
    }

    static func t(_ key: String) -> String { StringTable.text(key, language()) }

    static func tf(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), locale: Locale(identifier: language()), arguments: args)
    }

    static func status() -> String {
        guard let snapshot = GoobySharedStore.loadSnapshot() else { return t("system.siri.empty") }
        let today = snapshot.isCurrentDay
        let done = today ? snapshot.goalsDone : 0
        let total = today ? snapshot.goals.count : 0
        let energy = today ? snapshot.energy : 0
        var text = tf("system.siri.status", snapshot.goobyName, energy, snapshot.energyGoal, done, total)
        if today, let trip = snapshot.trip {
            let line = Date() >= trip.returnsAt
                ? tf("system.siri.back", snapshot.goobyName)
                : tf("system.siri.trip", snapshot.goobyName, trip.placeName)
            text += " " + line
        }
        return text
    }
}

struct GoobyGoalEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("Ziel", table: "GoobyIntents"))
    static let defaultQuery = GoobyGoalQuery()

    var id: String
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: title))
    }
}

struct GoobyGoalQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [GoobyGoalEntity] {
        goals().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [GoobyGoalEntity] { goals() }

    private func goals() -> [GoobyGoalEntity] {
        guard let snapshot = GoobySharedStore.loadSnapshot(), snapshot.isCurrentDay else { return [] }
        return snapshot.goals.map { GoobyGoalEntity(id: $0.id, title: $0.title) }
    }
}

struct GoobyStartFocusIntent: AppIntent {
    static let title = LocalizedStringResource("Fokus starten", table: "GoobyIntents")
    static let description = IntentDescription(LocalizedStringResource("Startet eine ruhige Fokuszeit mit Gooby.", table: "GoobyIntents"))
    static let openAppWhenRun = true

    @Parameter(title: LocalizedStringResource("Minuten", table: "GoobyIntents"), default: 10)
    var minutes: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        GoobyLinkRouter.shared.pending = .focus(minutes: max(1, min(90, minutes)))
        return .result()
    }
}

struct GoobyStartBreathingIntent: AppIntent {
    static let title = LocalizedStringResource("Atemübung öffnen", table: "GoobyIntents")
    static let description = IntentDescription(LocalizedStringResource("Öffnet die Atemübung mit Gooby.", table: "GoobyIntents"))
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        GoobyLinkRouter.shared.pending = .breath
        return .result()
    }
}

struct GoobyShowGoalsIntent: AppIntent {
    static let title = LocalizedStringResource("Tagesziele zeigen", table: "GoobyIntents")
    static let description = IntentDescription(LocalizedStringResource("Öffnet Gooby bei deinen Zielen für heute.", table: "GoobyIntents"))
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        GoobyLinkRouter.shared.pending = .home
        return .result()
    }
}

struct GoobyStatusIntent: AppIntent {
    static let title = LocalizedStringResource("Wie geht es Gooby?", table: "GoobyIntents")
    static let description = IntentDescription(LocalizedStringResource("Erzählt dir Goobys Energie, deine Ziele und das Abenteuer.", table: "GoobyIntents"))

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: GoobyIntentText.status()))
    }
}

struct GoobyCompleteGoalIntent: AppIntent {
    static let title = LocalizedStringResource("Ziel abhaken", table: "GoobyIntents")
    static let description = IntentDescription(LocalizedStringResource("Hakt eines deiner heutigen Ziele ab.", table: "GoobyIntents"))

    @Parameter(title: LocalizedStringResource("Ziel", table: "GoobyIntents"))
    var goal: GoobyGoalEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text: String
        if let result = GoobySystem.shared.completeGoal(goal.id) {
            text = GoobyIntentText.tf(result.wasDone ? "system.siri.already" : "system.siri.done", result.title)
        } else {
            text = GoobyIntentText.t("system.siri.missing")
        }
        return .result(dialog: IntentDialog(stringLiteral: text))
    }
}

struct GoobyPinGoalsIntent: AppIntent {
    static let title = LocalizedStringResource("Tagesziele anheften", table: "GoobyIntents")
    static let description = IntentDescription(LocalizedStringResource("Zeigt deine Tagesziele als Live-Aktivität oder blendet sie aus.", table: "GoobyIntents"))
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let next = !GoobySystem.shared.goalsPinned
        GoobySystem.shared.pinGoals(next)
        let text = GoobyIntentText.t(next ? "system.siri.pinned" : "system.siri.unpinned")
        return .result(dialog: IntentDialog(stringLiteral: text))
    }
}

struct GoobyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GoobyStatusIntent(),
            phrases: [
                "Wie geht es \(.applicationName)?",
                "Frag \(.applicationName), wie es ihm geht"
            ],
            shortTitle: LocalizedStringResource("Wie geht es Gooby?", table: "GoobyIntents"),
            systemImageName: "hare.fill"
        )
        AppShortcut(
            intent: GoobyCompleteGoalIntent(),
            phrases: [
                "Hake ein Ziel in \(.applicationName) ab",
                "\(.applicationName) Ziel abhaken"
            ],
            shortTitle: LocalizedStringResource("Ziel abhaken", table: "GoobyIntents"),
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: GoobyStartFocusIntent(),
            phrases: [
                "Starte Fokus mit \(.applicationName)",
                "\(.applicationName) Fokus"
            ],
            shortTitle: LocalizedStringResource("Fokus starten", table: "GoobyIntents"),
            systemImageName: "timer"
        )
        AppShortcut(
            intent: GoobyStartBreathingIntent(),
            phrases: [
                "Atme mit \(.applicationName)",
                "\(.applicationName) Atemübung"
            ],
            shortTitle: LocalizedStringResource("Atmen", table: "GoobyIntents"),
            systemImageName: "wind"
        )
        AppShortcut(
            intent: GoobyShowGoalsIntent(),
            phrases: [
                "Zeig meine Ziele in \(.applicationName)",
                "\(.applicationName) Tagesziele"
            ],
            shortTitle: LocalizedStringResource("Tagesziele", table: "GoobyIntents"),
            systemImageName: "list.bullet.circle.fill"
        )
        AppShortcut(
            intent: GoobyPinGoalsIntent(),
            phrases: [
                "Hefte meine Ziele aus \(.applicationName) an",
                "\(.applicationName) Ziele anheften"
            ],
            shortTitle: LocalizedStringResource("Ziele anheften", table: "GoobyIntents"),
            systemImageName: "pin.fill"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .lavender
}
