import CoreHaptics
import UIKit

enum HapticFeel {
    case none
    case selection
    case impact(UIImpactFeedbackGenerator.FeedbackStyle, Double)
    case notify(UINotificationFeedbackGenerator.FeedbackType)
    case pattern(HapticPattern)
}

enum HapticPattern {
    case done, allDone, coins, levelUp, gift, hatch, giggle

    // (seconds, intensity, sharpness); a negative duration marks a transient.
    fileprivate var beats: [(time: Double, intensity: Float, sharpness: Float, duration: Double)] {
        switch self {
        case .done:
            return [(0, 0.55, 0.35, -1), (0.12, 0.8, 0.45, -1)]
        case .allDone:
            return [(0, 0.5, 0.3, -1), (0.09, 0.6, 0.35, -1), (0.18, 0.75, 0.45, -1), (0.3, 0.35, 0.15, 0.45), (0.42, 0.9, 0.5, -1)]
        case .coins:
            return [(0, 0.45, 0.7, -1), (0.06, 0.55, 0.75, -1), (0.12, 0.7, 0.8, -1)]
        case .levelUp:
            return [(0, 0.3, 0.2, 0.55), (0.1, 0.5, 0.3, -1), (0.25, 0.65, 0.4, -1), (0.4, 0.8, 0.5, -1), (0.62, 1, 0.55, -1), (0.7, 0.4, 0.2, 0.5)]
        case .gift:
            return [(0, 0.25, 0.1, 0.22), (0.2, 0.9, 0.35, -1), (0.32, 0.5, 0.6, -1), (0.4, 0.55, 0.7, -1)]
        case .hatch:
            return [(0, 0.55, 0.8, -1), (0.12, 0.65, 0.85, -1), (0.24, 1, 0.3, -1), (0.3, 0.35, 0.15, 0.3)]
        case .giggle:
            return [(0, 0.45, 0.5, -1), (0.08, 0.55, 0.55, -1), (0.16, 0.65, 0.6, -1)]
        }
    }
}

@MainActor
final class GoobyHaptics {
    var enabled = true
    private var engine: CHHapticEngine?
    private let supportsCore = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private let selector = UISelectionFeedbackGenerator()
    private let notifier = UINotificationFeedbackGenerator()
    private var impacts: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]

    func prepare() {
        guard enabled else { return }
        selector.prepare()
        impact(.soft).prepare()
    }

    func soft() {
        play(.impact(.soft, 0.7))
    }

    func celebrate() {
        play(.pattern(.done))
    }

    func play(_ feel: HapticFeel) {
        guard enabled else { return }
        switch feel {
        case .none:
            break
        case .selection:
            selector.selectionChanged()
            selector.prepare()
        case let .impact(style, intensity):
            let generator = impact(style)
            generator.impactOccurred(intensity: intensity)
            generator.prepare()
        case let .notify(kind):
            notifier.notificationOccurred(kind)
            notifier.prepare()
        case let .pattern(pattern):
            playPattern(pattern.beats, fallback: .impact(.soft, 1))
        }
    }

    /// A slow swell for one breathing phase. Core Haptics only: the generators have no continuous feel.
    func breathe(rising: Bool, seconds: Double) {
        guard enabled, seconds > 0.5 else { return }
        let length = min(seconds, 12)
        let curve = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            .init(relativeTime: 0, value: rising ? 0.15 : 0.7),
            .init(relativeTime: length * 0.85, value: rising ? 0.7 : 0.1),
            .init(relativeTime: length, value: 0)
        ], relativeTime: 0)
        playPattern([(0, 0.45, 0.1, length)], curves: [curve], fallback: .none)
    }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        if let found = impacts[style] { return found }
        let made = UIImpactFeedbackGenerator(style: style)
        impacts[style] = made
        return made
    }

    private func playPattern(_ beats: [(time: Double, intensity: Float, sharpness: Float, duration: Double)], curves: [CHHapticParameterCurve] = [], fallback: HapticFeel) {
        guard supportsCore, let engine = readyEngine() else {
            play(fallback)
            return
        }
        let events = beats.map { beat in
            CHHapticEvent(
                eventType: beat.duration < 0 ? .hapticTransient : .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: beat.intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: beat.sharpness)
                ],
                relativeTime: beat.time,
                duration: max(0, beat.duration)
            )
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            self.engine = nil
            play(fallback)
        }
    }

    private func readyEngine() -> CHHapticEngine? {
        if let engine { return engine }
        guard let made = try? CHHapticEngine() else { return nil }
        made.playsHapticsOnly = true
        made.isAutoShutdownEnabled = true
        made.stoppedHandler = { [weak self] _ in
            Task { @MainActor in self?.engine = nil }
        }
        made.resetHandler = { [weak self] in
            Task { @MainActor in self?.engine = nil }
        }
        do {
            try made.start()
        } catch {
            return nil
        }
        engine = made
        return made
    }
}
