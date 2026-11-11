import SwiftUI

struct DayStartPledgePage: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var onFinished: () -> Void
    @State private var selected: Int?

    init(engine: GoobyEngine, reduceMotion: Bool, onFinished: @escaping () -> Void) {
        self.engine = engine
        self.reduceMotion = reduceMotion
        self.onFinished = onFinished
        let current = engine.profile.streakGoalDays
        _selected = State(initialValue: DayStartCopy.goals.contains { $0.days == current } ? current : nil)
    }

    var body: some View {
        DayStartPage(
            alignTop: true,
            buttonTitle: engine.t("daystart.pledge.commit"),
            enabled: selected != nil,
            reduceMotion: reduceMotion,
            action: { commit() }
        ) {
            VStack(spacing: 16) {
                Text(engine.tf("daystart.pledge.title", DayStartCopy.petName(engine)))
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                HStack(alignment: .center, spacing: 8) {
                    character
                    if selected != nil {
                        DayStartBubble(text: engine.t("daystart.pledge.bubble"))
                            .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.92, anchor: .leading)))
                    }
                    Spacer(minLength: 0)
                }
                .animation(reduceMotion ? nil : .spring(duration: 0.28), value: selected)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    ForEach(DayStartCopy.goals) { goal in
                        row(goal)
                    }
                }
            }
        }
    }

    private var character: some View {
        ZStack(alignment: .topTrailing) {
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: characterPose,
                reduceMotion: reduceMotion,
                companion: nil
            )
            .frame(width: 112, height: 128)
            if selected == nil {
                Text("?")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.top, 2)
                    .padding(.trailing, 2)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 116, height: 132)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DayStartCopy.petName(engine))
    }

    private var characterPose: GoobyAnimation {
        if reduceMotion { return .idle }
        return selected == nil ? .think : .celebrate
    }

    private func row(_ goal: DayStartGoal) -> some View {
        let isOn = selected == goal.days
        let days = engine.tf("daystart.goal.days", goal.days)
        let label = engine.t(goal.labelKey)
        return Button {
            guard selected != goal.days else { return }
            selected = goal.days
            engine.haptics.soft()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: goal.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 28)
                Text(days)
                    .font(.system(.body, design: .rounded).weight(.bold))
                Spacer(minLength: 8)
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isOn ? DayStartPalette.buttonInk : Color.white)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(isOn ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(isOn ? 0 : 0.55), lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days), \(label)")
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isOn)
    }

    private func commit() {
        guard let selected else { return }
        engine.haptics.celebrate()
        engine.setStreakGoalDays(selected)
        onFinished()
    }
}

struct DayStartBubble: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(DayStartPalette.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 2) {
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 10, height: 10)
                }
                .foregroundStyle(Color.white)
                .offset(x: -8, y: 6)
            }
            .accessibilityLabel(text)
    }
}
