import SwiftUI

struct ForestScene: View {
    var reduceMotion: Bool
    var look: WornLook
    var growth: String
    var companion: String?
    var animation: GoobyAnimation
    var walking: Bool
    var showPack: Bool
    var petLabel: String
    var petAction: String
    var onTap: () -> Void
    var onPet: () -> Void

    /// Drawn on a 402-point-wide screen from the top edge; taller frames get more meadow below.
    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / 402
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    var context = context
                    context.scaleBy(x: s, y: s)
                    ForestPaint.draw(&context, height: size.height / s)
                }
                .themedScene()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                ForestWalker(
                    reduceMotion: reduceMotion,
                    look: look,
                    growth: growth,
                    companion: companion,
                    animation: animation,
                    walking: walking,
                    showPack: showPack,
                    petLabel: petLabel,
                    petAction: petAction,
                    onTap: onTap,
                    onPet: onPet
                )
                .frame(width: 124 * s, height: 124 * s)
                .position(x: 203 * s, y: 263 * s)
            }
        }
        .clipped()
    }
}

extension ForestScene {
    init(reduceMotion: Bool, showHearts: Bool, look: WornLook = WornLook(), stage: String = "young", pet: @escaping () -> Void) {
        self.init(
            reduceMotion: reduceMotion,
            look: look,
            growth: stage,
            companion: nil,
            animation: showHearts ? .petting : .idle,
            walking: false,
            showPack: false,
            petLabel: "",
            petAction: "",
            onTap: pet,
            onPet: pet
        )
    }
}

