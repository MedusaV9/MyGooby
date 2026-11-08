import SwiftUI

/// Gooby on Home and in the room (masterprompt 1.3): plays each reaction the engine sets
/// (`engine.animation`, replayed on every `engine.celebration` and on every tap) once for its
/// length, then settles back into the ambient loop: idle with blinking and ear twitches, a small
/// fidget now and then, asleep at night until he is tapped awake. Leaving for an adventure walks
/// him out of the frame and lets him fade back in with his backpack. With reduced motion the rig
/// shows one still frame per pose and the fidgets stop.
struct GoobyLiveCharacter: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var preview: ItemDef? = nil
    var adventuring: Bool = false
    /// Night in his room: Gooby sleeps while nobody plays with him.
    var night: Bool = false
    /// Bumped by the owner on every tap, so the same reaction can play again.
    var tapToken: Int = 0

    @State private var reaction: GoobyAnimation?
    @State private var fidget: GoobyAnimation?
    @State private var play = 0
    @State private var hidden = false
    /// Gooby stays awake until then after a tap or a reaction at night.
    @State private var awakeUntil = Date.distantPast
    /// Ticks every 12 seconds so the sleep check sees the time move on.
    @State private var clock = 0

    var body: some View {
        let _ = clock
        GoobyCharacterView(
            look: engine.wornLook(preview: preview),
            stage: Growth.stage(of: engine.pet),
            animation: current,
            reduceMotion: reduceMotion,
            companion: engine.companionSpecies(),
            adventuring: adventuring
        )
        .opacity(hidden ? 0 : 1)
        .onAppear {
            if GoobyReactionMemo.isNew(engine) { react(engine.animation) }
        }
        .onChange(of: engine.animation) { _, next in react(next) }
        .onChange(of: engine.celebration) { _, _ in react(engine.animation) }
        .onChange(of: tapToken) { _, _ in react(engine.animation) }
        .task(id: reduceMotion) { await ambientLoop() }
    }

    private var asleep: Bool { night && !adventuring && Date() >= awakeUntil }

    private var ambient: GoobyAnimation { asleep ? .sleep : .idle }

    private var current: GoobyAnimation { reaction ?? fidget ?? ambient }

    private func react(_ next: GoobyAnimation) {
        GoobyReactionMemo.note(engine)
        guard next != .idle else {
            reaction = nil
            return
        }
        // Tapped while asleep: wake up first.
        let shown: GoobyAnimation = asleep && next != .sleep ? .wake : next
        if night { awakeUntil = Date().addingTimeInterval(90) }
        play += 1
        let token = play
        fidget = nil
        hidden = false
        reaction = shown
        let length = GoobyLiveCharacter.length(of: shown)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(length * 1_000_000_000))
            guard play == token else { return }
            if shown == .depart && !reduceMotion {
                // Walked out of the frame: come back in with the backpack.
                hidden = true
                reaction = nil
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard play == token else { return }
                withAnimation(.easeOut(duration: 0.5)) { hidden = false }
            } else {
                reaction = nil
            }
        }
    }

    /// Every 12 seconds: re-check the night sleep and, while nothing else plays, a small fidget
    /// (no fidgets with reduced motion; nothing in screenshot runs).
    private func ambientLoop() async {
        guard ShotMode.route == nil else { return }
        let moves: [GoobyAnimation] = [.ears, .hop, .wiggle, .think, .blink, .breathe]
        var index = 0
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            guard !Task.isCancelled else { return }
            if night { clock &+= 1 }
            guard !reduceMotion, reaction == nil, !asleep else { continue }
            fidget = moves[index % moves.count]
            index += 1
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            fidget = nil
        }
    }

    /// Seconds a reaction plays before Gooby settles again.
    static func length(of animation: GoobyAnimation) -> Double {
        switch animation {
        case .idle: return 0
        case .wiggle, .hop: return 2.0
        case .laugh: return 2.2
        case .arrive, .wave: return 2.4
        case .clap, .surprised: return 2.6
        case .hearts: return 2.8
        case .petting, .blink, .ears: return 3.0
        case .celebrate, .wake, .unwrap: return 3.2
        case .present: return 3.6
        case .dance, .think: return 4.0
        case .play: return 4.5
        case .breathe, .sit: return 5.0
        case .sleep: return 6.0
        case .depart: return 1.55
        }
    }
}

/// Remembers the last reaction any live Gooby has played, so a Gooby that appears later (the
/// room editor, a re-created Home) does not replay an old one.
@MainActor
enum GoobyReactionMemo {
    private static var lastAnimation: GoobyAnimation?
    private static var lastCelebration = -1

    static func isNew(_ engine: GoobyEngine) -> Bool {
        engine.animation != .idle && (engine.animation != lastAnimation || engine.celebration != lastCelebration)
    }

    static func note(_ engine: GoobyEngine) {
        lastAnimation = engine.animation
        lastCelebration = engine.celebration
    }
}
