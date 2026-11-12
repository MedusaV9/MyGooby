import SwiftUI

struct OnboardingSplashScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var onHatch: () -> Void

    @State private var arrived = false

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 14) {
                Spacer(minLength: 12)
                OnboardingBunny(fur: "fur-cream", animation: .breathe, reduceMotion: reduceMotion, height: 220)
                    .scaleEffect(arrived ? 1 : 0.72)
                    .offset(y: arrived ? 0 : 36)
                Text("Gooby")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .opacity(arrived ? 1 : 0)
                    .offset(y: arrived ? 0 : 14)
                Text(engine.t("onb.splash.subtitle"))
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(OnboardingPalette.subtitle)
                    .multilineTextAlignment(.center)
                    .opacity(arrived ? 1 : 0)
                Spacer(minLength: 12)
                OnboardingPill(title: engine.t("onb.splash.hatch"), action: onHatch)
                    .opacity(arrived ? 1 : 0)
                    .offset(y: arrived ? 0 : 18)
                Text(engine.t("onb.splash.local"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(OnboardingPalette.subtitle)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                    .opacity(arrived ? 1 : 0)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            if reduceMotion {
                arrived = true
            } else {
                withAnimation(.spring(response: 0.72, dampingFraction: 0.72)) { arrived = true }
            }
        }
    }
}

struct OnboardingEggScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Binding var eggIndex: Int
    var onHatch: () -> Void
    var onSkip: () -> Void

    @State private var hop = false

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
                            RingEgg(
                                egg: egg,
                                index: index,
                                selected: index == eggIndex,
                                reduceMotion: reduceMotion,
                                label: engine.t(egg.nameKey)
                            ) {
                                eggIndex = index
                                engine.haptics.soft()
                            }
                            .position(
                                x: geo.size.width / 2 + CGFloat(cos(angle)) * radius,
                                y: geo.size.height / 2 + CGFloat(sin(angle)) * radius
                            )
                        }
                        OnboardingBunny(
                            fur: OnboardingScript.rabbitFur,
                            animation: .idle,
                            reduceMotion: reduceMotion,
                            height: min(150, radius + 20)
                        )
                        .frame(width: min(150, radius + 20), height: min(150, radius + 20))
                        .scaleEffect(hop ? 1.08 : 1)
                        .offset(y: hop ? -12 : 0)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.7), value: eggIndex)
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
        .onChange(of: eggIndex) { _, _ in
            guard !reduceMotion else { return }
            hop = false
            withAnimation(.spring(response: 0.22, dampingFraction: 0.42)) { hop = true }
            Task {
                try? await Task.sleep(for: .milliseconds(160))
                withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) { hop = false }
            }
        }
    }
}

private struct RingEgg: View {
    var egg: OnboardingEgg
    var index: Int
    var selected: Bool
    var reduceMotion: Bool
    var label: String
    var choose: () -> Void

    @State private var shown = false

    var body: some View {
        Button(action: choose) {
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
        .contentShape(Rectangle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .scaleEffect(shown ? 1 : 0.35)
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(shown)
        .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.7), value: selected)
        .onAppear {
            if reduceMotion {
                shown = true
            } else {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.72).delay(Double(index) * 0.05)) {
                    shown = true
                }
            }
        }
    }
}

struct OnboardingCrackScreen: View {
    var egg: OnboardingEgg
    var reduceMotion: Bool
    var continueLabel: String
    var onFinished: () -> Void

    @State private var started: Date?
    @State private var handed = false

    var body: some View {
        OnboardingScreen {
            TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 30.0, paused: reduceMotion)) { timeline in
                let origin = started ?? timeline.date
                let elapsed = reduceMotion ? 2.0 : timeline.date.timeIntervalSince(origin)
                let wobbleAmp = reduceMotion ? 0.0 : min(16, 1.4 + elapsed * 9)
                let wobble = sin(elapsed * 18) * wobbleAmp
                // eggHatch.m4a is 0.827 s. The crack keeps that length.
                let crack = min(1, max(0, (elapsed - 0.12) / 0.827))
                let split = min(1, max(0, (elapsed - 1.15) / 0.42))
                ZStack {
                    if split < 0.001 {
                        EggGlyph(egg: egg, crack: crack, width: 168)
                    } else {
                        shellHalf(crack: crack, leading: true, split: split)
                        shellHalf(crack: crack, leading: false, split: split)
                    }
                }
                .rotationEffect(.degrees(wobble * (1 - split)))
                .scaleEffect(1 + (reduceMotion ? 0 : sin(elapsed * 22) * 0.018 * (1 - split)))
            }
        }
        .accessibilityLabel(continueLabel)
        .accessibilityAddTraits(.isButton)
        .onTapGesture { handoff() }
        .accessibilityAction { handoff() }
        .onAppear { started = Date() }
        .task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 450 : 1900))
            handoff()
        }
    }

    private func shellHalf(crack: CGFloat, leading: Bool, split: CGFloat) -> some View {
        EggGlyph(egg: egg, crack: crack, width: 168)
            .mask {
                HStack(spacing: 0) {
                    Rectangle().opacity(leading ? 1 : 0)
                    Rectangle().opacity(leading ? 0 : 1)
                }
            }
            .offset(x: (leading ? -1 : 1) * split * 58, y: split * 36)
            .rotationEffect(.degrees((leading ? -1 : 1) * split * 26))
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
    var egg: OnboardingEgg
    var onFinished: () -> Void

    @State private var popped = false
    @State private var handed = false

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 18) {
                Spacer()
                ZStack {
                    HatchRays(reduceMotion: reduceMotion)
                        .opacity(popped ? 1 : 0.2)
                    shell(leading: true)
                    shell(leading: false)
                    OnboardingBunny(
                        fur: fur,
                        animation: .celebrate,
                        reduceMotion: reduceMotion,
                        height: 220
                    )
                    .scaleEffect(popped ? 1 : 0.16)
                    .offset(y: popped ? 0 : 78)
                    .rotationEffect(.degrees(popped ? 0 : -10))
                }
                .frame(height: 300)
                Text(engine.t("onb.hatched"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(.center)
                    .opacity(popped ? 1 : 0)
                    .offset(y: popped ? 0 : 16)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onTapGesture { handoff() }
        .accessibilityAction(named: Text(engine.t("onb.next"))) { handoff() }
        .onAppear {
            engine.haptics.celebrate()
            if reduceMotion {
                popped = true
            } else {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.6)) { popped = true }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 600 : 1600))
            handoff()
        }
    }

    private func shell(leading: Bool) -> some View {
        EggGlyph(egg: egg, crack: 1, width: 156)
            .mask {
                HStack(spacing: 0) {
                    Rectangle().opacity(leading ? 1 : 0)
                    Rectangle().opacity(leading ? 0 : 1)
                }
            }
            .offset(
                x: (leading ? -1 : 1) * (popped ? 148 : 58),
                y: popped ? 96 : 36
            )
            .rotationEffect(.degrees((leading ? -1 : 1) * (popped ? 42 : 26)))
            .opacity(popped ? 0 : 1)
    }

    private func handoff() {
        guard !handed else { return }
        handed = true
        onFinished()
    }
}
