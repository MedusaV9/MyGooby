import SwiftUI

// Clothing layers for Gooby's round body (masterprompt 14). Every slot draws in the rig's
// 320 x 320 design box (origin in the center), so several items show at once: garments follow the
// body outline, sleeves follow the arms, hats sit between the ears, glasses on the eyes.

enum GearPart {
    /// The item itself (garment on the body, hat, glasses, ...).
    case main
    /// Sleeves over the arms (shirt, sweater, jacket, dress).
    case sleeves
    /// Backpack bag behind the body.
    case back
    /// Backpack straps in front of the body.
    case front
}

struct GearShape: View {
    var item: ItemDef
    var pose: GoobyPose
    var part: GearPart = .main

    private var primary: Color { Color(hexString: item.color) }
    private var second: Color { Color(hexString: item.color2) }

    var body: some View {
        switch part {
        case .main: main
        case .sleeves: sleeves
        case .back: if item.slot == "backpack" { packBack }
        case .front: if item.slot == "backpack" { GoobyPackStraps(color: primary, buckle: second) }
        }
    }

    @ViewBuilder private var main: some View {
        switch item.slot {
        case "hat": hat
        case "bow": bow
        case "glasses": glasses
        case "scarf": scarf
        case "shirt": shirt
        case "sweater": sweater
        case "jacket": jacket
        case "dress": dress
        case "pants": pants
        case "shoes": shoes
        case "backpack": EmptyView()
        default: accessory
        }
    }

    // MARK: Torso

    /// Garment frame: the body outline (180 x 128 at y 88) plus a little room.
    private func garment<Decor: View>(hem: CGFloat, top: CGFloat = 0, @ViewBuilder decor: () -> Decor) -> some View {
        GoobyCloth(shape: GoobyGarmentShape(top: top, hem: hem), color: primary, decor: decor)
            .goobyAt(0, 88, 188, 134)
    }

    private var shirt: some View {
        garment(hem: 0.8) {
            ZStack {
                switch item.style {
                case 1:
                    VStack(spacing: 9) {
                        ForEach(0..<4, id: \.self) { _ in Rectangle().fill(second).frame(height: 9) }
                    }
                    .offset(y: 18)
                case 2:
                    GoobyDots(color: second, size: 9, gap: 24).offset(y: 16)
                case 3:
                    GoobyHeartShape().fill(second).frame(width: 28, height: 25).offset(y: 20)
                default:
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(second)
                        .frame(width: 24, height: 18)
                        .overlay(Rectangle().fill(Color.black.opacity(0.12)).frame(height: 2).offset(y: -5))
                        .offset(x: 36, y: 20)
                }
                GoobyGarmentShape(top: 0.74, hem: 0.8).fill(Color.black.opacity(0.1))
            }
        }
    }

    private var sweater: some View {
        garment(hem: 0.84) {
            ZStack {
                switch item.style {
                case 1:
                    Rectangle().fill(second).frame(height: 12).offset(y: 14)
                case 2:
                    GoobyDots(color: Color.white.opacity(0.6), size: 7, gap: 20).offset(y: 14)
                case 3:
                    Star(points: 5, inner: 0.5).fill(second).frame(width: 30, height: 30).offset(y: 18)
                default:
                    EmptyView()
                }
                GoobyGarmentShape(top: 0.75, hem: 0.84).fill(second)
                GoobyRibs(color: Color.black.opacity(0.12)).mask { GoobyGarmentShape(top: 0.75, hem: 0.84) }
            }
        }
    }

    private var jacket: some View {
        garment(hem: 0.88) {
            ZStack {
                if item.style == 3 {
                    Rectangle().fill(second).frame(width: 4).offset(y: 10)
                    RoundedRectangle(cornerRadius: 2).fill(second).frame(width: 8, height: 12).offset(y: 6)
                } else {
                    Rectangle().fill(second).frame(width: 18)
                    Rectangle().fill(Color.black.opacity(0.16)).frame(width: 2).offset(x: -9)
                    Rectangle().fill(Color.black.opacity(0.16)).frame(width: 2).offset(x: 9)
                    Circle().fill(second).frame(width: 7, height: 7).offset(x: -17, y: 10)
                    Circle().fill(second).frame(width: 7, height: 7).offset(x: -17, y: 28)
                }
                if item.style == 1 {
                    HStack(spacing: 18) {
                        ForEach(0..<8, id: \.self) { _ in Rectangle().fill(Color.white.opacity(0.22)).frame(width: 4) }
                    }
                    VStack(spacing: 18) {
                        ForEach(0..<6, id: \.self) { _ in Rectangle().fill(Color.white.opacity(0.22)).frame(height: 4) }
                    }
                }
                if item.style == 2 {
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(second.opacity(0.85)).frame(width: 30, height: 20).offset(x: -44, y: 30)
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(second.opacity(0.85)).frame(width: 30, height: 20).offset(x: 44, y: 30)
                }
            }
        }
    }

