import SwiftUI

/// Full-bleed scene at the top of Home (screenshot-reference.md, screen 1). While Gooby is out on
/// today's adventure it shows a layered forest with Gooby wearing his backpack; otherwise his room.
/// The scene runs under the status bar; `topInset` is the status bar height.
struct HomeSceneView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var topInset: CGFloat
    @State private var taps = 0
    /// Bumped on every tap and hold so the same reaction can play again.
    @State private var pokes = 0

    /// Reactions a tap cycles through (laugh first, hearts second).
    private static let reactions: [GoobyAnimation] = [.laugh, .hearts, .wiggle, .clap, .hop, .dance]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            let now = engine.now()
            let outside = engine.homeIsOutside(at: now)
            let phase = HomeSceneView.phase(at: now)
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // Room and forest cross-fade when Gooby leaves for an adventure or comes home.
                    backdrop(outside: outside, phase: phase)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .transition(.opacity)
                        .id(outside)
                    if outside && (phase == .evening || phase == .night) {
                        HomeFireflies(reduceMotion: reduceMotion)
                            .frame(width: geo.size.width, height: geo.size.height)
                    } else if outside {
                        GoobyPollenMotes()
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    if outside || FeatureHost.shared.roomScreen == nil {
                        gooby(size: geo.size, outside: outside, night: phase == .night)
                    }
                    HomeWaveEdge()
                        .fill(Theme.Tab.home.bg)
                        .frame(width: geo.size.width, height: 22)
                        .offset(y: geo.size.height - 22)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .animation(GoobyMotion.fadeable(reduceMotion, .easeInOut(duration: 0.7)), value: outside)
            }
        }
    }

    /// Daylight phase of the scene. Screenshot runs always show the reference's dusk.
    static func phase(at date: Date) -> DaylightPhase {
        ShotMode.route != nil ? .evening : DaylightPhase.of(date)
    }

    /// Color above the scene for the scroll bounce at the top.
    static func topColor(engine: GoobyEngine) -> Color {
        let now = engine.now()
        if engine.homeIsOutside(at: now) { return HomeSkyPalette.colors(phase(at: now))[0] }
        return RoomDiorama.wallColor(engine)
    }

    @ViewBuilder
    private func backdrop(outside: Bool, phase: DaylightPhase) -> some View {
        if outside {
            HomeForestScene(phase: phase, topInset: topInset)
        } else if let room = FeatureHost.shared.roomScreen {
            room(engine)
                .contentShape(Rectangle())
                .onTapGesture { react() }
        } else {
            RoomDiorama(engine: engine, reduceMotion: reduceMotion, fullBleed: true, topInset: topInset, showsGooby: false)
        }
    }

    private func gooby(size: CGSize, outside: Bool, night: Bool) -> some View {
        let width = min(size.width * 0.52, 220)
        let height = width * 1.1
        // The rig's feet sit 0.375 of its width below the frame center. Gooby stands above the
        // adventure card, which overlaps the bottom of the scene (TodayView.cardOverlap).
        // The paws and the shadow reach about 20 pt below that point.
        let feet = min(size.height * 0.86, size.height - TodayView.cardOverlap - 28)
        let centerY = feet - width * 0.375
        let name = engine.profile.goobyName.isEmpty ? "Gooby" : engine.profile.goobyName
        return GoobyLiveCharacter(
            engine: engine,
            reduceMotion: reduceMotion,
            adventuring: outside,
            night: night,
            tapToken: pokes
        )
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture { react() }
        .onLongPressGesture(minimumDuration: 0.45) { pet(.petting) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityHint(engine.tx("home.gooby.hint", de: "Antippen zum Lachen, gedrückt halten zum Streicheln.", en: "Tap to make him laugh, hold to pet him."))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { react() }
        .accessibilityAction(named: engine.t("today.pet")) { pet(.petting) }
        .accessibilityAction(named: engine.t("today.hearts")) { pet(.hearts) }
        .position(x: size.width / 2, y: centerY)
    }

    private func react() {
        let next = HomeSceneView.reactions[taps % HomeSceneView.reactions.count]
        taps += 1
        pet(next)
    }

    private func pet(_ animation: GoobyAnimation) {
        pokes += 1
        engine.petAction(animation)
    }
}

