import SwiftUI

/// One complete app look. Colors stay as 0xRRGGBB so a look can mix shades without UIKit.
final class AppTheme: Identifiable {
    let id: String
    let isDark: Bool
    /// Alternate icon set name. Nil is the primary AppIcon.
    let icon: String?

    let page: UInt32
    let card: UInt32
    let well: UInt32
    let line: UInt32
    let ink: UInt32
    let inkSoft: UInt32
    let inkFaint: UInt32
    let accent: UInt32
    let rose: UInt32
    let success: UInt32
    let energy: UInt32

    let pink: UInt32
    let lavender: UInt32
    let mint: UInt32
    let yellow: UInt32
    let peach: UInt32
    let sky: UInt32

    let home: UInt32
    let homeDeep: UInt32
    let quests: UInt32
    let profile: UInt32
    let profileInk: UInt32
    let bag: UInt32
    let bagDeep: UInt32
    let settings: UInt32
    let night: UInt32
    let shadow: UInt32

    let sceneTint: UInt32
    let sceneSaturation: Double
    let sceneBrightness: Double

    init(
        id: String, isDark: Bool, icon: String?,
        page: UInt32, card: UInt32, well: UInt32, line: UInt32,
        ink: UInt32, inkSoft: UInt32, inkFaint: UInt32,
        accent: UInt32, rose: UInt32, success: UInt32, energy: UInt32,
        pink: UInt32, lavender: UInt32, mint: UInt32, yellow: UInt32, peach: UInt32, sky: UInt32,
        home: UInt32, homeDeep: UInt32, quests: UInt32, profile: UInt32, profileInk: UInt32,
        bag: UInt32, bagDeep: UInt32, settings: UInt32, night: UInt32, shadow: UInt32,
        scene: (tint: UInt32, saturation: Double, brightness: Double)
    ) {
        self.id = id
        self.isDark = isDark
        self.icon = icon
        self.page = page
        self.card = card
        self.well = well
        self.line = line
        self.ink = ink
        self.inkSoft = inkSoft
        self.inkFaint = inkFaint
        self.accent = accent
        self.rose = rose
        self.success = success
        self.energy = energy
        self.pink = pink
        self.lavender = lavender
        self.mint = mint
        self.yellow = yellow
        self.peach = peach
        self.sky = sky
        self.home = home
        self.homeDeep = homeDeep
        self.quests = quests
        self.profile = profile
        self.profileInk = profileInk
        self.bag = bag
        self.bagDeep = bagDeep
        self.settings = settings
        self.night = night
        self.shadow = shadow
        self.sceneTint = scene.tint
        self.sceneSaturation = scene.saturation
        self.sceneBrightness = scene.brightness
    }

    /// The shipped look. Routed colors return their original literals for this instance only.
    var isClassic: Bool { self === AppTheme.classic }
    var nameKey: String { "theme.\(id)" }

    var homeBar: UInt32 { HexMix.tint(home, isDark ? 0.08 : 0.12) }
    var homePill: UInt32 { HexMix.tint(home, isDark ? 0.2 : 0.38) }
    var homeButton: UInt32 { HexMix.shade(homeDeep, 0.06) }

    func soft(_ color: UInt32, _ amount: Double = 0.7) -> UInt32 { HexMix.mix(color, card, amount) }
    func color(_ value: UInt32) -> Color { Color(hex: value) }
}

enum HexMix {
    static func mix(_ a: UInt32, _ b: UInt32, _ amount: Double) -> UInt32 {
        let t = min(1, max(0, amount))
        func channel(_ shift: UInt32) -> UInt32 {
            let x = Double((a >> shift) & 0xFF)
            let y = Double((b >> shift) & 0xFF)
            return UInt32((x + (y - x) * t).rounded()) << shift
        }
        return channel(16) | channel(8) | channel(0)
    }

    static func tint(_ color: UInt32, _ amount: Double) -> UInt32 { mix(color, 0xFFFFFF, amount) }
    static func shade(_ color: UInt32, _ amount: Double) -> UInt32 { mix(color, 0x000000, amount) }
}

