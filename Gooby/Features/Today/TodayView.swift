import SwiftUI

enum HomeBand: String, CaseIterable {
    case morning, anytime, evening

    var titleKey: String { "home.section.\(rawValue)" }

    static func of(_ habit: Habit) -> HomeBand {
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

    var body: some View {
        let top = HomeMetrics.topInset
        ScrollView {
            VStack(spacing: 0) {
                forest(top: top)
                adventureCard
                    .padding(.top, -HomeMetrics.forestOverlap)
                goalsHeader
                    .padding(.top, 16)
                bandSection(.morning, open: $openMorning)
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
        .background(HomePalette.page.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: chooseBands)
        .sheet(isPresented: $showMenu) {
            NavigationStack { MoreScreen(engine: engine, reduceMotion: reduceMotion) }
        }
        .sheet(isPresented: $showMood) { MoodComposer(engine: engine) }
        .sheet(isPresented: $showAdventure) {
            NavigationStack { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
        }
        .overlay { SparkleOverlay(token: engine.celebration, enabled: !reduceMotion).allowsHitTesting(false) }
        .overlay(alignment: .top) { banner }
        .onChange(of: engine.celebration) { _, _ in
            hearts = true
            Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                hearts = false
            }
        }
    }

    private func forest(top: CGFloat) -> some View {
        ForestScene(reduceMotion: reduceMotion, showHearts: hearts) {
            engine.petAction(.petting)
            hearts = true
        }
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
        .background(HomePalette.card, in: RoundedRectangle(cornerRadius: HomeMetrics.cardRadius, style: .continuous))
        .padding(.horizontal, HomeMetrics.cardInset)
    }

    private var adventureCopy: (title: String, detail: String) {
        if let run = engine.todaysRun() {
            if run.status == "traveling", engine.now() < run.returnsAt {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: engine.languageCode)
                formatter.dateFormat = "HH:mm"
                let clock = formatter.string(from: run.returnsAt)
                let tomorrow = !Calendar.current.isDate(run.returnsAt, inSameDayAs: engine.now())
                let key = tomorrow ? "home.backTomorrow" : "home.backToday"
                return (engine.t("home.adventuring"), engine.tf(key, clock))
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
                HabitListScreen(engine: engine)
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
                NavigationLink {
                    HabitEditor(engine: engine, habit: nil)
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
                ForEach(habits(in: band)) { habit in
                    HomeGoalRow(engine: engine, habit: habit)
                        .padding(.horizontal, HomeMetrics.cardInset)
                }
            }
        }
    }

    private func habits(in band: HomeBand) -> [Habit] {
        engine.dueHabits(on: engine.now()).filter { HomeBand.of($0) == band }
    }

    private var addGoal: some View {
        NavigationLink {
            HabitEditor(engine: engine, habit: nil)
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
            .background(HomePalette.addGoal, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HomeMetrics.cardInset)
    }

    private func chooseBands() {
        guard !didChooseBands else { return }
        didChooseBands = true
        if habits(in: .morning).isEmpty { openAnytime = true }
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

    var body: some View {
        let key = engine.dayKey()
        let count = engine.habitLog(habit.id, key)?.count ?? 0
        let cap = max(1, habit.timesPerDay)
        let done = count >= cap
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
                        .foregroundStyle(Color(hex: 0x8E939A))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            HStack(spacing: 2) {
                Text("\(habit.energyReward)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x8E939A))
                BoltShape().fill(HomePalette.bolt).frame(width: 11, height: 15)
            }
            Button {
                engine.completeHabit(habit, on: engine.now())
            } label: {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(done ? HomePalette.check : HomePalette.iconWell)
                    .frame(width: 42, height: 42)
                    .shadow(color: Color(hex: 0xC8C8C8), radius: 0, y: 3)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(done ? Color.white : HomePalette.check)
                    }
            }
            .buttonStyle(.plain)
            .disabled(done)
            .accessibilityLabel(engine.t("home.complete"))
        }
        .padding(.leading, 10)
        .padding(.trailing, 10)
        .padding(.vertical, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: HomeMetrics.rowRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 3)
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
        .foregroundStyle(Color(hex: 0xD5D5D5))
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
