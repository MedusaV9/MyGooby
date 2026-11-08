import SwiftUI

// Drawn art of the menu (reference J): the widget banner illustration and the Activities tile
// icon. Original flat shapes, decorative and hidden from VoiceOver.

/// Two little widget cards leaning on each other: the front one shows Gooby's head over a
/// yellow progress strip, a sparkle twinkles beside them (still with reduced motion).
struct MenuWidgetArt: View {
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce
    @State private var twinkle = false

    var body: some View {
        let reduce = systemReduce || appReduce
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: 0xB9B0F0))
                .frame(width: 34, height: 34)
                .overlay(alignment: .bottom) {
                    Capsule().fill(Color.white.opacity(0.7)).frame(width: 18, height: 4).padding(.bottom, 6)
                }
                .rotationEffect(.degrees(12))
                .offset(x: 14, y: -10)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .overlay(alignment: .top) {
                    GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: 28)
                        .padding(.top, 3)
                }
                .overlay(alignment: .bottom) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0xEEEEEE))
                        Capsule().fill(Theme.progressFill).frame(width: 20)
                    }
                    .frame(width: 30, height: 5)
                    .padding(.bottom, 6)
                }
                .shadow(color: Color(hex: 0x4B3FA0).opacity(0.35), radius: 0, x: 0, y: 3)
                .rotationEffect(.degrees(-8))
                .offset(x: -6, y: 6)
            Image(systemName: "sparkle")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(Color(hex: 0xFFE07A))
                .scaleEffect(reduce ? 1 : (twinkle ? 1.15 : 0.75))
                .opacity(reduce ? 1 : (twinkle ? 1 : 0.6))
                .offset(x: -24, y: -20)
        }
        .frame(width: 62, height: 62)
        .onAppear {
            guard !reduce else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { twinkle = true }
        }
        .accessibilityHidden(true)
    }
}

/// Activities tile icon: a blue card with a yellow lightning bolt (reference J).
struct MenuActivitiesIcon: View {
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                .fill(Color(hex: 0x3E8EE8))
                .frame(width: size * 0.78, height: size * 0.94)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                        .fill(Color(hex: 0x62A8F2))
                        .frame(width: size * 0.78, height: size * 0.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
                .rotationEffect(.degrees(-6))
            MenuBoltShape()
                .fill(Color(hex: 0xFFD23F))
                .overlay(MenuBoltShape().stroke(Color(hex: 0xE89B1C), lineWidth: 1))
                .frame(width: size * 0.38, height: size * 0.6)
                .rotationEffect(.degrees(-6))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct MenuBoltShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.minX + w * 0.62, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.04, y: rect.minY + h * 0.58))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.46, y: rect.minY + h * 0.58))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.34, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.96, y: rect.minY + h * 0.4))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.54, y: rect.minY + h * 0.4))
        path.closeSubpath()
        return path
    }
}
