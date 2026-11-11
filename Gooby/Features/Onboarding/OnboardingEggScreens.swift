import SwiftUI

struct OnboardingSplashScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var onHatch: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 14) {
                Spacer(minLength: 12)
                OnboardingBunny(fur: "fur-cream", animation: .breathe, reduceMotion: reduceMotion, height: 220)
                Text("Gooby")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                Text(engine.t("onb.splash.subtitle"))
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(OnboardingPalette.subtitle)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 12)
                OnboardingPill(title: engine.t("onb.splash.hatch"), action: onHatch)
                Text(engine.t("onb.splash.local"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(OnboardingPalette.subtitle)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct OnboardingEggScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Binding var eggIndex: Int
    var onHatch: () -> Void
    var onSkip: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 16) {
                Text(engine.t("onb.egg.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)
                Text(engine.t("onb.egg.body"))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(OnboardingPalette.subtitle)
                    .multilineTextAlignment(.center)
                GeometryReader { geo in
                    let radius = min(118, geo.size.width / 2 - 36)
                    ZStack {
                        ForEach(Array(OnboardingScript.eggs.enumerated()), id: \.element.id) { index, egg in
                            let angle = -Double.pi / 2 + Double(index) * (2 * Double.pi / Double(OnboardingScript.eggs.count))
                            eggButton(egg, index: index)
                                .offset(x: cos(angle) * radius, y: sin(angle) * radius)
                        }
                        OnboardingBunny(
                            fur: OnboardingScript.eggs[eggIndex].id,
                            animation: .idle,
                            reduceMotion: reduceMotion,
                            height: min(150, radius + 20)
                        )
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(height: 340)
                .accessibilityElement(children: .contain)
                Spacer(minLength: 8)
                OnboardingPill(title: engine.t("onb.egg.hatch"), action: onHatch)
                Button(engine.t("common.skip"), action: onSkip)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(OnboardingPalette.subtitle)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
        }
    }

    private func eggButton(_ egg: OnboardingEgg, index: Int) -> some View {
        let selected = index == eggIndex
        return Button {
            eggIndex = index
            engine.haptics.soft()
        } label: {
            EggGlyph(egg: egg, width: selected ? 78 : 68)
                .padding(8)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(OnboardingPalette.fill)
                    }
                }
        }
        .buttonStyle(OnboardingPress())
        .accessibilityLabel(engine.t(egg.nameKey))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct OnboardingCrackScreen: View {
    var egg: OnboardingEgg
    var reduceMotion: Bool
    var continueLabel: String
    var onFinished: () -> Void

    @State private var crack: CGFloat = 0
    @State private var handed = false

    var body: some View {
        OnboardingScreen {
            TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 30.0, paused: reduceMotion)) { timeline in
                let wobble = reduceMotion ? 0 : sin(timeline.date.timeIntervalSinceReferenceDate * 14) * 7
                EggGlyph(egg: egg, crack: reduceMotion ? 1 : crack, width: 150)
                    .rotationEffect(.degrees(wobble))
            }
        }
        .accessibilityLabel(continueLabel)
        .accessibilityAddTraits(.isButton)
        .onTapGesture { handoff() }
        .accessibilityAction { handoff() }
        .onAppear {
            if reduceMotion {
                crack = 1
            } else {
                withAnimation(.easeIn(duration: 1.45)) { crack = 1 }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 450 : 1700))
            handoff()
        }
    }

    private func handoff() {
        guard !handed else { return }
        handed = true
        onFinished()
    }
}

struct OnboardingHatchedScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var onFinished: () -> Void

    @State private var handed = false

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 18) {
                Spacer()
                ZStack {
                    HatchRays(reduceMotion: reduceMotion)
                    OnboardingBunny(
                        fur: fur,
                        animation: .celebrate,
                        reduceMotion: reduceMotion,
                        height: 220
                    )
                }
                Text(engine.t("onb.hatched"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onTapGesture { handoff() }
        .accessibilityAction(named: Text(engine.t("onb.next"))) { handoff() }
        .onAppear { engine.haptics.celebrate() }
        .task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 600 : 1500))
            handoff()
        }
    }

    private func handoff() {
        guard !handed else { return }
        handed = true
        onFinished()
    }
}
