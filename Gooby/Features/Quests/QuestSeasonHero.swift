import SwiftUI

enum QuestSeasonText {
    static func ribbon(_ engine: GoobyEngine, _ window: QuestSeasonWindow) -> String {
        if window.forced { return engine.t("quests.season.open") }
        if window.active {
            if window.daysLeft <= 0 { return engine.t("quests.season.left.today") }
            if window.daysLeft == 1 { return engine.t("quests.season.left.one") }
            return engine.tf("quests.season.left.many", window.daysLeft)
        }
        if window.daysUntilStart <= 1 { return engine.t("quests.season.unlock.one") }
        return engine.tf("quests.season.unlock.many", max(2, window.daysUntilStart))
    }

    static func jarLabel(_ engine: GoobyEngine, _ window: QuestSeasonWindow?) -> (open: Bool, label: String) {
        guard let window else { return (true, engine.t("quests.season.open")) }
        if window.forced || window.active {
            return (true, ribbon(engine, window))
        }
        if window.daysUntilStart <= 1 {
            return (false, engine.t("quests.jar.opens.one"))
        }
        return (false, engine.tf("quests.jar.opens.many", window.daysUntilStart))
    }

    static func kicker(_ engine: GoobyEngine, _ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateFormat = "LLLL"
        let month = formatter.string(from: date).uppercased(with: formatter.locale)
        return engine.tf("quests.season.kicker", month)
    }
}

struct QuestSeasonHero: View {
    var engine: GoobyEngine
    var window: QuestSeasonWindow
    var calm: Bool

    var body: some View {
        let event = engine.catalog.events.first { $0.id == window.eventID }
        let title = event?.title.text(engine.languageCode) ?? window.eventID
        let kicker = QuestSeasonText.kicker(engine, window.starts)
        let ribbon = QuestSeasonText.ribbon(engine, window)
        let month = Calendar.current.component(.month, from: window.starts)
        ZStack {
            QuestSeasonScene(month: month, locked: !window.active, calm: calm)
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text(kicker)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .textCase(.uppercase)
                    Text(title)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .tracking(0.2)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.55)
                }
                .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                .padding(.horizontal, 16)
                Spacer(minLength: 0)
                QuestRibbon(text: ribbon)
                    .padding(.bottom, 14)
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: QuestColor.cardShadow.opacity(0.18), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kicker). \(title). \(ribbon)")
    }
}

struct QuestRibbon: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 22)
            .padding(.vertical, 7)
            .background(QuestRibbonShape().fill(Color(hex: 0x3EAF4A)))
            .shadow(color: .black.opacity(0.28), radius: 0, y: 2)
            .accessibilityLabel(text)
    }
}

struct QuestRibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch = rect.height * 0.42
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + notch, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct QuestSeasonScene: View {
    var month: Int
    var locked: Bool
    var calm: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: calm ? 8 : 1.0 / 20.0, paused: calm)) { timeline in
            let time = calm ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                QuestSeasonArt.paint(&context, size: size, month: month, locked: locked, time: time)
            }
        }
        .accessibilityHidden(true)
    }
}

enum QuestSeasonArt {
    private struct Ink {
        var top: Color
        var bottom: Color
        var hill: Color
        var tree: Color
        var ground: Color
        var glow: Color
    }

