import AVFoundation
import Foundation

@MainActor
@Observable
final class SoundscapePlayer {
    var active: String?
    private var player: AVAudioPlayer?
    static let names = ["rain", "ocean", "forest", "wind", "fire", "nature"]

    func toggle(_ name: String) {
        if active == name {
            stop()
            return
        }
        guard let url = BundleResources.audio(named: "sound-\(name)") else {
            active = nil
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            let next = try AVAudioPlayer(contentsOf: url)
            next.numberOfLoops = -1
            next.volume = 0.45
            next.prepareToPlay()
            next.play()
            player = next
            active = name
        } catch {
            active = nil
            player = nil
        }
    }

    func stop() {
        player?.stop()
        player = nil
        active = nil
    }
}
