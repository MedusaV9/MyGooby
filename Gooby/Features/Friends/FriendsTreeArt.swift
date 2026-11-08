import SwiftUI

enum FriendsPaint {
    static let skyTop = Color(hex: 0x526DB4)
    static let skyMid = Color(hex: 0x5D74B7)
    static let skyLow = Color(hex: 0x687ABA)
    static let skyBottom = Color(hex: 0x717FBE)
    static let bright = Color(hex: 0x63AA4A)
    static let mid = Color(hex: 0x449B3C)
    static let dark = Color(hex: 0x2E7332)
    static let deep = Color(hex: 0x1B7F27)
    static let grass = Color(hex: 0x7BB65C)
    static let trunk = Color(hex: 0x6D5030)
    static let wood = Color(hex: 0xD8A682)
    static let post = Color(hex: 0xC88155)
    static let nail = Color(hex: 0xF4E4D4)
    static let banner = Color(hex: 0x3F933D)
    static let bannerShade = Color(hex: 0x2F6E2E)
    static let gold = Color(hex: 0xE4C83C)
    static let buttonInk = Color(hex: 0x47971C)
    static let owner = Color(hex: 0xD2FFB3)
    static let chevronFill = Color(hex: 0xA8D4A6)
    static let gearGray = Color(hex: 0xA6B4BE)
    static let gearHole = Color(hex: 0x5F75B9)
    static let cream = Color(hex: 0xFFF6EA)
    static let creamShade = Color(hex: 0xF0D8C4)
    static let ear = Color(hex: 0xFFC2D6)
    static let cheek = Color(hex: 0xFFB7CC)
    static let eye = Color(hex: 0x8B5A34)
    static let pupil = Color(hex: 0x3A2416)
    static let nose = Color(hex: 0xFF9BB8)
    static let mouth = Color(hex: 0xC46B86)
    static let tongue = Color(hex: 0xFF8EAB)
    static let cap = Color(hex: 0xF3A0C0)
    static let capLight = Color(hex: 0xFFD0E4)
    static let heart = Color(hex: 0xFF8FB3)

    static let outline: [(CGFloat, CGFloat)] = [
        (0, 191), (10, 180), (20, 172), (30, 165), (40, 158), (50, 152), (60, 146), (70, 141),
        (80, 138), (90, 134), (100, 132), (110, 130), (120, 130), (130, 130), (140, 131), (150, 133),
        (160, 137), (170, 142), (180, 148), (190, 152), (200, 148), (210, 145), (220, 144), (230, 144),
        (240, 140), (250, 135), (260, 132), (270, 131), (280, 131), (290, 132), (300, 135), (310, 139),
        (320, 146), (330, 155), (340, 172), (350, 184), (360, 186), (370, 189), (380, 194), (390, 200)
    ]

    static let blobs: [(CGFloat, CGFloat, CGFloat, CGFloat, Color)] = [
        (98, 205, 118, 86, bright),
        (292, 208, 120, 88, dark),
        (332, 305, 78, 100, deep),
        (52, 312, 100, 92, dark),
        (318, 438, 112, 78, bright),
        (78, 450, 120, 90, mid),
        (205, 408, 78, 48, bright),
        (196, 328, 78, 62, mid)
    ]
}

struct FriendsTreeCanvas: View {
    var showInvite: Bool
    var leftOpen: Bool
    var rightOpen: Bool