/// The adventure forest in 402-point screen coordinates: the Finch frame 190.0s layout
/// in the palette of the Gooby forest reference (blue sky, olive crowns, birch, brown trunks, pines, hills).
private enum ForestPaint {
    static func draw(_ context: inout GraphicsContext, height: CGFloat) {
        let bottom = max(height, 400)
        context.fill(Path(CGRect(x: 0, y: 0, width: 402, height: bottom)), with: .color(Color(hex: 0x617CBF)))
        context.fill(Path(ellipseIn: CGRect(x: 297, y: 119, width: 42, height: 42)), with: .color(Color(hex: 0xFED072)))
        fill(&context, "M-10 176 C 50 150 120 160 190 178 C 250 152 330 146 412 168 L 412 400 L -10 400 Z", 0x9DBA68)
        fill(&context, "M-10 206 C 70 186 150 194 220 214 C 290 192 360 188 412 202 L 412 400 L -10 400 Z", 0x86A856)

        pine(&context, 334, 112, 1.5, 0x3A8C66)
        pine(&context, 384, 128, 1.45, 0x2F7D5A)
        pine(&context, 300, 150, 1.0, 0x3E8C64)
        pine(&context, 226, 96, 1.6, 0x3C9845)
        pine(&context, 22, 84, 1.9, 0x318635)
        pine(&context, 70, 64, 2.25, 0x3C9845)

        fill(&context, "M6 30 C 2 120 4 220 6 304 L 34 304 C 34 220 34 120 32 30 Z", 0xF1E2CD)
        fill(&context, "M24 30 C 26 120 26 220 26 304 L 34 304 C 34 220 34 120 32 30 Z", 0xE2D0B8)
        for mark in birchMarks {
            context.fill(Path(roundedRect: CGRect(x: mark.0, y: mark.1, width: mark.2, height: 3), cornerRadius: 1.5), with: .color(Color(hex: 0x6A5D55)))
        }
        context.fill(Path(ellipseIn: CGRect(x: 12, y: 142, width: 13, height: 19)), with: .color(Color(hex: 0x4A3528)))
        context.fill(Path(ellipseIn: CGRect(x: 15, y: 146, width: 7, height: 11)), with: .color(Color(hex: 0xFED085)))

        fill(&context, "M112 40 C 108 120 106 220 104 306 L 150 308 C 146 220 144 120 142 40 Z", 0xC08A50)
        stroke(&context, "M134 50 C 136 130 136 220 140 304", 0x93582E, 8)
        fill(&context, "M228 30 C 226 120 222 220 214 312 L 292 314 C 284 220 280 120 280 30 Z", 0xC9955A)
        stroke(&context, "M266 40 C 270 130 272 220 280 310", 0xA67149, 12)
        stroke(&context, "M270 120 C 290 96 312 80 336 62", 0xC9955A, 10)
        stroke(&context, "M236 140 C 220 124 204 116 186 112", 0xC9955A, 8)
        context.fill(Path(ellipseIn: CGRect(x: 245, y: 154, width: 18, height: 32)), with: .color(Color(hex: 0x6B4A30)))
        fill(&context, "M366 30 C 364 120 364 220 362 304 L 412 304 L 412 30 Z", 0xC08A50)
        stroke(&context, "M388 40 L 386 300", 0x93582E, 7)

        crown(&context, blobs: leftCrown, tuft: 24, back: 0x75822A, rim: 0x6F7C2A, mids: [0x8F9C3A, 0x98A436, 0x8F9C3A, 0xA5B22E], light: 0xB9C44A)
        crown(&context, blobs: rightCrown, tuft: 26, back: 0x75822A, rim: 0x6F7C2A, mids: [0x98A436, 0xA5B22E, 0x8F9C3A, 0xB0B92C], light: 0xC7CE4F)

        fill(&context, "M-10 300 C -14 262 10 236 40 244 C 56 222 96 224 108 246 C 128 244 140 266 134 300 Z", 0x2F7D5A)
        fill(&context, "M140 300 C 132 262 150 226 180 232 C 196 204 238 212 240 244 C 262 250 266 284 252 300 Z", 0xB7C85A)
        fill(&context, "M226 304 C 222 274 246 254 274 262 C 292 244 326 250 334 272 C 352 274 360 296 350 306 Z", 0x2D7246)
        fill(&context, "M316 300 C 306 266 330 236 360 244 C 376 226 410 232 412 250 L 412 300 Z", 0xADC549)
        for bloom in blooms {
            flower(&context, bloom.0, bloom.1, bloom.2)
        }
        fill(&context, "M-12 302 C -12 278 6 262 26 266 C 42 268 50 286 46 302 Z", 0xCFC1B8)
        context.fill(Path(ellipseIn: CGRect(x: 2, y: 268, width: 24, height: 8)), with: .color(Color(hex: 0xDDD3CC)))

        fill(&context, "M-10 298 C 70 290 180 296 260 300 C 320 302 370 296 412 298 L 412 \(bottom) L -10 \(bottom) Z", 0x73B556)
        fill(&context, "M-10 298 C 60 292 120 296 170 302 C 120 312 40 314 -10 312 Z", 0x5DA24C)
        mushroom(&context, 128, 262, 1.45)
        mushroom(&context, 96, 286, 0.75)
        fill(&context, "M330 350 C 326 330 344 318 362 324 C 378 312 404 318 412 330 L 412 350 Z", 0x2E7148)
        fill(&context, "M296 344 C 292 330 312 324 322 334 C 330 336 330 344 326 346 Z", 0xCFC1B8)
        for index in 0..<22 {
            let x = 6 + (index * 41) % 396
            let y = 312 + (index * 13) % 30
            stroke(&context, "M \(x) \(y + 10) L \(x + (index % 3) - 1) \(y)", 0x4E9A45, 1.8)
        }
        for bloom in meadowBlooms {
            flower(&context, bloom.0, bloom.1, bloom.2)
        }
        context.fill(Path(ellipseIn: CGRect(x: 166, y: 316, width: 74, height: 12)), with: .color(Color(hex: 0x5E9A47).opacity(0.55)))
    }

