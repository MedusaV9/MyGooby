import SwiftUI

enum InsightsPalette {
    static let canvas = Color(hex: 0xF4F5F7)
    static let ink = Color(hex: 0x1C1C1E)
    static let sub = Color(hex: 0x8E8E93)
    static let positive = Color(hex: 0x34C759)
    static let neutral = Color(hex: 0xC7C7CC)
    static let negative = Color(hex: 0xFF3B5C)
    static let emptyDot = Color(hex: 0xE5E5EA)
    static let tagFill = Color(hex: 0xE7E7EC)
    static let tagInk = Color(hex: 0xB0B0B6)
    static let history = Color(hex: 0x37C667)
    static let letter = Color(hex: 0x3CB4F5)
    static let track = Color(hex: 0xECECF1)
}

enum InsightsFormat {
    static func monthTitle(_ date: Date, language: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        var name = formatter.string(from: date)
        if name.hasSuffix(".") { name.removeLast() }
        let year = calendar.component(.year, from: date) % 100
        return "\(name) '\(String(format: "%02d", year))"
    }

    static func dayMonth(_ date: Date, language: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

    static func medium(_ date: Date, language: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct InsightsCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}

struct InsightsRise: ViewModifier {
    var index: Int
    var still: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .offset(y: still || shown ? 0 : 14)
            .onAppear {
                guard !still, !shown else { return }
                withAnimation(.spring(response: 0.48, dampingFraction: 0.86).delay(0.045 * Double(index))) {
                    shown = true
                }
            }
    }
}

struct InsightsScreen<Content: View>: View {
    var title: String
    var back: String
    var trailingSymbol: String? = nil
    var trailingLabel: String = ""
    var trailingAction: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                bar
                content()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(InsightsPalette.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
    }

    private var bar: some View {
        ZStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(InsightsPalette.ink)
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(InsightsPalette.ink.opacity(0.72))
                        .frame(width: 44, height: 36, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(back)
                Spacer()
                if let trailingSymbol, let trailingAction {
                    Button(action: trailingAction) {
                        Image(systemName: trailingSymbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xE39A1A))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(trailingLabel)
                }
            }
        }
        .padding(.top, 8)
    }
}

struct InsightsWindowMenu: View {
    var engine: GoobyEngine
    @Binding var window: InsightsWindow

    var body: some View {
        Menu {
            ForEach(InsightsWindow.allCases, id: \.rawValue) { item in
                Button(engine.t("insights.window.\(item.rawValue)")) { window = item }
            }
        } label: {
            HStack(spacing: 4) {
                Text(engine.t("insights.window.\(window.rawValue)"))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(InsightsPalette.sub)
        }
        .accessibilityLabel(engine.t("insights.window.pick"))
    }
}

struct InsightsScopeMenu: View {
    var engine: GoobyEngine
    @Binding var scope: InsightsScope

    var body: some View {
        Menu {
            ForEach(InsightsScope.allCases, id: \.rawValue) { item in
                Button(engine.t("insights.scope.\(item.rawValue)")) { scope = item }
            }
        } label: {
            HStack(spacing: 4) {
                Text(engine.t("insights.scope.\(scope.rawValue)"))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(InsightsPalette.sub)
        }
        .accessibilityLabel(engine.t("insights.scope.pick"))
    }
}

struct InsightsPill: View {
    var title: String
    var fill: Color
    var ink: Color

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(fill, in: Capsule())
    }
}
