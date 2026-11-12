import SwiftUI

/// The morning question after the pledge. The drawn rabbit stays in the phone mock.
/// `group.app.mygooby.gooby` only exists once a signature grants the container, so this
/// step keeps going and says so when that folder is missing.
struct DayStartWidgetPage: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var onFinished: () -> Void
    @State private var entered = false
    @State private var showGuide = false
    @State private var finished = false

    private var groupReady: Bool { GoobyAppGroup.isAvailable }

    var body: some View {
        ZStack(alignment: .bottom) {
            DayStartPalette.stage.ignoresSafeArea()
            Color.black.opacity(0.28).ignoresSafeArea()
            sheet
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showGuide, onDismiss: { closeGuide() }) {
            LookWidgetSheet(engine: engine)
        }
        .onAppear {
            guard !entered else { return }
            if reduceMotion {
                entered = true
            } else {
                withAnimation(.spring(duration: 0.45, bounce: 0.18)) { entered = true }
            }
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 48)
            VStack(spacing: 12) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Text(engine.t("daystart.widget.title"))
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(DayStartPalette.widgetInk)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        sentence
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if !groupReady {
                            Text(engine.tf("daystart.widget.noGroup", GoobyAppGroup.defaultID))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(hex: 0xC9504A))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        DayStartPhoneMock(engine: engine, reduceMotion: reduceMotion)
                            .padding(.top, 4)
                    }
                    .padding(.top, 22)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                actions
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28)
                    .fill(Color.white)
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(color: Color.black.opacity(0.16), radius: 18, y: -4)
            }
        }
        .opacity(entered ? 1 : 0)
        .offset(y: entered ? 0 : 28)
    }

    private var sentence: Text {
        let body = Font.system(size: 16, weight: .semibold, design: .rounded)
        let strong = Font.system(size: 16, weight: .heavy, design: .rounded)
        return Text(engine.t("daystart.widget.lead")).font(body).foregroundStyle(DayStartPalette.widgetInk)
            + Text(engine.t("daystart.widget.emph")).font(strong).foregroundStyle(DayStartPalette.widgetGreen)
            + Text(engine.t("daystart.widget.rest")).font(body).foregroundStyle(DayStartPalette.widgetInk)
    }

    private var actions: some View {
        VStack(spacing: 6) {
            Button(action: openGuide) {
                Text(engine.t("daystart.widget.add"))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(DayStartPalette.widgetGreen, in: Capsule())
            }
            .buttonStyle(DayStartGreenPress(reduceMotion: reduceMotion))
            .disabled(finished)
            .accessibilityHint(Text(groupReady ? engine.t("daystart.widget.guide") : engine.tf("daystart.widget.noGroup", GoobyAppGroup.defaultID)))
            Button(action: skip) {
                Text(engine.t("daystart.widget.skip"))
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(DayStartPalette.widgetMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(finished)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 8)
    }

    private func openGuide() {
        guard !finished else { return }
        engine.haptics.soft()
        showGuide = true
    }

    private func skip() {
        guard !finished else { return }
        finished = true
        engine.haptics.soft()
        onFinished()
    }

    private func closeGuide() {
        guard !finished else { return }
        finished = true
        onFinished()
    }
}

private struct DayStartGreenPress: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.22), value: configuration.isPressed)
    }
}

struct DayStartPhoneMock: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color(hex: 0x1A2330))
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: 0x2C384C))
                .padding(10)
            VStack(spacing: 12) {
                Capsule()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: 72, height: 16)
                    .padding(.top, 16)
                HStack(alignment: .top, spacing: 8) {
                    widgetTile
                    VStack(spacing: 8) {
                        HStack(spacing: 8) { icon; icon }
                        HStack(spacing: 8) { icon; icon }
                        HStack(spacing: 8) { icon; icon }
                    }
                }
                HStack(spacing: 8) {
                    icon; icon; icon; icon
                }
                Spacer(minLength: 0)
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 84, height: 4)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)
        }
        .frame(width: 250, height: 300)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(engine.tf("daystart.widget.phone", DayStartCopy.petName(engine)))
    }

    private var widgetTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFFF8EF), Color(hex: 0xF3E8FF)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: .hearts,
                reduceMotion: reduceMotion,
                companion: nil
            )
            .frame(width: 92, height: 108)
            heart
                .offset(x: 26, y: -30)
        }
        .frame(width: 116, height: 128)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var heart: some View {
        ZStack {
            DayStartHeart()
                .fill(Color(hex: 0xF25CA8))
                .frame(width: 36, height: 32)
            DayStartDiamond()
                .fill(DayStartPalette.gold)
                .frame(width: 10, height: 10)
                .offset(x: -22, y: -8)
            DayStartDiamond()
                .fill(Color.white)
                .frame(width: 7, height: 7)
                .offset(x: 20, y: 6)
        }
        .accessibilityHidden(true)
    }

    private var icon: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(hex: 0x46546C))
            .frame(width: 30, height: 30)
    }
}

struct DayStartHeart: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.9))
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.32),
            control1: CGPoint(x: w * 0.18, y: h * 0.7),
            control2: CGPoint(x: 0, y: h * 0.52)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.28),
            control1: CGPoint(x: 0, y: h * 0.08),
            control2: CGPoint(x: w * 0.28, y: h * 0.06)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.32),
            control1: CGPoint(x: w * 0.72, y: h * 0.06),
            control2: CGPoint(x: w, y: h * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.9),
            control1: CGPoint(x: w, y: h * 0.52),
            control2: CGPoint(x: w * 0.82, y: h * 0.7)
        )
        path.closeSubpath()
        return path
    }
}
