import Foundation

struct GoobyHabitLink: Equatable, Hashable, Sendable, Identifiable, Codable {
    var id: String
    var title: String
}

enum GoobyCareSignal: Equatable, Sendable {
    case habitCompleted(habitID: String)
    case moodLogged
    case journalWritten
    case calmSessionCompleted
    case goobyPetted
    case adventureStarted
    case adventureCompleted
    case dailyGoalCompleted
    case eventVisited(eventID: String)
    case companionPlayed(companionID: String)
}

struct GoobyRewardGrant: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var source: String
    var starSparks: Int
    var cosmeticIDs: [String]
    var companionSpeciesID: String?
    var titleDE: String
    var titleEN: String
    var dayKey: String

    static func make(
        id: String,
        source: String,
        starSparks: Int,
        cosmeticIDs: [String] = [],
        companionSpeciesID: String? = nil,
        titleDE: String,
        titleEN: String,
        dayKey: String
    ) -> GoobyRewardGrant {
        GoobyRewardGrant(
            id: id,
            source: source,
            starSparks: max(0, starSparks),
            cosmeticIDs: cosmeticIDs,
            companionSpeciesID: companionSpeciesID,
            titleDE: titleDE,
            titleEN: titleEN,
            dayKey: dayKey
        )
    }
}

enum GoobyEventsLanguage: String, Equatable, Sendable {
    case german = "de"
    case english = "en"

    static func resolve(_ code: String?) -> GoobyEventsLanguage {
        let value = (code ?? "de").lowercased()
        if value.hasPrefix("en") {
            return .english
        }
        return .german
    }
}

enum GoobyTimeTravelPreset: String, Equatable, Sendable, CaseIterable {
    case today
    case tomorrow
    case nextWeek
    case nextMonth
}

struct GoobyCompanionUnlockResult: Equatable, Sendable {
    var companions: [GoobyCompanionSnapshot]
    var grants: [GoobyRewardGrant]
}

struct GoobyForcedHatchResult: Equatable, Sendable {
    var companion: GoobyCompanionSnapshot?
    var grants: [GoobyRewardGrant]
}

struct GoobyEggBindResult: Equatable, Sendable {
    var egg: GoobyEggSnapshot?
    var grants: [GoobyRewardGrant]
}

struct GoobyEggSnapshot: Equatable, Sendable, Identifiable {
    var id: String
    var habitID: String
    var habitTitle: String
    var validDays: Int
    var requiredDays: Int
    var hatchedCompanionID: String?
}

struct GoobyCompanionSnapshot: Equatable, Sendable, Identifiable {
    var id: String
    var speciesID: String
    var name: String
    var story: String
    var rarity: String
    var stage: String
    var animation: String
    var primaryHex: String
    var secondaryHex: String
    var selected: Bool
    var playCount: Int
    var playedToday: Bool
}

struct GoobyQuestSnapshot: Equatable, Sendable, Identifiable {
    var id: String
    var templateID: String
    var title: String
    var detail: String
    var progress: Int
    var target: Int
    var sparks: Int
    var claimed: Bool
}

struct GoobyMilestoneSnapshot: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var current: Int
    var target: Int
    var sparks: Int
    var claimed: Bool
}

struct GoobyObjectiveSnapshot: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var current: Int
    var target: Int
}

struct GoobyEventSnapshot: Equatable, Sendable, Identifiable {
    var id: String
    var name: String
    var summary: String
    var phase: String
    var dateText: String
    var accentHex: String
    var symbolName: String
    var objectives: [GoobyObjectiveSnapshot]
    var rewardSparks: Int
    var cosmeticID: String
    var bonusSpeciesName: String?
    var complete: Bool
    var claimed: Bool
    var forced: Bool
}

struct GoobyEventsScreenModel: Equatable {
    var language: GoobyEventsLanguage
    var dayKey: String
    var events: [GoobyEventSnapshot]
    var quests: [GoobyQuestSnapshot]
    var milestones: [GoobyMilestoneSnapshot]
    var eggs: [GoobyEggSnapshot]
    var companions: [GoobyCompanionSnapshot]
    var pendingHatches: [GoobyCompanionSnapshot]
    var forcedEventID: String?
}

struct GoobyPlannedNotification: Equatable, Sendable, Identifiable {
    var id: String
    var title: String
    var body: String
    var fireDate: Date
}

struct GoobyNotificationScheduleResult: Equatable, Sendable {
    var scheduledIDs: [String]
    var authorization: String
    var messageDE: String
    var messageEN: String
}

extension Notification.Name {
    static let goobyEventsDidChange = Notification.Name("gooby.events.didChange")
}
