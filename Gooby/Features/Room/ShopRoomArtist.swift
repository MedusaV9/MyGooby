import SwiftUI

enum ShopRoomLayout {
    static let design = CGSize(width: 320, height: 440)
    static let window = CGRect(x: 18, y: 48, width: 102, height: 116)
    static let picture = CGRect(x: 198, y: 58, width: 104, height: 80)
    static let shelf = CGRect(x: 190, y: 150, width: 114, height: 56)
    static let lamp = CGRect(x: 128, y: 36, width: 48, height: 168)
    static let plant = CGRect(x: 8, y: 186, width: 70, height: 112)
    static let bed = CGRect(x: 14, y: 292, width: 148, height: 108)
    static let pillow = CGRect(x: 30, y: 308, width: 58, height: 42)
    static let sofa = CGRect(x: 176, y: 300, width: 128, height: 96)
    static let table = CGRect(x: 188, y: 372, width: 92, height: 50)
    static let rug = CGRect(x: 46, y: 352, width: 230, height: 72)
    static let seasonal = CGRect(x: 16, y: 8, width: 288, height: 36)
    static let bunny = CGRect(x: 112, y: 236, width: 96, height: 128)
    static let floor = CGRect(x: 0, y: 300, width: 320, height: 140)
    static let wall = CGRect(x: 0, y: 0, width: 320, height: 312)

    static func frame(for anchor: ShopAnchor) -> CGRect? {
        switch anchor {
        case .window: return window
        case .picture: return picture
        case .shelf: return shelf
        case .lamp: return lamp
        case .plant: return plant
        case .bed: return bed
        case .pillow: return pillow
        case .sofa: return sofa
        case .table: return table
        case .rug: return rug
        case .seasonal: return seasonal
        case .floor: return floor
        case .wall: return wall.insetBy(dx: 10, dy: 10)
        default: return nil
        }
    }

    static func fitted(in size: CGSize) -> (origin: CGPoint, scale: CGFloat) {
        let scale = min(size.width / design.width, size.height / design.height)
        let origin = CGPoint(
            x: (size.width - design.width * scale) / 2,
            y: (size.height - design.height * scale) / 2
        )
        return (origin, scale)
    }

    static func viewRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        let fitted = fitted(in: size)
        return CGRect(
            x: fitted.origin.x + rect.minX * fitted.scale,
            y: fitted.origin.y + rect.minY * fitted.scale,
            width: rect.width * fitted.scale,
            height: rect.height * fitted.scale
        )
    }
}