    private var dress: some View {
        GoobyCloth(shape: GoobyDressShape(), color: primary) {
            ZStack {
                switch item.style {
                case 1:
                    GoobyDots(color: second, size: 8, gap: 22).offset(y: 20)
                case 2:
                    HStack(spacing: 0) {
                        ForEach(0..<9, id: \.self) { _ in Circle().fill(second).frame(width: 24, height: 24) }
                    }
                    .offset(y: 60)
                case 3:
                    HStack(spacing: 14) {
                        ForEach(0..<8, id: \.self) { _ in Rectangle().fill(second.opacity(0.7)).frame(width: 10) }
                    }
                default:
                    EmptyView()
                }
                Rectangle().fill(second).frame(height: 10).offset(y: 2)
            }
        }
        .goobyAt(0, 92, 204, 136)
    }

    private var pants: some View {
        ZStack {
            if item.style == 1 {
                GoobyCloth(shape: RoundedRectangle(cornerRadius: 8, style: .continuous), color: primary)
                    .goobyAt(0, 100, 56, 36)
                Capsule().fill(primary).goobyAt(-26, 86, 9, 40)
                Capsule().fill(primary).goobyAt(26, 86, 9, 40)
                Circle().fill(second).goobyAt(-20, 94, 7, 7)
                Circle().fill(second).goobyAt(20, 94, 7, 7)
            }
            garment(hem: 1.2, top: 0.62) {
                switch item.style {
                case 2:
                    Rectangle().fill(second).frame(width: 7).offset(x: -60)
                    Rectangle().fill(second).frame(width: 7).offset(x: 60)
                case 3:
                    GoobyDots(color: second, size: 7, gap: 20).offset(y: 40)
                default:
                    Rectangle().fill(Color.black.opacity(0.12)).frame(width: 2).offset(y: 46)
                }
            }
        }
    }

    // MARK: Feet

    private var shoes: some View {
        let spread = 46 + pose.sit * 4
        let y = 138 + pose.sit * 3
        return ZStack {
            shoe.offset(x: -spread, y: y)
            shoe.offset(x: spread, y: y)
        }
    }

    private var shoe: some View {
        ZStack {
            if item.style == 2 {
                GoobyCloth(shape: RoundedRectangle(cornerRadius: 12, style: .continuous), color: primary)
                    .frame(width: 50, height: 30)
                    .offset(y: -14)
            }
            GoobyCloth(shape: Ellipse(), color: primary) {
                ZStack {
                    Capsule().fill(second).frame(height: 10).offset(y: 14)
                    if item.style == 1 {
                        HStack(spacing: 6) {
                            Circle().fill(second).frame(width: 6, height: 6)
                            Circle().fill(second).frame(width: 6, height: 6)
                        }
                        .offset(y: -6)
                    }
                    Ellipse().fill(Color.white.opacity(0.3)).frame(width: 22, height: 8).offset(x: -10, y: -6)
                }
            }
            .frame(width: 66, height: 34)
        }
    }

    // MARK: Sleeves

    @ViewBuilder private var sleeves: some View {
        switch item.slot {
        case "shirt": sleevePair(cover: 0.5, cuff: false)
        case "sweater": sleevePair(cover: 0.85, cuff: true)
        case "jacket": sleevePair(cover: 0.88, cuff: true)
        case "dress": sleevePair(cover: 0.4, cuff: false)
        default: EmptyView()
        }
    }

    private func sleevePair(cover: CGFloat, cuff: Bool) -> some View {
        ZStack {
            sleeve(cover: cover, cuff: cuff).modifier(GoobyArmPlacement(left: true, pose: pose, width: 34))
            sleeve(cover: cover, cuff: cuff).modifier(GoobyArmPlacement(left: false, pose: pose, width: 34))
        }
    }

    private func sleeve(cover: CGFloat, cuff: Bool) -> some View {
        let length = 46 * cover
        return GoobyCloth(shape: Capsule(), color: primary) {
            if cuff {
                Rectangle().fill(second).frame(height: 7).offset(y: length - 23 - 3.5)
            }
        }
        .mask(alignment: .top) {
            Rectangle().frame(height: length)
        }
    }

    // MARK: Head and neck

