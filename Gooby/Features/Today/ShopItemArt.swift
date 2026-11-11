import SwiftUI

struct ShopSwatch {
    var primary: Color
    var second: Color
    var mark: Int

    init(item: ItemDef) {
        primary = Color(hexString: item.color)
        second = Color(hexString: item.color2.isEmpty ? item.color : item.color2)
        var hash: UInt32 = 2166136261
        for byte in item.id.utf8 {
            hash = (hash ^ UInt32(byte)) &* 16777619
        }
        mark = Int(hash % 5)
    }
}

struct ShopMark: View {
    var swatch: ShopSwatch
    var size: CGFloat = 8

    var body: some View {
        switch swatch.mark {
        case 1:
            Circle().stroke(swatch.second, lineWidth: 1.6).frame(width: size, height: size)
        case 2:
            Capsule().fill(swatch.second).frame(width: size * 0.35, height: size)
        case 3:
            HStack(spacing: 2) {
                Circle().fill(swatch.second).frame(width: size * 0.42, height: size * 0.42)
                Circle().fill(swatch.second).frame(width: size * 0.42, height: size * 0.42)
            }
        case 4:
            RoundedRectangle(cornerRadius: 1).fill(swatch.second).frame(width: size, height: size * 0.32)
        default:
            Circle().fill(swatch.second).frame(width: size * 0.65, height: size * 0.65)
        }
    }
}

struct ShopHeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = rect.minY + rect.height * 0.32
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: top), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + rect.width * 0.25, y: top),
            radius: rect.width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: rect.minX + rect.width * 0.75, y: top),
            radius: rect.width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

struct ShopItemGlyph: View {
    var item: ItemDef

    private var swatch: ShopSwatch { ShopSwatch(item: item) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(0.16))
                .frame(width: 44, height: 8)
            piece
                .padding(.bottom, 4)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var piece: some View {
        switch item.slot {
        case "hat": ShopHatPiece(swatch: swatch, style: item.style)
        case "bow": ShopBowPiece(swatch: swatch, style: item.style)
        case "glasses": ShopGlassesPiece(swatch: swatch, style: item.style)
        case "shirt": ShopShirtPiece(swatch: swatch, style: item.style)
        case "sweater": ShopSweaterPiece(swatch: swatch, style: item.style)
        case "jacket": ShopJacketPiece(swatch: swatch, style: item.style)
        case "dress": ShopDressPiece(swatch: swatch, style: item.style)
        case "pants": ShopPantsPiece(swatch: swatch, style: item.style)
        case "shoes": ShopShoesPiece(swatch: swatch, style: item.style)
        case "backpack": ShopPackPiece(swatch: swatch, style: item.style)
        case "scarf": ShopScarfPiece(swatch: swatch, style: item.style)
        case "accessory": ShopPinPiece(item: item, swatch: swatch)
        case "fur": ShopFurHead(item: item)
        case "place": ShopTicketPiece(item: item, swatch: swatch)
        case "wall": ShopWallSwatch(swatch: swatch, style: item.style)
        case "floor": ShopFloorSwatch(swatch: swatch, style: item.style)
        case "bed": ShopBedPiece(swatch: swatch, style: item.style)
        case "rug": ShopRugPiece(swatch: swatch, style: item.style)
        case "lamp": ShopLampPiece(swatch: swatch, style: item.style)
        case "window": ShopWindowPiece(swatch: swatch, style: item.style)
        case "plant": ShopPlantPiece(swatch: swatch, style: item.style)
        case "shelf": ShopShelfPiece(swatch: swatch, style: item.style)
        case "picture": ShopPicturePiece(swatch: swatch, style: item.style)
        case "sofa": ShopSofaPiece(swatch: swatch, style: item.style)
        case "table": ShopTablePiece(swatch: swatch, style: item.style)
        case "cushion": ShopCushionPiece(swatch: swatch, style: item.style)
        case "seasonal": ShopSeasonalPiece(item: item, swatch: swatch)
        default: ShopCharmPiece(swatch: swatch, style: item.style)
        }
    }
}