/// Soft wave along the bottom of the scene where it meets the green list.
struct HomeWaveEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let crest = rect.minY + rect.height * 0.45
        path.move(to: CGPoint(x: rect.minX, y: crest + rect.height * 0.2))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: crest),
            control1: CGPoint(x: rect.width * 0.18, y: rect.minY - rect.height * 0.15),
            control2: CGPoint(x: rect.width * 0.32, y: crest + rect.height * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: crest - rect.height * 0.1),
            control1: CGPoint(x: rect.width * 0.68, y: crest - rect.height * 0.5),
            control2: CGPoint(x: rect.width * 0.84, y: crest + rect.height * 0.35)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Layered dusk forest drawn in one Canvas: sky with moon and stars, a far blue tree line, rolling
/// hills, pines, grey rocks, two tall round-canopy trees (the left one with a hollow and a tiny
/// dormouse), flowering bushes and a green meadow that runs into the Home background.
struct HomeForestScene: View {
    var phase: DaylightPhase
    var topInset: CGFloat

    var body: some View {
        Canvas { context, size in
            HomeForestPainter(size: size, top: topInset, phase: phase).paint(context)
        }
        .accessibilityHidden(true)
    }
}

/// Sky gradient of the forest per daylight phase, top to horizon.
enum HomeSkyPalette {
    static func colors(_ phase: DaylightPhase) -> [Color] {
        switch phase {
        case .morning: return [Color(hex: 0x8FA8E0), Color(hex: 0xC9B6E0), Color(hex: 0xF6C9C0)]
        case .day: return [Color(hex: 0x6FB8EC), Color(hex: 0x9FD3F2), Color(hex: 0xD3EEF8)]
        case .evening: return [Color(hex: 0x7F86D2), Theme.Tab.home.sky, Theme.Tab.home.skyLow]
        case .night: return [Color(hex: 0x222948), Color(hex: 0x2D3456), Color(hex: 0x46518A)]
        }
    }
}

private struct HomeForestPainter {
    let w: CGFloat
    let h: CGFloat
    let top: CGFloat
    let phase: DaylightPhase

    private let trunk = Color(hex: 0x8A5A3A)
    private let trunkDark = Color(hex: 0x6E4529)
    private let lime = Theme.Tab.home.lime
    private let limeLight = Color(hex: 0xDCE77A)
    private let midGreen = Color(hex: 0x9CC63E)
    private let leaf = Theme.Tab.home.leaf
    private let leafDark = Theme.Tab.home.leafDark
    private let bush = Color(hex: 0x4F9A45)
    private let bushLight = Color(hex: 0x66B052)
    private let ground = Theme.Tab.home.bg

    init(size: CGSize, top: CGFloat, phase: DaylightPhase) {
        w = max(1, size.width)
        h = max(1, size.height)
        self.top = top
        self.phase = phase
    }

