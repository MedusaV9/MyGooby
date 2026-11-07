import Foundation

enum CareLanguage: String, Codable, Equatable {
    case german = "de"
    case english = "en"

    var localeIdentifier: String {
        self == .german ? "de_DE" : "en_US"
    }

    static func resolve(_ raw: String) -> CareLanguage? {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "de", "de-de", "german", "deutsch":
            return .german
        case "en", "en-us", "en-gb", "english":
            return .english
        default:
            return nil
        }
    }
}

/// One currency event. `eventID` is stable across a crash replay.
/// The shell applies each eventID at most once, in order.
/// A reversal uses a new eventID and the original `key`.
struct CareReward: Codable, Equatable, Identifiable {
    var eventID: Int
    var key: String
    var energy: Int
    var sparks: Int
    var reversal: Bool
    var reason: String
    var title: String
    var id: Int { eventID }
}

struct StoredGrant: Codable, Equatable {
    var key: String
    var energy: Int
    var sparks: Int
    var reason: String
    var title: String
}

enum CareIssue: String, Codable, Equatable, Error {
    case emptyTitle
    case interval
    case weekdays
    case custom
    case dates
    case reps
    case reward
    case monthDay
    case customName
    case symbol
    case color
    case reminder
    case pause
    case notDue
    case alreadyDone
    case sameDay
    case outOfRange
    case targetDue
    case future
    case paused
    case missing
    case emptyEntry
    case emptyReflection
}

enum CareRewards {
    static let breathEnergy = 3
    static let breathSparks = 3
    static let reflectionEnergy = 5
    static let reflectionSparks = 5
    static let focusEnergy = 5
    static let focusSparks = 5
    static let movementEnergy = 4
    static let movementSparks = 3
    static let groundingEnergy = 2
    static let groundingSparks = 2
    static let dailyGoalEnergy = 5
    static let dailyGoalSparks = 10
}

struct CareReminderRequest: Codable, Equatable, Identifiable {
    var id: String
    var habitID: UUID
    var day: String
    var title: String
    var body: String
    var hour: Int
    var minute: Int
    var fireAt: Date
}

struct CareHabitSummary: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var symbol: String
    var colorHex: String
    var completed: Int
    var repetitions: Int
    var skipped: Bool
    var isDailyGoal: Bool
    var rewardValue: Int
    var paused: Bool
}

struct CareDaySnapshot: Equatable {
    var day: String
    var habits: [CareHabitSummary]
    var moodAverage: Double?
    var moodEntryCount: Int
    var journalCount: Int
}
