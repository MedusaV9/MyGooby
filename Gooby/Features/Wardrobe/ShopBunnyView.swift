import SwiftUI

struct ShopBunnyView: View {
    var worn: [ShopAnchor: ShopItem]
    var animated: Bool = true
    var language: ShopLanguage = .de

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var eyeOpen: CGFloat = 1
    @State private var breathing = false

    var body: some View {
        Canvas { context, size in
            ShopBunnyArtist.draw(
                context: &context,
                size: size,
                worn: worn,
                eyeOpen: reduceMotion || !animated ? 1 : eyeOpen
            )
        }
        .aspectRatio(ShopBunnyArtist.design.width / ShopBunnyArtist.design.height, contentMode: .fit)
        .scaleEffect(x: 1, y: breathing ? 1.018 : 1, anchor: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(phrase)
        .onAppear {
            guard animated, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        .task(id: animated && !reduceMotion) {
            guard animated, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_400_000_000)
                if Task.isCancelled { return }
                withAnimation(.easeIn(duration: 0.08)) { eyeOpen = 0.08 }
                try? await Task.sleep(nanoseconds: 140_000_000)
                if Task.isCancelled { return }
                withAnimation(.easeOut(duration: 0.12)) { eyeOpen = 1 }
            }
        }
    }

    private var phrase: String {
        let names = ShopAnchor.wearAnchors.compactMap { worn[$0]?.name(language) }
        if names.isEmpty {
            return ShopL10n.text(.bunnyPlain, language)
        }
        return ShopL10n.format(.bunnyWearing, language, names.joined(separator: ", "))
    }
}