enum ShopRoomArtist {
    static func draw(
        context: inout GraphicsContext,
        size: CGSize,
        placements: [ShopAnchor: ShopItem],
        phase: ShopDaylight,
        highlighted: ShopAnchor?
    ) {
        let resolved = phase == .auto ? ShopDaylight.day : phase
        let wall = placements[.wall]
        let floor = placements[.floor]
        fill(CGRect(origin: .zero, size: size), hex: wall?.primary ?? 0xFFF8EF, context: &context)
        let floorRect = ShopRoomLayout.viewRect(ShopRoomLayout.floor, in: size)
        var floorPath = Path()
        floorPath.move(to: CGPoint(x: 0, y: floorRect.minY + 18))
        floorPath.addQuadCurve(
            to: CGPoint(x: size.width, y: floorRect.minY + 10),
            control: CGPoint(x: size.width * 0.5, y: floorRect.minY - 8)
        )
        floorPath.addLine(to: CGPoint(x: size.width, y: size.height))
        floorPath.addLine(to: CGPoint(x: 0, y: size.height))
        floorPath.closeSubpath()
        ShopPaint.fill(&context, floorPath, floor?.primary ?? 0xE8C9A1)
        if let floor {
            drawPlanks(in: floorRect, item: floor, context: &context)
        }
        let board = CGRect(x: 0, y: floorRect.minY, width: size.width, height: 8)
        ShopPaint.fill(&context, Path(board), ShopPaint.mix(floor?.secondary ?? 0xC9A077, toward: 0x3D3656, amount: 0.15), 0.55)

        if resolved == .night {
            drawNightDots(in: size, context: &context)
        }
        drawIfPresent(.rug, placements, resolved, size, &context)
        drawIfPresent(.bed, placements, resolved, size, &context)
        drawIfPresent(.sofa, placements, resolved, size, &context)
        drawIfPresent(.table, placements, resolved, size, &context)
        drawIfPresent(.window, placements, resolved, size, &context)
        drawIfPresent(.picture, placements, resolved, size, &context)
        drawIfPresent(.shelf, placements, resolved, size, &context)
        drawIfPresent(.plant, placements, resolved, size, &context)
        drawIfPresent(.pillow, placements, resolved, size, &context)
        drawIfPresent(.lamp, placements, resolved, size, &context)
        drawIfPresent(.seasonal, placements, resolved, size, &context)

        let feet = ShopRoomLayout.viewRect(CGRect(x: 124, y: 348, width: 72, height: 16), in: size)
        ShopPaint.fill(&context, Path(ellipseIn: feet), 0x3D3656, 0.1)

        if let highlighted, let design = ShopRoomLayout.frame(for: highlighted) {
            let rect = ShopRoomLayout.viewRect(design, in: size).insetBy(dx: -3, dy: -3)
            let path = Path(roundedRect: rect, cornerRadius: 14)
            context.stroke(path, with: .color(Color(shopHex: 0x3D3656).opacity(0.55)), lineWidth: 2)
        }
    }