extension AppTheme {
    static let classic = AppTheme(
        id: "classic", isDark: false, icon: nil,
        page: 0xFFF8EF, card: 0xFFFFFF, well: 0xF0F0F0, line: 0xF0F2F4,
        ink: 0x3D3656, inkSoft: 0x687178, inkFaint: 0x9EA5AB,
        accent: 0x566FD6, rose: 0xE989B0, success: 0x53A34C, energy: 0xFFC122,
        pink: 0xFFD6E7, lavender: 0xD3C2FF, mint: 0xC6EFDC, yellow: 0xFFE7AD, peach: 0xFFD6B3, sky: 0xC8E9FF,
        home: 0x7BB65C, homeDeep: 0x70AD4E, quests: 0xCEDBE4, profile: 0xEEDCB6, profileInk: 0x645737,
        bag: 0xFD9F55, bagDeep: 0xF88119, settings: 0xD3E1EE, night: 0x253252, shadow: 0x7E96A8,
        scene: (0xFFFFFF, 1.0, 0.0)
    )

    static let cream = AppTheme(
        id: "cream", isDark: false, icon: "AppIcon-Cream",
        page: 0xF8F1E6, card: 0xFFFDF9, well: 0xF3ECE2, line: 0xEFE6DA,
        ink: 0x4A3B3A, inkSoft: 0x7A6B68, inkFaint: 0xA99C98,
        accent: 0x9378C9, rose: 0xEE9FAE, success: 0x74A862, energy: 0xF6C453,
        pink: 0xFBD3D8, lavender: 0xE3D6F3, mint: 0xD6EBD9, yellow: 0xFBE7B5, peach: 0xF9D9C4, sky: 0xD9E6F5,
        home: 0xA28BD0, homeDeep: 0x9279C6, quests: 0xE9DFF0, profile: 0xF1E2CB, profileInk: 0x6B5440,
        bag: 0xD9787A, bagDeep: 0xC65C5F, settings: 0xECE3F1, night: 0x3B3354, shadow: 0x9C8A9A,
        scene: (0xF4ECFF, 0.92, 0.02)
    )

    static let forest = AppTheme(
        id: "forest", isDark: false, icon: "AppIcon-Forest",
        page: 0xF1F4EA, card: 0xFFFFFF, well: 0xEBF0E4, line: 0xE3EADB,
        ink: 0x24352B, inkSoft: 0x5D6F62, inkFaint: 0x93A397,
        accent: 0x3E8A55, rose: 0xD98A8A, success: 0x3E9B4F, energy: 0xF2C14E,
        pink: 0xF3D9D2, lavender: 0xDCD8EC, mint: 0xCDE7D2, yellow: 0xF4E6B0, peach: 0xF2D8BF, sky: 0xCFE3E6,
        home: 0x4E8A4C, homeDeep: 0x437D42, quests: 0xD3E2D2, profile: 0xE4D9BC, profileInk: 0x5A4C30,
        bag: 0xC77B3B, bagDeep: 0xA9622A, settings: 0xD9E5D5, night: 0x1F3326, shadow: 0x5F7A64,
        scene: (0xE6F2DC, 1.08, -0.02)
    )

    static let sakura = AppTheme(
        id: "sakura", isDark: false, icon: "AppIcon-Sakura",
        page: 0xFFF5F7, card: 0xFFFFFF, well: 0xFBEDF1, line: 0xF6E3E9,
        ink: 0x4B2F3B, inkSoft: 0x85646F, inkFaint: 0xB39AA3,
        accent: 0xD45D8A, rose: 0xE77FA6, success: 0x6DB07A, energy: 0xF7BE4F,
        pink: 0xFFD3E2, lavender: 0xEAD7F2, mint: 0xD8EEDF, yellow: 0xFFEABC, peach: 0xFFDCCD, sky: 0xDDE8F7,
        home: 0xE08AA9, homeDeep: 0xD7769A, quests: 0xF5DEE6, profile: 0xF7E2DA, profileInk: 0x7A4A55,
        bag: 0xEE8E8E, bagDeep: 0xD96C78, settings: 0xF6E1EA, night: 0x3E2A3D, shadow: 0xB07A8C,
        scene: (0xFFE0EA, 0.95, 0.02)
    )

