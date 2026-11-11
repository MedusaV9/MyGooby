import SwiftUI

struct TraitHexagon: View {
    var traits: [TraitSnap]

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = side * 0.34
            let outer = ring(center: center, radius: radius, values: nil)
            let plot = ring(center: center, radius: radius, values: traits.map(\.value))
            ZStack {
                hexagon(outer).fill(Color(hex: 0xFBF6EC))
                hexagon(outer).stroke(Color(hex: 0xF0E2C8), lineWidth: 1.5)
                spokes(center: center, points: outer)
                hexagon(plot)
                    .fill(Color(hex: 0xF6C98A).opacity(0.9))
                hexagon(plot)
                    .stroke(Color(hex: 0xE7A85A), lineWidth: 1.6)
                Circle()
                    .fill(Color(hex: 0xE7A85A))
                    .frame(width: 5, height: 5)
                    .position(center)
                ForEach(Array(outer.enumerated()), id: \.offset) { index, point in
                    TraitFace(index: index)
                        .position(point)
                }
            }
        }
        .frame(height: 210)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(traits.map { "\($0.name) \(Int(($0.value * 100).rounded()))" }.joined(separator: ", "))
    }

    private func ring(center: CGPoint, radius: CGFloat, values: [Double]?) -> [CGPoint] {
        (0..<6).map { index in
            let angle = (-Double.pi / 2) + (Double(index) * Double.pi / 3)
            let scale: CGFloat
            if let values, index < values.count {
                scale = CGFloat(min(1, max(0.16, values[index])))
            } else {
                scale = 1
            }
            return CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * scale,
                y: center.y + CGFloat(sin(angle)) * radius * scale
            )
        }
    }

    private func hexagon(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }

    private func spokes(center: CGPoint, points: [CGPoint]) -> some View {
        Path { path in
            for point in points {
                path.move(to: center)
                path.addLine(to: point)
            }
        }
        .stroke(Color(hex: 0xE7D7BC), lineWidth: 1)
    }
}

struct TraitFace: View {
    var index: Int

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF8E7C0))
            Circle().stroke(Color(hex: 0xE4C98A), lineWidth: 1)
            eyes
            mark
        }
        .frame(width: 28, height: 28)
    }

    private var eyes: some View {
        HStack(spacing: 5) {
            Circle().fill(Color(hex: 0x5C4A32)).frame(width: 2.6, height: 2.6)
            Circle().fill(Color(hex: 0x5C4A32)).frame(width: 2.6, height: 2.6)
        }
        .offset(y: -2)
    }

    @ViewBuilder private var mark: some View {
        switch index % 6 {
        case 0:
            Capsule().fill(Color(hex: 0x5C4A32)).frame(width: 8, height: 1.4).offset(y: 6)
        case 1:
            Capsule().fill(Color(hex: 0x3A342C)).frame(width: 16, height: 4).offset(y: -1)
        case 2:
            Circle().fill(Color(hex: 0xE07A8A)).frame(width: 5, height: 5).offset(y: 6)
        case 3:
            Capsule().fill(Color(hex: 0xC9956A)).frame(width: 14, height: 3).offset(y: -9)
        case 4:
            Capsule().fill(Color(hex: 0x5C4A32)).frame(width: 7, height: 1.4).offset(y: 6)
        default:
            Circle().stroke(Color(hex: 0x5C4A32), lineWidth: 1).frame(width: 7, height: 7).offset(x: 8, y: -1)
        }
    }
}

struct PassportMeasures: View {
    var weight: String
    var height: String
    var span: String
    var weightName: String
    var heightName: String
    var spanName: String

    var body: some View {
        HStack(spacing: 8) {
            item(WeightGlyph(), weight, "\(weightName) \(weight)")
            Spacer(minLength: 4)
            item(RulerGlyph(), height, "\(heightName) \(height)")
            Spacer(minLength: 4)
            item(WingGlyph(), span, "\(spanName) \(span)")
        }
        .padding(.top, 4)
    }

    private func item(_ icon: some View, _ text: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            icon
                .frame(width: 16, height: 16)
                .foregroundStyle(ProfilePalette.brownSoft)
            Text(text)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

struct WeightGlyph: View {
    var body: some View {
        ZStack {
            Capsule().frame(width: 12, height: 1.6).offset(y: -4)
            Capsule().frame(width: 1.4, height: 6)
            Circle().frame(width: 4, height: 4).offset(x: -5, y: 3)
            Circle().frame(width: 4, height: 4).offset(x: 5, y: 3)
        }
    }
}

struct RulerGlyph: View {
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1).frame(width: 4, height: 14)
            VStack(alignment: .leading, spacing: 2) {
                Capsule().frame(width: 7, height: 1.2)
                Capsule().frame(width: 5, height: 1.2)
                Capsule().frame(width: 7, height: 1.2)
            }
            .offset(x: 3)
        }
    }
}

struct WingGlyph: View {
    var body: some View {
        HStack(spacing: 1) {
            Ellipse().frame(width: 7, height: 5).rotationEffect(.degrees(-24))
            Ellipse().frame(width: 7, height: 5).rotationEffect(.degrees(24))
        }
    }
}

struct ProfileHeart: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xE07A8A)).frame(width: 7, height: 7).offset(x: -2.5, y: -1.5)
            Circle().fill(Color(hex: 0xE07A8A)).frame(width: 7, height: 7).offset(x: 2.5, y: -1.5)
            ProfileTriangle()
                .fill(Color(hex: 0xE07A8A))
                .rotationEffect(.degrees(180))
                .frame(width: 11, height: 8)
                .offset(y: 3)
        }
        .frame(width: 16, height: 14)
        .accessibilityHidden(true)
    }
}
