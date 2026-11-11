import SwiftUI

struct ShopWallSwatch: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(swatch.primary).frame(width: 42, height: 36)
            Capsule().fill(swatch.second).frame(width: 42, height: 6).offset(y: 15)
            if style % 4 == 1 {
                Capsule().fill(swatch.second.opacity(0.7)).frame(width: 36, height: 4).offset(y: -6)
                Capsule().fill(swatch.second.opacity(0.7)).frame(width: 36, height: 4).offset(y: 4)
            }
            if style % 4 == 2 {
                Rectangle().fill(swatch.second).frame(width: 42, height: 16).offset(y: -10)
            }
            if style % 4 == 3 {
                Circle().fill(swatch.second).frame(width: 5).offset(x: -8, y: -4)
                Circle().fill(swatch.second).frame(width: 5).offset(x: 6, y: 2)
                Circle().fill(swatch.second).frame(width: 4).offset(x: 0, y: -10)
            }
            RoundedRectangle(cornerRadius: 3).stroke(Theme.ink.opacity(0.2), lineWidth: 2).frame(width: 12, height: 10).offset(x: 10, y: -8)
        }
    }
}

struct ShopFloorSwatch: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(swatch.primary).frame(width: 46, height: 28)
            if style % 4 == 0 {
                Capsule().fill(swatch.second.opacity(0.55)).frame(width: 2, height: 28).offset(x: -12)
                Capsule().fill(swatch.second.opacity(0.55)).frame(width: 2, height: 28)
                Capsule().fill(swatch.second.opacity(0.55)).frame(width: 2, height: 28).offset(x: 12)
            }
            if style % 4 == 1 {
                Capsule().fill(swatch.second).frame(width: 2, height: 40).rotationEffect(.degrees(35))
                Capsule().fill(swatch.second).frame(width: 2, height: 40).rotationEffect(.degrees(35)).offset(x: 12)
            }
            if style % 4 == 2 {
                RoundedRectangle(cornerRadius: 2).stroke(swatch.second, lineWidth: 2).frame(width: 14, height: 10).offset(x: -10)
                RoundedRectangle(cornerRadius: 2).stroke(swatch.second, lineWidth: 2).frame(width: 14, height: 10).offset(x: 10)
                RoundedRectangle(cornerRadius: 2).stroke(swatch.second, lineWidth: 2).frame(width: 14, height: 10).offset(y: 8)
            }
            if style % 4 == 3 {
                Ellipse().fill(swatch.second.opacity(0.8)).frame(width: 28, height: 12)
            }
        }
    }
}

struct ShopBedPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 4).fill(swatch.second).frame(width: 10, height: 28).offset(x: -22, y: -6)
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(swatch.primary).frame(width: 48, height: 18)
            Capsule().fill(Theme.cream).frame(width: 16, height: 10).offset(x: -8, y: -8)
            if style % 4 == 2 {
                Capsule().fill(swatch.second).frame(width: 36, height: 4).offset(y: -4)
            }
            if style % 4 == 3 {
                Circle().fill(swatch.second).frame(width: 6).offset(x: 12, y: -10)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 6).offset(x: 12, y: -2)
            }
        }
    }
}

struct ShopRugPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            Ellipse().fill(swatch.primary).frame(width: 52, height: 26)
            Ellipse().stroke(swatch.second, lineWidth: 3).frame(width: 40, height: 16)
            if style % 4 == 1 {
                RoundedRectangle(cornerRadius: 1).fill(swatch.second).frame(width: 8, height: 8).rotationEffect(.degrees(45))
            }
            if style % 4 == 2 {
                Circle().fill(swatch.second).frame(width: 8)
            }
            if style % 4 == 0 || style % 4 == 3 {
                ShopMark(swatch: swatch, size: 6)
            }
        }
    }
}

struct ShopLampPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        VStack(spacing: 0) {
            if style % 4 == 1 {
                Capsule().fill(swatch.primary).frame(width: 28, height: 16)
            } else if style % 4 == 2 {
                Circle().fill(swatch.primary).frame(width: 20)
            } else {
                Capsule().fill(swatch.primary).frame(width: 26, height: 16)
            }
            Rectangle().fill(Theme.ink.opacity(0.45)).frame(width: 3, height: style % 4 == 2 ? 10 : 16)
            Ellipse().fill(swatch.second).frame(width: 16, height: 6)
        }
    }
}

