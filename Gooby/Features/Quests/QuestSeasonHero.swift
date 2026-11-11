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
        let title = event?.title.text(engine.languageCode) ?? window.eventID
        let kicker = QuestSeasonText.kicker(engine, window.starts)
        let ribbon = QuestSeasonText.ribbon(engine, window)
        let month = Calendar.current.component(.month, from: window.starts)
        let locked = !window.active
        ZStack {
            QuestSeasonScene(month: month, locked: locked, calm: calm)
            GeometryReader { geo in
                let w = geo.size.width / QuestHeroMetric.width
                let h = geo.size.height / QuestHeroMetric.height
                ForEach(QuestHeroMetric.guests.indices, id: \.self) { index in
                    let guest = QuestHeroMetric.guests[index]
                    QuestHeroGooby(animation: guest.animation, calm: true)
                        .frame(width: guest.size * h, height: guest.size * h)
                        .scaleEffect(x: guest.flip ? -1 : 1)
                        .position(x: guest.x * w, y: guest.y * h)
                }
                Rectangle()
                    .fill(Color.black.opacity(locked ? QuestHeroMetric.veil : 0))
                QuestHeroGooby(animation: locked ? .curious : .wave, calm: calm)
                    .frame(width: QuestHeroMetric.hero.size * h, height: QuestHeroMetric.hero.size * h)
                    .position(x: QuestHeroMetric.hero.x * w, y: QuestHeroMetric.hero.y * h)
                if locked {
                    QuestHeroLock()
                        .frame(width: 52 * h, height: 54 * h)
                        .position(x: QuestHeroMetric.lock.x * w, y: QuestHeroMetric.lock.y * h)
                }
            }
            .allowsHitTesting(false)
            VStack(spacing: 0) {
                Text(kicker)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .textCase(.uppercase)
                Text(title)
                    .font(.system(size: 19.5, weight: .black))
                    .italic()
                    .tracking(0.3)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(0.55), radius: 0, x: 0, y: 1.5)
                    .padding(.top, 5)
                Spacer(minLength: 0)
                QuestRibbon(text: ribbon)
                    .padding(.bottom, 25)
            }
            .padding(.top, 25)
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
}

/// Placement in the 372 × 228 point hero, measured from the Finch frame at 0.67 pt per pixel.
enum QuestHeroMetric {
    struct Spot {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var animation: GoobyAnimation = .idle
        var flip = false
    }

    static let width: CGFloat = 372
    static let height: CGFloat = 228
    static let hero = Spot(x: 152, y: 142, size: 72)
    static let lock = CGPoint(x: 206, y: 149)
    static let guests = [
        Spot(x: 74, y: 160, size: 112, animation: .wave),
        Spot(x: 332, y: 150, size: 136, animation: .sit, flip: true)
    ]
    static let veil = 0.7
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
            .background(QuestRibbonShape().fill(Color(hex: 0x52BE4E)))
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

/// The hollow drawn in the flat Gooby forest style; a locked season sits behind a dark veil.
enum QuestSeasonArt {
    private struct Ink {
        var sky: Color
        var hillBack: Color
        var hillFront: Color
        var leaves: Color
        var leavesLight: Color
        var pine: Color
        var ground: Color
    }

    static func paint(_ context: inout GraphicsContext, size: CGSize, month: Int, locked: Bool) {
        let ink = palette(month)
        let sx = size.width / QuestHeroMetric.width
        let sy = size.height / QuestHeroMetric.height
        context.scaleBy(x: sx, y: sy)
        let w = QuestHeroMetric.width
        let h = QuestHeroMetric.height
        func oval(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
        }

        context.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(ink.sky))
        context.fill(oval(300, 40, 16, 16), with: .color(Color(hex: 0xF6D27A)))

        var back = Path()
        back.move(to: CGPoint(x: 0, y: 150))
        back.addQuadCurve(to: CGPoint(x: 190, y: 128), control: CGPoint(x: 90, y: 104))
        back.addQuadCurve(to: CGPoint(x: w, y: 132), control: CGPoint(x: 290, y: 100))
        back.addLine(to: CGPoint(x: w, y: h))
        back.addLine(to: CGPoint(x: 0, y: h))
        back.closeSubpath()
        context.fill(back, with: .color(ink.hillBack))

        for (x, top, width) in [(250.0, 70.0, 34.0), (282.0, 92.0, 28.0)] {
            var pine = Path()
            pine.move(to: CGPoint(x: x, y: top))
            pine.addLine(to: CGPoint(x: x + width / 2, y: 150))
            pine.addLine(to: CGPoint(x: x - width / 2, y: 150))
            pine.closeSubpath()
            context.fill(pine, with: .color(ink.pine))
        }

