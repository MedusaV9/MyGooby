import SwiftUI

struct AdventureReturn: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var choose: (StoryChoice) -> Void

    var body: some View {
        let name = AdventureText.petName(engine)
        let place = currentPlace
        VStack(alignment: .leading, spacing: 14) {
            Text(AdventureText.line(engine, "adventure.return", ["name": name]))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
            if let place {
                Text(AdventureText.line(engine, "adventure.return.lead", ["place": place.name.text(engine.languageCode)]))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                AdventureLocationCard(
                    engine: engine,
                    place: place,
                    reduceMotion: reduceMotion,
                    showsRabbit: true,
                    rabbit: .arrive
                )
            }
            story
        }
    }

    @ViewBuilder private var story: some View {
        if let run = engine.todaysRun(), let tale = engine.catalog.storiesByID[run.storyID] {
            Text(tale.title.text(engine.languageCode))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
            Text(tale.body.text(engine.languageCode))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            if run.choiceID.isEmpty {
                Text(engine.t("adventure.choose"))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.ink)
                if tale.choices.isEmpty {
                    Text(engine.t("adventure.noChoice"))
                        .foregroundStyle(Theme.ink.opacity(0.7))
                } else {
                    ForEach(tale.choices) { option in
                        Button {
                            choose(option)
                        } label: {
                            Text(option.text.text(engine.languageCode))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .buttonStyle(GoobyButtonStyle(fill: Theme.pink, ink: Theme.ink))
                    }
                }
            } else {
                Text(engine.t("adventure.alreadyChosen"))
                    .foregroundStyle(Theme.ink.opacity(0.75))
            }
        } else {
            Text(engine.t("adventure.noChoice"))
                .foregroundStyle(Theme.ink.opacity(0.75))
        }
    }

    private var currentPlace: PlaceDef? {
        guard let id = engine.todaysRun()?.placeID else { return nil }
        return engine.catalog.placesByID[id]
    }
}

struct AdventureHome: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        let name = AdventureText.petName(engine)
        let place = currentPlace
        let placeName = place?.name.text(engine.languageCode) ?? ""
        VStack(alignment: .leading, spacing: 14) {
            Text(AdventureText.line(engine, "adventure.home.title", ["name": name]))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
            if !placeName.isEmpty {
                Text(AdventureText.line(engine, "adventure.home.detail", ["place": placeName]))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.75))
            }
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: reduceMotion ? .idle : .celebrate,
                reduceMotion: reduceMotion,
                companion: nil,
                showCompanion: false
            )
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(name)
            if let place {
                AdventureLocationCard(engine: engine, place: place, reduceMotion: reduceMotion)
            }
            ending
        }
    }

    @ViewBuilder private var ending: some View {
        if let run = engine.todaysRun(),
           let tale = engine.catalog.storiesByID[run.storyID],
           let choice = tale.choices.first(where: { $0.id == run.choiceID }) {
            Text(choice.outcome.text(engine.languageCode))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if run.rewardSparks > 0 {
                Text(AdventureText.line(engine, "adventure.brought", ["count": "\(run.rewardSparks)"]))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }
            if !choice.discoveryID.isEmpty,
               let place = currentPlace,
               let found = place.discoveries.first(where: { $0.id == choice.discoveryID }) {
                Text(AdventureText.line(engine, "adventure.found.line", ["name": found.name.text(engine.languageCode)]))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.8))
            }
            let traits = traitLine(choice)
            if !traits.isEmpty {
                Text(traits)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
            }
        }
    }

    private var currentPlace: PlaceDef? {
        guard let id = engine.todaysRun()?.placeID else { return nil }
        return engine.catalog.placesByID[id]
    }

    private func traitLine(_ choice: StoryChoice) -> String {
        choice.deltas.keys.sorted().compactMap { key in
            let value = choice.deltas[key] ?? 0
            guard abs(value) > 0.0001 else { return nil }
            let sign = value > 0 ? "+" : ""
            return "\(engine.t("stat.\(key)")) \(sign)\(Int((value * 100).rounded()))"
        }
        .joined(separator: "  ")
    }
}
