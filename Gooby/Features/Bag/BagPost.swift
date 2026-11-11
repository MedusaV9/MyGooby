import SwiftUI

struct BagPostScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var wave = false

    private var still: Bool { reduceMotion || engine.reduceMotion }

    var body: some View {
        let letters = BagMail.letters(engine)
        let title = BagTitle.mail(name: engine.profile.goobyName, language: engine.languageCode)
        ZStack(alignment: .topLeading) {
            VStack(spacing: -22) {
                header
                sheet(title: title, letters: letters)
            }
            back
        }
        .background(BagPostColor.sheet.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear { syncWave() }
        .onChange(of: still) { _, _ in syncWave() }
    }

    private var header: some View {
        ZStack(alignment: .bottom) {
            BagPostColor.sky
                .overlay {
                    BagPostCloud()
                        .offset(x: wave && !still ? 12 : -6, y: 18)
                    BagPostCloud()
                        .scaleEffect(0.72)
                        .offset(x: wave && !still ? -18 : 8, y: -28)
                }
                .ignoresSafeArea(edges: .top)
            BagPostBox(waving: wave && !still)
                .padding(.bottom, 28)
        }
        .frame(height: 236)
        .accessibilityHidden(true)
    }

    private func sheet(title: String, letters: [BagLetter]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(BagPostColor.title)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
            if letters.isEmpty {
                Spacer(minLength: 0)
                Text(engine.t("bag.mail.empty"))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(BagPostColor.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(letters) { letter in
                            NavigationLink(value: BagRoute.letter(letter.id)) {
                                letterRow(letter)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { engine.haptics.soft() })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(topLeading: 28, bottomLeading: 0, bottomTrailing: 0, topTrailing: 28),
                style: .continuous
            )
            .fill(BagPostColor.sheet)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func letterRow(_ letter: BagLetter) -> some View {
        HStack(alignment: .top, spacing: 12) {
            BagMailbox().frame(width: 36, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(letter.title)
                        .font(.system(.headline, design: .rounded))
                    Spacer(minLength: 8)
                    if !BagMail.isRead(letter.id) {
                        Text(engine.t("bag.mail.new"))
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(BagColor.colorsTile, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Text(letter.body)
                    .font(.system(.subheadline, design: .rounded))
                    .lineLimit(2)
                    .foregroundStyle(Theme.ink.opacity(0.7))
                Text(engine.formatDate(letter.date))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.55))
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var back: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(BagPostColor.title)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 6)
        .accessibilityLabel(engine.t("bag.back"))
    }

    private func syncWave() {
        if still {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { wave = false }
            return
        }
        guard !wave else { return }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            wave = true
        }
    }
}

private enum BagPostColor {
    static let sky = Color(hex: 0x8ED4F8)
    static let sheet = Color(hex: 0xF3F4F6)
    static let title = Color(hex: 0x8B93A3)
    static let body = Color(hex: 0x6D7586)
}

private struct BagPostCloud: View {
    var body: some View {
        ZStack {
            Capsule().fill(.white.opacity(0.92)).frame(width: 92, height: 28)
            Circle().fill(.white.opacity(0.92)).frame(width: 36, height: 36).offset(x: -18, y: -8)
            Circle().fill(.white.opacity(0.92)).frame(width: 28, height: 28).offset(x: 16, y: -6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 28)
        .padding(.top, 36)
    }
}

private struct BagPostBox: View {
    var waving: Bool

    var body: some View {
        StageStill(name: "still-mail")
            .frame(width: 168, height: 140)
            .rotationEffect(.degrees(waving ? -5 : 4), anchor: .bottom)
            .offset(y: waving ? -6 : 0)
            .accessibilityHidden(true)
    }
}
