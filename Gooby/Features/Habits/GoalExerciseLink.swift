import SwiftUI

struct GoalExercise: Identifiable, Hashable {
    var id: String
    var title: String
    var detail: String
    var glyph: String
    var minutes: Int
    var energy: Int
    var showsPlus: Bool
}

enum GoalExerciseKind {
    case breathe
    case focus
    case sound(String)
    case move(String)
    case ground
    case journal(String)

    static func parse(_ id: String) -> GoalExerciseKind? {
        let parts = id.split(separator: ":", maxSplits: 1).map(String.init)
        guard let head = parts.first else { return nil }
        let tail = parts.count > 1 ? parts[1] : ""
        switch head {
        case "breathe": return .breathe
        case "focus": return .focus
        case "ground": return .ground
        case "sound": return tail.isEmpty ? nil : .sound(tail)
        case "move": return tail.isEmpty ? nil : .move(tail)
        case "journal": return tail.isEmpty ? nil : .journal(tail)
        default: return nil
        }
    }
}

enum GoalExerciseCatalog {
    static func starterLink(for suggestionID: String) -> String? {
        switch suggestionID {
        case "stretch-break": return "move:stretch"
        case "three-breaths": return "breathe:calm"
        default: return nil
        }
    }

    static func suggestedLink(for suggestionID: String) -> String? {
        if let starter = starterLink(for: suggestionID) { return starter }
        switch suggestionID {
        case "morning-yoga", "yoga", "stand-10": return "move:stretch"
        case "breathe-bed", "quiet-minute": return "breathe:calm"
        case "calm-sound": return "sound:rain"
        case "one-grateful", "three-good", "gratitude-bed", "positive-today", "savor": return "journal:gratitude-1"
        case "name-feeling", "notice-five": return "ground"
        case "focus-25", "start-hard": return "focus"
        default: return nil
        }
    }

    static func energy(for id: String) -> Int {
        switch id {
        case "breathe:calm": return 10
        case "focus": return 10
        case "ground": return 5
        default:
            if id.hasPrefix("sound:") { return 5 }
            if id.hasPrefix("move:") { return 6 }
            return 5
        }
    }

    static func showsPlus(_ id: String) -> Bool {
        id != "ground"
    }

    static func list(engine: GoobyEngine) -> [GoalExercise] {
        var rows: [GoalExercise] = [
            GoalExercise(
                id: "breathe:calm",
                title: engine.t("breath.calm"),
                detail: engine.t("care.ex.breathe.detail"),
                glyph: "leaf",
                minutes: 1,
                energy: 10,
                showsPlus: true
            ),
            GoalExercise(
                id: "focus",
                title: engine.t("focus.title"),
                detail: engine.t("care.ex.focus.detail"),
                glyph: "target",
                minutes: 10,
                energy: 10,
                showsPlus: true
            ),
            GoalExercise(
                id: "ground",
                title: engine.t("ground.title"),
                detail: engine.t("care.ex.ground.detail"),
                glyph: "heart",
                minutes: 3,
                energy: 5,
                showsPlus: false
            )
        ]
        for name in SoundscapePlayer.names {
            rows.append(GoalExercise(
                id: "sound:\(name)",
                title: engine.t("sound.\(name)"),
                detail: engine.t("care.ex.sound.detail"),
                glyph: name == "rain" || name == "ocean" ? "drop" : "leaf",
                minutes: 5,
                energy: 5,
                showsPlus: true
            ))
        }
        for exercise in engine.catalog.exercises {
            rows.append(GoalExercise(
                id: "move:\(exercise.id)",
                title: exercise.title.text(engine.languageCode),
                detail: engine.tf("care.exercise.minutes", exercise.minutes),
                glyph: "giraffe",
                minutes: exercise.minutes,
                energy: 6,
                showsPlus: true
            ))
        }
        for prompt in engine.catalog.prompts {
            rows.append(GoalExercise(
                id: "journal:\(prompt.id)",
                title: prompt.title.text(engine.languageCode),
                detail: prompt.body.text(engine.languageCode),
                glyph: glyph(forTheme: prompt.theme),
                minutes: 5,
                energy: 5,
                showsPlus: true
            ))
        }
        return rows
    }

    static func visible(engine: GoobyEngine, store: GoalMetaStore, query: String) -> [GoalExercise] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = list(engine: engine).filter { row in
            needle.isEmpty || row.title.localizedCaseInsensitiveContains(needle) || row.detail.localizedCaseInsensitiveContains(needle)
        }
        let stars = Set(store.meta.starredExercises)
        return source.sorted { lhs, rhs in
            let left = stars.contains(lhs.id)
            let right = stars.contains(rhs.id)
            if left != right { return left && !right }
            return false
        }
    }

    static func find(_ id: String, engine: GoobyEngine) -> GoalExercise? {
        list(engine: engine).first { $0.id == id }
    }

    static func title(for id: String, engine: GoobyEngine) -> String {
        find(id, engine: engine)?.title ?? engine.t("care.exercise.missing")
    }

    private static func glyph(forTheme theme: String) -> String {
        switch theme {
        case "gratitude": return "star"
        case "worth": return "smile"
        case "stress": return "leaf"
        case "day": return "sun"
        case "motive": return "bolt"
        case "feel": return "heart"
        default: return "note"
        }
    }
}

