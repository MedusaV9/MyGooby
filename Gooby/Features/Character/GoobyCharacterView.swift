import SwiftUI

// Gooby, the plush baby bunny (masterprompt 1.1-1.3, 12, 14), drawn after the character
// reference: a big round head with huge wide-set glossy eyes, big blush cheeks, a tiny pink nose
// and an open smile, two tall ears with pale-pink insides, a fur tuft on top, and a small chubby
// body with the paws held together under the chin.
//
// The rig is drawn in a 320 x 320 design box with the origin in its center (y grows down) and
// scaled to the space it gets. Layers back to front: backpack, ears, body, garments, feet, straps,
// arms, sleeves, tuft, head, face, head and neck wear, effects. Fur parts are flat-shaded like a
// soft plush toy: a radial light from the top left into a warmer shade and a thin tonal outline.

enum GoobyAnimation: String, CaseIterable, Identifiable {
    case idle, breathe, blink, ears, wiggle, hop, laugh, clap
    case surprised, think, sit, sleep, wake, petting, hearts, dance
    case play, unwrap, present, depart, arrive, celebrate
    /// Waves hello with one paw.
    case wave

    var id: String { rawValue }
}

struct WornLook: Equatable {
    var fur: String = "fur-cream"
    var slots: [String: ItemDef] = [:]
}

enum GoobyEyes {
    case open, happy, closed
}

enum GoobyMouth {
    /// Open happy smile with a pink tongue.
    case smile
    /// Wide open laugh.
    case laugh
    /// Small "o" (surprised, yawning).
    case round
    /// Closed little smile (asleep).
    case sleepy
    /// Small sideways smile (thinking).
    case flat
}

/// One frame of Gooby's body language. Angles are in degrees, offsets in design units.
struct GoobyPose {
    var time: Double = 0
    var breath: CGFloat = 1
    /// 1 = eyes open, 0 = shut.
    var blink: CGFloat = 1
    /// Outward lean added to both ears (positive = drooping outwards).
    var ear: CGFloat = 0
    var earL: CGFloat = 0
    var earR: CGFloat = 0
    /// Negative = up.
    var hop: CGFloat = 0
    var tilt: CGFloat = 0
    /// < 1 squashes (wider, lower), > 1 stretches.
    var squash: CGFloat = 1
    /// 0 = paws resting under the chin, 1 = paws together (clap).
    var arm: CGFloat = 0
    /// 0 = resting, 1 = arm up.
    var raiseL: CGFloat = 0
    var raiseR: CGFloat = 0
    var sit: CGFloat = 0
    var sleep: Bool = false
    var hearts: Bool = false
    var zzz: Bool = false
    var sparkles: Bool = false
    var thought: Bool = false
    var surprise: CGFloat = 0
    /// 0 = home, 1 = walked out to the right.
    var depart: CGFloat = 0
    var eyes: GoobyEyes = .open
    var mouth: GoobyMouth = .smile
    /// Gaze, -1...1 (x right, y down).
    var lookX: CGFloat = 0
    var lookY: CGFloat = 0
    var blush: CGFloat = 1
    /// Gift box lid, 0 = closed, 1 = open; nil = no gift.
    var gift: CGFloat?
    /// Companion hop while playing.
    var friendHop: CGFloat = 0
    /// Bunny nose nibble, -1...1.
    var nose: CGFloat = 0
}

struct GoobyCharacterView: View {
    var look: WornLook
    var stage: String
    var animation: GoobyAnimation
    var reduceMotion: Bool
    var companion: String?
    var showCompanion: Bool = true
    /// Draws a red backpack while Gooby is on an adventure.
    var adventuring: Bool = false

    /// When the current animation started; one-shot moves (hops, departures) run from there.
    @State private var started = Date()
    /// The animation before the current one and when it started, for the cross-fade.
    @State private var previous: GoobyAnimation?
    @State private var previousStarted = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 30.0, paused: reduceMotion)) { timeline in
            GoobyRig(look: look, stage: stage, pose: pose(at: timeline.date), companion: showCompanion ? companion : nil, adventuring: adventuring)
        }
        .onChange(of: animation) { old, _ in
            previous = old
            previousStarted = started
            started = Date()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gooby")
    }

    /// The pose at `date`; for 0.3 s after a change it blends out of the previous animation.
    private func pose(at date: Date) -> GoobyPose {
        let time = date.timeIntervalSinceReferenceDate
        let elapsed = max(0, date.timeIntervalSince(started))
        let next = GoobyPose.make(animation: animation, time: time, elapsed: elapsed, reduce: reduceMotion)
        guard !reduceMotion, let previous, elapsed < GoobyPose.blendLength else { return next }
        let before = GoobyPose.make(animation: previous, time: time, elapsed: max(0, date.timeIntervalSince(previousStarted)), reduce: false)
        let k = CGFloat(elapsed / GoobyPose.blendLength)
        return GoobyPose.blend(before, next, k * k * (3 - 2 * k))
    }
}

/// Head-and-ears crop of Gooby in a still idle pose (tab icon, progress tracks, small badges).
struct GoobyAvatar: View {
    var look: WornLook
    var stage: String
    var size: CGFloat

    var body: some View {
        // Shows the design band from the ear tips (-150) to just below the chin (+92).
        let full = size * 320 / 242
        GoobyRig(look: look, stage: stage, pose: GoobyPose.make(animation: .idle, time: 0, reduce: true), companion: nil)
            .frame(width: full, height: full)
            .offset(y: full * 29 / 320)
            .frame(width: size, height: size)
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Gooby")
    }
}

// MARK: - Poses

extension GoobyPose {
    /// Seconds a change of animation takes to blend.
    static let blendLength: Double = 0.3

    /// `time` drives the ambient loops (breathing, blinking), `elapsed` (seconds since the
    /// animation started) the one-shot moves, so a hop always starts with its crouch.
    static func make(animation: GoobyAnimation, time: Double, elapsed: Double? = nil, reduce: Bool) -> GoobyPose {
        var pose = GoobyPose()
        pose.express(animation)
        if reduce {
            pose.freeze(animation)
            return pose
        }
        pose.time = time
        pose.animate(animation, time: time, elapsed: elapsed ?? time)
        return pose
    }

