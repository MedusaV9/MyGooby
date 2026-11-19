import SwiftData
import SwiftUI

// A note the person seals until a calendar day. The words stay out of the
// sealed screens. Opening is a separate tap, and only on or after that day.

@Model
final class TimeCapsuleNote {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var opensOn: Date = Date()
    var opensOnKey: String = ""
    var title: String = ""
    var note: String = ""
    var openedAt: Date? = nil

    init() {}
}

enum TimeCapsuleGate {
    static func start(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    static func key(_ date: Date, calendar: Calendar = .current) -> String {
        DayKey.make(start(date, calendar: calendar), calendar: calendar)
    }

    /// YYYY-MM-DD compares in calendar order. A short or empty key stays closed.
    static func canOpen(opensOnKey: String, now: Date, calendar: Calendar = .current) -> Bool {
        guard opensOnKey.count == 10 else { return false }
        return DayKey.make(now, calendar: calendar) >= opensOnKey
    }

    static func day(for key: String, fallback: Date, calendar: Calendar = .current) -> Date {
        DayKey.parse(key, calendar: calendar) ?? fallback
    }
}

@MainActor
enum TimeCapsule {
    /// The journal's only hook into the sealed notes.
    static func open(_ engine: GoobyEngine) -> some View {
        NavigationLink {
            TimeCapsuleList(engine: engine)
        } label: {
            TimeCapsuleRow(
                sealed: true,
                title: engine.t("capsule.title"),
                subtitle: engine.t("capsule.rowHint")
            )
        }
        .buttonStyle(.plain)
    }

    static func notes(_ engine: GoobyEngine) -> [TimeCapsuleNote] {
        engine.all(TimeCapsuleNote.self).sorted { lhs, rhs in
            let leftOpen = lhs.openedAt != nil
            let rightOpen = rhs.openedAt != nil
            if leftOpen != rightOpen { return !leftOpen }
            if !leftOpen {
                if lhs.opensOnKey != rhs.opensOnKey { return lhs.opensOnKey < rhs.opensOnKey }
                return lhs.createdAt > rhs.createdAt
            }
            return (lhs.openedAt ?? lhs.createdAt) > (rhs.openedAt ?? rhs.createdAt)
        }
    }

    static func day(_ engine: GoobyEngine, _ note: TimeCapsuleNote) -> String {
        engine.formatDate(TimeCapsuleGate.day(for: note.opensOnKey, fallback: note.opensOn))
    }

    static func openedTitle(_ engine: GoobyEngine, _ note: TimeCapsuleNote) -> String {
        let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty { return title }
        let line = note.note
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split { $0.isNewline }
            .first
            .map(String.init) ?? ""
        return line.isEmpty ? engine.t("capsule.title") : line
    }
}

@MainActor
private struct TimeCapsuleList: View {
    var engine: GoobyEngine
    @State private var writing = false
    @State private var revision = 0

