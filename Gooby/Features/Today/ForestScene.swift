import SwiftUI

struct ForestScene: View {
    var reduceMotion: Bool
    var showHearts: Bool
    var pet: () -> Void

    var body: some View {
        ZStack {
            HomePalette.sky
            Ellipse().fill(HomePalette.moon).frame(width: 68, height: 68).position(x: 58, y: 198)
            Ellipse().fill(Color(hex: 0xB7D36A)).frame(width: 220, height: 90).position(x: 330, y: 228)
            Ellipse().fill(Color(hex: 0x8FB85A)).frame(width: 200, height: 78).position(x: 70, y: 248)
            Ellipse().fill(Color(hex: 0x7EAF55)).frame(width: 280, height: 86).position(x: 200, y: 286)

            pine(width: 92, height: 150, x: 292, y: 188, color: HomePalette.pineDeep)
            pine(width: 78, height: 128, x: 362, y: 210, color: HomePalette.pine)
            pine(width: 64, height: 110, x: 248, y: 214, color: HomePalette.pine)
            pine(width: 46, height: 78, x: 318, y: 248, color: Color(hex: 0x2F8A55))

            Capsule().fill(HomePalette.trunk).frame(width: 26, height: 210).position(x: 46, y: 236)
            Capsule().fill(HomePalette.trunkDeep.opacity(0.45)).frame(width: 8, height: 190).position(x: 54, y: 240)
            Circle().fill(Color(hex: 0x6B3E28)).frame(width: 22, height: 26).position(x: 42, y: 196)
            Circle().fill(HomePalette.moon.opacity(0.9)).frame(width: 10, height: 10).position(x: 42, y: 198)

            Capsule().fill(HomePalette.birch).frame(width: 16, height: 176).position(x: 108, y: 246)
            Capsule().fill(HomePalette.birch).frame(width: 14, height: 160).position(x: 126, y: 258)
            birchMarks(x: 108, y: 210)
            birchMarks(x: 126, y: 230)

            Capsule().fill(HomePalette.trunk).frame(width: 22, height: 200).position(x: 164, y: 250)
            Capsule().fill(HomePalette.trunkDeep.opacity(0.4)).frame(width: 7, height: 180).position(x: 171, y: 254)
            Capsule().fill(HomePalette.trunk).frame(width: 14, height: 70).rotationEffect(.degrees(-38)).position(x: 132, y: 188)

            Capsule().fill(HomePalette.trunk).frame(width: 42, height: 270).position(x: 228, y: 230)
            Capsule().fill(HomePalette.trunkDeep.opacity(0.55)).frame(width: 12, height: 250).position(x: 240, y: 234)

            canopy(150, x: 78, y: 78, HomePalette.canopyDeep)
            canopy(110, x: 18, y: 118, HomePalette.canopyShade)
            canopy(100, x: 128, y: 96, HomePalette.canopyDeep)
            canopy(70, x: 150, y: 132, HomePalette.canopyLeaf)

            canopy(210, x: 250, y: 62, HomePalette.canopy)
            canopy(160, x: 188, y: 96, HomePalette.canopy)
            canopy(150, x: 318, y: 78, Color(hex: 0xB5C42A))
            canopy(86, x: 168, y: 128, HomePalette.canopyLeaf)
            canopy(70, x: 300, y: 130, HomePalette.canopyShade)
            canopy(64, x: 86, y: 48, HomePalette.canopyDeep)
            canopy(72, x: 240, y: 78, HomePalette.canopy)
            canopy(48, x: 330, y: 70, Color(hex: 0xB5C42A))

            Ellipse().fill(HomePalette.grassDark).frame(width: 120, height: 46).position(x: 70, y: 332)
            Ellipse().fill(HomePalette.pineDeep).frame(width: 90, height: 40).position(x: 150, y: 338)
            Ellipse().fill(HomePalette.grassDark).frame(width: 130, height: 48).position(x: 330, y: 336)
            Ellipse().fill(HomePalette.meadow).frame(width: 80, height: 28).position(x: 250, y: 348)
            bush(56, x: 86, y: 328, HomePalette.grassDark)
            bush(40, x: 62, y: 340, HomePalette.pine)
            bush(48, x: 196, y: 336, HomePalette.pineDeep)
            bush(36, x: 348, y: 322, Color(hex: 0x3E8F45))

            flower(HomePalette.flowerRed, x: 96, y: 318)
            flower(HomePalette.flowerRed, x: 128, y: 308)
            flower(HomePalette.flowerYellow, x: 108, y: 336)
            flower(HomePalette.flowerRed, x: 48, y: 348)
            flower(Color(hex: 0xF2A0C0), x: 236, y: 348)
            flower(HomePalette.flowerYellow, x: 332, y: 352)
            tulip(x: 196, y: 300)
            tulip(x: 214, y: 312)
            tuft(x: 24, y: 360)
            tuft(x: 150, y: 358)
            tuft(x: 360, y: 364)

            Ellipse().fill(HomePalette.rock).frame(width: 92, height: 36).position(x: 300, y: 328)
            Ellipse().fill(HomePalette.rockDeep).frame(width: 70, height: 18).position(x: 304, y: 338)
            Ellipse().fill(HomePalette.rock).frame(width: 46, height: 22).position(x: 36, y: 368)
            Ellipse().fill(Color.white.opacity(0.85)).frame(width: 18, height: 14).position(x: 368, y: 372)

            Rectangle().fill(Color(hex: 0x5FA368)).frame(height: 36).position(x: 195, y: 372)
            Rectangle().fill(HomePalette.page).frame(height: 70).position(x: 195, y: 418)

            ForestGooby(reduceMotion: reduceMotion, showHearts: showHearts)
                .frame(width: 150, height: 150)
                .position(x: 168, y: 300)
                .onTapGesture(perform: pet)
        }
        .contentShape(Rectangle())
        .clipped()
    }

