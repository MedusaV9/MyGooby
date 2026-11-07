import SwiftUI

struct JournalHomeView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @State private var query = ""
    @State private var tag = ""
    @State private var editor: JournalDraft?
    @State private var showGuide = false

    var body: some View {
        CareScreen {
            TextField(session.text(.journalSearch), text: $query)
                .textFieldStyle(.roundedBorder)
            CareFlowLayout {
                tagChip(session.text(.tagAll), value: "")
                ForEach(store.journalTags(), id: \.self) { item in
                    tagChip(item, value: item)
                }
            }
            HStack(spacing: 10) {
                Button(session.text(.journalFree)) {
                    editor = JournalDraft.newFree(day: session.todayKey)
                }
                .buttonStyle(CarePrimaryButton())
                Button(session.text(.journalGuided)) { showGuide = true }
                    .buttonStyle(CarePrimaryButton())
            }
            let entries = store.journalEntries(query: query, tag: tag.isEmpty ? nil : tag)
            if entries.isEmpty {
                CareCard {
                    Text(session.text(.journalEmpty)).foregroundStyle(CarePalette.ink)
                }
            }
            ForEach(entries) { entry in
                Button {
                    editor = JournalDraft.existing(entry)
                } label: {
                    CareCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.title.isEmpty ? session.text(.journalNew) : entry.title)
                                .font(.headline)
                                .foregroundStyle(CarePalette.ink)
                            Text(CareDay.format(entry.day, language: session.language, calendar: session.calendar, template: "d MMM y"))
                                .font(.caption)
                                .foregroundStyle(CarePalette.ink.opacity(0.7))
                            if let kind = entry.reflection {
                                Text(CareCopy.reflection(kind, session.language))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(CarePalette.ink)
                            }
                            Text(entry.body)
                                .font(.subheadline)
                                .foregroundStyle(CarePalette.ink.opacity(0.85))
                                .lineLimit(3)
                            if !entry.tags.isEmpty {
                                Text(entry.tags.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(CarePalette.ink.opacity(0.7))
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Text(session.text(.notShared))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
        }
        .navigationTitle(session.text(.tabJournal))
        .careGroundingShortcut()
        .sheet(item: $editor) { draft in
            NavigationStack { JournalEditorView(draft: draft) }
        }
        .navigationDestination(isPresented: $showGuide) {
            ReflectionPickerView { kind in
                editor = JournalDraft.guided(kind: kind, day: session.todayKey)
                showGuide = false
            }
        }
    }

    private func tagChip(_ title: String, value: String) -> some View {
        Button {
            tag = value
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(CarePalette.ink)
                .background(Capsule().fill(tag == value ? CarePalette.mint : CarePalette.card))
        }
        .buttonStyle(.plain)
    }
}

struct JournalDraft: Identifiable, Equatable {
    var id: UUID
    var day: String
    var title: String
    var body: String
    var tags: [String]
    var reflection: ReflectionKind?
    var answers: [String]
    var isNew: Bool

    static func newFree(day: String) -> JournalDraft {
        JournalDraft(id: UUID(), day: day, title: "", body: "", tags: [], reflection: nil, answers: [], isNew: true)
    }

    static func guided(kind: ReflectionKind, day: String) -> JournalDraft {
        JournalDraft(id: UUID(), day: day, title: "", body: "", tags: [], reflection: kind, answers: ["", "", ""], isNew: true)
    }

    static func existing(_ entry: JournalEntry) -> JournalDraft {
        JournalDraft(
            id: entry.id,
            day: entry.day,
            title: entry.title,
            body: entry.body,
            tags: entry.tags,
            reflection: entry.reflection,
            answers: [],
            isNew: false
        )
    }
}

private struct JournalEditorView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @Environment(\.dismiss) private var dismiss
    @State private var draft: JournalDraft
    @State private var tagText = ""
    @State private var message = ""
    @State private var confirmDelete = false

    init(draft: JournalDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        CareScreen {
            if let kind = draft.reflection, draft.isNew {
                Text(CareCopy.reflection(kind, session.language))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CarePalette.ink)
                let questions = ReflectionCatalog.questions(for: kind)
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    Text(session.text(question))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarePalette.ink)
                    TextField(session.text(question), text: answerBinding(index), axis: .vertical)
                        .lineLimit(2...5)
                        .textFieldStyle(.roundedBorder)
                }
                Text(session.text(.reflectionFoot))
                    .font(.footnote)
                    .foregroundStyle(CarePalette.ink.opacity(0.7))
            } else {
                TextField(session.text(.journalTitleField), text: $draft.title)
                    .textFieldStyle(.roundedBorder)
                TextField(session.text(.journalBody), text: $draft.body, axis: .vertical)
                    .lineLimit(6...14)
                    .textFieldStyle(.roundedBorder)
            }
            DatePicker(session.text(.journalDate), selection: dayBinding, displayedComponents: .date)
                .foregroundStyle(CarePalette.ink)
            tagRow
            if !message.isEmpty {
                Text(message).font(.footnote).foregroundStyle(CarePalette.ink)
            }
            Button(draft.reflection != nil && draft.isNew ? session.text(.reflectionSave) : session.text(.save)) {
                save()
            }
            .buttonStyle(CarePrimaryButton())
            if !draft.isNew {
                Button(session.text(.delete), role: .destructive) { confirmDelete = true }
                    .foregroundStyle(CarePalette.ink)
            }
            Text(session.text(.notShared))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
        }
        .navigationTitle(session.text(.journalNew))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(session.text(.close)) { dismiss() }
            }
        }
        .confirmationDialog(session.text(.journalDeleteTitle), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(session.text(.delete), role: .destructive) {
                store.deleteJournal(id: draft.id)
                dismiss()
            }
            Button(session.text(.cancel), role: .cancel) {}
        } message: {
            Text(session.text(.journalDeleteMessage))
        }
    }

    private var tagRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(session.text(.journalAddTag), text: $tagText)
                    .textFieldStyle(.roundedBorder)
                Button(session.text(.add)) { addTag() }
                    .foregroundStyle(CarePalette.ink)
            }
            CareFlowLayout {
                ForEach(draft.tags, id: \.self) { tag in
                    Button {
                        draft.tags.removeAll { $0 == tag }
                    } label: {
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(CarePalette.ink)
                            .background(Capsule().fill(CarePalette.pink))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dayBinding: Binding<Date> {
        Binding(
            get: { CareDay.date(from: draft.day, calendar: session.calendar) ?? session.now },
            set: { draft.day = CareDay.key(for: $0, calendar: session.calendar) }
        )
    }

    private func answerBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { index < draft.answers.count ? draft.answers[index] : "" },
            set: { value in
                if draft.answers.count < 3 { draft.answers = ["", "", ""] }
                draft.answers[index] = value
            }
        )
    }

    private func addTag() {
        let cleaned = JournalSearch.cleanedTags(draft.tags + [tagText])
        draft.tags = cleaned
        tagText = ""
    }

    private func save() {
        if let kind = draft.reflection, draft.isNew {
            let answers = draft.answers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if !answers.contains(where: { !$0.isEmpty }) {
                message = session.text(.errEmptyReflection)
                return
            }
            draft.body = ReflectionCatalog.composedBody(kind: kind, answers: answers, language: session.language)
            if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                draft.title = CareCopy.reflection(kind, session.language)
            }
        }
        let entry = JournalEntry(
            id: draft.id,
            day: draft.day,
            createdAt: session.now,
            updatedAt: session.now,
            title: draft.title,
            body: draft.body,
            tags: draft.tags,
            reflection: draft.isNew ? draft.reflection : store.journalEntries(query: "", tag: nil).first { $0.id == draft.id }?.reflection,
            rewarded: false
        )
        switch store.saveJournal(entry, now: session.now) {
        case .success(let reward):
            if reward != nil { CareHaptics.success() }
            dismiss()
        case .failure(let issue):
            message = CareCopy.issue(issue, session.language)
        }
    }
}

private struct ReflectionPickerView: View {
    @EnvironmentObject private var session: CareSession
    @Environment(\.dismiss) private var dismiss
    var choose: (ReflectionKind) -> Void

    var body: some View {
        CareScreen {
            Text(session.text(.reflectionChoose))
                .font(.title3.weight(.semibold))
                .foregroundStyle(CarePalette.ink)
            ForEach(ReflectionKind.allCases) { kind in
                Button {
                    choose(kind)
                } label: {
                    CareCard(fill: CarePalette.lavender.opacity(0.75)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(CareCopy.reflection(kind, session.language))
                                .font(.headline)
                                .foregroundStyle(CarePalette.ink)
                            Text(session.text(ReflectionCatalog.questions(for: kind)[0]))
                                .font(.subheadline)
                                .foregroundStyle(CarePalette.ink.opacity(0.75))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            Text(session.text(.reflectionFoot))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
        }
        .navigationTitle(session.text(.journalGuided))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(session.text(.close)) { dismiss() }
            }
        }
    }
}
