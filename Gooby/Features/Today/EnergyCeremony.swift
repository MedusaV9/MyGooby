import Observation
import SwiftUI

enum EnergyCeremony {
    static let stoneReward = 129
    static let toddlerDays = 7
    static let notifyLatch = "ceremony-notify-asked"

    static func fullDayKey(_ day: String) -> String { "full-energy:\(day)" }

    @MainActor
    static func line(_ engine: GoobyEngine, _ key: String, _ pairs: [String: String] = [:]) -> String {
        var text = engine.t(key)
        for (token, value) in pairs {
            text = text.replacingOccurrences(of: "{\(token)}", with: value)
        }
        return text
    }

    @MainActor
    static func petName(_ engine: GoobyEngine) -> String {
        let trimmed = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Gooby" : trimmed
    }

    /// Empty and unknown pronouns use the neutral line. "her" is checked before "he".
    static func pronounKey(_ raw: String) -> String {
        let folded = raw.folding(options: .diacriticInsensitive, locale: Locale(identifier: "de"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if folded.isEmpty { return "they" }
        if folded.hasPrefix("she") || folded.hasPrefix("sie") || folded.contains("her") { return "she" }
        if folded.hasPrefix("he") || folded.hasPrefix("er") || folded.contains("him") { return "he" }
        return "they"
    }

    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
}

enum CeremonyStep: Equatable {
    case fill, reward, growing, departed
}

struct CeremonyToast: Identifiable, Equatable {
    var id = UUID()
    var text: String
}

@MainActor
@Observable
final class EnergyCeremonySession {
    var hidden: Set<UUID> = []
    var toasts: [CeremonyToast] = []
    var cover = false
    var askNotifications = false
    var step: CeremonyStep = .fill
    var stoneStart = 0
    var stoneEnd = 0
    var stoneGain = 0
    /// Energy the completing goal just added, so the bar can climb into MAX.
    var fillFrom = 5
    var departureError: String?

    func ready(_ engine: GoobyEngine) -> Bool {
        guard !cover, !askNotifications, engine.todaysRun() == nil else { return false }
        return engine.wallet.energy >= max(1, engine.profile.energyGoal)
    }

    /// Stones and one full-energy day, the first time the bar fills today. Independent of the scene.
    @discardableResult
    func book(_ engine: GoobyEngine) -> Bool {
        guard engine.wallet.energy >= max(1, engine.profile.energyGoal) else { return false }
        let fresh = engine.grant(key: EnergyCeremony.fullDayKey(engine.dayKey()), sparks: EnergyCeremony.stoneReward, energy: 0)
        if fresh { engine.addFullEnergyDay() }
        return fresh
    }

    func open(_ engine: GoobyEngine, reduceMotion: Bool, animateStones: Bool) {
        guard ready(engine) else { return }
        let key = EnergyCeremony.fullDayKey(engine.dayKey())
        let gain = engine.all(RewardLedger.self).first { $0.key == key }?.sparks ?? 0
        stoneGain = gain
        stoneEnd = engine.wallet.sparks
        stoneStart = max(0, stoneEnd - (animateStones ? gain : 0))
        departureError = nil
        step = (reduceMotion || !animateStones) ? .reward : .fill
        cover = true
    }

    func noteCheck(engine: GoobyEngine, habit: Habit, store: GoalMetaStore, count: Int) {
        let cap = max(1, habit.timesPerDay)
        var lines: [String] = []
        var changed = false
        if count == 1 {
            let prior = engine.all(HabitLog.self).filter { $0.habitID == habit.id && !$0.skipped && $0.count > 0 }
            let latch = "toast-amazing:\(habit.id.uuidString)"
            if prior.count == 1, engine.grant(key: latch, sparks: 0, energy: 0) {
                lines.append(engine.t("ceremony.toast.amazing"))
                changed = true
            }
        }
        if count >= cap {
            fillFrom = max(1, habit.energyReward)
            let day = engine.dayKey()
            if let area = GoalActions.areaName(for: habit, language: engine.languageCode, store: store) {
                let mates = engine.dueHabits(on: engine.now()).filter { $0.category == habit.category }
                let cleared = !mates.isEmpty && mates.allSatisfy { mate in
                    (engine.habitLog(mate.id, day)?.count ?? 0) >= max(1, mate.timesPerDay)
                }
                let latch = "toast-area:\(habit.category):\(day)"
                if cleared, engine.grant(key: latch, sparks: 0, energy: 0) {
                    lines.append(EnergyCeremony.line(engine, "ceremony.toast.area", ["area": area]))
                    changed = true
                }
            }
            let due = engine.dueHabits(on: engine.now())
            let left = due.filter { (engine.habitLog($0.id, day)?.count ?? 0) < max(1, $0.timesPerDay) }.count
            if !due.isEmpty, left == 0, engine.grant(key: "toast-rockstar", sparks: 0, energy: 0) {
                lines.append(engine.t("ceremony.toast.rockstar"))
                changed = true
            }
        }
        if changed { engine.save() }
        if !lines.isEmpty {
            toasts = toasts + lines.map { CeremonyToast(text: $0) }
        }
    }

    func conceal(_ id: UUID) {
        guard !hidden.contains(id) else { return }
        var next = hidden
        next.insert(id)
        hidden = next
    }

    func reveal(_ id: UUID) {
        guard hidden.contains(id) else { return }
        var next = hidden
        next.remove(id)
        hidden = next
    }

    func beginDeparture(_ engine: GoobyEngine) -> String? {
        if engine.todaysRun() != nil { return nil }
        guard let place = engine.catalog.places.first(where: { engine.isPlaceUnlocked($0.id) }) else {
            return "error.missing"
        }
        if let error = engine.startAdventure(placeID: place.id), error != "adventure.already" {
            return error
        }
        return nil
    }

    func finish(_ engine: GoobyEngine) {
        cover = false
        guard !engine.profile.notificationsEnabled else { return }
        if engine.all(RewardLedger.self).contains(where: { $0.key == EnergyCeremony.notifyLatch }) { return }
        askNotifications = true
    }

    func markNotifyAsked(_ engine: GoobyEngine) {
        if engine.grant(key: EnergyCeremony.notifyLatch, sparks: 0, energy: 0) {
            engine.save()
        }
    }
}

struct EnergyCeremonyChrome: ViewModifier {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var session: EnergyCeremonySession

    func body(content: Content) -> some View {
        content
            .task(id: engine.wallet.energy) {
                let fresh = session.book(engine)
                guard session.ready(engine) else { return }
                if !reduceMotion {
                    try? await Task.sleep(nanoseconds: 420_000_000)
                    guard !Task.isCancelled, session.ready(engine) else { return }
                }
                session.open(engine, reduceMotion: reduceMotion, animateStones: fresh)
            }
            .fullScreenCover(isPresented: Binding(get: { session.cover }, set: { session.cover = $0 })) {
                EnergyCeremonyScreen(engine: engine, reduceMotion: reduceMotion, session: session)
                    .interactiveDismissDisabled(true)
            }
            .overlay {
                if session.askNotifications {
                    CeremonyNotifyPrompt(engine: engine, reduceMotion: reduceMotion, session: session)
                }
            }
            .overlay(alignment: .bottom) {
                CeremonyToastHost(session: session, reduceMotion: reduceMotion)
            }
    }
}

struct GoalSendoff: ViewModifier {
    var engine: GoobyEngine
    var habit: Habit
    var reduceMotion: Bool
    var session: EnergyCeremonySession
    var store: GoalMetaStore
    @State private var lift: CGFloat = 0
    @State private var fade: Double = 1
    @State private var burst = 0
    @State private var sentOff = false
    @State private var tilt: Double = 0
    @State private var shrink: CGFloat = 1

    func body(content: Content) -> some View {
        let current = engine.habitLog(habit.id, engine.dayKey())?.count ?? 0
        content
            .rotationEffect(.degrees(tilt))
            .offset(y: lift)
            .opacity(fade)
            .scaleEffect(shrink, anchor: .trailing)
            .overlay {
                if burst > 0 && !reduceMotion {
                    RowConfetti(token: burst)
                }
            }
            .zIndex(burst > 0 && !sentOff ? 2 : 0)
            .onChange(of: current) { previous, next in
                guard next != previous else { return }
                let cap = max(1, habit.timesPerDay)
                if next < previous {
                    if next < cap {
                        sentOff = false
                        lift = 0
                        fade = 1
                        tilt = 0
                        shrink = 1
                        session.reveal(habit.id)
                    }
                    return
                }
                if !reduceMotion { burst += 1 }
                session.noteCheck(engine: engine, habit: habit, store: store, count: next)
                guard next >= cap, previous < cap, !sentOff else { return }
                sentOff = true
                if reduceMotion {
                    session.conceal(habit.id)
                    return
                }
                withAnimation(.easeIn(duration: 0.52)) {
                    lift = -168
                    fade = 0
                    tilt = -3
                    shrink = 0.94
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 540_000_000)
                    session.conceal(habit.id)
                }
            }
    }
}

struct EnergyCeremonyScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var session: EnergyCeremonySession

