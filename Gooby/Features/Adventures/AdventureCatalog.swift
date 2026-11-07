import CryptoKit
import Foundation

struct AdventureCatalogLoad: Equatable {
    var catalog: AdventureCatalog
    var issues: [String]
}

enum AdventureCatalogLoader {
    private static let requiredNames: [String: String] = [
        "flower-meadow": "Blumenwiese",
        "cloud-land": "Wolkenland",
        "star-forest": "Sternenwald",
        "sugar-island": "Zuckerinsel",
        "crystal-lake": "Kristallsee",
        "sunny-beach": "Sonnenstrand",
        "moon-valley": "Mondtal",
        "fairy-garden": "Märchengarten",
        "snow-village": "Schneedorf",
        "cherry-park": "Kirschblütenpark"
    ]

    static func load() -> AdventureCatalogLoad {
        let embedded = Data(AdventureCatalogJSON.text.utf8)
        let decoded = decode(embedded)
        var issues = decoded.issues
        issues.append(contentsOf: validate(decoded.catalog))
        issues.append(contentsOf: hashIssues(embedded: embedded))
        return AdventureCatalogLoad(catalog: decoded.catalog, issues: issues)
    }

    private static func decode(_ data: Data) -> (catalog: AdventureCatalog, issues: [String]) {
        do {
            let catalog = try JSONDecoder().decode(AdventureCatalog.self, from: data)
            return (catalog, [])
        } catch {
            return (AdventureCatalog(places: [], stories: []), ["Katalog konnte nicht gelesen werden: \(error.localizedDescription)"])
        }
    }

    private static func hashIssues(embedded: Data) -> [String] {
        var issues: [String] = []
        let digest = SHA256.hash(data: embedded).map { String(format: "%02x", Int($0)) }.joined()
        if digest != AdventureCatalogJSON.sha256 {
            issues.append("Eingebetteter Katalog passt nicht zur Prüfsumme.")
        }
        if let bundled = bundledData() {
            let bundledDigest = SHA256.hash(data: bundled).map { String(format: "%02x", Int($0)) }.joined()
            if bundledDigest != digest {
                issues.append("Die Katalogdatei im Bundle weicht vom eingebetteten Katalog ab.")
            }
        }
        return issues
    }

    private static func bundledData() -> Data? {
        let subdirectories: [String?] = [nil, "Adventures", "Resources/Adventures", "Gooby/Resources/Adventures"]
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(forResource: "adventure-catalog", withExtension: "json", subdirectory: subdirectory),
               let data = try? Data(contentsOf: url) {
                return data
            }
        }
        return nil
    }

    static func validate(_ catalog: AdventureCatalog) -> [String] {
        var issues: [String] = []
        if catalog.places.count < 10 {
            issues.append("Weniger als 10 Orte.")
        }
        if catalog.stories.count < 50 {
            issues.append("Weniger als 50 Geschichten.")
        }
        let ids = Set(catalog.places.map(\.id))
        if ids != Set(requiredNames.keys) {
            issues.append("Die zehn Orte sind nicht vollständig.")
        }
        var discoveryOwners: [String: String] = [:]
        for place in catalog.places {
            if place.name.de != requiredNames[place.id] {
                issues.append("Deutscher Ortsname fehlt oder weicht ab: \(place.id)")
            }
            if place.durationMinutes <= 0 {
                issues.append("Dauer fehlt: \(place.id)")
            }
            if place.name.en.trimmingCharacters(in: .whitespaces).isEmpty
                || place.summary.de.trimmingCharacters(in: .whitespaces).isEmpty
                || place.summary.en.trimmingCharacters(in: .whitespaces).isEmpty {
                issues.append("Orttext fehlt: \(place.id)")
            }
            for discovery in place.discoveries {
                if discoveryOwners[discovery.id] != nil {
                    issues.append("Entdeckung doppelt: \(discovery.id)")
                }
                discoveryOwners[discovery.id] = place.id
                if discovery.name.de.isEmpty || discovery.name.en.isEmpty {
                    issues.append("Entdeckungsname fehlt: \(discovery.id)")
                }
            }
        }
        var seenStories = Set<String>()
        var granted = Set<String>()
        var perPlace: [String: Int] = [:]
        var traitHits: [String: Int] = [:]
        for story in catalog.stories {
            if !seenStories.insert(story.id).inserted {
                issues.append("Geschichte doppelt: \(story.id)")
            }
            perPlace[story.placeID, default: 0] += 1
            if !ids.contains(story.placeID) {
                issues.append("Geschichte ohne Ort: \(story.id)")
            }
            if story.choices.count < 2 {
                issues.append("Zu wenige Antworten: \(story.id)")
            }
            if story.title.de.count < 3 || story.title.en.count < 3 || story.body.de.count < 40 || story.body.en.count < 40 {
                issues.append("Geschichte zu kurz: \(story.id)")
            }
            var choiceIDs = Set<String>()
            for choice in story.choices {
                if !choiceIDs.insert(choice.id).inserted {
                    issues.append("Antwort doppelt: \(story.id) \(choice.id)")
                }
                if choice.text.de.isEmpty || choice.text.en.isEmpty || choice.outcome.de.count < 20 || choice.outcome.en.count < 20 {
                    issues.append("Antworttext fehlt: \(story.id) \(choice.id)")
                }
                if choice.traits.isEmpty {
                    issues.append("Keine Persönlichkeit: \(story.id) \(choice.id)")
                }
                for (trait, amount) in choice.traits {
                    if AdventureTrait(rawValue: trait) == nil || amount < 1 || amount > 2 {
                        issues.append("Ungültiger Wert: \(story.id) \(trait)")
                    } else {
                        traitHits[trait, default: 0] += 1
                    }
                }
                if let discoveryID = choice.discoveryID {
                    if discoveryOwners[discoveryID] != story.placeID {
                        issues.append("Entdeckung passt nicht zum Ort: \(discoveryID)")
                    }
                    if !granted.insert(discoveryID).inserted {
                        issues.append("Entdeckung mehrfach vergeben: \(discoveryID)")
                    }
                }
            }
        }
        for (placeID, count) in perPlace where count < 5 {
            issues.append("Zu wenige Geschichten an \(placeID)")
        }
        for place in catalog.places where perPlace[place.id, default: 0] < 5 {
            if !issues.contains("Zu wenige Geschichten an \(place.id)") {
                issues.append("Zu wenige Geschichten an \(place.id)")
            }
        }
        let missing = Set(discoveryOwners.keys).subtracting(granted)
        if !missing.isEmpty {
            issues.append("Entdeckungen ohne Geschichte: \(missing.sorted().joined(separator: ", "))")
        }
        for trait in AdventureTrait.allCases where traitHits[trait.rawValue, default: 0] < 8 {
            issues.append("Eigenschaft \(trait.rawValue) kommt zu selten vor.")
        }
        return issues
    }
}
