import SwiftUI

/// The goal icon on Home: a sticker on the light blob plate. Morning starters keep their own marks.
struct HomeGoalIcon: View {
    var symbol: String
    var suggestionID: String

    var body: some View {
        ZStack {
            GoalPlate().fill(HomePalette.iconWell)
            GoalSticker(glyph: glyph)
                .scaleEffect(0.7)
        }
        .accessibilityHidden(true)
    }

    private var glyph: String {
        switch suggestionID {
        case "get-out-of-bed": return "sunflower"
        case "brush-teeth": return "brush"
        case "wash-face": return "soap"
        case "water": return "cup"
        default:
            switch symbol {
            case "bed.double.fill", "sun.max.fill", "sunrise.fill": return "sunflower"
            default: return GoalArt.glyph(forSymbol: symbol)
            }
        }
    }
}
