import SwiftUI

/// Seasonal event for the second tab. Gooby crosses the water in a boat drawn for this screen.
/// The quest list stays one tap away. The boat, sail, and clock are original drawings.
struct EventFerryScreen: View {
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var showQuests = false
    @State private var revision = 0

    private var calm: Bool { systemReduce || engine.reduceMotion }

    var body: some View {
        let _ = (engine.celebration, engine.languageCode, revision)
        let window = featured
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let window, let event = event(for: window) {
                    EventFerryScene(
                        engine: engine,
                        calm: calm,
                        active: window.active,
                        kicker: QuestSeasonText.kicker(engine, window.starts),
                        title: event.title.text(engine.languageCode),
                        ribbon: QuestSeasonText.ribbon(engine, window)
                    )
                    Text(event.blurb.text(engine.languageCode))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(span(window))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.62))
                    QuestSectionHead(title: engine.t("event.ferry.tasks")) { EmptyView() }
                    ForEach(event.tasks) { task in
                        step(event, task, open: window.active)
                    }
                } else {
                    Text(engine.t("event.ferry.empty"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 28)
                }
                questsRow
            }
            .padding(16)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(engine.t("tab.event"))
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showQuests) {
            QuestsJourneyScreen(engine: engine)
                .safeAreaInset(edge: .top, spacing: 0) {
                    HStack {
                        Text(engine.t("quests.title"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Spacer()
                        Button(engine.t("common.close")) { showQuests = false }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.cream)
                }
        }
        .goobyCue(.sheet, opening: showQuests)
    }

    private var featured: QuestSeasonWindow? {
        #if DEBUG
        if let pinned = QuestShotSeed.season(engine) { return pinned }
        #endif
        return engine.featuredSeason()
    }

    private func event(for window: QuestSeasonWindow) -> EventDef? {
        engine.catalog.events.first { $0.id == window.eventID }
    }

    private func span(_ window: QuestSeasonWindow) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return "\(formatter.string(from: window.starts)) – \(formatter.string(from: window.ends))"
    }

    private var questsRow: some View {
        Button { showQuests = true } label: {
            HStack(spacing: 10) {
                Text(engine.t("quests.title"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint(engine.t("event.ferry.questsHint"))
    }

    private func step(_ event: EventDef, _ task: EventTaskDef, open: Bool) -> some View {
        let progress = engine.eventProgress(event, task)
        let record = engine.all(EventRecord.self).first { $0.eventID == event.id }
        let claimed = record.map { engine.claimedTasks($0) } ?? []
        let done = claimed.contains(task.id)
        let ready = open && !done && progress >= task.goal
        return VStack(alignment: .leading, spacing: 8) {
            Text(task.title.text(engine.languageCode))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            ProgressRibbon(value: Double(progress) / Double(max(1, task.goal)), tint: HomePalette.bolt)
            HStack {
                Text("\(min(progress, task.goal))/\(task.goal)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.62))
                Text(engine.tf("adventure.sparks", task.rewardSparks))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.62))
                Spacer(minLength: 8)
                if done {
                    Text(engine.t("quests.claimed"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(HomePalette.check)
                } else if ready {
                    Button(engine.t("common.claim")) {
                        if engine.claimEventTask(event, task) { revision += 1 }
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x3D3656))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(HomePalette.bolt, in: Capsule())
                }
            }
        }
        .padding(14)
        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct EventFerryScene: View {
    var engine: GoobyEngine
    var calm: Bool
    var active: Bool
    var kicker: String
    var title: String
    var ribbon: String

    var body: some View {
        TimelineView(.animation(minimumInterval: calm ? 8 : 1.0 / 30.0, paused: calm)) { timeline in
            let bob = calm ? 0 : sin(timeline.date.timeIntervalSinceReferenceDate * 1.25) * 5
            ZStack {
                EventFerryWater()
                VStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text(kicker)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .tracking(1.1)
                            .textCase(.uppercase)
                        Text(title)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                    }
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: 0x1E4C6A).opacity(0.35), radius: 0, y: 1)
                    .padding(.top, 18)
                    .padding(.horizontal, 16)
                    Spacer(minLength: 0)
                    ZStack {
                        EventFerryBoat()
                            .frame(width: 250, height: 92)
                            .offset(y: 18)
                        GoobyCharacterView(
                            look: engine.wornLook(),
                            stage: Growth.stage(of: engine.pet),
                            animation: active ? .wave : .curious,
                            reduceMotion: calm,
                            companion: nil,
                            showCompanion: false
                        )
                        .frame(width: 148, height: 148)
                        .offset(y: -34)
                    }
                    .offset(y: bob)
                    QuestRibbon(text: ribbon)
                        .padding(.top, 8)
                        .padding(.bottom, 14)
                }
                if !active {
                    Color.black.opacity(0.18)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 312)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(engine.t("event.ferry.scene")). \(kicker). \(title). \(ribbon)")
    }
}

private struct EventFerryWater: View {
    var body: some View {
        Canvas { context, size in
            let sky = CGRect(origin: .zero, size: size)
            context.fill(Path(sky), with: .linearGradient(
                Gradient(colors: [Color(hex: 0x9FD4F2), Color(hex: 0xC8E9FF)]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height * 0.55)
            ))
            let sun = CGRect(x: size.width - 78, y: 28, width: 46, height: 46)
            context.fill(Path(ellipseIn: sun), with: .color(Color(hex: 0xFFE7AD)))
            let waterTop = size.height * 0.58
            var water = Path()
            water.addRect(CGRect(x: 0, y: waterTop, width: size.width, height: size.height - waterTop))
            context.fill(water, with: .linearGradient(
                Gradient(colors: [Color(hex: 0x7EB6D6), Color(hex: 0x3E86B0)]),
                startPoint: CGPoint(x: 0, y: waterTop),
                endPoint: CGPoint(x: 0, y: size.height)
            ))
            var wave = Path()
            wave.move(to: CGPoint(x: 0, y: waterTop + 18))
            wave.addQuadCurve(
                to: CGPoint(x: size.width, y: waterTop + 14),
                control: CGPoint(x: size.width * 0.5, y: waterTop - 6)
            )
            context.stroke(wave, with: .color(.white.opacity(0.45)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

private struct EventFerryBoat: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var hull = Path()
            hull.move(to: CGPoint(x: w * 0.08, y: h * 0.42))
            hull.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.42), control: CGPoint(x: w * 0.5, y: h * 1.05))
            hull.addLine(to: CGPoint(x: w * 0.78, y: h * 0.34))
            hull.addLine(to: CGPoint(x: w * 0.22, y: h * 0.34))
            hull.closeSubpath()
            context.fill(hull, with: .color(Color(hex: 0xC08946)))
            context.fill(hull, with: .color(Color(hex: 0x8F6243).opacity(0.28)))
            var deck = Path()
            deck.addRoundedRect(
                in: CGRect(x: w * 0.24, y: h * 0.28, width: w * 0.52, height: h * 0.12),
                cornerSize: CGSize(width: 6, height: 6)
            )
            context.fill(deck, with: .color(Color(hex: 0xE7C48A)))
            var mast = Path()
            mast.addRoundedRect(
                in: CGRect(x: w * 0.48, y: h * 0.02, width: 4, height: h * 0.34),
                cornerSize: CGSize(width: 2, height: 2)
            )
            context.fill(mast, with: .color(Color(hex: 0x8F6243)))
            var sail = Path()
            sail.move(to: CGPoint(x: w * 0.50, y: h * 0.04))
            sail.addLine(to: CGPoint(x: w * 0.50, y: h * 0.32))
            sail.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.04), control: CGPoint(x: w * 0.18, y: h * 0.24))
            context.fill(sail, with: .color(Color(hex: 0xFFF8EF)))
            context.stroke(sail, with: .color(Color(hex: 0xE7D3C4)), style: StrokeStyle(lineWidth: 1.5))
        }
        .accessibilityHidden(true)
    }
}
