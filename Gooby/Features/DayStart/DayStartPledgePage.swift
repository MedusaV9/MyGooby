import SwiftUI

struct DayStartPledgePage: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var onFinished: () -> Void
    @State private var selected: Int?
    @State private var entered = false

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
            tone: .solid,
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
                    .opacity(entered ? 1 : 0)
                    .offset(y: entered ? 0 : 8)

                HStack(alignment: .center, spacing: 8) {
                    character
                    if selected != nil {
                        DayStartBubble(text: engine.t("daystart.pledge.bubble"))
                            .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.86, anchor: .leading)))
                    }
                    Spacer(minLength: 0)
                }
                .animation(reduceMotion ? nil : .spring(duration: 0.32, bounce: 0.25), value: selected)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    ForEach(Array(DayStartCopy.goals.enumerated()), id: \.element.id) { index, goal in
                        row(goal)
                            .opacity(entered ? 1 : 0)
                            .offset(y: entered ? 0 : 16)
                            .animation(
                                reduceMotion ? nil : .spring(duration: 0.42).delay(0.05 * Double(index)),
                                value: entered
                            )
                    }
                }
            }
        }
        .onAppear {
            guard !entered else { return }
            if reduceMotion {
                entered = true
            } else {
                withAnimation(.spring(duration: 0.4)) { entered = true }
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
                DayStartQuestionMark(reduceMotion: reduceMotion)
                    .padding(.top, 2)
                    .padding(.trailing, 2)
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
                Text(goal.mark)
                    .font(.system(size: 22))
                    .frame(width: 32)
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
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(isOn ? Color.white : Color.clear, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color(hex: 0xB7ECFF).opacity(isOn ? 0 : 0.9), lineWidth: 1.6)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days), \(label)")
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
        .animation(reduceMotion ? nil : .spring(duration: 0.22), value: isOn)
    }

    private func commit() {
        guard let selected else { return }
        engine.haptics.celebrate()
        engine.setStreakGoalDays(selected)
        onFinished()
    }
}

struct DayStartQuestionMark: View {
    var reduceMotion: Bool

    var body: some View {
        Group {
            if reduceMotion {
                mark(offset: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                    let wave = sin(timeline.date.timeIntervalSinceReferenceDate * 2.2)
                    mark(offset: CGFloat(wave) * 3)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func mark(offset: CGFloat) -> some View {
        Text("?")
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.white)
            .offset(y: offset)
    }
}

struct DayStartBubble: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(DayStartPalette.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white, in: Capsule())
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 2) {
                    Circle().frame(width: 6, height: 6)
                    Circle().frame(width: 10, height: 10)
                }
                .foregroundStyle(Color.white)
                .offset(x: -4, y: 8)
            }
            .accessibilityLabel(text)
    }
}
