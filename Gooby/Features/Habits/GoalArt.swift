import SwiftUI

enum GoalLook {
    static var green: Color { Paint.pick(0x7BB65C) { $0.home } }
    static var button: Color { Paint.pick(0x69A148) { $0.homeButton } }
    static var plusDisc: Color { Paint.pick(0x8FCB74) { HexMix.tint($0.home, 0.15) } }
    static var wave: Color { Paint.pick(0x70AD4E) { $0.homeDeep } }
    static var ink: Color { Paint.pick(0x2C2C2C) { $0.ink } }
    static var energy: Color { Paint.pick(0x6E7478) { $0.inkSoft } }
    static var subtitle: Color { Paint.pick(0x9AA3AB) { $0.inkFaint } }
    static var bolt: Color { Paint.pick(0xFCAC34) { $0.energy } }
    static var check: Color { Paint.pick(0x3EAE45) { $0.success } }
    static var paper: Color { Paint.pick(0xF6F3EC) { $0.page } }
    static var plate: Color { Paint.pick(0xF0F0F0) { $0.well } }
    static var card: Color { Paint.pick(0xFFFFFF) { $0.card } }
    static var muted: Color { Paint.pick(0x8E8E93) { $0.inkFaint } }
    static var plateShade: Color { Paint.pick(0xD6D6D6) { $0.isDark ? HexMix.shade($0.well, 0.35) : HexMix.mix($0.well, $0.inkFaint, 0.4) } }
    static var plateEdge: Color { Paint.pick(0xD0D0D0) { $0.isDark ? $0.line : HexMix.mix($0.well, $0.inkFaint, 0.55) } }
    static let sheet = Color(hex: 0x8ED56C)
    static let purple = Color(hex: 0x7A5CFF)
    static let purpleDeep = Color(hex: 0x6846F0)
    static let teaPlate = Color(hex: 0x78B45A)
    static let line = Color.white.opacity(0.55)
    static let cardRadius: CGFloat = 22
}

enum GoalArt {
    /// SF Symbol names stay the stored `Habit.icon` value so other screens can still read it.
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
        case "figure.mind.and.body": return "yoga"
        case "fork.knife": return "plate"
        case "scope": return "target"
        case "hands.clap.fill": return "hands"
        default: return "star"
        }
    }

    static func plate(for glyph: String) -> Color {
        glyph == "tea" ? GoalLook.teaPlate : GoalLook.plate
    }
}

/// A sticker on its soft blob plate. Pass `plate` to tint the blob, or hide it for bare stickers.
struct GoalGlyph: View {
    var glyph: String
    var showsPlate: Bool = true
    var plate: Color? = nil

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                if showsPlate {
                    GoalPlate().fill(plate ?? GoalArt.plate(for: glyph))
                }
                GoalSticker(glyph: glyph)
                    .scaleEffect(side * (showsPlate ? 0.8 : 0.9) / 40)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }
}

struct GoalPlate: Shape {
    func path(in rect: CGRect) -> Path {
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var path = Path()
        path.move(to: at(0.5, 0.02))
        path.addCurve(to: at(0.98, 0.47), control1: at(0.8, 0.02), control2: at(0.97, 0.12))
        path.addCurve(to: at(0.52, 0.98), control1: at(0.99, 0.8), control2: at(0.84, 0.98))
        path.addCurve(to: at(0.02, 0.52), control1: at(0.18, 0.98), control2: at(0.02, 0.84))
        path.addCurve(to: at(0.5, 0.02), control1: at(0.02, 0.17), control2: at(0.2, 0.02))
        path.closeSubpath()
        return path
    }
}

struct EnergyBolt: View {
    var body: some View {
        GoalBoltShape()
            .fill(GoalLook.bolt)
            .frame(width: 13, height: 18)
            .accessibilityHidden(true)
    }
}

struct GoalBoltShape: Shape {
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

struct GoalArrowKey: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: 0xD6D6D6))
                .offset(y: 3)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: 0xF0F0F0))
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: 0x53A34C))
        }
        .accessibilityHidden(true)
    }
}

struct CheckKey: View {
    var done: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(GoalLook.plateShade)
                .offset(y: 3)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(GoalLook.plate)
            TickMark()
                .stroke(done ? GoalLook.check : GoalLook.plateEdge, style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round))
                .frame(width: 17, height: 14)
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
        .frame(width: 8)
        .accessibilityHidden(true)
    }
}

struct MenuBlob: View {
    var body: some View {
        VStack(spacing: 3.5) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule().fill(Color(hex: 0xA2AEBA)).frame(width: 25, height: 5.5)
            }
        }
        .stickerRim(3)
        .frame(width: 42, height: 34)
    }
}

struct PetFaceButton: View {
    var body: some View {
        GoalSticker(glyph: "face")
            .scaleEffect(0.9)
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)
    }
}

struct RocketMark: View {
    var body: some View {
        GoalGlyph(glyph: "rocket", showsPlate: false)
    }
}

struct GoalAddMark: View {
    var added: Bool

    var body: some View {
        ZStack {
            Circle().fill(added ? GoalLook.check : GoalLook.button)
            if added {
                TickMark()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 12, height: 10)
            } else {
                PlusMark().fill(Color.white).frame(width: 13, height: 13)
            }
        }
        .frame(width: 32, height: 32)
    }
}

struct PlusMark: Shape {
    func path(in rect: CGRect) -> Path {
        let bar = min(rect.width, rect.height) * 0.24
        let corner = CGSize(width: bar / 2, height: bar / 2)
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.midX - bar / 2, y: rect.minY, width: bar, height: rect.height), cornerSize: corner)
        path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.midY - bar / 2, width: rect.width, height: bar), cornerSize: corner)
        return path
    }
}

struct TickMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

struct ChevronMark: Shape {
    enum Direction { case down, left, right }
    var direction: Direction

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch direction {
        case .down:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        case .left:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .right:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        return path
    }
}

struct SearchMark: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let lens = side * 0.68
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY, width: lens, height: lens))
        path.move(to: CGPoint(x: rect.minX + lens * 0.86, y: rect.minY + lens * 0.86))
        path.addLine(to: CGPoint(x: rect.minX + side, y: rect.minY + side))
        return path
    }
}

struct TrashMark: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.2))
        path.move(to: CGPoint(x: rect.minX + w * 0.36, y: rect.minY + h * 0.2))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.4, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.6, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.64, y: rect.minY + h * 0.2))
        path.addRoundedRect(in: CGRect(x: rect.minX + w * 0.12, y: rect.minY + h * 0.2, width: w * 0.76, height: h * 0.8), cornerSize: CGSize(width: w * 0.12, height: w * 0.12))
        return path
    }
}

struct StarMark: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.04)
        let outer = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<10 {
            let radius = index.isMultiple(of: 2) ? outer : outer * 0.46
            let angle = (-90 + Double(index) * 36) * .pi / 180
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// The darker ribbon that crosses the list above the support card.
struct GoalWave: Shape {
    func path(in rect: CGRect) -> Path {
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var path = Path()
        path.move(to: at(0, 0.04))
        path.addCurve(to: at(1, 0.3), control1: at(0.33, -0.04), control2: at(0.66, 0.12))
        path.addLine(to: at(1, 0.66))
        path.addCurve(to: at(0, 0.96), control1: at(0.66, 0.6), control2: at(0.33, 0.78))
        path.closeSubpath()
        return path
    }
}
