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
    @State private var minutes = 1
    @State private var arms = true
    @State private var legs = true
    @State private var neck = true
    @State private var started: Date?
    @State private var done = false

    var body: some View {
        StretchSession(
            engine: engine,
            title: engine.t("stretch.stage.title"),
            minutes: minutes,
            channels: StretchChannels.blend(arms: arms, legs: legs, neck: neck),
            exerciseID: nil,
            started: started,
            done: done,
            onStart: {
                started = Date()
                done = false
            },
            onFinish: { finish() }
        ) {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    StretchSectionLabel(text: engine.t("stretch.stage.length"))
                    HStack(spacing: 10) {
                        ForEach([1, 3, 5, 10], id: \.self) { value in
                            StretchChoice(
                                title: "\(value)",
                                detail: engine.t("stretch.stage.min"),
                                on: minutes == value
                            ) { minutes = value }
                        }
                    }
                }
                VStack(spacing: 10) {
                    StretchSectionLabel(text: engine.t("stretch.stage.types"))
                    HStack(spacing: 8) {
                        StretchChoice(title: engine.t("stretch.stage.arms"), on: arms, toggle: { toggleArms() })
                        StretchChoice(title: engine.t("stretch.stage.legs"), on: legs, toggle: { toggleLegs() })
                        StretchChoice(title: engine.t("stretch.stage.neck"), on: neck, toggle: { toggleNeck() })
                    }
                }
            }
        }
        .navigationTitle(engine.t("stretch.stage.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(StretchPaint.page, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private func toggleArms() {
        if arms, !legs, !neck { return }
        arms.toggle()
    }

    private func toggleLegs() {
        if legs, !arms, !neck { return }
        legs.toggle()
    }

    private func toggleNeck() {
        if neck, !arms, !legs { return }
        neck.toggle()
    }

    private func finish() {
        guard !done else { return }
        done = true
        engine.finishMovement(StretchChannels.reward(arms: arms, legs: legs, neck: neck))
    }
}

struct MovementPlayer: View {
    var engine: GoobyEngine
    var exercise: ExerciseDef
    @State private var started = Date()
    @State private var done = false

