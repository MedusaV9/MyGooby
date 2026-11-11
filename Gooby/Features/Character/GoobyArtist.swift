import SwiftUI

/// Gooby drawn into a 320 × 320 box. The origin sits at the center, y grows downward:
/// ear tips near y = -150, feet near y = +146. The shapes follow the character sheets.
enum GoobyLayerPart {
    case shadow, back, front, marks
}

enum GoobyInkColor {
    static let eye = Color(hex: 0x3F2B24)
    static let nose = Color(hex: 0xEE8389)
    static let mouth = Color(hex: 0xC9606C)
    static let tongue = Color(hex: 0xF49AA6)
    static let foot = Color(hex: 0xB8A69E)
    static let footDeep = Color(hex: 0xA3918A)
    static let shadow = Color(hex: 0x8A5A3C)
    static let lavender = Color(hex: 0x9A7CC4)
    static let yellow = Color(hex: 0xF2BE3A)
    static let heart = Color(hex: 0xF08FAE)
    static let book = Color(hex: 0xBFA0D6)
    static let bookDeep = Color(hex: 0xA585C2)
    static let petal = Color(hex: 0xFBCB45)
    static let petalCenter = Color(hex: 0xE9973A)
    static let stem = Color(hex: 0x7FA450)
    static let leaf = Color(hex: 0x8DB35A)
    static let tail = Color(hex: 0xFFF8EF)
    static let pack = Color(hex: 0xCF544D)
}

struct GoobyInk {
    var context: GraphicsContext

    func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ color: Color, _ opacity: Double = 1) {
        let rect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color.opacity(opacity)))
    }

    func path(_ d: String, _ color: Color, _ opacity: Double = 1) {
        context.fill(GoobyPathData.path(d), with: .color(color.opacity(opacity)))
    }

    func stroke(_ d: String, _ color: Color, _ width: CGFloat, _ opacity: Double = 1) {
        let style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        context.stroke(GoobyPathData.path(d), with: .color(color.opacity(opacity)), style: style)
    }

    /// Same order as an SVG transform `translate(dx, dy) rotate(angle, around) scale(sx, sy)`.
    func group(rotate: Double = 0, around: CGPoint = .zero, dx: CGFloat = 0, dy: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, _ draw: (GoobyInk) -> Void) {
        var sub = context
        sub.translateBy(x: dx + around.x, y: dy + around.y)
        sub.rotate(by: .degrees(rotate))
        sub.scaleBy(x: sx, y: sy)
        sub.translateBy(x: -around.x, y: -around.y)
        draw(GoobyInk(context: sub))
    }

    func clipped(_ d: String, _ draw: (GoobyInk) -> Void) {
        var sub = context
        sub.clip(to: GoobyPathData.path(d))
        draw(GoobyInk(context: sub))
    }
}

struct GoobyArtist {
    var ink: GoobyInk
    var pose: GoobyPose
    var fur: FurPaint
    var pack: Color

    static func canvas(_ part: GoobyLayerPart, pose: GoobyPose, fur: FurPaint, pack: Color) -> some View {
        Canvas { context, size in
            var context = context
            let unit = min(size.width, size.height)
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.scaleBy(x: unit / 320, y: unit / 320)
            GoobyArtist(ink: GoobyInk(context: context), pose: pose, fur: fur, pack: pack).draw(part)
        }
    }

    private var sitting: Bool { pose.stance == .read || pose.stance == .sit }

    func draw(_ part: GoobyLayerPart) {
        switch part {
        case .shadow:
            let lift = max(0, -pose.hop) / 60
            let wide: CGFloat = pose.stance == .sleep ? 100 : 82
            let y: CGFloat = pose.stance == .sleep ? 140 : 146
            ink.ellipse(0, y, wide * (1 - lift * 0.35), 13 * (1 - lift * 0.3), GoobyInkColor.shadow, 0.12 * (1 - Double(lift) * 0.4))
        case .back:
            switch pose.stance {
            case .sleep: sleeping()
            case .back: backView()
            default: lowerBody()
            }
        case .front:
            if pose.stance != .sleep && pose.stance != .back { upperBody() }
        case .marks:
            marks()
        }
    }

    // MARK: Front-facing stances

