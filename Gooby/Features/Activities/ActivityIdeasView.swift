import SwiftUI

struct ActivityIdeasView: View {
    var engine: GoobyEngine
    @ObservedObject private var favorites = ActivityFavoriteStore.shared
    @State private var query = ""
    @State private var starsOnly = false
    @State private var store = GoalMetaStore()
    @State private var note: String?
    @State private var tick = 0

    var body: some View {
        let _ = tick
        let bundles = bundleRows
        let hits = suggestionRows
        ActivityLanePage(engine: engine, lane: .ideas) {
            ActivitySearchField(prompt: engine.t("common.search"), text: $query)
            ActivityFilterBar(
                engine: engine,
                filters: ["all"],
                filter: "all",
                starsOnly: starsOnly,
                onFilter: { _ in },
                onStars: { starsOnly.toggle() }
            )
            if let note {
                ActivityQuietNote(text: note)
            }
            ForEach(bundles) { bundle in
                bundleRow(bundle)
            }
            if !hits.isEmpty {
                Text(engine.t("activity.ideas.matches"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(hits) { suggestion in
                    suggestionRow(suggestion)
                }
            }
            if bundles.isEmpty && hits.isEmpty {
                ActivityQuietNote(text: engine.t("activity.search.empty"))
            }
        }
        .onAppear { store.load() }
    }

    private var bundleRows: [ActivityIdeaBundle] {
        ActivityCatalog.bundles().filter { bundle in
            ActivityCatalog.matches(
                query: query,
                title: bundle.title(engine),
                detail: bundle.detail(engine),
                filters: ["all"],
                filter: "all",
                starsOnly: starsOnly,
                starID: ActivityCatalog.starID("ideas-bundle", bundle.id),
                favorites: favorites
            )
        }
    }

    private var suggestionRows: [GoalSuggestion] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || starsOnly else { return [] }
        return GoalCatalog.suggestions.filter { suggestion in
            let title = suggestion.title(engine.languageCode)
            let area = GoalCatalog.area(suggestion.areaID)?.name(engine.languageCode) ?? ""
            return ActivityCatalog.matches(
                query: query,
                title: title,
                detail: area,
                filters: ["all"],
                filter: "all",
                starsOnly: starsOnly,
                starID: ActivityCatalog.starID("ideas", suggestion.id),
                favorites: favorites
            )
        }
    }

    private func bundleRow(_ bundle: ActivityIdeaBundle) -> some View {
        let starred = favorites.contains(ActivityCatalog.starID("ideas-bundle", bundle.id))
        return ActivityCard {
            HStack(spacing: 0) {
                NavigationLink {
                    ActivityIdeaList(engine: engine, bundle: bundle)
                } label: {
                    ActivityRowLabel(
                        title: bundle.title(engine),
                        detail: bundle.detail(engine),
                        symbol: bundle.symbol,
                        tint: bundle.tint
                    )
                }
                .buttonStyle(.plain)
                ActivityStarButton(
                    on: starred,
                    label: ActivityCatalog.starLabel(engine, on: starred, title: bundle.title(engine))
                ) {
                    favorites.toggle(ActivityCatalog.starID("ideas-bundle", bundle.id))
                    engine.haptics.soft()
                }
            }
        }
    }

    private func suggestionRow(_ suggestion: GoalSuggestion) -> some View {
        let title = suggestion.title(engine.languageCode)
        let area = GoalCatalog.area(suggestion.areaID)?.name(engine.languageCode) ?? ""
        let starred = favorites.contains(ActivityCatalog.starID("ideas", suggestion.id))
        let added = GoalActions.isAdded(suggestion, engine: engine, store: store)
        return ActivityCard {
            HStack(spacing: 0) {
                Button {
                    add(suggestion)
                } label: {
                    ActivityRowLabel(
                        title: title,
                        detail: area,
                        symbol: GoalArt.symbol(for: suggestion.glyph),
                        tint: GoalCatalog.area(suggestion.areaID)?.tint ?? 0x8FCB74,
                        mark: added ? "checkmark.circle.fill" : "plus.circle.fill"
                    )
                }
                .buttonStyle(.plain)
                ActivityStarButton(
                    on: starred,
                    label: ActivityCatalog.starLabel(engine, on: starred, title: title)
                ) {
                    favorites.toggle(ActivityCatalog.starID("ideas", suggestion.id))
                    engine.haptics.soft()
                }
            }
        }
    }

    private func add(_ suggestion: GoalSuggestion) {
        store.load()
        let already = GoalActions.isAdded(suggestion, engine: engine, store: store)
        _ = GoalActions.addSuggestion(suggestion, engine: engine, store: store)
        note = engine.t(already ? "activity.ideas.kept" : "activity.ideas.added")
        tick += 1
        engine.haptics.soft()
    }
}

struct ActivityIdeaList: View {
    var engine: GoobyEngine
    var bundle: ActivityIdeaBundle
    @ObservedObject private var favorites = ActivityFavoriteStore.shared
    @State private var query = ""
    @State private var starsOnly = false
    @State private var store = GoalMetaStore()
    @State private var note: String?
    @State private var tick = 0

