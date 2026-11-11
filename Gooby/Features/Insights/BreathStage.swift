import SwiftUI

struct BreathingView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var exercise: String = "calm"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var exerciseID: String
    @State private var minutes = 1
    @State private var showLengths = false
    @State private var showInfo = false
    @State private var soundOn: Bool
    @State private var showHint: Bool
    @State private var running = false
    @State private var paused = false
    @State private var finished = false
    @State private var rewarded = false
    @State private var hooked = false
    @State private var anchor = Date()
    @State private var frozen: TimeInterval = 0
    @State private var phaseID = ""
    @State private var burst: Date?

    init(engine: GoobyEngine, reduceMotion: Bool, exercise: String = "calm") {
        self.engine = engine
        self.reduceMotion = reduceMotion
        self.exercise = exercise
        let known = BreathPattern.named(exercise)?.id ?? "calm"
        _exerciseID = State(initialValue: known)
        let defaults = UserDefaults.standard
        _soundOn = State(initialValue: defaults.object(forKey: Self.soundKey) as? Bool ?? true)
        _showHint = State(initialValue: !defaults.bool(forKey: Self.hintKey))
    }

    private var still: Bool { reduceMotion || systemReduce || engine.reduceMotion }
    private var pattern: BreathPattern { BreathPattern.named(exerciseID) ?? BreathPattern.all[0] }
    private var limit: TimeInterval { Double(max(1, minutes) * 60) }

    var body: some View {
        ZStack {
            Color(hex: pattern.canvas).ignoresSafeArea()
            if running || finished {
                session
            } else {
                intro
            }
            if showLengths {
                CalmDimSheet(close: { setLengths(false) }) {
                    CalmLengthSheet(
                        title: engine.t("calm.breath.length"),
                        doneTitle: engine.t("common.done"),
                        closeLabel: engine.t("common.close"),
                        options: [1, 3, 5, 10],
                        minutes: $minutes,
                        label: { engine.tf("calm.breath.minutes", $0) },
                        close: { setLengths(false) },
                        done: { setLengths(false) }
                    )
                }
            } else if showInfo {
                CalmDimSheet(close: { setInfo(false) }) {
                    infoCard
                }
            }
        }
        .animation(still ? nil : .easeInOut(duration: 0.35), value: exerciseID)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .onChange(of: soundOn) { _, value in
            UserDefaults.standard.set(value, forKey: Self.soundKey)
            if !value { PackAudio.shared.stop() }
        }
        .onDisappear {
            PackAudio.shared.stop()
            endHook(reward: elapsed(at: Date()) >= pattern.cycle)
        }
    }

    private var intro: some View {
        VStack(spacing: 16) {
            topBar(session: false)
            if showHint && !showLengths && !showInfo {
                hint
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            exerciseMenu
            Text(engine.t("calm.breath.\(pattern.id).detail"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x5C6570))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            lengthPill
            Spacer(minLength: 0)
            introPet
            startButton
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private var session: some View {
        TimelineView(.animation(minimumInterval: still ? 0.45 : 1.0 / 30.0, paused: !running || paused)) { timeline in
            breathSession(at: timeline.date)
        }
    }

    private func breathSession(at date: Date) -> some View {
        let spent = elapsed(at: date)
        let visual = BreathPattern.visual(at: finished ? limit : spent, pattern: pattern, still: still)
        return ZStack {
            sessionStack(visual: visual, elapsed: spent)
            if let burst, !still {
                CalmConfetti(start: burst, still: still)
            }
        }
        .onChange(of: date) { _, next in
            guard running, !paused, !finished else { return }
            let now = elapsed(at: next)
            if now >= limit {
                complete()
            } else {
                notePhase(at: now)
            }
        }
    }

    private func sessionStack(visual: BreathVisual, elapsed: TimeInterval) -> some View {
        VStack(spacing: 0) {
            topBar(session: true)
                .padding(.horizontal, 18)
            Spacer(minLength: 8)
            ring(visual)
                .padding(.top, 8)
            Spacer(minLength: 0)
            ZStack(alignment: .bottom) {
                CalmPet(
                    engine: engine,
                    animation: finished ? .celebrate : .breathe,
                    reduceMotion: still || paused,
                    scale: 0.94 + (visual.scale - 0.72) * 0.18
                )
                .frame(height: 300)
                .offset(y: 36)
                VStack(spacing: 16) {
                    progress(min(1, elapsed / limit))
                    if finished {
                        Text(engine.t("calm.breath.done"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x1C1C1E))
                    } else {
                        pauseButton
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 22)
            }
        }
    }

    private func topBar(session: Bool) -> some View {
        HStack(spacing: 10) {
            CalmIconButton(symbol: "xmark", label: engine.t("common.close"), action: close)
            Spacer(minLength: 8)
            speaker
            if session {
                CalmIconButton(
                    symbol: "ellipsis",
                    label: engine.t("calm.breath.info"),
                    fill: Color.white.opacity(0.55),
                    ink: Color(hex: 0x1C1C1E),
                    action: { setInfo(true) }
                )
            } else {
                CalmSparkPill(count: engine.wallet.sparks, label: engine.t("calm.breath.sparks"))
            }
        }
        .padding(.top, 8)
    }

    private var speaker: some View {
        Button {
            soundOn.toggle()
            GoobyFeedback.play(soundOn ? .toggleOn : .toggleOff)
        } label: {
            Image(systemName: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: 0x1C1C1E))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.55), in: Circle())
                .symbolEffect(.bounce, value: soundOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(engine.t("calm.breath.sound"))
        .accessibilityValue(engine.t(soundOn ? "calm.breath.sound.on" : "calm.breath.sound.off"))
    }

    private var hint: some View {
        Button {
            dismissHint()
        } label: {
            Text(engine.t("calm.breath.soundHint"))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: 0x2C2C2E), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var exerciseMenu: some View {
        Menu {
            ForEach(BreathPattern.all) { item in
                Button(engine.t("calm.breath.\(item.id).title")) { exerciseID = item.id }
            }
        } label: {
            Text(engine.t("calm.breath.\(pattern.id).title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x1C1C1E))
                .multilineTextAlignment(.center)
        }
        .accessibilityHint(engine.t("calm.breath.pick"))
    }

    private var lengthPill: some View {
        Button {
            setLengths(true)
        } label: {
            HStack(spacing: 6) {
                Text(engine.tf("calm.breath.minutes", minutes))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: 0x1C1C1E))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: pattern.pill), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(engine.t("calm.breath.length"))
    }

    private var introPet: some View {
        TimelineView(.animation(minimumInterval: still ? 8 : 1.0 / 30.0, paused: still)) { timeline in
            let bob = still ? 0 : sin(timeline.date.timeIntervalSinceReferenceDate * 1.15) * 7
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.38))
                    .frame(width: 280, height: 280)
                    .offset(y: 30)
                CalmPet(engine: engine, animation: .breathe, reduceMotion: still, scale: 1)
                    .frame(width: 300, height: 300)
                    .offset(y: 48 + bob)
            }
        }
        .frame(height: 280)
    }

    private var startButton: some View {
        Button(action: begin) {
            Text(engine.t("common.start"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x1C1C1E))
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(CalmPressStyle(still: still))
    }

    private func ring(_ visual: BreathVisual) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(visual.opacity), lineWidth: 3)
                .scaleEffect(visual.scale)
            Circle()
                .fill(Color.white.opacity(min(0.78, visual.opacity + 0.12)))
                .scaleEffect(visual.scale * 0.6)
            VStack(spacing: 4) {
                Text(engine.t(visual.kind == "out" ? "calm.breath.exhale" : (visual.kind == "in" ? "calm.breath.inhale" : "calm.breath.hold")))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                if !visual.route.isEmpty {
                    Text(engine.t("calm.breath.\(visual.route)"))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
            }
            .foregroundStyle(Color(hex: 0x2C3338).opacity(visual.textOpacity))
        }
        .frame(width: 260, height: 260)
        .accessibilityElement(children: .combine)
    }

    private func progress(_ fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.88))
                Capsule()
                    .fill(Color(hex: 0x2A2E32))
                    .frame(width: max(10, geo.size.width * CGFloat(fraction)))
            }
        }
        .frame(height: 8)
        .accessibilityLabel(engine.t("calm.focus.remaining"))
        .accessibilityValue("\(Int((fraction * 100).rounded()))%")
    }

    private var pauseButton: some View {
        Button {
            if paused {
                anchor = Date()
                paused = false
            } else {
                frozen = elapsed(at: Date())
                paused = true
            }
            GoobyFeedback.play(.select)
        } label: {
            Group {
                if paused {
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                } else {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 1.5).frame(width: 5, height: 18)
                        RoundedRectangle(cornerRadius: 1.5).frame(width: 5, height: 18)
                    }
                }
            }
            .foregroundStyle(Color(hex: 0x2A2E32))
            .frame(width: 64, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(paused ? engine.t("common.resume") : engine.t("common.pause"))
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(engine.t("calm.breath.info"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1C1C1E))
                Spacer()
                Button(action: { setInfo(false) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: 0x8E8E93))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("common.close"))
            }
            Text(engine.t("calm.breath.\(pattern.id).detail"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x5C6570))
            ForEach(Array(pattern.phases.enumerated()), id: \.offset) { _, phase in
                Text(phaseLine(phase))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1C1C1E))
            }
            if !running && !finished {
                ForEach(BreathPattern.all) { item in
                    Button {
                        exerciseID = item.id
                        setInfo(false)
                    } label: {
                        Text(engine.t("calm.breath.\(item.id).title"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(item.id == pattern.id ? .white : Color(hex: 0x1C1C1E))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(item.id == pattern.id ? Color(hex: 0x3DDC78) : Color.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(engine.t("calm.disclaimer"))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x8E8E93))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color(hex: 0xF3F4F6), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func phaseLine(_ phase: BreathPattern.Phase) -> String {
        let title = engine.t(phase.kind == "out" ? "calm.breath.exhale" : (phase.kind == "in" ? "calm.breath.inhale" : "calm.breath.hold"))
        if phase.route.isEmpty {
            return engine.tf("calm.breath.phase.hold", title, Int(phase.seconds))
        }
        return engine.tf("calm.breath.phase", title, Int(phase.seconds), engine.t("calm.breath.\(phase.route)"))
    }

    private func elapsed(at date: Date) -> TimeInterval {
        if finished { return limit }
        if !running || paused { return min(limit, frozen) }
        return min(limit, frozen + date.timeIntervalSince(anchor))
    }

    private func notePhase(at time: TimeInterval) {
        let visual = BreathPattern.visual(at: time, pattern: pattern, still: still)
        let cycle = max(pattern.cycle, 0.1)
        let marker = "\(visual.kind)-\(Int(time / cycle))"
        guard marker != phaseID else { return }
        phaseID = marker
        if soundOn {
            let clip = visual.kind == "in" ? "pack-breathe-in" : (visual.kind == "out" ? "pack-breathe-out" : "pack-breathe-hold")
            if !PackAudio.shared.play(clip) { GoobyFeedback.play(.calm) }
        }
        let rising = visual.kind == "in"
        if visual.kind != "hold" {
            GoobyFeedback.shared.breathe(rising: rising, seconds: visual.phaseSeconds)
        }
    }

    private func begin() {
        dismissHint()
        finished = false
        rewarded = false
        burst = nil
        frozen = 0
        phaseID = ""
        anchor = Date()
        paused = false
        running = true
        let item = pattern
        hooked = true
        FeatureHost.shared.shellEvent?(engine, .breathStarted(pattern: item.id, seconds: [item.inhale, item.hold, item.exhale, item.hold2]))
        GoobyFeedback.play(.select)
    }

    private func complete() {
        guard !finished else { return }
        PackAudio.shared.stop()
        burst = Date()
        finished = true
        paused = false
        running = false
        frozen = limit
        endHook(reward: true)
    }

    private func close() {
        PackAudio.shared.stop()
        if !finished {
            endHook(reward: elapsed(at: Date()) >= pattern.cycle)
        }
        running = false
        dismiss()
    }

    private func endHook(reward: Bool) {
        guard hooked else { return }
        hooked = false
        if reward && !rewarded {
            rewarded = true
            engine.finishBreath()
        }
        FeatureHost.shared.shellEvent?(engine, .breathStopped)
    }

    private func dismissHint() {
        guard showHint else { return }
        showHint = false
        UserDefaults.standard.set(true, forKey: Self.hintKey)
    }

    private func setLengths(_ open: Bool) {
        withAnimation(still ? nil : .spring(response: 0.38, dampingFraction: 0.86)) {
            showInfo = false
            showLengths = open
        }
        if open { GoobyFeedback.play(.sheet) }
    }

    private func setInfo(_ open: Bool) {
        withAnimation(still ? nil : .spring(response: 0.38, dampingFraction: 0.86)) {
            showLengths = false
            showInfo = open
        }
        if open { GoobyFeedback.play(.sheet) }
    }

    private static let soundKey = "gooby.breath.sound"
    private static let hintKey = "gooby.breath.hint"
}

private struct CalmPressStyle: ButtonStyle {
    var still: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!still && configuration.isPressed ? 0.97 : 1)
            .animation(still ? nil : .spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct BreathPattern: Identifiable, Equatable {
    var id: String
    var inhale: Int
    var hold: Int
    var exhale: Int
    var hold2: Int
    var inRoute: String
    var outRoute: String
    var canvas: UInt32
    var pill: UInt32

    struct Phase: Equatable {
        var kind: String
        var seconds: Double
        var route: String
    }

    var cycle: Double { Double(inhale + hold + exhale + hold2) }

    var phases: [Phase] {
        var rows: [Phase] = []
        if inhale > 0 { rows.append(Phase(kind: "in", seconds: Double(inhale), route: inRoute)) }
        if hold > 0 { rows.append(Phase(kind: "hold", seconds: Double(hold), route: "")) }
        if exhale > 0 { rows.append(Phase(kind: "out", seconds: Double(exhale), route: outRoute)) }
        if hold2 > 0 { rows.append(Phase(kind: "rest", seconds: Double(hold2), route: "")) }
        return rows
    }

    static let all: [BreathPattern] = [
        BreathPattern(id: "calm", inhale: 4, hold: 0, exhale: 4, hold2: 0, inRoute: "nose", outRoute: "mouth", canvas: 0xC9F5D8, pill: 0x7DCE9A),
        BreathPattern(id: "energy", inhale: 3, hold: 0, exhale: 3, hold2: 0, inRoute: "mouth", outRoute: "nose", canvas: 0xFFE6BE, pill: 0xF0C36A),
        BreathPattern(id: "ease", inhale: 4, hold: 4, exhale: 8, hold2: 0, inRoute: "nose", outRoute: "mouth", canvas: 0xE4DEF8, pill: 0xC4B6EE),
        BreathPattern(id: "alert", inhale: 2, hold: 2, exhale: 2, hold2: 2, inRoute: "mouth", outRoute: "nose", canvas: 0xFFE7A3, pill: 0xF0C45A)
    ]

    static func named(_ id: String) -> BreathPattern? { all.first { $0.id == id } }

    static func visual(at elapsed: TimeInterval, pattern: BreathPattern, still: Bool) -> BreathVisual {
        let phases = pattern.phases
        let cycle = max(0.1, pattern.cycle)
        var cursor = elapsed.truncatingRemainder(dividingBy: cycle)
        if cursor < 0 { cursor += cycle }
        for (index, phase) in phases.enumerated() {
            let last = index == phases.count - 1
            if cursor < phase.seconds || last {
                let portion = min(1, max(0, cursor / max(phase.seconds, 0.001)))
                let eased = still ? (portion < 0.5 ? 0 : 1) : (0.5 - 0.5 * cos(portion * .pi))
                return paint(phase, eased: eased)
            }
            cursor -= phase.seconds
        }
        return paint(phases.last ?? Phase(kind: "out", seconds: 1, route: "mouth"), eased: 1)
    }

    private static func paint(_ phase: Phase, eased: Double) -> BreathVisual {
        let step = CGFloat(eased)
        switch phase.kind {
        case "in":
            return BreathVisual(scale: 0.72 + 0.32 * step, opacity: 0.95 - 0.2 * eased, textOpacity: 1, kind: "in", route: phase.route, phaseSeconds: phase.seconds)
        case "out":
            return BreathVisual(scale: 1.04 + 0.34 * step, opacity: 0.74 - 0.48 * eased, textOpacity: 1 - 0.5 * eased, kind: "out", route: phase.route, phaseSeconds: phase.seconds)
        case "rest":
            return BreathVisual(scale: 0.72, opacity: 0.9, textOpacity: 0.85, kind: "hold", route: "", phaseSeconds: phase.seconds)
        default:
            return BreathVisual(scale: 1.04, opacity: 0.8, textOpacity: 0.9, kind: "hold", route: "", phaseSeconds: phase.seconds)
        }
    }
}

struct BreathVisual: Equatable {
    var scale: CGFloat
    var opacity: Double
    var textOpacity: Double
    var kind: String
    var route: String
    var phaseSeconds: Double
}