    private func lowerBody() {
        backpack(cx: -70, cy: sitting ? 74 : 60)
        if sitting {
            ink.path(Self.bodyPath(top: 34, bottom: 136, half: 64), fur.body)
            ink.ellipse(-36, 122, 24, 18, fur.body)
            ink.ellipse(44, 120, 24, 18, fur.body)
            ink.ellipse(-38, 130, 18, 12, GoobyInkColor.foot)
            ink.ellipse(46, 128, 18, 12, GoobyInkColor.foot)
            ink.ellipse(-38, 132, 9, 6, GoobyInkColor.footDeep, 0.5)
            ink.ellipse(46, 130, 9, 6, GoobyInkColor.footDeep, 0.5)
        } else {
            ink.ellipse(-32, 141 - max(0, pose.step) * 6, 22, 11, GoobyInkColor.foot)
            ink.ellipse(28, 140 - max(0, -pose.step) * 6, 22, 11, GoobyInkColor.foot)
            ink.path(Self.bodyPath(top: 18, bottom: 140, half: 62), fur.body)
        }
        ink.ellipse(6, sitting ? 58 : 44, 50, 26, fur.bib)
    }

    private func upperBody() {
        let stance = pose.stance
        if stance == .stand || stance == .sit {
            ink.stroke("M64 56 C74 74 80 90 74 104", fur.body, 24)
        }
        ink.group(rotate: Double(pose.headTilt), around: CGPoint(x: 3, y: 40), dy: sitting ? 14 : 0) { head in
            ear(head, base: CGPoint(x: -30, y: -62), angle: -17 + pose.earLeft)
            ear(head, base: CGPoint(x: 30, y: -66), angle: 7 + pose.earRight)
            head.path(Self.headPath, fur.body)
            face(head)
        }
        switch stance {
        case .stand, .wave, .curious:
            ink.stroke("M-60 54 C-48 70 -36 80 -16 80", fur.shade, 26)
            ink.stroke("M-62 50 C-50 66 -36 76 -16 76", fur.body, 26)
        default:
            break
        }
        switch stance {
        case .wave:
            ink.group(rotate: Double(pose.wave) * 14, around: CGPoint(x: 54, y: 50)) { arm in
                arm.stroke("M54 52 C70 40 80 24 82 6", fur.shade, 24)
                arm.stroke("M52 50 C68 38 78 22 80 4", fur.body, 24)
            }
        case .curious:
            ink.stroke("M60 58 C66 46 60 36 42 32", fur.shade, 24)
            ink.stroke("M58 56 C64 44 58 32 40 28", fur.body, 22)
            ink.stroke("M30 24 C34 32 44 36 52 32", fur.shade, 2.4)
        case .flower:
            flower(x: 22, y: 20)
            ink.stroke("M-58 52 C-44 72 -20 72 2 62", fur.shade, 24)
            ink.stroke("M-60 48 C-46 68 -22 68 0 58", fur.body, 24)
            ink.stroke("M58 52 C56 66 44 72 30 70", fur.body, 22)
        case .sit:
            ink.ellipse(-24, 92, 15, 12, fur.shade)
            ink.ellipse(30, 92, 15, 12, fur.shade)
            ink.ellipse(-24, 90, 15, 12, fur.body)
            ink.ellipse(30, 90, 15, 12, fur.body)
        case .read:
            book(cx: 6, cy: 88)
            ink.ellipse(-36, 96, 14, 12, fur.body)
            ink.ellipse(48, 92, 14, 12, fur.body)
        default:
            break
        }
    }

    private func ear(_ ink: GoobyInk, base: CGPoint, angle: CGFloat, length: CGFloat = 98, width: CGFloat = 48, inner: Bool = true) {
        ink.group(rotate: Double(angle), around: base) { ear in
            let cy = base.y - length / 2
            ear.ellipse(base.x, cy, width / 2, length / 2, fur.body)
            if inner {
                ear.ellipse(base.x + 1, cy - 3, width * 0.3, length * 0.36, fur.innerEar)
            }
        }
    }

    private func face(_ ink: GoobyInk) {
        let ex: CGFloat = 18
        eye(ink, x: ex - 29, y: -20, size: 1.15)
        eye(ink, x: ex + 29, y: -20, size: 1.15)
        ink.clipped(Self.headPath) { cheeks in
            cheeks.ellipse(ex - 46, 2, 16, 12.5, fur.cheek, 0.95)
            cheeks.ellipse(ex + 46, -4, 15, 12, fur.cheek, 0.95)
        }
        let nx = ex + 4
        let ny: CGFloat = -12
        ink.path("M\(nx - 8) \(ny - 3) C\(nx - 8) \(ny - 7) \(nx + 8) \(ny - 7) \(nx + 8) \(ny - 3) C\(nx + 8) \(ny + 1) \(nx + 2) \(ny + 5) \(nx) \(ny + 5) C\(nx - 2) \(ny + 5) \(nx - 8) \(ny + 1) \(nx - 8) \(ny - 3) Z", GoobyInkColor.nose)
        if pose.mouth {
            ink.path("M\(nx - 7) \(ny + 7) Q\(nx) \(ny + 6) \(nx + 7) \(ny + 7) Q\(nx + 6) \(ny + 17) \(nx) \(ny + 17) Q\(nx - 6) \(ny + 17) \(nx - 7) \(ny + 7) Z", GoobyInkColor.mouth)
            ink.ellipse(nx, ny + 14, 4, 2.6, GoobyInkColor.tongue)
        } else {
            ink.stroke("M\(nx) \(ny + 5) L\(nx) \(ny + 9) Q\(nx + 1) \(ny + 12) \(nx + 4) \(ny + 11)", GoobyInkColor.nose, 2.2)
        }
    }

