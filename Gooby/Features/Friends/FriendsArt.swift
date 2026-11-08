import SwiftUI

// Drawn art of the friends tab (screen A): the giant friendship tree made of layered leaf
// clumps, wooden signposts standing on the canopy and the heads of the local NPC friends.
// Original vector art, no image assets.

/// The giant tree on rolling hills. Signposts stand at `FriendsTreePainter.spots`. The leaf
/// clumps sway a little and a few leaves drift down; everything is still with reduced motion.
struct FriendsTreeArt: View {
    var reduceMotion: Bool = false

    var body: some View {
        Group {
            if reduceMotion {
                Canvas { context, size in
                    FriendsTreePainter.draw(&context, size: size, time: nil)
                }
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    Canvas { context, size in
                        FriendsTreePainter.draw(&context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Drawing of `FriendsTreeArt` (a plain enum, so the canvas can call it from any context).
enum FriendsTreePainter {
    /// Foot of each signpost as fractions of the scene (x of width, y of height): two high on the
    /// canopy as in the reference, two lower on its sides.
    static let spots: [CGPoint] = [
        CGPoint(x: 0.20, y: 0.40),
        CGPoint(x: 0.80, y: 0.37),
        CGPoint(x: 0.14, y: 0.70),
        CGPoint(x: 0.86, y: 0.68)
    ]

    /// Center of Gooby's head as a fraction of the scene height.
    static let gooby: CGFloat = 0.36

    private struct Blob {
        var x: CGFloat
        var y: CGFloat
        var r: CGFloat
    }

    /// Canopy silhouette: x and y as fractions of the scene, r as a fraction of the width.
    private static let outline: [Blob] = [
        Blob(x: 0.50, y: 0.40, r: 0.44),
        Blob(x: 0.50, y: 0.16, r: 0.25),
        Blob(x: 0.27, y: 0.22, r: 0.22),
        Blob(x: 0.73, y: 0.22, r: 0.22),
        Blob(x: 0.12, y: 0.38, r: 0.21),
        Blob(x: 0.88, y: 0.38, r: 0.21),
        Blob(x: 0.05, y: 0.56, r: 0.20),
        Blob(x: 0.95, y: 0.56, r: 0.20),
        Blob(x: 0.20, y: 0.70, r: 0.22),
        Blob(x: 0.80, y: 0.70, r: 0.22),
        Blob(x: 0.50, y: 0.72, r: 0.24)
    ]

    /// Lighter leaf clumps in front: center x/y as fractions of the scene, r of the width.
    private static let clumps: [Blob] = [
        Blob(x: 0.31, y: 0.16, r: 0.15),
        Blob(x: 0.67, y: 0.12, r: 0.15),
        Blob(x: 0.11, y: 0.47, r: 0.13),
        Blob(x: 0.89, y: 0.45, r: 0.13),
        Blob(x: 0.29, y: 0.63, r: 0.14),
        Blob(x: 0.71, y: 0.61, r: 0.14),
        Blob(x: 0.50, y: 0.77, r: 0.14),
        Blob(x: 0.08, y: 0.74, r: 0.10),
        Blob(x: 0.93, y: 0.73, r: 0.10)
    ]

    /// Leafy clump: three overlapping circles around (cx, cy), about 2.2 r wide and 1.5 r tall.
    static func clump(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: cx - 0.52 * r - 0.56 * r, y: cy + 0.14 * r - 0.56 * r, width: 1.12 * r, height: 1.12 * r))
        path.addEllipse(in: CGRect(x: cx - 0.70 * r, y: cy - 0.10 * r - 0.70 * r, width: 1.40 * r, height: 1.40 * r))
        path.addEllipse(in: CGRect(x: cx + 0.52 * r - 0.56 * r, y: cy + 0.14 * r - 0.56 * r, width: 1.12 * r, height: 1.12 * r))
        return path
    }

    static func draw(_ context: inout GraphicsContext, size: CGSize, time: Double?) {
        let w = size.width
        let h = size.height
        let tint = Theme.Tab.friends
        let t = time ?? 0

        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }

        // Far hills behind the trunk.
        context.fill(Path(ellipseIn: CGRect(x: -0.40 * w, y: 0.79 * h, width: 1.00 * w, height: 0.42 * h)), with: .color(tint.hillFar))
        context.fill(Path(ellipseIn: CGRect(x: 0.42 * w, y: 0.77 * h, width: 1.05 * w, height: 0.45 * h)), with: .color(tint.hillFar))

        // Trunk with root flares and a darker right side.
        let topY = 0.62 * h
        let footY = 0.95 * h
        let cx = 0.5 * w
        var trunk = Path()
        trunk.move(to: CGPoint(x: cx - 0.07 * w, y: topY))
        trunk.addLine(to: CGPoint(x: cx + 0.07 * w, y: topY))
        trunk.addQuadCurve(to: CGPoint(x: cx + 0.17 * w, y: footY), control: CGPoint(x: cx + 0.075 * w, y: 0.88 * h))
        trunk.addLine(to: CGPoint(x: cx - 0.17 * w, y: footY))
        trunk.addQuadCurve(to: CGPoint(x: cx - 0.07 * w, y: topY), control: CGPoint(x: cx - 0.075 * w, y: 0.88 * h))
        trunk.closeSubpath()
        context.fill(trunk, with: .color(tint.trunk))
        var shade = Path()
        shade.move(to: CGPoint(x: cx + 0.02 * w, y: topY))
        shade.addLine(to: CGPoint(x: cx + 0.07 * w, y: topY))
        shade.addQuadCurve(to: CGPoint(x: cx + 0.17 * w, y: footY), control: CGPoint(x: cx + 0.075 * w, y: 0.88 * h))
        shade.addLine(to: CGPoint(x: cx + 0.06 * w, y: footY))
        shade.addQuadCurve(to: CGPoint(x: cx + 0.02 * w, y: topY), control: CGPoint(x: cx + 0.025 * w, y: 0.86 * h))
        shade.closeSubpath()
        context.fill(shade, with: .color(tint.trunkShade))

        // Canopy: dark silhouette, the mid layer lifted a little so each bump keeps a dark rim.
        var back = Path()
        for blob in outline {
            back.addPath(circle(blob.x * w, blob.y * h, blob.r * w))
        }
        context.fill(back, with: .color(tint.canopyDark))
        var mid = Path()
        for blob in outline {
            mid.addPath(circle(blob.x * w, blob.y * h - 0.016 * h, blob.r * w * 0.93))
        }
        context.fill(mid, with: .color(tint.canopy))

        // Front clumps with a soft shadow and a highlight blob; they sway a little in the wind.
        for (index, blob) in clumps.enumerated() {
            let sway = time == nil ? 0 : CGFloat(sin(t * 0.8 + Double(index) * 1.3)) * 1.6
            let x = blob.x * w + sway
            let y = blob.y * h
            let r = blob.r * w
            context.fill(clump(x, y + r * 0.18, r), with: .color(tint.canopyDark.opacity(0.45)))
            context.fill(clump(x, y, r), with: .color(tint.canopyFront))
            context.fill(clump(x - r * 0.24, y - r * 0.26, r * 0.44), with: .color(tint.canopyLight))
            context.fill(circle(x - r * 0.42, y - r * 0.52, r * 0.07), with: .color(tint.leafShine))
        }

        // Grass hill that runs into the tab bar, with tufts and two tiny flowers.
        context.fill(Path(ellipseIn: CGRect(x: -0.30 * w, y: 0.87 * h, width: 1.60 * w, height: 0.50 * h)), with: .color(tint.grass))
        context.fill(Path(ellipseIn: CGRect(x: -0.08 * w, y: 0.885 * h, width: 0.50 * w, height: 0.03 * h)), with: .color(tint.grassShine))
        for x in [0.10, 0.27, 0.73, 0.91] as [CGFloat] {
            var tuft = Path()
            let base = CGPoint(x: x * w, y: 0.95 * h)
            tuft.move(to: CGPoint(x: base.x - 6, y: base.y))
            tuft.addLine(to: CGPoint(x: base.x - 3, y: base.y - 9))
            tuft.addLine(to: CGPoint(x: base.x, y: base.y - 2))
            tuft.addLine(to: CGPoint(x: base.x + 3, y: base.y - 10))
            tuft.addLine(to: CGPoint(x: base.x + 6, y: base.y))
            tuft.closeSubpath()
            context.fill(tuft, with: .color(tint.tuft))
        }
        // A few leaves drifting down in front of the canopy.
        guard let time else { return }
        let leaves: [(x: CGFloat, start: CGFloat, period: Double, offset: Double)] = [
            (0.34, 0.30, 9.0, 0), (0.62, 0.20, 11.0, 3.7), (0.82, 0.48, 10.0, 6.1)
        ]
        for leaf in leaves {
            let progress = ((time + leaf.offset).truncatingRemainder(dividingBy: leaf.period)) / leaf.period
            let fall = CGFloat(progress)
            let x = leaf.x * w + CGFloat(sin(progress * .pi * 4)) * 14
            let y = leaf.start * h + fall * 0.34 * h
            let alpha = min(1, min(progress * 6, (1 - progress) * 4))
            var leafContext = context
            leafContext.translateBy(x: x, y: y)
            leafContext.rotate(by: .degrees(sin(progress * .pi * 4) * 40))
            leafContext.fill(Path(ellipseIn: CGRect(x: -6, y: -3, width: 12, height: 6)), with: .color(tint.canopyLight.opacity(alpha)))
            leafContext.fill(Path(CGRect(x: -5, y: -0.4, width: 9, height: 0.8)), with: .color(tint.canopyDark.opacity(alpha * 0.5)))
        }
    }
}

/// Light green leaf cushion Gooby sits on: a wide oval with a leafy bump on each side.
/// In a 136 x 46 frame the oval's top is 6 pt below the frame's top.
struct FriendsCushionShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let bump = h * 0.28
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.02, y: rect.minY + h * 0.13, width: w * 0.96, height: h * 0.87))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.19 - bump, y: rect.minY + h * 0.41 - bump, width: bump * 2, height: bump * 2))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.81 - bump, y: rect.minY + h * 0.41 - bump, width: bump * 2, height: bump * 2))
        return path
    }
}

