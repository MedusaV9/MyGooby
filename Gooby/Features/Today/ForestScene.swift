import SwiftUI

struct ForestScene: View {
    var reduceMotion: Bool
    var showHearts: Bool
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
                ForestGooby(reduceMotion: reduceMotion, showHearts: showHearts)
                    .frame(width: 52 * sx, height: 70 * sy)
                    .position(x: 162 * sx, y: 328 * sy)
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
        fill(&context, "M18 214 C 14 270 16 330 22 376 L 48 378 C 44 320 46 260 50 206 Z", 0xC08946)
        stroke(&context, "M36 210 C 32 270 34 330 36 372", 0x8F6243, 7)
        leafTufts(&context, along: (34, 198, 20, 176, 48, 214), clusters: 2)

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

        fill(&context, "M214 210 C 206 270 200 330 196 392 L 268 398 C 272 330 274 260 266 200 Z", 0xC08946)
        stroke(&context, "M246 208 C 250 280 252 340 250 396", 0x8F6243, 14)
        stroke(&context, "M228 214 C 170 150 140 90 112 48", 0xC08946, 12)
        stroke(&context, "M240 200 C 244 120 250 60 258 16", 0xC08946, 11)
        stroke(&context, "M252 208 C 310 140 346 80 368 36", 0xA8743A, 11)
        leafTufts(&context, along: (232, 198, 160, 110, 108, 42), clusters: 5)
        leafTufts(&context, along: (242, 188, 246, 70, 262, 8), clusters: 5)
        leafTufts(&context, along: (255, 196, 330, 90, 372, 30), clusters: 5)