    private func eye(_ ink: GoobyInk, x: CGFloat, y: CGFloat, size: CGFloat) {
        let w = 10 * size
        if pose.happy {
            ink.stroke("M\(x - w) \(y + 2) Q\(x) \(y - 9 * size) \(x + w) \(y + 2)", GoobyInkColor.eye, 3.6 * size)
        } else if pose.blink < 0.25 {
            ink.stroke("M\(x - w) \(y) Q\(x) \(y + 6 * size) \(x + w) \(y)", GoobyInkColor.eye, 3.4 * size)
        } else {
            let open = pose.blink
            let highlight = min(1, open)
            ink.ellipse(x, y, 10 * size, 11.5 * size * open, GoobyInkColor.eye)
            ink.ellipse(x + 3.6 * size, y - 4.2 * size * open, 3.8 * size, 3.8 * size * highlight, .white)
            ink.ellipse(x - 3.4 * size, y + 4.6 * size * open, 1.5 * size, 1.5 * size * highlight, .white, 0.8)
        }
    }

    private func backpack(cx: CGFloat, cy: CGFloat) {
        ink.group(rotate: -8, around: CGPoint(x: cx, y: cy)) { bag in
            bag.ellipse(cx, cy, 40, 52, pack)
            bag.path("M\(cx + 18) \(cy - 46) C\(cx + 40) \(cy - 30) \(cx + 44) \(cy + 30) \(cx + 22) \(cy + 50) C\(cx + 30) \(cy + 20) \(cx + 30) \(cy - 20) \(cx + 18) \(cy - 46) Z", .black, 0.16)
            bag.ellipse(cx - 14, cy - 26, 14, 18, .white, 0.14)
        }
    }

    private func flower(x: CGFloat, y: CGFloat) {
        ink.stroke("M\(x) \(y) Q\(x - 4) \(y + 22) \(x - 2) \(y + 40)", GoobyInkColor.stem, 3.4)
        ink.path("M\(x - 2) \(y + 26) C\(x - 18) \(y + 18) \(x - 22) \(y + 30) \(x - 14) \(y + 34) C\(x - 8) \(y + 36) \(x - 4) \(y + 30) \(x - 2) \(y + 26) Z", GoobyInkColor.leaf)
        ink.path("M\(x - 1) \(y + 20) C\(x + 14) \(y + 10) \(x + 20) \(y + 20) \(x + 12) \(y + 26) C\(x + 6) \(y + 28) \(x + 2) \(y + 24) \(x - 1) \(y + 20) Z", GoobyInkColor.leaf)
        for petal in 0..<5 {
            let angle = -CGFloat.pi / 2 + CGFloat(petal) * 2 * .pi / 5
            ink.ellipse(x + cos(angle) * 7.5, y + sin(angle) * 7.5, 6.2, 6.2, GoobyInkColor.petal)
        }
        ink.ellipse(x, y, 4.6, 4.6, GoobyInkColor.petalCenter)
    }

    private func book(cx: CGFloat, cy: CGFloat) {
        ink.path("M\(cx - 40) \(cy - 22) L\(cx) \(cy - 16) L\(cx + 40) \(cy - 26) L\(cx + 42) \(cy + 20) L\(cx) \(cy + 30) L\(cx - 38) \(cy + 22) Z", GoobyInkColor.bookDeep)
        ink.path("M\(cx - 36) \(cy - 24) Q\(cx - 16) \(cy - 26) \(cx - 1) \(cy - 16) L\(cx - 1) \(cy + 26) Q\(cx - 16) \(cy + 16) \(cx - 34) \(cy + 18) Z", GoobyInkColor.book)
        ink.path("M\(cx + 1) \(cy - 16) Q\(cx + 18) \(cy - 28) \(cx + 38) \(cy - 28) L\(cx + 38) \(cy + 16) Q\(cx + 18) \(cy + 16) \(cx + 1) \(cy + 26) Z", GoobyInkColor.book)
        for petal in 0..<5 {
            let angle = -CGFloat.pi / 2 + CGFloat(petal) * 2 * .pi / 5
            ink.ellipse(cx + 20 + cos(angle) * 4.5, cy - 3 + sin(angle) * 4.5, 3.6, 3.6, .white)
        }
        ink.ellipse(cx + 20, cy - 3, 2.6, 2.6, Color(hex: 0xF6CF62))
    }

