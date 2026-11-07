import SwiftUI

// Gooby, the plush baby bunny (masterprompt 1.1-1.3, 12, 14).
//
// The rig is drawn in a 320 x 320 design box with the origin in its center (y grows down) and
// scaled to the space it gets. Layers back to front: backpack, ears, body, garments, feet, arms,
// sleeves, straps, head, face, head and neck wear, effects. Every fur part uses a soft elliptical
// gradient (light top-left, shade bottom-right), a faint inner rim highlight and a warm outline.

enum GoobyAnimation: String, CaseIterable, Identifiable {
    case idle, breathe, blink, ears, wiggle, hop, laugh, clap
    case surprised, think, sit, sleep, wake, petting, hearts, dance
    case play, unwrap, present, depart, arrive, celebrate

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
    /// Small open smile.
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
    /// Outward lean added to both ears.
    var ear: CGFloat = 0
    var earL: CGFloat = 0
    var earR: CGFloat = 0
    /// Negative = up.
    var hop: CGFloat = 0
    var tilt: CGFloat = 0
    /// < 1 squashes (wider, lower), > 1 stretches.
    var squash: CGFloat = 1
    /// 0 = arms resting, 1 = paws together (clap).
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

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let pose = GoobyPose.make(animation: animation, time: timeline.date.timeIntervalSinceReferenceDate, reduce: reduceMotion)
            GoobyRig(look: look, stage: stage, pose: pose, companion: showCompanion ? companion : nil, adventuring: adventuring)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gooby")
    }
}

/// Head-and-ears crop of Gooby in a still idle pose (tab icon, progress tracks, small badges).
struct GoobyAvatar: View {
    var look: WornLook
    var stage: String
    var size: CGFloat

    var body: some View {
        // Shows the design band from the ear tips (-130) to the chin (+94).
        let full = size * 320 / 224
        GoobyRig(look: look, stage: stage, pose: GoobyPose.make(animation: .idle, time: 0, reduce: true), companion: nil)
            .frame(width: full, height: full)
            .offset(y: full * 18 / 320)
            .frame(width: size, height: size)
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Gooby")
    }
}

// MARK: - Poses

