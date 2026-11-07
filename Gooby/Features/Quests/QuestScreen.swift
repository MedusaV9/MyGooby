import SwiftUI

/// Quests tab (screenshot-reference.md, screen 3): pale blue-grey background, uppercase section
/// headers and white quest cards with a colored icon tile, title, description, striped progress
/// bar and a 3D "Hint" or "Claim" button. Sections: today's quests, the active event, achievements
/// and the achievements already claimed.
struct QuestScreen: View {
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    var body: some View {
        let reduce = systemReduce || appReduce
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                header
                SectionCaps(engine.tx("home.quests.daily", de: "Heute", en: "Today"))
                    .padding(.top, 6)
                ForEach(Array(daily.enumerated()), id: \.element.id) { index, quest in
                    card(quest)
                        .goobyEntrance(index)
                }
                ForEach(activeEvents) { event in
                    eventSection(event)
                        .goobyEntrance(3)
                }
                SectionCaps(engine.tx("home.quests.achievements", de: "Erfolge", en: "Achievements"))
                    .padding(.top, 10)
                // Claimed achievements move down to "Completed" with a soft slide.
                ForEach(Array(openMilestones.enumerated()), id: \.element.id) { index, quest in
                    card(quest)
                        .goobyEntrance(index + 4)
                        .transition(.goobyCard(reduce))
                }
                if !claimedMilestones.isEmpty {
                    SectionCaps(engine.tx("home.quests.claimed", de: "Geschafft", en: "Completed"))
                        .padding(.top, 10)
                    ForEach(claimedMilestones) { quest in
                        card(quest)
                            .transition(.goobyCard(reduce))
                    }
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Theme.Tab.quests.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        // Reward particles play in MainTabs' layer (goobyCelebrations).
        .onAppear {
            engine.recomputeQuests()
            engine.save()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.t("quests.title"))
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                Text(resetText)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.capsGrey)
            }
            Spacer()
            Text(verbatim: "✨ \(engine.wallet.sparks)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .goobyCounter(engine.wallet.sparks)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.white, in: Capsule())
                .goobyGainFloat(engine.wallet.sparks)
                .accessibilityLabel(engine.tf("adventure.sparks", engine.wallet.sparks))
        }
        .padding(.top, 16)
    }

    /// Time until the daily quests renew at midnight.
    private var resetText: String {
        let now = engine.now()
        let calendar = Calendar.current
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let minutes = max(1, Int(midnight.timeIntervalSince(now) / 60))
        return engine.txf("home.quests.reset", de: "Neue Tagesquests in %d Std. %d Min.", en: "New daily quests in %dh %dm", minutes / 60, minutes % 60)
    }

    // MARK: Data

    private var catalogOrder: [String: Int] {
        Dictionary(engine.catalog.quests.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
    }

    private func ordered(_ rows: [QuestRecord]) -> [QuestRecord] {
        let order = catalogOrder
        return rows.sorted { (order[$0.templateID] ?? Int.max) < (order[$1.templateID] ?? Int.max) }
    }

    private var daily: [QuestRecord] {
        let key = engine.dayKey()
        return ordered(engine.all(QuestRecord.self).filter { $0.kind == "daily" && $0.dayKey == key })
    }

    private var milestones: [QuestRecord] {
        ordered(engine.all(QuestRecord.self).filter { $0.kind == "milestone" })
    }

    /// Open achievements, the claimable ones first.
    private var openMilestones: [QuestRecord] {
        let open = milestones.filter { !$0.claimed }
        return open.filter { $0.progress >= $0.goal } + open.filter { $0.progress < $0.goal }
    }

    private var claimedMilestones: [QuestRecord] {
        milestones.filter(\.claimed)
    }

    private var activeEvents: [EventDef] {
        engine.catalog.events.filter { engine.isEventActive($0.id) }
    }

    /// Last day of the event's current window, e.g. "30. Nov." / "Nov 30".
    private func eventEnd(_ event: EventDef) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter.string(from: engine.eventBounds(event).1)
    }

    // MARK: Cards

    private func card(_ quest: QuestRecord) -> some View {
        let template = engine.catalog.questsByID[quest.templateID]
        return QuestTaskCard(
            engine: engine,
            title: template?.title.text(engine.languageCode) ?? quest.templateID,
            detail: template?.detail.text(engine.languageCode) ?? "",
            metric: template?.metric ?? "",
            progress: quest.progress,
            goal: max(1, quest.goal),
            reward: quest.rewardSparks,
            claimed: quest.claimed
        ) {
            goobyAnimate(systemReduce || appReduce) { _ = engine.claimQuest(quest) }
        }
    }

    private func eventSection(_ event: EventDef) -> some View {
        let record = engine.all(EventRecord.self).first { $0.eventID == event.id }
        let claimed = record.map { engine.claimedTasks($0) } ?? []
        let until = engine.txf("home.quests.until", de: "Bis %@", en: "Until %@", eventEnd(event))
        return VStack(alignment: .leading, spacing: Theme.Space.gap) {
            VStack(alignment: .leading, spacing: 4) {
                SectionCaps(event.title.text(engine.languageCode))
                Text(event.blurb.text(engine.languageCode))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.capsGrey)
                    .padding(.horizontal, 6)
            }
            .padding(.top, 10)
            ForEach(event.tasks) { task in
                QuestTaskCard(
                    engine: engine,
                    title: task.title.text(engine.languageCode),
                    detail: until,
                    metric: task.metric,
                    progress: engine.eventProgress(event, task),
                    goal: max(1, task.goal),
                    reward: task.rewardSparks,
                    claimed: claimed.contains(task.id)
                ) {
                    goobyAnimate(systemReduce || appReduce) { _ = engine.claimEventTask(event, task) }
                }
            }
        }
    }
}

