import SwiftUI

enum FriendsPaint {
    static let skyTop = Color(hex: 0x526DB4)
    static let skyMid = Color(hex: 0x5D74B7)
    static let skyLow = Color(hex: 0x687ABA)
    static let skyBottom = Color(hex: 0x7983BF)
    static let skyHaze = Color(hex: 0x8088C2)
    static let bright = Color(hex: 0x63AA4A)
    static let mid = Color(hex: 0x449B3C)
    static let dark = Color(hex: 0x2E7332)
    static let deep = Color(hex: 0x1B7F27)
    static let bush = Color(hex: 0x45A443)
    static let grass = Color(hex: 0x7BB65C)
    static let trunk = Color(hex: 0x6D5030)
    static let wood = Color(hex: 0xD8A880)
    static let woodEdge = Color(hex: 0xBF8763)
    static let post = Color(hex: 0xC88155)
    static let nail = Color(hex: 0xF4E4D4)
    static let banner = Color(hex: 0x3F933D)
    static let bannerShade = Color(hex: 0x2F6E2E)
    static let gold = Color(hex: 0xE4C83C)
    static let buttonInk = Color(hex: 0x47971C)
    static let buttonLip = Color(hex: 0xE4E4E4)
    static let owner = Color(hex: 0xD6FEB5)
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
    static let cap = Color(hex: 0xF08BB3)
    static let capRim = Color(hex: 0xD9719C)
    static let capLight = Color(hex: 0xFFC6DD)
    static let stem = Color(hex: 0xFFF8EE)
    static let stemShade = Color(hex: 0xEADBCB)
    static let boot = Color(hex: 0x7A4E3A)
    static let heart = Color(hex: 0xFF7FA6)
    static let nightSky = [Color(hex: 0x4A4A7E), Color(hex: 0x4A4A7E), Color(hex: 0x645384)]
    static let daySky = [Color(hex: 0x5D7BC2), Color(hex: 0x6F8CCB), Color(hex: 0x93ABDB)]

    // Sign centre: post x and the middle of the two boards.
    static let leftSign = CGPoint(x: 79, y: 298)
    static let rightSign = CGPoint(x: 320, y: 278)
}

