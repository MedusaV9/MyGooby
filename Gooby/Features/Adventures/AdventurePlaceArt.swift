import SwiftUI

struct AdventureSky: View {
    var place: AdventurePlaceDefinition
    var reducedMotion: Bool

    @State private var drift = false

    var body: some View {
        let sky = AdventurePalette.color(hex: place.skyHex)
        let ground = AdventurePalette.color(hex: place.groundHex)
        let accent = AdventurePalette.color(hex: place.accentHex)
        ZStack {
            LinearGradient(colors: [sky, ground.opacity(0.95)], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(accent.opacity(0.55))
                .frame(width: 180, height: 180)
                .offset(x: drift ? 40 : -24, y: -150)
            Circle()
                .fill(Color.white.opacity(place.motif == .star ? 0.16 : 0.38))
                .frame(width: 110, height: 110)
                .offset(x: drift ? -36 : 16, y: -60)
            Ellipse()
                .fill(ground)
                .frame(height: 180)
                .offset(y: 230)
            motifLayer(accent: accent)
                .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
        .onAppear(perform: start)
        .onChange(of: reducedMotion) { _, _ in start() }
    }

    @ViewBuilder
    private func motifLayer(accent: Color) -> some View {
        switch place.motif {
        case .flower:
            HStack(spacing: 28) {
                AdventurePlaceIcon(motif: .flower, tint: accent).frame(width: 28, height: 28)
                AdventurePlaceIcon(motif: .flower, tint: AdventurePalette.yellow).frame(width: 20, height: 20)
            }
            .offset(y: 70)
        case .petal:
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Ellipse()
                        .fill(accent.opacity(0.8))
                        .frame(width: 14, height: 10)
                        .rotationEffect(.degrees(Double(index) * 28))
                        .offset(x: CGFloat(index * 18 - 36), y: drift ? CGFloat(20 + index * 8) : CGFloat(40 + index * 6))
                }
            }
        case .sun:
            Circle()
                .fill(AdventurePalette.yellow)
                .frame(width: 54, height: 54)
                .offset(x: 110, y: -120)
        case .ripple:
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Ellipse()
                        .stroke(Color.white.opacity(0.7), lineWidth: 3)
                        .frame(width: CGFloat(40 + index * 28), height: CGFloat(16 + index * 8))
                }
            }
            .offset(y: 40)
        case .cloud:
            HStack(spacing: -10) {
                Circle().frame(width: 28, height: 28)
                Circle().frame(width: 40, height: 40)
                Circle().frame(width: 24, height: 24)
            }
            .foregroundStyle(Color.white.opacity(0.85))
            .offset(y: -20)
        case .swirl:
            Circle()
                .trim(from: 0.1, to: 0.75)
                .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 48, height: 48)
                .rotationEffect(.degrees(drift ? 20 : -10))
                .offset(y: 10)
        case .star:
            ZStack {
                AdventurePlaceIcon(motif: .star, tint: AdventurePalette.yellow)
                    .frame(width: 28, height: 28)
                    .offset(x: -80, y: -90)
                AdventurePlaceIcon(motif: .star, tint: Color.white.opacity(0.8))
                    .frame(width: 16, height: 16)
                    .offset(x: 90, y: -40)
            }
        case .moon:
            AdventurePlaceIcon(motif: .moon, tint: Color.white.opacity(0.92))
                .frame(width: 42, height: 42)
                .offset(x: 100, y: -120)
        case .gate, .snow:
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 70, height: 16)
                .offset(y: 80)
        }
    }

    private func start() {
        drift = false
        guard !reducedMotion else { return }
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
            drift = true
        }
    }
}

struct AdventurePlaceIcon: View {
    var motif: AdventureMotif
    var tint: Color

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            icon
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch motif {
        case .flower:
            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    Ellipse()
                        .fill(tint)
                        .frame(width: 10, height: 16)
                        .offset(y: -10)
                        .rotationEffect(.degrees(Double(index) * 72))
                }
                Circle().fill(AdventurePalette.yellow).frame(width: 10, height: 10)
            }
        case .gate:
            ZStack {
                Capsule().stroke(tint, lineWidth: 4)
                Rectangle().fill(tint).frame(width: 4, height: 8).offset(y: 12)
            }
        case .petal:
            ZStack {
                Ellipse().fill(tint).frame(width: 16, height: 22)
                Ellipse().fill(tint.opacity(0.7)).frame(width: 10, height: 14).offset(x: 8, y: 4)
            }
        case .sun:
            ZStack {
                Circle().fill(tint).frame(width: 14, height: 14)
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(tint)
                        .frame(width: 3, height: 8)
                        .offset(y: -14)
                        .rotationEffect(.degrees(Double(index) * 45))
                }
            }
        case .ripple:
            ZStack {
                Ellipse().stroke(tint, lineWidth: 3).frame(width: 28, height: 12)
                Ellipse().stroke(tint, lineWidth: 3).frame(width: 16, height: 7)
            }
        case .cloud:
            HStack(spacing: -6) {
                Circle().frame(width: 12, height: 12)
                Circle().frame(width: 18, height: 18)
                Circle().frame(width: 11, height: 11)
            }
            .foregroundStyle(tint)
        case .swirl:
            Circle()
                .trim(from: 0.05, to: 0.8)
                .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 22, height: 22)
        case .star:
            AdventureStar()
                .fill(tint)
                .frame(width: 22, height: 22)
        case .moon:
            ZStack {
                Circle().fill(tint)
                Circle().fill(AdventurePalette.lavender).offset(x: 6)
            }
            .frame(width: 20, height: 20)
            .mask(Circle().frame(width: 20, height: 20))
        case .snow:
            ZStack {
                Capsule().fill(tint).frame(width: 4, height: 22)
                Capsule().fill(tint).frame(width: 4, height: 22).rotationEffect(.degrees(60))
                Capsule().fill(tint).frame(width: 4, height: 22).rotationEffect(.degrees(120))
            }
        }
    }
}

struct AdventureStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<10 {
            let angle = (Double(index) * 36 - 90) * .pi / 180
            let length = index.isMultiple(of: 2) ? radius : radius * 0.42
            let point = CGPoint(x: center.x + CGFloat(cos(angle) * length), y: center.y + CGFloat(sin(angle) * length))
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct AdventureLockMark: View {
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(AdventurePalette.ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 10, height: 8)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AdventurePalette.ink)
                .frame(width: 12, height: 9)
        }
        .frame(width: 16, height: 18)
        .accessibilityHidden(true)
    }
}
