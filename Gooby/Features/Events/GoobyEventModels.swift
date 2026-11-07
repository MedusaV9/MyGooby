import Foundation

struct GoobyEventObjectiveDefinition: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var kind: String
    var target: Int
    var titleDE: String
    var titleEN: String
}

struct GoobySeasonalEventDefinition: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var nameDE: String
    var nameEN: String
    var summaryDE: String
    var summaryEN: String
    var startMonth: Int
    var startDay: Int
    var endMonth: Int
    var endDay: Int
    var accentHex: String
    var symbolName: String
    var objectives: [GoobyEventObjectiveDefinition]
    var rewardSparks: Int
    var cosmeticID: String
    var bonusSpeciesID: String?
}

struct GoobyEventOccurrenceProgress: Equatable, Codable, Sendable {
    var eventID: String
    var occurrenceKey: String
    var credits: [String]
}

struct GoobyEventWindow: Equatable, Sendable {
    var start: Date
    var end: Date
}

struct GoobyEventCalendarEntry: Equatable, Sendable, Identifiable {
    var id: String { event.id }
    var event: GoobySeasonalEventDefinition
    var window: GoobyEventWindow
    var phase: String
}
