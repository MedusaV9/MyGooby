import SwiftUI

enum QuestIconKind: String {
    case adventure
    case clothing
    case decoration
    case micropet
    case location
    case friendship
    case energy

    var tile: Color {
        switch self {
        case .adventure: Color(hex: 0xFD8C60)
        case .clothing: Color(hex: 0x9645FB)
        case .decoration: Color(hex: 0xFDCC4E)
        case .micropet: Color(hex: 0x7BB65C)
        case .location: Color(hex: 0x3CCDFC)
        case .friendship: Color(hex: 0xEC4998)
        case .energy: Color(hex: 0xFD8C60)
        }
    }
}

struct QuestIconTile: View {
    var kind: QuestIconKind

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(roundedRect: rect, cornerRadius: 18), with: .color(kind.tile))
            var ink = context
            switch kind {
            case .adventure: QuestGlyphs.bunnyFace(&ink)
            case .clothing: QuestGlyphs.shirt(&ink)
            case .decoration: QuestGlyphs.birdhouse(&ink)
            case .micropet: QuestGlyphs.drop(&ink)
            case .location: QuestGlyphs.goggles(&ink)
            case .friendship: QuestGlyphs.bunnyHug(&ink)
            case .energy: QuestGlyphs.bolt(&ink)
            }
        }
        .frame(width: 56, height: 56)
        .accessibilityHidden(true)
    }
}

/// Glyphs are drawn on a 56 pt grid. Every glyph sits on a white sticker rim
/// about 3 pt wide with a 1 pt drop, like the tiles in the look reference.
enum QuestGlyphs {
    private struct StickerPart {
        var path: Path
        var rim: CGFloat = 6
        var filled = true
    }

    private static let cream = Color(hex: 0xFFF3E3)
    private static let creamShade = Color(hex: 0xF6E2CB)
    private static let creamLight = Color(hex: 0xFFF5E8)
    private static let earPink = Color(hex: 0xFFB7C8)
    private static let eyeBrown = Color(hex: 0x4A3428)
    private static let cheek = Color(hex: 0xFF9C9C)
    private static let nose = Color(hex: 0xF08CA0)
    private static let mouth = Color(hex: 0xC9606F)

    static func bolt(_ context: inout GraphicsContext) {
        var shape = Path()
        shape.move(to: pt(31.5, 11))
        shape.addLine(to: pt(18.2, 29.6))
        shape.addLine(to: pt(26.4, 29.6))
        shape.addLine(to: pt(23.4, 45))
        shape.addLine(to: pt(39.8, 24.2))
        shape.addLine(to: pt(30.4, 24.2))
        shape.closeSubpath()
        sticker(&context, [StickerPart(path: shape, rim: 5.2)])
        context.fill(shape, with: .color(Color(hex: 0xFFE27A)))
        context.drawLayer { layer in
            layer.clip(to: shape)
            layer.fill(Path(CGRect(x: 29, y: 12, width: 12, height: 34)), with: .color(Color(hex: 0xF0B429)))
        }
    }

    static func bunnyFace(_ context: inout GraphicsContext) {
        let earL = ellipse(21.4, 17.6, 4.6, 7.6, tilt: -12)
        let earR = ellipse(34.6, 17.6, 4.6, 7.6, tilt: 12)
        let head = ellipse(28, 31.6, 14.6, 13.2)
        sticker(&context, [StickerPart(path: earL), StickerPart(path: earR), StickerPart(path: head)])
        context.fill(earL, with: .color(cream))
        context.fill(earR, with: .color(cream))
        context.fill(ellipse(21.4, 18.4, 2.1, 5, tilt: -12), with: .color(earPink))
        context.fill(ellipse(34.6, 18.4, 2.1, 5, tilt: 12), with: .color(earPink))
        context.fill(head, with: .color(creamShade))
        context.fill(ellipse(28, 33, 13.4, 11.6), with: .color(creamLight))
        line(&context, Color(hex: 0xFFFDF8), 1.5) { path in
            path.move(to: pt(18.6, 25.4))
            path.addQuadCurve(to: pt(27, 20), control: pt(21.8, 20.6))
        }
        for x in [22.2, 33.8] {
            context.fill(ellipse(x, 30.6, 2.3, 2.8), with: .color(eyeBrown))
            context.fill(ellipse(x + 0.7, 29.6, 0.95, 0.95), with: .color(.white))
            context.fill(ellipse(x - 0.5, 31.7, 0.45, 0.45), with: .color(.white))
        }
        context.fill(ellipse(18.2, 35.4, 3, 2.2), with: .color(cheek))
        context.fill(ellipse(37.8, 35.4, 3, 2.2), with: .color(cheek))
        context.fill(ellipse(28, 33.6, 1.3, 0.9), with: .color(nose))
        line(&context, mouth, 1.15) { path in
            path.move(to: pt(25.6, 35.4))
            path.addQuadCurve(to: pt(30.4, 35.4), control: pt(28, 38.2))
        }
    }