struct ShopHatPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            switch style % 4 {
            case 1:
                Ellipse().fill(swatch.primary).frame(width: 54, height: 14).offset(y: 10)
                Capsule().fill(Color.black.opacity(0.18)).frame(width: 54, height: 6).offset(y: 14)
                Capsule().fill(swatch.primary).frame(width: 34, height: 24).offset(y: -4)
                Capsule().fill(swatch.second).frame(width: 32, height: 6).offset(y: 4)
                Circle().fill(swatch.second).frame(width: 8).offset(x: 10, y: -14)
            case 2:
                Ellipse().fill(swatch.primary).frame(width: 58, height: 14).offset(y: 12)
                Ellipse().fill(Color.black.opacity(0.16)).frame(width: 58, height: 6).offset(y: 16)
                Ellipse().fill(swatch.primary).frame(width: 32, height: 22).offset(y: -2)
                Capsule().fill(swatch.second).frame(width: 26, height: 5).offset(y: 4)
                Circle().fill(Color.white.opacity(0.35)).frame(width: 8).offset(x: -6, y: -8)
            case 3:
                beanie
                Ellipse().fill(Color(hex: 0x7CB86A)).frame(width: 14, height: 8).rotationEffect(.degrees(-30)).offset(x: 14, y: -4)
                Circle().fill(Color(hex: 0xE24B4B)).frame(width: 6).offset(x: 18, y: -10)
            default:
                beanie
            }
        }
    }

    private var beanie: some View {
        ZStack {
            Circle().fill(swatch.second).frame(width: 14).offset(y: -24)
            Circle().fill(Color.white.opacity(0.35)).frame(width: 5).offset(x: -3, y: -26)
            Capsule().fill(swatch.primary).frame(width: 36, height: 30).offset(y: -6)
            Capsule().fill(Color.white.opacity(0.22)).frame(width: 8, height: 16).offset(x: -8, y: -10)
            Capsule().fill(swatch.second).frame(width: 38, height: 11).offset(y: 8)
            Capsule().fill(Color.black.opacity(0.12)).frame(width: 38, height: 3).offset(y: 12)
            Capsule().fill(swatch.primary.opacity(0.85)).frame(width: 4, height: 8).offset(x: -10, y: 8)
            Capsule().fill(swatch.primary.opacity(0.85)).frame(width: 4, height: 8).offset(x: 0, y: 8)
            Capsule().fill(swatch.primary.opacity(0.85)).frame(width: 4, height: 8).offset(x: 10, y: 8)
        }
    }
}

struct ShopBowPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            Circle().fill(swatch.primary).frame(width: style % 4 == 2 ? 14 : 18).offset(x: -12)
            Circle().fill(swatch.primary).frame(width: style % 4 == 2 ? 14 : 18).offset(x: 12)
            Circle().fill(swatch.second).frame(width: 8)
            if style % 4 == 1 {
                Capsule().fill(swatch.primary).frame(width: 8, height: 16).rotationEffect(.degrees(24)).offset(x: -8, y: 12)
                Capsule().fill(swatch.primary).frame(width: 8, height: 16).rotationEffect(.degrees(-24)).offset(x: 8, y: 12)
            }
            if style % 4 == 3 {
                Capsule().fill(swatch.second).frame(width: 28, height: 5)
            }
        }
    }
}

struct ShopGlassesPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            Capsule().fill(swatch.primary).frame(width: 10, height: 3)
            if style % 4 == 1 {
                RoundedRectangle(cornerRadius: 3).stroke(swatch.primary, lineWidth: 3).frame(width: 18, height: 14).offset(x: -16)
                RoundedRectangle(cornerRadius: 3).stroke(swatch.primary, lineWidth: 3).frame(width: 18, height: 14).offset(x: 16)
            } else if style % 4 == 2 {
                Capsule().fill(swatch.primary.opacity(0.9)).frame(width: 22, height: 12).offset(x: -14)
                Capsule().fill(swatch.primary.opacity(0.9)).frame(width: 22, height: 12).offset(x: 14)
                Capsule().fill(swatch.second.opacity(0.85)).frame(width: 10, height: 3).offset(x: -14, y: -2)
            } else {
                Circle().stroke(swatch.primary, lineWidth: 3).frame(width: 18).offset(x: -14)
                Circle().stroke(swatch.primary, lineWidth: 3).frame(width: 18).offset(x: 14)
                if style % 4 == 3 {
                    ShopMark(swatch: swatch, size: 6)
                }
            }
        }
    }
}

