import Foundation

struct GoobyEventsLibraries: Equatable {
    var events: [GoobySeasonalEventDefinition]
    var quests: [GoobyQuestTemplate]
    var milestones: [GoobyMilestoneDefinition]
    var species: [GoobyCompanionSpeciesDefinition]
    var copyDE: [String: String]
    var copyEN: [String: String]

    static func makeFallback() -> GoobyEventsLibraries {
        GoobyEventsLibraries(
            events: GoobyEventCatalog.events,
            quests: GoobyQuestCatalog.templates,
            milestones: GoobyQuestCatalog.milestones,
            species: GoobyCompanionCatalog.species,
            copyDE: GoobyEventsCopy.german,
            copyEN: GoobyEventsCopy.english
        )
    }

    nonisolated(unsafe) static var current: GoobyEventsLibraries = makeFallback()

    func text(_ key: String, language: GoobyEventsLanguage) -> String {
        let table = language == .english ? copyEN : copyDE
        if let value = table[key], !value.isEmpty {
            return value
        }
        if let value = copyDE[key], !value.isEmpty {
            return value
        }
        return key
    }

    func format(_ key: String, language: GoobyEventsLanguage, tokens: [String: String]) -> String {
        var value = text(key, language: language)
        for (token, replacement) in tokens {
            value = value.replacingOccurrences(of: "{\(token)}", with: replacement)
        }
        return value
    }

    func event(_ id: String) -> GoobySeasonalEventDefinition? {
        events.first { $0.id == id }
    }

    func quest(_ id: String) -> GoobyQuestTemplate? {
        quests.first { $0.id == id }
    }

    func species(_ id: String) -> GoobyCompanionSpeciesDefinition? {
        species.first { $0.id == id }
    }

    var eggPool: [GoobyCompanionSpeciesDefinition] {
        species.filter { $0.seasonalEventID == nil }
    }
}

enum GoobyEventsResourceLoader {
    static func loadFromBundle(_ bundle: Bundle = .main) {
        guard let directory = resourceDirectory(in: bundle) else {
            return
        }
        if let loaded = load(directory: directory) {
            GoobyEventsLibraries.current = loaded
        }
    }

    static func load(directory: URL) -> GoobyEventsLibraries? {
        let events: [GoobySeasonalEventDefinition]? = decode("seasonal-events", in: directory)
        let quests: [GoobyQuestTemplate]? = decode("quest-templates", in: directory)
        let milestones: [GoobyMilestoneDefinition]? = decode("milestones", in: directory)
        let species: [GoobyCompanionSpeciesDefinition]? = decode("companion-species", in: directory)
        let copyDE: [String: String]? = decode("copy-de", in: directory)
        let copyEN: [String: String]? = decode("copy-en", in: directory)
        guard
            let events, !events.isEmpty,
            let quests, !quests.isEmpty,
            let milestones, !milestones.isEmpty,
            let species, !species.isEmpty,
            let copyDE, !copyDE.isEmpty,
            let copyEN, !copyEN.isEmpty
        else {
            return nil
        }
        return GoobyEventsLibraries(
            events: events,
            quests: quests,
            milestones: milestones,
            species: species,
            copyDE: copyDE,
            copyEN: copyEN
        )
    }

    static func resourceDirectory(in bundle: Bundle) -> URL? {
        let subdirectories: [String?] = [nil, "Events", "Resources/Events", "Gooby/Resources/Events"]
        for subdirectory in subdirectories {
            if let url = bundle.url(forResource: "seasonal-events", withExtension: "json", subdirectory: subdirectory) {
                return url.deletingLastPathComponent()
            }
        }
        return nil
    }

    private static func decode<T: Decodable>(_ name: String, in directory: URL) -> T? {
        let url = directory.appendingPathComponent("\(name).json")
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
