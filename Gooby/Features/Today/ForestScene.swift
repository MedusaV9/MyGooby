import SwiftUI

struct ForestScene: View {
    var reduceMotion: Bool
    var showHearts: Bool
    var pet: () -> Void

    var body: some View {
        ZStack {
            HomePalette.sky
            hills
            pines
            hollow
            birch
            trunk
            crown
        }
        .overlay(alignment: .bottom) { foreground }
        .contentShape(Rectangle())
        .clipped()
    }

    private var hills: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x8FB85A)).frame(width: 280, height: 90).position(x: 70, y: 250)
            Ellipse().fill(Color(hex: 0x7EAF55)).frame(width: 340, height: 100).position(x: 230, y: 268)
            Ellipse().fill(Color(hex: 0xB7D36A)).frame(width: 220, height: 80).position(x: 340, y: 236)
            Ellipse().fill(Color(hex: 0x6E9A48)).frame(width: 180, height: 64).position(x: 150, y: 286)
            Ellipse().fill(Color(hex: 0x6E9A48)).frame(width: 480, height: 156).position(x: 200, y: 318)
            Ellipse().fill(Color(hex: 0x8FB85A)).frame(width: 260, height: 96).position(x: 60, y: 300)
        }
    }

    private var pines: some View {
        ZStack {
            pine(width: 70, height: 120, x: 300, y: 196, color: HomePalette.pineDeep)
            pine(width: 86, height: 150, x: 348, y: 176, color: HomePalette.pine)
            pine(width: 54, height: 96, x: 262, y: 214, color: Color(hex: 0x2F8A55))
            pine(width: 48, height: 88, x: 378, y: 220, color: HomePalette.pineDeep)
            pine(width: 36, height: 70, x: 214, y: 236, color: Color(hex: 0x3E8F45))
        }
    }

    private var hollow: some View {
        ZStack {
            Circle().fill(HomePalette.moon).frame(width: 54, height: 54).position(x: 28, y: 188)
            Capsule().fill(HomePalette.trunk).frame(width: 30, height: 210).position(x: 36, y: 250)
            Capsule().fill(HomePalette.trunkDeep.opacity(0.45)).frame(width: 8, height: 180).position(x: 46, y: 256)
            Circle().fill(Color(hex: 0x4A2E1C)).frame(width: 20, height: 24).position(x: 32, y: 196)
            Circle().fill(HomePalette.moon).frame(width: 8, height: 8).position(x: 30, y: 194)
        }
    }

    private var birch: some View {
        ZStack {
            Capsule().fill(HomePalette.birch).frame(width: 22, height: 280).position(x: 92, y: 230)
            Capsule().fill(Color(hex: 0xF4F1E4)).frame(width: 8, height: 250).position(x: 86, y: 228)
            birchStripes(x: 92, top: 120, count: 12)
        }
    }

    private var trunk: some View {
        ZStack {
            Capsule().fill(HomePalette.trunk).frame(width: 54, height: 320).position(x: 248, y: 210)
            Capsule().fill(HomePalette.trunkDeep).frame(width: 16, height: 300).position(x: 266, y: 214)
            Capsule().fill(HomePalette.trunk).frame(width: 16, height: 90).rotationEffect(.degrees(-36)).position(x: 196, y: 168)
            Capsule().fill(HomePalette.trunkDeep).frame(width: 8, height: 70).rotationEffect(.degrees(24)).position(x: 286, y: 150)
        }
    }

    private var crown: some View {
        ZStack {
            tuft(58, 40, 188, 62, 0x919944)
            tuft(52, 38, 230, 46, 0xADBC1B)
            tuft(60, 44, 274, 40, 0xB5C42A)
            tuft(48, 36, 312, 62, 0xADBC1B)
            tuft(44, 34, 250, 86, 0x83882E)
            tuft(40, 30, 210, 96, 0xC1C787)
            tuft(42, 32, 292, 92, 0x919944)
            tuft(36, 28, 168, 118, 0x7A9A32)
            tuft(32, 24, 142, 142, 0x8FB84A)
            tuft(28, 22, 118, 162, 0x6E9A32)
            tuft(34, 26, 330, 88, 0xC1C787)
            tuft(36, 28, 206, 58, 0xA3B43A)
            tuft(40, 30, 258, 24, 0xC5CE55)
            tuft(34, 26, 294, 22, 0xADBC1B)
            tuft(30, 24, 176, 78, 0x83882E)
            tuft(26, 20, 338, 48, 0x919944)
            tuft(24, 18, 154, 168, 0xA3B43A)
            tuft(22, 18, 100, 92, 0x7A9A32)
            tuft(26, 20, 124, 78, 0x8FB84A)
            tuft(56, 44, 236, 70, 0x9AA83A)
            tuft(52, 40, 268, 78, 0x7F9A30)
            tuft(48, 36, 300, 74, 0xA8BC45)
            tuft(44, 32, 214, 108, 0x6E8E34)
            tuft(48, 32, 252, 112, 0x8FA63C)
            tuft(40, 30, 288, 108, 0x738C32)
            tuft(32, 24, 188, 128, 0x8FB84A)
            tuft(28, 22, 160, 136, 0x6E9A32)
            tuft(32, 24, 320, 108, 0xA3B43A)
            tuft(36, 28, 246, 52, 0xC1C787)
            tuft(32, 24, 220, 36, 0x83882E)
            tuft(36, 26, 280, 34, 0x919944)
        }
    }

    private var foreground: some View {
        ZStack {
            MeadowShape().fill(Color(hex: 0x5FA368))
            MeadowShape().fill(HomePalette.meadow).offset(y: 18).scaleEffect(x: 1.05, y: 0.72, anchor: .bottom)
            Ellipse().fill(HomePalette.grassDark).frame(width: 90, height: 28).position(x: 70, y: 78)
            Ellipse().fill(HomePalette.pineDeep).frame(width: 70, height: 24).position(x: 300, y: 86)
            rock(x: 318, y: 96, w: 78, h: 30)
            rock(x: 40, y: 118, w: 36, h: 16)
            flower(HomePalette.flowerRed, x: 58, y: 100)
            flower(HomePalette.flowerYellow, x: 86, y: 112)
            flower(HomePalette.flowerPink, x: 210, y: 92)
            flower(HomePalette.flowerRed, x: 236, y: 108)
            flower(HomePalette.flowerYellow, x: 352, y: 118)
            tuftGrass(x: 18, y: 124)
            tuftGrass(x: 140, y: 128)
            tuftGrass(x: 372, y: 126)

            ForestGooby(reduceMotion: reduceMotion, showHearts: showHearts)
                .frame(width: 86, height: 112)
                .position(x: 168, y: 78)
                .onTapGesture(perform: pet)
        }
        .frame(height: 168)
    }

    private func pine(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat, color: Color) -> some View {
        Triangle().fill(color).frame(width: width, height: height).position(x: x, y: y)
    }

    private func tuft(_ width: CGFloat, _ height: CGFloat, _ x: CGFloat, _ y: CGFloat, _ hex: UInt) -> some View {
        Ellipse().fill(Color(hex: hex)).frame(width: width, height: height).position(x: x, y: y)
    }

    private func birchStripes(x: CGFloat, top: CGFloat, count: Int) -> some View {
        ForEach(0..<count, id: \.self) { index in
            Capsule()
                .fill(Color(hex: index % 2 == 0 ? 0x8A7A62 : 0x5C5344))
                .frame(width: index % 3 == 0 ? 16 : 11, height: 3)
                .position(x: x + (index % 2 == 0 ? -1 : 2), y: top + CGFloat(index) * 16)
        }
    }

    private func rock(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(HomePalette.rock).frame(width: w, height: h)
            Ellipse().fill(HomePalette.rockDeep).frame(width: w * 0.72, height: h * 0.45).offset(y: h * 0.18)
        }
        .position(x: x, y: y)
    }

    private func flower(_ color: Color, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Capsule().fill(HomePalette.pineDeep).frame(width: 2, height: 14).offset(y: 7)
            ForEach(0..<5, id: \.self) { index in
                Circle().fill(color).frame(width: 6, height: 6)
                    .offset(y: -4)
                    .rotationEffect(.degrees(Double(index) * 72))
            }
            Circle().fill(HomePalette.flowerYellow).frame(width: 4, height: 4)
        }
        .position(x: x, y: y)
    }

    private func tuftGrass(x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Capsule().fill(HomePalette.grassDark).frame(width: 3, height: 14).rotationEffect(.degrees(-16))
            Capsule().fill(HomePalette.pine).frame(width: 3, height: 16)
            Capsule().fill(HomePalette.grassDark).frame(width: 3, height: 12).rotationEffect(.degrees(18))
        }
        .position(x: x, y: y)
    }
}

