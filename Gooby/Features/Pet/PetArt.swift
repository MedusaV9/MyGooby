import SwiftUI

// Pet slice: drawn decorations for the profile, the notebooks and the world screens. All original
// shapes (no imported artwork), decorative and hidden from VoiceOver.

/// Brown clipboard clip that sits centered on the top edge of the profile card.
struct PetClip: View {
    var color: Color = Theme.Tab.pet.clip
    /// Color seen through the hole (the card behind the clip).
    var hole: Color = Theme.Tab.pet.paper

    var body: some View {
        ZStack {
            // Lower lip that presses on the paper.
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color)
                .overlay(Color.black.opacity(0.2).clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous)))
                .frame(width: 88, height: 12)
                .offset(y: 9)
            // Plate, narrower at the top.
            PetClipPlateShape()
                .fill(color)
                .frame(width: 70, height: 26)
                .offset(y: -2)
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: 40, height: 3.5)
                .offset(y: -11)
            Circle()
                .fill(hole)
                .frame(width: 11, height: 11)
                .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 1.5))
                .offset(y: -3)
        }
        .frame(width: 90, height: 32)
        .accessibilityHidden(true)
    }
}

/// Rounded trapezoid: the top edge is 70 % of the bottom edge.
struct PetClipPlateShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.15
        let r: CGFloat = min(8, rect.height / 3)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + inset + r, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset - r, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - inset + r * 0.3, y: rect.minY + r), control: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset - r * 0.3, y: rect.minY + r))
        path.addQuadCurve(to: CGPoint(x: rect.minX + inset + r, y: rect.minY), control: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

/// Faint round postmark with wavy cancellation lines (top-right watermark of the profile card).
struct PetPostmark: View {
    var color: Color = Theme.Tab.pet.watermark

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    PetWaveShape(waves: 3)
                        .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 58, height: 6)
                }
            }
            .offset(x: -26)
            Circle()
                .stroke(color, lineWidth: 2.5)
                .frame(width: 54, height: 54)
                .offset(x: 22)
            Circle()
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .frame(width: 42, height: 42)
                .offset(x: 22)
            PetBunnySilhouette(color: color)
                .frame(width: 18, height: 22)
                .offset(x: 22, y: 1)
        }
        .frame(width: 110, height: 60)
        .opacity(0.4)
        .accessibilityHidden(true)
    }
}

/// Bunny head silhouette (stamp motif).
struct PetBunnySilhouette: View {
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Capsule().fill(color).frame(width: w * 0.26, height: h * 0.5).rotationEffect(.degrees(-10)).offset(x: -w * 0.18, y: -h * 0.22)
                Capsule().fill(color).frame(width: w * 0.26, height: h * 0.5).rotationEffect(.degrees(10)).offset(x: w * 0.18, y: -h * 0.22)
                Ellipse().fill(color).frame(width: w, height: h * 0.58).offset(y: h * 0.2)
            }
            .frame(width: w, height: h)
        }
    }
}

/// Sine line across the rect.
struct PetWaveShape: Shape {
    var waves: Int = 3

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 48
        for index in 0...steps {
            let t = Double(index) / Double(steps)
            let x = rect.minX + rect.width * CGFloat(t)
            let y = rect.midY + CGFloat(sin(t * Double.pi * 2 * Double(waves))) * rect.height / 2
            if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }
}

struct PetStarShape: Shape {
    var points: Int = 5

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<(points * 2) {
            let angle = Double(index) * Double.pi / Double(points) - Double.pi / 2
            let length = index.isMultiple(of: 2) ? radius : radius * 0.45
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * length, y: center.y + CGFloat(sin(angle)) * length)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct PetTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Pointed leaf, tip at the top.
struct PetLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX + rect.width * 0.3, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX - rect.width * 0.3, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct PetLeaf: View {
    var color: Color
    var vein: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PetLeafShape().fill(color)
                if vein {
                    Capsule()
                        .fill(Color.black.opacity(0.13))
                        .frame(width: max(1.5, geo.size.width * 0.07), height: geo.size.height * 0.72)
                }
            }
        }
    }
}

