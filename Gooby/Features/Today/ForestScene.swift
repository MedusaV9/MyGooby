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
                    .frame(width: 72 * sx, height: 98 * sy)
                    .position(x: 186 * sx, y: 322 * sy)
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
        fill(&context, "M-16 8 C 20 -8 70 6 78 48 C 60 96 10 118 -16 78 Z", 0x83882E)
        fill(&context, "M-12 24 C 24 4 78 18 86 58 C 70 108 16 124 -8 86 C -20 60 -24 40 -12 24 Z", 0x7A9A32)
        fill(&context, "M-8 56 C 18 40 48 62 42 96 C 16 118 -10 96 -8 56 Z", 0x919944)

        pine(&context, 318, 150, 1.15, 0x1E8266)
        pine(&context, 356, 168, 1.45, 0x40964F)
        pine(&context, 388, 188, 1.05, 0x1A6B45)
        pine(&context, 286, 188, 0.85, 0x2F8A55)
        pine(&context, 248, 206, 0.62, 0x3E8F45)
        pine(&context, 338, 196, 0.70, 0x2A7A48)

        context.fill(Path(ellipseIn: CGRect(x: 48, y: 146, width: 44, height: 44)), with: .color(Color(hex: 0xFECB4E)))
        fill(&context, "M86 78 C 98 70 104 110 100 160 C 98 230 96 300 94 360 C 78 366 70 300 72 230 C 74 150 72 100 86 78 Z", 0xE7E3D2)
        fill(&context, "M78 90 C 82 88 86 140 84 210 C 83 270 82 330 84 355 C 76 352 74 280 76 210 C 77 140 74 96 78 90 Z", 0xF7F4EA)
        for mark in birchMarks {
            context.fill(Path(roundedRect: CGRect(x: mark.0, y: mark.1, width: mark.2, height: 3), cornerRadius: 1.5), with: .color(Color(hex: 0x5C5344)))
        }
        context.fill(Path(ellipseIn: CGRect(x: 81, y: 155, width: 18, height: 26)), with: .color(Color(hex: 0x3A2416)))
        context.fill(Path(ellipseIn: CGRect(x: 83, y: 159, width: 10, height: 14)), with: .color(Color(hex: 0xFECB4E)))

        fill(&context, "M232 36 C 214 90 206 180 198 280 C 194 330 192 370 190 392 L 262 398 C 268 330 274 240 278 150 C 282 90 274 48 258 32 Z", 0xC08946)
        fill(&context, "M248 40 C 252 110 256 200 258 310 C 259 350 260 380 258 396 L 270 398 C 274 300 278 180 276 90 C 274 55 266 40 258 34 Z", 0x8F6243)
        stroke(&context, "M226 90 Q 236 170 228 270", 0xA8743A, 2.2)
        stroke(&context, "M240 120 Q 246 200 238 300", 0x8F6243, 1.6)
        stroke(&context, "M236 118 C 200 132 160 148 128 168", 0xC08946, 13)
        stroke(&context, "M236 118 C 200 132 160 148 128 168", 0x8F6243, 4)
        stroke(&context, "M252 96 C 286 112 314 128 338 150", 0xC08946, 10)
        stroke(&context, "M220 150 C 196 158 176 172 162 188", 0xA8743A, 7)
        fill(&context, "M118 150 C 100 140 98 168 118 178 C 140 188 156 172 144 156 C 134 144 126 144 118 150 Z", 0x6E9A32)
        fill(&context, "M142 132 C 124 120 122 150 144 160 C 168 170 184 150 170 134 C 158 120 152 122 142 132 Z", 0x7A9A32)
        fill(&context, "M168 116 C 152 104 154 134 174 142 C 196 150 208 132 194 116 C 184 104 178 106 168 116 Z", 0x8FB84A)
        fill(&context, "M188 108 C 174 98 176 122 194 128 C 212 134 222 118 208 106 C 198 96 196 98 188 108 Z", 0x6E8A28)

        fill(&context, "M150 88 C 132 52 168 8 214 16 C 248 -6 310 -4 348 28 C 392 48 386 108 352 128 C 330 162 260 168 214 146 C 170 168 128 130 150 88 Z", 0x83882E)
        fill(&context, "M138 78 C 150 28 198 2 250 14 C 300 -6 362 16 372 64 C 386 108 348 142 300 136 C 270 162 200 156 168 128 C 128 118 112 96 138 78 Z", 0xADBC1B)
        fill(&context, "M176 62 C 196 28 250 16 292 36 C 322 22 356 48 348 78 C 336 108 286 112 246 98 C 210 112 168 92 176 62 Z", 0xC5CE55)
        fill(&context, "M168 96 C 190 78 250 82 292 104 C 270 132 210 140 168 118 C 150 112 154 102 168 96 Z", 0x919944)
        fill(&context, "M118 108 C 96 92 98 132 124 148 C 156 166 188 148 184 122 C 170 100 140 96 118 108 Z", 0x7A9A32)
        fill(&context, "M102 132 C 78 122 74 158 98 170 C 128 184 156 166 148 142 C 136 124 118 122 102 132 Z", 0x6E9A32)
        fill(&context, "M300 48 C 332 28 376 52 368 86 C 356 112 318 108 300 86 C 288 68 286 56 300 48 Z", 0xB5C42A)
        fill(&context, "M206 28 C 228 8 268 12 280 36 C 262 52 228 54 208 42 C 196 34 196 30 206 28 Z", 0xA3B43A)
        fill(&context, "M148 70 C 166 52 196 58 204 78 C 186 92 158 90 148 70 Z", 0x83882E)
        fill(&context, "M250 70 C 280 58 310 72 300 96 C 270 108 236 96 250 70 Z", 0x6E8A28)
        fill(&context, "M214 48 C 236 36 262 44 258 64 C 240 74 214 66 214 48 Z", 0xC1C787)
        fill(&context, "M156 124 C 140 116 142 142 162 150 C 184 156 196 140 184 126 C 174 116 166 116 156 124 Z", 0x7A9A32)
        fill(&context, "M126 150 C 112 144 114 166 132 172 C 152 178 162 164 150 152 C 140 144 134 144 126 150 Z", 0x8FB84A)

        fill(&context, "M40 330 C 24 318 28 348 52 356 C 78 366 96 346 84 328 C 72 314 52 316 40 330 Z", 0x2E7450)
        fill(&context, "M24 348 C 10 340 12 366 32 374 C 54 382 68 364 56 348 C 46 336 34 336 24 348 Z", 0x1E8266)
        fill(&context, "M300 336 C 278 324 276 356 304 366 C 336 376 356 354 340 336 C 328 322 314 322 300 336 Z", 0x3E8F45)
        fill(&context, "M0 348 C 46 328 96 358 156 344 C 214 330 268 352 330 336 C 362 328 384 340 390 346 L 390 428 L 0 428 Z", 0x5FA368)
        fill(&context, "M0 372 C 70 358 140 380 210 368 C 280 356 340 374 390 364 L 390 428 L 0 428 Z", 0x8DA452)
        fill(&context, "M0 396 C 80 388 160 404 250 394 C 320 386 360 398 390 392 L 390 428 L 0 428 Z", 0x7BB65C)
        fill(&context, "M18 372 C 8 366 10 386 26 390 C 42 394 50 380 40 370 C 32 364 24 364 18 372 Z", 0xC5B8A4)
        fill(&context, "M312 348 C 292 340 288 366 310 376 C 340 388 368 370 356 352 C 344 338 328 336 312 348 Z", 0xC5B8A4)
        fill(&context, "M328 360 C 318 356 316 372 330 378 C 348 384 362 374 352 362 C 344 354 336 354 328 360 Z", 0xA3978B)
        fill(&context, "M360 384 C 348 380 350 396 364 400 C 378 404 386 394 376 386 C 370 380 366 380 360 384 Z", 0xD5CBBA)
        for x in [12, 48, 96, 140, 180, 240, 280, 330, 368] {
            stroke(&context, "M \(x) 408 L \(x - 2) 394", 0x2E7450, 2)
            stroke(&context, "M \(x + 6) 410 L \(x + 6) 394", 0x3E8F45, 1.7)
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
