import SwiftUI
import UserNotifications

/// One name per moment. Screens and modules ask for a cue; the sound file, the haptic and the settings stay here.
enum GoobyCue: String, CaseIterable {
    case tap, tab, toggleOn, toggleOff, select, sheet
    case goalDone, goalUndo, allDone, coins, purchase, levelUp, gift, hatch
    case boop, giggle, questDone, notice, error, calm, save

    var sound: String {
        switch self {
        case .tap: return "sfx-tap"
        case .tab: return "sfx-tab"
        case .toggleOn: return "sfx-toggle-on"
        case .toggleOff: return "sfx-toggle-off"
        case .select: return "sfx-select"
        case .sheet: return "sfx-sheet"
        case .goalDone: return "sfx-goal-done"
        case .goalUndo: return "sfx-goal-undo"
        case .allDone: return "sfx-all-done"
        case .coins: return "sfx-coins"
        case .purchase: return "sfx-purchase"
        case .levelUp: return "sfx-level-up"
        case .gift: return "sfx-gift"
        case .hatch: return "sfx-hatch"
        case .boop: return "sfx-boop"
        case .giggle: return "sfx-giggle"
        case .questDone: return "sfx-quest-done"
        case .notice: return "sfx-notice"
        case .error: return "sfx-error"
        case .calm: return "sfx-calm"
        case .save: return "sfx-save"
        }
    }

    var feel: HapticFeel {
        switch self {
        case .tap: return .impact(.soft, 0.5)
        case .tab, .select: return .selection
        case .toggleOn: return .impact(.rigid, 0.55)
        case .toggleOff: return .impact(.soft, 0.5)
        case .sheet: return .impact(.soft, 0.35)
        case .goalDone, .questDone: return .pattern(.done)
        case .goalUndo: return .impact(.soft, 0.45)
        case .allDone: return .pattern(.allDone)
        case .coins, .purchase: return .pattern(.coins)
        case .levelUp: return .pattern(.levelUp)
        case .gift: return .pattern(.gift)
        case .hatch: return .pattern(.hatch)
        case .boop: return .impact(.soft, 0.8)
        case .giggle: return .pattern(.giggle)
        case .notice: return .impact(.light, 0.6)
        case .error: return .notify(.warning)
        case .calm: return .impact(.soft, 0.4)
        case .save: return .notify(.success)
        }
    }

    var volume: Float {
        switch self {
        case .tap, .tab, .select, .sheet: return 0.7
        case .levelUp, .allDone, .hatch, .gift: return 1
        default: return 0.85
        }
    }

    /// Bigger moments swallow smaller cues that land right after them (a goal that also levels Gooby up).
    var weight: Int {
        switch self {
        case .levelUp, .hatch: return 3
        case .allDone, .gift: return 2
        case .goalDone, .questDone, .purchase, .coins: return 1
        default: return 0
        }
    }
}

@MainActor
@Observable
final class GoobyFeedback {
    static let shared = GoobyFeedback()

    static let soundsKey = "gooby.feedback.sounds"
    static let hapticsKey = "gooby.feedback.haptics"

    var soundsOn: Bool {
        didSet {
            UserDefaults.standard.set(soundsOn, forKey: Self.soundsKey)
            sounds.enabled = soundsOn
            if !soundsOn { sounds.stopAll() }
        }
    }

    var hapticsOn: Bool {
        didSet {
            UserDefaults.standard.set(hapticsOn, forKey: Self.hapticsKey)
            haptics.enabled = hapticsOn
        }
    }

    @ObservationIgnored let sounds = GoobySoundEffects()
    @ObservationIgnored let haptics = GoobyHaptics()
    @ObservationIgnored private var lastPlayed: [GoobyCue: Date] = [:]
    @ObservationIgnored private var lastBig: (cue: GoobyCue, at: Date)?
    @ObservationIgnored private var auditionListed = false

    private init() {
        let defaults = UserDefaults.standard
        soundsOn = defaults.object(forKey: Self.soundsKey) as? Bool ?? true
        hapticsOn = defaults.object(forKey: Self.hapticsKey) as? Bool ?? true
        sounds.enabled = soundsOn
        haptics.enabled = hapticsOn
    }

    static func play(_ cue: GoobyCue) {
        shared.perform(cue)
    }

    func perform(_ cue: GoobyCue) {
        let now = Date()
        if let last = lastPlayed[cue], now.timeIntervalSince(last) < 0.06 { return }
        if let big = lastBig, big.cue.weight > cue.weight, now.timeIntervalSince(big.at) < 0.6 { return }
        lastPlayed[cue] = now
        if cue.weight > 0 { lastBig = (cue, now) }
        sounds.play(cue.sound, volume: cue.volume)
        haptics.play(cue.feel)
    }

    func breathe(rising: Bool, seconds: Double) {
        haptics.breathe(rising: rising, seconds: seconds)
    }

    func warmUp() {
        sounds.preload([GoobyCue.tap, .tab, .toggleOn, .toggleOff, .goalDone, .boop].map(\.sound))
        haptics.prepare()
        if !auditionListed {
            auditionListed = true
            FeatureHost.shared.devSections.append(("dev.feedback", { _ in AnyView(FeedbackAuditionList()) }))
        }
    }

    var notificationSound: UNNotificationSound {
        soundsOn ? UNNotificationSound(named: UNNotificationSoundName("sfx-notify.wav")) : .default
    }
}

extension View {
    /// Plays `cue` whenever `trigger` changes. For state that changes outside a button action.
    func goobyCue<T: Equatable>(_ cue: GoobyCue, trigger: T) -> some View {
        onChange(of: trigger) { _, _ in GoobyFeedback.play(cue) }
    }

    /// Plays `cue` when `flag` turns true, for sheets and overlays that open from several places.
    func goobyCue(_ cue: GoobyCue, opening flag: Bool) -> some View {
        onChange(of: flag) { _, open in
            if open { GoobyFeedback.play(cue) }
        }
    }
}

extension GoobyEngine {
    func cue(_ cue: GoobyCue) {
        GoobyFeedback.play(cue)
    }

    func cueFailure(_ key: String) -> String {
        cue(.error)
        return key
    }

    /// One cue for a step forward: a new growth stage beats a full day of goals, which beats the plain cue.
    func cueProgress(stageBefore: String, otherwise fallback: GoobyCue, countGoals: Bool = true) {
        if Growth.stage(of: pet) != stageBefore {
            cue(.levelUp)
            return
        }
        if countGoals {
            let progress = todayProgress()
            if progress.total > 0 && progress.done == progress.total {
                cue(.allDone)
                return
            }
        }
        cue(fallback)
    }
}
