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
            case .decoration: QuestGlyphs.flower(&ink)
            case .micropet: QuestGlyphs.mushroom(&ink)
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

    static func flower(_ context: inout GraphicsContext) {
        fillEllipse(&context, CGRect(x: 12, y: 30, width: 14, height: 9), Color(hex: 0x3EAA6E), outline: 1.6)
        fillEllipse(&context, CGRect(x: 30, y: 30, width: 14, height: 9), Color(hex: 0x3EAA6E), outline: 1.6)
        petal(&context, cx: 28, cy: 20, dx: 0, dy: -6)
        petal(&context, cx: 28, cy: 20, dx: 6, dy: 0)
        petal(&context, cx: 28, cy: 20, dx: -6, dy: 0)
        petal(&context, cx: 28, cy: 20, dx: 0, dy: 6)
        petal(&context, cx: 28, cy: 20, dx: 4.2, dy: -4.2)
        petal(&context, cx: 28, cy: 20, dx: -4.2, dy: -4.2)
        fillEllipse(&context, CGRect(x: 24.2, y: 16.2, width: 7.6, height: 7.6), Color.white, outline: 0)
        fillEllipse(&context, CGRect(x: 25.4, y: 17.4, width: 5.2, height: 5.2), Color(hex: 0xFFE27A), outline: 0)
        var pot = Path()
        pot.move(to: CGPoint(x: 19, y: 34))
        pot.addLine(to: CGPoint(x: 37, y: 34))
        pot.addLine(to: CGPoint(x: 34.2, y: 46))
        pot.addQuadCurve(to: CGPoint(x: 21.8, y: 46), control: CGPoint(x: 28, y: 48))
        pot.closeSubpath()
        context.stroke(pot, with: .color(.white), style: StrokeStyle(lineWidth: 4, lineJoin: .round))
        context.fill(pot, with: .color(Color(hex: 0xE39A62)))
        fillRound(&context, CGRect(x: 18.2, y: 32.2, width: 19.6, height: 4.2), 1.6, Color.white)
        fillRound(&context, CGRect(x: 19.4, y: 33.2, width: 17.2, height: 2.8), 1.2, Color(hex: 0xF0B27A))
    }

    static func mushroom(_ context: inout GraphicsContext) {
        fillRound(&context, CGRect(x: 22, y: 28, width: 12, height: 16), 6, Color.white)
        fillRound(&context, CGRect(x: 23.4, y: 29.2, width: 9.2, height: 13.6), 5, Color(hex: 0xFFF6EA))
        fillEllipse(&context, CGRect(x: 12, y: 16, width: 32, height: 22), Color.white, outline: 0)
        fillEllipse(&context, CGRect(x: 14, y: 17.6, width: 28, height: 18.4), Color(hex: 0xF48BB0), outline: 0)
        fillEllipse(&context, CGRect(x: 18, y: 20, width: 5, height: 4), Color(hex: 0xFFE3EE), outline: 0)
        fillEllipse(&context, CGRect(x: 30, y: 21, width: 4.2, height: 3.4), Color(hex: 0xFFE3EE), outline: 0)
        fillEllipse(&context, CGRect(x: 23.4, y: 31.2, width: 2.6, height: 3.1), Color(hex: 0x4A3428), outline: 0)
        fillEllipse(&context, CGRect(x: 30, y: 31.2, width: 2.6, height: 3.1), Color(hex: 0x4A3428), outline: 0)
        var smile = Path()
        smile.move(to: CGPoint(x: 25.2, y: 36))
        smile.addQuadCurve(to: CGPoint(x: 30.8, y: 36), control: CGPoint(x: 28, y: 38))
        context.stroke(smile, with: .color(Color(hex: 0xE07A8C)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
    }

    static func goggles(_ context: inout GraphicsContext) {
        var strap = Path()
        strap.move(to: CGPoint(x: 10, y: 30))
        strap.addQuadCurve(to: CGPoint(x: 46, y: 30), control: CGPoint(x: 28, y: 14))
        context.stroke(strap, with: .color(.white), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        context.stroke(strap, with: .color(Color(hex: 0xC4A574)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        lens(&context, x: 12)
        lens(&context, x: 30)
        fillRound(&context, CGRect(x: 24.6, y: 27.2, width: 6.8, height: 3.4), 1.4, Color.white)
        fillRound(&context, CGRect(x: 25.6, y: 28, width: 4.8, height: 1.8), 0.8, Color(hex: 0xE7D3B0))
    }

    private static func lens(_ context: inout GraphicsContext, x: CGFloat) {
        fillEllipse(context, CGRect(x: x, y: 24, width: 16, height: 16), Color.white, outline: 0)
        fillEllipse(context, CGRect(x: x + 1.6, y: 25.6, width: 12.8, height: 12.8), Color(hex: 0x3E342C), outline: 0)
        fillEllipse(context, CGRect(x: x + 3.4, y: 27.4, width: 4.2, height: 3.2), Color.white.opacity(0.85), outline: 0)
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

    private static func petal(_ context: inout GraphicsContext, cx: CGFloat, cy: CGFloat, dx: CGFloat, dy: CGFloat) {
        fillEllipse(context, CGRect(x: cx + dx - 4, y: cy + dy - 4, width: 8, height: 8), Color.white, outline: 0)
        fillEllipse(context, CGRect(x: cx + dx - 3, y: cy + dy - 3, width: 6, height: 6), Color(hex: 0xFF7A9A), outline: 0)
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
