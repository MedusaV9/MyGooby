import SwiftUI

struct GoalListScreen: View {
    var engine: GoobyEngine
    @State private var store = GoalMetaStore()
    @State private var revision = 0
    @State private var showAdd = false
    @State private var showGroup = false
    @State private var showBucket = false
    @State private var bucketName = ""
    @State private var closed: Set<String> = []
    @State private var editing: Habit?

    var body: some View {
        let _ = revision
        let language = engine.languageCode
        let rows = visibleRows
        let sections = GoalActions.sections(for: rows, engine: engine, store: store)
        let flat = store.meta.groupMode == "time"
        ScrollView {
            VStack(spacing: 10) {
                if store.meta.groupMode == "custom" {
                    Button {
                        bucketName = ""
                        showBucket = true
                    } label: {
                        Text(engine.t("care.group.add"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(GoalLook.button)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                if flat {
                    ForEach(sections.flatMap(\.habits)) { habit in
                        goalCard(habit, language: language, rows: rows)
                    }
                } else {
                    ForEach(sections) { section in
                        sectionBlock(section, language: language)
                    }
                }
                if rows.isEmpty {
                    Text(engine.t("care.empty"))
                        .font(GoalFont.body)
                        .foregroundStyle(GoalLook.subtitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                NavigationLink {
                    SelfCareAreasScreen(engine: engine, store: store) { revision += 1 }
                } label: {
                    Text(engine.t("care.areas"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(GoalLook.button)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Color(hex: 0xF2F3F5).ignoresSafeArea())
        .navigationTitle(engine.t("goals.mine"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color(hex: 0xF2F3F5), for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showGroup = true
                } label: {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(GoalLook.ink.opacity(0.55))
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel(engine.t("care.group.button"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: 0x3CC85A), in: Circle())
                }
                .accessibilityLabel(engine.t("care.add"))
            }
        }
        .sheet(isPresented: $showAdd) {
            AddGoalSheet(engine: engine, store: store) { revision += 1 }
        }
        .sheet(item: $editing) { habit in
            GoalEditorSheet(engine: engine, store: store, habit: habit) { revision += 1 }
        }
        .sheet(isPresented: $showGroup, onDismiss: {
            applySections()
            revision += 1
        }) {
            GoalGroupSheet(engine: engine, store: store)
        }
        .alert(engine.t("care.group.add"), isPresented: $showBucket) {
            TextField(engine.t("care.group.placeholder"), text: $bucketName)
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("care.areas.create")) {
                GoalActions.addBucket(name: bucketName, store: store)
                revision += 1
            }
        }
        .onAppear {
            GoalActions.ensureReferenceGoals(engine: engine, store: store)
            applySections()
            revision += 1
        }
    }

    private func applySections() {
        if store.meta.expandSections {
            closed = []
        } else {
            closed = Set(GoalActions.sections(for: visibleRows, engine: engine, store: store).map(\.id))
        }
    }

    private func sectionBlock(_ section: GoalSectionModel, language: String) -> some View {
        VStack(spacing: 9) {
            Button {
                if engine.reduceMotion {
                    toggle(section.id)
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) { toggle(section.id) }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(section.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: closed.contains(section.id) ? "chevron.down" : "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                    Rectangle()
                        .fill(Color(hex: 0xE4E4E8))
                        .frame(height: 1.5)
                }
                .foregroundStyle(GoalLook.ink)
            }
            .buttonStyle(.plain)
            if !closed.contains(section.id) {
                ForEach(section.habits) { habit in
                    goalCard(habit, language: language, rows: section.habits)
                }
            }
        }
    }

    private func toggle(_ id: String) {
        if closed.contains(id) {
            closed.remove(id)
        } else {
            closed.insert(id)
        }
    }

    private var visibleRows: [Habit] {
        engine.habits().filter { habit in
            !habit.isArchived && !habit.isPaused && engine.isDue(habit, on: engine.now())
                && GoalActions.matches(daypart: "any", habit: habit, store: store)
        }
    }

    private func goalCard(_ habit: Habit, language: String, rows: [Habit]) -> some View {
        let finished = done(habit)
        let skipped = engine.habitLog(habit.id, engine.dayKey())?.skipped == true
        return GoalManageRow(
            title: habit.title,
            cadence: cadence(habit, language: language, skipped: skipped),
            glyph: GoalActions.glyph(for: habit, store: store),
            done: finished,
            skipped: skipped,
            reduceMotion: engine.reduceMotion,
            moreLabel: engine.t("goals.more"),
            editLabel: engine.t("common.edit"),
            doneLabel: engine.t(finished ? "care.done" : "care.notDone")
        ) {
            editing = habit
        } menu: {
            Button(engine.t("common.edit")) { editing = habit }
            Button(engine.t(finished ? "habit.undo" : "home.complete")) {
                GoalActions.toggleComplete(habit, engine: engine)
                revision += 1
            }
            Button(engine.t("care.moveUp")) { GoalActions.move(habit, direction: -1, engine: engine, rows: rows); revision += 1 }
            Button(engine.t("care.moveDown")) { GoalActions.move(habit, direction: 1, engine: engine, rows: rows); revision += 1 }
            if store.meta.groupMode == "custom" {
                ForEach(store.meta.buckets) { bucket in
                    Button(engine.tf("care.group.assign", bucket.name)) {
                        GoalActions.assign(habit, bucket: bucket.id, store: store)
                        revision += 1
                    }
                }
                Button(engine.t("care.group.loose")) {
                    GoalActions.assign(habit, bucket: "", store: store)
                    revision += 1
                }
            }
        }
    }

    private func cadence(_ habit: Habit, language: String, skipped: Bool) -> String {
        if skipped { return engine.t("care.skipped") }
        let base: String
        switch habit.recurrence {
        case "daily": base = engine.t("goals.cadence.daily")
        case "once": base = engine.t("goals.cadence.once")
        case "weekdays":
            let chosen = Set(habit.weekdays)
            if chosen == Set(GoalRepeat.workdays) {
                base = engine.t("goals.cadence.weekdays")
            } else if chosen == Set(GoalRepeat.weekends) {
                base = engine.t("goals.cadence.weekends")
            } else {
                base = GoalRepeat.summary(recurrence: habit.recurrence, weekdays: habit.weekdays, engine: engine)
            }
        default:
            base = engine.t("recur.\(habit.recurrence)")
        }
        if let area = GoalActions.areaName(for: habit, language: language, store: store), !area.isEmpty {
            return "\(base) · \(area)"
        }
        return base
    }

    private func done(_ habit: Habit) -> Bool {
        let log = engine.habitLog(habit.id, engine.dayKey())
        return (log?.count ?? 0) >= max(1, habit.timesPerDay)
    }

}

private struct GoalManageRow<MenuContent: View>: View {
    var title: String
    var cadence: String
    var glyph: String
    var done: Bool
    var skipped: Bool
    var reduceMotion: Bool
    var moreLabel: String
    var editLabel: String
    var doneLabel: String
    var onOpen: () -> Void
    @ViewBuilder var menu: () -> MenuContent
    @State private var burst = 0

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onOpen) {
                HStack(spacing: 12) {
                    GoalGlyph(glyph: glyph)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(GoalLook.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .bold))
                            Text(cadence)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color(hex: 0x9AA3AB))
                    }
                    Spacer(minLength: 4)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(editLabel)
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: 0x3EAE45))
                    .accessibilityLabel(doneLabel)
            }
            Menu {
                menu()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: 0xC5CAD1))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(moreLabel)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .frame(minHeight: 76)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .opacity(skipped ? 0.72 : 1)
        .overlay {
            if burst > 0 && !reduceMotion {
                RowConfetti(token: burst)
            }
        }
        .onChange(of: done) { was, now in
            guard now, !was, !reduceMotion else { return }
            burst += 1
        }
    }
}

enum GoalFont {
    static let body = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
}
