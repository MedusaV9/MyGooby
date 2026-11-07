import SwiftUI

struct DevMenuView: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @State private var sparksText = "50"
    @State private var customDate = Date()
    @State private var eventID = ""
    @State private var storyID = ""
    @State private var message: String?
    @State private var reset1 = false
    @State private var reset2 = false
    @State private var pendingReset: String?

    var body: some View {
        NavigationStack {
            MenuScroll {
                section("dev.time", icon: "⏰") { timeTools }
                section("dev.currency", icon: "✨") { currencyTools }
                section("dev.gooby", icon: "🐰") { goobyTools }
                section("dev.inventory", icon: "🎒") { inventoryTools }
                section("dev.adventure", icon: "🗺️") { adventureTools }
                section("dev.events", icon: "🎉") { eventTools }
                section("dev.quests", icon: "📘") { questTools }
                section("dev.diagnostics", icon: "🩺") { diagnosticTools }
                section("dev.reset", icon: "🗑️") { resetTools }
                ForEach(Array(FeatureHost.shared.devSections.enumerated()), id: \.offset) { _, pair in
                    section(pair.0, icon: "🧩") { pair.1(engine) }
                }
            }
            .menuChrome(engine, title: engine.t("dev.title"), close: true)
            .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button(engine.t("common.ok"), role: .cancel) {}
            } message: { Text(message.map { engine.t($0) } ?? "") }
            .alert(engine.t("reset.title"), isPresented: $reset1) {
                Button(engine.t("common.cancel"), role: .cancel) {}
                Button(engine.t("reset.continue"), role: .destructive) { reset2 = true }
            } message: { Text(engine.t("reset.msg1")) }
            .alert(engine.t("reset.final"), isPresented: $reset2) {
                Button(engine.t("common.cancel"), role: .cancel) {}
                Button(engine.t("reset.do"), role: .destructive) { engine.resetAll() }
            } message: { Text(engine.t("reset.msg2")) }
            .confirmationDialog(engine.t("dev.resetOne"), isPresented: Binding(get: { pendingReset != nil }, set: { if !$0 { pendingReset = nil } })) {
                Button(engine.t("reset.do"), role: .destructive) { runPartial() }
                Button(engine.t("common.cancel"), role: .cancel) { pendingReset = nil }
            }
        }
    }

    /// Caps header over a white card, like the settings groups.
    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                GoobyIcon(icon, size: 18)
                SectionCaps(engine.t(title))
            }
            .padding(.top, 8)
            GCard {
                VStack(alignment: .leading, spacing: 10) {
                    content()
                }
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.text)
                .tint(Theme.Tab.menu.banner)
            }
        }
    }

    private var timeTools: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(engine.tf("dev.clock", engine.formatDate(engine.now(), time: true), engine.formatDate(Date(), time: true)))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.greyText)
            HStack {
                small(engine.t("dev.today")) { engine.clearOffset() }
                small(engine.t("dev.tomorrow")) { engine.shiftDays(1) }
                small(engine.t("dev.nextWeek")) { engine.shiftDays(7) }
            }
            small(engine.t("dev.nextMonth")) { engine.shiftMonths(1) }
            DatePicker(engine.t("dev.customDate"), selection: $customDate, displayedComponents: .date)
            small(engine.t("dev.applyDate")) {
                let calendar = Calendar.current
                let time = calendar.dateComponents([.hour, .minute, .second], from: Date())
                var parts = calendar.dateComponents([.year, .month, .day], from: customDate)
                parts.hour = time.hour
                parts.minute = time.minute
                parts.second = time.second
                engine.setOffset(to: calendar.date(from: parts) ?? customDate)
            }
        }
    }

    private var currencyTools: some View {
        VStack(alignment: .leading) {
            HStack {
                small("100") { engine.setSparks(100) }
                small("1.000") { engine.setSparks(1000) }
                small("10.000") { engine.setSparks(10000) }
            }
            TextField(engine.t("dev.customSparks"), text: $sparksText)
                .keyboardType(.numberPad)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.keyFace, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            small(engine.t("dev.applySparks")) { engine.setSparks(Int(sparksText) ?? 0) }
            small(engine.t("dev.resetSparks")) { engine.setSparks(0) }
            small(engine.t("dev.testReward")) { engine.testReward(sparks: 25) }
        }
    }

    private var goobyTools: some View {
        VStack(alignment: .leading, spacing: 8) {
            GoobyCharacterView(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), animation: engine.animation, reduceMotion: false, companion: engine.companionSpecies())
                .frame(height: 180)
            ScrollView(.horizontal) {
                HStack {
                    ForEach(Growth.order, id: \.self) { stage in
                        small(engine.t("pet.stage.\(stage)")) { engine.setStage(stage) }
                    }
                    small(engine.t("dev.autoStage")) { engine.setStage("") }
                }
            }
            ForEach(Personality.keys, id: \.self) { key in
                HStack {
                    Text(engine.t("stat.\(key)")).font(Theme.Fonts.caption).frame(width: 110, alignment: .leading)
                    Slider(value: Binding(get: { Personality.value(engine.pet, key) }, set: { engine.setPersonality(key, $0) }), in: 0...1)
                }
            }
            ScrollView(.horizontal) {
                HStack {
                    ForEach(GoobyAnimation.allCases) { animation in
                        small(engine.t("anim.\(animation.rawValue)")) { engine.animation = animation }
                    }
                }
            }
            ScrollView(.horizontal) {
                HStack {
                    ForEach(engine.catalog.items.filter { $0.kind == "color" }) { item in
                        small(item.name.text(engine.languageCode)) { engine.pet.furStyle = item.id; engine.save() }
                    }
                }
            }
            small(engine.t("dev.grow")) { engine.simulateGrowth() }
        }
    }

    private var inventoryTools: some View {
        VStack(alignment: .leading) {
            small(engine.t("dev.unlockItems")) { engine.unlockAllItems() }
            small(engine.t("dev.unlockFriends")) { engine.unlockAllFriends() }
            small(engine.t("dev.resetInventory")) { pendingReset = "inventory" }
        }
    }

    private var adventureTools: some View {
        VStack(alignment: .leading) {
            small(engine.t("dev.finishAdventure")) {
                if let error = engine.completeAdventureNow() { message = error }
            }
            small(engine.t("dev.fillEnergy")) { engine.fillEnergy() }
            small(engine.t("dev.unlockPlaces")) { engine.unlockAllPlaces() }
            small(engine.t("dev.resetAdventures")) { pendingReset = "adventures" }
            if storyID.isEmpty, let first = engine.catalog.stories.first { Text("").onAppear { storyID = first.id } }
            Picker(engine.t("dev.stories"), selection: $storyID) {
                ForEach(engine.catalog.stories) { story in
                    Text(story.title.text(engine.languageCode)).tag(story.id)
                }
            }
            if let story = engine.catalog.storiesByID[storyID] {
                Text(story.body.text(engine.languageCode)).font(.system(.caption, design: .rounded))
                ForEach(story.choices) { choice in
                    Button {
                        engine.applyStoryTest(story, choice)
                    } label: {
                        Text(choice.text.text(engine.languageCode))
                            .font(Theme.Fonts.caption)
                            .multilineTextAlignment(.leading)
                    }
                    .menuKeyButton()
                }
            }
        }
    }

    private var eventTools: some View {
        VStack(alignment: .leading) {
            if eventID.isEmpty, let first = engine.catalog.events.first {
                Text("").onAppear { eventID = first.id }
            }
            Picker(engine.t("events.title"), selection: $eventID) {
                ForEach(engine.catalog.events) { event in
                    Text(event.title.text(engine.languageCode)).tag(event.id)
                }
            }
            small(engine.t("dev.eventStart")) { engine.forceEvent(eventID, on: true) }
            small(engine.t("dev.eventStop")) { engine.forceEvent(eventID, on: false) }
            if let event = engine.catalog.events.first(where: { $0.id == eventID }) {
                ForEach(event.tasks) { task in
                    HStack {
                        Text(task.title.text(engine.languageCode))
                        Spacer()
                        small("+") { engine.bumpEvent(event.id, taskID: task.id, by: 1) }
                    }
                }
                small(engine.t("dev.eventRewards")) { engine.freeEventRewards(event) }
            }
            small(engine.t("dev.resetEvents")) { pendingReset = "events" }
            Text(engine.t("dev.calendar")).font(Theme.Fonts.headline)
            ForEach(engine.catalog.events) { event in
                Text("\(event.title.text(engine.languageCode)): \(engine.isEventActive(event.id) ? engine.t("events.active") : engine.t("events.upcoming"))")
                    .font(.system(.caption, design: .rounded))
            }
        }
    }

    private var questTools: some View {
        VStack(alignment: .leading) {
            small(engine.t("dev.newQuests")) { engine.regenerateDailyQuests() }
            small(engine.t("dev.resetQuests")) { pendingReset = "quests" }
            ForEach(engine.all(QuestRecord.self).filter { !$0.claimed }) { quest in
                Button {
                    engine.completeQuestNow(quest)
                } label: {
                    Text(engine.catalog.questsByID[quest.templateID]?.title.text(engine.languageCode) ?? quest.templateID)
                        .font(Theme.Fonts.caption)
                        .multilineTextAlignment(.leading)
                }
                .menuKeyButton()
            }
        }
    }

    private var diagnosticTools: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(engine.diagnostics())
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.text)
                .textSelection(.enabled)
            ShareLink(item: engine.diagnostics()) {
                Text(engine.t("dev.exportDiag"))
                    .font(Theme.Fonts.caption)
            }
            .menuKeyButton()
        }
    }

    private var resetTools: some View {
        VStack(alignment: .leading) {
            small(engine.t("dev.resetHabits")) { pendingReset = "habits" }
            small(engine.t("dev.resetMood")) { pendingReset = "mood" }
            small(engine.t("dev.resetAll")) { reset1 = true }
        }
    }

    private func runPartial() {
        switch pendingReset {
        case "inventory": engine.resetInventory()
        case "adventures": engine.resetAdventures()
        case "events": engine.resetEventProgress(eventID); engine.resetEvents()
        case "quests": engine.resetQuests()
        case "habits": engine.resetHabits()
        case "mood": engine.resetMoodJournal()
        default: break
        }
        pendingReset = nil
    }

    private func small(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.caption)
                .lineLimit(1)
        }
        .menuKeyButton()
    }
}