    var body: some View {
        GeometryReader { geo in
            let meadow = session.step != .departed
            ZStack(alignment: .topTrailing) {
                if meadow {
                    CeremonyMeadow()
                } else {
                    departedStage(height: geo.size.height)
                }
                if meadow {
                    character
                        .frame(width: 170, height: 170)
                        .position(x: geo.size.width / 2, y: min(geo.size.height * 0.34, 290))
                }
                ScrollView {
                    VStack(spacing: 16) {
                        Color.clear.frame(height: meadow ? min(geo.size.height * 0.46, 390) : geo.size.height * 0.40)
                        copy
                        buttons
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .top)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                CeremonyConfetti(active: session.step == .reward || session.step == .growing, reduceMotion: reduceMotion)
                if session.step == .reward {
                    stonePill
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                }
            }
        }
        .background(Color(hex: 0x73B752).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task(id: session.step) {
            guard session.step == .fill else { return }
            let goal = max(1, engine.profile.energyGoal)
            let steps = max(1, goal - fillStart)
            let wait: UInt64 = reduceMotion ? 0 : UInt64(steps) * 140_000_000 + 460_000_000
            try? await Task.sleep(nanoseconds: wait)
            guard !Task.isCancelled, session.step == .fill else { return }
            advance(to: .reward)
            engine.haptics.celebrate()
        }
    }

    private var fillStart: Int {
        let goal = max(1, engine.profile.energyGoal)
        let chunk = max(1, session.fillFrom)
        return max(0, min(goal - 1, goal - chunk))
    }

    private func departedStage(height: CGFloat) -> some View {
        let stage = max(220, height * 0.42)
        return VStack(spacing: 0) {
            ForestScene(
                reduceMotion: reduceMotion,
                look: engine.wornLook(),
                growth: Growth.stage(of: engine.pet),
                companion: engine.companionSpecies(),
                animation: reduceMotion ? .idle : .walk,
                walking: !reduceMotion,
                showPack: true,
                petLabel: EnergyCeremony.petName(engine),
                petAction: "",
                onTap: {},
                onPet: {}
            )
            .frame(height: stage)
            .clipped()
            Color(hex: 0x73B752)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var character: some View {
        GoobyCharacterView(
            look: engine.wornLook(),
            stage: Growth.stage(of: engine.pet),
            animation: ceremonyPose(session.step),
            reduceMotion: reduceMotion,
            companion: nil,
            showCompanion: false
        )
        .accessibilityLabel(EnergyCeremony.petName(engine))
    }

    @ViewBuilder private var copy: some View {
        if session.step == .fill || session.step == .reward {
            FillBar(
                from: fillStart,
                goal: max(1, engine.profile.energyGoal),
                instant: reduceMotion || session.step == .reward,
                maxWord: engine.t("ceremony.max")
            )
        }
        switch session.step {
        case .fill:
            Color.clear.frame(height: 1).accessibilityHidden(true)
        case .reward:
            rewardCopy
        case .growing:
            growingCopy
        case .departed:
            departedCopy
        }
    }

    private var rewardCopy: some View {
        let name = EnergyCeremony.petName(engine)
        let day = max(1, engine.pet.fullEnergyDays)
        let sentence = engine.pet.fullEnergyDays <= 1 ? "ceremony.corn" : "ceremony.energized"
        return VStack(spacing: 14) {
            Text(engine.t("ceremony.woohoo"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(EnergyCeremony.line(engine, sentence, ["name": name, "day": "\(day)"]))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            HStack(spacing: 10) {
                RainbowGem()
                VStack(alignment: .leading, spacing: 2) {
                    Text(EnergyCeremony.line(engine, "ceremony.stones.who", ["name": name]))
                    Text(EnergyCeremony.line(engine, "ceremony.stones.gain", ["count": "\(session.stoneGain)"]))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
    }

    private var growingCopy: some View {
        let name = EnergyCeremony.petName(engine)
        let days = max(0, engine.pet.fullEnergyDays)
        let shown = min(EnergyCeremony.toddlerDays, days)
        let left = max(0, EnergyCeremony.toddlerDays - days)
        let foot: String
        if left == 0 {
            foot = EnergyCeremony.line(engine, "ceremony.evolve.done", ["name": name])
        } else if left == 1 {
            foot = engine.t("ceremony.evolve.one")
        } else {
            foot = EnergyCeremony.line(engine, "ceremony.evolve.more", ["left": "\(left)"])
        }
        return VStack(spacing: 16) {
            Text(EnergyCeremony.line(engine, "ceremony.growing", ["name": name]))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    CeremonyTeddy()
                        .frame(width: 54, height: 54)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(EnergyCeremony.line(engine, "ceremony.evolve", ["name": name]))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(HomePalette.ink)
                        Text(engine.t("ceremony.evolve.detail"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x8E939A))
                    }
                }
                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: 0xECECEC))
                            Capsule()
                                .fill(HomePalette.bolt)
                                .frame(width: max(CGFloat(10), geo.size.width * CGFloat(shown) / CGFloat(EnergyCeremony.toddlerDays)))
                        }
                    }
                    .frame(height: 12)
                    Text("\(shown)/\(EnergyCeremony.toddlerDays)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x8E939A))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .topLeading) {
                CeremonyFlag().offset(x: 8, y: -12)
            }
            Text(foot)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
            Text(EnergyCeremony.line(engine, "ceremony.ready", ["name": name]))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
    }

    private var departedCopy: some View {
        VStack(spacing: 16) {
            Text(engine.t("ceremony.started"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            DepartureTrack()
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Text(shareLine)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var shareLine: String {
        let name = EnergyCeremony.petName(engine)
        let remaining = engine.todaysRun().map { $0.returnsAt.timeIntervalSince(engine.now()) } ?? GoobyEngine.dailyTripSeconds
        let key = "ceremony.share.\(EnergyCeremony.pronounKey(engine.pet.pronouns))"
        return EnergyCeremony.line(engine, key, ["name": name, "clock": EnergyCeremony.clock(remaining)])
    }

    @ViewBuilder private var buttons: some View {
        switch session.step {
        case .fill:
            Color.clear
                .frame(height: 54)
                .contentShape(Rectangle())
                .onTapGesture { advance(to: .reward) }
                .accessibilityLabel(engine.t("ceremony.continue"))
        case .reward:
            CeremonyWideButton(title: engine.t("ceremony.continue")) { advance(to: .growing) }
        case .growing:
            VStack(spacing: 10) {
                CeremonyWideButton(title: engine.t("ceremony.start")) { startTrip() }
                if let departureError = session.departureError {
                    Text(departureError)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Button(engine.t("ceremony.exit")) { session.cover = false }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        case .departed:
            CeremonyWideButton(title: engine.t("ceremony.gotIt")) { session.finish(engine) }
        }
    }

    private var stonePill: some View {
        HStack(spacing: 6) {
            RainbowGem().frame(width: 22, height: 22)
            StoneCounter(from: session.stoneStart, to: session.stoneEnd, reduceMotion: reduceMotion)
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
        .background(Color.white, in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private func advance(to next: CeremonyStep) {
        if reduceMotion {
            session.step = next
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { session.step = next }
        }
    }

    private func startTrip() {
        if let error = session.beginDeparture(engine) {
            session.departureError = engine.t(error)
            return
        }
        session.departureError = nil
        advance(to: .departed)
    }
}

private struct FillBar: View {
    var from: Int
    var goal: Int
    var instant: Bool
    var maxWord: String
    @State private var shown: Int
    @State private var showMax: Bool
    @State private var bolt: CGFloat

    init(from: Int, goal: Int, instant: Bool, maxWord: String) {
        let safe = max(1, goal)
        let start = min(max(0, from), safe - 1)
        self.from = start
        self.goal = safe
        self.instant = instant
        self.maxWord = maxWord
        _shown = State(initialValue: instant ? safe : start)
        _showMax = State(initialValue: instant)
        _bolt = State(initialValue: instant ? 1 : 0.2)
    }

    var body: some View {
        let fraction = showMax ? CGFloat(1) : CGFloat(shown) / CGFloat(goal)
        GeometryReader { geo in
            let width = geo.size.width
            ZStack {
                Capsule().fill(Color.white.opacity(0.42))
                HStack(spacing: 0) {
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: 0xFFE08A), Color(hex: 0xFF9A1F)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(CGFloat(28), width * fraction))
                    Spacer(minLength: 0)
                }
                Text(showMax ? maxWord : "\(min(shown, goal)) / \(goal)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(showMax ? Color.white : Color(hex: 0x8A4E08))
                    .contentTransition(.numericText())
                if showMax {
                    ZStack {
                        Circle().fill(Color(hex: 0xFFC44D))
                        Circle().fill(Color(hex: 0xFF9A1F)).padding(3)
                        BoltShape().fill(.white).frame(width: 14, height: 18)
                    }
                    .frame(width: 36, height: 36)
                    .scaleEffect(bolt)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(x: 10)
                }
            }
        }
        .frame(height: 28)
        .padding(.horizontal, 28)
        .accessibilityLabel(showMax ? maxWord : "\(shown) / \(goal)")
        .task(id: instant) {
            if instant {
                shown = goal
                showMax = true
                bolt = 1
                return
            }
            let start = from
            let steps = max(1, goal - start)
            shown = start
            showMax = false
            bolt = 0.2
            for step in 1...steps {
                try? await Task.sleep(nanoseconds: 140_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.12)) { shown = start + step }
            }
            try? await Task.sleep(nanoseconds: 80_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                showMax = true
                bolt = 1
            }
        }
    }
}

private func ceremonyPose(_ step: CeremonyStep) -> GoobyAnimation {
    switch step {
    case .fill: return .idle
    case .reward: return .celebrate
    case .growing: return .wave
    case .departed: return .walk
    }
}

private struct StoneCounter: View {
    var from: Int
    var to: Int
    var reduceMotion: Bool
    @State private var shown: Int

    init(from: Int, to: Int, reduceMotion: Bool) {
        self.from = from
        self.to = to
        self.reduceMotion = reduceMotion
        _shown = State(initialValue: reduceMotion || from >= to ? to : from)
    }

    var body: some View {
        Text("\(shown)")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(HomePalette.ink)
            .monospacedDigit()
            .contentTransition(.numericText())
            .task(id: to) {
                guard !reduceMotion, from < to else {
                    shown = to
                    return
                }
                shown = from
                let steps = 24
                for step in 1...steps {
                    try? await Task.sleep(nanoseconds: 40_000_000)
                    guard !Task.isCancelled else { return }
                    shown = from + (to - from) * step / steps
                }
                shown = to
            }
    }
}

private struct CeremonyWideButton: View {
    var title: String
    var fill: Color = .white
    var ink: Color = Color(hex: 0x667085)
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct DepartureTrack: View {
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(HomePalette.bolt).frame(width: 34, height: 34).offset(x: -14)
                BoltShape().fill(.white).frame(width: 13, height: 16).offset(x: -14)
                TrackBunny().offset(x: 14)
            }
            .frame(width: 64, height: 36)
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(Color.white.opacity(0.95), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [1.5, 7]))
            }
            .frame(height: 16)
            ZStack {
                Circle().fill(HomePalette.bolt).frame(width: 34, height: 34)
                Text("?")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 40)
        .accessibilityHidden(true)
    }
}

private struct CeremonyNotifyPrompt: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var session: EnergyCeremonySession
    @State private var busy = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.28).ignoresSafeArea()
            VStack(spacing: 0) {
                Text(engine.t("ceremony.notify.ask"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomePalette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .bottom) {
                        Circle().fill(Color.white).frame(width: 14, height: 14).offset(y: 6)
                    }
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: .wave,
                    reduceMotion: reduceMotion,
                    companion: nil,
                    showCompanion: false
                )
                .frame(width: 130, height: 130)
                .offset(y: 36)
                .frame(height: 72, alignment: .bottom)
                .clipped()
                .accessibilityHidden(true)
                VStack(spacing: 14) {
                    Text(EnergyCeremony.line(engine, "ceremony.notify.body", ["name": EnergyCeremony.petName(engine)]))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(HomePalette.ink)
                        .multilineTextAlignment(.center)
                    Button {
                        turnOn()
                    } label: {
                        Text(engine.t("ceremony.notify.on"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: 0x3CC85A), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(busy)
                    Button(engine.t("ceremony.notify.later")) { session.askNotifications = false }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x8E939A))
                        .disabled(busy)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .onAppear { session.markNotifyAsked(engine) }
        .accessibilityAddTraits(.isModal)
    }

    private func turnOn() {
        guard !busy else { return }
        busy = true
        Task {
            let ok = await GoobyAlerts.request()
            engine.profile.notificationsEnabled = ok
            engine.save()
            if ok { engine.rescheduleNotifications() }
            session.askNotifications = false
            busy = false
        }
    }
}

private struct CeremonyToastHost: View {
    var session: EnergyCeremonySession
    var reduceMotion: Bool

    var body: some View {
        Group {
            if !session.cover && !session.askNotifications, let toast = session.toasts.first {
                CeremonyToastCard(text: toast.text, reduceMotion: reduceMotion)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .task(id: toast.id) {
                        try? await Task.sleep(nanoseconds: 2_400_000_000)
                        guard !Task.isCancelled else { return }
                        guard session.toasts.first?.id == toast.id else { return }
                        var next = session.toasts
                        next.removeFirst()
                        session.toasts = next
                    }
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.35), value: session.toasts.first?.id)
    }
}

private struct CeremonyToastCard: View {
    var text: String
    var reduceMotion: Bool

    var body: some View {
        HStack(spacing: 10) {
            CeremonyFace().frame(width: 36, height: 36)
            Text(text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: 0x2C2C2E), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            if !reduceMotion { ToastConfetti() }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CeremonyFace: View {
    var body: some View {
        ZStack {
            Circle().fill(HomePalette.fur)
            Capsule().fill(HomePalette.fur).frame(width: 8, height: 12).offset(x: -10, y: -14)
            Capsule().fill(HomePalette.fur).frame(width: 8, height: 12).offset(x: 10, y: -14)
            Circle().fill(HomePalette.eye).frame(width: 3.5, height: 3.5).offset(x: -5, y: -1)
            Circle().fill(HomePalette.eye).frame(width: 3.5, height: 3.5).offset(x: 5, y: -1)
            SmileShape()
                .stroke(HomePalette.eye, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                .frame(width: 10, height: 5)
                .offset(y: 5)
        }
    }
}

private struct CeremonyTeddy: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xC4844A)).frame(width: 16, height: 16).offset(x: -16, y: -16)
            Circle().fill(Color(hex: 0xC4844A)).frame(width: 16, height: 16).offset(x: 16, y: -16)
            Circle().fill(Color(hex: 0xC4844A)).frame(width: 36, height: 36)
            Circle().fill(Color(hex: 0x8D5A32)).frame(width: 16, height: 12).offset(y: 6)
            Circle().fill(HomePalette.eye).frame(width: 3.5, height: 3.5).offset(x: -6, y: -2)
            Circle().fill(HomePalette.eye).frame(width: 3.5, height: 3.5).offset(x: 6, y: -2)
            Capsule().fill(Color(hex: 0xC23B3B)).frame(width: 28, height: 8).offset(y: 18)
        }
        .accessibilityHidden(true)
    }
}

private struct CeremonyFlag: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 2, y: 0))
            path.addLine(to: CGPoint(x: 16, y: 6))
            path.addLine(to: CGPoint(x: 2, y: 12))
            path.closeSubpath()
        }
        .fill(Color(hex: 0xE2554A))
        .frame(width: 16, height: 12)
        .accessibilityHidden(true)
    }
}

private struct RainbowGem: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: 0x7CFF6B))
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(18))
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: 0x4C8DFF))
                .frame(width: 12, height: 12)
                .rotationEffect(.degrees(42))
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0xFF7AD1))
                .frame(width: 8, height: 8)
        }
        .accessibilityHidden(true)
    }
}

