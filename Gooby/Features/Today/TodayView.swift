import SwiftUI

enum HomeBand: String, CaseIterable {
    case morning, anytime, evening

    var titleKey: String { "home.section.\(rawValue)" }

    static func of(_ habit: Habit, daypart: String?) -> HomeBand {
        switch daypart {
        case "morning": return .morning
        case "afternoon": return .anytime
        case "evening", "night": return .evening
        default: break
        }
        switch habit.category {
        case "morning", "sleep": return .morning
        case "evening": return .evening
        default: return .anytime
        }
    }
}

struct TodayView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var showMenu = false
    @State private var showMood = false
    @State private var showAdventure = false
    @State private var hearts = false
    @State private var openMorning = true
    @State private var openAnytime = false
    @State private var openEvening = true
    @State private var didChooseBands = false
    @State private var showAddGoal = false
    @State private var goalStore = GoalMetaStore()
    @State private var goalRevision = 0
    @State private var dreamLine: String?
    @State private var dreamToken = 0
    @State private var buddyDismissed = UserDefaults.standard.bool(forKey: HomeStage.buddyDismissedKey)
    @State private var buddyHasPal = false
    @State private var showFriends = false
    @State private var clockTick = 0
    @State private var ceremony = EnergyCeremonySession()

    var body: some View {
        let _ = goalRevision
        let _ = clockTick
        let kind = HomeStage.kind(engine: engine)
        let top = HomeMetrics.topInset
        ScrollView {
            VStack(spacing: 0) {
                forest(top: top)
                adventureCard
                    .padding(.top, -HomeMetrics.forestOverlap)
                goalsHeader
                    .padding(.top, 16)
                bandSection(.morning, open: $openMorning)
                if showBuddy {
                    HomeBuddyBanner(
                        title: engine.t("home.stage.buddy.title"),
                        message: engine.t("home.stage.buddy.body"),
                        actionTitle: engine.t("home.stage.buddy.action"),
                        closeLabel: engine.t("home.stage.buddy.close"),
                        fill: kind.banner,
                        onAction: { showFriends = true },
                        onClose: dismissBuddy
                    )
                    .padding(.top, 14)
                    .padding(.horizontal, HomeMetrics.cardInset)
                }
                bandSection(.anytime, open: $openAnytime)
                if !habits(in: .evening).isEmpty {
                    bandSection(.evening, open: $openEvening)
                }
                addGoal
                    .padding(.top, 18)
                    .padding(.bottom, 16)
            }
        }
        .scrollIndicators(.hidden)
        .background(kind.page.ignoresSafeArea())
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: kind)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            goalStore.load()
            GoalActions.ensureReferenceGoals(engine: engine, store: goalStore)
            goalRevision += 1
            chooseBands()
            buddyHasPal = !FriendsBook.load().pals.isEmpty
            HomeStageTone.shared.adopt(kind)
        }
        .onChange(of: kind) { _, new in
            HomeStageTone.shared.adopt(new)
        }
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(30))
                } catch {
                    return
                }
                clockTick += 1
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet(engine: engine, store: goalStore) { goalRevision += 1 }
        }
        .sheet(isPresented: $showMenu) {
            NavigationStack { MoreScreen(engine: engine, reduceMotion: reduceMotion) }
        }
        .sheet(isPresented: $showMood) { MoodComposer(engine: engine) }
        .sheet(isPresented: $showAdventure) {
            NavigationStack { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
        }
        .goobyCue(.sheet, opening: showMenu || showMood || showAdventure || showAddGoal)
        .overlay { SparkleOverlay(token: engine.celebration, enabled: !reduceMotion).allowsHitTesting(false) }
        .overlay(alignment: .top) { banner }
        .overlay(alignment: .bottom) {
            ZStack {
                if let dreamLine {
                    HomeDreamToast(text: dreamLine)
                        .padding(.bottom, 8)
                        .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .spring(duration: 0.35), value: dreamLine)
        }
        .onChange(of: engine.celebration) { _, _ in
            hearts = true
            Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                hearts = false
            }
        }
        .onChange(of: showFriends) { _, open in
            if !open { buddyHasPal = !FriendsBook.load().pals.isEmpty }
        }
        .sheet(isPresented: $showFriends) { friendsSheet }
        .modifier(EnergyCeremonyChrome(engine: engine, reduceMotion: reduceMotion, session: ceremony))
    }

    private func forest(top: CGFloat) -> some View {
        let kind = HomeStage.kind(engine: engine)
        let onTrip = HomeStage.isWalking(engine: engine)
        let animation: GoobyAnimation = hearts ? .petting : (kind == .nest ? .sleep : .hop)
        return ZStack {
            if kind == .nest {
                NestScene(
                    reduceMotion: reduceMotion,
                    look: engine.wornLook(),
                    growth: Growth.stage(of: engine.pet),
                    companion: engine.companionSpecies(),
                    animation: animation,
                    petLabel: petName,
                    petAction: engine.t("home.stage.pet.action"),
                    onTap: { stageTap() },
                    onPet: { stagePet() }
                )
                .transition(reduceMotion ? .identity : .opacity)
            } else {
                ForestScene(
                    reduceMotion: reduceMotion,
                    look: engine.wornLook(),
                    growth: Growth.stage(of: engine.pet),
                    companion: engine.companionSpecies(),
                    animation: animation,
                    walking: kind == .forest && !hearts,
                    showPack: onTrip,
                    petLabel: petName,
                    petAction: engine.t("home.stage.pet.action"),
                    onTap: { stageTap() },
                    onPet: { stagePet() }
                )
                .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: kind)
        .frame(height: HomeMetrics.forestBelowStatus + top)
        .overlay(alignment: .top) {
            HStack {
                Button { showMenu = true } label: {
                    VStack(spacing: 5) {
                        Capsule().frame(width: 22, height: 3)
                        Capsule().frame(width: 22, height: 3)
                        Capsule().frame(width: 22, height: 3)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 36)
                    .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("home.menu"))
                Spacer()
                Button { showMood = true } label: { MoodBubble() }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.t("home.mood"))
            }
            .padding(.horizontal, 16)
            .padding(.top, top + 18)
        }
    }

    private var adventureCard: some View {
        let copy = adventureCopy
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(copy.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 6)
                if !copy.detail.isEmpty {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(adventureCopy.detail)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                }
            }
            .foregroundStyle(.white)
            EnergyTrack(progress: journeyFraction, energyLabel: engine.t("home.energy"), adventureLabel: engine.t("home.adventure")) {
                showAdventure = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(HomeStage.kind(engine: engine).card, in: RoundedRectangle(cornerRadius: HomeMetrics.cardRadius, style: .continuous))
        .padding(.horizontal, HomeMetrics.cardInset)
    }

    private var adventureCopy: (title: String, detail: String) {
        if let run = engine.todaysRun() {
            if run.status == "traveling", engine.now() < run.returnsAt {
                let clock = EnergyCeremony.clock(run.returnsAt.timeIntervalSince(engine.now()))
                return (engine.t("home.adventuring"), EnergyCeremony.line(engine, "ceremony.backIn", ["clock": clock]))
            }
            return (engine.t("home.returned"), "")
        }
        if engine.wallet.energy >= engine.profile.energyGoal {
            return (engine.t("home.ready"), "")
        }
        return (engine.t("home.needEnergy"), "")
    }

    private var journeyFraction: Double {
        if let run = engine.todaysRun(), run.status == "traveling" {
            let span = run.returnsAt.timeIntervalSince(run.startedAt)
            let elapsed = engine.now().timeIntervalSince(run.startedAt)
            return min(0.92, max(0.08, elapsed / max(span, 1)))
        }
        let goal = Double(max(1, engine.profile.energyGoal))
        return min(1, max(0.08, Double(engine.wallet.energy) / goal))
    }

    private var goalsHeader: some View {
        HStack(spacing: 8) {
            CalendarGlyph()
                .frame(width: 22, height: 20)
            Text(goalsLeftText)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            NavigationLink {
                if let make = FeatureHost.shared.habitsScreen { make(engine) } else { HabitListScreen(engine: engine) }
            } label: {
                SliderGlyph().frame(width: 22, height: 18)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("home.goalsManage"))
            Button { showMood = true } label: {
                SparkGlyph().frame(width: 22, height: 18)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("home.mood"))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
    }

    private var goalsLeftText: String {
        let left = goalsLeft
        if left == 0 { return engine.t("home.goalsDone") }
        if left == 1 { return engine.t("home.goalsLeft.one") }
        return engine.tf("home.goalsLeft.many", left)
    }

    private var goalsLeft: Int {
        let key = engine.dayKey()
        return engine.dueHabits(on: engine.now()).filter { habit in
            (engine.habitLog(habit.id, key)?.count ?? 0) < max(1, habit.timesPerDay)
        }.count
    }

    private func bandSection(_ band: HomeBand, open: Binding<Bool>) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Button {
                    open.wrappedValue.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Text(engine.t(band.titleKey))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: open.wrappedValue ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .buttonStyle(.plain)
                Rectangle()
                    .fill(Color.white.opacity(0.55))
                    .frame(height: 1.5)
                Button {
                    showAddGoal = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.16), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("home.addGoal"))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.top, 12)
            if open.wrappedValue {
                ForEach(habits(in: band).filter { !ceremony.hidden.contains($0.id) }) { habit in
                    HomeGoalRow(engine: engine, habit: habit)
                        .modifier(GoalSendoff(engine: engine, habit: habit, reduceMotion: reduceMotion, session: ceremony, store: goalStore))
                        .padding(.horizontal, HomeMetrics.cardInset)
                }
                .animation(reduceMotion ? nil : .easeIn(duration: 0.35), value: ceremony.hidden)
            }
        }
    }

    private func habits(in band: HomeBand) -> [Habit] {
        engine.dueHabits(on: engine.now()).filter { HomeBand.of($0, daypart: goalStore.meta.dayparts[$0.id.uuidString]) == band }
    }

    private var addGoal: some View {
        Button {
            showAddGoal = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                Text(engine.t("home.addGoal"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(HomeStage.kind(engine: engine).action, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HomeMetrics.cardInset)
    }

    private func chooseBands() {
        guard !didChooseBands else { return }
        didChooseBands = true
        if habits(in: .morning).isEmpty { openAnytime = true }
    }

    private var showBuddy: Bool { !buddyDismissed && !buddyHasPal }

    private var petName: String {
        let raw = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Gooby" : raw
    }

    private func dismissBuddy() {
        buddyDismissed = true
        UserDefaults.standard.set(true, forKey: HomeStage.buddyDismissedKey)
    }

    private func stageTap() {
        if dreamLine != nil {
            stagePet()
        } else {
            showDream()
        }
    }

    private func stagePet() {
        dreamToken += 1
        dreamLine = nil
        engine.petAction(.petting)
        hearts = true
        Task {
            do {
                try await Task.sleep(for: .seconds(1.2))
            } catch {
                return
            }
            hearts = false
            if engine.animation == .petting {
                engine.animation = .idle
            }
        }
    }

    private func showDream() {
        let line = dreamText()
        dreamToken += 1
        let token = dreamToken
        dreamLine = line
        let announcement = AccessibilityNotification.Announcement(line)
        announcement.post()
        Task {
            do {
                try await Task.sleep(for: .seconds(2.6))
            } catch {
                return
            }
            guard token == dreamToken else { return }
            dreamLine = nil
        }
    }

    private func dreamText() -> String {
        let key: String
        if HomeStage.isWalking(engine: engine) {
            key = "home.stage.dream.walk"
        } else if HomeStage.kind(engine: engine) == .forest {
            key = "home.stage.dream.woods"
        } else {
            key = "home.stage.dream.hatch"
        }
        return engine.t(key).replacingOccurrences(of: "%@", with: petName)
    }

    private var friendsSheet: some View {
        NavigationStack {
            FriendsTreeScreen(engine: engine)
                .overlay(alignment: .topTrailing) {
                    Button {
                        showFriends = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.92), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                    .accessibilityLabel(engine.t("common.done"))
                }
        }
    }

    @ViewBuilder private var banner: some View {
        if let banner = engine.banner {
            Text(banner)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(HomePalette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.yellow, in: Capsule())
                .padding(.top, HomeMetrics.topInset + 8)
                .onAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        engine.banner = nil
                    }
                }
        }
    }
}

