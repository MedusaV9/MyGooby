import SwiftUI
import UIKit

/// Raster art that belongs to Quests, Profile, Onboarding, and Settings.
/// Names are unique last-path components, so a synchronized folder can ship them as bundle resources.
enum ScreenArt {
    private static let images: [String: UIImage] = load()

    static func image(_ name: String) -> UIImage? {
        images[name]
    }

    private static func load() -> [String: UIImage] {
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return [:] }
        let prefixes = ["onb-", "quest-", "profile-", "settings-"]
        var found: [String: UIImage] = [:]
        for case let url as URL in enumerator where url.pathExtension == "png" {
            let name = url.deletingPathExtension().lastPathComponent
            guard prefixes.contains(where: { name.hasPrefix($0) }) else { continue }
            if found[name] == nil, let image = UIImage(contentsOfFile: url.path) {
                found[name] = image
            }
        }
        return found
    }
}

struct ScreenArtView: View {
    var name: String
    var mode: ContentMode = .fit

    var body: some View {
        if let image = ScreenArt.image(name) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(image.size.width / max(image.size.height, 1), contentMode: mode)
        }
    }
}

/// Content settles into a sheet instead of appearing already parked.
struct SheetRise: ViewModifier {
    var calm: Bool
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var shown = false

    func body(content: Content) -> some View {
        let still = calm || reduce
        content
            .offset(y: shown || still ? 0 : 22)
            .opacity(shown || still ? 1 : 0)
            .onAppear {
                if still {
                    shown = true
                } else {
                    withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) { shown = true }
                }
            }
    }
}

extension View {
    func sheetRise(calm: Bool) -> some View {
        modifier(SheetRise(calm: calm))
    }
}
