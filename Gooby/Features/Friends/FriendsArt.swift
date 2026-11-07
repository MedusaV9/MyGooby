import SwiftUI

// Drawn art of the friends tab (screen 6): the big friendship tree, wooden signposts and the
// heads of the local NPC friends. Original vector art, no image assets.

/// The huge layered tree on a grass hill. Signposts sit at `FriendsTreePainter.spots`; the
/// canvas draws a short branch under each one.
struct FriendsTreeArt: View {
    var body: some View {
        Canvas { context, size in
            FriendsTreePainter.draw(&context, size: size)
        }
        .accessibilityHidden(true)
    }
}

/// Drawing of `FriendsTreeArt` (a plain enum, so the canvas can call it from any context).
enum FriendsTreePainter {
    /// Sign anchor points as fractions of the scene (x of width, y of height): the bottom of
    /// each signpost's post.
    static let spots: [CGPoint] = [
        CGPoint(x: 0.19, y: 0.27),
        CGPoint(x: 0.81, y: 0.29),
        CGPoint(x: 0.14, y: 0.63),
        CGPoint(x: 0.86, y: 0.65)
    ]

    private struct Blob {
        var x: CGFloat
        var y: CGFloat
        var r: CGFloat
    }

    /// Canopy silhouette: x and y as fractions of the scene, r as a fraction of the width.
    private static let blobs: [Blob] = [
        Blob(x: 0.50, y: 0.38, r: 0.44),
        Blob(x: 0.19, y: 0.33, r: 0.24),
        Blob(x: 0.81, y: 0.33, r: 0.24),
        Blob(x: 0.11, y: 0.52, r: 0.21),
        Blob(x: 0.89, y: 0.52, r: 0.21),
        Blob(x: 0.30, y: 0.59, r: 0.22),
        Blob(x: 0.70, y: 0.59, r: 0.22),
        Blob(x: 0.50, y: 0.62, r: 0.20),
        Blob(x: 0.50, y: 0.17, r: 0.24),
        Blob(x: 0.28, y: 0.21, r: 0.19),
        Blob(x: 0.72, y: 0.21, r: 0.19)
    ]

    static func draw(_ context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let tint = Theme.Tab.friends

        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }

        // Far hills behind the trunk.
        context.fill(Path(ellipseIn: CGRect(x: -0.35 * w, y: 0.80 * h, width: 0.95 * w, height: 0.40 * h)), with: .color(Theme.Tab.friends.hillFar))
        context.fill(Path(ellipseIn: CGRect(x: 0.45 * w, y: 0.78 * h, width: 0.95 * w, height: 0.42 * h)), with: .color(Theme.Tab.friends.hillFar))

        // Trunk with root flares and a darker right side.
        let topY = 0.60 * h
        let footY = 0.93 * h
        var trunk = Path()
        trunk.move(to: CGPoint(x: 0.5 * w - 0.065 * w, y: topY))
        trunk.addLine(to: CGPoint(x: 0.5 * w + 0.065 * w, y: topY))
        trunk.addQuadCurve(to: CGPoint(x: 0.5 * w + 0.17 * w, y: footY), control: CGPoint(x: 0.5 * w + 0.07 * w, y: 0.86 * h))
        trunk.addLine(to: CGPoint(x: 0.5 * w - 0.17 * w, y: footY))
        trunk.addQuadCurve(to: CGPoint(x: 0.5 * w - 0.065 * w, y: topY), control: CGPoint(x: 0.5 * w - 0.07 * w, y: 0.86 * h))
        trunk.closeSubpath()
        context.fill(trunk, with: .color(tint.trunk))
        var shade = Path()
        shade.move(to: CGPoint(x: 0.5 * w + 0.015 * w, y: topY))
        shade.addLine(to: CGPoint(x: 0.5 * w + 0.065 * w, y: topY))
        shade.addQuadCurve(to: CGPoint(x: 0.5 * w + 0.17 * w, y: footY), control: CGPoint(x: 0.5 * w + 0.07 * w, y: 0.86 * h))
        shade.addLine(to: CGPoint(x: 0.5 * w + 0.05 * w, y: footY))
        shade.addQuadCurve(to: CGPoint(x: 0.5 * w + 0.015 * w, y: topY), control: CGPoint(x: 0.5 * w + 0.02 * w, y: 0.84 * h))
        shade.closeSubpath()
        context.fill(shade, with: .color(Theme.Tab.friends.trunkShade))

