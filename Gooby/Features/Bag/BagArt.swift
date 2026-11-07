import SwiftUI

// Drawn art of the bag tab (screen 7): the night sky with hills, Gooby's red bindle sack, the
// yellow name tag and small tile glyphs. Original vector art, no image assets.

/// Art colors of this slice that are not in the shared palette.
enum BagArtInk {
    static let hillsFar = Color(hex: 0x2F4C3A)
    static let star = Color(hex: 0xFFF3C4)
    static let moon = Color(hex: 0xF4F0D2)
    static let sackDark = Color(hex: 0xC93A3F)
    static let sackShine = Color(hex: 0xF27A7E)
    static let stick = Color(hex: 0x9A6B43)
    static let stickDark = Color(hex: 0x7A5233)
    static let tagText = Color(hex: 0x6E5434)
    static let paw = Color(hex: 0x9A6B43)
    static let lockedLabel = Color.white
}

/// Dark navy night with stars, a pale moon and dark green hill silhouettes along the bottom.
struct BagNightArt: View {
    var body: some View {
        Canvas { context, size in
            BagNightPainter.draw(&context, size: size)
        }
        .background(Theme.Tab.bag.night)
        .accessibilityHidden(true)
    }
}

/// Drawing of `BagNightArt` (a plain enum, so the canvas can call it from any context).
enum BagNightPainter {
    private static let stars: [(CGFloat, CGFloat, CGFloat)] = [
        (0.08, 0.22, 2.0), (0.18, 0.48, 1.5), (0.27, 0.16, 2.5), (0.36, 0.38, 1.5), (0.45, 0.12, 1.8),
        (0.56, 0.30, 2.2), (0.63, 0.52, 1.4), (0.70, 0.18, 1.6), (0.80, 0.40, 2.4), (0.92, 0.26, 1.6),
        (0.12, 0.66, 1.3), (0.88, 0.62, 1.3), (0.40, 0.58, 1.2)
    ]

    static func draw(_ context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        for star in stars {
            let r = star.2
            context.fill(Path(ellipseIn: CGRect(x: star.0 * w - r, y: star.1 * h - r, width: r * 2, height: r * 2)), with: .color(BagArtInk.star.opacity(0.9)))
        }
        // Two sparkle stars.
        for spot in [CGPoint(x: 0.22 * w, y: 0.30 * h), CGPoint(x: 0.74 * w, y: 0.32 * h)] {
            var sparkle = Path()
            let s: CGFloat = 6
            sparkle.move(to: CGPoint(x: spot.x, y: spot.y - s))
            sparkle.addQuadCurve(to: CGPoint(x: spot.x + s, y: spot.y), control: spot)
            sparkle.addQuadCurve(to: CGPoint(x: spot.x, y: spot.y + s), control: spot)
            sparkle.addQuadCurve(to: CGPoint(x: spot.x - s, y: spot.y), control: spot)
            sparkle.addQuadCurve(to: CGPoint(x: spot.x, y: spot.y - s), control: spot)
            context.fill(sparkle, with: .color(BagArtInk.star))
        }
        // Moon.
        let moon = CGRect(x: 0.10 * w, y: 0.24 * h, width: 34, height: 34)
        context.fill(Path(ellipseIn: moon), with: .color(BagArtInk.moon))
        context.fill(Path(ellipseIn: moon.offsetBy(dx: 10, dy: -5)), with: .color(Theme.Tab.bag.night))
        // Hills.
        context.fill(Path(ellipseIn: CGRect(x: -0.25 * w, y: 0.70 * h, width: 0.85 * w, height: 0.70 * h)), with: .color(BagArtInk.hillsFar))
        context.fill(Path(ellipseIn: CGRect(x: 0.45 * w, y: 0.62 * h, width: 0.90 * w, height: 0.80 * h)), with: .color(BagArtInk.hillsFar))
        context.fill(Path(ellipseIn: CGRect(x: 0.15 * w, y: 0.80 * h, width: 0.90 * w, height: 0.60 * h)), with: .color(Theme.Tab.bag.hills))
        context.fill(Path(ellipseIn: CGRect(x: -0.30 * w, y: 0.86 * h, width: 0.80 * w, height: 0.50 * h)), with: .color(Theme.Tab.bag.hills))
    }
}