    private static let leftCrown: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (60, 18, 120, 58), (165, 40, 40, 22)
    ]

    private static let rightCrown: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (318, 12, 120, 58), (236, 38, 46, 26)
    ]

    private static let blooms: [(CGFloat, CGFloat, UInt32)] = [
        (322, 252, 0xE4502F), (352, 240, 0xE4502F), (374, 262, 0xE4502F), (160, 252, 0xE4502F),
        (344, 270, 0xFDD86A), (330, 284, 0xFDD86A), (198, 236, 0xFDD86A), (290, 270, 0xF7A3BE)
    ]

    private static let meadowBlooms: [(CGFloat, CGFloat, UInt32)] = [
        (40, 322, 0xE4502F), (112, 330, 0xF7A3BE), (262, 326, 0xFDD86A), (300, 316, 0xE4502F), (372, 312, 0xF7A3BE)
    ]

    private static let birchMarks: [(CGFloat, CGFloat, CGFloat)] = [
        (6, 52, 14), (18, 66, 12), (5, 82, 16), (20, 98, 10), (6, 114, 14),
        (19, 130, 12), (5, 170, 16), (20, 186, 10), (6, 202, 14), (18, 218, 12),
        (5, 234, 16), (20, 250, 10), (6, 266, 14), (18, 282, 12)
    ]

    private static func fill(_ context: inout GraphicsContext, _ d: String, _ hex: UInt32) {
        context.fill(SVGPath.path(d), with: .color(Color(hex: hex)))
    }

    private static func stroke(_ context: inout GraphicsContext, _ d: String, _ hex: UInt32, _ width: CGFloat) {
        context.stroke(SVGPath.path(d), with: .color(Color(hex: hex)), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// Fills the blobs (center x, center y, radius x, radius y) with tufts in three layers: a dense back mass,
    /// a middle layer whose tufts each carry a darker rim so they stay separate, and small light tufts on top.
    /// The back layer reaches about 1.15 × `tuft` beyond the blobs.
    private static func crown(_ context: inout GraphicsContext, blobs: [(CGFloat, CGFloat, CGFloat, CGFloat)], tuft: CGFloat, back: UInt32, rim: UInt32, mids: [UInt32], light: UInt32) {
        for spot in tuftSpots(blobs, spacing: tuft * 1.1) {
            context.fill(tuftPath(spot.0, spot.1, tuft * 1.15, spot.2), with: .color(Color(hex: back)))
        }
        for spot in tuftSpots(blobs, spacing: tuft * 1.25) {
            let x = spot.0
            let y = spot.1 - tuft * 0.25
            let radius = tuft * (0.88 + CGFloat(spot.2 * 7 % 5) * 0.06)
            context.fill(tuftPath(x + 2, y + 3, radius, spot.2), with: .color(Color(hex: rim)))
            context.fill(tuftPath(x, y, radius, spot.2), with: .color(Color(hex: mids[(spot.2 * 5 + spot.2 / 7) % mids.count])))
            if spot.2 % 3 == 0 {
                context.fill(tuftPath(x - radius * 0.36, y - radius * 0.42, radius * 0.24, spot.2 + 1), with: .color(Color(hex: light)))
            }
        }
    }

    /// Hex grid over the blobs' bounds, keeping points inside any blob, each nudged by a fixed jitter.
    private static func tuftSpots(_ blobs: [(CGFloat, CGFloat, CGFloat, CGFloat)], spacing: CGFloat) -> [(CGFloat, CGFloat, Int)] {
        let minX = blobs.map { $0.0 - $0.2 }.min() ?? 0
        let maxX = blobs.map { $0.0 + $0.2 }.max() ?? 0
        let minY = blobs.map { $0.1 - $0.3 }.min() ?? 0
        let maxY = blobs.map { $0.1 + $0.3 }.max() ?? 0
        var spots: [(CGFloat, CGFloat, Int)] = []
        var candidate = 0
        var row = 0
        var y = minY
        while y <= maxY {
            var x = minX + (row % 2 == 0 ? 0 : spacing / 2)
            while x <= maxX {
                let inside = blobs.contains { blob in
                    let dx = (x - blob.0) / blob.2
                    let dy = (y - blob.1) / blob.3
                    return dx * dx + dy * dy <= 1
                }
                if inside {
                    let jx = CGFloat((candidate * 37) % 13 - 6) / 6
                    let jy = CGFloat((candidate * 23 + 5) % 11 - 5) / 5
                    spots.append((x + jx * spacing * 0.28, y + jy * spacing * 0.28, candidate))
                }
                candidate += 1
                x += spacing
            }
            row += 1
            y += spacing * 0.87
        }
        return spots
    }

    /// A scalloped tuft: a core circle ringed by six lobes, turned by `seed`.
    private static func tuftPath(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ seed: Int) -> Path {
        var path = Path(ellipseIn: CGRect(x: x - radius * 0.8, y: y - radius * 0.8, width: radius * 1.6, height: radius * 1.6))
        let phase = CGFloat(seed * 17 % 60) * .pi / 180
        for lobe in 0..<6 {
            let angle = phase + CGFloat(lobe) * .pi / 3
            let cx = x + cos(angle) * radius * 0.56
            let cy = y + sin(angle) * radius * 0.56
            path.addEllipse(in: CGRect(x: cx - radius * 0.46, y: cy - radius * 0.46, width: radius * 0.92, height: radius * 0.92))
        }
        return path
    }

    private static func flower(_ context: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ hex: UInt32) {
        stroke(&context, "M \(x) \(y) L \(x) \(y + 12)", 0x1E8266, 2)
        for petal in 0..<5 {
            let angle = CGFloat(petal) * 2 * .pi / 5 - .pi / 2
            let rect = CGRect(x: x + cos(angle) * 4 - 3, y: y + sin(angle) * 4 - 3, width: 6, height: 6)
            context.fill(Path(ellipseIn: rect), with: .color(Color(hex: hex)))
        }
        let center: UInt32 = hex == 0xFFD581 ? 0xEF911F : 0xFFD581
        context.fill(Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)), with: .color(Color(hex: center)))
    }

    private static func mushroom(_ context: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ scale: CGFloat) {
        let stem = Path(roundedRect: CGRect(x: x - 5 * scale, y: y - 2 * scale, width: 10 * scale, height: 16 * scale), cornerRadius: 3 * scale)
        context.fill(stem, with: .color(Color(hex: 0xF7F1E6)))
        context.fill(Path(ellipseIn: CGRect(x: x - 16 * scale, y: y - 16 * scale, width: 32 * scale, height: 18 * scale)), with: .color(Color(hex: 0xE24B4B)))
        context.fill(Path(ellipseIn: CGRect(x: x - 8 * scale, y: y - 12 * scale, width: 6 * scale, height: 4.5 * scale)), with: .color(.white))
        context.fill(Path(ellipseIn: CGRect(x: x + 3 * scale, y: y - 9 * scale, width: 4.5 * scale, height: 3.5 * scale)), with: .color(.white))
    }

    private static func pine(_ context: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ scale: CGFloat, _ hex: UInt32) {
        var path = SVGPath.path("M0 2 L8 20 L3 20 L16 42 L7 42 L22 70 L-22 70 L-7 42 L-16 42 L-3 20 L-8 20 Z")
        let transform = CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: x, y: y))
        path = path.applying(transform)
        context.fill(path, with: .color(Color(hex: hex)))
        let trunk = Path(roundedRect: CGRect(x: -4, y: 66, width: 8, height: 16), cornerRadius: 2).applying(transform)
        context.fill(trunk, with: .color(Color(hex: 0x5C3A24)))
    }
}

