import SwiftUI

enum GoobyAnimation: String, CaseIterable, Identifiable {
    case idle, breathe, blink, ears, wiggle, hop, laugh, clap
    case surprised, think, sit, sleep, wake, petting, hearts, dance
    case play, unwrap, present, depart, arrive, celebrate
    case wave, read, curious, flower, walk

    var id: String { rawValue }
}

/// The drawn pose families from the character sheets.
enum GoobyStance {
    case stand, wave, read, sit, sleep, curious, flower, back
}

struct GoobyMarks: OptionSet {
    let rawValue: Int
    static let sparkle = GoobyMarks(rawValue: 1)
    static let question = GoobyMarks(rawValue: 2)
    static let alert = GoobyMarks(rawValue: 4)
    static let zzz = GoobyMarks(rawValue: 8)
    static let hearts = GoobyMarks(rawValue: 16)
}

struct WornLook: Equatable {
    var fur: String = "fur-cream"
    var slots: [String: ItemDef] = [:]
}

/// One frame of Gooby. Lengths are in the 320-point design box; a negative `hop` lifts Gooby.
struct GoobyPose {
    var stance: GoobyStance = .stand
    var breath: CGFloat = 1
    var blink: CGFloat = 1
    var happy = false
    var mouth = false
    var earLeft: CGFloat = 0
    var earRight: CGFloat = 0
    var hop: CGFloat = 0
    var tilt: CGFloat = 0
    var headTilt: CGFloat = 0
    var wave: CGFloat = 0
    var step: CGFloat = 0
    var squash: CGFloat = 1
    var depart: CGFloat = 0
    var marks: GoobyMarks = []
    var markPhase: Double = 0
}

struct GoobyCharacterView: View {
    var look: WornLook
    var stage: String
    var animation: GoobyAnimation
    var reduceMotion: Bool
    var companion: String?
    var showCompanion: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let pose = GoobyPose.make(animation: animation, time: timeline.date.timeIntervalSinceReferenceDate, reduce: reduceMotion)
            GoobyRig(look: look, stage: stage, pose: pose, companion: showCompanion ? companion : nil)
        }
        .accessibilityLabel("Gooby")
    }
}

extension GoobyPose {
    static func stance(for animation: GoobyAnimation) -> GoobyStance {
        switch animation {
        case .wave, .clap, .dance, .play, .celebrate: return .wave
        case .read: return .read
        case .sit, .wake: return .sit
        case .sleep: return .sleep
        case .think, .curious: return .curious
        case .flower, .present: return .flower
        case .depart, .walk: return .back
        default: return .stand
        }
    }

    /// The still frame of an animation: stance, face, and marks, with no motion.
    static func still(_ animation: GoobyAnimation) -> GoobyPose {
        var pose = GoobyPose(stance: stance(for: animation))
        switch animation {
        case .laugh, .clap, .dance, .play, .wave:
            pose.happy = true
            pose.mouth = true
            pose.marks = .sparkle
        case .celebrate:
            pose.happy = true
            pose.mouth = true
            pose.marks = [.sparkle, .hearts]
        case .petting, .hearts, .flower, .present, .arrive:
            pose.happy = true
            pose.marks = .hearts
        case .surprised, .unwrap:
            pose.blink = 1.12
            pose.marks = .alert
            pose.earLeft = -4
            pose.earRight = 4
        case .think, .curious:
            pose.headTilt = -8
            pose.marks = .question
        case .sleep:
            pose.marks = .zzz
        default:
            break
        }
        return pose
    }