struct FriendsTreeCanvas: View {
    var showInvite: Bool
    var leftOpen: Bool
    var rightOpen: Bool
    var night: Bool = false

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width, 1) / 402
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    context.scaleBy(x: scale, y: scale)
                    let sky = night ? FriendsPaint.nightSky : FriendsPaint.daySky
                    context.fill(
                        Path(CGRect(x: 0, y: 0, width: 402, height: 874)),
                        with: .linearGradient(
                            Gradient(stops: [
                                .init(color: sky[0], location: 0),
                                .init(color: sky[1], location: 0.45),
                                .init(color: sky[2], location: 1)
                            ]),
                            startPoint: CGPoint(x: 0, y: 0),
                            endPoint: CGPoint(x: 0, y: 170)
                        )
                    )
                }
                FriendsTreeGrove(night: night, scale: scale)
                Canvas { context, _ in
                    context.scaleBy(x: scale, y: scale)
                    if leftOpen { sign(in: &context, at: FriendsPaint.leftSign) }
                    if rightOpen { sign(in: &context, at: FriendsPaint.rightSign) }
                    if showInvite {
                        context.fill(Path(roundedRect: CGRect(x: 16, y: 486, width: 370, height: 84), cornerRadius: 22), with: .color(FriendsPaint.banner))
                        mushroomPal(in: &context, at: CGPoint(x: 56, y: 528))
                    }
                    gear(in: &context)
                }
                .allowsHitTesting(false)
            }
        }
        .accessibilityHidden(true)
    }

    private func sign(in context: inout GraphicsContext, at c: CGPoint) {
        context.fill(Path(ellipseIn: CGRect(x: c.x - 14.5, y: c.y + 30.5, width: 29, height: 7)), with: .color(.black.opacity(0.16)))
        context.fill(Path(roundedRect: CGRect(x: c.x - 3, y: c.y - 23, width: 6, height: 56), cornerRadius: 3), with: .color(FriendsPaint.post))
        var boards = context
        boards.translateBy(x: c.x + 1, y: c.y)
        boards.rotate(by: .degrees(-3))
        for top in [CGFloat(-12), 0.8] {
            let plate = CGRect(x: -29, y: top, width: 58, height: 11.6)
            boards.fill(Path(roundedRect: plate, cornerRadius: 3), with: .color(FriendsPaint.woodEdge))
            boards.fill(Path(roundedRect: CGRect(x: plate.minX, y: plate.minY, width: plate.width, height: plate.height - 1.8), cornerRadius: 3), with: .color(FriendsPaint.wood))
            boards.fill(Path(ellipseIn: CGRect(x: -2.1, y: top + 2.6, width: 2.2, height: 2.2)), with: .color(FriendsPaint.nail))
        }
    }

    // A standing mushroom friend: pink cap, white stem with the face, arms, boots.
    private func mushroomPal(in context: inout GraphicsContext, at origin: CGPoint) {
        var pal = context
        pal.translateBy(x: origin.x, y: origin.y)
        pal.fill(Path(ellipseIn: CGRect(x: -15, y: 21.5, width: 30, height: 6)), with: .color(FriendsPaint.bannerShade.opacity(0.55)))
        pal.fill(Path(ellipseIn: CGRect(x: -10, y: 18, width: 9, height: 6)), with: .color(FriendsPaint.boot))
        pal.fill(Path(ellipseIn: CGRect(x: 1, y: 18, width: 9, height: 6)), with: .color(FriendsPaint.boot))
        var arms = pal
        arms.translateBy(x: -13, y: 10)
        arms.rotate(by: .degrees(28))
        arms.fill(Path(ellipseIn: CGRect(x: -3.5, y: -6, width: 7, height: 12)), with: .color(FriendsPaint.stemShade))
        arms = pal
        arms.translateBy(x: 13, y: 10)
        arms.rotate(by: .degrees(-28))
        arms.fill(Path(ellipseIn: CGRect(x: -3.5, y: -6, width: 7, height: 12)), with: .color(FriendsPaint.stemShade))
        pal.fill(Path(roundedRect: CGRect(x: -12, y: -3, width: 24, height: 25), cornerRadius: 10.5), with: .color(FriendsPaint.stemShade))
        pal.fill(Path(roundedRect: CGRect(x: -11.5, y: -3, width: 23, height: 23.5), cornerRadius: 10), with: .color(FriendsPaint.stem))
        var rim = Path()
        rim.move(to: CGPoint(x: -20, y: 1))
        rim.addCurve(to: CGPoint(x: 20, y: 1), control1: CGPoint(x: -20, y: -25), control2: CGPoint(x: 20, y: -25))
        rim.addQuadCurve(to: CGPoint(x: -20, y: 1), control: CGPoint(x: 0, y: 6))
        rim.closeSubpath()
        pal.fill(rim, with: .color(FriendsPaint.capRim))
        var cap = Path()
        cap.move(to: CGPoint(x: -19.5, y: -0.5))
        cap.addCurve(to: CGPoint(x: 19.5, y: -0.5), control1: CGPoint(x: -19.5, y: -25), control2: CGPoint(x: 19.5, y: -25))
        cap.addQuadCurve(to: CGPoint(x: -19.5, y: -0.5), control: CGPoint(x: 0, y: 3))
        cap.closeSubpath()
        pal.fill(cap, with: .color(FriendsPaint.cap))
        pal.fill(Path(ellipseIn: CGRect(x: -11, y: -16, width: 11, height: 5.5)), with: .color(FriendsPaint.capLight.opacity(0.75)))
        let spots: [(CGFloat, CGFloat, CGFloat)] = [(-10, -6, 3.2), (1.5, -12.5, 2.6), (10.5, -5.5, 3.4), (-1.5, -4, 2)]
        for (x, y, r) in spots {
            pal.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(FriendsPaint.stem))
        }
        pal.fill(Path(ellipseIn: CGRect(x: -9.5, y: 11, width: 5, height: 3.2)), with: .color(FriendsPaint.cheek))
        pal.fill(Path(ellipseIn: CGRect(x: 4.5, y: 11, width: 5, height: 3.2)), with: .color(FriendsPaint.cheek))
        for x in [CGFloat(-4.2), 4.2] {
            pal.fill(Path(ellipseIn: CGRect(x: x - 1.5, y: 6, width: 3, height: 3.8)), with: .color(FriendsPaint.pupil))
            pal.fill(Path(ellipseIn: CGRect(x: x - 0.9, y: 6.4, width: 1.2, height: 1.2)), with: .color(.white))
        }
        var smile = Path()
        smile.move(to: CGPoint(x: -2.2, y: 12))
        smile.addQuadCurve(to: CGPoint(x: 2.2, y: 12), control: CGPoint(x: 0, y: 14.6))
        pal.stroke(smile, with: .color(FriendsPaint.mouth), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        heart(in: &pal, at: CGPoint(x: -24, y: -9), scale: 0.9)
        heart(in: &pal, at: CGPoint(x: 25, y: -12), scale: 1.2)
        heart(in: &pal, at: CGPoint(x: 21, y: 8), scale: 0.8)
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
        var cog = context
        cog.translateBy(x: 371, y: 82)
        cog.scaleBy(x: 0.96, y: 0.96)
        cog.translateBy(x: -17, y: -17)
        cog.fill(gearPath(FriendsPaint.gearWhite), with: .color(.white))
        cog.fill(gearPath(FriendsPaint.gearInner), with: .color(FriendsPaint.gearGray))
        cog.fill(Path(ellipseIn: CGRect(x: 11.6, y: 11.6, width: 10.8, height: 10.8)), with: .color(.white))
        cog.fill(Path(ellipseIn: CGRect(x: 13.7, y: 13.7, width: 6.6, height: 6.6)), with: .color(FriendsPaint.gearHole))
    }
}

