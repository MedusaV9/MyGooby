import SwiftUI

struct ActivityLaneView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var lane: ActivityLane
    @ObservedObject private var favorites = ActivityFavoriteStore.shared
    @State private var query = ""
    @State private var filter = "all"
    @State private var starsOnly = false

    var body: some View {
        let rows = filtered
        ActivityLanePage(engine: engine, lane: lane) {
            ActivitySearchField(prompt: engine.t("common.search"), text: $query)
            ActivityFilterBar(
                engine: engine,
                filters: ActivityCatalog.filters(for: lane),
                filter: filter,
                starsOnly: starsOnly,
                onFilter: { filter = $0 },
                onStars: { starsOnly.toggle() }
            )
            ForEach(rows) { piece in
                row(piece)
            }
            if rows.isEmpty {
                ActivityQuietNote(text: engine.t("activity.search.empty"))
            }
            ActivityCapsuleLink(title: engine.t("activity.open.calm")) {
                ActivityLaunch(engine: engine, reduceMotion: reduceMotion, run: .calm)
            }
            ActivityQuietNote(text: engine.t("calm.disclaimer"))
        }
    }

    private var filtered: [ActivityPiece] {
        ActivityCatalog.pieces(lane, engine).map { piece in
            var copy = piece
            if lane == .soundscapes, engine.sound.active == piece.id {
                copy.detail = "\(piece.detail) \(engine.t("activity.sound.playing"))"
            }
            return copy
        }
        .filter { piece in
            ActivityCatalog.matches(
                query: query,
                title: piece.title,
                detail: piece.detail,
                filters: piece.filters,
                filter: filter,
                starsOnly: starsOnly,
                starID: starID(piece.id),
                favorites: favorites
            )
        }
    }

    private func row(_ piece: ActivityPiece) -> some View {
        let starred = favorites.contains(starID(piece.id))
        return ActivityCard {
            HStack(spacing: 0) {
                NavigationLink {
                    ActivityLaunch(engine: engine, reduceMotion: reduceMotion, run: piece.run)
                } label: {
                    ActivityRowLabel(title: piece.title, detail: piece.detail, symbol: piece.symbol, tint: piece.tint, badge: piece.badge)
                }
                .buttonStyle(.plain)
                ActivityStarButton(
                    on: starred,
                    label: ActivityCatalog.starLabel(engine, on: starred, title: piece.title)
                ) {
                    favorites.toggle(starID(piece.id))
                    engine.haptics.soft()
                }
            }
        }
    }

    private func starID(_ id: String) -> String {
        ActivityCatalog.starID(lane.rawValue, id)
    }
}