    private func canopy(_ size: CGFloat, x: CGFloat, y: CGFloat, _ color: Color) -> some View {
        Circle().fill(color).frame(width: size, height: size).position(x: x, y: y)
    }

    private func pine(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat, color: Color) -> some View {
        Triangle().fill(color).frame(width: width, height: height).position(x: x, y: y)
    }

    private func birchMarks(x: CGFloat, y: CGFloat) -> some View {
        VStack(spacing: 16) {
            Capsule().frame(width: 10, height: 2)
            Capsule().frame(width: 8, height: 2)
            Capsule().frame(width: 11, height: 2)
        }
        .foregroundStyle(Color(hex: 0xC9C3A8))
        .position(x: x, y: y)
    }

    private func flower(_ color: Color, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Capsule().fill(HomePalette.pineDeep).frame(width: 2, height: 16).offset(y: 8)
            ForEach(0..<5, id: \.self) { index in
                Circle().fill(color).frame(width: 7, height: 7)
                    .offset(y: -5)
                    .rotationEffect(.degrees(Double(index) * 72))
            }
            Circle().fill(HomePalette.flowerYellow).frame(width: 5, height: 5)
        }
        .frame(width: 18, height: 28)
        .position(x: x, y: y)
    }

    private func tulip(x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Capsule().fill(HomePalette.pine).frame(width: 2, height: 18).offset(y: 8)
            Ellipse().fill(HomePalette.flowerPink).frame(width: 10, height: 14)
        }
        .position(x: x, y: y)
    }

    private func bush(_ size: CGFloat, x: CGFloat, y: CGFloat, _ color: Color) -> some View {
        Ellipse().fill(color).frame(width: size, height: size * 0.72).position(x: x, y: y)
    }

    private func tuft(x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Capsule().fill(HomePalette.grassDark).frame(width: 3, height: 14).rotationEffect(.degrees(-18))
            Capsule().fill(HomePalette.pine).frame(width: 3, height: 16)
            Capsule().fill(HomePalette.grassDark).frame(width: 3, height: 13).rotationEffect(.degrees(20))
        }
        .position(x: x, y: y)
    }
}