    static func drawPiece(
        _ item: ShopItem,
        phase: ShopDaylight,
        in rect: CGRect,
        context: inout GraphicsContext
    ) {
        let resolved = phase == .auto ? ShopDaylight.day : phase
        switch item.draw {
        case .wallFill:
            ShopPaint.fill(&context, Path(roundedRect: rect, cornerRadius: rect.width * 0.12), item.primary)
            let pane = fraction(rect, 0.62, 0.12, 0.26, 0.34)
            drawSky(in: pane, phase: resolved, context: &context)
        case .floorFill:
            ShopPaint.fill(&context, Path(roundedRect: rect, cornerRadius: rect.width * 0.12), item.primary)
            drawPlanks(in: rect, item: item, context: &context)
        case .bedCloud, .bedNest, .bedCanopy:
            drawBed(item, in: rect, context: &context)
        case .rugRound:
            ShopPaint.fill(&context, Path(ellipseIn: rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.12)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: rect.insetBy(dx: rect.width * 0.22, dy: rect.height * 0.28)), item.secondary, 0.85)
        case .rugOval:
            ShopPaint.fill(&context, Path(ellipseIn: rect.insetBy(dx: 2, dy: rect.height * 0.16)), item.primary)
        case .rugRunner:
            ShopPaint.fill(&context, Path(roundedRect: rect.insetBy(dx: 2, dy: rect.height * 0.22), cornerRadius: 12), item.primary)
            ShopPaint.fill(&context, Path(rect: fraction(rect, 0.08, 0.42, 0.84, 0.08)), item.secondary)
        case .lampHoney, .lampMushroom, .lampMoon, .lampOrb, .lampLantern:
            drawLamp(item, in: rect, context: &context)
        case .windowArch, .windowRound, .windowGarden:
            drawWindow(item, phase: resolved, in: rect, context: &context)
        case .plantDaisy, .plantFern, .plantSucculent, .plantHanging, .plantTulip:
            drawPlant(item, in: rect, context: &context)
        case .shelfCloud, .shelfBooks:
            drawShelf(item, in: rect, context: &context)
        case .pictureMeadow, .pictureMoon, .pictureSea, .pictureHarvest:
            drawPicture(item, in: rect, context: &context)
        case .sofa:
            drawSofa(item, in: rect, context: &context)
        case .tableRound, .tableTea:
            drawTable(item, in: rect, context: &context)
        case .pillowHeart:
            ShopPaint.fill(&context, ShopPaint.heart(in: rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.08)), item.primary)
        case .pillowStar:
            ShopPaint.fill(&context, Path(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 10), item.secondary)
            ShopPaint.fill(&context, ShopPaint.star(in: rect.insetBy(dx: rect.width * 0.28, dy: rect.height * 0.22)), item.primary)
        case .pillowRound:
            ShopPaint.fill(&context, Path(ellipseIn: rect.insetBy(dx: 2, dy: 2)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: rect.insetBy(dx: rect.width * 0.28, dy: rect.height * 0.28)), item.secondary, 0.7)
        case .garlandBlossom, .garlandLeaf, .garlandLights, .garlandShell:
            drawGarland(item, in: rect, context: &context)
        case .ticket:
            drawTicket(item, in: rect, context: &context)
        default:
            ShopPaint.fill(&context, Path(roundedRect: rect.insetBy(dx: 6, dy: 6), cornerRadius: 12), item.primary)
        }
    }

    private static func drawIfPresent(
        _ anchor: ShopAnchor,
        _ placements: [ShopAnchor: ShopItem],
        _ phase: ShopDaylight,
        _ size: CGSize,
        _ context: inout GraphicsContext
    ) {
        guard let item = placements[anchor], let design = ShopRoomLayout.frame(for: anchor) else { return }
        drawPiece(item, phase: phase, in: ShopRoomLayout.viewRect(design, in: size), context: &context)
    }

    private static func fill(_ rect: CGRect, hex: UInt32, context: inout GraphicsContext) {
        ShopPaint.fill(&context, Path(rect), hex)
    }

    private static func fraction(_ rect: CGRect, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX + rect.width * x,
            y: rect.minY + rect.height * y,
            width: rect.width * width,
            height: rect.height * height
        )
    }

    private static func drawPlanks(in rect: CGRect, item: ShopItem, context: inout GraphicsContext) {
        var index: CGFloat = 0
        while index < 6 {
            let band = CGRect(
                x: rect.minX,
                y: rect.minY + rect.height * (0.08 + index * 0.15),
                width: rect.width,
                height: max(1, rect.height * 0.015)
            )
            ShopPaint.fill(&context, Path(band), item.secondary, 0.45)
            index += 1
        }
    }

    private static func drawNightDots(in size: CGSize, context: inout GraphicsContext) {
        let spots: [CGPoint] = [
            CGPoint(x: 0.18, y: 0.08), CGPoint(x: 0.3, y: 0.16),
            CGPoint(x: 0.72, y: 0.1), CGPoint(x: 0.84, y: 0.2),
            CGPoint(x: 0.62, y: 0.05)
        ]
        for spot in spots {
            let dot = CGRect(x: size.width * spot.x, y: size.height * spot.y, width: 3, height: 3)
            ShopPaint.fill(&context, Path(ellipseIn: dot), 0xFFF8EF, 0.8)
        }
    }

    private static func drawSky(in rect: CGRect, phase: ShopDaylight, round: Bool = false, context: inout GraphicsContext) {
        let colors = sky(phase)
        let path = round ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: min(16, rect.width * 0.2))
        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: colors.map { Color(shopHex: $0) }),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)
            )
        )
        if phase == .night {
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.62, 0.16, 0.16, 0.16)), 0xFFF8EF)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.22, 0.3, 0.05, 0.05)), 0xFFF8EF, 0.9)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.4, 0.55, 0.04, 0.04)), 0xFFF8EF, 0.8)
        } else if phase == .evening {
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.62, 0.48, 0.2, 0.2)), 0xFFE7AD, 0.9)
        } else {
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.68, 0.12, 0.18, 0.18)), 0xFFE7AD)
        }
    }

    private static func sky(_ phase: ShopDaylight) -> [UInt32] {
        switch phase {
        case .morning:
            return [0xFFE7AD, 0xFFD6B3, 0xC8E9FF]
        case .day, .auto:
            return [0xC8E9FF, 0xEAF7FF, 0xFFF8EF]
        case .evening:
            return [0xFFB088, 0xD3C2FF, 0x6E628C]
        case .night:
            return [0x241E3A, 0x3D3656, 0x1B1730]
        }
    }

    private static func drawWindow(_ item: ShopItem, phase: ShopDaylight, in rect: CGRect, context: inout GraphicsContext) {
        let frame = Path(roundedRect: rect, cornerRadius: item.draw == .windowRound ? rect.width * 0.5 : 18)
        ShopPaint.fill(&context, frame, item.accent)
        let pane = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12)
        drawSky(in: pane, phase: phase, round: item.draw == .windowRound, context: &context)
        if item.draw == .windowArch {
            var bar = Path()
            bar.move(to: CGPoint(x: rect.midX, y: pane.minY))
            bar.addLine(to: CGPoint(x: rect.midX, y: pane.maxY))
            context.stroke(bar, with: .color(Color(shopHex: item.accent)), lineWidth: max(2, rect.width * 0.03))
        }
        if item.draw == .windowGarden {
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.2, 0.72, 0.18, 0.16)), 0xFF8FAB)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.38, 0.68, 0.16, 0.14)), 0xFFE7AD)
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.08, 0.1, 0.12, 0.8), cornerRadius: 6), item.secondary, 0.55)
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.8, 0.1, 0.12, 0.8), cornerRadius: 6), item.secondary, 0.55)
        }
    }

    private static func drawBed(_ item: ShopItem, in rect: CGRect, context: inout GraphicsContext) {
        if item.draw == .bedCanopy {
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.08, 0, 0.08, 0.72), cornerRadius: 4), item.primary)
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.84, 0, 0.08, 0.72), cornerRadius: 4), item.primary)
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.06, 0, 0.88, 0.22), cornerRadius: 10), item.secondary, 0.85)
        }
        let board = item.draw == .bedNest
            ? Path(ellipseIn: fraction(rect, 0.06, 0.18, 0.88, 0.78))
            : Path(roundedRect: fraction(rect, 0.04, 0.24, 0.92, 0.7), cornerRadius: 16)
        ShopPaint.fill(&context, board, item.primary)
        ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.1, 0.42, 0.8, 0.4), cornerRadius: 12), item.secondary)
        ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.14, 0.3, 0.28, 0.24), cornerRadius: 8), item.accent)
    }

    private static func drawLamp(_ item: ShopItem, in rect: CGRect, context: inout GraphicsContext) {
        switch item.draw {
        case .lampMushroom:
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.44, 0.42, 0.12, 0.48), cornerRadius: 4), item.secondary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.12, 0.18, 0.76, 0.36)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.3, 0.28, 0.18, 0.1)), 0xFFFFFF, 0.45)
        case .lampMoon, .lampOrb:
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.46, 0.48, 0.08, 0.4), cornerRadius: 3), item.accent)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.18, 0.08, 0.64, 0.46)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.36, 0.16, 0.16, 0.12)), item.secondary, 0.8)
        case .lampLantern:
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.28, 0.2, 0.44, 0.5), cornerRadius: 8), item.primary)
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.36, 0.32, 0.28, 0.26), cornerRadius: 4), item.secondary)
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.42, 0.08, 0.16, 0.14), cornerRadius: 3), item.accent)
        default:
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.46, 0.34, 0.08, 0.52), cornerRadius: 3), item.accent)
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.22, 0.08, 0.56, 0.32), cornerRadius: 10), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.4, 0.16, 0.16, 0.12)), 0xFFFFFF, 0.55)
        }
    }

    private static func drawPlant(_ item: ShopItem, in rect: CGRect, context: inout GraphicsContext) {
        ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.28, 0.62, 0.44, 0.32), cornerRadius: 6), item.accent)
        switch item.draw {
        case .plantFern:
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.08, 0.28, 0.4, 0.4)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.36, 0.16, 0.36, 0.46)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.52, 0.3, 0.4, 0.36)), item.secondary)
        case .plantSucculent:
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.18, 0.34, 0.28, 0.28)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.4, 0.28, 0.3, 0.3)), item.secondary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.32, 0.18, 0.24, 0.24)), item.accent == item.primary ? 0xC6EFDC : item.secondary)
        case .plantHanging:
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.46, 0, 0.08, 0.24), cornerRadius: 2), item.accent)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.22, 0.18, 0.56, 0.28)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.1, 0.32, 0.3, 0.36)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.58, 0.34, 0.28, 0.4)), item.secondary)
        case .plantTulip:
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.48, 0.28, 0.04, 0.36), cornerRadius: 2), item.secondary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.34, 0.12, 0.32, 0.28)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.18, 0.24, 0.24, 0.22)), item.primary, 0.85)
        default:
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.18, 0.34, 0.28, 0.28)), item.secondary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.4, 0.2, 0.34, 0.36)), item.secondary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.3, 0.16, 0.16, 0.16)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.52, 0.1, 0.16, 0.16)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.22, 0.28, 0.14, 0.14)), item.accent)
        }
    }

    private static func drawShelf(_ item: ShopItem, in rect: CGRect, context: inout GraphicsContext) {
        ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0, 0.62, 1, 0.16), cornerRadius: 4), item.primary)
        if item.draw == .shelfBooks {
            let colors: [UInt32] = [item.secondary, item.accent, 0xFF8FAB, 0x7DCEA0, item.primary]
            for index in 0..<5 {
                let book = fraction(rect, 0.08 + CGFloat(index) * 0.16, 0.18, 0.12, 0.46)
                ShopPaint.fill(&context, Path(roundedRect: book, cornerRadius: 2), colors[index])
            }
        } else {
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.1, 0.28, 0.22, 0.32)), item.secondary)
            ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.4, 0.22, 0.18, 0.4), cornerRadius: 3), item.accent)
            ShopPaint.fill(&context, ShopPaint.star(in: fraction(rect, 0.68, 0.24, 0.2, 0.32)), item.secondary)
        }
    }

    private static func drawPicture(_ item: ShopItem, in rect: CGRect, context: inout GraphicsContext) {
        ShopPaint.fill(&context, Path(roundedRect: rect, cornerRadius: 8), item.accent)
        let inner = rect.insetBy(dx: rect.width * 0.1, dy: rect.height * 0.12)
        switch item.draw {
        case .pictureMoon:
            ShopPaint.fill(&context, Path(rect.insetBy(dx: rect.width * 0.1, dy: rect.height * 0.12)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(inner, 0.58, 0.16, 0.24, 0.28)), item.secondary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(inner, 0, 0.7, 1, 0.4)), 0x6E628C)
        case .pictureSea:
            ShopPaint.fill(&context, Path(inner), 0xC8E9FF)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(inner, 0.7, 0.12, 0.18, 0.2)), 0xFFE7AD)
            ShopPaint.fill(&context, Path(fraction(inner, 0, 0.62, 1, 0.38)), 0x7EB6D9)
            ShopPaint.fill(&context, Path(fraction(inner, 0, 0.78, 1, 0.22)), item.secondary)
        case .pictureHarvest:
            ShopPaint.fill(&context, Path(inner), 0xFFE7AD)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(inner, 0.28, 0.36, 0.44, 0.48)), item.primary)
            ShopPaint.fill(&context, Path(roundedRect: fraction(inner, 0.46, 0.28, 0.08, 0.14), cornerRadius: 2), item.secondary)
        default:
            ShopPaint.fill(&context, Path(inner), 0xC8E9FF)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(inner, 0, 0.58, 1.1, 0.5)), item.primary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(inner, 0.18, 0.42, 0.16, 0.18)), item.secondary)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(inner, 0.48, 0.36, 0.18, 0.2)), 0xFF8FAB)
            ShopPaint.fill(&context, Path(ellipseIn: fraction(inner, 0.7, 0.46, 0.14, 0.16)), 0xFFF8EF)
        }
    }

    private static func drawSofa(_ item: ShopItem, in rect: CGRect, context: inout GraphicsContext) {
        ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.08, 0.16, 0.84, 0.58), cornerRadius: 16), item.primary)
        ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0, 0.28, 0.2, 0.6), cornerRadius: 12), item.secondary)
        ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.8, 0.28, 0.2, 0.6), cornerRadius: 12), item.secondary)
        ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.18, 0.48, 0.64, 0.28), cornerRadius: 10), item.accent, 0.65)
    }

    private static func drawTable(_ item: ShopItem, in rect: CGRect, context: inout GraphicsContext) {
        ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.08, 0.12, 0.84, 0.42)), item.primary)
        ShopPaint.fill(&context, Path(roundedRect: fraction(rect, 0.46, 0.4, 0.08, 0.48), cornerRadius: 3), item.secondary)
        if item.draw == .tableTea {
            ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.38, 0.02, 0.2, 0.18)), item.accent)
        } else if item.primary == 0x3D3656 {
            ShopPaint.fill(&context, ShopPaint.star(in: fraction(rect, 0.4, 0.2, 0.16, 0.2)), item.accent)
        }
    }

    private static func drawGarland(_ item: ShopItem, in rect: CGRect, context: inout GraphicsContext) {
        var wire = Path()
        wire.move(to: CGPoint(x: rect.minX, y: rect.midY))
        wire.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        context.stroke(wire, with: .color(Color(shopHex: item.secondary)), lineWidth: max(1.5, rect.height * 0.06))
        for index in 0..<7 {
            let x = rect.minX + rect.width * (0.06 + CGFloat(index) * 0.14)
            let y = rect.minY + rect.height * (index.isMultiple(of: 2) ? 0.15 : 0.35)
            let dot = CGRect(x: x, y: y, width: rect.height * 0.42, height: rect.height * 0.42)
            switch item.draw {
            case .garlandLights:
                let colors: [UInt32] = [0xFFE7AD, 0xFF8FAB, 0xC8E9FF, 0xC6EFDC, item.primary]
                ShopPaint.fill(&context, Path(ellipseIn: dot), colors[index % colors.count])
            case .garlandLeaf:
                ShopPaint.fill(&context, Path(ellipseIn: dot), index.isMultiple(of: 2) ? item.primary : item.secondary)
            case .garlandShell:
                ShopPaint.fill(&context, Path(ellipseIn: dot), item.primary)
                ShopPaint.stroke(&context, Path(ellipseIn: dot.insetBy(dx: 2, dy: 2)), item.accent, 0.6, 1)
            default:
                ShopPaint.fill(&context, Path(ellipseIn: dot), index.isMultiple(of: 2) ? item.primary : item.accent)
                ShopPaint.fill(&context, Path(ellipseIn: dot.insetBy(dx: dot.width * 0.3, dy: dot.height * 0.3)), 0xFFE7AD)
            }
        }
    }

    private static func drawTicket(_ item: ShopItem, in rect: CGRect, context: inout GraphicsContext) {
        let card = Path(roundedRect: rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.16), cornerRadius: 12)
        ShopPaint.fill(&context, card, 0xFFF8EF)
        ShopPaint.stroke(&context, card, item.primary, 0.8, 2)
        ShopPaint.fill(&context, Path(rect: fraction(rect, 0.14, 0.28, 0.34, 0.44)), item.primary)
        ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.2, 0.34, 0.12, 0.16)), item.accent)
        ShopPaint.fill(&context, Path(ellipseIn: fraction(rect, 0.52, 0.34, 0.08, 0.08)), item.secondary)
        ShopPaint.fill(&context, Path(rect: fraction(rect, 0.52, 0.5, 0.3, 0.06)), item.secondary, 0.7)
        ShopPaint.fill(&context, Path(rect: fraction(rect, 0.52, 0.6, 0.22, 0.05)), item.accent, 0.7)
    }
}
