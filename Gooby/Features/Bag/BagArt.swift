import SwiftUI

// Drawn art of the bag tab (screen B): the night sky with bush silhouettes, Gooby's red bindle
// sack with its yellow tie, the stitched name tag and the tile icons (mailbox, hanger, sofa
// with lamp, paints, paw prints). Original vector art, no image assets.

/// Dark navy night with faint twinkling stars and three layers of dark green bushes along the
/// bottom. The stars hold still with reduced motion.
struct BagNightArt: View {
    var reduceMotion: Bool = false

    var body: some View {
        Group {
            if reduceMotion {
                Canvas { context, size in
                    BagNightPainter.draw(&context, size: size, time: nil)
                }
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                    Canvas { context, size in
                        BagNightPainter.draw(&context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
        .background(Theme.Tab.bag.night)
        .accessibilityHidden(true)
    }
}

/// Drawing of `BagNightArt` (a plain enum, so the canvas can call it from any context).
enum BagNightPainter {
    private static let stars: [(CGFloat, CGFloat, CGFloat)] = [
        (0.07, 0.30, 1.6), (0.17, 0.52, 1.2), (0.26, 0.22, 2.0), (0.37, 0.42, 1.2), (0.46, 0.18, 1.5),
        (0.57, 0.34, 1.8), (0.64, 0.55, 1.1), (0.71, 0.24, 1.3), (0.81, 0.46, 1.9), (0.93, 0.32, 1.3),
        (0.12, 0.66, 1.1), (0.88, 0.62, 1.1), (0.41, 0.60, 1.0)
    ]

    /// Bush bumps: x as a fraction of the width, radius as a fraction of the width.
    private static let midBushes: [(CGFloat, CGFloat)] = [
        (-0.02, 0.12), (0.12, 0.10), (0.25, 0.13), (0.40, 0.09), (0.55, 0.12), (0.70, 0.10), (0.84, 0.13), (1.0, 0.11)
    ]
    private static let nearBushes: [(CGFloat, CGFloat)] = [
        (0.04, 0.08), (0.18, 0.07), (0.31, 0.09), (0.47, 0.07), (0.62, 0.08), (0.77, 0.07), (0.92, 0.09)
    ]

    static func draw(_ context: inout GraphicsContext, size: CGSize, time: Double?) {
        let w = size.width
        let h = size.height
        let tint = Theme.Tab.bag
        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }

        for (index, star) in stars.enumerated() {
            let twinkle = time.map { 0.55 + 0.45 * sin($0 * 1.7 + Double(index) * 2.1) } ?? 0.8
            context.fill(circle(star.0 * w, star.1 * h, star.2), with: .color(tint.star.opacity(0.35 + 0.5 * twinkle)))
        }

        // Rolling far hills, then bush rows that get lighter toward the sheet.
        context.fill(Path(ellipseIn: CGRect(x: -0.35 * w, y: 0.56 * h, width: 0.95 * w, height: 0.9 * h)), with: .color(tint.hillsFar))
        context.fill(Path(ellipseIn: CGRect(x: 0.40 * w, y: 0.50 * h, width: 0.95 * w, height: 0.9 * h)), with: .color(tint.hillsFar))
        var mid = Path()
        for bush in midBushes {
            mid.addPath(circle(bush.0 * w, 0.80 * h, bush.1 * w))
        }
        mid.addRect(CGRect(x: 0, y: 0.80 * h, width: w, height: 0.2 * h))
        context.fill(mid, with: .color(tint.hills))
        var near = Path()
        for bush in nearBushes {
            near.addPath(circle(bush.0 * w, 0.93 * h, bush.1 * w))
        }
        near.addRect(CGRect(x: 0, y: 0.93 * h, width: w, height: 0.07 * h))
        context.fill(near, with: .color(tint.hillsNear))
    }
}

/// Gooby's red bindle sack (about 95 pt) with a yellow tie and the wooden stick.
struct BagSackArt: View {
    var body: some View {
        let tint = Theme.Tab.bag
        ZStack {
            // Stick behind the sack, poking out of the knot to the upper left.
            Capsule()
                .fill(tint.stick)
                .frame(width: 8, height: 122)
                .overlay(alignment: .leading) {
                    Capsule().fill(tint.stickDark).frame(width: 3)
                }
                .rotationEffect(.degrees(-52))
                .offset(x: -20, y: -18)
            // Tied cloth corners above the tie.
            BagKnotShape()
                .fill(tint.sackDark)
                .frame(width: 27, height: 25)
                .rotationEffect(.degrees(-26))
                .offset(x: -12, y: -40)
            BagKnotShape()
                .fill(tint.sack)
                .frame(width: 28, height: 26)
                .rotationEffect(.degrees(28))
                .offset(x: 13, y: -41)
            // Body with a darker lower right and a shine.
            BagSackShape()
                .fill(tint.sack)
                .frame(width: 98, height: 78)
                .offset(y: 15)
            BagSackShape()
                .fill(tint.sackDark)
                .frame(width: 98, height: 78)
                .mask(alignment: .bottomTrailing) {
                    Ellipse().frame(width: 100, height: 62).offset(x: 28, y: 14)
                }
                .offset(y: 15)
            Ellipse()
                .fill(tint.sackShine)
                .frame(width: 30, height: 14)
                .rotationEffect(.degrees(-24))
                .offset(x: -22, y: 0)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 5, height: 5)
                .offset(x: -32, y: 6)
            // Yellow tie around the neck with a little bow.
            Capsule()
                .fill(tint.tieDark)
                .frame(width: 34, height: 11)
                .offset(y: -22)
            Capsule()
                .fill(tint.tie)
                .frame(width: 34, height: 9)
                .offset(y: -23)
            Ellipse()
                .fill(tint.tie)
                .frame(width: 11, height: 8)
                .rotationEffect(.degrees(-30))
                .offset(x: 19, y: -26)
            Ellipse()
                .fill(tint.tieDark)
                .frame(width: 10, height: 7)
                .rotationEffect(.degrees(30))
                .offset(x: 20, y: -18)
            Circle()
                .fill(tint.tie)
                .frame(width: 7, height: 7)
                .offset(x: 15, y: -22)
        }
        .frame(width: 132, height: 112)
        .accessibilityHidden(true)
    }
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

/// Yellow name tag (about 180 x 55) with a stitched brown dashed border inside.
struct BagNameTag: View {
    var text: String

    var body: some View {
        let tint = Theme.Tab.bag
        Text(text)
            .font(Theme.Fonts.title3)
            .foregroundStyle(tint.tagText)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 24)
            .frame(minWidth: 180, minHeight: 55)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.tag)
                    .shadow(color: tint.tileShadow.opacity(0.3), radius: 0, x: 0, y: 3)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(tint.tagBorder, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [7, 5]))
                    .padding(6)
            )
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Tile icons (44 pt design box)

/// Red mailbox on a post with its yellow flag up.
struct BagMailIcon: View {
    var size: CGFloat = 44

