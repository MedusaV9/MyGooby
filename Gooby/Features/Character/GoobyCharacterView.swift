import SwiftUI

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

struct GoobyPose {
    var breath: CGFloat
    var blink: CGFloat
    var ear: CGFloat
    var hop: CGFloat
    var tilt: CGFloat
    var squash: CGFloat
    var arm: CGFloat
    var sit: CGFloat
    var sleep: Bool
    var hearts: Bool
    var zzz: Bool
    var surprise: CGFloat
    var depart: CGFloat
}

struct GoobyCharacterView: View {
    var look: WornLook
    var stage: String
    var animation: GoobyAnimation
    var reduceMotion: Bool
    var companion: String?
    var showCompanion: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 24.0, paused: false)) { timeline in
            let pose = GoobyPose.make(animation: animation, time: timeline.date.timeIntervalSinceReferenceDate, reduce: reduceMotion)
            GoobyRig(look: look, stage: stage, pose: pose, companion: showCompanion ? companion : nil)
        }
        .accessibilityLabel("Gooby")
    }
}

extension GoobyPose {
    static func make(animation: GoobyAnimation, time: Double, reduce: Bool) -> GoobyPose {
        if reduce {
            return GoobyPose(breath: 1, blink: animation == .sleep ? 0.08 : 1, ear: 0, hop: 0, tilt: 0, squash: animation == .petting ? 0.92 : 1, arm: 0, sit: animation == .sit || animation == .sleep ? 1 : 0, sleep: animation == .sleep, hearts: animation == .hearts || animation == .celebrate, zzz: animation == .sleep, surprise: animation == .surprised ? 1 : 0, depart: animation == .depart ? 1 : 0)
        }
        let wave = CGFloat(sin(time * 1.6))
        let fast = CGFloat(sin(time * 6))
        var blink: CGFloat = 1
        if animation == .sleep {
            blink = 0.08
        } else if animation == .blink || animation == .idle || animation == .breathe {
            let cycle = time.truncatingRemainder(dividingBy: 4.4)
            if cycle > 4.05 {
                let local = (cycle - 4.05) / 0.35
                blink = local < 0.5 ? CGFloat(1 - local * 2) : CGFloat((local - 0.5) * 2)
                blink = max(0.08, blink)
            }
        }
        var pose = GoobyPose(breath: 1 + 0.018 * wave, blink: blink, ear: wave * 4, hop: 0, tilt: 0, squash: 1, arm: 0, sit: 0, sleep: false, hearts: false, zzz: false, surprise: 0, depart: 0)
        switch animation {
        case .idle, .breathe, .blink:
            pose.ear = wave * 5
        case .ears:
            pose.ear = CGFloat(sin(time * 3)) * 10
        case .wiggle:
            pose.tilt = fast * 6
        case .hop, .celebrate:
            pose.hop = abs(CGFloat(sin(time * 5))) * -18
            pose.hearts = animation == .celebrate
        case .laugh:
            pose.tilt = fast * 4
            pose.squash = 0.96 + 0.04 * abs(fast)
            pose.hearts = true
        case .clap:
            pose.arm = abs(fast)
        case .surprised:
            pose.surprise = 1
            pose.hop = -6
        case .think:
            pose.tilt = -8
            pose.ear = 6
        case .sit:
            pose.sit = 1
        case .sleep:
            pose.sleep = true
            pose.zzz = true
            pose.sit = 0.6
            pose.breath = 1 + 0.03 * CGFloat(sin(time * 0.8))
        case .wake:
            pose.blink = CGFloat(abs(sin(time * 2)))
            pose.hop = CGFloat(sin(time * 2)) * -4
        case .petting:
            pose.squash = 0.9
            pose.tilt = 3
            pose.hearts = true
        case .hearts:
            pose.hearts = true
            pose.hop = abs(wave) * -8
        case .dance:
            pose.tilt = CGFloat(sin(time * 5)) * 10
            pose.hop = abs(CGFloat(sin(time * 5))) * -16
            pose.arm = abs(fast)
        case .play:
            pose.tilt = CGFloat(sin(time * 3)) * 8
            pose.hop = abs(wave) * -10
        case .unwrap:
            pose.surprise = CGFloat(max(0, sin(time * 2)))
            pose.hop = -8
        case .present:
            pose.tilt = CGFloat(sin(time * 2)) * 8
            pose.hop = -4
        case .depart:
            pose.depart = min(1, CGFloat(time.truncatingRemainder(dividingBy: 2) / 1.2))
            pose.hop = abs(fast) * -12
        case .arrive:
            pose.depart = max(0, 1 - CGFloat(time.truncatingRemainder(dividingBy: 1.6)))
            pose.hop = abs(fast) * -10
            pose.hearts = true
        }
        return pose
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
            ZStack {
                if let companion {
                    MiniFriendBadge(species: companion)
                        .frame(width: unit * 0.28, height: unit * 0.28)
                        .offset(x: unit * 0.30, y: unit * 0.22 + pose.hop * 0.3)
                }
                ZStack {
                    GoobyShadowLayer()
                    if let pack = look.slots["backpack"] {
                        GearShape(item: pack, pose: pose)
                    }
                    GoobyEarsLayer(fur: fur, pose: pose, stage: stage)
                    if let hat = look.slots["hat"] { GearShape(item: hat, pose: pose) }
                    GoobyBodyLayer(fur: fur, pose: pose)
                    GoobyFeetLayer(fur: fur, pose: pose)
                    if let shoes = look.slots["shoes"] { GearShape(item: shoes, pose: pose) }
                    if let pants = look.slots["pants"] { GearShape(item: pants, pose: pose) }
                    if let shirt = look.slots["shirt"] { GearShape(item: shirt, pose: pose) }
                    if let sweater = look.slots["sweater"] { GearShape(item: sweater, pose: pose) }
                    if let jacket = look.slots["jacket"] { GearShape(item: jacket, pose: pose) }
                    if let dress = look.slots["dress"] { GearShape(item: dress, pose: pose) }
                    GoobyPawsLayer(fur: fur, pose: pose)
                    GoobyHeadLayer(fur: fur, pose: pose)
                    GoobyFaceLayer(pose: pose)
                    if let scarf = look.slots["scarf"] { GearShape(item: scarf, pose: pose) }
                    if let glasses = look.slots["glasses"] { GearShape(item: glasses, pose: pose) }
                    if let bow = look.slots["bow"] { GearShape(item: bow, pose: pose) }
                    if pose.hearts { HeartsLayer() }
                    if pose.zzz { SleepMarks() }
                    if let pin = look.slots["accessory"] { GearShape(item: pin, pose: pose) }
                }
                .scaleEffect(unit / 320)
                .scaleEffect(x: pose.squash, y: (2 - pose.squash) * pose.breath * CGFloat(Growth.scale(for: stage)), anchor: .bottom)
                .offset(y: pose.hop + pose.sit * unit * 0.04 + pose.depart * unit * 0.05)
                .rotationEffect(.degrees(pose.tilt))
                .offset(x: pose.depart * unit * 0.55)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var fur: FurPaint {
        FurPaint.resolve(look.fur)
    }
}

struct FurPaint {
    var body: Color
    var shade: Color
    var cheek: Color
    var innerEar: Color

    static func resolve(_ id: String) -> FurPaint {
        switch id {
        case "fur-peach":
            return FurPaint(body: Color(hex: 0xFFE1C8), shade: Color(hex: 0xF3C7A8), cheek: Color(hex: 0xFFB3C7), innerEar: Color(hex: 0xFFB7CB))
        case "fur-lilac":
            return FurPaint(body: Color(hex: 0xF4ECFF), shade: Color(hex: 0xDDD0F5), cheek: Color(hex: 0xF3B6D4), innerEar: Color(hex: 0xF7C3DE))
        case "fur-mint":
            return FurPaint(body: Color(hex: 0xF3FFF6), shade: Color(hex: 0xD5F3E2), cheek: Color(hex: 0xFFC0D4), innerEar: Color(hex: 0xFFC4D8))
        case "fur-honey":
            return FurPaint(body: Color(hex: 0xFFF3D8), shade: Color(hex: 0xF3D7A4), cheek: Color(hex: 0xFFB7C6), innerEar: Color(hex: 0xFFC0D0))
        case "fur-sky":
            return FurPaint(body: Color(hex: 0xF4FBFF), shade: Color(hex: 0xD5ECF8), cheek: Color(hex: 0xFFC2D6), innerEar: Color(hex: 0xFFC8DC))
        default:
            return FurPaint(body: Color(hex: 0xFFF6EA), shade: Color(hex: 0xF0D8C4), cheek: Color(hex: 0xFFB7CC), innerEar: Color(hex: 0xFFC2D6))
        }
    }
}

struct GoobyShadowLayer: View {
    var body: some View {
        Ellipse()
            .fill(Theme.ink.opacity(0.08))
            .frame(width: 120, height: 22)
            .offset(y: 108)
    }
}

struct GoobyEarsLayer: View {
    var fur: FurPaint
    var pose: GoobyPose
    var stage: String

    var body: some View {
        let extra: CGFloat = stage == "adult" || stage == "teen" ? 8 : 0
        ZStack {
            ear(tilt: -16 + pose.ear, x: -38)
            ear(tilt: 16 - pose.ear, x: 38)
        }
        .offset(y: -118 - extra * 0.2)
    }

    private func ear(tilt: CGFloat, x: CGFloat) -> some View {
        ZStack {
            Capsule().fill(fur.body).frame(width: 36, height: 92)
            Capsule().fill(fur.shade.opacity(0.35)).frame(width: 36, height: 92).offset(x: 4)
            Capsule().fill(fur.innerEar).frame(width: 18, height: 58).offset(y: 8)
        }
        .rotationEffect(.degrees(tilt))
        .offset(x: x)
    }
}

struct GoobyBodyLayer: View {
    var fur: FurPaint
    var pose: GoobyPose

    var body: some View {
        ZStack {
            Ellipse()
                .fill(fur.shade)
                .frame(width: 168, height: 142)
                .offset(x: 6, y: 58)
            Ellipse()
                .fill(fur.body)
                .frame(width: 168, height: 142)
                .offset(y: 52)
            Ellipse()
                .fill(Color.white.opacity(0.35))
                .frame(width: 70, height: 36)
                .offset(x: -28, y: 28)
        }
    }
}

struct GoobyHeadLayer: View {
    var fur: FurPaint
    var pose: GoobyPose

    var body: some View {
        ZStack {
            Circle().fill(fur.shade).frame(width: 156, height: 150).offset(x: 5, y: -28)
            Circle().fill(fur.body).frame(width: 156, height: 150).offset(y: -34)
            Ellipse()
                .fill(Color.white.opacity(0.45))
                .frame(width: 54, height: 28)
                .offset(x: -36, y: -72)
        }
        .scaleEffect(1 + pose.surprise * 0.04)
    }
}

struct GoobyFaceLayer: View {
    var pose: GoobyPose

    var body: some View {
        ZStack {
            cheek.offset(x: -48, y: -8)
            cheek.offset(x: 48, y: -8)
            eye.offset(x: -28, y: -40)
            eye.offset(x: 28, y: -40)
            Ellipse()
                .fill(Color(hex: 0xFF9BB8))
                .frame(width: 16, height: 12)
                .offset(y: -16)
            smile
                .offset(y: -2)
        }
    }

    private var cheek: some View {
        Circle().fill(Color(hex: 0xFFB7CC).opacity(0.9)).frame(width: 28, height: 22)
    }

    private var eye: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: 0x2A2438))
                .frame(width: 32, height: 34 * pose.blink)
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10 * pose.blink)
                .offset(x: -7, y: -8 * pose.blink)
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 4, height: 4 * pose.blink)
                .offset(x: 6, y: -2 * pose.blink)
        }
        .frame(width: 34, height: 36)
    }

    private var smile: some View {
        ZStack {
            SmileShape()
                .stroke(Color(hex: 0xC46B86), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 28, height: 16)
            Ellipse()
                .fill(Color(hex: 0xFF8EAB))
                .frame(width: 14, height: pose.sleep ? 2 : 8)
                .offset(y: 6)
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

struct GoobyPawsLayer: View {
    var fur: FurPaint
    var pose: GoobyPose

    var body: some View {
        ZStack {
            paw.offset(x: -78 - pose.arm * 10, y: 40 + pose.sit * 8)
            paw.offset(x: 78 + pose.arm * 10, y: 40 + pose.sit * 8)
            Ellipse()
                .fill(fur.body)
                .frame(width: 36, height: 28)
                .offset(y: 78)
            Ellipse()
                .fill(fur.body)
                .frame(width: 36, height: 28)
                .offset(x: 28, y: 78)
        }
    }

    private var paw: some View {
        Circle().fill(fur.body).frame(width: 34, height: 34)
            .overlay(Circle().stroke(fur.shade, lineWidth: 2))
    }
}

struct GoobyFeetLayer: View {
    var fur: FurPaint
    var pose: GoobyPose

    var body: some View {
        ZStack {
            Ellipse().fill(fur.shade).frame(width: 46, height: 26).offset(x: -32, y: 112 + pose.sit * 6)
            Ellipse().fill(fur.body).frame(width: 46, height: 26).offset(x: -32, y: 108 + pose.sit * 6)
            Ellipse().fill(fur.shade).frame(width: 46, height: 26).offset(x: 32, y: 112 + pose.sit * 6)
            Ellipse().fill(fur.body).frame(width: 46, height: 26).offset(x: 32, y: 108 + pose.sit * 6)
        }
    }
}

struct HeartsLayer: View {
    var body: some View {
        ZStack {
            heart.offset(x: -70, y: -120)
            heart.offset(x: 74, y: -100)
            heart.offset(x: 10, y: -140)
        }
    }

    private var heart: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 16))
            .foregroundStyle(Color(hex: 0xFF8FB3))
    }
}

