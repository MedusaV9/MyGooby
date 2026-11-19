import AVFoundation
import SwiftUI

/// Bundled instrumental loops. Nest, forest, shop, calm, and the morning start each hold one clip.
enum SceneLoop: String {
    case nest
    case forest
    case shop
    case calm
    case morning

    var clip: String { "music-\(rawValue)" }
}

@MainActor
final class SceneLoopPlayer {
    static let shared = SceneLoopPlayer()

    private var depth: [SceneLoop: Int] = [:]
    private var stack: [SceneLoop] = []
    private var player: AVAudioPlayer?
    private var current: SceneLoop?

    func acquire(_ place: SceneLoop) {
        depth[place, default: 0] += 1
        stack.removeAll { $0 == place }
        stack.append(place)
        follow()
    }

    func release(_ place: SceneLoop) {
        let left = (depth[place] ?? 0) - 1
        if left <= 0 {
            depth[place] = nil
            stack.removeAll { $0 == place }
        } else {
            depth[place] = left
        }
        follow()
    }

    /// Stops or resumes the current scene after `GoobyFeedback.soundsOn` changes. The stack stays.
    func applySounds(_ on: Bool) {
        if on {
            follow()
        } else {
            halt()
        }
    }

    private func follow() {
        guard GoobyFeedback.shared.soundsOn else {
            halt()
            return
        }
        guard let place = stack.last else {
            halt()
            return
        }
        if place == current, player?.isPlaying == true { return }
        guard let next = make(place) else {
            if let current, stack.contains(current), player?.isPlaying == true { return }
            halt()
            return
        }
        player?.stop()
        next.play()
        player = next
        current = place
    }

    private func halt() {
        player?.stop()
        player = nil
        current = nil
    }

    private func make(_ place: SceneLoop) -> AVAudioPlayer? {
        guard let url = BundleResources.audio(named: place.clip) else { return nil }
        let session = AVAudioSession.sharedInstance()
        if session.category == .soloAmbient || session.category == .ambient {
            try? session.setCategory(.ambient, options: [.mixWithOthers])
        }
        try? session.setActive(true)
        guard let next = try? AVAudioPlayer(contentsOf: url) else { return nil }
        next.numberOfLoops = -1
        next.volume = 0.4
        next.prepareToPlay()
        return next
    }
}

extension View {
    /// Starts the place loop while this view is on screen and sounds are on.
    /// Later calls sit above earlier ones. Turning sounds off stops the clip and keeps the lease.
    func sceneLoop(_ place: SceneLoop) -> some View {
        modifier(SceneLoopAttachment(place: place))
    }
}

private struct SceneLoopAttachment: ViewModifier {
    var place: SceneLoop

    func body(content: Content) -> some View {
        let soundsOn = GoobyFeedback.shared.soundsOn
        content
            .onChange(of: soundsOn) { _, on in
                SceneLoopPlayer.shared.applySounds(on)
            }
            .task(id: place.rawValue) { @MainActor in
                SceneLoopPlayer.shared.acquire(place)
                defer { SceneLoopPlayer.shared.release(place) }
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(for: .seconds(3_600))
                    } catch is CancellationError {
                        break
                    } catch {
                        continue
                    }
                }
            }
    }
}