    var body: some View {
        StretchSession(
            engine: engine,
            title: exercise.title.text(engine.languageCode),
            minutes: max(1, exercise.minutes),
            channels: StretchChannels.focus(exercise.id),
            exerciseID: exercise.id,
            started: started,
            done: done,
            onStart: nil,
            onFinish: { finish() }
        ) {
            EmptyView()
        }
        .navigationTitle(exercise.title.text(engine.languageCode))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(StretchPaint.page, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    private func finish() {
        guard !done else { return }
        done = true
        engine.finishMovement(exercise.id)
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

// The standing stretch plays on the drawn cream rabbit.
// Finch_Stretching_01.json is 25 fps, frames 25...300, 11.0 s. Wings become the arm and the ears.
// No Lottie, Rive, GIF, or bird.

private struct StretchSession<Setup: View>: View {
    var engine: GoobyEngine
    var title: String
    var minutes: Int
    var channels: StretchChannels
    var exerciseID: String?
    var started: Date?
    var done: Bool
    var onStart: (() -> Void)?
    var onFinish: () -> Void
    @ViewBuilder var setup: () -> Setup
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    private var still: Bool { systemReduce || engine.reduceMotion }
    private var configuring: Bool { onStart != nil && started == nil && !done }
    private var length: Double { Double(max(1, minutes) * 60) }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: still ? 1 : 1.0 / 30.0, paused: false)) { timeline in
                let clock = started.map { timeline.date.timeIntervalSince($0) } ?? timeline.date.timeIntervalSinceReferenceDate
                let poseTime = still && !done ? StretchMotion.heldTime(exerciseID: exerciseID, channels: channels) : clock
                let pose = StretchMotion.pose(time: done && still ? 10.5 : poseTime, channels: done ? .rest : channels)
                let cueLocal = StretchMotion.local(still ? poseTime : clock)
                ScrollView {
                    VStack(spacing: 0) {
                        rabbit(pose)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        sheet(clock: max(0, clock), cueLocal: cueLocal)
                            .padding(.top, -12)
                    }
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .background(StretchPaint.page.ignoresSafeArea())
        .task(id: started) { await runClock() }
    }

    private func rabbit(_ pose: GoobyPose) -> some View {
        ZStack(alignment: .bottom) {
            StretchRoom()
            GoobyRig(look: creamLook, stage: Growth.stage(of: engine.pet), pose: pose, companion: nil)
                .frame(width: 230, height: 230)
                .padding(.bottom, 6)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(engine.t(still ? "stretch.a11y.still" : "stretch.a11y"))
    }

    private var creamLook: WornLook {
        var look = engine.wornLook()
        look.fur = "fur-cream"
        return look
    }

    private func sheet(clock: Double, cueLocal: Double) -> some View {
        let left = Int(max(0, length - (started == nil ? length : min(clock, length))))
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(StretchPaint.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            if configuring {
                setup()
            } else {
                Text(engine.t(done ? "move.done" : StretchMotion.cueKey(local: cueLocal, channels: channels, exerciseID: exerciseID)))
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(StretchPaint.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56, alignment: .top)
                StretchMeter(value: started == nil ? 0 : min(1, clock / length))
                if started != nil, !done {
                    Text(engine.tf("stretch.stage.left", left / 60, left % 60))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(StretchPaint.ink.opacity(0.55))
                        .monospacedDigit()
                }
            }
            Spacer(minLength: 16)
            if configuring {
                if let onStart {
                    Button(engine.t("stretch.stage.start"), action: onStart)
                        .buttonStyle(GoobyButtonStyle(fill: StretchPaint.page, ink: StretchPaint.ink))
                }
            } else if !done {
                Button(engine.t("move.finish"), action: onFinish)
                    .buttonStyle(GoobyButtonStyle(fill: StretchPaint.page, ink: StretchPaint.ink))
            }
            Text(engine.t("stretch.stage.note"))
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(StretchPaint.ink.opacity(0.45))
                .multilineTextAlignment(.center)
            Text(engine.t("calm.disclaimer"))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(StretchPaint.ink.opacity(0.38))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28, style: .continuous)
                .fill(StretchPaint.card)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func runClock() async {
        guard let started else { return }
        let remain = max(0, length - Date().timeIntervalSince(started))
        if remain > 0 {
            do { try await Task.sleep(for: .seconds(remain)) } catch { return }
        }
        onFinish()
    }
}

private struct StretchRoom: View {
    var body: some View {
        ZStack {
            StretchPaint.room
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(StretchPaint.glass)
                    }
                }
                .padding(.horizontal, 28)
                .frame(height: 118)
                Capsule()
                    .fill(StretchPaint.sill)
                    .frame(height: 8)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Spacer(minLength: 0)
            }
            .padding(.top, 22)
        }
        .accessibilityHidden(true)
    }
}

private struct StretchSectionLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(StretchPaint.ink.opacity(0.45))
    }
}

private struct StretchChoice: View {
    var title: String
    var detail: String?
    var on: Bool
    var action: () -> Void

    init(title: String, detail: String, on: Bool, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.on = on
        self.action = action
    }

    init(title: String, on: Bool, toggle: @escaping () -> Void) {
        self.title = title
        self.detail = nil
        self.on = on
        self.action = toggle
    }

    @ViewBuilder private var labeled: some View {
        if detail == nil {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .textCase(.uppercase)
        } else {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                labeled
                if let detail {
                    Text(detail)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                }
            }
            .foregroundStyle(StretchPaint.ink)
            .padding(.horizontal, detail == nil ? 14 : 8)
            .padding(.vertical, detail == nil ? 10 : 8)
            .frame(minWidth: detail == nil ? 72 : 64, minHeight: detail == nil ? 40 : 64)
            .background { plate }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    @ViewBuilder private var plate: some View {
        if detail == nil {
            Capsule().fill(on ? StretchPaint.chip : StretchPaint.chipOff)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(on ? StretchPaint.chip : StretchPaint.chipOff)
        }
    }
}

private struct StretchMeter: View {
    var value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(StretchPaint.ink.opacity(0.08))
                Capsule()
                    .fill(StretchPaint.meter)
                    .frame(width: max(8, geo.size.width * min(1, max(0, value))))
            }
        }
        .frame(height: 12)
        .accessibilityValue("\(Int((min(1, max(0, value)) * 100).rounded()))%")
    }
}

