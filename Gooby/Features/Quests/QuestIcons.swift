import SwiftUI

enum QuestIconKind: String {
    case adventure
    case clothing
    case decoration
    case micropet
    case location
    case friendship

    var tile: Color {
        switch self {
        case .adventure: Color(hex: 0xFD8C60)
        case .clothing: Color(hex: 0x9645FB)
        case .decoration: Color(hex: 0xFDCC4E)
        case .micropet: Color(hex: 0x7BB65C)
        case .location: Color(hex: 0x3CCDFC)
        case .friendship: Color(hex: 0xEC4998)
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
            case .adventure: QuestGlyphs.bunny(&ink, bag: true, heart: false)
            case .clothing: QuestGlyphs.shirt(&ink, tile: kind.tile)
            case .decoration: QuestGlyphs.birdhouse(&ink)
            case .micropet: QuestGlyphs.drop(&ink)
            case .location: QuestGlyphs.goggles(&ink)
            case .friendship: QuestGlyphs.bunny(&ink, bag: false, heart: true)
            }
        }
        .frame(width: 56, height: 56)
        .accessibilityHidden(true)
    }
}

enum QuestGlyphs {
    static func bunny(_ context: inout GraphicsContext, bag: Bool, heart: Bool) {
        ear(context: &context, cx: 21, cy: 18, white: true)
        ear(context: &context, cx: 35, cy: 18, white: true)
        ear(context: &context, cx: 21, cy: 18, white: false)
        ear(context: &context, cx: 35, cy: 18, white: false)
        fillEllipse(&context, CGRect(x: 14.2, y: 20, width: 27.6, height: 26), Color.white, outline: 0)
        fillEllipse(&context, CGRect(x: 16.2, y: 21.6, width: 23.6, height: 22.4), Color(hex: 0xFFF6EA), outline: 0)
        fillEllipse(&context, CGRect(x: 17.2, y: 33.2, width: 4.6, height: 3), Color(hex: 0xFFB7C8), outline: 0)
        fillEllipse(&context, CGRect(x: 34.2, y: 33.2, width: 4.6, height: 3), Color(hex: 0xFFB7C8), outline: 0)
        fillEllipse(&context, CGRect(x: 21.2, y: 28.6, width: 4.4, height: 5.2), Color(hex: 0x4A3428), outline: 0)
        fillEllipse(&context, CGRect(x: 30.4, y: 28.6, width: 4.4, height: 5.2), Color(hex: 0x4A3428), outline: 0)
        fillEllipse(&context, CGRect(x: 22.4, y: 29.4, width: 1.5, height: 1.5), Color.white, outline: 0)
        fillEllipse(&context, CGRect(x: 31.6, y: 29.4, width: 1.5, height: 1.5), Color.white, outline: 0)
        fillEllipse(&context, CGRect(x: 26.6, y: 33.4, width: 2.8, height: 1.8), Color(hex: 0xF4A0B5), outline: 0)
        var smile = Path()
        smile.move(to: CGPoint(x: 24.2, y: 35.2))
        smile.addQuadCurve(to: CGPoint(x: 31.8, y: 35.2), control: CGPoint(x: 28, y: 37.6))
        context.stroke(smile, with: .color(Color(hex: 0xE07A8C)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        if bag {
            fillRound(&context, CGRect(x: 36.2, y: 34.5, width: 12, height: 10), 3, Color.white)
            fillRound(&context, CGRect(x: 37.6, y: 35.8, width: 9.2, height: 7.6), 2.2, Color(hex: 0xE4534A))
            fillRound(&context, CGRect(x: 40, y: 33.2, width: 4.4, height: 3.2), 1.4, Color(hex: 0xE4534A))
        }
        if heart {
            heartShape(&context, in: CGRect(x: 20, y: 32, width: 16, height: 14), fill: Color.white, grow: 1.6)
            heartShape(&context, in: CGRect(x: 21.4, y: 33.2, width: 13.2, height: 11.4), fill: Color(hex: 0xE23B4A), grow: 0)
        }
    }

    static func shirt(_ context: inout GraphicsContext, tile: Color) {
        var cloth = Path()
        cloth.addRoundedRect(in: CGRect(x: 18, y: 24, width: 20, height: 18), cornerSize: CGSize(width: 5, height: 5))
        cloth.addEllipse(in: CGRect(x: 8, y: 22, width: 14, height: 11))
        cloth.addEllipse(in: CGRect(x: 34, y: 22, width: 14, height: 11))
        context.stroke(cloth, with: .color(.white), style: StrokeStyle(lineWidth: 5.5, lineJoin: .round))
        context.fill(cloth, with: .color(Color(hex: 0x5EB0E6)))
        fillEllipse(&context, CGRect(x: 23.2, y: 22.4, width: 9.6, height: 7.2), tile, outline: 0)
    }

    static func birdhouse(_ context: inout GraphicsContext) {
        var roof = Path()
        roof.move(to: CGPoint(x: 28, y: 11.5))
        roof.addLine(to: CGPoint(x: 43.2, y: 25.4))
        roof.addLine(to: CGPoint(x: 12.8, y: 25.4))
        roof.closeSubpath()
        let body = Path(roundedRect: CGRect(x: 16.8, y: 23.4, width: 22.4, height: 14.6), cornerRadius: 2.2)
        let bar = Path(roundedRect: CGRect(x: 15.2, y: 36.4, width: 25.6, height: 3.5), cornerRadius: 1.2)
        let stem = Path(roundedRect: CGRect(x: 25.2, y: 38.8, width: 5.6, height: 5.4), cornerRadius: 1.1)
        strokeFill(&context, roof, Color(hex: 0xE45A57), width: 5)
        strokeFill(&context, body, Color(hex: 0xF8C56A), width: 4.4)
        strokeFill(&context, bar, Color(hex: 0xB67A45), width: 3.4)
        strokeFill(&context, stem, Color(hex: 0xB67A45), width: 2.8)
        context.fill(Path(ellipseIn: CGRect(x: 23.4, y: 26, width: 9.2, height: 9.2)), with: .color(Color(hex: 0x585868)))
    }

    static func drop(_ context: inout GraphicsContext) {
        var egg = Path()
        egg.move(to: CGPoint(x: 28, y: 12.6))
        egg.addCurve(to: CGPoint(x: 38.4, y: 28), control1: CGPoint(x: 32.2, y: 14.2), control2: CGPoint(x: 38.2, y: 19.2))
        egg.addCurve(to: CGPoint(x: 28, y: 40.4), control1: CGPoint(x: 38.6, y: 36.8), control2: CGPoint(x: 34.2, y: 40.4))
        egg.addCurve(to: CGPoint(x: 17.6, y: 28), control1: CGPoint(x: 21.8, y: 40.4), control2: CGPoint(x: 17.4, y: 36.8))
        egg.addCurve(to: CGPoint(x: 28, y: 12.6), control1: CGPoint(x: 17.8, y: 19.2), control2: CGPoint(x: 23.8, y: 14.2))
        egg.closeSubpath()
        context.fill(egg, with: .color(.white))
        var pale = Path()
        pale.move(to: CGPoint(x: 28, y: 16))
        pale.addCurve(to: CGPoint(x: 35.4, y: 27.8), control1: CGPoint(x: 31, y: 17.2), control2: CGPoint(x: 35.2, y: 21))
        pale.addCurve(to: CGPoint(x: 28, y: 37.2), control1: CGPoint(x: 35.6, y: 34.4), control2: CGPoint(x: 32.2, y: 37.2))
        pale.addCurve(to: CGPoint(x: 20.6, y: 27.8), control1: CGPoint(x: 23.8, y: 37.2), control2: CGPoint(x: 20.4, y: 34.4))
        pale.addCurve(to: CGPoint(x: 28, y: 16), control1: CGPoint(x: 20.8, y: 21), control2: CGPoint(x: 25, y: 17.2))
        pale.closeSubpath()
        context.fill(pale, with: .color(Color(hex: 0xC5F1FF)))
        context.fill(dropWave(), with: .color(Color(hex: 0x6ECFED)))
        var shine = Path()
        shine.move(to: CGPoint(x: 25.2, y: 20.6))
        shine.addCurve(to: CGPoint(x: 28.4, y: 24.8), control1: CGPoint(x: 28.8, y: 19.6), control2: CGPoint(x: 30.8, y: 22.4))
        context.stroke(shine, with: .color(Color(hex: 0xF4FCFF)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    static func goggles(_ context: inout GraphicsContext) {
        fillRound(&context, CGRect(x: 12.6, y: 26, width: 6.2, height: 14), 2.4, .white)
        fillRound(&context, CGRect(x: 37.2, y: 26, width: 6.2, height: 14), 2.4, .white)
        fillRound(&context, CGRect(x: 14.2, y: 27.2, width: 3.2, height: 11.4), 1.5, Color(hex: 0x7A4E32))
        fillRound(&context, CGRect(x: 38.6, y: 27.2, width: 3.2, height: 11.4), 1.5, Color(hex: 0x7A4E32))
        var cap = Path()
        cap.move(to: CGPoint(x: 14.8, y: 22.4))
        cap.addCurve(to: CGPoint(x: 28, y: 9.4), control1: CGPoint(x: 15.2, y: 13.2), control2: CGPoint(x: 20.6, y: 9.4))
        cap.addCurve(to: CGPoint(x: 41.2, y: 22.4), control1: CGPoint(x: 35.4, y: 9.4), control2: CGPoint(x: 40.8, y: 13.2))
        cap.closeSubpath()
        context.fill(cap, with: .color(.white))
        var crown = Path()
        crown.move(to: CGPoint(x: 17, y: 21.6))
        crown.addCurve(to: CGPoint(x: 28, y: 11.6), control1: CGPoint(x: 17.4, y: 14.4), control2: CGPoint(x: 21.8, y: 11.6))
        crown.addCurve(to: CGPoint(x: 39, y: 21.6), control1: CGPoint(x: 34.2, y: 11.6), control2: CGPoint(x: 38.6, y: 14.4))
        crown.closeSubpath()
        context.fill(crown, with: .color(Color(hex: 0xC4956A)))
        fillRound(&context, CGRect(x: 15.2, y: 19.6, width: 25.6, height: 9.2), 4.6, .white)
        fillRound(&context, CGRect(x: 16.6, y: 20.8, width: 22.8, height: 6.8), 3.4, Color(hex: 0x7A4E32))
        fillRound(&context, CGRect(x: 18.2, y: 21.6, width: 8.2, height: 5.2), 2.4, Color(hex: 0xB7E7FB))
        fillRound(&context, CGRect(x: 29.6, y: 21.6, width: 8.2, height: 5.2), 2.4, Color(hex: 0xB7E7FB))
        var glint = Path()
        glint.move(to: CGPoint(x: 19.4, y: 22.6))
        glint.addLine(to: CGPoint(x: 22.6, y: 22.6))
        glint.move(to: CGPoint(x: 30.8, y: 22.6))
        glint.addLine(to: CGPoint(x: 34, y: 22.6))
        context.stroke(glint, with: .color(.white), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
    }

    private static func dropWave() -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 23.6, y: 18.8))
        path.addCurve(to: CGPoint(x: 30.6, y: 26.6), control1: CGPoint(x: 30.6, y: 17.2), control2: CGPoint(x: 34.4, y: 22.4))
        path.addCurve(to: CGPoint(x: 25.2, y: 34.4), control1: CGPoint(x: 27.4, y: 30.2), control2: CGPoint(x: 23.8, y: 30.6))
        path.addCurve(to: CGPoint(x: 33.2, y: 33.4), control1: CGPoint(x: 26.4, y: 37.4), control2: CGPoint(x: 32, y: 36.6))
        path.addCurve(to: CGPoint(x: 22.4, y: 33.6), control1: CGPoint(x: 30.4, y: 37.2), control2: CGPoint(x: 24.8, y: 37.4))
        path.addCurve(to: CGPoint(x: 27.8, y: 24.6), control1: CGPoint(x: 20, y: 29.6), control2: CGPoint(x: 25.2, y: 28.2))
        path.addCurve(to: CGPoint(x: 23.6, y: 18.8), control1: CGPoint(x: 30, y: 21.6), control2: CGPoint(x: 26.2, y: 19.6))
        path.closeSubpath()
        return path
    }

    private static func strokeFill(_ context: inout GraphicsContext, _ path: Path, _ color: Color, width: CGFloat) {
        context.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: width, lineJoin: .round, lineCap: .round))
        context.fill(path, with: .color(color))
    }

    private static func ear(context: inout GraphicsContext, cx: CGFloat, cy: CGFloat, white: Bool) {
        let rect = CGRect(x: cx - 5, y: cy - 8, width: 10, height: 16)
        if white {
            fillEllipse(context, rect.insetBy(dx: -1.5, dy: -1.5), Color.white, outline: 0)
        } else {
            fillEllipse(context, rect, Color(hex: 0xFFF6EA), outline: 0)
            fillEllipse(context, rect.insetBy(dx: 2.4, dy: 3.2), Color(hex: 0xFFB7C8), outline: 0)
        }
    }

    private static func heartShape(_ context: inout GraphicsContext, in rect: CGRect, fill: Color, grow: CGFloat) {
        let box = rect.insetBy(dx: -grow, dy: -grow)
        var path = Path()
        let mid = CGPoint(x: box.midX, y: box.maxY - box.height * 0.08)
        path.move(to: mid)
        path.addCurve(
            to: CGPoint(x: box.minX + box.width * 0.18, y: box.minY + box.height * 0.38),
            control1: CGPoint(x: box.minX + box.width * 0.15, y: box.maxY * 0.72 + box.minY * 0.28),
            control2: CGPoint(x: box.minX, y: box.midY)
        )
        path.addCurve(
            to: CGPoint(x: box.midX, y: box.minY + box.height * 0.28),
            control1: CGPoint(x: box.minX + box.width * 0.28, y: box.minY),
            control2: CGPoint(x: box.midX - box.width * 0.02, y: box.minY + box.height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: box.maxX - box.width * 0.18, y: box.minY + box.height * 0.38),
            control1: CGPoint(x: box.midX + box.width * 0.02, y: box.minY + box.height * 0.08),
            control2: CGPoint(x: box.maxX - box.width * 0.28, y: box.minY)
        )
        path.addCurve(
            to: mid,
            control1: CGPoint(x: box.maxX, y: box.midY),
            control2: CGPoint(x: box.maxX - box.width * 0.15, y: box.maxY * 0.72 + box.minY * 0.28)
        )
        context.fill(path, with: .color(fill))
    }

    private static func fillEllipse(_ context: inout GraphicsContext, _ rect: CGRect, _ color: Color, outline: CGFloat) {
        if outline > 0 {
            context.fill(Path(ellipseIn: rect.insetBy(dx: -outline, dy: -outline)), with: .color(.white))
        }
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private static func fillRound(_ context: inout GraphicsContext, _ rect: CGRect, _ radius: CGFloat, _ color: Color) {
        context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
    }
}