    var body: some View {
        let _ = tick
        let rows = filtered
        ActivityLanePage(engine: engine, lane: .ideas, heading: bundle.title(engine)) {
            ActivitySearchField(prompt: engine.t("common.search"), text: $query)
            ActivityFilterBar(
                engine: engine,
                filters: ["all"],
                filter: "all",
                starsOnly: starsOnly,
                onFilter: { _ in },
                onStars: { starsOnly.toggle() }
            )
            if let note {
                ActivityQuietNote(text: note)
            }
            ForEach(rows) { suggestion in
                suggestionRow(suggestion)
            }
            if rows.isEmpty {
                ActivityQuietNote(text: engine.t("activity.search.empty"))
            }
        }
        .onAppear { store.load() }
    }

    private var filtered: [GoalSuggestion] {
        bundle.suggestions().filter { suggestion in
            let title = suggestion.title(engine.languageCode)
            let area = GoalCatalog.area(suggestion.areaID)?.name(engine.languageCode) ?? ""
            return ActivityCatalog.matches(
                query: query,
                title: title,
                detail: area,
                filters: ["all"],
                filter: "all",
                starsOnly: starsOnly,
                starID: ActivityCatalog.starID("ideas", suggestion.id),
                favorites: favorites
            )
        }
    }

    private func suggestionRow(_ suggestion: GoalSuggestion) -> some View {
        let title = suggestion.title(engine.languageCode)
        let area = GoalCatalog.area(suggestion.areaID)?.name(engine.languageCode) ?? ""
        let starred = favorites.contains(ActivityCatalog.starID("ideas", suggestion.id))
        let added = GoalActions.isAdded(suggestion, engine: engine, store: store)
        return ActivityCard {
            HStack(spacing: 0) {
                Button {
                    add(suggestion)
                } label: {
                    ActivityRowLabel(
                        title: title,
                        detail: area,
                        symbol: GoalArt.symbol(for: suggestion.glyph),
                        tint: GoalCatalog.area(suggestion.areaID)?.tint ?? 0x8FCB74,
                        mark: added ? "checkmark.circle.fill" : "plus.circle.fill"
                    )
                }
                .buttonStyle(.plain)
                ActivityStarButton(
                    on: starred,
                    label: ActivityCatalog.starLabel(engine, on: starred, title: title)
                ) {
                    favorites.toggle(ActivityCatalog.starID("ideas", suggestion.id))
                    engine.haptics.soft()
                }
            }
        }
    }

    private func add(_ suggestion: GoalSuggestion) {
        store.load()
        let already = GoalActions.isAdded(suggestion, engine: engine, store: store)
        _ = GoalActions.addSuggestion(suggestion, engine: engine, store: store)
        note = engine.t(already ? "activity.ideas.kept" : "activity.ideas.added")
        tick += 1
        engine.haptics.soft()
    }
}
