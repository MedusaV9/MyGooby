import SwiftUI

struct DayStartAffirmationPage: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var onStart: () -> Void

    var body: some View {
        DayStartPage(alignTop: true, buttonTitle: engine.t("daystart.start"), reduceMotion: reduceMotion, action: onStart) {
            VStack(spacing: 18) {
                header
                card
                    .padding(.horizontal, 2)
                    .padding(.vertical, 14)
                VStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(DayStartPalette.gold)
                        .accessibilityHidden(true)
                    Text(engine.tf(DayStartCopy.energyKey(engine.pet.pronouns), DayStartCopy.petName(engine)))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(engine.tf("daystart.day", DayStartCopy.dayNumber(engine)))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(Color.white.opacity(0.92))
            Text(engine.t("daystart.hello.\(min(7, max(1, DayStartCopy.weekdayNumber(engine))))"))
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
        }
        .accessibilityElement(children: .combine)
    }

    private var card: some View {
        VStack(spacing: 0) {
            Text(engine.t("daystart.affirm.label"))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(Color.white)
                .padding(.top, 18)
            sentence
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(3)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            ZStack {
                DayStartLamp()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 18)
                    .padding(.bottom, 14)
                DayStartClock()
                    .offset(x: -16, y: 10)
                sparkles
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: reduceMotion ? .idle : .think,
                    reduceMotion: reduceMotion,
                    companion: nil
                )
                .frame(width: 124, height: 146)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 2)
                .accessibilityLabel(DayStartCopy.petName(engine))
            }
            .frame(height: 168)
        }
        .frame(maxWidth: .infinity)
        .background(DayStartPalette.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.black.opacity(0.16), radius: 16, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(engine.t("daystart.affirm.label")). \(spokenSentence)")
    }

    private var sentence: Text {
        let font = Font.system(size: 26, weight: .bold, design: .rounded)
        return Text(lead).foregroundStyle(Color.white).font(font)
            + Text(rest).foregroundStyle(DayStartPalette.gold).font(font)
    }

    private var spokenSentence: String { lead + rest }

    private var lead: String {
        engine.t("daystart.affirm.\(DayStartCopy.affirmationIndex(engine)).lead")
    }

    private var rest: String {
        engine.t("daystart.affirm.\(DayStartCopy.affirmationIndex(engine)).rest")
    }

    private var sparkles: some View {
        ZStack {
            Circle().fill(DayStartPalette.gold).frame(width: 7, height: 7).offset(x: -78, y: -36)
            Circle().fill(Color.white).frame(width: 5, height: 5).offset(x: 36, y: -48)
            Circle().fill(Color.white.opacity(0.9)).frame(width: 4, height: 4).offset(x: -40, y: 8)
        }
        .accessibilityHidden(true)
    }
}

struct DayStartClock: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let face = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.fill(face, with: .color(Color.white))

            for index in 0..<12 {
                let degrees = Double(index) * 30 - 90
                let inner = visualPoint(center: center, degrees: degrees, radius: radius * 0.76)
                let outer = visualPoint(center: center, degrees: degrees, radius: radius * 0.90)
                var tick = Path()
                tick.move(to: inner)
                tick.addLine(to: outer)
                context.stroke(
                    tick,
                    with: .color(DayStartPalette.ink.opacity(0.28)),
                    style: StrokeStyle(lineWidth: index % 3 == 0 ? 2.6 : 1.6, lineCap: .round)
                )
            }

            eye(in: &context, at: CGPoint(x: center.x - 14, y: center.y - 6))
            eye(in: &context, at: CGPoint(x: center.x + 14, y: center.y - 6))

            var smile = Path()
            smile.move(to: CGPoint(x: center.x - 11, y: center.y + 10))
            smile.addQuadCurve(
                to: CGPoint(x: center.x + 11, y: center.y + 10),
                control: CGPoint(x: center.x, y: center.y + 20)
            )
            context.stroke(smile, with: .color(DayStartPalette.ink), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

            let arrowRadius = radius * 0.58
            var arrow = Path()
            let samples = Array(stride(from: 214.0, through: 64.0, by: -8.0))
            if let first = samples.first {
                arrow.move(to: visualPoint(center: center, degrees: first, radius: arrowRadius))
                for degrees in samples.dropFirst() {
                    arrow.addLine(to: visualPoint(center: center, degrees: degrees, radius: arrowRadius))
                }
            }
            context.stroke(arrow, with: .color(DayStartPalette.coral), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            if samples.count >= 2 {
                let end = visualPoint(center: center, degrees: samples[samples.count - 1], radius: arrowRadius)
                let before = visualPoint(center: center, degrees: samples[samples.count - 2], radius: arrowRadius)
                strokeHead(in: &context, from: before, to: end)
            }
        }
        .frame(width: 118, height: 118)
        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
        .accessibilityHidden(true)
    }

    private func visualPoint(center: CGPoint, degrees: Double, radius: CGFloat) -> CGPoint {
        let radians = degrees * .pi / 180
        return CGPoint(x: center.x + CGFloat(cos(radians)) * radius, y: center.y - CGFloat(sin(radians)) * radius)
    }

    private func eye(in context: inout GraphicsContext, at point: CGPoint) {
        var path = Path()
        path.move(to: CGPoint(x: point.x - 8, y: point.y))
        path.addQuadCurve(to: CGPoint(x: point.x + 8, y: point.y), control: CGPoint(x: point.x, y: point.y - 7))
        context.stroke(path, with: .color(DayStartPalette.ink), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
    }

    private func strokeHead(in context: inout GraphicsContext, from before: CGPoint, to end: CGPoint) {
        let dx = end.x - before.x
        let dy = end.y - before.y
        let length = max(CGFloat(0.001), (dx * dx + dy * dy).squareRoot())
        let ux = dx / length
        let uy = dy / length
        let px = -uy
        let py = ux
        let wing: CGFloat = 9
        var head = Path()
        head.move(to: CGPoint(x: end.x - ux * wing + px * wing * 0.55, y: end.y - uy * wing + py * wing * 0.55))
        head.addLine(to: end)
        head.addLine(to: CGPoint(x: end.x - ux * wing - px * wing * 0.55, y: end.y - uy * wing - py * wing * 0.55))
        context.stroke(head, with: .color(DayStartPalette.coral), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }
}

struct DayStartLamp: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Ellipse()
                    .fill(DayStartPalette.gold.opacity(0.7))
                    .frame(width: 36, height: 12)
                    .offset(y: 10)
                    .blur(radius: 1)
                DayStartShade()
                    .fill(DayStartPalette.cardDeep)
                    .frame(width: 52, height: 26)
            }
            Rectangle()
                .fill(DayStartPalette.cardDeep)
                .frame(width: 5, height: 20)
            Capsule()
                .fill(DayStartPalette.cardDeep)
                .frame(width: 32, height: 8)
        }
        .accessibilityHidden(true)
    }
}

struct DayStartShade: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