    /// Mixes the body language of two poses (`k` 0 = `a`, 1 = `b`); face and props come from `b`.
    static func blend(_ a: GoobyPose, _ b: GoobyPose, _ k: CGFloat) -> GoobyPose {
        func mix(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * k }
        var pose = b
        pose.breath = mix(a.breath, b.breath)
        pose.ear = mix(a.ear, b.ear)
        pose.earL = mix(a.earL, b.earL)
        pose.earR = mix(a.earR, b.earR)
        pose.hop = mix(a.hop, b.hop)
        pose.tilt = mix(a.tilt, b.tilt)
        pose.squash = mix(a.squash, b.squash)
        pose.arm = mix(a.arm, b.arm)
        pose.raiseL = mix(a.raiseL, b.raiseL)
        pose.raiseR = mix(a.raiseR, b.raiseR)
        pose.sit = mix(a.sit, b.sit)
        pose.surprise = mix(a.surprise, b.surprise)
        pose.lookX = mix(a.lookX, b.lookX)
        pose.lookY = mix(a.lookY, b.lookY)
        pose.blush = mix(a.blush, b.blush)
        pose.friendHop = mix(a.friendHop, b.friendHop)
        return pose
    }

    /// Face and props of each animation; shared by the moving and the reduced-motion pose.
    private mutating func express(_ animation: GoobyAnimation) {
        switch animation {
        case .hop:
            mouth = .laugh
        case .laugh:
            eyes = .happy
            mouth = .laugh
            blush = 1.3
        case .clap:
            eyes = .happy
            mouth = .laugh
            sparkles = true
            arm = 1
        case .surprised:
            surprise = 1
            mouth = .round
            ear = -6
        case .think:
            mouth = .flat
            thought = true
            lookX = -0.5
            lookY = -0.7
            earR = 26
        case .sit:
            sit = 1
        case .sleep:
            sleep = true
            zzz = true
            eyes = .closed
            mouth = .sleepy
            sit = 0.6
            ear = 22
        case .petting:
            eyes = .happy
            blush = 1.5
            hearts = true
            squash = 0.94
            ear = 14
        case .hearts:
            eyes = .happy
            hearts = true
            blush = 1.25
        case .dance:
            eyes = .happy
            mouth = .laugh
            sparkles = true
        case .play:
            mouth = .laugh
            lookX = 0.6
        case .unwrap:
            gift = 0.8
            mouth = .laugh
            sparkles = true
        case .present:
            eyes = .happy
            raiseL = 0.5
            raiseR = 0.5
            sparkles = true
        case .depart:
            lookX = 0.6
        case .arrive:
            eyes = .happy
            hearts = true
        case .celebrate:
            eyes = .happy
            mouth = .laugh
            raiseL = 1
            raiseR = 1
            hearts = true
            sparkles = true
        case .wave:
            raiseR = 0.85
            blush = 1.15
        case .idle, .breathe, .blink, .ears, .wiggle, .wake:
            break
        }
    }

    /// Reduced motion: one gentle still frame that still reads as the animation.
    private mutating func freeze(_ animation: GoobyAnimation) {
        switch animation {
        case .dance: raiseL = 0.8
        case .wiggle: tilt = 3
        case .ears: earL = -8; earR = 10
        default: break
        }
    }

    private mutating func animate(_ animation: GoobyAnimation, time t: Double, elapsed e: Double) {
        let wave = CGFloat(sin(t * 1.6))
        breath = 1 + 0.018 * wave
        ear += wave * 2.5
        if eyes == .open {
            blink = GoobyPose.blink(at: t, period: animation == .blink ? 1.7 : 4.4)
        }
        nose = GoobyPose.nibble(at: t, period: 5.3)
        switch animation {
        case .idle, .blink:
            earR += GoobyPose.twitch(at: t, period: 6.5) * 12
            earL += GoobyPose.twitch(at: t + 3.1, period: 9.4) * 9
            lookX += GoobyPose.glance(at: t, period: 7.8)
            tilt = CGFloat(sin(t * 0.8)) * 1.2
        case .breathe:
            breath = 1 + 0.035 * CGFloat(sin(t * 1.1))
            ear += CGFloat(sin(t * 1.1)) * 3
        case .ears:
            earL = CGFloat(sin(t * 3)) * 14
            earR = CGFloat(sin(t * 3 + .pi)) * 14
            tilt = CGFloat(sin(t * 1.5)) * 2
        case .wiggle:
            tilt = CGFloat(sin(t * 6)) * 6
            squash = 1 + 0.025 * CGFloat(sin(t * 12))
            earL = CGFloat(sin(t * 6 + 0.6)) * 8
            earR = -earL
        case .hop, .celebrate:
            let jump = GoobyPose.jump(at: e, period: animation == .celebrate ? 0.8 : 0.65, height: 28)
            hop = jump.lift
            squash = jump.squash
            ear += jump.rise * 12
            if animation == .celebrate {
                raiseL = 0.85 + 0.15 * (-jump.lift / 28)
                raiseR = raiseL
            }
        case .laugh:
            let shake = CGFloat(sin(t * 9))
            tilt = shake * 3
            hop = -abs(shake) * 3
            squash = 1 - 0.03 * abs(shake)
            ear += abs(shake) * 6
            arm = 0.4 + 0.3 * abs(shake)
        case .clap:
            arm = 0.55 + 0.45 * (CGFloat(sin(t * 7)) + 1) / 2
            hop = -abs(CGFloat(sin(t * 3.5))) * 4
            ear += abs(CGFloat(sin(t * 3.5))) * 5
        case .surprised:
            let phase = e.truncatingRemainder(dividingBy: 2.6)
            let pop = phase < 0.35 ? CGFloat(sin(phase / 0.35 * .pi)) : 0
            hop = -14 * pop
            squash = 1 + 0.05 * pop
            ear = -8 - 4 * pop
            raiseL = 0.25 * pop
            raiseR = 0.25 * pop
        case .think:
            tilt = -6 + CGFloat(sin(t * 1.2)) * 2
            arm = 0.6
        case .sit:
            breath = 1 + 0.014 * CGFloat(sin(t * 1.2))
            lookX += GoobyPose.glance(at: t, period: 6.4)
        case .sleep:
            breath = 1 + 0.03 * CGFloat(sin(t * 0.8))
            ear = 22 + CGFloat(sin(t * 0.8)) * 2
            tilt = 3 + CGFloat(sin(t * 0.4)) * 2
            nose = 0
        case .wake:
            let phase = e.truncatingRemainder(dividingBy: 3.2)
            if phase < 1.0 {
                eyes = .closed
                mouth = .sleepy
                ear = 20
            } else if phase < 2.0 {
                let stretch = CGFloat(sin((phase - 1.0) * .pi))
                raiseL = stretch
                raiseR = stretch
                breath = 1 + 0.04 * stretch
                ear = 20 - 28 * stretch
                eyes = .closed
                mouth = .round
            } else {
                blink = GoobyPose.blink(at: t, period: 0.6)
                hop = -abs(CGFloat(sin((phase - 2.0) * .pi * 2))) * 5
            }
        case .petting:
            squash = 0.93 + 0.02 * CGFloat(sin(t * 4))
            tilt = 4 + CGFloat(sin(t * 2)) * 3
            ear = 14 + CGFloat(sin(t * 2)) * 4
            arm = 0.5
        case .hearts:
            hop = -abs(CGFloat(sin(t * 2.5))) * 8
            ear += abs(CGFloat(sin(t * 2.5))) * 5
            arm = 0.8
        case .dance:
            let beat = CGFloat(sin(t * 4))
            tilt = beat * 10
            hop = -abs(beat) * 14
            raiseL = max(0, beat)
            raiseR = max(0, -beat)
            earL = beat * 10
            earR = beat * 10
        case .play:
            tilt = CGFloat(sin(t * 3)) * 6
            hop = -abs(CGFloat(sin(t * 3))) * 10
            ear += abs(CGFloat(sin(t * 3))) * 6
            friendHop = -abs(CGFloat(sin(t * 3 + 1.2))) * 16
        case .unwrap:
            let phase = e.truncatingRemainder(dividingBy: 3.2)
            let lid = CGFloat(min(1, max(0, (phase - 0.9) / 0.5)))
            gift = lid
            if lid < 0.5 {
                arm = 0.6
                mouth = .smile
                sparkles = false
            } else {
                surprise = lid
                hop = -6 * lid
                raiseL = 0.4 * lid
                raiseR = 0.4 * lid
            }
        case .present:
            let sway = CGFloat(sin(t * 2))
            tilt = sway * 6
            raiseL = 0.5 + 0.15 * sway
            raiseR = 0.5 - 0.15 * sway
            hop = -2
        case .depart:
            let phase = e.truncatingRemainder(dividingBy: 2.4)
            depart = CGFloat(min(1, phase / 1.6))
            hop = -abs(CGFloat(sin(t * 9))) * 10
            ear += abs(CGFloat(sin(t * 9))) * 6
        case .arrive:
            let phase = e.truncatingRemainder(dividingBy: 2.4)
            depart = CGFloat(max(0, 1 - phase / 1.2))
            hop = depart > 0 ? -abs(CGFloat(sin(t * 9))) * 10 : 0
        case .wave:
            let swing = CGFloat(sin(e * 9))
            raiseR = 0.8 + 0.2 * swing
            tilt = -3 + CGFloat(sin(e * 2.2)) * 2
            earR = -6 + swing * 4
            earL = 4
        }
    }

