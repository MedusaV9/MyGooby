import SwiftUI

extension Color {
    init(shopHex: UInt32) {
        let red = Double((shopHex >> 16) & 0xFF) / 255
        let green = Double((shopHex >> 8) & 0xFF) / 255
        let blue = Double(shopHex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

enum ShopTheme {
    static let cream = Color(shopHex: 0xFFF8EF)
    static let pink = Color(shopHex: 0xFFD6E7)
    static let lavender = Color(shopHex: 0xD3C2FF)
    static let mint = Color(shopHex: 0xC6EFDC)
    static let yellow = Color(shopHex: 0xFFE7AD)
    static let peach = Color(shopHex: 0xFFD6B3)
    static let sky = Color(shopHex: 0xC8E9FF)
    static let ink = Color(shopHex: 0x3D3656)
    static let card = Color(shopHex: 0xFFFFFF)
    static let fur = Color(shopHex: 0xFFF3E4)
    static let furShadow = Color(shopHex: 0xF3D7C4)
    static let innerEar = Color(shopHex: 0xFFB7C8)
    static let blush = Color(shopHex: 0xFFB3C7)
    static let nose = Color(shopHex: 0xFF8FAB)

    static func rarityColor(_ rarity: ShopRarity) -> Color {
        switch rarity {
        case .common:
            return Color(shopHex: 0x7DCEA0)
        case .uncommon:
            return Color(shopHex: 0x7EB6D9)
        case .rare:
            return Color(shopHex: 0xB9A6F2)
        case .epic:
            return Color(shopHex: 0xFFB088)
        case .legendary:
            return Color(shopHex: 0xF5C16C)
        }
    }

    static func titleFont() -> Font {
        .system(.title2, design: .rounded, weight: .bold)
    }

    static func bodyFont() -> Font {
        .system(.body, design: .rounded)
    }

    static func captionFont() -> Font {
        .system(.caption, design: .rounded, weight: .semibold)
    }
}

enum ShopPaint {
    static func fill(_ context: inout GraphicsContext, _ path: Path, _ hex: UInt32, _ alpha: Double = 1) {
        context.fill(path, with: .color(Color(shopHex: hex).opacity(alpha)))
    }

    static func fill(_ context: inout GraphicsContext, _ path: Path, _ color: Color) {
        context.fill(path, with: .color(color))
    }

    static func stroke(
        _ context: inout GraphicsContext,
        _ path: Path,
        _ hex: UInt32 = 0x3D3656,
        _ alpha: Double = 0.16,
        _ width: CGFloat = 1.2
    ) {
        context.stroke(path, with: .color(Color(shopHex: hex).opacity(alpha)), lineWidth: width)
    }

    static func mix(_ hex: UInt32, toward: UInt32, amount: Double) -> UInt32 {
        let t = min(1, max(0, amount))
        func channel(_ value: UInt32, _ shift: UInt32) -> Double {
            Double((value >> shift) & 0xFF)
        }
        let red = channel(hex, 16) * (1 - t) + channel(toward, 16) * t
        let green = channel(hex, 8) * (1 - t) + channel(toward, 8) * t
        let blue = channel(hex, 0) * (1 - t) + channel(toward, 0) * t
        return (UInt32(red) << 16) | (UInt32(green) << 8) | UInt32(blue)
    }

    static func star(in rect: CGRect, points: Int = 5) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.46
        var path = Path()
        let count = max(3, points) * 2
        for index in 0..<count {
            let angle = (Double(index) * .pi / Double(points)) - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    static func heart(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.28),
            control1: CGPoint(x: rect.minX - rect.width * 0.05, y: rect.midY),
            control2: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY),
            control2: CGPoint(x: rect.maxX + rect.width * 0.05, y: rect.midY)
        )
        path.closeSubpath()
        return path
    }
}

struct ShopBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(shopHex: 0xFFE9F3), ShopTheme.cream, Color(shopHex: 0xFFF8EF)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct ShopPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ShopPressLabel(configuration: configuration)
    }
}

private struct ShopPressLabel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let configuration: ButtonStyleConfiguration

    var body: some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct ShopBalancePill: View {
    var amount: Int
    var language: ShopLanguage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .foregroundStyle(ShopTheme.ink)
            Text("\(amount)")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(ShopTheme.ink)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .snappy, value: amount)
            Text(ShopL10n.text(.currencyName, language))
                .font(ShopTheme.captionFont())
                .foregroundStyle(ShopTheme.ink.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ShopTheme.yellow, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ShopL10n.sparks(amount, language))
    }
}

struct ShopChip: View {
    var title: String
    var systemImage: String?
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .lineLimit(1)
            }
            .font(ShopTheme.captionFont())
            .foregroundStyle(selected ? ShopTheme.cream : ShopTheme.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(selected ? ShopTheme.ink : ShopTheme.card, in: Capsule())
            .overlay {
                Capsule().stroke(ShopTheme.ink.opacity(selected ? 0 : 0.08), lineWidth: 1)
            }
        }
        .buttonStyle(ShopPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct ShopRarityPill: View {
    var rarity: ShopRarity
    var language: ShopLanguage

    var body: some View {
        Text(ShopL10n.rarity(rarity, language))
            .font(ShopTheme.captionFont())
            .foregroundStyle(ShopTheme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ShopTheme.rarityColor(rarity).opacity(0.85), in: Capsule())
    }
}

struct ShopBanner: View {
    var text: String

    var body: some View {
        Text(text)
            .font(ShopTheme.captionFont())
            .foregroundStyle(ShopTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(ShopTheme.peach, in: Capsule())
            .shadow(color: ShopTheme.ink.opacity(0.08), radius: 8, y: 4)
            .accessibilityAddTraits(.isStaticText)
    }
}

struct ShopSparkles: View {
    var tick: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var burst = 0

    var body: some View {
        ZStack {
            if burst == tick && tick > 0 && !reduceMotion {
                ForEach(0..<7, id: \.self) { index in
                    ShopSparkleBit(index: index)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: tick) { _, newValue in
            burst = newValue
        }
    }
}

private struct ShopSparkleBit: View {
    var index: Int
    @State private var fly = false

    var body: some View {
        let angle = Double(index) / 7 * Double.pi * 2
        Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "heart.fill")
            .font(.caption2)
            .foregroundStyle(index.isMultiple(of: 2) ? ShopTheme.yellow : ShopTheme.pink)
            .offset(
                x: fly ? CGFloat(cos(angle)) * 42 : 0,
                y: fly ? CGFloat(sin(angle)) * 32 : 0
            )
            .opacity(fly ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) {
                    fly = true
                }
            }
    }
}

struct ShopActionButton: View {
    var title: String
    var systemImage: String
    var filled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(ShopTheme.captionFont())
                .foregroundStyle(filled ? ShopTheme.cream : ShopTheme.ink)
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(filled ? ShopTheme.ink : ShopTheme.card, in: Capsule())
                .overlay {
                    Capsule().stroke(ShopTheme.ink.opacity(filled ? 0 : 0.08), lineWidth: 1)
                }
        }
        .buttonStyle(ShopPressStyle())
    }
}
