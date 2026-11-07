import SwiftUI

/// Gooby's room as a flat illustration: striped wall, wainscot, plank floor, a window that follows
/// the time of day, and the furniture slots of `RoomLayout`. `fullBleed` fills the frame edge to
/// edge (Home scene, under the status bar by `topInset`); otherwise it is a rounded card (editor).
struct RoomDiorama: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    /// Shop preview: furniture shows in its slot, clothing on Gooby.
    var preview: ItemDef? = nil
    var fullBleed: Bool = false
    var topInset: CGFloat = 0
    var showsGooby: Bool = true

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            let phase = HomeSceneView.phase(at: engine.now())
            GeometryReader { geo in
                room(RoomGeometry(size: geo.size, top: topInset), phase: phase)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: fullBleed ? 0 : 32, style: .continuous))
        .overlay {
            if !fullBleed {
                RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Theme.ink.opacity(0.06), lineWidth: 1)
            }
        }
    }

    /// Wall color of the current room (Home uses it above the scene).
    static func wallColor(_ engine: GoobyEngine) -> Color {
        guard let item = engine.catalog.itemsByID[engine.roomItem("wall")] else { return Color(hex: 0xFFF1E4) }
        return Color(hexString: item.color)
    }

    private func room(_ geometry: RoomGeometry, phase: DaylightPhase) -> some View {
        ZStack(alignment: .topLeading) {
            RoomShell(
                wall: color("wall") ?? Color(hex: 0xFFF1E4),
                wallAccent: accent("wall") ?? Color(hex: 0xFFF8EF),
                floor: color("floor") ?? Theme.peach,
                geometry: geometry
            )
            window(geometry, phase: phase)
            furniture(geometry)
            if showsGooby { gooby(geometry) }
            lighting(geometry, phase: phase)
        }
        .frame(width: geometry.w, height: geometry.h)
        .accessibilityHidden(!showsGooby)
    }

    // MARK: Window

    private func window(_ geometry: RoomGeometry, phase: DaylightPhase) -> some View {
        let width = geometry.w * 0.34
        let height = geometry.roomHeight * 0.32
        let id = itemID("window")
        let style: RoomWindowStyle = id.contains("round") ? .round : (id.contains("arch") || id.contains("heart") ? .arch : .square)
        let frame = accent("window") ?? Color(hex: 0xFFF8EF)
        return ZStack {
            RoomCurtains(width: width, height: height)
            RoomWindowGlyph(phase: phase, frameColor: frame, style: style, heart: id.contains("heart"))
                .frame(width: style == .round ? min(width, height) : width, height: style == .round ? min(width, height) : height)
            Capsule()
                .fill(frame)
                .overlay(Capsule().fill(Color.black.opacity(0.08)))
                .frame(width: width + 18, height: 9)
                .offset(y: (style == .round ? min(width, height) : height) / 2 + 3)
        }
        .position(x: geometry.w / 2, y: geometry.y(0.10) + height / 2)
    }

    // MARK: Furniture

    private func furniture(_ geometry: RoomGeometry) -> some View {
        ZStack(alignment: .topLeading) {
            piece("rug", geometry, x: 0.5, y: 0.9, wide: true)
            piece("picture", geometry, x: 0.15, y: 0.29)
            piece("shelf", geometry, x: 0.85, y: 0.33)
            piece("seasonal", geometry, x: 0.27, y: 0.49)
            piece("plant", geometry, x: 0.075, y: 0.62)
            piece("lamp", geometry, x: 0.935, y: 0.58)
            piece("bed", geometry, x: 0.2, y: 0.79)
            piece("sofa", geometry, x: 0.8, y: 0.78)
            piece("table", geometry, x: 0.8, y: 0.93)
            piece("cushion", geometry, x: 0.12, y: 0.94)
        }
    }

    @ViewBuilder
    private func piece(_ slot: String, _ geometry: RoomGeometry, x: CGFloat, y: CGFloat, wide: Bool = false) -> some View {
        let id = itemID(slot)
        if !id.isEmpty {
            FurnitureGlyph(slot: slot, color: color(slot) ?? Theme.lavender, wide: wide, accent: accent(slot))
                .scaleEffect(geometry.scale)
                .position(x: x * geometry.w, y: geometry.y(y))
        }
    }

    private func gooby(_ geometry: RoomGeometry) -> some View {
        let width = min(geometry.w * 0.5, 210)
        let feet = geometry.h * 0.9
        return GoobyCharacterView(
            look: engine.wornLook(preview: preview),
            stage: Growth.stage(of: engine.pet),
            animation: engine.animation,
            reduceMotion: reduceMotion,
            companion: engine.companionSpecies()
        )
        .frame(width: width, height: width * 1.1)
        .position(x: geometry.w / 2, y: feet - width * 0.375)
    }

    private func lighting(_ geometry: RoomGeometry, phase: DaylightPhase) -> some View {
        let color: Color
        let amount: Double
        switch phase {
        case .morning: color = Theme.yellow; amount = 0.14
        case .day: color = .clear; amount = 0
        case .evening: color = Theme.peach; amount = 0.2
        case .night: color = Color(hex: 0x4E5384); amount = 0.32
        }
        let lampLit = (phase == .night || phase == .evening) && !itemID("lamp").isEmpty
        return ZStack(alignment: .topLeading) {
            color.opacity(amount)
            if lampLit {
                Circle()
                    .fill(RadialGradient(colors: [Theme.yellow.opacity(phase == .night ? 0.55 : 0.35), Theme.yellow.opacity(0)], center: .center, startRadius: 0, endRadius: 70 * geometry.scale))
                    .frame(width: 140 * geometry.scale, height: 140 * geometry.scale)
                    .position(x: geometry.w * 0.935, y: geometry.y(0.58) - 22 * geometry.scale)
            }
        }
        .frame(width: geometry.w, height: geometry.h)
        .allowsHitTesting(false)
    }

    // MARK: Catalog

    /// Item in `slot`, with the shop preview taking its slot.
    private func itemID(_ slot: String) -> String {
        if let preview, preview.kind == "furniture", preview.slot == slot { return preview.id }
        return engine.roomItem(slot)
    }

    private func color(_ slot: String) -> Color? {
        guard let item = engine.catalog.itemsByID[itemID(slot)] else { return nil }
        return Color(hexString: item.color)
    }

    private func accent(_ slot: String) -> Color? {
        guard let item = engine.catalog.itemsByID[itemID(slot)], !item.color2.isEmpty else { return nil }
        return Color(hexString: item.color2)
    }
}

