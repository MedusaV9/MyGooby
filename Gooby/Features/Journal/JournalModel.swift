import Foundation

enum ReflectionKind: String, Codable, CaseIterable, Identifiable {
    case gratitude
    case selfWorth
    case stressCoping
    case dailyReview
    case mindfulness
    case motivation
    case feelings
    var id: String { rawValue }
}

struct JournalEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var day: String
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var body: String
    var tags: [String]
    var reflection: ReflectionKind?
    var rewarded: Bool
}

enum JournalSearch {
    static func matches(entry: JournalEntry, query: String, tag: String?) -> Bool {
        if let tag {
            let needle = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            if !needle.isEmpty && !entry.tags.contains(where: { $0.caseInsensitiveCompare(needle) == .orderedSame }) {
                return false
            }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        if entry.title.localizedStandardContains(trimmed) { return true }
        if entry.body.localizedStandardContains(trimmed) { return true }
        return entry.tags.contains { $0.localizedStandardContains(trimmed) }
    }

    static func cleanedTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for tag in tags {
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            let clipped = String(trimmed.prefix(24))
            let key = clipped.lowercased()
            if clipped.isEmpty || seen.contains(key) { continue }
            seen.insert(key)
            result.append(clipped)
            if result.count == 20 { break }
        }
        return result
    }
}

enum ReflectionCatalog {
    static func questions(for kind: ReflectionKind) -> [CareString] {
        switch kind {
        case .gratitude:
            return [.promptGratitude1, .promptGratitude2, .promptGratitude3]
        case .selfWorth:
            return [.promptWorth1, .promptWorth2, .promptWorth3]
        case .stressCoping:
            return [.promptStress1, .promptStress2, .promptStress3]
        case .dailyReview:
            return [.promptReview1, .promptReview2, .promptReview3]
        case .mindfulness:
            return [.promptMind1, .promptMind2, .promptMind3]
        case .motivation:
            return [.promptMotive1, .promptMotive2, .promptMotive3]
        case .feelings:
            return [.promptFeel1, .promptFeel2, .promptFeel3]
        }
    }

    static func composedBody(kind: ReflectionKind, answers: [String], language: CareLanguage) -> String {
        let prompts = questions(for: kind)
        var lines: [String] = []
        for (index, prompt) in prompts.enumerated() {
            let answer = index < answers.count ? answers[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            lines.append(CareCopy.text(prompt, language))
            lines.append(answer.isEmpty ? "—" : answer)
            lines.append("")
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
