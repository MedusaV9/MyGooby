import SwiftUI

struct ActivityHelplineRow: View {
    var engine: GoobyEngine

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: 0xC43B66))
                .frame(width: 42, height: 42)
                .background(Color(hex: 0xFDE7EF), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(engine.t("activity.aid.helpline.title"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x243041))
                Text(engine.t("activity.aid.helpline.body"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: 0x5C6570))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct AidDestination: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var flow: ActivityAidFlow

    var body: some View {
        switch flow {
        case .feeling:
            AidFeelingFlow(engine: engine, reduceMotion: reduceMotion)
        case .three:
            AidThreeFlow(engine: engine, reduceMotion: reduceMotion)
        case .anger:
            AidWriteFlow(engine: engine, reduceMotion: reduceMotion, kind: .anger)
        case .rainbow:
            AidRainbowFlow(engine: engine, reduceMotion: reduceMotion)
        case .breath:
            BreathingView(engine: engine, reduceMotion: reduceMotion, exercise: "ease")
        case .grief:
            AidWriteFlow(engine: engine, reduceMotion: reduceMotion, kind: .grief)
        case .senses:
            AidSenseFlow(engine: engine, reduceMotion: reduceMotion)
        case .body:
            AidBodyFlow(engine: engine, reduceMotion: reduceMotion)
        }
    }
}

