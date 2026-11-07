import SwiftUI

struct CareGroundingModifier: ViewModifier {
    @EnvironmentObject private var session: CareSession
    @State private var show = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        show = true
                    } label: {
                        Image(systemName: "leaf.circle.fill")
                    }
                    .accessibilityLabel(session.text(.groundingShortcut))
                }
            }
            .fullScreenCover(isPresented: $show) {
                CareHost {
                    NavigationStack { GroundingView() }
                }
            }
    }
}

extension View {
    func careGroundingShortcut() -> some View { modifier(CareGroundingModifier()) }
}

struct CalmHomeView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession

    var body: some View {
        CareScreen {
            Text(session.text(.calmIntro))
                .font(.title3.weight(.semibold))
                .foregroundStyle(CarePalette.ink)
            NavigationLink {
                GroundingView()
            } label: {
                CareCard(fill: CarePalette.pink.opacity(0.9)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.text(.groundingTitle)).font(.title3.weight(.semibold)).foregroundStyle(CarePalette.ink)
                        Text(session.text(.groundingLead)).foregroundStyle(CarePalette.ink.opacity(0.8))
                    }
                }
            }
            .buttonStyle(.plain)
            if let focus = store.database.focus, !focus.finished {
                CareCard(fill: CarePalette.yellow.opacity(0.9)) {
                    Text(session.text(.focusRunning))
                        .font(.headline)
                        .foregroundStyle(CarePalette.ink)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                link(.breathTitle, "wind", CarePalette.sky) { BreathingView() }
                link(.focusTitle, "timer", CarePalette.lavender) { FocusTimerView() }
                link(.soundTitle, "speaker.wave.2.fill", CarePalette.mint) { SoundscapeView() }
                link(.moveTitle, "figure.walk", CarePalette.peach) { MovementView() }
            }
            Text(session.text(.disclaimer))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
            Text(session.text(.notShared))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
        }
        .navigationTitle(session.text(.tabCalm))
        .careGroundingShortcut()
    }

    private func link<Destination: View>(_ title: CareString, _ symbol: String, _ fill: Color, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            CareCard(fill: fill.opacity(0.9)) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: symbol)
                        .font(.title2)
                        .foregroundStyle(CarePalette.ink)
                    Text(session.text(title))
                        .font(.headline)
                        .foregroundStyle(CarePalette.ink)
                }
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