struct ShopShirtPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            Capsule().fill(swatch.primary).frame(width: 16, height: 22).rotationEffect(.degrees(28)).offset(x: -18, y: -4)
            Capsule().fill(swatch.primary).frame(width: 16, height: 22).rotationEffect(.degrees(-28)).offset(x: 18, y: -4)
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(swatch.primary).frame(width: 30, height: 28).offset(y: 2)
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color.black.opacity(0.12)).frame(width: 30, height: 6).offset(y: 13)
            Capsule().fill(swatch.second).frame(width: 16, height: 8).offset(y: -12)
            Circle().fill(Theme.cream).frame(width: 7).offset(y: -16)
            Circle().fill(Color.white.opacity(0.28)).frame(width: 6).offset(x: -8, y: -2)
            if style % 4 == 1 {
                Capsule().fill(swatch.second).frame(width: 18, height: 5).offset(y: -6)
            }
            if style % 4 == 2 {
                VStack(spacing: 4) {
                    Capsule().fill(swatch.second).frame(width: 22, height: 3)
                    Capsule().fill(swatch.second).frame(width: 22, height: 3)
                    Capsule().fill(swatch.second).frame(width: 22, height: 3)
                }
                .offset(y: 2)
            }
            if style % 4 == 3 {
                // Collar, placket and a short hem, the way the frame's outfit is built from two pieces.
                Capsule().fill(swatch.second).frame(width: 8, height: 14).offset(y: -2)
                RoundedRectangle(cornerRadius: 4, style: .continuous).fill(swatch.second).frame(width: 22, height: 12).offset(y: 18)
                Capsule().fill(Color.black.opacity(0.15)).frame(width: 8, height: 10).offset(x: -6, y: 18)
                Capsule().fill(Color.black.opacity(0.15)).frame(width: 8, height: 10).offset(x: 6, y: 18)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 7).offset(y: 4)
            }
        }
    }
}

struct ShopSweaterPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            Capsule().fill(swatch.primary).frame(width: 18, height: 24).rotationEffect(.degrees(18)).offset(x: -20, y: 2)
            Capsule().fill(swatch.primary).frame(width: 18, height: 24).rotationEffect(.degrees(-18)).offset(x: 20, y: 2)
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(swatch.primary).frame(width: 36, height: 36)
            Capsule().fill(swatch.second).frame(width: 28, height: 6).offset(y: 14)
            if style % 4 == 1 {
                VStack(spacing: 4) {
                    Circle().fill(swatch.second).frame(width: 4)
                    Circle().fill(swatch.second).frame(width: 4)
                    Circle().fill(swatch.second).frame(width: 4)
                }
            }
            if style % 4 == 2 {
                Capsule().fill(swatch.second).frame(width: 26, height: 4).offset(y: -4)
                Capsule().fill(swatch.second).frame(width: 26, height: 4).offset(y: 4)
            }
            if style % 4 == 3 {
                Capsule().fill(swatch.second).frame(width: 14, height: 10).offset(y: -16)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 7)
            }
        }
    }
}

struct ShopJacketPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(swatch.primary).frame(width: 44, height: 36)
            Capsule().fill(swatch.second).frame(width: 8, height: 28)
            if style % 4 == 1 {
                Circle().fill(swatch.second).frame(width: 18).offset(y: -20)
            }
            if style % 4 == 2 {
                Capsule().fill(swatch.second).frame(width: 30, height: 5).offset(y: 8)
            }
            if style % 4 == 3 {
                Capsule().fill(swatch.second).frame(width: 18, height: 6).offset(y: -14)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 7).offset(x: 12, y: 4)
            }
        }
    }
}

struct ShopDressPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            Ellipse().fill(swatch.primary).frame(width: style % 4 == 2 ? 52 : 44, height: 28).offset(y: 8)
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(swatch.primary).frame(width: 22, height: 18).offset(y: -10)
            if style % 4 == 1 {
                Capsule().fill(swatch.second).frame(width: 24, height: 5).offset(y: -2)
            }
            if style % 4 == 3 {
                Capsule().fill(swatch.second).frame(width: 14, height: 5).offset(y: -16)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 7).offset(y: 10)
            }
        }
    }
}

