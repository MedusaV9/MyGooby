import SwiftUI

enum Theme {
    static let cream = Color(hex: 0xFFF8EF)
    static let pink = Color(hex: 0xFFD6E7)
    static let lavender = Color(hex: 0xD3C2FF)
    static let mint = Color(hex: 0xC6EFDC)
    static let yellow = Color(hex: 0xFFE7AD)
    static let peach = Color(hex: 0xFFD6B3)
    static let sky = Color(hex: 0xC8E9FF)
    static let ink = Color(hex: 0x3D3656)
    static let rose = Color(hex: 0xE989B0)
    static let whiteCard = Color(hex: 0xFFFDFB)

    static let habitColors = ["FFD6E7", "D3C2FF", "C6EFDC", "FFE7AD", "FFD6B3", "C8E9FF", "F7C8D4", "E7D7FF"]
    static let habitIcons = [
        "drop.fill", "bed.double.fill", "sparkles", "figure.walk", "wind", "pencil",
        "book.fill", "heart.fill", "leaf.fill", "cup.and.saucer.fill", "moon.fill",
        "sun.max.fill", "house.fill", "brain.head.profile", "fork.knife", "music.note"
    ]

    static func card(_ hex: String) -> Color { Color(hexString: hex).opacity(0.55) }
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    init(hexString: String) {
        var value = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") { value.removeFirst() }
        self.init(hex: UInt32(value, radix: 16) ?? 0xFFD6E7)
    }
}

struct SoftCard<Content: View>: View {
    var fill: Color = Theme.whiteCard
    var content: Content

    init(fill: Color = Theme.whiteCard, @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Theme.ink.opacity(0.08), radius: 14, y: 7)
    }
}

struct GoobyButtonStyle: ButtonStyle {
    var fill: Color = Theme.ink
    var ink: Color = Theme.cream
    @Environment(\.accessibilityReduceMotion) private var reduce

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(fill, in: Capsule())
            .scaleEffect(!reduce && configuration.isPressed ? 0.96 : 1)
            .animation(reduce ? nil : .spring(duration: 0.22), value: configuration.isPressed)
            .goobyCue(.tap, opening: configuration.isPressed)
    }
}

struct TinyIconButton: View {
    var title: String
    var symbol: String
    var fill: Color
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ProgressRibbon: View {
    var value: Double
    var tint: Color = Theme.rose

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ink.opacity(0.08))
                Capsule()
                    .fill(tint)
                    .frame(width: max(8, geo.size.width * min(1, max(0, value))))
            }
        }
        .frame(height: 12)
        .accessibilityValue("\(Int(min(1, max(0, value)) * 100))%")
    }
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cream.ignoresSafeArea())
    }
}

extension View {
    func goobyScreen() -> some View { modifier(ScreenBackground()) }
}
