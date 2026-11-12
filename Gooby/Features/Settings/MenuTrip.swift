import SwiftUI

/// One existing adventure place for each self-care area. The day's outing still
/// starts through `startAdventure`. This walk has no clock of its own.
@MainActor
enum MenuTripMap {
    static let placeID: [String: String] = [
        "productivity": "garden",
        "gratitude": "meadow",
        "kindness": "sugar",
        "calm": "crystal",
        "sleep": "moon",
        "hygiene": "beach",
        "movement": "clouds",
        "nutrition": "cherry",
        "connection": "starwood",
        "tidy": "snow"
    ]

    static func place(_ engine: GoobyEngine, areaID: String) -> PlaceDef? {
        guard let id = placeID[areaID] else { return nil }
        return engine.catalog.placesByID[id]
    }

    /// First catalog story for the place. The real outing still picks its own story.
    static func story(_ engine: GoobyEngine, placeID: String) -> StoryDef? {
        engine.catalog.stories.first { $0.placeID == placeID }
    }
}

struct MenuTripList: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    private struct TripStop: Identifiable {
        var area: GoalArea
        var place: PlaceDef
        var id: String { area.id }
    }

    private var rows: [TripStop] {
        GoalCatalog.areas.compactMap { area in
            guard let place = MenuTripMap.place(engine, areaID: area.id) else { return nil }
            return TripStop(area: area, place: place)
        }
    }

    private var runningName: String? {
        _ = engine.animation
        guard let run = engine.todaysRun() else { return nil }
        return engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode)
    }

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.travel"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.t("menu.trip.lead"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                    .fixedSize(horizontal: false, vertical: true)
                Text(AdventureText.line(engine, "adventure.energy", [
                    "have": "\(engine.wallet.energy)",
                    "need": "\(max(1, engine.profile.energyGoal))"
                ]))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Look.ink)
                if let runningName {
                    Text(engine.tf("menu.trip.out", runningName))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.row)
                        .fixedSize(horizontal: false, vertical: true)
                    adventureLink
                }
                LookCard {
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            NavigationLink {
                                MenuTripWalk(
                                    engine: engine,
                                    reduceMotion: reduceMotion,
                                    area: row.area,
                                    place: row.place
                                )
                            } label: {
                                tripRow(row.area, row.place)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("menu-trip-\(row.area.id)")
                            if index < rows.count - 1 { LookDivider() }
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("menu-trip-list")
        .onAppear { engine.syncRuns() }
    }

    private func tripRow(_ area: GoalArea, _ place: PlaceDef) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: area.tint))
                .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(area.name(engine.languageCode))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Look.row)
                Text(place.name.text(engine.languageCode))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.sub)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Look.chevron)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: Look.rowHeight, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var adventureLink: some View {
        NavigationLink {
            AdventureScreen(engine: engine, reduceMotion: reduceMotion)
        } label: {
            Text(engine.t("menu.trip.see"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Look.plus, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("menu-trip-see")
    }
}

struct MenuTripWalk: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var area: GoalArea
    var place: PlaceDef
    @State private var step = 0
    @State private var picked = ""
    @State private var notice: String?

    private var story: StoryDef? { MenuTripMap.story(engine, placeID: place.id) }
    private var total: Int { 3 }

    private var runningName: String? {
        _ = engine.animation
        guard let run = engine.todaysRun() else { return nil }
        return engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode)
    }

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(area.name(engine.languageCode))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.tf("menu.trip.step", step + 1, total))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Look.section)
                AdventurePlaceArt(place: place)
                    .frame(height: 148)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityHidden(true)
                stepBody
                if step < total - 1 {
                    Button(engine.t("menu.trip.next")) { step += 1 }
                        .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                        .accessibilityIdentifier("menu-trip-next")
                } else {
                    Text(engine.t("menu.trip.note"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.row)
                        .fixedSize(horizontal: false, vertical: true)
                    depart
                }
            }
        }
        .accessibilityIdentifier("menu-trip-walk-\(area.id)")
    }

    @ViewBuilder private var stepBody: some View {
        switch step {
        case 0:
            Text(engine.t("menu.trip.arrive"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Look.ink)
            Text(area.blurb(engine.languageCode))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Look.row)
                .fixedSize(horizontal: false, vertical: true)
            Text(place.name.text(engine.languageCode))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Look.ink)
            Text(place.blurb.text(engine.languageCode))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Look.row)
                .fixedSize(horizontal: false, vertical: true)
        case 1:
            Text(engine.t("menu.trip.listen"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Look.ink)
            if let story {
                Text(story.title.text(engine.languageCode))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(story.body.text(engine.languageCode))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(engine.t("menu.trip.empty"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
            }
        default:
            Text(engine.t("menu.trip.answer"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Look.ink)
            Text(engine.t("menu.trip.choices"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Look.row)
                .fixedSize(horizontal: false, vertical: true)
            if let story {
                ForEach(story.choices) { choice in
                    Button {
                        picked = choice.id
                    } label: {
                        HStack {
                            Text(choice.text.text(engine.languageCode))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Look.ink)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            if picked == choice.id {
                                Text(engine.t("menu.trip.picked"))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Look.ink)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            picked == choice.id ? Color(hex: area.tint).opacity(0.55) : Look.card,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .shadow(color: Look.shadow, radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("menu-trip-choice-\(choice.id)")
                }
            } else {
                Text(engine.t("menu.trip.empty"))
                    .foregroundStyle(Look.row)
            }
        }
    }

    @ViewBuilder private var depart: some View {
        Text(AdventureText.line(engine, "adventure.energy", [
            "have": "\(engine.wallet.energy)",
            "need": "\(max(1, engine.profile.energyGoal))"
        ]))
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundStyle(Look.ink)
        if let runningName {
            Text(engine.tf("menu.trip.out", runningName))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Look.row)
                .fixedSize(horizontal: false, vertical: true)
            seeAdventure
        } else if let notice {
            Text(notice)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Look.ink)
                .fixedSize(horizontal: false, vertical: true)
            if notice == engine.t("adventure.started") { seeAdventure }
        } else if !engine.isPlaceUnlocked(place.id) {
            Text(AdventureText.lockedLine(engine, place))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Look.row)
                .fixedSize(horizontal: false, vertical: true)
        } else if engine.wallet.energy < engine.profile.energyGoal {
            Text(engine.t("adventure.needEnergy"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Look.row)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Button(engine.t("adventure.start.trip"), action: start)
                .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                .accessibilityIdentifier("menu-trip-start")
        }
    }

    private var seeAdventure: some View {
        NavigationLink {
            AdventureScreen(engine: engine, reduceMotion: reduceMotion)
        } label: {
            Text(engine.t("menu.trip.see"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Look.widget, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func start() {
        if let error = engine.startAdventure(placeID: place.id) {
            notice = engine.t(error)
            return
        }
        notice = engine.t("adventure.started")
        engine.haptics.soft()
    }
}
