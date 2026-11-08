import SwiftUI

enum GoalLook {
    static let green = Color(hex: 0x7BB65C)
    static let button = Color(hex: 0x69A148)
    static let plusDisc = Color(hex: 0x8FCB74)
    static let ink = Color(hex: 0x2C2C2C)
    static let energy = Color(hex: 0x6E7478)
    static let subtitle = Color(hex: 0x9AA3AB)
    static let bolt = Color(hex: 0xFCAC34)
    static let check = Color(hex: 0x3EAE45)
    static let paper = Color(hex: 0xF6F3EC)
    static let line = Color.white.opacity(0.85)
    static let cardRadius: CGFloat = 22
}

enum GoalArt {
    static func symbol(for glyph: String) -> String {
        switch glyph {
        case "bed": return "bed.double.fill"
        case "giraffe": return "figure.flexibility"
        case "leaf": return "wind"
        case "smile": return "face.smiling.fill"
        case "tea": return "cup.and.saucer.fill"
        case "drop": return "drop.fill"
        case "walk": return "figure.walk"
        case "moon": return "moon.fill"
        case "shower": return "shower.fill"
        case "heart": return "heart.fill"
        case "people": return "person.2.fill"
        case "sun": return "sun.max.fill"
        case "home": return "house.fill"
        case "note": return "pencil"
        case "phone": return "iphone"
        case "star": return "star.fill"
        case "hands": return "hands.clap.fill"
        case "broom": return "sparkles"
        case "mail": return "envelope.fill"
        case "yoga": return "figure.mind.and.body"
        case "plate": return "fork.knife"
        case "book": return "book.fill"
        case "flower": return "leaf.fill"
        case "timer": return "timer"
        case "gift": return "gift.fill"
        case "shirt": return "tshirt.fill"
        case "mirror": return "face.smiling"
        case "apple": return "fork.knife"
        case "bolt": return "bolt.fill"
        case "sparkle": return "sparkles"
        case "target": return "scope"
        default: return "checkmark.circle.fill"
        }
    }

    static func glyph(forSymbol symbol: String) -> String {
        switch symbol {
        case "bed.double.fill": return "bed"
        case "figure.flexibility": return "giraffe"
        case "wind": return "leaf"
        case "face.smiling.fill", "face.smiling": return "smile"
        case "cup.and.saucer.fill": return "tea"
        case "drop.fill": return "drop"
        case "figure.walk": return "walk"
        case "moon.fill": return "moon"
        case "shower.fill": return "shower"
        case "heart.fill": return "heart"
        case "person.2.fill": return "people"
        case "sun.max.fill": return "sun"
        case "house.fill": return "home"
        case "pencil": return "note"
        case "iphone": return "phone"
        case "star.fill": return "star"
        case "envelope.fill": return "mail"
        case "book.fill": return "book"
        case "leaf.fill": return "flower"
        case "timer": return "timer"
        case "gift.fill": return "gift"
        case "tshirt.fill": return "shirt"
        case "bolt.fill": return "bolt"
        default: return "star"
        }
    }
}

struct GoalGlyph: View {
    var glyph: String
    var showsPlate: Bool = true

    var body: some View {
        ZStack {
            if showsPlate { plate }
            artwork
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder private var plate: some View {
        switch glyph {
        case "tea":
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0x7EBF62))
        case "smile":
            Circle().fill(Color(hex: 0xF6C431))
        case "giraffe", "leaf", "bed":
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0xF1F1F1))
        default:
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0xF3F1EC))
        }
    }

    @ViewBuilder private var artwork: some View {
        switch glyph {
        case "giraffe": GiraffeMark()
        case "leaf": LeafMark()
        case "smile": SmileMark(onYellow: true)
        case "tea": TeaMark()
        case "bed": BedMark()
        case "drop": DropMark()
        case "walk": WalkMark()
        case "moon": MoonMark()
        case "shower": ShowerMark()
        case "heart": HeartMark()
        case "people": PeopleMark()
        case "sun": SunMark()
        case "home": HomeMark()
        case "note": NoteMark()
        case "phone": PhoneMark()
        case "star": StarMark()
        case "hands": HandsMark()
        case "mail": MailMark()
        case "plate", "apple": PlateMark()
        case "book": BookMark()
        case "flower": FlowerMark()
        case "timer": TimerMark()
        case "gift": GiftMark()
        case "shirt": ShirtMark()
        case "bolt", "yoga": BoltMark()
        case "sparkle", "broom", "target", "mirror": SparkMark()
        default: SparkMark()
        }
    }
}

struct EnergyBolt: View {
    var body: some View {
        BoltShape()
            .fill(GoalLook.bolt)
            .frame(width: 13, height: 18)
            .accessibilityHidden(true)
    }
}

struct BoltShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.minX + w * 0.62, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.48, y: rect.minY + h * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.30, y: rect.minY + h))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.92, y: rect.minY + h * 0.38))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.38))
        path.closeSubpath()
        return path
    }
}

