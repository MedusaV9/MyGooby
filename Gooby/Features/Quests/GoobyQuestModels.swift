import Foundation

struct GoobyQuestTemplate: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var metric: String
    var target: Int
    var sparks: Int
    var titleDE: String
    var titleEN: String
    var detailDE: String
    var detailEN: String
}

struct GoobyMilestoneDefinition: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var metric: String
    var target: Int
    var sparks: Int
    var titleDE: String
    var titleEN: String
    var detailDE: String
    var detailEN: String
}

struct GoobyDailyQuestProgress: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var templateID: String
    var progress: Int
    var creditKeys: [String]
    var claimed: Bool
}

struct GoobyDailyBoard: Equatable, Codable, Sendable {
    var dayKey: String
    var quests: [GoobyDailyQuestProgress]
}