struct MoodBubble: View {
    var body: some View {
        ZStack {
            Circle().fill(.white).frame(width: 40, height: 40)
            Circle().fill(HomePalette.mood).frame(width: 34, height: 34)
            Circle().fill(HomePalette.eye).frame(width: 3.5, height: 3.5).offset(x: -6, y: -2)
            Circle().fill(HomePalette.eye).frame(width: 3.5, height: 3.5).offset(x: 6, y: -2)
            SmileShape()
                .stroke(HomePalette.eye, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 12, height: 6)
                .offset(y: 6)
        }
    }
}

struct EnergyTrack: View {
    var progress: Double
    var energyLabel: String
    var adventureLabel: String
    var openAdventure: () -> Void

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let travel = max(0, width - 64)
            let marker = 28 + travel * min(1, max(0, progress))
            ZStack {
                HStack(spacing: 7) {
                    ForEach(0..<18, id: \.self) { _ in
                        Capsule().fill(Color.white.opacity(0.85)).frame(width: 7, height: 4)
                    }
                }
                .padding(.horizontal, 36)
                ZStack {
                    ForEach(0..<8, id: \.self) { index in
                        Capsule()
                            .fill(Color(hex: 0xFFE08A))
                            .frame(width: 3, height: 7)
                            .offset(y: -18)
                            .rotationEffect(.degrees(Double(index) * 45))
                    }
                    Circle().fill(HomePalette.bolt).frame(width: 32, height: 32)
                    BoltShape().fill(.white).frame(width: 14, height: 18)
                }
                .position(x: 16, y: 18)
                .accessibilityLabel(energyLabel)
                TrackBunny()
                    .position(x: marker, y: 18)
                Button(action: openAdventure) {
                    ZStack {
                        Circle().fill(HomePalette.bolt).frame(width: 32, height: 32)
                        Text("?")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .position(x: width - 16, y: 18)
                .accessibilityLabel(adventureLabel)
            }
        }
        .frame(height: 36)
    }
}