    static func paint(_ context: inout GraphicsContext, size: CGSize, month: Int, locked: Bool, time: Double) {
        let ink = palette(month)
        let w = size.width
        let h = size.height
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }
        func circle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) -> Path {
            let center = at(x, y)
            return Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }

        let sky = Path(CGRect(origin: .zero, size: size))
        context.fill(sky, with: .linearGradient(
            Gradient(colors: [ink.top, ink.bottom]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: h)
        ))

        let drift: CGFloat = time == 0 ? 0 : CGFloat(sin(time * 0.18) * 7)
        context.drawLayer { layer in
            layer.translateBy(x: drift, y: 0)
            layer.fill(circle(0.78, 0.24, 18), with: .color(Color.white.opacity(0.92)))
            layer.fill(circle(0.78, 0.24, 14), with: .color(ink.glow))
        }

        for index in 0..<6 {
            let seed = Double(index)
            let alpha = time == 0 ? 0.7 : 0.35 + 0.5 * abs(sin(time * 1.1 + seed))
            let x = CGFloat(0.12 + Double(index) * 0.13)
            let y = CGFloat(0.12 + Double((index * 3) % 5) * 0.04)
            context.fill(circle(x, y, 1.6), with: .color(Color.white.opacity(alpha)))
        }

        var hill = Path()
        hill.move(to: at(0, 0.78))
        hill.addQuadCurve(to: at(1, 0.82), control: at(0.5, 0.52))
        hill.addLine(to: at(1, 1))
        hill.addLine(to: at(0, 1))
        hill.closeSubpath()
        context.fill(hill, with: .color(ink.hill))

        pine(context: &context, x: 0.16, scale: 1.05, ink: ink, at: at)
        pine(context: &context, x: 0.84, scale: 1.15, ink: ink, at: at)
        pine(context: &context, x: 0.08, scale: 0.72, ink: ink, at: at)

        let hollow = arch(at: at)
        context.fill(hollow, with: .color(ink.tree.opacity(0.95)))
        context.drawLayer { layer in
            layer.clip(to: hollow)
            let glow = circle(0.5, 0.62, locked ? 28 : 46)
            layer.fill(glow, with: .color(ink.glow.opacity(locked ? 0.35 : 0.85)))
        }

        var ground = Path()
        ground.move(to: at(0, 0.84))
        ground.addQuadCurve(to: at(1, 0.86), control: at(0.5, 0.78))
        ground.addLine(to: at(1, 1))
        ground.addLine(to: at(0, 1))
        ground.closeSubpath()
        context.fill(ground, with: .color(ink.ground))

        mushroom(&context, x: 0.3, y: 0.8, ink: ink, at: at)
        mushroom(&context, x: 0.68, y: 0.82, ink: ink, at: at)
        bunny(&context, at: at)

        if locked {
            lock(&context, at: at(0.5, 0.58))
        }

        let scrim = Path(CGRect(x: 0, y: 0, width: w, height: h * 0.48))
        context.fill(scrim, with: .linearGradient(
            Gradient(colors: [Color.black.opacity(0.42), Color.black.opacity(0)]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: h * 0.48)
        ))
    }

    private static func palette(_ month: Int) -> Ink {
        switch month {
        case 12, 1, 2:
            return Ink(
                top: Color(hex: 0x1B3A68),
                bottom: Color(hex: 0x6E93C4),
                hill: Color(hex: 0x243E62),
                tree: Color(hex: 0x16324C),
                ground: Color(hex: 0xE7F0F6),
                glow: Color(hex: 0xF6E2A4)
            )
        case 3, 4, 5:
            return Ink(
                top: Color(hex: 0x6EB0DE),
                bottom: Color(hex: 0xD4EEC0),
                hill: Color(hex: 0x5C9A55),
                tree: Color(hex: 0x2C7340),
                ground: Color(hex: 0x8FCB6C),
                glow: Color(hex: 0xFFE08A)
            )
        case 6, 7, 8:
            return Ink(
                top: Color(hex: 0x3E97D8),
                bottom: Color(hex: 0xC6E58A),
                hill: Color(hex: 0x3C8A48),
                tree: Color(hex: 0x1E6A36),
                ground: Color(hex: 0x74C45A),
                glow: Color(hex: 0xFFF1B8)
            )
        default:
            return Ink(
                top: Color(hex: 0x2C403C),
                bottom: Color(hex: 0x6E5844),
                hill: Color(hex: 0x24362F),
                tree: Color(hex: 0x1A2E28),
                ground: Color(hex: 0x4E3B30),
                glow: Color(hex: 0xF0B45A)
            )
        }
    }

    private static func pine(
        context: inout GraphicsContext,
        x: CGFloat,
        scale: CGFloat,
        ink: Ink,
        at: (CGFloat, CGFloat) -> CGPoint
    ) {
        var tree = Path()
        tree.move(to: at(x, 0.28))
        tree.addLine(to: at(x - 0.11 * scale, 0.8))
        tree.addLine(to: at(x + 0.11 * scale, 0.8))
        tree.closeSubpath()
        context.fill(tree, with: .color(ink.tree))
        let trunk = at(x, 0.8)
        context.fill(
            Path(CGRect(x: trunk.x - 3, y: trunk.y - 4, width: 6, height: 16)),
            with: .color(Color(hex: 0x5C4034))
        )
    }

    private static func arch(at: (CGFloat, CGFloat) -> CGPoint) -> Path {
        var path = Path()
        path.move(to: at(0.34, 0.8))
        path.addQuadCurve(to: at(0.66, 0.8), control: at(0.5, 0.36))
        path.closeSubpath()
        return path
    }

    private static func mushroom(
        _ context: inout GraphicsContext,
        x: CGFloat,
        y: CGFloat,
        ink: Ink,
        at: (CGFloat, CGFloat) -> CGPoint
    ) {
        let origin = at(x, y)
        context.fill(
            Path(roundedRect: CGRect(x: origin.x - 2, y: origin.y - 8, width: 4, height: 12), cornerRadius: 1.5),
            with: .color(Color(hex: 0xF4E2C4))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: origin.x - 8, y: origin.y - 14, width: 16, height: 10)),
            with: .color(ink.glow)
        )
    }

    private static func bunny(_ context: inout GraphicsContext, at: (CGFloat, CGFloat) -> CGPoint) {
        let head = at(0.5, 0.74)
        let earL = CGRect(x: head.x - 12, y: head.y - 22, width: 8, height: 16)
        let earR = CGRect(x: head.x + 4, y: head.y - 22, width: 8, height: 16)
        context.fill(Path(ellipseIn: earL), with: .color(Color(hex: 0xFFF3E3)))
        context.fill(Path(ellipseIn: earR), with: .color(Color(hex: 0xFFF3E3)))
        context.fill(Path(ellipseIn: earL.insetBy(dx: 2, dy: 3)), with: .color(Color(hex: 0xFFB7C8)))
        context.fill(Path(ellipseIn: earR.insetBy(dx: 2, dy: 3)), with: .color(Color(hex: 0xFFB7C8)))
        context.fill(
            Path(ellipseIn: CGRect(x: head.x - 14, y: head.y - 12, width: 28, height: 24)),
            with: .color(Color(hex: 0xFFF6EA))
        )
        for dx in [CGFloat(-5), 5] {
            context.fill(
                Path(ellipseIn: CGRect(x: head.x + dx - 1.4, y: head.y - 2, width: 2.8, height: 3.4)),
                with: .color(Color(hex: 0x4A3428))
            )
        }
        context.fill(
            Path(ellipseIn: CGRect(x: head.x - 1.2, y: head.y + 2, width: 2.4, height: 1.6)),
            with: .color(Color(hex: 0xF08CA0))
        )
    }

    private static func lock(_ context: inout GraphicsContext, at center: CGPoint) {
        var shackle = Path()
        shackle.move(to: CGPoint(x: center.x - 9, y: center.y + 1))
        shackle.addQuadCurve(
            to: CGPoint(x: center.x + 9, y: center.y + 1),
            control: CGPoint(x: center.x, y: center.y - 20)
        )
        context.stroke(
            shackle,
            with: .color(Color(hex: 0xF8E7A2)),
            style: StrokeStyle(lineWidth: 5, lineCap: .round)
        )
        let body = CGRect(x: center.x - 15, y: center.y - 2, width: 30, height: 24)
        context.fill(Path(roundedRect: body, cornerRadius: 6), with: .color(Color(hex: 0xF6C445)))
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - 3, y: center.y + 6, width: 6, height: 6)),
            with: .color(Color(hex: 0x8A6420))
        )
    }
}
