import SwiftUI

struct MoodHomeView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @State private var level: MoodLevel = .neutral
    @State private var tags: Set<MoodTag> = []
    @State private var note = ""
    @State private var banner = ""
    @State private var showCalendar = false

    var body: some View {
        CareScreen {
            Text(session.text(.moodQuestion))
                .font(.title3.weight(.semibold))
                .foregroundStyle(CarePalette.ink)
            HStack(spacing: 8) {
                ForEach(MoodLevel.allCases) { item in
                    Button {
                        level = item
                    } label: {
                        VStack(spacing: 6) {
                            MoodFace(level: item, selected: level == item)
                            Text(CareCopy.mood(item, session.language))
                                .font(.caption2)
                                .foregroundStyle(CarePalette.ink)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(CareCopy.mood(item, session.language))
                    .accessibilityAddTraits(level == item ? .isSelected : [])
                }
            }
            Text(session.text(.moodTags))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CarePalette.ink)
            CareFlowLayout {
                ForEach(MoodTag.allCases) { tag in
                    Button {
                        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
                    } label: {
                        Text(CareCopy.tag(tag, session.language))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(CarePalette.ink)
                            .background(Capsule().fill(tags.contains(tag) ? CarePalette.peach : CarePalette.card))
                    }
                    .buttonStyle(.plain)
                }
            }
            TextField(session.text(.moodNote), text: $note, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
            if !banner.isEmpty {
                Text(banner).font(.footnote).foregroundStyle(CarePalette.ink)
            }
            Button(session.text(.moodSave)) { save() }.buttonStyle(CarePrimaryButton())
            todayList
            trendCard(title: session.text(.moodWeek), trend: store.weekTrend(ending: session.todayKey, calendar: session.calendar))
            trendCard(title: session.text(.moodMonth), trend: store.monthTrend(containing: session.todayKey, calendar: session.calendar))
            Button(session.text(.moodCalendar)) { showCalendar = true }.buttonStyle(CarePrimaryButton())
            Text(session.text(.disclaimer))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
            Text(session.text(.notShared))
                .font(.footnote)
                .foregroundStyle(CarePalette.ink.opacity(0.7))
        }
        .navigationTitle(session.text(.tabMood))
        .careGroundingShortcut()
        .navigationDestination(isPresented: $showCalendar) {
            MoodCalendarView()
        }
    }

    private var todayList: some View {
        let entries = store.moods(on: session.todayKey)
        return VStack(alignment: .leading, spacing: 10) {
            if !entries.isEmpty {
                Text(session.text(.moodAddAnother))
                    .font(.headline)
                    .foregroundStyle(CarePalette.ink)
            }
            ForEach(entries) { entry in
                CareCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(CareCopy.mood(entry.level, session.language))
                            .font(.headline)
                            .foregroundStyle(CarePalette.ink)
                        if !entry.tags.isEmpty {
                            Text(entry.tags.map { CareCopy.tag($0, session.language) }.joined(separator: " · "))
                                .font(.subheadline)
                                .foregroundStyle(CarePalette.ink.opacity(0.75))
                        }
                        if !entry.note.isEmpty {
                            Text(entry.note).foregroundStyle(CarePalette.ink)
                        }
                        Button(session.text(.moodToJournal)) {
                            _ = store.createJournal(from: entry.id, language: session.language, now: session.now)
                            banner = session.text(.moodSaved)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarePalette.ink)
                    }
                }
            }
        }
    }

    private func trendCard(title: String, trend: MoodTrend) -> some View {
        CareCard(fill: CarePalette.sky.opacity(0.8)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline).foregroundStyle(CarePalette.ink)
                if let average = trend.average {
                    Text(session.format(.moodAverage, formatted(average)))
                        .foregroundStyle(CarePalette.ink)
                    Text(direction(trend)).font(.subheadline).foregroundStyle(CarePalette.ink.opacity(0.8))
                    if let previous = trend.previousAverage {
                        Text(session.format(.moodPrevious, formatted(previous)))
                            .font(.caption)
                            .foregroundStyle(CarePalette.ink.opacity(0.7))
                    }
                    Text(session.format(.moodEntries, trend.entryCount))
                        .font(.caption)
                        .foregroundStyle(CarePalette.ink.opacity(0.7))
                    bars(trend)
                    if !trend.tagCounts.isEmpty {
                        Text(trend.tagCounts.map { "\(CareCopy.tag($0.tag, session.language)) \($0.count)" }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(CarePalette.ink)
                    }
                } else {
                    Text(session.text(.moodNoData)).foregroundStyle(CarePalette.ink)
                }
            }
        }
    }

    private func bars(_ trend: MoodTrend) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(trend.daily.enumerated()), id: \.offset) { _, item in
                VStack {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color(for: item.average))
                        .frame(height: CGFloat(item.average) / 5 * 64)
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .accessibilityLabel("\(item.day) \(formatted(item.average))")
            }
        }
    }

    private func save() {
        _ = store.addMood(day: session.todayKey, level: level, tags: Array(tags), note: note, now: session.now)
        note = ""
        tags = []
        banner = session.text(.moodSaved)
        CareHaptics.success()
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.1f", locale: Locale(identifier: session.language.localeIdentifier), value)
    }

    private func direction(_ trend: MoodTrend) -> String {
        switch trend.direction {
        case .up: return session.text(.trendUp)
        case .down: return session.text(.trendDown)
        case .flat: return session.text(.trendFlat)
        case .unknown: return session.text(.moodNoData)
        }
    }

    private func color(for average: Double) -> Color {
        switch average {
        case ..<1.5: return CarePalette.lavender
        case ..<2.5: return CarePalette.peach
        case ..<3.5: return CarePalette.yellow
        case ..<4.5: return CarePalette.mint
        default: return CarePalette.sky
        }
    }
}

