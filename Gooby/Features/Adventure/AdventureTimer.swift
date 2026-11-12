import SwiftUI

struct AdventureTimer: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var showPlace: () -> Void
    var comeHome: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(engine.t("adventure.started"))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
            panel
            Button(engine.t("adventure.show"), action: showPlace)
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
                .accessibilityIdentifier("adventure-show-location")
            Button(engine.t("adventure.comeHome"), action: comeHome)
                .buttonStyle(GoobyButtonStyle(fill: Theme.rose, ink: Theme.ink))
                .accessibilityIdentifier("adventure-come-home")
        }
    }

    private var panel: some View {
        VStack(spacing: 14) {
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: .walk,
                reduceMotion: reduceMotion,
                companion: nil,
                showCompanion: false
            )
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(AdventureText.petName(engine))
            track
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                clock
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Theme.sky, Theme.mint], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    private var track: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Theme.yellow).frame(width: 34, height: 34)
                AdventureBoltShape()
                    .fill(Theme.ink)
                    .frame(width: 14, height: 18)
            }
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(Theme.ink.opacity(0.45), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 8]))
            }
            .frame(height: 16)
            ZStack {
                Circle().fill(Theme.yellow).frame(width: 34, height: 34)
                Text("?")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(.horizontal, 8)
        .accessibilityHidden(true)
    }

    private var clock: some View {
        let left = AdventureText.remaining(engine)
        return VStack(spacing: 6) {
            if left > 0 {
                Text(engine.t("adventure.backIn"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text(AdventureText.clock(left))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            Text(AdventureText.share(engine, remaining: left))
                .font(.system(.body, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity)
    }
}

private struct AdventureBoltShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()
        path.move(to: CGPoint(x: width * 0.55, y: 0))
        path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.48, y: height * 0.55))
        path.addLine(to: CGPoint(x: width * 0.38, y: height))
        path.addLine(to: CGPoint(x: width * 0.88, y: height * 0.4))
        path.addLine(to: CGPoint(x: width * 0.52, y: height * 0.4))
        path.closeSubpath()
        return path
    }
}
