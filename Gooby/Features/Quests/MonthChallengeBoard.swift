import SwiftUI

struct MonthChallengeRow: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var progress: Int
    var goal: Int
    var sparks: Int
    var claimed: Bool

    var ready: Bool { !claimed && progress >= goal }
}

@MainActor
enum MonthChallengeList {
    static let order = ["month-days", "month-checks", "month-same"]

    static func rows(_ engine: GoobyEngine) -> [MonthChallengeRow] {
        let key = engine.monthKey()
        let records = engine.all(QuestRecord.self).filter { $0.kind == "month" && $0.dayKey == key }
        return order.compactMap { id in
            guard let template = engine.catalog.questsByID[id] else { return nil }
            let record = records.first { $0.templateID == id }
            let name = QuestCopy.petName(engine)
            let fallbackTitle = template.title.text(engine.languageCode).replacingOccurrences(of: "Gooby", with: name)
            let fallbackDetail = template.detail.text(engine.languageCode).replacingOccurrences(of: "Gooby", with: name)
            return MonthChallengeRow(
                id: id,
                title: QuestCopy.line(engine, "quests.card.\(id).title", fallback: fallbackTitle),
                subtitle: QuestCopy.line(engine, "quests.card.\(id).detail", fallback: fallbackDetail),
                progress: record?.progress ?? 0,
                goal: max(1, record?.goal ?? template.goal),
                sparks: record?.rewardSparks ?? template.rewardSparks,
                claimed: record?.claimed ?? false
            )
        }
    }
}

struct MonthChallengeBoard: View {
    var engine: GoobyEngine
    var calm: Bool
    var claimed: () -> Void

    var body: some View {
        let rows = MonthChallengeList.rows(engine)
        let label = monthLabel
        VStack(alignment: .leading, spacing: 8) {
            QuestSectionHead(title: engine.t("quests.section.month")) {
                Text(label)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(QuestColor.section)
                    .multilineTextAlignment(.trailing)
            }
            Text(engine.t("quests.month.lead"))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(QuestColor.sub)
                .fixedSize(horizontal: false, vertical: true)
            if !engine.hasLiveHabits() {
                Text(engine.t("quests.month.empty"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuestColor.ink.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !rows.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        if index > 0 {
                            Rectangle()
                                .fill(QuestColor.track)
                                .frame(height: 1)
                                .padding(.leading, 66)
                        }
                        MonthChallengeLine(engine: engine, row: row, calm: calm, claim: claim)
                    }
                }
                .background(QuestColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: QuestColor.cardShadow.opacity(0.08), radius: 0.5, y: 1)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.setLocalizedDateFormatFromTemplate("LLLL y")
        return formatter.string(from: engine.now())
    }

    private func claim(_ row: MonthChallengeRow) {
        engine.recomputeQuests()
        let key = engine.monthKey()
        if let record = engine.all(QuestRecord.self).first(where: {
            $0.templateID == row.id && $0.kind == "month" && $0.dayKey == key && !$0.claimed
        }) {
            _ = engine.claimQuest(record)
        }
        claimed()
    }
}

private struct MonthChallengeLine: View {
    var engine: GoobyEngine
    var row: MonthChallengeRow
    var calm: Bool
    var claim: (MonthChallengeRow) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MonthChallengeMark(id: row.id)
            VStack(alignment: .leading, spacing: 6) {
                Text(row.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(QuestColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if !row.subtitle.isEmpty {
                    Text(row.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(QuestColor.sub)
                        .fixedSize(horizontal: false, vertical: true)
                }
                QuestMeter(progress: row.progress, goal: row.goal)
                HStack(alignment: .center, spacing: 8) {
                    if row.claimed {
                        Text(engine.t("quests.claimed"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(QuestColor.sub)
                    } else if row.ready {
                        Button {
                            claim(row)
                        } label: {
                            Text(engine.tf("quests.claim", row.sparks))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(QuestColor.meterInk)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(QuestColor.yellow, in: Capsule())
                        }
                        .buttonStyle(QuestPressStyle(calm: calm))
                    } else {
                        Text(engine.tf("adventure.sparks", row.sparks))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(QuestColor.sub)
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .opacity(row.claimed ? 0.72 : 1)
        .accessibilityElement(children: .contain)
    }
}

private struct MonthChallengeMark: View {
    var id: String

    var body: some View {
        Canvas { context, size in
            let scale = size.width / 44
            var context = context
            context.scaleBy(x: scale, y: scale)
            let tile = Path(roundedRect: CGRect(x: 0, y: 0, width: 44, height: 44), cornerRadius: 12)
            context.fill(tile, with: .color(fill))
            switch id {
            case "month-days": calendar(&context)
            case "month-checks": check(&context)
            default: repeatMark(&context)
            }
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }

    private var fill: Color {
        switch id {
        case "month-days": Color(hex: 0x3C7D8C)
        case "month-checks": Color(hex: 0xE7B423)
        default: Color(hex: 0xC45B8A)
        }
    }

    private func calendar(_ context: inout GraphicsContext) {
        let page = Path(roundedRect: CGRect(x: 10, y: 12, width: 24, height: 22), cornerRadius: 4)
        context.fill(page, with: .color(.white))
        context.fill(Path(roundedRect: CGRect(x: 10, y: 12, width: 24, height: 6), cornerRadius: 2), with: .color(Color(hex: 0xF4E2C4)))
        for point in [CGPoint(x: 16, y: 24), CGPoint(x: 22, y: 24), CGPoint(x: 28, y: 24), CGPoint(x: 16, y: 29)] {
            context.fill(Path(ellipseIn: CGRect(x: point.x - 1.4, y: point.y - 1.4, width: 2.8, height: 2.8)), with: .color(Color(hex: 0x3C7D8C)))
        }
    }

    private func check(_ context: inout GraphicsContext) {
        var mark = Path()
        mark.move(to: CGPoint(x: 12, y: 23))
        mark.addLine(to: CGPoint(x: 19, y: 30))
        mark.addLine(to: CGPoint(x: 33, y: 15))
        context.stroke(mark, with: .color(Color(hex: 0x3D3420)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round))
    }

    private func repeatMark(_ context: inout GraphicsContext) {
        let back = Path(roundedRect: CGRect(x: 15, y: 9, width: 18, height: 14), cornerRadius: 4)
        let front = Path(roundedRect: CGRect(x: 11, y: 17, width: 18, height: 14), cornerRadius: 4)
        context.fill(back, with: .color(.white.opacity(0.5)))
        context.fill(front, with: .color(.white))
        var tick = Path()
        tick.move(to: CGPoint(x: 15, y: 24))
        tick.addLine(to: CGPoint(x: 18.4, y: 27.4))
        tick.addLine(to: CGPoint(x: 25, y: 20.6))
        context.stroke(tick, with: .color(Color(hex: 0xC45B8A)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
    }
}