/// Yellow scalloped sun badge with an orange check (streak card). With `spins` the scalloped
/// rim turns slowly (one turn in 24 s); it stays still with reduced motion.
struct PetSunBadge: View {
    var size: CGFloat = 58
    var spins: Bool = false
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    var body: some View {
        let turning = spins && !systemReduce && !appReduce
        ZStack {
            Group {
                if turning {
                    TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                        rim.rotationEffect(.degrees(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 24) * 15))
                    }
                } else {
                    rim
                }
            }
            Circle().fill(Color(hex: 0xFFDD6B)).frame(width: size * 0.62, height: size * 0.62)
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: size * 0.2, height: size * 0.12)
                .rotationEffect(.degrees(-30))
                .offset(x: -size * 0.14, y: -size * 0.17)
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.3, weight: .black))
                .foregroundStyle(Color(hex: 0xF0832A))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var rim: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(Color(hex: 0xFFC63A))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(y: -size * 0.35)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
            Circle().fill(Color(hex: 0xFFC63A)).frame(width: size * 0.8, height: size * 0.8)
        }
        .frame(width: size, height: size)
    }
}

/// Sun with short rays.
struct PetSun: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                Capsule()
                    .fill(Color(hex: 0xFFC63A))
                    .frame(width: size * 0.09, height: size * 0.2)
                    .offset(y: -size * 0.42)
                    .rotationEffect(.degrees(Double(index) * 36))
            }
            Circle().fill(Color(hex: 0xFFC63A)).frame(width: size * 0.62, height: size * 0.62)
            Circle().fill(Color(hex: 0xFFE07A)).frame(width: size * 0.42, height: size * 0.42).offset(x: -size * 0.04, y: -size * 0.04)
        }
        .frame(width: size, height: size)
    }
}

/// Five-petal flower.
struct PetFlower: View {
    var color: Color
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: size * 0.5, height: size * 0.5)
                    .offset(y: -size * 0.28)
                    .rotationEffect(.degrees(Double(index) * 72))
            }
            Circle().fill(Color(hex: 0xFFF3C9)).frame(width: size * 0.34, height: size * 0.34)
        }
        .frame(width: size, height: size)
    }
}

/// White-outlined sticker: Gooby on a sunny meadow with leaves and flowers (journey notebook).
struct PetSticker: View {
    var look: WornLook
    var stage: String

    var body: some View {
        ZStack {
            PetSun(size: 78).offset(x: 66, y: -56)
            PetLeaf(color: Color(hex: 0x5FA64A)).frame(width: 34, height: 60).rotationEffect(.degrees(-40)).offset(x: -82, y: 18)
            PetLeaf(color: Color(hex: 0x8CC66A)).frame(width: 28, height: 50).rotationEffect(.degrees(-10)).offset(x: -62, y: -6)
            PetLeaf(color: Color(hex: 0x4CA84A)).frame(width: 30, height: 54).rotationEffect(.degrees(42)).offset(x: 82, y: 26)
            Ellipse().fill(Color(hex: 0xA6D77F)).frame(width: 196, height: 58).offset(y: 64)
            Ellipse().fill(Color(hex: 0x8CC66A)).frame(width: 150, height: 34).offset(y: 74)
            PetFlower(color: Color(hex: 0xFF8FB1), size: 20).offset(x: -70, y: 58)
            PetFlower(color: Color(hex: 0xFFD45E), size: 18).offset(x: 74, y: 62)
            PetFlower(color: Color.white, size: 14).offset(x: -40, y: 78)
            GoobyCharacterView(look: look, stage: stage, animation: .idle, reduceMotion: true, companion: nil, adventuring: false)
                .frame(width: 140, height: 140)
                .offset(y: 8)
        }
        .frame(width: 230, height: 200)
        .compositingGroup()
        .shadow(color: .white, radius: 0, x: 3, y: 0)
        .shadow(color: .white, radius: 0, x: -3, y: 0)
        .shadow(color: .white, radius: 0, x: 0, y: 3)
        .shadow(color: .white, radius: 0, x: 0, y: -3)
        .shadow(color: Theme.brown.opacity(0.2), radius: 3, x: 0, y: 2)
        .accessibilityHidden(true)
    }
}