struct CheckKey: View {
    var done: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: 0xE4E4E4))
                .offset(y: 3)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(done ? GoalLook.check : Color(hex: 0xD0D0D0))
        }
    }
}

struct GripDots: View {
    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                Circle().fill(Color(hex: 0xC8C8C8)).frame(width: 4.5, height: 4.5)
            }
        }
        .frame(width: 14)
        .accessibilityHidden(true)
    }
}

struct MenuBlob: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.white)
            .frame(width: 42, height: 34)
            .overlay {
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(Color(hex: 0xC5C8CC)).frame(width: 18, height: 3)
                    }
                }
            }
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct PetFaceButton: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 46, height: 46)
            Circle().fill(Color(hex: 0xF8C850)).frame(width: 38, height: 38)
            SmileMark(onYellow: true).frame(width: 28, height: 28)
        }
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }
}

private struct GiraffeMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xF0A33A)).frame(width: 8, height: 20).offset(x: -1, y: -6)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(hex: 0xF0A33A))
                .frame(width: 16, height: 13)
                .offset(y: 6)
            Circle().fill(Color(hex: 0xF0A33A)).frame(width: 12, height: 12).offset(x: -1, y: -15)
            Capsule().fill(Color(hex: 0xE0892A)).frame(width: 2, height: 5).offset(x: -4, y: -21)
            Capsule().fill(Color(hex: 0xE0892A)).frame(width: 2, height: 5).offset(x: 2, y: -21)
            Circle().fill(Color(hex: 0xE0892A)).frame(width: 3.5).offset(x: -4, y: -24)
            Circle().fill(Color(hex: 0xE0892A)).frame(width: 3.5).offset(x: 2, y: -24)
            Circle().fill(Color(hex: 0x3A2A1A)).frame(width: 2).offset(x: -3, y: -16)
            Circle().fill(Color(hex: 0xC47A22)).frame(width: 4).offset(x: 3, y: 4)
            Circle().fill(Color(hex: 0xC47A22)).frame(width: 3).offset(x: -2, y: 8)
            HStack(spacing: 2) {
                Capsule().fill(Color(hex: 0x3A2A1A)).frame(width: 2.4, height: 8)
                Capsule().fill(Color(hex: 0x3A2A1A)).frame(width: 2.4, height: 8)
            }
            .offset(y: 14)
            Capsule().fill(Color(hex: 0x3A2A1A)).frame(width: 7, height: 2).rotationEffect(.degrees(-30)).offset(x: 10, y: 6)
        }
        .frame(width: 36, height: 40)
    }
}

private struct LeafMark: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: 0x7BC85A))
                .frame(width: 22, height: 16)
                .rotationEffect(.degrees(-28))
            Ellipse()
                .fill(Color(hex: 0x3E8C32))
                .frame(width: 2, height: 14)
                .rotationEffect(.degrees(-28))
            Capsule().stroke(Color(hex: 0x7EB6E8), lineWidth: 1.6).frame(width: 8, height: 5).offset(x: 8, y: -8)
            Capsule().stroke(Color(hex: 0x7EB6E8), lineWidth: 1.6).frame(width: 7, height: 4).offset(x: 11, y: -2)
            Capsule().stroke(Color(hex: 0x7EB6E8), lineWidth: 1.6).frame(width: 6, height: 3.5).offset(x: 9, y: 4)
        }
    }
}

private struct SmileMark: View {
    var onYellow: Bool
    var body: some View {
        ZStack {
            if !onYellow {
                Circle().fill(Color(hex: 0xF6C431))
            }
            HStack(spacing: 6) {
                Circle().fill(Color(hex: 0x3A2A1A)).frame(width: 3.2, height: 3.2)
                Circle().fill(Color(hex: 0x3A2A1A)).frame(width: 3.2, height: 3.2)
            }
            .offset(y: -2)
            SmileArc().stroke(Color(hex: 0x3A2A1A), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 12, height: 7)
                .offset(y: 5)
        }
    }
}

private struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.minY), radius: rect.width * 0.45, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
        return path
    }
}

private struct TeaMark: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x5C5C5C)).frame(width: 26, height: 8).offset(y: 10)
            Ellipse().fill(Color.white).frame(width: 24, height: 16).offset(y: 4)
            Ellipse().fill(Color(hex: 0xD8F5C4)).frame(width: 18, height: 8).offset(y: 1)
            Capsule().stroke(Color(hex: 0xF4FFF0), lineWidth: 1.4).frame(width: 3, height: 7).offset(x: -4, y: -8)
            Capsule().stroke(Color(hex: 0xF4FFF0), lineWidth: 1.4).frame(width: 3, height: 8).offset(x: 3, y: -9)
        }
    }
}