extension GoobyPose {
    static func make(animation: GoobyAnimation, time: Double, reduce: Bool) -> GoobyPose {
        var pose = GoobyPose()
        pose.express(animation)
        if reduce {
            pose.freeze(animation)
            return pose
        }
        pose.time = time
        pose.animate(animation, time: time)
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
            blush = 1.25
        case .clap:
            eyes = .happy
            mouth = .laugh
            sparkles = true
        case .surprised:
            surprise = 1
            mouth = .round
            ear = -5
        case .think:
            mouth = .flat
            thought = true
            lookX = -0.5
            lookY = -0.7
            earR = 24
        case .sit:
            sit = 1
        case .sleep:
            sleep = true
            zzz = true
            eyes = .closed
            mouth = .sleepy
            sit = 0.6
            ear = 20
        case .petting:
            eyes = .happy
            blush = 1.45
            hearts = true
            squash = 0.94
        case .hearts:
            eyes = .happy
            hearts = true
            blush = 1.2
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
            raiseL = 0.55
            raiseR = 0.55
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
        case .idle, .breathe, .blink, .ears, .wiggle, .wake:
            break
        }
    }

    /// Reduced motion: one gentle still frame that still reads as the animation.
    private mutating func freeze(_ animation: GoobyAnimation) {
        switch animation {
        case .clap: arm = 1
        case .dance: raiseL = 0.8
        case .wiggle: tilt = 3
        default: break
        }
    }

    private mutating func animate(_ animation: GoobyAnimation, time t: Double) {
        let wave = CGFloat(sin(t * 1.6))
        breath = 1 + 0.018 * wave
        ear += wave * 3
        if eyes == .open {
            blink = GoobyPose.blink(at: t, period: animation == .blink ? 1.7 : 4.4)
        }
        switch animation {
        case .idle, .blink:
            earR += GoobyPose.twitch(at: t, period: 6.5) * 12
        case .breathe:
            breath = 1 + 0.035 * CGFloat(sin(t * 1.1))
        case .ears:
            earL = CGFloat(sin(t * 3)) * 13
            earR = CGFloat(sin(t * 3 + .pi)) * 13
        case .wiggle:
            tilt = CGFloat(sin(t * 6)) * 6
            squash = 1 + 0.025 * CGFloat(sin(t * 12))
        case .hop, .celebrate:
            let phase = (t * 1.5).truncatingRemainder(dividingBy: 1)
            let lift = CGFloat(sin(phase * .pi))
            hop = -26 * lift
            squash = lift < 0.2 ? 0.95 + lift * 0.1 : 1.02
            ear -= lift * 8
            if animation == .celebrate {
                raiseL = 0.85 + 0.15 * lift
                raiseR = raiseL
            }
        case .laugh:
            let shake = CGFloat(sin(t * 9))
            tilt = shake * 3
            hop = -abs(shake) * 3
            squash = 1 - 0.03 * abs(shake)
        case .clap:
            arm = (CGFloat(sin(t * 7)) + 1) / 2
            hop = -abs(CGFloat(sin(t * 3.5))) * 4
        case .surprised:
            let phase = t.truncatingRemainder(dividingBy: 2.6)
            hop = phase < 0.35 ? -14 * CGFloat(sin(phase / 0.35 * .pi)) : 0
            ear = -6
        case .think:
            tilt = -6 + CGFloat(sin(t * 1.2)) * 2
        case .sit:
            breath = 1 + 0.014 * CGFloat(sin(t * 1.2))
        case .sleep:
            breath = 1 + 0.03 * CGFloat(sin(t * 0.8))
            ear = 20 + CGFloat(sin(t * 0.8)) * 2
        case .wake:
            let phase = t.truncatingRemainder(dividingBy: 3.2)
            if phase < 1.0 {
                eyes = .closed
                mouth = .sleepy
            } else if phase < 2.0 {
                let stretch = CGFloat(sin((phase - 1.0) * .pi))
                raiseL = stretch
                raiseR = stretch
                breath = 1 + 0.04 * stretch
                eyes = .closed
                mouth = .round
            } else {
                blink = GoobyPose.blink(at: t, period: 0.6)
                hop = -abs(CGFloat(sin((phase - 2.0) * .pi * 2))) * 5
            }
        case .petting:
            squash = 0.93 + 0.02 * CGFloat(sin(t * 4))
            tilt = 4 + CGFloat(sin(t * 2)) * 3
        case .hearts:
            hop = -abs(CGFloat(sin(t * 2.5))) * 8
        case .dance:
            let beat = CGFloat(sin(t * 4))
            tilt = beat * 10
            hop = -abs(beat) * 14
            raiseL = max(0, beat)
            raiseR = max(0, -beat)
        case .play:
            tilt = CGFloat(sin(t * 3)) * 6
            hop = -abs(CGFloat(sin(t * 3))) * 10
            friendHop = -abs(CGFloat(sin(t * 3 + 1.2))) * 16
        case .unwrap:
            let phase = t.truncatingRemainder(dividingBy: 3.2)
            let lid = CGFloat(min(1, max(0, (phase - 0.9) / 0.5)))
            gift = lid
            if lid < 0.5 {
                arm = 0.6
                mouth = .smile
                sparkles = false
            } else {
                surprise = lid
                hop = -6 * lid
            }
        case .present:
            let sway = CGFloat(sin(t * 2))
            tilt = sway * 6
            raiseL = 0.5 + 0.15 * sway
            raiseR = 0.5 - 0.15 * sway
            hop = -2
        case .depart:
            let phase = t.truncatingRemainder(dividingBy: 2.4)
            depart = CGFloat(min(1, phase / 1.6))
            hop = -abs(CGFloat(sin(t * 9))) * 10
        case .arrive:
            let phase = t.truncatingRemainder(dividingBy: 2.4)
            depart = CGFloat(max(0, 1 - phase / 1.2))
            hop = depart > 0 ? -abs(CGFloat(sin(t * 9))) * 10 : 0
        }
    }

    /// 1 most of the time, dips to ~0 for a short blink at the end of every period.
    static func blink(at t: Double, period: Double) -> CGFloat {
        let window = min(0.28, period * 0.4)
        let cycle = t.truncatingRemainder(dividingBy: period)
        guard cycle > period - window else { return 1 }
        let local = (cycle - (period - window)) / window
        return max(0.05, CGFloat(abs(local * 2 - 1)))
    }

    /// A quick flick (-1...1) at the start of every period, 0 otherwise.
    static func twitch(at t: Double, period: Double) -> CGFloat {
        let cycle = t.truncatingRemainder(dividingBy: period)
        guard cycle < 0.45 else { return 0 }
        return CGFloat(sin(cycle / 0.45 * .pi * 2))
    }
}