private enum StretchPaint {
    static let page = Color(hex: 0xF8C83C)
    static let card = Color(hex: 0xFFFEFB)
    static let ink = Color(hex: 0x2C261C)
    static let chip = Color(hex: 0xF8C83C)
    static let chipOff = Color(hex: 0xE7E4DE)
    static let room = Color(hex: 0xF4EFE4)
    static let glass = Color(hex: 0xD5E6F1)
    static let sill = Color(hex: 0xFFFEFB)
    static let meter = Color(hex: 0xE2A31A)
}

struct StretchChannels: Equatable {
    var arm: Double
    var ears: Double
    var body: Double
    var neck: Double
    var leg: Double
    var blink: Double
    var sit: Bool

    static let full = StretchChannels(arm: 1, ears: 1, body: 1, neck: 1, leg: 1, blink: 1, sit: false)
    static let rest = StretchChannels(arm: 0, ears: 0.12, body: 0.35, neck: 0.15, leg: 0, blink: 1, sit: true)

    static func blend(arms: Bool, legs: Bool, neck: Bool) -> StretchChannels {
        if arms, legs, neck { return .full }
        var value = StretchChannels(arm: 0, ears: 0, body: 0.2, neck: 0, leg: 0, blink: 1, sit: false)
        if arms {
            value.arm = 1
            value.ears = 1
            value.body = 1
        }
        if legs {
            value.leg = 1
            value.body = max(value.body, 0.5)
        }
        if neck {
            value.neck = 1
            value.body = max(value.body, 0.3)
        }
        return value
    }

    /// stretch, shoulders, break, neck, hands, rest. Each one reads a part of the same 11 s loop.
    static func focus(_ id: String) -> StretchChannels {
        switch id {
        case "shoulders":
            return StretchChannels(arm: 0.42, ears: 1, body: 1, neck: 0.35, leg: 0.15, blink: 1, sit: false)
        case "break":
            return StretchChannels(arm: 0.15, ears: 0.2, body: 0.45, neck: 0.2, leg: 1, blink: 1, sit: false)
        case "neck":
            return StretchChannels(arm: 0.08, ears: 0.25, body: 0.25, neck: 1, leg: 0, blink: 1, sit: false)
        case "hands":
            return StretchChannels(arm: 1, ears: 0.35, body: 0.3, neck: 0.2, leg: 0, blink: 1, sit: false)
        case "rest":
            return .rest
        default:
            return .full
        }
    }

    static func reward(arms: Bool, legs: Bool, neck: Bool) -> String {
        if legs, !arms, !neck { return "break" }
        if neck, !arms, !legs { return "neck" }
        return "stretch"
    }
}

private enum StretchMotion {
    /// `Finch_Stretching_01.json`, in-point frame 25, out-point frame 300, 25 fps.
    static let period = (300.0 - 25.0) / 25.0

    static func local(_ time: Double) -> Double {
        let value = time.truncatingRemainder(dividingBy: period)
        return value < 0 ? value + period : value
    }

    static func heldTime(exerciseID: String?, channels: StretchChannels) -> Double {
        if channels.sit || exerciseID == "rest" { return 10.5 }
        switch exerciseID {
        case "shoulders": return 0.48
        case "break": return 1.32
        case "hands", "neck": return 2.20
        default:
            if channels.arm < 0.35, channels.leg >= 0.5, channels.neck < 0.5 { return 1.32 }
            if channels.arm < 0.35, channels.neck >= 0.5 { return 2.20 }
            if channels.arm < 0.35 { return 0.48 }
            return 2.20
        }
    }