    var body: some View {
        Canvas { context, size in
            let sx = size.width / 390
            let sy = size.height / 844
            context.scaleBy(x: sx, y: sy)
            let sky = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: FriendsPaint.skyTop, location: 0),
                    .init(color: FriendsPaint.skyMid, location: 0.42),
                    .init(color: FriendsPaint.skyLow, location: 0.72),
                    .init(color: FriendsPaint.skyBottom, location: 1)
                ]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: 844)
            )
            context.fill(Path(CGRect(x: 0, y: 0, width: 390, height: 844)), with: sky)
            context.drawLayer { layer in
                layer.clip(to: canopyPath())
                layer.fill(Path(CGRect(x: 0, y: 120, width: 390, height: 530)), with: .color(FriendsPaint.mid))
                for blob in FriendsPaint.blobs {
                    let rect = CGRect(x: blob.0 - blob.2, y: blob.1 - blob.3, width: blob.2 * 2, height: blob.3 * 2)
                    layer.fill(Path(ellipseIn: rect), with: .color(blob.4))
                }
            }
            if leftOpen { sign(in: &context, post: CGRect(x: 75, y: 276, width: 7, height: 56), board: 49, boardY: 288, shadow: CGPoint(x: 78, y: 334)) }
            if rightOpen { sign(in: &context, post: CGRect(x: 309, y: 256, width: 7, height: 56), board: 283, boardY: 268, shadow: CGPoint(x: 312, y: 314)) }
            context.fill(grassPath(), with: .color(FriendsPaint.grass))
            context.fill(trunkPath(), with: .color(FriendsPaint.trunk))
            if showInvite {
                let shadow = CGRect(x: 16, y: 512, width: 358, height: 82)
                let plate = CGRect(x: 16, y: 508, width: 358, height: 82)
                context.fill(Path(roundedRect: shadow, cornerRadius: 22), with: .color(FriendsPaint.bannerShade))
                context.fill(Path(roundedRect: plate, cornerRadius: 22), with: .color(FriendsPaint.banner))
                mushroom(in: &context)
            }
            gear(in: &context)
        }
        .accessibilityHidden(true)
    }

    private func sign(in context: inout GraphicsContext, post: CGRect, board: CGFloat, boardY: CGFloat, shadow: CGPoint) {
        context.fill(Path(ellipseIn: CGRect(x: shadow.x - 11, y: shadow.y - 3.2, width: 22, height: 6.4)), with: .color(FriendsPaint.deep.opacity(0.35)))
        context.fill(Path(roundedRect: post, cornerRadius: 2), with: .color(FriendsPaint.post))
        context.fill(Path(roundedRect: CGRect(x: board, y: boardY, width: 59, height: 11), cornerRadius: 3), with: .color(FriendsPaint.wood))
        context.fill(Path(roundedRect: CGRect(x: board, y: boardY + 13, width: 59, height: 11), cornerRadius: 3), with: .color(FriendsPaint.wood))
        context.fill(Path(ellipseIn: CGRect(x: board + 20, y: boardY + 4.4, width: 2.2, height: 2.2)), with: .color(FriendsPaint.nail))
        context.fill(Path(ellipseIn: CGRect(x: board + 36, y: boardY + 4.4, width: 2.2, height: 2.2)), with: .color(FriendsPaint.nail))
    }

    private func mushroom(in context: inout GraphicsContext) {
        context.translateBy(x: 48, y: 551)
        context.fill(Path(ellipseIn: CGRect(x: -9, y: 13, width: 20, height: 6)), with: .color(FriendsPaint.bannerShade.opacity(0.28)))
        context.fill(Path(ellipseIn: CGRect(x: -7, y: -3, width: 16, height: 22)), with: .color(FriendsPaint.cream))
        context.fill(Path(ellipseIn: CGRect(x: -16, y: -14, width: 34, height: 24)), with: .color(FriendsPaint.cap))
        context.fill(Path(ellipseIn: CGRect(x: -11, y: -12, width: 20, height: 10)), with: .color(FriendsPaint.capLight.opacity(0.9)))
        context.fill(Path(ellipseIn: CGRect(x: -9.2, y: -6.2, width: 4.4, height: 4.4)), with: .color(FriendsPaint.cream))
        context.fill(Path(ellipseIn: CGRect(x: -0.7, y: -8.7, width: 3.4, height: 3.4)), with: .color(FriendsPaint.cream))
        context.fill(Path(ellipseIn: CGRect(x: 6, y: -5, width: 4, height: 4)), with: .color(FriendsPaint.cream))
        context.fill(Path(ellipseIn: CGRect(x: -6.3, y: 6.5, width: 4.6, height: 3)), with: .color(FriendsPaint.cheek))
        context.fill(Path(ellipseIn: CGRect(x: 3.7, y: 6.5, width: 4.6, height: 3)), with: .color(FriendsPaint.cheek))
        context.fill(Path(ellipseIn: CGRect(x: -3.2, y: 4.8, width: 2.4, height: 2.4)), with: .color(Theme.ink))
        context.fill(Path(ellipseIn: CGRect(x: 2.8, y: 4.8, width: 2.4, height: 2.4)), with: .color(Theme.ink))
        var smile = Path()
        smile.move(to: CGPoint(x: -1.5, y: 9))
        smile.addQuadCurve(to: CGPoint(x: 3.5, y: 9), control: CGPoint(x: 1, y: 11.2))
        context.stroke(smile, with: .color(Color(hex: 0xE989B0)), lineWidth: 0.9)
        heart(in: &context, at: CGPoint(x: -18, y: 0), scale: 1)
        heart(in: &context, at: CGPoint(x: 14, y: -12), scale: 0.9)
        context.translateBy(x: -48, y: -551)
    }

    private func heart(in context: inout GraphicsContext, at point: CGPoint, scale: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: point.x, y: point.y + 3 * scale))
        path.addCurve(to: CGPoint(x: point.x - 4 * scale, y: point.y), control1: CGPoint(x: point.x - 2 * scale, y: point.y + 2 * scale), control2: CGPoint(x: point.x - 4 * scale, y: point.y + 1.4 * scale))
        path.addCurve(to: CGPoint(x: point.x, y: point.y - 1.2 * scale), control1: CGPoint(x: point.x - 4 * scale, y: point.y - 2 * scale), control2: CGPoint(x: point.x - 1.4 * scale, y: point.y - 2 * scale))
        path.addCurve(to: CGPoint(x: point.x + 4 * scale, y: point.y), control1: CGPoint(x: point.x + 1.4 * scale, y: point.y - 2 * scale), control2: CGPoint(x: point.x + 4 * scale, y: point.y - 2 * scale))
        path.addCurve(to: CGPoint(x: point.x, y: point.y + 3 * scale), control1: CGPoint(x: point.x + 4 * scale, y: point.y + 1.4 * scale), control2: CGPoint(x: point.x + 2 * scale, y: point.y + 2 * scale))
        context.fill(path, with: .color(FriendsPaint.heart))
    }

    private func gear(in context: inout GraphicsContext) {
        context.translateBy(x: 339, y: 69)
        context.fill(gearPath(FriendsPaint.gearWhite), with: .color(.white))
        context.fill(gearPath(FriendsPaint.gearGray), with: .color(FriendsPaint.gearGray))
        context.fill(Path(ellipseIn: CGRect(x: 11.6, y: 11.6, width: 10.8, height: 10.8)), with: .color(.white))
        context.fill(Path(ellipseIn: CGRect(x: 13.7, y: 13.7, width: 6.6, height: 6.6)), with: .color(FriendsPaint.gearHole))
        context.translateBy(x: -339, y: -69)
    }
}