/// Wooden signpost standing on the canopy: two light planks on a darker post with a soft
/// shadow. Before Gooby met the friend the top plank reads "???"; afterwards the friend's head
/// peeks over it, the top plank shows the name and the lower one the friendship hearts.
struct FriendsSignpost: View {
    var npc: SocialNPC
    var unlocked: Bool
    var level: Int
    /// Index on the tree; staggers the head bobbing and flips the lower plank on the right side.
    var index: Int = 0
    var reduceMotion: Bool = false

    private var tint: FriendsTint { Theme.Tab.friends }
    private var rightSide: Bool { index % 2 == 1 }

    var body: some View {
        VStack(spacing: 0) {
            if unlocked {
                head
                    .padding(.bottom, -12)
                    .zIndex(2)
            }
            plank(width: 92, height: 36) {
                Text(verbatim: unlocked ? npc.name : "???")
                    .font(.system(size: unlocked ? 16 : 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: tint.signEdge, radius: 0, x: 0, y: 1.5)
            }
            .zIndex(1)
            post(height: 7)
            plank(width: 70, height: 24) {
                if unlocked {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { heart in
                            Image(systemName: heart < level ? "heart.fill" : "heart")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(heart < level ? tint.heart : Color.white.opacity(0.85))
                        }
                    }
                }
            }
            .offset(x: rightSide ? -7 : 7)
            post(height: 14)
            Ellipse()
                .fill(tint.canopyDark.opacity(0.75))
                .frame(width: 58, height: 13)
                .padding(.top, -6)
                .zIndex(-1)
        }
        .frame(width: 110, height: 140, alignment: .bottom)
    }

