import SwiftUI

/// Colorful, emoji-style icon for a name.
/// - An emoji name ("🌻") renders as Apple Color Emoji (bundled with iOS, offline).
/// - A known SF Symbol name (stored `Habit.icon` values, shell symbols) maps to an emoji at
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
            if let emoji = GoobyIcon.emoji(for: name) {
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

/// Flat drawn tab icons (not SF Symbols). `.pet` draws a small bunny head; the tab bar shows
/// `GoobyAvatar` there instead.
struct TabIconView: View {
    var kind: GoobyTab
    var selected: Bool
    var size: CGFloat = 30

    var body: some View {
        icon
            .frame(width: 30, height: 30)
            .scaleEffect(size / 30)
            .frame(width: size, height: size)
            .scaleEffect(selected ? 1.08 : 1)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var icon: some View {
        switch kind {
        case .home: burrowHouse
        case .quests: starBook
        case .shop: awningShop
        case .friends: roundTree
        case .bag: bindle
        case .pet: bunnyHead
        }
    }

    /// Little bunny house with an orange/yellow roof and two ears on top.
    private var burrowHouse: some View {
        ZStack {
            ear.rotationEffect(.degrees(-14)).offset(x: -5, y: -11)
            ear.rotationEffect(.degrees(14)).offset(x: 5, y: -11)
            Triangle().fill(Color(hex: 0xFFC23D)).frame(width: 29, height: 14).offset(y: -3)
            Triangle().fill(Color(hex: 0xF47B4F)).frame(width: 22, height: 10).offset(y: -2)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: 0xFFE6A6))
                .frame(width: 21, height: 12)
                .offset(y: 9)
            Capsule().fill(Color(hex: 0x8A5A3C)).frame(width: 7, height: 9).offset(y: 10.5)
            Circle().fill(Color(hex: 0xBFE3FF)).frame(width: 4, height: 4).offset(x: 6.5, y: 7)
        }
    }

    private var ear: some View {
        Capsule()
            .fill(Color(hex: 0xFFF3E2))
            .frame(width: 6, height: 11)
            .overlay(Capsule().fill(Color(hex: 0xFFB7CC)).frame(width: 2.5, height: 7))
    }

    /// Blue book with a yellow star.
    private var starBook: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0x3A63B8))
                .frame(width: 22, height: 26)
                .offset(x: 1.5, y: 1.5)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white)
                .frame(width: 20, height: 24)
                .offset(x: 2.5, y: 0.5)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0x5B8DEF))
                .frame(width: 21, height: 25)
                .offset(x: -0.5, y: -1)
            Rectangle().fill(Color(hex: 0x3F6FD0)).frame(width: 3.5, height: 25).offset(x: -8.5, y: -1)
            Star(points: 5).fill(Color(hex: 0xFFD34E)).frame(width: 13, height: 13).offset(x: 1, y: -1)
        }
    }

    /// Small shop with a red and white awning.
    private var awningShop: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: 0xFFF1DC))
                .frame(width: 23, height: 15)
                .offset(y: 7)
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color(hex: 0x8FC1E8))
                .frame(width: 7, height: 10)
                .offset(x: -4, y: 9.5)
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color(hex: 0x8FC1E8))
                .frame(width: 6, height: 5)
                .offset(x: 6, y: 5)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0xE84A4A))
                .frame(width: 28, height: 5)
                .offset(y: -10)
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    let color = index.isMultiple(of: 2) ? Color(hex: 0xE84A4A) : Color.white
                    VStack(spacing: -3.5) {
                        Rectangle().fill(color).frame(width: 7, height: 6)
                        Circle().fill(color).frame(width: 7, height: 7)
                    }
                }
            }
            .offset(y: -3)
        }
    }

    /// Round green tree.
    private var roundTree: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0x9A6B43))
                .frame(width: 5, height: 11)
                .offset(y: 10)
            Circle().fill(Color(hex: 0x4CA84A)).frame(width: 25, height: 25).offset(y: -3)
            Circle().fill(Color(hex: 0x2E8B3A).opacity(0.55)).frame(width: 11, height: 11).offset(x: 6, y: 3)
            Circle().fill(Color(hex: 0x7BC768)).frame(width: 10, height: 10).offset(x: -5, y: -8)
        }
    }

    /// Red bindle sack on a stick.
    private var bindle: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0x9A6B43))
                .frame(width: 3, height: 31)
                .rotationEffect(.degrees(-40))
                .offset(x: -2, y: 1)
            Circle().fill(Color(hex: 0xE5484D)).frame(width: 20, height: 20).offset(x: 4, y: 4)
            Triangle().fill(Color(hex: 0xC93A3F)).frame(width: 8, height: 7).offset(x: 6, y: -7)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 3, height: 3).offset(x: 0, y: 2)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 3, height: 3).offset(x: 8, y: 6)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 3, height: 3).offset(x: 3, y: 10)
        }
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
