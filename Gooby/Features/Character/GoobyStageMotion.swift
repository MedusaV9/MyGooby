import UIKit

/// Stage plates shipped in the app bundle. Missing art falls back to the drawn scenes.
/// The rabbit's pack timings live in `PackMotion`.
enum GoobyStageArt {
    private static var cache: [String: UIImage] = [:]
    private static var missing = Set<String>()

    static func image(named name: String) -> UIImage? {
        if let cached = cache[name] { return cached }
        if missing.contains(name) { return nil }
        if let image = load(named: name) {
            cache[name] = image
            return image
        }
        missing.insert(name)
        return nil
    }

    private static func load(named name: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = image(at: url) {
            return image
        }
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return nil }
        for case let url as URL in enumerator {
            if url.pathExtension.lowercased() == "png",
               url.deletingPathExtension().lastPathComponent == name,
               let image = image(at: url) {
                return image
            }
        }
        return nil
    }

    private static func image(at url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
