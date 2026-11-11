import SwiftUI

struct DayStartStreakPage: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var onContinue: () -> Void
    @State private var goal: Int
    @State private var shown: Int
    @State private var ready: Bool

    init(engine: GoobyEngine, reduceMotion: Bool, onContinue: @escaping () -> Void) {
        self.engine = engine
        self.reduceMotion = reduceMotion
        self.onContinue = onContinue
        let target = DayStartCopy.streakTarget(engine)
        _goal = State(initialValue: target)
        _shown = State(initialValue: reduceMotion ? target : 0)
        _ready = State(initialValue: reduceMotion || target == 0)
    }

    var body: some View {
        DayStartPage(alignTop: false, buttonTitle: engine.t("daystart.streak.next"), reduceMotion: reduceMotion, action: onContinue) {
            VStack(spacing: 8) {
                ZStack {
                    Ellipse()
                        .fill(Color.black.opacity(0.16))
                        .frame(width: 78, height: 16)
                        .offset(y: 58)
                    GoobyCharacterView(
                        look: engine.wornLook(),
                        stage: Growth.stage(of: engine.pet),
                        animation: pose,
                        reduceMotion: reduceMotion,
                        companion: nil
                    )
                }
                .frame(width: 180, height: 176)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(DayStartCopy.petName(engine))

                Text("\(shown)")
                    .font(.system(size: 88, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .contentTransition(reduceMotion ? .identity : .numericText(countsDown: false))
                    .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: shown)
                    .shadow(color: Color.black.opacity(0.18), radius: 0, y: 1)
                    .accessibilityLabel(DayStartCopy.streakAccess(engine, count: goal))

                Text(engine.t("daystart.streak"))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.18), radius: 0, y: 1)
                    .accessibilityHidden(true)

                week
                    .padding(.top, 18)
                    .opacity(ready ? 1 : 0)
                    .accessibilityHidden(!ready)
            }
        }
        .task(id: reduceMotion) { await runCounter() }
    }

    private var pose: GoobyAnimation {
        if reduceMotion { return .idle }
        if ready && goal > 0 { return .celebrate }
        return .breathe
    }

    private var week: some View {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: engine.now())
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { offset in
                if let date = calendar.date(byAdding: .day, value: offset, to: start) {
                    weekDay(date: date, offset: offset)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func weekDay(date: Date, offset: Int) -> some View {
        let kind: WeekKind = offset == 0 ? .today : (offset == 1 ? .next : .later)
        return VStack(spacing: 6) {
            Text(DayStartCopy.narrowWeekday(date, language: engine.languageCode))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            mark(kind)
                .frame(height: 28)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(access(date: date, kind: kind))
    }

    @ViewBuilder
    private func mark(_ kind: WeekKind) -> some View {
        switch kind {
        case .today:
            ZStack {
                Circle().strokeBorder(Color.white, lineWidth: 2)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 26, height: 26)
        case .next:
            DayStartTwinkle(reduceMotion: reduceMotion)
        case .later:
            Circle()
                .fill(Color.white.opacity(0.72))
                .frame(width: 8, height: 8)
        }
    }

    private func access(date: Date, kind: WeekKind) -> String {
        let name = DayStartCopy.fullWeekday(date, language: engine.languageCode)
        switch kind {
        case .today: return "\(name), \(engine.t("daystart.week.today"))"
        case .next: return "\(name), \(engine.t("daystart.week.next"))"
        case .later: return name
        }
    }

    @MainActor
    private func runCounter() async {
        if reduceMotion || goal == 0 {
            shown = goal
            ready = true
            return
        }
        shown = 0
        ready = false
        let steps = min(goal, 18)
        let chunk = max(1, Int((Double(goal) / Double(steps)).rounded(.up)))
        var value = 0
        while value < goal {
            try? await Task.sleep(for: .milliseconds(70))
            if Task.isCancelled { return }
            value = min(goal, value + chunk)
            shown = value
        }
        if Task.isCancelled { return }
        ready = true
        engine.haptics.soft()
    }
}

private enum WeekKind {
    case today, next, later
}

struct DayStartRays: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.30)
                let spin = timeline.date.timeIntervalSinceReferenceDate * (.pi * 2 / 36)
                let count = 16
                let reach = max(size.width, size.height)
                for index in 0..<count {
                    let mid = spin + (Double(index) / Double(count)) * .pi * 2
                    let spread = .pi / Double(count) * 0.42
                    var wedge = Path()
                    wedge.move(to: origin)
                    wedge.addLine(to: CGPoint(x: origin.x + CGFloat(cos(mid - spread)) * reach, y: origin.y + CGFloat(sin(mid - spread)) * reach))
                    wedge.addLine(to: CGPoint(x: origin.x + CGFloat(cos(mid + spread)) * reach, y: origin.y + CGFloat(sin(mid + spread)) * reach))
                    wedge.closeSubpath()
                    context.fill(wedge, with: .color(Color.white.opacity(index.isMultiple(of: 2) ? 0.10 : 0.05)))
                }
            }
        }
    }
}

struct DayStartTwinkle: View {
    var reduceMotion: Bool

    var body: some View {
        if reduceMotion {
            DayStartSparkle(scale: 1)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                let wave = sin(timeline.date.timeIntervalSinceReferenceDate * 2.4)
                DayStartSparkle(scale: 1 + CGFloat(wave) * 0.08)
            }
        }
    }
}

struct DayStartSparkle: View {
    var scale: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(Color.white)
                    .frame(width: 2, height: index.isMultiple(of: 2) ? 14 : 8)
                    .offset(y: -1)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            Circle().fill(Color.white).frame(width: 4, height: 4)
            Circle().fill(Color.white).frame(width: 3, height: 3).offset(x: 9, y: -8)
            Circle().fill(Color.white).frame(width: 2, height: 2).offset(x: -8, y: 7)
        }
        .frame(width: 28, height: 28)
        .scaleEffect(scale)
    }
}
