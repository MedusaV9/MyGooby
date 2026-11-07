import SwiftUI

// Design tokens shared by the app and the widget extension (GoobyWidgets). The app's `Theme`
// (Gooby/Design/Theme.swift) is not compiled into the extension, so widget and Live Activity
// views use `GoobyTokens`; the values are the same reference tokens (screenshot-reference.md,
// "Cross-screen style"). Shared file: only the extras foundation and extras-integrate edit it.

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

enum GoobyTokens {
    /// Cream screen and widget background.
    static let cream = Color(hex: 0xFFF8EF)
    static let white = Color(hex: 0xFFFFFF)
    /// Dark grey text on white and cream. Never pure black.
    static let text = Color(hex: 0x3A3A3A)
    /// Warm brown text on beige.
    static let brown = Color(hex: 0x6E5434)
    static let greyText = Color(hex: 0x9A9A9A)
    static let capsGrey = Color(hex: 0x8C96A3)
    static let line = Color(hex: 0xECECEC)
    static let keyFace = Color(hex: 0xEFEFEF)
    static let keyEdge = Color(hex: 0xD5D5D5)
    static let checkGreen = Color(hex: 0x4CAF50)
    static let checkGreenEdge = Color(hex: 0x3B8E3F)
    /// Energy bolt and the striped progress fill.
    static let bolt = Color(hex: 0xF5A524)
    static let progressFill = Color(hex: 0xF9C74F)
    static let ochre = Color(hex: 0xD4A53C)
    static let notebook = Color(hex: 0xFFF7EF)

    /// Home tab: green meadow, dusk sky of the adventure forest.
    static let homeGreen = Color(hex: 0x7DBA5E)
    static let homeSky = Color(hex: 0x5E6BB0)
    static let homeSkyLow = Color(hex: 0x8F8FC9)
    static let homeLime = Color(hex: 0xC5D93A)
    /// Quests tab background and its icon tile colors.
    static let questsBlue = Color(hex: 0xD2DEEC)
    static let tileOrange = Color(hex: 0xF47B4F)
    static let tilePurple = Color(hex: 0x8B4FE0)
    static let tileYellow = Color(hex: 0xF7C540)
    static let tileGreen = Color(hex: 0x6DB45A)
    static let tileSky = Color(hex: 0x3EB5E8)
    static let tilePink = Color(hex: 0xE54C8B)
    /// Pet tab beige and cream.
    static let petBeige = Color(hex: 0xEAD8A8)
    static let petBeigeTop = Color(hex: 0xF3E6C3)
    static let petCream = Color(hex: 0xF6EBCB)
    /// Bag tab night sky and orange sheet.
    static let night = Color(hex: 0x2D3456)
    static let bagOrange = Color(hex: 0xFFA357)
    static let star = Color(hex: 0xFFF3C4)
    static let moon = Color(hex: 0xF4F0D2)
    /// Menu, settings and activities.
    static let menuBlue = Color(hex: 0xD3E0EE)
    static let purple = Color(hex: 0x7A6CC9)
    static let purpleLight = Color(hex: 0x9C90DE)
    static let calm = Color(hex: 0xE2DDF4)
    static let heart = Color(hex: 0xFF6F91)

    enum Radius {
        static let card: CGFloat = 22
        static let tile: CGFloat = 20
        static let icon: CGFloat = 14
    }

    /// Heavy rounded type, same styles as `Theme.Fonts`.
    enum Fonts {
        static let title = Font.system(.title2, design: .rounded, weight: .heavy)
        static let title3 = Font.system(.title3, design: .rounded, weight: .heavy)
        static let headline = Font.system(.headline, design: .rounded, weight: .heavy)
        static let button = Font.system(.headline, design: .rounded, weight: .bold)
        static let body = Font.system(.subheadline, design: .rounded, weight: .semibold)
        static let caption = Font.system(.footnote, design: .rounded, weight: .semibold)
        static let caps = Font.system(.caption, design: .rounded, weight: .heavy)

        /// Fixed-size rounded type for small widget and Live Activity surfaces.
        static func rounded(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }
    }
}
