import SwiftUI

struct HabitListScreen: View {
    var engine: GoobyEngine
    @State private var query = ""
    @State private var showArchive = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                TextField(engine.t("common.search"), text: $query)
                    .textFieldStyle(.roundedBorder)
                ForEach(visible) { habit in
                    NavigationLink {
                        HabitDetail(engine: engine, habit: habit)
                    } label: {
                        HabitRow(engine: engine, habit: habit, day: engine.now())
                    }
                    .buttonStyle(.plain)
                }
                NavigationLink(engine.t("habit.new")) { HabitEditor(engine: engine, habit: nil) }
                    .buttonStyle(GoobyButtonStyle())
                Button(engine.t("habit.archive")) { showArchive = true }
                    .foregroundStyle(Theme.ink.opacity(0.7))
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("tab.habits"))
        .sheet(isPresented: $showArchive) { ArchiveScreen(engine: engine) }
    }

    private var visible: [Habit] {
        engine.habits().filter { habit in
            !habit.isArchived && (query.isEmpty || habit.title.localizedCaseInsensitiveContains(query))
        }
    }
}

struct ArchiveScreen: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(engine.habits().filter(\.isArchived)) { habit in
                    Button(habit.title) {
                        habit.isArchived = false
                        engine.save()
                    }
                }
            }
            .navigationTitle(engine.t("common.archived"))
            .toolbar { Button(engine.t("common.done")) { dismiss() } }
        }
    }
}

struct HabitDetail: View {
    var engine: GoobyEngine
    var habit: Habit
    @State private var day = Date()
    @State private var moveDay = Date()
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HabitRow(engine: engine, habit: habit, day: day)
                Text(habit.details).foregroundStyle(Theme.ink.opacity(0.75))
                Text(engine.t("cat.\(habit.category)") + " · " + engine.t("recur.\(habit.recurrence)"))
                    .foregroundStyle(Theme.ink.opacity(0.65))
                DatePicker(engine.t("habit.backfill"), selection: $day, displayedComponents: .date)
                HStack {
                    Button(engine.t("habit.undo")) { engine.undoHabit(habit, on: day) }
                    Button(engine.t("habit.skip")) { engine.skipHabit(habit, on: day) }
                    Button(habit.isPaused ? engine.t("habit.resume") : engine.t("habit.pause")) {
                        habit.isPaused.toggle()
                        engine.save()
                    }
                }
                .buttonStyle(.bordered)
                DatePicker(engine.t("habit.moveTo"), selection: $moveDay, displayedComponents: .date)
                Button(engine.t("habit.move")) { engine.moveHabit(habit, from: day, to: moveDay) }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
                if engine.activeEgg(for: habit.id) == nil {
                    Button(engine.t("egg.bind")) { engine.bindEgg(to: habit) }
                        .buttonStyle(GoobyButtonStyle(fill: Theme.yellow, ink: Theme.ink))
                } else if let egg = engine.activeEgg(for: habit.id) {
                    Text(engine.tf("egg.progress", egg.progress, egg.requiredCount)).foregroundStyle(Theme.ink)
                    ProgressRibbon(value: Double(egg.progress) / Double(max(1, egg.requiredCount)))
                }
                Text(engine.t("habit.skipNote")).font(.system(.caption, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.65))
                NavigationLink(engine.t("common.edit")) { HabitEditor(engine: engine, habit: habit) }
                Button(engine.t("habit.archive")) { habit.isArchived = true; engine.save() }
                Button(engine.t("common.delete"), role: .destructive) { confirmDelete = true }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(habit.title)
        .alert(engine.t("habit.deleteAsk"), isPresented: $confirmDelete) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.delete"), role: .destructive) { engine.deleteHabit(habit) }
        }
    }
}

struct HabitEditor: View {
    var engine: GoobyEngine
    var habit: Habit?
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var details = ""
    @State private var icon = "sparkles"
    @State private var color = "FFD6E7"
    @State private var category = "mindful"
    @State private var priority = 1
    @State private var start = Date()
    @State private var hasEnd = false
    @State private var end = Date()
    @State private var recurrence = "daily"
    @State private var weekdays: Set<Int> = []
    @State private var interval = 2
    @State private var times = 1
    @State private var reminder = false
    @State private var reminderDate = Date()
    @State private var energy = 5
    @State private var sparks = 2
    @State private var dailyGoal = false

    private let categories = ["morning", "evening", "hygiene", "movement", "sleep", "learning", "home", "mindful", "health", "creative", "custom"]
    private let recurrences = ["once", "daily", "weekly", "monthly", "weekdays", "everyX", "custom"]