        context.fill(Path(roundedRect: CGRect(x: 22, y: -10, width: 24, height: 190), cornerRadius: 8), with: .color(Color(hex: 0xB9814C)))
        var branch = Path()
        branch.move(to: CGPoint(x: 40, y: 64))
        branch.addQuadCurve(to: CGPoint(x: 120, y: 18), control: CGPoint(x: 70, y: 30))
        context.stroke(branch, with: .color(Color(hex: 0xB9814C)), style: StrokeStyle(lineWidth: 9, lineCap: .round))

        let birch = CGRect(x: 104, y: -10, width: 20, height: 168)
        context.fill(Path(roundedRect: birch, cornerRadius: 6), with: .color(Color(hex: 0xF3EADB)))
        for y in stride(from: 12.0, to: 150.0, by: 22.0) {
            let left = Int(y) % 44 == 12
            context.fill(
                Path(roundedRect: CGRect(x: left ? 104 : 112, y: y, width: 12, height: 3), cornerRadius: 1.5),
                with: .color(Color(hex: 0x5E5650))
            )
        }

        context.fill(Path(roundedRect: CGRect(x: 214, y: 34, width: 40, height: 140), cornerRadius: 10), with: .color(Color(hex: 0xA8743F)))
        context.fill(Path(roundedRect: CGRect(x: 236, y: 34, width: 18, height: 140), cornerRadius: 8), with: .color(Color(hex: 0x8E5F34)))
        context.fill(oval(250, 26, 74, 34), with: .color(ink.leaves))
        context.fill(oval(196, 12, 50, 26), with: .color(ink.leaves))
        context.fill(oval(330, 22, 56, 30), with: .color(ink.leaves))
        context.fill(oval(258, 12, 40, 14), with: .color(ink.leavesLight))
        context.fill(oval(30, 6, 64, 30), with: .color(ink.leaves))
        context.fill(oval(18, 0, 34, 14), with: .color(ink.leavesLight))

        var front = Path()
        front.move(to: CGPoint(x: 0, y: 178))
        front.addQuadCurve(to: CGPoint(x: w, y: 172), control: CGPoint(x: 186, y: 148))
        front.addLine(to: CGPoint(x: w, y: h))
        front.addLine(to: CGPoint(x: 0, y: h))
        front.closeSubpath()
        context.fill(front, with: .color(ink.hillFront))
        context.fill(oval(186, 196, 120, 34), with: .color(ink.ground))
        context.fill(oval(36, 206, 30, 18), with: .color(Color(hex: 0xC2B8B0)))
        context.fill(oval(352, 200, 34, 20), with: .color(Color(hex: 0xC2B8B0)))

        for (x, y, color) in [(70.0, 196.0, 0xE5583B), (300.0, 204.0, 0xF7A8C0), (318.0, 188.0, 0xF6CE5A)] as [(CGFloat, CGFloat, UInt32)] {
            context.fill(Path(CGRect(x: x - 0.8, y: y, width: 1.6, height: 9)), with: .color(Color(hex: 0x4E8A43)))
            context.fill(oval(x, y, 5, 5), with: .color(Color(hex: color)))
            context.fill(oval(x, y, 2, 2), with: .color(Color(hex: 0xFFE7A0)))
        }

        if !locked {
            context.fill(
                Path(CGRect(x: 0, y: 0, width: w, height: 90)),
                with: .linearGradient(
                    Gradient(colors: [Color.black.opacity(0.38), Color.black.opacity(0)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: 90)
                )
            )
        }
    }

    private static func palette(_ month: Int) -> Ink {
        switch month {
        case 12, 1, 2:
            return Ink(
                sky: Color(hex: 0x6E86C8), hillBack: Color(hex: 0xC9D8E6), hillFront: Color(hex: 0xE8F0F6),
                leaves: Color(hex: 0x5E8A6A), leavesLight: Color(hex: 0xF4F8FB), pine: Color(hex: 0x2F7A5C), ground: Color(hex: 0xD6E2EC)
            )
        case 3, 4, 5:
            return Ink(
                sky: Color(hex: 0x6A86C9), hillBack: Color(hex: 0x9CC772), hillFront: Color(hex: 0x6FA95C),
                leaves: Color(hex: 0x86AE3E), leavesLight: Color(hex: 0xB4C94A), pine: Color(hex: 0x2F8460), ground: Color(hex: 0x5E9A52)
            )
        case 6, 7, 8:
            return Ink(
                sky: Color(hex: 0x5F7FC4), hillBack: Color(hex: 0x8DBF63), hillFront: Color(hex: 0x66A457),
                leaves: Color(hex: 0x6F9F35), leavesLight: Color(hex: 0xA9C33F), pine: Color(hex: 0x2B7D5A), ground: Color(hex: 0x58944C)
            )
        default:
            return Ink(
                sky: Color(hex: 0x6C80B8), hillBack: Color(hex: 0xA9B66A), hillFront: Color(hex: 0x8C9A58),
                leaves: Color(hex: 0xC98A3A), leavesLight: Color(hex: 0xE2B04C), pine: Color(hex: 0x3F7A5A), ground: Color(hex: 0x7E8A4E)
            )
        }
    }
}