private struct CeremonyMeadow: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            func box(_ x: CGFloat, _ y: CGFloat, _ bw: CGFloat, _ bh: CGFloat) -> CGRect {
                CGRect(x: x / 390 * w, y: y / 844 * h, width: bw / 390 * w, height: bh / 844 * h)
            }
            func pine(_ context: inout GraphicsContext, _ x: CGFloat, _ tip: CGFloat, _ scale: CGFloat, _ hex: UInt32) {
                for layer in 0..<3 {
                    let width = (54 - CGFloat(layer) * 8) * scale
                    let top = tip + CGFloat(layer) * 28 * scale
                    var path = Path()
                    path.move(to: CGPoint(x: x / 390 * w, y: top / 844 * h))
                    path.addLine(to: CGPoint(x: (x + width / 2) / 390 * w, y: (top + 46 * scale) / 844 * h))
                    path.addLine(to: CGPoint(x: (x - width / 2) / 390 * w, y: (top + 46 * scale) / 844 * h))
                    path.closeSubpath()
                    context.fill(path, with: .color(Color(hex: hex)))
                }
            }
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x7ED06A)))
            context.fill(
                Path(box(0, 0, 390, 300)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: 0x24357A), Color(hex: 0x5C6EBE), Color(hex: 0x8AA4D4)]),
                    startPoint: CGPoint(x: w * 0.5, y: 0),
                    endPoint: CGPoint(x: w * 0.5, y: h * 300 / 844)
                )
            )
            context.fill(Path(ellipseIn: box(-30, 210, 180, 70)), with: .color(Color(hex: 0x3E8F45)))
            context.fill(Path(ellipseIn: box(120, 220, 160, 64)), with: .color(Color(hex: 0x4E9A4A)))
            context.fill(Path(ellipseIn: box(250, 200, 180, 80)), with: .color(Color(hex: 0x2F8A40)))
            pine(&context, 36, 28, 1.35, 0x245E2C)
            pine(&context, 78, 58, 1.05, 0x2F7A38)
            pine(&context, 8, 70, 0.85, 0x1E6A30)
            context.fill(Path(roundedRect: box(18, 168, 46, 28), cornerRadius: 8), with: .color(Color(hex: 0x8B5A32)))
            context.fill(Path(ellipseIn: box(12, 156, 58, 22)), with: .color(Color(hex: 0xC4A574)))
            context.fill(Path(ellipseIn: box(28, 160, 18, 8)), with: .color(Color(hex: 0xE6D2B0)))
            context.fill(Path(roundedRect: box(292, 118, 28, 168), cornerRadius: 10), with: .color(Color(hex: 0x8B5A3C)))
            context.fill(Path(ellipseIn: box(286, 150, 8, 90)), with: .color(Color(hex: 0x6E4328)))
            context.fill(Path(ellipseIn: box(210, 36, 150, 78)), with: .color(Color(hex: 0x3E9A48)))
            context.fill(Path(ellipseIn: box(250, 18, 120, 70)), with: .color(Color(hex: 0x67C15A)))
            context.fill(Path(ellipseIn: box(300, 48, 100, 64)), with: .color(Color(hex: 0x2E8B3A)))
            context.fill(Path(ellipseIn: box(236, 70, 70, 36)), with: .color(Color(hex: 0x8ED36A)))
            context.fill(Path(ellipseIn: box(248, 188, 86, 40)), with: .color(Color(hex: 0xC5B8A4)))
            context.fill(Path(ellipseIn: box(268, 176, 36, 22)), with: .color(Color(hex: 0xE7DFD2)))
            context.fill(Path(roundedRect: box(214, 214, 16, 28), cornerRadius: 6), with: .color(Color(hex: 0xF4E6C8)))
            context.fill(Path(ellipseIn: box(200, 198, 44, 26)), with: .color(Color(hex: 0xE23B3B)))
            context.fill(Path(ellipseIn: box(210, 204, 10, 8)), with: .color(Color.white))
            context.fill(Path(ellipseIn: box(226, 200, 8, 7)), with: .color(Color.white))
            context.fill(Path(roundedRect: box(262, 228, 12, 22), cornerRadius: 5), with: .color(Color(hex: 0xF4E6C8)))
            context.fill(Path(ellipseIn: box(252, 214, 30, 18)), with: .color(Color(hex: 0xF7F1E4)))
            context.fill(Path(roundedRect: box(300, 236, 14, 24), cornerRadius: 5), with: .color(Color(hex: 0xF4E6C8)))
            context.fill(Path(ellipseIn: box(290, 222, 34, 20)), with: .color(Color(hex: 0xF7F1E4)))
            let blooms: [(CGFloat, CGFloat, UInt32)] = [
                (168, 196, 0xF2A0C0), (188, 188, 0xE25B4A), (146, 210, 0xFFD56A),
                (330, 200, 0xF2A0C0), (348, 214, 0xE25B4A), (118, 230, 0xF4A0B8)
            ]
            for bloom in blooms {
                context.fill(Path(ellipseIn: box(bloom.0, bloom.1, 12, 12)), with: .color(Color(hex: bloom.2)))
                context.fill(Path(ellipseIn: box(bloom.0 + 4, bloom.1 + 4, 4, 4)), with: .color(Color(hex: 0xFFE08A)))
            }
            context.fill(Path(ellipseIn: box(-40, 300, 470, 220)), with: .color(Color(hex: 0x8ED36A)))
            context.fill(Path(ellipseIn: box(-20, 390, 440, 520)), with: .color(Color(hex: 0x7ED06A)))
            context.fill(Path(ellipseIn: box(90, 360, 210, 36)), with: .color(Color(hex: 0x6BB85A).opacity(0.35)))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct CeremonyConfetti: View {
    var active: Bool
    var reduceMotion: Bool

    var body: some View {
        if active && !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let colors: [UInt32] = [0xFF5A5A, 0x4C8DFF, 0x3DDC97, 0xFFB020, 0xC56BFF, 0xFF7AD1, 0xFFE14A]
                    for index in 0..<36 {
                        let cycle = 2.6 + Double(index % 5) * 0.22
                        let age = (time + Double(index) * 0.17).truncatingRemainder(dividingBy: cycle)
                        let progress = age / cycle
                        let x = size.width * CGFloat((index * 47) % 100) / CGFloat(100)
                        let sway = CGFloat(sin(time * 2.4 + Double(index))) * CGFloat(14)
                        let y = CGFloat(progress) * (size.height + CGFloat(30)) - CGFloat(16)
                        var piece = context
                        piece.translateBy(x: x + sway, y: y)
                        piece.rotate(by: .degrees(time * 70 + Double(index * 24)))
                        piece.opacity = 0.95
                        let w = CGFloat(index % 3 == 0 ? 7 : 12)
                        let rect = CGRect(x: -w / 2, y: -3, width: w, height: 6)
                        piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(Color(hex: colors[index % colors.count])))
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

struct RowConfetti: View {
    var token: Int
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let age = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                let origin = CGPoint(x: size.width - CGFloat(28), y: size.height / 2)
                let colors: [UInt32] = [0xFF5A5A, 0x4C8DFF, 0x3DDC97, 0xFFB020, 0xC56BFF, 0xFF7AD1, 0xFFE14A]
                let progress = min(1.0, age / 0.85)
                for index in 0..<18 {
                    let angle = Double(index) / 18 * .pi * 2
                    let distance = CGFloat(progress) * CGFloat(36 + (index % 4) * 16)
                    var piece = context
                    piece.translateBy(x: origin.x + CGFloat(cos(angle)) * distance, y: origin.y + CGFloat(sin(angle)) * distance * CGFloat(0.7))
                    piece.rotate(by: .degrees(Double(index) * 30 + age * 40))
                    piece.opacity = 1 - progress
                    let rect = CGRect(x: -5, y: -2, width: 10, height: 4)
                    piece.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(Color(hex: colors[index % colors.count])))
                }
            }
            .opacity(age > 0.9 ? 0 : 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: token) { _, _ in start = Date() }
    }
}

private struct ToastConfetti: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let colors: [UInt32] = [0xFF5A5A, 0x4C8DFF, 0xFFB020, 0x3DDC97, 0xC56BFF]
                for index in 0..<8 {
                    let progress = (time * 0.35 + Double(index) * 0.12).truncatingRemainder(dividingBy: 1)
                    let x = size.width * CGFloat(index) / CGFloat(7)
                    var piece = context
                    piece.translateBy(x: x, y: CGFloat(progress) * size.height)
                    piece.rotate(by: .degrees(Double(index) * 20))
                    piece.opacity = 1 - progress
                    piece.fill(
                        Path(roundedRect: CGRect(x: -4, y: -2, width: 8, height: 4), cornerRadius: 1),
                        with: .color(Color(hex: colors[index % colors.count]))
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