    static func make(animation: GoobyAnimation, time t: Double, reduce: Bool) -> GoobyPose {
        var pose = still(animation)
        if reduce { return pose }
        pose.markPhase = t
        pose.breath = 1 + 0.014 * CGFloat(sin(t * 1.8))
        if !pose.happy && animation != .surprised && animation != .unwrap {
            pose.blink = GoobyMotion.blink(t, every: animation == .blink ? 2.2 : 4.6)
        }
        let sway = CGFloat(sin(t * 1.3)) * 2
        pose.earLeft += sway
        pose.earRight -= sway
        switch animation {
        case .idle:
            pose.earRight += GoobyMotion.flick(t, period: 7, length: 0.6) * 12
            pose.earLeft -= GoobyMotion.flick(t + 3.1, period: 9, length: 0.5) * 8
            let local = t.truncatingRemainder(dividingBy: 11)
            if local < 0.45 { pose.hop = -CGFloat(sin(local / 0.45 * .pi)) * 9 }
        case .breathe:
            pose.breath = 1 + 0.024 * CGFloat(sin(t * 1.2))
        case .ears:
            pose.earLeft += CGFloat(sin(t * 6)) * 10
            pose.earRight += CGFloat(sin(t * 6 + 1.2)) * 10
        case .wiggle:
            pose.tilt = CGFloat(sin(t * 6)) * 6
        case .hop:
            GoobyMotion.hops(&pose, t, height: 16, period: 0.9)
        case .laugh:
            pose.tilt = CGFloat(sin(t * 6)) * 4
            pose.squash = 1 + 0.03 * CGFloat(abs(sin(t * 6)))
        case .clap, .wave:
            pose.wave = CGFloat(sin(t * (animation == .clap ? 9 : 5)))
        case .surprised:
            pose.hop = -6
            pose.earLeft -= 4
            pose.earRight += 4
        case .think, .curious:
            pose.headTilt = -8 + CGFloat(sin(t * 1.2)) * 2.5
            pose.earRight += GoobyMotion.flick(t, period: 5, length: 0.5) * 10
        case .sit, .read:
            pose.earRight += GoobyMotion.flick(t, period: 8, length: 0.6) * 10
        case .sleep:
            pose.breath = 1 + 0.03 * CGFloat(sin(t * 0.9))
            pose.blink = 0
        case .wake:
            pose.blink = CGFloat(abs(sin(t * 1.5)))
            pose.earLeft += CGFloat(sin(t * 2)) * 6
        case .petting:
            pose.squash = 1 + 0.035 * CGFloat(sin(t * 4))
            pose.headTilt = 4
        case .hearts:
            GoobyMotion.hops(&pose, t, height: 8, period: 1.4)
        case .dance:
            pose.wave = CGFloat(sin(t * 5))
            pose.tilt = CGFloat(sin(t * 5)) * 8
            pose.hop = -abs(CGFloat(sin(t * 5))) * 12
        case .play:
            pose.wave = CGFloat(sin(t * 3))
            pose.hop = -abs(CGFloat(sin(t * 3))) * 10
        case .unwrap:
            pose.hop = -abs(CGFloat(sin(t * 2))) * 8
        case .present, .flower:
            pose.headTilt = CGFloat(sin(t * 1.6)) * 3
        case .depart:
            pose.depart = min(1, CGFloat(t.truncatingRemainder(dividingBy: 2.4) / 2))
            GoobyMotion.walk(&pose, t)
        case .walk:
            GoobyMotion.walk(&pose, t)
        case .arrive:
            pose.depart = -max(0, 1 - CGFloat(t.truncatingRemainder(dividingBy: 2.4) / 1.6))
            GoobyMotion.walk(&pose, t)
        case .celebrate:
            pose.wave = CGFloat(sin(t * 7))
            GoobyMotion.hops(&pose, t, height: 18, period: 0.8)
        case .blink:
            break
        }
        return pose
    }
}

enum GoobyMotion {
    /// 1 while the eyes are open. Each cycle ends in a 0.16 s blink, and every third cycle blinks twice.
    static func blink(_ t: Double, every period: Double) -> CGFloat {
        let cycle = t.truncatingRemainder(dividingBy: period)
        func dip(_ start: Double) -> Double {
            let local = (cycle - start) / 0.16
            guard local >= 0, local <= 1 else { return 1 }
            return abs(1 - local * 2)
        }
        var value = dip(period - 0.3)
        if Int(t / period) % 3 == 0 { value = min(value, dip(period - 0.6)) }
        return CGFloat(max(0, value))
    }

    /// One sine bump of `length` seconds, once per `period`.
    static func flick(_ t: Double, period: Double, length: Double) -> CGFloat {
        let local = t.truncatingRemainder(dividingBy: period)
        guard local < length else { return 0 }
        return CGFloat(sin(local / length * .pi * 2))
    }

