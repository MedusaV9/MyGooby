import AVFoundation
import Foundation

/// Calm sounds (masterprompt 20: rain, ocean, forest, wind, fireplace, gentle nature). The loops are
/// bundled 48 s IMA4 CAF files (Gooby/Resources/Shell/Audio/sound-*.caf, synthesized by
/// Tools/make_sounds.py) that repeat without a seam. A sound fades in, fades out when stopped and
/// cross-fades when another one is picked; it resumes after a phone call or Siri.
@MainActor
@Observable
final class SoundscapePlayer {
    var active: String?
    @ObservationIgnored private var player: AVAudioPlayer?
    /// Players still fading out; kept until their fade ends.
    @ObservationIgnored private var fading: [AVAudioPlayer] = []
    @ObservationIgnored private var interruption: NSObjectProtocol?
    static let names = ["rain", "ocean", "forest", "wind", "fire", "nature"]

    private static let volume: Float = 0.9
    private static let fadeIn: TimeInterval = 1.6
    private static let fadeOut: TimeInterval = 0.9

    func toggle(_ name: String) {
        if active == name {
            stop()
            return
        }
        guard let url = Bundle.main.url(forResource: "sound-\(name)", withExtension: "caf") ?? BundleResources.audio(named: "sound-\(name)") else {
            stop()
            return
        }
        do {
            GoobyAudioSession.soundscape(true)
            let next = try AVAudioPlayer(contentsOf: url)
            next.numberOfLoops = -1
            next.volume = 0
            next.prepareToPlay()
            next.play()
            next.setVolume(SoundscapePlayer.volume, fadeDuration: SoundscapePlayer.fadeIn)
            retire(player)
            player = next
            active = name
            observeInterruptions()
        } catch {
            stop()
        }
    }

    func stop() {
        retire(player)
        player = nil
        active = nil
        GoobyAudioSession.soundscape(false)
    }

    /// Fades `old` out and lets it go when the fade is over.
    private func retire(_ old: AVAudioPlayer?) {
        guard let old else { return }
        old.setVolume(0, fadeDuration: SoundscapePlayer.fadeOut)
        fading.append(old)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64((SoundscapePlayer.fadeOut + 0.1) * 1_000_000_000))
            old.stop()
            self?.fading.removeAll { $0 === old }
        }
    }

    private func observeInterruptions() {
        guard interruption == nil else { return }
        interruption = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            MainActor.assumeIsolated {
                guard let self, raw == AVAudioSession.InterruptionType.ended.rawValue,
                      AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume),
                      let player = self.player, self.active != nil else { return }
                GoobyAudioSession.soundscape(true)
                player.play()
            }
        }
    }
}