/// Gooby's big red bindle sack with white dots, a tied knot and a wooden stick.
struct BagSackArt: View {
    var body: some View {
        ZStack {
            // Stick behind the sack.
            Capsule()
                .fill(BagArtInk.stick)
                .frame(width: 12, height: 190)
                .overlay(alignment: .leading) {
                    Capsule().fill(BagArtInk.stickDark).frame(width: 4)
                }
                .rotationEffect(.degrees(-52))
                .offset(x: -30, y: -6)
            // Knot ears.
            BagKnotShape()
                .fill(BagArtInk.sackDark)
                .frame(width: 38, height: 34)
                .rotationEffect(.degrees(-28))
                .offset(x: -26, y: -58)
            BagKnotShape()
                .fill(Theme.Tab.bag.sack)
                .frame(width: 40, height: 36)
                .rotationEffect(.degrees(30))
                .offset(x: 24, y: -60)
            // Body.
            BagSackShape()
                .fill(Theme.Tab.bag.sack)
                .frame(width: 150, height: 120)
                .offset(y: 14)
            BagSackShape()
                .fill(BagArtInk.sackDark)
                .frame(width: 150, height: 120)
                .mask(alignment: .bottomTrailing) {
                    Ellipse().frame(width: 150, height: 90).offset(x: 40, y: 20)
                }
                .offset(y: 14)
            Ellipse()
                .fill(BagArtInk.sackShine)
                .frame(width: 46, height: 22)
                .rotationEffect(.degrees(-24))
                .offset(x: -34, y: -12)
            // Dots.
            ForEach(Array(BagSackArt.dots.enumerated()), id: \.offset) { _, dot in
                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: dot.2, height: dot.2)
                    .offset(x: dot.0, y: dot.1)
            }
            // Gathered neck.
            Capsule()
                .fill(BagArtInk.sackDark)
                .frame(width: 44, height: 16)
                .offset(y: -44)
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 26, height: 4)
                .offset(x: -4, y: -47)
        }
        .frame(width: 190, height: 170)
        .accessibilityHidden(true)
    }

    private static let dots: [(CGFloat, CGFloat, CGFloat)] = [
        (-44, 20, 12), (-12, 4, 10), (22, 18, 13), (50, 2, 9), (-30, 50, 10), (8, 46, 12), (44, 42, 10), (-54, -6, 7)
    ]
}

/// Round sack body that narrows to a gathered neck.
struct BagSackShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + w * 0.40, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.60, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.98, y: rect.minY + h * 0.66),
            control1: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.16),
            control2: CGPoint(x: rect.minX + w * 1.02, y: rect.minY + h * 0.30)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.02, y: rect.minY + h * 0.66),
            control1: CGPoint(x: rect.minX + w * 0.94, y: rect.minY + h * 1.08),
            control2: CGPoint(x: rect.minX + w * 0.06, y: rect.minY + h * 1.08)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.40, y: rect.minY),
            control1: CGPoint(x: rect.minX - w * 0.02, y: rect.minY + h * 0.30),
            control2: CGPoint(x: rect.minX + w * 0.30, y: rect.minY + h * 0.16)
        )
        path.closeSubpath()
        return path
    }
}

/// One tied corner of the cloth above the knot.
struct BagKnotShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.15), control: CGPoint(x: rect.minX, y: rect.minY + h * 0.75))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.25), control: CGPoint(x: rect.minX + w * 0.55, y: rect.minY - h * 0.15))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.minY + h * 0.75))
        path.closeSubpath()
        return path
    }
}

/// Yellow name tag with a dashed darker inner border.
struct BagNameTag: View {
    var text: String

    var body: some View {
        Text(text)
            .font(Theme.Fonts.title3)
            .foregroundStyle(BagArtInk.tagText)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.Tab.bag.tag)
                    .shadow(color: Color.black.opacity(0.12), radius: 0, x: 0, y: 3)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Theme.Tab.bag.tagBorder, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .padding(5)
            )
            .accessibilityAddTraits(.isHeader)
    }
}

/// Two brown paw prints (mini-friends tile).
struct BagPawPrints: View {
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            paw.rotationEffect(.degrees(-18)).offset(x: -12, y: -10)
            paw.rotationEffect(.degrees(14)).scaleEffect(0.85).offset(x: 14, y: 12)
        }
        .frame(width: 60, height: 60)
        .scaleEffect(size / 60)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var paw: some View {
        ZStack {
            Ellipse().fill(BagArtInk.paw).frame(width: 20, height: 17).offset(y: 6)
            Ellipse().fill(BagArtInk.paw).frame(width: 7, height: 9).offset(x: -10, y: -6)
            Ellipse().fill(BagArtInk.paw).frame(width: 7, height: 9).offset(x: -3.5, y: -10)
            Ellipse().fill(BagArtInk.paw).frame(width: 7, height: 9).offset(x: 3.5, y: -10)
            Ellipse().fill(BagArtInk.paw).frame(width: 7, height: 9).offset(x: 10, y: -6)
        }
    }
}
