import SwiftUI

/// Mood check-in sheet (Home's smiley button and the mood screen): five faces, feelings, a note.
struct MoodComposer: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    private var reduceMotion: Bool { systemReduce || appReduce || engine.reduceMotion }
    @State private var level = 3
    @State private var tags: Set<String> = []
    @State private var note = ""

    var body: some View {
        NavigationStack {
            MenuScroll {
                GCard {
                    VStack(spacing: 14) {
                        Text(engine.t("mood.level.\(level)"))
                            .font(Theme.Fonts.title)
                            .foregroundStyle(Theme.text)
                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    MomentHub.shared.emit(.tap)
                                    goobyAnimate(reduceMotion, .spring(response: 0.3, dampingFraction: 0.55)) { level = value }
                                } label: {
                                    Text(verbatim: MenuMoodArt.face(value))
                                        .font(.system(size: 34))
                                        .scaleEffect(level == value ? 1.18 : 0.88)
                                        .rotationEffect(.degrees(level == value && !reduceMotion ? -6 : 0))
                                        .frame(maxWidth: .infinity, minHeight: 58)
                                        .background(level == value ? Theme.Tab.menu.moodLevel(value) : Theme.keyFace, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(level == value ? Theme.text.opacity(0.18) : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(engine.t("mood.level.\(value)"))
                                .accessibilityAddTraits(level == value ? .isSelected : [])
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                MenuSectionHeader(text: engine.tx("menu.mood.feelings", de: "Gefühle", en: "Feelings"))
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(MenuMoodArt.tagIDs, id: \.self) { tag in
                        MenuChip(title: engine.t("mood.tag.\(tag)"), icon: MenuMoodArt.tag(tag), selected: tags.contains(tag), tint: Theme.Tab.quests.orange) {
                            if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                MenuSectionHeader(text: engine.t("mood.note"))
                MenuField(placeholder: engine.t("mood.note"), text: $note, axis: .vertical)
                Button {
                    engine.addMood(level: level, tags: Array(tags), note: note)
                    dismiss()
                } label: {
                    Text(engine.t("common.save"))
                }
                .menuPrimaryButton(fill: Theme.Tab.quests.orange)
                .padding(.top, 6)
            }
            .menuChrome(engine, title: engine.t("mood.add"), close: true, background: Theme.Tab.menu.mood)
        }
    }
}

/// Mood tracker: week and month summaries, a month calendar and the history.
struct MoodScreen: View {
    var engine: GoobyEngine
    @State private var showAdd = false
    @State private var month = Date()

    var body: some View {
        let entries = engine.all(MoodEntry.self).sorted { $0.recordedAt > $1.recordedAt }
        MenuScroll {
            Button {
                showAdd = true
            } label: {
                HStack(spacing: 10) {
                    Text(verbatim: "😊").font(.system(size: 26))
                    Text(engine.t("mood.add"))
                }
            }
            .menuPrimaryButton(fill: Theme.Tab.quests.orange)
            summaryCard(icon: "🌤️", title: engine.tx("menu.mood.week", de: "Diese Woche", en: "This week"), text: summary(days: 7))
            summaryCard(icon: "🗓️", title: engine.tx("menu.mood.month", de: "Letzte 30 Tage", en: "Last 30 days"), text: summary(days: 30))
            monthGrid
            if !entries.isEmpty {
                MenuSectionHeader(text: engine.tx("menu.mood.history", de: "Verlauf", en: "History"))
            }
            ForEach(entries.prefix(30), id: \.id) { entry in
                GCard {
                    HStack(alignment: .top, spacing: 14) {
                        Text(verbatim: MenuMoodArt.face(entry.level))
                            .font(.system(size: 30))
                            .frame(width: 52, height: 52)
                            .background(Theme.Tab.menu.moodLevel(entry.level), in: RoundedRectangle(cornerRadius: Theme.Radius.icon, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(engine.t("mood.level.\(entry.level)"))
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.text)
                            if !entry.tags.isEmpty {
                                Text(entry.tags.map { "\(MenuMoodArt.tag($0)) \(engine.t("mood.tag.\($0)"))" }.joined(separator: "  "))
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.text.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            if !entry.note.isEmpty {
                                Text(entry.note)
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(Theme.text)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text(engine.formatDate(entry.recordedAt, time: true))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.greyText)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .contextMenu {
                    Button(engine.t("common.delete"), role: .destructive) { engine.deleteMood(entry) }
                }
            }
        }
        .menuChrome(engine, title: engine.t("mood.title"), background: Theme.Tab.menu.mood)
        .goobySheet(isPresented: $showAdd) { MoodComposer(engine: engine) }
    }

    private func summaryCard(icon: String, title: String, text: String) -> some View {
        GCard {
            HStack(alignment: .top, spacing: 14) {
                IconTile(color: Theme.Tab.quests.yellow.opacity(0.35), size: 48) {
                    GoobyIcon(icon, size: 30)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                    Text(text)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.greyText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func summary(days: Int) -> String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: engine.now()) ?? engine.now()
        let rows = engine.all(MoodEntry.self).filter { $0.recordedAt >= cutoff }
        guard !rows.isEmpty else { return engine.tf(days == 7 ? "mood.week.empty" : "mood.month.empty", days) }
        let average = Double(rows.map(\.level).reduce(0, +)) / Double(rows.count)
        let counts = Dictionary(grouping: rows.flatMap(\.tags), by: { $0 }).mapValues(\.count)
        let top = counts.max { $0.value < $1.value }?.key
        let tone = average >= 4 ? engine.t("mood.tone.bright") : (average >= 3 ? engine.t("mood.tone.steady") : engine.t("mood.tone.tender"))
        let tag = top.map { engine.t("mood.tag.\($0)") } ?? engine.t("common.none")
        return engine.tf(days == 7 ? "mood.week" : "mood.month", tone, tag, average)
    }

    private var monthGrid: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<29
        let map = Dictionary(grouping: engine.all(MoodEntry.self), by: \.dayKey)
        // Leading blanks so the first day sits under its weekday.
        let weekday = calendar.component(.weekday, from: start)
        let blanks = (weekday - calendar.firstWeekday + 7) % 7
        let today = DayKey.make(engine.now())
        return GCard {
            VStack(spacing: 12) {
                HStack {
                    Button { shift(-1) } label: {
                        CircleChevron(color: Theme.text, fill: Theme.keyFace, size: 32, symbol: "chevron.left")
                    }
                    .buttonStyle(MenuTilePressStyle())
                    .accessibilityLabel(engine.tx("menu.mood.prevMonth", de: "Voriger Monat", en: "Previous month"))
                    Spacer()
                    Text(monthTitle)
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Button { shift(1) } label: {
                        CircleChevron(color: Theme.text, fill: Theme.keyFace, size: 32)
                    }
                    .buttonStyle(MenuTilePressStyle())
                    .accessibilityLabel(engine.tx("menu.mood.nextMonth", de: "Nächster Monat", en: "Next month"))
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                    // The ids of the header (-100...-94) and the blanks (-blanks..<0) must not
                    // collide with the day numbers in one lazy grid, or days go missing.
                    ForEach(weekdayInitials.indices.map { -100 + $0 }, id: \.self) { slot in
                        Text(weekdayInitials[slot + 100])
                            .font(Theme.Fonts.caps)
                            .foregroundStyle(Theme.capsGrey)
                            .frame(height: 18)
                            .accessibilityHidden(true)
                    }
                    ForEach(Array((-blanks)..<0), id: \.self) { _ in
                        Color.clear.frame(height: 34)
                    }
                    ForEach(Array(range), id: \.self) { day in
                        let date = calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
                        let key = DayKey.make(date)
                        let level = map[key]?.map(\.level).max()
                        ZStack {
                            Circle()
                                .fill(level == nil ? Theme.keyFace.opacity(0.6) : Theme.Tab.menu.moodLevel(level))
                            if key == today {
                                Circle().stroke(Theme.Tab.quests.orange, lineWidth: 2.5)
                            }
                            if let level {
                                Text(verbatim: MenuMoodArt.face(level)).font(.system(size: 17))
                            } else {
                                Text("\(day)")
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.greyText)
                            }
                        }
                        .frame(width: 34, height: 34)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(level.map { "\(day): \(engine.t("mood.level.\($0)"))" } ?? "\(day)")
                    }
                }
            }
        }
    }

    /// Narrow weekday names starting at the calendar's first weekday.
    private var weekdayInitials: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let first = Calendar.current.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: month)
    }

    private func shift(_ value: Int) {
        month = Calendar.current.date(byAdding: .month, value: value, to: month) ?? month
    }
}
