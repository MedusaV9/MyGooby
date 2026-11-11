import SwiftUI

struct GoalListScreen: View {
    var engine: GoobyEngine
    @State private var store = GoalMetaStore()
    @State private var revision = 0
    @State private var filter = "any"
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
        let tucked: Habit? = store.meta.groupMode == "time" && filter == "any" ? rows.first { isReferenceBed($0) } : nil
        GeometryReader { geo in
            let top = max(geo.safeAreaInsets.top, 47)
            ZStack(alignment: .top) {
                GoalLook.green.ignoresSafeArea()
                VStack(spacing: 0) {
                    header(topInset: top, bed: filter == "any" ? tucked : nil)
                    ScrollView {
                        VStack(spacing: 9) {
                            if store.meta.groupMode == "custom" {
                                Button {
                                    bucketName = ""
                                    showBucket = true
                                } label: {
                                    Text(engine.t("care.group.add"))
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                            let listed = rows.filter { tucked == nil || $0.id != tucked?.id }
                            let sections = GoalActions.sections(for: listed, engine: engine, store: store)
                            ForEach(sections) { section in
                                sectionBlock(section, language: language)
                            }
                            if rows.isEmpty {
                                Text(engine.t("care.empty"))
                                    .font(GoalFont.body)
                                    .foregroundStyle(Color.white.opacity(0.92))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }
                            addButton
                            GoalWave()
                                .fill(GoalLook.wave)
                                .frame(height: 24)
                                .padding(.horizontal, -16)
                                .padding(.top, 13)
                                .accessibilityHidden(true)
                            supportCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 2)
                        .padding(.bottom, 28)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
                        .fill(Color.white.opacity(0.45))
                        .frame(height: 1.5)
                }
                .foregroundStyle(Color.white)
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
                && GoalActions.matches(daypart: filter, habit: habit, store: store)
        }
    }

    private func isReferenceBed(_ habit: Habit) -> Bool {
        if store.meta.links[habit.id.uuidString] == "get-out-of-bed" { return true }
        guard let suggestion = GoalCatalog.suggestion("get-out-of-bed") else { return false }
        return GoalCatalog.matches(habit, suggestion)
    }

    private func header(topInset: CGFloat, bed: Habit?) -> some View {
        VStack(spacing: 21) {
            ZStack(alignment: .bottom) {
                if let bed {
                    goalCard(bed, language: engine.languageCode, rows: visibleRows)
                        .blur(radius: engine.reduceMotion ? 0 : 2)
                        .opacity(0.5)
                        .offset(y: -4)
                        .allowsHitTesting(false)
                    HStack {
                        Button {
                            editing = bed
                        } label: {
                            Color.clear.frame(width: 180, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(bed.title)
                        Spacer()
                        Button {
                            GoalActions.toggleComplete(bed, engine: engine)
                            revision += 1
                        } label: {
                            Color.clear.frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(done(bed) ? engine.t("care.done") : engine.t("care.notDone"))
                        Color.clear.frame(width: 46, height: 44)
                    }
                }
                HStack {
                    NavigationLink {
                        SelfCareAreasScreen(engine: engine, store: store) { revision += 1 }
                    } label: {
                        MenuBlob()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.t("care.areas"))
                    Spacer()
                    Button {
                        engine.haptics.soft()
                        engine.petAction(.laugh)
                    } label: {
                        PetFaceButton()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.profile.goobyName)
                }
            }
            .frame(height: 70)
            filterRow
        }
        .padding(.horizontal, 16)
        .padding(.top, topInset - 14)
    }

    private var filterRow: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(GoalDaypart.order, id: \.self) { part in
                    Button(engine.t("care.filter.\(part)")) { filter = part }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(engine.t("care.filter.\(filter)"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    ChevronMark(direction: .down)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .frame(width: 10, height: 6)
                }
                .foregroundStyle(Color.white)
            }
            Rectangle()
                .fill(GoalLook.line)
                .frame(height: 1.5)
            Button {
                showGroup = true
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("care.group.button"))
            Button {
                showAdd = true
            } label: {
                ZStack {
                    Circle().fill(Color.white.opacity(0.25))
                    PlusMark().fill(Color.white).frame(width: 10, height: 10)
                }
                .frame(width: 22, height: 22)
                .frame(width: 32, height: 32)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("care.add"))
        }
    }

    private func goalCard(_ habit: Habit, language: String, rows: [Habit]) -> some View {
        let finished = done(habit)
        let skipped = engine.habitLog(habit.id, engine.dayKey())?.skipped == true
        let area = GoalActions.areaName(for: habit, language: language, store: store)
        return HStack(spacing: 2) {
            Menu {
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
            } label: {
                GripDots()
            }
            .buttonStyle(.plain)
            Button {
                editing = habit
            } label: {
                HStack(spacing: 11) {
                    GoalGlyph(glyph: GoalActions.glyph(for: habit, store: store))
                        .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(habit.title)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(GoalLook.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        if let area {
                            Text(area)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(GoalLook.subtitle)
                        } else if skipped {
                            Text(engine.t("care.skipped"))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(GoalLook.subtitle)
                        }
                    }
                    Spacer(minLength: 4)
                }
            }
            .buttonStyle(.plain)
            GoalEnergyText(value: habit.energyReward, linked: !GoalActions.linkedExerciseID(habit, store: store).isEmpty, engine: engine)
            GoalRowFinish(engine: engine, habit: habit, linked: !GoalActions.linkedExerciseID(habit, store: store).isEmpty, done: finished) {
                GoalActions.toggleComplete(habit, engine: engine)
                revision += 1
            }
        }
        .padding(.leading, 2)
        .padding(.trailing, 10)
        .padding(.vertical, 8)
        .frame(minHeight: 72)
        .background(Color.white, in: RoundedRectangle(cornerRadius: GoalLook.cardRadius, style: .continuous))
        .opacity(skipped ? 0.72 : 1)
    }

    private func done(_ habit: Habit) -> Bool {
        let log = engine.habitLog(habit.id, engine.dayKey())
        return (log?.count ?? 0) >= max(1, habit.timesPerDay)
    }

    private var addButton: some View {
        Button {
            showAdd = true
        } label: {
            HStack(spacing: 18) {
                ZStack {
                    Circle().fill(GoalLook.plusDisc)
                    PlusMark().fill(Color.white).frame(width: 16, height: 16)
                }
                .frame(width: 40, height: 40)
                Text(engine.t("care.add"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(GoalLook.button, in: RoundedRectangle(cornerRadius: GoalLook.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 23)
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(engine.t("care.support"))
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .padding(.leading, 6)
                .padding(.top, 8)
            HStack(alignment: .center, spacing: 12) {
                RocketMark()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.t("care.support.title"))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(GoalLook.ink)
                    Text(engine.t("care.support.detail"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: 0x8E8E93))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

enum GoalFont {
    static let body = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
}
