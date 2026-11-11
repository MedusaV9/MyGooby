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
        let status = QuestSeasonText.jarLabel(engine, Self.season(engine))
        let count = engine.all(JournalEntry.self).filter { $0.promptID == QuestJarNote.promptID }.count
        let name = QuestCopy.petName(engine)
        VStack(alignment: .leading, spacing: 6) {
            QuestSectionHead(title: engine.t("quests.section.season")) {
                Text(status.label)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(QuestColor.section)
                    .multilineTextAlignment(.trailing)
            }
            HStack(alignment: .center, spacing: 19) {
                QuestJarGlass(notes: count, calm: calm)
                    .frame(width: 72, height: 92)
                    .accessibilityLabel(engine.tf("quests.jar.a11y", count))
                VStack(alignment: .leading, spacing: 0) {
                    Text(engine.t("quests.jar.title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(QuestColor.ink)
                    let detail = Text(engine.tf("quests.jar.detail", name))
                    ViewThatFits(in: .horizontal) {
                        detail.lineLimit(1)
                        detail.fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(QuestColor.sub)
                    .padding(.top, 4.5)
                    HStack(spacing: 9) {
                        jarButton(engine.t("quests.jar.add"), face: QuestColor.pink, lip: QuestColor.pinkLip, ink: .white) {
                            draft = .add
                        }
                        jarButton(engine.t("quests.jar.send"), face: QuestColor.keyFace, lip: QuestColor.keyLip, ink: QuestColor.keyInk) {
                            draft = .send
                        }
                    }
                    .disabled(!status.open)
                    .padding(.top, 10.5)
                    if !notice.isEmpty {
                        Text(notice)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(QuestColor.ink.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 15)
            .padding(.trailing, 15)
            .padding(.vertical, 14)
            .background(QuestColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: QuestColor.cardShadow.opacity(0.08), radius: 0.5, y: 1)
            .accessibilityHint(status.open ? "" : engine.t("quests.jar.closed"))
        }
        .sheet(item: $draft) { mode in
            QuestJarSheet(engine: engine, mode: mode, calm: calm) { message in
                notice = message
                wrote()
            }
        }
    }

    static func season(_ engine: GoobyEngine) -> QuestSeasonWindow? {
        #if DEBUG
        if let pinned = QuestShotSeed.jar(engine) { return pinned }
        #endif
        return engine.gratitudeSeason()
    }

    private func jarButton(_ title: String, face: Color, lip: Color, ink: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            let key = RoundedRectangle(cornerRadius: 10, style: .continuous)
            Text(title)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 33)
                .background(face, in: key)
                .background(lip, in: key.offset(y: 3))
                .padding(.bottom, 3)
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

/// A wide corked jar with round shoulders in a 72 × 92 design box.
enum QuestJarArt {
    static func paint(_ context: inout GraphicsContext, size: CGSize, notes: Int, time: Double) {
        let scale = min(size.width / 72, size.height / 92)
        context.translateBy(x: (size.width - 72 * scale) / 2, y: (size.height - 92 * scale) / 2)
        context.scaleBy(x: scale, y: scale)
        let glass = CGRect(x: 0, y: 18, width: 72, height: 74)
        var body = Path()
        body.move(to: CGPoint(x: 13, y: 18))
        body.addLine(to: CGPoint(x: 59, y: 18))
        body.addQuadCurve(to: CGPoint(x: 72, y: 40), control: CGPoint(x: 72, y: 21))
        body.addLine(to: CGPoint(x: 72, y: 77))
        body.addQuadCurve(to: CGPoint(x: 57, y: 92), control: CGPoint(x: 72, y: 92))
        body.addLine(to: CGPoint(x: 15, y: 92))
        body.addQuadCurve(to: CGPoint(x: 0, y: 77), control: CGPoint(x: 0, y: 92))
        body.addLine(to: CGPoint(x: 0, y: 40))
        body.addQuadCurve(to: CGPoint(x: 13, y: 18), control: CGPoint(x: 0, y: 21))
        body.closeSubpath()
        let neck = CGRect(x: 10, y: 9, width: 52, height: 12)
        let cork = CGRect(x: 12, y: 0, width: 46, height: 11)

        context.fill(Path(roundedRect: neck, cornerRadius: 4), with: .color(Color(hex: 0xC9E4E8)))
        context.fill(body, with: .color(Color(hex: 0xB9DADF)))
        context.drawLayer { layer in
            layer.clip(to: body)
            layer.fill(
                Path(CGRect(x: 0, y: 18, width: 72, height: 14)),
                with: .color(Color(hex: 0xCDE6E9))
            )
            layer.fill(
                Path(ellipseIn: CGRect(x: 4, y: 80, width: 64, height: 16)),
                with: .color(Color(hex: 0xA6CFD5))
            )
            let slips = min(max(0, notes), 4)
            for index in 0..<slips {
                let base = CGFloat(-8 + index * 6)
                let wobble: CGFloat = time == 0 || index > 0 ? 0 : CGFloat(sin(time * 1.3) * 4)
                let width = glass.width * 0.6
                let height: CGFloat = 11
                let origin = CGPoint(
                    x: glass.midX - width / 2 + CGFloat(index % 2 == 0 ? -3 : 3),
                    y: glass.maxY - height - 8 - CGFloat(index) * 8
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
        context.stroke(body, with: .color(Color(hex: 0xA3CCD3)), lineWidth: 1.2)
        var shine = Path()
        shine.move(to: CGPoint(x: 7, y: 40))
        shine.addQuadCurve(to: CGPoint(x: 8, y: 74), control: CGPoint(x: 5, y: 57))
        context.stroke(shine, with: .color(Color.white.opacity(0.8)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

        context.fill(Path(roundedRect: cork, cornerRadius: 3), with: .color(Color(hex: 0x7A5420)))
        context.fill(
            Path(roundedRect: CGRect(x: cork.minX, y: cork.minY, width: cork.width, height: 5), cornerRadius: 3),
            with: .color(Color(hex: 0x8F6427))
        )
        for (x, y) in [(20.0, 4.0), (31.0, 7.0), (44.0, 3.5), (51.0, 7.5)] {
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2.2, height: 2.2)), with: .color(Color(hex: 0x5E3F17)))
        }
    }
}
