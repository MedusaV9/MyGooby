import Foundation

/// What the widgets show. The app builds it from the save (GoobyWidgetBridge.makeSnapshot) and
/// stores it as JSON in the App Group container; the widget timelines load it. All dates are real
/// device time (the app removes its developer time offset before writing).
struct GoobyWidgetSnapshot: Codable, Equatable, Sendable {
    static let fileName = "widget-snapshot.json"
    static let currentVersion = 1

    struct Goal: Codable, Equatable, Sendable, Identifiable {
        var id: String
        var title: String
        /// Emoji (mapped from the stored SF Symbol name) or the raw name when no emoji exists.
        var icon: String
        var colorHex: String
        var done: Bool
    }

    struct Adventure: Codable, Equatable, Sendable {
        var placeName: String
        var startedAt: Date
        var returnsAt: Date
        /// "traveling", "ready" (back home, the story waits) or "claimed".
        var status: String
    }

    var version: Int = GoobyWidgetSnapshot.currentVersion
    var createdAt: Date = Date()
    /// "de" or "en", the app's language.
    var language: String = "de"
    var goobyName: String = "Gooby"
    var nickname: String = ""
    /// Growth stage id (baby, little, young, teen, adult).
    var stage: String = "baby"
    /// Fur style id (fur-cream, fur-peach, ...), drawn by `GoobyMiniHead`.
    var fur: String = "fur-cream"
    var goalsDone: Int = 0
    var goalsTotal: Int = 0
    /// Goals due today in Home order, open ones first.
    var goals: [Goal] = []
    var streak: Int = 0
    var energy: Int = 0
    var energyGoal: Int = 12
    var sparks: Int = 0
    var adventure: Adventure?
    /// End of a running focus session; nil when none runs or it is paused.
    var focusEndsAt: Date?
    /// Today's latest mood level 1...5.
    var moodLevel: Int?
    /// Title of the seasonal event running today.
    var eventTitle: String?

    /// The stored snapshot, or nil without the App Group, before the first write or when the
    /// file has another version.
    static func load() -> GoobyWidgetSnapshot? {
        guard let data = GoobyAppGroup.read(named: fileName) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let snapshot = try? decoder.decode(GoobyWidgetSnapshot.self, from: data),
              snapshot.version == currentVersion else { return nil }
        return snapshot
    }

    /// Writes the snapshot to the App Group container. False without the group.
    @discardableResult
    func store() -> Bool {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(self) else { return false }
        return GoobyAppGroup.write(data, named: GoobyWidgetSnapshot.fileName)
    }
}