        // Canopy: dark silhouette, mid layer, light highlights.
        for blob in blobs {
            context.fill(circle(blob.x * w, blob.y * h, blob.r * w), with: .color(tint.canopyDark))
        }
        for blob in blobs {
            let r = blob.r * w
            context.fill(circle(blob.x * w - r * 0.05, blob.y * h - r * 0.08, r * 0.86), with: .color(tint.canopy))
        }
        for blob in blobs {
            let r = blob.r * w
            context.fill(circle(blob.x * w - r * 0.30, blob.y * h - r * 0.34, r * 0.40), with: .color(tint.canopyLight))
            context.fill(circle(blob.x * w - r * 0.46, blob.y * h - r * 0.50, r * 0.07), with: .color(Theme.Tab.friends.leafShine))
        }
        // A few darker leaf dots for texture.
        let dots: [(CGFloat, CGFloat)] = [(0.36, 0.30), (0.64, 0.27), (0.24, 0.45), (0.77, 0.47), (0.42, 0.55), (0.60, 0.50), (0.50, 0.24)]
        for dot in dots {
            context.fill(circle(dot.0 * w, dot.1 * h, 0.022 * w), with: .color(tint.canopyDark.opacity(0.55)))
        }

        // Branch stubs under the signposts, pointing in toward the trunk.
        for spot in spots {
            let start = CGPoint(x: spot.x * w, y: spot.y * h - 4)
            let inward: CGFloat = spot.x < 0.5 ? 1 : -1
            var branch = Path()
            branch.move(to: CGPoint(x: start.x - inward * 22, y: start.y - 2))
            branch.addQuadCurve(to: CGPoint(x: start.x + inward * 46, y: start.y + 26), control: CGPoint(x: start.x + inward * 16, y: start.y + 2))
            context.stroke(branch, with: .color(tint.trunk), style: StrokeStyle(lineWidth: 11, lineCap: .round))
            var twig = Path()
            twig.move(to: CGPoint(x: start.x + inward * 24, y: start.y + 12))
            twig.addLine(to: CGPoint(x: start.x + inward * 34, y: start.y - 4))
            context.stroke(twig, with: .color(tint.trunk), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            context.fill(circle(start.x + inward * 36, start.y - 8, 7), with: .color(tint.canopyLight))
        }

        // Grass hill that runs into the tab bar.
        context.fill(Path(ellipseIn: CGRect(x: -0.30 * w, y: 0.88 * h, width: 1.60 * w, height: 0.50 * h)), with: .color(tint.grass))
        context.fill(Path(ellipseIn: CGRect(x: -0.10 * w, y: 0.895 * h, width: 0.55 * w, height: 0.035 * h)), with: .color(Theme.Tab.friends.grassShine))
        let tufts: [CGFloat] = [0.12, 0.30, 0.71, 0.90]
        for x in tufts {
            var tuft = Path()
            let base = CGPoint(x: x * w, y: 0.955 * h)
            tuft.move(to: CGPoint(x: base.x - 6, y: base.y))
            tuft.addLine(to: CGPoint(x: base.x - 3, y: base.y - 9))
            tuft.addLine(to: CGPoint(x: base.x, y: base.y - 2))
            tuft.addLine(to: CGPoint(x: base.x + 3, y: base.y - 10))
            tuft.addLine(to: CGPoint(x: base.x + 6, y: base.y))
            tuft.closeSubpath()
            context.fill(tuft, with: .color(Theme.Tab.friends.tuft))
        }
    }
}

/// Art colors of this slice that are not in the shared palette.
/// Wooden signpost on a branch: a board with the friend's name and hearts (or "???" before
/// they met), the friend's head peeking over the board, and a short post.
struct FriendsSignpost: View {
    var npc: SocialNPC
    var unlocked: Bool
    var level: Int

