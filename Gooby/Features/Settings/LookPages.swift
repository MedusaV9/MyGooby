import SwiftUI

struct LookGoalsPage: View {
    var engine: GoobyEngine

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.goals"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                let rows = engine.habits().filter { !$0.isArchived }
                if rows.isEmpty {
                    Text(engine.t("look.goals.empty"))
                        .foregroundStyle(Look.row)
                } else {
                    LookCard {
                        VStack(spacing: 0) {
                            ForEach(Array(rows.enumerated()), id: \.element.id) { index, habit in
                                NavigationLink {
                                    HabitDetail(engine: engine, habit: habit)
                                } label: {
                                    LookNavRow(title: habit.title)
                                }
                                .buttonStyle(.plain)
                                if index < rows.count - 1 { LookDivider() }
                            }
                        }
                    }
                }
                NavigationLink {
                    HabitEditor(engine: engine, habit: nil)
                } label: {
                    Text(engine.t("habit.new"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Look.plus, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct LookActivitiesPage: View {
    var engine: GoobyEngine

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(engine.t("look.activities"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.t("look.activity.quests"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Look.section)
                let quests = engine.all(QuestRecord.self).filter { $0.kind == "daily" && $0.dayKey == engine.dayKey() }
                if quests.isEmpty {
                    Text(engine.t("look.activity.empty")).foregroundStyle(Look.row)
                }
                ForEach(quests) { quest in
                    questRow(quest)
                }
                Text(engine.t("look.activity.events"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Look.section)
                    .padding(.top, 8)
                ForEach(engine.catalog.events) { event in
                    eventBlock(event)
                }
            }
        }
        .onAppear {
            engine.recomputeQuests()
            engine.save()
        }
    }

    private func questRow(_ quest: QuestRecord) -> some View {
        let template = engine.catalog.questsByID[quest.templateID]
        return LookCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(template?.title.text(engine.languageCode) ?? quest.templateID)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                ProgressRibbon(value: Double(quest.progress) / Double(max(1, quest.goal)), tint: Color(hex: 0xFFE14A))
                Text("\(quest.progress)/\(quest.goal)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                if quest.claimed {
                    Text(engine.t("quests.claimed")).foregroundStyle(Look.sub)
                } else if quest.progress >= quest.goal {
                    Button(engine.tf("quests.claim", quest.rewardSparks)) { _ = engine.claimQuest(quest) }
                        .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                }
            }
            .padding(14)
        }
    }

    private func eventBlock(_ event: EventDef) -> some View {
        let active = engine.isEventActive(event.id)
        return LookCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title.text(engine.languageCode))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(active ? engine.t("events.active") : engine.t("events.upcoming"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                if active {
                    let record = engine.all(EventRecord.self).first { $0.eventID == event.id }
                    let claimed = record.map { engine.claimedTasks($0) } ?? []
                    ForEach(event.tasks) { task in
                        let progress = engine.eventProgress(event, task)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title.text(engine.languageCode)).foregroundStyle(Look.ink)
                            ProgressRibbon(value: Double(progress) / Double(max(1, task.goal)), tint: Color(hex: 0xFFE14A))
                            if claimed.contains(task.id) {
                                Text(engine.t("quests.claimed")).foregroundStyle(Look.sub)
                            } else if progress >= task.goal {
                                Button(engine.t("common.claim")) { _ = engine.claimEventTask(event, task) }
                                    .buttonStyle(GoobyButtonStyle(fill: Color(hex: 0xFFE14A), ink: Look.ink))
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }
}

private struct CareArea: Identifiable {
    var id: String
    var titleKey: String
    var category: String
    var icon: LookIcon.Kind
}

struct LookAreasPage: View {
    var engine: GoobyEngine
    private let areas = [
        CareArea(id: "sleep", titleKey: "look.area.sleep", category: "sleep", icon: .history),
        CareArea(id: "movement", titleKey: "look.area.movement", category: "movement", icon: .activities),
        CareArea(id: "nutrition", titleKey: "look.area.nutrition", category: "health", icon: .sprout),
        CareArea(id: "hygiene", titleKey: "look.area.hygiene", category: "hygiene", icon: .profile),
        CareArea(id: "kindness", titleKey: "look.area.kindness", category: "mindful", icon: .sparkles),
        CareArea(id: "focus", titleKey: "look.area.focus", category: "learning", icon: .insights),
        CareArea(id: "social", titleKey: "look.area.social", category: "custom", icon: .circles),
        CareArea(id: "mindful", titleKey: "look.area.mindful", category: "mindful", icon: .bell),
        CareArea(id: "home", titleKey: "look.area.home", category: "home", icon: .gift)
    ]

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.areas"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                LookCard {
                    VStack(spacing: 0) {
                        ForEach(Array(areas.enumerated()), id: \.element.id) { index, area in
                            NavigationLink {
                                LookAreaDetail(engine: engine, area: area)
                            } label: {
                                let count = engine.habits().filter { !$0.isArchived && $0.category == area.category }.count
                                LookNavRow(title: engine.t(area.titleKey), subtitle: engine.tf("look.area.count", count), icon: area.icon)
                            }
                            .buttonStyle(.plain)
                            if index < areas.count - 1 { LookDivider() }
                        }
                    }
                }
            }
        }
    }
}

private struct LookAreaDetail: View {
    var engine: GoobyEngine
    var area: CareArea

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t(area.titleKey))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                let rows = engine.habits().filter { !$0.isArchived && $0.category == area.category }
                ForEach(rows) { habit in
                    NavigationLink {
                        HabitDetail(engine: engine, habit: habit)
                    } label: {
                        LookCard { LookNavRow(title: habit.title) }
                    }
                    .buttonStyle(.plain)
                }
                NavigationLink {
                    HabitEditor(engine: engine, habit: nil)
                } label: {
                    Text(engine.t("look.area.add"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Look.plus, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct LookInsightsPage: View {
    var engine: GoobyEngine

    var body: some View {
        let runs = engine.all(AdventureRun.self).filter { $0.status == "claimed" }.count
        let completions = engine.all(HabitLog.self).filter { !$0.skipped && $0.habitID != LookMark.holdHabit }.reduce(0) { $0 + $1.count }
        let moods = engine.all(MoodEntry.self)
        let average = moods.isEmpty ? 0 : Double(moods.map(\.level).reduce(0, +)) / Double(moods.count)
        return LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.insights"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    stat(engine.t("look.insight.streak"), "\(engine.streak())")
                    stat(engine.t("look.insight.done"), "\(completions)")
                    stat(engine.t("look.insight.mood"), moods.isEmpty ? engine.t("common.none") : String(format: "%.1f", average))
                    stat(engine.t("look.insight.adventures"), "\(runs)")
                    stat(engine.t("look.insight.sparks"), "\(engine.wallet.sparks)")
                    stat(engine.t("look.insight.notes"), "\(engine.all(JournalEntry.self).count)")
                }
            }
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        LookCard(radius: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Look.row)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        }
    }
}

struct LookNewsPage: View {
    var engine: GoobyEngine
    @State private var read: Set<String> = Set(UserDefaults.standard.stringArray(forKey: LookMark.letters) ?? [])

