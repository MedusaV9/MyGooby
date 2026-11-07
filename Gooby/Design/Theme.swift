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

    // MARK: Reference tokens (screenshot-reference.md, "Cross-screen style")

    /// Dark grey text on white cards. Never pure black.
    static let text = Color(hex: 0x3A3A3A)
    /// Warm brown text on beige screens.
    static let brown = Color(hex: 0x6E5434)
    /// Semibold secondary text.
    static let greyText = Color(hex: 0x9A9A9A)
    /// Uppercase section headers on pale screens.
    static let capsGrey = Color(hex: 0x8C96A3)
    static let line = Color(hex: 0xECECEC)
    /// Flat face and bottom edge of the light grey 3D keys (check, Hint, Add).
    static let keyFace = Color(hex: 0xEFEFEF)
    static let keyEdge = Color(hex: 0xD5D5D5)
    static let checkGreen = Color(hex: 0x4CAF50)
    static let checkGreenEdge = Color(hex: 0x3B8E3F)
    static let bolt = Color(hex: 0xF5A524)
    static let progressFill = Color(hex: 0xF9C74F)
    static let ochre = Color(hex: 0xD4A53C)
    static let notebook = Color(hex: 0xFFF7EF)

    enum Radius {
        static let card: CGFloat = 22
        static let tile: CGFloat = 20
        static let icon: CGFloat = 14
        static let sheet: CGFloat = 32
    }

    enum Space {
        /// Side margin of a screen.
        static let margin: CGFloat = 20
        /// Padding inside a card.
        static let inner: CGFloat = 16
        /// Vertical gap between cards.
        static let gap: CGFloat = 12
    }

    /// Heavy rounded type. Text styles keep Dynamic Type working.
    enum Fonts {
        /// 22 pt heavy: screen and profile titles.
        static let title = Font.system(.title2, design: .rounded, weight: .heavy)
        /// 20 pt heavy: big numbers, banner titles.
        static let title3 = Font.system(.title3, design: .rounded, weight: .heavy)
        /// 17 pt heavy: card and row titles.
        static let headline = Font.system(.headline, design: .rounded, weight: .heavy)
        /// 17 pt bold: buttons.
        static let button = Font.system(.headline, design: .rounded, weight: .bold)
        /// 15 pt semibold: secondary text.
        static let body = Font.system(.subheadline, design: .rounded, weight: .semibold)
        /// 13 pt semibold: subtitles under titles.
        static let caption = Font.system(.footnote, design: .rounded, weight: .semibold)
        /// 12 pt heavy: uppercase section headers and tab labels.
        static let caps = Font.system(.caption, design: .rounded, weight: .heavy)
    }

    /// Per-tab full-screen palettes. Each tab bar takes its tab's `bar` tint.
    enum Tab {
        static let home = HomeTint()
        static let quests = QuestsTint()
        static let shop = ShopTint()
        static let friends = FriendsTint()
        static let bag = BagTint()
        static let pet = PetTint()
        static let menu = MenuTint()
    }
}

/// The six tabs of the shell, in tab bar order.
enum GoobyTab: String, CaseIterable, Identifiable, Hashable {
    case home, quests, shop, friends, bag, pet

    var id: String { rawValue }

    var tint: TabBarTint {
        switch self {
        case .home: return Theme.Tab.home.bar
        case .quests: return Theme.Tab.quests.bar
        case .shop: return Theme.Tab.shop.bar
        case .friends: return Theme.Tab.friends.bar
        case .bag: return Theme.Tab.bag.bar
        case .pet: return Theme.Tab.pet.bar
        }
    }
}

/// Colors of the custom tab bar for one tab.
struct TabBarTint {
    var bar: Color
    var highlight: Color
    var label: Color
}

struct HomeTint {
    let bg = Color(hex: 0x7DBA5E)
    let sky = Color(hex: 0x5E6BB0)
    let skyLow = Color(hex: 0x8F8FC9)
    let lime = Color(hex: 0xC5D93A)
    let leaf = Color(hex: 0x5FA64A)
    let leafDark = Color(hex: 0x3F8A3C)
    let trunk = Color(hex: 0x8A5A3A)
    let rock = Color(hex: 0x9CA3A8)
    let moon = Color(hex: 0xF4F0D2)
    /// Translucent darker cards on the green (adventure card, "Add a goal").
    let overlay = Color.black.opacity(0.10)
    let wave = Color(hex: 0x93C977)
    let bar = TabBarTint(bar: Color(hex: 0x6CAA50), highlight: Color.white.opacity(0.28), label: .white)
}

struct QuestsTint {
    let bg = Color(hex: 0xD2DEEC)
    /// Icon tile colors from the quest list, in reference order.
    let orange = Color(hex: 0xF47B4F)
    let purple = Color(hex: 0x8B4FE0)
    let yellow = Color(hex: 0xF7C540)
    let green = Color(hex: 0x6DB45A)
    let sky = Color(hex: 0x3EB5E8)
    let pink = Color(hex: 0xE54C8B)
    var tiles: [Color] { [orange, purple, yellow, green, sky, pink] }
    let bar = TabBarTint(bar: Color(hex: 0xC2D1E3), highlight: Color.white.opacity(0.7), label: Color(hex: 0x5C6B80))
}

struct ShopTint {
    let bg = Color(hex: 0xF7D6E0)
    let awning = Color(hex: 0xE84A4A)
    let accent = Color(hex: 0xD9668C)
    let bar = TabBarTint(bar: Color(hex: 0xEEC3D1), highlight: Color.white.opacity(0.6), label: Color(hex: 0x95506A))
}

