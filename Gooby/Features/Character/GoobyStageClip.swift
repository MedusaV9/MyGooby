import ImageIO
import SwiftUI
import UIKit

/// Plays a GIF clip from the stage pack. The drawn rabbit stays when a clip is missing.
enum GoobyStageClip {
    struct Frames {
        var images: [UIImage]
        var delays: [Double]
        var duration: Double

        func image(at time: Double) -> UIImage {
            guard let first = images.first else { return UIImage() }
            var cursor = 0.0
            let local = positive(time.truncatingRemainder(dividingBy: duration))
            for index in images.indices {
                cursor += delays[index]
                if local < cursor { return images[index] }
            }
            return images.last ?? first
        }

        private func positive(_ value: Double) -> Double {
            value < 0 ? value + duration : value
        }
    }

    /// Full-frame clip that stands in for the drawn character.
    static func replacement(for animation: GoobyAnimation) -> String? {
        switch animation {
        case .laugh: return "stage-clip-laugh"
        case .hearts: return "stage-clip-hearts"
        case .petting: return "stage-clip-caring"
        case .surprised, .unwrap: return "stage-clip-surprised"
        case .celebrate: return "stage-clip-confetti"
        case .ears: return "stage-clip-brows"
        default: return nil
        }
    }

    /// Clip drawn over the rabbit. The wing clap is only the wings, not a whole pose.
    static func overlay(for animation: GoobyAnimation) -> String? {
        animation == .clap ? "stage-clip-clap" : nil
    }

    static func frames(named name: String) -> Frames? {
        if let cached = cache[name] { return cached }
        if missing.contains(name) { return nil }
        guard let data = data(named: name), let decoded = decode(data) else {
            missing.insert(name)
            return nil
        }
        cache[name] = decoded
        return decoded
    }

    private static var cache: [String: Frames] = [:]
    private static var missing = Set<String>()

    private static func data(named name: String) -> Data? {
        if let url = Bundle.main.url(forResource: name, withExtension: "gif"),
           let data = try? Data(contentsOf: url) {
            return data
        }
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return nil }
        for case let url as URL in enumerator {
            if url.pathExtension.lowercased() == "gif",
               url.deletingPathExtension().lastPathComponent == name,
               let data = try? Data(contentsOf: url) {
                return data
            }
        }
        return nil
    }

    private static func decode(_ data: Data) -> Frames? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }
        var images: [UIImage] = []
        var delays: [Double] = []
        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))
            delays.append(delay(source, index: index))
        }
        guard !images.isEmpty else { return nil }
        let duration = delays.reduce(0, +)
        return Frames(images: images, delays: delays, duration: max(duration, 0.05))
    }

    private static func delay(_ source: CGImageSource, index: Int) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }
        let value = seconds(gif[kCGImagePropertyGIFUnclampedDelayTime])
            ?? seconds(gif[kCGImagePropertyGIFDelayTime])
            ?? 0.1
        return value < 0.02 ? 0.1 : value
    }

    private static func seconds(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let number = value as? Double { return number }
        return nil
    }
}

struct GoobyStageClipView: View {
    var name: String
    var reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 30.0, paused: reduceMotion)) { timeline in
            if let frames = GoobyStageClip.frames(named: name) {
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                Image(uiImage: frames.image(at: time))
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}