    private var letters: [(id: String, need: Int)] {
        [("1", 0), ("2", 3), ("3", 7), ("4", 14)]
    }

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.news"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                ForEach(letters, id: \.id) { letter in
                    let open = engine.streak() >= letter.need || engine.pet.careDays >= letter.need
                    Button {
                        guard open else { return }
                        read.insert(letter.id)
                        UserDefaults.standard.set(Array(read), forKey: LookMark.letters)
                    } label: {
                        LookCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(engine.t("look.letter.\(letter.id).title"))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(Look.ink)
                                Text(open ? engine.t("look.letter.\(letter.id).body") : engine.t("look.letter.sealed"))
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(open ? Look.row : Look.sub)
                            }
                            .padding(14)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct LookHistoryPage: View {
    var engine: GoobyEngine

    private struct Row: Identifiable {
        var id: String
        var day: String
        var title: String
        var detail: String
    }

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.history"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                let rows = history
                if rows.isEmpty {
                    Text(engine.t("look.history.empty")).foregroundStyle(Look.row)
                }
                LookCard {
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Look.row)
                                Text("\(row.day) · \(row.detail)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Look.sub)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            if index < rows.count - 1 { LookDivider() }
                        }
                    }
                }
            }
        }
    }

    private var history: [Row] {
        var rows: [Row] = []
        let habits = Dictionary(uniqueKeysWithValues: engine.habits().map { ($0.id, $0.title) })
        for log in engine.all(HabitLog.self).filter({ $0.habitID != LookMark.holdHabit && $0.count > 0 }) {
            rows.append(Row(id: "h-\(log.id.uuidString)", day: log.dayKey, title: habits[log.habitID] ?? engine.t("look.history.goal"), detail: engine.t("look.history.goal")))
        }
        for mood in engine.all(MoodEntry.self) {
            rows.append(Row(id: "m-\(mood.id.uuidString)", day: mood.dayKey, title: engine.t("mood.level.\(mood.level)"), detail: engine.t("look.history.mood")))
        }
        for run in engine.all(AdventureRun.self) {
            let place = engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode) ?? engine.t("look.history.adventure")
            rows.append(Row(id: "a-\(run.id.uuidString)", day: run.dayKey, title: place, detail: engine.t("look.history.adventure")))
        }
        return rows.sorted { $0.day > $1.day }.prefix(40).map { $0 }
    }
}

struct LookCirclesPage: View {
    var engine: GoobyEngine
    var code: String
    @State private var name = ""
    @State private var circles = UserDefaults.standard.stringArray(forKey: LookMark.circles) ?? []

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.circles"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.t("look.circles.lead"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                Text(code)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                ShareLink(item: engine.tf("look.invite.share", code)) {
                    Text(engine.t("look.invite"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Look.plus)
                }
                TextField(engine.t("look.circles.placeholder"), text: $name)
                    .textFieldStyle(.roundedBorder)
                Button(engine.t("look.circles.add")) { add() }
                    .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                if circles.isEmpty {
                    Text(engine.t("look.circles.empty")).foregroundStyle(Look.sub)
                }
                ForEach(circles, id: \.self) { circle in
                    HStack {
                        Text(circle).foregroundStyle(Look.ink)
                        Spacer()
                        Button(engine.t("common.delete")) { remove(circle) }
                            .foregroundStyle(Theme.rose)
                    }
                    .padding(12)
                    .background(Look.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !circles.contains(trimmed) else { return }
        circles.append(trimmed)
        name = ""
        UserDefaults.standard.set(circles, forKey: LookMark.circles)
    }

    private func remove(_ circle: String) {
        circles.removeAll { $0 == circle }
        UserDefaults.standard.set(circles, forKey: LookMark.circles)
    }
}
