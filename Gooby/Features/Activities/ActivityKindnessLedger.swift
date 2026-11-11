import Combine
import Foundation

/// Local heart counts for acts of kindness. Nothing leaves the phone.
final class ActivityKindnessLedger: ObservableObject {
    static let shared = ActivityKindnessLedger()

    @Published private(set) var counts: [String: Int] = [:]
    private let url: URL

    private init() {
        url = GoobyFiles.supportDirectory().appendingPathComponent("activity-kindness.json")
        load()
    }

    func count(_ id: String) -> Int {
        max(0, counts[id] ?? 0)
    }

    var total: Int {
        counts.values.reduce(0) { $0 + max(0, $1) }
    }

    func give(_ id: String) {
        var next = counts
        next[id, default: 0] += 1
        counts = next
        persist()
    }

    private struct File: Codable {
        var counts: [String: Int]
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return }
        counts = file.counts
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(File(counts: counts)) else { return }
        try? data.write(to: url, options: .atomic)
        GoobyFiles.exclude(url)
    }
}
