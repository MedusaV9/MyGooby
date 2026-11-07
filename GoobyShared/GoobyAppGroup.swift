import Foundation

/// Data bridge from the app to the widget extension: files in the shared App Group container
/// `group.app.mygooby.gooby`, written by the app (GoobyWidgetBridge) and read by the widget
/// timelines. Everything stays on this iPhone.
///
/// Why this shape: the CI IPA is unsigned, so it carries no entitlements. The App Group exists
/// only once the IPA is signed with the group (Gooby/Gooby.entitlements and
/// GoobyWidgets/GoobyWidgets.entitlements, or a re-signing tool that adds it). Without it
/// `containerURL` is nil, writes are skipped and the widgets show their own offline content
/// (Gooby, the date, a greeting, a tap opens the app) instead of the save data. Live Activities
/// do not use this bridge: the app sends their content through ActivityKit, which needs no
/// entitlement and no push server.
enum GoobyAppGroup {
    static let identifier = "group.app.mygooby.gooby"

    /// The shared container, or nil when this build is not entitled for the group.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var isAvailable: Bool { containerURL != nil }

    /// Writes `data` atomically to `name` in the container and keeps it out of iCloud backups
    /// (masterprompt 2.4). Returns false without the group or when writing fails.
    @discardableResult
    static func write(_ data: Data, named name: String) -> Bool {
        guard let base = containerURL else { return false }
        var url = base.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return false
        }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
        return true
    }

    static func read(named name: String) -> Data? {
        guard let base = containerURL else { return nil }
        return try? Data(contentsOf: base.appendingPathComponent(name))
    }

    static func remove(named name: String) {
        guard let base = containerURL else { return }
        try? FileManager.default.removeItem(at: base.appendingPathComponent(name))
    }
}