struct ShopWindowPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            if style % 4 == 1 {
                Circle().fill(swatch.primary).frame(width: 32)
                Circle().stroke(swatch.second, lineWidth: 3).frame(width: 32)
                Capsule().fill(swatch.second).frame(width: 3, height: 26)
                Capsule().fill(swatch.second).frame(width: 26, height: 3)
            } else {
                RoundedRectangle(cornerRadius: style % 4 == 2 ? 14 : 6, style: .continuous)
                    .fill(swatch.primary)
                    .frame(width: 32, height: 28)
                RoundedRectangle(cornerRadius: style % 4 == 2 ? 12 : 4, style: .continuous)
                    .stroke(swatch.second, lineWidth: 3)
                    .frame(width: 32, height: 28)
                Capsule().fill(swatch.second).frame(width: 3, height: 22)
                Capsule().fill(swatch.second).frame(width: 26, height: 3)
            }
            if style % 4 == 3 {
                Circle().fill(Color(hex: 0xFFE56A)).frame(width: 6).offset(x: 6, y: -4)
            }
        }
    }
}

struct ShopPlantPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            Capsule().fill(swatch.second).frame(width: 18, height: 12).offset(y: 14)
            Ellipse().fill(swatch.primary).frame(width: 14, height: 22).rotationEffect(.degrees(-24)).offset(x: -8, y: -2)
            Ellipse().fill(swatch.primary).frame(width: 14, height: 22).rotationEffect(.degrees(22)).offset(x: 8, y: -2)
            Ellipse().fill(swatch.primary.opacity(0.85)).frame(width: 12, height: 20).offset(y: -10)
            if style % 4 == 1 || style % 4 == 2 {
                Circle().fill(swatch.second).frame(width: 6).offset(x: 10, y: -12)
            }
            if style % 4 == 3 {
                Circle().fill(Color(hex: 0xFF8FB3)).frame(width: 5).offset(x: -6, y: -8)
                Circle().fill(Color(hex: 0xFFE56A)).frame(width: 4).offset(x: 4, y: -14)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 5).offset(y: 6)
            }
        }
    }
}

struct ShopShelfPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 2).fill(style % 4 == 1 ? swatch.second : Theme.peach).frame(width: 8, height: 16)
                RoundedRectangle(cornerRadius: 2).fill(swatch.primary).frame(width: 8, height: 20)
                RoundedRectangle(cornerRadius: 2).fill(style % 4 == 2 ? swatch.second : Theme.sky).frame(width: 8, height: 14)
                if style % 4 == 3 {
                    Circle().fill(swatch.second).frame(width: 8)
                }
            }
            Capsule().fill(swatch.primary).frame(width: 42, height: 5)
            if style % 4 == 0 {
                Capsule().fill(swatch.second).frame(width: 42, height: 5)
            }
        }
    }
}

struct ShopPicturePiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(swatch.second).frame(width: 36, height: 30)
            RoundedRectangle(cornerRadius: 3, style: .continuous).fill(swatch.primary).frame(width: 26, height: 20)
            if style % 4 == 0 {
                Circle().fill(Color(hex: 0xFFE56A)).frame(width: 8).offset(x: 6, y: -4)
            }
            if style % 4 == 1 {
                Circle().fill(Theme.cream).frame(width: 8).offset(x: 4, y: -3)
            }
            if style % 4 == 2 {
                Capsule().fill(Theme.cream.opacity(0.8)).frame(width: 16, height: 4).offset(y: 4)
                Capsule().fill(Theme.cream.opacity(0.8)).frame(width: 12, height: 3).offset(y: 8)
            }
            ShopMark(swatch: swatch, size: 5).offset(x: -8, y: 6)
        }
    }
}

struct ShopSofaPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(swatch.primary).frame(width: 46, height: 18).offset(y: 6)
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(swatch.primary.opacity(0.9)).frame(width: 46, height: 12).offset(y: -6)
            RoundedRectangle(cornerRadius: 4).fill(swatch.second).frame(width: 8, height: 20).offset(x: -22, y: 2)
            RoundedRectangle(cornerRadius: 4).fill(swatch.second).frame(width: 8, height: 20).offset(x: 22, y: 2)
            if style % 4 == 2 || style % 4 == 3 {
                Circle().fill(Theme.cream).frame(width: 8).offset(x: -8, y: 2)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 6).offset(y: 4)
            }
        }
    }
}

struct ShopTablePiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(swatch.primary).frame(width: 40, height: 10)
            Rectangle().fill(swatch.second).frame(width: 4, height: 14).offset(x: -12, y: 8)
            Rectangle().fill(swatch.second).frame(width: 4, height: 14).offset(x: 12, y: 8)
            if style % 4 == 3 {
                Circle().fill(Theme.cream).frame(width: 8).offset(y: -8)
                Capsule().fill(swatch.second).frame(width: 6, height: 4).offset(y: -4)
            }
            if style % 4 == 1 {
                Ellipse().fill(swatch.second).frame(width: 14, height: 6).offset(y: -6)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 5).offset(y: -8)
            }
        }
    }
}

