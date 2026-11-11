import SwiftUI

// Colors sampled from reference/finch-frames (PR 34), 600×1304 px frames of a 390-point phone.
enum HomePalette {
    static let sky = Color(hex: 0x526DB4)
    static let canopy = Color(hex: 0xADBC1B)
    static let canopyLeaf = Color(hex: 0xC1C787)
    static let canopyDeep = Color(hex: 0x919944)
    static let canopyShade = Color(hex: 0x83882E)
    static let page = Color(hex: 0x73B752)
    static let card = Color(hex: 0x68AF45)
    static let tabBar = Color(hex: 0x7FC064)
    static let pill = Color.white.opacity(0.35)
    static let addGoal = Color(hex: 0x5FA43E)
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
    static let ink = Color(hex: 0x2A2A2A)
    static let check = Color(hex: 0x4EA448)
    static let bolt = Color(hex: 0xF5BA25)
    static let boltDeep = Color(hex: 0xF1A031)
    static let iconWell = Color(hex: 0xECECEC)
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
    static let questsBar = Color(hex: 0xB4C7D3)
    static let bagBar = Color(hex: 0xE96C1B)
    static let goobyBar = Color(hex: 0xE0CE94)
    static let shopBar = Color(hex: 0xFFF8EF)
    static let fur = Color(hex: 0xFFF6EA)
    static let furShade = Color(hex: 0xF0D8C4)
    static let cheek = Color(hex: 0xFFB7CC)
    static let innerEar = Color(hex: 0xFFC2D6)
    static let eye = Color(hex: 0x6B4128)
    static let nose = Color(hex: 0xFF9BB8)

    static let questsPill = Color.black.opacity(0.09)
    static let bagPill = Color.white.opacity(0.22)
    static let creamPill = Color.black.opacity(0.09)
    static let shopPill = Color.black.opacity(0.06)
    static let labelDark = Color(hex: 0x3A3A3A)
}

enum HomeMetrics {
    static let cardRadius: CGFloat = 20
    static let cardInset: CGFloat = 14
    static let rowRadius: CGFloat = 22
    static let rowHeight: CGFloat = 64
    static let rowSpacing: CGFloat = 8
    static let forestBelowStatus: CGFloat = 310
    static let forestOverlap: CGFloat = 36
    static let tabBody: CGFloat = 60
    static let tabPillRadius: CGFloat = 12

    static var topInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let height = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.safeAreaInsets.top ?? 0
        return height > 1 ? height : 47
    }
}
