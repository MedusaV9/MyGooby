import SwiftUI
import UIKit

struct ActivityKindnessView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @ObservedObject private var favorites = ActivityFavoriteStore.shared
    @ObservedObject private var ledger = ActivityKindnessLedger.shared
    @State private var query = ""
    @State private var filter = "friends"
    @State private var starsOnly = false
    @State private var writing: ActivityKindnessCard?
    @State private var notice: String?

    var body: some View {
        let rows = filtered
        ActivityLanePage(engine: engine, lane: .kindness) {
            Text(engine.tf("activity.kindness.total", ledger.total))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: ledger.total)
            if let notice {
                ActivityQuietNote(text: notice)
            }
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
            ActivityQuietNote(text: engine.tf("activity.kindness.energyNote", ActivityKindnessReward.energy))
            ActivityQuietNote(text: engine.t("activity.kindness.local"))
        }
        .sheet(item: $writing) { card in
            ActivityKindnessNote(engine: engine, card: card) { rewarded in
                ledger.record(card.id)
                notice = rewarded
                    ? engine.tf("activity.kindness.rewarded", ActivityKindnessReward.energy)
                    : engine.t("activity.kindness.capped")
            }
        }
        .onChange(of: notice) { _, new in
            guard let new else { return }
            UIAccessibility.post(notification: .announcement, argument: new)
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

    private func openLabel(title: String, detail: String, saved: Int) -> String {
        var line = "\(engine.tf("activity.kindness.open", title, ActivityKindnessReward.energy)). \(detail)"
        if saved > 0 {
            line += ". \(engine.tf("activity.kindness.count", saved))"
        }
        return line
    }

    private func cardRow(_ card: ActivityKindnessCard) -> some View {
        let title = engine.t(card.titleKey)
        let starred = favorites.contains(ActivityCatalog.starID("kindness", card.id))
        let saved = ledger.count(card.id)
        return ActivityCard {
            HStack(alignment: .top, spacing: 0) {
                Button {
                    writing = card
                    engine.haptics.soft()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        ActivityRowLabel(
                            title: title,
                            detail: engine.t(card.detailKey),
                            symbol: card.symbol,
                            tint: card.tint,
                            badge: "\(ActivityKindnessReward.energy)"
                        )
                        if saved > 0 {
                            Text(engine.tf("activity.kindness.count", saved))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: 0x2F7D32))
                                .padding(.leading, 52)
                                .padding(.bottom, 4)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(openLabel(title: title, detail: engine.t(card.detailKey), saved: saved))
                ActivityStarButton(
                    on: starred,
                    label: ActivityCatalog.starLabel(engine, on: starred, title: title)
                ) {
                    favorites.toggle(ActivityCatalog.starID("kindness", card.id))
                    engine.haptics.soft()
                }
            }
        }
    }
}

/// A kindness prompt saved as a journal note. Friends stay a note on this phone, not a network.
private struct ActivityKindnessNote: View {
    var engine: GoobyEngine
    var card: ActivityKindnessCard
    var onDone: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var saving = false
    @FocusState private var focused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(engine.t(card.detailKey))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text(engine.t("activity.kindness.placeholder"))
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Theme.ink.opacity(0.35))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                        TextEditor(text: $text)
                            .focused($focused)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .frame(minHeight: 180)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .accessibilityLabel(engine.t("activity.kindness.placeholder"))
                    }
                    .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Text(engine.t("activity.kindness.local"))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(engine.tf("activity.kindness.energyNote", ActivityKindnessReward.energy))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                    Button(engine.t("common.save")) { save() }
                        .buttonStyle(GoobyButtonStyle(fill: Color(hex: 0x2F7D32), ink: .white))
                        .disabled(trimmed.isEmpty || saving)
                        .opacity(trimmed.isEmpty || saving ? 0.45 : 1)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .goobyScreen()
            .navigationTitle(engine.t(card.titleKey))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(engine.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(engine.t("common.save")) { save() }
                        .disabled(trimmed.isEmpty || saving)
                }
            }
            .onAppear { focused = true }
        }
    }

    private func save() {
        let body = trimmed
        guard !saving, !body.isEmpty else { return }
        saving = true
        let title = engine.t(card.titleKey)
        let tags = ["kindness", card.filter]
        let entry = engine.addJournal(title: title, body: "", tags: tags, promptID: "kindness-\(card.id)")
        let day = engine.dayKey()
        let before = engine.dailyStat(day).journalRewards
        engine.updateJournal(entry, title: title, body: body, tags: tags)
        let rewarded = engine.dailyStat(day).journalRewards > before
        if rewarded { engine.celebration += 1 }
        onDone(rewarded)
        dismiss()
    }
}