    /// 1 most of the time, dips to ~0 for a short blink at the end of every period; every third
    /// blink is a double blink.
    static func blink(at t: Double, period: Double) -> CGFloat {
        let window = min(0.26, period * 0.4)
        let cycle = t.truncatingRemainder(dividingBy: period)
        let round = Int(t / period)
        let double = round % 3 == 2 && period > 1
        let start = period - window * (double ? 2.2 : 1)
        guard cycle > start else { return 1 }
        let local = ((cycle - start) / window).truncatingRemainder(dividingBy: 1.1)
        guard local < 1 else { return 1 }
        return max(0.05, CGFloat(abs(local * 2 - 1)))
    }

    /// A quick flick (-1...1) at the start of every period, 0 otherwise.
    static func twitch(at t: Double, period: Double) -> CGFloat {
        let cycle = t.truncatingRemainder(dividingBy: period)
        guard cycle < 0.45 else { return 0 }
        return CGFloat(sin(cycle / 0.45 * .pi * 2))
    }

    /// Three quick bunny nose nibbles at the start of every period.
    static func nibble(at t: Double, period: Double) -> CGFloat {
        let cycle = t.truncatingRemainder(dividingBy: period)
        guard cycle < 0.6 else { return 0 }
        return CGFloat(sin(cycle / 0.6 * .pi * 6))
    }

    /// Looks to one side for a moment once per period, alternating sides (-0.6...0.6).
    static func glance(at t: Double, period: Double) -> CGFloat {
        let cycle = t.truncatingRemainder(dividingBy: period)
        let side: CGFloat = Int(t / period) % 2 == 0 ? 0.6 : -0.6
        guard cycle > period - 1.6 else { return 0 }
        let local = (cycle - (period - 1.6)) / 1.6
        return side * CGFloat(sin(local * .pi))
    }

    /// One hop per period: a short crouch, a stretched take-off, a squashed landing.
    /// `lift` is the (negative) height, `rise` 1 while going up and -1 while coming down.
    static func jump(at t: Double, period: Double, height: CGFloat) -> (lift: CGFloat, squash: CGFloat, rise: CGFloat) {
        let p = (t / period).truncatingRemainder(dividingBy: 1)
        if p < 0.16 {
            return (0, 1 - 0.07 * CGFloat(sin(p / 0.16 * .pi)), 0)
        }
        if p < 0.84 {
            let a = (p - 0.16) / 0.68
            let lift = CGFloat(sin(a * .pi))
            let rise = CGFloat(cos(a * .pi))
            return (-height * lift, 1 + 0.05 * abs(rise), rise)
        }
        return (0, 1 - 0.08 * CGFloat(sin((p - 0.84) / 0.16 * .pi)), 0)
    }
}

// MARK: - Rig

/// Subtle growth stages: ear length and cheek size change, the round shape never does.
enum GoobyStageLook {
    static func earScale(_ stage: String) -> CGFloat {
        switch stage {
        case "baby": return 0.92
        case "little": return 0.96
        case "young": return 1.0
        case "teen": return 1.03
        default: return 1.06
        }
    }

    static func cheekScale(_ stage: String) -> CGFloat {
        switch stage {
        case "baby": return 1.1
        case "little": return 1.05
        case "young": return 1.0
        case "teen": return 0.97
        default: return 0.94
        }
    }
}

extension View {
    /// Places a view of size `w` x `h` with its center at (`x`, `y`) of a centered design box.
    func goobyAt(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> some View {
        frame(width: w, height: h).offset(x: x, y: y)
    }
}

struct GoobyRig: View {
    var look: WornLook
    var stage: String
    var pose: GoobyPose
    var companion: String?
    var adventuring: Bool = false

    /// The ground line (y = 152) of the design box as a unit point.
    static let ground = UnitPoint(x: 0.5, y: 312.0 / 320.0)

