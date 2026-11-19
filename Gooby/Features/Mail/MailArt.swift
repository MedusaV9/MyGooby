import SwiftUI

enum MailPaint {
    static let skyTop = Color(hex: 0xB7E6FB)
    static let sky = Color(hex: 0x8ED4F8)
    static let sheet = Color(hex: 0xF3F4F6)
    static let title = Color(hex: 0x8B93A3)
    static let body = Color(hex: 0x6D7586)
    static let box = Color(hex: 0xE25C68)
    static let door = Color(hex: 0xD24E5C)
    static let slot = Color(hex: 0x6E2430)
    static let post = Color(hex: 0x8A5A3A)
    static let flag = Color(hex: 0xF2C14E)
    static let flagPin = Color(hex: 0xC9A227)
    static let wing = Color(hex: 0xF6C445)
    static let ink = Color(hex: 0x5C5348)
    static let cream = Color(hex: 0xFFF6EA)
    static let heart = Color(hex: 0xF7A8C4)
    static let paper = Color(hex: 0xFFF8EF)
    static let seal = Color(hex: 0xE989B0)
}

struct MailCloud: View {
    var body: some View {
        ZStack {
            Capsule().fill(.white.opacity(0.94)).frame(width: 92, height: 28)
            Circle().fill(.white.opacity(0.94)).frame(width: 36, height: 36).offset(x: -18, y: -8)
            Circle().fill(.white.opacity(0.94)).frame(width: 28, height: 28).offset(x: 16, y: -6)
        }
        .accessibilityHidden(true)
    }
}

struct MailboxGlyph: View {
    var waving: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(MailPaint.post)
                .frame(width: 16, height: 64)
                .offset(y: 52)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MailPaint.box)
                .frame(width: 120, height: 78)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(MailPaint.door)
                .frame(width: 78, height: 56)
                .offset(y: 6)
            Capsule()
                .fill(MailPaint.slot)
                .frame(width: 36, height: 7)
                .offset(y: -4)
            mailHeart
                .offset(x: 24, y: 14)
            mailPeek
                .offset(x: -26, y: 10)
            Capsule()
                .fill(MailPaint.flag)
                .frame(width: 8, height: 36)
                .rotationEffect(.degrees(waving ? -16 : 10), anchor: .bottom)
                .offset(x: 64, y: -30)
            Circle()
                .fill(MailPaint.flagPin)
                .frame(width: 10, height: 10)
                .offset(x: 64, y: -10)
            mailButterfly
                .offset(x: waving ? -58 : -70, y: waving ? -52 : -44)
        }
        .frame(width: 168, height: 150)
        .accessibilityHidden(true)
    }

    private var mailHeart: some View {
        ZStack {
            Circle().fill(MailPaint.heart).frame(width: 9, height: 9).offset(x: -3.5, y: -1)
            Circle().fill(MailPaint.heart).frame(width: 9, height: 9).offset(x: 3.5, y: -1)
            MailTriangle().fill(MailPaint.heart).frame(width: 12, height: 9).rotationEffect(.degrees(180)).offset(y: 4)
        }
        .frame(width: 16, height: 14)
    }

    private var mailPeek: some View {
        ZStack {
            Circle().fill(MailPaint.cream).frame(width: 18, height: 18)
            Capsule().fill(MailPaint.cream).frame(width: 5, height: 11).offset(x: -4, y: -10)
            Capsule().fill(MailPaint.cream).frame(width: 5, height: 11).offset(x: 4, y: -10)
            Circle().fill(MailPaint.ink).frame(width: 2.4, height: 2.4).offset(x: -3, y: 1)
            Circle().fill(MailPaint.ink).frame(width: 2.4, height: 2.4).offset(x: 3, y: 1)
        }
        .frame(width: 22, height: 28)
    }

    private var mailButterfly: some View {
        ZStack {
            Ellipse().fill(MailPaint.wing).frame(width: 16, height: 11).rotationEffect(.degrees(-28)).offset(x: -7)
            Ellipse().fill(MailPaint.wing).frame(width: 16, height: 11).rotationEffect(.degrees(28)).offset(x: 7)
            Capsule().fill(MailPaint.ink).frame(width: 3, height: 14)
            Circle().fill(MailPaint.ink).frame(width: 4, height: 4).offset(y: -8)
        }
        .frame(width: 32, height: 22)
    }
}

struct MailEnvelope: View {
    var unread: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(unread ? MailPaint.cream : Color(hex: 0xF4F1EA))
                .frame(width: 34, height: 24)
            MailTriangle()
                .fill(unread ? MailPaint.seal.opacity(0.85) : Color(hex: 0xE4D5CC))
                .frame(width: 34, height: 14)
                .offset(y: -5)
            Circle()
                .fill(unread ? MailPaint.seal : Color(hex: 0xC9C3B8))
                .frame(width: 8, height: 8)
                .offset(y: 2)
        }
        .frame(width: 36, height: 28)
        .accessibilityHidden(true)
    }
}

struct MailStamp: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(MailPaint.seal, style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
            Circle().fill(MailPaint.cream).frame(width: 22, height: 22).offset(y: 4)
            Capsule().fill(MailPaint.cream).frame(width: 6, height: 12).offset(x: -5, y: -10)
            Capsule().fill(MailPaint.cream).frame(width: 6, height: 12).offset(x: 5, y: -10)
            Circle().fill(MailPaint.ink).frame(width: 3, height: 3).offset(x: -4, y: 4)
            Circle().fill(MailPaint.ink).frame(width: 3, height: 3).offset(x: 4, y: 4)
        }
        .frame(width: 54, height: 64)
        .accessibilityHidden(true)
    }
}

struct MailTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
