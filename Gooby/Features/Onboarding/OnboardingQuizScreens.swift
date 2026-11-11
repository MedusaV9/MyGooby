import SwiftUI

struct OnboardingRemindersScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var petName: String
    var onBack: () -> Void
    var onDone: () -> Void

    @State private var busy = false
    @State private var request: Task<Void, Never>?

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 16) {
                OnboardingBack(label: engine.t("onb.back"), action: onBack)
                Text(engine.tf("onb.remind.title", petName))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                HStack(spacing: 12) {
                    OnboardingBunny(fur: fur, animation: .idle, reduceMotion: true, height: 46)
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.tf("onb.remind.from", petName))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(OnboardingPalette.ink)
                        Text(engine.t("onb.remind.body"))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(OnboardingPalette.subtitle)
                    }
                    Spacer(minLength: 0)
                    Text(engine.t("onb.remind.now"))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(OnboardingPalette.subtitle)
                }
                .padding(14)
                .background(OnboardingPalette.fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                OnboardingBunny(fur: fur, animation: .hop, reduceMotion: reduceMotion, height: 180)
                Spacer(minLength: 8)
                OnboardingPill(title: engine.t("onb.remind.on"), enabled: !busy, action: enable)
                OnboardingGrayPill(title: engine.t("onb.remind.later")) {
                    guard !busy else { return }
                    onDone()
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
        }
        .onDisappear { request?.cancel() }
    }

    private func enable() {
        guard !busy else { return }
        busy = true
        request = Task {
            let ok = await GoobyAlerts.request()
            if ok {
                engine.profile.notificationsEnabled = true
                engine.save()
                engine.rescheduleNotifications()
            }
            guard !Task.isCancelled else { return }
            onDone()
        }
    }
}

struct OnboardingLearnScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var petName: String
    var onBack: () -> Void
    var onNext: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 16) {
                OnboardingBack(label: engine.t("onb.back"), action: onBack)
                Spacer(minLength: 8)
                OnboardingBunny(fur: fur, animation: .hearts, reduceMotion: reduceMotion, height: 200)
                Text(engine.t("onb.learn.title"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(.center)
                Text(engine.tf("onb.learn.body", petName))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(OnboardingPalette.subtitle)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 8)
                OnboardingPill(title: engine.t("onb.next"), action: onNext)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct OnboardingQuizScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var index: Int
    @Binding var answers: [String: String]
    @Binding var areas: Set<String>
    var onBack: () -> Void
    var onAdvance: () -> Void
    var onFinishAreas: () -> Void

    private var question: OnboardingQuestion {
        OnboardingScript.questions[index]
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    OnboardingBack(label: engine.t("onb.back"), action: onBack)
                    SectionBar(current: question.section, count: OnboardingScript.sectionKeys.count)
                }
                Text(engine.t(OnboardingScript.sectionKeys[question.section]))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(OnboardingPalette.subtitle)
                OnboardingBunny(
                    fur: fur,
                    animation: .think,
                    reduceMotion: reduceMotion,
                    height: 110,
                    badge: "questionmark",
                    badgeAbove: true
                )
                Text(engine.t(question.titleKey))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(.center)
                if !question.hintKey.isEmpty {
                    Text(engine.t(question.hintKey))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(OnboardingPalette.subtitle)
                        .multilineTextAlignment(.center)
                }
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(question.options) { option in
                            OnboardingChoiceRow(
                                title: engine.t(option.titleKey),
                                symbol: option.symbol,
                                tint: option.tint,
                                selected: isSelected(option),
                                centered: question.centered,
                                multi: question.multi,
                                reduceMotion: reduceMotion
                            ) {
                                choose(option)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                if question.multi {
                    OnboardingPill(
                        title: engine.t("onb.next"),
                        enabled: !areas.isEmpty,
                        action: onFinishAreas
                    )
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 22)
        }
    }

    private func isSelected(_ option: OnboardingOption) -> Bool {
        if question.multi { return areas.contains(option.id) }
        return answers[question.id] == option.id
    }

    private func choose(_ option: OnboardingOption) {
        if question.multi {
            if areas.contains(option.id) {
                areas.remove(option.id)
            } else {
                areas.insert(option.id)
            }
            return
        }
        // Age and the other answers stay on this pass. Under 18 does not change the app.
        answers[question.id] = option.id
        onAdvance()
    }
}
