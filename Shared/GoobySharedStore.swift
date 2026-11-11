import Foundation

// Compiled into the app and the widget extension. Keep it free of app types.

enum GoobyAppGroup {
    static let defaultID = "group.app.mygooby.gooby"
    static let widgetSuffix = ".widgets"

    // Re-signing tools may rename the group; the first identifier the system grants wins.
    static let containerURL: URL? = {
        for id in candidates() {
            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) { return url }
        }
        return nil
    }()

    static var isAvailable: Bool { containerURL != nil }

    static func candidates() -> [String] {
        var ids: [String] = []
        for info in [Bundle.main.infoDictionary, hostAppInfo()] {
            guard let info else { continue }
            if let value = info["GoobyAppGroup"] as? String { ids.append(value) }
            if let values = info["ALTAppGroups"] as? [String] { ids.append(contentsOf: values) }
        }
        ids.append(defaultID)
        if let bundleID = Bundle.main.bundleIdentifier {
            let app = bundleID.hasSuffix(widgetSuffix) ? String(bundleID.dropLast(widgetSuffix.count)) : bundleID
            ids.append("group.\(app)")
        }
        var seen = Set<String>()
        return ids.filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private static func hostAppInfo() -> [String: Any]? {
        let url = Bundle.main.bundleURL
        guard url.pathExtension == "appex" else { return nil }
        let app = url.deletingLastPathComponent().deletingLastPathComponent()
        return Bundle(url: app)?.infoDictionary
    }
}

struct GoobyWidgetSnapshot: Codable, Equatable {
    struct Goal: Codable, Equatable, Hashable, Identifiable {
        var id: String
        var title: String
        var icon: String
        var colorHex: String
        var count: Int
        var target: Int
        var isDailyGoal: Bool

        var done: Bool { count >= max(1, target) }
    }

    struct Trip: Codable, Equatable {
        var placeName: String
        var startedAt: Date
        var returnsAt: Date
    }

    struct Focus: Codable, Equatable {
        var plannedSeconds: Int
        var remainingSeconds: Int
        var endsAt: Date?
    }

    var dayKey: String
    var timeOffset: Double
    var language: String
    var goobyName: String
    var stage: String
    var energy: Int
    var energyGoal: Int
    var sparks: Int
    var streak: Int
    var goals: [Goal]
    var trip: Trip?
    var focus: Focus?
    var updatedAt: Date

    var goalsDone: Int { goals.filter(\.done).count }

    func sameContent(as other: GoobyWidgetSnapshot?) -> Bool {
        guard var other else { return false }
        other.updatedAt = updatedAt
        return other == self
    }

    static func dayKey(for date: Date, offset: Double) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date.addingTimeInterval(offset))
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    var isCurrentDay: Bool { dayKey == GoobyWidgetSnapshot.dayKey(for: Date(), offset: timeOffset) }
}

struct GoobyPendingAction: Codable, Equatable {
    var habitID: String
    var complete: Bool
    var dayKey: String
    var at: Date
}

struct GoobyPendingRoute: Codable, Equatable {
    var link: String
    var minutes: Int?
}

enum GoobySharedStore {
    static let snapshotName = "widget-snapshot.json"
    static let actionsName = "pending-actions.json"
    static let routeName = "pending-route.json"
    static let portraitName = "gooby-portrait.png"
    static let badgeName = "gooby-badge.png"

    // Without the App Group each process keeps a private copy, so widgets show their fallback.
    static func directory() -> URL? {
        let base: URL
        if let group = GoobyAppGroup.containerURL {
            base = group
        } else if let local = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            base = local
        } else {
            return nil
        }
        let dir = base.appendingPathComponent("GoobyShared", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                return nil
            }
            var copy = dir
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? copy.setResourceValues(values)
        }
        return dir
    }

    static func url(_ name: String) -> URL? { directory()?.appendingPathComponent(name) }

    static func loadSnapshot() -> GoobyWidgetSnapshot? {
        guard let url = url(snapshotName), let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder().decode(GoobyWidgetSnapshot.self, from: data)
    }

    static func saveSnapshot(_ snapshot: GoobyWidgetSnapshot) {
        guard let url = url(snapshotName), let data = try? encoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func appendAction(_ action: GoobyPendingAction) {
        guard let url = url(actionsName) else { return }
        coordinate(url) { target in
            var list = readActions(target)
            list.append(action)
            if list.count > 64 { list = Array(list.suffix(64)) }
            if let data = try? encoder().encode(list) { try? data.write(to: target, options: .atomic) }
        }
    }

    static func takeActions() -> [GoobyPendingAction] {
        guard let url = url(actionsName) else { return [] }
        var taken: [GoobyPendingAction] = []
        coordinate(url) { target in
            taken = readActions(target)
            if !taken.isEmpty { try? FileManager.default.removeItem(at: target) }
        }
        return taken
    }

    // Mirrors a tap in the stored snapshot so widgets update before the app applies it.
    @discardableResult
    static func toggleGoal(_ habitID: String, at date: Date = Date()) -> GoobyPendingAction? {
        guard var snapshot = loadSnapshot(), snapshot.isCurrentDay,
              let index = snapshot.goals.firstIndex(where: { $0.id == habitID }) else { return nil }
        let complete = !snapshot.goals[index].done
        snapshot.goals[index].count = max(0, snapshot.goals[index].count + (complete ? 1 : -1))
        snapshot.updatedAt = date
        saveSnapshot(snapshot)
        let action = GoobyPendingAction(habitID: habitID, complete: complete, dayKey: snapshot.dayKey, at: date)
        appendAction(action)
        return action
    }

    static func saveRoute(link: String, minutes: Int? = nil) {
        guard let url = url(routeName) else { return }
        let route = GoobyPendingRoute(link: link, minutes: minutes)
        guard let data = try? encoder().encode(route) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func takeRoute() -> GoobyPendingRoute? {
        guard let url = url(routeName), let data = try? Data(contentsOf: url) else { return nil }
        try? FileManager.default.removeItem(at: url)
        return try? decoder().decode(GoobyPendingRoute.self, from: data)
    }

    static func imageData(_ name: String) -> Data? {
        guard let url = url(name) else { return nil }
        return try? Data(contentsOf: url)
    }

    private static func readActions(_ url: URL) -> [GoobyPendingAction] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? decoder().decode([GoobyPendingAction].self, from: data)) ?? []
    }

    private static func coordinate(_ url: URL, _ body: (URL) -> Void) {
        var error: NSError?
        var ran = false
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url, options: .forMerging, error: &error) { target in
            ran = true
            body(target)
        }
        if !ran { body(url) }
    }

    private static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }

    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}

enum GoobyLink: String, CaseIterable {
    case home, goals, focus, breath, adventure

    static let scheme = "gooby"

    var url: URL { URL(string: "\(GoobyLink.scheme)://\(rawValue)") ?? URL(fileURLWithPath: "/") }

    static func focusURL(minutes: Int) -> URL {
        URL(string: "\(scheme)://focus?minutes=\(max(1, min(90, minutes)))") ?? GoobyLink.focus.url
    }

    init?(url: URL) {
        guard url.scheme == GoobyLink.scheme, let host = url.host, let link = GoobyLink(rawValue: host) else { return nil }
        self = link
    }
}