    var body: some View {
        GeometryReader { geo in
            let unit = min(geo.size.width, geo.size.height)
            let growth = CGFloat(Growth.scale(for: stage))
            let squash = pose.squash * (1 + 0.035 * pose.sit)
            let walk = pose.depart * 176
            ZStack {
                GoobyShadowLayer(lift: pose.hop)
                    .offset(x: walk)
                figure
                    .scaleEffect(x: (2 - squash) * growth, y: squash * pose.breath * growth, anchor: GoobyRig.ground)
                    .offset(y: pose.hop)
                    .rotationEffect(.degrees(pose.tilt), anchor: GoobyRig.ground)
                    .offset(x: walk)
                if let companion {
                    MiniFriendArt(species: companion, time: pose.time == 0 ? nil : pose.time)
                        .goobyAt(124, 110 + pose.friendHop, 82, 82)
                }
            }
            .frame(width: 320, height: 320)
            .scaleEffect(unit / 320)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var fur: FurPaint {
        FurPaint.resolve(look.fur)
    }

    private static let torsoSlots = ["pants", "dress", "shirt", "sweater", "jacket"]
    private static let sleeveSlots = ["shirt", "sweater", "jacket", "dress"]
    private static let headSlots = ["scarf", "glasses", "hat", "bow", "accessory"]

    private var figure: some View {
        let paint = fur
        return ZStack {
            Group {
                if let pack = look.slots["backpack"] {
                    GearShape(item: pack, pose: pose, part: .back)
                } else if adventuring {
                    AdventurePackLayer(front: false)
                }
                GoobyEarsLayer(fur: paint, pose: pose, stage: stage)
                GoobyBodyLayer(fur: paint, pose: pose)
                ForEach(GoobyRig.torsoSlots, id: \.self) { slot in
                    if let item = look.slots[slot] { GearShape(item: item, pose: pose) }
                }
                GoobyFeetLayer(fur: paint, pose: pose)
                if let shoes = look.slots["shoes"] { GearShape(item: shoes, pose: pose) }
            }
            Group {
                if let pack = look.slots["backpack"] {
                    GearShape(item: pack, pose: pose, part: .front)
                } else if adventuring {
                    AdventurePackLayer(front: true)
                }
                GoobyPawsLayer(fur: paint, pose: pose)
                ForEach(GoobyRig.sleeveSlots, id: \.self) { slot in
                    if let item = look.slots[slot] { GearShape(item: item, pose: pose, part: .sleeves) }
                }
                GoobyNeckShade(fur: paint)
                GoobyTuftLayer(fur: paint)
                GoobyHeadLayer(fur: paint, pose: pose, cheekScale: GoobyStageLook.cheekScale(stage))
                GoobyFaceLayer(pose: pose, fur: paint)
            }
            Group {
                ForEach(GoobyRig.headSlots, id: \.self) { slot in
                    if let item = look.slots[slot] { GearShape(item: item, pose: pose) }
                }
                if let lid = pose.gift { GoobyGiftLayer(lid: lid) }
                GoobyEffectsLayer(pose: pose)
            }
        }
        .frame(width: 320, height: 320)
    }
}

struct FurPaint {
    var body: Color
    var shade: Color
    var cheek: Color
    var innerEar: Color
    /// Lit top-left of every fur part.
    var light: Color
    /// Thin tonal outline.
    var outline: Color
    /// Pale top of the inner ear.
    var innerLight: Color

    static func resolve(_ id: String) -> FurPaint {
        switch id {
        case "fur-peach":
            return FurPaint(body: Color(hex: 0xFFE3CD), shade: Color(hex: 0xF4C6A6), cheek: Color(hex: 0xFF9AAE), innerEar: Color(hex: 0xFFAFC0), light: Color(hex: 0xFFF5EC), outline: Color(hex: 0xDDA582), innerLight: Color(hex: 0xFFD3DD))
        case "fur-lilac":
            return FurPaint(body: Color(hex: 0xF0E7FF), shade: Color(hex: 0xDACCF3), cheek: Color(hex: 0xF5A6C9), innerEar: Color(hex: 0xF6B9D6), light: Color(hex: 0xFDFBFF), outline: Color(hex: 0xB8A5DC), innerLight: Color(hex: 0xFCD9EA))
        case "fur-mint":
            return FurPaint(body: Color(hex: 0xEBF8EF), shade: Color(hex: 0xCBE8D6), cheek: Color(hex: 0xFFA9BF), innerEar: Color(hex: 0xFFBCCF), light: Color(hex: 0xFBFFFC), outline: Color(hex: 0xA6CFB6), innerLight: Color(hex: 0xFFDCE6))
        case "fur-honey":
            return FurPaint(body: Color(hex: 0xFFEDC9), shade: Color(hex: 0xF0CF94), cheek: Color(hex: 0xFFA6B8), innerEar: Color(hex: 0xFFB8C8), light: Color(hex: 0xFFFAEC), outline: Color(hex: 0xD6AA66), innerLight: Color(hex: 0xFFDAE2))
        case "fur-sky":
            return FurPaint(body: Color(hex: 0xECF5FF), shade: Color(hex: 0xCCE0F3), cheek: Color(hex: 0xFFAAC4), innerEar: Color(hex: 0xFFBCD1), light: Color(hex: 0xFBFDFF), outline: Color(hex: 0xA6C3DC), innerLight: Color(hex: 0xFFDCE7))
        default:
            return FurPaint(body: Color(hex: 0xF8ECDA), shade: Color(hex: 0xEDD8BA), cheek: Color(hex: 0xF7A1A5), innerEar: Color(hex: 0xF5B8B4), light: Color(hex: 0xFFFBF3), outline: Color(hex: 0xDCBE98), innerLight: Color(hex: 0xFBD9D5))
        }
    }

    /// Soft plush shading for one fur part: light where the light falls, shade at the far edge.
    func gradient(center: UnitPoint = UnitPoint(x: 0.38, y: 0.3), reach: CGFloat = 0.8) -> EllipticalGradient {
        EllipticalGradient(
            stops: [
                .init(color: light, location: 0),
                .init(color: body, location: 0.45),
                .init(color: shade, location: 1)
            ],
            center: center,
            startRadiusFraction: 0,
            endRadiusFraction: reach
        )
    }
}

/// One fur part: plush gradient and a thin tonal outline (`line` 0 leaves the outline out).
struct GoobyFurPart<S: Shape>: View {
    var shape: S
    var fur: FurPaint
    var center: UnitPoint = UnitPoint(x: 0.38, y: 0.3)
    var reach: CGFloat = 0.8
    var line: CGFloat = 2.4

    var body: some View {
        ZStack {
            shape.fill(fur.gradient(center: center, reach: reach))
            if line > 0 {
                shape.stroke(fur.outline, lineWidth: line)
            }
        }
    }
}

// MARK: - Shapes

/// Rounded "mochi" blob: an ellipse with fuller shoulders whose widest point sits at `widest`.
struct GoobyBlobShape: Shape {
    var widest: CGFloat = 0.56
    var round: CGFloat = 0.6

    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        let mid = y + h * widest
        let upper = h * widest
        let lower = h - upper
        var path = Path()
        path.move(to: CGPoint(x: x + w / 2, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: mid), control1: CGPoint(x: x + w / 2 + w / 2 * round, y: y), control2: CGPoint(x: x + w, y: mid - upper * round))
        path.addCurve(to: CGPoint(x: x + w / 2, y: y + h), control1: CGPoint(x: x + w, y: mid + lower * round), control2: CGPoint(x: x + w / 2 + w / 2 * round, y: y + h))
        path.addCurve(to: CGPoint(x: x, y: mid), control1: CGPoint(x: x + w / 2 - w / 2 * round, y: y + h), control2: CGPoint(x: x, y: mid + lower * round))
        path.addCurve(to: CGPoint(x: x + w / 2, y: y), control1: CGPoint(x: x, y: mid - upper * round), control2: CGPoint(x: x + w / 2 - w / 2 * round, y: y))
        path.closeSubpath()
        return path
    }
}

/// Gooby's head: a round top, full cheeks just below the middle and a soft, wide chin.
struct GoobyBunShape: Shape {
    var widest: CGFloat = 0.58
    var top: CGFloat = 0.6
    var sideUp: CGFloat = 0.56
    var sideDown: CGFloat = 0.6
    var bottom: CGFloat = 0.7

    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        let mid = y + h * widest
        let upper = h * widest
        let lower = h - upper
        var path = Path()
        path.move(to: CGPoint(x: x + w / 2, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: mid), control1: CGPoint(x: x + w / 2 + w / 2 * top, y: y), control2: CGPoint(x: x + w, y: mid - upper * sideUp))
        path.addCurve(to: CGPoint(x: x + w / 2, y: y + h), control1: CGPoint(x: x + w, y: mid + lower * sideDown), control2: CGPoint(x: x + w / 2 + w / 2 * bottom, y: y + h))
        path.addCurve(to: CGPoint(x: x, y: mid), control1: CGPoint(x: x + w / 2 - w / 2 * bottom, y: y + h), control2: CGPoint(x: x, y: mid + lower * sideDown))
        path.addCurve(to: CGPoint(x: x + w / 2, y: y), control1: CGPoint(x: x, y: mid - upper * sideUp), control2: CGPoint(x: x + w / 2 - w / 2 * top, y: y))
        path.closeSubpath()
        return path
    }
}

/// Long bunny ear: round tip, fullest at a third of its height, narrower base.
struct GoobyEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x + w * 0.5, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: y + h * 0.36), control1: CGPoint(x: x + w * 0.86, y: y), control2: CGPoint(x: x + w, y: y + h * 0.15))
        path.addCurve(to: CGPoint(x: x + w * 0.66, y: y + h), control1: CGPoint(x: x + w, y: y + h * 0.62), control2: CGPoint(x: x + w * 0.84, y: y + h * 0.9))
        path.addLine(to: CGPoint(x: x + w * 0.34, y: y + h))
        path.addCurve(to: CGPoint(x: x, y: y + h * 0.36), control1: CGPoint(x: x + w * 0.16, y: y + h * 0.9), control2: CGPoint(x: x, y: y + h * 0.62))
        path.addCurve(to: CGPoint(x: x + w * 0.5, y: y), control1: CGPoint(x: x, y: y + h * 0.15), control2: CGPoint(x: x + w * 0.14, y: y))
        path.closeSubpath()
        return path
    }
}