// MARK: - Rig

/// Subtle growth stages: ear length and cheek size change, the round shape never does.
enum GoobyStageLook {
    static func earScale(_ stage: String) -> CGFloat {
        switch stage {
        case "baby": return 0.9
        case "little": return 0.95
        case "young": return 1.0
        case "teen": return 1.05
        default: return 1.1
        }
    }

    static func cheekScale(_ stage: String) -> CGFloat {
        switch stage {
        case "baby": return 1.12
        case "little": return 1.06
        case "young": return 1.0
        case "teen": return 0.96
        default: return 0.92
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
    /// Soft warm outline.
    var outline: Color

    static func resolve(_ id: String) -> FurPaint {
        switch id {
        case "fur-peach":
            return FurPaint(body: Color(hex: 0xFFE1C8), shade: Color(hex: 0xF0BE9C), cheek: Color(hex: 0xFFA3BA), innerEar: Color(hex: 0xFFB0C4), light: Color(hex: 0xFFF4EA), outline: Color(hex: 0xD9A27F))
        case "fur-lilac":
            return FurPaint(body: Color(hex: 0xF1E8FF), shade: Color(hex: 0xD9CBF2), cheek: Color(hex: 0xF5AECD), innerEar: Color(hex: 0xF6BBD8), light: Color(hex: 0xFDFBFF), outline: Color(hex: 0xB9A6DD))
        case "fur-mint":
            return FurPaint(body: Color(hex: 0xEEFBF2), shade: Color(hex: 0xCDEBD9), cheek: Color(hex: 0xFFB3C8), innerEar: Color(hex: 0xFFBDD0), light: Color(hex: 0xFBFFFC), outline: Color(hex: 0xA8D2B9))
        case "fur-honey":
            return FurPaint(body: Color(hex: 0xFFEFCF), shade: Color(hex: 0xF0CF95), cheek: Color(hex: 0xFFAFBF), innerEar: Color(hex: 0xFFBACB), light: Color(hex: 0xFFFAEC), outline: Color(hex: 0xD8AE6C))
        case "fur-sky":
            return FurPaint(body: Color(hex: 0xEEF7FF), shade: Color(hex: 0xCFE3F4), cheek: Color(hex: 0xFFB5CB), innerEar: Color(hex: 0xFFBED3), light: Color(hex: 0xFBFDFF), outline: Color(hex: 0xA9C6DE))
        default:
            return FurPaint(body: Color(hex: 0xFFF3E2), shade: Color(hex: 0xF2D5BC), cheek: Color(hex: 0xFFA9C0), innerEar: Color(hex: 0xFFB9CC), light: Color(hex: 0xFFFDF8), outline: Color(hex: 0xDDB797))
        }
    }

    /// Soft plush shading for one fur part: light where the light falls, shade at the far edge.
    func gradient(center: UnitPoint = UnitPoint(x: 0.38, y: 0.3), reach: CGFloat = 0.8) -> EllipticalGradient {
        EllipticalGradient(
            stops: [
                .init(color: light, location: 0),
                .init(color: body, location: 0.42),
                .init(color: shade, location: 1)
            ],
            center: center,
            startRadiusFraction: 0,
            endRadiusFraction: reach
        )
    }
}

/// One fur part: plush gradient, darker far edge, faint inner rim light, warm outline.
struct GoobyFurPart<S: Shape>: View {
    var shape: S
    var fur: FurPaint
    var center: UnitPoint = UnitPoint(x: 0.38, y: 0.3)
    var line: CGFloat = 2.6
    var rim: Bool = true

    var body: some View {
        ZStack {
            shape.fill(fur.gradient(center: center))
            shape.fill(EllipticalGradient(
                stops: [.init(color: .clear, location: 0.6), .init(color: fur.shade.opacity(0.55), location: 1)],
                center: UnitPoint(x: center.x + 0.06, y: center.y + 0.05),
                endRadiusFraction: 0.76
            ))
            if rim {
                shape
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0)], startPoint: .topLeading, endPoint: UnitPoint(x: 0.55, y: 0.6)), lineWidth: 6)
                    .clipShape(shape)
            }
            shape.stroke(fur.outline, lineWidth: line)
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

/// Long bunny ear: round tip, fullest at 40 % of its height, narrower base.
struct GoobyEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x + w * 0.5, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: y + h * 0.4), control1: CGPoint(x: x + w * 0.84, y: y), control2: CGPoint(x: x + w, y: y + h * 0.17))
        path.addCurve(to: CGPoint(x: x + w * 0.7, y: y + h), control1: CGPoint(x: x + w, y: y + h * 0.66), control2: CGPoint(x: x + w * 0.82, y: y + h * 0.86))
        path.addLine(to: CGPoint(x: x + w * 0.3, y: y + h))
        path.addCurve(to: CGPoint(x: x, y: y + h * 0.4), control1: CGPoint(x: x + w * 0.18, y: y + h * 0.86), control2: CGPoint(x: x, y: y + h * 0.66))
        path.addCurve(to: CGPoint(x: x + w * 0.5, y: y), control1: CGPoint(x: x, y: y + h * 0.17), control2: CGPoint(x: x + w * 0.16, y: y))
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

