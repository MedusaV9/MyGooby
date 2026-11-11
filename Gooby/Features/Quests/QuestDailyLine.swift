import SwiftUI

enum QuestDayClock {
    struct Reading {
        var hours: Int
        var minutes: Int
        var fraction: Double
        var dayKey: String
    }

    static func read(_ now: Date, calendar: Calendar = .current) -> Reading {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now.addingTimeInterval(86_400)
        let remain = max(0, end.timeIntervalSince(now))
        let total = max(1, end.timeIntervalSince(start))
        return Reading(
            hours: Int(remain) / 3600,
            minutes: (Int(remain) % 3600) / 60,
            fraction: min(1, remain / total),
            dayKey: DayKey.make(now, calendar: calendar)
        )
    }
}

struct QuestHopToken: Identifiable {
    var metric: String
    var id: String { metric }
}

struct QuestDailyLine: View {
    var engine: GoobyEngine
    var cards: [JourneyCard]
    var calm: Bool
    var claim: (JourneyCard) -> Void
    var onReturn: () -> Void

    @State private var hop: QuestHopToken?
    @State private var seenDay = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            QuestSectionHead(title: engine.t("quests.section.daily")) {
                TimelineView(.periodic(from: .now, by: calm ? 60 : 30)) { _ in
                    let reading = QuestDayClock.read(engine.now())
                    HStack(spacing: 6) {
                        QuestDayRing(fraction: reading.fraction, calm: calm)
                        Text(engine.tf("quests.daily.left", reading.hours, reading.minutes))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(QuestColor.section)
                            .contentTransition(calm ? .identity : .numericText())
                            .animation(calm ? nil : .snappy(duration: 0.35), value: reading.minutes)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(engine.tf("quests.daily.leftA11y", reading.hours, reading.minutes))
                    .onAppear {
                        if seenDay.isEmpty { seenDay = reading.dayKey }
                    }
                    .onChange(of: reading.dayKey) { _, key in
                        if seenDay.isEmpty {
                            seenDay = key
                            return
                        }
                        if key != seenDay {
                            seenDay = key
                            onReturn()
                        }
                    }
                }
            }
            if cards.isEmpty {
                Text(engine.t("quests.daily.empty"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuestColor.sub)
                    .padding(.horizontal, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { _, card in
                        HStack(alignment: .center, spacing: 8) {
                            Circle()
                                .fill(QuestColor.page)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Color(hex: 0xC5D0D8), lineWidth: 2.5))
                                .frame(width: 16)
                            dailyCard(card)
                        }
                    }
                }
                .background(alignment: .leading) {
                    GeometryReader { geo in
                        Path { path in
                            path.move(to: CGPoint(x: 8, y: 22))
                            path.addLine(to: CGPoint(x: 8, y: max(22, geo.size.height - 22)))
                        }
                        .stroke(
                            Color(hex: 0xC5D0D8),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1.4, 5])
                        )
                    }
                }
            }
        }
        .sheet(item: $hop, onDismiss: onReturn) { token in
            NavigationStack {
                hopScreen(token.metric)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(engine.t("common.close")) { hop = nil }
                        }
                    }
            }
        }
    }

    private func dailyCard(_ card: JourneyCard) -> some View {
        HStack(alignment: .center, spacing: 10) {
            QuestDailyTile(metric: card.metric)
            VStack(alignment: .leading, spacing: 6) {
                Text(card.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(QuestColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                QuestMeter(progress: card.progress, goal: card.goal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing(card)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: QuestColor.cardShadow.opacity(0.08), radius: 0.5, y: 1)
        .shadow(color: QuestColor.cardShadow.opacity(0.12), radius: 6, y: 3)
        .opacity(card.claimed ? 0.72 : 1)
    }

    @ViewBuilder
    private func trailing(_ card: JourneyCard) -> some View {
        if card.ready {
            Button {
                claim(card)
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(QuestColor.ink)
                    .frame(width: 36, height: 36)
                    .background(QuestColor.yellow, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(QuestPressStyle(calm: calm))
            .accessibilityLabel(engine.tf("quests.daily.claimA11y", card.title))
        } else if card.claimed {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(QuestColor.sub)
                .frame(width: 36, height: 36)
                .accessibilityLabel(engine.t("quests.claimed"))
        } else if card.canOpen {
            Button {
                hop = QuestHopToken(metric: card.metric)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: 0x8B98A3))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: 0xF3F5F7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(QuestPressStyle(calm: calm))
            .accessibilityLabel(engine.tf("quests.daily.openA11y", card.title))
        }
    }

    @ViewBuilder
    private func hopScreen(_ metric: String) -> some View {
        switch metric {
        case "mood":
            MoodScreen(engine: engine)
        case "journal":
            JournalScreen(engine: engine)
        case "breath":
            BreathingView(engine: engine, reduceMotion: calm)
        case "focus":
            FocusTimerView(engine: engine)
        case "movement":
            MovementList(engine: engine)
        case "adventure":
            WorldScreen(engine: engine, reduceMotion: calm)
        default:
            Text(engine.t("quests.daily.empty"))
                .foregroundStyle(QuestColor.ink)
        }
    }
}

struct QuestDayRing: View {
    var fraction: Double
    var calm: Bool

    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: 0xC5D0D8), lineWidth: 2)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(Color(hex: 0x6E7C88), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 16, height: 16)
        .animation(calm ? nil : .linear(duration: 0.35), value: fraction)
        .accessibilityHidden(true)
    }
}

struct QuestDailyTile: View {
    var metric: String

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 48
            var ink = context
            ink.scaleBy(x: scale, y: scale)
            let rect = CGRect(x: 0, y: 0, width: 48, height: 48)
            ink.fill(Path(roundedRect: rect, cornerRadius: 14), with: .color(fill))
            glyph(&ink)
        }
        .frame(width: 48, height: 48)
        .accessibilityHidden(true)
    }

    private var fill: Color {
        switch metric {
        case "habits": Color(hex: 0x7BC67E)
        case "mood": Color(hex: 0xF6C445)
        case "journal": Color(hex: 0xF48FB1)
        case "breath": Color(hex: 0x7ED0F2)
        case "focus": Color(hex: 0x7C93F5)
        case "movement": Color(hex: 0xF0A04B)
        case "pet": Color(hex: 0xF27BA2)
        case "adventure": Color(hex: 0xE07A4C)
        default: Color(hex: 0xC5D0D8)
        }
    }

    private func glyph(_ context: inout GraphicsContext) {
        let white = Color.white
        switch metric {
        case "habits":
            context.fill(Path(CGRect(x: 15, y: 12, width: 3, height: 26)), with: .color(white))
            var flag = Path()
            flag.move(to: CGPoint(x: 18, y: 12))
            flag.addLine(to: CGPoint(x: 34, y: 17))
            flag.addLine(to: CGPoint(x: 18, y: 23))
            flag.closeSubpath()
            context.fill(flag, with: .color(white))
        case "mood":
            context.stroke(Path(ellipseIn: CGRect(x: 12, y: 12, width: 24, height: 24)), with: .color(white), lineWidth: 2.4)
            context.fill(Path(ellipseIn: CGRect(x: 19, y: 20, width: 3, height: 3)), with: .color(white))
            context.fill(Path(ellipseIn: CGRect(x: 26, y: 20, width: 3, height: 3)), with: .color(white))
            var smile = Path()
            smile.move(to: CGPoint(x: 19, y: 27))
            smile.addQuadCurve(to: CGPoint(x: 29, y: 27), control: CGPoint(x: 24, y: 32))
            context.stroke(smile, with: .color(white), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        case "journal":
            context.fill(Path(roundedRect: CGRect(x: 14, y: 11, width: 20, height: 26), cornerRadius: 3), with: .color(white))
            context.fill(Path(CGRect(x: 18, y: 17, width: 12, height: 1.6)), with: .color(fill))
            context.fill(Path(CGRect(x: 18, y: 22, width: 12, height: 1.6)), with: .color(fill))
            context.fill(Path(CGRect(x: 18, y: 27, width: 8, height: 1.6)), with: .color(fill))
        case "breath":
            for index in 0..<3 {
                var wave = Path()
                let y = CGFloat(16 + index * 8)
                wave.move(to: CGPoint(x: 12, y: y))
                wave.addQuadCurve(to: CGPoint(x: 36, y: y), control: CGPoint(x: 24, y: y - 6))
                context.stroke(wave, with: .color(white), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
        case "focus":
            context.stroke(Path(ellipseIn: CGRect(x: 12, y: 12, width: 24, height: 24)), with: .color(white), lineWidth: 2.4)
            var hands = Path()
            hands.move(to: CGPoint(x: 24, y: 24))
            hands.addLine(to: CGPoint(x: 24, y: 16))
            hands.move(to: CGPoint(x: 24, y: 24))
            hands.addLine(to: CGPoint(x: 30, y: 27))
            context.stroke(hands, with: .color(white), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        case "movement":
            context.fill(Path(ellipseIn: CGRect(x: 21, y: 10, width: 6, height: 6)), with: .color(white))
            var body = Path()
            body.move(to: CGPoint(x: 24, y: 16))
            body.addLine(to: CGPoint(x: 24, y: 28))
            body.move(to: CGPoint(x: 14, y: 20))
            body.addLine(to: CGPoint(x: 34, y: 18))
            body.move(to: CGPoint(x: 24, y: 28))
            body.addLine(to: CGPoint(x: 18, y: 38))
            body.move(to: CGPoint(x: 24, y: 28))
            body.addLine(to: CGPoint(x: 31, y: 38))
            context.stroke(body, with: .color(white), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        case "pet":
            var heart = Path()
            heart.move(to: CGPoint(x: 24, y: 34))
            heart.addCurve(to: CGPoint(x: 14, y: 22), control1: CGPoint(x: 16, y: 30), control2: CGPoint(x: 14, y: 26))
            heart.addCurve(to: CGPoint(x: 20, y: 16), control1: CGPoint(x: 14, y: 18), control2: CGPoint(x: 16.5, y: 16))
            heart.addCurve(to: CGPoint(x: 24, y: 19), control1: CGPoint(x: 22, y: 16), control2: CGPoint(x: 23.2, y: 17.2))
            heart.addCurve(to: CGPoint(x: 28, y: 16), control1: CGPoint(x: 24.8, y: 17.2), control2: CGPoint(x: 26, y: 16))
            heart.addCurve(to: CGPoint(x: 34, y: 22), control1: CGPoint(x: 31.5, y: 16), control2: CGPoint(x: 34, y: 18))
            heart.addCurve(to: CGPoint(x: 24, y: 34), control1: CGPoint(x: 34, y: 26), control2: CGPoint(x: 32, y: 30))
            heart.closeSubpath()
            context.fill(heart, with: .color(white))
        default:
            context.fill(Path(roundedRect: CGRect(x: 16, y: 18, width: 16, height: 18), cornerRadius: 4), with: .color(white))
            context.fill(Path(roundedRect: CGRect(x: 18, y: 12, width: 12, height: 8), cornerRadius: 3), with: .color(white.opacity(0.85)))
        }
    }
}
