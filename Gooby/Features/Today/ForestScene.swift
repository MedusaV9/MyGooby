import SwiftUI

struct ForestScene: View {
    var reduceMotion: Bool
    var showHearts: Bool
    var look = WornLook()
    var stage = "young"
    var pet: () -> Void

    var body: some View {
        GeometryReader { geo in
            let sx = geo.size.width / 390
            let sy = geo.size.height / 428
            ZStack {
                Canvas { context, _ in
                    var context = context
                    context.scaleBy(x: sx, y: sy)
                    ForestPaint.draw(&context)
                }
                .themedScene()
                ForestGooby(look: look, stage: stage, reduceMotion: reduceMotion, showHearts: showHearts)
                    .frame(width: 168 * min(sx, sy), height: 168 * min(sx, sy))
                    .contentShape(Rectangle())
                    .position(x: 196 * sx, y: 290 * sy)
                    .onTapGesture(perform: pet)
            }
        }
        .contentShape(Rectangle())
        .clipped()
    }
}

private enum ForestPaint {
    static func draw(_ context: inout GraphicsContext) {
        context.fill(Path(CGRect(x: 0, y: 0, width: 390, height: 428)), with: .color(Color(hex: 0x526DB4)))
        fill(&context, "M-10 250 C 40 200 110 214 170 246 C 210 210 280 198 350 230 C 390 214 410 250 410 270 L 410 340 L -10 340 Z", 0x8FB85A)
        fill(&context, "M-20 278 C 30 240 100 252 160 286 C 220 248 300 240 400 272 L 410 360 L -20 360 Z", 0x7EAF55)
        fill(&context, "M-10 310 C 50 286 130 300 200 322 C 270 292 340 300 410 318 L 410 390 L -10 390 Z", 0x6E9A48)
        fill(&context, "M14 110 C 10 200 16 300 22 376 L 48 378 C 44 300 48 200 54 104 Z", 0xC08946)
        stroke(&context, "M34 112 C 30 200 34 300 36 372", 0x8F6243, 7)
        stroke(&context, "M46 132 C 58 124 66 122 76 122", 0xC08946, 6)
        crown(&context, blobs: leftCrown, tuft: 23, back: 0x7E842A, rim: 0x767C28, mids: [0x919944, 0x969C46, 0x919944], light: 0xA4AC3E)

        pine(&context, 318, 150, 1.15, 0x1E8266)
        pine(&context, 356, 168, 1.45, 0x40964F)
        pine(&context, 388, 188, 1.05, 0x1A6B45)
        pine(&context, 286, 188, 0.85, 0x2F8A55)
        pine(&context, 248, 206, 0.62, 0x3E8F45)
        pine(&context, 338, 196, 0.70, 0x2A7A48)

        context.fill(Path(ellipseIn: CGRect(x: 60, y: 150, width: 36, height: 36)), with: .color(Color(hex: 0xFECB4E)))
        fill(&context, "M86 78 C 98 70 104 110 100 160 C 98 230 96 300 94 360 C 78 366 70 300 72 230 C 74 150 72 100 86 78 Z", 0xE7E3D2)
        fill(&context, "M78 90 C 82 88 86 140 84 210 C 83 270 82 330 84 355 C 76 352 74 280 76 210 C 77 140 74 96 78 90 Z", 0xF7F4EA)
        for mark in birchMarks {
            context.fill(Path(roundedRect: CGRect(x: mark.0, y: mark.1, width: mark.2, height: 3), cornerRadius: 1.5), with: .color(Color(hex: 0x5C5344)))
        }
        context.fill(Path(ellipseIn: CGRect(x: 81, y: 155, width: 18, height: 26)), with: .color(Color(hex: 0x3A2416)))
        context.fill(Path(ellipseIn: CGRect(x: 83, y: 159, width: 10, height: 14)), with: .color(Color(hex: 0xFECB4E)))

        fill(&context, "M222 150 C 210 230 202 320 196 392 L 268 398 C 270 320 268 230 258 148 Z", 0xC08946)
        stroke(&context, "M244 160 C 250 250 252 340 250 396", 0x8F6243, 14)
        stroke(&context, "M226 184 C 212 174 200 170 186 168", 0xC08946, 8)
        stroke(&context, "M256 178 C 270 168 282 164 296 162", 0xA8743A, 7)
        crown(&context, blobs: rightCrown, tuft: 26, back: 0x5F7426, rim: 0x7E842A, mids: [0xADBC1B, 0xA6B522, 0xADBC1B, 0x9FAA2E], light: 0xCDD64A)

        fill(&context, "M40 330 C 24 318 28 348 52 356 C 78 366 96 346 84 328 C 72 314 52 316 40 330 Z", 0x2E7450)
        fill(&context, "M24 348 C 10 340 12 366 32 374 C 54 382 68 364 56 348 C 46 336 34 336 24 348 Z", 0x1E8266)
        fill(&context, "M300 336 C 278 324 276 356 304 366 C 336 376 356 354 340 336 C 328 322 314 322 300 336 Z", 0x3E8F45)
        fill(&context, "M66 344 C 52 320 70 296 92 302 C 104 284 132 288 138 306 C 156 306 160 334 146 346 Z", 0xB9C44E)
        for bloom in blooms {
            flower(&context, bloom.0, bloom.1, bloom.2)
        }
        fill(&context, "M0 348 C 46 328 96 358 156 344 C 214 330 268 352 330 336 C 362 328 384 340 390 346 L 390 428 L 0 428 Z", 0x5FA368)
        fill(&context, "M0 372 C 70 358 140 380 210 368 C 280 356 340 374 390 364 L 390 428 L 0 428 Z", 0x8DA452)
        fill(&context, "M0 396 C 80 388 160 404 250 394 C 320 386 360 398 390 392 L 390 428 L 0 428 Z", 0x7BB65C)
        fill(&context, "M24 368 C 10 360 12 386 30 392 C 50 398 62 382 48 366 C 38 356 32 356 24 368 Z", 0xC5B8A4)
        context.fill(Path(ellipseIn: CGRect(x: 22, y: 362, width: 18, height: 10)), with: .color(Color(hex: 0xE7DFD2)))
        fill(&context, "M318 352 C 298 344 296 372 318 382 C 346 392 370 374 356 356 C 344 342 332 342 318 352 Z", 0xC5B8A4)
        context.fill(Path(ellipseIn: CGRect(x: 324, y: 350, width: 26, height: 12)), with: .color(Color(hex: 0xE7DFD2)))
        for index in 0..<32 {
            let x = 8 + (index * 37) % 374
            let y = 378 + (index * 13) % 28
            stroke(&context, "M \(x) \(y + 14) L \(x + (index % 3) - 1) \(y + 2)", 0x2E7450, 1.8)
        }
        for bloom in meadowBlooms {
            flower(&context, bloom.0, bloom.1, bloom.2)
        }
    }