/// Shine along the lower lid of a glossy eye.
struct GoobyLidShineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.8))
        path.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.8), control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.99))
        return path
    }
}

/// Rounded, slightly heart-like little nose.
struct GoobyNoseShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + h * 0.3))
        path.addCurve(to: CGPoint(x: x + w, y: y + h * 0.3), control1: CGPoint(x: x + w * 0.1, y: y - h * 0.12), control2: CGPoint(x: x + w * 0.9, y: y - h * 0.12))
        path.addCurve(to: CGPoint(x: x + w * 0.5, y: y + h), control1: CGPoint(x: x + w, y: y + h * 0.62), control2: CGPoint(x: x + w * 0.66, y: y + h))
        path.addCurve(to: CGPoint(x: x, y: y + h * 0.3), control1: CGPoint(x: x + w * 0.34, y: y + h), control2: CGPoint(x: x, y: y + h * 0.62))
        path.closeSubpath()
        return path
    }
}

/// Open smiling mouth: flat top, round bottom.
struct GoobyMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x, y: y))
        path.addQuadCurve(to: CGPoint(x: x + w, y: y), control: CGPoint(x: x + w / 2, y: y + h * 0.12))
        path.addCurve(to: CGPoint(x: x + w / 2, y: y + h), control1: CGPoint(x: x + w, y: y + h * 0.62), control2: CGPoint(x: x + w * 0.78, y: y + h))
        path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x + w * 0.22, y: y + h), control2: CGPoint(x: x, y: y + h * 0.62))
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
            .frame(width: 196, height: 32)
            .scaleEffect(scale)
            .offset(y: 150)
    }
}