struct FriendsTint {
    let skyTop = Color(hex: 0x5468C0)
    let skyBottom = Color(hex: 0x7F94D8)
    let canopyDark = Color(hex: 0x2E8B3A)
    let canopy = Color(hex: 0x4CA84A)
    let canopyLight = Color(hex: 0x7BC768)
    let trunk = Color(hex: 0x8A5A3A)
    let grass = Color(hex: 0x8CC66A)
    let sign = Color(hex: 0xB98552)
    /// Light green user name under Gooby's name.
    let nameGreen = Color(hex: 0xCFF3B0)
    /// Dark translucent green banner.
    let banner = Color(hex: 0x1F5E2A).opacity(0.55)
    let bannerLabel = Color(hex: 0xFFD45E)
    var sky: LinearGradient { LinearGradient(colors: [skyTop, skyBottom], startPoint: .top, endPoint: .bottom) }
    let bar = TabBarTint(bar: Color(hex: 0x7AB65A), highlight: Color.white.opacity(0.3), label: .white)
}

struct BagTint {
    let night = Color(hex: 0x2D3456)
    let hills = Color(hex: 0x24402F)
    let sheet = Color(hex: 0xFFA357)
    let locked = Color(hex: 0xF28A2E)
    let tag = Color(hex: 0xFFD45E)
    let tagBorder = Color(hex: 0xC99A2E)
    let sack = Color(hex: 0xE5484D)
    let bar = TabBarTint(bar: Color(hex: 0xF7963F), highlight: Color.white.opacity(0.3), label: .white)
}

struct PetTint {
    let bg = Color(hex: 0xEAD8A8)
    /// Lighter top of the beige gradient.
    let bgTop = Color(hex: 0xF3E6C3)
    /// Square top-bar buttons and the portrait frame.
    let cream = Color(hex: 0xF6EBCB)
    let clip = Color(hex: 0xA9784C)
    /// Beige bottom band of the profile card and the selected segment pill.
    let band = Color(hex: 0xEFE2BE)
    let pill = Color(hex: 0xDCC795)
    let watermark = Color(hex: 0xDCC896)
    /// Notebook card: binding tabs and stand.
    let binding = Color(hex: 0xB98552)
    let stand = Color(hex: 0xB07D50)
    /// Collection tiles.
    let tileOwned = Color(hex: 0x4A4A4A)
    let tileLocked = Color(hex: 0xF1E6D2)
    let silhouette = Color(hex: 0xE0CFAE)
    /// Friend album (screen 8).
    let ribbon = Color(hex: 0xE2A62A)
    let albumBinding = Color(hex: 0x7C6A3C)
    let albumTile = Color(hex: 0xF0E3C0)
    let albumSilhouette = Color(hex: 0xD2BF8E)
    var background: LinearGradient { LinearGradient(colors: [bgTop, bg], startPoint: .top, endPoint: .center) }
    let bar = TabBarTint(bar: Color(hex: 0xDDC68F), highlight: Color.white.opacity(0.45), label: Color(hex: 0x6E5434))
}

struct MenuTint {
    let bg = Color(hex: 0xD3E0EE)
    let banner = Color(hex: 0x7A6CC9)
    let chevron = Color(hex: 0x4A4A4A)
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

extension View {
    /// The very light shadow of white cards.
    func cardShadow() -> some View {
        shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
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
            .padding(Theme.Space.inner)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .cardShadow()
    }
}

/// Full-width primary button with a flat face and a darker bottom edge.
struct GoobyButtonStyle: ButtonStyle {
    var fill: Color = Theme.ink
    var ink: Color = Theme.cream
    @Environment(\.accessibilityReduceMotion) private var reduce
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        let pressed = configuration.isPressed
        configuration.label
            .font(Theme.Fonts.button)
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(shape.fill(fill))
            .offset(y: pressed ? 4 : 0)
            .background(
                shape.fill(fill).overlay(shape.fill(Color.black.opacity(0.18))).offset(y: 4)
            )
            .padding(.bottom, 4)
            .contentShape(shape)
            .opacity(enabled ? 1 : 0.5)
            .scaleEffect(!reduce && pressed ? 0.98 : 1)
            .animation(reduce ? nil : .easeOut(duration: 0.08), value: pressed)
    }
}

struct TinyIconButton: View {
    var title: String
    var symbol: String
    var fill: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                GoobyIcon(symbol, size: 24)
                Text(title)
                    .font(Theme.Fonts.caption)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(Press3DButtonStyle(fill: fill, edge: nil, radius: 18, horizontal: 0, vertical: 0))
    }
}

struct ProgressRibbon: View {
    var value: Double
    var tint: Color = Theme.rose

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line)
                Capsule()
                    .fill(tint)
                    .frame(width: max(8, geo.size.width * min(1, max(0, value))))
                    .overlay(alignment: .top) {
                        Capsule().fill(Color.white.opacity(0.35)).frame(height: 3).padding(.horizontal, 4).padding(.top, 2)
                    }
            }
        }
        .frame(height: 12)
        .accessibilityValue("\(Int(min(1, max(0, value)) * 100))%")
    }
}

struct ScreenBackground: ViewModifier {
    var color: Color = Theme.cream

    func body(content: Content) -> some View {
        content
            .background(color.ignoresSafeArea())
    }
}

extension View {
    func goobyScreen() -> some View { modifier(ScreenBackground()) }

    /// Full-screen solid background of a tab or screen, e.g. `.goobyScreen(Theme.Tab.quests.bg)`.
    func goobyScreen(_ color: Color) -> some View { modifier(ScreenBackground(color: color)) }
}