private enum SVGPath {
    static func path(_ d: String) -> Path {
        var path = Path()
        let tokens = tokenize(d)
        var index = 0
        func number() -> CGFloat {
            let value = CGFloat(Double(tokens[index]) ?? 0)
            index += 1
            return value
        }
        while index < tokens.count {
            let command = tokens[index]
            index += 1
            switch command {
            case "M":
                path.move(to: CGPoint(x: number(), y: number()))
            case "L":
                path.addLine(to: CGPoint(x: number(), y: number()))
            case "C":
                let c1 = CGPoint(x: number(), y: number())
                let c2 = CGPoint(x: number(), y: number())
                path.addCurve(to: CGPoint(x: number(), y: number()), control1: c1, control2: c2)
            case "Q":
                let control = CGPoint(x: number(), y: number())
                path.addQuadCurve(to: CGPoint(x: number(), y: number()), control: control)
            case "Z", "z":
                path.closeSubpath()
            default:
                break
            }
        }
        return path
    }

    private static func tokenize(_ d: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        func flush() {
            if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        }
        for character in d {
            if character == "," || character == " " || character == "\n" {
                flush()
            } else if "MLCQZ".contains(character) {
                flush()
                tokens.append(String(character))
            } else {
                current.append(character)
            }
        }
        flush()
        return tokens
    }
}

private struct ForestWalker: View {
    var reduceMotion: Bool
    var look: WornLook
    var growth: String
    var companion: String?
    var animation: GoobyAnimation
    var walking: Bool
    var showPack: Bool
    var petLabel: String
    var petAction: String
    var onTap: () -> Void
    var onPet: () -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 30.0, paused: reduceMotion || !walking)) { timeline in
            ZStack {
                GoobyCharacterView(
                    look: look,
                    stage: growth,
                    animation: animation,
                    reduceMotion: reduceMotion,
                    companion: companion
                )
            }
            .offset(x: stride(at: timeline.date))
        }
        .homeStagePet(label: petLabel, petAction: petAction, onTap: onTap, onPet: onPet)
    }

    private func stride(at date: Date) -> CGFloat {
        guard walking, !reduceMotion else { return 0 }
        return CGFloat(sin(date.timeIntervalSinceReferenceDate * 0.55)) * 34
    }
}
