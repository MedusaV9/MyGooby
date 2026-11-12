import AVFoundation
import Foundation

/// Local soundscape loops. `AVAudioPlayer` repeats the clip until stop or the fade timer.
@MainActor
@Observable
final class SoundscapePlayer {
    /// Chosen scene. Stays set while the sounds switch is off, so playback can resume.
    private(set) var active: String?
    /// True only while the clip is actually audible.
    private(set) var heard = false
    /// Minutes until the loop fades out. Zero means it runs until stop.
    var fadeMinutes: Int = 0
    var secondsLeft: Int?
    var fading = false

    private var player: AVAudioPlayer?
    private var endsAt: Date?
    private var frozenLeft: TimeInterval?
    private var clock: Task<Void, Never>?

    static let shared = SoundscapePlayer()
    static let names = ["rain", "ocean", "forest", "wind", "fire", "nature"]
    static let level: Float = 0.45
    private static let fadeSpan: TimeInterval = 8

    private init() {}

    func toggle(_ name: String) {
        if active == name {
            stop()
        } else {
            frozenLeft = nil
            endsAt = nil
            play(name, freshDeadline: true)
        }
    }

    func stop() {
        clock?.cancel()
        clock = nil
        player?.stop()
        player = nil
        active = nil
        heard = false
        fading = false
        secondsLeft = nil
        endsAt = nil
        frozenLeft = nil
    }

    func chooseFade(minutes: Int) {
        fadeMinutes = minutes
        fading = false
        player?.volume = Self.level
        guard active != nil else {
            endsAt = nil
            secondsLeft = nil
            frozenLeft = nil
            clock?.cancel()
            clock = nil
            return
        }
        resetDeadline()
        if heard {
            startClock()
            tick()
        } else {
            clock?.cancel()
            clock = nil
        }
    }

    /// Stops or resumes after `GoobyFeedback.soundsOn` changes. The chosen scene stays.
    func applySounds(_ on: Bool) {
        guard let name = active else { return }
        if on {
            guard player == nil else { return }
            play(name, freshDeadline: false)
        } else if player != nil {
            freeze()
            player?.stop()
            player = nil
            heard = false
        }
    }

    private func play(_ name: String, freshDeadline: Bool) {
        if !freshDeadline, let frozenLeft, frozenLeft <= 0.2 {
            stop()
            return
        }
        guard let url = BundleResources.audio(named: "sound-\(name)") else {
            stop()
            return
        }
        guard GoobyFeedback.shared.soundsOn else {
            player?.stop()
            player = nil
            heard = false
            clock?.cancel()
            clock = nil
            active = name
            if freshDeadline { resetDeadline() }
            return
        }
        // `.ambient` follows the Ring/Silent switch and mixes with scene loops.
        // `.playback` would keep playing while the silent switch is on.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        guard let next = try? AVAudioPlayer(contentsOf: url) else {
            stop()
            return
        }
        next.numberOfLoops = -1
        next.volume = Self.level
        next.prepareToPlay()
        player?.stop()
        guard next.play() else {
            stop()
            return
        }
        player = next
        active = name
        heard = true
        if freshDeadline {
            resetDeadline()
        } else if let frozenLeft {
            endsAt = Date().addingTimeInterval(frozenLeft)
            secondsLeft = max(0, Int(frozenLeft.rounded(.up)))
            self.frozenLeft = nil
            fading = false
        }
        startClock()
        tick()
    }

    private func resetDeadline() {
        fading = false
        if fadeMinutes > 0 {
            let span = TimeInterval(fadeMinutes * 60)
            secondsLeft = fadeMinutes * 60
            if heard {
                endsAt = Date().addingTimeInterval(span)
                frozenLeft = nil
            } else {
                endsAt = nil
                frozenLeft = span
            }
        } else {
            endsAt = nil
            secondsLeft = nil
            frozenLeft = nil
        }
    }

    private func freeze() {
        if let endsAt {
            frozenLeft = max(0, endsAt.timeIntervalSinceNow)
        }
        self.endsAt = nil
        clock?.cancel()
        clock = nil
        fading = false
    }

    private func startClock() {
        clock?.cancel()
        clock = nil
        guard endsAt != nil, heard else { return }
        clock = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(400))
                guard let self, !Task.isCancelled else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        guard heard, let endsAt else { return }
        let left = endsAt.timeIntervalSinceNow
        if left <= 0 {
            stop()
            return
        }
        let whole = max(0, Int(left.rounded(.up)))
        if secondsLeft != whole { secondsLeft = whole }
        if left <= Self.fadeSpan, !fading {
            fading = true
            player?.setVolume(0, fadeDuration: left)
        }
    }
}