struct GoobyEarsLayer: View {
    var fur: FurPaint
    var pose: GoobyPose
    var stage: String

    var body: some View {
        let length = 124 * GoobyStageLook.earScale(stage)
        let base: CGFloat = -34
        ZStack {
            GoobyEar(fur: fur, right: false)
                .frame(width: 60, height: length)
                .rotationEffect(.degrees(-(10 + pose.ear + pose.earL)), anchor: .bottom)
                .offset(x: -44, y: base - length / 2)
            GoobyEar(fur: fur, right: true)
                .frame(width: 60, height: length)
                .rotationEffect(.degrees(10 + pose.ear + pose.earR), anchor: .bottom)
                .offset(x: 44, y: base - length / 2)
        }
    }
}

struct GoobyEar: View {
    var fur: FurPaint
    var right: Bool

    var body: some View {
        let shape = GoobyEarShape()
        ZStack {
            GoobyFurPart(shape: shape, fur: fur, center: UnitPoint(x: right ? 0.62 : 0.36, y: 0.22), line: 2.4, rim: false)
            // Soft, slightly warmer tip.
            shape.fill(LinearGradient(stops: [.init(color: fur.shade.opacity(0.5), location: 0), .init(color: fur.shade.opacity(0), location: 0.2)], startPoint: .top, endPoint: .bottom))
            shape
                .fill(LinearGradient(colors: [fur.innerEar, fur.innerEar.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .overlay(shape.stroke(fur.innerEar.opacity(0.9), lineWidth: 2))
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: 5, height: 30)
                        .offset(x: right ? 4 : -4, y: 14)
                }
                .scaleEffect(x: 0.56, y: 0.72, anchor: UnitPoint(x: 0.5, y: 0.86))
            shape.stroke(fur.outline, lineWidth: 2.4)
        }
    }
}

struct GoobyBodyLayer: View {
    var fur: FurPaint
    var pose: GoobyPose

    var body: some View {
        ZStack {
            GoobyFurPart(shape: GoobyBlobShape(widest: 0.6), fur: fur, center: UnitPoint(x: 0.4, y: 0.22))
            // Lighter, fluffy belly.
            Ellipse()
                .fill(EllipticalGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0)], center: .center, endRadiusFraction: 0.5))
                .goobyAt(0, 30, 112, 64)
        }
        .goobyAt(0, 88, 180, 128)
    }
}

/// Soft shadow the round head casts on the body and the outfit.
struct GoobyNeckShade: View {
    var fur: FurPaint

    var body: some View {
        Ellipse()
            .fill(EllipticalGradient(colors: [fur.shade.opacity(0.85), fur.shade.opacity(0)], center: .center, endRadiusFraction: 0.5))
            .goobyAt(0, 90, 156, 34)
    }
}

struct GoobyHeadLayer: View {
    var fur: FurPaint
    var pose: GoobyPose
    var cheekScale: CGFloat = 1

    var body: some View {
        ZStack {
            ZStack {
                GoobyFurPart(shape: GoobyBlobShape(widest: 0.56), fur: fur, line: 2.6)
                // Fluffy pink cheeks, kept inside the head outline.
                ZStack {
                    GoobyCheek(fur: fur, blush: pose.blush, scale: cheekScale).offset(x: -64, y: 38)
                    GoobyCheek(fur: fur, blush: pose.blush, scale: cheekScale).offset(x: 64, y: 38)
                }
                .frame(width: 192, height: 166)
                .clipShape(GoobyBlobShape(widest: 0.56))
                // Glossy plush sheen.
                Ellipse()
                    .fill(EllipticalGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0)], center: .center, endRadiusFraction: 0.5))
                    .frame(width: 74, height: 40)
                    .rotationEffect(.degrees(-22))
                    .offset(x: -44, y: -46)
            }
            .goobyAt(0, 4, 192, 166)
            // Little fur tuft on top.
            GoobyFurPart(shape: GoobyEarShape(), fur: fur, line: 2, rim: false)
                .frame(width: 13, height: 24)
                .rotationEffect(.degrees(-26))
                .offset(x: -6, y: -82)
            GoobyFurPart(shape: GoobyEarShape(), fur: fur, line: 2, rim: false)
                .frame(width: 11, height: 20)
                .rotationEffect(.degrees(20))
                .offset(x: 6, y: -82)
        }
    }
}

