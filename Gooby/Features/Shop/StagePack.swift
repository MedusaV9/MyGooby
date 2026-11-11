import SwiftUI
import UIKit

/// Pictures and motion reels cut from the Finch pack for Shop, Bag, and Friends.
/// Reels are vertical strips named `clip-<id>-f<count>-r<fps>.png`.
enum StagePack {
    static func itemName(_ id: String) -> String {
        "item-" + id.replacingOccurrences(of: ".", with: "_")
    }

    static func image(named name: String) -> UIImage? {
        cacheLock.lock()
        if let cached = images[name] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        guard let url = url(named: name), let image = UIImage(contentsOfFile: url.path) else { return nil }
        cacheLock.lock()
        images[name] = image
        cacheLock.unlock()
        return image
    }

    static func reel(named name: String) -> StageReel? {
        cacheLock.lock()
        if let cached = reels[name] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        guard let url = url(namedPrefix: name + "-f"),
              let image = UIImage(contentsOfFile: url.path),
              let reel = StageReel(strip: image, fileName: url.deletingPathExtension().lastPathComponent) else { return nil }
        cacheLock.lock()
        reels[name] = reel
        cacheLock.unlock()
        return reel
    }

    private static let cacheLock = NSLock()
    private static var images: [String: UIImage] = [:]
    private static var reels: [String: StageReel] = [:]
    private static var catalog: [String: URL]?

    private static func files() -> [String: URL] {
        if let catalog { return catalog }
        var map: [String: URL] = [:]
        if let root = Bundle.main.resourceURL,
           let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator where url.pathExtension.lowercased() == "png" {
                map[url.deletingPathExtension().lastPathComponent] = url
            }
        }
        catalog = map
        return map
    }

    private static func url(named name: String) -> URL? {
        files()[name]
    }

    private static func url(namedPrefix prefix: String) -> URL? {
        files().first { $0.key.hasPrefix(prefix) }?.value
    }
}

struct StageReel {
    var frames: [UIImage]
    var fps: Double

    init?(strip: UIImage, fileName: String) {
        let parts = fileName.split(separator: "-")
        guard let framePart = parts.last(where: { $0.hasPrefix("f") }),
              let ratePart = parts.last(where: { $0.hasPrefix("r") }),
              let count = Int(framePart.dropFirst()),
              let rate = Double(ratePart.dropFirst()),
              count > 0,
              let cg = strip.cgImage else { return nil }
        let height = cg.height / count
        guard height > 0 else { return nil }
        var sliced: [UIImage] = []
        for index in 0..<count {
            let rect = CGRect(x: 0, y: index * height, width: cg.width, height: height)
            guard let piece = cg.cropping(to: rect) else { continue }
            sliced.append(UIImage(cgImage: piece, scale: strip.scale, orientation: .up))
        }
        guard !sliced.isEmpty else { return nil }
        frames = sliced
        fps = max(1, rate)
    }

    func frame(elapsed: TimeInterval, still: Bool, loop: Bool) -> UIImage {
        guard let first = frames.first else { return UIImage() }
        if still || frames.count == 1 { return first }
        let tick = Int(elapsed * fps)
        if loop {
            let index = ((tick % frames.count) + frames.count) % frames.count
            return frames[index]
        }
        return frames[min(frames.count - 1, max(0, tick))]
    }
}

struct StageStill: View {
    var name: String
    var fill: Bool = false

    var body: some View {
        if let image = StagePack.image(named: name) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: fill ? .fill : .fit)
        }
    }
}

struct StageClip: View {
    var name: String
    var reduceMotion: Bool = false
    var loop: Bool = true
    /// Skips the empty opening of a reel, in seconds.
    var lead: TimeInterval = 0
    @State private var start = Date()

    var body: some View {
        if let reel = StagePack.reel(named: name) {
            TimelineView(.animation(minimumInterval: 1 / reel.fps, paused: reduceMotion)) { timeline in
                Image(uiImage: reel.frame(elapsed: timeline.date.timeIntervalSince(start) + lead, still: reduceMotion, loop: loop))
                    .resizable()
                    .interpolation(.medium)
                    .scaledToFit()
            }
        } else {
            StageStill(name: name)
        }
    }
}

struct StageSway: ViewModifier {
    var amount: Double = 1.6
    var seconds: Double = 2.8
    var still: Bool = false
    @State private var lifted = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(still ? 0 : (lifted ? amount : -amount)), anchor: .bottom)
            .onAppear {
                guard !still else { return }
                withAnimation(.easeInOut(duration: seconds).repeatForever(autoreverses: true)) {
                    lifted = true
                }
            }
    }
}

extension View {
    func stageSway(amount: Double = 1.6, seconds: Double = 2.8, still: Bool = false) -> some View {
        modifier(StageSway(amount: amount, seconds: seconds, still: still))
    }
}
