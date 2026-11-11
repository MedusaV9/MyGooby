import SwiftUI

struct CalmScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(engine.t("calm.intro")).foregroundStyle(Theme.ink.opacity(0.75))
                NavigationLink { GroundingView(engine: engine) } label: {
                    SoftCard(fill: Theme.lavender.opacity(0.7)) {
                        Text(engine.t("ground.title")).font(.system(.title3, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
                        Text(engine.t("ground.subtitle")).foregroundStyle(Theme.ink.opacity(0.75))
                    }
                }
                .buttonStyle(.plain)
                NavigationLink { BreathingView(engine: engine, reduceMotion: reduceMotion) } label: {
                    linkCard("breath.title", "breath.subtitle", Theme.sky)
                }
                .buttonStyle(.plain)
                NavigationLink { FocusTimerView(engine: engine) } label: {
                    linkCard("focus.title", "focus.subtitle", Theme.yellow)
                }
                .buttonStyle(.plain)
                NavigationLink { SoundscapeView(engine: engine) } label: {
                    linkCard("sound.title", "sound.subtitle", Theme.mint)
                }
                .buttonStyle(.plain)
                NavigationLink { MovementList(engine: engine) } label: {
                    linkCard("move.title", "move.subtitle", Theme.peach)
                }
                .buttonStyle(.plain)
                Text(engine.t("calm.disclaimer"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("tab.calm"))
    }

    private func linkCard(_ title: String, _ subtitle: String, _ fill: Color) -> some View {
        SoftCard(fill: fill.opacity(0.75)) {
            Text(engine.t(title)).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
            Text(engine.t(subtitle)).foregroundStyle(Theme.ink.opacity(0.75))
        }
    }
}

struct BreathingView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var pattern = "calm"
    @State private var running = false
    @State private var inhale = 4
    @State private var hold = 4
    @State private var exhale = 4
    @State private var hold2 = 0
    @State private var cycles = 0
    @State private var started: Date?
    private let patterns = ["calm", "box", "sleep", "stress", "custom"]

    var body: some View {
        VStack(spacing: 16) {
            Picker(engine.t("breath.pattern"), selection: $pattern) {
                ForEach(patterns, id: \.self) { Text(engine.t("breath.\($0)")).tag($0) }
            }
            .onChange(of: pattern) { _, value in apply(value) }
            TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30.0, paused: !running)) { timeline in
                let phase = breathPhase(at: timeline.date)
                VStack {
                    Circle()
                        .fill(Theme.pink)
                        .frame(width: 160 * phase.scale, height: 160 * phase.scale)
                        .overlay(Text(engine.t(phase.label)).foregroundStyle(Theme.ink))
                    Text(engine.tf("breath.cycles", cycles)).foregroundStyle(Theme.ink.opacity(0.7))
                }
                .frame(height: 240)
                .onChange(of: timeline.date) { _, date in
                    if running { noteCycle(at: date) }
                }
                .onChange(of: phase.label) { _, label in
                    guard running, label != "breath.hold.label" else { return }
                    let rising = label == "breath.in.label"
                    GoobyFeedback.shared.breathe(rising: rising, seconds: Double(rising ? inhale : exhale))
                }
            }
            if pattern == "custom" {
                Stepper(engine.tf("breath.in", inhale), value: $inhale, in: 2...12)
                Stepper(engine.tf("breath.hold", hold), value: $hold, in: 0...12)
                Stepper(engine.tf("breath.out", exhale), value: $exhale, in: 2...12)
                Stepper(engine.tf("breath.hold2", hold2), value: $hold2, in: 0...12)
            }
            Button(running ? engine.t("common.stop") : engine.t("common.start")) {
                if running {
                    if cycles > 0 { engine.finishBreath() }
                    running = false
                    FeatureHost.shared.shellEvent?(engine, .breathStopped)
                } else {
                    cycles = 0
                    started = Date()
                    running = true
                    FeatureHost.shared.shellEvent?(engine, .breathStarted(pattern: pattern, seconds: [inhale, hold, exhale, hold2]))
                }
            }
            .buttonStyle(GoobyButtonStyle(fill: Theme.sky, ink: Theme.ink))
            Text(engine.t("calm.disclaimer")).font(.system(.footnote, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.65))
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .goobyScreen()
        .navigationTitle(engine.t("breath.title"))
        .onAppear { apply(pattern) }
        .onDisappear {
            if running { FeatureHost.shared.shellEvent?(engine, .breathStopped) }
        }
    }

    private func apply(_ name: String) {
        switch name {
        case "box": inhale = 4; hold = 4; exhale = 4; hold2 = 4
        case "sleep": inhale = 4; hold = 7; exhale = 8; hold2 = 0
        case "stress": inhale = 4; hold = 0; exhale = 6; hold2 = 0
        case "custom": break
        default: inhale = 4; hold = 0; exhale = 4; hold2 = 0
        }
    }

    private func total() -> Double { Double(inhale + hold + exhale + hold2) }

    private func breathPhase(at date: Date) -> (scale: CGFloat, label: String) {
        let span = max(1, total())
        let t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: span)
        let i = Double(inhale), h = Double(hold), e = Double(exhale)
        if t < i {
            let p = i == 0 ? 1 : t / i
            return (CGFloat(0.65 + 0.5 * p), "breath.in.label")
        } else if t < i + h {
            return (1.15, "breath.hold.label")
        } else if t < i + h + e {
            let p = e == 0 ? 1 : (t - i - h) / e
            return (CGFloat(1.15 - 0.5 * p), "breath.out.label")
        }
        return (0.65, "breath.hold.label")
    }

    private func noteCycle(at date: Date) {
        guard let started else { return }
        let span = max(1, total())
        cycles = Int(date.timeIntervalSince(started) / span)
    }
}