    static func bunnyHug(_ context: inout GraphicsContext) {
        let earL = ellipse(22.4, 13.6, 3.8, 6, tilt: -12)
        let earR = ellipse(33.6, 13.6, 3.8, 6, tilt: 12)
        let head = ellipse(28, 24.4, 12, 10.6)
        let body = Path(roundedRect: CGRect(x: 14.4, y: 31.4, width: 27.2, height: 13.4), cornerRadius: 6.4)
        sticker(&context, [StickerPart(path: earL), StickerPart(path: earR), StickerPart(path: head), StickerPart(path: body)])
        context.fill(earL, with: .color(cream))
        context.fill(earR, with: .color(cream))
        context.fill(body, with: .color(creamShade))
        context.fill(ellipse(22.4, 14.2, 1.7, 3.8, tilt: -12), with: .color(earPink))
        context.fill(ellipse(33.6, 14.2, 1.7, 3.8, tilt: 12), with: .color(earPink))
        context.fill(head, with: .color(creamShade))
        context.fill(ellipse(28, 25.4, 11, 9.4), with: .color(creamLight))
        for x in [23.4, 32.6] {
            context.fill(ellipse(x, 23.6, 1.9, 2.3), with: .color(eyeBrown))
            context.fill(ellipse(x + 0.6, 22.8, 0.8, 0.8), with: .color(.white))
        }
        context.fill(ellipse(20, 27.4, 2.4, 1.8), with: .color(cheek))
        context.fill(ellipse(36, 27.4, 2.4, 1.8), with: .color(cheek))
        context.fill(ellipse(28, 26, 1.1, 0.75), with: .color(nose))
        line(&context, mouth, 1) { path in
            path.move(to: pt(26.1, 27.4))
            path.addQuadCurve(to: pt(29.9, 27.4), control: pt(28, 29.4))
        }
        let heart = heartPath()
        context.fill(heart, with: .color(Color(hex: 0xE3221F)))
        context.drawLayer { layer in
            layer.clip(to: heart)
            var shade = Path()
            shade.move(to: pt(28, 44.4))
            shade.addLine(to: pt(36, 34))
            shade.addLine(to: pt(36, 46))
            shade.closeSubpath()
            shade.move(to: pt(30, 41))
            shade.addCurve(to: pt(34.8, 33.4), control1: pt(33, 38.4), control2: pt(34.6, 36))
            shade.addLine(to: pt(37, 33))
            shade.addLine(to: pt(37, 44))
            shade.closeSubpath()
            layer.fill(shade, with: .color(Color(hex: 0xC61A1A)))
        }
        line(&context, Color.white.opacity(0.9), 1.2) { path in
            path.move(to: pt(22.6, 34))
            path.addQuadCurve(to: pt(24.9, 32.1), control: pt(23.2, 32.4))
        }
        context.fill(ellipse(20.8, 37.6, 2.4, 2), with: .color(creamLight))
        context.fill(ellipse(35.2, 37.6, 2.4, 2), with: .color(creamLight))
    }

