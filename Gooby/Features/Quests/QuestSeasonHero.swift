import SwiftUI

@MainActor
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
        let title = heroTitle(event)
        let kicker = QuestSeasonText.kicker(engine, window.starts)
        let ribbon = QuestSeasonText.ribbon(engine, window)
        let month = Calendar.current.component(.month, from: window.starts)
        let locked = !window.active
        let still = posed(calm)
        ZStack {
            QuestSeasonScene(month: month, locked: locked, calm: calm)
            GeometryReader { geo in
                let w = geo.size.width / QuestHeroMetric.width
                let h = geo.size.height / QuestHeroMetric.height
                let shade = Color(white: locked ? 0.38 : 0.88)
                ForEach(QuestHeroMetric.guests.indices, id: \.self) { index in
                    let guest = QuestHeroMetric.guests[index]
                    QuestHeroGooby(animation: guest.animation, calm: true)
                        .colorMultiply(shade)
                        .frame(width: guest.size * h, height: guest.size * h)
                        .scaleEffect(x: guest.flip ? -1 : 1)
                        .position(x: guest.x * w, y: guest.y * h)
                }
                QuestHeroGooby(animation: locked ? .curious : .wave, calm: still)
                    .colorMultiply(shade)
                    .frame(width: QuestHeroMetric.hero.size * h, height: QuestHeroMetric.hero.size * h)
                    .position(x: QuestHeroMetric.hero.x * w, y: QuestHeroMetric.hero.y * h)
                if locked {
                    QuestHeroLock()
                        .frame(width: 54 * h, height: 56 * h)
                        .position(x: QuestHeroMetric.lock.x * w, y: QuestHeroMetric.lock.y * h)
                }
            }
            .allowsHitTesting(false)
            VStack(spacing: 0) {
                Text(kicker)
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(1.7)
                    .textCase(.uppercase)
                Text(title)
                    .font(.system(size: 20.5, weight: .black))
                    .italic()
                    .tracking(0.35)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.85), radius: 0, x: 0.6, y: 1.6)
                    .padding(.top, 8)
                Spacer(minLength: 0)
                QuestRibbon(text: ribbon)
                    .padding(.bottom, 26)
            }
            .padding(.top, 28)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: QuestHeroMetric.height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kicker). \(title). \(ribbon)")
    }

    private func heroTitle(_ event: EventDef?) -> String {
        #if DEBUG
        if QuestShotSeed.active { return QuestShotSeed.heroTitle }
        #endif
        return event?.title.text(engine.languageCode) ?? window.eventID
    }

    /// Screenshots keep one pose so the hero can be compared frame to frame.
    private func posed(_ calm: Bool) -> Bool {
        #if DEBUG
        if QuestShotSeed.active { return true }
        #endif
        return calm
    }
}

/// Placement in the 372 × 230 point hero, measured from the Finch frame at 0.67 pt per pixel.
enum QuestHeroMetric {
    struct Spot {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var animation: GoobyAnimation = .idle
        var flip = false
    }

    static let width: CGFloat = 372
    static let height: CGFloat = 230
    static let hero = Spot(x: 158, y: 156, size: 84)
    static let lock = CGPoint(x: 210, y: 154)
    static let guests = [
        Spot(x: 62, y: 168, size: 128, animation: .wave),
        Spot(x: 342, y: 158, size: 146, animation: .sit, flip: true)
    ]
}

struct QuestHeroGooby: View {
    var animation: GoobyAnimation
    var calm: Bool

    var body: some View {
        GoobyCharacterView(look: WornLook(), stage: "young", animation: animation, reduceMotion: calm, companion: nil)
            .accessibilityHidden(true)
    }
}

