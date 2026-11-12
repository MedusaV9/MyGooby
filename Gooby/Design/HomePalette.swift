import SwiftUI

// Colors sampled from reference/video-frames, 600×1304 px frames of a 390-point phone.
enum HomePalette {
    static let sky = Color(hex: 0x526DB4)
    static let canopy = Color(hex: 0xADBC1B)
    static let canopyLeaf = Color(hex: 0xC1C787)
    static let canopyDeep = Color(hex: 0x919944)
    static let canopyShade = Color(hex: 0x83882E)
    static var page: Color { Paint.pick(0x73B752) { $0.home } }
    static var card: Color { Paint.pick(0x68AF45) { $0.homeDeep } }
    static var tabBar: Color { Paint.pick(0x7FC064) { $0.homeBar } }
    static var pill: Color { Paint.pick(0xABD597) { $0.homePill } }
    static var addGoal: Color { Paint.pick(0x5FA43E) { $0.homeButton } }
    static let addGoalInk = Color(hex: 0xDDEFD3)
    static let addGoalWell = Color.white.opacity(0.12)
    static let rowInk = Color(hex: 0x2A2A2A)
    static let energyInk = Color(hex: 0x5F6567)
    static let rowBolt = Color(hex: 0xF0A53A)
    static let grip = Color(hex: 0x939699)
    static let buttonFace = Color(hex: 0xECECEC)
    static let buttonLip = Color(hex: 0xCECECE)
    static let trackDash = Color(hex: 0xDCDCDC)
    static let trackLink = Color(hex: 0xDAD9DB)
    static let meterFill = Color(hex: 0xF29F31)
    static let meterInk = Color(hex: 0x785224)
    static let petMarker = Color(hex: 0xCCF0D2)
    static let grassDark = Color(hex: 0x2E7450)
    static let pine = Color(hex: 0x40964F)
    static let pineDeep = Color(hex: 0x1E8266)
    static let meadow = Color(hex: 0x8DA452)
    static let trunk = Color(hex: 0xC08946)
    static let trunkDeep = Color(hex: 0x8F6243)
    static let rock = Color(hex: 0xC5B8A4)
    static let rockDeep = Color(hex: 0xA3978B)
    static let satchel = Color(hex: 0xBF3D3D)
    static let satchelDeep = Color(hex: 0x9A3030)
    static var ink: Color { Paint.pick(0x2A2A2A) { $0.ink } }
    static var check: Color { Paint.pick(0x4EA448) { $0.success } }
    static var bolt: Color { Paint.pick(0xF5BA25) { $0.energy } }
    static var boltDeep: Color { Paint.pick(0xF1A031) { HexMix.mix($0.energy, 0xE0701A, 0.6) } }
    static var iconWell: Color { Paint.pick(0xECECEC) { $0.well } }
    static let mood = Color(hex: 0xF7C765)
    static let moon = Color(hex: 0xFECB4E)
    static let birch = Color(hex: 0xE7E3D2)
    static let flowerRed = Color(hex: 0xDF5727)
    static let flowerYellow = Color(hex: 0xFFD581)
    static let flowerPink = Color(hex: 0xF2A0C0)
    static let house = Color(hex: 0xFFC56A)
    static let houseDoor = Color(hex: 0xEF911F)
    static let bag = Color(hex: 0xF15839)
    static let treeIcon = Color(hex: 0x5C903B)
    static var questsBar: Color { Paint.pick(0xB5C9D4) { HexMix.mix($0.quests, $0.ink, 0.08) } }
    static var bagBar: Color { Paint.pick(0xEA6D1B) { $0.bagDeep } }
    static var goobyBar: Color { Paint.pick(0xE0CE94) { HexMix.mix($0.profile, $0.profileInk, 0.1) } }
    static var shopBar: Color { Paint.pick(0xFFF8EF) { $0.page } }
    static let fur = Color(hex: 0xFFF6EA)
    static let furShade = Color(hex: 0xF0D8C4)
    static let cheek = Color(hex: 0xFFB7CC)
    static let innerEar = Color(hex: 0xFFC2D6)
    static let eye = Color(hex: 0x6B4128)
    static let nose = Color(hex: 0xFF9BB8)

    static var questsPill: Color { Paint.pick(0xA4B6C0) { $0.soft($0.quests, 0.35) } }
    static var bagPill: Color { Paint.pick(0xF48E4E) { HexMix.tint($0.bagDeep, $0.isDark ? 0.25 : 0.45) } }
    static var creamPill: Color { Paint.pick(0xCCBC89) { $0.soft($0.profile, 0.6) } }
    static var labelDark: Color { Paint.pick(0x2E363C) { $0.ink } }
    static var shopPill: Color { Paint.pick(0xF0E9E1) { $0.card } }
    static var row: Color { Paint.pick(0xFFFFFF) { $0.card } }
    static var rowSub: Color { Paint.pick(0x8E939A) { $0.inkFaint } }
    static var rowGrip: Color { Paint.pick(0xD5D5D5) { $0.isDark ? $0.line : HexMix.mix($0.well, $0.inkFaint, 0.35) } }
    static var rowShade: Color { Paint.pick(0xC8C8C8) { $0.isDark ? HexMix.shade($0.well, 0.35) : HexMix.mix($0.well, $0.inkFaint, 0.45) } }
}

enum HomeMetrics {
    static let cardRadius: CGFloat = 20
    static let cardInset: CGFloat = 14.5
    static let rowRadius: CGFloat = 22
    static let rowHeight: CGFloat = 66.5
    static let rowSpacing: CGFloat = 8.25
    static let forestBelowStatus: CGFloat = 317
    static let forestOverlap: CGFloat = 36
    /// Tab content above the home indicator. 99 reference px at 0.67 pt per px.
    static let tabBody: CGFloat = 66
    /// Pill corner. About 18 reference px at 0.67 pt per px.
    static let tabPillRadius: CGFloat = 12

    static var topInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let height = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.safeAreaInsets.top ?? 0
        return height > 1 ? height : 47
    }
}
