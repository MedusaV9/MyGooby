import SwiftUI

enum OnboardingPalette {
    static let green = Color(hex: 0x3DCC62)
    static let greenDeep = Color(hex: 0x2EBE54)
    static let blue = Color(hex: 0x3EC6F0)
    static let ink = Color(hex: 0x1C1C1E)
    static let subtitle = Color(hex: 0x8A8A8E)
    static let line = Color(hex: 0xE6E6EB)
    static let fill = Color(hex: 0xF4F4F6)
    static let disabled = Color(hex: 0xE8E8ED)
    static let disabledInk = Color(hex: 0xB0B0B8)
    static let paper = Color(hex: 0xFFF4D2)
}

struct OnboardingPill: View {
    var title: String
    var enabled: Bool = true
    var fill: Color = OnboardingPalette.green
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(enabled ? Color.white : OnboardingPalette.disabledInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(enabled ? fill : OnboardingPalette.disabled, in: Capsule())
        }
        .buttonStyle(OnboardingPress())
        .disabled(!enabled)
        .opacity(1)
    }
}

struct OnboardingGrayPill: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(OnboardingPalette.subtitle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(OnboardingPalette.fill, in: Capsule())
        }
        .buttonStyle(OnboardingPress())
    }
}

struct OnboardingPress: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduce

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduce && configuration.isPressed ? 0.98 : 1)
            .animation(reduce ? nil : .spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct OnboardingBack: View {
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OnboardingPalette.ink)
                .frame(width: 36, height: 36)
                .background(OnboardingPalette.fill, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct OnboardingBunny: View {
    var fur: String
    var animation: GoobyAnimation
    var reduceMotion: Bool
    var height: CGFloat = 180
    var badge: String?
    var badgeAbove: Bool = false

    var body: some View {
        ZStack {
            GoobyCharacterView(
                look: WornLook(fur: fur),
                stage: "baby",
                animation: reduceMotion ? .idle : animation,
                reduceMotion: reduceMotion,
                companion: nil
            )
            if let badge {
                Image(systemName: badge)
                    .font(.system(size: badgeAbove ? 18 : 20, weight: .bold))
                    .foregroundStyle(OnboardingPalette.ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white, in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                    .offset(x: badgeAbove ? 0 : 62, y: badgeAbove ? -height * 0.38 : -28)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }
}

struct OnboardingBubble: View {
    var text: String
    var trailing: Bool = false
    var fill: Color = OnboardingPalette.fill

    var body: some View {
        HStack {
            if trailing { Spacer(minLength: 48) }
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(OnboardingPalette.ink)
                .multilineTextAlignment(trailing ? .trailing : .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            if !trailing { Spacer(minLength: 48) }
        }
    }
}

struct OnboardingScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
    }
}

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.58),
            control1: CGPoint(x: w * 0.86, y: 0),
            control2: CGPoint(x: w, y: h * 0.26)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w, y: h * 0.9),
            control2: CGPoint(x: w * 0.78, y: h)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.58),
            control1: CGPoint(x: w * 0.22, y: h),
            control2: CGPoint(x: 0, y: h * 0.9)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: 0, y: h * 0.26),
            control2: CGPoint(x: w * 0.14, y: 0)
        )
        return path
    }
}

struct CrackMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.62, y: h * 0.06))
        path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.2))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.32))
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.48))
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.64))
        return path
    }
}

struct EggGlyph: View {
    var egg: OnboardingEgg
    var crack: CGFloat = 0
    var width: CGFloat = 72

    var body: some View {
        let height = width * 1.28
        ZStack {
            EggShape().fill(Color(hex: egg.shell))
            Ellipse()
                .fill(Color(hex: egg.spots))
                .frame(width: width * 0.38, height: width * 0.28)
                .offset(x: -width * 0.16, y: -height * 0.16)
            Ellipse()
                .fill(Color(hex: egg.spots))
                .frame(width: width * 0.28, height: width * 0.22)
                .offset(x: width * 0.18, y: height * 0.02)
            Ellipse()
                .fill(Color(hex: egg.spots))
                .frame(width: width * 0.18, height: width * 0.16)
                .offset(x: -width * 0.06, y: height * 0.22)
            CrackMark()
                .trim(from: 0, to: crack)
                .stroke(Color(hex: 0x2C3140), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .padding(width * 0.12)
        }
        .frame(width: width, height: height)
        .mask(EggShape())
    }
}

struct HatchRays: View {
    var reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            Color.clear.frame(width: 280, height: 280)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let turn = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 18) / 18
                ZStack {
                    ForEach(0..<12, id: \.self) { index in
                        Capsule()
                            .fill(OnboardingPalette.green.opacity(0.16))
                            .frame(width: 16, height: 240)
                            .offset(y: -20)
                            .rotationEffect(.degrees(Double(index) / 12.0 * 360))
                    }
                }
                .rotationEffect(.degrees(turn * 360))
                .frame(width: 300, height: 300)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }
}

struct OnboardingChoiceRow: View {
    var title: String
    var symbol: String?
    var tint: UInt32?
    var selected: Bool
    var centered: Bool
    var multi: Bool
    var reduceMotion: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: tint ?? 0x3DCC62))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: tint ?? 0x3DCC62).opacity(0.16), in: Circle())
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(centered && symbol == nil ? .center : .leading)
                    .frame(maxWidth: .infinity, alignment: centered && symbol == nil ? .center : .leading)
                marker
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? OnboardingPalette.green : OnboardingPalette.line, lineWidth: selected ? 2 : 1)
            }
        }
        .buttonStyle(OnboardingPress())
        .accessibilityAddTraits(selected ? .isSelected : [])
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: selected)
    }

    @ViewBuilder
    private var marker: some View {
        if multi {
            Image(systemName: selected ? "checkmark" : "plus")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(selected ? Color.white : OnboardingPalette.subtitle)
                .frame(width: 26, height: 26)
                .background(selected ? OnboardingPalette.green : OnboardingPalette.fill, in: Circle())
        } else if selected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(OnboardingPalette.green)
        }
    }
}

struct SectionBar: View {
    var current: Int
    var count: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                ZStack {
                    Capsule()
                        .fill(index <= current ? OnboardingPalette.green : OnboardingPalette.line)
                    if index < current {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 14)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(min(current + 1, count)) / \(count)")
    }
}
