import SwiftUI

struct JournalScreen: View {
    var engine: GoobyEngine
    @State private var query = ""
    @State private var editing: JournalEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                TextField(engine.t("common.search"), text: $query).textFieldStyle(.roundedBorder)
                Text(engine.t("journal.rewardHint")).font(.system(.caption, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.65))
                ForEach(engine.catalog.prompts) { prompt in
                    Button(prompt.title.text(engine.languageCode)) {
                        editing = engine.addJournal(title: prompt.title.text(engine.languageCode), body: "", tags: [prompt.theme], promptID: prompt.id)
                    }
                    .buttonStyle(.bordered)
                }
                Button(engine.t("journal.new")) {
                    editing = engine.addJournal(title: "", body: "", tags: [], promptID: "")
                }
                .buttonStyle(GoobyButtonStyle())
                ForEach(filtered) { entry in
                    Button {
                        editing = entry
                    } label: {
                        VStack(alignment: .leading) {
                            Text(entry.title.isEmpty ? engine.t("journal.untitled") : entry.title).font(.system(.headline, design: .rounded))
                            Text(entry.body).lineLimit(3)
                            Text(entry.tags.map { tagLabel($0) }.joined(separator: ", ")).font(.system(.caption, design: .rounded))
                        }
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("journal.title"))
        .sheet(item: $editing) { entry in
            JournalEditor(engine: engine, entry: entry)
        }
    }

    private func tagLabel(_ tag: String) -> String {
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

struct JournalEditor: View {
    var engine: GoobyEngine
    var entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var tags = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextField(engine.t("journal.titleField"), text: $title).textFieldStyle(.roundedBorder)
                TextField(engine.t("journal.tags"), text: $tags).textFieldStyle(.roundedBorder)
                TextEditor(text: $bodyText).frame(minHeight: 220).scrollContentBackground(.hidden).padding(8).background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16))
                if let prompt = engine.catalog.prompts.first(where: { $0.id == entry.promptID }) {
                    Text(prompt.body.text(engine.languageCode)).font(.system(.footnote, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.7))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .goobyScreen()
            .navigationTitle(engine.t("journal.edit"))
            .toolbar {
                Button(engine.t("common.delete"), role: .destructive) { engine.deleteJournal(entry); dismiss() }
                Button(engine.t("common.save")) {
                    let parsed = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    engine.updateJournal(entry, title: title, body: bodyText, tags: parsed)
                    dismiss()
                }
            }
            .onAppear {
                title = entry.title
                bodyText = entry.body
                tags = entry.tags.joined(separator: ", ")
            }
        }
    }
}