struct HomeGoalRow: View {
    var engine: GoobyEngine
    var habit: Habit
    @State private var showExercise = false

    var body: some View {
        let key = engine.dayKey()
        let count = engine.habitLog(habit.id, key)?.count ?? 0
        let cap = max(1, habit.timesPerDay)
        let done = count >= cap
        let exerciseID = GoalMetaStore.peek().exercises[habit.id.uuidString] ?? ""
        let linked = !exerciseID.isEmpty
        HStack(spacing: 8) {
            grip
            ZStack {
                Circle().fill(HomePalette.iconWell).frame(width: 46, height: 46)
                HomeGlyph(symbol: habit.icon, tint: Color(hexString: habit.colorHex))
                    .frame(width: 30, height: 30)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(habit.title)
                    .font(.system(size: 15.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(HomePalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if !habit.details.isEmpty {
                    Text(habit.details)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(HomePalette.rowSub)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            HStack(spacing: 2) {
                Text(linked ? "\(habit.energyReward)+" : "\(habit.energyReward)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomePalette.rowSub)
                BoltShape().fill(HomePalette.bolt).frame(width: 11, height: 15)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(engine.tf(linked ? "care.energy.plus" : "care.energy", habit.energyReward))
            Button {
                if linked && !done {
                    showExercise = true
                } else {
                    engine.completeHabit(habit, on: engine.now())
                }
            } label: {
                if linked && !done {
                    GoalArrowKey()
                        .frame(width: 42, height: 42)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(done ? HomePalette.check : HomePalette.iconWell)
                        .frame(width: 42, height: 42)
                        .shadow(color: HomePalette.rowShade, radius: 0, y: 3)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(done ? Color.white : HomePalette.check)
                        }
                }
            }
            .buttonStyle(.plain)
            .disabled(done)
            .accessibilityLabel(linked && !done ? engine.t("care.exercise.open") : engine.t("home.complete"))
        }
        .padding(.leading, 10)
        .padding(.trailing, 10)
        .padding(.vertical, 10)
        .background(HomePalette.row, in: RoundedRectangle(cornerRadius: HomeMetrics.rowRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
        .sheet(isPresented: $showExercise) {
            GoalExerciseHost(engine: engine, exerciseID: GoalMetaStore.peek().exercises[habit.id.uuidString] ?? "") {
                engine.completeHabit(habit, on: engine.now())
            }
        }
    }

    private var grip: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 3) {
                    Circle().frame(width: 3, height: 3)
                    Circle().frame(width: 3, height: 3)
                }
            }
        }
        .foregroundStyle(HomePalette.rowGrip)
        .accessibilityHidden(true)
    }
}

struct HomeGlyph: View {
    var symbol: String
    var tint: Color

    var body: some View {
        switch symbol {
        case "bed.double.fill", "sun.max.fill", "sunrise.fill":
            SunflowerGlyph()
        case "wind", "leaf.fill":
            LeafGlyph()
        case "heart.fill", "face.smiling", "face.smiling.fill":
            SmileGlyph()
        case "cup.and.saucer.fill":
            TeaGlyph()
        case "figure.walk", "figure.flexibility":
            StretchGlyph()
        case "drop.fill":
            DropGlyph(tint: tint)
        default:
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

struct SunflowerGlyph: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x3E8F45)).frame(width: 3, height: 12).offset(y: 8)
            Ellipse().fill(Color(hex: 0x3E8F45)).frame(width: 8, height: 5).offset(x: -5, y: 6).rotationEffect(.degrees(-30))
            Ellipse().fill(Color(hex: 0x3E8F45)).frame(width: 8, height: 5).offset(x: 5, y: 6).rotationEffect(.degrees(30))
            ForEach(0..<8, id: \.self) { index in
                Ellipse().fill(Color(hex: 0xF0A020)).frame(width: 6, height: 10)
                    .offset(y: -8)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            Circle().fill(Color(hex: 0xE07A14)).frame(width: 10, height: 10)
        }
    }
}

struct LeafGlyph: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x7DCAA8)).frame(width: 18, height: 12).rotationEffect(.degrees(-30))
            Capsule().fill(Color(hex: 0x3E8F45)).frame(width: 2, height: 14).rotationEffect(.degrees(-30))
        }
    }
}

