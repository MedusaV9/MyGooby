import SwiftUI

struct OnboardingChatScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var petName: String
    @Binding var humanName: String
    var onBack: () -> Void
    var onNext: () -> Void

    @FocusState private var focused: Bool
    @State private var sent = false

    private var trimmed: String {
        humanName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                OnboardingBack(label: engine.t("onb.back"), action: onBack)
                    .padding(.horizontal, 24)
                ScrollView {
                    VStack(spacing: 16) {
                        OnboardingBubble(text: engine.tf("onb.chat.ask", petName))
                        OnboardingBunny(fur: fur, animation: .hop, reduceMotion: reduceMotion, height: 150)
                        if sent {
                            OnboardingBubble(text: trimmed, trailing: true, fill: Color(hex: 0xE5F8EA))
                        } else {
                            TextField(engine.t("onb.chat.placeholder"), text: $humanName)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.words)
                                .textContentType(.givenName)
                                .submitLabel(.next)
                                .focused($focused)
                                .onSubmit(send)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(OnboardingPalette.fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                OnboardingPill(title: engine.t("onb.next"), enabled: sent || !trimmed.isEmpty) {
                    if sent { onNext() } else { send() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
        .onAppear { focused = true }
        .task(id: sent) {
            guard sent else { return }
            if !reduceMotion {
                try? await Task.sleep(for: .milliseconds(420))
            }
            guard !Task.isCancelled else { return }
            onNext()
        }
    }

    private func send() {
        guard !sent else { return }
        guard !trimmed.isEmpty else { return }
        humanName = trimmed
        focused = false
        if reduceMotion {
            sent = true
            return
        }
        withAnimation(.easeOut(duration: 0.25)) { sent = true }
    }
}

struct OnboardingCareScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var humanName: String
    var onBack: () -> Void
    var onChoose: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 16) {
                OnboardingBack(label: engine.t("onb.back"), action: onBack)
                ScrollView {
                    VStack(spacing: 16) {
                        OnboardingBubble(text: engine.tf("onb.care.ask", humanName))
                        OnboardingBunny(
                            fur: fur,
                            animation: .think,
                            reduceMotion: reduceMotion,
                            height: 160,
                            badge: "questionmark",
                            badgeAbove: true
                        )
                    }
                }
                .scrollIndicators(.hidden)
                reply(engine.t("onb.care.warm"))
                reply(engine.t("onb.care.long"))
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
    }

    private func reply(_ text: String) -> some View {
        Button(action: onChoose) {
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(OnboardingPalette.ink)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(OnboardingPalette.line, lineWidth: 1)
                }
        }
        .buttonStyle(OnboardingPress())
    }
}

struct OnboardingGainScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var petName: String
    var traitName: String
    var onBack: () -> Void
    var onNext: () -> Void

    @State private var fill: CGFloat = 0

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 16) {
                OnboardingBack(label: engine.t("onb.back"), action: onBack)
                OnboardingBubble(text: engine.t("onb.gain.line"))
                OnboardingBunny(fur: fur, animation: .hearts, reduceMotion: reduceMotion, height: 170)
                Spacer(minLength: 8)
                VStack(alignment: .leading, spacing: 6) {
                    Text(engine.tf("onb.gain.label", petName, traitName))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                    Text(engine.t("onb.gain.step"))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
                .background {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            OnboardingPalette.blue.opacity(0.45)
                            OnboardingPalette.blue
                                .frame(width: geo.size.width * (reduceMotion ? 0.34 : fill))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                Spacer(minLength: 8)
                OnboardingPill(title: engine.t("onb.next"), action: onNext)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            if reduceMotion {
                fill = 0.34
            } else {
                withAnimation(.easeOut(duration: 0.9)) { fill = 0.34 }
            }
        }
    }
}