struct GoobyFaceLayer: View {
    var pose: GoobyPose
    var fur: FurPaint

    var body: some View {
        let gazeX = pose.lookX * 4
        let gazeY = pose.lookY * 4
        ZStack {
            GoobyEye(pose: pose).offset(x: -40 + gazeX, y: 10 + gazeY)
            GoobyEye(pose: pose).offset(x: 40 + gazeX, y: 10 + gazeY)
            nose.offset(x: gazeX * 0.5, y: 31)
            mouth.offset(x: gazeX * 0.5, y: 44)
        }
    }

    private var nose: some View {
        ZStack {
            GoobyNoseShape()
                .fill(LinearGradient(colors: [Color(hex: 0xFFA6BF), Color(hex: 0xF07C9C)], startPoint: .top, endPoint: .bottom))
            Ellipse()
                .fill(Color.white.opacity(0.8))
                .frame(width: 5, height: 3)
                .offset(x: -3, y: -2)
        }
        .frame(width: 17, height: 12)
    }

    @ViewBuilder private var mouth: some View {
        let ink = Color(hex: 0x8C3B52)
        switch pose.mouth {
        case .smile:
            openMouth(width: 20, height: 13, ink: ink)
        case .laugh:
            openMouth(width: 30, height: 20, ink: ink).offset(y: 2)
        case .round:
            ZStack {
                Ellipse().fill(ink)
                Ellipse().fill(Color(hex: 0xFF8FA8)).frame(width: 9, height: 6).offset(y: 3.5)
            }
            .clipShape(Ellipse())
            .frame(width: 13, height: 15)
            .offset(y: 3)
        case .sleepy:
            GoobyClosedEyeShape()
                .stroke(ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 14, height: 4)
        case .flat:
            GoobyClosedEyeShape()
                .stroke(ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 12, height: 3)
                .rotationEffect(.degrees(-8))
                .offset(x: 4)
        }
    }

    private func openMouth(width: CGFloat, height: CGFloat, ink: Color) -> some View {
        ZStack {
            GoobyMouthShape().fill(ink)
            Ellipse()
                .fill(Color(hex: 0xFF8FA8))
                .frame(width: width * 0.6, height: height * 0.55)
                .offset(y: height * 0.3)
        }
        .clipShape(GoobyMouthShape())
        .frame(width: width, height: height)
    }
}

/// Soft radial pink blush with a tiny light dot.
struct GoobyCheek: View {
    var fur: FurPaint
    var blush: CGFloat
    var scale: CGFloat

    var body: some View {
        let size = scale * (0.92 + 0.08 * blush)
        let strength = min(1, 0.8 * blush)
        ZStack {
            Ellipse()
                .fill(EllipticalGradient(
                    stops: [
                        .init(color: fur.cheek.opacity(strength), location: 0),
                        .init(color: fur.cheek.opacity(strength * 0.6), location: 0.55),
                        .init(color: fur.cheek.opacity(0), location: 1)
                    ],
                    center: .center,
                    endRadiusFraction: 0.5
                ))
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: 8, height: 4)
                .offset(x: -8, y: -6)
        }
        .frame(width: 56 * size, height: 38 * size)
    }
}

/// Huge glossy black eye: one big and one small highlight, a soft shine on the lower lid.
struct GoobyEye: View {
    var pose: GoobyPose

    private var ink: Color { Color(hex: 0x2A2130) }

