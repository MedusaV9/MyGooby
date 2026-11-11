import AVFoundation
import SwiftUI
import UIKit

enum PackArt {
    static func image(_ name: String) -> UIImage? {
        images[name]
    }

    private static let images: [String: UIImage] = {
        var found: [String: UIImage] = [:]
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            return found
        }
        for case let url as URL in enumerator {
            let stem = url.deletingPathExtension().lastPathComponent
            guard stem.hasPrefix("pack-"), url.pathExtension.lowercased() == "png" else { continue }
            if let image = UIImage(contentsOfFile: url.path) {
                found[stem] = image
            }
        }
        return found
    }()
}

struct PackImage: View {
    var name: String
    var side: CGFloat

    var body: some View {
        if let image = PackArt.image(name) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: side, height: side)
                .accessibilityHidden(true)
        }
    }
}

struct PackBanner: View {
    var name: String
    var height: CGFloat

    var body: some View {
        if let image = PackArt.image(name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)
        }
    }
}

final class PackAudio {
    static let shared = PackAudio()
    private var players: [String: AVAudioPlayer] = [:]

    func play(_ name: String) -> Bool {
        let player: AVAudioPlayer
        if let cached = players[name] {
            player = cached
        } else if let made = make(name) {
            players[name] = made
            player = made
        } else {
            return false
        }
        if player.isPlaying { player.stop() }
        player.currentTime = 0
        return player.play()
    }

    func stop() {
        for player in players.values where player.isPlaying {
            player.stop()
        }
    }

    private func make(_ name: String) -> AVAudioPlayer? {
        guard let url = BundleResources.audio(named: name),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        return player
    }
}
