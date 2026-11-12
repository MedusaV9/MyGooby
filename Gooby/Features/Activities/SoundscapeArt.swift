import SwiftUI

struct SoundscapeGlyph: View {
    var id: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(plate)
            artwork
        }
        .frame(width: 46, height: 46)
        .accessibilityHidden(true)
    }

    private var plate: Color {
        switch id {
        case "home": return Color(hex: 0xD7ECFA)
        case "water": return Color(hex: 0xE5F6FF)
        case "forest": return Color(hex: 0xE7F6EA)
        case "rain": return Color(hex: 0xE4EEF8)
        case "travel": return Color(hex: 0xFFF4D8)
        case "boat": return Color(hex: 0xE5F3FF)
        case "shop": return Color(hex: 0xFDE8F1)
        case "thunder": return Color(hex: 0xECE8FA)
        case "wind": return Color(hex: 0xE7F4FA)
        case "land": return Color(hex: 0xFFF1E4)
        case "birds": return Color(hex: 0xE7F7FF)
        default: return Color(hex: 0xEEEAF8)
        }
    }

    @ViewBuilder private var artwork: some View {
        switch id {
        case "home": SoundHomeMark()
        case "water": SoundWaterMark()
        case "forest": SoundForestMark()
        case "rain": SoundRainMark()
        case "travel": SoundTravelMark()
        case "boat": SoundBoatMark()
        case "shop": SoundShopMark()
        case "thunder": SoundThunderMark()
        case "wind": SoundWindMark()
        case "land": SoundLandMark()
        case "birds": SoundBirdsMark()
        default: EmptyView()
        }
    }
}

private struct SoundHomeMark: View {
    var body: some View {
        ZStack {
            SoundPeak().fill(Color(hex: 0xE25B4A)).frame(width: 26, height: 12).offset(y: -9)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0xFFF8EE))
                .frame(width: 18, height: 13)
                .offset(y: 4)
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color(hex: 0x7EC8F0))
                .frame(width: 5, height: 5)
                .offset(x: -4, y: 2)
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color(hex: 0xE0A322))
                .frame(width: 4, height: 6)
                .offset(x: 4, y: 7)
        }
    }
}

private struct SoundWaterMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x8DCA7A)).frame(width: 16, height: 9).offset(x: -10, y: -2)
            Capsule().fill(Color(hex: 0x6BBF6A)).frame(width: 12, height: 8).offset(x: 10, y: -4)
            Capsule().fill(Color(hex: 0x2E9BE0)).frame(width: 30, height: 8).offset(y: 8)
            Capsule().fill(Color(hex: 0x7EC8F0)).frame(width: 18, height: 4).offset(y: 6)
        }
    }
}

private struct SoundForestMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x8A5A32)).frame(width: 4, height: 8).offset(y: 12)
            SoundPeak().fill(Color(hex: 0x2F8A45)).frame(width: 24, height: 12).offset(y: 5)
            SoundPeak().fill(Color(hex: 0x3EAE45)).frame(width: 18, height: 11).offset(y: -3)
            SoundPeak().fill(Color(hex: 0x67C36A)).frame(width: 11, height: 9).offset(y: -11)
        }
    }
}

private struct SoundRainMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color.white).frame(width: 22, height: 12).offset(y: -6)
            Circle().fill(Color.white).frame(width: 12, height: 12).offset(x: -6, y: -8)
            Circle().fill(Color.white).frame(width: 10, height: 10).offset(x: 6, y: -9)
            Capsule().fill(Color(hex: 0x5AA7E8)).frame(width: 2, height: 6).offset(x: -7, y: 8)
            Capsule().fill(Color(hex: 0x5AA7E8)).frame(width: 2, height: 7).offset(x: 0, y: 9)
            Capsule().fill(Color(hex: 0x5AA7E8)).frame(width: 2, height: 5).offset(x: 7, y: 7)
        }
    }
}

private struct SoundTravelMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xF0A020)).frame(width: 26, height: 8)
            SoundPeak().fill(Color(hex: 0xE08912)).frame(width: 10, height: 8).rotationEffect(.degrees(90)).offset(x: 8)
            Capsule().fill(Color(hex: 0xE08912)).frame(width: 14, height: 4).offset(y: 4)
            Circle().fill(Color(hex: 0xFFF8EE)).frame(width: 4, height: 4).offset(x: 2)
        }
    }
}