/// A soft lock of fur with a rounded tip that curls to the right.
struct GoobyTuftShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + h))
        path.addCurve(to: CGPoint(x: x + w * 0.72, y: y), control1: CGPoint(x: x, y: y + h * 0.4), control2: CGPoint(x: x + w * 0.3, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: y + h), control1: CGPoint(x: x + w * 1.02, y: y), control2: CGPoint(x: x + w, y: y + h * 0.5))
        path.addQuadCurve(to: CGPoint(x: x, y: y + h), control: CGPoint(x: x + w * 0.5, y: y + h * 1.1))
        path.closeSubpath()
        return path
    }
}

/// "^" arch (happy closed eye).
struct GoobyHappyEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height))
        return path
    }
}

/// "‿" curve (sleeping eye, small closed smile).
struct GoobyClosedEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 2 - rect.minY))
        return path
    }
}

/// Rounded, slightly heart-like little nose.
struct GoobyNoseShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + h * 0.32))
        path.addCurve(to: CGPoint(x: x + w, y: y + h * 0.32), control1: CGPoint(x: x + w * 0.08, y: y - h * 0.1), control2: CGPoint(x: x + w * 0.92, y: y - h * 0.1))
        path.addCurve(to: CGPoint(x: x + w * 0.5, y: y + h), control1: CGPoint(x: x + w, y: y + h * 0.66), control2: CGPoint(x: x + w * 0.64, y: y + h))
        path.addCurve(to: CGPoint(x: x, y: y + h * 0.32), control1: CGPoint(x: x + w * 0.36, y: y + h), control2: CGPoint(x: x, y: y + h * 0.66))
        path.closeSubpath()
        return path
    }
}

/// Open smiling mouth: gently curved top, round bottom.
struct GoobyMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x, y: y))
        path.addQuadCurve(to: CGPoint(x: x + w, y: y), control: CGPoint(x: x + w / 2, y: y + h * 0.16))
        path.addCurve(to: CGPoint(x: x + w / 2, y: y + h), control1: CGPoint(x: x + w, y: y + h * 0.6), control2: CGPoint(x: x + w * 0.8, y: y + h))
        path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x + w * 0.2, y: y + h), control2: CGPoint(x: x, y: y + h * 0.6))
        path.closeSubpath()
        return path
    }
}