/// Positions inside the room: `y` fractions run over the part below `top`.
struct RoomGeometry {
    let w: CGFloat
    let h: CGFloat
    let top: CGFloat

    init(size: CGSize, top: CGFloat) {
        w = max(1, size.width)
        h = max(1, size.height)
        self.top = top
    }

    var roomHeight: CGFloat { max(1, h - top) }
    var floorY: CGFloat { y(0.68) }
    /// Furniture scale against a 300 x 250 room.
    var scale: CGFloat { min(1.55, max(0.8, min(w / 300, roomHeight / 250))) }

    func y(_ fraction: CGFloat) -> CGFloat { top + fraction * roomHeight }
}

/// Wall with soft stripes, wainscot with a light trim, baseboard and plank floor.
struct RoomShell: View {
    var wall: Color
    var wallAccent: Color
    var floor: Color
    var geometry: RoomGeometry

    var body: some View {
        Canvas { ctx, size in
            let floorY = geometry.floorY
            let wainscot = geometry.y(0.54)
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(wall))
            var x: CGFloat = 10
            while x < size.width {
                ctx.fill(Path(CGRect(x: x, y: 0, width: 11, height: wainscot)), with: .color(wallAccent.opacity(0.5)))
                x += 30
            }
            ctx.fill(Path(CGRect(x: 0, y: wainscot, width: size.width, height: floorY - wainscot)), with: .color(Color.black.opacity(0.035)))
            ctx.fill(Path(CGRect(x: 0, y: wainscot, width: size.width, height: 5)), with: .color(Color.white.opacity(0.6)))
            ctx.fill(Path(CGRect(x: 0, y: floorY, width: size.width, height: size.height - floorY)), with: .color(floor))
            var row: CGFloat = floorY + 16
            var shift = false
            while row < size.height {
                ctx.fill(Path(CGRect(x: 0, y: row, width: size.width, height: 1.5)), with: .color(Color.black.opacity(0.06)))
                var joint: CGFloat = shift ? 40 : 90
                while joint < size.width {
                    ctx.fill(Path(CGRect(x: joint, y: row - 16, width: 1.5, height: 16)), with: .color(Color.black.opacity(0.05)))
                    joint += 120
                }
                shift.toggle()
                row += 18
            }
            ctx.fill(Path(CGRect(x: 0, y: floorY - 4, width: size.width, height: 9)), with: .color(floor))
            ctx.fill(Path(CGRect(x: 0, y: floorY - 4, width: size.width, height: 9)), with: .color(Color.black.opacity(0.13)))
        }
        .accessibilityHidden(true)
    }
}