    static func shirt(_ context: inout GraphicsContext) {
        var cloth = Path()
        cloth.move(to: pt(23.4, 14))
        cloth.addQuadCurve(to: pt(32.6, 14), control: pt(28, 18.2))
        cloth.addLine(to: pt(39.6, 14.4))
        cloth.addQuadCurve(to: pt(43.4, 16.8), control: pt(42.2, 14.8))
        cloth.addLine(to: pt(44.4, 22.2))
        cloth.addQuadCurve(to: pt(43.2, 24), control: pt(44.6, 23.6))
        cloth.addLine(to: pt(39.8, 25))
        cloth.addLine(to: pt(39.8, 40.4))
        cloth.addQuadCurve(to: pt(37.6, 42.6), control: pt(39.8, 42.6))
        cloth.addLine(to: pt(18.4, 42.6))
        cloth.addQuadCurve(to: pt(16.2, 40.4), control: pt(16.2, 42.6))
        cloth.addLine(to: pt(16.2, 25))
        cloth.addLine(to: pt(12.8, 24))
        cloth.addQuadCurve(to: pt(11.6, 22.2), control: pt(11.4, 23.6))
        cloth.addLine(to: pt(12.6, 16.8))
        cloth.addQuadCurve(to: pt(16.4, 14.4), control: pt(13.8, 14.8))
        cloth.closeSubpath()
        sticker(&context, [StickerPart(path: cloth)])
        context.fill(cloth, with: .color(Color(hex: 0x3C88C2)))
        context.drawLayer { layer in
            layer.clip(to: cloth)
            let cuff = Color(hex: 0x64AAE1)
            line(&layer, cuff, 3.4) { path in
                path.move(to: pt(16.4, 14.4))
                path.addQuadCurve(to: pt(12.6, 16.8), control: pt(13.8, 14.8))
                path.addLine(to: pt(11.6, 22.2))
                path.addQuadCurve(to: pt(12.8, 24), control: pt(11.4, 23.6))
            }
            line(&layer, cuff, 3.4) { path in
                path.move(to: pt(39.6, 14.4))
                path.addQuadCurve(to: pt(43.4, 16.8), control: pt(42.2, 14.8))
                path.addLine(to: pt(44.4, 22.2))
                path.addQuadCurve(to: pt(43.2, 24), control: pt(44.6, 23.6))
            }
            line(&layer, Color(hex: 0x6AB2E6), 3.8) { path in
                path.move(to: pt(23.4, 14))
                path.addQuadCurve(to: pt(32.6, 14), control: pt(28, 18.2))
            }
            layer.fill(Path(CGRect(x: 14, y: 40.6, width: 28, height: 3)), with: .color(Color(hex: 0x3479B2)))
            let fold = Color(hex: 0x2F71A8)
            line(&layer, fold, 1.2) { path in
                path.move(to: pt(17.8, 26))
                path.addQuadCurve(to: pt(18.9, 31.8), control: pt(19.3, 28.6))
                path.move(to: pt(38.2, 26))
                path.addQuadCurve(to: pt(37.1, 31.8), control: pt(36.7, 28.6))
            }
            line(&layer, Color(hex: 0x3479B2), 1.1) { path in
                path.move(to: pt(24.4, 37.6))
                path.addQuadCurve(to: pt(31, 37.4), control: pt(27.6, 38.9))
            }
        }
    }

