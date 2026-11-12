import SwiftUI

/// Heptagon of the seven stored personality values (`Personality.keys`).
/// The first vertex sits at the top and the rest follow that order, clockwise.
/// The filled area uses each stored value as its radius, so it reaches toward the strongest trait.
struct TraitRadar: View {
    var traits: [TraitSnap]
    var reduceMotion: Bool = false

    @State private var shown = false

    private static let floor = 0.16
    fileprivate static let badge: CGFloat = 30

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let side = min(rect.width, rect.height)
            let radius = min(side * 0.38, side / 2 - Self.badge / 2 - 4)
            let outerScales = Array(repeating: CGFloat(1), count: traits.count)
            let outer = Self.ring(center: center, radius: radius, scales: outerScales)
            let progress = (reduceMotion || shown) ? 1.0 : 0.0
            ZStack(alignment: .topLeading) {
                Self.polygon(outer).fill(Color(hex: 0xFBF6EC))
                Self.polygon(outer).stroke(Color(hex: 0xF0E2C8), lineWidth: 1.5)
                spokes(center: center, points: outer)
                TraitRadarFill(center: center, radius: radius, samples: traits.map(\.value), progress: progress)
                    .fill(Color(hex: 0xF6C98A).opacity(0.9))
                TraitRadarFill(center: center, radius: radius, samples: traits.map(\.value), progress: progress)
                    .stroke(Color(hex: 0xE7A85A), lineWidth: 1.6)
                Circle()
                    .fill(Color(hex: 0xE7A85A))
                    .frame(width: 5, height: 5)
                    .position(center)
                ForEach(Array(traits.enumerated()), id: \.element.id) { index, trait in
                    if index < outer.count {
                        TraitEmoji(symbol: Self.emoji(for: trait.id))
                            .position(outer[index])
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .animation(reduceMotion ? nil : .spring, value: shown)
        }
        .frame(height: 232)
        .onAppear {
            if reduceMotion {
                shown = true
            } else {
                withAnimation(.spring) { shown = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(traits.map { "\($0.name) \(Int(($0.value * 100).rounded()))" }.joined(separator: ", "))
    }

    /// One vertex per scale. Index 0 points up; later indexes continue clockwise.
    static func ring(center: CGPoint, radius: CGFloat, scales: [CGFloat]) -> [CGPoint] {
        let count = scales.count
        guard count >= 3 else { return [] }
        return (0..<count).map { index in
            let angle = (-Double.pi / 2) + (Double(index) / Double(count)) * (2 * Double.pi)
            let scale = scales[index]
            return CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius * scale,
                y: center.y + CGFloat(sin(angle)) * radius * scale
            )
        }
    }

    static func polygon(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }

    static func emoji(for id: String) -> String {
        switch id {
        case "curiosity": return "🤔"
        case "courage": return "🤠"
        case "kindness": return "😊"
        case "playfulness": return "😜"
        case "confidence": return "😎"
        case "calm": return "😌"
        case "empathy": return "🥰"
        default: return "✨"
        }
    }

    fileprivate static func grown(_ sample: Double, progress: Double) -> CGFloat {
        let target = min(1, max(floor, sample))
        let amount = max(0, progress)
        return CGFloat(min(1, floor + (target - floor) * amount))
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

/// Filled personality area. `progress` springs from 0 to 1 when the chart appears.
private struct TraitRadarFill: Shape {
    var center: CGPoint
    var radius: CGFloat
    var samples: [Double]
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let scales = samples.map { TraitRadar.grown($0, progress: progress) }
        return TraitRadar.polygon(TraitRadar.ring(center: center, radius: radius, scales: scales))
    }
}

private struct TraitEmoji: View {
    var symbol: String

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF8E7C0))
            Circle().stroke(Color(hex: 0xE4C98A), lineWidth: 1)
            Text(symbol)
                .font(.system(size: 16))
        }
        .frame(width: TraitRadar.badge, height: TraitRadar.badge)
        .accessibilityHidden(true)
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
            item(EarGlyph(), span, "\(spanName) \(span)")
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

struct EarGlyph: View {
    var body: some View {
        HStack(spacing: 2) {
            Capsule().frame(width: 4.5, height: 12)
            Capsule().frame(width: 4.5, height: 12)
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
