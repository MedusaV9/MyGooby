import SwiftUI

struct MoreScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        GoobyMenuView(engine: engine, reduceMotion: reduceMotion)
    }
}


struct JournalScreen: View {
    var engine: GoobyEngine
    @State private var query = ""
    @State private var editing: JournalEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                TextField(engine.t("common.search"), text: $query).textFieldStyle(.roundedBorder)
                Text(engine.t("journal.rewardHint")).font(.system(.caption, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.65))
                TimeCapsule.open(engine)
                ForEach(engine.catalog.prompts) { prompt in
                    Button(prompt.title.text(engine.languageCode)) {
                        editing = engine.addJournal(title: prompt.title.text(engine.languageCode), body: "", tags: [prompt.theme], promptID: prompt.id)
                    }
                    .buttonStyle(.bordered)
                }
                Button(engine.t("journal.new")) {
                    editing = engine.addJournal(title: "", body: "", tags: [], promptID: "")
                }
                .buttonStyle(GoobyButtonStyle())
                ForEach(filtered) { entry in
                    Button {
                        editing = entry
                    } label: {
                        VStack(alignment: .leading) {
                            Text(entry.title.isEmpty ? engine.t("journal.untitled") : entry.title).font(.system(.headline, design: .rounded))
                            Text(entry.body).lineLimit(3)
                            Text(entry.tags.map { tagLabel($0) }.joined(separator: ", ")).font(.system(.caption, design: .rounded))
                        }
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("journal.title"))
        .sheet(item: $editing) { entry in
            JournalEditor(engine: engine, entry: entry)
        }
    }

    private func tagLabel(_ tag: String) -> String {
        let key = "theme.\(tag)"
        let value = engine.t(key)
        return value == key ? tag : value
    }

    private var filtered: [JournalEntry] {
        engine.all(JournalEntry.self)
            .filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.body.localizedCaseInsensitiveContains(query) || $0.tags.contains { $0.localizedCaseInsensitiveContains(query) } }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}

struct JournalEditor: View {
    var engine: GoobyEngine
    var entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var tags = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextField(engine.t("journal.titleField"), text: $title).textFieldStyle(.roundedBorder)
                TextField(engine.t("journal.tags"), text: $tags).textFieldStyle(.roundedBorder)
                TextEditor(text: $bodyText).frame(minHeight: 220).scrollContentBackground(.hidden).padding(8).background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16))
                if let prompt = engine.catalog.prompts.first(where: { $0.id == entry.promptID }) {
                    Text(prompt.body.text(engine.languageCode)).font(.system(.footnote, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.7))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .goobyScreen()
            .navigationTitle(engine.t("journal.edit"))
            .toolbar {
                Button(engine.t("common.delete"), role: .destructive) { engine.deleteJournal(entry); dismiss() }
                Button(engine.t("common.save")) {
                    let parsed = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    engine.updateJournal(entry, title: title, body: bodyText, tags: parsed)
                    dismiss()
                }
            }
            .onAppear {
                title = entry.title
                bodyText = entry.body
                tags = entry.tags.joined(separator: ", ")
            }
        }
    }
}

struct FriendsScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("egg.explain")).foregroundStyle(Theme.ink.opacity(0.75))
                ForEach(engine.habits().filter { !$0.isArchived }) { habit in
                    if let egg = engine.activeEgg(for: habit.id) {
                        Text(engine.tf("egg.bound", habit.title, egg.progress, egg.requiredCount)).foregroundStyle(Theme.ink)
                        ProgressRibbon(value: Double(egg.progress) / Double(max(1, egg.requiredCount)))
                    } else {
                        Button(engine.tf("egg.bindTo", habit.title)) { engine.bindEgg(to: habit) }
                            .buttonStyle(.bordered)
                    }
                }
                ForEach(engine.all(MiniFriend.self)) { friend in
                    HStack {
                        MiniFriendBadge(species: friend.speciesID).frame(width: 54, height: 54)
                        VStack(alignment: .leading) {
                            Text(friend.givenName).font(.system(.headline, design: .rounded))
                            Text(engine.t("rarity.\(friend.rarity)"))
                        }
                        Spacer()
                        if friend.isCompanion {
                            Text(engine.t("friends.with"))
                        } else {
                            Button(engine.t("friends.choose")) { engine.setCompanion(friend) }
                        }
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(10)
                    .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                GoobyCharacterView(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), animation: .play, reduceMotion: reduceMotion, companion: engine.companionSpecies())
                    .frame(height: 240)
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("friends.title"))
    }
}

struct QuestScreen: View {
    var engine: GoobyEngine

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("quests.daily")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                questList(engine.all(QuestRecord.self).filter { $0.kind == "daily" && $0.dayKey == engine.dayKey() })
                Text(engine.t("quests.milestones")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                questList(engine.all(QuestRecord.self).filter { $0.kind == "milestone" })
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("quests.title"))
        .onAppear { engine.recomputeQuests(); engine.save() }
    }

    private func questList(_ rows: [QuestRecord]) -> some View {
        ForEach(rows) { quest in
            let template = engine.catalog.questsByID[quest.templateID]
            VStack(alignment: .leading, spacing: 6) {
                Text(template?.title.text(engine.languageCode) ?? quest.templateID).font(.system(.headline, design: .rounded))
                Text(template?.detail.text(engine.languageCode) ?? "").font(.system(.caption, design: .rounded))
                ProgressRibbon(value: Double(quest.progress) / Double(max(1, quest.goal)))
                Text("\(quest.progress)/\(quest.goal)").font(.system(.caption, design: .rounded))
                if quest.claimed {
                    Text(engine.t("quests.claimed"))
                } else if quest.progress >= quest.goal {
                    Button(engine.tf("quests.claim", quest.rewardSparks)) { _ = engine.claimQuest(quest) }
                        .buttonStyle(GoobyButtonStyle(fill: Theme.yellow, ink: Theme.ink))
                }
            }
            .foregroundStyle(Theme.ink)
            .padding(12)
            .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

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

struct StatsScreen: View {
    var engine: GoobyEngine

    var body: some View {
        let runs = engine.all(AdventureRun.self).filter { $0.status == "claimed" }.count
        let completions = engine.all(HabitLog.self).filter { !$0.skipped }.reduce(0) { $0 + $1.count }
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                stat(engine.t("today.streak"), "\(engine.streak())")
                stat(engine.t("stats.completions"), "\(completions)")
                stat(engine.t("stats.adventures"), "\(runs)")
                stat(engine.t("stats.earned"), "\(engine.wallet.lifetimeSparksEarned)")
                stat(engine.t("stats.spent"), "\(engine.wallet.lifetimeSparksSpent)")
                stat(engine.t("journal.title"), "\(engine.all(JournalEntry.self).count)")
                stat(engine.t("friends.title"), "\(engine.all(MiniFriend.self).count)")
                stat(engine.t("stats.places"), "\(engine.all(PlaceProgress.self).filter(\.unlocked).count)")
                stat(engine.t("stats.discoveries"), "\(engine.all(DiscoveryRecord.self).count)")
                stat(engine.t("pet.stage"), engine.t("pet.stage.\(Growth.stage(of: engine.pet))"))
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("stats.title"))
    }

    private func stat(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).font(.system(.headline, design: .rounded))
        }
        .foregroundStyle(Theme.ink)
        .padding(12)
        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
