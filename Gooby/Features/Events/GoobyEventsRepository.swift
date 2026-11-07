import Foundation

final class GoobyEventsRepository {
    nonisolated(unsafe) static let shared = GoobyEventsRepository()

    private(set) var save: GoobyEventsSave
    let fileURL: URL
    private(set) var lastError: String?

    init(fileURL: URL? = nil, loadFromDisk: Bool = true) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        if loadFromDisk, let stored = Self.load(self.fileURL) {
            save = stored
        } else {
            save = GoobyEventsSave()
        }
    }

    @discardableResult
    func update(_ body: (inout GoobyEventsSave) -> [GoobyRewardGrant]) -> [GoobyRewardGrant] {
        let grants = body(&save).map { grant in
            var copy = grant
            if copy.starSparks < 0 {
                copy.starSparks = 0
            }
            return copy
        }
        persist()
        return grants
    }

    func modify(_ body: (inout GoobyEventsSave) -> Void) {
        body(&save)
        persist()
    }

    func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(save)
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: backupURL)
                try? FileManager.default.copyItem(at: fileURL, to: backupURL)
            }
            try data.write(to: fileURL, options: .atomic)
            Self.excludeFromBackup(directory)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        NotificationCenter.default.post(name: .goobyEventsDidChange, object: nil)
    }

    var backupURL: URL {
        fileURL.deletingPathExtension().appendingPathExtension("bak")
    }

    static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("Gooby", isDirectory: true)
            .appendingPathComponent("events-world.json")
    }

    static func load(_ url: URL) -> GoobyEventsSave? {
        if let save = decode(url) {
            return save
        }
        let backup = url.deletingPathExtension().appendingPathExtension("bak")
        return decode(backup)
    }

    private static func decode(_ url: URL) -> GoobyEventsSave? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(GoobyEventsSave.self, from: data)
    }

    private static func excludeFromBackup(_ directory: URL) {
        #if os(iOS) || os(macOS) || os(visionOS)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var copy = directory
        try? copy.setResourceValues(values)
        #endif
    }
}
