import SwiftUI

struct ProfileForestPreview: View {
    var seeAll: String

    private let artHeight: CGFloat = 291

    var body: some View {
        ZStack(alignment: .topLeading) {
            if ScreenArt.image("profile-forest-header") != nil {
                Color(hex: 0xB7E4F6)
                ScreenArtView(name: "profile-forest-header", mode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: artHeight)
            } else {
            Group {
            Color.clear
            Circle().fill(shape).frame(width: 64, height: 64).position(x: 65.7, y: 63)
            ForestSprigShape().fill(sprig).frame(width: 14, height: 18).rotationEffect(.degrees(35)).position(x: 118, y: 28)
            heart(9).position(x: 247, y: 21)
            ForestCherries().fill(shape).frame(width: 64, height: 66).position(x: 295.5, y: 40)
            ForestBush().fill(shape).frame(width: 114, height: 107).position(x: 181.6, y: 123)
            ForestSparkle().stroke(shape, style: StrokeStyle(lineWidth: 2.4, lineCap: .round)).frame(width: 34, height: 34).position(x: 213, y: 80)
            Circle().fill(shape).frame(width: 13, height: 13).position(x: 213, y: 80)
            Image(systemName: "star.fill").font(.system(size: 10)).foregroundStyle(sprig).position(x: 295, y: 111)
            ForestSprigShape().fill(sprig).frame(width: 16, height: 22).rotationEffect(.degrees(-12)).position(x: 62, y: 131)
            ForestBunny().fill(shape).frame(width: 96, height: 92).position(x: 88, y: 190)
            ForestLeaf().fill(shape).frame(width: 57, height: 60).position(x: 300, y: 177.5)
            Circle().fill(shape).frame(width: 67, height: 67).position(x: 216.5, y: 240)
            heart(10).position(x: 157, y: 223)
            ForestSprigShape().fill(sprig).frame(width: 10, height: 13).rotationEffect(.degrees(60)).position(x: 337, y: 238)
            }
            }
            LinearGradient(colors: [ProfilePalette.paper.opacity(0), ProfilePalette.paper.opacity(0.9), ProfilePalette.paper], startPoint: .top, endPoint: .bottom)
                .frame(width: 420, height: 90)
                .position(x: 186.3, y: 238)
            seeAllPill
                .position(x: 186.3, y: 259)
        }
        .frame(maxWidth: .infinity)
        .frame(height: artHeight)
        .clipped()
        .accessibilityHidden(true)
    }

    private var shape: Color { ProfilePalette.forestShape }
    private var sprig: Color { ProfilePalette.forestSprig }

    private func heart(_ size: CGFloat) -> some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size))
            .foregroundStyle(sprig)
    }

    private var seeAllPill: some View {
        HStack(spacing: 6) {
            Text(seeAll)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            ChevronGlyph(direction: .down)
        }
        .foregroundStyle(ProfilePalette.seeAllInk)
        .frame(width: 128, height: 36)
        .background(ProfilePalette.seeAllPill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ProfileGround: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 7))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + 7), control: CGPoint(x: rect.midX, y: rect.minY - 7))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ForestSprigShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.midX - w * 0.07, y: rect.minY + h * 0.2, width: w * 0.14, height: h * 0.8), cornerSize: CGSize(width: w * 0.07, height: w * 0.07))
        path.addEllipse(in: CGRect(x: rect.midX - w * 0.2, y: rect.minY, width: w * 0.4, height: h * 0.36))
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY + h * 0.3, width: w * 0.46, height: h * 0.3))
        path.addEllipse(in: CGRect(x: rect.maxX - w * 0.46, y: rect.minY + h * 0.42, width: w * 0.46, height: h * 0.3))
        return path
    }
}

