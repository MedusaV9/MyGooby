import SwiftUI

enum QuestColor {
    static var page: Color { Paint.pick(0xCEDBE4) { $0.quests } }
    static var ink: Color { Paint.pick(0x2F2F2F) { $0.ink } }
    static var sub: Color { Paint.pick(0x818181) { $0.inkFaint } }
    static var hintFill: Color { Paint.pick(0xF3F3F3) { $0.well } }
    static var hintInk: Color { Paint.pick(0x6A7480) { $0.inkSoft } }
    static var track: Color { Paint.pick(0xE9EEF3) { $0.isDark ? HexMix.mix($0.inkFaint, $0.card, 0.3) : $0.well } }
    static var yellow: Color { Paint.pick(0xFEC957) { $0.energy } }
    static var meterInk: Color { Paint.pick(0x3E4652) { $0.isDark ? UInt32(0x15161A) : $0.ink } }
    static var cardShadow: Color { Paint.pick(0x5F7387) { $0.shadow } }
    static var card: Color { Paint.pick(0xFFFFFF) { $0.card } }
    static var hintShadow: Color { Paint.pick(0x5A646E) { $0.shadow } }
    static let section = Color(hex: 0x8B98A3)
    static let pink = Color(hex: 0xF278B6)
}

@MainActor
enum QuestCopy {
    static func petName(_ engine: GoobyEngine) -> String {
        let name = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Gooby" : name
    }

    static func line(_ engine: GoobyEngine, _ key: String, fallback: String) -> String {
        let value = engine.t(key)
        if value == key { return fallback }
        if value.contains("%@") || value.contains("%d") {
            return engine.tf(key, petName(engine))
        }
        return value
    }
}

struct QuestSectionHead<Trailing: View>: View {
    var title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(0.7)
                .textCase(.uppercase)
                .foregroundStyle(QuestColor.section)
            Spacer(minLength: 8)
            trailing()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct HintToken: Identifiable {
    var id: String
}

struct JourneyCard: Identifiable {
    var id: String
    var kind: QuestIconKind
    var metric: String
    var title: String
    var subtitle: String
    var progress: Int
    var goal: Int
    var sparks: Int
    var claimed: Bool
    var hint: String

    var ready: Bool { !claimed && progress >= goal }

    var canOpen: Bool {
        switch metric {
        case "mood", "journal", "breath", "focus", "movement", "adventure":
            return true
        default:
            return false
        }
    }
}

@MainActor
struct QuestBoard {
    var engine: GoobyEngine

    static let specialOrder = [
        "look-energy-7",
        "look-cloth-1",
        "look-decor-1",
        "m-friend",
        "look-places-2",
        "look-adv-7",
        "look-friends-3",
        "look-bond-2"
    ]

    func specialCards() -> [JourneyCard] {
        let records = engine.all(QuestRecord.self)
        return Self.specialOrder.compactMap { id in
            guard let template = engine.catalog.questsByID[id] else { return nil }
            let record = records.first { $0.templateID == id }
            return make(id: id, template: template, record: record)
        }
    }

    func dailyCards() -> [JourneyCard] {
        let key = engine.dayKey()
        let templates = engine.catalog.quests.filter { $0.kind == "daily" }
        let ordered = ShopRotation.orderedIDs(
            templates.map(\.id),
            dayKey: key,
            category: "daily-quests",
            appSeed: engine.profile.appSeed
        )
        let rank = Dictionary(uniqueKeysWithValues: ordered.enumerated().map { ($1, $0) })
        let rows = engine.all(QuestRecord.self).filter { $0.kind == "daily" && $0.dayKey == key }
        return rows
            .sorted { (rank[$0.templateID] ?? 999) < (rank[$1.templateID] ?? 999) }
            .prefix(3)
            .compactMap { record in
                guard let template = engine.catalog.questsByID[record.templateID] else { return nil }
                return make(id: record.templateID, template: template, record: record)
            }
    }

    private func make(id: String, template: QuestTemplate, record: QuestRecord?) -> JourneyCard {
        let goal = max(1, record?.goal ?? template.goal)
        let name = QuestCopy.petName(engine)
        let fallbackTitle = template.title.text(engine.languageCode).replacingOccurrences(of: "Gooby", with: name)
        let fallbackDetail = template.detail.text(engine.languageCode).replacingOccurrences(of: "Gooby", with: name)
        let claimed = record?.claimed ?? false
        return JourneyCard(
            id: id,
            kind: Self.icon(for: id),
            metric: template.metric,
            title: QuestCopy.line(engine, "quests.card.\(id).title", fallback: fallbackTitle),
            subtitle: QuestCopy.line(engine, "quests.card.\(id).detail", fallback: fallbackDetail),
            progress: record?.progress ?? 0,
            goal: goal,
            sparks: record?.rewardSparks ?? template.rewardSparks,
            claimed: claimed,
            hint: engine.t(claimed ? "quests.hint.done" : "quests.hint.\(id)")
        )
    }

