import SwiftUI
import UIKit

/// Goal stickers taken from the real emoji art shipped with the goal flow.
struct GoalSticker: View {
    var glyph: String

    var body: some View {
        FeatureArt.image("goal-emoji-\(glyph)")
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
    }
}

enum FeatureArt {
    static func image(_ name: String) -> Image {
        if let ui = uiImage(named: name) {
            return Image(uiImage: ui)
        }
        return Image(systemName: "sparkle")
    }

    private static let lock = NSLock()
    private static var cache: [String: UIImage] = [:]
    private static var missing: Set<String> = []

    private static func uiImage(named name: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[name] { return cached }
        if missing.contains(name) { return nil }
        guard let loaded = load(name) else {
            missing.insert(name)
            return nil
        }
        cache[name] = loaded
        return loaded
    }

    private static var index: [String: URL]?

    private static func load(_ name: String) -> UIImage? {
        if index == nil {
            var found: [String: URL] = [:]
            if let root = Bundle.main.resourceURL,
               let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in enumerator where url.pathExtension == "png" {
                    found[url.deletingPathExtension().lastPathComponent] = url
                }
            }
            index = found
        }
        guard let url = index?[name] else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

extension View {
    func stickerRim(_ width: CGFloat = 2.2) -> some View {
        compositingGroup()
            .shadow(color: .white, radius: 0, x: width, y: 0)
            .compositingGroup()
            .shadow(color: .white, radius: 0, x: -width, y: 0)
            .compositingGroup()
            .shadow(color: .white, radius: 0, x: 0, y: width)
            .compositingGroup()
            .shadow(color: .white, radius: 0, x: 0, y: -width)
            .compositingGroup()
            .shadow(color: .black.opacity(0.16), radius: 1.2, x: 0, y: 1.4)
    }
}
