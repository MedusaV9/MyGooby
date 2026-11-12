import SwiftUI

struct AdventureLocationCard: View {
    var engine: GoobyEngine
    var place: PlaceDef
    var reduceMotion: Bool
    var selected: Bool = false
    var showsRabbit: Bool = false
    var rabbit: GoobyAnimation = .idle
    var tap: (() -> Void)?

    var body: some View {
        Group {
            if let tap {
                Button(action: tap) { card }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
            } else {
                card
            }
        }
        .accessibilityIdentifier("adventure-place-\(place.id)")
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            stage
            Text(place.name.text(engine.languageCode))
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(place.blurb.text(engine.languageCode))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
            Text(AdventureText.visits(engine, place))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.62))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(selected ? Theme.rose : Color.clear, lineWidth: 3)
        }
        .shadow(color: Theme.ink.opacity(0.08), radius: 12, y: 6)
    }

    private var stage: some View {
        ZStack(alignment: .bottom) {
            AdventurePlaceArt(place: place)
                .frame(height: showsRabbit ? 176 : 92)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .opacity(engine.isPlaceUnlocked(place.id) ? 1 : 0.72)
                .overlay(alignment: .topTrailing) {
                    if !engine.isPlaceUnlocked(place.id) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.88), in: Circle())
                            .padding(8)
                    }
                }
            if showsRabbit {
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: rabbit,
                    reduceMotion: reduceMotion,
                    companion: nil,
                    showCompanion: false
                )
                .frame(width: 150, height: 156)
                .accessibilityLabel(AdventureText.petName(engine))
            }
        }
    }
}