struct GoobyMark: View {
    var body: some View {
        ZStack {
            ear(tilt: -16).offset(x: -16, y: -22)
            ear(tilt: 16).offset(x: 16, y: -22)
            Circle().fill(FriendsPaint.creamShade).frame(width: 47, height: 47)
            Circle().fill(FriendsPaint.cream).frame(width: 46, height: 46).offset(y: -1)
            Ellipse().fill(Color.white.opacity(0.55)).frame(width: 16, height: 10).offset(x: -8, y: -12)
            Ellipse().fill(FriendsPaint.cheek).frame(width: 12.4, height: 8.4).offset(x: -13, y: 7)
            Ellipse().fill(FriendsPaint.cheek).frame(width: 12.4, height: 8.4).offset(x: 13, y: 7)
            eye.offset(x: -8, y: -3)
            eye.offset(x: 8, y: -3)
            Ellipse().fill(FriendsPaint.nose).frame(width: 6.2, height: 4.4).offset(y: 7)
            Smile().stroke(FriendsPaint.mouth, style: StrokeStyle(lineWidth: 1.5, lineCap: .round)).frame(width: 12.4, height: 6).offset(y: 12)
            Ellipse().fill(FriendsPaint.tongue).frame(width: 6.4, height: 4.6).offset(y: 13.2)
        }
        .frame(width: 70, height: 78)
        .accessibilityLabel("Gooby")
    }

    private func ear(tilt: Double) -> some View {
        ZStack {
            Capsule().fill(FriendsPaint.creamShade).frame(width: 14.4, height: 32)
            Capsule().fill(FriendsPaint.cream).frame(width: 14, height: 31)
            Capsule().fill(FriendsPaint.ear).frame(width: 6.8, height: 19).offset(y: 2.5)
        }
        .rotationEffect(.degrees(tilt))
    }

