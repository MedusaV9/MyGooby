import SwiftUI

/// One month of the days already stored for the habit streak.
/// Marks come from `GoobyEngine.streakDayKeys()` (a habit log with a count that was not skipped).
struct StreakCalendarSheet: View {
    var engine: GoobyEngine
    var snap: ProfileSnapshot
    var calm: Bool
    var subtitle: String

    @State private var monthAnchor: Date?
    @State private var detent: PresentationDetent = .large

    private var page: StreakMonthPage {
        StreakMonthPage.make(
            month: monthAnchor ?? engine.now(),
            kept: snap.keptDayKeys,
            today: engine.now(),
            createdAt: engine.profile.createdAt,
            language: engine.languageCode,
            keptWord: engine.t("profile.streak.kept"),
            openWord: engine.t("profile.streak.open"),
            aheadWord: engine.t("profile.streak.ahead"),
            todayWord: engine.t("profile.streak.today")
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("profile.streak.detail"))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(ProfilePalette.ink)
                stat(engine.t("profile.streak.now"), "\(snap.streak)")
                stat(engine.t("profile.streak.best"), "\(snap.longest)")
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(ProfilePalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                calendarCard
                    .padding(.top, 6)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ProfilePalette.page.ignoresSafeArea())
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationBackground(ProfilePalette.page)
        .sheetRise(calm: calm)
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            monthHeader
            weekdayRow
            monthGrid
            legend
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ProfilePalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: ProfilePalette.shadow, radius: 10, y: 4)
        .animation(calm ? nil : .easeInOut(duration: 0.2), value: page.monthStart)
    }

    private var monthHeader: some View {
        HStack(spacing: 0) {
            monthButton(forward: false)
            Text(page.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            monthButton(forward: true)
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(page.weekdayLabels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(ProfilePalette.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var monthGrid: some View {
        VStack(spacing: 0) {
            ForEach(page.weeks) { week in
                HStack(spacing: 0) {
                    ForEach(week.slots) { slot in
                        dayCell(slot)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(engine.t("profile.streak.calendar"))
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendMark(kept: true, title: engine.t("profile.streak.kept"))
            legendMark(kept: false, title: engine.t("profile.streak.today"))
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundStyle(ProfilePalette.brown)
    }

    private func legendMark(kept: Bool, title: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(kept ? ProfilePalette.sun : Color.clear)
                .frame(width: 12, height: 12)
                .overlay {
                    if !kept {
                        Circle().stroke(ProfilePalette.sunCheck, lineWidth: 2)
                    }
                }
            Text(title)
                .lineLimit(1)
        }
    }

    private func monthButton(forward: Bool) -> some View {
        let enabled = forward ? page.canGoForward : page.canGoBack
        return Button {
            step(forward ? 1 : -1)
        } label: {
            ChevronGlyph()
                .rotationEffect(.degrees(forward ? 0 : 180))
                .foregroundStyle(ProfilePalette.brown)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.28)
        .accessibilityLabel(engine.t(forward ? "profile.streak.month.next" : "profile.streak.month.previous"))
    }

    private func dayCell(_ slot: StreakMonthPage.Slot) -> some View {
        ZStack {
            if let number = slot.number {
                if slot.kept {
                    Circle()
                        .fill(ProfilePalette.sun)
                        .frame(width: 34, height: 34)
                }
                if slot.isToday {
                    Circle()
                        .stroke(ProfilePalette.sunCheck, lineWidth: 2)
                        .frame(width: 34, height: 34)
                }
                Text("\(number)")
                    .font(.system(size: 14, weight: slot.kept || slot.isToday ? .heavy : .semibold, design: .rounded))
                    .foregroundStyle(ProfilePalette.ink)
                    .opacity(slot.isFuture && !slot.kept ? 0.38 : 1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(slot.label)
        .accessibilityHidden(slot.number == nil)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ProfilePalette.muted)
            Spacer(minLength: 6)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(ProfilePalette.brown)
                .lineLimit(1)
        }
    }

    private func step(_ delta: Int) {
        let shown = page
        guard delta < 0 ? shown.canGoBack : shown.canGoForward else { return }
        guard let next = shown.calendar.date(byAdding: .month, value: delta, to: shown.monthStart) else { return }
        monthAnchor = next
    }
}

struct StreakMonthPage {
    struct Slot: Identifiable, Hashable {
        var id: String
        var number: Int?
        var kept: Bool
        var isToday: Bool
        var isFuture: Bool
        var label: String
    }

    struct Week: Identifiable, Hashable {
        var id: Int
        var slots: [Slot]
    }

    var title: String
    var weekdayLabels: [String]
    var weeks: [Week]
    var canGoBack: Bool
    var canGoForward: Bool
    var monthStart: Date
    var calendar: Calendar

    static func make(
        month: Date,
        kept: Set<String>,
        today: Date,
        createdAt: Date,
        language: String,
        keptWord: String,
        openWord: String,
        aheadWord: String,
        todayWord: String,
        base: Calendar = .current
    ) -> StreakMonthPage {
        let calendar = displayCalendar(language: language, base: base)
        let todayStart = calendar.startOfDay(for: today)
        let todayMonth = startOfMonth(todayStart, calendar: calendar)
        let requested = startOfMonth(month, calendar: calendar)
        let shown = monthKey(requested, calendar: calendar) > monthKey(todayMonth, calendar: calendar) ? todayMonth : requested

        var floor = min(startOfMonth(createdAt, calendar: calendar), todayMonth)
        for key in kept {
            guard let date = DayKey.parse(key, calendar: calendar) else { continue }
            let candidate = startOfMonth(date, calendar: calendar)
            if candidate < floor { floor = candidate }
        }

        let weekday = calendar.component(.weekday, from: shown)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: shown)?.count ?? 30
        let monthID = monthKey(shown, calendar: calendar)
        var slots: [Slot] = (0..<leading).map { index in
            Slot(id: "pad-\(monthID)-\(index)", number: nil, kept: false, isToday: false, isFuture: false, label: "")
        }
        for day in 1...dayCount {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: shown) else { continue }
            let start = calendar.startOfDay(for: date)
            let key = DayKey.make(start, calendar: calendar)
            let keptDay = kept.contains(key)
            let isToday = calendar.isDate(start, inSameDayAs: todayStart)
            let isFuture = start > todayStart
            var parts = [dayTitle(start, language: language, calendar: calendar)]
            if isToday { parts.append(todayWord) }
            if keptDay {
                parts.append(keptWord)
            } else if isFuture {
                parts.append(aheadWord)
            } else {
                parts.append(openWord)
            }
            slots.append(Slot(
                id: key,
                number: day,
                kept: keptDay,
                isToday: isToday,
                isFuture: isFuture,
                label: parts.joined(separator: ", ")
            ))
        }
        var tail = 0
        while slots.count % 7 != 0 {
            slots.append(Slot(id: "tail-\(monthID)-\(tail)", number: nil, kept: false, isToday: false, isFuture: false, label: ""))
            tail += 1
        }
        var weeks: [Week] = []
        var index = 0
        while index < slots.count {
            weeks.append(Week(id: weeks.count, slots: Array(slots[index..<min(index + 7, slots.count)])))
            index += 7
        }

        return StreakMonthPage(
            title: monthTitle(shown, language: language, calendar: calendar),
            weekdayLabels: weekdayLabels(language: language, calendar: calendar),
            weeks: weeks,
            canGoBack: monthKey(shown, calendar: calendar) > monthKey(floor, calendar: calendar),
            canGoForward: monthKey(shown, calendar: calendar) < monthKey(todayMonth, calendar: calendar),
            monthStart: shown,
            calendar: calendar
        )
    }

    /// `Calendar.current` keeps the day keys identical to the stored logs. Locale only picks the weekday column.
    static func displayCalendar(language: String, base: Calendar = .current) -> Calendar {
        var calendar = base
        let zone = base.timeZone
        var probe = Calendar(identifier: base.identifier)
        probe.locale = Locale(identifier: language)
        let first = probe.firstWeekday
        calendar.locale = Locale(identifier: language)
        calendar.timeZone = zone
        calendar.firstWeekday = (1...7).contains(first) ? first : (language.hasPrefix("en") ? 1 : 2)
        return calendar
    }

    private static func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        let parts = calendar.dateComponents([.year, .month], from: date)
        var pinned = DateComponents()
        pinned.year = parts.year
        pinned.month = parts.month
        pinned.day = 1
        guard let first = calendar.date(from: pinned) else { return calendar.startOfDay(for: date) }
        return calendar.startOfDay(for: first)
    }

    private static func monthKey(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    private static func monthTitle(_ date: Date, language: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }

    private static func dayTitle(_ date: Date, language: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.calendar = calendar
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Short names in column order. Built from real dates so the first column matches `firstWeekday`.
    private static func weekdayLabels(language: String, calendar: Calendar) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.calendar = calendar
        formatter.dateFormat = "EEE"
        var cursor = calendar.date(from: DateComponents(year: 2024, month: 1, day: 7)) ?? Date()
        var steps = 0
        while calendar.component(.weekday, from: cursor) != calendar.firstWeekday && steps < 7 {
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            steps += 1
        }
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: cursor) else { return nil }
            let name = formatter.string(from: day).replacingOccurrences(of: ".", with: "")
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
