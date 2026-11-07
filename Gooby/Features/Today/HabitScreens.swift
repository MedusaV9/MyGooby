import SwiftUI

// Goal management screens in the pale menu style: own top row with the back chevron, white cards,
// uppercase section headers and 3D keys. The logic is unchanged.

struct HabitListScreen: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var showArchive = false
    @State private var selected: Habit?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                searchField
                if visible.isEmpty {
                    Text(engine.tx("home.habits.empty", de: "Hier ist noch nichts. Leg dein erstes Ziel an!", en: "Nothing here yet. Add your first goal!"))
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.greyText)
                        .padding(.vertical, 12)
                }
                ForEach(visible) { habit in
                    HomeGoalCard(engine: engine, habit: habit, day: engine.now(), showsHandle: false) { selected = habit }
                }
                NavigationLink {
                    HabitEditor(engine: engine, habit: nil)
                } label: {
                    Label(engine.t("habit.new"), systemImage: "plus")
                        .foregroundStyle(.white)
                }
                .buttonStyle(Press3DButtonStyle(fill: Theme.checkGreen, edge: Theme.checkGreenEdge, radius: 18, vertical: 14, expand: true))
                .padding(.top, 6)
                Button(engine.t("common.archived")) { showArchive = true }
                    .buttonStyle(Press3DButtonStyle(fill: .white, edge: Theme.keyEdge, radius: 18, vertical: 12, expand: true))
                    .foregroundStyle(Theme.text)
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Tab.menu.bg.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeTopRow(title: engine.t("tab.habits"), backLabel: engine.t("kit.back")) { dismiss() }
                .background(Theme.Tab.menu.bg)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selected) { habit in
            HabitDetail(engine: engine, habit: habit)
        }
        .sheet(isPresented: $showArchive) { ArchiveScreen(engine: engine) }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.greyText)
            TextField(engine.t("common.search"), text: $query)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            ScrollView {
                VStack(spacing: 10) {
                    let archived = engine.habits().filter(\.isArchived)
                    if archived.isEmpty {
                        Text(engine.tx("home.archive.empty", de: "Das Archiv ist leer.", en: "The archive is empty."))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.greyText)
                            .padding(.vertical, 16)
                    }
                    ForEach(archived) { habit in
                        Button {
                            habit.isArchived = false
                            engine.save()
                        } label: {
                            row(habit)
                        }
                        .buttonStyle(HomeSoftPressStyle())
                    }
                }
                .padding(.horizontal, Theme.Space.margin)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(Theme.Tab.menu.bg.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                HomeTopRow(title: engine.t("common.archived"), backLabel: engine.t("kit.close")) { dismiss() }
                    .background(Theme.Tab.menu.bg)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func row(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            GoobyIcon(habit.icon, size: 30)
                .frame(width: 44, height: 44)
                .background(Theme.card(habit.colorHex), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(habit.title)
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.text)
                .lineLimit(2)
            Spacer(minLength: 6)
            Text(engine.tx("home.archive.restore", de: "Zurückholen", en: "Restore"))
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.checkGreen)
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .cardShadow()
    }
}

