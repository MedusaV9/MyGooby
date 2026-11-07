import Foundation

enum AdventureTrait: String, Codable, CaseIterable, Identifiable {
    case curiosity
    case courage
    case kindness
    case playfulness
    case confidence
    case calm
    case empathy

    var id: String { rawValue }
}

enum AdventureLanguage: String, Codable {
    case german = "de"
    case english = "en"

    static func resolve(_ code: String?) -> AdventureLanguage {
        let value = code?.lowercased() ?? ""
        if value.hasPrefix("en") {
            return .english
        }
        return .german
    }
}

struct AdventureLocalizedText: Codable, Equatable {
    var de: String
    var en: String

    func resolved(_ language: AdventureLanguage) -> String {
        switch language {
        case .english:
            return en
        case .german:
            return de
        }
    }
}

enum AdventureMotif: String, Codable {
    case flower
    case gate
    case petal
    case sun
    case ripple
    case cloud
    case swirl
    case star
    case moon
    case snow
}

struct AdventureDiscoveryDefinition: Codable, Equatable, Identifiable {
    var id: String
    var name: AdventureLocalizedText
    var detail: AdventureLocalizedText
}

struct AdventurePlaceDefinition: Codable, Equatable, Identifiable {
    var id: String
    var name: AdventureLocalizedText
    var summary: AdventureLocalizedText
    var durationMinutes: Int
    var unlockAfterAdventures: Int
    var mapX: Double
    var mapY: Double
    var skyHex: String
    var groundHex: String
    var accentHex: String
    var motif: AdventureMotif
    var discoveries: [AdventureDiscoveryDefinition]
}

struct AdventureChoiceDefinition: Codable, Equatable, Identifiable {
    var id: String
    var text: AdventureLocalizedText
    var outcome: AdventureLocalizedText
    var traits: [String: Int]
    var discoveryID: String?
}

struct AdventureStoryDefinition: Codable, Equatable, Identifiable {
    var id: String
    var placeID: String
    var sparkReward: Int
    var title: AdventureLocalizedText
    var body: AdventureLocalizedText
    var choices: [AdventureChoiceDefinition]
}

struct AdventureCatalog: Codable, Equatable {
    var places: [AdventurePlaceDefinition]
    var stories: [AdventureStoryDefinition]

    func place(id: String) -> AdventurePlaceDefinition? {
        places.first { $0.id == id }
    }

    func story(id: String) -> AdventureStoryDefinition? {
        stories.first { $0.id == id }
    }

    func discovery(id: String) -> (place: AdventurePlaceDefinition, discovery: AdventureDiscoveryDefinition)? {
        for place in places {
            if let discovery = place.discoveries.first(where: { $0.id == id }) {
                return (place, discovery)
            }
        }
        return nil
    }
}

struct AdventureActiveTrip: Codable, Equatable, Identifiable {
    var id: String
    var placeID: String
    var storyID: String
    var startedAt: Date
    var returnsAt: Date
    var appDayKey: String
    var countsAsDaily: Bool
}

struct AdventureJournalEntry: Codable, Equatable, Identifiable {
    var id: String
    var storyID: String
    var placeID: String
    var choiceID: String
    var sparks: Int
    var discoveryID: String?
    var traitDeltas: [String: Int]
    var dayKey: String
    var claimedAt: Date
    var preview: Bool
}

struct AdventureSave: Codable, Equatable {
    var version: Int
    var traits: [String: Int]
    var completedCount: Int
    var placeVisits: [String: Int]
    var foundDiscoveryIDs: [String]
    var seenStoryIDs: [String]
    var previewRewardedStoryIDs: [String]
    var lastResolvedDayKey: String?
    var selectedPlaceID: String
    var active: AdventureActiveTrip?
    var journal: [AdventureJournalEntry]
    var allPlacesUnlocked: Bool
    var queuedStoryID: String?

    static let currentVersion = 1

    static func fresh() -> AdventureSave {
        AdventureSave(
            version: currentVersion,
            traits: AdventureEngine.initialTraits(),
            completedCount: 0,
            placeVisits: [:],
            foundDiscoveryIDs: [],
            seenStoryIDs: [],
            previewRewardedStoryIDs: [],
            lastResolvedDayKey: nil,
            selectedPlaceID: "flower-meadow",
            active: nil,
            journal: [],
            allPlacesUnlocked: false,
            queuedStoryID: nil
        )
    }

    func normalized() -> AdventureSave {
        var copy = self
        var traits = AdventureEngine.initialTraits()
        for (key, value) in copy.traits where AdventureTrait(rawValue: key) != nil {
            traits[key] = min(AdventureEngine.traitMaximum, max(0, value))
        }
        copy.traits = traits
        if copy.selectedPlaceID.isEmpty {
            copy.selectedPlaceID = "flower-meadow"
        }
        copy.completedCount = max(0, copy.completedCount)
        return copy
    }
}

enum AdventurePhase: Equatable {
    case needsEnergy(current: Int, goal: Int)
    case ready
    case traveling(AdventureActiveTrip, remaining: TimeInterval)
    case storyReady(AdventureActiveTrip)
    case rested(dayKey: String)
}

struct AdventurePersonalityDelta: Equatable {
    var traits: [String: Int]

    var isEmpty: Bool {
        traits.values.allSatisfy { $0 == 0 }
    }
}

struct AdventureStorySummary: Identifiable, Equatable {
    var id: String
    var placeID: String
    var titleDE: String
    var titleEN: String
}

struct AdventureDebugSnapshot: Equatable {
    var completedCount: Int
    var activePlaceID: String?
    var activeStoryID: String?
    var startedAt: Date?
    var returnsAt: Date?
    var unlockedPlaceIDs: [String]
    var discoveryCount: Int
    var traits: [String: Int]
    var savePath: String
    var storyCount: Int
    var placeCount: Int
    var validationIssues: [String]
    var energyFillHandlerRegistered: Bool
    var queuedStoryID: String?
    var allPlacesUnlocked: Bool
    var lastResolvedDayKey: String?
}

enum AdventureStartError: Equatable {
    case notReady
    case placeLocked
    case missingStory
    case energyRefused
}

enum AdventureBanner: Equatable {
    case energyRefused
    case placeLocked
}

enum AdventureText {
    static func filled(_ raw: String, name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let safe = trimmed.isEmpty ? "Gooby" : trimmed
        return raw.replacingOccurrences(of: "{{name}}", with: safe)
    }
}
