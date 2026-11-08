import SwiftUI

enum BagColor {
    static let sky = Color(hex: 0x323956)
    static let hillLeft = Color(hex: 0x2D4E23)
    static let hillMid = Color(hex: 0x1E471B)
    static let hillRight = Color(hex: 0x143516)
    static let stage = Color(hex: 0xFD9F55)
    static let colorsTile = Color(hex: 0xF88119)
    static let plaque = Color(hex: 0xFDCB55)
    static let plaqueInk = Color(hex: 0x6F5524)
    static let dash = Color(hex: 0x7A5E2A)
    static let label = Color(hex: 0x2C2C2C)
    static let satchel = Color(hex: 0xF15839)
    static let satchelShade = Color(hex: 0xE04730)
    static let stick = Color(hex: 0x955316)
    static let tie = Color(hex: 0xEFC12D)
    static let gear = Color(hex: 0xD5D9E6)
    static let gearInner = Color(hex: 0xA8AEC0)
    static let mailRed = Color(hex: 0xE14B3A)
    static let mailTop = Color(hex: 0xC73B32)
    static let flag = Color(hex: 0xF6C44A)
    static let post = Color(hex: 0xC4894E)
    static let shirtYellow = Color(hex: 0xF8B85A)
    static let shirtPink = Color(hex: 0xF27B7B)
    static let hanger = Color(hex: 0x7EC8E8)
    static let sofa = Color(hex: 0xF06060)
    static let sofaLight = Color(hex: 0xF7A0A0)
    static let lamp = Color(hex: 0xF6C84A)
    static let lampPole = Color(hex: 0xE4E4E4)
    static let paw = Color(hex: 0x7A5644)
    static let pin = Color.white
}

enum BagMetric {
    static let designWidth: CGFloat = 390
    static let stageTop: CGFloat = 246
    static let stageRadius: CGFloat = 32
    static let plaque = CGRect(x: 101.5, y: 297, width: 187, height: 59)
    static let margin: CGFloat = 33
    static let gap: CGFloat = 14
    static let tileHeight: CGFloat = 80.5
    static let corner: CGFloat = 22
    static let mailY: CGFloat = 379
    static let row2Y: CGFloat = 473.4
    static let row3Y: CGFloat = 567
    static let locationY: CGFloat = 676
    static let gearCenter = CGPoint(x: 353, y: 78)
    static let satchelCenter = CGPoint(x: 195, y: 247)
    static let satchelSize = CGSize(width: 90, height: 90)
}

struct BagHills: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(BagColor.hillLeft)
                .frame(width: 300, height: 300)
                .position(x: 118, y: 278)
            Circle()
                .fill(BagColor.hillMid)
                .frame(width: 220, height: 220)
                .position(x: 214, y: 292)
            Circle()
                .fill(BagColor.hillRight)
                .frame(width: 250, height: 250)
                .position(x: 304, y: 268)
        }
        .frame(width: BagMetric.designWidth, height: 420)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct BagSatchel: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white)
                .frame(width: 80, height: 14)
                .rotationEffect(.degrees(16))
                .offset(x: 1, y: -14)
            Capsule()
                .fill(BagColor.stick)
                .frame(width: 72, height: 8)
                .rotationEffect(.degrees(16))
                .offset(x: 1, y: -14)
            BagBindle()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 7, lineJoin: .round, lineCap: .round))
            BagBindle()
                .fill(BagColor.satchel)
            BagBindle()
                .fill(BagColor.satchelShade)
                .mask(Ellipse().frame(width: 32, height: 24).offset(x: -5, y: 23))
            Capsule()
                .fill(BagColor.tie)
                .frame(width: 26, height: 6.4)
                .rotationEffect(.degrees(18))
                .offset(x: 7, y: -7)
        }
        .accessibilityHidden(true)
    }
}

struct BagBindle: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        var path = Path()
        path.move(to: p(34.0 / 90, 44.0 / 90))
        path.addCurve(to: p(36.0 / 90, 26.0 / 90), control1: p(26.0 / 90, 36.0 / 90), control2: p(30.0 / 90, 28.0 / 90))
        path.addCurve(to: p(40.0 / 90, 16.0 / 90), control1: p(32.0 / 90, 20.0 / 90), control2: p(34.0 / 90, 14.0 / 90))
        path.addCurve(to: p(54.0 / 90, 16.0 / 90), control1: p(44.0 / 90, 8.0 / 90), control2: p(52.0 / 90, 8.0 / 90))
        path.addCurve(to: p(68.0 / 90, 26.0 / 90), control1: p(60.0 / 90, 12.0 / 90), control2: p(70.0 / 90, 16.0 / 90))
        path.addCurve(to: p(68.0 / 90, 42.0 / 90), control1: p(74.0 / 90, 28.0 / 90), control2: p(76.0 / 90, 36.0 / 90))
        path.addCurve(to: p(64.0 / 90, 76.0 / 90), control1: p(76.0 / 90, 50.0 / 90), control2: p(74.0 / 90, 66.0 / 90))
        path.addCurve(to: p(28.0 / 90, 76.0 / 90), control1: p(54.0 / 90, 86.0 / 90), control2: p(36.0 / 90, 86.0 / 90))
        path.addCurve(to: p(34.0 / 90, 44.0 / 90), control1: p(18.0 / 90, 66.0 / 90), control2: p(20.0 / 90, 52.0 / 90))
        path.closeSubpath()
        return path
    }
}