struct HabitDetail: View {
    var engine: GoobyEngine
    var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @State private var day = Date()
    @State private var moveDay = Date()
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                HabitRow(engine: engine, habit: habit, day: day)
                GCard {
                    VStack(alignment: .leading, spacing: 6) {
                        if !habit.details.isEmpty {
                            Text(habit.details)
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.text)
                        }
                        Text(engine.t("cat.\(habit.category)") + " · " + engine.t("recur.\(habit.recurrence)"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.greyText)
                    }
                }
                SectionCaps(engine.tx("home.detail.day", de: "Tag", en: "Day"))
                    .padding(.top, 4)
                GCard { dayCard }
                SectionCaps(engine.t("habit.move"))
                    .padding(.top, 4)
                GCard { moveCard }
                SectionCaps(engine.tx("home.detail.egg", de: "Mini-Freund-Ei", en: "Mini-friend egg"))
                    .padding(.top, 4)
                GCard { eggCard }
                NavigationLink(engine.t("common.edit")) { HabitEditor(engine: engine, habit: habit) }
                    .buttonStyle(Press3DButtonStyle(fill: .white, edge: Theme.keyEdge, radius: 18, vertical: 12, expand: true))
                    .foregroundStyle(Theme.text)
                    .padding(.top, 6)
                Button(engine.t("habit.archive")) {
                    habit.isArchived = true
                    engine.save()
                }
                .buttonStyle(Press3DButtonStyle(fill: .white, edge: Theme.keyEdge, radius: 18, vertical: 12, expand: true))
                .foregroundStyle(Theme.text)
                Button(engine.t("common.delete"), role: .destructive) { confirmDelete = true }
                    .buttonStyle(Press3DButtonStyle(fill: Color(hex: 0xFFE3E3), edge: Color(hex: 0xF2B8B8), radius: 18, vertical: 12, expand: true))
                    .foregroundStyle(Color(hex: 0xC94040))
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Theme.Tab.menu.bg.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeTopRow(title: habit.title, backLabel: engine.t("kit.back")) { dismiss() }
                .background(Theme.Tab.menu.bg)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(engine.t("habit.deleteAsk"), isPresented: $confirmDelete) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.delete"), role: .destructive) { delete() }
        }
    }

    private var dayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker(engine.t("habit.backfill"), selection: $day, displayedComponents: .date)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.text)
                .tint(Theme.checkGreen)
            HStack(spacing: 8) {
                key(engine.t("habit.undo")) { engine.undoHabit(habit, on: day) }
                key(engine.t("habit.skip")) { engine.skipHabit(habit, on: day) }
                key(habit.isPaused ? engine.t("habit.resume") : engine.t("habit.pause")) {
                    habit.isPaused.toggle()
                    engine.save()
                }
            }
            Text(engine.t("habit.skipNote"))
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.greyText)
        }
    }

    private var moveCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker(engine.t("habit.moveTo"), selection: $moveDay, displayedComponents: .date)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.text)
                .tint(Theme.checkGreen)
            Button(engine.t("habit.move")) { engine.moveHabit(habit, from: day, to: moveDay) }
                .buttonStyle(Press3DButtonStyle(fill: Theme.lavender, edge: nil, radius: 16, vertical: 11, expand: true))
                .foregroundStyle(Theme.text)
        }
    }

    @ViewBuilder private var eggCard: some View {
        if let egg = engine.activeEgg(for: habit.id) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    GoobyIcon("🥚", size: 30)
                    Text(engine.tf("egg.progress", egg.progress, egg.requiredCount))
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                }
                StripedProgressBar(value: egg.progress, goal: max(1, egg.requiredCount))
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(engine.t("egg.explain"))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.greyText)
                Button(engine.t("egg.bind")) { engine.bindEgg(to: habit) }
                    .buttonStyle(Press3DButtonStyle(fill: Theme.progressFill, edge: Color(hex: 0xDDA22F), radius: 16, vertical: 11, expand: true))
                    .foregroundStyle(Theme.brown)
            }
        }
    }

    private func key(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Theme.text)
        }
        .buttonStyle(Press3DButtonStyle(radius: 12, horizontal: 6, vertical: 9, expand: true))
    }

    /// Leaves the screen first; deleting while it is still shown would read a deleted model.
    private func delete() {
        let store = engine
        let doomed = habit
        dismiss()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            store.deleteHabit(doomed)
        }
    }
}

