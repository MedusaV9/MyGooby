import SwiftUI

enum DayStartStep: Equatable {
    case affirmation, streak, pledge, widget
}

enum DayStartButtonTone {
    case solid, frost
}

enum DayStartPalette {
    static let stage = Color(hex: 0x1B98D8)
    static let slate = Color(hex: 0x3B444B)
    static let card = Color(hex: 0xE364A4)
    static let cardDeep = Color(hex: 0xC43D78)
    static let gold = Color(hex: 0xFFE56A)
    static let coral = Color(hex: 0xFF8A5B)
    static let ink = Color(hex: 0x14324F)
    static let buttonInk = Color(hex: 0x1468A0)
    static let frostInk = Color(hex: 0x1A6494)
    static let widgetGreen = Color(hex: 0x2EBE64)
    static let widgetInk = Color(hex: 0x1C2430)
    static let widgetMuted = Color(hex: 0x8A9099)
}

@MainActor
enum DayStartCopy {
    static let goals: [DayStartGoal] = [
        DayStartGoal(days: 2, mark: "👏", labelKey: "daystart.goal.2"),
        DayStartGoal(days: 5, mark: "💪", labelKey: "daystart.goal.5"),
        DayStartGoal(days: 7, mark: "🎯", labelKey: "daystart.goal.7"),
        DayStartGoal(days: 14, mark: "🔥", labelKey: "daystart.goal.14")
    ]

    static func petName(_ engine: GoobyEngine) -> String {
        let trimmed = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Gooby" : trimmed
    }

    static func dayNumber(_ engine: GoobyEngine) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: engine.profile.createdAt)
        let today = calendar.startOfDay(for: engine.now())
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(1, days + 1)
    }

    static func weekdayNumber(_ engine: GoobyEngine) -> Int {
        Calendar.current.component(.weekday, from: engine.now())
    }

    /// Day 1 of the profile shows the first sentence. Later mornings rotate.
    static func affirmationIndex(_ engine: GoobyEngine) -> Int {
        (dayNumber(engine) - 1) % 7 + 1
    }

    /// Habit streak from the engine. On the morning the profile was created the
    /// counter still runs from 0 to 1, before any goal is logged.
    static func streakTarget(_ engine: GoobyEngine) -> Int {
        let logged = max(0, engine.streak())
        if logged > 0 { return logged }
        if engine.dayKey(engine.profile.createdAt) == engine.dayKey() { return 1 }
        return 0
    }

    static func energyKey(_ pronouns: String) -> String {
        let value = pronouns.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let head = value.split(whereSeparator: { $0 == "/" || $0 == " " || $0 == "," }).first.map(String.init) ?? value
        switch head {
        case "she", "her", "sie": return "daystart.energy.she"
        case "he", "him", "er", "ihn": return "daystart.energy.he"
        default: return "daystart.energy"
        }
    }

    static func streakAccess(_ engine: GoobyEngine, count: Int) -> String {
        if count <= 0 { return engine.t("daystart.streak.access.zero") }
        if count == 1 { return engine.t("daystart.streak.access.one") }
        return engine.tf("daystart.streak.access.many", count)
    }

    static func narrowWeekday(_ date: Date, language: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.dateFormat = "EEEEE"
        let text = formatter.string(from: date).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "?" }
        return text.uppercased(with: formatter.locale)
    }

    static func fullWeekday(_ date: Date, language: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

struct DayStartGoal: Identifiable {
    var days: Int
    var mark: String
    var labelKey: String
    var id: Int { days }
}

struct DayStartView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var step = DayStartStep.affirmation

    var body: some View {
        ZStack {
            DayStartPalette.stage.ignoresSafeArea()
            Group {
                switch step {
                case .affirmation:
                    DayStartAffirmationPage(engine: engine, reduceMotion: reduceMotion) {
                        engine.haptics.soft()
                        step = .streak
                    }
                    .transition(reduceMotion ? .identity : .opacity)
                case .streak:
                    DayStartStreakPage(engine: engine, reduceMotion: reduceMotion) {
                        engine.haptics.soft()
                        if engine.profile.streakGoalDays == 0 {
                            step = .pledge
                        } else {
                            engine.markAffirmationShownToday()
                        }
                    }
                    .transition(reduceMotion ? .identity : .opacity)
                case .pledge:
                    DayStartPledgePage(engine: engine, reduceMotion: reduceMotion) {
                        engine.haptics.soft()
                        step = .widget
                    }
                    .transition(reduceMotion ? .identity : .opacity)
                case .widget:
                    DayStartWidgetPage(engine: engine, reduceMotion: reduceMotion) {
                        engine.markAffirmationShownToday()
                    }
                    .transition(reduceMotion ? .identity : .opacity)
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: step)
    }
}

struct DayStartPage<Content: View>: View {
    var alignTop: Bool
    var buttonTitle: String
    var enabled: Bool
    var tone: DayStartButtonTone
    var reduceMotion: Bool
    var action: () -> Void
    var content: Content
    @State private var buttonHeight: CGFloat = 64

    init(
        alignTop: Bool,
        buttonTitle: String,
        enabled: Bool = true,
        tone: DayStartButtonTone = .solid,
        reduceMotion: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.alignTop = alignTop
        self.buttonTitle = buttonTitle
        self.enabled = enabled
        self.tone = tone
        self.reduceMotion = reduceMotion
        self.action = action
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 12) {
                ScrollView(showsIndicators: false) {
                    content
                        .frame(maxWidth: .infinity, alignment: alignTop ? .top : .center)
                        .frame(minHeight: max(0, proxy.size.height - buttonHeight - 12), alignment: alignTop ? .top : .center)
                        .padding(.top, alignTop ? 8 : 0)
                        .padding(.bottom, 8)
                }
                .scrollBounceBehavior(.basedOnSize)
                DayStartActionButton(title: buttonTitle, enabled: enabled, tone: tone, reduceMotion: reduceMotion, action: action)
                    .background {
                        GeometryReader { geo in
                            Color.clear.preference(key: DayStartButtonHeight.self, value: geo.size.height)
                        }
                    }
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 8)
        .onPreferenceChange(DayStartButtonHeight.self) { buttonHeight = $0 }
    }
}

struct DayStartActionButton: View {
    var title: String
    var enabled: Bool = true
    var tone: DayStartButtonTone = .solid
    var reduceMotion: Bool
    var action: () -> Void

    private var frost: Bool { tone == .frost || !enabled }

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(DayStartPressStyle(enabled: enabled, frost: frost, reduceMotion: reduceMotion))
        .disabled(!enabled)
    }
}

private struct DayStartPressStyle: ButtonStyle {
    var enabled: Bool
    var frost: Bool
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(frost ? DayStartPalette.frostInk : DayStartPalette.buttonInk)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(frost ? Color.white.opacity(enabled ? 0.42 : 0.28) : Color.white, in: Capsule())
            .opacity(enabled ? 1 : 0.92)
            .scaleEffect(!reduceMotion && enabled && configuration.isPressed ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.22), value: configuration.isPressed)
    }
}

private struct DayStartButtonHeight: PreferenceKey {
    static var defaultValue: CGFloat = 64
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