    static func hops(_ pose: inout GoobyPose, _ t: Double, height: CGFloat, period: Double) {
        let local = t.truncatingRemainder(dividingBy: period) / period
        if local < 0.62 {
            let air = CGFloat(sin(local / 0.62 * .pi))
            pose.hop = -air * height
            pose.squash = 1 - 0.04 * air
            pose.earLeft -= air * 6
            pose.earRight += air * 6
        } else {
            let land = CGFloat(sin((local - 0.62) / 0.38 * .pi))
            pose.squash = 1 + 0.06 * land
        }
    }

    static func walk(_ pose: inout GoobyPose, _ t: Double) {
        pose.step = CGFloat(sin(t * 7))
        pose.hop = -abs(CGFloat(sin(t * 7))) * 4
        pose.earLeft += CGFloat(sin(t * 7)) * 3
        pose.earRight -= CGFloat(sin(t * 7)) * 3
    }
}

struct GoobyRig: View {
    var look: WornLook
    var stage: String
    var pose: GoobyPose
    var companion: String?

    var body: some View {
        GeometryReader { geo in
            let unit = min(geo.size.width, geo.size.height)
            let k = unit / 320
            let feet = UnitPoint(x: 0.5, y: 306.0 / 320.0)
            let growth = CGFloat(Growth.scale(for: stage))
            let away = max(0, pose.depart)
            ZStack {
                if let companion {
                    MiniFriendBadge(species: companion)
                        .frame(width: unit * 0.24, height: unit * 0.24)
                        .offset(x: unit * 0.36, y: unit * 0.3 + pose.hop * k * 0.3)
                }
                GoobyArtist.canvas(.shadow, pose: pose, fur: fur, pack: packColor)
                    .scaleEffect(growth * (1 - away * 0.35), anchor: feet)
                ZStack {
                    ZStack {
                        GoobyArtist.canvas(.back, pose: pose, fur: fur, pack: packColor)
                        if showsGear {
                            gear(Self.torsoSlots)
                                .offset(y: sitting ? 14 * k : 0)
                        }
                        GoobyArtist.canvas(.front, pose: pose, fur: fur, pack: packColor)
                        if showsGear {
                            gear(Self.headSlots)
                                .rotationEffect(.degrees(Double(pose.headTilt)), anchor: UnitPoint(x: 163.0 / 320.0, y: 200.0 / 320.0))
                                .offset(y: sitting ? 14 * k : 0)
                        }
                    }
                    .scaleEffect(x: pose.squash, y: (2 - pose.squash) * pose.breath, anchor: feet)
                    .rotationEffect(.degrees(Double(pose.tilt)), anchor: feet)
                    .offset(y: pose.hop * k)
                    GoobyArtist.canvas(.marks, pose: pose, fur: fur, pack: packColor)
                        .offset(y: pose.hop * k)
                }
                .scaleEffect(growth * (1 - away * 0.35), anchor: feet)
            }
            .offset(x: pose.depart * unit * 0.3, y: -away * unit * 0.1)
            .opacity(1 - Double(away) * 0.5)
            .frame(width: unit, height: unit)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private static let torsoSlots = ["shoes", "pants", "shirt", "sweater", "jacket", "dress"]
    private static let headSlots = ["scarf", "glasses", "bow", "hat", "accessory"]

    private var sitting: Bool { pose.stance == .read || pose.stance == .sit }
    private var showsGear: Bool { pose.stance != .sleep && pose.stance != .back }

    private func gear(_ slots: [String]) -> some View {
        GeometryReader { geo in
            ZStack {
                ForEach(slots, id: \.self) { slot in
                    if let item = look.slots[slot] { GearShape(item: item) }
                }
            }
            .frame(width: 320, height: 320)
            .scaleEffect(min(geo.size.width, geo.size.height) / 320)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var fur: FurPaint { FurPaint.resolve(look.fur) }

    private var packColor: Color {
        if let pack = look.slots["backpack"] { return Color(hexString: pack.color) }
        return GoobyInkColor.pack
    }
}

struct FurPaint {
    var body: Color
    var shade: Color
    var bib: Color
    var cheek: Color
    var innerEar: Color

    static func resolve(_ id: String) -> FurPaint {
        switch id {
        case "fur-peach":
            return FurPaint(body: Color(hex: 0xFFE1C8), shade: Color(hex: 0xF0C3A2), bib: Color(hex: 0xF7CFB2), cheek: Color(hex: 0xFFADB8), innerEar: Color(hex: 0xFFB1BE))
        case "fur-lilac":
            return FurPaint(body: Color(hex: 0xF4ECFF), shade: Color(hex: 0xDACDF2), bib: Color(hex: 0xE5DAF8), cheek: Color(hex: 0xF3B6D4), innerEar: Color(hex: 0xF7C3DE))
        case "fur-mint":
            return FurPaint(body: Color(hex: 0xF0FBF2), shade: Color(hex: 0xCFEBDB), bib: Color(hex: 0xDCF1E5), cheek: Color(hex: 0xFFC0D4), innerEar: Color(hex: 0xFFC4D8))
        case "fur-honey":
            return FurPaint(body: Color(hex: 0xFFF3D8), shade: Color(hex: 0xF0D29E), bib: Color(hex: 0xF6DFB4), cheek: Color(hex: 0xFFB7C6), innerEar: Color(hex: 0xFFC0D0))
        case "fur-sky":
            return FurPaint(body: Color(hex: 0xF4FBFF), shade: Color(hex: 0xD2E8F5), bib: Color(hex: 0xDEEEF8), cheek: Color(hex: 0xFFC2D6), innerEar: Color(hex: 0xFFC8DC))
        default:
            return FurPaint(body: Color(hex: 0xFDF0E3), shade: Color(hex: 0xEFD5BF), bib: Color(hex: 0xF4DAC4), cheek: Color(hex: 0xFBB7B4), innerEar: Color(hex: 0xFBB9B9))
        }
    }
}

struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 2))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + 2), control: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

struct GearShape: View {
    var item: ItemDef