    var body: some View {
        let _ = revision
        let rows = TimeCapsule.notes(engine)
        ScrollView {
            VStack(spacing: 12) {
                if rows.isEmpty {
                    Text(engine.t("capsule.empty"))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(rows) { note in
                    NavigationLink {
                        TimeCapsuleDetail(engine: engine, note: note)
                    } label: {
                        TimeCapsuleRowLabel(engine: engine, note: note)
                    }
                    .buttonStyle(.plain)
                }
                Button(engine.t("capsule.write")) { writing = true }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.yellow, ink: Theme.ink))
                    .padding(.top, 4)
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("capsule.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { revision += 1 }
        .sheet(isPresented: $writing) {
            TimeCapsuleComposer(engine: engine) { revision += 1 }
        }
    }
}

@MainActor
private struct TimeCapsuleRowLabel: View {
    var engine: GoobyEngine
    var note: TimeCapsuleNote

    var body: some View {
        if let opened = note.openedAt {
            TimeCapsuleRow(
                sealed: false,
                title: TimeCapsule.openedTitle(engine, note),
                subtitle: engine.tf("capsule.openedOn", engine.formatDate(opened))
            )
        } else if TimeCapsuleGate.canOpen(opensOnKey: note.opensOnKey, now: engine.now()) {
            TimeCapsuleRow(
                sealed: true,
                title: engine.t("capsule.ready"),
                subtitle: TimeCapsule.day(engine, note)
            )
        } else {
            TimeCapsuleRow(
                sealed: true,
                title: engine.t("capsule.sealed"),
                subtitle: engine.tf("capsule.until", TimeCapsule.day(engine, note))
            )
        }
    }
}

private struct TimeCapsuleRow: View {
    var sealed: Bool
    var title: String
    var subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            TimeCapsuleJar(sealed: sealed, span: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.ink.opacity(0.35))
        }
        .foregroundStyle(Theme.ink)
        .padding(12)
        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

@MainActor
private struct TimeCapsuleDetail: View {
    var engine: GoobyEngine
    var note: TimeCapsuleNote
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        let open = note.openedAt != nil
        let ready = !open && TimeCapsuleGate.canOpen(opensOnKey: note.opensOnKey, now: engine.now())
        ScrollView {
            VStack(spacing: 14) {
                TimeCapsuleJar(sealed: !open, span: 132)
                    .padding(.top, 8)
                Text(heading(open: open, ready: ready))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(dateLine(open: open))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                if open {
                    OpenNoteCard(text: note.note)
                } else {
                    SealedCopy(engine: engine, ready: ready) { reveal() }
                }
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: .sit,
                    reduceMotion: engine.reduceMotion,
                    companion: nil,
                    showCompanion: false
                )
                .frame(height: 180)
                .accessibilityHidden(true)
                Button(engine.t("common.delete")) { confirmDelete = true }
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
        }
        .goobyScreen()
        .navigationTitle(engine.t("capsule.title"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(engine.t("capsule.deleteAsk"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(engine.t("common.delete"), role: .destructive) { remove() }
            Button(engine.t("common.cancel"), role: .cancel) {}
        } message: {
            Text(engine.t("capsule.deleteNote"))
        }
    }

    private func heading(open: Bool, ready: Bool) -> String {
        if open {
            let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
            return title.isEmpty ? engine.t("capsule.title") : title
        }
        return engine.t(ready ? "capsule.ready" : "capsule.sealed")
    }

    private func dateLine(open: Bool) -> String {
        if let opened = note.openedAt {
            return engine.tf("capsule.openedOn", engine.formatDate(opened))
        }
        let day = TimeCapsule.day(engine, note)
        if TimeCapsuleGate.canOpen(opensOnKey: note.opensOnKey, now: engine.now()) { return day }
        return engine.tf("capsule.until", day)
    }

    private func reveal() {
        guard note.openedAt == nil else { return }
        guard TimeCapsuleGate.canOpen(opensOnKey: note.opensOnKey, now: engine.now()) else { return }
        note.openedAt = engine.now()
        engine.save()
        engine.cue(.select)
    }

    private func remove() {
        engine.context.delete(note)
        engine.save()
        dismiss()
    }
}

private struct SealedCopy: View {
    var engine: GoobyEngine
    var ready: Bool
    var open: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(engine.t(ready ? "capsule.readyBody" : "capsule.closedBody"))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if ready {
                Button(engine.t("capsule.open"), action: open)
                    .buttonStyle(GoobyButtonStyle(fill: Theme.yellow, ink: Theme.ink))
            }
        }
    }
}

private struct OpenNoteCard: View {
    var text: String

    var body: some View {
        SoftCard {
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}

@MainActor
private struct TimeCapsuleComposer: View {
    var engine: GoobyEngine
    var onSealed: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var noteText = ""
    @State private var day = Date().addingTimeInterval(30 * 24 * 60 * 60)
    @State private var prepared = false

    var body: some View {
        let earliest = TimeCapsuleGate.start(engine.now())
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(engine.t("capsule.dayHint"))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                    TextField(engine.t("capsule.heading"), text: $title, prompt: Text(engine.t("capsule.headingPlaceholder")))
                        .font(.system(.body, design: .rounded))
                        .textFieldStyle(.roundedBorder)
                    Text(engine.t("capsule.note"))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    ZStack(alignment: .topLeading) {
                        if trimmed.isEmpty {
                            Text(engine.t("capsule.notePlaceholder"))
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Theme.ink.opacity(0.35))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $noteText)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)
                    }
                    .padding(8)
                    .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Text(engine.t("capsule.day"))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    DatePicker(engine.t("capsule.day"), selection: $day, in: earliest..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: engine.languageCode))
                        .tint(Theme.accent)
                        .frame(maxHeight: 400)
                    Button(engine.t("capsule.seal")) { seal(earliest: earliest) }
                        .buttonStyle(GoobyButtonStyle(fill: Theme.yellow, ink: Theme.ink))
                        .disabled(trimmed.isEmpty)
                        .opacity(trimmed.isEmpty ? 0.45 : 1)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .goobyScreen()
            .navigationTitle(engine.t("capsule.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(engine.t("common.close")) { dismiss() }
            }
        }
        .onAppear {
            guard !prepared else { return }
            day = Calendar.current.date(byAdding: .day, value: 30, to: earliest) ?? earliest
            prepared = true
        }
    }

    private func seal(earliest: Date) {
        let text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let chosen = max(TimeCapsuleGate.start(day), earliest)
        let row = TimeCapsuleNote()
        row.createdAt = engine.now()
        row.opensOn = chosen
        row.opensOnKey = TimeCapsuleGate.key(chosen)
        row.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        row.note = text
        row.openedAt = nil
        engine.context.insert(row)
        engine.save()
        engine.cue(.save)
        onSealed()
        dismiss()
    }
}

private struct TimeCapsuleJar: View {
    var sealed: Bool
    var span: CGFloat = 132

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Ellipse()
                    .fill(Theme.ink.opacity(0.08))
                    .frame(width: w * 0.62, height: h * 0.08)
                    .position(x: w * 0.5, y: h * 0.94)
                if !sealed {
                    RoundedRectangle(cornerRadius: w * 0.06, style: .continuous)
                        .fill(Color(hex: 0xFFFDFB))
                        .frame(width: w * 0.52, height: h * 0.2)
                        .overlay(
                            RoundedRectangle(cornerRadius: w * 0.06, style: .continuous)
                                .stroke(Color(hex: 0xE7D3B5), lineWidth: max(1, w * 0.015))
                        )
                        .position(x: w * 0.5, y: h * 0.12)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(hex: 0xE8C9A0))
                        .frame(width: w * 0.34, height: h * 0.055)
                        .position(x: w * 0.5, y: h * 0.02)
                }
                RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                    .fill(Color(hex: 0xE7F4FF).opacity(0.95))
                    .frame(width: w * 0.72, height: h * 0.58)
                    .overlay(
                        RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                            .stroke(Color(hex: 0x8EC4E8), lineWidth: max(2, w * 0.028))
                    )
                    .position(x: w * 0.5, y: h * 0.62)
                Capsule()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: w * 0.055, height: h * 0.28)
                    .position(x: w * 0.3, y: h * 0.58)
                RoundedRectangle(cornerRadius: w * 0.04, style: .continuous)
                    .fill(Color(hex: 0xE8C9A0))
                    .frame(width: w * 0.36, height: h * 0.09)
                    .position(x: w * 0.5, y: h * 0.3)
                if sealed {
                    Capsule()
                        .fill(Color(hex: 0xD3C2FF))
                        .frame(width: w * 0.62, height: h * 0.07)
                        .position(x: w * 0.5, y: h * 0.66)
                    Circle()
                        .fill(Color(hex: 0xE989B0))
                        .frame(width: w * 0.26, height: w * 0.26)
                        .overlay(Circle().stroke(Color(hex: 0xC45B86), lineWidth: max(1, w * 0.02)))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.85), lineWidth: max(1, w * 0.02))
                                .padding(w * 0.045)
                        )
                        .position(x: w * 0.5, y: h * 0.34)
                }
            }
            .frame(width: w, height: h)
        }
        .frame(width: span, height: span * 1.28)
        .accessibilityHidden(true)
    }
}
