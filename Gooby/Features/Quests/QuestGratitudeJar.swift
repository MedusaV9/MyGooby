import SwiftUI

enum QuestJarNote {
    static let promptID = "quest-gratitude-jar"
}

enum QuestJarDraft: String, Identifiable {
    case add
    case send
    var id: String { rawValue }
}

struct QuestGratitudeJar: View {
    var engine: GoobyEngine
    var calm: Bool
    var revision: Int
    var wrote: () -> Void

    @State private var draft: QuestJarDraft?
    @State private var notice = ""

    var body: some View {
        let _ = revision
        let status = QuestSeasonText.jarLabel(engine, engine.gratitudeSeason())
        let count = engine.all(JournalEntry.self).filter { $0.promptID == QuestJarNote.promptID }.count
        let name = QuestCopy.petName(engine)
        VStack(alignment: .leading, spacing: 8) {
            QuestSectionHead(title: engine.t("quests.section.season")) {
                Text(status.label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuestColor.section)
                    .multilineTextAlignment(.trailing)
            }
            HStack(alignment: .center, spacing: 12) {
                QuestJarGlass(notes: count, calm: calm)
                    .frame(width: 78, height: 96)
                    .accessibilityLabel(engine.tf("quests.jar.a11y", count))
                VStack(alignment: .leading, spacing: 8) {
                    Text(engine.t("quests.jar.title"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(QuestColor.ink)
                    Text(engine.tf("quests.jar.detail", name))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(QuestColor.sub)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        jarButton(engine.t("quests.jar.add"), fill: QuestColor.pink, ink: .white) {
                            draft = .add
                        }
                        jarButton(engine.t("quests.jar.send"), fill: Color(hex: 0xEEF1F4), ink: Color(hex: 0x5C6770)) {
                            draft = .send
                        }
                    }
                    .disabled(!status.open)
                    .opacity(status.open ? 1 : 0.42)
                    if !notice.isEmpty {
                        Text(notice)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(QuestColor.ink.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    } else if !status.open {
                        Text(engine.t("quests.jar.closed"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(QuestColor.sub)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: QuestColor.cardShadow.opacity(0.08), radius: 0.5, y: 1)
            .shadow(color: QuestColor.cardShadow.opacity(0.12), radius: 6, y: 3)
            .accessibilityHint(status.open ? "" : engine.t("quests.jar.closed"))
        }
        .sheet(item: $draft) { mode in
            QuestJarSheet(engine: engine, mode: mode, calm: calm) { message in
                notice = message
                wrote()
            }
        }
    }

    private func jarButton(_ title: String, fill: Color, ink: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(fill, in: Capsule())
        }
        .buttonStyle(QuestPressStyle(calm: calm))
    }
}

struct QuestJarSheet: View {
    var engine: GoobyEngine
    var mode: QuestJarDraft
    var calm: Bool
    var saved: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        let prompt = engine.catalog.prompts.first { $0.id == QuestJarNote.promptID }
        let name = QuestCopy.petName(engine)
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(prompt?.body.text(engine.languageCode) ?? engine.t("quests.jar.prompt"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(QuestColor.ink.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
                TextEditor(text: $text)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(QuestColor.ink)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 140)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Button(mode == .send ? engine.t("quests.jar.send") : engine.t("quests.jar.add")) {
                    commit(prompt: prompt, name: name)
                }
                .buttonStyle(GoobyButtonStyle(
                    fill: mode == .send ? QuestColor.pink : QuestColor.yellow,
                    ink: mode == .send ? .white : QuestColor.ink
                ))
                .disabled(trimmed.isEmpty)
                .opacity(trimmed.isEmpty ? 0.45 : 1)
                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(QuestColor.page.ignoresSafeArea())
            .navigationTitle(engine.t("quests.jar.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(engine.t("common.close")) { dismiss() }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .transaction { transaction in
            if calm { transaction.disablesAnimations = true }
        }
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commit(prompt: PromptDef?, name: String) {
        let body = trimmed
        guard !body.isEmpty else { return }
        let title = prompt?.title.text(engine.languageCode) ?? engine.t("quests.jar.title")
        let tags = mode == .send ? ["gratitude", "sent"] : ["gratitude", "jar"]
        let entry = engine.addJournal(title: title, body: body, tags: tags, promptID: QuestJarNote.promptID)
        engine.updateJournal(entry, title: title, body: body, tags: tags)
        engine.haptics.soft()
        let message = mode == .send ? engine.tf("quests.jar.sent", name) : engine.t("quests.jar.added")
        saved(message)
        dismiss()
    }
}

struct QuestJarGlass: View {
    var notes: Int
    var calm: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: calm || notes == 0 ? 8 : 1.0 / 20.0, paused: calm || notes == 0)) { timeline in
            let time = calm ? 0.0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                QuestJarArt.paint(&context, size: size, notes: notes, time: time)
            }
        }
    }
}

enum QuestJarArt {
    static func paint(_ context: inout GraphicsContext, size: CGSize, notes: Int, time: Double) {
        let w = size.width
        let h = size.height
        let glass = CGRect(x: w * 0.16, y: h * 0.3, width: w * 0.68, height: h * 0.62)
        let neck = CGRect(x: w * 0.3, y: h * 0.2, width: w * 0.4, height: h * 0.14)
        let cork = CGRect(x: w * 0.28, y: h * 0.08, width: w * 0.44, height: h * 0.14)

        context.fill(Path(roundedRect: cork, cornerRadius: 6), with: .color(Color(hex: 0xC4894A)))
        context.fill(
            Path(roundedRect: cork.insetBy(dx: 3, dy: 3), cornerRadius: 4),
            with: .color(Color(hex: 0xE2B56A))
        )
        context.fill(Path(roundedRect: neck, cornerRadius: 3), with: .color(Color(hex: 0xD7F4FA).opacity(0.9)))

        let body = Path(roundedRect: glass, cornerRadius: 16)
        context.fill(body, with: .color(Color(hex: 0xD9F6FB).opacity(0.72)))
        context.drawLayer { layer in
            layer.clip(to: body)
            let slips = min(max(0, notes), 4)
            for index in 0..<slips {
                let base = CGFloat(-8 + index * 6)
                let wobble: CGFloat = time == 0 || index > 0 ? 0 : CGFloat(sin(time * 1.3) * 4)
                let width = glass.width * 0.62
                let height = glass.height * 0.16
                let origin = CGPoint(
                    x: glass.midX - width / 2 + CGFloat(index % 2 == 0 ? -3 : 3),
                    y: glass.maxY - height - CGFloat(8) - CGFloat(index) * (height * 0.72)
                )
                var note = Path(roundedRect: CGRect(origin: origin, size: CGSize(width: width, height: height)), cornerRadius: 2)
                let center = CGPoint(x: origin.x + width / 2, y: origin.y + height / 2)
                let turn = CGAffineTransform(translationX: center.x, y: center.y)
                    .rotated(by: (base + wobble) * .pi / 180)
                    .translatedBy(x: -center.x, y: -center.y)
                note = note.applying(turn)
                layer.fill(note, with: .color(index % 2 == 0 ? Color(hex: 0xFFF6D8) : Color(hex: 0xFFE0EA)))
            }
        }
        context.stroke(body, with: .color(Color(hex: 0x9ED7E4)), lineWidth: 2)
        var shine = Path()
        shine.move(to: CGPoint(x: glass.minX + 8, y: glass.minY + 16))
        shine.addQuadCurve(
            to: CGPoint(x: glass.minX + 12, y: glass.maxY - 16),
            control: CGPoint(x: glass.minX + 2, y: glass.midY)
        )
        context.stroke(shine, with: .color(Color.white.opacity(0.85)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}