    var body: some View {
        switch pose.eyes {
        case .happy:
            GoobyHappyEyeShape()
                .stroke(ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 30, height: 13)
                .offset(y: 2)
        case .closed:
            closed
        case .open:
            if pose.blink < 0.3 { closed } else { open }
        }
    }

    private var closed: some View {
        GoobyClosedEyeShape()
            .stroke(ink, style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
            .frame(width: 30, height: 9)
            .offset(y: 8)
    }

    private var open: some View {
        let grow = 1 + pose.surprise * 0.12
        let shift = pose.lookX * 3
        return ZStack {
            Ellipse()
                .fill(EllipticalGradient(
                    stops: [.init(color: Color(hex: 0x54425F), location: 0), .init(color: Color(hex: 0x1C1621), location: 0.8)],
                    center: UnitPoint(x: 0.5, y: 0.88),
                    endRadiusFraction: 0.9
                ))
            GoobyLidShineShape()
                .stroke(Color(hex: 0xA48EB8).opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            Circle()
                .fill(Color.white)
                .frame(width: 17, height: 17)
                .offset(x: -8 + shift, y: -11)
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 7, height: 7)
                .offset(x: 9 + shift, y: 7)
        }
        .frame(width: 44 * grow, height: 50 * grow)
        .scaleEffect(x: 1, y: pose.blink)
    }
}

/// Short stubby arms. Each arm hangs from its shoulder and swings there.
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
        ZStack {
            GoobyFurPart(shape: Capsule(), fur: fur, center: UnitPoint(x: 0.4, y: 0.2), line: 2.4, rim: false)
            Ellipse()
                .fill(fur.innerEar.opacity(0.55))
                .frame(width: 12, height: 8)
                .offset(y: 15)
        }
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
        let angle = sign * (18 + pose.arm * 44 - raise * 150)
        content
            .frame(width: width, height: 46)
            .rotationEffect(.degrees(angle), anchor: .top)
            .offset(x: sign * (78 - pose.arm * 18), y: 84 + 23)
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
            GoobyFurPart(shape: Ellipse(), fur: fur, center: UnitPoint(x: 0.4, y: 0.25), line: 2.4, rim: false)
            Ellipse()
                .fill(fur.innerEar)
                .frame(width: 24, height: 13)
                .offset(y: 4)
            HStack(spacing: 2.5) {
                Circle().fill(fur.innerEar).frame(width: 7, height: 7)
                Circle().fill(fur.innerEar).frame(width: 7, height: 7).offset(y: -2)
                Circle().fill(fur.innerEar).frame(width: 7, height: 7)
            }
            .offset(y: -7)
        }
        .frame(width: 62, height: 32)
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

    private static let spots: [CGPoint] = [CGPoint(x: -108, y: -60), CGPoint(x: 104, y: -80), CGPoint(x: 70, y: -120)]

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
        (CGPoint(x: -122, y: -24), 22), (CGPoint(x: 116, y: -36), 18), (CGPoint(x: -84, y: -128), 16),
        (CGPoint(x: 120, y: 56), 20), (CGPoint(x: -124, y: 76), 16)
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
                    .offset(x: 62 + CGFloat(index) * 24 + CGFloat(progress) * 10, y: -92 - CGFloat(index) * 22 - CGFloat(progress) * 16)
            }
        }
    }
}

/// Thought bubble with a question mark (thinking).
struct GoobyThoughtBubble: View {
    var body: some View {
        let line = Color(hex: 0xC9C2E8)
        ZStack {
            Circle().fill(Color.white).overlay(Circle().stroke(line, lineWidth: 2)).goobyAt(72, -78, 10, 10)
            Circle().fill(Color.white).overlay(Circle().stroke(line, lineWidth: 2)).goobyAt(88, -98, 16, 16)
            Capsule().fill(Color.white).overlay(Capsule().stroke(line, lineWidth: 2.5)).goobyAt(116, -128, 58, 42)
            Text(verbatim: "?")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: 0x8E84D8))
                .offset(x: 116, y: -128)
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
