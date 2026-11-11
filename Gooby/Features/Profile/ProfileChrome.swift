import SwiftUI

struct ProfileHeader: View {
    var title: String?
    var menuLabel: String
    var shareLabel: String
    var editLabel: String
    var shareText: String
    var onMenu: () -> Void
    var onEdit: () -> Void

    var body: some View {
        ZStack {
            HStack(spacing: 15) {
                Button(action: onMenu) {
                    MenuGlyph()
                        .frame(width: 40, height: 36, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(menuLabel)
                Spacer(minLength: 0)
                ShareLink(item: shareText) {
                    HeaderFace { ShareGlyph() }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(shareLabel)
                HeaderButton(label: editLabel, action: onEdit) { PencilGlyph() }
            }
            if let title {
                Text(title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(ProfilePalette.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 108)
            }
        }
        .frame(height: 40)
    }
}

struct HeaderButton<Glyph: View>: View {
    var label: String
    var action: () -> Void
    @ViewBuilder var glyph: () -> Glyph

    var body: some View {
        Button(action: action) {
            HeaderFace { glyph() }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct HeaderFace<Glyph: View>: View {
    @ViewBuilder var glyph: () -> Glyph

    var body: some View {
        glyph()
            .foregroundStyle(ProfilePalette.headerIcon)
            .frame(width: 40, height: 36)
            .background(ProfilePalette.headerFill, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .shadow(color: ProfilePalette.shadow, radius: 3, y: 1)
    }
}

struct MenuGlyph: View {
    var body: some View {
        ZStack {
            VStack(spacing: -1.8) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(Color.white).frame(width: 29, height: 7.5)
                }
            }
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(ProfilePalette.menuBars).frame(width: 24.2, height: 2.7)
                }
            }
        }
    }
}

struct ShareGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
                .frame(width: 13, height: 11)
                .offset(y: 3)
            Path { path in
                path.move(to: CGPoint(x: 9, y: 8))
                path.addLine(to: CGPoint(x: 9, y: 1))
                path.move(to: CGPoint(x: 5.5, y: 4))
                path.addLine(to: CGPoint(x: 9, y: 0.5))
                path.addLine(to: CGPoint(x: 12.5, y: 4))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
            .frame(width: 18, height: 18)
        }
        .frame(width: 18, height: 18)
    }
}

struct PencilGlyph: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 4, y: 14))
            path.addLine(to: CGPoint(x: 13.5, y: 4.5))
            path.move(to: CGPoint(x: 11.6, y: 3.2))
            path.addLine(to: CGPoint(x: 14.8, y: 6.4))
            path.move(to: CGPoint(x: 3.2, y: 15.2))
            path.addLine(to: CGPoint(x: 6.2, y: 14.2))
        }
        .stroke(style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
        .frame(width: 18, height: 18)
    }
}

struct CopyGlyph: View {
    var copied: Bool

    var body: some View {
        ZStack {
            if copied {
                Path { path in
                    path.move(to: CGPoint(x: 3, y: 9))
                    path.addLine(to: CGPoint(x: 7, y: 13))
                    path.addLine(to: CGPoint(x: 14, y: 4))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            } else {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(lineWidth: 1.5)
                    .frame(width: 9, height: 11)
                    .offset(x: 2, y: 2)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(lineWidth: 1.5)
                    .frame(width: 9, height: 11)
                    .offset(x: -2, y: -2)
            }
        }
        .frame(width: 16, height: 16)
    }
}

struct ChevronGlyph: View {
    var direction: ChevronDirection = .right

    enum ChevronDirection { case right, down }

    var body: some View {
        Path { path in
            switch direction {
            case .right:
                path.move(to: CGPoint(x: 3, y: 2))
                path.addLine(to: CGPoint(x: 8, y: 7))
                path.addLine(to: CGPoint(x: 3, y: 12))
            case .down:
                path.move(to: CGPoint(x: 2, y: 4))
                path.addLine(to: CGPoint(x: 7, y: 9))
                path.addLine(to: CGPoint(x: 12, y: 4))
            }
        }
        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: 12, height: 12)
    }
}