struct QuestHeroLock: View {
    var body: some View {
        Canvas { context, size in
            let s = size.width / 52
            context.scaleBy(x: s, y: s)
            var shackle = Path()
            shackle.move(to: CGPoint(x: 13, y: 28))
            shackle.addLine(to: CGPoint(x: 13, y: 18))
            shackle.addCurve(to: CGPoint(x: 39, y: 18), control1: CGPoint(x: 13, y: 0), control2: CGPoint(x: 39, y: 0))
            shackle.addLine(to: CGPoint(x: 39, y: 28))
            context.stroke(shackle, with: .color(Color(hex: 0xB9BCC6)), style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
            context.stroke(shackle, with: .color(Color(hex: 0xD6D8E0)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            let body = CGRect(x: 1, y: 19, width: 50, height: 35)
            context.fill(Path(roundedRect: body, cornerRadius: 7), with: .color(Color(hex: 0xE9B23A)))
            context.fill(Path(roundedRect: body.insetBy(dx: 0, dy: 0).offsetBy(dx: 0, dy: -2.5), cornerRadius: 7), with: .color(Color(hex: 0xF8CB4B)))
            context.fill(Path(ellipseIn: CGRect(x: 21.5, y: 28, width: 9, height: 9)), with: .color(Color(hex: 0x5E5A55)))
            context.fill(Path(roundedRect: CGRect(x: 24, y: 33, width: 4, height: 10), cornerRadius: 2), with: .color(Color(hex: 0x5E5A55)))
        }
        .accessibilityHidden(true)
    }
}

struct QuestRibbon: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.9)
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 30)
            .frame(height: 27)
            .background(QuestRibbonShape().fill(Color(hex: 0x67C062)))
            .accessibilityLabel(text)
    }
}

/// A banner with swallowtail notches cut into both ends.
struct QuestRibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch = rect.height * 0.36
        let slant = rect.height * 0.12
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - slant, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + slant, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct QuestSeasonScene: View {
    var month: Int
    var locked: Bool
    var calm: Bool

    var body: some View {
        Canvas { context, size in
            QuestSeasonArt.paint(&context, size: size, month: month, locked: locked)
        }
        .accessibilityHidden(true)
    }
}

/// A close, dark hollow in the Gooby forest: birch, round canopy, pines, cropped by the card.
enum QuestSeasonArt {
    private struct Ink {
        var night: Color
        var leaf: Color
        var pine: Color
        var trunk: Color
        var birch: Color
        var mark: Color
        var ground: Color
        var glow: Color
    }

    static func paint(_ context: inout GraphicsContext, size: CGSize, month: Int, locked: Bool) {
        let ink = palette(month, locked: locked)
        let sx = size.width / QuestHeroMetric.width
        let sy = size.height / QuestHeroMetric.height
        context.scaleBy(x: sx, y: sy)
        let w = QuestHeroMetric.width
        let h = QuestHeroMetric.height
        func oval(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
        }

        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(ink.night))

        // Pines and canopy run off the top and the sides, so the card crops a near view.
        for (x, top, width) in [(-8.0, 18.0, 54.0), (40.0, 46.0, 36.0), (300.0, 8.0, 48.0), (348.0, 36.0, 40.0)] {
            var pine = Path()
            pine.move(to: CGPoint(x: x, y: top))
            pine.addLine(to: CGPoint(x: x + width / 2, y: 168))
            pine.addLine(to: CGPoint(x: x - width / 2, y: 168))
            pine.closeSubpath()
            context.fill(pine, with: .color(ink.pine))
        }
        context.fill(oval(-10, 20, 90, 48), with: .color(ink.leaf))
        context.fill(oval(70, -8, 78, 40), with: .color(ink.leaf))
        context.fill(oval(300, -6, 96, 46), with: .color(ink.leaf))
        context.fill(oval(390, 24, 80, 50), with: .color(ink.leaf))

        context.fill(Path(roundedRect: CGRect(x: -16, y: -20, width: 34, height: 210), cornerRadius: 12), with: .color(ink.trunk))
        var branch = Path()
        branch.move(to: CGPoint(x: 12, y: 54))
        branch.addQuadCurve(to: CGPoint(x: 108, y: 16), control: CGPoint(x: 48, y: 22))
        context.stroke(branch, with: .color(ink.trunk), style: StrokeStyle(lineWidth: 11, lineCap: .round))

        let birch = CGRect(x: 108, y: -16, width: 18, height: 176)
        context.fill(Path(roundedRect: birch, cornerRadius: 6), with: .color(ink.birch))
        for y in stride(from: 8.0, through: 150.0, by: 18.0) {
            let left = Int(y) % 36 == 8
            context.fill(
                Path(roundedRect: CGRect(x: left ? 108 : 116, y: y, width: 10, height: 2.4), cornerRadius: 1.2),
                with: .color(ink.mark)
            )
        }

