import SwiftUI

/// Top row of Home over the scene: hamburger (menu), sparks and streak, and the yellow mood face.
struct HomeTopBar: View {
    var engine: GoobyEngine
    var openMenu: () -> Void
    var openMood: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HamburgerButton(label: engine.t("kit.menu.open"), action: openMenu)
            Spacer(minLength: 4)
            HomeStatPill(icon: "✨", value: "\(engine.wallet.sparks)")
                .accessibilityLabel(engine.tf("adventure.sparks", engine.wallet.sparks))
            HomeStatPill(icon: "🔥", value: "\(engine.streak())")
                .accessibilityLabel(engine.tf("today.streak", engine.streak()))
            HomeMoodButton(level: engine.homeMoodToday()?.level, label: moodLabel, action: openMood)
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
    }

    private var moodLabel: String {
        if let level = engine.homeMoodToday()?.level {
            return engine.txf("home.mood.today", de: "Stimmung heute: %@. Neue Stimmung eintragen", en: "Mood today: %@. Log a new mood", engine.t("mood.level.\(level)"))
        }
        return engine.tx("home.mood.add", de: "Stimmung eintragen", en: "Log your mood")
    }
}

/// Translucent pill with an emoji and a number (sparks, streak).
struct HomeStatPill: View {
    var icon: String
    var value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(verbatim: icon).font(.system(size: 14))
            Text(verbatim: value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Color.black.opacity(0.2), in: Capsule())
        .accessibilityElement(children: .ignore)
    }
}

/// Yellow round smiley with a darker bottom edge. The mouth follows today's mood (1 sad ... 5 happy);
/// without an entry it smiles.
struct HomeMoodButton: View {
    var level: Int?
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HomeMoodFace(level: level ?? 4)
                .frame(width: 40, height: 40)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(HomeMoodPressStyle())
        .accessibilityLabel(label)
    }
}

private struct HomeMoodPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduce

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 2 : 0)
            .scaleEffect(!reduce && configuration.isPressed ? 0.94 : 1)
            .animation(reduce ? nil : .easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct HomeMoodFace: View {
    var level: Int

    var body: some View {
        Canvas { ctx, size in
            let side = min(size.width, size.height)
            let face = CGRect(x: 0, y: 0, width: side, height: side - 3)
            ctx.fill(Path(ellipseIn: face.offsetBy(dx: 0, dy: 3)), with: .color(Color(hex: 0xE9A92B)))
            ctx.fill(Path(ellipseIn: face), with: .color(Color(hex: 0xFFD34E)))
            ctx.fill(Path(ellipseIn: CGRect(x: side * 0.2, y: side * 0.1, width: side * 0.32, height: side * 0.16)), with: .color(Color.white.opacity(0.45)))
            let ink = Color(hex: 0x6B4420)
            let eyeY = side * 0.36
            ctx.fill(Path(ellipseIn: CGRect(x: side * 0.3, y: eyeY, width: side * 0.1, height: side * 0.15)), with: .color(ink))
            ctx.fill(Path(ellipseIn: CGRect(x: side * 0.6, y: eyeY, width: side * 0.1, height: side * 0.15)), with: .color(ink))
            let curve: CGFloat
            switch level {
            case ...1: curve = -0.16
            case 2: curve = -0.08
            case 3: curve = 0
            case 4: curve = 0.14
            default: curve = 0.22
            }
            let mouthY = side * (curve < 0 ? 0.7 : 0.62)
            var mouth = Path()
            mouth.move(to: CGPoint(x: side * 0.32, y: mouthY))
            mouth.addQuadCurve(to: CGPoint(x: side * 0.68, y: mouthY), control: CGPoint(x: side * 0.5, y: mouthY + side * curve))
            ctx.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: side * 0.07, lineCap: .round))
        }
        .accessibilityHidden(true)
    }
}

/// Own top row for the pushed and presented goal screens: back chevron, centered title and an
/// optional trailing control. Use with `.safeAreaInset(edge: .top)` and a hidden navigation bar.
struct HomeTopRow<Trailing: View>: View {
    var title: String
    var backLabel: String
    var back: () -> Void
    var trailing: Trailing

    init(title: String, backLabel: String, back: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.backLabel = backLabel
        self.back = back
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 64)
                .accessibilityAddTraits(.isHeader)
            HStack {
                BackChevronButton(label: backLabel, action: back)
                Spacer()
                trailing
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 52)
    }
}

extension HomeTopRow where Trailing == EmptyView {
    init(title: String, backLabel: String, back: @escaping () -> Void) {
        self.init(title: title, backLabel: backLabel, back: back) { EmptyView() }
    }
}
