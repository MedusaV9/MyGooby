import SwiftUI

/// Activities: first aid, breathing, focus timer, soundscapes and movement on a soft lavender
/// background, in the menu card style.
struct CalmScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        MenuScroll {
            Text(engine.t("calm.intro"))
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.text.opacity(0.7))
                .padding(.horizontal, 4)
            NavigationLink { GroundingView(engine: engine) } label: {
                HStack(spacing: 14) {
                    GoobyIcon("💗", size: 48)
                        .modifier(CalmHeartbeat(active: !reduceMotion))
                        .frame(width: 64, height: 64)
                        .background(Color.white.opacity(0.25), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(engine.t("ground.title"))
                            .font(Theme.Fonts.title3)
                            .foregroundStyle(.white)
                        Text(engine.t("ground.subtitle"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer(minLength: 6)
                    CircleChevron(color: Theme.Tab.menu.banner, fill: .white)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Tab.menu.banner, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .cardShadow()
            }
            .buttonStyle(MenuTilePressStyle())
            .goobyEntrance(0)
            MenuSectionHeader(text: engine.tx("menu.calm.tools", de: "Werkzeuge", en: "Tools"))
            NavigationLink { BreathingView(engine: engine, reduceMotion: reduceMotion) } label: {
                MenuLinkCard(icon: "🌬️", color: Theme.Tab.quests.sky, title: engine.t("breath.title"), subtitle: engine.t("breath.subtitle"))
            }
            .buttonStyle(MenuTilePressStyle())
            .goobyEntrance(1)
            NavigationLink { FocusTimerView(engine: engine) } label: {
                MenuLinkCard(icon: "⏱️", color: Theme.Tab.quests.yellow, title: engine.t("focus.title"), subtitle: engine.t("focus.subtitle"))
            }
            .buttonStyle(MenuTilePressStyle())
            .goobyEntrance(2)
            NavigationLink { SoundscapeView(engine: engine) } label: {
                MenuLinkCard(icon: "🌧️", color: Theme.Tab.quests.green, title: engine.t("sound.title"), subtitle: engine.t("sound.subtitle"))
            }
            .buttonStyle(MenuTilePressStyle())
            .goobyEntrance(3)
            NavigationLink { MovementList(engine: engine) } label: {
                MenuLinkCard(icon: "🤸", color: Theme.Tab.quests.orange, title: engine.t("move.title"), subtitle: engine.t("move.subtitle"))
            }
            .buttonStyle(MenuTilePressStyle())
            .goobyEntrance(4)
            MenuFootnote(text: engine.t("calm.disclaimer"))
                .padding(.top, 6)
        }
        .menuChrome(engine, title: engine.tx("menu.activities", de: "Aktivitäten", en: "Activities"), background: Theme.Tab.menu.calm)
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
    /// The running session for the extras (Live Activity, sounds), see GoobyEngine.breathBegin.
    @State private var session: BreathPlan?
    private let patterns = ["calm", "box", "sleep", "stress", "custom"]

    var body: some View {
        MenuScroll {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(patterns, id: \.self) { name in
                        MenuChip(title: engine.t("breath.\(name)"), icon: nil, selected: pattern == name) {
                            pattern = name
                        }
                        .disabled(running)
                    }
                }
                .padding(.horizontal, Theme.Space.margin)
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -Theme.Space.margin)
            .accessibilityLabel(engine.t("breath.pattern"))
            .onChange(of: pattern) { _, value in apply(value) }
            GCard {
                TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30.0, paused: !running)) { timeline in
                    let phase = breathPhase(at: timeline.date)
                    VStack(spacing: 12) {
                        bubble(scale: running && !reduceMotion ? phase.scale : 0.85, label: running ? engine.t(phase.label) : nil)
                        Text(engine.tf("breath.cycles", cycles))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.greyText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 290)
                    .onChange(of: timeline.date) { _, date in
                        if running { noteCycle(at: date) }
                    }
                }
            }
            if pattern == "custom" {
                MenuListGroup {
                    stepper(engine.tf("breath.in", inhale), value: $inhale, range: 2...12)
                    MenuListDivider()
                    stepper(engine.tf("breath.hold", hold), value: $hold, range: 0...12)
                    MenuListDivider()
                    stepper(engine.tf("breath.out", exhale), value: $exhale, range: 2...12)
                    MenuListDivider()
                    stepper(engine.tf("breath.hold2", hold2), value: $hold2, range: 0...12)
                }
                .disabled(running)
            }
            Button {
                if running {
                    engine.breathEnd(sessionID: session?.sessionID ?? "", cycles: cycles, completed: true)
                    session = nil
                    running = false
                } else {
                    cycles = 0
                    started = Date()
                    running = true
                    session = engine.breathBegin(pattern: pattern, inhale: inhale, hold: hold, exhale: exhale, hold2: hold2)
                }
            } label: {
                Text(running ? engine.t("common.stop") : engine.t("common.start"))
            }
            .menuPrimaryButton(fill: running ? Color(hex: 0x8C96A3) : Theme.Tab.quests.sky)
            MenuFootnote(text: engine.t("calm.disclaimer"))
        }
        .menuChrome(engine, title: engine.t("breath.title"), background: Theme.Tab.menu.calm)
        .onAppear { apply(pattern) }
        .onDisappear {
            // Leaving while it runs ends the session without a reward, as before.
            guard running else { return }
            engine.breathEnd(sessionID: session?.sessionID ?? "", cycles: cycles, completed: false)
            session = nil
            running = false
        }
    }

    /// Soft layered bubble with Gooby in the middle that grows on the in-breath and shrinks on the
    /// out-breath. With reduce motion it keeps its size and the label carries the rhythm.
    private func bubble(scale: CGFloat, label: String?) -> some View {
        ZStack {
            Circle()
                .fill(Theme.Tab.quests.sky.opacity(0.16))
                .frame(width: 250 * scale, height: 250 * scale)
            Circle()
                .fill(Theme.Tab.quests.sky.opacity(0.28))
                .frame(width: 205 * scale, height: 205 * scale)
            Circle()
                .fill(
                    RadialGradient(colors: [Color(hex: 0xE4F4FD), Color(hex: 0xA9DCF5)], center: .topLeading, startRadius: 10, endRadius: 190)
                )
                .frame(width: 165 * scale, height: 165 * scale)
            VStack(spacing: 6) {
                GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: 64)
                if let label {
                    Text(label)
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                }
            }
        }
        .frame(width: 250, height: 250)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? engine.t("breath.title"))
    }

    private func stepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            Text(title)
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
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
            return (CGFloat(0.65 + 0.35 * p), "breath.in.label")
        } else if t < i + h {
            return (1, "breath.hold.label")
        } else if t < i + h + e {
            let p = e == 0 ? 1 : (t - i - h) / e
            return (CGFloat(1 - 0.35 * p), "breath.out.label")
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
        .menuChrome(engine, title: engine.t("focus.title"), background: Theme.Tab.menu.calm)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                engine.reconcileFocus()
            }
        }
    }

    private var focusBody: some View {
        MenuScroll {
            GCard {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(Theme.line, lineWidth: 14)
                        Circle()
                            .trim(from: 0, to: remainingFraction)
                            .stroke(Theme.Tab.quests.yellow, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(timeLabel)
                            .font(.system(size: 54, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.text)
                            .monospacedDigit()
                    }
                    .frame(width: 220, height: 220)
                    .padding(.top, 8)
                    .accessibilityElement(children: .combine)
                    if engine.currentFocus() == nil {
                        Stepper(value: $minutes, in: 1...90) {
                            Text(engine.tf("focus.minutes", minutes))
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.text)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            if engine.currentFocus() == nil {
                Button {
                    engine.focusStart(seconds: minutes * 60)
                } label: {
                    Text(engine.t("common.start"))
                }
                .menuPrimaryButton(fill: Theme.Tab.quests.yellow, ink: Theme.text)
            } else {
                HStack(spacing: 12) {
                    Button {
                        if engine.currentFocus()?.runningSince == nil { engine.focusResume() } else { engine.focusPause() }
                    } label: {
                        Text(engine.currentFocus()?.runningSince == nil ? engine.t("common.resume") : engine.t("common.pause"))
                    }
                    .menuPrimaryButton(fill: Theme.Tab.quests.yellow, ink: Theme.text)
                    Button {
                        engine.focusStop()
                    } label: {
                        Text(engine.t("common.stop"))
                    }
                    .buttonStyle(Press3DButtonStyle(radius: 18, horizontal: 18, vertical: 14, expand: true))
                    .foregroundStyle(Theme.text)
                }
            }
            MenuFootnote(text: engine.t("focus.rewardHint"))
        }
    }

    private var remainingFraction: CGFloat {
        guard let session = engine.currentFocus(), session.plannedSeconds > 0 else { return 1 }
        return CGFloat(engine.focusRemaining()) / CGFloat(session.plannedSeconds)
    }

    private var timeLabel: String {
        let seconds = engine.currentFocus() == nil ? minutes * 60 : engine.focusRemaining()
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

/// Slow heartbeat of the first-aid heart (two soft beats every 2.4 s); still with reduced motion.
struct CalmHeartbeat: ViewModifier {
    var active: Bool

    func body(content: Content) -> some View {
        if active {
            content.keyframeAnimator(initialValue: CGFloat(1), repeating: true) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(1.12, duration: 0.18, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.2)
                    SpringKeyframe(1.08, duration: 0.16, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.3)
                    LinearKeyframe(1.0, duration: 1.56)
                }
            }
        } else {
            content
        }
    }
}

/// Three white bars bouncing like a little equalizer while a soundscape plays; a still
/// speaker glyph with reduced motion.
struct CalmEqualizer: View {
    var active: Bool

    var body: some View {
        if active {
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        let phase = t * (2.2 + Double(index) * 0.7) + Double(index)
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 5, height: 5 + 9 * CGFloat((sin(phase) + 1) / 2))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .accessibilityHidden(true)
        } else {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
        }
    }
}

struct SoundscapeView: View {
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    private var reduceMotion: Bool { systemReduce || appReduce || engine.reduceMotion }

    var body: some View {
        MenuScroll {
            MenuFootnote(text: engine.t("sound.local"))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(SoundscapePlayer.names, id: \.self) { name in
                    let active = engine.sound.active == name
                    Button {
                        engine.sound.toggle(name)
                    } label: {
                        VStack(spacing: 8) {
                            GoobyIcon(icon(name), size: 44)
                            Text(engine.t("sound.\(name)"))
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(active ? .white : Theme.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            if active {
                                CalmEqualizer(active: !reduceMotion)
                                    .frame(width: 26, height: 14)
                                    .transition(.opacity)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundStyle(Theme.greyText)
                                    .frame(height: 14)
                                    .transition(.opacity)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(active ? Theme.Tab.quests.green : Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
                        .cardShadow()
                        .animation(GoobyMotion.fadeable(reduceMotion, .easeOut(duration: 0.25)), value: active)
                    }
                    .buttonStyle(MenuTilePressStyle())
                    .goobyPop(on: active, amount: 1.04)
                    .accessibilityAddTraits(active ? .isSelected : [])
                }
            }
            if engine.sound.active != nil {
                Button {
                    engine.sound.stop()
                } label: {
                    Text(engine.t("common.stop"))
                }
                .buttonStyle(Press3DButtonStyle(radius: 18, horizontal: 18, vertical: 14, expand: true))
                .foregroundStyle(Theme.text)
            }
        }
        .menuChrome(engine, title: engine.t("sound.title"), background: Theme.Tab.menu.calm)
    }

    private func icon(_ name: String) -> String {
        switch name {
        case "rain": return "🌧️"
        case "ocean": return "🌊"
        case "forest": return "🌲"
        case "wind": return "🌬️"
        case "fire": return "🔥"
        default: return "🍃"
        }
    }
}

struct MovementList: View {
    var engine: GoobyEngine

    var body: some View {
        MenuScroll {
            ForEach(engine.catalog.exercises) { exercise in
                NavigationLink {
                    MovementPlayer(engine: engine, exercise: exercise)
                } label: {
                    MenuLinkCard(icon: "🤸", color: Theme.Tab.quests.orange.opacity(0.3), title: exercise.title.text(engine.languageCode), subtitle: engine.tf("move.minutes", exercise.minutes))
                }
                .buttonStyle(MenuTilePressStyle())
            }
            MenuFootnote(text: engine.t("calm.disclaimer"))
        }
        .menuChrome(engine, title: engine.t("move.title"), background: Theme.Tab.menu.calm)
    }
}

struct MovementPlayer: View {
    var engine: GoobyEngine
    var exercise: ExerciseDef
    @State private var index = 0
    @State private var done = false

    var body: some View {
        MenuScroll {
            StripedProgressBar(value: done ? exercise.steps.count : index, goal: exercise.steps.count)
            GCard {
                VStack(alignment: .leading, spacing: 14) {
                    GoobyIcon(done ? "🎉" : "🤸", size: 52)
                    if done {
                        Text(engine.t("move.done"))
                            .font(Theme.Fonts.title3)
                            .foregroundStyle(Theme.text)
                    } else if exercise.steps.indices.contains(index) {
                        Text(exercise.steps[index].text(engine.languageCode))
                            .font(Theme.Fonts.title3)
                            .foregroundStyle(Theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
            }
            if !done {
                Button {
                    if index + 1 >= exercise.steps.count {
                        engine.finishMovement(exercise.id)
                        done = true
                    } else {
                        index += 1
                    }
                } label: {
                    Text(index + 1 >= exercise.steps.count ? engine.t("move.finish") : engine.t("common.continue"))
                }
                .menuPrimaryButton(fill: Theme.Tab.quests.orange)
            }
        }
        .menuChrome(engine, title: exercise.title.text(engine.languageCode), background: Theme.Tab.menu.calm)
    }
}

/// Mental first aid: 5-4-3-2-1 grounding, naming feelings, writing a thought down.
struct GroundingView: View {
    var engine: GoobyEngine
    @State private var step = 0
    @State private var feeling: Set<String> = []
    @State private var thought = ""
    @State private var saved = false
    private let counts = [5, 4, 3, 2, 1]
    private let tags = MenuMoodArt.tagIDs

    var body: some View {
        MenuScroll {
            MenuFootnote(text: engine.t("ground.lead"))
            StripedProgressBar(value: min(step, counts.count + 1), goal: counts.count + 1, fill: Theme.Tab.menu.bannerLight)
            if step < counts.count {
                GCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(counts[step])")
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.Tab.menu.banner)
                            .contentTransition(engine.reduceMotion ? .identity : .numericText(countsDown: true))
                        Text(engine.tf("ground.step", counts[step], engine.t("ground.sense.\(step)")))
                            .font(Theme.Fonts.title3)
                            .foregroundStyle(Theme.text)
                        Text(engine.t("ground.sense.help.\(step)"))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.greyText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Button {
                    goobyAnimate(engine.reduceMotion, GoobyMotion.springy) { step += 1 }
                } label: {
                    Text(engine.t("ground.next"))
                }
                .menuPrimaryButton()
            } else if step == counts.count {
                Text(engine.t("ground.feelings"))
                    .font(Theme.Fonts.title3)
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 4)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(tags, id: \.self) { tag in
                        MenuChip(title: engine.t("mood.tag.\(tag)"), icon: MenuMoodArt.tag(tag), selected: feeling.contains(tag)) {
                            if feeling.contains(tag) { feeling.remove(tag) } else { feeling.insert(tag) }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                Button {
                    engine.addMood(level: 3, tags: Array(feeling), note: "")
                    goobyAnimate(engine.reduceMotion, GoobyMotion.springy) { step += 1 }
                } label: {
                    Text(engine.t("ground.saveFeeling"))
                }
                .menuPrimaryButton()
            } else {
                Text(engine.t("ground.write"))
                    .font(Theme.Fonts.title3)
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 4)
                MenuField(placeholder: engine.t("ground.placeholder"), text: $thought, axis: .vertical)
                Button {
                    _ = engine.addJournal(title: engine.t("ground.journalTitle"), body: thought, tags: ["grounding"], promptID: "grounding")
                    saved = true
                } label: {
                    Text(engine.t("ground.saveThought"))
                }
                .menuPrimaryButton()
                .disabled(thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if saved {
                    Text(engine.t("ground.saved"))
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.checkGreen)
                        .padding(.horizontal, 4)
                }
                ForEach(0..<3, id: \.self) { index in
                    GCard(fill: Color.white.opacity(0.7)) {
                        HStack(alignment: .top, spacing: 12) {
                            GoobyIcon(["🦶", "🫧", "💗"][index], size: 28)
                            Text(engine.t("ground.card.\(index)"))
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            MenuFootnote(text: engine.t("calm.disclaimer"))
                .padding(.top, 6)
        }
        .menuChrome(engine, title: engine.t("ground.title"), background: Theme.Tab.menu.calm)
    }
}