    func paint(_ ctx: GraphicsContext) {
        sky(ctx)
        switch phase {
        case .night:
            stars(ctx)
            moon(ctx)
        case .evening:
            stars(ctx)
            sunDisk(ctx)
        case .morning, .day:
            sunDisk(ctx)
            cloud(ctx, x: 0.52, y: top + 62, scale: 1)
            cloud(ctx, x: 0.86, y: top + 120, scale: 0.75)
        }
        farTreeLine(ctx)
        hill(ctx, [p(0, 0.66), p(0.18, 0.62), p(0.42, 0.665), p(0.66, 0.615), p(0.86, 0.65), p(1, 0.63)], farHill)
        hill(ctx, [p(0, 0.72), p(0.22, 0.70), p(0.5, 0.73), p(0.78, 0.69), p(1, 0.72)], Color(hex: 0x68A653))
        pine(ctx, x: 0.30, base: 0.745, height: 0.30, width: 0.13)
        pine(ctx, x: 0.63, base: 0.735, height: 0.18, width: 0.085)
        pine(ctx, x: 0.72, base: 0.75, height: 0.27, width: 0.12)
        rocks(ctx)
        yellowBushes(ctx)
        hill(ctx, [p(0, 0.80), p(0.3, 0.775), p(0.62, 0.79), p(1, 0.77)], ground)
        leftTree(ctx)
        rightTree(ctx)
        bushes(ctx)
        meadow(ctx)
        // Fireflies glow in their own animated layer (HomeFireflies).
        if phase == .night {
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(Color(hex: 0x1C2347).opacity(0.25)))
        } else if phase == .morning {
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(Theme.peach.opacity(0.08)))
        }
    }

    // MARK: Helpers

    /// Point from fractions of the width and height.
    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }

    private func circle(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color) {
        let radius = r * w
        ctx.fill(Path(ellipseIn: CGRect(x: x * w - radius, y: y * h - radius, width: radius * 2, height: radius * 2)), with: .color(color))
    }

    private func dot(_ ctx: GraphicsContext, _ center: CGPoint, _ radius: CGFloat, _ color: Color) {
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
    }

    private func ellipse(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ color: Color) {
        ctx.fill(Path(ellipseIn: CGRect(x: (x - width / 2) * w, y: (y - height / 2) * h, width: width * w, height: height * h)), with: .color(color))
    }

    private func glow(_ ctx: GraphicsContext, _ center: CGPoint, _ radius: CGFloat, _ color: Color, _ strength: Double) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [color.opacity(strength), color.opacity(0)]),
            center: center, startRadius: 0, endRadius: radius
        ))
    }

    /// Smooth crest line through `points`, filled down to the bottom edge.
    private func hill(_ ctx: GraphicsContext, _ points: [CGPoint], _ color: Color) {
        guard points.count >= 2 else { return }
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: points[0])
        if points.count > 2 {
            for index in 1..<(points.count - 1) {
                let next = points[index + 1]
                let mid = CGPoint(x: (points[index].x + next.x) / 2, y: (points[index].y + next.y) / 2)
                path.addQuadCurve(to: mid, control: points[index])
            }
        }
        path.addLine(to: points[points.count - 1])
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        ctx.fill(path, with: .color(color))
    }

    private var farColor: Color {
        switch phase {
        case .morning: return Color(hex: 0x9C9FCB)
        case .day: return Color(hex: 0x8CBCC4)
        case .evening: return Color(hex: 0x5F6AAB)
        case .night: return Color(hex: 0x353F6C)
        }
    }

    private var farHill: Color {
        switch phase {
        case .morning: return Color(hex: 0x86AE8E)
        case .day: return Color(hex: 0x7DB47E)
        case .evening: return Color(hex: 0x56868E)
        case .night: return Color(hex: 0x3A5E66)
        }
    }

    // MARK: Layers

    private func sky(_ ctx: GraphicsContext) {
        let colors = HomeSkyPalette.colors(phase)
        ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .linearGradient(
            Gradient(colors: colors),
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 0, y: h * 0.68)
        ))
    }

    private func stars(_ ctx: GraphicsContext) {
        let spots: [(CGFloat, CGFloat, CGFloat, Double)] = [
            (0.38, 0.20, 1.4, 0.9), (0.47, 0.30, 1.0, 0.6), (0.55, 0.17, 1.6, 0.85), (0.60, 0.38, 1.0, 0.5),
            (0.84, 0.44, 1.2, 0.7), (0.33, 0.40, 1.1, 0.55), (0.50, 0.46, 0.9, 0.45), (0.88, 0.30, 1.0, 0.6),
            (0.25, 0.30, 1.0, 0.5), (0.66, 0.26, 1.3, 0.75)
        ]
        let count = phase == .night ? spots.count : 6
        for spot in spots.prefix(count) {
            let center = CGPoint(x: spot.0 * w, y: max(top + 8, spot.1 * h))
            dot(ctx, center, spot.2, Color.white.opacity(spot.3))
        }
    }

    private func moon(_ ctx: GraphicsContext) {
        let center = CGPoint(x: w * 0.68, y: top + 66)
        let radius = w * 0.052
        glow(ctx, center, radius * 3.2, Theme.Tab.home.moon, 0.32)
        dot(ctx, center, radius, Theme.Tab.home.moon)
        dot(ctx, CGPoint(x: center.x - radius * 0.35, y: center.y - radius * 0.2), radius * 0.2, Color(hex: 0xE4DDB8))
        dot(ctx, CGPoint(x: center.x + radius * 0.3, y: center.y + radius * 0.35), radius * 0.14, Color(hex: 0xE4DDB8))
        dot(ctx, CGPoint(x: center.x + radius * 0.4, y: center.y - radius * 0.4), radius * 0.1, Color(hex: 0xE4DDB8))
    }

    /// Big yellow disk low in the sky, partly behind the left tree (screen F).
    private func sunDisk(_ ctx: GraphicsContext) {
        let center = CGPoint(x: w * 0.36, y: max(top + 70, h * 0.3))
        let radius = w * 0.1
        glow(ctx, center, radius * 2.6, Color(hex: 0xFFF3B0), phase == .evening ? 0.35 : 0.5)
        dot(ctx, center, radius, Theme.Tab.home.sun)
        dot(ctx, CGPoint(x: center.x + radius * 0.18, y: center.y + radius * 0.12), radius * 0.78, Color(hex: 0xFAE37F))
    }

    /// Two yellow-green bushes behind the meadow.
    private func yellowBushes(_ ctx: GraphicsContext) {
        let clusters: [(CGFloat, CGFloat, CGFloat)] = [(0.40, 0.79, 0.055), (0.47, 0.795, 0.04), (0.60, 0.785, 0.05)]
        for cluster in clusters {
            circle(ctx, cluster.0, cluster.1 + 0.008, cluster.2, Color(hex: 0xC9B23C))
            circle(ctx, cluster.0, cluster.1, cluster.2, Color(hex: 0xE6CF52))
            circle(ctx, cluster.0 - cluster.2 * 0.3, cluster.1 - cluster.2 * 0.5, cluster.2 * 0.45, Color(hex: 0xF3E07A))
        }
    }

    /// Lighter bark stripes down a trunk.
    private func stripes(_ ctx: GraphicsContext, x: CGFloat, from topY: CGFloat, to bottomY: CGFloat) {
        let light = Color(hex: 0xA87452)
        for (dx, start, end) in [(-0.012, 0.0, 0.42), (0.004, 0.3, 0.8), (-0.004, 0.62, 0.95)] as [(CGFloat, CGFloat, CGFloat)] {
            var line = Path()
            line.move(to: CGPoint(x: (x + dx) * w, y: (topY + (bottomY - topY) * start) * h))
            line.addLine(to: CGPoint(x: (x + dx) * w, y: (topY + (bottomY - topY) * end) * h))
            ctx.stroke(line, with: .color(light), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        }
    }

    private func cloud(_ ctx: GraphicsContext, x: CGFloat, y: CGFloat, scale: CGFloat) {
        let unit = w * 0.05 * scale
        let cx = x * w
        let color = Color.white.opacity(0.9)
        dot(ctx, CGPoint(x: cx - unit * 1.1, y: y + unit * 0.2), unit * 0.8, color)
        dot(ctx, CGPoint(x: cx, y: y - unit * 0.25), unit * 1.1, color)
        dot(ctx, CGPoint(x: cx + unit * 1.1, y: y + unit * 0.15), unit * 0.85, color)
        ctx.fill(Path(roundedRect: CGRect(x: cx - unit * 1.9, y: y + unit * 0.1, width: unit * 3.8, height: unit * 0.9), cornerRadius: unit * 0.45), with: .color(color))
    }

    /// Far blue tree line: round tree tops and pine tips.
    private func farTreeLine(_ ctx: GraphicsContext) {
        let color = farColor
        let rounds: [(CGFloat, CGFloat, CGFloat)] = [
            (0.02, 0.585, 0.09), (0.14, 0.56, 0.08), (0.24, 0.585, 0.07), (0.40, 0.575, 0.085),
            (0.52, 0.595, 0.07), (0.62, 0.565, 0.08), (0.80, 0.58, 0.09), (0.93, 0.56, 0.08)
        ]
        for round in rounds { circle(ctx, round.0, round.1, round.2, color) }
        for tip in [0.32, 0.47, 0.71, 0.87] as [CGFloat] {
            var path = Path()
            path.move(to: p(tip, 0.44))
            path.addLine(to: p(tip + 0.045, 0.62))
            path.addLine(to: p(tip - 0.045, 0.62))
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3, lineJoin: .round))
        }
        ctx.fill(Path(CGRect(x: 0, y: h * 0.58, width: w, height: h * 0.12)), with: .color(color))
    }

    private func pine(_ ctx: GraphicsContext, x: CGFloat, base: CGFloat, height: CGFloat, width: CGFloat) {
        let cx = x * w
        let bottom = base * h
        let tall = height * h
        let wide = width * w
        ctx.fill(Path(CGRect(x: cx - wide * 0.07, y: bottom - tall * 0.14, width: wide * 0.14, height: tall * 0.14)), with: .color(trunkDark))
        for tier in 0..<3 {
            let step = CGFloat(tier)
            let tierBottom = bottom - tall * 0.1 - step * tall * 0.24
            let tierTop = tierBottom - tall * (tier == 2 ? 0.42 : 0.38)
            let tierWide = wide * (1 - step * 0.22)
            var shape = Path()
            shape.move(to: CGPoint(x: cx, y: tierTop))
            shape.addLine(to: CGPoint(x: cx + tierWide / 2, y: tierBottom))
            shape.addLine(to: CGPoint(x: cx - tierWide / 2, y: tierBottom))
            shape.closeSubpath()
            ctx.fill(shape, with: .color(leafDark))
            ctx.stroke(shape, with: .color(leafDark), style: StrokeStyle(lineWidth: 4, lineJoin: .round))
            var lit = Path()
            lit.move(to: CGPoint(x: cx, y: tierTop))
            lit.addLine(to: CGPoint(x: cx, y: tierBottom))
            lit.addLine(to: CGPoint(x: cx - tierWide / 2, y: tierBottom))
            lit.closeSubpath()
            ctx.fill(lit, with: .color(Color(hex: 0x4E9C4C)))
        }
    }

    private func rocks(_ ctx: GraphicsContext) {
        let base = Theme.Tab.home.rock
        let light = Color(hex: 0xB8BEC3)
        let shade = Color(hex: 0x838A90)
        ellipse(ctx, 0.81, 0.79, 0.27, 0.15, shade)
        ellipse(ctx, 0.80, 0.78, 0.26, 0.14, base)
        ellipse(ctx, 0.77, 0.745, 0.15, 0.055, light)
        ellipse(ctx, 0.95, 0.80, 0.12, 0.09, shade)
        ellipse(ctx, 0.945, 0.795, 0.11, 0.085, Color(hex: 0xA3AAAF))
        ellipse(ctx, 0.25, 0.80, 0.15, 0.085, shade)
        ellipse(ctx, 0.245, 0.795, 0.14, 0.08, base)
        ellipse(ctx, 0.23, 0.78, 0.08, 0.03, light)
    }

    private func trunkShape(x: CGFloat, top topY: CGFloat, bottom: CGFloat, width: CGFloat) -> (Path, Path) {
        let cx = x * w
        let ty = topY * h
        let by = bottom * h
        let half = width * w / 2
        let flare = by - (by - ty) * 0.16
        var body = Path()
        body.move(to: CGPoint(x: cx - half * 0.8, y: ty))
        body.addLine(to: CGPoint(x: cx + half * 0.8, y: ty))
        body.addQuadCurve(to: CGPoint(x: cx + half * 1.8, y: by), control: CGPoint(x: cx + half, y: flare))
        body.addLine(to: CGPoint(x: cx - half * 1.8, y: by))
        body.addQuadCurve(to: CGPoint(x: cx - half * 0.8, y: ty), control: CGPoint(x: cx - half, y: flare))
        body.closeSubpath()
        var shade = Path()
        shade.move(to: CGPoint(x: cx + half * 0.15, y: ty))
        shade.addLine(to: CGPoint(x: cx + half * 0.8, y: ty))
        shade.addQuadCurve(to: CGPoint(x: cx + half * 1.8, y: by), control: CGPoint(x: cx + half, y: flare))
        shade.addLine(to: CGPoint(x: cx + half * 0.55, y: by))
        shade.closeSubpath()
        return (body, shade)
    }

    /// Tall tree on the left with a lime canopy and a hollow with a dormouse.
    private func leftTree(_ ctx: GraphicsContext) {
        let shapes = trunkShape(x: 0.105, top: 0.18, bottom: 0.86, width: 0.08)
        ctx.fill(shapes.0, with: .color(trunk))
        ctx.fill(shapes.1, with: .color(trunkDark))
        stripes(ctx, x: 0.095, from: 0.36, to: 0.82)
        // Branch to the right.
        var branch = Path()
        branch.move(to: p(0.12, 0.40))
        branch.addQuadCurve(to: p(0.25, 0.30), control: p(0.20, 0.39))
        ctx.stroke(branch, with: .color(trunk), style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round))
        hollow(ctx, center: p(0.102, 0.585))
        // Canopy: shade, body, highlights.
        circle(ctx, 0.07, 0.30, 0.14, Color(hex: 0x86B33A))
        circle(ctx, 0.25, 0.27, 0.085, Color(hex: 0x86B33A))
        circle(ctx, -0.02, 0.14, 0.17, lime)
        circle(ctx, 0.15, 0.07, 0.13, lime)
        circle(ctx, 0.22, 0.20, 0.10, midGreen)
        circle(ctx, 0.05, 0.25, 0.12, midGreen)
        circle(ctx, 0.27, 0.27, 0.07, lime)
        circle(ctx, 0.10, 0.16, 0.10, lime)
        circle(ctx, 0.04, 0.09, 0.05, limeLight)
        circle(ctx, 0.17, 0.12, 0.035, limeLight)
        circle(ctx, 0.25, 0.23, 0.03, limeLight)
    }

    private func hollow(_ ctx: GraphicsContext, center: CGPoint) {
        let width = w * 0.054
        let height = h * 0.085
        let rect = CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
        ctx.fill(Path(ellipseIn: rect.insetBy(dx: -2.5, dy: -2.5)), with: .color(Color(hex: 0xA97852)))
        ctx.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0x3B2414)))
        // Dormouse peeking out: fawn head, round ears, dot eyes, pink nose.
        let head = CGPoint(x: center.x, y: center.y + height * 0.14)
        let fur = Color(hex: 0xD9C4A3)
        dot(ctx, CGPoint(x: head.x - 5, y: head.y - 5.5), 3.2, fur)
        dot(ctx, CGPoint(x: head.x + 5, y: head.y - 5.5), 3.2, fur)
        dot(ctx, CGPoint(x: head.x - 5, y: head.y - 5.5), 1.7, Color(hex: 0xF4B3C2))
        dot(ctx, CGPoint(x: head.x + 5, y: head.y - 5.5), 1.7, Color(hex: 0xF4B3C2))
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - 7, y: head.y - 6, width: 14, height: 12)), with: .color(fur))
        dot(ctx, CGPoint(x: head.x - 2.6, y: head.y - 1), 1.3, Color(hex: 0x2B2B2B))
        dot(ctx, CGPoint(x: head.x + 2.6, y: head.y - 1), 1.3, Color(hex: 0x2B2B2B))
        dot(ctx, CGPoint(x: head.x, y: head.y + 1.8), 1.1, Color(hex: 0xE9899E))
    }

    /// Tall tree on the right with a mid-green canopy.
    private func rightTree(_ ctx: GraphicsContext) {
        let shapes = trunkShape(x: 0.915, top: 0.30, bottom: 0.85, width: 0.065)
        ctx.fill(shapes.0, with: .color(trunk))
        ctx.fill(shapes.1, with: .color(trunkDark))
        stripes(ctx, x: 0.905, from: 0.42, to: 0.82)
        // Knot hole.
        ellipse(ctx, 0.9, 0.6, 0.026, 0.032, Color(hex: 0xA97852))
        ellipse(ctx, 0.9, 0.602, 0.017, 0.022, Color(hex: 0x4A2E1A))
        circle(ctx, 0.97, 0.36, 0.13, Color(hex: 0x3F8A3C))
        circle(ctx, 0.80, 0.30, 0.085, Color(hex: 0x4B9744))
        circle(ctx, 1.0, 0.20, 0.15, leaf)
        circle(ctx, 0.85, 0.22, 0.10, Color(hex: 0x6DB54E))
        circle(ctx, 0.93, 0.29, 0.10, leaf)
        circle(ctx, 0.86, 0.16, 0.05, lime)
        circle(ctx, 0.97, 0.12, 0.045, lime)
        circle(ctx, 0.80, 0.26, 0.03, limeLight)
    }

    private func bushes(_ ctx: GraphicsContext) {
        let clusters: [(CGFloat, CGFloat, CGFloat)] = [
            (0.02, 0.875, 0.085), (0.13, 0.895, 0.07), (0.22, 0.915, 0.05),
            (0.84, 0.905, 0.06), (0.95, 0.88, 0.08)
        ]
        for cluster in clusters {
            circle(ctx, cluster.0, cluster.1 + 0.01, cluster.2, Color(hex: 0x3F8A3C))
            circle(ctx, cluster.0, cluster.1, cluster.2, bush)
            circle(ctx, cluster.0 - cluster.2 * 0.3, cluster.1 - cluster.2 * 0.45, cluster.2 * 0.45, bushLight)
        }
        let flowers: [(CGFloat, CGFloat, Bool)] = [
            (0.04, 0.855, true), (0.10, 0.88, false), (0.17, 0.885, true), (0.01, 0.9, false), (0.215, 0.905, false),
            (0.83, 0.89, true), (0.92, 0.86, false), (0.97, 0.895, true), (0.88, 0.91, false)
        ]
        for flower in flowers {
            blossom(ctx, p(flower.0, flower.1), color: flower.2 ? Color(hex: 0xE8505B) : Color(hex: 0xF59AC0))
        }
    }

    private func blossom(_ ctx: GraphicsContext, _ center: CGPoint, color: Color) {
        for petal in 0..<5 {
            let angle = Double(petal) / 5 * 2 * Double.pi
            let offset = CGPoint(x: center.x + CGFloat(cos(angle)) * 2.6, y: center.y + CGFloat(sin(angle)) * 2.6)
            dot(ctx, offset, 2.3, color)
        }
        dot(ctx, center, 1.6, Color(hex: 0xFFD45E))
    }

    /// Light spot where Gooby stands, plus grass tufts.
    private func meadow(_ ctx: GraphicsContext) {
        ellipse(ctx, 0.5, 0.85, 0.46, 0.075, Color(hex: 0x8CC66A))
        let tufts: [(CGFloat, CGFloat)] = [(0.33, 0.83), (0.42, 0.80), (0.60, 0.82), (0.70, 0.86), (0.28, 0.93), (0.74, 0.95), (0.52, 0.79)]
        for tuft in tufts {
            let base = p(tuft.0, tuft.1)
            var blades = Path()
            blades.move(to: base)
            blades.addLine(to: CGPoint(x: base.x - 3, y: base.y - 6))
            blades.move(to: base)
            blades.addLine(to: CGPoint(x: base.x, y: base.y - 8))
            blades.move(to: base)
            blades.addLine(to: CGPoint(x: base.x + 3, y: base.y - 6))
            ctx.stroke(blades, with: .color(Color(hex: 0x5E9E48)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        }
    }

}

/// Fireflies over the evening and night forest: each drifts on a small loop and its glow swells
/// and fades. With reduced motion (and on hidden tabs) they stand still at a steady glow.
struct HomeFireflies: View {
    var reduceMotion: Bool

    /// Position as fractions of the scene and a phase offset in seconds.
    private static let spots: [(CGFloat, CGFloat, Double)] = [
        (0.36, 0.62, 0), (0.58, 0.55, 1.3), (0.66, 0.70, 2.1), (0.20, 0.68, 0.7), (0.46, 0.50, 2.8), (0.82, 0.58, 1.9)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas { context, size in
                let light = Color(hex: 0xFFF3A0)
                for spot in HomeFireflies.spots {
                    let phase = time * 0.6 + spot.2
                    let x = spot.0 * size.width + CGFloat(sin(phase * 0.9)) * (reduceMotion ? 0 : 10)
                    let y = spot.1 * size.height + CGFloat(cos(phase * 0.7)) * (reduceMotion ? 0 : 7)
                    let strength = reduceMotion ? 0.55 : 0.3 + 0.4 * (sin(phase * 2.1) + 1) / 2
                    let center = CGPoint(x: x, y: y)
                    let radius: CGFloat = 8
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                        with: .radialGradient(
                            Gradient(colors: [light.opacity(strength), light.opacity(0)]),
                            center: center, startRadius: 0, endRadius: radius
                        )
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 1.7, y: y - 1.7, width: 3.4, height: 3.4)),
                        with: .color(Color(hex: 0xFFF7C2).opacity(min(1, 0.55 + strength * 0.6)))
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Button style for the flat translucent Home cards: a slight scale when reduce motion is off.
struct HomeSoftPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    func makeBody(configuration: Configuration) -> some View {
        let reduce = systemReduce || appReduce
        return configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(!reduce && configuration.isPressed ? 0.98 : 1)
            .animation(reduce ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