struct FriendsTreeGrove: View {
    var night: Bool
    var scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        ZStack(alignment: .topLeading) {
            tree("still-tree", x: 8, y: 70, w: 210, h: 270, sway: 1.3, seconds: 3.4)
            tree("still-tree-2", x: 200, y: 36, w: 210, h: 260, sway: 1.1, seconds: 3.8)
            tree("still-tree-3", x: 86, y: 168, w: 150, h: 180, sway: 1.6, seconds: 2.9)
            tree("still-tree-wave", x: 248, y: 190, w: 150, h: 190, sway: 1.8, seconds: 2.6)
            tree("still-bushes", x: 0, y: 400, w: 402, h: 150, sway: 0.7, seconds: 3.2)
            tree("still-flowers", x: 18, y: 470, w: 110, h: 78, sway: 2.2, seconds: 2.2)
            tree("still-flowers-2", x: 270, y: 460, w: 110, h: 78, sway: 2.0, seconds: 2.6)
            tree("still-daisies", x: 150, y: 500, w: 100, h: 70, sway: 1.7, seconds: 2.3)
        }
        .frame(width: 402 * scale, height: 874 * scale, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func tree(_ name: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, sway: Double, seconds: Double) -> some View {
        StageStill(name: name)
            .frame(width: w * scale, height: h * scale)
            .colorMultiply(night ? Color(hex: 0x5E8A52) : .white)
            .stageSway(amount: sway, seconds: seconds, still: reduce)
            .position(x: (x + w / 2) * scale, y: (y + h / 2) * scale)
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
    static let gearInner: [(CGFloat, CGFloat)] = [
        (13.86, 9.42), (14.90, 4.37), (19.10, 4.37), (20.14, 9.42), (24.44, 6.59), (27.41, 9.56),
        (24.58, 13.86), (29.63, 14.90), (29.63, 19.10), (24.58, 20.14), (27.41, 24.44), (24.44, 27.41),
        (20.14, 24.58), (19.10, 29.63), (14.90, 29.63), (13.86, 24.58), (9.56, 27.41), (6.59, 24.44),
        (9.42, 20.14), (4.37, 19.10), (4.37, 14.90), (9.42, 13.86), (6.59, 9.56), (9.56, 6.59)
    ]
}
