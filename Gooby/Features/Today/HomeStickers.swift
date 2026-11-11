import SwiftUI

/// The goal icon on Home: a sticker on the light blob plate. Morning starters get their own stickers.
struct HomeGoalIcon: View {
    var symbol: String
    var suggestionID: String

    var body: some View {
        ZStack {
            GoalPlate().fill(HomePalette.iconWell)
            sticker
                .scaleEffect(0.7)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder private var sticker: some View {
        switch suggestionID {
        case "get-out-of-bed": SunflowerSticker()
        case "brush-teeth": ToothbrushSticker()
        case "wash-face": SoapSticker()
        case "water": WaterGlassSticker()
        default:
            switch symbol {
            case "bed.double.fill", "sun.max.fill", "sunrise.fill": SunflowerSticker()
            default: GoalSticker(glyph: GoalArt.glyph(forSymbol: symbol))
            }
        }
    }
}

private struct HomeStickerCanvas: View {
    var draw: (inout GraphicsContext) -> Void

    var body: some View {
        Canvas { context, _ in draw(&context) }
            .frame(width: 40, height: 40)
            .stickerRim()
    }
}

private extension GraphicsContext {
    func fill(_ d: String, _ hex: UInt32, _ opacity: Double = 1) {
        fill(GoobyPathData.path(d), with: .color(Color(hex: hex).opacity(opacity)))
    }

    func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ hex: UInt32, turn: Double = 0, opacity: Double = 1) {
        let path = Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
            .applying(CGAffineTransform(rotationAngle: turn * .pi / 180).concatenating(CGAffineTransform(translationX: cx, y: cy)))
        fill(path, with: .color(Color(hex: hex).opacity(opacity)))
    }

    func line(_ d: String, _ hex: UInt32, _ width: CGFloat) {
        stroke(GoobyPathData.path(d), with: .color(Color(hex: hex)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}

struct SunflowerSticker: View {
    var body: some View {
        HomeStickerCanvas { context in
            context.line("M20 22 L20 37", 0x5C913B, 2.6)
            context.oval(13.5, 31, 6, 2.8, 0x77B255, turn: -28)
            context.oval(26.5, 31, 6, 2.8, 0x77B255, turn: 28)
            for petal in 0..<12 {
                let angle = Double(petal) * 30
                let radians = angle * .pi / 180
                let x = 20 + CGFloat(sin(radians)) * 8.6
                let y = 15 - CGFloat(cos(radians)) * 8.6
                context.oval(x, y, 3.1, 5.4, petal.isMultiple(of: 2) ? 0xFFAC33 : 0xFFCC4D, turn: angle)
            }
            context.oval(20, 15, 6, 6, 0x664500)
            context.oval(20, 15, 4, 4, 0x8A5A1A)
            context.oval(18.4, 13.4, 1.2, 1.2, 0xC1894F)
        }
    }
}

struct ToothbrushSticker: View {
    var body: some View {
        HomeStickerCanvas { context in
            context.line("M14.5 13 L32 33", 0x3BB0A4, 5)
            context.line("M16.5 14.5 L31 31", 0x7FD3C9, 1.6)
            context.line("M8 6.5 L15 14.5", 0x3BB0A4, 5)
            for step in 0..<4 {
                let t = CGFloat(step) * 1.9
                context.line("M\(9.4 + t) \(3.8 + t * 1.05) L\(5.4 + t) \(7.6 + t * 1.05)", 0xF5F8FA, 2.2)
            }
            context.line("M8.6 3.4 L5 6.8", 0xBBDDF5, 1.2)
        }
    }
}

struct SoapSticker: View {
    var body: some View {
        HomeStickerCanvas { context in
            context.oval(21.5, 25, 14, 9.5, 0xD94F72, turn: -32)
            context.oval(21, 23.4, 13, 8.4, 0xF493AE, turn: -32)
            context.oval(17.5, 21.5, 5, 2, 0xFFD3DF, turn: -32, opacity: 0.9)
            context.oval(9.5, 11, 4.4, 4.4, 0xCCD6DD)
            context.oval(9.5, 11, 3.6, 3.6, 0xFFFFFF)
            context.oval(16.5, 7, 3.2, 3.2, 0xCCD6DD)
            context.oval(16.5, 7, 2.5, 2.5, 0xFFFFFF)
            context.oval(6.5, 18.5, 2.6, 2.6, 0xCCD6DD)
            context.oval(6.5, 18.5, 1.9, 1.9, 0xFFFFFF)
        }
    }
}

struct WaterGlassSticker: View {
    var body: some View {
        HomeStickerCanvas { context in
            context.fill("M9 10 L31 10 L28.6 36 L11.4 36 Z", 0xDDEBF5)
            context.fill("M10.2 18 L29.8 18 L27.9 35 L12.1 35 Z", 0x55ACEE)
            context.oval(20, 18, 9.8, 1.8, 0x9BD1F7)
            context.line("M25.5 3 L21.5 31", 0xF5F8FA, 2.6)
            context.line("M25.2 5 L24.7 8.6", 0xDD2E44, 2.6)
            context.line("M24.2 12 L23.7 15.6", 0xDD2E44, 2.6)
            context.line("M23.2 19 L22.7 22.6", 0xDD2E44, 2.6)
            context.fill("M12.6 21 L14.4 21 L14.6 32 L13.4 32 Z", 0xFFFFFF, 0.55)
            context.line("M9 10 L31 10", 0xBBDDF5, 1.2)
        }
    }
}
