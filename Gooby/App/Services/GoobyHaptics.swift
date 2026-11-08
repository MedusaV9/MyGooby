import CoreHaptics
import UIKit

@MainActor
final class GoobyHaptics {
    private var engine: CHHapticEngine?
    private let tap = UIImpactFeedbackGenerator(style: .soft)
    /// Settings > Preferences > Haptic feedback (`GoobyEngine.hapticsOn`).
    var enabled = true
    /// One pattern at a time: a second one within 0.25 s (one action, two moments) is dropped.
    private var lastPattern = Date.distantPast

    init() {
        tap.prepare()
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        // The system stops the engine in the background and on audio interruptions.
        engine?.resetHandler = { [weak self] in
            Task { @MainActor in try? self?.engine?.start() }
        }
        engine?.isAutoShutdownEnabled = true
        try? engine?.start()
    }

    func soft() {
        guard enabled else { return }
        tap.impactOccurred(intensity: 0.7)
    }

    func celebrate() {
        guard enabled else { return }
        play([(0, 0.7, 0.4), (0.12, 0.45, 0.2)])
    }

    /// Three rising taps for the bigger moments (growth stage, energy goal reached).
    func cheer() {
        guard enabled else { return }
        play([(0, 0.45, 0.3), (0.09, 0.65, 0.4), (0.18, 0.9, 0.5)])
    }

    /// Moments from `MomentHub` that the engine does not already give a haptic for (goals,
    /// quests, purchases, petting, hatching and visits call `soft` / `celebrate` themselves).
    func handle(_ moment: GoobyMoment) {
        guard enabled else { return }
        switch moment {
        case .energyReady, .levelUp: cheer()
        case .eventTaskClaimed, .adventureReturned: celebrate()
        case .adventureStarted, .goalUndone, .itemEquipped, .companionChanged, .moodLogged, .journalSaved, .movementDone:
            soft()
        case .breathEnded(_, let cycles, let completed) where completed && cycles > 0: soft()
        default: break
        }
    }

    /// Transient taps (time s, intensity, sharpness); a soft impact where Core Haptics is missing.
    private func play(_ taps: [(TimeInterval, Float, Float)]) {
        let now = Date()
        guard now.timeIntervalSince(lastPattern) > 0.25 else { return }
        lastPattern = now
        guard let engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            tap.impactOccurred(intensity: 1)
            return
        }
        let events = taps.map { time, intensity, sharpness in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: time)
        }
        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            tap.impactOccurred()
        }
    }
}