    private var eye: some View {
        ZStack {
            Ellipse().fill(FriendsPaint.eye).frame(width: 11.2, height: 12.4)
            Ellipse().fill(FriendsPaint.pupil).frame(width: 6.2, height: 6.8).offset(y: 1.1)
            Circle().fill(Color.white).frame(width: 3.6, height: 3.6).offset(x: -2, y: -2)
            Circle().fill(Color.white).frame(width: 1.8, height: 1.8).offset(x: 1.6, y: 1.3)
        }
        .frame(width: 12, height: 14)
    }
}

private struct Smile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + 1), control: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

private func canopyPath() -> Path {
    let pts = FriendsPaint.outline.map { CGPoint(x: $0.0, y: $0.1) }
    var path = Path()
    guard pts.count >= 3 else { return path }
    path.move(to: pts[0])
    for index in 1..<(pts.count - 1) {
        let next = pts[index + 1]
        let mid = CGPoint(x: (pts[index].x + next.x) / 2, y: (pts[index].y + next.y) / 2)
        path.addQuadCurve(to: mid, control: pts[index])
    }
    path.addLine(to: CGPoint(x: 390, y: 640))
    path.addLine(to: CGPoint(x: 0, y: 640))
    path.closeSubpath()
    return path
}

private func grassPath() -> Path {
    var path = Path()
    path.move(to: CGPoint(x: 0, y: 435))
    path.addCurve(to: CGPoint(x: 108, y: 498), control1: CGPoint(x: 28, y: 478), control2: CGPoint(x: 62, y: 504))
    path.addCurve(to: CGPoint(x: 190, y: 500), control1: CGPoint(x: 150, y: 492), control2: CGPoint(x: 168, y: 486))
    path.addCurve(to: CGPoint(x: 330, y: 494), control1: CGPoint(x: 230, y: 492), control2: CGPoint(x: 280, y: 486))
    path.addCurve(to: CGPoint(x: 390, y: 455), control1: CGPoint(x: 352, y: 498), control2: CGPoint(x: 368, y: 470))
    path.addLine(to: CGPoint(x: 390, y: 844))
    path.addLine(to: CGPoint(x: 0, y: 844))
    path.closeSubpath()
    return path
}

private func trunkPath() -> Path {
    var path = Path()
    let pts = [CGPoint(x: 147, y: 464), CGPoint(x: 236, y: 464), CGPoint(x: 221, y: 500), CGPoint(x: 202, y: 608), CGPoint(x: 184, y: 608), CGPoint(x: 166, y: 500)]
    path.move(to: pts[0])
    pts.dropFirst().forEach { path.addLine(to: $0) }
    path.closeSubpath()
    return path
}

private func gearPath(_ pts: [(CGFloat, CGFloat)]) -> Path {
    var path = Path()
    guard let first = pts.first else { return path }
    path.move(to: CGPoint(x: first.0, y: first.1))
    pts.dropFirst().forEach { path.addLine(to: CGPoint(x: $0.0, y: $0.1)) }
    path.closeSubpath()
    return path
}

private extension FriendsPaint {
    static let gearWhite: [(CGFloat, CGFloat)] = [
        (12.94, 7.21), (14.47, 1.81), (19.53, 1.81), (21.06, 7.21), (25.95, 4.47), (29.53, 8.05),
        (26.79, 12.94), (32.19, 14.47), (32.19, 19.53), (26.79, 21.06), (29.53, 25.95), (25.95, 29.53),
        (21.06, 26.79), (19.53, 32.19), (14.47, 32.19), (12.94, 26.79), (8.05, 29.53), (4.47, 25.95),
        (7.21, 21.06), (1.81, 19.53), (1.81, 14.47), (7.21, 12.94), (4.47, 8.05), (8.05, 4.47)
    ]
    static let gearGray: [(CGFloat, CGFloat)] = [
        (13.86, 9.42), (14.90, 4.37), (19.10, 4.37), (20.14, 9.42), (24.44, 6.59), (27.41, 9.56),
        (24.58, 13.86), (29.63, 14.90), (29.63, 19.10), (24.58, 20.14), (27.41, 24.44), (24.44, 27.41),
        (20.14, 24.58), (19.10, 29.63), (14.90, 29.63), (13.86, 24.58), (9.56, 27.41), (6.59, 24.44),
        (9.42, 20.14), (4.37, 19.10), (4.37, 14.90), (9.42, 13.86), (6.59, 9.56), (9.56, 6.59)
    ]
}
