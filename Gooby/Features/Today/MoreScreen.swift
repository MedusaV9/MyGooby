import SwiftUI

struct MoreScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                link(engine.t("tab.shop"), "bag.fill") {
                    if let make = FeatureHost.shared.shopScreen { make(engine) } else { ShopScreen(engine: engine, reduceMotion: reduceMotion) }
                }
                link(engine.t("today.room.edit"), "sofa.fill") {
                    if let room = FeatureHost.shared.roomScreen { room(engine) } else { RoomEditorSheet(engine: engine) }
                }
                link(engine.t("mood.title"), "face.smiling.fill") {
                    if let make = FeatureHost.shared.moodScreen { make(engine) } else { MoodScreen(engine: engine) }
                }
                link(engine.t("journal.title"), "book.fill") {
                    if let make = FeatureHost.shared.journalScreen { make(engine) } else { JournalScreen(engine: engine) }
                }
                link(engine.t("friends.title"), "pawprint.fill") {
                    if let make = FeatureHost.shared.companionsScreen { make(engine) } else { FriendsScreen(engine: engine, reduceMotion: reduceMotion) }
                }
                link(engine.t("quests.title"), "flag.fill") {
                    if let make = FeatureHost.shared.questsScreen { make(engine) } else { QuestScreen(engine: engine) }
                }
                link(engine.t("events.title"), "calendar") {
                    if let make = FeatureHost.shared.eventsScreen { make(engine) } else { EventScreen(engine: engine) }
                }
                link(engine.t("stats.title"), "chart.bar.fill") { StatsScreen(engine: engine) }
                link(engine.t("settings.title"), "gearshape.fill") { SettingsView(engine: engine) }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("tab.more"))
    }

    private func link<Destination: View>(_ title: String, _ symbol: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink { destination() } label: {
            HStack {
                Image(systemName: symbol).frame(width: 36, height: 36).background(Theme.pink, in: Circle())
                Text(title).font(.system(.headline, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(Theme.ink)
            .padding(14)
            .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct MoodComposer: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @State private var level = 3
    @State private var tags: Set<String> = []
    @State private var note = ""
    private let tagIDs = ["happy", "sad", "tired", "stressed", "grateful", "motivated", "overwhelmed", "calm"]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("mood.level.\(level)")).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
                Picker(engine.t("mood.level"), selection: $level) {
                    ForEach(1...5, id: \.self) { Text(engine.t("mood.level.\($0)")).tag($0) }
                }
                .pickerStyle(.segmented)
                ForEach(tagIDs, id: \.self) { tag in
                    Button {
                        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
                    } label: {
                        HStack {
                            Text(engine.t("mood.tag.\(tag)")).foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: tags.contains(tag) ? "checkmark.circle.fill" : "circle")
                        }
                    }
                    .buttonStyle(.plain)
                }
                TextField(engine.t("mood.note"), text: $note, axis: .vertical).textFieldStyle(.roundedBorder)
                Button(engine.t("common.save")) {
                    engine.addMood(level: level, tags: Array(tags), note: note)
                    dismiss()
                }
                .buttonStyle(GoobyButtonStyle())
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .goobyScreen()
            .navigationTitle(engine.t("mood.add"))
            .toolbar { Button(engine.t("common.close")) { dismiss() } }
        }
    }
}

struct MoodScreen: View {
    var engine: GoobyEngine
    @State private var showAdd = false
    @State private var month = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Button(engine.t("mood.add")) { showAdd = true }.buttonStyle(GoobyButtonStyle(fill: Theme.pink, ink: Theme.ink))
                Text(summary(days: 7)).foregroundStyle(Theme.ink)
                Text(summary(days: 30)).foregroundStyle(Theme.ink.opacity(0.75))
                monthGrid
                ForEach(engine.all(MoodEntry.self).sorted { $0.recordedAt > $1.recordedAt }.prefix(30), id: \.id) { entry in
                    VStack(alignment: .leading) {
                        Text(engine.t("mood.level.\(entry.level)")).font(.system(.headline, design: .rounded))
                        Text(entry.tags.map { engine.t("mood.tag.\($0)") }.joined(separator: ", "))
                        if !entry.note.isEmpty { Text(entry.note) }
                        Text(engine.formatDate(entry.recordedAt, time: true)).font(.system(.caption, design: .rounded))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contextMenu {
                        Button(engine.t("common.delete"), role: .destructive) { engine.deleteMood(entry) }
                    }
                }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("mood.title"))
        .sheet(isPresented: $showAdd) { MoodComposer(engine: engine) }
    }

    private func summary(days: Int) -> String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: engine.now()) ?? engine.now()
        let rows = engine.all(MoodEntry.self).filter { $0.recordedAt >= cutoff }
        guard !rows.isEmpty else { return engine.tf(days == 7 ? "mood.week.empty" : "mood.month.empty", days) }
        let average = Double(rows.map(\.level).reduce(0, +)) / Double(rows.count)
        let counts = Dictionary(grouping: rows.flatMap(\.tags), by: { $0 }).mapValues(\.count)
        let top = counts.max { $0.value < $1.value }?.key
        let tone = average >= 4 ? engine.t("mood.tone.bright") : (average >= 3 ? engine.t("mood.tone.steady") : engine.t("mood.tone.tender"))
        let tag = top.map { engine.t("mood.tag.\($0)") } ?? engine.t("common.none")
        return engine.tf(days == 7 ? "mood.week" : "mood.month", tone, tag, average)
    }

    private var monthGrid: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<29
        let map = Dictionary(grouping: engine.all(MoodEntry.self), by: \.dayKey)
        return VStack(alignment: .leading) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                Text(monthTitle).foregroundStyle(Theme.ink)
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(range, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
                    let key = DayKey.make(date)
                    let level = map[key]?.map(\.level).max()
                    Text("\(day)")
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(levelColor(level), in: Circle())
                        .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: month)
    }

    private func shift(_ value: Int) {
        month = Calendar.current.date(byAdding: .month, value: value, to: month) ?? month
    }

    private func levelColor(_ level: Int?) -> Color {
        switch level {
        case 1: return Theme.lavender
        case 2: return Theme.sky
        case 3: return Theme.cream
        case 4: return Theme.mint
        case 5: return Theme.yellow
        default: return Color.clear
        }
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