/// White quest card: colored icon tile, title, grey description, striped progress bar and on the
/// right a grey "Hint" key (opens a how-to popover) or a yellow "Claim" key once the goal is met.
struct QuestTaskCard: View {
    var engine: GoobyEngine
    var title: String
    var detail: String
    var metric: String
    var progress: Int
    var goal: Int
    var reward: Int
    var claimed: Bool
    var claim: () -> Void
    @State private var showHint = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            QuestMetricTile(engine: engine, metric: metric)
                .opacity(claimed ? 0.55 : 1)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                if !detail.isEmpty {
                    Text(detail)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                StripedProgressBar(value: progress, goal: goal)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .cardShadow()
        // The card pops when its goal is reached and when it is claimed.
        .goobyPop(on: claimed, amount: 1.03)
        .goobyPop(on: progress >= goal, amount: 1.03)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var trailing: some View {
        VStack(spacing: 6) {
            if claimed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.checkGreen)
                    .transition(.goobyCard(false))
                    .accessibilityLabel(engine.t("quests.claimed"))
            } else if progress >= goal {
                Button(action: claim) {
                    Text(engine.t("common.claim"))
                        .foregroundStyle(Theme.brown)
                }
                .buttonStyle(Press3DButtonStyle(fill: Theme.progressFill, edge: Color(hex: 0xDDA22F), radius: 14, horizontal: 12, vertical: 9))
                .accessibilityLabel(engine.tf("quests.claim", reward))
            } else {
                Button { showHint = true } label: {
                    Text(engine.tx("home.quests.hint", de: "Tipp", en: "Hint"))
                        .foregroundStyle(Theme.greyText)
                }
                .buttonStyle(Press3DButtonStyle(radius: 14, horizontal: 14, vertical: 9))
                .popover(isPresented: $showHint) {
                    hintBubble
                        .presentationCompactAdaptation(.popover)
                }
            }
            Text(verbatim: "✨ \(reward)")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.greyText)
                .accessibilityLabel(engine.tf("adventure.sparks", reward))
        }
        .frame(minWidth: 64)
    }

    private var hintBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(QuestHints.text(for: metric, engine: engine))
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(engine.txf("home.quests.reward", de: "Belohnung: %d Sternenfunken", en: "Reward: %d star sparks", reward))
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.greyText)
        }
        .padding(16)
        .frame(width: 260, alignment: .leading)
    }
}

/// Colored rounded tile with the glyph for a quest metric (the six reference tile colors).
struct QuestMetricTile: View {
    var engine: GoobyEngine
    var metric: String

