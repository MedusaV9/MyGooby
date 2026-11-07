import SwiftUI
import UIKit

enum CarePalette {
    static let cream = Color(red: 1.0, green: 0.973, blue: 0.937)
    static let pink = Color(red: 1.0, green: 0.839, blue: 0.906)
    static let lavender = Color(red: 0.827, green: 0.761, blue: 1.0)
    static let mint = Color(red: 0.776, green: 0.937, blue: 0.863)
    static let yellow = Color(red: 1.0, green: 0.906, blue: 0.678)
    static let peach = Color(red: 1.0, green: 0.839, blue: 0.702)
    static let sky = Color(red: 0.784, green: 0.914, blue: 1.0)
    static let ink = Color(red: 0.239, green: 0.212, blue: 0.337)
    static let card = Color.white.opacity(0.74)

    static func color(hex: String) -> Color {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let number = UInt64(value, radix: 16) else { return pink }
        let red = Double((number >> 16) & 0xFF) / 255
        let green = Double((number >> 8) & 0xFF) / 255
        let blue = Double(number & 0xFF) / 255
        return Color(red: red, green: green, blue: blue)
    }
}

struct CareCard<Content: View>: View {
    var fill: Color = CarePalette.card
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(fill)
                    .shadow(color: CarePalette.ink.opacity(0.06), radius: 12, y: 6)
            )
    }
}

struct CarePrimaryButton: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(CarePalette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(CarePalette.pink))
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.22), value: configuration.isPressed)
    }
}

struct CareScreen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(CarePalette.cream.ignoresSafeArea())
    }
}

struct CareFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let rows = rows(for: subviews, width: width)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, width: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: item.size.width, height: item.size.height)
                )
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current: [Item] = []
        var x: CGFloat = 0
        var height: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if x + size.width > width, !current.isEmpty {
                rows.append(Row(items: current, height: height))
                current = []
                x = 0
                height = 0
            }
            current.append(Item(index: index, size: size))
            x += size.width + spacing
            height = max(height, size.height)
        }
        if !current.isEmpty {
            rows.append(Row(items: current, height: height))
        }
        return rows
    }

    private struct Item {
        var index: Int
        var size: CGSize
    }

    private struct Row {
        var items: [Item]
        var height: CGFloat
    }
}

struct CareHaptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func tap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}