    var body: some View {
        let tint = Theme.Tab.bag
        ZStack {
            RoundedRectangle(cornerRadius: 1.5).fill(tint.stick).frame(width: 6, height: 14).offset(y: 15)
            UnevenRoundedRectangle(topLeadingRadius: 11, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 11, style: .continuous)
                .fill(tint.mailbox)
                .frame(width: 34, height: 23)
                .offset(y: -1)
            UnevenRoundedRectangle(topLeadingRadius: 11, bottomLeadingRadius: 3, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
                .fill(tint.mailboxDark)
                .frame(width: 10, height: 23)
                .offset(x: -12, y: -1)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white)
                .frame(width: 7, height: 9)
                .rotationEffect(.degrees(-8))
                .offset(x: -12, y: -3)
            Capsule().fill(Color.white.opacity(0.4)).frame(width: 12, height: 3).offset(x: 4, y: -8)
            Capsule().fill(tint.flag).frame(width: 3, height: 17).offset(x: 13, y: -13)
            RoundedRectangle(cornerRadius: 1.5).fill(tint.flag).frame(width: 9, height: 7).offset(x: 17, y: -18)
        }
        .frame(width: 44, height: 44)
        .scaleEffect(size / 44)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Blue T-shirt on a wooden hanger.
struct BagOutfitIcon: View {
    var size: CGFloat = 44

    var body: some View {
        let tint = Theme.Tab.bag
        ZStack {
            Circle()
                .trim(from: 0.5, to: 1.0)
                .stroke(tint.lampPole, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .frame(width: 8, height: 8)
                .offset(x: 4, y: -18)
            Capsule().fill(tint.lampPole).frame(width: 2.4, height: 6).offset(y: -15)
            BagHangerShape()
                .stroke(tint.hanger, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 36, height: 9)
                .offset(y: -8)
            BagShirtShape()
                .fill(tint.shirt)
                .frame(width: 36, height: 27)
                .offset(y: 8)
            BagShirtShape()
                .fill(tint.shirtDark)
                .frame(width: 36, height: 27)
                .mask(alignment: .bottom) { Rectangle().frame(height: 5) }
                .offset(y: 8)
            Circle().fill(Color.white.opacity(0.85)).frame(width: 3, height: 3).offset(y: 3)
            Circle().fill(Color.white.opacity(0.85)).frame(width: 3, height: 3).offset(y: 9)
        }
        .frame(width: 44, height: 44)
        .scaleEffect(size / 44)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Little red sofa with a floor lamp.
struct BagFurnitureIcon: View {
    var size: CGFloat = 44

    var body: some View {
        let tint = Theme.Tab.bag
        ZStack {
            Capsule().fill(tint.lampPole).frame(width: 2.4, height: 30).offset(x: 16, y: 4)
            Ellipse().fill(tint.lampPole).frame(width: 11, height: 3.5).offset(x: 16, y: 19)
            BagLampShadeShape().fill(tint.lampShade).frame(width: 14, height: 10).offset(x: 16, y: -14)
            Ellipse().fill(tint.lampShade.opacity(0.35)).frame(width: 18, height: 8).offset(x: 16, y: -6)
            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(tint.sofa).frame(width: 28, height: 15).offset(x: -5, y: 1)
            Capsule().fill(Color.white.opacity(0.35)).frame(width: 12, height: 2.5).offset(x: -8, y: -3)
            RoundedRectangle(cornerRadius: 3, style: .continuous).fill(tint.sofa).frame(width: 28, height: 8).offset(x: -5, y: 10)
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(tint.sofaDark).frame(width: 7, height: 15).offset(x: -20, y: 8)
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(tint.sofaDark).frame(width: 7, height: 15).offset(x: 10, y: 8)
            Rectangle().fill(tint.stickDark).frame(width: 2.5, height: 4).offset(x: -19, y: 17)
            Rectangle().fill(tint.stickDark).frame(width: 2.5, height: 4).offset(x: 9, y: 17)
        }
        .frame(width: 44, height: 44)
        .scaleEffect(size / 44)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Three dabs of paint (the colors tile once a fur color is owned).
struct BagPaintsIcon: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xFF8FB1)).frame(width: 20, height: 20).offset(x: -8, y: -6)
            Circle().fill(Color(hex: 0x5AA9E6)).frame(width: 20, height: 20).offset(x: 8, y: -6)
            Circle().fill(Theme.Tab.bag.flag).frame(width: 20, height: 20).offset(y: 8)
            Circle().fill(Color.white.opacity(0.5)).frame(width: 5, height: 5).offset(x: -12, y: -10)
            Circle().fill(Color.white.opacity(0.5)).frame(width: 5, height: 5).offset(x: 4, y: -10)
            Circle().fill(Color.white.opacity(0.5)).frame(width: 5, height: 5).offset(x: -4, y: 4)
        }
        .frame(width: 44, height: 44)
        .scaleEffect(size / 44)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Hanger triangle: hook neck at the top center, bar along the bottom.
struct BagHangerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// T-shirt with short sleeves and a round collar.
struct BagShirtShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x + 0.38 * w, y: y))
        path.addLine(to: CGPoint(x: x + 0.12 * w, y: y + 0.08 * h))
        path.addLine(to: CGPoint(x: x, y: y + 0.36 * h))
        path.addLine(to: CGPoint(x: x + 0.15 * w, y: y + 0.46 * h))
        path.addLine(to: CGPoint(x: x + 0.23 * w, y: y + 0.38 * h))
        path.addLine(to: CGPoint(x: x + 0.23 * w, y: y + h))
        path.addLine(to: CGPoint(x: x + 0.77 * w, y: y + h))
        path.addLine(to: CGPoint(x: x + 0.77 * w, y: y + 0.38 * h))
        path.addLine(to: CGPoint(x: x + 0.85 * w, y: y + 0.46 * h))
        path.addLine(to: CGPoint(x: x + w, y: y + 0.36 * h))
        path.addLine(to: CGPoint(x: x + 0.88 * w, y: y + 0.08 * h))
        path.addLine(to: CGPoint(x: x + 0.62 * w, y: y))
        path.addQuadCurve(to: CGPoint(x: x + 0.38 * w, y: y), control: CGPoint(x: x + 0.5 * w, y: y + 0.2 * h))
        path.closeSubpath()
        return path
    }
}

/// Lamp shade: a trapezoid with rounded corners, narrow at the top.
struct BagLampShadeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.28, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
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
            Ellipse().fill(Theme.Tab.bag.paw).frame(width: 20, height: 17).offset(y: 6)
            Ellipse().fill(Theme.Tab.bag.paw).frame(width: 7, height: 9).offset(x: -10, y: -6)
            Ellipse().fill(Theme.Tab.bag.paw).frame(width: 7, height: 9).offset(x: -3.5, y: -10)
            Ellipse().fill(Theme.Tab.bag.paw).frame(width: 7, height: 9).offset(x: 3.5, y: -10)
            Ellipse().fill(Theme.Tab.bag.paw).frame(width: 7, height: 9).offset(x: 10, y: -6)
        }
    }
}