    var body: some View {
        VStack(spacing: 0) {
            if unlocked {
                SocialNPCHead(species: npc.species, size: 50)
                    .padding(.bottom, -10)
                    .zIndex(1)
            }
            board
            Rectangle()
                .fill(Theme.Tab.friends.signEdge)
                .frame(width: 8, height: 16)
        }
        .frame(width: 104, height: 112, alignment: .bottom)
    }

    private var board: some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        return VStack(spacing: 2) {
            Text(verbatim: unlocked ? npc.name : "???")
                .font(.system(size: unlocked ? 15 : 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Theme.Tab.friends.signEdge, radius: 0, x: 0, y: 1)
            if unlocked {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < level ? "heart.fill" : "heart")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(index < level ? Theme.Tab.friends.heart : Color.white.opacity(0.7))
                    }
                }
            }
        }
        .frame(width: 88, height: unlocked ? 42 : 36)
        .background {
            ZStack(alignment: .top) {
                shape.fill(Theme.Tab.friends.sign)
                    .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 3)
                Capsule().fill(Theme.Tab.friends.signGrain).frame(width: 52, height: 3).padding(.top, 5)
                shape.stroke(Theme.Tab.friends.signEdge, lineWidth: 2.5)
            }
        }
    }
}

/// Head of a local NPC friend in Gooby's style: round face, big shiny eyes, pink cheeks.
struct SocialNPCHead: View {
    var species: String
    var size: CGFloat

