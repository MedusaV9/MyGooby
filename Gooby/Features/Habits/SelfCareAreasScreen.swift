import SwiftUI

struct SelfCareAreasScreen: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var onChange: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showGrid = false
    @State private var picked: String?
    @State private var openArea: String?
    @State private var tick = 0

    var body: some View {
        let _ = tick
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .top) {
                    GoalWindowScene()
                    Text(engine.t("care.areas.cheer"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(GoalLook.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.top, 12)
                        .padding(.horizontal, 28)
                }
                Text(engine.t("care.areas.mine"))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
                    .frame(maxWidth: .infinity)
                if listed.isEmpty {
                    Text(engine.t("care.areas.lead"))
                        .font(GoalFont.body)
                        .foregroundStyle(GoalLook.ink.opacity(0.72))
                }
                ForEach(listed) { area in
                    NavigationLink {
                        AreaIdeasScreen(engine: engine, store: store, areaID: area.id) {
                            tick += 1
                            onChange()
                        }
                    } label: {
                        areaCard(area)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    showGrid = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(GoalLook.subtitle)
                            .frame(width: 46, height: 46)
                            .overlay(Circle().stroke(Color(hex: 0xD5D5DA), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                        Text(engine.t("care.areas.new"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(GoalLook.subtitle)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(hex: 0xF3F3F5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle(engine.t("care.areas"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    ChevronMark(direction: .left)
                        .stroke(GoalLook.ink, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 9, height: 16)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(engine.t("common.close"))
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showGrid, onDismiss: openPicked) {
            GoalAreaGrid(engine: engine, store: store) { id in
                picked = id
            }
        }
        .navigationDestination(isPresented: openBinding) {
            if let openArea {
                AreaIdeasScreen(engine: engine, store: store, areaID: openArea) {
                    tick += 1
                    onChange()
                }
            }
        }
    }

    private var openBinding: Binding<Bool> {
        Binding(get: { openArea != nil }, set: { if !$0 { openArea = nil } })
    }

    private var listed: [AreaRow] {
        var rows: [AreaRow] = []
        for area in GoalCatalog.areas where isListed(area.id, custom: false) {
            rows.append(AreaRow(id: area.id, name: area.name(engine.languageCode), blurb: area.blurb(engine.languageCode), glyph: area.glyph, tint: GoalActions.tint(for: area.id, store: store), custom: false))
        }
        for area in store.meta.customAreas where isListed(area.id, custom: true) {
            rows.append(AreaRow(id: area.id, name: area.name, blurb: engine.t("care.areas.custom"), glyph: area.glyph, tint: area.tint, custom: true))
        }
        let focus = store.meta.focused
        return rows.enumerated().sorted { lhs, rhs in
            let left = focus.contains(lhs.element.id)
            let right = focus.contains(rhs.element.id)
            if left != right { return left && !right }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func isListed(_ id: String, custom: Bool) -> Bool {
        if custom { return true }
        if store.meta.started.contains(id) || store.meta.focused.contains(id) { return true }
        return engine.habits().contains { !$0.isArchived && $0.category == id }
    }

    private func areaCard(_ area: AreaRow) -> some View {
        let focused = store.meta.focused.contains(area.id)
        return HStack(spacing: 12) {
            GoalGlyph(glyph: area.glyph, plate: Color(hex: area.tint))
                .frame(width: 52, height: 52)
            Text(area.name)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(GoalLook.ink)
            Spacer(minLength: 4)
            GoalWeekDots(marks: weekMarks(area.id), tint: area.tint)
            Button {
                GoalActions.toggleFocus(area.id, store: store)
                tick += 1
            } label: {
                Image(systemName: focused ? "star.fill" : "star")
                    .foregroundStyle(Color(hex: 0xFFAC33))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t(focused ? "care.focus.on" : "care.focus"))
            if area.custom {
                Button(role: .destructive) {
                    GoalActions.deleteArea(area.id, engine: engine, store: store)
                    tick += 1
                    onChange()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Color(hex: 0xC45B5B))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("common.delete"))
            }
        }
        .padding(12)
        .background(Color(hex: 0xF7F7F8), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func weekMarks(_ areaID: String) -> [Bool] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: engine.now())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = weekday == 1 ? -6 : 2 - weekday
        guard let monday = calendar.date(byAdding: .day, value: mondayOffset, to: today) else {
            return Array(repeating: false, count: 7)
        }
        let habits = engine.habits().filter { !$0.isArchived && $0.category == areaID }
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { return false }
            let key = DayKey.make(day, calendar: calendar)
            return habits.contains { (engine.habitLog($0.id, key)?.count ?? 0) > 0 }
        }
    }

    private func openPicked() {
        guard let picked else { return }
        GoalActions.markStarted(picked, store: store)
        self.picked = nil
        openArea = picked
        tick += 1
        onChange()
    }
}

private struct AreaRow: Identifiable {
    var id: String
    var name: String
    var blurb: String
    var glyph: String
    var tint: UInt32
    var custom: Bool
}

struct GoalWeekDots: View {
    var marks: [Bool]
    var tint: UInt32

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(marks.enumerated()), id: \.offset) { _, on in
                Circle()
                    .fill(on ? Color(hex: tint) : Color(hex: 0xE4E4E8))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct AreaCommit: Identifiable {
    var id = UUID()
    var title: String
    var suggestion: GoalSuggestion?
}

struct AreaIdeasScreen: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var areaID: String
    var onChange: () -> Void
    @State private var tick = 0
    @State private var commit: AreaCommit?
    @State private var ownTitle = ""
    @State private var naming = false
    @State private var showIdeas = false
    @State private var showExisting = false
    @State private var editing: Habit?
    @State private var toast: String?

    var body: some View {
        let _ = tick
        let goals = areaGoals
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(goals.isEmpty)
                    if goals.isEmpty {
                        ideaList
                    } else {
                        filled(goals)
                    }
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            if let toast {
                GoalToastBanner(text: toast)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                    .transition(engine.reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(engine.reduceMotion ? nil : .easeOut(duration: 0.25), value: toast)
        .background(Color(hex: 0xF6F4EF).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $commit) { request in
            GoalRepeatCommit(
                engine: engine,
                title: request.title,
                areaName: title,
                tint: GoalActions.tint(for: areaID, store: store),
                glyph: request.suggestion?.glyph ?? GoalActions.glyphName(for: areaID, store: store),
                recurrence: "weekdays",
                weekdays: [GoalRepeat.today(on: engine.now())],
                showsCommit: true
            ) { recurrence, days in
                save(request, recurrence: recurrence, weekdays: days)
            }
        }
        .sheet(isPresented: $showIdeas) {
            NavigationStack {
                ideaBrowser
            }
        }
        .sheet(isPresented: $showExisting) {
            existingSheet
        }
        .sheet(item: $editing) { habit in
            GoalEditorSheet(engine: engine, store: store, habit: habit) {
                tick += 1
                onChange()
            }
        }
        .alert(engine.t("care.areas.addOwn"), isPresented: $naming) {
            TextField(engine.t("care.own.placeholder"), text: $ownTitle)
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.done")) {
                let trimmed = ownTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                commit = AreaCommit(title: trimmed, suggestion: nil)
            }
        }
    }

    private var areaGoals: [Habit] {
        engine.habits().filter { !$0.isArchived && $0.category == areaID }
    }

    private func header(_ ideas: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(hex: GoalActions.tint(for: areaID, store: store)))
                    .frame(height: 150)
                GoalAreaScene(glyph: GoalActions.glyphName(for: areaID, store: store))
                    .frame(height: 130)
            }
            Text(ideas ? question : title)
                .font(.system(size: ideas ? 22 : 28, weight: .heavy, design: .rounded))
                .foregroundStyle(GoalLook.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            if !ideas {
                GoalWeekDots(marks: weekMarks(), tint: GoalActions.tint(for: areaID, store: store))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var ideaList: some View {
        VStack(spacing: 10) {
            ForEach(GoalCatalog.suggestions(in: areaID)) { suggestion in
                ideaButton(suggestion)
            }
            Button {
                ownTitle = ""
                naming = true
            } label: {
                Text(engine.t("care.areas.addOwn"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(GoalLook.ink.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: 0xECEDEF), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private var ideaBrowser: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(question)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ideaList
            }
            .padding(16)
        }
        .background(Color(hex: 0xF6F4EF))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(engine.t("common.close")) { showIdeas = false }
            }
        }
    }

    private func filled(_ goals: [Habit]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(engine.t("care.areas.goals"))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(GoalLook.subtitle)
            ForEach(goals) { habit in
                goalRow(habit)
            }
            Button {
                showIdeas = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text(engine.t("care.areas.addGoal"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(GoalLook.subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(hex: 0xECEDEF), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            Button {
                showExisting = true
            } label: {
                Text(engine.t("care.areas.existing"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.subtitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }

    private func ideaButton(_ suggestion: GoalSuggestion) -> some View {
        Button {
            commit = AreaCommit(title: suggestion.title(engine.languageCode), suggestion: suggestion)
        } label: {
            HStack(spacing: 12) {
                GoalGlyph(glyph: suggestion.glyph, showsPlate: false)
                    .frame(width: 28, height: 28)
                Text(suggestion.title(engine.languageCode))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func goalRow(_ habit: Habit) -> some View {
        let linked = !GoalActions.linkedExerciseID(habit, store: store).isEmpty
        let done = (engine.habitLog(habit.id, engine.dayKey())?.count ?? 0) >= max(1, habit.timesPerDay)
        return HStack(spacing: 8) {
            Button {
                editing = habit
            } label: {
                HStack(spacing: 10) {
                    GoalGlyph(glyph: GoalActions.glyph(for: habit, store: store))
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.title)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(GoalLook.ink)
                            .multilineTextAlignment(.leading)
                        Text(GoalRepeat.summary(recurrence: habit.recurrence, weekdays: habit.weekdays, engine: engine))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(GoalLook.subtitle)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 4)
            GoalEnergyText(value: habit.energyReward, linked: linked, engine: engine)
            GoalRowFinish(engine: engine, habit: habit, linked: linked, done: done) {
                GoalActions.toggleComplete(habit, engine: engine)
                tick += 1
                onChange()
            }
        }
        .padding(10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var existingSheet: some View {
        NavigationStack {
            List {
                ForEach(engine.habits().filter { !$0.isArchived && $0.category != areaID }) { habit in
                    Button(habit.title) {
                        habit.category = areaID
                        engine.save()
                        GoalActions.markStarted(areaID, store: store)
                        tick += 1
                        onChange()
                        showExisting = false
                    }
                    .foregroundStyle(GoalLook.ink)
                }
            }
            .navigationTitle(engine.t("care.areas.existing"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(engine.t("common.close")) { showExisting = false }
                }
            }
        }
    }

    private func save(_ request: AreaCommit, recurrence: String, weekdays: [Int]) {
        let link = request.suggestion.flatMap { GoalExerciseCatalog.suggestedLink(for: $0.id) } ?? ""
        let draft = GoalCommit(
            title: request.title,
            areaID: areaID,
            daypart: "any",
            recurrence: recurrence,
            weekdays: weekdays,
            timesPerDay: 1,
            remind: false,
            energy: request.suggestion?.energy ?? 5,
            exerciseID: link,
            suggestionID: request.suggestion?.id ?? "",
            glyph: request.suggestion?.glyph ?? GoalActions.glyphName(for: areaID, store: store)
        )
        guard GoalActions.commit(draft, habit: nil, engine: engine, store: store) != nil else { return }
        engine.haptics.soft()
        tick += 1
        onChange()
        showIdeas = false
        let message = engine.tf("care.toast.area", title)
        engine.banner = message
        presentToast(message)
    }

    private func presentToast(_ text: String) {
        if engine.reduceMotion {
            toast = text
        } else {
            withAnimation { toast = text }
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if engine.reduceMotion {
                toast = nil
            } else {
                withAnimation { toast = nil }
            }
        }
    }

    private func weekMarks() -> [Bool] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: engine.now())
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = weekday == 1 ? -6 : 2 - weekday
        guard let monday = calendar.date(byAdding: .day, value: mondayOffset, to: today) else {
            return Array(repeating: false, count: 7)
        }
        let habits = areaGoals
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { return false }
            let key = DayKey.make(day, calendar: calendar)
            return habits.contains { (engine.habitLog($0.id, key)?.count ?? 0) > 0 }
        }
    }

    private var title: String {
        if let area = GoalCatalog.area(areaID) { return area.name(engine.languageCode) }
        return store.custom(areaID)?.name ?? engine.t("care.areas")
    }

    private var question: String {
        let key = "care.area.ask.\(areaID)"
        let value = engine.t(key)
        if value != key { return value }
        if let area = GoalCatalog.area(areaID) { return area.blurb(engine.languageCode) }
        return engine.t("care.area.ask.custom")
    }
}