    static let ocean = AppTheme(
        id: "ocean", isDark: false, icon: "AppIcon-Ocean",
        page: 0xF0F7FA, card: 0xFFFFFF, well: 0xE8F1F5, line: 0xDFEBF1,
        ink: 0x1F3442, inkSoft: 0x557080, inkFaint: 0x8EA5B2,
        accent: 0x2B7BBE, rose: 0xE7899E, success: 0x2FA37A, energy: 0xF6C24A,
        pink: 0xF7D7E0, lavender: 0xD9DAF4, mint: 0xC9EDE3, yellow: 0xF7E9B8, peach: 0xF8DCC6, sky: 0xC8E5F5,
        home: 0x3A93BA, homeDeep: 0x2F82A8, quests: 0xD2E6EF, profile: 0xEBE1CB, profileInk: 0x5C4E36,
        bag: 0xF08A5D, bagDeep: 0xD96F3F, settings: 0xD4E6F1, night: 0x1C2F4A, shadow: 0x5F8299,
        scene: (0xDCEEFF, 1.0, 0.0)
    )

    static let honey = AppTheme(
        id: "honey", isDark: false, icon: "AppIcon-Honey",
        page: 0xFFF6E6, card: 0xFFFFFF, well: 0xFBEEDA, line: 0xF4E6CF,
        ink: 0x47331F, inkSoft: 0x7D6447, inkFaint: 0xAD987D,
        accent: 0xC26A1C, rose: 0xE58F87, success: 0x6FA650, energy: 0xF5B731,
        pink: 0xFCD9CF, lavender: 0xE6DBF0, mint: 0xDDEBCF, yellow: 0xFFE6A6, peach: 0xFFD4B0, sky: 0xD8E6EF,
        home: 0xD3862C, homeDeep: 0xC47621, quests: 0xF5E5C8, profile: 0xF1D8AE, profileInk: 0x6A4B23,
        bag: 0xE06E3C, bagDeep: 0xC85A2C, settings: 0xF5E7D2, night: 0x3A2A1E, shadow: 0xA98A62,
        scene: (0xFFE9C4, 1.0, 0.02)
    )

    static let contrast = AppTheme(
        id: "contrast", isDark: false, icon: "AppIcon-Contrast",
        page: 0xF2F2F2, card: 0xFFFFFF, well: 0xE3E3E3, line: 0x9A9A9A,
        ink: 0x000000, inkSoft: 0x1A1A1A, inkFaint: 0x4D4D4D,
        accent: 0x0040C8, rose: 0xB0004F, success: 0x006B2D, energy: 0xF2B200,
        pink: 0xFFD1E3, lavender: 0xDCD3FF, mint: 0xC2F0D8, yellow: 0xFFE680, peach: 0xFFD0A8, sky: 0xBFE3FF,
        home: 0x0E5A2A, homeDeep: 0x0A4620, quests: 0xE3ECF5, profile: 0xF0E2C2, profileInk: 0x3A2A00,
        bag: 0xB23A00, bagDeep: 0x8C2D00, settings: 0xE8EDF2, night: 0x0A1230, shadow: 0x000000,
        scene: (0xFFFFFF, 1.15, 0.0)
    )

