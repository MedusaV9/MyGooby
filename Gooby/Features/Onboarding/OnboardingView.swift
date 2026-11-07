import SwiftUI

struct OnboardingView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var step = 0
    @State private var nickname = ""
    @State private var goobyName = "Gooby"
    @State private var goals: Set<String> = []
    @State private var chosen: Set<String> = ["water", "bed", "walk"]
    @State private var created: [Habit] = []
    @State private var finished = false
    @State private var rewardText = ""

    private let goalIDs = ["care", "sleep", "habits", "move", "stress", "motivation", "organize", "mood", "mindful"]
    private let suggestions: [(String, String, String, String)] = [
        ("water", "drop.fill", "hygiene", "onb.habit.water"),
        ("bed", "bed.double.fill", "morning", "onb.habit.bed"),
        ("teeth", "sparkles", "hygiene", "onb.habit.teeth"),
        ("walk", "figure.walk", "movement", "onb.habit.walk"),
        ("relax", "wind", "mindful", "onb.habit.relax"),
        ("note", "pencil", "creative", "onb.habit.note")
    ]

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                ForEach(0..<6, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Theme.rose : Theme.ink.opacity(0.12))
                        .frame(height: 6)
                }
            }
            .padding(.top, 12)
            GoobyCharacterView(
                look: WornLook(),
                stage: "baby",
                animation: step == 5 && finished ? .celebrate : .idle,
                reduceMotion: reduceMotion,
                companion: nil
            )
            .frame(height: 230)
            Group {
                switch step {
                case 0: welcome
                case 1: nickStep
                case 2: goalStep
                case 3: nameStep
                case 4: habitStep
                default: firstTask
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .goobyScreen()
    }

    private var welcome: some View {
        VStack(spacing: 14) {
            Text(engine.t("onb.welcome.title"))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(engine.t("onb.welcome.body"))
                .foregroundStyle(Theme.ink.opacity(0.75))
                .multilineTextAlignment(.center)
            Button(engine.t("onb.welcome.go")) { step = 1 }
                .buttonStyle(GoobyButtonStyle(fill: Theme.rose, ink: Theme.ink))
        }
    }

    private var nickStep: some View {
        VStack(spacing: 14) {
            Text(engine.t("onb.nick.title")).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
            TextField(engine.t("onb.nick.placeholder"), text: $nickname)
                .textFieldStyle(.roundedBorder)
            Button(engine.t("common.continue")) { step = 2 }
                .buttonStyle(GoobyButtonStyle())
            Button(engine.t("common.skip")) { nickname = ""; step = 2 }
                .foregroundStyle(Theme.ink.opacity(0.7))
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(engine.t("onb.goals.title")).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
            Text(engine.t("onb.goals.subtitle")).foregroundStyle(Theme.ink.opacity(0.7))
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(goalIDs, id: \.self) { id in
                        Button {
                            if goals.contains(id) { goals.remove(id) } else { goals.insert(id) }
                        } label: {
                            HStack {
                                Text(engine.t("onb.goal.\(id)")).foregroundStyle(Theme.ink)
                                Spacer()
                                Image(systemName: goals.contains(id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Theme.rose)
                            }
                            .padding(12)
                            .background(Theme.pink.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 280)
            Button(engine.t("common.continue")) { step = 3 }.buttonStyle(GoobyButtonStyle())
            Button(engine.t("common.skip")) { goals = []; step = 3 }.foregroundStyle(Theme.ink.opacity(0.7))
        }
    }

    private var nameStep: some View {
        VStack(spacing: 14) {
            Text(engine.t("onb.name.title")).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
            TextField(engine.t("onb.name.placeholder"), text: $goobyName).textFieldStyle(.roundedBorder)
            Button(engine.t("common.continue")) {
                if goobyName.trimmingCharacters(in: .whitespaces).isEmpty { goobyName = "Gooby" }
                step = 4
            }
            .buttonStyle(GoobyButtonStyle())
            Button(engine.t("common.skip")) { goobyName = "Gooby"; step = 4 }.foregroundStyle(Theme.ink.opacity(0.7))
        }
    }

    private var habitStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(engine.t("onb.habits.title")).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
            Text(engine.t("onb.habits.subtitle")).foregroundStyle(Theme.ink.opacity(0.7))
            ForEach(suggestions, id: \.0) { item in
                Button {
                    if chosen.contains(item.0) { chosen.remove(item.0) } else { chosen.insert(item.0) }
                } label: {
                    HStack {
                        Image(systemName: item.1).foregroundStyle(Theme.ink)
                        Text(engine.t(item.3)).foregroundStyle(Theme.ink)
                        Spacer()
                        Image(systemName: chosen.contains(item.0) ? "checkmark.circle.fill" : "circle").foregroundStyle(Theme.rose)
                    }
                    .padding(12)
                    .background(Theme.mint.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            Button(engine.t("common.continue")) { prepareTasks(); step = 5 }.buttonStyle(GoobyButtonStyle())
            Button(engine.t("common.skip")) { chosen = []; prepareTasks(); step = 5 }.foregroundStyle(Theme.ink.opacity(0.7))
        }
    }

    private var firstTask: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(engine.t("onb.first.title")).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
            Text(engine.t("onb.first.body")).foregroundStyle(Theme.ink.opacity(0.75))
            if finished {
                SoftCard(fill: Theme.yellow.opacity(0.7)) {
                    Text(rewardText).foregroundStyle(Theme.ink)
                    Text(engine.tf("onb.first.reward", engine.wallet.energy, engine.wallet.sparks))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
                Button(engine.t("onb.first.home")) { finishOnboarding() }.buttonStyle(GoobyButtonStyle(fill: Theme.rose, ink: Theme.ink))
            } else {
                ForEach(created) { habit in
                    Button {
                        engine.completeHabit(habit, on: engine.now())
                        rewardText = habit.title
                        finished = true
                    } label: {
                        HStack {
                            Image(systemName: habit.icon)
                            Text(habit.title)
                            Spacer()
                            Text(engine.t("today.complete"))
                        }
                        .foregroundStyle(Theme.ink)
                        .padding(12)
                        .background(Theme.peach, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func prepareTasks() {
        guard created.isEmpty else { return }
        engine.profile.nickname = nickname.trimmingCharacters(in: .whitespaces)
        engine.profile.goobyName = goobyName.trimmingCharacters(in: .whitespaces).isEmpty ? "Gooby" : goobyName
        engine.profile.goals = goalIDs.filter { goals.contains($0) }
        engine.save()
        let picked = suggestions.filter { chosen.contains($0.0) }
        if picked.isEmpty {
            let habit = engine.makeHabit(title: engine.t("onb.greeting.title"), details: engine.t("onb.greeting.detail"), icon: "heart.fill", category: "mindful", dailyGoal: true)
            created = [habit]
        } else {
            for (index, item) in picked.enumerated() {
                let habit = engine.makeHabit(
                    title: engine.t(item.3),
                    details: engine.t(item.3 + ".detail"),
                    icon: item.1,
                    category: item.2,
                    dailyGoal: index == 0
                )
                created.append(habit)
            }
        }
    }

    private func finishOnboarding() {
        engine.profile.onboardingDone = true
        engine.profile.nickname = nickname.trimmingCharacters(in: .whitespaces)
        engine.profile.goobyName = goobyName
        engine.save()
        engine.rescheduleNotifications()
    }
}
