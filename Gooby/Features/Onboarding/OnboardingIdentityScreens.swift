import SwiftUI

struct OnboardingPronounScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    @Binding var pronoun: String
    var onBack: () -> Void
    var onNext: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 14) {
                OnboardingBack(label: engine.t("onb.back"), action: onBack)
                OnboardingBunny(fur: fur, animation: .idle, reduceMotion: reduceMotion, height: 160)
                Text(engine.t("onb.hatched"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(.center)
                Text(engine.t("onb.pronoun.subtitle"))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(OnboardingPalette.subtitle)
                VStack(spacing: 10) {
                    pronounRow("he/him", key: "onb.pronoun.he")
                    pronounRow("she/her", key: "onb.pronoun.she")
                    pronounRow("they/them", key: "onb.pronoun.they")
                }
                Spacer(minLength: 8)
                OnboardingPill(title: engine.t("onb.next"), enabled: !pronoun.isEmpty, action: onNext)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
        }
    }

    private func pronounRow(_ id: String, key: String) -> some View {
        let selected = pronoun == id
        return Button {
            pronoun = id
            engine.haptics.soft()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "heart.fill" : "heart")
                    .foregroundStyle(selected ? OnboardingPalette.blue : OnboardingPalette.disabledInk)
                Text(engine.t(key))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(OnboardingPalette.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? OnboardingPalette.blue : OnboardingPalette.line, lineWidth: selected ? 2 : 1)
            }
        }
        .buttonStyle(OnboardingPress())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct OnboardingNameScreen: View {
    var engine: GoobyEngine
    var fur: String
    var reduceMotion: Bool
    @Binding var petName: String
    var onBack: () -> Void
    var onNext: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 0) {
                OnboardingBack(label: engine.t("onb.back"), action: onBack)
                    .padding(.horizontal, 24)
                ScrollView {
                    VStack(spacing: 14) {
                        OnboardingBunny(fur: fur, animation: .idle, reduceMotion: reduceMotion, height: 150)
                        Text(engine.t("onb.pet.title"))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(OnboardingPalette.ink)
                            .multilineTextAlignment(.center)
                        Text(engine.t("onb.pet.hint"))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(OnboardingPalette.subtitle)
                        nameField
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                HStack(spacing: 10) {
                    OnboardingGrayPill(title: engine.t("onb.pet.shuffle")) {
                        petName = OnboardingScript.shuffledName(besides: petName)
                    }
                    OnboardingPill(title: engine.t("onb.next"), action: onNext)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
    }

    private var nameField: some View {
        HStack(spacing: 8) {
            TextField("Gooby", text: $petName)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .onSubmit(onNext)
            if !petName.isEmpty {
                Button {
                    petName = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(OnboardingPalette.disabledInk)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("onb.pet.clear"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(OnboardingPalette.fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct OnboardingTraitScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var fur: String
    var petName: String
    @Binding var trait: String
    var onBack: () -> Void
    var onNext: () -> Void

    var body: some View {
        OnboardingScreen {
            VStack(spacing: 10) {
                OnboardingBack(label: engine.t("onb.back"), action: onBack)
                OnboardingBunny(
                    fur: fur,
                    animation: OnboardingScript.pose(for: trait),
                    reduceMotion: reduceMotion,
                    height: 130,
                    badge: trait.isEmpty ? nil : OnboardingScript.symbol(for: trait)
                )
                Text(engine.tf("onb.trait.title", petName))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                    .multilineTextAlignment(.center)
                Text(engine.tf("onb.trait.cares", petName))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(OnboardingPalette.subtitle)
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(OnboardingScript.traits) { item in
                            traitRow(item)
                        }
                    }
                    .padding(.vertical, 4)
                }
                OnboardingPill(title: engine.t("onb.next"), enabled: !trait.isEmpty, action: onNext)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
        }
    }

    private func traitRow(_ item: OnboardingTrait) -> some View {
        let selected = trait == item.id
        return Button {
            guard engine.setStarterTrait(item.id) else { return }
            trait = item.id
            engine.haptics.soft()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .foregroundStyle(OnboardingPalette.ink)
                Text(engine.t(item.nameKey))
                    .font(.system(size: 17, weight: selected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(OnboardingPalette.ink)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(OnboardingPalette.green)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? OnboardingPalette.green : OnboardingPalette.line, lineWidth: selected ? 2 : 1)
            }
        }
        .buttonStyle(OnboardingPress())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
