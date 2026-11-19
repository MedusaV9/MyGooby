import SwiftUI

enum GoobyFaceMood: Equatable {
    case rest
    case low
    case dim
    case even
    case glad
    case bright
}

/// Close-up of Gooby for breathing and mood. Long ears and a pink nose, drawn with shapes.
struct GoobyCalmFace: View {
    var furID: String
    var mood: GoobyFaceMood
    var pulse: CGFloat

    var body: some View {
        let fur = FurPaint.resolve(furID)
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                chest(fur, side: side)
                ear(fur, side: side, lean: -20, dx: -side * 0.16)
                ear(fur, side: side, lean: 18, dx: side * 0.18)
                head(fur, side: side)
                features(fur, side: side)
            }
            .frame(width: side, height: side)
            .scaleEffect(pulse, anchor: UnitPoint(x: 0.5, y: 0.62))
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }

    private func chest(_ fur: FurPaint, side: CGFloat) -> some View {
        Ellipse()
            .fill(fur.body)
            .frame(width: side * 1.2, height: side * 0.58)
            .offset(y: side * 0.46)
    }

    private func ear(_ fur: FurPaint, side: CGFloat, lean: Double, dx: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(fur.shade)
                .frame(width: side * 0.16, height: side * 0.42)
                .offset(x: side * 0.012, y: side * 0.012)
            Capsule()
                .fill(fur.body)
                .frame(width: side * 0.15, height: side * 0.40)
            Capsule()
                .fill(fur.innerEar)
                .frame(width: side * 0.07, height: side * 0.22)
                .offset(y: side * 0.02)
        }
        .rotationEffect(.degrees(lean), anchor: .bottom)
        .offset(x: dx, y: -side * 0.30)
    }

    private func head(_ fur: FurPaint, side: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(fur.shade)
                .frame(width: side * 0.76, height: side * 0.68)
                .offset(y: side * 0.035)
            Ellipse()
                .fill(fur.body)
                .frame(width: side * 0.72, height: side * 0.64)
                .offset(y: side * 0.012)
            Ellipse()
                .fill(Color.white.opacity(0.18))
                .frame(width: side * 0.28, height: side * 0.16)
                .offset(x: -side * 0.12, y: -side * 0.12)
            Ellipse()
                .fill(fur.bib)
                .frame(width: side * 0.36, height: side * 0.22)
                .offset(y: side * 0.16)
        }
    }

    private func features(_ fur: FurPaint, side: CGFloat) -> some View {
        let gap = side * 0.14
        return ZStack {
            Ellipse()
                .fill(fur.cheek.opacity(0.9))
                .frame(width: side * 0.13, height: side * 0.08)
                .offset(x: -side * 0.2, y: side * 0.04)
            Ellipse()
                .fill(fur.cheek.opacity(0.9))
                .frame(width: side * 0.12, height: side * 0.075)
                .offset(x: side * 0.2, y: side * 0.03)
            eye(side: side)
                .offset(x: -gap, y: -side * 0.02)
            eye(side: side)
                .offset(x: gap, y: -side * 0.02)
            nose(side: side)
                .offset(y: side * 0.075)
            mouth(side: side)
                .offset(y: side * 0.145)
        }
    }

    @ViewBuilder
    private func eye(side: CGFloat) -> some View {
        let color = GoobyInkColor.eye
        let width = side * 0.095
        switch mood {
        case .rest:
            EyeArc(lift: -0.7)
                .stroke(color, style: StrokeStyle(lineWidth: max(2, side * 0.012), lineCap: .round))
                .frame(width: width, height: width * 0.42)
        case .low:
            EyeArc(lift: -1.1)
                .stroke(color, style: StrokeStyle(lineWidth: max(2, side * 0.013), lineCap: .round))
                .frame(width: width * 1.05, height: width * 0.48)
        case .dim:
            Capsule()
                .fill(color)
                .frame(width: width * 0.9, height: max(2.5, side * 0.012))
        case .bright:
            EyeArc(lift: 1.15)
                .stroke(color, style: StrokeStyle(lineWidth: max(2.4, side * 0.014), lineCap: .round))
                .frame(width: width * 1.05, height: width * 0.55)
        case .even, .glad:
            ZStack {
                Ellipse()
                    .fill(color)
                    .frame(width: width * 0.42, height: width * (mood == .glad ? 0.58 : 0.5))
                Circle()
                    .fill(Color.white)
                    .frame(width: width * 0.14, height: width * 0.14)
                    .offset(x: width * 0.06, y: -width * 0.08)
            }
            .frame(width: width, height: width * 0.6)
        }
    }

    private func nose(side: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(GoobyInkColor.nose)
                .frame(width: side * 0.07, height: side * 0.046)
            Capsule()
                .fill(GoobyInkColor.mouth.opacity(0.85))
                .frame(width: max(1.5, side * 0.008), height: side * 0.028)
                .offset(y: side * 0.03)
        }
    }

    private func mouth(side: CGFloat) -> some View {
        let lift: CGFloat
        let width: CGFloat
        switch mood {
        case .rest:
            lift = 5
            width = side * 0.05
        case .low:
            lift = -12
            width = side * 0.09
        case .dim:
            lift = -6
            width = side * 0.07
        case .even:
            lift = 0
            width = side * 0.05
        case .glad:
            lift = 10
            width = side * 0.08
        case .bright:
            lift = 16
            width = side * 0.11
        }
        return MouthArc(lift: lift)
            .stroke(GoobyInkColor.mouth, style: StrokeStyle(lineWidth: max(2, side * 0.01), lineCap: .round))
            .frame(width: width, height: side * 0.06)
    }
}

private struct EyeArc: Shape {
    var lift: CGFloat

    var animatableData: CGFloat {
        get { lift }
        set { lift = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.midY - rect.height * lift)
        )
        return path
    }
}

private struct MouthArc: Shape {
    var lift: CGFloat

    var animatableData: CGFloat {
        get { lift }
        set { lift = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: y))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: y),
            control: CGPoint(x: rect.midX, y: y + lift)
        )
        return path
    }
}