struct HabitEditor: View {
    var engine: GoobyEngine
    var habit: Habit?
    /// Category of a new goal added from a Home section.
    var presetCategory: String? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var loaded = false
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
    /// SF Symbol names (stored as before); GoobyIcon draws them as color emoji.
    private let icons = Theme.habitIcons + [
        "figure.run", "bicycle", "figure.mind.and.body", "pills.fill", "shower.fill", "bathtub.fill",
        "carrot.fill", "paintbrush.fill", "camera.fill", "lightbulb.fill", "graduationcap.fill", "birthday.cake.fill"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                preview
                SectionCaps(engine.t("habit.basics"))
                GCard { basics }
                SectionCaps(engine.t("habit.look"))
                    .padding(.top, 4)
                GCard { look }
                SectionCaps(engine.t("habit.schedule"))
                    .padding(.top, 4)
                GCard { schedule }
                SectionCaps(engine.t("habit.rewards"))
                    .padding(.top, 4)
                GCard { rewards }
                Button { save() } label: {
                    Text(engine.t("common.save")).foregroundStyle(.white)
                }
                .buttonStyle(Press3DButtonStyle(fill: Theme.checkGreen, edge: Theme.checkGreenEdge, radius: 18, vertical: 14, expand: true))
                .disabled(trimmedTitle.isEmpty)
                .padding(.top, 6)
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Tab.menu.bg.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            HomeTopRow(title: habit == nil ? engine.t("habit.new") : engine.t("common.edit"), backLabel: engine.t("kit.close")) {
                dismiss()
            } trailing: {
                Button(engine.t("common.save")) { save() }
                    .font(Theme.Fonts.button)
                    .foregroundStyle(trimmedTitle.isEmpty ? Theme.greyText : Theme.checkGreen)
                    .disabled(trimmedTitle.isEmpty)
                    .padding(.horizontal, 8)
                    .frame(height: 44)
            }
            .background(Theme.Tab.menu.bg)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: load)
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespaces) }

    private var preview: some View {
        HStack(spacing: 12) {
            GoobyIcon(icon, size: 34)
                .frame(width: 52, height: 52)
                .background(Theme.card(color), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(trimmedTitle.isEmpty ? engine.t("habit.title") : trimmedTitle)
                .font(Theme.Fonts.headline)
                .foregroundStyle(trimmedTitle.isEmpty ? Theme.greyText : Theme.text)
                .lineLimit(2)
            Spacer()
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .cardShadow()
        .accessibilityHidden(true)
    }

    private var basics: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(engine.t("habit.title"), text: $title)
                .modifier(HabitFieldStyle())
            TextField(engine.t("habit.details"), text: $details, axis: .vertical)
                .lineLimit(1...4)
                .modifier(HabitFieldStyle())
            HStack {
                Text(engine.t("habit.category"))
                Spacer()
                Picker(engine.t("habit.category"), selection: $category) {
                    ForEach(categories, id: \.self) { Text(engine.t("cat.\($0)")).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(Theme.text)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(engine.t("habit.priority"))
                Picker(engine.t("habit.priority"), selection: $priority) {
                    Text(engine.t("priority.low")).tag(0)
                    Text(engine.t("priority.normal")).tag(1)
                    Text(engine.t("priority.high")).tag(2)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .font(Theme.Fonts.body)
        .foregroundStyle(Theme.text)
    }

    private var look: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(icons, id: \.self) { name in
                    iconChoice(name)
                }
            }
            HStack(spacing: 0) {
                ForEach(Theme.habitColors, id: \.self) { hex in
                    Button { color = hex } label: {
                        Circle()
                            .fill(Color(hexString: hex))
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Theme.text, lineWidth: color == hex ? 2.5 : 0).padding(-3))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.tx("home.editor.color", de: "Farbe", en: "Color"))
                    .accessibilityAddTraits(color == hex ? .isSelected : [])
                }
            }
        }
    }

    private func iconChoice(_ name: String) -> some View {
        let chosen = icon == name
        return Button { icon = name } label: {
            GoobyIcon(name, size: 30)
                .frame(width: 46, height: 46)
                .background(chosen ? Theme.card(color) : Theme.keyFace, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(chosen ? Theme.checkGreen : Color.clear, lineWidth: 2.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(GoobyIcon.emoji(for: name) ?? name)
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    private var schedule: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker(engine.t("habit.start"), selection: $start, displayedComponents: .date)
            Toggle(engine.t("habit.hasEnd"), isOn: $hasEnd)
            if hasEnd {
                DatePicker(engine.t("habit.end"), selection: $end, displayedComponents: .date)
            }
            HStack {
                Text(engine.t("habit.repeat"))
                Spacer()
                Picker(engine.t("habit.repeat"), selection: $recurrence) {
                    ForEach(recurrences, id: \.self) { Text(engine.t("recur.\($0)")).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(Theme.text)
            }
            if recurrence == "weekdays" || recurrence == "custom" { weekdayPicker }
            if recurrence == "everyX" || recurrence == "custom" {
                Stepper(engine.tf("habit.every", interval), value: $interval, in: 1...60)
            }
            Stepper(engine.tf("habit.times", times), value: $times, in: 1...8)
            Toggle(engine.t("habit.reminder"), isOn: $reminder)
            if reminder {
                DatePicker(engine.t("habit.reminder"), selection: $reminderDate, displayedComponents: .hourAndMinute)
            }
        }
        .font(Theme.Fonts.body)
        .foregroundStyle(Theme.text)
        .tint(Theme.checkGreen)
    }

    private var rewards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(engine.tf("habit.energyValue", energy), value: $energy, in: 0...20)
            Stepper(engine.tf("habit.sparkValue", sparks), value: $sparks, in: 0...20)
            Toggle(engine.t("habit.dailyGoal"), isOn: $dailyGoal)
            Text(engine.t("today.goal.bonus"))
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.greyText)
        }
        .font(Theme.Fonts.body)
        .foregroundStyle(Theme.text)
        .tint(Theme.checkGreen)
    }

    private var weekdayPicker: some View {
        let symbols = weekdaySymbols()
        return HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                let value = index + 1
                let on = weekdays.contains(value)
                Button {
                    if on { weekdays.remove(value) } else { weekdays.insert(value) }
                } label: {
                    Text(symbols[index])
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(on ? Color.white : Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(on ? Theme.checkGreen : Theme.keyFace, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
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
        guard !loaded else { return }
        loaded = true
        guard let habit else {
            if let presetCategory { category = presetCategory }
            return
        }
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
        if habit.reminderHour >= 0 {
            reminderDate = Calendar.current.date(bySettingHour: habit.reminderHour, minute: habit.reminderMinute, second: 0, of: Date()) ?? Date()
        }
        energy = habit.energyReward
        sparks = habit.sparkReward
        dailyGoal = habit.isDailyGoal
    }

    private func save() {
        let trimmed = trimmedTitle
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

/// White rounded input field on the grey card.
private struct HabitFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Fonts.body)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Theme.keyFace, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
