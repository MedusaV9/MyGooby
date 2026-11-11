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
                .frame(width: 86 * s, height: 86 * s)
                .position(x: 208 * s, y: 252 * s)
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
        // Far hills sit under the sky the way the Finch frame opens between the trees.
        fill(&context, "M-10 188 C 40 162 110 168 170 186 C 230 164 310 158 412 176 L 412 400 L -10 400 Z", 0x8CB060)
        fill(&context, "M-10 214 C 60 196 140 202 210 220 C 280 200 350 196 412 210 L 412 400 L -10 400 Z", 0x6BA04F)

        pine(&context, 48, 78, 2.05, 0x318635)
        pine(&context, 96, 96, 1.7, 0x3C9845)
        pine(&context, 168, 118, 1.15, 0x3A9442)
        pine(&context, 300, 108, 1.35, 0x3C9845)
        pine(&context, 348, 92, 1.55, 0x338A39)
        pine(&context, 392, 118, 1.25, 0x2F7D5A)

        // One slim birch, Sophie's cream trunk, kept narrow so the left stays pine-green.
        fill(&context, "M10 96 C 8 140 8 180 10 214 L 24 214 C 24 180 24 140 22 96 Z", 0xF1E2CD)
        fill(&context, "M18 96 C 20 140 20 180 20 214 L 24 214 C 24 180 24 140 22 96 Z", 0xE2D0B8)
        for mark in birchMarks {
            context.fill(Path(roundedRect: CGRect(x: mark.0, y: mark.1, width: mark.2, height: 2.4), cornerRadius: 1.2), with: .color(Color(hex: 0x6A5D55)))
        }
        context.fill(Path(ellipseIn: CGRect(x: 12, y: 148, width: 9, height: 13)), with: .color(Color(hex: 0x4A3528)))
        context.fill(Path(ellipseIn: CGRect(x: 14, y: 151, width: 5, height: 7)), with: .color(Color(hex: 0xFED085)))

        // The frame's brown trunk, just right of the left pines.
        fill(&context, "M118 78 C 116 130 114 180 112 236 L 136 236 C 136 180 134 130 132 78 Z", 0x91562E)
        stroke(&context, "M128 84 C 130 140 130 190 132 232", 0x6E3E1C, 4)

        context.fill(Path(ellipseIn: CGRect(x: 296, y: 118, width: 48, height: 48)), with: .color(Color(hex: 0xF9D575)))

        canopy(&context, base: 78, depth: 10, hex: 0x75822A)
        canopy(&context, base: 58, depth: 8, hex: 0x85933C)
        context.fill(Path(CGRect(x: 0, y: 0, width: 36, height: 70)), with: .color(Color(hex: 0xA2BE1E)))
        context.fill(Path(CGRect(x: 0, y: 52, width: 28, height: 28)), with: .color(Color(hex: 0xAFC64F)))

        fill(&context, "M-8 292 C -12 250 16 228 48 236 C 70 214 112 216 124 240 C 142 236 154 262 146 292 Z", 0x3F9846)
        fill(&context, "M150 300 C 146 258 168 228 206 236 C 228 210 270 218 276 248 C 298 256 300 286 286 300 Z", 0x80A349)
        fill(&context, "M250 304 C 246 268 270 246 302 256 C 322 238 360 246 368 272 C 388 278 392 300 380 308 Z", 0x338A39)
        fill(&context, "M330 292 C 324 256 348 232 382 242 C 400 226 418 236 412 258 L 412 300 Z", 0x6BA04F)
        for bloom in blooms {
            flower(&context, bloom.0, bloom.1, bloom.2)
        }
        mushroom(&context, 246, 268, 0.85)

        fill(&context, "M-10 292 C 70 284 160 292 240 296 C 310 300 360 292 412 294 L 412 \(bottom) L -10 \(bottom) Z", 0x73B752)
        fill(&context, "M150 300 C 170 292 210 294 236 304 C 210 312 170 312 150 304 Z", 0xB5E0B4)
        fill(&context, "M-10 300 C 40 294 80 302 120 308 C 70 316 20 316 -10 312 Z", 0x50A049)
        for index in 0..<18 {
            let x = 8 + (index * 47) % 390
            let y = 308 + (index * 11) % 24
            stroke(&context, "M \(x) \(y + 9) L \(x + (index % 3) - 1) \(y)", 0x4E9A45, 1.6)
        }
        for bloom in meadowBlooms {
            flower(&context, bloom.0, bloom.1, bloom.2)
        }
    }

    /// A leaf mass across the top whose lower edge hangs in scallops around `base`.
    private static func canopy(_ context: inout GraphicsContext, base: CGFloat, depth: CGFloat, hex: UInt32) {
        var path = Path()
        path.move(to: CGPoint(x: -10, y: -10))
        path.addLine(to: CGPoint(x: 412, y: -10))
        path.addLine(to: CGPoint(x: 412, y: base))
        var x: CGFloat = 412
        var index = 0
        while x > -10 {
            let width = CGFloat(30 + (index * 7) % 16)
            let sag = depth * (0.7 + CGFloat((index * 5) % 4) * 0.15)
            let lift = CGFloat((index * 11) % 9) - 4
            path.addQuadCurve(to: CGPoint(x: x - width, y: base + lift), control: CGPoint(x: x - width / 2, y: base + lift + sag * 2))
            x -= width
            index += 1
        }
        path.closeSubpath()
        context.fill(path, with: .color(Color(hex: hex)))
    }

    private static let blooms: [(CGFloat, CGFloat, UInt32)] = [
        (322, 252, 0xE4502F), (352, 240, 0xE4502F), (374, 262, 0xE4502F), (160, 252, 0xE4502F),
        (344, 270, 0xFDD86A), (330, 284, 0xFDD86A), (198, 236, 0xFDD86A), (290, 270, 0xF7A3BE)
    ]

    private static let meadowBlooms: [(CGFloat, CGFloat, UInt32)] = [
        (40, 322, 0xE4502F), (112, 330, 0xF7A3BE), (262, 326, 0xFDD86A), (300, 316, 0xE4502F), (372, 312, 0xF7A3BE)
    ]

    private static let birchMarks: [(CGFloat, CGFloat, CGFloat)] = [
        (11, 108, 8), (12, 126, 9), (11, 146, 8), (13, 166, 7), (11, 186, 9), (12, 204, 8)
    ]

    private static func fill(_ context: inout GraphicsContext, _ d: String, _ hex: UInt32) {
        context.fill(SVGPath.path(d), with: .color(Color(hex: hex)))
    }

    private static func stroke(_ context: inout GraphicsContext, _ d: String, _ hex: UInt32, _ width: CGFloat) {
        context.stroke(SVGPath.path(d), with: .color(Color(hex: hex)), style: StrokeStyle(lineWidth: width, lineCap: .round))
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
        .opacity(showPack ? 1 : 1)
    }

    private func stride(at date: Date) -> CGFloat {
        guard walking, !reduceMotion else { return 0 }
        return CGFloat(sin(date.timeIntervalSinceReferenceDate * 0.55)) * 8
    }
}