struct ShopPantsPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        let short = style % 4 == 1
        ZStack {
            Capsule().fill(swatch.primary).frame(width: 16, height: short ? 20 : 32).offset(x: -10, y: short ? 6 : 2)
            Capsule().fill(swatch.primary).frame(width: 16, height: short ? 20 : 32).offset(x: 10, y: short ? 6 : 2)
            Capsule().fill(Color.black.opacity(0.16)).frame(width: 14, height: 5).offset(x: -10, y: short ? 14 : 16)
            Capsule().fill(Color.black.opacity(0.16)).frame(width: 14, height: 5).offset(x: 10, y: short ? 14 : 16)
            Capsule().fill(swatch.second).frame(width: 30, height: 8).offset(y: short ? -6 : -14)
            Capsule().fill(Color.white.opacity(0.25)).frame(width: 4, height: short ? 12 : 18).offset(x: -12, y: 2)
            if style % 4 == 2 {
                Capsule().fill(swatch.second).frame(width: 4, height: 16).offset(x: -8, y: -18)
                Capsule().fill(swatch.second).frame(width: 4, height: 16).offset(x: 8, y: -18)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 6).offset(y: short ? 2 : -2)
            }
            if style % 4 == 1 {
                // Turned-up cuffs, like the frame's patterned shorts.
                Capsule().fill(swatch.second).frame(width: 16, height: 5).offset(x: -10, y: 12)
                Capsule().fill(swatch.second).frame(width: 16, height: 5).offset(x: 10, y: 12)
            }
        }
    }
}

struct ShopShoesPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        HStack(spacing: 8) {
            shoe
            shoe
        }
    }

    private var shoe: some View {
        ZStack {
            if style % 4 == 2 {
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(swatch.primary).frame(width: 18, height: 22)
                Ellipse().fill(swatch.primary).frame(width: 22, height: 10).offset(y: 8)
                Capsule().fill(Color.black.opacity(0.2)).frame(width: 20, height: 4).offset(y: 12)
            } else {
                Ellipse().fill(swatch.primary).frame(width: 26, height: 14)
                Capsule().fill(Color.black.opacity(0.22)).frame(width: 24, height: 4).offset(y: 5)
                Capsule().fill(swatch.second).frame(width: 16, height: 3).offset(y: -2)
                Capsule().fill(Color.white.opacity(0.3)).frame(width: 8, height: 3).offset(x: -4, y: -3)
            }
            if style % 4 == 1 {
                Circle().fill(swatch.second).frame(width: 4).offset(y: -4)
            }
            if style % 4 == 3 {
                Capsule().fill(swatch.second).frame(width: 14, height: 3).offset(y: -4)
                Capsule().fill(swatch.second).frame(width: 10, height: 3).offset(y: 0)
            }
        }
    }
}

struct ShopPackPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        let tall = style % 4 == 3
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(swatch.primary)
                .frame(width: 34, height: tall ? 40 : 34)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.14))
                .frame(width: 34, height: 8)
                .offset(y: tall ? 16 : 13)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(swatch.second)
                .frame(width: 20, height: 14)
                .offset(y: -8)
            Capsule().fill(Color.white.opacity(0.28)).frame(width: 6, height: 8).offset(x: -5, y: -10)
            Capsule().fill(swatch.second).frame(width: 5, height: tall ? 34 : 28).offset(x: -14)
            Capsule().fill(swatch.second).frame(width: 5, height: tall ? 34 : 28).offset(x: 14)
            if style % 4 == 1 {
                RoundedRectangle(cornerRadius: 3).fill(swatch.second).frame(width: 16, height: 8).offset(y: 10)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 6).offset(y: 6)
            }
        }
    }
}