    static func cueKey(local: Double, channels: StretchChannels, exerciseID: String?) -> String {
        if channels.sit || exerciseID == "rest" { return "stretch.cue.rest" }
        switch exerciseID {
        case "shoulders":
            return local < 2.9 ? "stretch.cue.shrug" : "stretch.cue.lower"
        case "break":
            return "stretch.cue.leg"
        case "neck":
            return "stretch.cue.neck"
        case "hands":
            return (local >= 4.72 && local < 7.4) ? "stretch.cue.hands" : "stretch.cue.reach"
        default:
            break
        }
        if local < 0.55, channels.body > 0.6 { return "stretch.cue.shrug" }
        if local < 1.15, channels.arm > 0.5 { return "stretch.cue.reach" }
        if local < 2.72, channels.neck > 0.5 { return "stretch.cue.neck" }
        if local < 2.72, channels.arm > 0.5 { return "stretch.cue.reach" }
        if local < 2.72, channels.leg > 0.5 { return "stretch.cue.leg" }
        if local < 4.72 { return "stretch.cue.lower" }
        if local < 7.40, channels.arm > 0.5 { return "stretch.cue.hands" }
        if local < 7.40, channels.neck > 0.5 { return "stretch.cue.neck" }
        if local < 7.40, channels.leg > 0.5 { return "stretch.cue.leg" }
        if channels.neck > 0.5, local < 8.4 { return "stretch.cue.neck" }
        return "stretch.cue.rest"
    }

    /// Near wing → the one arm the rig can swing. Far wing → ears. Root scale → body.
    /// Head rotation → neck. Leg rotation → the stepping foot. Eye scale → blink.
    static func pose(time: Double, channels: StretchChannels) -> GoobyPose {
        let t = local(time)
        var pose = GoobyPose()
        let lifted = min(1.12, max(-0.15, (sample(t, nearWing) + 4.0) / -110.0))
        let raised = 2.6 + (-6.4 * lifted)
        if channels.sit {
            pose.stance = .sit
        } else if channels.arm >= 0.35 {
            pose.stance = .wave
            pose.wave = CGFloat(2.6 + (raised - 2.6) * channels.arm)
        } else {
            pose.stance = .stand
        }
        let ear = min(1.05, max(0, (sample(t, farWing) + 152.0) / 158.0))
        pose.earLeft = CGFloat(-16 * ear * channels.ears)
        pose.earRight = CGFloat(14 * ear * channels.ears)
        let width = 1 + (sample(t, scaleX) / 100.0 - 1) * channels.body
        let height = 1 + (sample(t, scaleY) / 100.0 - 1) * channels.body
        pose.squash = CGFloat(width)
        let span = 2 - width
        pose.breath = CGFloat(abs(span) < 0.05 ? height : height / span)
        pose.headTilt = CGFloat((sample(t, head) - 6.0) * (18.0 / 28.4) * channels.neck)
        pose.tilt = CGFloat(sample(t, torso) * 0.8 * max(channels.body, channels.arm * 0.65))
        pose.step = CGFloat(sample(t, leg) / 30.0 * 5.0 * channels.leg)
        let open = min(1.0, max(0.0, (sample(t, eye) - 5.74) / (97.74 - 5.74)))
        pose.blink = CGFloat(1 - (1 - open) * channels.blink)
        return pose
    }

    private struct Knot {
        var t: Double
        var v: Double
        var ox: Double
        var oy: Double
        var ix: Double?
        var iy: Double?

        init(_ t: Double, _ v: Double, _ ox: Double = 0, _ oy: Double = 0, ix: Double? = nil, iy: Double? = nil) {
            self.t = t
            self.v = v
            self.ox = ox
            self.oy = oy
            self.ix = ix
            self.iy = iy
        }

        init(_ t: Double, _ v: Double, _ ox: Double, _ oy: Double, _ ix: Double, _ iy: Double) {
            self.init(t, v, ox, oy, ix: ix, iy: iy)
        }
    }