enum RoomWindowStyle {
    case round, arch, square
}

/// Window glass with the sky of the daylight phase, sun or crescent moon, mullions and a frame.
struct RoomWindowGlyph: View {
    var phase: DaylightPhase
    var frameColor: Color
    var style: RoomWindowStyle
    var heart: Bool

    var body: some View {
        GeometryReader { geo in
            let shape = outline(geo.size)
            ZStack {
                shape.fill(LinearGradient(colors: sky, startPoint: .top, endPoint: .bottom))
                celestial(geo.size)
                Rectangle().fill(frameColor).frame(width: 5)
                Rectangle().fill(frameColor).frame(height: 5).offset(y: geo.size.height * 0.08)
                if heart {
                    Image(systemName: "heart.fill")
                        .font(.system(size: geo.size.width * 0.14))
                        .foregroundStyle(Theme.pink)
                        .offset(y: -geo.size.height * 0.22)
                }
            }
            .clipShape(shape)
            .overlay(shape.stroke(frameColor, lineWidth: 7))
            .overlay(shape.stroke(Color.black.opacity(0.06), lineWidth: 7))
        }
        .accessibilityHidden(true)
    }

    private func outline(_ size: CGSize) -> AnyShape {
        switch style {
        case .round:
            return AnyShape(Circle())
        case .arch:
            let radius = size.width / 2
            return AnyShape(UnevenRoundedRectangle(topLeadingRadius: radius, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: radius, style: .continuous))
        case .square:
            return AnyShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private static let stars: [CGPoint] = [
        CGPoint(x: -0.25, y: -0.25), CGPoint(x: -0.1, y: 0.3), CGPoint(x: 0.12, y: 0.25), CGPoint(x: -0.3, y: 0.1)
    ]

    private var sky: [Color] {
        switch phase {
        case .morning: return [Color(hex: 0xFFE7AD), Color(hex: 0xFFD6B3)]
        case .day: return [Color(hex: 0x9FD6F5), Color(hex: 0xD6F0FB)]
        case .evening: return [Color(hex: 0x6C78BE), Color(hex: 0xE5A9B8)]
        case .night: return [Color(hex: 0x2D3456), Color(hex: 0x56609A)]
        }
    }

    @ViewBuilder
    private func celestial(_ size: CGSize) -> some View {
        let side = size.width * 0.22
        switch phase {
        case .morning, .day:
            Circle()
                .fill(Color(hex: 0xFFF1A8))
                .frame(width: side, height: side)
                .shadow(color: Color(hex: 0xFFE27A).opacity(0.8), radius: 8)
                .offset(x: size.width * 0.18, y: -size.height * 0.18)
            Capsule().fill(Color.white.opacity(0.9)).frame(width: side * 1.5, height: side * 0.45)
                .offset(x: -size.width * 0.2, y: size.height * 0.26)
        case .evening, .night:
            ZStack {
                Circle().fill(Theme.Tab.home.moon).frame(width: side, height: side)
                Circle().fill(sky[0]).frame(width: side * 0.8, height: side * 0.8).offset(x: side * 0.28, y: -side * 0.12)
            }
            .offset(x: size.width * 0.2, y: -size.height * 0.2)
            ForEach(0..<RoomWindowGlyph.stars.count, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 2.5, height: 2.5)
                    .offset(x: size.width * RoomWindowGlyph.stars[index].x, y: size.height * RoomWindowGlyph.stars[index].y)
            }
        }
    }
}

/// Pink curtains tied back at both sides of the window, on a wooden rod.
struct RoomCurtains: View {
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        let drape = Color(hex: 0xF7BFD3)
        ZStack {
            RoomDrapeShape()
                .fill(drape)
                .frame(width: width * 0.3, height: height * 1.1)
                .offset(x: -width * 0.58, y: height * 0.02)
            RoomDrapeShape()
                .fill(drape)
                .frame(width: width * 0.3, height: height * 1.1)
                .scaleEffect(x: -1)
                .offset(x: width * 0.58, y: height * 0.02)
            Capsule()
                .fill(Color(hex: 0xC99A6E))
                .frame(width: width * 1.62, height: 6)
                .offset(y: -height * 0.53)
        }
        .accessibilityHidden(true)
    }
}

