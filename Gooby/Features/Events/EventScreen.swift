import SwiftUI

struct EventScreen: View {
    var engine: GoobyEngine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(engine.catalog.events) { event in
                    let active = engine.isEventActive(event.id)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.title.text(engine.languageCode)).font(.system(.title3, design: .rounded).weight(.bold))
                        Text(event.blurb.text(engine.languageCode))
                        Text(active ? engine.t("events.active") : engine.t("events.upcoming"))
                        Text(String(format: "%02d.%02d – %02d.%02d", event.startDay, event.startMonth, event.endDay, event.endMonth))
                        if active {
                            let record = engine.all(EventRecord.self).first { $0.eventID == event.id }
                            let claimed = record.map { engine.claimedTasks($0) } ?? []
                            ForEach(event.tasks) { task in
                                let progress = engine.eventProgress(event, task)
                                VStack(alignment: .leading) {
                                    Text(task.title.text(engine.languageCode))
                                    ProgressRibbon(value: Double(progress) / Double(max(1, task.goal)))
                                    Text("\(progress)/\(task.goal)")
                                    if claimed.contains(task.id) {
                                        Text(engine.t("quests.claimed"))
                                    } else if progress >= task.goal {
                                        Button(engine.t("common.claim")) { _ = engine.claimEventTask(event, task) }
                                            .buttonStyle(.borderedProminent)
                                    }
                                }
                            }
                        }
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(14)
                    .background(active ? Theme.yellow.opacity(0.65) : Theme.whiteCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("events.title"))
    }
}
