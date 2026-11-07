import SwiftUI

struct HabitHomeView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @State private var selectedDay = ""
    @State private var showArchive = false
    @State private var editor: Habit?
    @State private var action: HabitActionTarget?
    @State private var banner = ""

    var body: some View {
        CareScreen {
            weekStrip
            progressCard
            if !banner.isEmpty {
                Text(banner).font(.footnote).foregroundStyle(CarePalette.ink)
            }
            if showArchive {
                archiveList
            } else {
                dueList
                pausedList
            }
            Text(session.text(.disclaimer))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
            Text(session.text(.notShared))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
        }
        .navigationTitle(session.text(.tabHabits))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showArchive.toggle()
                } label: {
                    Image(systemName: showArchive ? "checkmark.circle" : "archivebox")
                }
                .accessibilityLabel(session.text(showArchive ? .filterActive : .filterArchive))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editor = Habit.makeNew(today: selectedDay.isEmpty ? session.todayKey : selectedDay)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel(session.text(.addHabit))
            }
        }
        .careGroundingShortcut()
        .onAppear {
            if selectedDay.isEmpty { selectedDay = session.todayKey }
        }
        .onChange(of: session.simulatedNow) { _, _ in
            selectedDay = session.todayKey
        }
        .sheet(item: $editor) { habit in
            NavigationStack { HabitEditorView(habit: habit) }
        }
        .sheet(item: $action) { target in
            NavigationStack { HabitActionSheet(habitID: target.id, day: target.day) }
        }
    }

    private var day: String { selectedDay.isEmpty ? session.todayKey : selectedDay }

    private var weekStrip: some View {
        let keys = CareDay.weekKeys(containing: day, calendar: session.calendar)
        return HStack(spacing: 8) {
            ForEach(keys, id: \.self) { key in
                let selected = key == day
                Button {
                    selectedDay = key
                    banner = ""
                } label: {
                    VStack(spacing: 4) {
                        Text(weekdayLabel(key))
                            .font(.caption2)
                        Text(numberLabel(key))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(CarePalette.ink)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selected ? CarePalette.lavender : CarePalette.card)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(CareDay.format(key, language: session.language, calendar: session.calendar, template: "EEEE d MMMM"))
            }
        }
    }

    private var progressCard: some View {
        let due = store.dueHabits(on: day, calendar: session.calendar)
        let done = due.filter { store.progress(for: $0, day: day, calendar: session.calendar).isComplete }.count
        return CareCard(fill: CarePalette.yellow.opacity(0.85)) {
            VStack(alignment: .leading, spacing: 6) {
                Text(CareDay.format(day, language: session.language, calendar: session.calendar, template: "EEEE d MMMM"))
                    .font(.headline)
                    .foregroundStyle(CarePalette.ink)
                Text(session.format(.progressLine, done, due.count))
                    .font(.subheadline)
                    .foregroundStyle(CarePalette.ink.opacity(0.8))
                if day > session.todayKey {
                    Text(session.text(.futureLocked)).font(.footnote).foregroundStyle(CarePalette.ink.opacity(0.75))
                } else if day < session.todayKey {
                    Text(session.text(.pastHint)).font(.footnote).foregroundStyle(CarePalette.ink.opacity(0.75))
                }
            }
        }
    }

    private var dueList: some View {
        let due = store.dueHabits(on: day, calendar: session.calendar)
        return VStack(alignment: .leading, spacing: 12) {
            if due.isEmpty {
                CareCard {
                    Text(store.sortedHabits(archived: false).isEmpty ? session.text(.habitsEmpty) : session.text(.noHabitsDue))
                        .foregroundStyle(CarePalette.ink)
                }
            }
            ForEach(due) { habit in
                habitRow(habit)
            }
        }
    }

    private var pausedList: some View {
        let paused = store.pausedHabits(on: day)
        return VStack(alignment: .leading, spacing: 12) {
            if !paused.isEmpty {
                Text(session.text(.pausedSection))
                    .font(.headline)
                    .foregroundStyle(CarePalette.ink)
                ForEach(paused) { habit in
                    habitRow(habit, forcePaused: true)
                }
            }
        }
    }

    private var archiveList: some View {
        let archived = store.sortedHabits(archived: true)
        return VStack(alignment: .leading, spacing: 12) {
            if archived.isEmpty {
                CareCard {
                    Text(session.text(.habitsEmptyArchive)).foregroundStyle(CarePalette.ink)
                }
            }
            ForEach(archived) { habit in
                Button {
                    editor = habit
                } label: {
                    habitLabel(habit, progress: nil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func habitRow(_ habit: Habit, forcePaused: Bool = false) -> some View {
        let progress = store.progress(for: habit, day: day, calendar: session.calendar)
        return HStack(spacing: 12) {
            Button {
                action = HabitActionTarget(id: habit.id, day: day)
            } label: {
                habitLabel(habit, progress: progress, forcePaused: forcePaused)
            }
            .buttonStyle(.plain)
            Button {
                toggle(habit, progress: progress)
            } label: {
                Image(systemName: progress.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(CarePalette.ink)
            }
            .accessibilityLabel(session.text(progress.isComplete ? .undo : .completeRep))
            .disabled(day > session.todayKey || (!progress.due && !progress.isComplete))
        }
    }

    private func habitLabel(_ habit: Habit, progress: HabitProgress?, forcePaused: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: habit.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(CarePalette.ink)
                .frame(width: 42, height: 42)
                .background(Circle().fill(CarePalette.color(hex: habit.colorHex)))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(habit.title)
                        .font(.headline)
                        .foregroundStyle(CarePalette.ink)
                    if habit.isDailyGoal {
                        Text(session.text(.dailyGoalBadge))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(CarePalette.yellow))
                    }
                }
                Text(categoryLine(habit))
                    .font(.caption)
                    .foregroundStyle(CarePalette.ink.opacity(0.7))
                if let progress, progress.due {
                    Text(session.format(.repsOf, progress.completed, progress.repetitions))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CarePalette.ink)
                }
                if forcePaused || habit.pauseFrom != nil && !(progress?.due ?? false) {
                    Text(session.text(.pausedSection))
                        .font(.caption2)
                        .foregroundStyle(CarePalette.ink.opacity(0.7))
                }
                if progress?.skipped == true {
                    Text(session.text(.skippedBadge))
                        .font(.caption2)
                        .foregroundStyle(CarePalette.ink.opacity(0.7))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(CarePalette.card)
                .shadow(color: CarePalette.ink.opacity(0.05), radius: 8, y: 4)
        )
    }

    private func toggle(_ habit: Habit, progress: HabitProgress) {
        if progress.isComplete {
            switch store.undoRep(habitID: habit.id, day: day, now: session.now) {
            case .success:
                banner = ""
                CareHaptics.tap()
            case .failure(let issue):
                banner = CareCopy.issue(issue, session.language)
            }
            return
        }
        switch store.completeRep(habitID: habit.id, day: day, now: session.now, calendar: session.calendar) {
        case .success(let rewards):
            banner = rewards.isEmpty ? "" : session.text(.rewardNoted)
            CareHaptics.success()
        case .failure(let issue):
            banner = CareCopy.issue(issue, session.language)
        }
    }

    private func categoryLine(_ habit: Habit) -> String {
        if habit.category == .custom && !habit.customCategory.isEmpty {
            return habit.customCategory
        }
        return CareCopy.category(habit.category, session.language)
    }

    private func weekdayLabel(_ key: String) -> String {
        guard let date = CareDay.date(from: key, calendar: session.calendar) else { return "" }
        return CareCopy.weekday(session.calendar.component(.weekday, from: date), session.language)
    }

    private func numberLabel(_ key: String) -> String {
        guard let date = CareDay.date(from: key, calendar: session.calendar) else { return "" }
        return String(session.calendar.component(.day, from: date))
    }
}

struct HabitActionTarget: Identifiable, Equatable {
    var id: UUID
    var day: String
}

private struct HabitActionSheet: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @Environment(\.dismiss) private var dismiss
    let habitID: UUID
    let day: String
    @State private var moveDay: String
    @State private var pauseUntil: String
    @State private var openPause = true
    @State private var message = ""
    @State private var confirmDelete = false
    @State private var editor: Habit?

    init(habitID: UUID, day: String) {
        self.habitID = habitID
        self.day = day
        _moveDay = State(initialValue: day)
        _pauseUntil = State(initialValue: day)
    }

    var body: some View {
        CareScreen {
            if let habit = store.habit(habitID) {
                let progress = store.progress(for: habit, day: day, calendar: session.calendar)
                Text(habit.title).font(.title2.weight(.semibold)).foregroundStyle(CarePalette.ink)
                Text(CareDay.format(day, language: session.language, calendar: session.calendar, template: "EEEE d MMMM"))
                    .foregroundStyle(CarePalette.ink.opacity(0.7))
                if progress.due {
                    Text(session.format(.repsOf, progress.completed, progress.repetitions))
                        .font(.headline)
                        .foregroundStyle(CarePalette.ink)
                }
                if !message.isEmpty {
                    Text(message).font(.footnote).foregroundStyle(CarePalette.ink)
                }
                if progress.due && day <= session.todayKey && !progress.isComplete {
                    Button(session.text(.completeRep)) { complete(habit) }.buttonStyle(CarePrimaryButton())
                }
                if progress.completed > 0 {
                    Button(session.text(.undo)) { undo() }.buttonStyle(CarePrimaryButton())
                }
                if progress.due && day <= session.todayKey && progress.completed == 0 {
                    Button(session.text(progress.skipped ? .undoSkip : .skip)) { skip(progress) }
                        .buttonStyle(CarePrimaryButton())
                }
                DatePicker(
                    session.text(.moveTo),
                    selection: moveBinding,
                    displayedComponents: .date
                )
                .foregroundStyle(CarePalette.ink)
                Button(session.text(.reschedule)) { move() }.buttonStyle(CarePrimaryButton())
                Toggle(session.text(.pauseOpen), isOn: $openPause)
                    .foregroundStyle(CarePalette.ink)
                if !openPause {
                    DatePicker(session.text(.pauseUntil), selection: pauseBinding, displayedComponents: .date)
                }
                if habit.pauseFrom != nil {
                    Button(session.text(.resume)) {
                        message = issueText(store.resume(id: habit.id))
                        if message.isEmpty { dismiss() }
                    }
                    .buttonStyle(CarePrimaryButton())
                } else {
                    Button(session.text(.pause)) { pause() }.buttonStyle(CarePrimaryButton())
                }
                Button(session.text(.edit)) { editor = habit }.buttonStyle(CarePrimaryButton())
                Button(session.text(habit.archived ? .restore : .archive)) {
                    _ = store.setArchived(id: habit.id, archived: !habit.archived)
                    dismiss()
                }
                .buttonStyle(CarePrimaryButton())
                Button(session.text(.delete), role: .destructive) { confirmDelete = true }
                    .foregroundStyle(CarePalette.ink)
            } else {
                Text(session.text(.errMissing)).foregroundStyle(CarePalette.ink)
            }
        }
        .navigationTitle(session.text(.tabHabits))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(session.text(.close)) { dismiss() }
            }
        }
        .confirmationDialog(session.text(.deleteHabitTitle), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(session.text(.delete), role: .destructive) {
                store.deleteHabit(id: habitID)
                dismiss()
            }
            Button(session.text(.cancel), role: .cancel) {}
        } message: {
            Text(session.text(.deleteHabitMessage))
        }
        .sheet(item: $editor) { habit in
            NavigationStack { HabitEditorView(habit: habit) }
        }
    }

    private var moveBinding: Binding<Date> {
        Binding(
            get: { CareDay.date(from: moveDay, calendar: session.calendar) ?? session.now },
            set: { moveDay = CareDay.key(for: $0, calendar: session.calendar) }
        )
    }

    private var pauseBinding: Binding<Date> {
        Binding(
            get: { CareDay.date(from: pauseUntil, calendar: session.calendar) ?? session.now },
            set: { pauseUntil = CareDay.key(for: $0, calendar: session.calendar) }
        )
    }

    private func complete(_ habit: Habit) {
        switch store.completeRep(habitID: habit.id, day: day, now: session.now, calendar: session.calendar) {
        case .success:
            message = session.text(.rewardNoted)
            CareHaptics.success()
        case .failure(let issue):
            message = CareCopy.issue(issue, session.language)
        }
    }

    private func undo() {
        switch store.undoRep(habitID: habitID, day: day, now: session.now) {
        case .success:
            message = ""
        case .failure(let issue):
            message = CareCopy.issue(issue, session.language)
        }
    }

    private func skip(_ progress: HabitProgress) {
        if progress.skipped {
            message = issueText(store.undoSkip(habitID: habitID, day: day, now: session.now))
        } else {
            message = issueText(store.skip(habitID: habitID, day: day, now: session.now, calendar: session.calendar))
        }
    }

    private func move() {
        message = issueText(store.reschedule(habitID: habitID, from: day, to: moveDay, now: session.now, calendar: session.calendar))
    }

    private func pause() {
        let until = openPause ? nil : pauseUntil
        message = issueText(store.pause(id: habitID, from: day, until: until))
    }

    private func issueText(_ issue: CareIssue?) -> String {
        guard let issue else { return "" }
        return CareCopy.issue(issue, session.language)
    }
}