    private var hat: some View {
        ZStack {
            switch item.style {
            case 1:
                GoobyCloth(shape: Ellipse(), color: primary).goobyAt(0, -60, 200, 36)
                GoobyCloth(shape: GoobyDomeShape(), color: primary).goobyAt(0, -86, 112, 56)
                Capsule().fill(second).goobyAt(0, -64, 112, 12)
                GoobyFlower(petal: second, center: Color(hex: 0xFFD45E)).goobyAt(42, -68, 24, 24)
            case 2:
                GoobyCloth(shape: Ellipse(), color: primary)
                    .frame(width: 150, height: 52)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -6, y: -80)
                Capsule().fill(primary).goobyAt(-8, -108, 8, 16)
                GoobyHeartShape().fill(second).goobyAt(36, -78, 16, 14)
            case 3:
                ForEach(0..<7, id: \.self) { index in
                    let angle = (200 + Double(index) * 140 / 6) * .pi / 180
                    GoobyFlower(petal: index.isMultiple(of: 2) ? primary : second, center: Color(hex: 0xFFE7AD))
                        .goobyAt(CGFloat(cos(angle)) * 90, 4 + CGFloat(sin(angle)) * 78, 26, 26)
                }
            default:
                GoobyCloth(shape: GoobyDomeShape(), color: primary) {
                    VStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { _ in Rectangle().fill(Color.white.opacity(0.18)).frame(height: 6) }
                    }
                    .offset(y: 8)
                }
                .goobyAt(0, -74, 136, 62)
                GoobyCloth(shape: Capsule(), color: second) {
                    GoobyRibs(color: Color.black.opacity(0.12))
                }
                .goobyAt(0, -46, 146, 22)
                GoobyCloth(shape: Circle(), color: second).goobyAt(0, -106, 24, 24)
            }
        }
    }

    private var bow: some View {
        let spot: CGPoint
        let angle: Double
        let scale: CGFloat
        switch item.style {
        case 2:
            spot = CGPoint(x: -50, y: -70)
            angle = -18
            scale = 1
        case 3:
            spot = CGPoint(x: 0, y: -84)
            angle = 0
            scale = 1.3
        default:
            spot = CGPoint(x: 50, y: -70)
            angle = 18
            scale = 1
        }
        return ZStack {
            if item.style == 2 {
                Capsule().fill(primary).frame(width: 8, height: 22).rotationEffect(.degrees(16)).offset(x: -6, y: 14)
                Capsule().fill(primary).frame(width: 8, height: 22).rotationEffect(.degrees(-16)).offset(x: 6, y: 14)
            }
            loop(right: false).offset(x: -15)
            loop(right: true).offset(x: 15)
            GoobyCloth(shape: Circle(), color: second).frame(width: 13, height: 13)
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(angle))
        .offset(x: spot.x, y: spot.y)
    }

    private func loop(right: Bool) -> some View {
        GoobyCloth(shape: Ellipse(), color: primary) {
            if item.style == 1 {
                GoobyDots(color: Color.white.opacity(0.75), size: 4, gap: 9)
            }
        }
        .frame(width: 30, height: 22)
        .rotationEffect(.degrees(right ? -18 : 18))
    }

    private var glasses: some View {
        ZStack {
            lens.offset(x: -40, y: 10)
            lens.offset(x: 40, y: 10)
            Capsule().fill(primary).goobyAt(0, 4, 16, 5)
        }
    }

    @ViewBuilder private var lens: some View {
        switch item.style {
        case 1:
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(primary, lineWidth: 5))
                .frame(width: 58, height: 50)
        case 2:
            GoobyHeartShape().fill(primary.opacity(0.3))
                .overlay(GoobyHeartShape().stroke(primary, lineWidth: 5))
                .frame(width: 58, height: 52)
        case 3:
            Star(points: 5, inner: 0.55).fill(primary.opacity(0.35))
                .overlay(Star(points: 5, inner: 0.55).stroke(primary, style: StrokeStyle(lineWidth: 5, lineJoin: .round)))
                .frame(width: 64, height: 64)
        default:
            Circle().fill(Color.white.opacity(0.18))
                .overlay(Circle().stroke(primary, lineWidth: 5))
                .frame(width: 54, height: 54)
        }
    }

    private var scarf: some View {
        ZStack {
            GoobyCloth(shape: RoundedRectangle(cornerRadius: 10, style: .continuous), color: primary) { scarfPattern }
                .frame(width: 26, height: 50)
                .rotationEffect(.degrees(-8))
                .offset(x: 44, y: 116)
            if item.style == 2 {
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in Capsule().fill(second).frame(width: 3, height: 9) }
                }
                .rotationEffect(.degrees(-8))
                .offset(x: 47, y: 144)
            }
            GoobyCloth(shape: Capsule(), color: primary) { scarfPattern }
                .goobyAt(0, 88, 168, 30)
        }
    }

    @ViewBuilder private var scarfPattern: some View {
        switch item.style {
        case 1:
            HStack(spacing: 12) {
                ForEach(0..<12, id: \.self) { _ in Rectangle().fill(second).frame(width: 10) }
            }
        case 3:
            GoobyDots(color: second, size: 6, gap: 14)
        default:
            EmptyView()
        }
    }

    private var accessory: some View {
        ZStack {
            switch item.style {
            case 1:
                Star(points: 5, inner: 0.5).fill(primary)
                    .overlay(Star(points: 5, inner: 0.5).stroke(second, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)))
                    .goobyAt(-50, 110, 30, 30)
            case 2:
                Capsule().fill(second).goobyAt(0, 90, 120, 8)
                ZStack {
                    Circle().fill(primary)
                    Circle().fill(LinearGradient(colors: [Color.white.opacity(0.45), Color.clear], startPoint: .topLeading, endPoint: .center))
                    Capsule().fill(Color.black.opacity(0.3)).frame(width: 10, height: 3).offset(y: 4)
                    Circle().stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                }
                .goobyAt(0, 100, 20, 20)
            default:
                GoobyFlower(petal: primary, center: second).goobyAt(52, 108, 28, 28)
            }
        }
    }

    // MARK: Backpack

    private var packBack: some View {
        ZStack {
            GoobyCloth(shape: RoundedRectangle(cornerRadius: 24, style: .continuous), color: primary) {
                if item.style == 2 {
                    GoobyDots(color: second, size: 8, gap: 20)
                }
                if item.style == 3 {
                    Star(points: 5, inner: 0.5).fill(second).frame(width: 26, height: 26).offset(x: 14, y: 12)
                }
            }
            .goobyAt(86, 62, 84, 100)
            GoobyCloth(shape: RoundedRectangle(cornerRadius: 16, style: .continuous), color: second)
                .goobyAt(86, 26, 84, 34)
            if item.style == 1 {
                GoobyCloth(shape: RoundedRectangle(cornerRadius: 10, style: .continuous), color: second)
                    .goobyAt(100, 84, 40, 30)
            }
        }
    }
}