    static func birdhouse(_ context: inout GraphicsContext) {
        var roof = Path()
        roof.move(to: pt(14.6, 23.6))
        roof.addLine(to: pt(28, 12.8))
        roof.addLine(to: pt(41.4, 23.6))
        let house = polygon([pt(18.2, 23.8), pt(28, 15.6), pt(37.8, 23.8), pt(38.6, 37.2), pt(17.4, 37.2)])
        let perch = Path(roundedRect: CGRect(x: 16.4, y: 36.6, width: 23.2, height: 3.2), cornerRadius: 1.2)
        let stem = Path(roundedRect: CGRect(x: 26.1, y: 39.4, width: 3.8, height: 4.8), cornerRadius: 0.9)
        sticker(&context, [
            StickerPart(path: roof, rim: 8.8, filled: false),
            StickerPart(path: house),
            StickerPart(path: perch),
            StickerPart(path: stem)
        ])
        context.fill(house, with: .color(Color(hex: 0xFDC867)))
        context.fill(polygon([pt(33.4, 19.9), pt(37.8, 23.8), pt(38.6, 37.2), pt(33.8, 37.2)]), with: .color(Color(hex: 0xF2B852)))
        context.fill(polygon([pt(18.2, 23.8), pt(20, 22.3), pt(19.3, 37.2), pt(17.4, 37.2)]), with: .color(Color(hex: 0xFFDD9A)))
        context.fill(ellipse(28, 29.2, 4.9, 4.9), with: .color(Color(hex: 0x555866)))
        line(&context, Color(hex: 0x6D7080), 1) { path in
            path.move(to: pt(24.6, 27.4))
            path.addQuadCurve(to: pt(28.6, 24.5), control: pt(26, 25))
        }
        context.fill(stem, with: .color(Color(hex: 0xA26B4B)))
        context.fill(perch, with: .color(Color(hex: 0xB47D4C)))
        context.fill(Path(roundedRect: CGRect(x: 17.2, y: 36.9, width: 21.6, height: 0.9), cornerRadius: 0.45), with: .color(Color(hex: 0xCD9862)))
        line(&context, Color(hex: 0xE25E59), 2.8, path: roof)
        line(&context, Color(hex: 0xF08A80), 0.8) { path in
            path.move(to: pt(15.6, 22.2))
            path.addLine(to: pt(28, 12.2))
            path.addLine(to: pt(40.4, 22.2))
        }
    }

    static func drop(_ context: inout GraphicsContext) {
        var egg = Path()
        egg.move(to: pt(28, 15.2))
        egg.addCurve(to: pt(38.2, 30), control1: pt(33.6, 15.2), control2: pt(38.2, 23.4))
        egg.addCurve(to: pt(28, 39.4), control1: pt(38.2, 35.6), control2: pt(33.8, 39.4))
        egg.addCurve(to: pt(17.8, 30), control1: pt(22.2, 39.4), control2: pt(17.8, 35.6))
        egg.addCurve(to: pt(28, 15.2), control1: pt(17.8, 23.4), control2: pt(22.4, 15.2))
        egg.closeSubpath()
        sticker(&context, [StickerPart(path: egg, rim: 5.4)])
        context.fill(egg, with: .color(Color(hex: 0xD4FAFC)))
        context.drawLayer { layer in
            layer.clip(to: egg)
            var swirl = Path()
            swirl.move(to: pt(21.4, 21))
            swirl.addCurve(to: pt(22.6, 31.2), control1: pt(19.4, 25), control2: pt(19.6, 29.6))
            swirl.addCurve(to: pt(24.4, 27.6), control1: pt(25, 32.4), control2: pt(26, 29.6))
            swirl.addCurve(to: pt(21.4, 21), control1: pt(22.8, 25.6), control2: pt(23.2, 22.6))
            swirl.closeSubpath()
            swirl.move(to: pt(28.6, 16.2))
            swirl.addCurve(to: pt(30.6, 23.6), control1: pt(31.6, 17.8), control2: pt(32.4, 21.2))
            swirl.addCurve(to: pt(32.4, 29.4), control1: pt(29, 25.8), control2: pt(29.6, 28.4))
            swirl.addCurve(to: pt(33.6, 36), control1: pt(34.6, 30.2), control2: pt(35.4, 33.6))
            swirl.addLine(to: pt(31, 37.6))
            swirl.addCurve(to: pt(29, 32), control1: pt(32.4, 35), control2: pt(31.2, 32.8))
            swirl.addCurve(to: pt(27.4, 24.8), control1: pt(26.2, 31), control2: pt(25.6, 27.2))
            swirl.addCurve(to: pt(26.8, 17.2), control1: pt(29, 22.6), control2: pt(28.8, 19.4))
            swirl.closeSubpath()
            swirl.move(to: pt(35.4, 31.2))
            swirl.addCurve(to: pt(34.2, 37.6), control1: pt(37, 33), control2: pt(36.6, 36))
            swirl.addCurve(to: pt(35.4, 31.2), control1: pt(34.6, 35.4), control2: pt(34.6, 33.2))
            swirl.closeSubpath()
            layer.fill(swirl, with: .color(Color(hex: 0x8DE4F6)))
            line(&layer, Color(hex: 0xB6EEFA), 0.9) { path in
                path.move(to: pt(30.4, 18))
                path.addCurve(to: pt(30.4, 22.8), control1: pt(31.6, 19.4), control2: pt(31.6, 21.4))
            }
            layer.fill(ellipse(27.4, 38, 8, 2.6), with: .color(Color(hex: 0xF4FFF6).opacity(0.9)))
        }
        line(&context, .white, 1.9) { path in
            path.move(to: pt(21.8, 23.8))
            path.addCurve(to: pt(25.8, 17.8), control1: pt(22.4, 21), control2: pt(24, 18.8))
        }
        context.fill(ellipse(21.5, 26.6, 0.95, 0.95), with: .color(.white))
    }