struct GoobyHeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x + w * 0.5, y: y + h))
        path.addCurve(to: CGPoint(x: x, y: y + h * 0.32), control1: CGPoint(x: x + w * 0.18, y: y + h * 0.78), control2: CGPoint(x: x, y: y + h * 0.55))
        path.addCurve(to: CGPoint(x: x + w * 0.25, y: y), control1: CGPoint(x: x, y: y + h * 0.14), control2: CGPoint(x: x + w * 0.11, y: y))
        path.addCurve(to: CGPoint(x: x + w * 0.5, y: y + h * 0.2), control1: CGPoint(x: x + w * 0.38, y: y), control2: CGPoint(x: x + w * 0.5, y: y + h * 0.1))
        path.addCurve(to: CGPoint(x: x + w * 0.75, y: y), control1: CGPoint(x: x + w * 0.5, y: y + h * 0.1), control2: CGPoint(x: x + w * 0.62, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: y + h * 0.32), control1: CGPoint(x: x + w * 0.89, y: y), control2: CGPoint(x: x + w, y: y + h * 0.14))
        path.addCurve(to: CGPoint(x: x + w * 0.5, y: y + h), control1: CGPoint(x: x + w, y: y + h * 0.55), control2: CGPoint(x: x + w * 0.82, y: y + h * 0.78))
        path.closeSubpath()
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    var points: Int
    /// Inner radius as a fraction of the outer radius.
    var inner: CGFloat = 0.45

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<(points * 2) {
            let angle = (Double(index) * .pi / Double(points)) - .pi / 2
            let length = index.isMultiple(of: 2) ? radius : radius * inner
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * length, y: center.y + CGFloat(sin(angle)) * length)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Layers

/// Soft oval ground shadow; it shrinks while Gooby is in the air.
struct GoobyShadowLayer: View {
    var lift: CGFloat = 0

    var body: some View {
        let scale = max(0.6, 1 + lift / 90)
        Ellipse()
            .fill(EllipticalGradient(colors: [Color(hex: 0x3D3656).opacity(0.22), Color(hex: 0x3D3656).opacity(0)], center: .center, endRadiusFraction: 0.5))
            .frame(width: 200, height: 30)
            .scaleEffect(scale)
            .offset(y: 151)
    }
}

/// Two tall ears, slightly apart, pivoting at their base behind the head.
struct GoobyEarsLayer: View {
    var fur: FurPaint
    var pose: GoobyPose
    var stage: String

    var body: some View {
        let length = 118 * GoobyStageLook.earScale(stage)
        let base: CGFloat = -34
        ZStack {
            GoobyEar(fur: fur, right: false)
                .frame(width: 58, height: length)
                .rotationEffect(.degrees(-(9 + pose.ear + pose.earL)), anchor: .bottom)
                .offset(x: -42, y: base - length / 2)
            GoobyEar(fur: fur, right: true)
                .frame(width: 58, height: length)
                .rotationEffect(.degrees(9 + pose.ear + pose.earR), anchor: .bottom)
                .offset(x: 42, y: base - length / 2)
        }
    }
}

struct GoobyEar: View {
    var fur: FurPaint
    var right: Bool

    var body: some View {
        let shape = GoobyEarShape()
        ZStack {
            GoobyFurPart(shape: shape, fur: fur, center: UnitPoint(x: right ? 0.64 : 0.36, y: 0.2), reach: 0.9)
            // Large pale-pink inner ear.
            shape
                .fill(LinearGradient(stops: [.init(color: fur.innerLight, location: 0), .init(color: fur.innerEar, location: 0.55)], startPoint: .top, endPoint: .bottom))
                .scaleEffect(x: 0.58, y: 0.8, anchor: UnitPoint(x: 0.5, y: 0.6))
        }
    }
}

/// Small chubby body (the garments follow this outline).
struct GoobyBodyLayer: View {
    var fur: FurPaint
    var pose: GoobyPose

    var body: some View {
        ZStack {
            GoobyFurPart(shape: GoobyBlobShape(widest: 0.6), fur: fur, center: UnitPoint(x: 0.42, y: 0.2))
            // Lighter, fluffy tummy.
            Ellipse()
                .fill(EllipticalGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0)], center: .center, endRadiusFraction: 0.5))
                .goobyAt(0, 26, 100, 60)
        }
        .goobyAt(0, 88, 180, 128)
    }
}

/// Soft shadow the round head casts on the body, the paws and the outfit.
struct GoobyNeckShade: View {
    var fur: FurPaint

    var body: some View {
        Ellipse()
            .fill(EllipticalGradient(colors: [fur.shade.opacity(0.9), fur.shade.opacity(0)], center: .center, endRadiusFraction: 0.5))
            .goobyAt(0, 90, 160, 30)
    }
}

/// Little fur tuft on top of the head; drawn behind the head so it grows out of it.
struct GoobyTuftLayer: View {
    var fur: FurPaint

    var body: some View {
        ZStack {
            GoobyFurPart(shape: GoobyTuftShape(), fur: fur, center: UnitPoint(x: 0.35, y: 0.3), reach: 0.9, line: 2)
                .frame(width: 13, height: 18)
                .rotationEffect(.degrees(-24), anchor: .bottom)
                .offset(x: -8, y: -83)
            GoobyFurPart(shape: GoobyTuftShape(), fur: fur, center: UnitPoint(x: 0.35, y: 0.3), reach: 0.9, line: 2)
                .frame(width: 14, height: 22)
                .rotationEffect(.degrees(2), anchor: .bottom)
                .offset(x: 0, y: -85)
            GoobyFurPart(shape: GoobyTuftShape(), fur: fur, center: UnitPoint(x: 0.35, y: 0.3), reach: 0.9, line: 2)
                .frame(width: 12, height: 16)
                .rotationEffect(.degrees(30), anchor: .bottom)
                .offset(x: 8, y: -83)
        }
    }
}

/// Big round head with soft blush cheeks and a plush sheen.
struct GoobyHeadLayer: View {
    var fur: FurPaint
    var pose: GoobyPose
    var cheekScale: CGFloat = 1

    var body: some View {
        let shape = GoobyBunShape()
        ZStack {
            GoobyFurPart(shape: shape, fur: fur, center: UnitPoint(x: 0.4, y: 0.3), reach: 0.82, line: 0)
            ZStack {
                GoobyCheek(fur: fur, blush: pose.blush, scale: cheekScale).offset(x: -70, y: 38)
                GoobyCheek(fur: fur, blush: pose.blush, scale: cheekScale).offset(x: 70, y: 38)
            }
            .frame(width: 206, height: 164)
            .clipShape(shape)
            Ellipse()
                .fill(EllipticalGradient(colors: [Color.white.opacity(0.75), Color.white.opacity(0)], center: .center, endRadiusFraction: 0.5))
                .frame(width: 70, height: 36)
                .rotationEffect(.degrees(-20))
                .offset(x: -45, y: -50)
            shape.stroke(fur.outline, lineWidth: 2.4)
        }
        .goobyAt(0, 6, 206, 164)
    }
}