private struct ForestCherries: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY + h * 0.46, width: w * 0.52, height: w * 0.52))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.4, y: rect.minY + h * 0.5, width: w * 0.52, height: w * 0.52))
        var stems = Path()
        stems.move(to: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + h * 0.5))
        stems.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.08), control: CGPoint(x: rect.minX + w * 0.36, y: rect.minY + h * 0.14))
        stems.move(to: CGPoint(x: rect.minX + w * 0.68, y: rect.minY + h * 0.54))
        stems.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.08), control: CGPoint(x: rect.minX + w * 0.6, y: rect.minY + h * 0.3))
        path.addPath(stems.strokedPath(StrokeStyle(lineWidth: 3.2, lineCap: .round)))
        var leaf = Path()
        leaf.move(to: CGPoint(x: rect.minX + w * 0.64, y: rect.minY + h * 0.07))
        leaf.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.32), control: CGPoint(x: rect.minX + w * 0.98, y: rect.minY))
        leaf.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.64, y: rect.minY + h * 0.07), control: CGPoint(x: rect.minX + w * 0.7, y: rect.minY + h * 0.34))
        path.addPath(leaf)
        return path
    }
}

private struct ForestBush: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.04, y: rect.minY + h * 0.28, width: w * 0.92, height: h * 0.72))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.32, y: rect.minY, width: w * 0.36, height: h * 0.38))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.12, y: rect.minY + h * 0.1, width: w * 0.32, height: h * 0.36))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.56, y: rect.minY + h * 0.08, width: w * 0.3, height: h * 0.34))
        path.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + h * 0.26, width: w * 0.2, height: h * 0.3), cornerSize: CGSize(width: w * 0.08, height: w * 0.08))
        path.addRoundedRect(in: CGRect(x: rect.maxX - w * 0.18, y: rect.minY + h * 0.3, width: w * 0.18, height: h * 0.28), cornerSize: CGSize(width: w * 0.08, height: w * 0.08))
        return path
    }
}

private struct ForestSparkle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for index in 0..<7 {
            let angle = Double(index) / 7 * .pi * 2 - .pi / 2
            let dx = CGFloat(cos(angle))
            let dy = CGFloat(sin(angle))
            path.move(to: CGPoint(x: center.x + dx * radius * 0.62, y: center.y + dy * radius * 0.62))
            path.addLine(to: CGPoint(x: center.x + dx * radius, y: center.y + dy * radius))
        }
        return path
    }
}

private struct ForestLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + w * 0.14, y: rect.maxY - h * 0.12))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.minX - w * 0.12, y: rect.minY + h * 0.06))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.14, y: rect.maxY - h * 0.12), control: CGPoint(x: rect.maxX + w * 0.02, y: rect.maxY - h * 0.08))
        path.closeSubpath()
        var stem = Path()
        stem.move(to: CGPoint(x: rect.minX + w * 0.16, y: rect.maxY - h * 0.14))
        stem.addLine(to: CGPoint(x: rect.minX + w * 0.04, y: rect.maxY))
        path.addPath(stem.strokedPath(StrokeStyle(lineWidth: 4, lineCap: .round)))
        return path
    }
}

private struct ForestBunny: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.2, y: rect.minY + h * 0.5, width: w * 0.66, height: h * 0.5))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.14, y: rect.minY + h * 0.24, width: w * 0.5, height: h * 0.46))
        let ear = Path(roundedRect: CGRect(x: 0, y: 0, width: w * 0.15, height: h * 0.4), cornerRadius: w * 0.075)
        path.addPath(ear.applying(CGAffineTransform(rotationAngle: -0.18).concatenating(CGAffineTransform(translationX: rect.minX + w * 0.22, y: rect.minY + h * 0.04))))
        path.addPath(ear.applying(CGAffineTransform(rotationAngle: 0.26).concatenating(CGAffineTransform(translationX: rect.minX + w * 0.44, y: rect.minY))))
        path.addRoundedRect(in: CGRect(x: rect.minX + w * 0.62, y: rect.minY + h * 0.44, width: w * 0.3, height: h * 0.38), cornerSize: CGSize(width: w * 0.1, height: w * 0.1))
        path.addEllipse(in: CGRect(x: rect.maxX - w * 0.16, y: rect.maxY - h * 0.3, width: w * 0.16, height: w * 0.16))
        path.addEllipse(in: CGRect(x: rect.minX + w * 0.08, y: rect.maxY - h * 0.14, width: w * 0.3, height: h * 0.14))
        return path
    }
}