/// The sticker rocks gently on its bottom edge; still when `active` is false (reduced motion or
/// the pet tab hidden).
struct PetStickerMotion: ViewModifier {
    var active: Bool

    func body(content: Content) -> some View {
        if active {
            content.goobySway(1.6, duration: 2.6, anchor: .bottom)
        } else {
            content
        }
    }
}

/// Faint darker-beige doodles behind the sticker: ring, cherries, cat, leaves, stars.
struct PetDoodles: View {
    var color: Color = Theme.Tab.pet.watermark

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle().stroke(color, lineWidth: 3).frame(width: 34, height: 34).position(x: w * 0.1, y: h * 0.18)
                cherries.frame(width: 30, height: 32).position(x: w * 0.9, y: h * 0.78)
                cat.frame(width: 30, height: 34).position(x: w * 0.1, y: h * 0.78)
                PetLeaf(color: color, vein: false).frame(width: 14, height: 26).rotationEffect(.degrees(35)).position(x: w * 0.84, y: h * 0.14)
                PetLeaf(color: color, vein: false).frame(width: 12, height: 22).rotationEffect(.degrees(-30)).position(x: w * 0.2, y: h * 0.48)
                PetStarShape().fill(color).frame(width: 18, height: 18).position(x: w * 0.94, y: h * 0.42)
                PetStarShape().fill(color).frame(width: 12, height: 12).position(x: w * 0.3, y: h * 0.08)
                PetStarShape().fill(color).frame(width: 14, height: 14).position(x: w * 0.72, y: h * 0.94)
            }
        }
        .opacity(0.6)
        .accessibilityHidden(true)
    }

    private var cherries: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 9, y: 22))
                path.addQuadCurve(to: CGPoint(x: 18, y: 2), control: CGPoint(x: 8, y: 8))
                path.move(to: CGPoint(x: 22, y: 24))
                path.addQuadCurve(to: CGPoint(x: 18, y: 2), control: CGPoint(x: 22, y: 10))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            Circle().fill(color).frame(width: 12, height: 12).position(x: 8, y: 25)
            Circle().fill(color).frame(width: 12, height: 12).position(x: 22, y: 26)
        }
    }

    private var cat: some View {
        ZStack {
            PetTriangleShape().fill(color).frame(width: 9, height: 10).offset(x: -6, y: -11)
            PetTriangleShape().fill(color).frame(width: 9, height: 10).offset(x: 6, y: -11)
            Circle().fill(color).frame(width: 20, height: 18).offset(y: -3)
            Ellipse().fill(color).frame(width: 24, height: 16).offset(y: 10)
        }
    }
}

/// Small illustration of a place in its own colors: sky gradient, a sun, two hills and an emoji.
struct PetPlaceArt: View {
    var place: PlaceDef
    var size: CGFloat
    var radius: CGFloat = 16
    var showsGlyph: Bool = true