struct SmileGlyph: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xFFE08A))
            Circle().fill(HomePalette.eye).frame(width: 3, height: 3).offset(x: -5, y: -2)
            Circle().fill(HomePalette.eye).frame(width: 3, height: 3).offset(x: 5, y: -2)
            SmileShape().stroke(HomePalette.eye, style: StrokeStyle(lineWidth: 1.4, lineCap: .round)).frame(width: 10, height: 5).offset(y: 4)
        }
    }
}

struct TeaGlyph: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xD8D8D8)).frame(width: 22, height: 6).offset(y: 8)
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color(hex: 0xF4F1EA)).frame(width: 16, height: 12).offset(y: 2)
            Capsule().stroke(Color(hex: 0xC8C2B8), lineWidth: 1.5).frame(width: 6, height: 8).offset(x: 11, y: 2)
            Circle().fill(Color(hex: 0x7DCAA8)).frame(width: 8, height: 8).offset(y: -4)
        }
    }
}

struct StretchGlyph: View {
    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xE0A15A)).frame(width: 4, height: 16).offset(y: 2)
            Circle().fill(Color(hex: 0xE0A15A)).frame(width: 8, height: 8).offset(y: -10)
            Capsule().fill(Color(hex: 0xE0A15A)).frame(width: 12, height: 3).offset(y: -2).rotationEffect(.degrees(-20))
            Capsule().fill(Color(hex: 0xE0A15A)).frame(width: 12, height: 3).offset(y: -2).rotationEffect(.degrees(20))
        }
    }
}

