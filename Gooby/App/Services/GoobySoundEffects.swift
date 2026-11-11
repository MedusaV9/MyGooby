import AVFoundation
import Foundation

@MainActor
final class GoobySoundEffects {
    var enabled = true
    var masterVolume: Float = 0.8
    private var pools: [String: [AVAudioPlayer]] = [:]
    private var sessionReady = false
    private let voices = 3

    func preload(_ names: [String]) {
        guard enabled else { return }
        for name in names where pools[name] == nil {
            _ = makePlayer(name)
        }
    }

    func play(_ name: String, volume: Float = 1, force: Bool = false) {
        guard enabled || force else { return }
        prepareSession()
        guard let player = nextPlayer(name) else { return }
        player.volume = max(0, min(1, volume * masterVolume))
        player.currentTime = 0
        player.play()
    }

    func stopAll() {
        for pool in pools.values {
            for player in pool where player.isPlaying { player.stop() }
        }
    }

    // `.ambient` is what keeps effects quiet under the Ring/Silent switch and mixed with other apps' audio.
    // A module that switches the shared session to `.playback` makes these effects audible in silent mode too.
    private func prepareSession() {
        guard !sessionReady else { return }
        let session = AVAudioSession.sharedInstance()
        if session.category == .soloAmbient || session.category == .ambient {
            try? session.setCategory(.ambient, options: [.mixWithOthers])
        }
        sessionReady = true
    }

    private func nextPlayer(_ name: String) -> AVAudioPlayer? {
        let pool = pools[name] ?? []
        if let idle = pool.first(where: { !$0.isPlaying }) { return idle }
        if pool.count < voices, let made = makePlayer(name) { return made }
        return pool.first
    }

    private func makePlayer(_ name: String) -> AVAudioPlayer? {
        guard let url = BundleResources.audio(named: name),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        pools[name, default: []].append(player)
        return player
    }
}