struct BreathingView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var choice = "calm"
    @State private var custom = BreathPattern(id: "custom", inhale: 4, holdIn: 1, exhale: 6, holdOut: 0, cycles: 6)
    @State private var run: BreathRun?
    @State private var banner = ""

    var body: some View {
        CareScreen {
            Picker(session.text(.breathTitle), selection: $choice) {
                Text(session.text(.breathCalm)).tag("calm")
                Text(session.text(.breathBox)).tag("box")
                Text(session.text(.breathSleep)).tag("sleep")
                Text(session.text(.breathStress)).tag("stress")
                Text(session.text(.breathCustom)).tag("custom")
            }
            .pickerStyle(.menu)
            .disabled(run != nil)
            Text(detail).font(.subheadline).foregroundStyle(CarePalette.ink.opacity(0.75))
            if choice == "custom" && run == nil {
                customControls
            }
            TimelineView(.animation(minimumInterval: reduceMotion ? 0.5 : 1.0 / 30.0, paused: run == nil || run?.paused == true)) { timeline in
                let frame = frame(at: timeline.date)
                VStack(spacing: 16) {
                    Circle()
                        .fill(RadialGradient(colors: [CarePalette.sky, CarePalette.lavender], center: .center, startRadius: 8, endRadius: 140))
                        .frame(width: 220, height: 220)
                        .scaleEffect(reduceMotion ? 1 : frame.scale)
                        .opacity(reduceMotion ? 0.65 + 0.35 * frame.phaseProgress : 1)
                        .shadow(color: CarePalette.lavender.opacity(0.45), radius: 16, y: 8)
                        .overlay {
                            Text(session.text(phaseKey(frame.kind)))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(CarePalette.ink)
                        }
                        .accessibilityLabel(session.text(phaseKey(frame.kind)))
                    Text(session.format(.cycleLine, min(frame.cycleIndex + 1, frame.cycleCount), frame.cycleCount))
                        .foregroundStyle(CarePalette.ink)
                }
                .frame(maxWidth: .infinity)
            }
            .onChange(of: tickDate) { _, date in
                rewardIfNeeded(at: date)
            }
            TimelineView(.periodic(from: .now, by: 0.2)) { timeline in
                Color.clear.preference(key: TickKey.self, value: timeline.date.timeIntervalSinceReferenceDate)
            }
            .frame(height: 0)
            .onPreferenceChange(TickKey.self) { tickDate = Date(timeIntervalSinceReferenceDate: $0) }
            if !banner.isEmpty {
                Text(banner).foregroundStyle(CarePalette.ink)
            }
            if run == nil {
                Button(session.text(.start)) { start() }.buttonStyle(CarePrimaryButton())
            } else if run?.rewarded == true {
                Button(session.text(.done)) { run = nil; banner = "" }.buttonStyle(CarePrimaryButton())
            } else if run?.paused == true {
                Button(session.text(.resumeSession)) { resume() }.buttonStyle(CarePrimaryButton())
                Button(session.text(.stopSession)) { run = nil }.buttonStyle(CarePrimaryButton())
            } else {
                Button(session.text(.pauseSession)) { pause() }.buttonStyle(CarePrimaryButton())
                Button(session.text(.stopSession)) { run = nil }.buttonStyle(CarePrimaryButton())
            }
            Text(session.text(.disclaimer)).font(.footnote).foregroundStyle(CarePalette.ink.opacity(0.7))
        }
        .navigationTitle(session.text(.breathTitle))
        .onDisappear { run = nil }
    }

    @State private var tickDate = Date()

    private var activePattern: BreathPattern {
        switch choice {
        case "box": return .box
        case "sleep": return .sleep
        case "stress": return .stress
        case "custom": return custom.clamped()
        default: return .calm
        }
    }

    private var detail: String {
        switch choice {
        case "box": return session.text(.breathBoxDetail)
        case "sleep": return session.text(.breathSleepDetail)
        case "stress": return session.text(.breathStressDetail)
        case "custom": return session.text(.breathCustom)
        default: return session.text(.breathCalmDetail)
        }
    }

    private var customControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Stepper("\(session.text(.inhaleSeconds)): \(Int(custom.inhale))", value: $custom.inhale, in: 1.0...12.0, step: 1.0)
            Stepper("\(session.text(.holdSeconds)): \(Int(custom.holdIn))", value: $custom.holdIn, in: 0.0...12.0, step: 1.0)
            Stepper("\(session.text(.exhaleSeconds)): \(Int(custom.exhale))", value: $custom.exhale, in: 1.0...12.0, step: 1.0)
            Stepper("\(session.text(.restSeconds)): \(Int(custom.holdOut))", value: $custom.holdOut, in: 0.0...12.0, step: 1.0)
            Stepper("\(session.text(.cycleCount)): \(custom.cycles)", value: $custom.cycles, in: 1...20)
        }
        .foregroundStyle(CarePalette.ink)
    }

    private func frame(at date: Date) -> BreathFrame {
        BreathEngine.frame(elapsed: elapsed(at: date), pattern: activePattern)
    }

    private func elapsed(at date: Date) -> TimeInterval {
        guard let run else { return 0 }
        if run.paused { return run.base }
        return run.base + date.timeIntervalSince(run.started)
    }

    private func start() {
        run = BreathRun(id: UUID(), started: Date(), base: 0, paused: false, rewarded: false)
        banner = ""
    }

    private func pause() {
        guard var run, !run.paused else { return }
        run.base = elapsed(at: Date())
        run.paused = true
        self.run = run
    }

    private func resume() {
        guard var run, run.paused else { return }
        run.started = Date()
        run.paused = false
        self.run = run
    }

    private func rewardIfNeeded(at date: Date) {
        guard var run, !run.paused, !run.rewarded else { return }
        let frame = frame(at: date)
        guard frame.finished else { return }
        run.rewarded = true
        run.paused = true
        run.base = elapsed(at: date)
        self.run = run
        _ = store.grantCalm(
            key: "breath:\(run.id.uuidString)",
            energy: CareRewards.breathEnergy,
            sparks: CareRewards.breathSparks,
            reason: "breath",
            title: session.text(.breathTitle)
        )
        banner = "\(session.text(.sessionDone)) \(session.text(.rewardNoted))"
        CareHaptics.success()
    }

    private func phaseKey(_ kind: BreathPhaseKind) -> CareString {
        switch kind {
        case .inhale: return .phaseInhale
        case .hold: return .phaseHold
        case .exhale: return .phaseExhale
        case .rest: return .phaseRest
        }
    }
}