/// Red adventure backpack: the bag and bedroll peek out behind Gooby, the straps sit in front.
struct AdventurePackLayer: View {
    var front: Bool

    var body: some View {
        if front {
            GoobyPackStraps(color: Color(hex: 0xC93A3F), buckle: Color(hex: 0xFFD45E))
        } else {
            ZStack {
                GoobyCloth(shape: Capsule(), color: Color(hex: 0xE8C9A0)) {
                    HStack(spacing: 22) {
                        Rectangle().fill(Color(hex: 0x9B6B43)).frame(width: 5)
                        Rectangle().fill(Color(hex: 0x9B6B43)).frame(width: 5)
                    }
                }
                .goobyAt(92, 4, 92, 26)
                GoobyCloth(shape: RoundedRectangle(cornerRadius: 24, style: .continuous), color: Color(hex: 0xE5484D)) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0xC93A3F))
                        .frame(width: 44, height: 30)
                        .offset(x: 14, y: 26)
                }
                .goobyAt(90, 60, 90, 104)
                GoobyCloth(shape: RoundedRectangle(cornerRadius: 16, style: .continuous), color: Color(hex: 0xC93A3F))
                    .goobyAt(90, 26, 90, 36)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(hex: 0xFFD45E))
                    .goobyAt(104, 42, 14, 10)
            }
        }
    }
}

/// Two backpack straps over the shoulders with small buckles.
struct GoobyPackStraps: View {
    var color: Color
    var buckle: Color

    var body: some View {
        ZStack {
            strap.rotationEffect(.degrees(8)).offset(x: -42, y: 104)
            strap.rotationEffect(.degrees(-8)).offset(x: 42, y: 104)
        }
    }

    private var strap: some View {
        ZStack {
            Capsule().fill(color)
            Capsule().stroke(Color.black.opacity(0.15), lineWidth: 1.5)
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(buckle).frame(width: 14, height: 8).offset(y: 6)
        }
        .frame(width: 12, height: 44)
    }
}

// MARK: - Cloth helpers

