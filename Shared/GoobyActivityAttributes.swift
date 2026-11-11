import ActivityKit
import Foundation

// One source file, compiled into the app and the widget extension, so both agree on the payload.
struct GoobyActivityAttributes: ActivityAttributes {
    enum Kind: String, Codable, Hashable {
        case adventure, focus, breath, goals
    }

    struct ContentState: Codable, Hashable {
        var language: String
        var headline: String
        var detail: String
        var start: Date
        var end: Date
        var pausedRemaining: Int?
        var pausedProgress: Double?
        var finished: Bool
        var goalsDone: Int
        var goalsTotal: Int
        var energy: Int
        var energyGoal: Int
    }

    var kind: Kind
    var reference: String
    var goobyName: String
}
