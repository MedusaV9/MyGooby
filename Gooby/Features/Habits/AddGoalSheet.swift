import SwiftUI

private struct GoalCardRequest: Identifiable {
    var id = UUID()
    var suggestion: GoalSuggestion?
    var title: String
    var areaID: String
    var daypart: String
    var recurrence: String
    var weekdays: [Int]
}

struct AddGoalSheet: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var onChange: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var areaID = ""
    @State private var daypart = "any"
    @State private var recurrence = "once"
    @State private var weekdays: [Int] = []
    @State private var chip = "easy"
    @State private var showArea = false
    @State private var showDaypart = false
    @State private var showRepeat = false
    @State private var card: GoalCardRequest?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.22), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("common.close"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            composer
                .padding(.horizontal, 16)
                .padding(.top, 8)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(filtered) { suggestion in
                        suggestionPill(suggestion)
                    }
                    if filtered.isEmpty {
                        Text(engine.t(chip.hasPrefix("custom-") ? "care.areas.custom.empty" : "care.search.empty"))
                            .font(GoalFont.body)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            chips
        }
        .background(GoalLook.sheet.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .presentationBackground(GoalLook.sheet)
        .sheet(isPresented: $showArea) {
            GoalAreaGrid(engine: engine, store: store, allowsNone: true) { id in
                areaID = id
                showArea = false
            }
        }
        .sheet(isPresented: $showDaypart) {
            GoalDaypartSheet(engine: engine, daypart: $daypart)
        }
        .sheet(isPresented: $showRepeat) {
            GoalRepeatCommit(
                engine: engine,
                title: title.isEmpty ? engine.t("care.own") : title,
                areaName: areaTitle,
                tint: GoalActions.tint(for: areaID, store: store),
                glyph: GoalActions.glyphName(for: areaID.isEmpty ? "kindness" : areaID, store: store),
                recurrence: recurrence,
                weekdays: weekdays,
                showsCommit: false
            ) { next, days in
                recurrence = next
                weekdays = days
            }
        }
        .fullScreenCover(item: $card) { request in
            GoalQuickCard(
                engine: engine,
                store: store,
                habit: existingHabit(for: request.suggestion),
                suggestion: request.suggestion,
                presetTitle: request.title,
                presetArea: request.areaID,
                presetDaypart: request.daypart,
                presetRecurrence: request.recurrence,
                presetWeekdays: request.weekdays,
                onChange: onChange,
                onClose: { card = nil },
                onSaved: { message in
                    engine.banner = message
                    onChange()
                    card = nil
                    dismiss()
                }
            )
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 12) {
            GoalGlyph(glyph: "target", plate: Color(hex: 0xF4F6F2))
                .frame(width: 48, height: 48)
            TextField(engine.t("care.compose.placeholder"), text: $title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(GoalLook.ink)
                .submitLabel(.done)
                .onSubmit(openTyped)
            composerRow(system: "plus.circle.fill", text: areaID.isEmpty ? engine.t("care.compose.area") : areaTitle) {
                showArea = true
            }
            composerRow(system: "calendar", text: engine.tf("care.compose.when", engine.t("care.filter.\(daypart)"))) {
                showDaypart = true
            }
            composerRow(system: "arrow.triangle.2.circlepath", text: GoalRepeat.summary(recurrence: recurrence, weekdays: weekdays, engine: engine)) {
                showRepeat = true
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func composerRow(system: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: system)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GoalLook.button)
                    .frame(width: 22)
                Text(text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x6E9A52))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    private func suggestionPill(_ suggestion: GoalSuggestion) -> some View {
        Button {
            card = GoalCardRequest(
                suggestion: suggestion,
                title: suggestion.title(engine.languageCode),
                areaID: suggestion.areaID,
                daypart: "any",
                recurrence: "daily",
                weekdays: []
            )
        } label: {
            HStack(spacing: 10) {
                GoalGlyph(glyph: suggestion.glyph).frame(width: 36, height: 36)
                Text(suggestion.title(engine.languageCode))
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1E4A28))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.38), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GoalCatalog.chipOrder, id: \.self) { id in
                    if id == "easy" {
                        chipButton("easy", title: engine.t("care.chip.easy"))
                    } else if let area = GoalCatalog.area(id) {
                        chipButton(area.id, title: area.name(engine.languageCode))
                    }
                }
                ForEach(store.meta.customAreas) { area in
                    chipButton(area.id, title: area.name)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(GoalLook.sheet)
    }

    private func chipButton(_ id: String, title: String) -> some View {
        let on = chip == id
        return Button {
            chip = id
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(on ? GoalLook.button : Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(on ? Color.white : Color.white.opacity(0.16), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var filtered: [GoalSuggestion] {
        if chip == "easy" || chip.hasPrefix("custom-") || GoalCatalog.area(chip) != nil {
            return GoalCatalog.suggestions(in: chip)
        }
        return GoalCatalog.suggestions
    }

    private var areaTitle: String {
        if let area = GoalCatalog.area(areaID) { return area.name(engine.languageCode) }
        return store.custom(areaID)?.name ?? ""
    }

    private func openTyped() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        card = GoalCardRequest(
            suggestion: nil,
            title: trimmed,
            areaID: areaID,
            daypart: daypart,
            recurrence: recurrence,
            weekdays: weekdays
        )
    }

    private func existingHabit(for suggestion: GoalSuggestion?) -> Habit? {
        guard let suggestion else { return nil }
        return GoalActions.habit(for: suggestion, engine: engine, store: store)
    }
}

struct GoalDraftSheet: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var habit: Habit?
    var presetArea: String = ""
    var onChange: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GoalQuickCard(
            engine: engine,
            store: store,
            habit: habit,
            suggestion: nil,
            presetTitle: "",
            presetArea: presetArea,
            presetDaypart: "any",
            presetRecurrence: "daily",
            presetWeekdays: [],
            onChange: onChange,
            onClose: { dismiss() },
            onSaved: { message in
                engine.banner = message
                onChange()
                dismiss()
            }
        )
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
