import AVFoundation
import Foundation

/// Sound effects for app moments (masterprompt 2.1 AVFoundation, 27 "Soundeffekte").
/// Effects are bundled files rendered with earshot (Gooby/Resources/Sounds/sfx-*.wav, made by
/// Tools/make_sounds.py and checked by Tools/check_sounds.py; no streaming).
/// `enabled` mirrors Settings > Preferences > Sound effects (`GoobyEngine.soundEffectsOn`).
@MainActor
final class GoobySounds {
    static let shared = GoobySounds()

    var enabled = true {
        didSet { if !enabled { stopAll() } }
    }

    /// Bundled effects (file `sfx-<rawValue>.wav`).
    enum Effect: String, CaseIterable {
        case tap, tab, toggleOn = "toggle-on", toggleOff = "toggle-off"
        case sheetOpen = "sheet-open", sheetClose = "sheet-close"
        case check, allDone = "all-done", undo, skip
        case sparkle, coin, energy, levelUp = "level-up"
        case depart, comeBack = "return", boop, hatch, knock, equip, page
        case focusStart = "focus-start", focusPause = "focus-pause", chime
        case mood1 = "mood-1", mood2 = "mood-2", mood3 = "mood-3", mood4 = "mood-4", mood5 = "mood-5"

        /// 0 for plain feedback (taps, tabs, switches, sheets), higher for bigger moments. When one
        /// action brings several moments (a goal that also fills the energy goal), the biggest
        /// sound plays and smaller ones right after it stay quiet.
        var rank: Int {
            switch self {
            case .tap, .tab, .toggleOn, .toggleOff, .sheetOpen, .sheetClose: return 0
            case .check, .undo, .skip, .boop, .equip, .page, .focusStart, .focusPause,
                 .mood1, .mood2, .mood3, .mood4, .mood5: return 1
            case .sparkle, .coin, .chime, .depart, .comeBack, .knock: return 2
            case .energy, .allDone, .hatch: return 3
            case .levelUp: return 4
            }
        }
    }

    /// Two players per effect, so a quick repeat does not cut the first one off.
    private var players: [Effect: [AVAudioPlayer]] = [:]
    private var lastPlayed: [Effect: Date] = [:]
    private var lastBig = (rank: 0, at: Date.distantPast)

    /// Every moment from `MomentHub`; plays the matching effect. Muted in screenshot runs.
    func handle(_ moment: GoobyMoment) {
        if case .booted = moment, enabled {
            preload()
            return
        }
        guard enabled, let effect = GoobySounds.effect(for: moment) else { return }
        play(effect)
    }

    /// The effect a moment plays, nil for moments without sound.
    static func effect(for moment: GoobyMoment) -> Effect? {
        switch moment {
        case .tap: return .tap
        case .tabChanged: return .tab
        case .toggled(let on): return on ? .toggleOn : .toggleOff
        case .sheetOpened: return .sheetOpen
        case .sheetClosed: return .sheetClose
        case .goalDone(_, _, let allDone): return allDone ? .allDone : .check
        case .goalUndone: return .undo
        case .goalSkipped: return .skip
        case .reward(let sparks, let energy): return sparks > 0 || energy > 0 ? .sparkle : nil
        case .questClaimed, .eventTaskClaimed, .giftReceived: return .sparkle
        case .energyReady: return .energy
        case .levelUp: return .levelUp
        case .adventureStarted: return .depart
        case .adventureReturned: return .comeBack
        case .storyAnswered: return .allDone
        case .focusStarted, .focusResumed, .breathStarted: return .focusStart
        case .focusPaused, .focusStopped: return .focusPause
        case .focusFinished, .movementDone: return .chime
        case .breathEnded(_, let cycles, let completed): return completed && cycles > 0 ? .chime : nil
        case .petted: return .boop
        case .eggHatched: return .hatch
        case .friendVisited: return .knock
        case .itemBought: return .coin
        case .itemEquipped, .companionChanged: return .equip
        case .moodLogged(let level):
            return [.mood1, .mood2, .mood3, .mood4, .mood5][min(4, max(0, level - 1))]
        case .journalSaved: return .page
        // Lifecycle moments (booted, active, background, saved, language, reset) stay silent.
        default: return nil
        }
    }

    func play(_ effect: Effect) {
        let now = Date()
        // The same effect at most every 70 ms (a burst of taps, one reward announced twice).
        if let last = lastPlayed[effect], now.timeIntervalSince(last) < 0.07 { return }
        // A smaller sound right after a bigger one would only muddy it (a goal check that also
        // reached the energy goal, a sheet closing on "Claim").
        if now.timeIntervalSince(lastBig.at) < 0.3 && effect.rank < lastBig.rank { return }
        lastPlayed[effect] = now
        if effect.rank > 0 { lastBig = (effect.rank, now) }
        GoobyAudioSession.activateForEffects()
        guard let player = freePlayer(for: effect) else { return }
        player.currentTime = 0
        player.play()
    }

    private func freePlayer(for effect: Effect) -> AVAudioPlayer? {
        if players[effect] == nil { load(effect) }
        guard let pool = players[effect], !pool.isEmpty else { return nil }
        return pool.first { !$0.isPlaying } ?? pool.max { $0.currentTime < $1.currentTime }
    }

    private func load(_ effect: Effect) {
        guard let url = Bundle.main.url(forResource: "sfx-\(effect.rawValue)", withExtension: "wav") else {
            players[effect] = []
            return
        }
        players[effect] = (0..<2).compactMap { _ in
            guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
            player.prepareToPlay()
            return player
        }
    }

    /// Loads the effects of the first taps right away; the rest load on first use.
    private func preload() {
        for effect in [Effect.tap, .tab, .sheetOpen, .sheetClose, .check] where players[effect] == nil {
            load(effect)
        }
    }

    private func stopAll() {
        for pool in players.values {
            for player in pool where player.isPlaying { player.stop() }
        }
    }
}

/// One audio session for effects and soundscapes. Effects use the ambient category: they mix with
/// other apps' audio and follow the Ring/Silent switch. A soundscape the user started switches to
/// playback (still mixing with other audio), so it plays with the switch on silent too.
@MainActor
enum GoobyAudioSession {
    private static var current: AVAudioSession.Category?
    private static var active = false
    private static var observer: NSObjectProtocol?
    private(set) static var soundscapeActive = false

    static func activateForEffects() {
        guard !soundscapeActive else { return }
        set(.ambient)
    }

    static func soundscape(_ active: Bool) {
        soundscapeActive = active
        set(active ? .playback : .ambient)
    }

    private static func set(_ category: AVAudioSession.Category) {
        let session = AVAudioSession.sharedInstance()
        if observer == nil {
            // A call or another app's audio interrupts the session; activate it again afterwards.
            observer = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { _ in
                MainActor.assumeIsolated { GoobyAudioSession.active = false }
            }
        }
        if current != category {
            try? session.setCategory(category, mode: .default, options: [.mixWithOthers])
            current = category
            active = false
        }
        if !active {
            active = (try? session.setActive(true)) != nil
        }
    }
}