    var body: some View {
        let accent = Color(hexString: place.accent)
        ZStack {
            LinearGradient(colors: [Color(hexString: place.skyTop), Color(hexString: place.skyBottom)], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(Color.white.opacity(0.75))
                .frame(width: size * 0.2, height: size * 0.2)
                .offset(x: size * 0.26, y: -size * 0.27)
            Ellipse()
                .fill(accent.opacity(0.7))
                .frame(width: size * 1.3, height: size * 0.62)
                .offset(x: -size * 0.32, y: size * 0.4)
            Ellipse()
                .fill(accent)
                .frame(width: size * 1.2, height: size * 0.5)
                .offset(x: size * 0.34, y: size * 0.46)
            if showsGlyph {
                Text(verbatim: PetPlaceArt.glyph(place.id))
                    .font(.system(size: size * 0.36))
                    .offset(y: size * 0.04)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .accessibilityHidden(true)
    }

    static func glyph(_ id: String) -> String {
        switch id {
        case "meadow": return "🌼"
        case "garden": return "🌷"
        case "cherry": return "🌸"
        case "crystal": return "💎"
        case "beach": return "🐚"
        case "sugar": return "🍭"
        case "clouds": return "☁️"
        case "starwood": return "🌲"
        case "moon": return "🌙"
        case "snow": return "⛄"
        default: return "📍"
        }
    }
}

/// Little scene of a place for the pet tab's Places tiles (reference H "Locations"): sky in the
/// place's colors, a soft sun, a far hill, two round trees, a mushroom, flowers and a front hill.
struct PetPlaceThumb: View {
    var place: PlaceDef
    var size: CGFloat
    var radius: CGFloat = 16

    var body: some View {
        let accent = Color(hexString: place.accent)
        let s = size
        ZStack {
            LinearGradient(colors: [Color(hexString: place.skyTop), Color(hexString: place.skyBottom)], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(Color(hex: 0xFFF1B8))
                .frame(width: s * 0.22, height: s * 0.22)
                .offset(x: -s * 0.25, y: -s * 0.27)
            Ellipse()
                .fill(accent.opacity(0.6))
                .frame(width: s * 1.25, height: s * 0.62)
                .offset(x: s * 0.28, y: s * 0.26)
            tree(accent, canopy: s * 0.36)
                .offset(x: s * 0.2, y: -s * 0.02)
            tree(accent, canopy: s * 0.26)
                .offset(x: -s * 0.27, y: s * 0.08)
            Ellipse()
                .fill(accent)
                .overlay(Ellipse().fill(Color.white.opacity(0.18)).frame(width: s * 0.7, height: s * 0.12).offset(x: -s * 0.12, y: -s * 0.18))
                .frame(width: s * 1.45, height: s * 0.56)
                .offset(x: -s * 0.08, y: s * 0.44)
            mushroom(s * 0.17)
                .offset(x: -s * 0.05, y: s * 0.25)
            PetFlower(color: Color(hex: 0xFF8FB1), size: s * 0.13)
                .offset(x: s * 0.22, y: s * 0.3)
            PetFlower(color: Color(hex: 0xFFD45E), size: s * 0.1)
                .offset(x: s * 0.36, y: s * 0.38)
            PetFlower(color: .white, size: s * 0.09)
                .offset(x: -s * 0.33, y: s * 0.34)
        }
        .frame(width: s, height: s)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .accessibilityHidden(true)
    }

    private func tree(_ accent: Color, canopy: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0x8A5A3A))
                .frame(width: canopy * 0.18, height: canopy * 0.7)
                .offset(y: canopy * 0.55)
            Circle()
                .fill(accent)
                .overlay(Circle().fill(Color.black.opacity(0.22)))
                .frame(width: canopy, height: canopy)
            Circle()
                .fill(accent)
                .overlay(Circle().fill(Color.black.opacity(0.08)))
                .frame(width: canopy * 0.72, height: canopy * 0.72)
                .offset(x: -canopy * 0.1, y: -canopy * 0.08)
            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: canopy * 0.22, height: canopy * 0.22)
                .offset(x: -canopy * 0.2, y: -canopy * 0.2)
        }
    }

    private func mushroom(_ w: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
                .fill(Color(hex: 0xFFF3DD))
                .frame(width: w * 0.36, height: w * 0.5)
                .offset(y: w * 0.28)
            Ellipse()
                .fill(Color(hex: 0xE5534B))
                .frame(width: w, height: w * 0.62)
                .mask(Rectangle().frame(width: w, height: w * 0.36).offset(y: -w * 0.13))
                .offset(y: w * 0.06)
            Circle().fill(Color.white).frame(width: w * 0.16, height: w * 0.16).offset(x: -w * 0.2, y: -w * 0.08)
            Circle().fill(Color.white).frame(width: w * 0.12, height: w * 0.12).offset(x: w * 0.18, y: -w * 0.12)
        }
        .frame(width: w, height: w)
    }
}

/// Locked collection tile: light beige with a large light "?".
struct PetLockedTile: View {
    var size: CGFloat
    var fill: Color = Theme.Tab.pet.tileLocked
    var radius: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(fill)
            .frame(width: size, height: size)
            .overlay {
                Text(verbatim: "?")
                    .font(.system(size: size * 0.5, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .accessibilityHidden(true)
    }
}