struct SpiralRings: View {
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            ring
            Spacer(minLength: 0)
            ring
            Spacer(minLength: 0)
            ring
            Spacer(minLength: 0)
            ring
            Spacer(minLength: 0)
            ring
            Spacer(minLength: 0)
        }
    }

    private var ring: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(ProfilePalette.ring)
            .frame(width: 11, height: 21)
            .shadow(color: Color(hex: 0x8A5A32).opacity(0.18), radius: 0, y: 1)
    }
}

struct NotebookShell<Content: View>: View {
    var binder: String?
    var binderAction: (() -> Void)?
    var inset: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            SpiralRings()
                .padding(.bottom, -10.6)
                .zIndex(2)
            ZStack(alignment: .bottom) {
                if let binder {
                    Button {
                        binderAction?()
                    } label: {
                        HStack(spacing: 6) {
                            Text(binder)
                            ChevronGlyph()
                        }
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: 0xFFF8EF))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(ProfilePalette.binder)
                    }
                    .buttonStyle(.plain)
                }
                content()
                    .padding(inset)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ProfilePalette.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.bottom, binder == nil ? 0 : 30)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: ProfilePalette.shadow, radius: 8, y: 3)
        }
    }
}

struct InfoDot: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().stroke(ProfilePalette.brownSoft, lineWidth: 1.4)
                Text("i")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(ProfilePalette.brownSoft)
            }
            .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }
}

struct SunCheck: View {
    var body: some View {
        ZStack {
            ProfileSun(points: 14, inner: 0.84)
                .fill(ProfilePalette.sun)
                .frame(width: 39, height: 39)
            Circle().fill(ProfilePalette.sunFace).frame(width: 26, height: 26)
            Path { path in
                path.move(to: CGPoint(x: 8, y: 13.5))
                path.addLine(to: CGPoint(x: 12, y: 17.5))
                path.addLine(to: CGPoint(x: 19, y: 9))
            }
            .stroke(ProfilePalette.sunCheck, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
            .frame(width: 26, height: 26)
        }
    }
}

struct ProfileSun: Shape {
    var points: Int
    var inner: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        let steps = points * 2
        for index in 0..<steps {
            let angle = (Double(index) / Double(steps)) * .pi * 2 - .pi / 2
            let length = index.isMultiple(of: 2) ? radius : radius * inner
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * length, y: center.y + CGFloat(sin(angle)) * length)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct ProfileLeafGlyph: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(ProfilePalette.leaf)
                .frame(width: 16, height: 22)
                .rotationEffect(.degrees(-28))
            Capsule()
                .fill(Color(hex: 0x2F7A38))
                .frame(width: 2, height: 14)
                .rotationEffect(.degrees(-28))
        }
        .frame(width: 22, height: 22)
    }
}

struct RibbonBanner: View {
    var title: String

    var body: some View {
        ZStack {
            RibbonTail().fill(Color.white).frame(width: 40, height: 30).offset(x: -86)
            RibbonTail().scale(x: -1, y: 1).fill(Color.white).frame(width: 40, height: 30).offset(x: 86)
            RibbonTail().fill(ProfilePalette.banner).frame(width: 32, height: 22).offset(x: -84)
            RibbonTail().scale(x: -1, y: 1).fill(ProfilePalette.banner).frame(width: 32, height: 22).offset(x: 84)
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white)
                .frame(width: 156, height: 40)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ProfilePalette.banner)
                .frame(width: 144, height: 30)
            Text(title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
        }
        .frame(height: 50)
        .accessibilityAddTraits(.isHeader)
    }
}