struct BagGear: View {
    var body: some View {
        ZStack {
            BagGearShape()
                .fill(BagColor.gear, style: FillStyle(eoFill: true))
            Circle()
                .stroke(BagColor.gearInner, lineWidth: 3)
                .frame(width: 14, height: 14)
        }
        .accessibilityHidden(true)
    }
}

struct BagGearShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) * 0.5
        let root = outer * 0.70
        let teeth = 8
        let half = Double.pi / Double(teeth) * 0.46
        var path = Path()
        for index in 0..<teeth {
            let mid = (Double(index) / Double(teeth)) * 2 * Double.pi - Double.pi / 2
            let angles = [mid - half * 1.35, mid - half, mid + half, mid + half * 1.35]
            let radii = [root, outer, outer, root]
            for step in 0..<4 {
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angles[step])) * radii[step],
                    y: center.y + CGFloat(sin(angles[step])) * radii[step]
                )
                if index == 0 && step == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }
        path.closeSubpath()
        let hole = outer * 0.34
        path.addEllipse(in: CGRect(x: center.x - hole, y: center.y - hole, width: hole * 2, height: hole * 2))
        return path
    }
}

struct BagMailbox: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(BagColor.post)
                .frame(width: 8, height: 9)
                .offset(y: 14)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(BagColor.mailRed)
                .frame(width: 42, height: 22)
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(topLeading: 6, bottomLeading: 0, bottomTrailing: 0, topTrailing: 6),
                style: .continuous
            )
            .fill(BagColor.mailTop)
            .frame(width: 42, height: 9)
            .offset(y: -6.5)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(BagColor.flag)
                .frame(width: 8, height: 11)
                .offset(x: 11, y: -1)
        }
        .frame(width: 46, height: 40)
        .accessibilityHidden(true)
    }
}

struct BagOutfitsIcon: View {
    var body: some View {
        ZStack {
            BagHanger()
                .stroke(BagColor.hanger, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 24, height: 12)
                .offset(x: 10, y: -14)
            BagShirt()
                .fill(BagColor.shirtPink)
                .frame(width: 24, height: 20)
                .offset(x: 10, y: 2)
            BagHanger()
                .stroke(BagColor.hanger, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 28, height: 13)
                .offset(x: -6, y: -14)
            BagShirt()
                .fill(BagColor.shirtYellow)
                .frame(width: 30, height: 24)
                .offset(x: -6, y: 3)
        }
        .frame(width: 56, height: 40)
        .accessibilityHidden(true)
    }
}

struct BagHanger: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = CGPoint(x: rect.midX, y: rect.minY + 2)
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX + 5, y: rect.minY + 6), control: CGPoint(x: rect.midX + 6, y: rect.minY))
        path.move(to: CGPoint(x: rect.minX + 2, y: rect.maxY))
        path.addLine(to: mid)
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.maxY))
        return path
    }
}

struct BagShirt: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }
        var path = Path()
        path.move(to: p(0.28, 0.16))
        path.addLine(to: p(0.08, 0.34))
        path.addQuadCurve(to: p(0.18, 0.48), control: p(0.02, 0.46))
        path.addLine(to: p(0.28, 0.40))
        path.addLine(to: p(0.28, 0.96))
        path.addQuadCurve(to: p(0.72, 0.96), control: p(0.50, 1.02))
        path.addLine(to: p(0.72, 0.40))
        path.addLine(to: p(0.82, 0.48))
        path.addQuadCurve(to: p(0.92, 0.34), control: p(0.98, 0.46))
        path.addLine(to: p(0.72, 0.16))
        path.addQuadCurve(to: p(0.50, 0.28), control: p(0.62, 0.08))
        path.addQuadCurve(to: p(0.28, 0.16), control: p(0.38, 0.08))
        path.closeSubpath()
        return path
    }
}

struct BagFurnitureIcon: View {
    var body: some View {
        ZStack {
            BagLamp()
                .frame(width: 18, height: 36)
                .offset(x: 16, y: 2)
            BagSofa()
                .frame(width: 42, height: 26)
                .offset(x: -6, y: 6)
        }
        .frame(width: 54, height: 42)
        .accessibilityHidden(true)
    }
}