struct ShopCushionPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            if style % 4 == 0 {
                ShopHeartShape().fill(swatch.primary).frame(width: 28, height: 24)
            } else {
                Ellipse().fill(swatch.primary).frame(width: 36, height: 22)
                Ellipse().stroke(swatch.second.opacity(0.8), lineWidth: 2).frame(width: 26, height: 14)
            }
            if style % 4 == 2 {
                ShopMark(swatch: swatch, size: 6)
            }
            if style % 4 == 1 {
                Circle().fill(swatch.second).frame(width: 6)
            }
        }
    }
}

struct ShopSeasonalPiece: View {
    var item: ItemDef
    var swatch: ShopSwatch

    private var motif: String {
        let id = item.id
        if id.contains("lantern") { return "lantern" }
        if id.contains("snow") || id.contains("winter") { return "snow" }
        if id.contains("sun") || id.contains("picnic") { return "sun" }
        if id.contains("blossom") || id.contains("petal") || id.contains("spring") || id.contains("cherry") { return "blossom" }
        if id.contains("leaf") { return "leaf" }
        if id.contains("star") || id.contains("spark") { return "star" }
        if id.contains("rainbow") { return "rainbow" }
        if id.contains("cozy") { return "cozy" }
        return "fest"
    }

    var body: some View {
        ZStack {
            switch motif {
            case "lantern":
                RoundedRectangle(cornerRadius: 3).fill(swatch.second).frame(width: 16, height: 4).offset(y: -16)
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(swatch.primary).frame(width: 22, height: 26)
                Capsule().fill(Color(hex: 0xFFE56A)).frame(width: 8, height: 12)
            case "snow":
                Capsule().fill(swatch.primary).frame(width: 4, height: 28)
                Capsule().fill(swatch.primary).frame(width: 4, height: 28).rotationEffect(.degrees(60))
                Capsule().fill(swatch.second).frame(width: 4, height: 28).rotationEffect(.degrees(120))
            case "sun":
                Circle().fill(swatch.primary).frame(width: 16)
                Capsule().fill(swatch.second).frame(width: 3, height: 10).offset(y: -14)
                Capsule().fill(swatch.second).frame(width: 3, height: 10).offset(y: 14)
                Capsule().fill(swatch.second).frame(width: 10, height: 3).offset(x: -14)
                Capsule().fill(swatch.second).frame(width: 10, height: 3).offset(x: 14)
            case "blossom":
                Circle().fill(swatch.primary).frame(width: 10).offset(y: -8)
                Circle().fill(swatch.primary).frame(width: 10).offset(x: -8, y: 2)
                Circle().fill(swatch.primary).frame(width: 10).offset(x: 8, y: 2)
                Circle().fill(swatch.second).frame(width: 8)
                Capsule().fill(Color(hex: 0x7BB65C)).frame(width: 3, height: 16).offset(y: 14)
            case "leaf":
                Ellipse().fill(swatch.primary).frame(width: 18, height: 28).rotationEffect(.degrees(-20))
                Capsule().fill(swatch.second).frame(width: 2, height: 20)
            case "star":
                RoundedRectangle(cornerRadius: 2).fill(swatch.primary).frame(width: 14, height: 14).rotationEffect(.degrees(45))
                Capsule().fill(swatch.second).frame(width: 3, height: 26)
                Capsule().fill(swatch.second).frame(width: 3, height: 26).rotationEffect(.degrees(90))
            case "rainbow":
                Circle().trim(from: 0.5, to: 1).stroke(Color(hex: 0xFF8FB3), lineWidth: 3).frame(width: 32, height: 32)
                Circle().trim(from: 0.5, to: 1).stroke(Color(hex: 0xFFE56A), lineWidth: 3).frame(width: 22, height: 22).offset(y: 4)
                Circle().trim(from: 0.5, to: 1).stroke(Color(hex: 0x7FD3FF), lineWidth: 3).frame(width: 12, height: 12).offset(y: 8)
            case "cozy":
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(swatch.primary).frame(width: 24, height: 18).offset(y: 4)
                Circle().stroke(swatch.second, lineWidth: 3).frame(width: 10, height: 12).offset(x: 16, y: 4)
                Capsule().fill(swatch.second.opacity(0.8)).frame(width: 3, height: 8).offset(x: -4, y: -12)
                Capsule().fill(swatch.second.opacity(0.8)).frame(width: 3, height: 8).offset(x: 4, y: -14)
            default:
                Capsule().fill(Theme.ink.opacity(0.35)).frame(width: 3, height: 28).offset(y: 4)
                RoundedRectangle(cornerRadius: 3).fill(swatch.primary).frame(width: 22, height: 14).offset(x: 6, y: -6)
                ShopMark(swatch: swatch, size: 6).offset(x: 6, y: -6)
            }
        }
    }
}