    static func icon(for id: String) -> QuestIconKind {
        switch id {
        case "look-cloth-1": return .clothing
        case "look-decor-1": return .decoration
        case "look-friends-3", "m-friend": return .micropet
        case "look-places-2": return .location
        case "look-bond-2": return .friendship
        case "look-energy-7": return .energy
        default: return .adventure
        }
    }
}

struct QuestsJourneyScreen: View {
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var hint: HintToken?
    @State private var revision = 0

    private var calm: Bool { systemReduce || engine.reduceMotion }

    var body: some View {
        let _ = (engine.celebration, engine.languageCode, revision)
        let board = QuestBoard(engine: engine)
        let season = engine.featuredSeason()
        let specials = board.specialCards()
        let dailies = board.dailyCards()
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let season {
                    QuestSeasonHero(engine: engine, window: season, calm: calm)
                }
                QuestGratitudeJar(engine: engine, calm: calm, revision: revision) {
                    revision += 1
                }
                QuestDailyLine(engine: engine, cards: dailies, calm: calm, claim: claimDaily, onReturn: refresh)
                if !specials.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        QuestSectionHead(title: engine.t("quests.section.special")) { EmptyView() }
                        ForEach(specials) { card in
                            QuestCard(card: card, hintWord: engine.t("quests.hint"), calm: calm) {
                                hint = HintToken(id: card.id)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(QuestColor.page.ignoresSafeArea())
        .navigationTitle(engine.t("quests.title"))
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refresh)
        .sheet(item: $hint, onDismiss: refresh) { token in
            QuestHintSheet(engine: engine, questID: token.id) { hint = nil }
        }
    }

    func refresh() {
        engine.ensureMilestones()
        engine.ensureDailyQuests(engine.dayKey())
        engine.recomputeQuests()
        engine.save()
    }

    func claimDaily(_ card: JourneyCard) {
        engine.recomputeQuests()
        let key = engine.dayKey()
        if let record = engine.all(QuestRecord.self).first(where: {
            $0.templateID == card.id && $0.kind == "daily" && $0.dayKey == key && !$0.claimed
        }) {
            _ = engine.claimQuest(record)
        }
    }
}

struct QuestCard: View {
    var card: JourneyCard
    var hintWord: String
    var calm: Bool
    var hint: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            QuestIconTile(kind: card.kind)
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(QuestColor.ink)
                        .lineSpacing(1)
                        .fixedSize(horizontal: false, vertical: true)
                    if !card.subtitle.isEmpty {
                        Text(card.subtitle)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(QuestColor.sub)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                QuestMeter(progress: card.progress, goal: card.goal)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: hint) {
                Text(hintWord)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuestColor.hintInk)
                    .frame(width: 74, height: 44)
                    .background(QuestColor.hintFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: QuestColor.hintShadow.opacity(0.16), radius: 3, y: 2)
            }
            .buttonStyle(QuestPressStyle(calm: calm))
            .accessibilityLabel("\(hintWord), \(card.title)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(QuestColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: QuestColor.cardShadow.opacity(0.08), radius: 0.5, y: 1)
        .shadow(color: QuestColor.cardShadow.opacity(0.12), radius: 6, y: 3)
        .opacity(card.claimed ? 0.72 : 1)
    }
}

struct QuestPressStyle: ButtonStyle {
    var calm: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    func makeBody(configuration: Configuration) -> some View {
        let still = calm || systemReduce
        configuration.label
            .scaleEffect(!still && configuration.isPressed ? 0.96 : 1)
            .animation(still ? nil : .spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct QuestMeter: View {
    var progress: Int
    var goal: Int

    var body: some View {
        let safeGoal = max(1, goal)
        let shown = min(max(0, progress), safeGoal)
        GeometryReader { geo in
            let height = geo.size.height
            let width = geo.size.width
            let ratio = CGFloat(shown) / CGFloat(safeGoal)
            let fill = shown == 0 ? height * 1.65 : min(width, max(height * 1.65, width * ratio))
            let label = "\(shown) / \(safeGoal)"
            ZStack {
                Capsule().fill(QuestColor.track)
                HStack(spacing: 0) {
                    Capsule()
                        .fill(QuestColor.yellow)
                        .frame(width: fill)
                    Spacer(minLength: 0)
                }
                Text(label)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(QuestColor.meterInk)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: 18)
        .accessibilityLabel("\(shown) / \(safeGoal)")
    }
}

struct QuestHintSheet: View {
    var engine: GoobyEngine
    var questID: String
    var close: () -> Void

    var body: some View {
        let card = QuestBoard(engine: engine).specialCards().first { $0.id == questID }
        VStack(alignment: .leading, spacing: 14) {
            if let card {
                QuestIconTile(kind: card.kind)
                Text(card.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(QuestColor.ink)
                Text(card.hint)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(QuestColor.ink.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
                if card.ready {
                    Button(engine.tf("quests.claim", card.sparks)) {
                        claim(card)
                    }
                    .buttonStyle(GoobyButtonStyle(fill: QuestColor.yellow, ink: QuestColor.ink))
                    .padding(.top, 6)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(QuestColor.page.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func claim(_ card: JourneyCard) {
        engine.recomputeQuests()
        if let record = engine.all(QuestRecord.self).first(where: { $0.templateID == card.id && !$0.claimed }) {
            _ = engine.claimQuest(record)
        }
        close()
    }
}