/// Curtain panel whose inner edge is gathered at about 55 % height.
struct RoomDrapeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.minY + rect.height * 0.56), control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.4))
        path.addQuadCurve(to: CGPoint(x: rect.maxX * 0.9, y: rect.maxY), control: CGPoint(x: rect.minX + rect.width * 0.4, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Flat furniture drawings for each room slot, colored by the catalog item (`color`) with its
/// second color as `accent`.
struct FurnitureGlyph: View {
    var slot: String
    var color: Color
    var wide: Bool
    var accent: Color? = nil

    private let wood = Color(hex: 0xC99A6E)
    private let woodDark = Color(hex: 0xA87A50)
    private static let sag: [CGFloat] = [2, 5, 6, 5, 2]
    private var second: Color { accent ?? color }

    var body: some View {
        glyph.accessibilityHidden(true)
    }

    @ViewBuilder private var glyph: some View {
        switch slot {
        case "bed": bed
        case "rug": rug
        case "lamp": lamp
        case "plant": plant
        case "shelf": shelf
        case "picture": picture
        case "sofa": sofa
        case "table": table
        case "cushion": cushion
        default: bunting
        }
    }

    private var bed: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(wood).frame(width: 16, height: 50).offset(x: -40, y: -6)
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(wood).frame(width: 11, height: 28).offset(x: 41, y: 5)
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(woodDark).frame(width: 88, height: 12).offset(y: 16)
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white).frame(width: 78, height: 16).offset(y: 4)
            Capsule().fill(Color.white)
                .overlay(Capsule().stroke(second.opacity(0.7), lineWidth: 1.5))
                .frame(width: 24, height: 13).offset(x: -24, y: -6)
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.black.opacity(0.07), lineWidth: 1.5))
                .frame(width: 52, height: 22).offset(x: 12, y: 5)
            RoundedRectangle(cornerRadius: 2).fill(second).frame(width: 52, height: 4).offset(x: 12, y: -3)
            RoundedRectangle(cornerRadius: 2).fill(woodDark).frame(width: 5, height: 7).offset(x: -38, y: 24)
            RoundedRectangle(cornerRadius: 2).fill(woodDark).frame(width: 5, height: 7).offset(x: 38, y: 24)
        }
    }

    private var rug: some View {
        ZStack {
            Ellipse().fill(color).frame(width: wide ? 180 : 92, height: 30)
            Ellipse().stroke(second, style: StrokeStyle(lineWidth: 3, dash: [6, 5])).frame(width: wide ? 150 : 74, height: 20)
            Ellipse().stroke(Color.black.opacity(0.06), lineWidth: 2).frame(width: wide ? 180 : 92, height: 30)
        }
    }

    private var lamp: some View {
        ZStack {
            Ellipse().fill(woodDark).frame(width: 24, height: 7).offset(y: 34)
            Capsule().fill(Color(hex: 0x8C7A6B)).frame(width: 3.5, height: 52).offset(y: 8)
            RoomLampShadeShape().fill(color)
                .overlay(RoomLampShadeShape().fill(Color.black.opacity(0.06)).frame(width: 17).offset(x: 8.5))
                .frame(width: 34, height: 24).offset(y: -26)
            Capsule().fill(second.opacity(0.9)).frame(width: 30, height: 4).offset(y: -15)
        }
    }

    private var plant: some View {
        ZStack {
            leaf.rotationEffect(.degrees(-38)).offset(x: -10, y: -14)
            leaf.rotationEffect(.degrees(34)).offset(x: 10, y: -16)
            leaf.scaleEffect(1.1).offset(y: -22)
            leaf.scaleEffect(0.8).rotationEffect(.degrees(-70)).offset(x: -14, y: -4)
            leaf.scaleEffect(0.8).rotationEffect(.degrees(66)).offset(x: 14, y: -5)
            RoomPotShape().fill(Color(hex: 0xD9895B)).frame(width: 28, height: 22).offset(y: 12)
            Capsule().fill(Color(hex: 0xC4744A)).frame(width: 32, height: 6).offset(y: 2)
        }
    }

    private var leaf: some View {
        Ellipse()
            .fill(LinearGradient(colors: [color, second], startPoint: .top, endPoint: .bottom))
            .overlay(Capsule().fill(Color.white.opacity(0.25)).frame(width: 1.5, height: 14))
            .frame(width: 13, height: 26)
    }

    private var shelf: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 2) {
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 8, height: 20)
                RoundedRectangle(cornerRadius: 2).fill(second).frame(width: 7, height: 24)
                RoundedRectangle(cornerRadius: 2).fill(Color.white).frame(width: 6, height: 17)
                RoundedRectangle(cornerRadius: 2).fill(color).overlay(Color.black.opacity(0.1)).frame(width: 8, height: 22).rotationEffect(.degrees(12))
                Spacer().frame(width: 6)
                ZStack(alignment: .bottom) {
                    Circle().fill(Color(hex: 0x7DCAA8)).frame(width: 14, height: 14).offset(y: -8)
                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xD9895B)).frame(width: 11, height: 9)
                }
            }
            .padding(.bottom, 6)
            RoundedRectangle(cornerRadius: 3).fill(wood).frame(width: 62, height: 6)
        }
        .frame(width: 66, height: 34)
    }

    private var picture: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(wood).frame(width: 42, height: 34)
            RoundedRectangle(cornerRadius: 3, style: .continuous).fill(color).frame(width: 34, height: 26)
            RoomHillShape().fill(second).frame(width: 34, height: 12).offset(y: 7)
            Circle().fill(Color(hex: 0xFFE27A)).frame(width: 7, height: 7).offset(x: 8, y: -5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private var sofa: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color).frame(width: 74, height: 30).offset(y: -11)
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.black.opacity(0.07)))
                .frame(width: 74, height: 20).offset(y: 9)
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.35)).frame(width: 27, height: 12)
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.35)).frame(width: 27, height: 12)
            }
            .offset(y: -1)
            RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color)
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.black.opacity(0.1)))
                .frame(width: 13, height: 30).offset(x: -38, y: 4)
            RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color)
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.black.opacity(0.1)))
                .frame(width: 13, height: 30).offset(x: 38, y: 4)
            Circle().fill(second).frame(width: 12, height: 12).offset(x: -24, y: -12)
            RoundedRectangle(cornerRadius: 2).fill(woodDark).frame(width: 5, height: 6).offset(x: -30, y: 21)
            RoundedRectangle(cornerRadius: 2).fill(woodDark).frame(width: 5, height: 6).offset(x: 30, y: 21)
        }
    }

    private var table: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2).fill(woodDark).frame(width: 5, height: 18).offset(x: -16, y: 8)
            RoundedRectangle(cornerRadius: 2).fill(woodDark).frame(width: 5, height: 18).offset(x: 16, y: 8)
            Ellipse().fill(color).overlay(Ellipse().fill(Color.black.opacity(0.1)).offset(y: 3).clipShape(Ellipse())).frame(width: 54, height: 14)
            Ellipse().fill(color).frame(width: 54, height: 11).offset(y: -1.5)
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(Color.white).frame(width: 10, height: 8)
                Circle().stroke(Color.white, lineWidth: 2).frame(width: 5, height: 5).offset(x: 6)
            }
            .offset(x: 6, y: -9)
        }
    }

    private var cushion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color).frame(width: 40, height: 24)
            RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(second, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])).frame(width: 32, height: 17)
            Circle().fill(second).frame(width: 5, height: 5)
        }
    }

    /// Seasonal decor: bunting with alternating pennants.
    private var bunting: some View {
        ZStack(alignment: .top) {
            RoomGarlandShape().stroke(woodDark, lineWidth: 1.5).frame(width: 74, height: 10)
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Triangle()
                        .fill(index.isMultiple(of: 2) ? color : second)
                        .overlay(Triangle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                        .frame(width: 11, height: 13)
                        .rotationEffect(.degrees(180))
                        .offset(y: FurnitureGlyph.sag[index])
                }
            }
        }
        .frame(width: 76, height: 22)
    }
}

