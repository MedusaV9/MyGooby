import Foundation
import WidgetKit

/// Keeps the widget snapshot (GoobyShared/GoobyWidgetSnapshot.swift) in the App Group container
/// up to date and asks WidgetKit to reload. Without the App Group (unsigned IPA re-signed without
/// it) `store()` returns false and nothing is written; the widgets then show their offline look.
@MainActor
final class GoobyWidgetBridge {
    static let shared = GoobyWidgetBridge()

    private var pending: Task<Void, Never>?
    private var lastWritten: GoobyWidgetSnapshot?

    func handle(_ moment: GoobyMoment, engine: GoobyEngine) {
        switch moment {
        case .tap, .toggled, .sheetOpened, .sheetClosed, .tabChanged:
            return
        case .appBackground, .dataReset:
            pending?.cancel()
            write(engine)
        default:
            schedule(engine)
        }
    }

    /// The snapshot of the current save, in real device time.
    func makeSnapshot(_ engine: GoobyEngine) -> GoobyWidgetSnapshot {
        let today = engine.now()
        let offset = engine.profile.timeOffset
        let language = engine.languageCode
        let due = engine.dueHabits(on: today)
        let goals = due.map { habit in
            GoobyWidgetSnapshot.Goal(
                id: habit.id.uuidString,
                title: habit.title,
                icon: GoobyIcon.emoji(for: habit.icon) ?? habit.icon,
                colorHex: habit.colorHex,
                done: engine.homeIsDone(habit, on: today)
            )
        }
        let progress = engine.todayProgress()
        var snapshot = GoobyWidgetSnapshot()
        snapshot.language = language
        snapshot.goobyName = engine.profile.goobyName
        snapshot.nickname = engine.profile.nickname
        snapshot.stage = Growth.stage(of: engine.pet)
        snapshot.fur = engine.pet.furStyle
        snapshot.goalsDone = progress.done
        snapshot.goalsTotal = progress.total
        snapshot.goals = goals.filter { !$0.done } + goals.filter(\.done)
        snapshot.streak = engine.streak()
        snapshot.energy = engine.wallet.energy
        snapshot.energyGoal = max(1, engine.profile.energyGoal)
        snapshot.sparks = engine.wallet.sparks
        if let run = engine.todaysRun() {
            snapshot.adventure = GoobyWidgetSnapshot.Adventure(
                placeName: engine.catalog.placesByID[run.placeID]?.name.text(language) ?? "",
                startedAt: run.startedAt.addingTimeInterval(-offset),
                returnsAt: run.returnsAt.addingTimeInterval(-offset),
                status: run.status
            )
        }
        if let focus = engine.currentFocus(), focus.runningSince != nil {
            snapshot.focusEndsAt = Date().addingTimeInterval(TimeInterval(engine.focusRemaining()))
        }
        snapshot.moodLevel = engine.homeMoodToday()?.level
        snapshot.eventTitle = engine.catalog.events.first { engine.isEventActive($0.id) }?.title.text(language)
        return snapshot
    }

    /// Writes now when the content changed and reloads the widget timelines.
    func write(_ engine: GoobyEngine) {
        let snapshot = makeSnapshot(engine)
        var unchanged = snapshot
        unchanged.createdAt = lastWritten?.createdAt ?? snapshot.createdAt
        guard unchanged != lastWritten else { return }
        guard snapshot.store() else { return }
        lastWritten = snapshot
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Coalesces bursts of saves into one write.
    private func schedule(_ engine: GoobyEngine) {
        pending?.cancel()
        pending = Task { [weak engine] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled, let engine else { return }
            GoobyWidgetBridge.shared.write(engine)
        }
    }
}