    var body: some View {
        Form {
            Section(engine.t("habit.basics")) {
                TextField(engine.t("habit.title"), text: $title)
                TextField(engine.t("habit.details"), text: $details, axis: .vertical)
                Picker(engine.t("habit.category"), selection: $category) {
                    ForEach(categories, id: \.self) { Text(engine.t("cat.\($0)")).tag($0) }
                }
                Picker(engine.t("habit.priority"), selection: $priority) {
                    Text(engine.t("priority.low")).tag(0)
                    Text(engine.t("priority.normal")).tag(1)
                    Text(engine.t("priority.high")).tag(2)
                }
            }
            Section(engine.t("habit.look")) {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Theme.habitIcons, id: \.self) { name in
                            Image(systemName: name)
                                .padding(8)
                                .background(icon == name ? Theme.pink : Color.clear, in: Circle())
                                .onTapGesture { icon = name }
                        }
                    }
                }
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Theme.habitColors, id: \.self) { hex in
                            Circle().fill(Color(hexString: hex)).frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Theme.ink, lineWidth: color == hex ? 2 : 0))
                                .onTapGesture { color = hex }
                        }
                    }
                }
            }
            Section(engine.t("habit.schedule")) {
                DatePicker(engine.t("habit.start"), selection: $start, displayedComponents: .date)
                Toggle(engine.t("habit.hasEnd"), isOn: $hasEnd)
                if hasEnd { DatePicker(engine.t("habit.end"), selection: $end, displayedComponents: .date) }
                Picker(engine.t("habit.repeat"), selection: $recurrence) {
                    ForEach(recurrences, id: \.self) { Text(engine.t("recur.\($0)")).tag($0) }
                }
                if recurrence == "weekdays" || recurrence == "custom" { weekdayPicker }
                if recurrence == "everyX" || recurrence == "custom" {
                    Stepper(engine.tf("habit.every", interval), value: $interval, in: 1...60)
                }
                Stepper(engine.tf("habit.times", times), value: $times, in: 1...8)
                Toggle(engine.t("habit.reminder"), isOn: $reminder)
                if reminder { DatePicker(engine.t("habit.reminder"), selection: $reminderDate, displayedComponents: .hourAndMinute) }
            }
            Section(engine.t("habit.rewards")) {
                Stepper(engine.tf("habit.energyValue", energy), value: $energy, in: 0...20)
                Stepper(engine.tf("habit.sparkValue", sparks), value: $sparks, in: 0...20)
                Toggle(engine.t("habit.dailyGoal"), isOn: $dailyGoal)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.cream)
        .navigationTitle(habit == nil ? engine.t("habit.new") : engine.t("common.edit"))
        .toolbar {
            Button(engine.t("common.save")) { save() }
        }
        .onAppear(perform: load)
    }

    private var weekdayPicker: some View {
        let symbols = weekdaySymbols()
        return HStack {
            ForEach(0..<7, id: \.self) { index in
                let value = index + 1
                Text(symbols[index])
                    .font(.system(.caption, design: .rounded))
                    .padding(6)
                    .background(weekdays.contains(value) ? Theme.lavender : Theme.whiteCard, in: Capsule())
                    .onTapGesture {
                        if weekdays.contains(value) { weekdays.remove(value) } else { weekdays.insert(value) }
                    }
            }
        }
    }

    private func weekdaySymbols() -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: engine.languageCode)
        calendar.firstWeekday = 1
        return calendar.shortWeekdaySymbols
    }

    private func load() {
        guard let habit else { return }
        title = habit.title
        details = habit.details
        icon = habit.icon
        color = habit.colorHex
        category = habit.category
        priority = habit.priority
        start = habit.startDate
        hasEnd = habit.endDate != nil
        end = habit.endDate ?? Date()
        recurrence = habit.recurrence
        weekdays = Set(habit.weekdays)
        interval = habit.intervalDays
        times = habit.timesPerDay
        reminder = habit.reminderHour >= 0
        energy = habit.energyReward
        sparks = habit.sparkReward
        dailyGoal = habit.isDailyGoal
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let target = habit ?? Habit()
        if habit == nil { engine.context.insert(target) }
        target.title = trimmed
        target.details = details
        target.icon = icon
        target.colorHex = color
        target.category = category
        target.priority = priority
        target.startDate = start
        target.endDate = hasEnd ? end : nil
        target.recurrence = recurrence
        target.weekdays = Array(weekdays).sorted()
        target.intervalDays = interval
        target.timesPerDay = times
        let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        target.reminderHour = reminder ? (parts.hour ?? 9) : -1
        target.reminderMinute = parts.minute ?? 0
        target.energyReward = energy
        target.sparkReward = sparks
        target.isDailyGoal = dailyGoal
        engine.updateHabit(target, dailyGoal: dailyGoal)
        dismiss()
    }
}