struct AidAffirmationFlow: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var index = 0
    @State private var said = 0
    @State private var saved = false
    private let lines = [
        "activity.aid.affirm.line.0",
        "activity.aid.affirm.line.1",
        "activity.aid.affirm.line.2"
    ]

    var body: some View {
        AidPage(engine: engine, reduceMotion: reduceMotion, title: engine.t("activity.aid.affirm.title")) {
            Text(engine.t("activity.aid.affirm.lead"))
                .foregroundStyle(Theme.ink.opacity(0.75))
            Text(engine.t(lines[index]))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.peach.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(engine.tf("activity.aid.affirm.count", said))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .accessibilityLabel(engine.tf("activity.aid.affirm.count", said))
            if said < 3 {
                Button(engine.t("activity.aid.affirm.said")) {
                    engine.haptics.soft()
                    said += 1
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            } else if index < lines.count - 1 {
                Text(engine.t("activity.aid.affirm.enough"))
                    .foregroundStyle(Theme.ink)
                Button(engine.t("activity.aid.affirm.next")) {
                    engine.haptics.soft()
                    index += 1
                    said = 0
                    saved = false
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            } else {
                Text(engine.t("activity.aid.affirm.done"))
                    .foregroundStyle(Theme.ink)
            }
            Button(engine.t("activity.aid.affirm.write")) { store() }
                .buttonStyle(GoobyButtonStyle(fill: Theme.mint, ink: Theme.ink))
                .disabled(saved)
                .opacity(saved ? 0.45 : 1)
            if saved {
                Text(engine.t("activity.aid.affirm.saved"))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    private func store() {
        guard !saved else { return }
        AidJournal.keep(
            engine: engine,
            title: engine.t("activity.aid.affirm.title"),
            body: engine.t(lines[index]),
            tags: ["worth"],
            promptID: "aid-affirm-\(index)"
        )
        saved = true
        engine.haptics.soft()
    }
}

private struct AidFeelingFlow: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var feeling: Set<String> = []
    @State private var word = ""
    @State private var saved = false
    private let tags = ["happy", "sad", "tired", "stressed", "grateful", "motivated", "overwhelmed", "calm"]

    var body: some View {
        AidPage(engine: engine, reduceMotion: reduceMotion, title: engine.t("activity.aid.emotion.title")) {
            Text(engine.t("activity.aid.emotion.lead"))
                .foregroundStyle(Theme.ink.opacity(0.75))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    chip(tag)
                }
            }
            TextField(engine.t("activity.aid.emotion.word"), text: $word)
                .textFieldStyle(.roundedBorder)
                .disabled(saved)
            Button(engine.t("activity.aid.emotion.save")) { store() }
                .buttonStyle(GoobyButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.45)
            if saved {
                Text(engine.t("activity.aid.emotion.saved"))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    private func chip(_ tag: String) -> some View {
        let on = feeling.contains(tag)
        return Button {
            engine.haptics.soft()
            if on { feeling.remove(tag) } else { feeling.insert(tag) }
        } label: {
            Text(engine.t("mood.tag.\(tag)"))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(on ? Theme.lavender : Theme.whiteCard, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(saved)
        .accessibilityAddTraits(on ? .isSelected : AccessibilityTraits())
    }

    private var canSave: Bool {
        !saved && (!feeling.isEmpty || !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func store() {
        let note = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSave else { return }
        // 3 is the unrated middle of the mood log, the same value the grounding page stores.
        engine.addMood(level: 3, tags: feeling.sorted(), note: note)
        saved = true
        engine.haptics.soft()
    }
}

private struct AidThreeFlow: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var step = 0
    @State private var notes = ["", "", ""]
    @State private var saved = false
    private let prompts = [
        "activity.aid.three.see",
        "activity.aid.three.hear",
        "activity.aid.three.touch"
    ]

    var body: some View {
        AidPage(engine: engine, reduceMotion: reduceMotion, title: engine.t("activity.aid.three.title")) {
            Text(engine.t("activity.aid.three.lead"))
                .foregroundStyle(Theme.ink.opacity(0.75))
            if step < prompts.count {
                AidStepCaption(engine: engine, index: step, total: prompts.count)
                Text(engine.t(prompts[step]))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(engine.t("activity.aid.three.help"))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                TextField(engine.t("activity.aid.three.placeholder"), text: noteBinding, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                Button(engine.t("common.continue")) { advance() }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            } else {
                Text(engine.t("activity.aid.three.done"))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                if !written.isEmpty && !saved {
                    Button(engine.t("activity.aid.three.keep")) { store() }
                        .buttonStyle(GoobyButtonStyle(fill: Theme.mint, ink: Theme.ink))
                }
                if saved {
                    Text(engine.t("ground.saved"))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { notes[min(step, notes.count - 1)] },
            set: { notes[min(step, notes.count - 1)] = $0 }
        )
    }

    private var written: String {
        zip(prompts, notes).compactMap { key, note -> String? in
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return "\(engine.t(key))\n\(trimmed)"
        }
        .joined(separator: "\n\n")
    }

    private func advance() {
        engine.haptics.soft()
        step += 1
    }

    private func store() {
        guard !saved, !written.isEmpty else { return }
        AidJournal.keep(
            engine: engine,
            title: engine.t("activity.aid.three.title"),
            body: written,
            tags: ["grounding"],
            promptID: "aid-three"
        )
        saved = true
        engine.haptics.soft()
    }
}

private struct AidSenseFlow: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var step = 0
    private let counts = [5, 4, 3, 2, 1]

    var body: some View {
        AidPage(engine: engine, reduceMotion: reduceMotion, title: engine.t("activity.aid.senses.title")) {
            Text(engine.t("activity.aid.senses.lead"))
                .foregroundStyle(Theme.ink.opacity(0.75))
            if step < counts.count {
                AidStepCaption(engine: engine, index: step, total: counts.count)
                Text(engine.tf("ground.step", counts[step], engine.t("ground.sense.\(step)")))
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(engine.t("ground.sense.help.\(step)"))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                Button(engine.t("ground.next")) {
                    engine.haptics.soft()
                    step += 1
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            } else {
                Text(engine.t("activity.aid.senses.done"))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
            }
        }
    }
}

private struct AidRainbowFlow: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var step = 0
    private let stops: [(key: String, hex: UInt32)] = [
        ("activity.aid.rainbow.red", 0xE4534A),
        ("activity.aid.rainbow.orange", 0xF08A3C),
        ("activity.aid.rainbow.yellow", 0xE2B423),
        ("activity.aid.rainbow.green", 0x3EAE45),
        ("activity.aid.rainbow.blue", 0x5AA7E8),
        ("activity.aid.rainbow.purple", 0x7A6AD4)
    ]

    var body: some View {
        AidPage(engine: engine, reduceMotion: reduceMotion, title: engine.t("activity.aid.colors.title")) {
            Text(engine.t("activity.aid.rainbow.lead"))
                .foregroundStyle(Theme.ink.opacity(0.75))
            if step < stops.count {
                let stop = stops[step]
                AidStepCaption(engine: engine, index: step, total: stops.count)
                Circle()
                    .fill(Color(hex: stop.hex))
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)
                Text(engine.t(stop.key))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Button(engine.t("activity.aid.rainbow.found")) {
                    engine.haptics.soft()
                    step += 1
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            } else {
                Text(engine.t("activity.aid.rainbow.done"))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
            }
        }
    }
}

private struct AidBodyFlow: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var step = 0
    private let parts = [
        "activity.aid.body.feet",
        "activity.aid.body.legs",
        "activity.aid.body.belly",
        "activity.aid.body.hands",
        "activity.aid.body.shoulders",
        "activity.aid.body.face"
    ]

    var body: some View {
        AidPage(engine: engine, reduceMotion: reduceMotion, title: engine.t("activity.aid.body.title")) {
            Text(engine.t("activity.aid.body.lead"))
                .foregroundStyle(Theme.ink.opacity(0.75))
            if step < parts.count {
                AidStepCaption(engine: engine, index: step, total: parts.count)
                Text(engine.t(parts[step]))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Button(engine.t("common.continue")) {
                    engine.haptics.soft()
                    step += 1
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            } else {
                Text(engine.t("activity.aid.body.done"))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
            }
        }
    }
}

// Anger and grief only keep the words. They do not suggest a next action.
private enum AidWriteKind {
    case anger
    case grief

    var titleKey: String {
        switch self {
        case .anger: return "activity.aid.anger.title"
        case .grief: return "activity.aid.grief.title"
        }
    }

    var leadKey: String {
        switch self {
        case .anger: return "activity.aid.anger.lead"
        case .grief: return "activity.aid.grief.lead"
        }
    }

    var placeholderKey: String {
        switch self {
        case .anger: return "activity.aid.anger.placeholder"
        case .grief: return "activity.aid.grief.placeholder"
        }
    }

    var saveKey: String {
        switch self {
        case .anger: return "activity.aid.anger.save"
        case .grief: return "activity.aid.grief.save"
        }
    }

    var savedKey: String {
        switch self {
        case .anger: return "activity.aid.anger.saved"
        case .grief: return "activity.aid.grief.saved"
        }
    }

    var promptID: String {
        switch self {
        case .anger: return "aid-anger"
        case .grief: return "aid-grief"
        }
    }

    var paper: Color {
        switch self {
        case .anger: return Theme.peach.opacity(0.55)
        case .grief: return Theme.lavender.opacity(0.4)
        }
    }
}

private struct AidWriteFlow: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var kind: AidWriteKind
    @State private var text = ""
    @State private var saved = false

    var body: some View {
        AidPage(engine: engine, reduceMotion: reduceMotion, title: engine.t(kind.titleKey)) {
            Text(engine.t(kind.leadKey))
                .foregroundStyle(Theme.ink.opacity(0.75))
            Text(engine.t("activity.aid.helpline.body"))
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(engine.t(kind.placeholderKey))
                        .foregroundStyle(Theme.ink.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .frame(minHeight: 180)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .disabled(saved)
            }
            .background(kind.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Button(engine.t(kind.saveKey)) { store() }
                .buttonStyle(GoobyButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.45)
            if saved {
                Text(engine.t(kind.savedKey))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    private var canSave: Bool {
        !saved && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func store() {
        guard canSave else { return }
        AidJournal.keep(
            engine: engine,
            title: engine.t(kind.titleKey),
            body: text,
            tags: ["feel"],
            promptID: kind.promptID
        )
        saved = true
        engine.haptics.soft()
    }
}

private struct AidPage<Content: View>: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                content()
                Text(engine.t("calm.disclaimer"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .goobyScreen()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .transaction { transaction in
            if reduceMotion { transaction.disablesAnimations = true }
        }
    }
}

private struct AidStepCaption: View {
    var engine: GoobyEngine
    var index: Int
    var total: Int

    var body: some View {
        Text(engine.tf("activity.aid.step", index + 1, total))
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(Theme.ink.opacity(0.55))
    }
}

private enum AidJournal {
    static func keep(engine: GoobyEngine, title: String, body: String, tags: [String], promptID: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        engine.addJournal(title: title, body: trimmed, tags: tags, promptID: promptID)
    }
}
