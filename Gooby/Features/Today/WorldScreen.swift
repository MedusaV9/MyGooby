import SwiftUI

struct WorldScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var selected: PlaceDef?
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(engine.t("world.intro"))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                IllustratedMap(engine: engine) { selected = $0 }
                statusCard
                ForEach(engine.catalog.places) { place in
                    placeCard(place)
                }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("tab.world"))
        .sheet(item: $selected) { place in
            PlaceDetail(engine: engine, place: place, reduceMotion: reduceMotion)
        }
        .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private var statusCard: some View {
        SoftCard(fill: Theme.sky.opacity(0.8)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(engine.t("world.status")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                if let run = engine.todaysRun() {
                    Text(run.status == "claimed" ? engine.t("today.adventure.done") : engine.t("today.adventure.traveling"))
                    if run.status == "ready" || (run.status == "traveling" && engine.now() >= run.returnsAt) {
                        if let story = engine.catalog.storiesByID[run.storyID] {
                            NavigationLink(engine.t("adventure.read")) {
                                StoryReader(engine: engine, run: run, story: story, reduceMotion: reduceMotion)
                            }
                        }
                    } else if run.status == "traveling" {
                        let minutes = max(1, Int(run.returnsAt.timeIntervalSince(engine.now()) / 60))
                        Text(engine.tf("today.adventure.minutes", minutes))
                    }
                } else {
                    Text(engine.wallet.energy >= engine.profile.energyGoal ? engine.t("today.adventure.readyToStart") : engine.tf("today.energy.goal", engine.wallet.energy, engine.profile.energyGoal))
                }
            }
            .foregroundStyle(Theme.ink)
        }
    }

    private func placeCard(_ place: PlaceDef) -> some View {
        let unlocked = engine.isPlaceUnlocked(place.id)
        return Button { selected = place } label: {
            HStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hexString: place.skyTop), Color(hexString: place.skyBottom)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 74, height: 74)
                    .overlay(Image(systemName: unlocked ? "mappin.and.ellipse" : "lock.fill").foregroundStyle(Theme.ink))
                VStack(alignment: .leading) {
                    Text(place.name.text(engine.languageCode)).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                    Text(place.blurb.text(engine.languageCode)).font(.system(.caption, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.7)).lineLimit(2)
                    Text(unlocked ? engine.tf("world.visits", engine.placeProgress(place.id)?.visits ?? 0) : engine.tf("world.locked", place.unlockAfterAdventures))
                        .font(.system(.caption2, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.6))
                }
                Spacer()
            }
            .padding(12)
            .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct IllustratedMap: View {
    var engine: GoobyEngine
    var select: (PlaceDef) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(engine.t("world.map")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
            GeometryReader { geo in
                let spots: [(CGFloat, CGFloat)] = [
                    (0.18, 0.82), (0.42, 0.70), (0.70, 0.78), (0.84, 0.58), (0.62, 0.50),
                    (0.34, 0.46), (0.16, 0.32), (0.40, 0.22), (0.66, 0.18), (0.86, 0.12)
                ]
                ZStack {
                    Path { path in
                        for (index, spot) in spots.enumerated() {
                            let point = CGPoint(x: spot.0 * geo.size.width, y: spot.1 * geo.size.height)
                            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                        }
                    }
                    .stroke(Theme.ink.opacity(0.25), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [6, 6]))
                    ForEach(Array(engine.catalog.places.prefix(spots.count).enumerated()), id: \.element.id) { index, place in
                        let spot = spots[index]
                        Button { select(place) } label: {
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(engine.isPlaceUnlocked(place.id) ? Color(hexString: place.accent) : Theme.ink.opacity(0.15))
                                    .frame(width: 28, height: 28)
                                    .overlay(Image(systemName: engine.isPlaceUnlocked(place.id) ? "pawprint.fill" : "lock.fill").font(.system(size: 11)).foregroundStyle(Theme.ink))
                                Text(place.name.text(engine.languageCode))
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .position(x: spot.0 * geo.size.width, y: spot.1 * geo.size.height)
                    }
                }
            }
            .frame(height: 280)
            .background(
                LinearGradient(colors: [Theme.mint, Theme.sky, Theme.pink.opacity(0.7)], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
        }
    }
}

struct PlaceDetail: View {
    var engine: GoobyEngine
    var place: PlaceDef
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    LinearGradient(colors: [Color(hexString: place.skyTop), Color(hexString: place.skyBottom)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    GoobyCharacterView(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), animation: .depart, reduceMotion: reduceMotion, companion: engine.companionSpecies())
                        .frame(height: 220)
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                Text(place.name.text(engine.languageCode)).font(.system(.largeTitle, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
                Text(place.blurb.text(engine.languageCode)).foregroundStyle(Theme.ink.opacity(0.75))
                Text(engine.tf("world.duration", place.durationMinutes)).foregroundStyle(Theme.ink)
                if engine.isPlaceUnlocked(place.id) {
                    Button(engine.t("adventure.start")) {
                        if let error = engine.startAdventure(placeID: place.id) {
                            message = engine.t(error)
                        } else {
                            dismiss()
                        }
                    }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.rose, ink: Theme.ink))
                } else {
                    Text(engine.tf("world.locked", place.unlockAfterAdventures)).foregroundStyle(Theme.ink)
                }
                Text(engine.t("world.discoveries")).font(.system(.headline, design: .rounded))
                ForEach(place.discoveries) { discovery in
                    let found = engine.all(DiscoveryRecord.self).contains { $0.discoveryID == discovery.id }
                    VStack(alignment: .leading) {
                        Text(found ? discovery.name.text(engine.languageCode) : engine.t("world.unknown")).foregroundStyle(Theme.ink)
                        if found { Text(discovery.detail.text(engine.languageCode)).font(.system(.caption, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.7)) }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(found ? Theme.mint : Theme.lavender.opacity(0.4), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(16)
        }
        .goobyScreen()
        .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: { Text(message ?? "") }
    }
}

struct StoryReader: View {
    var engine: GoobyEngine
    var run: AdventureRun
    var story: StoryDef
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var choice: StoryChoice?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GoobyCharacterView(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), animation: choice == nil ? .think : .celebrate, reduceMotion: reduceMotion, companion: engine.companionSpecies())
                    .frame(height: 220)
                Text(story.title.text(engine.languageCode)).font(.system(.title, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
                Text(story.body.text(engine.languageCode)).foregroundStyle(Theme.ink.opacity(0.8))
                if let choice {
                    SoftCard(fill: Theme.yellow.opacity(0.75)) {
                        Text(choice.outcome.text(engine.languageCode)).foregroundStyle(Theme.ink)
                        Text(engine.tf("adventure.sparks", choice.sparks)).font(.system(.headline, design: .rounded))
                        if !choice.discoveryID.isEmpty, let place = engine.catalog.placesByID[run.placeID], let found = place.discoveries.first(where: { $0.id == choice.discoveryID }) {
                            Text(engine.tf("adventure.found", found.name.text(engine.languageCode)))
                        }
                        personalityHint(choice)
                    }
                    Button(engine.t("common.done")) { dismiss() }.buttonStyle(GoobyButtonStyle())
                } else if run.choiceID.isEmpty && (run.status == "ready" || engine.now() >= run.returnsAt) {
                    ForEach(story.choices) { option in
                        Button(option.text.text(engine.languageCode)) {
                            engine.choose(run: run, choice: option)
                            choice = option
                        }
                        .buttonStyle(GoobyButtonStyle(fill: Theme.pink, ink: Theme.ink))
                    }
                } else if run.choiceID.isEmpty {
                    Text(engine.t("today.adventure.traveling")).foregroundStyle(Theme.ink)
                } else {
                    Text(engine.t("adventure.alreadyChosen")).foregroundStyle(Theme.ink)
                }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode) ?? "")
    }

    private func personalityHint(_ choice: StoryChoice) -> some View {
        let bits = choice.deltas.filter { abs($0.value) > 0.0001 }.map { key, value in
            let sign = value > 0 ? "+" : ""
            return "\(engine.t("stat.\(key)")) \(sign)\(Int((value * 100).rounded()))"
        }
        return Text(bits.joined(separator: "  ")).font(.system(.caption, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.7))
    }
}