    var body: some View {
        head
            .frame(width: 100, height: 100)
            .scaleEffect(size / 100)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var head: some View {
        switch species {
        case "bear": bear
        case "cat": cat
        case "fox": fox
        default: chick
        }
    }

    private func eyes(y: CGFloat, spacing: CGFloat) -> some View {
        ZStack {
            eye.offset(x: -spacing, y: y)
            eye.offset(x: spacing, y: y)
        }
    }

    private var eye: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x2B2420)).frame(width: 14, height: 16)
            Circle().fill(Color.white).frame(width: 6, height: 6).offset(x: -2.5, y: -3.5)
            Circle().fill(Color.white.opacity(0.85)).frame(width: 2.5, height: 2.5).offset(x: 3, y: 3.5)
        }
    }

    private func cheeks(y: CGFloat, spacing: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xFF9FB5).opacity(0.75)).frame(width: 14, height: 9).offset(x: -spacing, y: y)
            Ellipse().fill(Color(hex: 0xFF9FB5).opacity(0.75)).frame(width: 14, height: 9).offset(x: spacing, y: y)
        }
    }

    private var smile: some View {
        SocialSmileShape()
            .stroke(Color(hex: 0x5A3A2A), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 12, height: 6)
    }

    private var bear: some View {
        let fur = Color(hex: 0xD9A877)
        let dark = Color(hex: 0xB9835A)
        return ZStack {
            Circle().fill(dark).frame(width: 30, height: 30).offset(x: -28, y: -28)
            Circle().fill(dark).frame(width: 30, height: 30).offset(x: 28, y: -28)
            Circle().fill(Color(hex: 0xF2C9A0)).frame(width: 16, height: 16).offset(x: -28, y: -27)
            Circle().fill(Color(hex: 0xF2C9A0)).frame(width: 16, height: 16).offset(x: 28, y: -27)
            Ellipse().fill(fur).frame(width: 84, height: 78).offset(y: 6)
            Ellipse().fill(Color.white.opacity(0.22)).frame(width: 40, height: 16).offset(x: -14, y: -20)
            Ellipse().fill(Color(hex: 0xF5DEC0)).frame(width: 34, height: 24).offset(y: 22)
            Ellipse().fill(Color(hex: 0x5A3A2A)).frame(width: 12, height: 8).offset(y: 16)
            smile.offset(y: 25)
            eyes(y: 2, spacing: 17)
            cheeks(y: 16, spacing: 28)
        }
    }

    private var cat: some View {
        let fur = Color(hex: 0xC9C3DE)
        return ZStack {
            SocialEarShape().fill(fur).frame(width: 30, height: 34).rotationEffect(.degrees(-16)).offset(x: -26, y: -30)
            SocialEarShape().fill(fur).frame(width: 30, height: 34).rotationEffect(.degrees(16)).offset(x: 26, y: -30)
            SocialEarShape().fill(Color(hex: 0xFFB7CC)).frame(width: 14, height: 18).rotationEffect(.degrees(-16)).offset(x: -25, y: -25)
            SocialEarShape().fill(Color(hex: 0xFFB7CC)).frame(width: 14, height: 18).rotationEffect(.degrees(16)).offset(x: 25, y: -25)
            Ellipse().fill(fur).frame(width: 86, height: 76).offset(y: 6)
            Ellipse().fill(Color.white.opacity(0.25)).frame(width: 40, height: 16).offset(x: -14, y: -20)
            Ellipse().fill(Color.white.opacity(0.85)).frame(width: 30, height: 20).offset(y: 24)
            Ellipse().fill(Color(hex: 0xF08FA8)).frame(width: 10, height: 7).offset(y: 17)
            smile.offset(y: 25)
            eyes(y: 2, spacing: 18)
            cheeks(y: 16, spacing: 29)
            whiskers
        }
    }

    private var whiskers: some View {
        ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(Color(hex: 0x8D86A8)).frame(width: 16, height: 2).rotationEffect(.degrees(side * 8)).offset(x: CGFloat(side) * 44, y: 18)
                Capsule().fill(Color(hex: 0x8D86A8)).frame(width: 16, height: 2).rotationEffect(.degrees(side * -8)).offset(x: CGFloat(side) * 44, y: 25)
            }
        }
    }

    private var fox: some View {
        let fur = Color(hex: 0xF29A4A)
        return ZStack {
            SocialEarShape().fill(fur).frame(width: 32, height: 40).rotationEffect(.degrees(-18)).offset(x: -26, y: -30)
            SocialEarShape().fill(fur).frame(width: 32, height: 40).rotationEffect(.degrees(18)).offset(x: 26, y: -30)
            SocialEarShape().fill(Color(hex: 0x5A3A2A)).frame(width: 14, height: 14).rotationEffect(.degrees(-18)).offset(x: -31, y: -43)
            SocialEarShape().fill(Color(hex: 0x5A3A2A)).frame(width: 14, height: 14).rotationEffect(.degrees(18)).offset(x: 31, y: -43)
            Ellipse().fill(fur).frame(width: 86, height: 76).offset(y: 6)
            Ellipse().fill(Color.white.opacity(0.22)).frame(width: 40, height: 16).offset(x: -14, y: -20)
            Ellipse().fill(Color(hex: 0xFFF4E6)).frame(width: 40, height: 30).offset(x: -18, y: 24)
            Ellipse().fill(Color(hex: 0xFFF4E6)).frame(width: 40, height: 30).offset(x: 18, y: 24)
            Ellipse().fill(Color(hex: 0x3A2A22)).frame(width: 11, height: 8).offset(y: 16)
            smile.offset(y: 25)
            eyes(y: 0, spacing: 18)
            cheeks(y: 14, spacing: 30)
        }
    }

    private var chick: some View {
        let fur = Color(hex: 0xFFD95A)
        return ZStack {
            Ellipse().fill(fur).frame(width: 12, height: 22).rotationEffect(.degrees(-20)).offset(x: -5, y: -40)
            Ellipse().fill(fur).frame(width: 10, height: 18).rotationEffect(.degrees(24)).offset(x: 6, y: -38)
            Circle().fill(fur).frame(width: 86, height: 86).offset(y: 4)
            Ellipse().fill(Color.white.opacity(0.3)).frame(width: 40, height: 16).offset(x: -14, y: -22)
            Ellipse().fill(Color(hex: 0xFFA43B)).frame(width: 18, height: 10).offset(y: 16)
            Ellipse().fill(Color(hex: 0xE88A24)).frame(width: 14, height: 5).offset(y: 21)
            eyes(y: 0, spacing: 17)
            cheeks(y: 16, spacing: 28)
        }
    }
}

/// Rounded triangle ear (cat, fox).
struct SocialEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.minX + w * 0.95, y: rect.minY + h * 0.4))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY + h * 1.1))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX + w * 0.05, y: rect.minY + h * 0.4))
        path.closeSubpath()
        return path
    }
}

/// Small open smile.
struct SocialSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 1.6))
        return path
    }
}
