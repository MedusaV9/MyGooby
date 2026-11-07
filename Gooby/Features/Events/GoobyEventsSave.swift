import Foundation

struct GoobyEventsSave: Equatable, Codable {
    var version: Int
    var seed: UInt64
    var seedConfigured: Bool
    var timeTravelISO: String?
    var forcedEventID: String?
    var eventProgress: [String: GoobyEventOccurrenceProgress]
    var claimedEventRewards: [String]
    var debugEventGrants: [String]
    var dailyBoards: [String: GoobyDailyBoard]
    var questSalt: UInt64
    var claimedQuestIDs: [String]
    var totalQuestsCompleted: Int
    var questCompletionDays: [String]
    var claimedMilestoneIDs: [String]
    var eggs: [GoobyEggRecord]
    var eggsEverBound: Int
    var companions: [GoobyCompanionRecord]
    var companionsHatchedEver: Int
    var selectedCompanionID: String?
    var pendingHatchIDs: [String]
    var speciesHatched: [String]
    var eventsTouched: [String]
    var companionPlayTotal: Int
    var debugLog: [String]

    static let currentVersion = 1
    static let defaultSeed: UInt64 = 0x600B_7E17

    init() {
        version = Self.currentVersion
        seed = Self.defaultSeed
        seedConfigured = false
        timeTravelISO = nil
        forcedEventID = nil
        eventProgress = [:]
        claimedEventRewards = []
        debugEventGrants = []
        dailyBoards = [:]
        questSalt = 0
        claimedQuestIDs = []
        totalQuestsCompleted = 0
        questCompletionDays = []
        claimedMilestoneIDs = []
        eggs = []
        eggsEverBound = 0
        companions = []
        companionsHatchedEver = 0
        selectedCompanionID = nil
        pendingHatchIDs = []
        speciesHatched = []
        eventsTouched = []
        companionPlayTotal = 0
        debugLog = []
    }

    mutating func log(_ line: String) {
        debugLog.append(line)
        if debugLog.count > 80 {
            debugLog.removeFirst(debugLog.count - 80)
        }
    }
}