    var body: some View {
        let primary = Color(hexString: item.color)
        let second = Color(hexString: item.color2)
        switch item.slot {
        case "hat":
            hat(primary, second).offset(y: 22)
        case "bow":
            bow(primary, second).offset(x: -36, y: -70)
        case "glasses":
            glasses(primary).offset(x: 18, y: -20)
        case "scarf":
            scarf(primary, second).offset(x: 6, y: 44)
        case "shirt", "sweater":
            torso(primary, second, neck: item.slot == "sweater").offset(y: 80)
        case "jacket":
            jacket(primary, second).offset(y: 78)
        case "dress":
            dress(primary, second).offset(y: 96)
        case "pants":
            pants(primary).offset(x: -3, y: 112)
        case "shoes":
            shoes(primary, second).offset(x: -3, y: 140)
        case "backpack":
            EmptyView()
        default:
            accessory(primary, second).offset(x: 50, y: 64)
        }
    }

    private func hat(_ primary: Color, _ second: Color) -> some View {
        ZStack {
            if item.style == 1 {
                Ellipse().fill(primary).frame(width: 120, height: 28).offset(y: -86)
                Capsule().fill(primary).frame(width: 70, height: 36).offset(y: -108)
            } else if item.style == 2 {
                Capsule().fill(primary).frame(width: 78, height: 44).offset(y: -108)
                Circle().fill(second).frame(width: 16).offset(x: 24, y: -124)
            } else if item.style == 3 {
                ForEach(0..<5, id: \.self) { index in
                    Circle().fill(index.isMultiple(of: 2) ? primary : second).frame(width: 16)
                        .offset(x: CGFloat(index - 2) * 16, y: -108)
                }
            } else {
                Capsule().fill(second).frame(width: 90, height: 18).offset(y: -92)
                Capsule().fill(primary).frame(width: 64, height: 40).offset(y: -112)
            }
        }
    }

    private func bow(_ primary: Color, _ second: Color) -> some View {
        ZStack {
            Circle().fill(primary).frame(width: 22, height: 22).offset(x: -16)
            Circle().fill(primary).frame(width: 22, height: 22).offset(x: 16)
            Circle().fill(second).frame(width: 12, height: 12)
        }
    }

