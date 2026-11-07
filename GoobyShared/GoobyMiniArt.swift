import SwiftUI

/// Gooby's head and ears for widgets, Live Activities and other small surfaces that cannot use
/// the app's full rig (Gooby/Features/Character/GoobyCharacterView.swift is not compiled into the
/// widget extension). Same geometry, fur palettes and face as the rig's still idle pose, drawn in
/// the rig's 320-unit design space and scaled to fit, ears included. No animation: widgets and
/// Live Activities render still frames.
struct GoobyMiniHead: View {
    enum Face: String, Codable, Sendable {
        /// Glossy open eyes, small open smile.
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
            let earLength = 124 * MiniStage.earScale(stage)
            // Bounding box in design units: ear tips down to the chin.
            let top = -34 - earLength * 0.985
            let bottom: CGFloat = 87
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
                .frame(width: 60, height: earLength)
                .rotationEffect(.degrees(-10), anchor: .bottom)
                .offset(x: -44, y: -34 - earLength / 2)
            MiniEar(fur: paint, right: true)
                .frame(width: 60, height: earLength)
                .rotationEffect(.degrees(10), anchor: .bottom)
                .offset(x: 44, y: -34 - earLength / 2)
            head(paint, cheek: cheek)
                .frame(width: 192, height: 166)
                .offset(y: 4)
            MiniFurPart(shape: MiniEarShape(), fur: paint, line: 2, rim: false)
                .frame(width: 13, height: 24)
                .rotationEffect(.degrees(-26))
                .offset(x: -6, y: -82)
            MiniFurPart(shape: MiniEarShape(), fur: paint, line: 2, rim: false)
                .frame(width: 11, height: 20)
                .rotationEffect(.degrees(20))
                .offset(x: 6, y: -82)
            eye.offset(x: -40, y: 10)
            eye.offset(x: 40, y: 10)
            nose.offset(y: 31)
            mouth.offset(y: 44)
        }
    }

    private func head(_ paint: MiniFur, cheek: CGFloat) -> some View {
        ZStack {
            MiniFurPart(shape: MiniBlobShape(widest: 0.56), fur: paint, line: 2.6)
            ZStack {
                MiniCheek(fur: paint, scale: cheek).offset(x: -64, y: 38)
                MiniCheek(fur: paint, scale: cheek).offset(x: 64, y: 38)
            }
            .frame(width: 192, height: 166)
            .clipShape(MiniBlobShape(widest: 0.56))
            Ellipse()
                .fill(EllipticalGradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0)], center: .center, endRadiusFraction: 0.5))
                .frame(width: 74, height: 40)
                .rotationEffect(.degrees(-22))
                .offset(x: -44, y: -46)
        }
    }

    private static let ink = Color(hex: 0x2A2130)
    private static let mouthInk = Color(hex: 0x8C3B52)
    private static let tongue = Color(hex: 0xFF8FA8)

    @ViewBuilder private var eye: some View {
        switch face {
        case .happy:
            MiniArcShape(up: true)
                .stroke(GoobyMiniHead.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 30, height: 13)
                .offset(y: 2)
        case .sleepy:
            MiniArcShape(up: false)
                .stroke(GoobyMiniHead.ink, style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
                .frame(width: 30, height: 9)
                .offset(y: 8)
        case .smile:
            ZStack {
                Ellipse()
                    .fill(EllipticalGradient(
                        stops: [.init(color: Color(hex: 0x54425F), location: 0), .init(color: Color(hex: 0x1C1621), location: 0.8)],
                        center: UnitPoint(x: 0.5, y: 0.88),
                        endRadiusFraction: 0.9
                    ))
                MiniLidShineShape()
                    .stroke(Color(hex: 0xA48EB8).opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                Circle()
                    .fill(Color.white)
                    .frame(width: 17, height: 17)
                    .offset(x: -8, y: -11)
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 7, height: 7)
                    .offset(x: 9, y: 7)
            }
            .frame(width: 44, height: 50)
        }
    }

    private var nose: some View {
        ZStack {
            MiniNoseShape()
                .fill(LinearGradient(colors: [Color(hex: 0xFFA6BF), Color(hex: 0xF07C9C)], startPoint: .top, endPoint: .bottom))
            Ellipse()
                .fill(Color.white.opacity(0.8))
                .frame(width: 5, height: 3)
                .offset(x: -3, y: -2)
        }
        .frame(width: 17, height: 12)
    }

    @ViewBuilder private var mouth: some View {
        switch face {
        case .sleepy:
            MiniArcShape(up: false)
                .stroke(GoobyMiniHead.mouthInk, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 14, height: 4)
        case .happy:
            openMouth(width: 30, height: 20).offset(y: 2)
        case .smile:
            openMouth(width: 20, height: 13)
        }
    }

    private func openMouth(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            MiniMouthShape().fill(GoobyMiniHead.mouthInk)
            Ellipse()
                .fill(GoobyMiniHead.tongue)
                .frame(width: width * 0.6, height: height * 0.55)
                .offset(y: height * 0.3)
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

    static func resolve(_ id: String) -> MiniFur {
        switch id {
        case "fur-peach":
            return MiniFur(body: Color(hex: 0xFFE1C8), shade: Color(hex: 0xF0BE9C), cheek: Color(hex: 0xFFA3BA), innerEar: Color(hex: 0xFFB0C4), light: Color(hex: 0xFFF4EA), outline: Color(hex: 0xD9A27F))
        case "fur-lilac":
            return MiniFur(body: Color(hex: 0xF1E8FF), shade: Color(hex: 0xD9CBF2), cheek: Color(hex: 0xF5AECD), innerEar: Color(hex: 0xF6BBD8), light: Color(hex: 0xFDFBFF), outline: Color(hex: 0xB9A6DD))
        case "fur-mint":
            return MiniFur(body: Color(hex: 0xEEFBF2), shade: Color(hex: 0xCDEBD9), cheek: Color(hex: 0xFFB3C8), innerEar: Color(hex: 0xFFBDD0), light: Color(hex: 0xFBFFFC), outline: Color(hex: 0xA8D2B9))
        case "fur-honey":
            return MiniFur(body: Color(hex: 0xFFEFCF), shade: Color(hex: 0xF0CF95), cheek: Color(hex: 0xFFAFBF), innerEar: Color(hex: 0xFFBACB), light: Color(hex: 0xFFFAEC), outline: Color(hex: 0xD8AE6C))
        case "fur-sky":
            return MiniFur(body: Color(hex: 0xEEF7FF), shade: Color(hex: 0xCFE3F4), cheek: Color(hex: 0xFFB5CB), innerEar: Color(hex: 0xFFBED3), light: Color(hex: 0xFBFDFF), outline: Color(hex: 0xA9C6DE))
        default:
            return MiniFur(body: Color(hex: 0xFFF3E2), shade: Color(hex: 0xF2D5BC), cheek: Color(hex: 0xFFA9C0), innerEar: Color(hex: 0xFFB9CC), light: Color(hex: 0xFFFDF8), outline: Color(hex: 0xDDB797))
        }
    }

    func gradient(center: UnitPoint = UnitPoint(x: 0.38, y: 0.3)) -> EllipticalGradient {
        EllipticalGradient(
            stops: [
                .init(color: light, location: 0),
                .init(color: body, location: 0.42),
                .init(color: shade, location: 1)
            ],
            center: center,
            startRadiusFraction: 0,
            endRadiusFraction: 0.8
        )
    }
}

/// The rig's growth stages: ears grow a little, cheeks shrink a little.
enum MiniStage {
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

// MARK: - Parts

private struct MiniFurPart<S: Shape>: View {
    var shape: S
    var fur: MiniFur
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

private struct MiniEar: View {
    var fur: MiniFur
    var right: Bool

    var body: some View {
        let shape = MiniEarShape()
        ZStack {
            MiniFurPart(shape: shape, fur: fur, center: UnitPoint(x: right ? 0.62 : 0.36, y: 0.22), line: 2.4, rim: false)
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

private struct MiniCheek: View {
    var fur: MiniFur
    var scale: CGFloat

    var body: some View {
        ZStack {
            Ellipse()
                .fill(EllipticalGradient(
                    stops: [
                        .init(color: fur.cheek.opacity(0.8), location: 0),
                        .init(color: fur.cheek.opacity(0.48), location: 0.55),
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
        .frame(width: 56 * scale, height: 38 * scale)
    }
}

// MARK: - Shapes (same paths as the rig)

private struct MiniBlobShape: Shape {
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

private struct MiniEarShape: Shape {
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

private struct MiniLidShineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.minY + rect.height * 0.8))
        path.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.8), control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.99))
        return path
    }
}

private struct MiniNoseShape: Shape {
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

private struct MiniMouthShape: Shape {
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