    static let night = AppTheme(
        id: "night", isDark: true, icon: "AppIcon-Night",
        page: 0x1C1A2B, card: 0x2A2740, well: 0x37334F, line: 0x3A3654,
        ink: 0xF2EEFF, inkSoft: 0xC7C0E0, inkFaint: 0x8D87A8,
        accent: 0x7462E6, rose: 0xEE8DB6, success: 0x5CC27D, energy: 0xFFC94A,
        pink: 0x5A3248, lavender: 0x443A6E, mint: 0x2D5243, yellow: 0x5A4A22, peach: 0x5C3F2F, sky: 0x2B4562,
        home: 0x2E3D6E, homeDeep: 0x26335E, quests: 0x23203A, profile: 0x2D2738, profileInk: 0xEBDDB9,
        bag: 0xA9583A, bagDeep: 0x8E4528, settings: 0x1C1A2B, night: 0x141226, shadow: 0x000000,
        scene: (0x7F88C8, 0.85, -0.06)
    )

    static let firefly = AppTheme(
        id: "firefly", isDark: true, icon: "AppIcon-Firefly",
        page: 0x141F19, card: 0x1F2E26, well: 0x2A3D32, line: 0x314538,
        ink: 0xEAF4EC, inkSoft: 0xB9CDBF, inkFaint: 0x7F9587,
        accent: 0x35875A, rose: 0xE7909A, success: 0x63C27A, energy: 0xF7D64A,
        pink: 0x543340, lavender: 0x3B3A5C, mint: 0x2A5240, yellow: 0x54502A, peach: 0x553C2B, sky: 0x25445A,
        home: 0x2A5A3B, homeDeep: 0x224C31, quests: 0x1A2A22, profile: 0x2A281D, profileInk: 0xE7DDB6,
        bag: 0xA86A2C, bagDeep: 0x8A5420, settings: 0x141F19, night: 0x0D1812, shadow: 0x000000,
        scene: (0x6E9A86, 0.9, -0.08)
    )

    static let contrastDark = AppTheme(
        id: "contrastDark", isDark: true, icon: "AppIcon-ContrastDark",
        page: 0x000000, card: 0x161616, well: 0x2A2A2A, line: 0x5C5C5C,
        ink: 0xFFFFFF, inkSoft: 0xF0F0F0, inkFaint: 0xBDBDBD,
        accent: 0x6BA3FF, rose: 0xFF5C9A, success: 0x30D158, energy: 0xFFD60A,
        pink: 0x5C1E36, lavender: 0x3A2A70, mint: 0x0F4A2E, yellow: 0x5A4A00, peach: 0x5C3010, sky: 0x0F3A5C,
        home: 0x0F4D24, homeDeep: 0x0B3D1C, quests: 0x0A0A0A, profile: 0x121212, profileInk: 0xFFE7A8,
        bag: 0xB83E0A, bagDeep: 0x942F06, settings: 0x000000, night: 0x000000, shadow: 0x000000,
        scene: (0xA0A0A0, 1.1, -0.05)
    )

    static let lightLooks: [AppTheme] = [classic, cream, forest, sakura, ocean, honey, contrast]
    static let darkLooks: [AppTheme] = [night, firefly, contrastDark]
    static let all: [AppTheme] = lightLooks + darkLooks

    static func find(_ id: String?) -> AppTheme? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }
}

/// Sends a color through the active look. The classic look always gets its original literal back.
enum Paint {
    static var theme: AppTheme { ThemeStore.shared.active }

    static func pick(_ classic: UInt32, _ derive: (AppTheme) -> UInt32) -> Color {
        let current = theme
        return Color(hex: current.isClassic ? classic : derive(current))
    }

    static func shadow(_ classic: UInt32, _ opacity: Double) -> Color {
        let current = theme
        if current.isClassic { return Color(hex: classic).opacity(opacity) }
        return Color(hex: current.shadow).opacity(current.isDark ? min(0.6, opacity * 2.4) : opacity)
    }
}

/// Tints a large illustrated backdrop so it sits inside the active look.
struct ThemedScene: ViewModifier {
    func body(content: Content) -> some View {
        let current = Paint.theme
        content
            .colorMultiply(Color(hex: current.sceneTint))
            .saturation(current.sceneSaturation)
            .brightness(current.sceneBrightness)
    }
}

extension View {
    func themedScene() -> some View { modifier(ThemedScene()) }
}
