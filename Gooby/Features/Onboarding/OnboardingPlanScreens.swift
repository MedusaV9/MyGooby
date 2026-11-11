import SwiftUI

struct OnboardingGeneratingScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var petName: String
    var onFinished: () -> Void

    @State private var progress: CGFloat = 0
    @State private var handed = false

    private let lines = ["onb.proof.1", "onb.proof.2", "onb.proof.3"]

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                Text(engine.tf("onb.gen.title", petName))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)
                    .padding(.horizontal, 24)
                Spacer(minLength: 8)
                ZStack {
                    Circle()
                        .stroke(OnboardingPalette.line, lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: reduceMotion ? 1 : progress)
                        .stroke(OnboardingPalette.green, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    OnboardingBunny(fur: fur, animation: .idle, reduceMotion: reduceMotion, height: 120)
                }
                .frame(width: 190, height: 190)
                .padding(.bottom, 12)
                Spacer(minLength: 8)
                proof
            }
        }
        .task {
            if reduceMotion {
                progress = 1
                return
            }
            withAnimation(.easeInOut(duration: 2.1)) { progress = 1 }
            try? await Task.sleep(for: .milliseconds(2300))
            handoff()
        }
        .onTapGesture { if !reduceMotion { handoff() } }
        .accessibilityAction(named: Text(engine.t("onb.next"))) { handoff() }
    }

    private var proof: some View {
        VStack(spacing: 14) {
            Text(engine.t("onb.proof.title"))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(lines, id: \.self) { key in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 3) {
                                ForEach(0..<5, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: 0xF5B942))
                                }
                            }
                            .accessibilityHidden(true)
                            Text(engine.t(key))
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(OnboardingPalette.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(14)
                        .frame(width: 196, alignment: .leading)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            if reduceMotion {
                OnboardingPill(title: engine.t("onb.next"), fill: OnboardingPalette.greenDeep, action: handoff)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 22)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .background(
            OnboardingPalette.green,
            in: UnevenRoundedRectangle(
                topLeadingRadius: 32,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 32
            )
        )
    }

    private func handoff() {
        guard !handed else { return }
        handed = true
        onFinished()
    }
}

struct OnboardingPlanScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var petName: String
    var humanName: String
    var busy: Bool
    var onStart: () -> Void

    private let holeColors: [UInt32] = [0xF6C445, 0x7BC67B, 0xF094B0, 0x7EB6E0, 0xF0A35A, 0xB9A4DE, 0x3DCC62]

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        OnboardingBubble(text: engine.t("onb.plan.bubble"))
                        OnboardingBunny(fur: fur, animation: .hop, reduceMotion: reduceMotion, height: 140)
                        note
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
                OnboardingPill(title: engine.t("onb.plan.go"), enabled: !busy, action: onStart)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        }
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(OnboardingPalette.ink)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .padding(.top, 18)
            Text(engine.tf("onb.plan.subtitle", petName))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(OnboardingPalette.subtitle)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Rectangle()
                        .fill(Color(hex: 0xF0E2B4))
                        .frame(height: 1)
                }
                HStack(spacing: 12) {
                    Image(systemName: row.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: row.tint))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: row.tint).opacity(0.18), in: Circle())
                    Text(row.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(OnboardingPalette.ink)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(OnboardingPalette.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .top) {
            HStack {
                ForEach(Array(holeColors.enumerated()), id: \.offset) { _, tint in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color(hex: tint))
                        .frame(width: 12, height: 22)
                }
            }
            .offset(y: -10)
        }
        .padding(.top, 12)
    }

    private var title: String {
        let trimmed = humanName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return engine.t("onb.plan.anon") }
        return engine.tf("onb.plan.title", trimmed)
    }

    private var rows: [(id: String, title: String, symbol: String, tint: UInt32)] {
        OnboardingScript.starterIDs.compactMap { id in
            guard let suggestion = GoalCatalog.suggestion(id) else { return nil }
            let tint = GoalCatalog.area(suggestion.areaID)?.tint ?? 0x7BC67B
            return (id, suggestion.title(engine.languageCode), GoalArt.symbol(for: suggestion.glyph), tint)
        }
    }
}