struct BagSofa: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(BagColor.sofa)
                .frame(height: 18)
                .padding(.horizontal, 4)
                .offset(y: -2)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(BagColor.sofaLight)
                .frame(height: 7)
                .padding(.horizontal, 8)
                .offset(y: 5)
            HStack {
                Capsule().fill(Color(hex: 0xE44848)).frame(width: 7, height: 16)
                Spacer()
                Capsule().fill(Color(hex: 0xE44848)).frame(width: 7, height: 16)
            }
            .offset(y: 1)
            HStack {
                RoundedRectangle(cornerRadius: 1).fill(BagColor.sofaShade).frame(width: 4, height: 5)
                Spacer()
                RoundedRectangle(cornerRadius: 1).fill(BagColor.sofaShade).frame(width: 4, height: 5)
            }
            .padding(.horizontal, 10)
            .offset(y: 12)
        }
    }
}

private extension BagColor {
    static let sofaShade = Color(hex: 0xC42828)
}

struct BagLamp: View {
    var body: some View {
        VStack(spacing: 0) {
            BagLampShade()
                .fill(BagColor.lamp)
                .frame(width: 16, height: 12)
            Rectangle()
                .fill(BagColor.lampPole)
                .frame(width: 2, height: 14)
            Capsule()
                .fill(BagColor.lampPole)
                .frame(width: 12, height: 4)
        }
    }
}

struct BagLampShade: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.22, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct BagQuestion: View {
    var body: some View {
        ZStack {
            BagQuestionShape()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 28)
                .offset(y: -4)
            Circle()
                .fill(Color.white)
                .frame(width: 6.5, height: 6.5)
                .offset(y: 16)
        }
        .frame(width: 36, height: 40)
        .accessibilityHidden(true)
    }
}

struct BagQuestionShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.28, y: h * 0.38))
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.08),
            control1: CGPoint(x: w * 0.28, y: h * 0.14),
            control2: CGPoint(x: w * 0.34, y: h * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.74, y: h * 0.34),
            control1: CGPoint(x: w * 0.70, y: h * 0.02),
            control2: CGPoint(x: w * 0.82, y: h * 0.16)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.62),
            control1: CGPoint(x: w * 0.66, y: h * 0.50),
            control2: CGPoint(x: w * 0.50, y: h * 0.50)
        )
        path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.74))
        return path
    }
}

struct BagPaws: View {
    var body: some View {
        ZStack {
            BagPaw()
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(-18))
                .offset(x: -8, y: 4)
            BagPaw()
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(12))
                .offset(x: 8, y: -6)
        }
        .frame(width: 48, height: 36)
        .accessibilityHidden(true)
    }
}

struct BagPaw: View {
    var body: some View {
        ZStack {
            Circle().frame(width: 5.2, height: 5.2).offset(x: -7, y: -7)
            Circle().frame(width: 5.4, height: 5.4).offset(x: -2.4, y: -9.2)
            Circle().frame(width: 5.4, height: 5.4).offset(x: 2.6, y: -9.2)
            Circle().frame(width: 5.2, height: 5.2).offset(x: 7, y: -6.4)
            Ellipse().frame(width: 13, height: 9.6).offset(y: 2)
        }
        .foregroundStyle(BagColor.paw)
    }
}

struct BagPin: View {
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(BagColor.pin)
                .frame(width: 11, height: 11)
            Capsule()
                .fill(BagColor.pin)
                .frame(width: 3, height: 8)
            Ellipse()
                .stroke(BagColor.pin, lineWidth: 2)
                .frame(width: 14, height: 6)
                .offset(y: -1)
        }
        .frame(width: 16, height: 24)
        .accessibilityHidden(true)
    }
}

enum BagTitle {
    static func text(name: String, language: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let who = trimmed.isEmpty ? "Gooby" : trimmed
        if language == "en" {
            return "\(who)'s bag"
        }
        if let last = who.lowercased().last, "sßxz".contains(last) {
            return "Tasche von \(who)"
        }
        return "\(who)s Tasche"
    }
}

enum BagPlace {
    static func current(_ engine: GoobyEngine) -> PlaceDef? {
        if let run = engine.todaysRun(), let place = engine.catalog.placesByID[run.placeID] {
            return place
        }
        let claimed = engine.all(AdventureRun.self)
            .filter { $0.status == "claimed" }
            .sorted { ($0.claimedAt ?? .distantPast) > ($1.claimedAt ?? .distantPast) }
        if let id = claimed.first?.placeID, let place = engine.catalog.placesByID[id] {
            return place
        }
        return engine.catalog.places.first { $0.unlockAfterAdventures == 0 } ?? engine.catalog.places.first
    }
}