    private func glasses(_ primary: Color) -> some View {
        HStack(spacing: 24) {
            Circle().stroke(primary, lineWidth: 4).frame(width: 34, height: 34)
            Circle().stroke(primary, lineWidth: 4).frame(width: 34, height: 34)
        }
    }

    private func scarf(_ primary: Color, _ second: Color) -> some View {
        ZStack {
            Capsule().fill(primary).frame(width: 86, height: 22)
            Capsule().fill(second).frame(width: 16, height: 36).offset(x: 24, y: 16)
        }
    }

    private func torso(_ primary: Color, _ second: Color, neck: Bool) -> some View {
        ZStack {
            Ellipse().fill(primary).frame(width: 124, height: neck ? 104 : 92)
            if item.style == 2 {
                Circle().fill(second).frame(width: 16).offset(y: -10)
            } else {
                Capsule().fill(second.opacity(0.8)).frame(width: 28, height: 10).offset(y: -24)
            }
        }
    }

    private func jacket(_ primary: Color, _ second: Color) -> some View {
        ZStack {
            Ellipse().fill(primary).frame(width: 132, height: 100)
            Capsule().fill(second).frame(width: 10, height: 70)
        }
    }

    private func dress(_ primary: Color, _ second: Color) -> some View {
        ZStack {
            Ellipse().fill(primary).frame(width: 136, height: 108)
            Capsule().fill(second).frame(width: 70, height: 12).offset(y: -40)
        }
    }

    private func pants(_ primary: Color) -> some View {
        HStack(spacing: 18) {
            Capsule().fill(primary).frame(width: 36, height: 48)
            Capsule().fill(primary).frame(width: 36, height: 48)
        }
    }

    private func shoes(_ primary: Color, _ second: Color) -> some View {
        HStack(spacing: 14) {
            Ellipse().fill(primary).frame(width: 40, height: 18)
            Ellipse().fill(primary).frame(width: 40, height: 18)
        }
        .overlay(alignment: .top) {
            if item.style == 1 {
                HStack(spacing: 46) {
                    Circle().fill(second).frame(width: 8)
                    Circle().fill(second).frame(width: 8)
                }
            }
        }
    }