struct GoobyFaceLayer: View {
    var pose: GoobyPose
    var fur: FurPaint

    var body: some View {
        let gazeX = pose.lookX * 4
        let gazeY = pose.lookY * 4
        ZStack {
            GoobyEye(pose: pose).offset(x: -46 + gazeX, y: 16 + gazeY)
            GoobyEye(pose: pose).offset(x: 46 + gazeX, y: 16 + gazeY)
            nose
                .scaleEffect(x: 1 + 0.12 * abs(pose.nose), y: 1 - 0.1 * abs(pose.nose))
                .offset(x: gazeX * 0.5, y: 36 - pose.nose * 1.2)
            mouth.offset(x: gazeX * 0.5)
        }
    }

    private var nose: some View {
        ZStack {
            GoobyNoseShape()
                .fill(LinearGradient(colors: [Color(hex: 0xF6A2AE), Color(hex: 0xE07484)], startPoint: .top, endPoint: .bottom))
            Ellipse()
                .fill(Color.white.opacity(0.8))
                .frame(width: 5, height: 3)
                .offset(x: -2, y: -2.5)
        }
        .frame(width: 15, height: 10)
    }

    @ViewBuilder private var mouth: some View {
        let ink = Color(hex: 0x8E3546)
        switch pose.mouth {
        case .smile:
            openMouth(width: 26, height: 17, ink: ink).offset(y: 52.5)
        case .laugh:
            openMouth(width: 34, height: 23, ink: ink).offset(y: 55.5)
        case .round:
            ZStack {
                Ellipse().fill(ink)
                Ellipse().fill(Color(hex: 0xF4838F)).frame(width: 9, height: 6).offset(y: 4)
            }
            .clipShape(Ellipse())
            .frame(width: 14, height: 16)
            .offset(y: 53)
        case .sleepy:
            GoobyClosedEyeShape()
                .stroke(ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 14, height: 5)
                .offset(y: 48)
        case .flat:
            GoobyClosedEyeShape()
                .stroke(ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 13, height: 4)
                .rotationEffect(.degrees(-8))
                .offset(x: 4, y: 48)
        }
    }

    private func openMouth(width: CGFloat, height: CGFloat, ink: Color) -> some View {
        ZStack {
            GoobyMouthShape().fill(ink)
            Ellipse()
                .fill(Color(hex: 0xF4838F))
                .frame(width: width * 0.68, height: height * 0.8)
                .offset(y: height * 0.35)
        }
        .clipShape(GoobyMouthShape())
        .frame(width: width, height: height)
    }
}

/// Big soft-edged pink blush.
struct GoobyCheek: View {
    var fur: FurPaint
    var blush: CGFloat
    var scale: CGFloat

    var body: some View {
        let size = scale * (0.92 + 0.08 * blush)
        let strength = min(1, 0.85 * blush)
        Ellipse()
            .fill(EllipticalGradient(
                stops: [
                    .init(color: fur.cheek.opacity(strength), location: 0),
                    .init(color: fur.cheek.opacity(strength * 0.62), location: 0.5),
                    .init(color: fur.cheek.opacity(0), location: 1)
                ],
                center: .center,
                endRadiusFraction: 0.5
            ))
            .frame(width: 60 * size, height: 36 * size)
    }
}

/// Huge glossy dark eye: a big catchlight upper left, a small one lower right and a warm glow
/// at the bottom.
struct GoobyEye: View {
    var pose: GoobyPose

    private var ink: Color { Color(hex: 0x2B1D1B) }

    var body: some View {
        switch pose.eyes {
        case .happy:
            GoobyHappyEyeShape()
                .stroke(ink, style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
                .frame(width: 34, height: 14)
                .offset(y: 1)
        case .closed:
            closed
        case .open:
            if pose.blink < 0.25 { closed } else { open }
        }
    }

    private var closed: some View {
        GoobyClosedEyeShape()
            .stroke(ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
            .frame(width: 32, height: 10)
            .offset(y: 6)
    }

    private var open: some View {
        let grow = 1 + pose.surprise * 0.12
        let shift = pose.lookX * 3
        return ZStack {
            Ellipse()
                .fill(EllipticalGradient(
                    stops: [.init(color: Color(hex: 0x6A4639), location: 0), .init(color: ink, location: 0.62)],
                    center: UnitPoint(x: 0.5, y: 0.92),
                    endRadiusFraction: 0.85
                ))
            Circle()
                .fill(Color.white)
                .frame(width: 19, height: 19)
                .offset(x: -8 + shift, y: -12)
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 8.4, height: 8.4)
                .offset(x: 10 + shift, y: 10)
        }
        .frame(width: 46 * grow, height: 52 * grow)
        .scaleEffect(x: 1, y: pose.blink, anchor: UnitPoint(x: 0.5, y: 0.62))
    }
}

/// Short stubby arms. Each arm hangs from its shoulder; at rest the paws meet under the chin.
struct GoobyPawsLayer: View {
    var fur: FurPaint
    var pose: GoobyPose

    var body: some View {
        ZStack {
            arm.modifier(GoobyArmPlacement(left: true, pose: pose))
            arm.modifier(GoobyArmPlacement(left: false, pose: pose))
        }
    }

    private var arm: some View {
        GoobyFurPart(shape: Capsule(), fur: fur, center: UnitPoint(x: 0.4, y: 0.3), line: 2.2)
    }
}

/// Shoulder pivot and swing of one arm (fur arm and sleeve share it).
struct GoobyArmPlacement: ViewModifier {
    var left: Bool
    var pose: GoobyPose
    var width: CGFloat = 30

    func body(content: Content) -> some View {
        let sign: CGFloat = left ? -1 : 1
        let raise = left ? pose.raiseL : pose.raiseR
        let angle = sign * (50 + pose.arm * 22 - raise * 176)
        content
            .frame(width: width, height: 46)
            .rotationEffect(.degrees(angle), anchor: .top)
            .offset(x: sign * (70 - pose.arm * 14), y: 76 + 23)
    }
}

struct GoobyFeetLayer: View {
    var fur: FurPaint
    var pose: GoobyPose

