import Foundation

enum ShopPersistence {
    private static let folderName = "Gooby"
    private static let fileName = "shop-room.json"

    static func load() -> ShopState {
        let url = fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ShopEngine.fresh()
        }
        do {
            let data = try Data(contentsOf: url)
            guard data.count < 1_000_000 else {
                throw CocoaError(.fileReadTooLarge)
            }
            let decoded = try JSONDecoder().decode(ShopState.self, from: data)
            return ShopEngine.sanitize(decoded)
        } catch {
            quarantine(url)
            return ShopEngine.fresh()
        }
    }

    @discardableResult
    static func save(_ state: ShopState) -> Bool {
        let url = fileURL()
        do {
            let folder = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            try data.write(to: url, options: .atomic)
            var excluded = url
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? excluded.setResourceValues(values)
            return true
        } catch {
            return false
        }
    }

    static func exportText() -> String {
        let url = fileURL()
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else {
            return ""
        }
        return text
    }

    private static func fileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent(folderName, isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
    }

    private static func quarantine(_ url: URL) {
        let broken = url.deletingLastPathComponent().appendingPathComponent("shop-room.corrupt.json")
        try? FileManager.default.removeItem(at: broken)
        try? FileManager.default.moveItem(at: url, to: broken)
    }
}
