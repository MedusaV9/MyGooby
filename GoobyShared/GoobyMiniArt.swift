import SwiftUI

/// Gooby's head and ears for widgets, Live Activities and other small surfaces that cannot use
/// the app's full rig (Gooby/Features/Character/GoobyCharacterView.swift is not compiled into the
/// widget extension). Same geometry, fur palettes and face as the rig's still idle pose, drawn in
/// the rig's 320-unit design space and scaled to fit, ears included. No animation: widgets and
/// Live Activities render still frames.
struct GoobyMiniHead: View {
    enum Face: String, Codable, Sendable {
        /// Glossy open eyes, open smile.
        case smile
        /// "^ ^" eyes, wide laugh.
        case happy
        /// Closed eyes, closed little smile (resting, breathing, asleep).
        case sleepy
    }

    var fur: String = "fur-cream"
    var stage: String = "baby"
    var face: Face = .smile

    var body: some View {
        GeometryReader { geo in
            let unit = min(geo.size.width, geo.size.height)
            let earLength = 118 * MiniStage.earScale(stage)
            // Bounding box in design units: ear tips down to the chin.
            let top = -34 - earLength * 0.99
            let bottom: CGFloat = 88
            let height = bottom - top + 8
            let center = (top + bottom) / 2
            figure(earLength: earLength)
                .frame(width: 320, height: 320)
                .offset(y: -center)
                .scaleEffect(unit / height)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gooby")
    }

    private func figure(earLength: CGFloat) -> some View {
        let paint = MiniFur.resolve(fur)
        let cheek = MiniStage.cheekScale(stage)
        return ZStack {
            MiniEar(fur: paint, right: false)
                .frame(width: 58, height: earLength)
                .rotationEffect(.degrees(-9), anchor: .bottom)
                .offset(x: -42, y: -34 - earLength / 2)
            MiniEar(fur: paint, right: true)
                .frame(width: 58, height: earLength)
                .rotationEffect(.degrees(9), anchor: .bottom)
                .offset(x: 42, y: -34 - earLength / 2)
            MiniFurPart(shape: MiniTuftShape(), fur: paint, center: UnitPoint(x: 0.35, y: 0.3), reach: 0.9, line: 2)
                .frame(width: 13, height: 18)
                .rotationEffect(.degrees(-24), anchor: .bottom)
                .offset(x: -8, y: -83)
            MiniFurPart(shape: MiniTuftShape(), fur: paint, center: UnitPoint(x: 0.35, y: 0.3), reach: 0.9, line: 2)
                .frame(width: 14, height: 22)
                .rotationEffect(.degrees(2), anchor: .bottom)
                .offset(x: 0, y: -85)
            MiniFurPart(shape: MiniTuftShape(), fur: paint, center: UnitPoint(x: 0.35, y: 0.3), reach: 0.9, line: 2)
                .frame(width: 12, height: 16)
                .rotationEffect(.degrees(30), anchor: .bottom)
                .offset(x: 8, y: -83)
            head(paint, cheek: cheek)
                .frame(width: 206, height: 164)
                .offset(y: 6)
            eye.offset(x: -46, y: 16)
            eye.offset(x: 46, y: 16)
            nose.offset(y: 36)
            mouth
        }
    }

    private func head(_ paint: MiniFur, cheek: CGFloat) -> some View {
        let shape = MiniBunShape()
        return ZStack {
            MiniFurPart(shape: shape, fur: paint, center: UnitPoint(x: 0.4, y: 0.3), reach: 0.82, line: 0)
            ZStack {
                MiniCheek(fur: paint, scale: cheek).offset(x: -70, y: 38)
                MiniCheek(fur: paint, scale: cheek).offset(x: 70, y: 38)
            }
            .frame(width: 206, height: 164)
            .clipShape(shape)
            Ellipse()
                .fill(EllipticalGradient(colors: [Color.white.opacity(0.75), Color.white.opacity(0)], center: .center, endRadiusFraction: 0.5))
                .frame(width: 70, height: 36)
                .rotationEffect(.degrees(-20))
                .offset(x: -45, y: -50)
            shape.stroke(paint.outline, lineWidth: 2.4)
        }
    }

    private static let ink = Color(hex: 0x2B1D1B)
    private static let mouthInk = Color(hex: 0x8E3546)
    private static let tongue = Color(hex: 0xF4838F)

    @ViewBuilder private var eye: some View {
        switch face {
        case .happy:
            MiniArcShape(up: true)
                .stroke(GoobyMiniHead.ink, style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
                .frame(width: 34, height: 14)
                .offset(y: 1)
        case .sleepy:
            MiniArcShape(up: false)
                .stroke(GoobyMiniHead.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 32, height: 10)
                .offset(y: 6)
        case .smile:
            ZStack {
                Ellipse()
                    .fill(EllipticalGradient(
                        stops: [.init(color: Color(hex: 0x6A4639), location: 0), .init(color: GoobyMiniHead.ink, location: 0.62)],
                        center: UnitPoint(x: 0.5, y: 0.92),
                        endRadiusFraction: 0.85
                    ))
                Circle()
                    .fill(Color.white)
                    .frame(width: 19, height: 19)
                    .offset(x: -8, y: -12)
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 8.4, height: 8.4)
                    .offset(x: 10, y: 10)
            }
            .frame(width: 46, height: 52)
        }
    }

    private var nose: some View {
        ZStack {
            MiniNoseShape()
                .fill(LinearGradient(colors: [Color(hex: 0xF6A2AE), Color(hex: 0xE07484)], startPoint: .top, endPoint: .bottom))
            Ellipse()
                .fill(Color.white.opacity(0.8))
                .frame(width: 5, height: 3)
                .offset(x: -2, y: -2.5)
        }
        .frame(width: 15, height: 10)
    }

    @ViewBuilder private var mouth: some View {
        switch face {
        case .sleepy:
            MiniArcShape(up: false)
                .stroke(GoobyMiniHead.mouthInk, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 14, height: 5)
                .offset(y: 48)
        case .happy:
            openMouth(width: 34, height: 23).offset(y: 55.5)
        case .smile:
            openMouth(width: 26, height: 17).offset(y: 52.5)
        }
    }

    private func openMouth(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            MiniMouthShape().fill(GoobyMiniHead.mouthInk)
            Ellipse()
                .fill(GoobyMiniHead.tongue)
                .frame(width: width * 0.68, height: height * 0.8)
                .offset(y: height * 0.35)
        }
        .clipShape(MiniMouthShape())
        .frame(width: width, height: height)
    }
}