private struct BedMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x8E7CC3)).frame(width: 26, height: 8).offset(y: 8)
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xF7F4EA)).frame(width: 10, height: 12).offset(x: -8, y: 1)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xD9D0F2)).frame(width: 16, height: 8).offset(x: 4, y: 3)
        }
    }
}

private struct DropMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x7EB6E8)).frame(width: 16, height: 16).offset(y: 3)
            DropTop().fill(Color(hex: 0x7EB6E8)).frame(width: 12, height: 12).offset(y: -6)
        }
    }
}

private struct DropTop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.midY))
        return path
    }
}

private struct WalkMark: View {
    var body: some View {
        Image(systemName: "figure.walk").font(.system(size: 22, weight: .bold)).foregroundStyle(Color(hex: 0xE07A3D))
    }
}

private struct MoonMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF6D56A)).frame(width: 18, height: 18)
            Circle().fill(Color(hex: 0xF3F1EC)).frame(width: 14, height: 14).offset(x: 5, y: -3)
        }
    }
}

private struct ShowerMark: View {
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "shower.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Color(hex: 0x5AA4D6))
        }
    }
}

private struct HeartMark: View {
    var body: some View {
        Image(systemName: "heart.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Color(hex: 0xE46B8A))
    }
}

private struct PeopleMark: View {
    var body: some View {
        Image(systemName: "person.2.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: 0xE07A5F))
    }
}

private struct SunMark: View {
    var body: some View {
        Image(systemName: "sun.max.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Color(hex: 0xF0A202))
    }
}

private struct HomeMark: View {
    var body: some View {
        Image(systemName: "house.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Color(hex: 0xC4A574))
    }
}

private struct NoteMark: View {
    var body: some View {
        Image(systemName: "pencil").font(.system(size: 18, weight: .bold)).foregroundStyle(Color(hex: 0x6B7C93))
    }
}

private struct PhoneMark: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .stroke(Color(hex: 0x5C6B7A), lineWidth: 1.6)
            .frame(width: 12, height: 18)
            .overlay(Circle().fill(Color(hex: 0x5C6B7A)).frame(width: 2, height: 2).offset(y: 6))
    }
}

private struct StarMark: View {
    var body: some View {
        Image(systemName: "star.fill").font(.system(size: 18, weight: .bold)).foregroundStyle(Color(hex: 0xE2B43A))
    }
}

private struct HandsMark: View {
    var body: some View {
        Image(systemName: "hands.clap.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: 0xE08A4F))
    }
}

private struct MailMark: View {
    var body: some View {
        Image(systemName: "envelope.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: 0x6C8EBF))
    }
}

private struct PlateMark: View {
    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: 0xE07A3D), lineWidth: 2).frame(width: 18, height: 18)
            Circle().fill(Color(hex: 0xF6C14A)).frame(width: 8, height: 8)
        }
    }
}

private struct BookMark: View {
    var body: some View {
        Image(systemName: "book.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: 0x7A6BB5))
    }
}

private struct FlowerMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF2A3C0)).frame(width: 8, height: 8).offset(y: -5)
            Circle().fill(Color(hex: 0xF2A3C0)).frame(width: 8, height: 8).offset(x: 5)
            Circle().fill(Color(hex: 0xF2A3C0)).frame(width: 8, height: 8).offset(x: -5)
            Circle().fill(Color(hex: 0xF6D56A)).frame(width: 6, height: 6)
            Capsule().fill(Color(hex: 0x7BC85A)).frame(width: 2, height: 8).offset(y: 8)
        }
    }
}

private struct TimerMark: View {
    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: 0xE08A4F), lineWidth: 2).frame(width: 18, height: 18)
            Capsule().fill(Color(hex: 0xE08A4F)).frame(width: 2, height: 6).offset(y: -2)
        }
    }
}

private struct GiftMark: View {
    var body: some View {
        Image(systemName: "gift.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: 0xE06B8A))
    }
}

private struct ShirtMark: View {
    var body: some View {
        Image(systemName: "tshirt.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: 0x6AA8D8))
    }
}

private struct BoltMark: View {
    var body: some View {
        EnergyBolt().scaleEffect(1.15)
    }
}

private struct SparkMark: View {
    var body: some View {
        Image(systemName: "sparkles").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: 0xE2B43A))
    }
}

struct RocketMark: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x4C8DFF)).frame(width: 16, height: 28).offset(y: -2)
            Circle().fill(Color(hex: 0xD7E6FF)).frame(width: 8, height: 8).offset(y: -4)
            Triangle().fill(Color(hex: 0xFF5A5A)).frame(width: 10, height: 10).offset(x: -10, y: 6)
            Triangle().fill(Color(hex: 0xFF5A5A)).frame(width: 10, height: 10).scaleEffect(x: -1).offset(x: 10, y: 6)
            Ellipse().fill(Color(hex: 0xFFD15C)).frame(width: 8, height: 6).offset(y: 16)
        }
        .frame(width: 36, height: 40)
        .accessibilityHidden(true)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