    var body: some View {
        let spread = 46 + pose.sit * 4
        let y = 138 + pose.sit * 3
        ZStack {
            foot.offset(x: -spread, y: y)
            foot.offset(x: spread, y: y)
        }
    }

    private var foot: some View {
        ZStack {
            GoobyFurPart(shape: Ellipse(), fur: fur, center: UnitPoint(x: 0.4, y: 0.25))
            Ellipse()
                .fill(fur.innerEar)
                .frame(width: 24, height: 15)
                .offset(y: 4.5)
            HStack(spacing: 2.8) {
                Circle().fill(fur.innerEar).frame(width: 7.2, height: 7.2)
                Circle().fill(fur.innerEar).frame(width: 7.2, height: 7.2).offset(y: -2)
                Circle().fill(fur.innerEar).frame(width: 7.2, height: 7.2)
            }
            .offset(y: -8)
        }
        .frame(width: 62, height: 34)
    }
}

// MARK: - Effects

struct GoobyEffectsLayer: View {
    var pose: GoobyPose

    var body: some View {
        ZStack {
            if pose.hearts { HeartsLayer(time: pose.time) }
            if pose.sparkles { GoobySparkleLayer(time: pose.time) }
            if pose.zzz { SleepMarks(time: pose.time) }
            if pose.thought { GoobyThoughtBubble() }
        }
    }
}

/// Hearts floating up beside the head.
struct HeartsLayer: View {
    var time: Double = 0

    private static let spots: [CGPoint] = [CGPoint(x: -118, y: -50), CGPoint(x: 112, y: -72), CGPoint(x: 84, y: -118)]

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let progress = (time * 0.45 + (Double(index) + 0.5) / 3).truncatingRemainder(dividingBy: 1)
                let spot = HeartsLayer.spots[index]
                heart
                    .frame(width: 26, height: 23)
                    .scaleEffect(0.75 + 0.35 * CGFloat(sin(progress * .pi)))
                    .opacity(sin(progress * .pi))
                    .offset(x: spot.x + CGFloat(sin(progress * 6 + Double(index))) * 5, y: spot.y + 20 - CGFloat(progress) * 40)
            }
        }
    }

    private var heart: some View {
        ZStack {
            GoobyHeartShape()
                .fill(LinearGradient(colors: [Color(hex: 0xFFA3C4), Color(hex: 0xFF6F9F)], startPoint: .top, endPoint: .bottom))
            GoobyHeartShape().stroke(Color.white.opacity(0.9), lineWidth: 2)
            Ellipse()
                .fill(Color.white.opacity(0.75))
                .frame(width: 7, height: 4)
                .rotationEffect(.degrees(-30))
                .offset(x: -6, y: -5)
        }
    }
}

/// Twinkling four-point sparkles around Gooby.
struct GoobySparkleLayer: View {
    var time: Double = 0

    private static let spots: [(CGPoint, CGFloat)] = [
        (CGPoint(x: -128, y: -24), 22), (CGPoint(x: 124, y: -36), 18), (CGPoint(x: -96, y: -128), 16),
        (CGPoint(x: 124, y: 56), 20), (CGPoint(x: -128, y: 76), 16)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<GoobySparkleLayer.spots.count, id: \.self) { index in
                let spot = GoobySparkleLayer.spots[index]
                let twinkle = 0.55 + 0.45 * abs(sin(time * 3 + Double(index) * 1.3))
                ZStack {
                    Star(points: 4, inner: 0.38).fill(index.isMultiple(of: 2) ? Color(hex: 0xFFD34E) : Color(hex: 0xFFB3CF))
                    Star(points: 4, inner: 0.38).fill(Color.white).scaleEffect(0.42)
                }
                .frame(width: spot.1, height: spot.1)
                .scaleEffect(CGFloat(twinkle))
                .rotationEffect(.degrees(time * 30 + Double(index) * 20))
                .offset(x: spot.0.x, y: spot.0.y)
            }
        }
    }
}

/// Little "z z z" drifting up while Gooby sleeps.
struct SleepMarks: View {
    var time: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let progress = (time * 0.35 + Double(index) / 3).truncatingRemainder(dividingBy: 1)
                let size = CGFloat(18 + index * 6)
                Text(verbatim: "z")
                    .font(.system(size: size, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x8E84D8))
                    .shadow(color: Color.white.opacity(0.9), radius: 0, x: 1.5, y: 1.5)
                    .opacity(time == 0 ? 1 : sin(progress * .pi))
                    .offset(x: 84 + CGFloat(index) * 22 + CGFloat(progress) * 10, y: -70 - CGFloat(index) * 22 - CGFloat(progress) * 16)
            }
        }
    }
}

/// Thought bubble with a question mark (thinking).
struct GoobyThoughtBubble: View {
    var body: some View {
        let line = Color(hex: 0xC9C2E8)
        ZStack {
            Circle().fill(Color.white).overlay(Circle().stroke(line, lineWidth: 2)).goobyAt(88, -70, 10, 10)
            Circle().fill(Color.white).overlay(Circle().stroke(line, lineWidth: 2)).goobyAt(102, -90, 16, 16)
            Capsule().fill(Color.white).overlay(Capsule().stroke(line, lineWidth: 2.5)).goobyAt(124, -122, 58, 42)
            Text(verbatim: "?")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x8E84D8))
                .offset(x: 124, y: -122)
        }
    }
}

/// Gift box in front of Gooby; the lid pops open as `lid` goes to 1.
struct GoobyGiftLayer: View {
    var lid: CGFloat

    var body: some View {
        let box = Color(hex: 0xFF8FB3)
        let ribbon = Color(hex: 0xFFD45E)
        ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(box)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.25), Color.black.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Rectangle().fill(ribbon).frame(width: 16)
                RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color(hex: 0xE0628E), lineWidth: 2.5)
            }
            .goobyAt(0, 128, 92, 56)
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color(hex: 0xFF7AA5))
                Rectangle().fill(ribbon).frame(width: 16)
                RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color(hex: 0xE0628E), lineWidth: 2.5)
                HStack(spacing: 2) {
                    Ellipse().fill(ribbon).frame(width: 20, height: 14).rotationEffect(.degrees(-20))
                    Ellipse().fill(ribbon).frame(width: 20, height: 14).rotationEffect(.degrees(20))
                }
                .offset(y: -16)
            }
            .frame(width: 102, height: 22)
            .rotationEffect(.degrees(Double(-lid * 18)))
            .offset(x: -lid * 8, y: 98 - lid * 34)
        }
    }
}
