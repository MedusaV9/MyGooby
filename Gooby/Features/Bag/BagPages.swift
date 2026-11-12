import SwiftUI

struct BagDestination: View {
    var route: BagRoute
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        page
            .toolbar(hidesBar ? .hidden : .visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .navigationBarBackButtonHidden(hidesBar)
    }

    @ViewBuilder private var page: some View {
        switch route {
        case .mail:
            MailScreen(engine: engine)
        case .outfits:
            BagHouse(engine: engine, reduceMotion: reduceMotion, kind: .outfits)
        case .furniture:
            BagHouse(engine: engine, reduceMotion: reduceMotion, kind: .furniture)
        case .colors:
            BagHouse(engine: engine, reduceMotion: reduceMotion, kind: .colors)
        case .micropets:
            MicropetsScreen(engine: engine)
        case .settings:
            SettingsView(engine: engine)
        case .place(let id):
            if let place = engine.catalog.placesByID[id] {
                PlaceDetail(engine: engine, place: place, reduceMotion: reduceMotion)
            } else {
                BagMissingNote(text: engine.t("bag.place.missing"))
            }
        case .letter(let id):
            if let letter = BagMail.letters(engine).first(where: { $0.id == id }) {
                BagLetterPage(engine: engine, letter: letter)
            } else {
                BagMissingNote(text: engine.t("bag.mail.missing"))
            }
        }
    }

    private var hidesBar: Bool {
        switch route {
        case .mail, .outfits, .furniture, .colors: true
        default: false
        }
    }
}

private struct BagMissingNote: View {
    var text: String

    var body: some View {
        VStack(spacing: 16) {
            BagArtView(art: .hintFace)
                .frame(width: 72, height: 72)
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
    }
}

private struct BagLetterPage: View {
    var engine: GoobyEngine
    var letter: BagLetter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(letter.title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(engine.formatDate(letter.date, time: true))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                Text(letter.body)
                    .font(.system(.body, design: .rounded))
            }
            .foregroundStyle(Theme.ink)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(BagTitle.mail(name: engine.profile.goobyName, language: engine.languageCode))
        .onAppear { BagMail.markRead(letter.id) }
    }
}

private struct BagMicropets: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        let friends = engine.all(MiniFriend.self).sorted { $0.hatchedAt > $1.hatchedAt }
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if friends.isEmpty {
                    VStack(spacing: 12) {
                        BagArtView(art: .hintFace)
                            .frame(width: 72, height: 72)
                        Text(engine.t("bag.micropets.emptyTitle"))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                        Text(engine.t("bag.micropets.empty"))
                            .font(.system(.body, design: .rounded))
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                ForEach(friends) { friend in
                    HStack(spacing: 12) {
                        MiniFriendBadge(species: friend.speciesID)
                            .frame(width: 54, height: 54)
                        VStack(alignment: .leading) {
                            Text(friend.givenName)
                                .font(.system(.headline, design: .rounded))
                            Text(engine.t("rarity.\(friend.rarity)"))
                                .font(.system(.caption, design: .rounded))
                        }
                        Spacer()
                        if friend.isCompanion {
                            Text(engine.t("friends.with"))
                        } else {
                            Button(engine.t("friends.choose")) { engine.setCompanion(friend) }
                                .buttonStyle(.bordered)
                        }
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(12)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: reduceMotion ? .idle : .play,
                    reduceMotion: reduceMotion,
                    companion: engine.companionSpecies()
                )
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(engine.t("bag.micropets"))
    }
}
