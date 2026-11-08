import SwiftUI

struct AddGoalSheet: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var onChange: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var areaID = "all"
    @State private var writing = false
    @State private var tick = 0

    var body: some View {
        let _ = tick
        NavigationStack {
            VStack(spacing: 0) {
                header
                search
                chips
                List {
                    ownRow
                    ForEach(filtered) { suggestion in
                        suggestionRow(suggestion)
                    }
                    if filtered.isEmpty {
                        Text(engine.t("care.search.empty"))
                            .font(GoalFont.body)
                            .foregroundStyle(GoalLook.ink.opacity(0.65))
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(GoalLook.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(engine.t("common.done")) { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $writing) {
            GoalDraftSheet(engine: engine, store: store, habit: nil) {
                tick += 1
                onChange()
            }
        }
    }

    private var header: some View {
        Text(engine.t("care.add"))
            .font(GoalFont.title)
            .foregroundStyle(GoalLook.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)
    }

    private var search: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(GoalLook.subtitle)
            TextField(engine.t("care.search"), text: $query)
                .font(GoalFont.body)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("all", title: engine.t("care.all"))
                ForEach(GoalCatalog.areas) { area in
                    chip(area.id, title: area.name(engine.languageCode))
                }
                ForEach(store.meta.customAreas) { area in
                    chip(area.id, title: area.name)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func chip(_ id: String, title: String) -> some View {
        let on = areaID == id
        return Button {
            areaID = id
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(on ? Color.white : GoalLook.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(on ? GoalLook.button : Color.white, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var ownRow: some View {
        Button {
            writing = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(GoalLook.green.opacity(0.25))
                    Image(systemName: "square.and.pencil").font(.system(size: 16, weight: .bold)).foregroundStyle(GoalLook.button)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.t("care.own")).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(GoalLook.ink)
                    Text(engine.t("care.own.hint")).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(GoalLook.subtitle)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(GoalLook.subtitle)
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.white)
    }

    private func suggestionRow(_ suggestion: GoalSuggestion) -> some View {
        let added = GoalActions.isAdded(suggestion, engine: engine, store: store)
        let area = GoalCatalog.area(suggestion.areaID)?.name(engine.languageCode) ?? ""
        return HStack(spacing: 12) {
            GoalGlyph(glyph: suggestion.glyph).frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text(suggestion.title(engine.languageCode))
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
                    .multilineTextAlignment(.leading)
                Text(area)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.subtitle)
            }
            Spacer(minLength: 8)
            Button {
                guard !added else { return }
                _ = GoalActions.addSuggestion(suggestion, engine: engine, store: store)
                engine.haptics.soft()
                tick += 1
                onChange()
            } label: {
                Image(systemName: added ? "checkmark" : "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(added ? GoalLook.check : GoalLook.button)
                    .frame(width: 32, height: 32)
                    .background(Color(hex: 0xF3F6F0), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(added)
            .accessibilityLabel(added ? engine.t("care.added") : engine.t("care.add"))
        }
        .listRowBackground(Color.white)
    }

    private var filtered: [GoalSuggestion] {
        let source: [GoalSuggestion]
        if areaID == "all" || GoalCatalog.area(areaID) == nil && !areaID.hasPrefix("custom-") {
            source = areaID == "all" ? GoalCatalog.suggestions : GoalCatalog.suggestions.filter { $0.areaID == areaID }
        } else if areaID.hasPrefix("custom-") {
            source = []
        } else {
            source = GoalCatalog.suggestions(in: areaID)
        }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return source }
        return source.filter {
            $0.en.localizedCaseInsensitiveContains(needle) || $0.de.localizedCaseInsensitiveContains(needle)
        }
    }
}

struct GoalDraftSheet: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var habit: Habit?
    var presetArea: String = ""
    var onChange: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var areaID = ""
    @State private var loaded = false
    @State private var daypart = "any"
    @State private var energy = 5
    @State private var remind = false
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section(engine.t("care.own.title")) {
                    TextField(engine.t("care.own.placeholder"), text: $title, axis: .vertical)
                }
                Section(engine.t("care.area")) {
                    Picker(engine.t("care.area"), selection: $areaID) {
                        Text(engine.t("care.area.none")).tag("")
                        ForEach(GoalCatalog.areas) { area in
                            Text(area.name(engine.languageCode)).tag(area.id)
                        }
                        ForEach(store.meta.customAreas) { area in
                            Text(area.name).tag(area.id)
                        }
                    }
                }
                Section(engine.t("care.daypart")) {
                    Picker(engine.t("care.daypart"), selection: $daypart) {
                        ForEach(GoalDaypart.order, id: \.self) { part in
                            Text(engine.t("care.filter.\(part)")).tag(part)
                        }
                    }
                    Toggle(engine.t("care.reminder"), isOn: $remind)
                    Stepper(engine.tf("care.energy", energy), value: $energy, in: 0...20)
                }
                if habit != nil {
                    Section {
                        Button(habit?.isPaused == true ? engine.t("habit.resume") : engine.t("habit.pause")) { togglePause() }
                        Button(engine.t("habit.skip")) { skipToday() }
                        Button(engine.t("habit.archive")) { archive() }
                        Button(engine.t("common.delete"), role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(GoalLook.paper)
            .navigationTitle(habit == nil ? engine.t("care.own") : engine.t("care.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(engine.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(engine.t("common.save")) { save() }
                }
            }
            .onAppear(perform: load)
            .alert(engine.t("habit.deleteAsk"), isPresented: $confirmDelete) {
                Button(engine.t("common.cancel"), role: .cancel) {}
                Button(engine.t("common.delete"), role: .destructive) { remove() }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let habit else {
            if !presetArea.isEmpty { areaID = presetArea }
            return
        }
        title = habit.title
        areaID = habit.category
        daypart = store.meta.dayparts[habit.id.uuidString] ?? "any"
        energy = habit.energyReward
        remind = habit.reminderHour >= 0
    }

    private func save() {
        if let habit {
            GoalActions.update(habit, title: title, areaID: areaID, daypart: daypart, energy: energy, remind: remind, engine: engine, store: store)
        } else {
            _ = GoalActions.addCustom(title: title, areaID: areaID, daypart: daypart, energy: energy, remind: remind, engine: engine, store: store)
        }
        onChange()
        dismiss()
    }

    private func togglePause() {
        guard let habit else { return }
        habit.isPaused.toggle()
        engine.save()
        onChange()
        dismiss()
    }

    private func skipToday() {
        guard let habit else { return }
        engine.skipHabit(habit, on: engine.now())
        onChange()
        dismiss()
    }

    private func archive() {
        guard let habit else { return }
        habit.isArchived = true
        engine.save()
        onChange()
        dismiss()
    }

    private func remove() {
        guard let habit else { return }
        let key = habit.id.uuidString
        engine.deleteHabit(habit)
        store.update { meta in
            meta.links.removeValue(forKey: key)
            meta.dayparts.removeValue(forKey: key)
        }
        onChange()
        dismiss()
    }
}

struct GoalEditorSheet: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var habit: Habit
    var onChange: () -> Void

    var body: some View {
        GoalDraftSheet(engine: engine, store: store, habit: habit, onChange: onChange)
    }
}
