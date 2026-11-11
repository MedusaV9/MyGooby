import Combine
import Foundation

/// Local star list for exercises. A JSON file in Application Support, not a SwiftData model.
final class ActivityFavoriteStore: ObservableObject {
    static let shared = ActivityFavoriteStore()

    @Published private(set) var ids: [String] = []
    private let url: URL

    private init() {
        url = GoobyFiles.supportDirectory().appendingPathComponent("activity-favorites.json")
        load()
    }

    func contains(_ id: String) -> Bool {
        ids.contains(id)
    }

    func toggle(_ id: String) {
        var next = ids
        if let index = next.firstIndex(of: id) {
            next.remove(at: index)
        } else {
            next.append(id)
        }
        ids = next
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else { return }
        var seen = Set<String>()
        ids = decoded.filter { seen.insert($0).inserted }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        try? data.write(to: url, options: .atomic)
        GoobyFiles.exclude(url)
    }
}
