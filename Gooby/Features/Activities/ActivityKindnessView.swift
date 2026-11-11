import SwiftUI

struct ActivityKindnessView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @ObservedObject private var favorites = ActivityFavoriteStore.shared
    @ObservedObject private var ledger = ActivityKindnessLedger.shared
    @State private var query = ""
    @State private var filter = "all"
    @State private var starsOnly = false
    @State private var editing: JournalEntry?

    var body: some View {
        let rows = filtered
        ActivityLanePage(engine: engine, lane: .kindness) {
            Text(engine.tf("activity.kindness.total", ledger.total))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            ActivitySearchField(prompt: engine.t("common.search"), text: $query)
            ActivityFilterBar(
                engine: engine,
                filters: ActivityCatalog.filters(for: .kindness),
                filter: filter,
                starsOnly: starsOnly,
                onFilter: { filter = $0 },
                onStars: { starsOnly.toggle() }
            )
            ForEach(rows) { card in
                cardRow(card)
            }
            if rows.isEmpty {
                ActivityQuietNote(text: engine.t("activity.search.empty"))
            }
            ActivityQuietNote(text: engine.t("activity.kindness.local"))
        }
        .sheet(item: $editing) { entry in
            JournalEditor(engine: engine, entry: entry)
        }
    }

    private var filtered: [ActivityKindnessCard] {
        ActivityCatalog.kindness.filter { card in
            ActivityCatalog.matches(
                query: query,
                title: engine.t(card.titleKey),
                detail: engine.t(card.detailKey),
                filters: [card.filter],
                filter: filter,
                starsOnly: starsOnly,
                starID: ActivityCatalog.starID("kindness", card.id),
                favorites: favorites
            )
        }
    }

    private func cardRow(_ card: ActivityKindnessCard) -> some View {
        let title = engine.t(card.titleKey)
        let starred = favorites.contains(ActivityCatalog.starID("kindness", card.id))
        let hearts = ledger.count(card.id)
        return ActivityCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    ActivityRowLabel(
                        title: title,
                        detail: engine.t(card.detailKey),
                        symbol: card.symbol,
                        tint: card.tint
                    )
                    ActivityStarButton(
                        on: starred,
                        label: ActivityCatalog.starLabel(engine, on: starred, title: title)
                    ) {
                        favorites.toggle(ActivityCatalog.starID("kindness", card.id))
                        engine.haptics.soft()
                    }
                }
                HStack(spacing: 10) {
                    Button {
                        give(card)
                    } label: {
                        Text(engine.t("activity.kindness.give"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x2F7D32))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: 0xE5F6DE), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 8)
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color(hex: 0xE4534A))
                        Text("\(hearts)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x243041))
                            .monospacedDigit()
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: hearts)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(engine.tf("activity.kindness.total", hearts))
                }
                .padding(.leading, 52)
                .padding(.trailing, 8)
                .padding(.bottom, 4)
            }
        }
    }

    private func give(_ card: ActivityKindnessCard) {
        ledger.give(card.id)
        editing = engine.addJournal(
            title: engine.t(card.titleKey),
            body: engine.t(card.detailKey),
            tags: ["kindness", card.filter],
            promptID: "kindness-\(card.id)"
        )
        engine.haptics.soft()
    }
}
