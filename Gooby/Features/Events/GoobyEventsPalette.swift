#if canImport(SwiftUI)
import SwiftUI

enum GoobyEventsPalette {
    static let cream = Color(red: 1.0, green: 0.973, blue: 0.937)
    static let blush = Color(red: 1.0, green: 0.839, blue: 0.906)
    static let lavender = Color(red: 0.827, green: 0.761, blue: 1.0)
    static let mint = Color(red: 0.776, green: 0.937, blue: 0.863)
    static let butter = Color(red: 1.0, green: 0.906, blue: 0.678)
    static let peach = Color(red: 1.0, green: 0.839, blue: 0.702)
    static let sky = Color(red: 0.784, green: 0.914, blue: 1.0)
    static let ink = Color(red: 0.239, green: 0.212, blue: 0.337)

    static func color(hex: String) -> Color {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") {
            text.removeFirst()
        }
        guard text.count == 6, let number = UInt64(text, radix: 16) else {
            return blush
        }
        let red = Double((number >> 16) & 0xFF) / 255
        let green = Double((number >> 8) & 0xFF) / 255
        let blue = Double(number & 0xFF) / 255
        return Color(red: red, green: green, blue: blue)
    }
}

struct GoobySquishButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.22), value: configuration.isPressed)
    }
}

struct GoobyCardModifier: ViewModifier {
    var fill: Color

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: GoobyEventsPalette.ink.opacity(0.08), radius: 16, y: 8)
    }
}

extension View {
    func goobyCard(fill: Color = Color.white.opacity(0.94)) -> some View {
        modifier(GoobyCardModifier(fill: fill))
    }
}

struct GoobyProgressBar: View {
    var value: Int
    var total: Int
    var tint: Color

    var body: some View {
        GeometryReader { proxy in
            let fraction = total > 0 ? CGFloat(min(max(value, 0), total)) / CGFloat(total) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(GoobyEventsPalette.ink.opacity(0.08))
                if fraction > 0 {
                    Capsule()
                        .fill(tint)
                        .frame(width: max(10, proxy.size.width * fraction))
                }
            }
        }
        .frame(height: 10)
        .accessibilityLabel("\(value) / \(max(total, 0))")
    }
}

struct GoobyPrimaryButton: View {
    var title: String
    var tint: Color = GoobyEventsPalette.ink
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(tint)
                .clipShape(Capsule())
        }
        .buttonStyle(GoobySquishButtonStyle())
    }
}
#endif