struct GoalEnergyText: View {
    var value: Int
    var linked: Bool
    var engine: GoobyEngine

    var body: some View {
        HStack(spacing: 3) {
            Text(linked ? "\(value)+" : "\(value)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(GoalLook.energy)
            EnergyBolt()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(engine.tf(linked ? "care.energy.plus" : "care.energy", value))
    }
}

struct GoalRowFinish: View {
    var engine: GoobyEngine
    var habit: Habit
    var linked: Bool
    var done: Bool
    var onToggle: () -> Void
    @State private var showExercise = false

    var body: some View {
        let exerciseID = GoalMetaStore.peek().exercises[habit.id.uuidString] ?? ""
        Button {
            if linked && !done {
                showExercise = true
            } else {
                onToggle()
            }
        } label: {
            Group {
                if linked && !done {
                    GoalArrowKey()
                } else {
                    CheckKey(done: done)
                }
            }
            .frame(width: 42, height: 42)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(linked && !done ? engine.t("care.exercise.open") : (done ? engine.t("care.done") : engine.t("care.notDone")))
        .sheet(isPresented: $showExercise) {
            GoalExerciseHost(engine: engine, exerciseID: exerciseID) {
                onToggle()
            }
        }
    }
}

struct GoalToastBanner: View {
    var text: String

    var body: some View {
        HStack(spacing: 10) {
            GoalSticker(glyph: "face")
                .frame(width: 36, height: 36)
            Text(text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0x2C2C2E), in: Capsule())
        .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        .accessibilityAddTraits(.isStaticText)
    }
}

struct GoalExerciseSearch: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var tick = 0

    var body: some View {
        let _ = tick
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    SearchMark()
                        .stroke(GoalLook.subtitle, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        .frame(width: 15, height: 15)
                    TextField(engine.t("care.exercise.search"), text: $query)
                        .font(GoalFont.body)
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(hex: 0xF3F4F6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                List {
                    let rows = GoalExerciseCatalog.visible(engine: engine, store: store, query: query)
                    if rows.isEmpty {
                        Text(engine.t("care.exercise.empty"))
                            .font(GoalFont.body)
                            .foregroundStyle(GoalLook.subtitle)
                            .listRowBackground(Color.clear)
                    }
                    ForEach(rows) { exercise in
                        exerciseRow(exercise)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color.white)
            .navigationTitle(engine.t("care.quick.link"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(engine.t("common.close")) { dismiss() }
                }
            }
        }
    }

    private func exerciseRow(_ exercise: GoalExercise) -> some View {
        let starred = store.meta.starredExercises.contains(exercise.id)
        return HStack(spacing: 12) {
            Button {
                onPick(exercise.id)
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    GoalGlyph(glyph: exercise.glyph).frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.title)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(GoalLook.ink)
                            .multilineTextAlignment(.leading)
                        Text(exercise.detail)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(GoalLook.subtitle)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 4)
                }
            }
            .buttonStyle(.plain)
            VStack(alignment: .trailing, spacing: 8) {
                Text(exercise.showsPlus ? "\(exercise.energy)+" : "\(exercise.energy)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(GoalLook.energy)
                Button {
                    GoalActions.toggleStar(exercise.id, store: store)
                    tick += 1
                } label: {
                    Image(systemName: starred ? "star.fill" : "star")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF0A020))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t(starred ? "care.exercise.starred" : "care.exercise.star"))
            }
        }
        .listRowBackground(Color.white)
    }
}

struct GoalExerciseHost: View {
    var engine: GoobyEngine
    var exerciseID: String
    var onFinish: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var finished = false
    @State private var startedSound: String?

    var body: some View {
        NavigationStack {
            stage
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(engine.t("common.close")) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(engine.t("care.exercise.finish")) { complete() }
                    }
                }
        }
        .onAppear(perform: startSound)
        .onDisappear(perform: stopSound)
    }

    @ViewBuilder private var stage: some View {
        switch GoalExerciseKind.parse(exerciseID) {
        case .breathe:
            BreathingView(engine: engine, reduceMotion: engine.reduceMotion)
        case .focus:
            FocusTimerView(engine: engine)
        case .sound:
            SoundscapeView(engine: engine)
        case .move(let id):
            if let exercise = engine.catalog.exercises.first(where: { $0.id == id }) {
                MovementPlayer(engine: engine, exercise: exercise)
            } else {
                MovementList(engine: engine)
            }
        case .ground:
            GroundingView(engine: engine)
        case .journal:
            JournalScreen(engine: engine)
        case nil:
            Text(engine.t("care.exercise.missing"))
                .font(GoalFont.body)
                .foregroundStyle(GoalLook.ink)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .goobyScreen()
        }
    }

    private func startSound() {
        guard case .sound(let name) = GoalExerciseKind.parse(exerciseID) else { return }
        if engine.sound.active != name {
            engine.sound.toggle(name)
        }
        startedSound = name
    }

    private func stopSound() {
        guard let startedSound, engine.sound.active == startedSound else { return }
        engine.sound.stop()
    }

    private func complete() {
        guard !finished else { return }
        finished = true
        onFinish()
        dismiss()
    }
}