    private static let rightCrown: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (272, 104, 96, 50), (232, 66, 44, 22), (354, 84, 30, 32)
    ]

    private static let leftCrown: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (46, 72, 70, 32), (104, 56, 22, 16)
    ]

    private static let blooms: [(CGFloat, CGFloat, UInt32)] = [
        (80, 310, 0xDF5727), (110, 298, 0xDF5727), (130, 316, 0xDF5727),
        (96, 322, 0xFFD581), (120, 330, 0xFFD581), (210, 250, 0xF2A0C0), (222, 268, 0xF2A0C0)
    ]

    private static let meadowBlooms: [(CGFloat, CGFloat, UInt32)] = [
        (58, 368, 0xDF5727), (196, 360, 0xF2A0C0), (214, 372, 0xFFD581), (300, 374, 0xDF5727), (366, 368, 0xFFD581)
    ]

    private static let birchMarks: [(CGFloat, CGFloat, CGFloat)] = [
        (76, 108, 18), (80, 122, 12), (75, 136, 20), (82, 150, 11), (76, 164, 18),
        (79, 178, 14), (75, 192, 20), (81, 206, 12), (76, 220, 18), (80, 234, 13),
        (75, 248, 20), (82, 262, 11), (76, 276, 18), (79, 290, 14), (75, 304, 19),
        (81, 318, 12), (76, 332, 17)
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

struct ForestGooby: View {
    var look: WornLook
    var stage: String
    var reduceMotion: Bool
    var showHearts: Bool

    var body: some View {
        GoobyCharacterView(look: look, stage: stage, animation: showHearts ? .petting : .idle, reduceMotion: reduceMotion, companion: nil)
    }
}
