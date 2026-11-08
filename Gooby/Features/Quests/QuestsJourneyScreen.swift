import SwiftUI

enum QuestColor {
    static let page = Color(hex: 0xCEDBE4)
    static let ink = Color(hex: 0x2F2F2F)
    static let sub = Color(hex: 0x818181)
    static let hintFill = Color(hex: 0xF3F3F3)
    static let hintInk = Color(hex: 0x6A7480)
    static let track = Color(hex: 0xE9EEF3)
    static let yellow = Color(hex: 0xFEC957)
    static let meterInk = Color(hex: 0x3E4652)
}

struct HintToken: Identifiable {
    var id: String
}

struct JourneyCard: Identifiable {
    var id: String
    var kind: QuestIconKind
    var title: String
    var subtitle: String
    var progress: Int
    var goal: Int
    var sparks: Int
    var claimed: Bool
    var hint: String

    var ready: Bool { !claimed && progress >= goal }
}

struct QuestsJourneyScreen: View {
    var engine: GoobyEngine
    @State private var hint: HintToken?

    private let order = [
        "look-adv-7",
        "look-cloth-1",
        "look-decor-1",
        "look-friends-3",
        "look-places-2",
        "look-bond-2"
    ]

    var body: some View {
        let cards = journeyCards()
        ScrollView {
            VStack(spacing: 8) {
                ForEach(cards) { card in
                    QuestCard(card: card, hintWord: engine.t("quests.hint")) {
                        hint = HintToken(id: card.id)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 18)
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
        engine.recomputeQuests()
        syncDecoration()
        engine.save()
    }

    func syncDecoration() {
        let decorations = decorationCount()
        if let row = engine.all(QuestRecord.self).first(where: { $0.templateID == "look-decor-1" && !$0.claimed }) {
            row.progress = decorations
        }
    }

    func decorationCount() -> Int {
        engine.all(OwnedItem.self).filter { item in
            item.kind == "furniture" && engine.catalog.itemsByID[item.catalogID]?.starter == false
        }.count
    }

    func journeyCards() -> [JourneyCard] {
        let _ = (engine.celebration, engine.languageCode)
        let records = engine.all(QuestRecord.self)
        return order.compactMap { id in
            guard let template = engine.catalog.questsByID[id] else { return nil }
            let record = records.first { $0.templateID == id }
            let goal = max(1, record?.goal ?? template.goal)
            let progress = record?.progress ?? 0
            let detail = template.detail.text(engine.languageCode)
            return JourneyCard(
                id: id,
                kind: icon(for: id),
                title: template.title.text(engine.languageCode),
                subtitle: detail,
                progress: progress,
                goal: goal,
                sparks: record?.rewardSparks ?? template.rewardSparks,
                claimed: record?.claimed ?? false,
                hint: engine.t(record?.claimed == true ? "quests.hint.done" : "quests.hint.\(id)")
            )
        }
    }

    private func icon(for id: String) -> QuestIconKind {
        switch id {
        case "look-cloth-1": .clothing
        case "look-decor-1": .decoration
        case "look-friends-3": .micropet
        case "look-places-2": .location
        case "look-bond-2": .friendship
        default: .adventure
        }
    }
}

struct QuestCard: View {
    var card: JourneyCard
    var hintWord: String
    var hint: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                            .frame(maxWidth: card.subtitle.count > 22 ? CGFloat(146) : nil, alignment: .leading)
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
                    .shadow(color: Color(hex: 0x5A646E).opacity(0.16), radius: 3, y: 2)
            }
            .buttonStyle(QuestPressStyle(reduceMotion: reduceMotion))
            .accessibilityLabel("\(hintWord), \(card.title)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color(hex: 0x8AA0B4).opacity(0.12), radius: 5, y: 2)
    }
}

private struct QuestPressStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? nil : .spring(duration: 0.2), value: configuration.isPressed)
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
        let card = QuestsJourneyScreen(engine: engine).journeyCards().first { $0.id == questID }
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
        let screen = QuestsJourneyScreen(engine: engine)
        screen.syncDecoration()
        engine.recomputeQuests()
        if card.id == "look-decor-1" {
            screen.syncDecoration()
        }
        if let record = engine.all(QuestRecord.self).first(where: { $0.templateID == card.id && !$0.claimed }) {
            _ = engine.claimQuest(record)
        }
        close()
    }
}
