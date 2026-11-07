import CoreHaptics
import UIKit

@MainActor
final class GoobyHaptics {
    private var engine: CHHapticEngine?
    private let tap = UIImpactFeedbackGenerator(style: .soft)

    init() {
        tap.prepare()
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    func soft() {
        tap.impactOccurred(intensity: 0.7)
    }

    func celebrate() {
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
