import SwiftUI

struct ActivityIdeasView: View {
    var engine: GoobyEngine
    @State private var store = GoalMetaStore()
    @State private var note: String?
    @State private var tick = 0
    @State private var openID: String?

    var body: some View {
        let _ = tick
        ActivityLanePage(engine: engine, lane: .ideas) {
            if let note {
                ActivityQuietNote(text: note)
            }
            ForEach(ActivityCatalog.bundles()) { bundle in
                packRow(bundle)
            }
        }
        .navigationDestination(item: $openID) { id in
            if let bundle = ActivityCatalog.bundles().first(where: { $0.id == id }) {
                ActivityIdeaList(engine: engine, bundle: bundle)
            } else {
                EmptyView()
            }
        }
        .onAppear {
            store.load()
            tick += 1
        }
    }

    private func packRow(_ bundle: ActivityIdeaBundle) -> some View {
        let title = bundle.title(engine)
        let ready = packReady(bundle)
        return HStack(spacing: 4) {
            Button {
                add(bundle)
            } label: {
                HStack(spacing: 12) {
                    PackBadge(id: bundle.id)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x243041))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(bundle.detail(engine))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: 0x8B97A3))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    if ready {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x3EAE45))
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.tf(ready ? "activity.ideas.pack.ready" : "activity.ideas.pack.add", title))
            Button {
                openID = bundle.id
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: 0xC5CAD1))
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.tf("activity.ideas.pack.contents", title))
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
    }

    private func packReady(_ bundle: ActivityIdeaBundle) -> Bool {
        let goals = bundle.suggestions()
        guard !goals.isEmpty else { return false }
        return goals.allSatisfy { GoalActions.isAdded($0, engine: engine, store: store) }
    }

    private func add(_ bundle: ActivityIdeaBundle) {
        store.load()
        let count = GoalActions.addPack(ActivityCatalog.packPlan(bundle), engine: engine, store: store)
        if count == 0 {
            note = engine.t("activity.ideas.kept")
            engine.haptics.soft()
        } else if count == 1 {
            note = engine.t("activity.ideas.added")
            engine.haptics.celebrate()
        } else {
            note = engine.tf("activity.ideas.pack.added", count)
            engine.haptics.celebrate()
        }
        tick += 1
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

private struct PackBadge: View {
    var id: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: 0x3EAE45))
            switch id {
            case "day": SunflowerMark()
            case "tomorrow": DaySunMark()
            case "sleep": NightWindowMark()
            case "active": ShoeMark()
            default: FacesMark()
            }
        }
        .accessibilityHidden(true)
    }
}

private struct SunflowerMark: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(Color(hex: 0xF6C43A))
                    .frame(width: 6, height: 12)
                    .offset(y: -8)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            Circle().fill(Color(hex: 0x8A5A2B)).frame(width: 10, height: 10)
        }
    }
}

private struct DaySunMark: View {
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(Color(hex: 0xFFE08A))
                    .frame(width: 3, height: 7)
                    .offset(y: -11)
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            Circle().fill(Color(hex: 0xF6A23A)).frame(width: 14, height: 14)
        }
    }
}

private struct NightWindowMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0x243056))
                .frame(width: 22, height: 22)
            Rectangle().fill(Color(hex: 0x3EAE45)).frame(width: 22, height: 1.6)
            Rectangle().fill(Color(hex: 0x3EAE45)).frame(width: 1.6, height: 22)
            Circle().fill(Color(hex: 0xF6D56A)).frame(width: 3, height: 3).offset(x: 5, y: -6)
            Circle().fill(Color(hex: 0xF4E2A0)).frame(width: 7, height: 7).offset(x: -4, y: 3)
            Circle().fill(Color(hex: 0x243056)).frame(width: 6, height: 6).offset(x: -2, y: 2)
        }
    }
}

private struct ShoeMark: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0xF4F7FB))
                .frame(width: 24, height: 5)
                .offset(y: 9)
            Capsule()
                .fill(Color(hex: 0xE23B4A))
                .frame(width: 26, height: 11)
                .offset(y: 3)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white)
                .frame(width: 12, height: 7)
                .offset(x: 6, y: 1)
        }
    }
}

private struct FacesMark: View {
    var body: some View {
        ZStack {
            face(Color(hex: 0xF6C14A)).offset(x: -8, y: 3)
            face(Color(hex: 0x7BC96A)).offset(x: 8, y: 3)
            face(Color(hex: 0xF4A574)).offset(y: -3)
        }
    }

    private func face(_ color: Color) -> some View {
        ZStack {
            Circle().fill(color).frame(width: 14, height: 14)
            Circle().fill(Color(hex: 0x243041)).frame(width: 1.6, height: 1.6).offset(x: -2.2, y: -1)
            Circle().fill(Color(hex: 0x243041)).frame(width: 1.6, height: 1.6).offset(x: 2.2, y: -1)
        }
    }
}