struct RibbonTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 4))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 4))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let midY = rect.midY
        let point = rect.height * 0.34
        let top = rect.minY + rect.height * 0.12
        let bottom = rect.maxY - rect.height * 0.12
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + point + 6, y: top))
        path.addLine(to: CGPoint(x: rect.maxX - point - 6, y: top))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - point, y: top + 7), control: CGPoint(x: rect.maxX - point, y: top))
        path.addLine(to: CGPoint(x: rect.maxX - point, y: midY - 7))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX - point, y: midY + 7))
        path.addLine(to: CGPoint(x: rect.maxX - point, y: bottom - 7))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - point - 6, y: bottom), control: CGPoint(x: rect.maxX - point, y: bottom))
        path.addLine(to: CGPoint(x: rect.minX + point + 6, y: bottom))
        path.addQuadCurve(to: CGPoint(x: rect.minX + point, y: bottom - 7), control: CGPoint(x: rect.minX + point, y: bottom))
        path.addLine(to: CGPoint(x: rect.minX + point, y: midY + 7))
        path.addLine(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: rect.minX + point, y: midY - 7))
        path.addLine(to: CGPoint(x: rect.minX + point, y: top + 7))
        path.addQuadCurve(to: CGPoint(x: rect.minX + point + 6, y: top), control: CGPoint(x: rect.minX + point, y: top))
        path.closeSubpath()
        return path
    }
}

struct Postmark: View {
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var pressed = false

    var body: some View {
        stamp
            .scaleEffect(pressed || reduce ? 1 : 1.4)
            .opacity(pressed || reduce ? 1 : 0)
            .rotationEffect(.degrees(pressed || reduce ? -8 : -22))
            .onAppear {
                if reduce {
                    pressed = true
                } else {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.52)) { pressed = true }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var stamp: some View {
        if ScreenArt.image("profile-stamp") != nil {
            ScreenArtView(name: "profile-stamp")
                .frame(width: 118, height: 100)
        } else {
            ZStack {
                Circle().stroke(ProfilePalette.postmark, lineWidth: 2.7).frame(width: 88, height: 88)
                Circle().stroke(ProfilePalette.postmark, lineWidth: 2.7).frame(width: 68, height: 68)
                PostmarkWaves()
                    .stroke(ProfilePalette.postmark, style: StrokeStyle(lineWidth: 2.7, lineCap: .round))
                    .frame(width: 96, height: 72)
                    .offset(x: 47)
            }
            .frame(width: 90, height: 90)
        }
    }
}

struct PostmarkWaves: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows: [CGFloat] = [0.083, 0.333, 0.583, 0.833]
        let wave = rect.width / 2
        for row in rows {
            let y = rect.minY + rect.height * row
            path.move(to: CGPoint(x: rect.minX, y: y))
            var x = rect.minX
            var up = true
            while x < rect.maxX {
                let next = x + wave
                path.addQuadCurve(to: CGPoint(x: next, y: y), control: CGPoint(x: x + wave / 2, y: y + (up ? -9 : 9)))
                x = next
                up.toggle()
            }
        }
        return path
    }
}

struct WavyMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - 6))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY - 6), control: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.midY - 16))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY - 6), control: CGPoint(x: rect.midX + rect.width * 0.25, y: rect.midY + 4))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + 6))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY + 6), control: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.midY - 4))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY + 6), control: CGPoint(x: rect.midX + rect.width * 0.25, y: rect.midY + 16))
        return path
    }
}

struct ProfileCardClip: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(ProfilePalette.clip)
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white.opacity(0.16))
                    .frame(height: 6)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            }
            .frame(width: 46, height: 25)
    }
}

struct CloseCross: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 3, y: 3))
            path.addLine(to: CGPoint(x: 15, y: 15))
            path.move(to: CGPoint(x: 15, y: 3))
            path.addLine(to: CGPoint(x: 3, y: 15))
        }
        .stroke(ProfilePalette.ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        .frame(width: 18, height: 18)
    }
}