struct MoodFace: View {
    var level: MoodLevel
    var selected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: 52, height: 52)
            MoodFaceDrawing(level: level)
                .frame(width: 52, height: 52)
        }
        .overlay(Circle().stroke(CarePalette.ink, lineWidth: selected ? 3 : 0))
    }

    private var fill: Color {
        switch level {
        case .veryBad: return CarePalette.lavender
        case .bad: return CarePalette.peach
        case .neutral: return CarePalette.yellow
        case .good: return CarePalette.mint
        case .veryGood: return CarePalette.sky
        }
    }
}

private struct MoodFaceDrawing: View {
    var level: MoodLevel

    var body: some View {
        Canvas { context, size in
            let eyeY = size.height * 0.38
            let left = CGRect(x: size.width * 0.28, y: eyeY, width: 5, height: 6)
            let right = CGRect(x: size.width * 0.62, y: eyeY, width: 5, height: 6)
            context.fill(Path(ellipseIn: left), with: .color(CarePalette.ink))
            context.fill(Path(ellipseIn: right), with: .color(CarePalette.ink))
            var mouth = Path()
            let smile = CGFloat(level.rawValue - 3) * 4
            mouth.move(to: CGPoint(x: size.width * 0.32, y: size.height * 0.66))
            mouth.addQuadCurve(
                to: CGPoint(x: size.width * 0.68, y: size.height * 0.66),
                control: CGPoint(x: size.width * 0.5, y: size.height * 0.66 + smile)
            )
            context.stroke(mouth, with: .color(CarePalette.ink), lineWidth: 2)
        }
    }
}

struct MoodCalendarView: View {
    @EnvironmentObject private var store: CareStore
    @EnvironmentObject private var session: CareSession
    @State private var month: String = ""
    @State private var selected: String = ""

    var body: some View {
        CareScreen {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthTitle).font(.headline).foregroundStyle(CarePalette.ink)
                Spacer()
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
            }
            .foregroundStyle(CarePalette.ink)
            let cells = CareDay.monthCells(containing: visibleMonth, calendar: session.calendar)
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdayOrder, id: \.self) { weekday in
                    Text(CareCopy.weekday(weekday, session.language))
                        .font(.caption2)
                        .foregroundStyle(CarePalette.ink.opacity(0.7))
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, key in
                    if let key {
                        dayCell(key)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
            if !selected.isEmpty {
                Text(CareDay.format(selected, language: session.language, calendar: session.calendar, template: "EEEE d MMMM"))
                    .font(.headline)
                    .foregroundStyle(CarePalette.ink)
                ForEach(store.moods(on: selected)) { entry in
                    CareCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(CareCopy.mood(entry.level, session.language)).foregroundStyle(CarePalette.ink)
                            if !entry.note.isEmpty { Text(entry.note).foregroundStyle(CarePalette.ink) }
                        }
                    }
                }
            }
            let trend = store.monthTrend(containing: visibleMonth, calendar: session.calendar)
            if let average = trend.average {
                Text(session.format(.moodAverage, String(format: "%.1f", average)))
                    .foregroundStyle(CarePalette.ink)
            } else {
                Text(session.text(.moodNoData)).foregroundStyle(CarePalette.ink)
            }
        }
        .navigationTitle(session.text(.moodCalendar))
        .onAppear {
            if month.isEmpty { month = session.todayKey }
            if selected.isEmpty { selected = session.todayKey }
        }
    }

    private var visibleMonth: String { month.isEmpty ? session.todayKey : month }
    private var monthTitle: String {
        CareDay.format(visibleMonth, language: session.language, calendar: session.calendar, template: "MMMM y")
    }
    private var weekdayOrder: [Int] {
        let first = session.calendar.firstWeekday
        return (0..<7).map { (($0 + first - 1) % 7) + 1 }
    }

    private func dayCell(_ key: String) -> some View {
        let entries = store.moods(on: key)
        let average = MoodMath.mean(entries.map { Double($0.level.rawValue) })
        return Button {
            selected = key
        } label: {
            Text(String(key.suffix(2)))
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 36)
                .foregroundStyle(CarePalette.ink)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(fill(average, selected: key == selected))
                )
        }
        .buttonStyle(.plain)
    }

    private func fill(_ average: Double?, selected: Bool) -> Color {
        if selected { return CarePalette.lavender }
        guard let average else { return CarePalette.card }
        switch average {
        case ..<2.5: return CarePalette.peach
        case ..<3.5: return CarePalette.yellow
        default: return CarePalette.mint
        }
    }

    private func shift(_ months: Int) {
        if let next = CareDay.shiftMonth(containing: visibleMonth, by: months, calendar: session.calendar) {
            month = next
        }
    }
}