private struct SoundBoatMark: View {
    var body: some View {
        ZStack {
            SoundHull().fill(Color(hex: 0xE07A3D)).frame(width: 26, height: 8).offset(y: 8)
            Rectangle().fill(Color(hex: 0x8A5A32)).frame(width: 2, height: 16).offset(y: -2)
            SoundPeak().fill(Color.white).frame(width: 12, height: 12).offset(x: 6, y: -2)
            Capsule().fill(Color(hex: 0x7EC8F0)).frame(width: 28, height: 3).offset(y: 14)
        }
    }
}

private struct SoundShopMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0xFFF8EE))
                .frame(width: 22, height: 14)
                .offset(y: 4)
            HStack(spacing: 0) {
                Rectangle().fill(Color(hex: 0xE25B93))
                Rectangle().fill(Color.white)
                Rectangle().fill(Color(hex: 0xE25B93))
                Rectangle().fill(Color.white)
                Rectangle().fill(Color(hex: 0xE25B93))
            }
            .frame(width: 24, height: 7)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .offset(y: -8)
            RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x7EC8F0)).frame(width: 6, height: 6).offset(x: -5, y: 3)
            RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0xE0A322)).frame(width: 5, height: 8).offset(x: 5, y: 6)
        }
    }
}

private struct SoundThunderMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xD9D4F0)).frame(width: 24, height: 12).offset(y: -8)
            Circle().fill(Color(hex: 0xD9D4F0)).frame(width: 12, height: 12).offset(x: -7, y: -10)
            Circle().fill(Color(hex: 0xD9D4F0)).frame(width: 10, height: 10).offset(x: 7, y: -11)
            SoundBolt().fill(Color(hex: 0xF2C14E)).frame(width: 12, height: 16).offset(y: 6)
        }
    }
}

private struct SoundWindMark: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Capsule().fill(Color(hex: 0x7EB6D6)).frame(width: 22, height: 3)
            Capsule().fill(Color(hex: 0x5AA7E8)).frame(width: 16, height: 3)
            Capsule().fill(Color(hex: 0x7EB6D6)).frame(width: 24, height: 3)
        }
    }
}

private struct SoundLandMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xE07A3D)).frame(width: 7, height: 7).offset(x: -7, y: -6)
            Circle().fill(Color(hex: 0xE07A3D)).frame(width: 7, height: 7).offset(y: -8)
            Circle().fill(Color(hex: 0xE07A3D)).frame(width: 7, height: 7).offset(x: 7, y: -6)
            Circle().fill(Color(hex: 0xC46A32)).frame(width: 3, height: 3).offset(x: -7, y: -6)
            Circle().fill(Color(hex: 0xC46A32)).frame(width: 3, height: 3).offset(y: -8)
            Circle().fill(Color(hex: 0xC46A32)).frame(width: 3, height: 3).offset(x: 7, y: -6)
            Capsule().fill(Color(hex: 0xE07A3D)).frame(width: 16, height: 12).offset(y: 6)
        }
    }
}

private struct SoundBirdsMark: View {
    var body: some View {
        ZStack {
            SoundWings()
                .stroke(Color(hex: 0x5C6B7A), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 16, height: 8)
                .offset(x: -6, y: -2)
            SoundWings()
                .stroke(Color(hex: 0x5C6B7A), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 12, height: 6)
                .offset(x: 8, y: 6)
        }
    }
}

private struct SoundPeak: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct SoundHull: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        path.closeSubpath()
        return path
    }
}

private struct SoundBolt: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.58, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.width * 0.46, y: rect.height * 0.46))
        path.addLine(to: CGPoint(x: rect.width * 0.32, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.95, y: rect.height * 0.36))
        path.addLine(to: CGPoint(x: rect.width * 0.52, y: rect.height * 0.44))
        path.closeSubpath()
        return path
    }
}

private struct SoundWings: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.midY),
            control: CGPoint(x: rect.width * 0.25, y: rect.minY)
        )
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.width * 0.75, y: rect.minY)
        )
        return path
    }
}