    @ViewBuilder private var head: some View {
        let face = SocialNPCHead(species: npc.species, size: 48)
        if reduceMotion {
            face
        } else {
            let length = 1.1 + Double(index) * 0.17
            face.phaseAnimator([false, true]) { view, up in
                view.offset(y: up ? -3 : 0)
            } animation: { _ in
                .easeInOut(duration: length)
            }
        }
    }

    private func post(height: CGFloat) -> some View {
        Rectangle()
            .fill(tint.signPost)
            .frame(width: 9, height: height)
            .overlay(alignment: .trailing) {
                Rectangle().fill(Color.black.opacity(0.12)).frame(width: 3)
            }
    }

    /// A plank is drawn even when `content` is empty (the lower plank of an unknown friend).
    private func plank<Content: View>(width: CGFloat, height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        return ZStack(alignment: .top) {
            shape.fill(tint.signEdge).offset(y: 3)
            shape.fill(tint.sign)
            Capsule().fill(tint.signGrain).frame(width: width * 0.55, height: 3).padding(.top, 5)
            content()
                .frame(width: width, height: height)
        }
        .frame(width: width, height: height)
        .padding(.bottom, 3)
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

// MARK: - Motion

private struct FriendsWiggleFrame {
    var angle: Double = 0
    var lift: CGFloat = 0
}

/// Quick wobble around the bottom edge each time `trigger` changes (tapped signposts and
/// Gooby). Nothing moves with reduced motion.
private struct FriendsWiggle: ViewModifier {
    var trigger: Int
    @Environment(\.goobyReduceMotion) private var appReduce
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    func body(content: Content) -> some View {
        if appReduce || systemReduce {
            content
        } else {
            content.keyframeAnimator(initialValue: FriendsWiggleFrame(), trigger: trigger) { view, frame in
                view
                    .rotationEffect(.degrees(frame.angle), anchor: .bottom)
                    .offset(y: frame.lift)
            } keyframes: { _ in
                KeyframeTrack(\.angle) {
                    CubicKeyframe(-7, duration: 0.08)
                    CubicKeyframe(6, duration: 0.12)
                    CubicKeyframe(-3, duration: 0.12)
                    SpringKeyframe(0, duration: 0.3, spring: .bouncy)
                }
                KeyframeTrack(\.lift) {
                    CubicKeyframe(-8, duration: 0.12)
                    SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                }
            }
        }
    }
}

extension View {
    /// Wobble and small hop whenever `trigger` changes.
    func friendsWiggle(_ trigger: Int) -> some View {
        modifier(FriendsWiggle(trigger: trigger))
    }
}

/// Two little hearts that rise and fade next to the banner's mini-friend; still with reduced
/// motion.
struct FriendsBannerHearts: View {
    var reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            ZStack {
                heart(size: 11).offset(x: 20, y: -18)
                heart(size: 8).offset(x: -18, y: -22)
            }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    floating(t: t, offset: 0, x: 20, size: 11)
                    floating(t: t, offset: 1.1, x: -18, size: 8)
                }
            }
        }
    }

    private func floating(t: Double, offset: Double, x: CGFloat, size: CGFloat) -> some View {
        let progress = ((t + offset).truncatingRemainder(dividingBy: 2.2)) / 2.2
        let alpha = min(1, min(progress * 5, (1 - progress) * 2.5))
        return heart(size: size)
            .scaleEffect(0.7 + 0.3 * progress)
            .offset(x: x + CGFloat(sin(progress * .pi * 2)) * 2, y: -10 - CGFloat(progress) * 16)
            .opacity(alpha)
    }

    private func heart(size: CGFloat) -> some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size, weight: .heavy))
            .foregroundStyle(Theme.Tab.friends.heart)
            .shadow(color: Color.white.opacity(0.6), radius: 0, x: 0, y: 1)
    }
}