        fill(&context, "M40 330 C 24 318 28 348 52 356 C 78 366 96 346 84 328 C 72 314 52 316 40 330 Z", 0x2E7450)
        fill(&context, "M24 348 C 10 340 12 366 32 374 C 54 382 68 364 56 348 C 46 336 34 336 24 348 Z", 0x1E8266)
        fill(&context, "M300 336 C 278 324 276 356 304 366 C 336 376 356 354 340 336 C 328 322 314 322 300 336 Z", 0x3E8F45)
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
    }

    private static let birchMarks: [(CGFloat, CGFloat, CGFloat)] = [
        (76, 108, 18), (80, 122, 12), (75, 136, 20), (82, 150, 11), (76, 164, 18),
        (79, 178, 14), (75, 192, 20), (81, 206, 12), (76, 220, 18), (80, 234, 13),
        (75, 248, 20), (82, 262, 11), (76, 276, 18), (79, 290, 14), (75, 304, 19),
        (81, 318, 12), (76, 332, 17)
    ]

    private static func fill(_ context: inout GraphicsContext, _ d: String, _ hex: UInt) {
        context.fill(SVGPath.path(d), with: .color(Color(hex: hex)))
    }

    private static func stroke(_ context: inout GraphicsContext, _ d: String, _ hex: UInt, _ width: CGFloat) {
        context.stroke(SVGPath.path(d), with: .color(Color(hex: hex)), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// Places three small ellipses at each stop along a branch. Four greens, with a pale tip on the last stop.
    private static func leafTufts(_ context: inout GraphicsContext, along branch: (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat), clusters: Int) {
        let greens: [UInt] = [0xC5CE55, 0x919944, 0x5C7A24]
        let tip: UInt = 0xE8F08A
        let offsets: [(CGFloat, CGFloat)] = [(-7, -5), (6, -2), (0, 7)]
        for cluster in 0..<clusters {
            let t = 0.08 + CGFloat(cluster) * 0.2
            let x = quad(branch.0, branch.2, branch.4, t)
            let y = quad(branch.1, branch.3, branch.5, t)
            for (index, offset) in offsets.enumerated() {
                let size = 12 + CGFloat((cluster + index) % 3) * 2
                let hex = (cluster == clusters - 1 && index == 0) ? tip : greens[(cluster + index) % greens.count]
                let rect = CGRect(x: x + offset.0 - size / 2, y: y + offset.1 - size * 0.39, width: size, height: size * 0.78)
                context.fill(Path(ellipseIn: rect), with: .color(Color(hex: hex)))
            }
        }
    }

    private static func quad(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ t: CGFloat) -> CGFloat {
        let u = 1 - t
        return u * u * a + 2 * u * t * b + t * t * c
    }

    private static func pine(_ context: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ scale: CGFloat, _ hex: UInt) {
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
    var reduceMotion: Bool
    var showHearts: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 24.0, paused: reduceMotion)) { timeline in
            let step = reduceMotion ? 0 : sin(timeline.date.timeIntervalSinceReferenceDate * 2.2)
            ZStack {
                Ellipse().fill(Color.black.opacity(0.16)).frame(width: 34, height: 8).offset(y: 50)
                backpack
                leg(angle: -12 - step * 8).offset(x: -7, y: 30)
                leg(angle: 14 + step * 8).offset(x: 8, y: 28)
                torso
                strap
                arm.offset(x: -16, y: 8)
                arm.offset(x: 14, y: 6)
                head
                ears(wave: step)
                face
                if showHearts {
                    heart.offset(x: 24, y: -46)
                    heart.offset(x: -16, y: -54).scaleEffect(0.75)
                }
            }
            .rotationEffect(.degrees(6))
        }
        .accessibilityLabel("Gooby")
    }

    private var backpack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(HomePalette.satchelDeep)
                .frame(width: 24, height: 30)
                .offset(y: 2)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(HomePalette.satchel)
                .frame(width: 24, height: 28)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0xE86A64))
                .frame(width: 14, height: 8)
                .offset(y: -6)
        }
        .offset(x: -18, y: 2)
    }

    private func leg(angle: Double) -> some View {
        ZStack {
            Capsule().fill(HomePalette.furShade).frame(width: 9, height: 22)
            Capsule().fill(HomePalette.fur).frame(width: 9, height: 22).offset(x: -1)
            Ellipse().fill(HomePalette.fur).frame(width: 12, height: 7).offset(y: 12)
        }
        .rotationEffect(.degrees(angle), anchor: .top)
    }

    private var torso: some View {
        ZStack {
            Ellipse().fill(HomePalette.furShade).frame(width: 32, height: 40).offset(x: 2, y: 8)
            Ellipse().fill(HomePalette.fur).frame(width: 32, height: 40).offset(y: 6)
        }
    }

    private var strap: some View {
        Capsule()
            .fill(HomePalette.satchelDeep)
            .frame(width: 4, height: 18)
            .rotationEffect(.degrees(32))
            .offset(x: -8, y: 2)
    }

    private var arm: some View {
        Capsule().fill(HomePalette.fur).frame(width: 8, height: 16)
    }

    private var head: some View {
        ZStack {
            Circle().fill(HomePalette.furShade).frame(width: 36, height: 34).offset(x: 2, y: -20)
            Circle().fill(HomePalette.fur).frame(width: 36, height: 34).offset(y: -22)
        }
    }

    private func ears(wave: Double) -> some View {
        ZStack {
            ear(tilt: -18 + wave * 3).offset(x: -10, y: -46)
            ear(tilt: 16 - wave * 3).offset(x: 12, y: -46)
        }
    }

    private func ear(tilt: Double) -> some View {
        ZStack {
            Capsule().fill(HomePalette.fur).frame(width: 11, height: 28)
            Capsule().fill(HomePalette.innerEar).frame(width: 5, height: 18).offset(y: 3)
        }
        .rotationEffect(.degrees(tilt))
    }

    private var face: some View {
        ZStack {
            Ellipse().fill(HomePalette.cheek).frame(width: 8, height: 5).offset(x: -12, y: -18)
            Ellipse().fill(HomePalette.cheek).frame(width: 8, height: 5).offset(x: 12, y: -18)
            eye.offset(x: -7, y: -24)
            eye.offset(x: 7, y: -24)
            Ellipse().fill(HomePalette.nose).frame(width: 5, height: 3.5).offset(y: -16)
            SmileShape()
                .stroke(Color(hex: 0xC46B86), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                .frame(width: 10, height: 5)
                .offset(y: -12)
        }
    }

    private var eye: some View {
        ZStack {
            Ellipse().fill(HomePalette.eye).frame(width: 7, height: 8)
            Circle().fill(Color.white).frame(width: 2.2, height: 2.2).offset(x: -1.2, y: -1.6)
        }
    }

    private var heart: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 9))
            .foregroundStyle(Color(hex: 0xFF8FB3))
    }
}
