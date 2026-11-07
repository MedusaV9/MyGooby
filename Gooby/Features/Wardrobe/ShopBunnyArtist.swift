import SwiftUI

struct ShopBunnyMap {
    var origin: CGPoint
    var scale: CGFloat

    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }

    func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        CGRect(x: origin.x + x * scale, y: origin.y + y * scale, width: width * scale, height: height * scale)
    }

    func ellipse(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> Path {
        Path(ellipseIn: rect(x, y, width, height))
    }

    func round(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ radius: CGFloat) -> Path {
        Path(roundedRect: rect(x, y, width, height), cornerRadius: max(1, radius * scale))
    }

    var line: CGFloat { max(1, scale * 1.5) }
}

enum ShopBunnyArtist {
    static let design = CGSize(width: 200, height: 268)

    static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        worn: [ShopAnchor: ShopItem],
        eyeOpen: CGFloat
    ) {
        let scale = min(size.width / design.width, size.height / design.height)
        let origin = CGPoint(
            x: (size.width - design.width * scale) / 2,
            y: (size.height - design.height * scale) / 2
        )
        let map = ShopBunnyMap(origin: origin, scale: scale)
        let open = min(1, max(0, eyeOpen))

        ShopPaint.fill(&context, map.ellipse(34, 250, 132, 16), 0x3D3656, 0.08)
        if let pack = worn[.backpack], pack.draw != .pouch {
            drawPack(&context, map, pack)
        }
        drawEars(&context, map)
        if let sweater = worn[.sweater], sweater.draw == .hoodie {
            drawHood(&context, map, sweater)
        } else if let jacket = worn[.jacket], jacket.draw == .raincoat {
            drawHood(&context, map, jacket)
        }
        drawBody(&context, map)
        if let pants = worn[.pants] {
            drawLegs(&context, map, pants)
        }
        if let shoes = worn[.shoes] {
            drawShoes(&context, map, shoes)
        }
        if let shirt = worn[.shirt] {
            drawShirt(&context, map, shirt)
        }
        if let pants = worn[.pants], pants.draw == .dungarees {
            drawBib(&context, map, pants)
        }
        if let dress = worn[.dress] {
            drawDress(&context, map, dress)
        }
        if let sweater = worn[.sweater] {
            drawSweater(&context, map, sweater)
        }
        if let jacket = worn[.jacket] {
            drawJacket(&context, map, jacket)
        }
        if let scarf = worn[.scarf] {
            drawScarf(&context, map, scarf)
        }
        drawArms(&context, map)
        if worn[.backpack]?.draw == .pouch, let pack = worn[.backpack] {
            drawPack(&context, map, pack)
        }
        drawHead(&context, map)
        drawFace(&context, map, eyeOpen: open)
        if let glasses = worn[.glasses] {
            drawGlasses(&context, map, glasses)
        }
        if let bow = worn[.bow] {
            drawBow(&context, map, bow)
        }
        if let hat = worn[.hat] {
            drawHat(&context, map, hat)
        }
        if let pin = worn[.accessory] {
            drawPin(&context, map, pin)
        }
    }

    private static func drawEars(_ context: inout GraphicsContext, _ map: ShopBunnyMap) {
        ShopPaint.fill(&context, map.ellipse(24, 0, 40, 90), 0xFFF3E4)
        ShopPaint.fill(&context, map.ellipse(136, 0, 40, 90), 0xFFF3E4)
        ShopPaint.fill(&context, map.ellipse(32, 16, 22, 58), 0xFFB7C8)
        ShopPaint.fill(&context, map.ellipse(146, 16, 22, 58), 0xFFB7C8)
        ShopPaint.fill(&context, map.ellipse(36, 24, 8, 18), 0xFFFFFF, 0.35)
        ShopPaint.fill(&context, map.ellipse(150, 24, 8, 18), 0xFFFFFF, 0.35)
    }

    private static func drawBody(_ context: inout GraphicsContext, _ map: ShopBunnyMap) {
        ShopPaint.fill(&context, map.ellipse(38, 156, 124, 98), 0xFFF3E4)
        ShopPaint.fill(&context, map.ellipse(56, 176, 88, 64), 0xFFFFFF, 0.42)
        ShopPaint.fill(&context, map.ellipse(52, 230, 40, 28), 0xFFF3E4)
        ShopPaint.fill(&context, map.ellipse(108, 230, 40, 28), 0xFFF3E4)
    }

    private static func drawArms(_ context: inout GraphicsContext, _ map: ShopBunnyMap) {
        ShopPaint.fill(&context, map.ellipse(6, 170, 40, 50), 0xFFF3E4)
        ShopPaint.fill(&context, map.ellipse(154, 170, 40, 50), 0xFFF3E4)
        ShopPaint.fill(&context, map.ellipse(12, 176, 16, 12), 0xFFFFFF, 0.35)
        ShopPaint.fill(&context, map.ellipse(168, 176, 16, 12), 0xFFFFFF, 0.35)
    }

    private static func drawHead(_ context: inout GraphicsContext, _ map: ShopBunnyMap) {
        ShopPaint.fill(&context, map.ellipse(18, 42, 164, 124), 0xFFF3E4)
        ShopPaint.fill(&context, map.ellipse(48, 54, 48, 28), 0xFFFFFF, 0.38)
    }

    private static func drawFace(_ context: inout GraphicsContext, _ map: ShopBunnyMap, eyeOpen: CGFloat) {
        ShopPaint.fill(&context, map.ellipse(58, 118, 84, 42), 0xFFF7EE)
        drawEye(&context, map, x: 46, eyeOpen: eyeOpen)
        drawEye(&context, map, x: 114, eyeOpen: eyeOpen)
        ShopPaint.fill(&context, map.ellipse(30, 118, 34, 22), 0xFFB3C7, 0.85)
        ShopPaint.fill(&context, map.ellipse(136, 118, 34, 22), 0xFFB3C7, 0.85)
        ShopPaint.fill(&context, map.ellipse(88, 118, 24, 16), 0xFF8FAB)
        ShopPaint.fill(&context, map.ellipse(94, 120, 8, 6), 0xFFFFFF, 0.55)
        ShopPaint.fill(&context, map.ellipse(90, 136, 20, 14), 0xE9859C)
        ShopPaint.fill(&context, map.ellipse(94, 142, 12, 8), 0xFF7A9A)
        var smile = Path()
        smile.move(to: map.point(78, 136))
        smile.addQuadCurve(to: map.point(122, 136), control: map.point(100, 156))
        context.stroke(smile, with: .color(Color(shopHex: 0xC47A8A)), lineWidth: map.line)
    }

    private static func drawEye(_ context: inout GraphicsContext, _ map: ShopBunnyMap, x: CGFloat, eyeOpen: CGFloat) {
        let eye = map.ellipse(x, 84, 40, 44)
        ShopPaint.fill(&context, eye, 0x2B241F)
        ShopPaint.fill(&context, map.ellipse(x + 6, 90, 14, 14), 0xFFFFFF, 0.95)
        ShopPaint.fill(&context, map.ellipse(x + 22, 110, 7, 7), 0xFFFFFF, 0.75)
        guard eyeOpen < 0.98 else { return }
        let lidHeight = max(4, 44 * (1 - eyeOpen))
        ShopPaint.fill(&context, map.ellipse(x - 1, 82, 42, lidHeight), 0xFFF3E4)
    }

    private static func drawHood(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        ShopPaint.fill(&context, map.ellipse(26, 58, 148, 112), item.primary)
        ShopPaint.stroke(&context, map.ellipse(40, 72, 120, 86), item.secondary, 0.35, map.line)
    }

    private static func drawShirt(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        let shirt = map.round(48, 162, 104, 68, 24)
        ShopPaint.fill(&context, shirt, item.primary)
        ShopPaint.stroke(&context, shirt, ShopPaint.mix(item.primary, toward: 0x3D3656, amount: 0.18), 0.45, map.line)
        ShopPaint.fill(&context, map.ellipse(78, 160, 44, 18), 0xFFF3E4)
        switch item.draw {
        case .teeStripe:
            ShopPaint.fill(&context, map.round(56, 182, 88, 10, 5), item.accent)
            ShopPaint.fill(&context, map.round(56, 200, 88, 10, 5), item.secondary)
        case .teeHeart:
            ShopPaint.fill(&context, ShopPaint.heart(in: map.rect(86, 184, 28, 26)), item.accent)
        default:
            break
        }
    }

    private static func drawSweater(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        let body = map.round(42, 158, 116, 78, 26)
        ShopPaint.fill(&context, body, item.primary)
        ShopPaint.fill(&context, map.round(42, 220, 116, 16, 8), item.secondary)
        ShopPaint.fill(&context, map.round(18, 176, 28, 34, 12), item.primary)
        ShopPaint.fill(&context, map.round(154, 176, 28, 34, 12), item.primary)
        ShopPaint.stroke(&context, body, ShopPaint.mix(item.primary, toward: 0x3D3656, amount: 0.2), 0.4, map.line)
    }

    private static func drawJacket(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        if item.draw == .vest {
            let vest = map.round(58, 166, 84, 52, 18)
            ShopPaint.fill(&context, vest, item.primary)
            ShopPaint.fill(&context, map.ellipse(92, 182, 8, 8), item.accent)
            ShopPaint.fill(&context, map.ellipse(92, 198, 8, 8), item.accent)
            ShopPaint.stroke(&context, vest, item.secondary, 0.5, map.line)
            return
        }
        let left = map.round(40, 160, 54, 82, 18)
        let right = map.round(106, 160, 54, 82, 18)
        ShopPaint.fill(&context, left, item.primary)
        ShopPaint.fill(&context, right, item.primary)
        ShopPaint.stroke(&context, left, item.secondary, 0.45, map.line)
        ShopPaint.stroke(&context, right, item.secondary, 0.45, map.line)
        if item.draw == .raincoat {
            ShopPaint.fill(&context, map.round(92, 176, 16, 48, 6), item.accent)
        } else {
            ShopPaint.fill(&context, map.ellipse(118, 186, 8, 8), item.accent)
            ShopPaint.fill(&context, map.ellipse(118, 204, 8, 8), item.accent)
        }
    }

    private static func drawDress(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        var skirt = Path()
        skirt.move(to: map.point(54, 160))
        skirt.addLine(to: map.point(146, 160))
        skirt.addQuadCurve(to: map.point(172, 246), control: map.point(176, 200))
        skirt.addQuadCurve(to: map.point(28, 246), control: map.point(100, 268))
        skirt.addQuadCurve(to: map.point(54, 160), control: map.point(24, 200))
        skirt.closeSubpath()
        ShopPaint.fill(&context, skirt, item.primary)
        if item.draw == .dressTulle {
            ShopPaint.fill(&context, map.ellipse(24, 196, 152, 62), item.secondary, 0.45)
            ShopPaint.fill(&context, ShopPaint.star(in: map.rect(62, 208, 16, 16)), item.accent)
            ShopPaint.fill(&context, ShopPaint.star(in: map.rect(96, 220, 14, 14)), item.accent)
            ShopPaint.fill(&context, ShopPaint.star(in: map.rect(124, 206, 12, 12)), item.accent)
        }
        ShopPaint.fill(&context, map.round(62, 168, 76, 12, 6), item.accent)
        ShopPaint.stroke(&context, skirt, ShopPaint.mix(item.primary, toward: 0x3D3656, amount: 0.16), 0.35, map.line)
    }

    private static func drawLegs(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        let tall = item.draw == .trousers || item.draw == .dungarees
        let top: CGFloat = tall ? 198 : 206
        let height: CGFloat = tall ? 46 : 34
        let left = map.round(50, top, 42, height, 14)
        let right = map.round(108, top, 42, height, 14)
        ShopPaint.fill(&context, left, item.primary)
        ShopPaint.fill(&context, right, item.primary)
        ShopPaint.stroke(&context, left, item.secondary, 0.4, map.line)
        ShopPaint.stroke(&context, right, item.secondary, 0.4, map.line)
    }

    private static func drawBib(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        let bib = map.round(70, 164, 60, 46, 12)
        ShopPaint.fill(&context, bib, item.primary)
        ShopPaint.fill(&context, map.round(78, 150, 10, 28, 4), item.secondary)
        ShopPaint.fill(&context, map.round(112, 150, 10, 28, 4), item.secondary)
        ShopPaint.fill(&context, map.round(84, 186, 32, 16, 6), item.accent)
    }

    private static func drawShoes(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        switch item.draw {
        case .boots:
            let left = map.round(46, 210, 46, 50, 16)
            let right = map.round(108, 210, 46, 50, 16)
            ShopPaint.fill(&context, left, item.primary)
            ShopPaint.fill(&context, right, item.primary)
            ShopPaint.fill(&context, map.round(46, 246, 46, 10, 4), item.accent)
            ShopPaint.fill(&context, map.round(108, 246, 46, 10, 4), item.accent)
        case .sneakers:
            shoe(&context, map, item, y: 226, height: 30)
            ShopPaint.fill(&context, map.round(54, 236, 32, 6, 3), item.accent)
            ShopPaint.fill(&context, map.round(114, 236, 32, 6, 3), item.accent)
        case .slippers:
            shoe(&context, map, item, y: 232, height: 24)
            ShopPaint.fill(&context, ShopPaint.star(in: map.rect(62, 234, 12, 12)), item.accent)
            ShopPaint.fill(&context, ShopPaint.star(in: map.rect(122, 234, 12, 12)), item.accent)
        default:
            shoe(&context, map, item, y: 228, height: 28)
        }
    }

    private static func shoe(
        _ context: inout GraphicsContext,
        _ map: ShopBunnyMap,
        _ item: ShopItem,
        y: CGFloat,
        height: CGFloat
    ) {
        let left = map.ellipse(46, y, 48, height)
        let right = map.ellipse(106, y, 48, height)
        ShopPaint.fill(&context, left, item.primary)
        ShopPaint.fill(&context, right, item.primary)
        ShopPaint.stroke(&context, left, item.secondary, 0.45, map.line)
        ShopPaint.stroke(&context, right, item.secondary, 0.45, map.line)
    }

    private static func drawPack(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        switch item.draw {
        case .satchel:
            let bag = map.round(150, 176, 46, 52, 18)
            ShopPaint.fill(&context, bag, item.primary)
            ShopPaint.fill(&context, map.round(156, 176, 34, 16, 8), item.secondary)
            ShopPaint.fill(&context, map.ellipse(166, 198, 12, 12), item.accent)
        case .pouch:
            let bag = map.round(12, 196, 36, 40, 14)
            ShopPaint.fill(&context, bag, item.primary)
            ShopPaint.fill(&context, map.round(18, 196, 24, 12, 6), item.secondary)
            ShopPaint.fill(&context, ShopPaint.star(in: map.rect(20, 214, 16, 16)), item.accent)
        default:
            let bag = map.round(152, 150, 44, 72, 16)
            ShopPaint.fill(&context, bag, item.primary)
            ShopPaint.fill(&context, map.round(160, 168, 28, 22, 8), item.secondary)
            ShopPaint.fill(&context, map.round(168, 150, 8, 36, 3), item.accent, 0.7)
            ShopPaint.stroke(&context, bag, ShopPaint.mix(item.primary, toward: 0x3D3656, amount: 0.2), 0.4, map.line)
        }
    }

    private static func drawScarf(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        let wrap = map.round(40, 154, 120, 28, 14)
        ShopPaint.fill(&context, wrap, item.primary)
        let tail = map.round(118, 170, 28, 46, 12)
        ShopPaint.fill(&context, tail, item.primary)
        if item.draw == .scarfPlaid {
            ShopPaint.fill(&context, map.rect(40, 164, 120, 5), item.secondary)
            ShopPaint.fill(&context, map.rect(40, 174, 120, 5), item.accent)
            ShopPaint.fill(&context, map.rect(126, 176, 8, 40), item.secondary)
        } else {
            ShopPaint.fill(&context, map.ellipse(124, 198, 14, 14), item.accent)
        }
    }

    private static func drawGlasses(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        let left = map.ellipse(44, 86, 44, 40)
        let right = map.ellipse(112, 86, 44, 40)
        if item.draw == .glassesSun {
            ShopPaint.fill(&context, left, item.primary, 0.55)
            ShopPaint.fill(&context, right, item.primary, 0.55)
        }
        context.stroke(left, with: .color(Color(shopHex: item.secondary)), lineWidth: map.line * 1.4)
        context.stroke(right, with: .color(Color(shopHex: item.secondary)), lineWidth: map.line * 1.4)
        var bridge = Path()
        bridge.move(to: map.point(88, 104))
        bridge.addQuadCurve(to: map.point(112, 104), control: map.point(100, 98))
        context.stroke(bridge, with: .color(Color(shopHex: item.secondary)), lineWidth: map.line)
        if item.draw == .glassesStar {
            ShopPaint.fill(&context, ShopPaint.star(in: map.rect(146, 82, 16, 16)), item.accent)
        }
    }

    private static func drawBow(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        ShopPaint.fill(&context, map.ellipse(8, 62, 28, 22), item.primary)
        ShopPaint.fill(&context, map.ellipse(30, 62, 28, 22), item.primary)
        ShopPaint.fill(&context, map.ellipse(24, 66, 14, 14), item.accent)
        ShopPaint.fill(&context, map.round(14, 78, 8, 16, 3), item.secondary)
        ShopPaint.fill(&context, map.round(36, 78, 8, 16, 3), item.secondary)
    }

    private static func drawHat(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        switch item.draw {
        case .cap:
            ShopPaint.fill(&context, map.ellipse(58, 36, 86, 48), item.primary)
            ShopPaint.fill(&context, map.ellipse(108, 62, 58, 20), item.secondary)
        case .sunhat:
            ShopPaint.fill(&context, map.ellipse(18, 70, 164, 26), item.secondary)
            ShopPaint.fill(&context, map.ellipse(62, 34, 76, 50), item.primary)
            ShopPaint.fill(&context, map.ellipse(84, 42, 22, 12), item.accent, 0.8)
        case .beret:
            var tilted = context
            let blob = map.rect(44, 30, 112, 52)
            tilted.translateBy(x: blob.midX, y: blob.midY)
            tilted.rotate(by: .degrees(-16))
            tilted.translateBy(x: -blob.midX, y: -blob.midY)
            ShopPaint.fill(&tilted, Path(ellipseIn: blob), item.primary)
            ShopPaint.fill(&context, map.ellipse(96, 48, 12, 12), item.accent)
        case .pompom:
            ShopPaint.fill(&context, map.ellipse(60, 34, 80, 50), item.primary)
            ShopPaint.fill(&context, map.ellipse(84, 8, 32, 32), item.accent)
        case .flowerCrown:
            ShopPaint.fill(&context, map.round(48, 72, 104, 10, 5), item.secondary)
            for index in 0..<5 {
                let x = 52 + CGFloat(index) * 20
                ShopPaint.fill(&context, map.ellipse(x, 60, 16, 16), index.isMultiple(of: 2) ? item.primary : item.accent)
                ShopPaint.fill(&context, map.ellipse(x + 5, 65, 6, 6), 0xFFE7AD)
            }
        default:
            ShopPaint.fill(&context, map.ellipse(58, 30, 84, 52), item.primary)
            ShopPaint.fill(&context, map.round(58, 68, 84, 12, 6), item.secondary)
            ShopPaint.fill(&context, map.ellipse(86, 14, 28, 28), item.accent)
        }
    }

    private static func drawPin(_ context: inout GraphicsContext, _ map: ShopBunnyMap, _ item: ShopItem) {
        switch item.draw {
        case .pinStar:
            ShopPaint.fill(&context, ShopPaint.star(in: map.rect(132, 168, 28, 28)), item.primary)
        case .pinFlower:
            ShopPaint.fill(&context, map.ellipse(128, 166, 14, 14), item.primary)
            ShopPaint.fill(&context, map.ellipse(142, 166, 14, 14), item.primary)
            ShopPaint.fill(&context, map.ellipse(128, 180, 14, 14), item.primary)
            ShopPaint.fill(&context, map.ellipse(142, 180, 14, 14), item.primary)
            ShopPaint.fill(&context, map.ellipse(135, 173, 12, 12), item.accent)
        case .pinBell:
            ShopPaint.fill(&context, map.ellipse(132, 166, 26, 22), item.primary)
            ShopPaint.fill(&context, map.round(136, 184, 18, 14, 6), item.secondary)
            ShopPaint.fill(&context, map.ellipse(141, 196, 8, 8), item.accent)
        default:
            ShopPaint.fill(&context, ShopPaint.heart(in: map.rect(130, 166, 30, 28)), item.primary)
        }
    }
}
