import SwiftUI

/// Colorful icon for a name.
/// - Names with a flat illustration (GoobyArt: the habit icons, calendar, sparks, bolt, flame,
///   quest glyphs and the emoji aliased to them) draw that illustration.
/// - Other emoji names ("🌻") render as Apple Color Emoji (bundled with iOS, offline).
/// - Other known SF Symbol names (stored `Habit.icon` values, shell symbols) map to an emoji at
///   render time. Stored values are never migrated.
/// - Any other name falls back to `Image(systemName:)` in `tint`.
struct GoobyIcon: View {
    var name: String
    var size: CGFloat
    var tint: Color

    init(_ name: String, size: CGFloat = 28, tint: Color = Theme.text) {
        self.name = name
        self.size = size
        self.tint = tint
    }

    var body: some View {
        Group {
            if let art = GoobyArt.resolve(name) {
                // The art fills its 32-unit grid; inset it to the visual size of an emoji glyph.
                GoobyArtView(name: art)
                    .padding(size * 0.06)
            } else if let emoji = GoobyIcon.emoji(for: name) {
                Text(verbatim: emoji)
                    .font(.system(size: size * 0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else {
                Image(systemName: name)
                    .font(.system(size: size * 0.62, weight: .bold))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// The emoji drawn for `name`, or nil when it falls back to the SF Symbol.
    static func emoji(for name: String) -> String? {
        if name.unicodeScalars.contains(where: { !$0.isASCII }) { return name }
        return symbolEmoji[name]
    }

    static let symbolEmoji: [String: String] = [
        // Theme.habitIcons
        "drop.fill": "💧",
        "bed.double.fill": "🛏️",
        "sparkles": "✨",
        "figure.walk": "🚶",
        "wind": "🌬️",
        "pencil": "✏️",
        "book.fill": "📖",
        "heart.fill": "💗",
        "leaf.fill": "🌿",
        "cup.and.saucer.fill": "🍵",
        "moon.fill": "🌙",
        "sun.max.fill": "🌻",
        "house.fill": "🏡",
        "brain.head.profile": "🧠",
        "fork.knife": "🥗",
        "music.note": "🎵",
        // Shell and feature symbols
        "sparkle": "✨",
        "star.fill": "⭐",
        "bolt.fill": "⚡",
        "flame.fill": "🔥",
        "calendar": "📅",
        "bag.fill": "🎒",
        "backpack.fill": "🎒",
        "gearshape.fill": "⚙️",
        "face.smiling": "🙂",
        "face.smiling.fill": "😊",
        "pawprint.fill": "🐾",
        "flag.fill": "🚩",
        "chart.bar.fill": "📊",
        "map.fill": "🗺️",
        "hand.draw.fill": "🤲",
        "sofa.fill": "🛋️",
        "bell.fill": "🔔",
        "gift.fill": "🎁",
        "envelope.fill": "💌",
        "tshirt.fill": "👕",
        "paintpalette.fill": "🎨",
        "airplane": "✈️",
        "checkmark.circle.fill": "✅",
        "list.bullet.clipboard": "📋",
        "book.closed.fill": "📔",
        "lock.fill": "🔒",
        "globe": "🌍",
        "square.and.arrow.up": "📤",
        "trash.fill": "🗑️",
        "timer": "⏱️",
        "hourglass": "⏳",
        "alarm.fill": "⏰",
        "moon.stars.fill": "🌙",
        "sun.haze.fill": "🌅",
        "cloud.rain.fill": "🌧️",
        "water.waves": "🌊",
        "tree.fill": "🌳",
        "leaf": "🌿",
        "mappin.and.ellipse": "📍",
        "info.circle.fill": "ℹ️",
        "questionmark.circle.fill": "❓",
        "photo.fill": "🖼️",
        "externaldrive.fill": "💾",
        "figure.mind.and.body": "🧘",
        "figure.run": "🏃",
        "bicycle": "🚲",
        "lightbulb.fill": "💡",
        "newspaper.fill": "📰",
        "shippingbox.fill": "📦",
        "storefront.fill": "🏪",
        "ticket.fill": "🎟️",
        "pills.fill": "💊",
        "bathtub.fill": "🛁",
        "shower.fill": "🚿",
        "graduationcap.fill": "🎓",
        "paintbrush.fill": "🖌️",
        "camera.fill": "📷",
        "carrot.fill": "🥕",
        "birthday.cake.fill": "🎂",
        "snowflake": "❄️",
        "cross.case.fill": "🩹",
        "eye.fill": "👀"
    ]
}

/// Illustrated tab icons (GoobyArt "tab.*"): a bunny hutch with a round hole, a clipboard with a
/// blue star sticker, a shop with a striped awning, a round tree and a red bundle on a stick.
/// `.pet` draws a small bunny head; the tab bar shows `GoobyAvatar` there instead.
struct TabIconView: View {
    var kind: GoobyTab
    var selected: Bool
    var size: CGFloat = 30

    var body: some View {
        Group {
            if kind == .pet {
                bunnyHead
                    .frame(width: 30, height: 30)
                    .scaleEffect(size / 30)
            } else {
                GoobyArtView(name: "tab.\(kind.rawValue)")
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(selected ? 1.08 : 1)
        .accessibilityHidden(true)
    }

    private var ear: some View {
        Capsule()
            .fill(Color(hex: 0xFFF3E2))
            .frame(width: 6, height: 11)
            .overlay(Capsule().fill(Color(hex: 0xFFB7CC)).frame(width: 2.5, height: 7))
    }

    /// Small cream bunny head (fallback for the pet tab).
    private var bunnyHead: some View {
        ZStack {
            ear.scaleEffect(1.2).rotationEffect(.degrees(-10)).offset(x: -5, y: -9)
            ear.scaleEffect(1.2).rotationEffect(.degrees(10)).offset(x: 5, y: -9)
            Circle().fill(Color(hex: 0xFFF3E2)).frame(width: 22, height: 20).offset(y: 4)
            Circle().fill(Color(hex: 0x2B2B2B)).frame(width: 3.5, height: 3.5).offset(x: -4, y: 3)
            Circle().fill(Color(hex: 0x2B2B2B)).frame(width: 3.5, height: 3.5).offset(x: 4, y: 3)
            Ellipse().fill(Color(hex: 0xFFB7CC)).frame(width: 4, height: 2.5).offset(x: -7, y: 7)
            Ellipse().fill(Color(hex: 0xFFB7CC)).frame(width: 4, height: 2.5).offset(x: 7, y: 7)
        }
    }
}