// MARK: - Paint and stage

/// The rig's fur palettes (`FurPaint` in the app).
struct MiniFur {
    var body: Color
    var shade: Color
    var cheek: Color
    var innerEar: Color
    var light: Color
    var outline: Color
    var innerLight: Color

    static func resolve(_ id: String) -> MiniFur {
        switch id {
        case "fur-peach":
            return MiniFur(body: Color(hex: 0xFFE3CD), shade: Color(hex: 0xF4C6A6), cheek: Color(hex: 0xFF9AAE), innerEar: Color(hex: 0xFFAFC0), light: Color(hex: 0xFFF5EC), outline: Color(hex: 0xDDA582), innerLight: Color(hex: 0xFFD3DD))
        case "fur-lilac":
            return MiniFur(body: Color(hex: 0xF0E7FF), shade: Color(hex: 0xDACCF3), cheek: Color(hex: 0xF5A6C9), innerEar: Color(hex: 0xF6B9D6), light: Color(hex: 0xFDFBFF), outline: Color(hex: 0xB8A5DC), innerLight: Color(hex: 0xFCD9EA))
        case "fur-mint":
            return MiniFur(body: Color(hex: 0xEBF8EF), shade: Color(hex: 0xCBE8D6), cheek: Color(hex: 0xFFA9BF), innerEar: Color(hex: 0xFFBCCF), light: Color(hex: 0xFBFFFC), outline: Color(hex: 0xA6CFB6), innerLight: Color(hex: 0xFFDCE6))
        case "fur-honey":
            return MiniFur(body: Color(hex: 0xFFEDC9), shade: Color(hex: 0xF0CF94), cheek: Color(hex: 0xFFA6B8), innerEar: Color(hex: 0xFFB8C8), light: Color(hex: 0xFFFAEC), outline: Color(hex: 0xD6AA66), innerLight: Color(hex: 0xFFDAE2))
        case "fur-sky":
            return MiniFur(body: Color(hex: 0xECF5FF), shade: Color(hex: 0xCCE0F3), cheek: Color(hex: 0xFFAAC4), innerEar: Color(hex: 0xFFBCD1), light: Color(hex: 0xFBFDFF), outline: Color(hex: 0xA6C3DC), innerLight: Color(hex: 0xFFDCE7))
        default:
            return MiniFur(body: Color(hex: 0xF8ECDA), shade: Color(hex: 0xEDD8BA), cheek: Color(hex: 0xF7A1A5), innerEar: Color(hex: 0xF5B8B4), light: Color(hex: 0xFFFBF3), outline: Color(hex: 0xDCBE98), innerLight: Color(hex: 0xFBD9D5))
        }
    }

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

/// The rig's growth stages: ears grow a little, cheeks shrink a little.
enum MiniStage {
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

// MARK: - Parts

private struct MiniFurPart<S: Shape>: View {
    var shape: S
    var fur: MiniFur
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

private struct MiniEar: View {
    var fur: MiniFur
    var right: Bool

    var body: some View {
        let shape = MiniEarShape()
        ZStack {
            MiniFurPart(shape: shape, fur: fur, center: UnitPoint(x: right ? 0.64 : 0.36, y: 0.2), reach: 0.9)
            shape
                .fill(LinearGradient(stops: [.init(color: fur.innerLight, location: 0), .init(color: fur.innerEar, location: 0.55)], startPoint: .top, endPoint: .bottom))
                .scaleEffect(x: 0.58, y: 0.8, anchor: UnitPoint(x: 0.5, y: 0.6))
        }
    }
}

private struct MiniCheek: View {
    var fur: MiniFur
    var scale: CGFloat

    var body: some View {
        Ellipse()
            .fill(EllipticalGradient(
                stops: [
                    .init(color: fur.cheek.opacity(0.85), location: 0),
                    .init(color: fur.cheek.opacity(0.53), location: 0.5),
                    .init(color: fur.cheek.opacity(0), location: 1)
                ],
                center: .center,
                endRadiusFraction: 0.5
            ))
            .frame(width: 60 * scale, height: 36 * scale)
    }
}

// MARK: - Shapes (same paths as the rig)

private struct MiniBunShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        let widest: CGFloat = 0.58, top: CGFloat = 0.6, sideUp: CGFloat = 0.56, sideDown: CGFloat = 0.6, bottom: CGFloat = 0.7
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

private struct MiniEarShape: Shape {
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

private struct MiniTuftShape: Shape {
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

/// "^" (up) or "‿" (down) arch: happy and closed eyes, the sleepy mouth.
private struct MiniArcShape: Shape {
    var up: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if up {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY - rect.height))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 2 - rect.minY))
        }
        return path
    }
}

private struct MiniNoseShape: Shape {
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

private struct MiniMouthShape: Shape {
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
