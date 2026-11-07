import Foundation

struct LocText: Codable, Hashable {
    var de: String
    var en: String

    func text(_ language: String) -> String {
        if language == "en" { return en.isEmpty ? de : en }
        return de.isEmpty ? en : de
    }
}

struct DiscoveryDef: Codable, Identifiable, Hashable {
    var id: String
    var name: LocText
    var detail: LocText
}

struct PlaceDef: Codable, Identifiable, Hashable {
    var id: String
    var name: LocText
    var blurb: LocText
    var durationMinutes: Int
    var unlockAfterAdventures: Int
    var ticketPrice: Int
    var skyTop: String
    var skyBottom: String
    var accent: String
    var discoveries: [DiscoveryDef]
}

struct StoryChoice: Codable, Identifiable, Hashable {
    var id: String
    var text: LocText
    var outcome: LocText
    var deltas: [String: Double]
    var sparks: Int
    var discoveryID: String
}

struct StoryDef: Codable, Identifiable, Hashable {
    var id: String
    var placeID: String
    var title: LocText
    var body: LocText
    var choices: [StoryChoice]
}

struct ItemDef: Codable, Identifiable, Hashable {
    var id: String
    var kind: String
    var slot: String
    var style: Int
    var price: Int
    var rarity: String
    var color: String
    var color2: String
    var name: LocText
    var blurb: LocText
    var shop: String
    var starter: Bool
    var seasonalEvent: String
}

struct FriendDef: Codable, Identifiable, Hashable {
    var id: String
    var name: LocText
    var rarity: String
    var weight: Int
    var blurb: LocText
}

struct QuestTemplate: Codable, Identifiable, Hashable {
    var id: String
    var kind: String
    var metric: String
    var goal: Int
    var rewardSparks: Int
    var rewardItemID: String
    var title: LocText
    var detail: LocText
}

struct EventTaskDef: Codable, Identifiable, Hashable {
    var id: String
    var metric: String
    var goal: Int
    var rewardSparks: Int
    var rewardItemID: String
    var title: LocText
}

struct EventDef: Codable, Identifiable, Hashable {
    var id: String
    var startMonth: Int
    var startDay: Int
    var endMonth: Int
    var endDay: Int
    var title: LocText
    var blurb: LocText
    var tasks: [EventTaskDef]
}

struct PromptDef: Codable, Identifiable, Hashable {
    var id: String
    var theme: String
    var title: LocText
    var body: LocText
}

struct ExerciseDef: Codable, Identifiable, Hashable {
    var id: String
    var minutes: Int
    var title: LocText
    var steps: [LocText]
}

struct ContentFile: Codable {
    var places: [PlaceDef] = []
    var stories: [StoryDef] = []
    var items: [ItemDef] = []
    var friends: [FriendDef] = []
    var quests: [QuestTemplate] = []
    var events: [EventDef] = []
    var prompts: [PromptDef] = []
    var exercises: [ExerciseDef] = []

    init() {}

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        places = try box.decodeIfPresent([PlaceDef].self, forKey: .places) ?? []
        stories = try box.decodeIfPresent([StoryDef].self, forKey: .stories) ?? []
        items = try box.decodeIfPresent([ItemDef].self, forKey: .items) ?? []
        friends = try box.decodeIfPresent([FriendDef].self, forKey: .friends) ?? []
        quests = try box.decodeIfPresent([QuestTemplate].self, forKey: .quests) ?? []
        events = try box.decodeIfPresent([EventDef].self, forKey: .events) ?? []
        prompts = try box.decodeIfPresent([PromptDef].self, forKey: .prompts) ?? []
        exercises = try box.decodeIfPresent([ExerciseDef].self, forKey: .exercises) ?? []
    }
}

struct ContentCatalog {
    var places: [PlaceDef]
    var stories: [StoryDef]
    var items: [ItemDef]
    var friends: [FriendDef]
    var quests: [QuestTemplate]
    var events: [EventDef]
    var prompts: [PromptDef]
    var exercises: [ExerciseDef]

    var placesByID: [String: PlaceDef] = [:]
    var storiesByID: [String: StoryDef] = [:]
    var itemsByID: [String: ItemDef] = [:]
    var friendsByID: [String: FriendDef] = [:]
    var questsByID: [String: QuestTemplate] = [:]

    static let shared = ContentCatalog.load()

    static func load() -> ContentCatalog {
        var file = ContentFile()
        let urls = BundleResources.urls(prefix: "content-", extension: "json")
        let decoder = JSONDecoder()
        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            guard let data = try? Data(contentsOf: url),
                  let piece = try? decoder.decode(ContentFile.self, from: data) else { continue }
            file.places.append(contentsOf: piece.places)
            file.stories.append(contentsOf: piece.stories)
            file.items.append(contentsOf: piece.items)
            file.friends.append(contentsOf: piece.friends)
            file.quests.append(contentsOf: piece.quests)
            file.events.append(contentsOf: piece.events)
            file.prompts.append(contentsOf: piece.prompts)
            file.exercises.append(contentsOf: piece.exercises)
        }
        return ContentCatalog(
            places: file.places,
            stories: file.stories,
            items: file.items,
            friends: file.friends,
            quests: file.quests,
            events: file.events,
            prompts: file.prompts,
            exercises: file.exercises
        )
    }

    init(places: [PlaceDef], stories: [StoryDef], items: [ItemDef], friends: [FriendDef], quests: [QuestTemplate], events: [EventDef], prompts: [PromptDef], exercises: [ExerciseDef]) {
        self.places = places
        self.stories = stories
        self.items = items
        self.friends = friends
        self.quests = quests
        self.events = events
        self.prompts = prompts
        self.exercises = exercises
        placesByID = Dictionary(uniqueKeysWithValues: places.map { ($0.id, $0) })
        storiesByID = Dictionary(uniqueKeysWithValues: stories.map { ($0.id, $0) })
        itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        friendsByID = Dictionary(uniqueKeysWithValues: friends.map { ($0.id, $0) })
        questsByID = Dictionary(uniqueKeysWithValues: quests.map { ($0.id, $0) })
    }
}

enum BundleResources {
    static func urls(prefix: String, extension ext: String) -> [URL] {
        guard let root = Bundle.main.resourceURL else { return [] }
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return [] }
        var found: [URL] = []
        for case let url as URL in enumerator {
            if url.pathExtension == ext && url.lastPathComponent.hasPrefix(prefix) {
                found.append(url)
            }
        }
        return found
    }

    static func audio(named name: String) -> URL? {
        if let direct = Bundle.main.url(forResource: name, withExtension: "wav") { return direct }
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return nil }
        for case let url as URL in enumerator {
            if url.deletingPathExtension().lastPathComponent == name { return url }
        }
        return nil
    }
}

enum StringTable {
    private static let map: [String: [String: String]] = load()

    static func text(_ key: String, _ language: String) -> String {
        guard let row = map[key] else { return key }
        if let value = row[language], !value.isEmpty { return value }
        if let value = row["de"], !value.isEmpty { return value }
        return key
    }

    private static func load() -> [String: [String: String]] {
        var merged: [String: [String: String]] = [:]
        let decoder = JSONDecoder()
        for url in BundleResources.urls(prefix: "l10n-", extension: "json") {
            guard let data = try? Data(contentsOf: url),
                  let piece = try? decoder.decode([String: [String: String]].self, from: data) else { continue }
            for (key, value) in piece { merged[key] = value }
        }
        return merged
    }
}