private struct BreathRun {
    var id: UUID
    var started: Date
    var base: TimeInterval
    var paused: Bool
    var rewarded: Bool
}

private struct TickKey: PreferenceKey {
    static var defaultValue: TimeInterval = Date().timeIntervalSinceReferenceDate
    static func reduce(value: inout TimeInterval, nextValue: () -> TimeInterval) {
        value = nextValue()
    }
}

struct FocusTimerView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @State private var minutes = 25
    @State private var banner = ""

    var body: some View {
        CareScreen {
            if let focus = store.database.focus {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let left = FocusMath.remaining(session: focus, now: timeline.date)
                    VStack(spacing: 12) {
                        Text(clock(left))
                            .font(.system(size: 64, weight: .semibold, design: .rounded))
                            .foregroundStyle(CarePalette.ink)
                            .monospacedDigit()
                        Text(focus.finished ? session.text(.focusFinished) : (focus.pausedRemaining != nil ? session.text(.focusPaused) : session.text(.focusRunning)))
                            .foregroundStyle(CarePalette.ink)
                        ring(planned: Double(focus.plannedSeconds), remaining: left)
                    }
                    .frame(maxWidth: .infinity)
                    .onChange(of: timeline.date) { _, date in
                        if store.refreshFocus(now: date, title: session.text(.focusTitle)) != nil {
                            banner = session.text(.rewardNoted)
                            CareHaptics.success()
                        }
                    }
                }
                if focus.finished {
                    Button(session.text(.done)) {
                        store.clearFinishedFocus()
                        banner = ""
                    }
                    .buttonStyle(CarePrimaryButton())
                } else if focus.pausedRemaining != nil {
                    Button(session.text(.resumeSession)) { store.resumeFocus(now: Date()) }.buttonStyle(CarePrimaryButton())
                    Button(session.text(.focusEnd)) { store.cancelFocus(); banner = "" }.buttonStyle(CarePrimaryButton())
                } else {
                    Button(session.text(.pauseSession)) { store.pauseFocus(now: Date()) }.buttonStyle(CarePrimaryButton())
                    Button(session.text(.focusEnd)) { store.cancelFocus(); banner = "" }.buttonStyle(CarePrimaryButton())
                }
            } else {
                Text(session.text(.focusPick)).font(.title3.weight(.semibold)).foregroundStyle(CarePalette.ink)
                CareFlowLayout {
                    ForEach([5, 10, 15, 25, 45], id: \.self) { value in
                        Button {
                            minutes = value
                        } label: {
                            Text(session.format(.focusMinutes, value))
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(CarePalette.ink)
                                .background(Capsule().fill(minutes == value ? CarePalette.lavender : CarePalette.card))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Stepper("\(session.text(.focusCustom)): \(minutes)", value: $minutes, in: 1...120)
                    .foregroundStyle(CarePalette.ink)
                Button(session.text(.start)) {
                    store.startFocus(seconds: minutes * 60, now: Date())
                    banner = ""
                }
                .buttonStyle(CarePrimaryButton())
            }
            if !banner.isEmpty { Text(banner).foregroundStyle(CarePalette.ink) }
        }
        .navigationTitle(session.text(.focusTitle))
        .onAppear {
            if store.refreshFocus(now: Date(), title: session.text(.focusTitle)) != nil {
                banner = session.text(.rewardNoted)
            }
        }
    }

    private func ring(planned: Double, remaining: TimeInterval) -> some View {
        let total = max(1, planned)
        let progress = min(1, max(0, 1 - remaining / total))
        return ZStack {
            Circle().stroke(CarePalette.lavender.opacity(0.4), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(CarePalette.ink, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 180, height: 180)
        .padding(.vertical, 8)
    }

    private func clock(_ seconds: TimeInterval) -> String {
        let whole = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", whole / 60, whole % 60)
    }
}

struct SoundscapeView: View {
    @EnvironmentObject private var session: CareSession
    @StateObject private var player = SoundscapePlayer()

    var body: some View {
        CareScreen {
            Text(session.text(.soundGenerated))
                .font(.subheadline)
                .foregroundStyle(CarePalette.ink.opacity(0.8))
            if player.failed {
                Text(session.text(.soundFailed)).foregroundStyle(CarePalette.ink)
            }
            ForEach(SoundscapeKind.allCases) { kind in
                Button {
                    player.toggle(kind)
                } label: {
                    CareCard(fill: player.current == kind ? CarePalette.mint : CarePalette.card) {
                        HStack {
                            Text(session.text(kind.title))
                                .font(.headline)
                                .foregroundStyle(CarePalette.ink)
                            Spacer()
                            Text(player.current == kind ? session.text(.soundPlaying) : session.text(.soundStopped))
                                .font(.subheadline)
                                .foregroundStyle(CarePalette.ink.opacity(0.75))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            if player.current != nil {
                Button(session.text(.stopSession)) { player.stop() }.buttonStyle(CarePrimaryButton())
            }
        }
        .navigationTitle(session.text(.soundTitle))
        .onDisappear { player.stop() }
    }
}

struct MovementView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @State private var run: MoveRun?
    @State private var banner = ""

    var body: some View {
        CareScreen {
            Text(session.text(.moveComfort))
                .font(.subheadline)
                .foregroundStyle(CarePalette.ink.opacity(0.8))
            if let run, let routine = MovementCatalog.routines.first(where: { $0.id == run.routineID }) {
                active(run, routine)
            } else {
                ForEach(MovementCatalog.routines) { routine in
                    Button {
                        start(routine)
                    } label: {
                        CareCard(fill: CarePalette.peach.opacity(0.85)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.text(routine.title)).font(.headline).foregroundStyle(CarePalette.ink)
                                Text(session.text(routine.summary)).foregroundStyle(CarePalette.ink.opacity(0.75))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            if !banner.isEmpty { Text(banner).foregroundStyle(CarePalette.ink) }
        }
        .navigationTitle(session.text(.moveTitle))
    }

    private func active(_ run: MoveRun, _ routine: MovementRoutine) -> some View {
        let step = routine.steps[min(run.step, routine.steps.count - 1)]
        return VStack(alignment: .leading, spacing: 12) {
            Text(session.text(routine.title)).font(.title3.weight(.semibold)).foregroundStyle(CarePalette.ink)
            Text(session.format(.groundStep, run.step + 1, routine.steps.count))
                .font(.caption)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
            Text(session.text(step.title)).font(.title2.weight(.semibold)).foregroundStyle(CarePalette.ink)
            Text(session.text(step.detail)).foregroundStyle(CarePalette.ink)
            TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                Text(clock(remaining(run, at: timeline.date)))
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(CarePalette.ink)
                    .onChange(of: timeline.date) { _, date in
                        advance(to: date, routine: routine)
                    }
            }
            if run.endsAt == nil && run.pausedRemaining == nil {
                Button(session.text(.done)) { self.run = nil }.buttonStyle(CarePrimaryButton())
            } else if run.pausedRemaining != nil {
                Button(session.text(.resumeSession)) { resume() }.buttonStyle(CarePrimaryButton())
                Button(session.text(.stopSession)) { self.run = nil }.buttonStyle(CarePrimaryButton())
            } else {
                Button(session.text(run.step + 1 >= routine.steps.count ? .moveFinish : .moveNext)) {
                    skipOrFinish(routine)
                }
                .buttonStyle(CarePrimaryButton())
                Button(session.text(.pauseSession)) { pause() }.buttonStyle(CarePrimaryButton())
                Button(session.text(.stopSession)) { self.run = nil }.buttonStyle(CarePrimaryButton())
            }
        }
    }

    private func start(_ routine: MovementRoutine) {
        guard let first = routine.steps.first else { return }
        run = MoveRun(
            id: UUID(),
            routineID: routine.id,
            step: 0,
            endsAt: Date().addingTimeInterval(Double(first.seconds)),
            pausedRemaining: nil,
            rewarded: false
        )
        banner = ""
    }

    private func remaining(_ run: MoveRun, at date: Date) -> TimeInterval {
        if let paused = run.pausedRemaining { return paused }
        if let endsAt = run.endsAt { return max(0, endsAt.timeIntervalSince(date)) }
        return 0
    }

    private func pause() {
        guard var run, let endsAt = run.endsAt else { return }
        run.pausedRemaining = max(0, endsAt.timeIntervalSince(Date()))
        run.endsAt = nil
        self.run = run
    }

    private func resume() {
        guard var run, let left = run.pausedRemaining else { return }
        run.endsAt = Date().addingTimeInterval(left)
        run.pausedRemaining = nil
        self.run = run
    }

    private func skipOrFinish(_ routine: MovementRoutine) {
        guard var run else { return }
        if run.step + 1 >= routine.steps.count {
            finish(&run)
            return
        }
        run.step += 1
        run.pausedRemaining = nil
        run.endsAt = Date().addingTimeInterval(Double(routine.steps[run.step].seconds))
        self.run = run
    }

    private func advance(to date: Date, routine: MovementRoutine) {
        guard var run, run.endsAt != nil else { return }
        var guardrail = 0
        while let ends = run.endsAt, date >= ends, guardrail < 12 {
            guardrail += 1
            if run.step + 1 >= routine.steps.count {
                finish(&run)
                return
            }
            let overflow = date.timeIntervalSince(ends)
            run.step += 1
            let duration = Double(routine.steps[run.step].seconds)
            run.endsAt = date.addingTimeInterval(max(0.2, duration - overflow))
        }
        self.run = run
    }

    private func finish(_ run: inout MoveRun) {
        run.endsAt = nil
        run.pausedRemaining = nil
        if !run.rewarded {
            run.rewarded = true
            _ = store.grantCalm(
                key: "move:\(run.id.uuidString)",
                energy: CareRewards.movementEnergy,
                sparks: CareRewards.movementSparks,
                reason: "movement",
                title: session.text(.moveTitle)
            )
            banner = session.text(.rewardNoted)
            CareHaptics.success()
        }
        self.run = run
    }

    private func clock(_ seconds: TimeInterval) -> String {
        let whole = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", whole / 60, whole % 60)
    }
}

private struct MoveRun {
    var id: UUID
    var routineID: String
    var step: Int
    var endsAt: Date?
    var pausedRemaining: TimeInterval?
    var rewarded: Bool
}

struct GroundingView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var senses = ["", "", "", "", ""]
    @State private var tags: Set<MoodTag> = []
    @State private var thought = ""
    @State private var sessionID = UUID()
    @State private var rewarded = false

    private var total: Int { GroundingCatalog.sensePrompts.count + 3 }

    var body: some View {
        CareScreen {
            Text(session.format(.groundStep, min(step + 1, total), total))
                .font(.caption.weight(.semibold))
                .foregroundStyle(CarePalette.ink.opacity(0.7))
            content
            if step < total - 1 {
                Button(session.text(.moveNext)) { advance() }.buttonStyle(CarePrimaryButton())
            } else {
                Button(session.text(.close)) { dismiss() }.buttonStyle(CarePrimaryButton())
            }
            Text(session.text(.disclaimer))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
            Text(session.text(.notShared))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
        }
        .navigationTitle(session.text(.groundingTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(session.text(.close)) { dismiss() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if step < GroundingCatalog.sensePrompts.count {
            Text(session.text(.groundingLead))
                .foregroundStyle(CarePalette.ink.opacity(0.8))
            Text(session.text(GroundingCatalog.sensePrompts[step]))
                .font(.title3.weight(.semibold))
                .foregroundStyle(CarePalette.ink)
            TextField(session.text(GroundingCatalog.sensePrompts[step]), text: senseBinding, axis: .vertical)
                .lineLimit(2...5)
                .textFieldStyle(.roundedBorder)
        } else if step == GroundingCatalog.sensePrompts.count {
            Text(session.text(.groundFeeling))
                .font(.title3.weight(.semibold))
                .foregroundStyle(CarePalette.ink)
            CareFlowLayout {
                ForEach(MoodTag.allCases) { tag in
                    Button {
                        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
                    } label: {
                        Text(CareCopy.tag(tag, session.language))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(CarePalette.ink)
                            .background(Capsule().fill(tags.contains(tag) ? CarePalette.peach : CarePalette.card))
                    }
                    .buttonStyle(.plain)
                }
            }
        } else if step == GroundingCatalog.sensePrompts.count + 1 {
            Text(session.text(.groundThought))
                .font(.title3.weight(.semibold))
                .foregroundStyle(CarePalette.ink)
            TextField(session.text(.groundThoughtPlaceholder), text: $thought, axis: .vertical)
                .lineLimit(3...8)
                .textFieldStyle(.roundedBorder)
        } else {
            Text(session.text(.groundDone))
                .font(.title3.weight(.semibold))
                .foregroundStyle(CarePalette.ink)
            Text(session.text(.calmLine1)).foregroundStyle(CarePalette.ink)
            Text(session.text(.calmLine2)).foregroundStyle(CarePalette.ink)
            Text(session.text(.calmLine3)).foregroundStyle(CarePalette.ink)
            if rewarded {
                Text(session.text(.rewardNoted)).font(.footnote).foregroundStyle(CarePalette.ink.opacity(0.75))
            }
        }
    }

    private var senseBinding: Binding<String> {
        Binding(
            get: { step < senses.count ? senses[step] : "" },
            set: { value in
                if step < senses.count { senses[step] = value }
            }
        )
    }

    private func advance() {
        let feeling = GroundingCatalog.sensePrompts.count
        let writing = feeling + 1
        if step == writing {
            saveThought()
            reward()
        }
        step += 1
    }

    private func saveThought() {
        let text = thought.trimmingCharacters(in: .whitespacesAndNewlines)
        let feeling = tags.map { CareCopy.tag($0, session.language) }.joined(separator: ", ")
        let sensesText = senses.enumerated().compactMap { index, value -> String? in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return "\(session.text(GroundingCatalog.sensePrompts[index])) \(trimmed)"
        }.joined(separator: "\n")
        let body = [feeling, text, sensesText].filter { !$0.isEmpty }.joined(separator: "\n\n")
        guard !body.isEmpty else { return }
        let entry = JournalEntry(
            id: UUID(),
            day: session.todayKey,
            createdAt: session.now,
            updatedAt: session.now,
            title: session.text(.groundingTitle),
            body: body,
            tags: [session.text(.groundingTitle)],
            reflection: nil,
            rewarded: false
        )
        _ = store.saveJournal(entry, now: session.now)
    }

    private func reward() {
        guard !rewarded else { return }
        rewarded = true
        _ = store.grantCalm(
            key: "ground:\(sessionID.uuidString)",
            energy: CareRewards.groundingEnergy,
            sparks: CareRewards.groundingSparks,
            reason: "grounding",
            title: session.text(.groundingTitle)
        )
        CareHaptics.success()
    }
}
