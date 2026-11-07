import SwiftUI

/// Shell entry for habits, mood, journal, and calm.
///
/// Call only this type from the shell. Rewards use `CareReward.eventID`:
/// apply each event once, in order. A reversal is a later event with the same `key`
/// and `reversal == true`. Reversals must not push a balance below zero.
/// Habit days follow `CareSession.simulatedNow` when the dev menu sets it.
/// Breathing, focus, and movement countdowns use the device clock.
/// Reminder requests are data only. This slice does not schedule notifications.
@MainActor
enum CareIntegration {
    static func rootView() -> some View { CareHost { CareRootView() } }
    static func habitsView() -> some View { CareHost { HabitHomeView() } }
    static func moodView() -> some View { CareHost { MoodHomeView() } }
    static func journalView() -> some View { CareHost { JournalHomeView() } }
    static func calmView() -> some View { CareHost { CalmHomeView() } }

    static func setLanguage(_ code: String) {
        CareSession.shared.setLanguageCode(code)
    }

    static func setSimulatedNow(_ date: Date?) {
        CareSession.shared.simulatedNow = date
    }

    static func setRewardHandler(_ handler: ((CareReward) -> Void)?) {
        CareStore.shared.setRewardHandler(handler)
    }

    @discardableResult
    static func createStarterHabits() -> Int {
        let session = CareSession.shared
        return CareStore.shared.createStarterHabits(now: session.now, calendar: session.calendar, language: session.language)
    }

    static func snapshot(on date: Date) -> CareDaySnapshot {
        let session = CareSession.shared
        let day = CareDay.key(for: date, calendar: session.calendar)
        return CareStore.shared.snapshot(on: day, calendar: session.calendar)
    }

    static func dueHabitIDs(on date: Date) -> [UUID] {
        snapshot(on: date).habits.map(\.id)
    }

    @discardableResult
    static func completeHabit(id: UUID, on date: Date) -> [CareReward] {
        let session = CareSession.shared
        let day = CareDay.key(for: date, calendar: session.calendar)
        switch CareStore.shared.completeRep(habitID: id, day: day, now: session.now, calendar: session.calendar) {
        case .success(let rewards):
            return rewards
        case .failure:
            return []
        }
    }

    static func reminderRequests(days: Int = 7) -> [CareReminderRequest] {
        let session = CareSession.shared
        return CareStore.shared.reminderRequests(
            from: session.todayKey,
            count: max(1, days),
            now: session.now,
            calendar: session.calendar,
            body: session.text(.reminderBody)
        )
    }

    enum Debug {
        static func resetAllData() {
            CareStore.shared.resetAll()
        }

        static func seedSampleContent() {
            let session = CareSession.shared
            CareStore.shared.seedSampleContent(now: session.now, calendar: session.calendar, language: session.language)
        }

        static func setSimulatedNow(_ date: Date?) {
            CareSession.shared.simulatedNow = date
        }

        static func clearSimulatedNow() {
            CareSession.shared.simulatedNow = nil
        }

        static func diagnostics() -> String {
            let session = CareSession.shared
            let lines = [
                CareStore.shared.diagnostics(now: session.now, calendar: session.calendar),
                "language \(session.language.rawValue)",
                session.simulatedNow == nil ? "clock device" : "clock simulated"
            ]
            return lines.joined(separator: "\n")
        }

        static func runSelfCheck() -> String {
            let failures = HabitSchedule.selfCheck()
                + MoodMath.selfCheck()
                + BreathEngine.selfCheck()
                + FocusMath.selfCheck()
                + CareStore.logicCheck()
            return failures.isEmpty ? "pass" : failures.joined(separator: "\n")
        }

        static func reminderRequests(days: Int = 7) -> [CareReminderRequest] {
            CareIntegration.reminderRequests(days: days)
        }

        static func forceComplete(habitID: UUID, day: String) -> String {
            let session = CareSession.shared
            switch CareStore.shared.completeRep(habitID: habitID, day: day, now: session.now, calendar: session.calendar) {
            case .success(let rewards):
                if rewards.isEmpty { return "none" }
                return rewards.map { "\($0.eventID) \($0.reason) \($0.energy)" }.joined(separator: ", ")
            case .failure(let issue):
                return issue.rawValue
            }
        }
    }
}

struct CareHost<Content: View>: View {
    @ObservedObject private var store: CareStore
    @ObservedObject private var session: CareSession
    private let content: Content

    init(store: CareStore = .shared, @ViewBuilder content: () -> Content) {
        self.store = store
        self.session = .shared
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(store)
            .environmentObject(session)
            .environment(\.locale, Locale(identifier: session.language == .german ? "de" : "en"))
            .tint(CarePalette.ink)
    }
}

struct CareRootView: View {
    @EnvironmentObject private var session: CareSession

    var body: some View {
        TabView {
            NavigationStack { HabitHomeView() }
                .tabItem { Label(session.text(.tabHabits), systemImage: "checkmark.circle") }
            NavigationStack { MoodHomeView() }
                .tabItem { Label(session.text(.tabMood), systemImage: "face.smiling") }
            NavigationStack { JournalHomeView() }
                .tabItem { Label(session.text(.tabJournal), systemImage: "book") }
            NavigationStack { CalmHomeView() }
                .tabItem { Label(session.text(.tabCalm), systemImage: "wind") }
        }
    }
}

#Preview {
    CareIntegration.rootView()
}
