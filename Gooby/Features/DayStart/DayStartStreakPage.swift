import SwiftUI
import UIKit

struct DayStartStreakPage: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var onContinue: () -> Void
    @State private var goal: Int
    @State private var shown: Int
    @State private var reveal: CGFloat
    @State private var pop: CGFloat
    @State private var ready: Bool
    @State private var burst: CGFloat
    @State private var left = false
    @State private var skipped = false

    init(engine: GoobyEngine, reduceMotion: Bool, onContinue: @escaping () -> Void) {
        self.engine = engine
        self.reduceMotion = reduceMotion
        self.onContinue = onContinue
        let target = DayStartCopy.streakTarget(engine)
        _goal = State(initialValue: target)
        _shown = State(initialValue: reduceMotion ? target : 0)
        _reveal = State(initialValue: reduceMotion ? 1 : 0)
        _pop = State(initialValue: reduceMotion ? 1 : 0.15)
        _ready = State(initialValue: reduceMotion)
        _burst = State(initialValue: reduceMotion ? 1 : 0)
    }

    var body: some View {
        ZStack {
            DayStartPalette.stage.ignoresSafeArea()
            DayStartPalette.slate.opacity(1 - reveal).ignoresSafeArea()
            DayStartRays(spinning: !reduceMotion && reveal > 0.2)
                .opacity(reveal)
                .scaleEffect(0.25 + 0.75 * pop)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            VStack(spacing: 6) {
                Spacer(minLength: 8)
                character
                Text("\(shown)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(numberColor)
                    .contentTransition(reduceMotion ? .identity : .numericText(countsDown: false))
                    .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: shown)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityLabel(DayStartCopy.streakAccess(engine, count: goal))
                Text(engine.t("daystart.streak"))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(numberColor)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .accessibilityHidden(true)
                week
                    .padding(.top, 22)
                    .opacity(ready ? 1 : 0)
                    .offset(y: ready ? 0 : 16)
                    .accessibilityHidden(!ready)
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)
            DayStartBurst(progress: burst)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture { skipOrAdvance() }
        .overlay(alignment: .bottom) {
            if ready {
                DayStartActionButton(
                    title: engine.t("daystart.streak.next"),
                    tone: .frost,
                    reduceMotion: reduceMotion,
                    action: advance
                )
                .padding(.horizontal, 22)
                .padding(.bottom, 8)
                .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .accessibilityAction(named: Text(engine.t("daystart.streak.next"))) { advance() }
        .task(id: reduceMotion) { await runCounter() }
    }

    private var numberColor: Color {
        let t = Double(reveal)
        return Color(red: 0.17 + 0.83 * t, green: 0.20 + 0.80 * t, blue: 0.23 + 0.77 * t)
    }

    private var character: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.16 * reveal))
                .frame(width: 78, height: 16)
                .offset(y: 62)
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: pose,
                reduceMotion: reduceMotion,
                companion: nil
            )
            .scaleEffect(pop)
            .opacity(reveal)
        }
        .frame(width: 180, height: 176)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DayStartCopy.petName(engine))
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
        .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func weekDay(date: Date, offset: Int) -> some View {
        let kind: WeekKind = offset == 0 ? (goal > 0 ? .today : .open) : (offset == 1 ? .next : .later)
        return VStack(spacing: 8) {
            Text(DayStartCopy.narrowWeekday(date, language: engine.languageCode))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))
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
                Circle().fill(Color.white.opacity(0.22))
                Circle().strokeBorder(Color.white, lineWidth: 2)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 26, height: 26)
            .scaleEffect(ready ? 1 : 0.4)
        case .open:
            Circle()
                .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 22, height: 22)
        case .next:
            DayStartTwinkle(reduceMotion: reduceMotion)
        case .later:
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 8, height: 8)
        }
    }

    private func access(date: Date, kind: WeekKind) -> String {
        let name = DayStartCopy.fullWeekday(date, language: engine.languageCode)
        switch kind {
        case .today: return "\(name), \(engine.t("daystart.week.today"))"
        case .open: return name
        case .next: return "\(name), \(engine.t("daystart.week.next"))"
        case .later: return name
        }
    }

    private func skipOrAdvance() {
        guard !reduceMotion else {
            advance()
            return
        }
        if !ready {
            skipped = true
            shown = goal
            reveal = 1
            pop = 1
            burst = 1
            withAnimation(reduceMotion ? nil : .spring(duration: 0.35)) {
                ready = true
            }
            return
        }
        advance()
    }

    private func advance() {
        guard ready, !left else { return }
        left = true
        onContinue()
    }

    @MainActor
    private func runCounter() async {
        if reduceMotion {
            shown = goal
            reveal = 1
            pop = 1
            ready = true
            burst = 1
            return
        }
        shown = 0
        reveal = 0
        pop = 0.15
        ready = false
        burst = 0
        try? await Task.sleep(for: .milliseconds(560))
        if Task.isCancelled || left || skipped { return }
        withAnimation(.easeInOut(duration: 0.55)) { reveal = 1 }
        withAnimation(.spring(duration: 0.7, bounce: 0.38)) { pop = 1 }
        if goal > 0 {
            let steps = min(goal, 18)
            let chunk = max(1, Int((Double(goal) / Double(steps)).rounded(.up)))
            var value = 0
            while value < goal {
                try? await Task.sleep(for: .milliseconds(80))
                if Task.isCancelled || left || skipped { return }
                value = min(goal, value + chunk)
                shown = value
            }
        }
        if Task.isCancelled || left || skipped { return }
        withAnimation(.spring(duration: 0.45)) { ready = true }
        withAnimation(.easeOut(duration: 0.7)) { burst = 1 }
        engine.haptics.soft()
        try? await Task.sleep(for: .milliseconds(1300))
        if Task.isCancelled || left || skipped { return }
        if UIAccessibility.isVoiceOverRunning { return }
        advance()
    }
}

