import SwiftUI

/// Painted place, drawn in the adventure screen. No photo, no video, no bird.
struct AdventurePlaceArt: View {
    var place: PlaceDef

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                LinearGradient(
                    colors: [Color(hexString: place.skyTop), Color(hexString: place.skyBottom)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                ground(in: size)
                landmark(in: size)
            }
        }
        .accessibilityHidden(true)
    }

    private func ground(in size: CGSize) -> some View {
        Ellipse()
            .fill(Color(hexString: place.accent).opacity(0.55))
            .frame(width: size.width * 1.35, height: size.height * 0.42)
            .position(x: size.width * 0.5, y: size.height * 0.94)
    }

    @ViewBuilder private func landmark(in size: CGSize) -> some View {
        let scale = max(0.7, size.height / 92)
        Group {
            marks(in: size, scale: scale)
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder private func marks(in size: CGSize, scale: CGFloat) -> some View {
        switch place.id {
        case "garden":
            garden(in: size, scale: scale)
        case "cherry":
            cherry(in: size, scale: scale)
        case "beach":
            beach(in: size, scale: scale)
        case "crystal":
            crystal(in: size, scale: scale)
        case "clouds":
            clouds(in: size, scale: scale)
        case "sugar":
            sugar(in: size, scale: scale)
        case "starwood":
            starwood(in: size, scale: scale)
        case "moon":
            moon(in: size, scale: scale)
        case "snow":
            snow(in: size, scale: scale)
        default:
            meadow(in: size, scale: scale)
        }
    }

    private func meadow(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            sun(in: size, scale: scale)
            flower(Color.white, x: size.width * 0.28, y: size.height * 0.62, scale: scale)
            flower(Color(hexString: place.skyBottom), x: size.width * 0.5, y: size.height * 0.7, scale: scale * 1.15)
            flower(.white, x: size.width * 0.74, y: size.height * 0.64, scale: scale * 0.9)
        }
    }

    private func garden(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            sun(in: size, scale: scale)
            RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                .fill(Color(hexString: place.accent).opacity(0.95))
                .frame(width: size.width * 0.72, height: 14 * scale)
                .position(x: size.width * 0.5, y: size.height * 0.58)
            RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .frame(width: 22 * scale, height: 34 * scale)
                .position(x: size.width * 0.5, y: size.height * 0.68)
            Circle()
                .fill(Color(hexString: place.accent))
                .frame(width: 6 * scale, height: 6 * scale)
                .position(x: size.width * 0.54, y: size.height * 0.68)
        }
    }

    private func cherry(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            sun(in: size, scale: scale)
            Capsule()
                .fill(Color(hex: 0x8A5A44))
                .frame(width: 8 * scale, height: 28 * scale)
                .position(x: size.width * 0.5, y: size.height * 0.7)
            Circle().fill(Color(hex: 0xF4A8C4)).frame(width: 22 * scale, height: 22 * scale).position(x: size.width * 0.42, y: size.height * 0.52)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 18 * scale, height: 18 * scale).position(x: size.width * 0.58, y: size.height * 0.48)
            Circle().fill(Color(hex: 0xF7C4D8)).frame(width: 16 * scale, height: 16 * scale).position(x: size.width * 0.5, y: size.height * 0.58)
        }
    }

    private func beach(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            sun(in: size, scale: scale * 1.2)
            Capsule()
                .fill(Color.white.opacity(0.75))
                .frame(width: size.width * 0.7, height: 10 * scale)
                .position(x: size.width * 0.42, y: size.height * 0.62)
            Capsule()
                .fill(Color.white.opacity(0.55))
                .frame(width: size.width * 0.5, height: 8 * scale)
                .position(x: size.width * 0.62, y: size.height * 0.72)
        }
    }

    private func crystal(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            gem(size.width * 0.34, size.height * 0.58, 16 * scale, Color.white.opacity(0.9))
            gem(size.width * 0.52, size.height * 0.66, 22 * scale, Color(hexString: place.accent).opacity(0.85))
            gem(size.width * 0.7, size.height * 0.6, 14 * scale, Color.white.opacity(0.8))
        }
    }

    private func clouds(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            puff(size.width * 0.32, size.height * 0.42, 28 * scale)
            puff(size.width * 0.58, size.height * 0.36, 36 * scale)
            puff(size.width * 0.74, size.height * 0.5, 22 * scale)
        }
    }

    private func sugar(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            sweet(size.width * 0.3, size.height * 0.58, 16 * scale, Color.white)
            sweet(size.width * 0.5, size.height * 0.68, 20 * scale, Color(hex: 0xF7C6D8))
            sweet(size.width * 0.7, size.height * 0.6, 14 * scale, Color(hexString: place.skyTop))
        }
    }

    private func starwood(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            star(size.width * 0.22, size.height * 0.28, 10 * scale)
            star(size.width * 0.78, size.height * 0.22, 8 * scale)
            trunk(size.width * 0.4, size.height * 0.68, scale)
            trunk(size.width * 0.64, size.height * 0.72, scale * 0.8)
        }
    }

    private func moon(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 28 * scale, height: 28 * scale)
                .position(x: size.width * 0.72, y: size.height * 0.32)
            Circle()
                .fill(Color(hexString: place.skyTop))
                .frame(width: 22 * scale, height: 22 * scale)
                .position(x: size.width * 0.78, y: size.height * 0.28)
            star(size.width * 0.28, size.height * 0.3, 8 * scale)
            star(size.width * 0.42, size.height * 0.22, 6 * scale)
        }
    }

    private func snow(in size: CGSize, scale: CGFloat) -> some View {
        ZStack {
            Color.clear
            flake(size.width * 0.25, size.height * 0.28, scale)
            flake(size.width * 0.48, size.height * 0.22, scale * 0.8)
            flake(size.width * 0.7, size.height * 0.34, scale)
            flake(size.width * 0.36, size.height * 0.46, scale * 0.7)
        }
    }

    private func sun(in size: CGSize, scale: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.88))
            .frame(width: 22 * scale, height: 22 * scale)
            .position(x: size.width * 0.78, y: size.height * 0.26)
    }

    private func flower(_ petal: Color, x: CGFloat, y: CGFloat, scale: CGFloat) -> some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(petal)
                    .frame(width: 8 * scale, height: 8 * scale)
                    .offset(y: -5 * scale)
                    .rotationEffect(.degrees(Double(index) * 72))
            }
            Circle()
                .fill(Color(hexString: place.accent))
                .frame(width: 6 * scale, height: 6 * scale)
            Capsule()
                .fill(Color(hex: 0x3E8F62))
                .frame(width: 2 * scale, height: 12 * scale)
                .offset(y: 10 * scale)
        }
        .position(x: x, y: y)
    }

    private func gem(_ x: CGFloat, _ y: CGFloat, _ side: CGFloat, _ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(color)
            .frame(width: side, height: side)
            .rotationEffect(.degrees(45))
            .position(x: x, y: y)
    }

    private func puff(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat) -> some View {
        Capsule()
            .fill(Color.white.opacity(0.88))
            .frame(width: width, height: width * 0.62)
            .position(x: x, y: y)
    }

    private func sweet(_ x: CGFloat, _ y: CGFloat, _ side: CGFloat, _ color: Color) -> some View {
        Circle()
            .fill(color)
            .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: max(1, side * 0.08)))
            .frame(width: side, height: side)
            .position(x: x, y: y)
    }

    private func trunk(_ x: CGFloat, _ y: CGFloat, _ scale: CGFloat) -> some View {
        Capsule()
            .fill(Color(hex: 0x8A5A44))
            .frame(width: 7 * scale, height: 26 * scale)
            .position(x: x, y: y)
    }

    private func star(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) -> some View {
        AdventureStar()
            .fill(Color.white.opacity(0.92))
            .frame(width: radius * 2, height: radius * 2)
            .position(x: x, y: y)
    }

    private func flake(_ x: CGFloat, _ y: CGFloat, _ scale: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color.white.opacity(0.92)).frame(width: 2 * scale, height: 12 * scale)
            Capsule().frame(width: 2 * scale, height: 12 * scale).rotationEffect(.degrees(60))
            Capsule().frame(width: 2 * scale, height: 12 * scale).rotationEffect(.degrees(120))
        }
        .foregroundStyle(Color.white.opacity(0.92))
        .position(x: x, y: y)
    }
}

private struct AdventureStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<10 {
            let angle = -CGFloat.pi / 2 + CGFloat(index) * .pi / 5
            let radius = index.isMultiple(of: 2) ? outer : outer * 0.42
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
