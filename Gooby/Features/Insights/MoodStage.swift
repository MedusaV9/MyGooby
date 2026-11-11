import SwiftUI

struct MoodComposer: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var level = 3
    @State private var tags: Set<String> = []
    @State private var note = ""
    @State private var saved = false
    @State private var shown = false
    private let tagIDs = ["happy", "grateful", "calm", "motivated", "tired", "sad", "stressed", "overwhelmed"]

    private var still: Bool { systemReduce || engine.reduceMotion }

    var body: some View {
        NavigationStack {
            ZStack {
                moodWash.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        HStack {
                            CalmIconButton(symbol: "xmark", label: engine.t("common.close")) { dismiss() }
                            Spacer()
                        }
                        Text(engine.t("calm.mood.ask"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(InsightsPalette.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ZStack {
                            CalmPet(engine: engine, animation: moodPose(level), reduceMotion: still)
                                .frame(width: 220, height: 220)
                                .id(level)
                                .transition(.scale(scale: 0.92).combined(with: .opacity))
                        }
                        .frame(height: 210)
                        .animation(still ? nil : .spring(response: 0.38, dampingFraction: 0.72), value: level)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { step in
                                Button {
                                    withAnimation(still ? nil : .spring(response: 0.34, dampingFraction: 0.62)) { level = step }
                                    GoobyFeedback.play(.select)
                                } label: {
                                    MoodMark(level: step, selected: level == step)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(engine.t("mood.level.\(step)"))
                                .accessibilityAddTraits(level == step ? .isSelected : AccessibilityTraits())
                            }
                        }
                        Text(engine.t("mood.level.\(level)"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(InsightsPalette.ink)
                            .contentTransition(.opacity)
                        Text(engine.t("calm.mood.tags"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(InsightsPalette.sub)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        CalmWrap(spacing: 8) {
                            ForEach(Array(tagIDs.enumerated()), id: \.element) { index, tag in
                                tagChip(tag, index: index)
                            }
                        }
                        TextField(engine.t("mood.note"), text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .padding(14)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Button(action: save) {
                            HStack(spacing: 8) {
                                if saved {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                                Text(saved ? engine.t("calm.mood.saved") : engine.t("common.save"))
                            }
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(InsightsPalette.positive, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(saved)
                    }
                    .padding(18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                guard !still else { shown = true; return }
                withAnimation(.easeOut(duration: 0.35)) { shown = true }
            }
        }
    }

    private var moodWash: Color {
        switch level {
        case 1: return Color(hex: 0xF8D5DE)
        case 2: return Color(hex: 0xF8E4EC)
        case 4: return Color(hex: 0xE5F6EA)
        case 5: return Color(hex: 0xFFF3D0)
        default: return InsightsPalette.canvas
        }
    }

    private func tagChip(_ tag: String, index: Int) -> some View {
        let on = tags.contains(tag)
        return Button {
            if on { tags.remove(tag) } else { tags.insert(tag) }
            GoobyFeedback.play(.tap)
        } label: {
            HStack(spacing: 6) {
                if let art = feelingArt(tag), PackArt.image(art) != nil {
                    PackImage(name: art, side: 18)
                }
                Text(engine.t("mood.tag.\(tag)"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(on ? Color.white : InsightsPalette.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(on ? InsightsPalette.positive : Color.white, in: Capsule())
            .overlay(Capsule().stroke(on ? Color.clear : InsightsPalette.tagFill, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .scaleEffect(on ? 1.04 : 1)
        .opacity(still || shown ? 1 : 0)
        .offset(y: still || shown ? 0 : 8)
        .animation(still ? nil : .spring(response: 0.32, dampingFraction: 0.74), value: on)
        .animation(still ? nil : .easeOut(duration: 0.3).delay(0.03 * Double(index)), value: shown)
        .accessibilityAddTraits(on ? .isSelected : AccessibilityTraits())
    }

    private func feelingArt(_ tag: String) -> String? {
        switch tag {
        case "happy": return "pack-feeling-happy"
        case "sad": return "pack-feeling-sad"
        case "calm": return "pack-feeling-calm"
        case "stressed", "overwhelmed": return "pack-feeling-worried"
        case "tired": return "pack-feeling-meh"
        default: return nil
        }
    }

    private func save() {
        guard !saved else { return }
        engine.addMood(level: level, tags: Array(tags), note: note)
        withAnimation(still ? nil : .spring(response: 0.32, dampingFraction: 0.7)) { saved = true }
        Task { @MainActor in
            if !still { try? await Task.sleep(nanoseconds: 420_000_000) }
            dismiss()
        }
    }

    private func moodPose(_ level: Int) -> GoobyAnimation {
        switch level {
        case 1: return .sleep
        case 2: return .think
        case 4: return .wave
        case 5: return .celebrate
        default: return .idle
        }
    }
}

struct MoodScreen: View {
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var showAdd = false
    @State private var month = Date()
    @State private var refresh = 0

    private let calendar = Calendar.current
    private var still: Bool { systemReduce || engine.reduceMotion }

    var body: some View {
        let _ = refresh
        let marks = moodMarks()
        let months = InsightsLedger.months(ending: month, marks: marks, calendar: calendar, count: 1)
        InsightsScreen(title: engine.t("mood.title"), back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 14) {
                Button { showAdd = true } label: {
                    InsightsPill(title: engine.t("mood.add"), fill: InsightsPalette.positive, ink: .white)
                }
                .buttonStyle(.plain)
                Text(engine.t("calm.mood.ask"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(InsightsPalette.sub)
                Text(summary(days: 7)).foregroundStyle(InsightsPalette.ink)
                Text(summary(days: 30)).foregroundStyle(InsightsPalette.sub)
                if let field = months.first {
                    monthHeader
                    MoodDotMonth(engine: engine, month: field, today: engine.now(), still: still)
                        .id(field.id)
                    legend
                }
                Text(engine.t("calm.mood.history"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(InsightsPalette.ink)
                entries()
            }
        }
        .sheet(isPresented: $showAdd, onDismiss: { refresh += 1 }) {
            MoodComposer(engine: engine)
        }
    }

    private var monthHeader: some View {
        HStack {
            Text(monthTitle)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(InsightsPalette.ink)
            Spacer()
            Button { shift(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("insights.history.earlier"))
            Button { shift(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.35 : 1)
            .accessibilityLabel(engine.t("insights.history.later"))
        }
        .foregroundStyle(InsightsPalette.ink)
    }

    private var legend: some View {
        Group {
            if PackArt.image("pack-mood-1-calendar") != nil {
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { level in
                        VStack(spacing: 2) {
                            PackImage(name: "pack-mood-\(level)-calendar", side: 20)
                            Text("\(level)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(InsightsPalette.sub)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(engine.t("mood.level.\(level)"))
                    }
                }
            } else {
                HStack(spacing: 14) {
                    legendItem(.positive)
                    legendItem(.neutral)
                    legendItem(.negative)
                }
            }
        }
    }

    private func legendItem(_ tone: InsightsTone) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(swatch(tone))
                .frame(width: 14, height: 14)
            Text(engine.t("insights.legend.\(tone.rawValue)"))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(InsightsPalette.ink.opacity(0.8))
        }
    }

    @ViewBuilder
    private func entries() -> some View {
        let rows = monthEntries()
        if rows.isEmpty {
            Text(engine.t("calm.mood.empty"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(InsightsPalette.sub)
        } else {
            ForEach(rows, id: \.id) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        moodFace(entry.level)
                        Text(engine.t("mood.level.\(entry.level)"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Spacer(minLength: 8)
                        Text(engine.formatDate(entry.recordedAt, time: true))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsPalette.sub)
                    }
                    let names = entry.tags.map { engine.t("mood.tag.\($0)") }.filter { !$0.isEmpty }
                    if !names.isEmpty {
                        Text(names.joined(separator: ", "))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsPalette.sub)
                    }
                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(InsightsPalette.ink)
                    }
                }
                .foregroundStyle(InsightsPalette.ink)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .contextMenu {
                    Button(engine.t("common.delete"), role: .destructive) {
                        engine.deleteMood(entry)
                        refresh += 1
                    }
                }
            }
        }
    }

    private func summary(days: Int) -> String {
        let cutoff = calendar.date(byAdding: .day, value: -days, to: engine.now()) ?? engine.now()
        let rows = engine.all(MoodEntry.self).filter { $0.recordedAt >= cutoff }
        guard !rows.isEmpty else { return engine.tf(days == 7 ? "mood.week.empty" : "mood.month.empty", days) }
        let average = Double(rows.map(\.level).reduce(0, +)) / Double(rows.count)
        let counts = Dictionary(grouping: rows.flatMap(\.tags), by: { $0 }).mapValues(\.count)
        let top = counts.max { $0.value < $1.value }?.key
        let tone = average >= 4 ? engine.t("mood.tone.bright") : (average >= 3 ? engine.t("mood.tone.steady") : engine.t("mood.tone.tender"))
        let tag = top.map { engine.t("mood.tag.\($0)") } ?? engine.t("common.none")
        return engine.tf(days == 7 ? "mood.week" : "mood.month", tone, tag, average)
    }

    private func moodMarks() -> [InsightsMoodMark] {
        engine.all(MoodEntry.self).map { entry in
            InsightsMoodMark(
                dayKey: entry.dayKey.isEmpty ? DayKey.make(entry.recordedAt, calendar: calendar) : entry.dayKey,
                recordedAt: entry.recordedAt,
                level: entry.level,
                tags: entry.tags
            )
        }
    }

    private func monthEntries() -> [MoodEntry] {
        let key = InsightsLedger.monthID(month, calendar: calendar)
        return engine.all(MoodEntry.self)
            .filter { entry in
                let day = entry.dayKey.isEmpty ? DayKey.make(entry.recordedAt, calendar: calendar) : entry.dayKey
                return String(day.prefix(7)) == key
            }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    private var monthTitle: String {
        InsightsFormat.monthTitle(month, language: engine.languageCode, calendar: calendar)
    }

    private var isCurrentMonth: Bool {
        InsightsLedger.monthID(month, calendar: calendar) >= InsightsLedger.monthID(engine.now(), calendar: calendar)
    }

    private func shift(_ delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: month) else { return }
        if delta > 0 && InsightsLedger.monthID(next, calendar: calendar) > InsightsLedger.monthID(engine.now(), calendar: calendar) {
            return
        }
        GoobyFeedback.play(.select)
        withAnimation(still ? nil : .easeInOut(duration: 0.28)) { month = next }
    }

    @ViewBuilder
    private func moodFace(_ level: Int) -> some View {
        let name = "pack-mood-\(min(5, max(1, level)))-calendar"
        if PackArt.image(name) != nil {
            PackImage(name: name, side: 28)
        } else {
            Circle().fill(swatch(InsightsLedger.tone(level: level) ?? .neutral)).frame(width: 12, height: 12)
        }
    }

    private func swatch(_ tone: InsightsTone) -> Color {
        switch tone {
        case .positive: return InsightsPalette.positive
        case .neutral: return InsightsPalette.neutral
        case .negative: return InsightsPalette.negative
        }
    }
}

private struct MoodDotMonth: View {
    var engine: GoobyEngine
    var month: InsightsMonth
    var today: Date
    var still: Bool
    @State private var shown = false

    private let calendar = Calendar.current

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            weekColumns
            weekdayLabels
        }
        .onAppear {
            guard !still else { return }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { shown = true }
        }
    }

    private var weekColumns: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(0..<month.weekCount, id: \.self) { week in
                VStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { row in
                        dot(month.cell(week: week, row: row), week: week, row: row)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var weekdayLabels: some View {
        let todayRow = InsightsLedger.mondayRow(today, calendar: calendar)
        return VStack(alignment: .trailing, spacing: 4) {
            ForEach(0..<7, id: \.self) { row in
                Text(name(row, today: todayRow))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(row == todayRow ? InsightsPalette.ink : InsightsPalette.sub)
                    .frame(height: 22, alignment: .trailing)
            }
        }
        .frame(width: 36, alignment: .trailing)
    }

    private func dot(_ cell: InsightsDot?, week: Int, row: Int) -> some View {
        let tone = cell?.inMonth == true ? cell?.tone : nil
        let level = latestLevel(cell)
        let face = level.map { "pack-mood-\(min(5, max(1, $0)))-calendar" }
        return ZStack {
            if let face, PackArt.image(face) != nil {
                PackImage(name: face, side: 20)
            } else {
                Circle()
                    .fill(cell?.inMonth == true ? color(tone) : Color.clear)
                    .frame(width: 10, height: 10)
            }
        }
            .frame(width: 22, height: 22)
            .scaleEffect(still || shown ? 1 : 0.2)
            .opacity(still || shown ? 1 : 0)
            .animation(
                still ? nil : .spring(response: 0.38, dampingFraction: 0.7).delay(Double(week) * 0.04 + Double(row) * 0.02),
                value: shown
            )
            .accessibilityHidden(cell?.inMonth != true)
            .accessibilityLabel(label(cell, tone: tone))
    }

    private func latestLevel(_ cell: InsightsDot?) -> Int? {
        guard let cell, cell.inMonth, cell.tone != nil else { return nil }
        let rows = engine.all(MoodEntry.self).filter { entry in
            let day = entry.dayKey.isEmpty ? DayKey.make(entry.recordedAt, calendar: calendar) : entry.dayKey
            return day == cell.dayKey
        }
        return rows.max(by: { $0.recordedAt < $1.recordedAt })?.level
    }

    private func color(_ tone: InsightsTone?) -> Color {
        switch tone {
        case .positive: return InsightsPalette.positive
        case .neutral: return InsightsPalette.neutral
        case .negative: return InsightsPalette.negative
        case nil: return InsightsPalette.emptyDot
        }
    }

    private func name(_ row: Int, today: Int) -> String {
        var symbolsCalendar = calendar
        symbolsCalendar.locale = Locale(identifier: engine.languageCode)
        let symbols = symbolsCalendar.shortWeekdaySymbols
        let index = (row + 1) % 7
        let raw = symbols.indices.contains(index) ? symbols[index] : ""
        if row == today { return engine.tf("insights.weekday.today", raw) }
        return raw
    }

    private func label(_ cell: InsightsDot?, tone: InsightsTone?) -> String {
        guard let cell, cell.inMonth, let date = DayKey.parse(cell.dayKey, calendar: calendar) else { return "" }
        let day = InsightsFormat.medium(date, language: engine.languageCode, calendar: calendar)
        if let level = latestLevel(cell) {
            return engine.tf("insights.dot.tone", day, engine.t("mood.level.\(level)"))
        }
        let toneName = tone.map { engine.t("insights.legend.\($0.rawValue)") } ?? engine.t("insights.dot.empty")
        return engine.tf("insights.dot.tone", day, toneName)
    }
}

private struct MoodMark: View {
    var level: Int
    var selected: Bool

    var body: some View {
        ZStack {
            if PackArt.image("pack-mood-\(level)") != nil {
                PackImage(name: "pack-mood-\(level)", side: 48)
            } else {
                Circle().fill(fill)
                eyes
                MoodMouth(lift: lift)
                    .stroke(Color(hex: 0x3D3656), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 16, height: 8)
                    .offset(y: 8)
            }
        }
        .frame(width: 48, height: 48)
        .scaleEffect(selected ? 1.16 : 0.92)
        .overlay(Circle().stroke(Color.white, lineWidth: selected ? 3 : 0).padding(-2))
        .shadow(color: fill.opacity(selected ? 0.45 : 0), radius: 6, y: 3)
        .animation(.spring(response: 0.34, dampingFraction: 0.62), value: selected)
    }

    private var fill: Color {
        switch level {
        case 1: return Color(hex: 0xF09AAA)
        case 2: return Color(hex: 0xF3B7C8)
        case 4: return Color(hex: 0x8ED9A8)
        case 5: return Color(hex: 0xF2C14D)
        default: return Color(hex: 0xD5D8E0)
        }
    }

    private var lift: CGFloat {
        switch level {
        case 1: return -7
        case 2: return -3
        case 4: return 6
        case 5: return 10
        default: return 0
        }
    }

    private var eyes: some View {
        HStack(spacing: 10) {
            Capsule()
                .fill(Color(hex: 0x3D3656))
                .frame(width: level == 1 ? 8 : 4, height: level == 1 ? 2.5 : 7)
            Capsule()
                .fill(Color(hex: 0x3D3656))
                .frame(width: level == 1 ? 8 : 4, height: level == 1 ? 2.5 : 7)
        }
        .offset(y: -6)
    }
}

private struct MoodMouth: Shape {
    var lift: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.midY + lift)
        )
        return path
    }
}
