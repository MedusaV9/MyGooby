import Foundation
import SwiftData

// Canonical SwiftData schema for every Gooby domain.
// Feature modules must reuse these types and must not declare a second model with the same name.
// Singletons: PlayerProfile, Wallet, GoobyPet, RoomLayout. Everything else is a row.
// New stored properties keep a default so an older store still opens.

@Model
final class PlayerProfile {
    var id: UUID = UUID()
    var nickname: String = ""
    // Human birthday as plain text. Empty means not set. The human name stays in nickname.
    var birthday: String = ""
    var goobyName: String = "Gooby"
    var photoFilename: String = ""
    var goals: [String] = []
    var onboardingDone: Bool = false
    var faceIDEnabled: Bool = false
    var languageCode: String = "de"
    var reduceMotion: Bool = false
    var appSeed: Int64 = 0
    var timeOffset: Double = 0
    var createdAt: Date = Date()
    var notificationsEnabled: Bool = false
    // Daily energy the adventure waits for. Older rows stored 12; the engine lifts that to 15.
    var energyGoal: Int = 15
    // Promised streak length in days. 0 means no promise yet.
    var streakGoalDays: Int = 0
    // Day key (YYYY-MM-DD) of the last affirmation card. Empty means it has not been shown.
    var lastAffirmationDay: String = ""
    var helpSeen: Bool = false

    init() {}
}

@Model
final class Wallet {
    // Rainbow-stone balance. Earn and spend paths keep this name.
    var sparks: Int = 0
    var energy: Int = 0
    var energyDayKey: String = ""
    var lifetimeSparksEarned: Int = 0
    var lifetimeSparksSpent: Int = 0

    init() {}
}

@Model
final class GoobyPet {
    var curiosity: Double = 0.35
    var courage: Double = 0.35
    var kindness: Double = 0.4
    var playfulness: Double = 0.4
    var confidence: Double = 0.3
    var calm: Double = 0.35
    var empathy: Double = 0.4
    // Pet pronouns as stored by the caller, for example "he/him". Empty means not chosen.
    var pronouns: String = ""
    // Starter id: curiosity, resilience, compassion, logic, confidence, or security.
    var starterTrait: String = ""
    var stageOverride: String = ""
    var adventureDays: Int = 0
    var careDays: Int = 0
    // Days whose energy reached energyGoal. Starts at 0 for an older save.
    var fullEnergyDays: Int = 0
    var lastCareDayKey: String = ""
    var affection: Int = 0
    var furStyle: String = "fur-cream"
    var recentStoryIDs: [String] = []

    init() {}
}

@Model
final class Habit {
    var id: UUID = UUID()
    var title: String = ""
    var details: String = ""
    var icon: String = "sparkles"
    var colorHex: String = "FFD6E7"
    var category: String = "mindful"
    var priority: Int = 1
    var startDate: Date = Date()
    var endDate: Date?
    var recurrence: String = "daily"
    var weekdays: [Int] = []
    var intervalDays: Int = 1
    var timesPerDay: Int = 1
    var reminderHour: Int = -1
    var reminderMinute: Int = 0
    var energyReward: Int = 5
    var sparkReward: Int = 2
    var isDailyGoal: Bool = false
    var isArchived: Bool = false
    var isPaused: Bool = false
    var movedFromKey: String = ""
    var movedToKey: String = ""
    var sortIndex: Int = 0
    var createdAt: Date = Date()

    init() {}
}

@Model
final class HabitLog {
    var id: UUID = UUID()
    var habitID: UUID = UUID()
    var dayKey: String = ""
    var count: Int = 0
    var skipped: Bool = false
    var createdAt: Date = Date()

    init() {}
}

@Model
final class RewardLedger {
    @Attribute(.unique) var key: String = ""
    var sparks: Int = 0
    var energy: Int = 0
    var createdAt: Date = Date()

    init() {}
}

@Model
final class AdventureRun {
    var id: UUID = UUID()
    var placeID: String = ""
    var storyID: String = ""
    var startedAt: Date = Date()
    var returnsAt: Date = Date()
    var claimedAt: Date?
    var status: String = "traveling"
    var dayKey: String = ""
    var choiceID: String = ""
    var rewardSparks: Int = 0
    var discoveryID: String = ""

    init() {}
}

@Model
final class OwnedItem {
    var catalogID: String = ""
    var kind: String = ""
    var acquiredAt: Date = Date()
    var favorite: Bool = false
    var equippedSlot: String = ""

    init() {}
}

@Model
final class SavedOutfit {
    var id: UUID = UUID()
    var name: String = ""
    var slotsJSON: String = "{}"
    var favorite: Bool = false
    var createdAt: Date = Date()

    init() {}
}

@Model
final class RoomLayout {
    var wall: String = "wall-cream"
    var floor: String = "floor-blush"
    var bed: String = "bed-cream"
    var rug: String = "rug-cloud"
    var lamp: String = "lamp-blossom"
    var windowItem: String = "window-round"
    var plant: String = "plant-sprout"
    var shelf: String = ""
    var picture: String = ""
    var sofa: String = ""
    var tableItem: String = ""
    var cushion: String = "cushion-peach"
    var seasonal: String = ""

    init() {}
}

@Model
final class MoodEntry {
    var id: UUID = UUID()
    var recordedAt: Date = Date()
    var dayKey: String = ""
    var level: Int = 3
    var tags: [String] = []
    var note: String = ""

    init() {}
}

@Model
final class JournalEntry {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var title: String = ""
    var body: String = ""
    var tags: [String] = []
    var promptID: String = ""
    var dayKey: String = ""

    init() {}
}

@Model
final class QuestRecord {
    var id: UUID = UUID()
    var templateID: String = ""
    var kind: String = "daily"
    var dayKey: String = ""
    var progress: Int = 0
    var goal: Int = 1
    var claimed: Bool = false
    var rewardSparks: Int = 0
    var rewardItemID: String = ""

    init() {}
}

@Model
final class EventRecord {
    var eventID: String = ""
    var forced: Bool = false
    var forcedOn: Date?
    var bonusJSON: String = "{}"
    var claimedJSON: String = "[]"

    init() {}
}

@Model
final class MiniFriend {
    var id: UUID = UUID()
    var speciesID: String = ""
    var givenName: String = ""
    var rarity: String = "common"
    var stage: Int = 1
    var hatchedAt: Date = Date()
    var isCompanion: Bool = false

    init() {}
}

@Model
final class EggBinding {
    var id: UUID = UUID()
    var habitID: UUID = UUID()
    var progress: Int = 0
    var requiredCount: Int = 7
    var hatched: Bool = false
    var friendID: UUID?
    var createdAt: Date = Date()

    init() {}
}

@Model
final class PlaceProgress {
    var placeID: String = ""
    var unlocked: Bool = false
    var visits: Int = 0

    init() {}
}

@Model
final class DiscoveryRecord {
    var discoveryID: String = ""
    var placeID: String = ""
    var foundAt: Date = Date()

    init() {}
}

@Model
final class FocusSession {
    var id: UUID = UUID()
    var plannedSeconds: Int = 0
    var accumulated: Double = 0
    var runningSince: Date?
    var finished: Bool = false
    var rewarded: Bool = false
    var dayKey: String = ""

    init() {}
}

@Model
final class DailyStat {
    var dayKey: String = ""
    var breathSessions: Int = 0
    var focusMinutes: Int = 0
    var movementSessions: Int = 0
    var petActions: Int = 0
    var journalRewards: Int = 0

    init() {}
}

@Model
final class AppLogEntry {
    var at: Date = Date()
    var message: String = ""

    init() {}
}