private enum WeekKind {
    case today, open, next, later
}

struct DayStartRays: View {
    var spinning: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: spinning ? 1.0 / 30.0 : 8, paused: false)) { timeline in
            let spin = spinning ? timeline.date.timeIntervalSinceReferenceDate * (.pi * 2 / 12) : 0
            Canvas { context, size in
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.30)
                let count = 18
                let reach = max(size.width, size.height) * 0.95
                for index in 0..<count {
                    let mid = spin + (Double(index) / Double(count)) * .pi * 2
                    let spread = .pi / Double(count) * 0.38
                    var wedge = Path()
                    wedge.move(to: origin)
                    wedge.addLine(to: CGPoint(x: origin.x + CGFloat(cos(mid - spread)) * reach, y: origin.y + CGFloat(sin(mid - spread)) * reach))
                    wedge.addLine(to: CGPoint(x: origin.x + CGFloat(cos(mid + spread)) * reach, y: origin.y + CGFloat(sin(mid + spread)) * reach))
                    wedge.closeSubpath()
                    context.fill(wedge, with: .color(Color.white.opacity(index.isMultiple(of: 2) ? 0.16 : 0.07)))
                }
            }
        }
    }
}

struct DayStartBurst: View {
    var progress: CGFloat

    var body: some View {
        Canvas { context, size in
            guard progress > 0, progress < 1 else { return }
            let origin = CGPoint(x: size.width / 2, y: size.height * 0.34)
            let fade = Double(1 - progress)
            for index in 0..<14 {
                let angle = (Double(index) / 14.0) * .pi * 2 + 0.2
                let reach = 30 + progress * 120
                let point = CGPoint(
                    x: origin.x + CGFloat(cos(angle)) * reach,
                    y: origin.y + CGFloat(sin(angle)) * reach
                )
                let radius: CGFloat = index.isMultiple(of: 2) ? 5 : 3
                let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                let color = index.isMultiple(of: 3) ? DayStartPalette.gold : Color.white
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(fade)))
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
                DayStartSparkle(scale: 1 + CGFloat(wave) * 0.1)
            }
        }
    }
}

struct DayStartSparkle: View {
    var scale: CGFloat

    var body: some View {
        Group {
            if let image = ActivityArt.image("daystart-sparkle") {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
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
            }
        }
        .frame(width: 28, height: 28)
        .scaleEffect(scale)
    }
}