    // MARK: Sleeping loaf

    private func sleeping() {
        ink.path("M-92 130 C-100 96 -76 62 -30 56 C20 50 78 60 96 96 C108 120 98 138 70 138 L-72 138 C-86 138 -92 136 -92 130 Z", fur.body)
        ink.ellipse(54, 82, 40, 34, pack)
        ink.path("M30 56 C14 70 14 104 32 112 C24 92 24 72 30 56 Z", .black, 0.16)
        ink.ellipse(66, 70, 12, 9, .white, 0.14)
        ink.ellipse(96, 132, 16, 9, GoobyInkColor.foot)
        ear(ink, base: CGPoint(x: -34, y: 52), angle: -62 + pose.earLeft, length: 88, width: 40)
        ear(ink, base: CGPoint(x: -6, y: 46), angle: -30 + pose.earRight, length: 90, width: 42)
        ink.path("M-104 106 C-108 70 -78 44 -42 44 C-6 44 18 68 16 100 C14 128 -10 140 -44 140 C-80 140 -102 132 -104 106 Z", fur.body)
        for x: CGFloat in [-72, -22] {
            ink.stroke("M\(x - 10) 96 Q\(x) 104 \(x + 10) 96", GoobyInkColor.eye, 3.4)
        }
        ink.path("M-52 104 C-52 100 -40 100 -40 104 C-40 107 -44 110 -46 110 C-48 110 -52 107 -52 104 Z", GoobyInkColor.nose)
        ink.ellipse(-90, 116, 13, 9, fur.cheek)
        ink.ellipse(-2, 112, 13, 9, fur.cheek)
        ink.ellipse(-64, 134, 15, 9, fur.shade)
        ink.ellipse(-30, 136, 15, 9, fur.shade)
        ink.ellipse(-64, 132, 15, 9, fur.body)
        ink.ellipse(-30, 134, 15, 9, fur.body)
    }

    // MARK: Back view

    private func backView() {
        let step = pose.step
        ink.ellipse(-26, 140 + min(0, step) * 4, 18, 10, GoobyInkColor.foot)
        ink.ellipse(26, 138 + min(0, -step) * 4, 18, 10, GoobyInkColor.foot)
        ink.path(Self.bodyPath(top: 18, bottom: 140, half: 62), fur.body)
        ink.ellipse(34, 112, 18, 16, fur.shade)
        ink.ellipse(32, 110, 18, 16, GoobyInkColor.tail)
        ink.stroke("M-58 48 L\(-68 - step * 4) 84", fur.body, 20)
        ink.stroke("M58 48 L\(66 + step * 4) 82", fur.body, 20)
        ear(ink, base: CGPoint(x: -30, y: -62), angle: -12 + pose.earLeft, inner: false)
        ear(ink, base: CGPoint(x: 30, y: -64), angle: 10 + pose.earRight, inner: false)
        ink.path(Self.headPath, fur.body)
        ink.ellipse(-30, -44, 22, 14, .white, 0.25)
        ink.path("M-48 44 C-50 22 -30 16 0 16 C30 16 50 22 48 44 L50 98 C50 114 30 118 0 118 C-30 118 -50 114 -50 98 Z", pack)
        ink.path("M-48 44 C-50 22 -30 16 0 16 C30 16 50 22 48 44 L48 58 C30 66 -30 66 -48 58 Z", .black, 0.16)
        ink.path("M-30 74 C-30 70 30 70 30 74 L30 100 C30 106 -30 106 -30 100 Z", .black, 0.09)
        ink.ellipse(0, 62, 6, 5, Color(hex: 0xE8A04A))
        for line in [(76.0, 116.0, 90.0, 110.0), (80, 130, 96, 128), (72, 100, 82, 90)] {
            ink.stroke("M\(line.0) \(line.1) L\(line.2) \(line.3)", GoobyInkColor.lavender, 3.5)
        }
    }

    // MARK: Marks around Gooby