struct ShopScarfPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            Capsule().fill(swatch.primary).frame(width: 46, height: 14)
            Capsule().fill(swatch.second).frame(width: 10, height: style % 4 == 1 ? 28 : 20).offset(x: 14, y: 12)
            if style % 4 == 2 {
                Circle().fill(swatch.second).frame(width: 10)
            }
            if style % 4 == 3 {
                HStack(spacing: 2) {
                    Capsule().fill(swatch.second).frame(width: 2, height: 8)
                    Capsule().fill(swatch.second).frame(width: 2, height: 8)
                    Capsule().fill(swatch.second).frame(width: 2, height: 8)
                }
                .offset(x: 14, y: 22)
            }
            if style % 4 == 0 {
                ShopMark(swatch: swatch, size: 6).offset(x: -10)
            }
        }
    }
}

struct ShopPinPiece: View {
    var item: ItemDef
    var swatch: ShopSwatch

    private var motif: String {
        let id = item.id
        if id.contains("bell") { return "bell" }
        if id.contains("heart") { return "heart" }
        if id.contains("flower") || id.contains("blossom") { return "flower" }
        if id.contains("moon") { return "moon" }
        if id.contains("star") || id.contains("spark") { return "star" }
        if id.contains("cane") || id.contains("stick") || id.contains("wand") || id.contains("staff") { return "cane" }
        return "pin"
    }

    var body: some View {
        ZStack {
            switch motif {
            case "cane":
                Capsule().fill(swatch.primary).frame(width: 6, height: 36).rotationEffect(.degrees(18))
                Capsule().fill(swatch.second).frame(width: 16, height: 6).rotationEffect(.degrees(-20)).offset(x: 4, y: -16)
                Circle().fill(swatch.second).frame(width: 7).offset(x: 10, y: -18)
                Capsule().fill(Color.black.opacity(0.18)).frame(width: 10, height: 3).offset(y: 16)
            case "bell":
                Capsule().fill(swatch.primary).frame(width: 22, height: 20).offset(y: -2)
                Ellipse().fill(swatch.primary).frame(width: 26, height: 10).offset(y: 8)
                Circle().fill(swatch.second).frame(width: 6).offset(y: 12)
            case "heart":
                ShopHeartShape().fill(swatch.primary).frame(width: 26, height: 24)
            case "flower":
                Circle().fill(swatch.primary).frame(width: 12).offset(y: -10)
                Circle().fill(swatch.primary).frame(width: 12).offset(x: 9, y: -3)
                Circle().fill(swatch.primary).frame(width: 12).offset(x: 6, y: 8)
                Circle().fill(swatch.primary).frame(width: 12).offset(x: -6, y: 8)
                Circle().fill(swatch.primary).frame(width: 12).offset(x: -9, y: -3)
                Circle().fill(swatch.second).frame(width: 10)
            case "moon":
                Circle().fill(swatch.primary).frame(width: 26)
                Circle().fill(Theme.cream).frame(width: 20).offset(x: 8, y: -2)
            case "star":
                RoundedRectangle(cornerRadius: 2).fill(swatch.primary).frame(width: 12, height: 12).rotationEffect(.degrees(45))
                Capsule().fill(swatch.second).frame(width: 4, height: 22)
                Capsule().fill(swatch.second).frame(width: 4, height: 22).rotationEffect(.degrees(90))
            default:
                Circle().fill(swatch.primary).frame(width: 16)
                Capsule().fill(swatch.second).frame(width: 4, height: 16).offset(y: 12)
                ShopMark(swatch: swatch, size: 6).offset(y: -2)
            }
        }
    }
}

struct ShopFurHead: View {
    var item: ItemDef

    private var fur: FurPaint { FurPaint.resolve(item.id) }

    var body: some View {
        ZStack {
            ear(-1)
            ear(1)
            Circle().fill(fur.shade).frame(width: 44).offset(y: 2)
            Circle().fill(fur.body).frame(width: 44)
            Circle().fill(fur.cheek).frame(width: item.style == 1 ? 10 : 8).offset(x: -12, y: 6)
            Circle().fill(fur.cheek).frame(width: item.style == 1 ? 10 : 8).offset(x: 12, y: 6)
            Circle().fill(Theme.ink).frame(width: 4).offset(x: -8, y: -1)
            Circle().fill(Theme.ink).frame(width: 4).offset(x: 8, y: -1)
            Ellipse().fill(Color(hex: 0xFF9BB8)).frame(width: 7, height: 5).offset(y: 6)
            if item.style == 2 {
                Ellipse().fill(fur.shade).frame(width: 16, height: 8).offset(y: -18)
            }
            if item.style == 3 {
                Circle().fill(Color(hex: 0xE989B0)).frame(width: 6).offset(x: -5, y: 16)
                Circle().fill(Color(hex: 0xE989B0)).frame(width: 6).offset(x: 5, y: 16)
            }
            if item.style >= 4 {
                Circle().fill(fur.shade).frame(width: 5).offset(x: -14, y: 12)
                Circle().fill(fur.shade).frame(width: 5).offset(x: 14, y: 12)
                Circle().fill(fur.shade).frame(width: 4).offset(y: 14)
            }
        }
    }