    private static let nearWing: [Knot] = [
        Knot(0.0000, -4.0000, 0.3300, 0.0000, 0.0000, 1.0000),
        Knot(0.4800, 3.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(1.2000, -114.0000, 0.3000, 0.0000, 0.6500, 1.0800),
        Knot(1.2732, -116.6300, 0.4000, 0.0900, 0.6700, 1.0000),
        Knot(1.3468, -114.0000, 0.3000, 0.0000, 0.6500, 1.0800),
        Knot(1.4200, -116.6300, 0.4000, 0.0900, 0.6700, 1.0000),
        Knot(1.4932, -114.0000, 0.3000, 0.0000, 0.6500, 1.0800),
        Knot(1.5668, -116.6300, 0.4000, 0.0900, 0.6700, 1.0000),
        Knot(1.6400, -114.0000, 0.3000, 0.0000, 0.6500, 1.0800),
        Knot(1.7132, -116.6300, 0.4000, 0.0900, 0.6700, 1.0000),
        Knot(1.7868, -114.0000, 0.3000, 0.0000, 0.6500, 1.0800),
        Knot(1.8600, -116.6300, 0.4000, 0.0900, 0.6700, 1.0000),
        Knot(1.9332, -114.0000, 0.3000, 0.0000, 0.6500, 1.0800),
        Knot(2.0068, -116.6300, 0.4000, 0.0900, 0.6700, 1.0000),
        Knot(2.0800, -114.0000, 0.3000, 0.0000, 0.6500, 1.0800),
        Knot(2.1532, -116.6300, 0.4000, 0.0900, 0.6700, 1.0000),
        Knot(2.2268, -114.0000, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(2.7200, 3.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(3.1200, -4.0000, 0.1700, 0.0000, 0.8300, 1.0000),
        Knot(3.7600, -4.0000, 0.1700, 0.0000, 0.8300, 1.0000),
        Knot(4.7200, -4.0000, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(5.2800, -101.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(5.5200, -65.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(5.7600, -101.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(6.0000, -65.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(6.2800, -101.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(6.5200, -65.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(6.7200, -66.0200, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(7.3200, -4.0000, 0.3300, 0.0000, 0.8300, 1.0000),
        Knot(10.9600, -4.0000)
    ]

    private static let farWing: [Knot] = [
        Knot(0.0000, -152.0000, 0.3300, 0.0000, 0.0000, 1.0000),
        Knot(0.4800, -152.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(1.3200, 0.0000, 0.1700, 0.0000, 0.4000, 1.0000),
        Knot(2.2000, 6.0000, 0.1700, 0.0000, 0.6800, 1.0000),
        Knot(2.8000, -167.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(3.2000, -152.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(3.7600, -152.0000, 0.1700, 0.0000, 0.8300, 1.0000),
        Knot(4.1200, -152.0000, 0.1700, 0.0000, 0.8300, 1.0000),
        Knot(4.7200, -140.0000, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(10.9600, -152.0000)
    ]

    private static let head: [Knot] = [
        Knot(0.0000, 6.0000, 0.3300, 0.0000, 0.0000, 1.0000),
        Knot(0.7200, 11.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(1.5600, -15.4000, 0.3300, 0.0000, 0.4000, 1.0000),
        Knot(2.2000, -22.4000, 0.1700, 0.0000, 0.6800, 1.0000),
        Knot(2.9200, 10.0000, 0.3300, 0.0000, 0.6800, 1.0000),
        Knot(3.3200, 6.0000, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(3.7600, 6.0000, 0.3300, 0.0000, 0.8300, 1.0000),
        Knot(4.1200, 6.0000, 0.1700, 0.0000, 0.0000, 1.0000),
        Knot(4.7200, 0.0000, 0.3300, 0.0000, 0.6700, 1.0100),
        Knot(5.3600, -8.8600, 0.3300, 0.0100, 0.6700, 0.9800),
        Knot(5.6000, -4.6800, 0.3300, -0.0200, 0.6700, 1.0100),
        Knot(5.8400, -8.8600, 0.3300, 0.0100, 0.6700, 0.9800),
        Knot(6.0800, -4.6800, 0.3300, -0.0200, 0.6700, 1.0100),
        Knot(6.3600, -8.8600, 0.3300, 0.0100, 0.6700, 0.9800),
        Knot(6.6000, -4.6800, 0.3300, -0.0300, 0.6700, 1.0100),
        Knot(7.0000, -8.8600, 0.3300, 0.0200, 0.6700, 0.9500),
        Knot(7.6000, -4.6800, 0.3300, 0.6900, 0.6700, 0.3100),
        Knot(9.6000, -4.6800, 0.3300, 0.0100, 0.6700, 1.0000),
        Knot(10.0800, 6.0000, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(10.9200, 6.0000)
    ]

    private static let torso: [Knot] = [
        Knot(0.0000, 0.0000, 0.3300, 0.0000, 0.0000, 1.0000),
        Knot(0.4800, 4.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(1.3200, -6.0000, 0.3300, 0.0000, 0.4000, 1.0000),
        Knot(2.2000, -10.0000, 0.1700, 0.0000, 0.6800, 1.0000),
        Knot(2.7200, 4.0000, 0.3300, 0.0000, 0.6800, 1.0000),
        Knot(3.1200, 0.0000, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(3.7600, 0.0000, 0.1700, 0.0000, 0.8300, 1.0000),
        Knot(4.7200, 0.0000, 0.1700, 0.0000, 0.8300, 1.0000),
        Knot(6.7200, -5.0000, 0.1700, 0.0000, 0.8300, 1.0000),
        Knot(7.3200, 0.0000, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(10.9600, 0.0000)
    ]

    private static let leg: [Knot] = [
        Knot(0.0000, 0.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(0.4800, -13.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(1.3200, 30.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(2.2000, 30.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(2.7200, 0.0000)
    ]

    private static let scaleX: [Knot] = [
        Knot(0.0000, 100.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(0.4800, 105.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(1.3200, 95.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(2.2000, 94.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(2.7200, 105.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(3.1200, 100.0000)
    ]

    private static let scaleY: [Knot] = [
        Knot(0.0000, 100.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(0.4800, 95.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(1.3200, 105.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(2.2000, 107.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(2.7200, 95.0000, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(3.1200, 100.0000)
    ]

    private static let eye: [Knot] = [
        Knot(3.2000, 97.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(3.3200, 5.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(3.5200, 97.7400, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(4.1200, 97.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(4.2100, 5.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(4.3600, 97.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(4.4500, 5.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(4.6000, 97.7400, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(7.1200, 97.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(7.1952, 5.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(7.3200, 97.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(7.3952, 5.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(7.5200, 97.7400, 0.1700, 0.0000, 0.6700, 1.0000),
        Knot(10.0000, 97.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(10.1200, 5.7400, 0.3300, 0.0000, 0.6700, 1.0000),
        Knot(10.3200, 97.7400)
    ]

    private static func sample(_ time: Double, _ knots: [Knot]) -> Double {
        guard let first = knots.first else { return 0 }
        if time <= first.t { return first.v }
        for index in 1..<knots.count {
            let left = knots[index - 1]
            let right = knots[index]
            if time <= right.t || index == knots.count - 1 {
                let span = right.t - left.t
                if span <= 0 || time >= right.t { return right.v }
                let u = (time - left.t) / span
                let eased = unitEase(u, left.ox, left.oy, right.ix, right.iy)
                return left.v + (right.v - left.v) * eased
            }
        }
        return knots[knots.count - 1].v
    }

    /// Same temporal bezier as the waiting loop. A value influence outside 0...1.5 stays linear.
    private static func unitEase(_ u: Double, _ x1: Double, _ y1: Double, _ x2: Double?, _ y2: Double?) -> Double {
        guard let x2, let y2 else { return u }
        if y1 < 0 || y2 < 0 || y1 > 1.5 || y2 > 1.5 { return u }
        func cx(_ t: Double) -> Double {
            let mt = 1 - t
            return 3 * mt * mt * t * x1 + 3 * mt * t * t * x2 + t * t * t
        }
        func cy(_ t: Double) -> Double {
            let mt = 1 - t
            return 3 * mt * mt * t * y1 + 3 * mt * t * t * y2 + t * t * t
        }
        func dx(_ t: Double) -> Double {
            let mt = 1 - t
            return 3 * mt * mt * x1 + 6 * mt * t * (x2 - x1) + 3 * t * t * (1 - x2)
        }
        var slope = dx(0)
        var step = 0.0
        while step <= 1 {
            slope = min(slope, dx(step))
            step += 0.025
        }
        if slope < -0.0001 { return u }
        var t = u
        for _ in 0..<16 {
            let derivative = dx(t)
            if abs(derivative) < 1e-9 { break }
            t = min(1, max(0, t - (cx(t) - u) / derivative))
        }
        if abs(cx(t) - u) > 0.001 { return u }
        return cy(t)
    }
}