private struct HabitEditorView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Habit
    @State private var kind: RuleKind
    @State private var weeklyDay: Int
    @State private var monthDay: Int
    @State private var weekdaySet: Set<Int>
    @State private var interval: Int
    @State private var customIntervalOn: Bool
    @State private var monthDaySet: Set<Int>
    @State private var hasEnd: Bool
    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    @State private var message = ""
    @State private var confirmDelete = false

    init(habit: Habit) {
        _draft = State(initialValue: habit)
        let parsed = RuleKind.parsed(habit.rule)
        _kind = State(initialValue: parsed.kind)
        _weeklyDay = State(initialValue: parsed.weeklyDay)
        _monthDay = State(initialValue: parsed.monthDay)
        _weekdaySet = State(initialValue: parsed.weekdays)
        _interval = State(initialValue: parsed.interval)
        _customIntervalOn = State(initialValue: parsed.customInterval)
        _monthDaySet = State(initialValue: parsed.monthDays)
        _hasEnd = State(initialValue: habit.endDay != nil)
        _hasReminder = State(initialValue: habit.reminder != nil)
        let calendar = Calendar(identifier: .gregorian)
        var parts = DateComponents()
        parts.hour = habit.reminder?.hour ?? 9
        parts.minute = habit.reminder?.minute ?? 0
        _reminderDate = State(initialValue: calendar.date(from: parts) ?? Date())
    }

    var body: some View {
        CareScreen {
            field(session.text(.fieldTitle)) {
                TextField(session.text(.fieldTitle), text: $draft.title)
                    .textFieldStyle(.roundedBorder)
            }
            field(session.text(.fieldDescription)) {
                TextField(session.text(.fieldDescription), text: $draft.details, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }
            field(session.text(.fieldIcon)) { iconGrid }
            field(session.text(.fieldColor)) { colorRow }
            field(session.text(.fieldCategory)) {
                Picker(session.text(.fieldCategory), selection: $draft.category) {
                    ForEach(HabitCategory.allCases) { category in
                        Text(CareCopy.category(category, session.language)).tag(category)
                    }
                }
                if draft.category == .custom {
                    TextField(session.text(.customCategory), text: $draft.customCategory)
                        .textFieldStyle(.roundedBorder)
                }
            }
            field(session.text(.fieldPriority)) {
                Picker(session.text(.fieldPriority), selection: $draft.priority) {
                    ForEach(HabitPriority.allCases) { priority in
                        Text(CareCopy.priority(priority, session.language)).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
            field(session.text(.fieldStart)) {
                DatePicker(session.text(.fieldStart), selection: startBinding, displayedComponents: .date)
            }
            Toggle(session.text(.fieldNoEnd), isOn: Binding(
                get: { !hasEnd },
                set: { hasEnd = !$0; if !hasEnd { draft.endDay = nil } else if draft.endDay == nil { draft.endDay = draft.startDay } }
            ))
            .foregroundStyle(CarePalette.ink)
            if hasEnd {
                DatePicker(session.text(.fieldEnd), selection: endBinding, displayedComponents: .date)
            }
            field(session.text(.fieldRepeat)) { ruleControls }
            Toggle(session.text(.fieldReminder), isOn: $hasReminder)
                .foregroundStyle(CarePalette.ink)
            if hasReminder {
                DatePicker(session.text(.fieldReminder), selection: $reminderDate, displayedComponents: .hourAndMinute)
            }
            Stepper(session.format(.repsOf, draft.repetitions, 24), value: $draft.repetitions, in: 1...24)
                .foregroundStyle(CarePalette.ink)
            Stepper("\(session.text(.fieldReward)): \(draft.rewardValue)", value: $draft.rewardValue, in: 0...100)
                .foregroundStyle(CarePalette.ink)
            Toggle(session.text(.fieldDailyGoal), isOn: $draft.isDailyGoal)
                .foregroundStyle(CarePalette.ink)
            Text(session.text(.dailyGoalHint))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
            if !message.isEmpty {
                Text(message).font(.footnote).foregroundStyle(CarePalette.ink)
            }
            Button(session.text(.save)) { save() }.buttonStyle(CarePrimaryButton())
            if store.habit(draft.id) != nil {
                Button(session.text(draft.archived ? .restore : .archive)) {
                    draft.archived.toggle()
                    if store.saveHabit(draft) == nil { dismiss() }
                }
                .buttonStyle(CarePrimaryButton())
                Button(session.text(.delete), role: .destructive) { confirmDelete = true }
                    .foregroundStyle(CarePalette.ink)
            }
            Text(session.format(.historyCount, store.completionTotal(for: draft.id)))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
        }
        .navigationTitle(store.habit(draft.id) == nil ? session.text(.addHabit) : session.text(.editHabit))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(session.text(.cancel)) { dismiss() }
            }
        }
        .confirmationDialog(session.text(.deleteHabitTitle), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(session.text(.delete), role: .destructive) {
                store.deleteHabit(id: draft.id)
                dismiss()
            }
            Button(session.text(.cancel), role: .cancel) {}
        } message: {
            Text(session.text(.deleteHabitMessage))
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(CarePalette.ink)
            content()
        }
    }

    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
            ForEach(HabitSymbol.allCases) { symbol in
                Button {
                    draft.symbol = symbol.rawValue
                } label: {
                    Image(systemName: symbol.rawValue)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .foregroundStyle(CarePalette.ink)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(draft.symbol == symbol.rawValue ? CarePalette.lavender : CarePalette.cream)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(symbol.rawValue)
            }
        }
    }

    private var colorRow: some View {
        HStack(spacing: 10) {
            ForEach(HabitColor.allCases) { color in
                Button {
                    draft.colorHex = color.rawValue
                } label: {
                    Circle()
                        .fill(CarePalette.color(hex: color.rawValue))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(CarePalette.ink, lineWidth: draft.colorHex == color.rawValue ? 2 : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(color.rawValue)
            }
        }
    }

    private var ruleControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker(session.text(.fieldRepeat), selection: $kind) {
                ForEach(RuleKind.allCases) { item in
                    Text(session.text(item.title)).tag(item)
                }
            }
            switch kind {
            case .weekly:
                weekdayPicker(single: weeklyBinding)
            case .monthly:
                Stepper("\(session.text(.monthDays)): \(monthDay)", value: $monthDay, in: 1...31)
                    .foregroundStyle(CarePalette.ink)
            case .weekdays:
                weekdayToggles
            case .every:
                Stepper(session.format(.everyDays, interval), value: $interval, in: 1...366)
                    .foregroundStyle(CarePalette.ink)
            case .custom:
                Toggle(session.text(.ruleEvery), isOn: $customIntervalOn).foregroundStyle(CarePalette.ink)
                if customIntervalOn {
                    Stepper(session.format(.everyDays, interval), value: $interval, in: 1...366)
                        .foregroundStyle(CarePalette.ink)
                }
                weekdayToggles
                Text(session.text(.monthDays)).font(.caption).foregroundStyle(CarePalette.ink)
                monthGrid
                Text(session.text(.customHint)).font(.footnote).foregroundStyle(CarePalette.ink.opacity(0.7))
            case .once, .daily:
                EmptyView()
            }
        }
    }

    private var weekdayToggles: some View {
        let order = weekdayOrder
        return CareFlowLayout {
            ForEach(order, id: \.self) { weekday in
                Button {
                    if weekdaySet.contains(weekday) { weekdaySet.remove(weekday) } else { weekdaySet.insert(weekday) }
                } label: {
                    Text(CareCopy.weekday(weekday, session.language))
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundStyle(CarePalette.ink)
                        .background(Capsule().fill(weekdaySet.contains(weekday) ? CarePalette.mint : CarePalette.cream))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func weekdayPicker(single binding: Binding<Int>) -> some View {
        Picker(session.text(.ruleWeekly), selection: binding) {
            ForEach(weekdayOrder, id: \.self) { weekday in
                Text(CareCopy.weekday(weekday, session.language)).tag(weekday)
            }
        }
        .pickerStyle(.segmented)
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
            ForEach(1...31, id: \.self) { day in
                Button {
                    if monthDaySet.contains(day) { monthDaySet.remove(day) } else { monthDaySet.insert(day) }
                } label: {
                    Text("\(day)")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .foregroundStyle(CarePalette.ink)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(monthDaySet.contains(day) ? CarePalette.peach : CarePalette.cream)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weekdayOrder: [Int] {
        let first = session.calendar.firstWeekday
        return (0..<7).map { offset in ((first - 1 + offset) % 7) + 1 }
    }

    private var weeklyBinding: Binding<Int> {
        Binding(get: { weeklyDay }, set: { weeklyDay = $0 })
    }

    private var startBinding: Binding<Date> {
        Binding(
            get: { CareDay.date(from: draft.startDay, calendar: session.calendar) ?? session.now },
            set: { draft.startDay = CareDay.key(for: $0, calendar: session.calendar) }
        )
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { CareDay.date(from: draft.endDay ?? draft.startDay, calendar: session.calendar) ?? session.now },
            set: { draft.endDay = CareDay.key(for: $0, calendar: session.calendar) }
        )
    }

    private func save() {
        draft.rule = builtRule()
        draft.endDay = hasEnd ? (draft.endDay ?? draft.startDay) : nil
        if hasReminder {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
            draft.reminder = HabitReminder(hour: parts.hour ?? 9, minute: parts.minute ?? 0)
        } else {
            draft.reminder = nil
        }
        if let issue = store.saveHabit(draft) {
            message = CareCopy.issue(issue, session.language)
        } else {
            dismiss()
        }
    }

    private func builtRule() -> HabitRule {
        switch kind {
        case .once: return .once
        case .daily: return .daily
        case .weekly: return .weekly(weekday: weeklyDay)
        case .monthly: return .monthly(day: monthDay)
        case .weekdays: return .weekdays(days: weekdaySet.sorted())
        case .every: return .every(days: interval)
        case .custom:
            return .custom(
                interval: customIntervalOn ? interval : nil,
                weekdays: weekdaySet.sorted(),
                monthDays: monthDaySet.sorted()
            )
        }
    }
}

private enum RuleKind: String, CaseIterable, Identifiable {
    case once, daily, weekly, monthly, weekdays, every, custom
    var id: String { rawValue }
    var title: CareString {
        switch self {
        case .once: return .ruleOnce
        case .daily: return .ruleDaily
        case .weekly: return .ruleWeekly
        case .monthly: return .ruleMonthly
        case .weekdays: return .ruleWeekdays
        case .every: return .ruleEvery
        case .custom: return .ruleCustom
        }
    }

    struct Parsed {
        var kind: RuleKind
        var weeklyDay: Int
        var monthDay: Int
        var weekdays: Set<Int>
        var interval: Int
        var customInterval: Bool
        var monthDays: Set<Int>
    }

    static func parsed(_ rule: HabitRule) -> Parsed {
        var value = Parsed(kind: .daily, weeklyDay: 2, monthDay: 1, weekdays: [2], interval: 2, customInterval: true, monthDays: [])
        switch rule {
        case .once: value.kind = .once
        case .daily: value.kind = .daily
        case .weekly(let weekday):
            value.kind = .weekly
            value.weeklyDay = weekday
        case .monthly(let day):
            value.kind = .monthly
            value.monthDay = day
        case .weekdays(let days):
            value.kind = .weekdays
            value.weekdays = Set(days)
        case .every(let days):
            value.kind = .every
            value.interval = days
        case .custom(let interval, let weekdays, let monthDays):
            value.kind = .custom
            value.customInterval = interval != nil
            value.interval = interval ?? 2
            value.weekdays = Set(weekdays)
            value.monthDays = Set(monthDays)
        }
        return value
    }
}
