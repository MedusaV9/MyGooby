import SwiftUI
import UIKit

enum WidgetPalette {
    static let cream = Color(widgetHex: 0xFFF8EF)
    static let fur = Color(widgetHex: 0xFFFBF4)
    static let outline = Color(widgetHex: 0xE9DCCB)
    static let lavender = Color(widgetHex: 0xE9DEFF)
    static let lilac = Color(widgetHex: 0xB79BE8)
    static let pink = Color(widgetHex: 0xF6B5C0)
    static let blush = Color(widgetHex: 0xF7A9B5)
    static let backpack = Color(widgetHex: 0xC9504A)
    static let feet = Color(widgetHex: 0xA39C96)
    static let ink = Color(widgetHex: 0x3D3656)
    static let soft = Color(widgetHex: 0x8E86A3)
    static let bolt = Color(widgetHex: 0xF0B43C)
    static let check = Color(widgetHex: 0x7DCAA8)
    static let well = Color(widgetHex: 0xF3EDE4)

    static var background: LinearGradient {
        LinearGradient(colors: [cream, lavender.opacity(0.85)], startPoint: .top, endPoint: .bottom)
    }
}

extension Color {
    init(widgetHex hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    init(widgetHexString: String) {
        var value = widgetHexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") { value.removeFirst() }
        self.init(widgetHex: UInt32(value, radix: 16) ?? 0xFFD6E7)
    }
}

enum GoobyWidgetArt {
    static func portrait() -> UIImage? { image(GoobySharedStore.portraitName) }

    static func badge() -> UIImage? { image(GoobySharedStore.badgeName) }

    private static func image(_ name: String) -> UIImage? {
        guard let data = GoobySharedStore.imageData(name), let image = UIImage(data: data), image.size.width > 1 else { return nil }
        return image
    }

    static func symbol(_ name: String) -> String {
        UIImage(systemName: name) == nil ? "sparkles" : name
    }
}

// Shown when the rendered character is missing, including when the App Group never opens.
struct GoobyBunnyMark: View {
    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 100, geo.size.height / 118)
            ZStack {
                RoundedRectangle(cornerRadius: 15 * scale, style: .continuous)
                    .fill(WidgetPalette.backpack)
                    .frame(width: 36 * scale, height: 44 * scale)
                    .offset(x: -30 * scale, y: 30 * scale)
                ear(scale).rotationEffect(.degrees(-9)).offset(x: -15 * scale, y: -38 * scale)
                ear(scale).rotationEffect(.degrees(9)).offset(x: 15 * scale, y: -38 * scale)
                Ellipse().fill(WidgetPalette.feet).frame(width: 16 * scale, height: 9 * scale).offset(x: -12 * scale, y: 54 * scale)
                Ellipse().fill(WidgetPalette.feet).frame(width: 16 * scale, height: 9 * scale).offset(x: 12 * scale, y: 54 * scale)
                Ellipse()
                    .fill(WidgetPalette.fur)
                    .overlay(Ellipse().stroke(WidgetPalette.outline, lineWidth: max(1, 1.5 * scale)))
                    .frame(width: 56 * scale, height: 50 * scale)
                    .offset(y: 30 * scale)
                Ellipse()
                    .fill(WidgetPalette.fur)
                    .overlay(Ellipse().stroke(WidgetPalette.outline, lineWidth: max(1, 1.5 * scale)))
                    .frame(width: 72 * scale, height: 60 * scale)
                    .offset(y: -4 * scale)
                Circle().fill(WidgetPalette.blush.opacity(0.8)).frame(width: 13 * scale).offset(x: -23 * scale, y: 6 * scale)
                Circle().fill(WidgetPalette.blush.opacity(0.8)).frame(width: 13 * scale).offset(x: 23 * scale, y: 6 * scale)
                Circle().fill(WidgetPalette.ink).frame(width: 8 * scale).offset(x: -13 * scale, y: -5 * scale)
                Circle().fill(WidgetPalette.ink).frame(width: 8 * scale).offset(x: 13 * scale, y: -5 * scale)
                Capsule().fill(WidgetPalette.pink).frame(width: 7 * scale, height: 5 * scale).offset(y: 3 * scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }

    private func ear(_ scale: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(WidgetPalette.fur)
                .overlay(Capsule().stroke(WidgetPalette.outline, lineWidth: max(1, 1.5 * scale)))
                .frame(width: 21 * scale, height: 46 * scale)
            Capsule().fill(WidgetPalette.pink).frame(width: 10 * scale, height: 32 * scale).offset(y: 3 * scale)
        }
    }
}

struct GoobyPortrait: View {
    var image: UIImage?

    var body: some View {
        if let image {
            Image(uiImage: image).resizable().scaledToFit()
        } else {
            GoobyBunnyMark()
        }
    }
}

enum WidgetText {
    static func language(_ snapshot: GoobyWidgetSnapshot?) -> String {
        if let snapshot { return snapshot.language == "en" ? "en" : "de" }
        return deviceLanguage()
    }

    static func deviceLanguage() -> String {
        "de"
    }

    static func t(_ key: String, _ language: String) -> String {
        guard let row = table[key] else { return key }
        return language == "en" ? row.1 : row.0
    }

    static func tf(_ key: String, _ language: String, _ args: CVarArg...) -> String {
        String(format: t(key, language), locale: Locale(identifier: language), arguments: args)
    }

    static func clock(_ seconds: Int) -> String {
        let safe = max(0, seconds)
        return String(format: "%d:%02d", safe / 60, safe % 60)
    }

    private static let table: [String: (String, String)] = [
        "energy": ("Energie", "Energy"),
        "goals": ("Ziele", "Goals"),
        "goalsCount": ("%d von %d Zielen", "%d of %d goals"),
        "allDone": ("Alles geschafft!", "All done!"),
        "noGoals": ("Heute keine Ziele", "No goals today"),
        "away": ("%@ ist unterwegs", "%@ is exploring"),
        "back": ("%@ ist zurück!", "%@ is back!"),
        "ready": ("Bereit fürs Abenteuer", "Ready for an adventure"),
        "needEnergy": ("Noch %d Energie bis zum Abenteuer", "%d more energy until the adventure"),
        "focus": ("Fokus", "Focus"),
        "paused": ("Pausiert", "Paused"),
        "newDay": ("Neuer Tag – öffne Gooby", "New day – open Gooby"),
        "openOnce": ("Öffne Gooby einmal, dann erscheint hier dein Tag.", "Open Gooby once to see your day here."),
        "more": ("+%d weitere", "+%d more"),
        "streak": ("%d Tage in Folge", "%d days in a row"),
        "done": ("Geschafft", "Done")
    ]
}