struct MeadowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.minY + rect.height * 0.28
        path.move(to: CGPoint(x: rect.minX, y: y + 8))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.25, y: y), control: CGPoint(x: rect.width * 0.12, y: y - 16))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.55, y: y + 6), control: CGPoint(x: rect.width * 0.4, y: y + 18))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.82, y: y - 4), control: CGPoint(x: rect.width * 0.68, y: y - 14))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: y + 10), control: CGPoint(x: rect.width * 0.92, y: y + 8))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ForestGooby: View {
    var reduceMotion: Bool
    var showHearts: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 24.0, paused: reduceMotion)) { timeline in
            let step = reduceMotion ? 0 : sin(timeline.date.timeIntervalSinceReferenceDate * 2.2)
            ZStack {
                Ellipse().fill(Color.black.opacity(0.16)).frame(width: 34, height: 8).offset(y: 50)
                backpack
                leg(angle: -12 - step * 8).offset(x: -7, y: 30)
                leg(angle: 14 + step * 8).offset(x: 8, y: 28)
                torso
                strap
                arm.offset(x: -16, y: 8)
                arm.offset(x: 14, y: 6)
                head
                ears(wave: step)
                face
                if showHearts {
                    heart.offset(x: 24, y: -46)
                    heart.offset(x: -16, y: -54).scaleEffect(0.75)
                }
            }
            .rotationEffect(.degrees(6))
        }
        .accessibilityLabel("Gooby")
    }

    private var backpack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(HomePalette.satchelDeep)
                .frame(width: 24, height: 30)
                .offset(y: 2)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(HomePalette.satchel)
                .frame(width: 24, height: 28)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0xE86A64))
                .frame(width: 14, height: 8)
                .offset(y: -6)
        }
        .offset(x: -18, y: 2)
    }

    private func leg(angle: Double) -> some View {
        ZStack {
            Capsule().fill(HomePalette.furShade).frame(width: 9, height: 22)
            Capsule().fill(HomePalette.fur).frame(width: 9, height: 22).offset(x: -1)
            Ellipse().fill(HomePalette.fur).frame(width: 12, height: 7).offset(y: 12)
        }
        .rotationEffect(.degrees(angle), anchor: .top)
    }

    private var torso: some View {
        ZStack {
            Ellipse().fill(HomePalette.furShade).frame(width: 32, height: 40).offset(x: 2, y: 8)
            Ellipse().fill(HomePalette.fur).frame(width: 32, height: 40).offset(y: 6)
        }
    }

    private var strap: some View {
        Capsule()
            .fill(HomePalette.satchelDeep)
            .frame(width: 4, height: 18)
            .rotationEffect(.degrees(32))
            .offset(x: -8, y: 2)
    }

    private var arm: some View {
        Capsule().fill(HomePalette.fur).frame(width: 8, height: 16)
    }

    private var head: some View {
        ZStack {
            Circle().fill(HomePalette.furShade).frame(width: 36, height: 34).offset(x: 2, y: -20)
            Circle().fill(HomePalette.fur).frame(width: 36, height: 34).offset(y: -22)
        }
    }

    private func ears(wave: Double) -> some View {
        ZStack {
            ear(tilt: -18 + wave * 3).offset(x: -10, y: -46)
            ear(tilt: 16 - wave * 3).offset(x: 12, y: -46)
        }
    }

    private func ear(tilt: Double) -> some View {
        ZStack {
            Capsule().fill(HomePalette.fur).frame(width: 11, height: 28)
            Capsule().fill(HomePalette.innerEar).frame(width: 5, height: 18).offset(y: 3)
        }
        .rotationEffect(.degrees(tilt))
    }

    private var face: some View {
        ZStack {
            Ellipse().fill(HomePalette.cheek).frame(width: 8, height: 5).offset(x: -12, y: -18)
            Ellipse().fill(HomePalette.cheek).frame(width: 8, height: 5).offset(x: 12, y: -18)
            eye.offset(x: -7, y: -24)
            eye.offset(x: 7, y: -24)
            Ellipse().fill(HomePalette.nose).frame(width: 5, height: 3.5).offset(y: -16)
            SmileShape()
                .stroke(Color(hex: 0xC46B86), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                .frame(width: 10, height: 5)
                .offset(y: -12)
        }
    }

    private var eye: some View {
        ZStack {
            Ellipse().fill(HomePalette.eye).frame(width: 7, height: 8)
            Circle().fill(Color.white).frame(width: 2.2, height: 2.2).offset(x: -1.2, y: -1.6)
        }
    }

    private var heart: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 9))
            .foregroundStyle(Color(hex: 0xFF8FB3))
    }
}
