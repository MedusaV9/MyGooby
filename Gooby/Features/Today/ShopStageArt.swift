import SwiftUI

enum ShopFloor: String, CaseIterable, Identifiable {
    case clothes
    case furniture

    var id: String { rawValue }
}

struct ShopFloorPaint {
    var screen: Color
    var sheet: Color
    var cell: Color
    var ink: Color
    var badge: Color
    var lightStatus: Bool

    static let clothes = ShopFloorPaint(
        screen: Color(hex: 0x6846D4),
        sheet: Color(hex: 0x5636B4),
        cell: Color(hex: 0x7354DE),
        ink: .white,
        badge: Color(hex: 0xFF8A34),
        lightStatus: true
    )

    static let furniture = ShopFloorPaint(
        screen: Color(hex: 0xB56E3A),
        sheet: Color(hex: 0x7E4E28),
        cell: Color(hex: 0x9A6236),
        ink: .white,
        badge: Color(hex: 0xF0B429),
        lightStatus: true
    )

    static func season(_ id: String) -> ShopFloorPaint {
        switch id {
        case "starry-nights":
            return dark(screen: 0x2C3A78, sheet: 0x243268, cell: 0x3A4C96, badge: 0xF0B429)
        case "winter", "winter-warmth":
            return light(screen: 0xD7ECFF, sheet: 0xB9D8F5, cell: 0xE7F4FF, ink: 0x1C3E5C, badge: 0x5E97D4)
        case "spring", "spring-meadow", "cherry", "blossom-week":
            return light(screen: 0xFFD0E4, sheet: 0xF3B0D0, cell: 0xFFE3F0, ink: 0x5A2444, badge: 0xE07AA8)
        case "rainbow-week":
            return light(screen: 0xE7D6FF, sheet: 0xD4C2F8, cell: 0xF3EAFF, ink: 0x3A2A55, badge: 0x8A6AD4)
        case "autumn", "harvest", "leaf-walk":
            return light(screen: 0xFFC27A, sheet: 0xF0A24A, cell: 0xFFD7A8, ink: 0x4A2A10, badge: 0xE07A20)
        case "newyear", "new-year-sparkle":
            return light(screen: 0xFFE7A0, sheet: 0xF0D060, cell: 0xFFF4CC, ink: 0x4A3810, badge: 0xE0A020)
        default:
            return light(screen: 0xFFE38A, sheet: 0xF6D15A, cell: 0xFFF1B8, ink: 0x4A3412, badge: 0xFF8A34)
        }
    }

    private static func light(screen: UInt32, sheet: UInt32, cell: UInt32, ink: UInt32, badge: UInt32) -> ShopFloorPaint {
        ShopFloorPaint(
            screen: Color(hex: screen),
            sheet: Color(hex: sheet),
            cell: Color(hex: cell),
            ink: Color(hex: ink),
            badge: Color(hex: badge),
            lightStatus: false
        )
    }

    private static func dark(screen: UInt32, sheet: UInt32, cell: UInt32, badge: UInt32) -> ShopFloorPaint {
        ShopFloorPaint(
            screen: Color(hex: screen),
            sheet: Color(hex: sheet),
            cell: Color(hex: cell),
            ink: .white,
            badge: Color(hex: badge),
            lightStatus: true
        )
    }
}

struct ShopGem: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let midY = rect.midY
        let width = rect.width * 0.42
        let height = rect.height * 0.48
        path.move(to: CGPoint(x: midX, y: midY - height))
        path.addLine(to: CGPoint(x: midX + width, y: midY - height * 0.15))
        path.addLine(to: CGPoint(x: midX + width * 0.62, y: midY + height))
        path.addLine(to: CGPoint(x: midX - width * 0.62, y: midY + height))
        path.addLine(to: CGPoint(x: midX - width, y: midY - height * 0.15))
        path.closeSubpath()
        return path
    }
}

struct ShopStoneGlyph: View {
    var body: some View {
        ZStack {
            ShopGem().fill(Color(hex: 0x7FD3FF))
            ShopGem().fill(Color(hex: 0xFFE56A)).scaleEffect(0.72)
            ShopGem().fill(Color(hex: 0xFF8FB8)).scaleEffect(0.4)
            ShopGem().fill(Color.white.opacity(0.7)).scaleEffect(0.16).offset(x: -2, y: -3)
        }
        .accessibilityHidden(true)
    }
}

struct ShopStonePill: View {
    var count: Int
    var spoken: String

