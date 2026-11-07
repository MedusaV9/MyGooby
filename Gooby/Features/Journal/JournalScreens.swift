import SwiftUI

/// Journal: search, guided reflections as tiles, a free entry and the saved entries.
struct JournalScreen: View {
    var engine: GoobyEngine
    @State private var query = ""
    @State private var editing: JournalEntry?
    @State private var selectedTheme = ""

    /// Reflection themes in catalog order.
    private var themes: [String] {
        var seen = Set<String>()
        return engine.catalog.prompts.map(\.theme).filter { seen.insert($0).inserted }
    }

    private var currentTheme: String {
        themes.contains(selectedTheme) ? selectedTheme : (themes.first ?? "")
    }

    var body: some View {
        MenuScroll {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.greyText)
                TextField(engine.t("common.search"), text: $query)
                    .font(Theme.Fonts.button)
                    .foregroundStyle(Theme.text)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white, in: Capsule())
            .cardShadow()
            Button {
                editing = engine.addJournal(title: "", body: "", tags: [], promptID: "")
            } label: {
                HStack(spacing: 10) {
                    Text(verbatim: "✏️").font(.system(size: 22))
                    Text(engine.t("journal.new"))
                }
            }
            .menuPrimaryButton(fill: Color(hex: 0xD99A5B))
            MenuFootnote(text: engine.t("journal.rewardHint"))
            MenuSectionHeader(text: engine.tx("menu.journal.prompts", de: "Geführte Reflexionen", en: "Guided reflections"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(themes, id: \.self) { theme in
                        MenuChip(title: themeLabel(theme), icon: MenuJournalArt.icon(theme), selected: currentTheme == theme, tint: Color(hex: 0xD99A5B)) {
                            selectedTheme = theme
                        }
                    }
                }
                .padding(2)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(engine.catalog.prompts.filter { $0.theme == currentTheme }) { prompt in
                    Button {
                        editing = engine.addJournal(title: prompt.title.text(engine.languageCode), body: "", tags: [prompt.theme], promptID: prompt.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            GoobyIcon(MenuJournalArt.icon(prompt.theme), size: 32)
                            Text(prompt.title.text(engine.languageCode))
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.text)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Text(themeLabel(prompt.theme))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.greyText)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
                        .cardShadow()
                    }
                    .buttonStyle(.plain)
                }
            }
            if !filtered.isEmpty {
                MenuSectionHeader(text: engine.tx("menu.journal.entries", de: "Deine Einträge", en: "Your entries"))
            }
            ForEach(filtered) { entry in
                Button {
                    editing = entry
                } label: {
                    GCard {
                        HStack(alignment: .top, spacing: 14) {
                            IconTile(color: MenuPalette.journal, size: 48) {
                                GoobyIcon(MenuJournalArt.icon(entry.tags.first ?? ""), size: 30)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title.isEmpty ? engine.t("journal.untitled") : entry.title)
                                    .font(Theme.Fonts.headline)
                                    .foregroundStyle(Theme.text)
                                    .multilineTextAlignment(.leading)
                                if !entry.body.isEmpty {
                                    Text(entry.body)
                                        .font(Theme.Fonts.body)
                                        .foregroundStyle(Theme.text.opacity(0.8))
                                        .lineLimit(3)
                                        .multilineTextAlignment(.leading)
                                }
                                Text(([engine.formatDate(entry.createdAt)] + entry.tags.map { themeLabel($0) }).joined(separator: " · "))
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.greyText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .menuChrome(engine, title: engine.t("journal.title"), background: MenuPalette.journal)
        .sheet(item: $editing) { entry in
            JournalEditor(engine: engine, entry: entry)
        }
    }

    private func themeLabel(_ tag: String) -> String {
        let key = "theme.\(tag)"
        let value = engine.t(key)
        return value == key ? tag : value
    }

    private var filtered: [JournalEntry] {
        engine.all(JournalEntry.self)
            .filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.body.localizedCaseInsensitiveContains(query) || $0.tags.contains { $0.localizedCaseInsensitiveContains(query) } }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}

/// Emoji for the reflection themes.
enum MenuJournalArt {
    static func icon(_ theme: String) -> String {
        switch theme {
        case "gratitude": return "🙏"
        case "worth": return "💖"
        case "stress": return "🌿"
        case "day": return "🌙"
        case "mind": return "🧘"
        case "motive": return "🚀"
        case "feel": return "💭"
        case "grounding": return "🩹"
        default: return "📔"
        }
    }
}

struct JournalEditor: View {
    var engine: GoobyEngine
    var entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var tags = ""

    var body: some View {
        NavigationStack {
            MenuScroll {
                if let prompt = engine.catalog.prompts.first(where: { $0.id == entry.promptID }) {
                    GCard(fill: Color.white.opacity(0.7)) {
                        HStack(alignment: .top, spacing: 12) {
                            GoobyIcon(MenuJournalArt.icon(prompt.theme), size: 28)
                            Text(prompt.body.text(engine.languageCode))
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                MenuField(placeholder: engine.t("journal.titleField"), text: $title)
                TextEditor(text: $bodyText)
                    .font(Theme.Fonts.button)
                    .foregroundStyle(Theme.text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 240)
                    .padding(10)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
                    .cardShadow()
                MenuField(placeholder: engine.t("journal.tags"), text: $tags)
                Button {
                    let parsed = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    engine.updateJournal(entry, title: title, body: bodyText, tags: parsed)
                    dismiss()
                } label: {
                    Text(engine.t("common.save"))
                }
                .menuPrimaryButton(fill: Color(hex: 0xD99A5B))
                .padding(.top, 4)
                Button(role: .destructive) {
                    engine.deleteJournal(entry)
                    dismiss()
                } label: {
                    Text(engine.t("common.delete"))
                        .font(Theme.Fonts.button)
                        .foregroundStyle(MenuPalette.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .menuChrome(engine, title: engine.t("journal.edit"), close: true, background: MenuPalette.journal)
            .onAppear {
                title = entry.title
                bodyText = entry.body
                tags = entry.tags.joined(separator: ", ")
            }
        }
    }
}