struct DropGlyph: View {
    var tint: Color
    var body: some View {
        Circle().fill(tint).frame(width: 16, height: 16).overlay(alignment: .top) {
            Circle().fill(Color.white.opacity(0.7)).frame(width: 5, height: 5).offset(y: 3)
        }
    }
}

struct CalendarGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color.white, lineWidth: 1.6)
            Capsule().fill(Color.white).frame(width: 1.6, height: 5).offset(x: -5, y: -8)
            Capsule().fill(Color.white).frame(width: 1.6, height: 5).offset(x: 5, y: -8)
            HStack(spacing: 3) {
                Circle().frame(width: 2, height: 2)
                Circle().frame(width: 2, height: 2)
            }
            .foregroundStyle(.white)
            .offset(y: 2)
        }
    }
}

struct SliderGlyph: View {
    var body: some View {
        VStack(spacing: 3) {
            slider(knob: -4)
            slider(knob: 4)
            slider(knob: 0)
        }
    }

    private func slider(knob: CGFloat) -> some View {
        ZStack {
            Capsule().fill(Color.white).frame(height: 1.6)
            Circle().fill(Color.white).frame(width: 5, height: 5).offset(x: knob)
        }
    }
}

struct SparkGlyph: View {
    var body: some View {
        ZStack {
            Circle().frame(width: 4, height: 4).offset(x: -5, y: -4)
            Circle().frame(width: 4, height: 4).offset(x: 5, y: -4)
            Circle().frame(width: 4, height: 4).offset(x: -5, y: 4)
            Circle().frame(width: 3, height: 3).offset(x: 6, y: 5)
            Circle().frame(width: 2, height: 2).offset(x: 1, y: 0)
        }
        .foregroundStyle(.white)
    }
}

struct HabitRow: View {
    var engine: GoobyEngine
    var habit: Habit
    var day: Date

    var body: some View {
        let key = DayKey.make(day)
        let log = engine.habitLog(habit.id, key)
        let count = log?.count ?? 0
        let cap = max(1, habit.timesPerDay)
        HStack(spacing: 12) {
            Image(systemName: habit.icon)
                .frame(width: 42, height: 42)
                .background(Color(hexString: habit.colorHex), in: Circle())
                .foregroundStyle(Theme.ink)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                if !habit.details.isEmpty {
                    Text(habit.details).font(.system(.caption, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.65)).lineLimit(2)
                }
                Text(engine.tf("habit.progress", count, cap)).font(.system(.caption, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.65))
            }
            Spacer()
            Button {
                engine.completeHabit(habit, on: day)
            } label: {
                Image(systemName: count >= cap ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(count >= cap ? Color(hex: 0x7DCAA8) : Theme.ink.opacity(0.35))
            }
            .disabled(count >= cap)
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