    private func accessory(_ primary: Color, _ second: Color) -> some View {
        ZStack {
            if item.style == 1 {
                Image(systemName: "star.fill").foregroundStyle(primary)
            } else if item.style == 2 {
                Image(systemName: "bell.fill").foregroundStyle(primary)
            } else {
                Circle().fill(primary).frame(width: 18)
                Circle().fill(second).frame(width: 8)
            }
        }
        .font(.system(size: 22))
    }
}

struct MiniFriendBadge: View {
    var species: String

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0)) { timeline in
            let bob = CGFloat(sin(timeline.date.timeIntervalSinceReferenceDate * 2)) * 3
            friend
                .offset(y: bob)
        }
        .accessibilityLabel(species)
    }

    @ViewBuilder private var friend: some View {
        switch species {
        case "chick":
            ZStack {
                Circle().fill(Color(hex: 0xFFE7AD)).frame(width: 36, height: 34)
                Circle().fill(Color(hex: 0x3D3656)).frame(width: 4).offset(x: -6, y: -4)
                Circle().fill(Color(hex: 0x3D3656)).frame(width: 4).offset(x: 6, y: -4)
                Triangle().fill(Color(hex: 0xFFB067)).frame(width: 8, height: 6).offset(y: 4)
            }
        case "cloud":
            ZStack {
                Circle().fill(Color.white).frame(width: 26).offset(x: -8)
                Circle().fill(Color.white).frame(width: 32)
                Circle().fill(Color.white).frame(width: 22).offset(x: 12, y: 4)
                Circle().fill(Theme.ink).frame(width: 3).offset(x: -4, y: 2)
                Circle().fill(Theme.ink).frame(width: 3).offset(x: 6, y: 2)
            }
        case "dragon":
            ZStack {
                Circle().fill(Color(hex: 0xC6EFDC)).frame(width: 34)
                Capsule().fill(Color(hex: 0x8FD8B8)).frame(width: 8, height: 16).offset(x: -10, y: -16).rotationEffect(.degrees(-20))
                Capsule().fill(Color(hex: 0x8FD8B8)).frame(width: 8, height: 16).offset(x: 10, y: -16).rotationEffect(.degrees(20))
                Circle().fill(Theme.ink).frame(width: 4).offset(x: -6, y: -2)
                Circle().fill(Theme.ink).frame(width: 4).offset(x: 6, y: -2)
            }
        case "fox":
            ZStack {
                Circle().fill(Color(hex: 0xFFD6B3)).frame(width: 34)
                Triangle().fill(Color(hex: 0xFFB38A)).frame(width: 12, height: 12).offset(x: -12, y: -14)
                Triangle().fill(Color(hex: 0xFFB38A)).frame(width: 12, height: 12).offset(x: 12, y: -14)
                Ellipse().fill(Color.white).frame(width: 16, height: 12).offset(y: 6)
            }
        case "starling":
            ZStack {
                Star(points: 5).fill(Color(hex: 0xFFE7AD)).frame(width: 36, height: 36)
                Circle().fill(Theme.ink).frame(width: 3).offset(x: -4)
                Circle().fill(Theme.ink).frame(width: 3).offset(x: 4)
            }
        case "penguin":
            ZStack {
                Ellipse().fill(Color(hex: 0x3D3656)).frame(width: 30, height: 36)
                Ellipse().fill(Color.white).frame(width: 16, height: 22).offset(y: 4)
                Circle().fill(Color(hex: 0xFFD6B3)).frame(width: 6).offset(y: -2)
            }
        case "bear":
            ZStack {
                Circle().fill(Color(hex: 0xE7C4A8)).frame(width: 34)
                Circle().fill(Color(hex: 0xC9A184)).frame(width: 12).offset(x: -14, y: -12)
                Circle().fill(Color(hex: 0xC9A184)).frame(width: 12).offset(x: 14, y: -12)
                Ellipse().fill(Color(hex: 0xFFD6E7)).frame(width: 12, height: 8).offset(y: 4)
            }
        case "cat":
            ZStack {
                Circle().fill(Color(hex: 0xF7E7D8)).frame(width: 34)
                Triangle().fill(Color(hex: 0xF7E7D8)).frame(width: 10, height: 12).offset(x: -10, y: -16)
                Triangle().fill(Color(hex: 0xF7E7D8)).frame(width: 10, height: 12).offset(x: 10, y: -16)
                Ellipse().fill(Color(hex: 0xFFB7CC)).frame(width: 8, height: 5).offset(y: 2)
            }
        case "ghost":
            ZStack {
                Capsule().fill(Color.white.opacity(0.92)).frame(width: 30, height: 38)
                Circle().fill(Theme.lavender).frame(width: 5).offset(x: -6, y: -4)
                Circle().fill(Theme.lavender).frame(width: 5).offset(x: 6, y: -4)
            }
        case "unicorn":
            ZStack {
                Circle().fill(Color.white).frame(width: 34)
                Capsule().fill(Color(hex: 0xD3C2FF)).frame(width: 6, height: 16).offset(y: -22)
                Circle().fill(Theme.ink).frame(width: 3).offset(x: -5, y: -2)
                Circle().fill(Theme.ink).frame(width: 3).offset(x: 5, y: -2)
            }
        case "moon":
            ZStack {
                Circle().fill(Color(hex: 0xFFF3C9)).frame(width: 34)
                Circle().fill(Theme.cream).frame(width: 22).offset(x: 8)
                Circle().fill(Theme.ink).frame(width: 3).offset(x: -8)
            }
        default:
            ZStack {
                Capsule().fill(Color(hex: 0xF3C6D8)).frame(width: 28, height: 32)
                Capsule().fill(Color.white).frame(width: 16, height: 12).offset(y: 6)
                Circle().fill(Color(hex: 0xE989B0)).frame(width: 10).offset(y: -16)
            }
        }
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
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<(points * 2) {
            let angle = (Double(index) * .pi / Double(points)) - .pi / 2
            let length = index.isMultiple(of: 2) ? radius : radius * 0.45
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * length, y: center.y + CGFloat(sin(angle)) * length)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