struct SleepMarks: View {
    var body: some View {
        Text("z z")
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.lavender)
            .offset(x: 78, y: -120)
    }
}

struct GearShape: View {
    var item: ItemDef
    var pose: GoobyPose

    var body: some View {
        let primary = Color(hexString: item.color)
        let second = Color(hexString: item.color2)
        switch item.slot {
        case "hat":
            hat(primary, second)
        case "bow":
            bow(primary, second).offset(y: -78)
        case "glasses":
            glasses(primary).offset(y: -40)
        case "scarf":
            scarf(primary, second).offset(y: 8)
        case "shirt", "sweater":
            torso(primary, second, neck: item.slot == "sweater").offset(y: 48)
        case "jacket":
            jacket(primary, second).offset(y: 46)
        case "dress":
            dress(primary, second).offset(y: 70)
        case "pants":
            pants(primary).offset(y: 92)
        case "shoes":
            shoes(primary, second).offset(y: 112)
        case "backpack":
            backpack(primary, second).offset(y: 40)
        default:
            accessory(primary, second).offset(x: 58, y: 20)
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
        HStack(spacing: 8) {
            Circle().stroke(primary, lineWidth: 4).frame(width: 28, height: 28)
            Circle().stroke(primary, lineWidth: 4).frame(width: 28, height: 28)
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
            Ellipse().fill(primary).frame(width: 132, height: neck ? 110 : 96)
            if item.style == 2 {
                Circle().fill(second).frame(width: 16).offset(y: -10)
            } else {
                Capsule().fill(second.opacity(0.8)).frame(width: 28, height: 10).offset(y: -24)
            }
        }
    }

    private func jacket(_ primary: Color, _ second: Color) -> some View {
        ZStack {
            Ellipse().fill(primary).frame(width: 148, height: 108)
            Capsule().fill(second).frame(width: 10, height: 70)
        }
    }

    private func dress(_ primary: Color, _ second: Color) -> some View {
        ZStack {
            Ellipse().fill(primary).frame(width: 150, height: 120)
            Capsule().fill(second).frame(width: 70, height: 12).offset(y: -40)
        }
    }

    private func pants(_ primary: Color) -> some View {
        HStack(spacing: 8) {
            Capsule().fill(primary).frame(width: 36, height: 48)
            Capsule().fill(primary).frame(width: 36, height: 48)
        }
    }

    private func shoes(_ primary: Color, _ second: Color) -> some View {
        HStack(spacing: 18) {
            Ellipse().fill(primary).frame(width: 40, height: 18)
            Ellipse().fill(primary).frame(width: 40, height: 18)
        }
        .overlay(alignment: .top) {
            if item.style == 1 {
                HStack(spacing: 28) {
                    Circle().fill(second).frame(width: 8)
                    Circle().fill(second).frame(width: 8)
                }
            }
        }
    }

    private func backpack(_ primary: Color, _ second: Color) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(primary)
            .frame(width: 54, height: 64)
            .overlay(RoundedRectangle(cornerRadius: 8).fill(second).frame(width: 28, height: 20))
            .offset(y: -6)
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