    private func marks() {
        let marks = pose.marks
        let pulse = 0.75 + 0.25 * sin(pose.markPhase * 4)
        if marks.contains(.sparkle) {
            for line in [(84.0, -92.0, 96.0, -104.0), (90, -74, 106, -78), (78, -110, 82, -124)] {
                ink.stroke("M\(line.0) \(line.1) L\(line.2) \(line.3)", GoobyInkColor.yellow, 4, pulse)
            }
        }
        if marks.contains(.question) {
            ink.stroke("M84 -112 C84 -126 106 -126 106 -112 C106 -102 95 -102 95 -92", GoobyInkColor.lavender, 5)
            ink.ellipse(95, -82, 3.2, 3.2, GoobyInkColor.lavender)
            ink.stroke("M70 -96 L64 -112", GoobyInkColor.yellow, 4, pulse)
        }
        if marks.contains(.alert) {
            ink.stroke("M88 -96 L84 -118", GoobyInkColor.yellow, 4.5)
            ink.ellipse(90, -86, 3, 3, GoobyInkColor.yellow)
            ink.stroke("M100 -88 L112 -104", GoobyInkColor.yellow, 4, pulse)
        }
        if marks.contains(.zzz) {
            for (index, letter) in [(26.0, 6.0, 6.0), (42, -8, 7.5), (60, -26, 9)].enumerated() {
                let (x, y, s) = letter
                let fade = 0.55 + 0.45 * sin(pose.markPhase * 1.6 - Double(index) * 0.9)
                ink.stroke("M\(x - s) \(y - s) L\(x + s) \(y - s) L\(x - s) \(y + s) L\(x + s) \(y + s)", GoobyInkColor.lavender, 3.6, fade)
            }
        }
        if marks.contains(.hearts) {
            let rise = CGFloat(sin(pose.markPhase * 2)) * 4
            heart(x: 86, y: -88 + rise, scale: 1)
            heart(x: -84, y: -64 - rise, scale: 0.7)
        }
    }

    private func heart(x: CGFloat, y: CGFloat, scale: CGFloat) {
        ink.group(around: CGPoint(x: x, y: y), sx: scale, sy: scale) { mark in
            mark.path("M\(x) \(y + 10) C\(x - 14) \(y) \(x - 12) \(y - 12) \(x - 5) \(y - 12) C\(x - 2) \(y - 12) \(x) \(y - 9) \(x) \(y - 7) C\(x) \(y - 9) \(x + 2) \(y - 12) \(x + 5) \(y - 12) C\(x + 12) \(y - 12) \(x + 14) \(y) \(x) \(y + 10) Z", GoobyInkColor.heart)
        }
    }

    // MARK: Shared outlines

    static let headPath: String = {
        let cx: CGFloat = 3
        let cy: CGFloat = -20
        let rx: CGFloat = 74
        let ry: CGFloat = 62
        let parts = [
            "M\(cx - rx) \(cy + 4)",
            "C\(cx - rx) \(cy - 40) \(cx - 40) \(cy - ry) \(cx) \(cy - ry)",
            "C\(cx + 40) \(cy - ry) \(cx + rx) \(cy - 40) \(cx + rx) \(cy + 4)",
            "C\(cx + rx) \(cy + 44) \(cx + 38) \(cy + ry) \(cx) \(cy + ry)",
            "C\(cx - 38) \(cy + ry) \(cx - rx) \(cy + 44) \(cx - rx) \(cy + 4) Z"
        ]
        return parts.joined(separator: " ")
    }()

    static func bodyPath(top: CGFloat, bottom: CGFloat, half: CGFloat) -> String {
        let parts = [
            "M\(-half + 12) \(top)",
            "C\(-half - 4) \(top + 22) \(-half - 6) \(bottom - 50) \(-half) \(bottom - 22)",
            "C\(-half + 4) \(bottom - 4) \(-half + 22) \(bottom) 0 \(bottom)",
            "C\(half - 22) \(bottom) \(half - 4) \(bottom - 4) \(half) \(bottom - 22)",
            "C\(half + 6) \(bottom - 50) \(half + 4) \(top + 22) \(half - 12) \(top) Z"
        ]
        return parts.joined(separator: " ")
    }
}

/// Absolute M, L, C, Q and Z commands, the subset the drawings use.
enum GoobyPathData {
    static func path(_ d: String) -> Path {
        var path = Path()
        let tokens = tokenize(d)
        var index = 0
        func number() -> CGFloat {
            guard index < tokens.count else { return 0 }
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
            case "Z":
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
        for character in d {
            if character == " " || character == "," {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else if "MLCQZ".contains(character) {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(character))
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}
