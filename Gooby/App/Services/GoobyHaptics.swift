import CoreHaptics
import UIKit

@MainActor
final class GoobyHaptics {
    private var engine: CHHapticEngine?
    private let tap = UIImpactFeedbackGenerator(style: .soft)
    /// Settings > Preferences > Haptic feedback (`GoobyEngine.hapticsOn`).
    var enabled = true

    init() {
        tap.prepare()
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    func soft() {
        guard enabled else { return }
        tap.impactOccurred(intensity: 0.7)
    }

    func celebrate() {
        guard enabled else { return }
        guard let engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            tap.impactOccurred(intensity: 1)
            return
        }
        let sharp = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
        ], relativeTime: 0)
        let soft = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.45),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        ], relativeTime: 0.12)
        do {
            let pattern = try CHHapticPattern(events: [sharp, soft], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            tap.impactOccurred()
        }
    }
}
