import SwiftUI

struct TodayView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var showRoom = false
    @State private var showMood = false
    @State private var showCalm = false
    @State private var showAdventure = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if let room = FeatureHost.shared.roomScreen {
                    room(engine).frame(height: 360)
                } else {
                    RoomDiorama(engine: engine, reduceMotion: reduceMotion)
                        .frame(height: 360)
                        .onTapGesture { engine.petAction(.laugh) }
                }
                HStack {
                    TinyIconButton(title: engine.t("today.pet"), symbol: "hand.draw.fill", fill: Theme.pink) { engine.petAction(.petting) }
                    TinyIconButton(title: engine.t("today.laugh"), symbol: "face.smiling.fill", fill: Theme.yellow) { engine.petAction(.laugh) }
                    TinyIconButton(title: engine.t("today.hearts"), symbol: "heart.fill", fill: Theme.lavender) { engine.petAction(.hearts) }
                }
                energyCard
                adventureCard
                if let goal = engine.habits().first(where: { $0.isDailyGoal && !($0.isArchived) }) {
                    dailyGoal(goal)
                }
                taskSection
                Button(engine.t("today.pause")) { showCalm = true }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.sky, ink: Theme.ink))
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.profile.goobyName)
        .toolbar {
            Button { showRoom = true } label: { Image(systemName: "sofa.fill") }
            Button { showMood = true } label: { Image(systemName: "face.smiling") }
        }
        .sheet(isPresented: $showRoom) {
            if let room = FeatureHost.shared.roomScreen { room(engine) } else { RoomEditorSheet(engine: engine) }
        }
        .sheet(isPresented: $showMood) {
            if let mood = FeatureHost.shared.moodScreen { mood(engine) } else { MoodComposer(engine: engine) }
        }
        .sheet(isPresented: $showCalm) { NavigationStack { CalmScreen(engine: engine, reduceMotion: reduceMotion) } }
        .sheet(isPresented: $showAdventure) { NavigationStack { WorldScreen(engine: engine, reduceMotion: reduceMotion) } }
        .overlay { SparkleOverlay(token: engine.celebration, enabled: !reduceMotion).allowsHitTesting(false) }
        .overlay(alignment: .top) { banner }
    }

    private var header: some View {
        SoftCard(fill: Theme.pink.opacity(0.55)) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(engine.formatDate(engine.now()))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                HStack {
                    Label("\(engine.wallet.sparks)", systemImage: "sparkle")
                    Label(engine.tf("today.streak", engine.streak()), systemImage: "flame.fill")
                    Spacer()
                    let progress = engine.todayProgress()
                    Text(engine.tf("today.progress", progress.done, progress.total))
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.ink)
                ProgressRibbon(value: engine.todayProgress().total == 0 ? 0 : Double(engine.todayProgress().done) / Double(engine.todayProgress().total))
            }
        }
    }

    private var greeting: String {
        let name = engine.profile.nickname
        if name.isEmpty { return engine.tf("today.hello.noname", engine.profile.goobyName) }
        return engine.tf("today.hello", name, engine.profile.goobyName)
    }

    private var energyCard: some View {
        SoftCard(fill: Theme.mint.opacity(0.75)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(engine.t("today.energy")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                ProgressRibbon(value: Double(engine.wallet.energy) / Double(max(1, engine.profile.energyGoal)), tint: Color(hex: 0x7DCAA8))
                Text(engine.tf("today.energy.goal", engine.wallet.energy, engine.profile.energyGoal))
                    .foregroundStyle(Theme.ink.opacity(0.75))
            }
        }
    }

    private var adventureCard: some View {
        SoftCard(fill: Theme.lavender.opacity(0.65)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(adventureTitle).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                Text(adventureDetail).foregroundStyle(Theme.ink.opacity(0.75))
                Button(engine.t("today.adventure.open")) { showAdventure = true }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.ink))
            }
        }
    }

    private var adventureTitle: String {
        guard let run = engine.todaysRun() else {
            return engine.wallet.energy >= engine.profile.energyGoal ? engine.t("today.adventure.readyToStart") : engine.t("adventure.needEnergy")
        }
        if run.status == "claimed" { return engine.t("today.adventure.done") }
        if run.status == "ready" || engine.now() >= run.returnsAt { return engine.t("today.adventure.returned") }
        return engine.t("today.adventure.traveling")
    }

    private var adventureDetail: String {
        guard let run = engine.todaysRun(), run.status == "traveling", engine.now() < run.returnsAt else { return engine.t("today.adventure.hint") }
        let minutes = max(1, Int(run.returnsAt.timeIntervalSince(engine.now()) / 60))
        return engine.tf("today.adventure.minutes", minutes)
    }

    private func dailyGoal(_ habit: Habit) -> some View {
        SoftCard(fill: Theme.yellow.opacity(0.75)) {
            VStack(alignment: .leading, spacing: 6) {
                Text(engine.t("today.dailyGoal")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                Text(habit.title).foregroundStyle(Theme.ink)
                Text(engine.t("today.goal.bonus")).font(.system(.caption, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.7))
            }
        }
    }

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(engine.t("today.tasks")).font(.system(.title3, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
                Spacer()
                NavigationLink(engine.t("today.add")) { HabitEditor(engine: engine, habit: nil) }
            }
            let due = engine.dueHabits(on: engine.now())
            if due.isEmpty {
                Text(engine.t("today.tasks.empty")).foregroundStyle(Theme.ink.opacity(0.7))
            }
            ForEach(due) { habit in
                HabitRow(engine: engine, habit: habit, day: engine.now())
            }
        }
    }

    @ViewBuilder private var banner: some View {
        if let banner = engine.banner {
            Text(banner)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.yellow, in: Capsule())
                .padding(.top, 8)
                .onAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        engine.banner = nil
                    }
                }
        }
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
