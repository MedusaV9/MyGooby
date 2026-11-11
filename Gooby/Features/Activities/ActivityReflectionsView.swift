import SwiftUI

struct ActivityReflectionsView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @ObservedObject private var favorites = ActivityFavoriteStore.shared
    @State private var query = ""
    @State private var filter = "all"
    @State private var starsOnly = false
    @State private var editing: JournalEntry?

    var body: some View {
        let rows = filtered
        ActivityLanePage(
            engine: engine,
            lane: .reflections,
            corner: engine.t("activity.reflect.free"),
            cornerAction: openBlank
        ) {
            ActivitySearchField(prompt: engine.t("common.search"), text: $query)
            ActivityFilterBar(
                engine: engine,
                filters: ActivityCatalog.filters(for: .reflections),
                filter: filter,
                starsOnly: starsOnly,
                onFilter: { filter = $0 },
                onStars: { starsOnly.toggle() }
            )
            ForEach(rows) { prompt in
                row(prompt)
            }
            if rows.isEmpty {
                ActivityQuietNote(text: engine.t("activity.search.empty"))
            }
            ActivityQuietNote(text: engine.t("activity.reflect.note"))
            ActivityCapsuleLink(title: engine.t("activity.open.journal")) {
                ActivityLaunch(engine: engine, reduceMotion: reduceMotion, run: .journal)
            }
        }
        .sheet(item: $editing) { entry in
            JournalEditor(engine: engine, entry: entry)
        }
    }

    private var filtered: [PromptDef] {
        engine.catalog.prompts.filter { prompt in
            let title = prompt.title.text(engine.languageCode)
            let detail = prompt.body.text(engine.languageCode)
            return ActivityCatalog.matches(
                query: query,
                title: title,
                detail: detail,
                filters: [ActivityCatalog.reflectionChip(prompt.theme)],
                filter: filter,
                starsOnly: starsOnly,
                starID: ActivityCatalog.starID("reflections", prompt.id),
                favorites: favorites
            )
        }
    }

    private func row(_ prompt: PromptDef) -> some View {
        let title = prompt.title.text(engine.languageCode)
        let detail = prompt.body.text(engine.languageCode)
        let starred = favorites.contains(ActivityCatalog.starID("reflections", prompt.id))
        return ActivityCard {
            HStack(spacing: 0) {
                Button {
                    open(prompt)
                } label: {
                    ActivityRowLabel(
                        title: title,
                        detail: detail,
                        symbol: ActivityCatalog.reflectionSymbol(prompt.theme),
                        tint: ActivityCatalog.reflectionTint(prompt.theme),
                        badge: reflectionBadge(prompt.theme)
                    )
                }
                .buttonStyle(.plain)
                ActivityStarButton(
                    on: starred,
                    label: ActivityCatalog.starLabel(engine, on: starred, title: title)
                ) {
                    favorites.toggle(ActivityCatalog.starID("reflections", prompt.id))
                    engine.haptics.soft()
                }
            }
        }
    }

    private func reflectionBadge(_ theme: String) -> String {
        switch ActivityCatalog.reflectionChip(theme) {
        case "deep": return "30"
        case "morning": return "5"
        case "energize": return "4+"
        case "night": return "3+"
        default: return "2+"
        }
    }

    private func open(_ prompt: PromptDef) {
        editing = engine.addJournal(
            title: prompt.title.text(engine.languageCode),
            body: "",
            tags: [prompt.theme],
            promptID: prompt.id
        )
        engine.haptics.soft()
    }

    private func openBlank() {
        editing = engine.addJournal(title: "", body: "", tags: [], promptID: "")
        engine.haptics.soft()
    }
}