    var body: some View {
        HStack(spacing: 6) {
            ShopStoneGlyph()
                .frame(width: 22, height: 22)
            Text("\(count)")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}

struct ShopSparkle: View {
    var color: Color

    var body: some View {
        ZStack {
            Capsule().fill(color).frame(width: 3, height: 14)
            Capsule().fill(color).frame(width: 3, height: 14).rotationEffect(.degrees(90))
            Capsule().fill(color).frame(width: 2, height: 8).rotationEffect(.degrees(45))
            Capsule().fill(color).frame(width: 2, height: 8).rotationEffect(.degrees(-45))
        }
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
    }
}

struct ShopRefreshMark: View {
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.12, to: 0.78)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            Circle()
                .fill(Color.white)
                .frame(width: 3.2, height: 3.2)
                .offset(x: 4.6, y: -2.4)
        }
        .frame(width: 13, height: 13)
        .accessibilityHidden(true)
    }
}

struct ShopCheckMark: View {
    var ink: Color

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 2, y: 7))
            path.addLine(to: CGPoint(x: 6, y: 11))
            path.addLine(to: CGPoint(x: 13, y: 3))
        }
        .stroke(ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: 14, height: 14)
        .accessibilityHidden(true)
    }
}

struct ShopLockMark: View {
    var ink: Color

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 8, height: 8)
                .offset(y: -4)
            RoundedRectangle(cornerRadius: 2)
                .fill(ink)
                .frame(width: 12, height: 8)
                .offset(y: 3)
        }
        .frame(width: 14, height: 16)
        .accessibilityHidden(true)
    }
}

struct ShopCollectionHeader: View {
    var title: String
    var subtitle: String?
    var ink: Color
    var badge: Color
    var freeTitle: String
    var showsFree: Bool
    var sparkle: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                if sparkle {
                    ShopSparkle(color: ink)
                }
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 6)
                if showsFree {
                    HStack(spacing: 4) {
                        Text(freeTitle)
                        ShopRefreshMark()
                    }
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(badge, in: Capsule())
                    .accessibilityHidden(true)
                }
            }
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(ink.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ShopHareEar: View {
    var side: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xF0D8C4)).frame(width: 14, height: 32)
            Capsule().fill(Color(hex: 0xFFC2D6)).frame(width: 7, height: 18).offset(y: 3)
        }
        .rotationEffect(.degrees(Double(side) * 18))
        .offset(x: side * 16, y: -46)
    }
}

struct ShopClerkLilo: View {
    var body: some View {
        ZStack {
            ShopHareEar(side: -1)
            ShopHareEar(side: 1)
            Ellipse().fill(Color(hex: 0xFFF6EA)).frame(width: 62, height: 50).offset(y: 34)
            Ellipse().fill(Color(hex: 0x7A5BE8)).frame(width: 40, height: 28).offset(y: 40)
            Circle().fill(Color(hex: 0xFFF6EA)).frame(width: 52).offset(y: -4)
            Circle().fill(Color(hex: 0xFFB7CC)).frame(width: 9).offset(x: -14, y: 2)
            Circle().fill(Color(hex: 0xFFB7CC)).frame(width: 9).offset(x: 14, y: 2)
            Circle().fill(Color(hex: 0x3D3656)).frame(width: 4.5).offset(x: -9, y: -6)
            Circle().fill(Color(hex: 0x3D3656)).frame(width: 4.5).offset(x: 9, y: -6)
            Ellipse().fill(Color(hex: 0xFF9BB8)).frame(width: 8, height: 6).offset(y: 4)
            Circle().stroke(Color(hex: 0x3D3656), lineWidth: 1.6).frame(width: 16).offset(x: -9, y: -6)
            Circle().stroke(Color(hex: 0x3D3656), lineWidth: 1.6).frame(width: 16).offset(x: 9, y: -6)
            Capsule().fill(Color(hex: 0x3D3656)).frame(width: 8, height: 1.6).offset(y: -6)
            Ellipse().fill(Color(hex: 0x6E4FE0)).frame(width: 40, height: 14).offset(y: -26)
            Circle().fill(Color(hex: 0x6E4FE0)).frame(width: 26).offset(y: -32)
            Circle().fill(Color(hex: 0xFFE7AD)).frame(width: 7).offset(x: 10, y: -38)
            Circle().fill(Color(hex: 0xE989B0)).frame(width: 9).offset(x: -7, y: 22)
            Circle().fill(Color(hex: 0xE989B0)).frame(width: 9).offset(x: 7, y: 22)
            Circle().fill(Color(hex: 0xC45B86)).frame(width: 5).offset(y: 22)
            Circle().fill(Color(hex: 0xFFF6EA)).frame(width: 14).offset(x: 36, y: 12)
        }
        .frame(width: 104, height: 128)
        .accessibilityHidden(true)
    }
}