    private func ear(_ side: CGFloat) -> some View {
        ZStack {
            Capsule().fill(fur.shade).frame(width: 12, height: 26)
            Capsule().fill(fur.innerEar).frame(width: 6, height: 14).offset(y: 2)
        }
        .rotationEffect(.degrees(Double(side) * 16))
        .offset(x: side * 14, y: -26)
    }
}

struct ShopTicketPiece: View {
    var item: ItemDef
    var swatch: ShopSwatch

    private var motif: String {
        let id = item.id
        if id.contains("cherry") { return "blossom" }
        if id.contains("crystal") { return "gem" }
        if id.contains("beach") { return "sun" }
        if id.contains("sugar") { return "heart" }
        if id.contains("cloud") { return "cloud" }
        if id.contains("star") { return "star" }
        if id.contains("moon") { return "moon" }
        if id.contains("snow") { return "snow" }
        return "leaf"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.cream)
                .frame(width: 46, height: 30)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(swatch.primary)
                .frame(width: 16, height: 30)
                .offset(x: -15)
            motifView.offset(x: 8)
            Circle().stroke(swatch.second, lineWidth: 1.5).frame(width: 6).offset(x: 18)
        }
    }

    @ViewBuilder
    private var motifView: some View {
        switch motif {
        case "blossom":
            Circle().fill(swatch.second).frame(width: 8)
            Circle().fill(Color(hex: 0xFF8FB3)).frame(width: 4).offset(x: -4, y: -3)
            Circle().fill(Color(hex: 0xFF8FB3)).frame(width: 4).offset(x: 4, y: -2)
        case "gem":
            RoundedRectangle(cornerRadius: 1).fill(swatch.second).frame(width: 10, height: 10).rotationEffect(.degrees(45))
        case "sun":
            Circle().fill(Color(hex: 0xFFE56A)).frame(width: 10)
            Capsule().fill(Color(hex: 0xFFE56A)).frame(width: 2, height: 6).offset(y: -8)
        case "heart":
            ShopHeartShape().fill(Color(hex: 0xFF8FB3)).frame(width: 12, height: 11)
        case "cloud":
            Circle().fill(.white).frame(width: 8).offset(x: -3)
            Circle().fill(.white).frame(width: 10).offset(x: 3, y: 1)
        case "star":
            RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0xFFE56A)).frame(width: 8, height: 8).rotationEffect(.degrees(45))
        case "moon":
            Circle().fill(Color(hex: 0xFFE7AD)).frame(width: 12)
            Circle().fill(Theme.cream).frame(width: 9).offset(x: 3)
        case "snow":
            Capsule().fill(Color(hex: 0xE7F4FF)).frame(width: 2, height: 12)
            Capsule().fill(Color(hex: 0xE7F4FF)).frame(width: 2, height: 12).rotationEffect(.degrees(60))
            Capsule().fill(Color(hex: 0xE7F4FF)).frame(width: 2, height: 12).rotationEffect(.degrees(120))
        default:
            Ellipse().fill(Color(hex: 0x7BB65C)).frame(width: 8, height: 12).rotationEffect(.degrees(-30))
        }
    }
}

struct ShopCharmPiece: View {
    var swatch: ShopSwatch
    var style: Int

    var body: some View {
        ZStack {
            Circle().fill(swatch.primary).frame(width: 22)
            Circle().fill(swatch.second).frame(width: style % 2 == 0 ? 8 : 12)
            ShopMark(swatch: swatch, size: 6).offset(y: 14)
        }
    }
}
