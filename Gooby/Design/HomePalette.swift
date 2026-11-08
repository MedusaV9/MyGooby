import SwiftUI

// Colors sampled from media/look-reference/home.jpg and goals.jpg (390×844 points).
enum HomePalette {
    static let sky = Color(hex: 0x526DB4)
    static let canopy = Color(hex: 0xADBC1B)
    static let canopyLeaf = Color(hex: 0xC1C787)
    static let canopyDeep = Color(hex: 0x919944)
    static let canopyShade = Color(hex: 0x83882E)
    static let page = Color(hex: 0x7BB65C)
    static let card = Color(hex: 0x70AD4E)
    static let tabBar = Color(hex: 0x8ABD6E)
    static let pill = Color(hex: 0xB3D5A2)
    static let addGoal = Color(hex: 0x69A148)
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
    static let ink = Color(hex: 0x2A2A2A)
    static let check = Color(hex: 0x53A34C)
    static let bolt = Color(hex: 0xFFC122)
    static let boltDeep = Color(hex: 0xEF911F)
    static let iconWell = Color(hex: 0xF0F0F0)
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
    static let questsBar = Color(hex: 0xBDCFDB)
    static let bagBar = Color(hex: 0xF88119)
    static let goobyBar = Color(hex: 0xE8D4A1)
    static let shopBar = Color(hex: 0xFFF8EF)
    static let fur = Color(hex: 0xFFF6EA)
    static let furShade = Color(hex: 0xF0D8C4)
    static let cheek = Color(hex: 0xFFB7CC)
    static let innerEar = Color(hex: 0xFFC2D6)
    static let eye = Color(hex: 0x6B4128)
    static let nose = Color(hex: 0xFF9BB8)

    static let questsPill = Color(hex: 0xD7E6F0)
    static let bagPill = Color(hex: 0xFFC089)
    static let creamPill = Color(hex: 0xFFF4DE)
    static let labelDark = Color(hex: 0x3A4550)
}

enum HomeMetrics {
    static let cardRadius: CGFloat = 22
    static let cardInset: CGFloat = 16
    static let rowRadius: CGFloat = 26
    static let forestBelowStatus: CGFloat = 381
    static let forestOverlap: CGFloat = 36
    static let tabBody: CGFloat = 62

    static var topInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let height = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.safeAreaInsets.top ?? 0
        return height > 1 ? height : 47
    }
}