struct FocusTimerView: View {
    var engine: GoobyEngine
    @State private var minutes = 10

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            focusBody
        }
        .navigationTitle(engine.t("focus.title"))
    }

    private var focusBody: some View {
        VStack(spacing: 16) {
            Text(timeLabel)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            if engine.currentFocus() == nil {
                Stepper(engine.tf("focus.minutes", minutes), value: $minutes, in: 1...90)
                Button(engine.t("common.start")) { engine.focusStart(seconds: minutes * 60) }
                    .buttonStyle(GoobyButtonStyle())
            } else {
                HStack {
                    Button(engine.currentFocus()?.runningSince == nil ? engine.t("common.resume") : engine.t("common.pause")) {
                        if engine.currentFocus()?.runningSince == nil { engine.focusResume() } else { engine.focusPause() }
                    }
                    Button(engine.t("common.stop")) { engine.focusStop() }
                }
                .buttonStyle(.bordered)
            }
            Text(engine.t("focus.rewardHint")).foregroundStyle(Theme.ink.opacity(0.7))
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .goobyScreen()
        .navigationTitle(engine.t("focus.title"))
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                engine.reconcileFocus()
            }
        }
    }

    private var timeLabel: String {
        let seconds = engine.currentFocus() == nil ? minutes * 60 : engine.focusRemaining()
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct SoundscapeView: View {
    var engine: GoobyEngine

    var body: some View {
        VStack(spacing: 12) {
            Text(engine.t("sound.local")).foregroundStyle(Theme.ink.opacity(0.7))
            ForEach(SoundscapePlayer.names, id: \.self) { name in
                Button {
                    engine.sound.toggle(name)
                } label: {
                    HStack {
                        Text(engine.t("sound.\(name)"))
                        Spacer()
                        Image(systemName: engine.sound.active == name ? "speaker.wave.2.fill" : "speaker")
                    }
                    .foregroundStyle(Theme.ink)
                    .padding()
                    .background(engine.sound.active == name ? Theme.mint : Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            if engine.sound.active != nil {
                Button(engine.t("common.stop")) { engine.sound.stop() }.buttonStyle(GoobyButtonStyle(fill: Theme.peach, ink: Theme.ink))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .goobyScreen()
        .navigationTitle(engine.t("sound.title"))
    }
}

struct MovementList: View {
    var engine: GoobyEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(engine.catalog.exercises) { exercise in
                    NavigationLink {
                        MovementPlayer(engine: engine, exercise: exercise)
                    } label: {
                        SoftCard(fill: Theme.peach.opacity(0.7)) {
                            Text(exercise.title.text(engine.languageCode)).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                            Text(engine.tf("move.minutes", exercise.minutes)).foregroundStyle(Theme.ink.opacity(0.7))
                        }
                    }
                    .buttonStyle(.plain)
                }
                Text(engine.t("calm.disclaimer")).font(.system(.footnote, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.65))
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("move.title"))
    }
}

struct MovementPlayer: View {
    var engine: GoobyEngine
    var exercise: ExerciseDef
    @State private var index = 0
    @State private var done = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(exercise.title.text(engine.languageCode)).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
            if exercise.steps.indices.contains(index) {
                Text(exercise.steps[index].text(engine.languageCode))
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }
            ProgressRibbon(value: Double(index) / Double(max(1, exercise.steps.count)))
            if done {
                Text(engine.t("move.done")).foregroundStyle(Theme.ink)
            } else {
                Button(index + 1 >= exercise.steps.count ? engine.t("move.finish") : engine.t("common.continue")) {
                    if index + 1 >= exercise.steps.count {
                        engine.finishMovement(exercise.id)
                        done = true
                    } else {
                        index += 1
                    }
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.peach, ink: Theme.ink))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .goobyScreen()
    }
}

struct GroundingView: View {
    var engine: GoobyEngine
    @State private var step = 0
    @State private var feeling: Set<String> = []
    @State private var thought = ""
    @State private var saved = false
    private let counts = [5, 4, 3, 2, 1]
    private let tags = ["happy", "sad", "tired", "stressed", "grateful", "motivated", "overwhelmed", "calm"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(engine.t("ground.lead")).foregroundStyle(Theme.ink.opacity(0.75))
                if step < counts.count {
                    Text(engine.tf("ground.step", counts[step], engine.t("ground.sense.\(step)")))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.ink)
                    Text(engine.t("ground.sense.help.\(step)")).foregroundStyle(Theme.ink.opacity(0.75))
                    Button(engine.t("ground.next")) { step += 1 }.buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
                } else if step == counts.count {
                    Text(engine.t("ground.feelings")).font(.system(.title3, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            if feeling.contains(tag) { feeling.remove(tag) } else { feeling.insert(tag) }
                        } label: {
                            HStack {
                                Text(engine.t("mood.tag.\(tag)")).foregroundStyle(Theme.ink)
                                Spacer()
                                Image(systemName: feeling.contains(tag) ? "checkmark.circle.fill" : "circle")
                            }
                            .padding(8)
                        }
                        .buttonStyle(.plain)
                    }
                    Button(engine.t("ground.saveFeeling")) {
                        engine.addMood(level: 3, tags: Array(feeling), note: "")
                        step += 1
                    }
                    .buttonStyle(GoobyButtonStyle())
                } else {
                    Text(engine.t("ground.write")).font(.system(.title3, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
                    TextField(engine.t("ground.placeholder"), text: $thought, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    Button(engine.t("ground.saveThought")) {
                        _ = engine.addJournal(title: engine.t("ground.journalTitle"), body: thought, tags: ["grounding"], promptID: "grounding")
                        saved = true
                    }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.mint, ink: Theme.ink))
                    .disabled(thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if saved { Text(engine.t("ground.saved")).foregroundStyle(Theme.ink) }
                    ForEach(0..<3, id: \.self) { index in
                        Text(engine.t("ground.card.\(index)"))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.peach.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                Text(engine.t("calm.disclaimer")).font(.system(.footnote, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.65))
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("ground.title"))
    }
}