        context.fill(Path(roundedRect: CGRect(x: 248, y: 18, width: 46, height: 168), cornerRadius: 14), with: .color(ink.trunk))
        context.fill(Path(roundedRect: CGRect(x: 268, y: 18, width: 18, height: 168), cornerRadius: 8), with: .color(ink.mark.opacity(0.55)))
        context.fill(oval(292, 8, 78, 36), with: .color(ink.leaf))
        context.fill(oval(210, 2, 46, 24), with: .color(ink.leaf))

        // Warm hollow behind the lock, kept dim so the title stays on night.
        context.fill(oval(206, 128, 70, 42), with: .color(ink.glow.opacity(locked ? 0.22 : 0.4)))
        context.fill(oval(206, 124, 28, 16), with: .color(ink.glow.opacity(locked ? 0.18 : 0.35)))

        var ground = Path()
        ground.move(to: CGPoint(x: 0, y: 168))
        ground.addQuadCurve(to: CGPoint(x: w, y: 160), control: CGPoint(x: 186, y: 142))
        ground.addLine(to: CGPoint(x: w, y: h))
        ground.addLine(to: CGPoint(x: 0, y: h))
        ground.closeSubpath()
        context.fill(ground, with: .color(ink.ground))
        context.fill(oval(186, 196, 130, 28), with: .color(ink.leaf.opacity(0.55)))
        context.fill(oval(28, 208, 34, 16), with: .color(ink.mark.opacity(0.7)))
        context.fill(oval(348, 204, 40, 18), with: .color(ink.mark.opacity(0.65)))

        context.fill(
            Path(CGRect(x: 0, y: 0, width: w, height: 78)),
            with: .linearGradient(
                Gradient(colors: [Color.black.opacity(locked ? 0.45 : 0.28), Color.black.opacity(0)]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: 78)
            )
        )
    }

    private static func palette(_ month: Int, locked: Bool) -> Ink {
        switch month {
        case 12, 1, 2:
            return Ink(
                night: Color(hex: locked ? 0x121820 : 0x1A2430),
                leaf: Color(hex: locked ? 0x1A2834 : 0x243848),
                pine: Color(hex: locked ? 0x142028 : 0x1C3040),
                trunk: Color(hex: locked ? 0x2A3038 : 0x3A4450),
                birch: Color(hex: locked ? 0x3A4048 : 0x5A646C),
                mark: Color(hex: 0x1A1E22),
                ground: Color(hex: locked ? 0x1C242C : 0x2A343C),
                glow: Color(hex: 0xC4B48A)
            )
        case 3, 4, 5:
            return Ink(
                night: Color(hex: locked ? 0x141C18 : 0x1C2820),
                leaf: Color(hex: locked ? 0x1C3024 : 0x2C4430),
                pine: Color(hex: locked ? 0x14281C : 0x1E3824),
                trunk: Color(hex: locked ? 0x3A2C22 : 0x4A3828),
                birch: Color(hex: locked ? 0x3A342C : 0x5A5044),
                mark: Color(hex: 0x241C16),
                ground: Color(hex: locked ? 0x1E281C : 0x2C3828),
                glow: Color(hex: 0xE0C080)
            )
        case 6, 7, 8:
            return Ink(
                night: Color(hex: locked ? 0x101C1A : 0x16302C),
                leaf: Color(hex: locked ? 0x1A3028 : 0x2A4434),
                pine: Color(hex: locked ? 0x143028 : 0x1E3830),
                trunk: Color(hex: locked ? 0x3A3024 : 0x5A4030),
                birch: Color(hex: locked ? 0x3A3830 : 0x5C584C),
                mark: Color(hex: 0x221C16),
                ground: Color(hex: locked ? 0x1A2820 : 0x243028),
                glow: Color(hex: 0xF0D090)
            )
        default:
            return Ink(
                night: Color(hex: locked ? 0x161412 : 0x221C18),
                leaf: Color(hex: locked ? 0x243028 : 0x324034),
                pine: Color(hex: locked ? 0x1A241C : 0x24382C),
                trunk: Color(hex: locked ? 0x3A2C24 : 0x4A382C),
                birch: Color(hex: locked ? 0x3A342C : 0x564C40),
                mark: Color(hex: 0x221C16),
                ground: Color(hex: locked ? 0x241C16 : 0x322820),
                glow: Color(hex: 0xE8A25A)
            )
        }
    }
}
