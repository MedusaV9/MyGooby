import SwiftUI

struct WideHomeBoard: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var night: Bool
    var openBag: () -> Void
    @State private var showMenu = false
    @State private var showMood = false
    @State private var showAdventure = false
    @State private var hearts = false
    @State private var goalStore = GoalMetaStore()
    @State private var goalRevision = 0
    @State private var covered: CGFloat = 0

    var body: some View {
        let _ = goalRevision
        GeometryReader { geo in
            let glance = geo.size.width > 980 ? GoobySize.glanceRailWidth : min(GoobySize.glanceRailWidth, 252)
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: GoobySize.sceneBand - HomeMetrics.boardOverlap)
                        .allowsHitTesting(false)
                    HStack(alignment: .top, spacing: 14) {
                        centerColumn
                        sideColumn
                            .frame(width: glance)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 22)
                    .background(page)
                }
                .background(alignment: .top) {
                    scene
                        .frame(height: GoobySize.sceneBand)
                        .overlay {
                            Color.black
                                .opacity(HomeMotion.scrim(covered: covered))
                                .allowsHitTesting(false)
                        }
                        .offset(y: HomeMotion.pinOffset(covered: covered, reduceMotion: reduceMotion))
                        .animation(nil, value: covered)
                }
                .background { HomeScrollProbe() }
            }
            .scrollIndicators(.hidden)
            .modifier(HomeScrollTracking(covered: $covered))
        }
        .background(page.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showMenu) {
            NavigationStack { MoreScreen(engine: engine, reduceMotion: reduceMotion) }
                .goobyFormSheet()
        }
        .sheet(isPresented: $showMood) {
            MoodComposer(engine: engine)
                .goobyFormSheet()
        }
        .sheet(isPresented: $showAdventure) {
            NavigationStack { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
                .goobyFormSheet()
        }
        .overlay { SparkleOverlay(token: engine.celebration, enabled: !reduceMotion).allowsHitTesting(false) }
        .overlay(alignment: .top) { banner }
        .modifier(HomeSparkChrome(engine: engine, reduceMotion: reduceMotion, top: 14, trailing: 72))
        .onAppear {
            goalStore.load()
            GoalActions.ensureReferenceGoals(engine: engine, store: goalStore)
            goalRevision += 1
        }
        .onChange(of: engine.celebration) { _, _ in
            hearts = true
            Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                hearts = false
            }
        }
    }

    private var page: Color { night ? Color(hex: 0x17141F) : HomePalette.page }
    private var cardFill: Color { night ? Color(hex: 0x2A2438) : HomePalette.card }
    private var paper: Color { night ? Color(hex: 0x2C2642) : Color(hex: 0xFFF6E6) }
    private var ink: Color { night ? .white : HomePalette.ink }
    private var vibeInk: Color { night ? Color(hex: 0xF0E4FF) : Color(hex: 0x7A58D0) }
    private var inviteFill: Color { night ? Color(hex: 0x5A3C86) : Color(hex: 0x3EAE56) }

    private var scene: some View {
        ZStack {
            if night {
                NestScene(
                    reduceMotion: reduceMotion,
                    look: engine.wornLook(),
                    growth: Growth.stage(of: engine.pet),
                    companion: engine.companionSpecies(),
                    animation: hearts ? .petting : .sleep,
                    petLabel: petName,
                    petAction: engine.t("home.stage.pet.action"),
                    onTap: pet,
                    onPet: pet
                )
                .transition(reduceMotion ? .identity : .opacity)
            } else {
                DayForestBanner(reduceMotion: reduceMotion, hearts: hearts) {
                    pet()
                }
                .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.65), value: night)
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, page], startPoint: .top, endPoint: .bottom)
                .frame(height: 54)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            Button { showMenu = true } label: {
                VStack(spacing: 5) {
                    Capsule().frame(width: 22, height: 3)
                    Capsule().frame(width: 22, height: 3)
                    Capsule().frame(width: 22, height: 3)
                }
                .foregroundStyle(.white)
                .frame(width: 44, height: 36)
                .background(Color.black.opacity(night ? 0.28 : 0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("home.menu"))
            .padding(.leading, 16)
            .padding(.top, 14)
        }
        .overlay(alignment: .topTrailing) {
            Button { showMood = true } label: { MoodBubble() }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("home.mood"))
                .padding(.trailing, 16)
                .padding(.top, 12)
        }
        .clipped()
    }

    private var petName: String {
        let raw = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Gooby" : raw
    }

    private func pet() {
        engine.petAction(.petting)
        hearts = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            hearts = false
        }
    }

    private var centerColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            adventureCard
            goalsHeader
            if habits.isEmpty {
                Text(engine.t("today.tasks.empty"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
            } else {
                ForEach(habits) { habit in
                    HomeGoalRow(engine: engine, habit: habit)
                }
            }
        }
    }

    private var adventureCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let copy = adventureCopy
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(copy.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 6)
                    if !copy.detail.isEmpty {
                        Text(copy.detail)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
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
            .background(cardFill, in: RoundedRectangle(cornerRadius: HomeMetrics.cardRadius, style: .continuous))
        }
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
                habitsRoot
                    .goobyReadableColumn()
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
        .padding(.horizontal, 4)
    }

    @ViewBuilder private var habitsRoot: some View {
        if let make = FeatureHost.shared.habitsScreen { make(engine) } else { HabitListScreen(engine: engine) }
    }

    private var sideColumn: some View {
        VStack(spacing: 12) {
            vibeCard
            weekCard
            if let friend = ownedFriend {
                micropetCard(friend)
            } else {
                inviteCard
            }
        }
    }

    private var vibeCard: some View {
        let mood = todayMood
        let level = mood.map { min(5, max(1, $0.level)) } ?? 4
        return Button { showMood = true } label: {
            VStack(spacing: 8) {
                Text(engine.t("pad.vibe"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(ink)
                GlanceFace(level: level)
                Text(mood == nil ? engine.t("pad.vibe.empty") : engine.t("pad.vibe.\(level)"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(vibeInk)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .topTrailing) { leaf.padding(12) }
            .overlay(alignment: .topLeading) { leaf.padding(12).scaleEffect(x: -1) }
        }
        .buttonStyle(.plain)
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .bold))
                Text(engine.t("pad.week"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(ink)
            HStack(spacing: 0) {
                ForEach(weekDots) { dot in
                    VStack(spacing: 6) {
                        weekMark(dot)
                        Text(dot.label)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(ink.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(dot.access)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topTrailing) { leaf.padding(12) }
    }

    private var inviteCard: some View {
        let friend = featuredFriend
        let name = friend?.name.text(engine.languageCode) ?? engine.t("pad.micropet")
        return ShareLink(item: engine.tf("look.invite.share", GoobyFriendCode.make(profileID: engine.profile.id))) {
            HStack(spacing: 10) {
                MiniFriendBadge(species: friend?.id ?? "fox")
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.tf("pad.invite.title", name))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text(engine.t("pad.invite.body"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(.white)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(inviteFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func micropetCard(_ friend: MiniFriend) -> some View {
        let name = friendTitle(friend)
        return Button(action: openBag) {
            HStack(spacing: 10) {
                MiniFriendBadge(species: friend.speciesID)
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text(engine.t("pad.micropet"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .opacity(0.85)
                    Text(name)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .frame(height: 8)
                }
                .foregroundStyle(.white)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(inviteFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(engine.t("pad.micropet")), \(name)")
    }

    private var leaf: some View {
        Ellipse()
            .fill(night ? Color(hex: 0xB9A4E8).opacity(0.55) : HomePalette.canopy.opacity(0.85))
            .frame(width: 16, height: 9)
            .rotationEffect(.degrees(-28))
            .accessibilityHidden(true)
    }

    private func weekMark(_ dot: WeekDot) -> some View {
        ZStack {
            switch dot.kind {
            case .done:
                Circle().fill(Color(hex: 0x3CB54A))
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            case .today:
                Circle().fill(night ? Color(hex: 0x6E5CB8) : Color.white)
                Circle().stroke(night ? Color.clear : HomePalette.ink.opacity(0.2), lineWidth: 1.5)
                if night {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            case .open:
                Circle().fill(night ? Color.white.opacity(0.08) : Color.white)
                Circle().stroke(night ? Color.white.opacity(0.28) : Color(hex: 0xD9D3C8), lineWidth: 1.5)
            }
        }
        .frame(width: 28, height: 28)
    }

    private var habits: [Habit] {
        engine.dueHabits(on: engine.now())
    }

    private var goalsLeft: Int {
        let key = engine.dayKey()
        return habits.filter { habit in
            (engine.habitLog(habit.id, key)?.count ?? 0) < max(1, habit.timesPerDay)
        }.count
    }

    private var goalsLeftText: String {
        let left = goalsLeft
        if left == 0 { return engine.t("home.goalsDone") }
        if left == 1 { return engine.t("home.goalsLeft.one") }
        return engine.tf("home.goalsLeft.many", left)
    }

    private var adventureCopy: (title: String, detail: String) {
        if let run = engine.todaysRun() {
            if run.status == "traveling", engine.now() < run.returnsAt {
                let tomorrow = !Calendar.current.isDate(run.returnsAt, inSameDayAs: engine.now())
                if tomorrow {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: engine.languageCode)
                    formatter.dateFormat = "HH:mm"
                    return (engine.t("home.adventuring"), engine.tf("home.backTomorrow", formatter.string(from: run.returnsAt)))
                }
                let remain = max(0, Int(run.returnsAt.timeIntervalSince(engine.now())))
                return (engine.t("home.adventuring"), engine.tf("pad.backIn", clock(remain)))
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

    private var todayMood: MoodEntry? {
        let key = engine.dayKey()
        return engine.all(MoodEntry.self)
            .filter { $0.dayKey == key }
            .max { $0.recordedAt < $1.recordedAt }
    }

    private var ownedFriend: MiniFriend? {
        let friends = engine.all(MiniFriend.self)
        if let companion = friends.first(where: \.isCompanion) { return companion }
        return friends.max { $0.hatchedAt < $1.hatchedAt }
    }

    private var featuredFriend: FriendDef? {
        let pool = engine.catalog.friends
        guard !pool.isEmpty else { return nil }
        let index = Int(engine.profile.appSeed.magnitude % UInt64(pool.count))
        return pool[index]
    }

    private func friendTitle(_ friend: MiniFriend) -> String {
        if !friend.givenName.isEmpty { return friend.givenName }
        return engine.catalog.friendsByID[friend.speciesID]?.name.text(engine.languageCode) ?? friend.speciesID
    }

    private var weekDots: [WeekDot] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: engine.now())
        let weekday = calendar.component(.weekday, from: today)
        let delta = (weekday - calendar.firstWeekday + 7) % 7
        guard let start = calendar.date(byAdding: .day, value: -delta, to: today) else { return [] }
        var labels = calendar
        labels.locale = Locale(identifier: engine.languageCode)
        let symbols = labels.shortWeekdaySymbols
        let done = Set(engine.all(HabitLog.self).filter { !$0.skipped && $0.count > 0 }.map(\.dayKey))
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let key = DayKey.make(day)
            let symbolIndex = max(0, calendar.component(.weekday, from: day) - 1)
            let label = symbols.indices.contains(symbolIndex) ? symbols[symbolIndex].replacingOccurrences(of: ".", with: "") : ""
            let kind: WeekDot.Kind
            if done.contains(key) {
                kind = .done
            } else if calendar.isDate(day, inSameDayAs: today) {
                kind = .today
            } else {
                kind = .open
            }
            let access: String
            switch kind {
            case .done: access = "\(label), \(engine.t("pad.week.done"))"
            case .today: access = "\(label), \(engine.t("pad.week.today"))"
            case .open: access = label
            }
            return WeekDot(id: key, label: label, kind: kind, access: access)
        }
    }

    private func clock(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, secs) }
        return String(format: "%d:%02d", minutes, secs)
    }

    @ViewBuilder private var banner: some View {
        if let banner = engine.banner {
            Text(banner)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(HomePalette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.yellow, in: Capsule())
                .padding(.top, 12)
                .onAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        engine.banner = nil
                    }
                }
        }
    }
}

private struct WeekDot: Identifiable {
    enum Kind { case done, today, open }
    var id: String
    var label: String
    var kind: Kind
    var access: String
}

private struct GlanceFace: View {
    var level: Int

    var body: some View {
        ZStack {
            Circle().fill(HomePalette.mood)
            Circle().fill(HomePalette.eye).frame(width: 5, height: 5).offset(x: -8, y: -3)
            Circle().fill(HomePalette.eye).frame(width: 5, height: 5).offset(x: 8, y: -3)
            mouth
        }
        .frame(width: 54, height: 54)
    }

    @ViewBuilder private var mouth: some View {
        if level <= 2 {
            SmileShape()
                .stroke(HomePalette.eye, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 16, height: 8)
                .rotationEffect(.degrees(180))
                .offset(y: 10)
        } else if level == 3 {
            Capsule()
                .fill(HomePalette.eye)
                .frame(width: 14, height: 2.5)
                .offset(y: 8)
        } else {
            SmileShape()
                .stroke(HomePalette.eye, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 16, height: 8)
                .offset(y: 8)
        }
    }
}

private struct DayForestBanner: View {
    var reduceMotion: Bool
    var hearts: Bool
    var pet: () -> Void

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let sceneWidth = min(geo.size.width * 0.62, height * 390 / 428)
            HStack(spacing: 0) {
                DaySideGrove()
                ForestScene(reduceMotion: reduceMotion, showHearts: hearts, pet: pet)
                    .frame(width: sceneWidth, height: height)
                DaySideGrove()
                    .scaleEffect(x: -1, y: 1)
            }
        }
        .background(HomePalette.sky)
    }
}

private struct DaySideGrove: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            ZStack {
                HomePalette.sky
                Circle()
                    .fill(HomePalette.moon)
                    .frame(width: 42, height: 42)
                    .position(x: width * 0.3, y: height * 0.16)
                pine(scale: 1.15)
                    .position(x: width * 0.28, y: height * 0.46)
                pine(scale: 0.82)
                    .position(x: width * 0.62, y: height * 0.42)
                Ellipse()
                    .fill(HomePalette.canopy)
                    .frame(width: width * 0.72, height: height * 0.22)
                    .position(x: width * 0.48, y: height * 0.58)
                HomePalette.page
                    .frame(height: height * 0.32)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private func pine(scale: CGFloat) -> some View {
        VStack(spacing: -10) {
            Triangle().fill(HomePalette.pine).frame(width: 58 * scale, height: 48 * scale)
            Triangle().fill(HomePalette.pineDeep).frame(width: 70 * scale, height: 52 * scale)
            Capsule().fill(HomePalette.trunk).frame(width: 10 * scale, height: 26 * scale)
        }
    }
}

