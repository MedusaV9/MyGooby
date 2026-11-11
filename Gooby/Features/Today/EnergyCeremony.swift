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

    static let redPack = ItemDef(
        id: "ceremony-red-pack",
        kind: "clothing",
        slot: "backpack",
        style: 0,
        price: 0,
        rarity: "common",
        color: "BF3D3D",
        color2: "9A3030",
        name: LocText(de: "Rucksack", en: "Pack"),
        blurb: LocText(de: "", en: ""),
        shop: "",
        starter: false,
        seasonalEvent: ""
    )
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

    func body(content: Content) -> some View {
        let current = engine.habitLog(habit.id, engine.dayKey())?.count ?? 0
        content
            .offset(y: lift)
            .opacity(fade)
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
                withAnimation(.easeIn(duration: 0.45)) {
                    lift = -76
                    fade = 0
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 460_000_000)
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
            ZStack(alignment: .topTrailing) {
                CeremonyMeadow()
                CeremonyConfetti(active: session.step != .departed, reduceMotion: reduceMotion)
                ScrollView {
                    VStack(spacing: 18) {
                        Spacer(minLength: 0)
                        character
                            .frame(height: min(CGFloat(230), geo.size.height * CGFloat(0.32)))
                        copy
                        buttons
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)
                    .frame(minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                if session.step == .reward {
                    stonePill
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                }
            }
        }
        .background(Color(hex: 0x6EBE58).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            guard session.step == .fill else { return }
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            guard !Task.isCancelled, session.step == .fill else { return }
            advance(to: .reward)
            engine.haptics.celebrate()
        }
    }

    private var character: some View {
        let departing = session.step == .departed
        var look = engine.wornLook()
        if departing { look.slots["backpack"] = EnergyCeremony.redPack }
        let pose = ceremonyPose(session.step)
        return GoobyCharacterView(
            look: look,
            stage: Growth.stage(of: engine.pet),
            animation: pose,
            reduceMotion: reduceMotion,
            companion: nil,
            showCompanion: false
        )
        .accessibilityLabel(EnergyCeremony.petName(engine))
    }

    @ViewBuilder private var copy: some View {
        if session.step == .fill || session.step == .reward {
            FillBar(
                goal: max(1, engine.profile.energyGoal),
                instant: reduceMotion || session.stoneStart == session.stoneEnd,
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
    var goal: Int
    var instant: Bool
    var maxWord: String
    @State private var fraction: CGFloat = 0.62
    @State private var showMax = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack {
                Capsule().fill(Color.white.opacity(0.28))
                HStack(spacing: 0) {
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: 0xFFD56A), Color(hex: 0xFF9A1F)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(CGFloat(18), width * fraction))
                    Spacer(minLength: 0)
                }
                Text(showMax ? maxWord : "\(min(goal, max(0, Int((fraction * CGFloat(goal)).rounded())))) / \(goal)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(showMax ? Color.white : Color(hex: 0x8A4E08))
                if showMax {
                    ZStack {
                        Circle().fill(HomePalette.bolt).frame(width: 34, height: 34)
                        BoltShape().fill(.white).frame(width: 14, height: 18)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(x: 6)
                }
            }
        }
        .frame(height: 28)
        .accessibilityLabel(showMax ? maxWord : "\(goal)")
        .onAppear {
            if instant {
                fraction = 1
                showMax = true
            }
        }
        .task {
            guard !instant else { return }
            withAnimation(.easeOut(duration: 0.9)) { fraction = 1 }
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            showMax = true
        }
    }
}

private func ceremonyPose(_ step: CeremonyStep) -> GoobyAnimation {
    switch step {
    case .fill, .reward: return .celebrate
    case .growing: return .clap
    case .departed: return .depart
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
                    animation: .clap,
                    reduceMotion: reduceMotion,
                    companion: nil,
                    showCompanion: false
                )
                .frame(width: 140, height: 110)
                .offset(y: 6)
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
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x7CC85A)))
            context.fill(
                Path(box(0, 0, 390, 360)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: 0x24357A), Color(hex: 0x6E8FD4)]),
                    startPoint: CGPoint(x: w / 2, y: 0),
                    endPoint: CGPoint(x: w / 2, y: h * CGFloat(360) / CGFloat(844))
                )
            )
            context.fill(Path(ellipseIn: box(-40, 250, 220, 90)), with: .color(Color(hex: 0x3E8F45)))
            context.fill(Path(ellipseIn: box(180, 230, 250, 110)), with: .color(Color(hex: 0x2F8A55)))
            context.fill(Path(ellipseIn: box(40, 80, 120, 70)), with: .color(Color(hex: 0x2E7450)))
            context.fill(Path(roundedRect: box(70, 130, 18, 200), cornerRadius: 8), with: .color(Color(hex: 0x8F6243)))
            context.fill(Path(ellipseIn: box(250, 150, 28, 210)), with: .color(Color(hex: 0xC08946)))
            context.fill(Path(ellipseIn: box(210, 70, 150, 80)), with: .color(Color(hex: 0x3E8F45)))
            context.fill(Path(ellipseIn: box(300, 90, 90, 60)), with: .color(Color(hex: 0x2E7450)))
            context.fill(Path(ellipseIn: box(300, 250, 70, 36)), with: .color(Color(hex: 0xC5B8A4)))
            context.fill(Path(ellipseIn: box(318, 236, 28, 22)), with: .color(Color(hex: 0xE7DFD2)))
            context.fill(Path(ellipseIn: box(292, 300, 36, 28)), with: .color(Color(hex: 0xE25B4A)))
            context.fill(Path(ellipseIn: box(286, 292, 16, 14)), with: .color(Color.white.opacity(0.85)))
            context.fill(Path(ellipseIn: box(330, 292, 22, 18)), with: .color(Color(hex: 0xF4F1EA)))
            context.fill(Path(ellipseIn: box(348, 286, 16, 14)), with: .color(Color(hex: 0xF4F1EA)))
            context.fill(Path(ellipseIn: box(0, 430, 390, 460)), with: .color(Color(hex: 0x8ED36A)))
            context.fill(Path(ellipseIn: box(-30, 560, 460, 360)), with: .color(Color(hex: 0x7CC85A)))
            let blooms: [(CGFloat, CGFloat, UInt32)] = [
                (40, 470, 0xDF5727), (90, 500, 0xFFD581), (150, 480, 0xF2A0C0), (210, 510, 0xDF5727)
            ]
            for bloom in blooms {
                let rect = box(bloom.0, bloom.1, 10, 10)
                context.fill(Path(ellipseIn: rect), with: .color(Color(hex: bloom.2)))
            }
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

private struct RowConfetti: View {
    var token: Int
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let age = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                let origin = CGPoint(x: size.width - CGFloat(36), y: size.height / 2)
                let colors: [UInt32] = [0xFF5A5A, 0x4C8DFF, 0x3DDC97, 0xFFB020, 0xC56BFF, 0xFF7AD1]
                let progress = min(1.0, age / 0.7)
                for index in 0..<12 {
                    let angle = Double(index) / 12 * .pi * 2
                    let distance = CGFloat(progress) * CGFloat(28 + (index % 4) * 12)
                    var piece = context
                    piece.translateBy(x: origin.x + CGFloat(cos(angle)) * distance, y: origin.y + CGFloat(sin(angle)) * distance * CGFloat(0.7))
                    piece.rotate(by: .degrees(Double(index) * 30 + age * 40))
                    piece.opacity = 1 - progress
                    let rect = CGRect(x: -5, y: -2, width: 10, height: 4)
                    piece.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(Color(hex: colors[index % colors.count])))
                }
            }
            .opacity(age > 0.75 ? 0 : 1)
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
