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
            if BagColorsGate.isOpen(engine) {
                BagHouse(engine: engine, reduceMotion: reduceMotion, kind: .colors)
            } else {
                BagColorsClosed(engine: engine)
            }
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
        }
    }

    private var hidesBar: Bool {
        switch route {
        case .mail, .outfits, .furniture: true
        case .colors: BagColorsGate.isOpen(engine)
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

private struct BagColorsClosed: View {
    var engine: GoobyEngine

    var body: some View {
        VStack(spacing: 18) {
            BagQuestion()
                .frame(width: 64, height: 64)
            Text(engine.t("bag.colors.locked"))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(engine.t("bag.colors"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
