import SwiftUI

struct GoalWeekday: Identifiable {
    var id: Int { value }
    var value: Int
    var narrow: String
    var wide: String
}

enum GoalRepeat {
    static let workdays = [2, 3, 4, 5, 6]
    static let weekends = [1, 7]

    static func days(language: String) -> [GoalWeekday] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: language)
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 11, day: 9)) ?? Date()
        let narrow = DateFormatter()
        narrow.locale = calendar.locale
        narrow.setLocalizedDateFormatFromTemplate("EEEEE")
        let wide = DateFormatter()
        wide.locale = calendar.locale
        wide.setLocalizedDateFormatFromTemplate("EEEE")
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: anchor) else { return nil }
            let value = calendar.component(.weekday, from: date)
            let short = narrow.string(from: date).replacingOccurrences(of: ".", with: "")
            return GoalWeekday(value: value, narrow: String(short.prefix(2)), wide: wide.string(from: date))
        }
    }

    @MainActor
    static func summary(recurrence: String, weekdays: [Int], engine: GoobyEngine) -> String {
        if recurrence == "once" { return engine.t("care.compose.repeat.none") }
        if recurrence == "daily" || recurrence == "everyX" || recurrence == "monthly" || recurrence == "custom" {
            if recurrence == "daily" { return engine.t("care.repeat.every") }
            return engine.t("recur.\(recurrence)")
        }
        let chosen = Set(weekdays)
        if chosen == Set(workdays) { return engine.t("care.repeat.weekdays") }
        if chosen == Set(weekends) { return engine.t("care.repeat.weekends") }
        let labels = days(language: engine.languageCode)
        if weekdays.count == 1, let day = labels.first(where: { $0.value == weekdays[0] }) {
            return engine.tf("care.repeat.weekly", day.wide)
        }
        let names = labels.filter { chosen.contains($0.value) }.map(\.narrow)
        if names.isEmpty { return engine.t("care.compose.repeat.none") }
        return names.joined(separator: " ")
    }

    static func today(on date: Date) -> Int {
        Calendar(identifier: .gregorian).component(.weekday, from: date)
    }
}

struct GoalRepeatCommit: View {
    var engine: GoobyEngine
    var title: String
    var areaName: String
    var tint: UInt32
    var glyph: String
    var recurrence: String
    var weekdays: [Int]
    var showsCommit: Bool
    var onSave: (String, [Int]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var mode = "weekdays"
    @State private var chosen: Set<Int> = []
    @State private var loaded = false

    var body: some View {
        let labels = GoalRepeat.days(language: engine.languageCode)
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(engine.t("care.repeat.ask"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(GoalLook.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundStyle(Color(hex: 0x7AA7F8))
                            Text(engine.t("care.repeat.label"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(GoalLook.ink.opacity(0.7))
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(labels) { day in
                                    dayChip(day)
                                }
                            }
                        }
                        choice(engine.t("care.repeat.every"), selected: mode == "daily") {
                            mode = "daily"
                            chosen = []
                        }
                        choice(engine.t("care.repeat.weekdays"), selected: mode == "weekdays" && chosen == Set(GoalRepeat.workdays)) {
                            mode = "weekdays"
                            chosen = Set(GoalRepeat.workdays)
                        }
                        choice(engine.t("care.repeat.weekends"), selected: mode == "weekdays" && chosen == Set(GoalRepeat.weekends)) {
                            mode = "weekdays"
                            chosen = Set(GoalRepeat.weekends)
                        }
                        if mode == "weekdays", chosen.count == 1, let only = chosen.first, let name = labels.first(where: { $0.value == only })?.wide {
                            choice(engine.tf("care.repeat.weekly", name), selected: true) {}
                        }
                    }
                    .padding(16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .padding(20)
            }
            .background(Color(hex: 0xF6F4EF))
            Button(engine.t(showsCommit ? "care.repeat.commit" : "common.done")) {
                onSave(savedRecurrence, savedDays)
                dismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(GoalLook.button, in: Capsule())
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(hex: 0xF6F4EF))
            .disabled(mode == "weekdays" && chosen.isEmpty)
        }
        .background(Color(hex: tint).ignoresSafeArea())
        .onAppear(perform: load)
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.25), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("common.close"))
                Spacer()
            }
            GoalGlyph(glyph: glyph, plate: Color.white.opacity(0.92))
                .frame(width: 64, height: 64)
            if !areaName.isEmpty {
                Text(areaName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity)
        .background(Color(hex: tint))
    }

    private func dayChip(_ day: GoalWeekday) -> some View {
        let on = mode == "weekdays" && chosen.contains(day.value)
        return Button {
            mode = "weekdays"
            if chosen.contains(day.value) {
                chosen.remove(day.value)
            } else {
                chosen.insert(day.value)
            }
            if chosen.isEmpty { mode = "once" }
        } label: {
            Text(day.narrow)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(on ? Color.white : GoalLook.ink)
                .frame(width: 40, height: 40)
                .background(on ? GoalLook.button : Color(hex: 0xF0F1F3), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func choice(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? GoalLook.button : GoalLook.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selected ? GoalLook.button : Color(hex: 0xE4E6EA), lineWidth: selected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var savedRecurrence: String {
        if mode == "daily" { return "daily" }
        if mode == "once" || chosen.isEmpty { return "once" }
        return "weekdays"
    }

    private var savedDays: [Int] {
        savedRecurrence == "weekdays" ? chosen.sorted() : []
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if recurrence == "daily" {
            mode = "daily"
            chosen = []
        } else if recurrence == "once" {
            mode = "once"
            chosen = []
        } else if weekdays.isEmpty {
            let today = GoalRepeat.today(on: engine.now())
            mode = "weekdays"
            chosen = [today]
        } else {
            mode = "weekdays"
            chosen = Set(weekdays)
        }
    }
}