    var body: some View {
        let tint = Theme.Tab.quests
        IconTile(color: color(tint)) {
            if metric == "pet" {
                GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: 44)
            } else {
                GoobyIcon(glyph, size: 34)
            }
        }
        .accessibilityHidden(true)
    }

    private func color(_ tint: QuestsTint) -> Color {
        switch metric {
        case "pet", "streak": return tint.orange
        case "clothing", "focus", "journal": return tint.purple
        case "energy", "place": return tint.yellow
        case "habits", "movement": return tint.green
        case "adventure", "breath": return tint.sky
        default: return tint.pink
        }
    }

    private var glyph: String {
        switch metric {
        case "habits": return "✅"
        case "mood": return "😊"
        case "journal": return "📔"
        case "breath": return "🌬️"
        case "focus": return "⏱️"
        case "movement": return "🤸"
        case "adventure": return "🎒"
        case "energy": return "⚡"
        case "friend": return "🥚"
        case "place": return "🗺️"
        case "clothing": return "👕"
        case "streak": return "🔥"
        default: return "⭐"
        }
    }
}

/// How-to text behind the "Hint" key for each quest metric.
enum QuestHints {
    @MainActor
    static func text(for metric: String, engine: GoobyEngine) -> String {
        switch metric {
        case "habits", "energy":
            return engine.tx("home.hint.habits", de: "Hake auf der Startseite deine Ziele ab. Jedes Ziel zählt und gibt Energie.", en: "Check off your goals on Home. Every goal counts and gives energy.")
        case "mood":
            return engine.tx("home.hint.mood", de: "Tippe auf der Startseite oben rechts auf den gelben Smiley und trage deine Stimmung ein.", en: "Tap the yellow smiley at the top right of Home and log your mood.")
        case "journal":
            return engine.tx("home.hint.journal", de: "Öffne oben links auf der Startseite das Menü und schreib ins Tagebuch.", en: "Open the menu at the top left of Home and write in the journal.")
        case "breath":
            return engine.tx("home.hint.breath", de: "Unten auf der Startseite: „Ich brauche eine Pause“ und dann eine Atemrunde.", en: "At the bottom of Home: “I need a pause”, then one breathing round.")
        case "focus":
            return engine.tx("home.hint.focus", de: "Unten auf der Startseite: „Ich brauche eine Pause“ und dann den Fokus-Timer starten.", en: "At the bottom of Home: “I need a pause”, then start the focus timer.")
        case "movement":
            return engine.tx("home.hint.movement", de: "Unten auf der Startseite: „Ich brauche eine Pause“ und dann eine Bewegungsübung.", en: "At the bottom of Home: “I need a pause”, then one movement exercise.")
        case "pet":
            return engine.tx("home.hint.pet", de: "Tippe Gooby auf der Startseite an oder halte ihn gedrückt, um ihn zu streicheln.", en: "Tap Gooby on Home, or hold him to pet him.")
        case "adventure":
            return engine.tx("home.hint.adventure", de: "Sammle mit deinen Zielen Energie. Ist sie voll, startest du auf der Startseite ein Abenteuer.", en: "Gather energy with your goals. When it is full, start an adventure on Home.")
        case "friend":
            return engine.tx("home.hint.friend", de: "Binde in den Details eines Ziels ein Ei daran. Nach sieben Abschlüssen schlüpft ein Mini-Freund.", en: "Bind an egg to a goal in its details. After seven completions a mini-friend hatches.")
        case "place":
            return engine.tx("home.hint.place", de: "Neue Orte öffnen sich nach und nach, wenn Gooby von Abenteuern zurückkommt.", en: "New places open step by step as Gooby returns from adventures.")
        case "clothing":
            return engine.tx("home.hint.clothing", de: "Im Laden gibt es Kleidung für Sternenfunken.", en: "The shop has clothes for star sparks.")
        case "streak":
            return engine.tx("home.hint.streak", de: "Erledige jeden Tag mindestens ein Ziel, dann wächst deine Serie.", en: "Finish at least one goal every day and your streak grows.")
        default:
            return engine.tx("home.hint.default", de: "Kümmere dich gut um dich, dann kommt der Fortschritt von allein.", en: "Take good care of yourself and the progress follows.")
        }
    }
}
