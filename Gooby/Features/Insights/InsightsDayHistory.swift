import SwiftUI

struct InsightsDayHistory: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var picked: Date?
    @State private var openID: UUID?
    @State private var addGoal = false
    @State private var addNote = false
    @State private var refresh = 0

    private let calendar = Calendar.current

    private var still: Bool { reduceMotion || systemReduce || engine.reduceMotion }
    private var today: Date { calendar.startOfDay(for: engine.now()) }
    private var day: Date { calendar.startOfDay(for: picked ?? today) }

    var body: some View {
        let _ = refresh
        let snapshot = InsightsReader.snapshot(engine)
        let page = InsightsLedger.daySnapshot(snapshot, on: day, calendar: calendar)
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    goalSection(page.goals)
                    noteSection(page.notes)
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(InsightsPalette.canvas)
        }
        .background(InsightsPalette.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: detailShown, onDismiss: { refresh += 1 }) {
            NavigationStack {
                if let id = openID, let habit = engine.habits().first(where: { $0.id == id }) {
                    HabitDetail(engine: engine, habit: habit)
                } else {
                    Text(engine.t("insights.history.missing"))
                        .foregroundStyle(InsightsPalette.ink)
                        .padding(24)
                }
            }
        }
        .sheet(isPresented: $addGoal, onDismiss: { refresh += 1 }) {
            NavigationStack { HabitEditor(engine: engine, habit: nil) }
        }
        .sheet(isPresented: $addNote, onDismiss: { refresh += 1 }) {
            NavigationStack { JournalScreen(engine: engine) }
        }
    }

    private var detailShown: Binding<Bool> {
        Binding(get: { openID != nil }, set: { if !$0 { openID = nil } })
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.18), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("common.close"))
                Spacer()
                HStack(spacing: 6) {
                    stepButton("chevron.left", engine.t("insights.history.earlier"), -1)
                    Menu {
                        Button(engine.t("insights.history.jump")) { picked = today }
                        ForEach(recentDays) { item in
                            Button(item.title) { picked = item.date }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                            Text(heading)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .accessibilityLabel(heading)
                    stepButton("chevron.right", engine.t("insights.history.later"), 1)
                        .disabled(calendar.isDate(day, inSameDayAs: today))
                        .opacity(calendar.isDate(day, inSameDayAs: today) ? 0.45 : 1)
                }
                .foregroundStyle(.white)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            weekStrip
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .background(InsightsPalette.history.ignoresSafeArea(edges: .top))
    }

    private var weekStrip: some View {
        let days = InsightsLedger.weekDates(containing: day, calendar: calendar)
        return HStack(spacing: 4) {
            ForEach(days, id: \.self) { date in
                let selected = calendar.isDate(date, inSameDayAs: day)
                Button {
                    guard date <= today else { return }
                    picked = date
                } label: {
                    VStack(spacing: 3) {
                        Text(veryShort(date))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                            .opacity(selected ? 1 : 0)
                    }
                    .foregroundStyle(.white.opacity(date > today ? 0.45 : 1))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(selected ? Color.white.opacity(0.22) : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(date > today)
                .accessibilityLabel(InsightsFormat.medium(date, language: engine.languageCode, calendar: calendar))
                .accessibilityAddTraits(selected ? .isSelected : AccessibilityTraits())
            }
        }
        .animation(still ? nil : .easeOut(duration: 0.2), value: day)
    }

    private func goalSection(_ goals: [InsightsDayGoal]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundStyle(InsightsPalette.positive)
                Text(goalHeading(goals.count))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                Spacer()
                Button {
                    addGoal = true
                } label: {
                    plus
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("habit.new"))
            }
            if goals.isEmpty {
                Text(engine.t("insights.history.emptyGoals"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
            }
            ForEach(goals) { goal in
                goalRow(goal)
            }
        }
    }

    private func goalRow(_ goal: InsightsDayGoal) -> some View {
        HStack(spacing: 10) {
            Button {
                openID = goal.id
            } label: {
                HStack(spacing: 10) {
                    GoalGlyph(glyph: GoalArt.glyph(forSymbol: goal.icon))
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(InsightsPalette.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        status(goal)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 4)
            Menu {
                Button(engine.t("insights.history.open")) { openID = goal.id }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(InsightsPalette.sub)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel(engine.t("insights.history.open"))
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func status(_ goal: InsightsDayGoal) -> some View {
        switch goal.state {
        case .first:
            label(engine.t("insights.history.first"), symbol: "checkmark", tint: InsightsPalette.positive)
        case .done:
            label(engine.t("insights.history.done"), symbol: "checkmark", tint: InsightsPalette.positive)
        case .skipped:
            label(engine.t("insights.history.skipped"), symbol: "minus", tint: InsightsPalette.sub)
        case .open:
            label(engine.t("recur.\(goal.recurrence)"), symbol: "arrow.triangle.2.circlepath", tint: InsightsPalette.sub)
        }
    }

    private func label(_ text: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .foregroundStyle(tint)
    }

    private func noteSection(_ notes: [InsightsNoteMark]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "pencil")
                    .foregroundStyle(InsightsPalette.ink)
                Text(noteHeading(notes.count))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                Spacer()
                Button {
                    addNote = true
                } label: {
                    plus
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("journal.new"))
            }
            ForEach(notes) { note in
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? engine.t("journal.untitled") : note.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(InsightsPalette.ink)
                    if note.written {
                        Text(note.body)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsPalette.sub)
                            .lineLimit(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var plus: some View {
        Image(systemName: "plus")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(InsightsPalette.positive, in: Circle())
    }

    private var heading: String {
        let label = InsightsFormat.dayMonth(day, language: engine.languageCode, calendar: calendar)
        if calendar.isDate(day, inSameDayAs: today) {
            return engine.tf("insights.history.today", label)
        }
        return label
    }

    private var recentDays: [RecentDay] {
        (0..<21).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return RecentDay(
                id: DayKey.make(date, calendar: calendar),
                date: date,
                title: InsightsFormat.dayMonth(date, language: engine.languageCode, calendar: calendar)
            )
        }
    }

    private func stepButton(_ symbol: String, _ label: String, _ delta: Int) -> some View {
        Button {
            shift(delta)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func shift(_ delta: Int) {
        guard let next = calendar.date(byAdding: .day, value: delta, to: day) else { return }
        let start = calendar.startOfDay(for: next)
        guard start <= today else { return }
        picked = start
    }

    private func veryShort(_ date: Date) -> String {
        var symbolsCalendar = calendar
        symbolsCalendar.locale = Locale(identifier: engine.languageCode)
        let symbols = symbolsCalendar.veryShortWeekdaySymbols
        let index = calendar.component(.weekday, from: date) - 1
        guard symbols.indices.contains(index) else { return "" }
        return symbols[index]
    }

    private func goalHeading(_ count: Int) -> String {
        count == 1 ? engine.t("insights.history.goals.one") : engine.tf("insights.history.goals", count)
    }

    private func noteHeading(_ count: Int) -> String {
        if count == 0 { return engine.t("insights.history.none") }
        if count == 1 { return engine.t("insights.history.notes.one") }
        return engine.tf("insights.history.notes", count)
    }
}

private struct RecentDay: Identifiable {
    var id: String
    var date: Date
    var title: String
}