struct ShopClerkFiete: View {
    var body: some View {
        ZStack {
            ShopHareEar(side: -1)
            ShopHareEar(side: 1)
            Ellipse().fill(Color(hex: 0xFFF6EA)).frame(width: 64, height: 52).offset(y: 34)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: 0x8E5A30))
                .frame(width: 36, height: 30)
                .offset(y: 40)
            Capsule().fill(Color(hex: 0xF0B429)).frame(width: 28, height: 6).offset(y: 28)
            Circle().fill(Color(hex: 0xFFF6EA)).frame(width: 52).offset(y: -4)
            Circle().fill(Color(hex: 0xFFB7CC)).frame(width: 9).offset(x: -14, y: 2)
            Circle().fill(Color(hex: 0xFFB7CC)).frame(width: 9).offset(x: 14, y: 2)
            Circle().fill(Color(hex: 0x3D3656)).frame(width: 4.5).offset(x: -9, y: -6)
            Circle().fill(Color(hex: 0x3D3656)).frame(width: 4.5).offset(x: 9, y: -6)
            Ellipse().fill(Color(hex: 0xFF9BB8)).frame(width: 8, height: 6).offset(y: 4)
            Capsule().fill(Color(hex: 0xC17A45)).frame(width: 34, height: 10).offset(y: -28)
            Capsule().fill(Color(hex: 0xFFE7AD)).frame(width: 5, height: 22).rotationEffect(.degrees(24)).offset(x: 16, y: -40)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x6B4428)).frame(width: 18, height: 10).offset(x: 38, y: 8)
            Rectangle().fill(Color(hex: 0xC17A45)).frame(width: 3, height: 16).offset(x: 38, y: 18)
            Circle().fill(Color(hex: 0xFFF6EA)).frame(width: 12).offset(x: -34, y: 24)
        }
        .frame(width: 104, height: 128)
        .accessibilityHidden(true)
    }
}

struct ShopKeeperRow: View {
    var clothes: Bool
    var name: String
    var line: String
    var accent: Color
    var still: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            keeper
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accent, in: Capsule())
                Text(line)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var keeper: some View {
        if still {
            art
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { timeline in
                let bob = CGFloat(sin(timeline.date.timeIntervalSinceReferenceDate * 1.5)) * 3
                art.offset(y: bob)
            }
        }
    }

    @ViewBuilder
    private var art: some View {
        if clothes {
            ShopClerkLilo()
        } else {
            ShopClerkFiete()
        }
    }
}

struct ShopFloorSwitch: View {
    @Binding var floor: ShopFloor
    var paint: ShopFloorPaint
    var clothesTitle: String
    var furnitureTitle: String

    var body: some View {
        HStack(spacing: 8) {
            button(.clothes, title: clothesTitle, slot: "shirt", color: "FFFDFB", second: "D3C2FF")
            button(.furniture, title: furnitureTitle, slot: "sofa", color: "FFFDFB", second: "E989B0")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(paint.sheet.ignoresSafeArea(edges: .bottom))
    }

    private func button(_ choice: ShopFloor, title: String, slot: String, color: String, second: String) -> some View {
        let selected = floor == choice
        return Button {
            floor = choice
        } label: {
            VStack(spacing: 1) {
                ShopItemGlyph(item: sample(slot: slot, color: color, second: second))
                    .frame(width: 64, height: 52)
                    .scaleEffect(0.62)
                    .frame(width: 46, height: 32)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(paint.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(paint.cell)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    private func sample(slot: String, color: String, second: String) -> ItemDef {
        ItemDef(
            id: "shop-floor-\(slot)",
            kind: slot == "sofa" ? "furniture" : "clothing",
            slot: slot,
            style: 0,
            price: 0,
            rarity: "common",
            color: color,
            color2: second,
            name: LocText(de: "", en: ""),
            blurb: LocText(de: "", en: ""),
            shop: slot == "sofa" ? "furniture" : "wardrobe",
            starter: false,
            seasonalEvent: ""
        )
    }
}
