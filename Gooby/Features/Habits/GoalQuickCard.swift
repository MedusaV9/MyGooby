import SwiftUI

struct GoalQuickCard: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var habit: Habit?
    var suggestion: GoalSuggestion?
    var presetTitle: String
    var presetArea: String
    var presetDaypart: String
    var presetRecurrence: String
    var presetWeekdays: [Int]
    var onChange: () -> Void
    var onClose: () -> Void
    var onSaved: (String) -> Void

    @State private var title = ""
    @State private var areaID = ""
    @State private var daypart = "any"
    @State private var recurrence = "daily"
    @State private var weekdays: [Int] = []
    @State private var times = 1
    @State private var remind = false
    @State private var energy = 5
    @State private var exerciseID = ""
    @State private var glyph = "star"
    @State private var suggestionID = ""
    @State private var preserveSchedule = false
    @State private var expanded = false
    @State private var loaded = false
    @State private var showArea = false
    @State private var showDaypart = false
    @State private var showRepeat = false
    @State private var showExercises = false
    @State private var showDeep = false
    @State private var confirmDelete = false
    @State private var held: Habit?
    @State private var createdHere = false
    @State private var sealed = false

    var body: some View {
        ZStack {
            GoalLook.purple.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: undo) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.18), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.t("common.close"))
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                ScrollView {
                    VStack(spacing: 18) {
                        card
                        Button(action: undo) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.uturn.backward")
                                Text(engine.t("care.quick.undo"))
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .animation(engine.reduceMotion ? nil : .easeInOut(duration: 0.2), value: expanded)
        .onAppear(perform: load)
        .sheet(isPresented: $showArea) {
            GoalAreaGrid(engine: engine, store: store, allowsNone: true) { id in
                areaID = id
                showArea = false
            }
        }
        .sheet(isPresented: $showDaypart) {
            GoalDaypartSheet(engine: engine, daypart: $daypart)
        }
        .sheet(isPresented: $showRepeat) {
            GoalRepeatCommit(
                engine: engine,
                title: title.isEmpty ? engine.t("care.own") : title,
                areaName: areaTitle,
                tint: GoalActions.tint(for: areaID, store: store),
                glyph: displayGlyph,
                recurrence: recurrence,
                weekdays: weekdays,
                showsCommit: false
            ) { next, days in
                preserveSchedule = false
                recurrence = next
                weekdays = days
            }
        }
        .sheet(isPresented: $showExercises) {
            GoalExerciseSearch(engine: engine, store: store) { id in
                exerciseID = id
            }
        }
        .sheet(isPresented: $showDeep, onDismiss: reloadFromHabit) {
            NavigationStack {
                if let target = habit ?? held {
                    HabitEditor(engine: engine, habit: target)
                }
            }
        }
        .alert(engine.t("habit.deleteAsk"), isPresented: $confirmDelete) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.delete"), role: .destructive) { remove() }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZStack(alignment: .bottomTrailing) {
                    GoalGlyph(glyph: displayGlyph, plate: Color(hex: GoalActions.tint(for: areaID, store: store)))
                        .frame(width: 64, height: 64)
                    if expanded {
                        Button(action: openDeep) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GoalLook.ink)
                                .frame(width: 26, height: 26)
                                .background(Color.white, in: Circle())
                                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(engine.t("care.quick.deep"))
                    }
                }
                Spacer()
            }
            if expanded {
                TextField(engine.t("care.compose.placeholder"), text: $title, axis: .vertical)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
                optionRows
            } else {
                Text(title.isEmpty ? engine.t("care.compose.placeholder") : title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(title.isEmpty ? GoalLook.subtitle : GoalLook.ink)
                    .fixedSize(horizontal: false, vertical: true)
                summaryRows
            }
            footer
        }
        .padding(18)
        .background(expanded ? Color(hex: 0xF4F2F8) : Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var summaryRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            summaryLine(system: "circle.grid.2x2.fill", tint: Color(hex: 0xC9B7F5), text: areaTitle.isEmpty ? engine.t("care.area.none") : areaTitle)
            summaryLine(system: "clock.fill", tint: GoalLook.button, text: engine.t("care.filter.\(daypart)"))
            summaryLine(system: "arrow.triangle.2.circlepath", tint: Color(hex: 0x7AA7F8), text: GoalRepeat.summary(recurrence: recurrence, weekdays: weekdays, engine: engine))
        }
    }

    private var optionRows: some View {
        VStack(spacing: 8) {
            menuRow(system: "circle.grid.2x2.fill", tint: Color(hex: 0xC9B7F5), title: engine.t("care.quick.areaLabel"), value: areaTitle.isEmpty ? engine.t("care.area.none") : areaTitle) {
                showArea = true
            }
            menuRow(system: "clock.fill", tint: GoalLook.button, title: engine.t("care.quick.time"), value: engine.t("care.filter.\(daypart)")) {
                showDaypart = true
            }
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(Color(hex: 0xF0A020))
                    .frame(width: 28)
                Text(engine.t("care.reminder"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
                Spacer()
                Toggle("", isOn: $remind)
                    .labelsHidden()
                    .tint(GoalLook.button)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 54)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            menuRow(system: "arrow.triangle.2.circlepath", tint: Color(hex: 0x7AA7F8), title: engine.t("care.quick.repeatLabel"), value: GoalRepeat.summary(recurrence: recurrence, weekdays: weekdays, engine: engine)) {
                showRepeat = true
            }
            HStack(spacing: 12) {
                Image(systemName: "repeat")
                    .foregroundStyle(Color(hex: 0x8B6CFF))
                    .frame(width: 28)
                Text(engine.t("care.quick.times"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
                Spacer()
                Button { times = max(1, times - 1) } label: {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                Text("\(times)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(minWidth: 16)
                Button { times = min(8, times + 1) } label: {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(GoalLook.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 54)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Button { showExercises = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(Color(hex: 0xF08A4A))
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.t("care.quick.link"))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(GoalLook.ink)
                        Text(exerciseID.isEmpty ? engine.t("care.quick.link.hint") : GoalExerciseCatalog.title(for: exerciseID, engine: engine))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(GoalLook.subtitle)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(GoalLook.subtitle)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 64)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            if !exerciseID.isEmpty {
                Button(engine.t("care.quick.unlink")) { exerciseID = "" }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.subtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
            }
            Button(action: openDeep) {
                Text(engine.t("care.quick.deep"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(GoalLook.purpleDeep)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
            }
            .buttonStyle(.plain)
            if habit != nil || held != nil {
                HStack(spacing: 16) {
                    Button(engine.t((habit ?? held)?.isPaused == true ? "habit.resume" : "habit.pause")) { togglePause() }
                    Button(engine.t("habit.skip")) { skipToday() }
                    Button(engine.t("common.delete"), role: .destructive) { confirmDelete = true }
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.leading, 8)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button(engine.t(expanded ? "care.quick.less" : "care.quick.more")) {
                expanded.toggle()
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(hex: 0x8E939A))
            Spacer()
            Button(engine.t("common.save")) { save() }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 22)
                .frame(height: 44)
                .background(expanded ? GoalLook.purple : GoalLook.button, in: Capsule())
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.top, 4)
    }

    private func summaryLine(system: String, tint: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8E939A))
        }
    }

    private func menuRow(system: String, tint: Color, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: system)
                    .foregroundStyle(tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(GoalLook.subtitle)
                    Text(value)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(GoalLook.ink)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(GoalLook.subtitle)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var displayGlyph: String {
        if !suggestionID.isEmpty, let suggestion = GoalCatalog.suggestion(suggestionID) {
            return suggestion.glyph
        }
        if !areaID.isEmpty { return GoalActions.glyphName(for: areaID, store: store) }
        return glyph
    }

    private var areaTitle: String {
        if areaID.isEmpty { return "" }
        if let area = GoalCatalog.area(areaID) { return area.name(engine.languageCode) }
        return store.custom(areaID)?.name ?? ""
    }

    private func draft() -> GoalCommit {
        GoalCommit(
            title: title,
            areaID: areaID,
            daypart: daypart,
            recurrence: recurrence,
            weekdays: weekdays,
            timesPerDay: times,
            remind: remind,
            energy: energy,
            exerciseID: exerciseID,
            suggestionID: suggestionID,
            glyph: displayGlyph,
            preserveSchedule: preserveSchedule
        )
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let habit {
            apply(habit)
            if suggestionID.isEmpty, let suggestion {
                suggestionID = suggestion.id
                glyph = suggestion.glyph
            }
            return
        }
        title = presetTitle
        areaID = presetArea
        daypart = presetDaypart
        recurrence = presetRecurrence
        weekdays = presetWeekdays
        guard let suggestion else { return }
        suggestionID = suggestion.id
        title = suggestion.title(engine.languageCode)
        areaID = suggestion.areaID
        glyph = suggestion.glyph
        energy = suggestion.energy
        if let link = GoalExerciseCatalog.suggestedLink(for: suggestion.id) {
            exerciseID = link
        }
    }

    private func apply(_ habit: Habit) {
        title = habit.title
        areaID = habit.category
        daypart = store.meta.dayparts[habit.id.uuidString] ?? "any"
        energy = habit.energyReward
        times = max(1, habit.timesPerDay)
        remind = habit.reminderHour >= 0
        exerciseID = store.meta.exercises[habit.id.uuidString] ?? ""
        suggestionID = store.meta.links[habit.id.uuidString] ?? ""
        glyph = GoalActions.glyph(for: habit, store: store)
        switch habit.recurrence {
        case "everyX", "monthly", "custom":
            preserveSchedule = true
            recurrence = habit.recurrence
            weekdays = habit.weekdays
        case "weekly":
            preserveSchedule = false
            recurrence = "weekdays"
            weekdays = [Calendar.current.component(.weekday, from: habit.startDate)]
        case "once":
            preserveSchedule = false
            recurrence = "once"
            weekdays = []
        case "weekdays":
            preserveSchedule = false
            recurrence = "weekdays"
            weekdays = habit.weekdays
        default:
            preserveSchedule = false
            recurrence = "daily"
            weekdays = []
        }
    }

    private func reloadFromHabit() {
        guard let habit = habit ?? held else { return }
        apply(habit)
        loaded = true
    }

    private func save() {
        guard let saved = GoalActions.commit(draft(), habit: habit ?? held, engine: engine, store: store) else { return }
        held = saved
        sealed = true
        engine.haptics.soft()
        onChange()
        onSaved(engine.t("care.toast.added"))
    }

    private func openDeep() {
        guard let saved = GoalActions.commit(draft(), habit: habit ?? held, engine: engine, store: store) else { return }
        if habit == nil && held == nil { createdHere = true }
        held = saved
        sealed = true
        onChange()
        showDeep = true
    }

    private func undo() {
        if createdHere && !sealed, let held {
            GoalActions.forget(held, engine: engine, store: store)
            onChange()
        }
        onClose()
    }

    private func togglePause() {
        guard let target = habit ?? held else { return }
        target.isPaused.toggle()
        engine.save()
        onChange()
        onClose()
    }

    private func skipToday() {
        guard let target = habit ?? held else { return }
        engine.skipHabit(target, on: engine.now())
        onChange()
        onClose()
    }

    private func remove() {
        guard let target = habit ?? held else { return }
        GoalActions.forget(target, engine: engine, store: store)
        onChange()
        onClose()
    }
}

struct GoalDaypartSheet: View {
    var engine: GoobyEngine
    @Binding var daypart: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(GoalDaypart.order, id: \.self) { part in
                Button {
                    daypart = part
                    dismiss()
                } label: {
                    HStack {
                        Text(engine.t("care.filter.\(part)"))
                            .foregroundStyle(GoalLook.ink)
                        Spacer()
                        if daypart == part {
                            Image(systemName: "checkmark")
                                .foregroundStyle(GoalLook.button)
                        }
                    }
                }
            }
            .navigationTitle(engine.t("care.daypart"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(engine.t("common.close")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