/// Fabric fill: flat color, an optional pattern clipped to the shape, soft shading and a seam.
struct GoobyCloth<S: Shape, Decor: View>: View {
    var shape: S
    var color: Color
    var decor: Decor

    init(shape: S, color: Color, @ViewBuilder decor: () -> Decor) {
        self.shape = shape
        self.color = color
        self.decor = decor()
    }

    var body: some View {
        ZStack {
            shape.fill(color)
            decor.clipShape(shape)
            shape.fill(EllipticalGradient(
                stops: [
                    .init(color: Color.white.opacity(0.3), location: 0),
                    .init(color: Color.white.opacity(0), location: 0.45),
                    .init(color: Color.black.opacity(0.14), location: 1)
                ],
                center: UnitPoint(x: 0.36, y: 0.25),
                endRadiusFraction: 0.8
            ))
            shape.stroke(Color.black.opacity(0.16), lineWidth: 2)
        }
    }
}

extension GoobyCloth where Decor == EmptyView {
    init(shape: S, color: Color) {
        self.init(shape: shape, color: color) { EmptyView() }
    }
}

/// The body outline between `top` and a gently curved hem at `hem` (fractions of the height).
struct GoobyGarmentShape: Shape {
    var top: CGFloat = 0
    var hem: CGFloat
    var sag: CGFloat = 0.06

    func path(in rect: CGRect) -> Path {
        let outline = GoobyBlobShape(widest: 0.6).path(in: rect)
        var cut = Path()
        let left = rect.minX - 40
        let right = rect.maxX + 40
        cut.move(to: CGPoint(x: left, y: rect.minY + rect.height * top))
        cut.addLine(to: CGPoint(x: right, y: rect.minY + rect.height * top))
        cut.addLine(to: CGPoint(x: right, y: rect.minY + rect.height * hem))
        cut.addQuadCurve(to: CGPoint(x: left, y: rect.minY + rect.height * hem), control: CGPoint(x: rect.midX, y: rect.minY + rect.height * (hem + sag * 2)))
        cut.closeSubpath()
        return Path(outline.cgPath.intersection(cut.cgPath))
    }
}

/// A-line dress: narrow at the chest, flared and round at the hem.
struct GoobyDressShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x + w * 0.18, y: y))
        path.addLine(to: CGPoint(x: x + w * 0.82, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: y + h * 0.9), control1: CGPoint(x: x + w * 0.98, y: y + h * 0.15), control2: CGPoint(x: x + w, y: y + h * 0.6))
        path.addQuadCurve(to: CGPoint(x: x, y: y + h * 0.9), control: CGPoint(x: x + w * 0.5, y: y + h * 1.08))
        path.addCurve(to: CGPoint(x: x + w * 0.18, y: y), control1: CGPoint(x: x, y: y + h * 0.6), control2: CGPoint(x: x + w * 0.02, y: y + h * 0.15))
        path.closeSubpath()
        return path
    }
}

/// Round crown with a flat bottom (beanie, hat crown).
struct GoobyDomeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + h))
        path.addCurve(to: CGPoint(x: x + w / 2, y: y), control1: CGPoint(x: x, y: y + h * 0.4), control2: CGPoint(x: x + w * 0.2, y: y))
        path.addCurve(to: CGPoint(x: x + w, y: y + h), control1: CGPoint(x: x + w * 0.8, y: y), control2: CGPoint(x: x + w, y: y + h * 0.4))
        path.closeSubpath()
        return path
    }
}

/// Polka dots filling the proposed frame.
struct GoobyDots: View {
    var color: Color
    var size: CGFloat
    var gap: CGFloat

    var body: some View {
        VStack(spacing: gap - size) {
            ForEach(0..<10, id: \.self) { row in
                HStack(spacing: gap - size) {
                    ForEach(0..<14, id: \.self) { _ in Circle().fill(color).frame(width: size, height: size) }
                }
                .offset(x: row.isMultiple(of: 2) ? 0 : gap / 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Vertical knit ribs.
struct GoobyRibs: View {
    var color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<30, id: \.self) { _ in Rectangle().fill(color).frame(width: 2) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Five round petals around a center.
struct GoobyFlower: View {
    var petal: Color
    var center: Color

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    let angle = Double(index) * 2 * .pi / 5 - .pi / 2
                    Circle()
                        .fill(petal)
                        .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 1))
                        .frame(width: side * 0.46, height: side * 0.46)
                        .offset(x: CGFloat(cos(angle)) * side * 0.28, y: CGFloat(sin(angle)) * side * 0.28)
                }
                Circle().fill(center).frame(width: side * 0.36, height: side * 0.36)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
