import SwiftUI
import UIKit

/// Sheet behind the pencil button: Gooby's name and the player's nickname.
struct PetEditSheet: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var nickname = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: 92)
                    .frame(width: 110, height: 110)
                    .background(Theme.Tab.pet.cream, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .accessibilityHidden(true)
                field(engine.t("settings.goobyName"), text: $name, prompt: "Gooby")
                field(engine.t("settings.nickname"), text: $nickname, prompt: "")
                Button(engine.t("common.save")) {
                    engine.petRename(gooby: name, nickname: nickname)
                    engine.haptics.soft()
                    dismiss()
                }
                .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.pet.clip, edge: nil, radius: 18, vertical: 14, expand: true))
                .foregroundStyle(.white)
                .padding(.top, 4)
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            ZStack {
                Text(engine.tx("pet.edit.title", de: "Namen", en: "Names"))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.brown)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    CloseCircleButton(label: engine.t("kit.close")) { dismiss() }
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.Tab.pet.bgTop.ignoresSafeArea(edges: .top))
        }
        .background(Theme.Tab.pet.screen.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .onAppear {
            name = engine.profile.goobyName
            nickname = engine.profile.nickname
        }
    }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionCaps(title, color: Theme.brown.opacity(0.7))
            TextField(prompt, text: text)
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityLabel(title)
        }
    }
}

/// Static card rendered to a PNG for the share button (ImageRenderer, fully offline).
struct PetShareCard: View {
    var look: WornLook
    var stage: String
    var title: String
    var subtitle: String
    var birthdayLabel: String
    var birthday: String
    var streakLine: String
    var footer: String

    var body: some View {
        VStack(spacing: 14) {
            card
            Text(footer)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.brown.opacity(0.6))
        }
        .padding(.top, 34)
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
        .background(Theme.Tab.pet.background)
    }

    private var card: some View {
        VStack(spacing: 10) {
            GoobyCharacterView(look: look, stage: stage, animation: .idle, reduceMotion: true, companion: nil, adventuring: false)
                .frame(width: 170, height: 170)
                .frame(width: 190, height: 190)
                .background(Theme.Tab.pet.cream, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(.top, 8)
            Text(title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.greyText)
            }
            VStack(spacing: 2) {
                Text(birthdayLabel.uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Theme.greyText)
                Text(birthday)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ochre)
            }
            .padding(.top, 6)
            Text(streakLine)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.brown)
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .frame(width: 340)
        .background(Theme.Tab.pet.paper, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(alignment: .top) { PetClip().offset(y: -16) }
    }

    /// PNG-backed image of the card at 3x.
    @MainActor
    func render() -> Image? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 3
        guard let image = renderer.uiImage else { return nil }
        return Image(uiImage: image)
    }
}
