import Foundation

struct GoobyCompanionSpeciesDefinition: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var nameDE: String
    var nameEN: String
    var storyDE: String
    var storyEN: String
    var rarity: String
    var animation: String
    var seasonalEventID: String?
    var primaryHex: String
    var secondaryHex: String
}

struct GoobyEggRecord: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var habitID: String
    var habitTitle: String
    var boundDay: String
    var validDays: [String]
    var rollSeed: UInt64
    var hatchedCompanionID: String?
}

struct GoobyCompanionRecord: Equatable, Codable, Sendable, Identifiable {
    var id: String
    var speciesID: String
    var customName: String?
    var hatchedDay: String
    var playDays: [String]
    var playCount: Int
    var origin: String
}

enum GoobyCompanionGrowth {
    static let requiredEggDays = 7

    static func stage(playCount: Int) -> String {
        if playCount >= 10 {
            return "grown"
        }
        if playCount >= 4 {
            return "little"
        }
        return "baby"
    }

    static func rarityWeight(_ rarity: String) -> Int {
        switch rarity {
        case "common":
            return 50
        case "uncommon":
            return 28
        case "rare":
            return 16
        case "epic":
            return 6
        default:
            return 10
        }
    }
}

enum GoobyHabitIdentity {
    static func link(title: String) -> GoobyHabitLink {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = trimmed.isEmpty ? "Gewohnheit" : String(trimmed.prefix(40))
        var slug = ""
        var pendingDash = false
        for scalar in display.lowercased().unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                if pendingDash, !slug.isEmpty {
                    slug.append("-")
                }
                pendingDash = false
                slug.unicodeScalars.append(scalar)
            } else {
                pendingDash = true
            }
        }
        if slug.isEmpty {
            slug = "eigen"
        }
        return GoobyHabitLink(id: "habit-\(slug)", title: display)
    }
}