struct ForestGooby: View {
    var reduceMotion: Bool
    var showHearts: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 24.0, paused: reduceMotion)) { timeline in
            let wave = reduceMotion ? 0 : sin(timeline.date.timeIntervalSinceReferenceDate * 1.7)
            let breath = 1 + 0.02 * wave
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.16))
                    .frame(width: 58, height: 12)
                    .offset(y: 66)
                body(breath: breath)
                feet
                head
                ears(wave: wave)
                face
                paws
                satchel
                    .offset(x: -42, y: 16)
                if showHearts {
                    heart.offset(x: 36, y: -48)
                    heart.offset(x: -20, y: -62).scaleEffect(0.8)
                }
            }
            .offset(y: reduceMotion ? 0 : CGFloat(wave) * -2)
        }
        .accessibilityLabel("Gooby")
    }

    private var satchel: some View {
        ZStack {
            Capsule()
                .fill(HomePalette.satchelDeep)
                .frame(width: 8, height: 36)
                .rotationEffect(.degrees(58))
                .offset(x: 28, y: -8)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HomePalette.satchelDeep)
                .frame(width: 46, height: 52)
                .offset(y: 4)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HomePalette.satchel)
                .frame(width: 46, height: 50)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: 0xE86A64))
                .frame(width: 28, height: 14)
                .offset(y: -10)
        }
    }

    private func body(breath: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(HomePalette.furShade).frame(width: 78, height: 64).offset(x: 4, y: 30)
            Ellipse().fill(HomePalette.fur).frame(width: 78, height: 64).scaleEffect(x: 1, y: breath, anchor: .center).offset(y: 26)
            Ellipse().fill(Color.white.opacity(0.45)).frame(width: 28, height: 16).offset(x: -16, y: 16)
        }
    }

    private var feet: some View {
        ZStack {
            Ellipse().fill(HomePalette.furShade).frame(width: 22, height: 12).offset(x: -16, y: 56)
            Ellipse().fill(HomePalette.fur).frame(width: 22, height: 12).offset(x: -16, y: 54)
            Ellipse().fill(HomePalette.furShade).frame(width: 22, height: 12).offset(x: 16, y: 56)
            Ellipse().fill(HomePalette.fur).frame(width: 22, height: 12).offset(x: 16, y: 54)
        }
    }

    private var head: some View {
        ZStack {
            Circle().fill(HomePalette.furShade).frame(width: 74, height: 70).offset(x: 3, y: -16)
            Circle().fill(HomePalette.fur).frame(width: 74, height: 70).offset(y: -20)
            Ellipse().fill(Color.white.opacity(0.55)).frame(width: 22, height: 12).offset(x: -16, y: -36)
        }
    }

    private func ears(wave: CGFloat) -> some View {
        ZStack {
            ear(tilt: -16 + wave * 4).offset(x: -20, y: -62)
            ear(tilt: 16 - wave * 4).offset(x: 20, y: -62)
        }
    }

    private func ear(tilt: CGFloat) -> some View {
        ZStack {
            Capsule().fill(HomePalette.fur).frame(width: 20, height: 48)
            Capsule().fill(HomePalette.innerEar).frame(width: 10, height: 30).offset(y: 4)
        }
        .rotationEffect(.degrees(tilt))
    }

    private var face: some View {
        ZStack {
            Ellipse().fill(HomePalette.cheek.opacity(0.95)).frame(width: 16, height: 11).offset(x: -22, y: -8)
            Ellipse().fill(HomePalette.cheek.opacity(0.95)).frame(width: 16, height: 11).offset(x: 22, y: -8)
            eye.offset(x: -14, y: -24)
            eye.offset(x: 14, y: -24)
            Ellipse().fill(HomePalette.nose).frame(width: 8, height: 6).offset(y: -10)
            SmileShape()
                .stroke(Color(hex: 0xC46B86), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 16, height: 8)
                .offset(y: -2)
            Ellipse().fill(Color(hex: 0xFF8EAB)).frame(width: 8, height: 5).offset(y: 3)
        }
    }

    private var eye: some View {
        ZStack {
            Ellipse().fill(HomePalette.eye).frame(width: 16, height: 18)
            Ellipse().fill(Color(hex: 0x3A2416)).frame(width: 8, height: 10)
            Circle().fill(Color.white).frame(width: 5, height: 5).offset(x: -3, y: -4)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 2.2, height: 2.2).offset(x: 3, y: 2)
        }
    }

    private var paws: some View {
        ZStack {
            Circle().fill(HomePalette.fur).frame(width: 16, height: 16).overlay(Circle().stroke(HomePalette.furShade, lineWidth: 1))
                .offset(x: -8, y: 18)
            Circle().fill(HomePalette.fur).frame(width: 16, height: 16).overlay(Circle().stroke(HomePalette.furShade, lineWidth: 1))
                .offset(x: 12, y: 16)
        }
    }

    private var heart: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 12))
            .foregroundStyle(Color(hex: 0xFF8FB3))
    }
}
