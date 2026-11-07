import SwiftUI

enum AdventurePalette {
    static let cream = color(0xFFF8EF)
    static let pink = color(0xFFD6E7)
    static let lavender = color(0xD3C2FF)
    static let mint = color(0xC6EFDC)
    static let yellow = color(0xFFE7AD)
    static let peach = color(0xFFD6B3)
    static let sky = color(0xC8E9FF)
    static let ink = color(0x3D3656)
    static let fur = color(0xFFF4E6)
    static let furShade = color(0xF4D2B4)
    static let cheek = color(0xFFB3C8)
    static let nose = color(0xFF8FAA)
    static let innerEar = color(0xFFC1D2)
    static let eye = color(0x241C18)
    static let tongue = color(0xFF9EB4)

    static func color(_ hex: UInt32, opacity: Double = 1) -> Color {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        return Color(red: red, green: green, blue: blue, opacity: opacity)
    }

    static func color(hex string: String) -> Color {
        var cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard let value = UInt32(cleaned, radix: 16) else {
            return cream
        }
        return color(value)
    }
}

struct AdventurePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct AdventureCard<Content: View>: View {
    var fill: Color = Color.white.opacity(0.78)
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: AdventurePalette.ink.opacity(0.08), radius: 16, y: 8)
    }
}

struct AdventurePrimaryButton: View {
    var title: String
    var fill: Color = AdventurePalette.ink
    var foreground: Color = Color.white
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(fill, in: Capsule())
        }
        .buttonStyle(AdventurePressStyle())
        .opacity(enabled ? 1 : 0.45)
        .disabled(!enabled)
    }
}

struct AdventureScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AdventurePalette.sky.opacity(0.55), AdventurePalette.cream, AdventurePalette.pink.opacity(0.35)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