/// Trapezoid lamp shade, narrow at the top.
struct RoomLampShadeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Flower pot, wide at the top.
struct RoomPotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Rolling hill for the framed picture.
struct RoomHillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY), control: CGPoint(x: rect.width * 0.25, y: rect.minY - rect.height * 0.4))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.3), control: CGPoint(x: rect.width * 0.8, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Sagging string of the bunting.
struct RoomGarlandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        return path
    }
}

/// Room editor: preview on top, one card per slot with the owned items as chips.
struct RoomEditorSheet: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    private let slots = ["wall", "floor", "bed", "rug", "lamp", "window", "plant", "shelf", "picture", "sofa", "table", "cushion", "seasonal"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.gap) {
                    RoomDiorama(engine: engine, reduceMotion: engine.reduceMotion)
                        .frame(height: 280)
                    ForEach(slots, id: \.self) { slot in
                        slotCard(slot)
                    }
                }
                .padding(.horizontal, Theme.Space.margin)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(Theme.Tab.pet.bgTop.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) { header }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack {
            Text(engine.t("today.room.edit"))
                .font(Theme.Fonts.title)
                .foregroundStyle(Theme.brown)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(engine.t("common.done")) { dismiss() }
                .buttonStyle(Press3DButtonStyle(fill: .white, edge: Theme.Tab.pet.pill, radius: 14, horizontal: 16, vertical: 8))
                .foregroundStyle(Theme.brown)
        }
        .padding(.horizontal, Theme.Space.margin)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(Theme.Tab.pet.bgTop)
    }

    private func slotCard(_ slot: String) -> some View {
        let current = engine.roomItem(slot)
        let items = owned(slot)
        return GCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(engine.t("slot.\(slot)"))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.text)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip(engine.t("room.empty"), swatch: nil, selected: current.isEmpty) { engine.unequip(slot: slot) }
                        ForEach(items) { item in
                            chip(item.name.text(engine.languageCode), swatch: Color(hexString: item.color), selected: current == item.id) {
                                engine.equip(item)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                if items.isEmpty {
                    Text(engine.tx("home.room.more", de: "Mehr Möbel gibt es im Laden.", en: "More furniture is in the shop."))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                }
            }
        }
    }

    private func chip(_ title: String, swatch: Color?, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let swatch {
                    Circle().fill(swatch).overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1)).frame(width: 14, height: 14)
                }
                Text(title).lineLimit(1)
            }
            .foregroundStyle(selected ? Color.white : Theme.text)
        }
        .buttonStyle(Press3DButtonStyle(
            fill: selected ? Theme.rose : Theme.keyFace,
            edge: selected ? Color(hex: 0xC96F94) : Theme.keyEdge,
            radius: 14,
            horizontal: 14,
            vertical: 8
        ))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func owned(_ slot: String) -> [ItemDef] {
        engine.all(OwnedItem.self).compactMap { row in
            guard let item = engine.catalog.itemsByID[row.catalogID], item.slot == slot else { return nil }
            return item
        }
    }
}