    static func goggles(_ context: inout GraphicsContext) {
        var dome = Path()
        dome.move(to: pt(14.4, 30))
        dome.addCurve(to: pt(28, 12.6), control1: pt(14.4, 19.4), control2: pt(20.6, 12.6))
        dome.addCurve(to: pt(41.6, 30), control1: pt(35.4, 12.6), control2: pt(41.6, 19.4))
        dome.closeSubpath()
        let rim = Path(roundedRect: CGRect(x: 13.2, y: 28.2, width: 29.6, height: 2.8), cornerRadius: 1.4)
        let strapL = Path(roundedRect: CGRect(x: 13.6, y: 27, width: 3.6, height: 16.8), cornerRadius: 1.8)
        let strapR = Path(roundedRect: CGRect(x: 38.8, y: 27, width: 3.6, height: 16.8), cornerRadius: 1.8)
        sticker(&context, [StickerPart(path: dome), StickerPart(path: rim), StickerPart(path: strapL), StickerPart(path: strapR)])
        let strap = Color(hex: 0x71443D)
        context.fill(strapL, with: .color(strap))
        context.fill(strapR, with: .color(strap))
        for x in [14.3, 39.5] {
            context.fill(Path(roundedRect: CGRect(x: x, y: 31, width: 0.9, height: 11.4), cornerRadius: 0.45), with: .color(Color(hex: 0x8E5C4E)))
        }
        context.fill(dome, with: .color(Color(hex: 0xAE7749)))
        line(&context, Color(hex: 0xC99566), 1.8) { path in
            path.move(to: pt(19.4, 18.8))
            path.addCurve(to: pt(27, 14.2), control1: pt(21.2, 15.9), control2: pt(24, 14.4))
        }
        context.drawLayer { layer in
            layer.clip(to: dome)
            layer.fill(Path(CGRect(x: 13, y: 20.4, width: 4.6, height: 9)), with: .color(Color(hex: 0x5C3637)))
            layer.fill(Path(CGRect(x: 38.4, y: 20.4, width: 4.6, height: 9)), with: .color(Color(hex: 0x5C3637)))
        }
        context.fill(rim, with: .color(Color(hex: 0xD8B18C)))
        context.fill(Path(roundedRect: CGRect(x: 14, y: 28.4, width: 28, height: 0.8), cornerRadius: 0.4), with: .color(Color(hex: 0xE9CCAA)))

        let frame = Color(hex: 0x6E4339)
        var lens = Path()
        lens.move(to: pt(16.4, 22.6))
        lens.addQuadCurve(to: pt(19.2, 19.8), control: pt(16.2, 19.8))
        lens.addLine(to: pt(25.8, 19.8))
        lens.addQuadCurve(to: pt(27.8, 22.4), control: pt(28, 19.8))
        lens.addQuadCurve(to: pt(23.8, 29.4), control: pt(27.4, 27.2))
        lens.addQuadCurve(to: pt(20.8, 29.6), control: pt(22.4, 30.2))
        lens.addQuadCurve(to: pt(16.4, 22.6), control: pt(16.8, 28))
        lens.closeSubpath()
        var glass = Path()
        glass.move(to: pt(18, 22.8))
        glass.addQuadCurve(to: pt(19.6, 21.4), control: pt(17.9, 21.4))
        glass.addLine(to: pt(25.4, 21.4))
        glass.addQuadCurve(to: pt(26.3, 22.6), control: pt(26.4, 21.4))
        glass.addQuadCurve(to: pt(23.2, 27.9), control: pt(26, 26.4))
        glass.addQuadCurve(to: pt(21.2, 28), control: pt(22.2, 28.4))
        glass.addQuadCurve(to: pt(18, 22.8), control: pt(18.3, 26.8))
        glass.closeSubpath()
        let mirror = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 56, ty: 0)
        context.fill(lens, with: .color(frame))
        context.fill(lens.applying(mirror), with: .color(frame))
        context.fill(Path(CGRect(x: 26.6, y: 21.2, width: 2.8, height: 2.8)), with: .color(frame))
        var glasses = glass
        glasses.addPath(glass.applying(mirror))
        context.fill(glasses, with: .color(Color(hex: 0x76B5CE)))
        context.drawLayer { layer in
            layer.clip(to: glasses)
            layer.fill(Path(CGRect(x: 17, y: 21, width: 22, height: 2.2)), with: .color(Color(hex: 0x9CD2E7)))
        }
        line(&context, Color.white.opacity(0.75), 1) { path in
            path.move(to: pt(20.4, 25.4))
            path.addLine(to: pt(23, 22.8))
            path.move(to: pt(31.8, 25.4))
            path.addLine(to: pt(34.4, 22.8))
        }
    }

    private static func sticker(_ context: inout GraphicsContext, _ parts: [StickerPart]) {
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: Color.black.opacity(0.13), radius: 0.6, x: 0, y: 1))
            for part in parts {
                layer.stroke(part.path, with: .color(.white), style: StrokeStyle(lineWidth: part.rim, lineCap: .round, lineJoin: .round))
                if part.filled {
                    layer.fill(part.path, with: .color(.white))
                }
            }
        }
    }

    private static func heartPath() -> Path {
        var path = Path()
        path.move(to: pt(28, 44.4))
        path.addCurve(to: pt(20.4, 34.8), control1: pt(22, 40.6), control2: pt(20.4, 37.6))
        path.addCurve(to: pt(24.4, 30.6), control1: pt(20.4, 32.2), control2: pt(22.4, 30.6))
        path.addCurve(to: pt(28, 32.8), control1: pt(26, 30.6), control2: pt(27.2, 31.4))
        path.addCurve(to: pt(31.6, 30.6), control1: pt(28.8, 31.4), control2: pt(30, 30.6))
        path.addCurve(to: pt(35.6, 34.8), control1: pt(33.6, 30.6), control2: pt(35.6, 32.2))
        path.addCurve(to: pt(28, 44.4), control1: pt(35.6, 37.6), control2: pt(34, 40.6))
        path.closeSubpath()
        return path
    }

    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }

    private static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, tilt degrees: CGFloat = 0) -> Path {
        let oval = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        guard degrees != 0 else { return oval }
        let turn = CGAffineTransform(translationX: cx, y: cy)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -cx, y: -cy)
        return oval.applying(turn)
    }

    private static func polygon(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    private static func line(_ context: inout GraphicsContext, _ color: Color, _ width: CGFloat, build: (inout Path) -> Void) {
        var path = Path()
        build(&path)
        line(&context, color, width, path: path)
    }

    private static func line(_ context: inout GraphicsContext, _ color: Color, _ width: CGFloat, path: Path) {
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}
