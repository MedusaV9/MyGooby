import SwiftUI

private enum AdventureBeat {
    case deck, timer, place, returning, home
}

/// Start a trip, show the place, then come home. The rabbit is the drawn cream Gooby.
struct AdventureScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var beat: AdventureBeat = .deck
    @State private var selectedID: String?
    @State private var notice: String?
    @State private var choosing = false

    private var calm: Bool { reduceMotion || systemReduce }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button(engine.t("adventure.back")) { dismiss() }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .accessibilityIdentifier("adventure-back")
                content
            }
            .padding(16)
            .padding(.bottom, 12)
        }
        .goobyScreen()
        .navigationTitle(engine.t("adventure.title"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("adventure-screen")
        .onAppear(perform: prepare)
        .task(id: beat) { await watch() }
    }

    @ViewBuilder private var content: some View {
        switch beat {
        case .deck:
            deck
        case .timer:
            AdventureTimer(engine: engine, reduceMotion: calm, showPlace: { beat = .place }, comeHome: comeHome)
        case .place:
            place
        case .returning:
            AdventureReturn(engine: engine, reduceMotion: calm, choose: pick)
        case .home:
            AdventureHome(engine: engine, reduceMotion: calm)
        }
    }

    private var deck: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(engine.t("adventure.title"))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: .curious,
                reduceMotion: calm,
                companion: nil,
                showCompanion: false
            )
            .frame(height: 190)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(AdventureText.petName(engine))
            Text(AdventureText.line(engine, "adventure.pick", ["name": AdventureText.petName(engine)]))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.75))
            Text(AdventureText.line(engine, "adventure.energy", [
                "have": "\(engine.wallet.energy)",
                "need": "\(max(1, engine.profile.energyGoal))"
            ]))
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(Theme.ink)
            if engine.catalog.places.isEmpty {
                Text(engine.t("adventure.empty"))
                    .foregroundStyle(Theme.ink.opacity(0.7))
            } else {
                ForEach(engine.catalog.places) { place in
                    AdventureLocationCard(
                        engine: engine,
                        place: place,
                        reduceMotion: calm,
                        selected: place.id == selectedPlace?.id,
                        tap: { selectedID = place.id }
                    )
                }
            }
            Button(engine.t("adventure.start.trip"), action: startTrip)
                .buttonStyle(GoobyButtonStyle(fill: Theme.rose, ink: Theme.ink))
                .accessibilityIdentifier("adventure-start-trip")
            if let notice {
                Text(notice)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.rose)
            }
        }
    }

    private var place: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let spot = tripPlace {
                Text(AdventureText.line(engine, "adventure.at", [
                    "name": AdventureText.petName(engine),
                    "place": spot.name.text(engine.languageCode)
                ]))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
                AdventureLocationCard(
                    engine: engine,
                    place: spot,
                    reduceMotion: calm,
                    showsRabbit: true,
                    rabbit: .curious
                )
            } else {
                Text(engine.t("adventure.empty"))
                    .foregroundStyle(Theme.ink)
            }
            Button(engine.t("adventure.comeHome"), action: comeHome)
                .buttonStyle(GoobyButtonStyle(fill: Theme.rose, ink: Theme.ink))
                .accessibilityIdentifier("adventure-come-home")
            Button(engine.t("adventure.clock")) { beat = .timer }
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
        }
    }

    private var selectedPlace: PlaceDef? {
        if let selectedID, let place = engine.catalog.placesByID[selectedID] { return place }
        return engine.catalog.places.first { engine.isPlaceUnlocked($0.id) } ?? engine.catalog.places.first
    }

    private var tripPlace: PlaceDef? {
        if let id = engine.todaysRun()?.placeID, let place = engine.catalog.placesByID[id] { return place }
        return selectedPlace
    }

    private func prepare() {
        engine.syncRuns()
        if selectedID == nil {
            selectedID = engine.todaysRun()?.placeID ?? engine.catalog.places.first { engine.isPlaceUnlocked($0.id) }?.id
        }
        if beat == .deck, let run = engine.todaysRun() { open(run) }
    }

    private func open(_ run: AdventureRun) {
        switch run.status {
        case "claimed": beat = .home
        case "ready": beat = .returning
        default: beat = .timer
        }
    }

    private func startTrip() {
        guard let place = selectedPlace else {
            notice = engine.t("adventure.empty")
            return
        }
        guard engine.isPlaceUnlocked(place.id) else {
            notice = AdventureText.lockedLine(engine, place)
            return
        }
        if let run = engine.todaysRun() {
            notice = nil
            open(run)
            return
        }
        if let error = depart(place.id) {
            notice = engine.t(error)
            return
        }
        notice = nil
        beat = .timer
        engine.haptics.soft()
    }

    /// The day's energy is the only gate this screen cannot earn by itself.
    private func depart(_ placeID: String) -> String? {
        if let error = engine.startAdventure(placeID: placeID) {
            guard error == "adventure.needEnergy" else { return error }
            engine.fillEnergy()
            return engine.startAdventure(placeID: placeID)
        }
        return nil
    }

    private func comeHome() {
        engine.syncRuns()
        guard let run = engine.todaysRun() else { return }
        if run.status == "claimed" {
            beat = .home
            return
        }
        if run.status == "traveling" {
            markReady(run)
        }
        beat = .returning
        engine.haptics.soft()
    }

    /// Today's outing comes home from this screen, even while the clock is still running.
    private func markReady(_ run: AdventureRun) {
        _ = engine.completeAdventureNow()
        if run.status == "traveling" {
            run.returnsAt = engine.now()
            run.status = "ready"
            engine.leaveReturnPostcard(for: run)
            engine.animation = .arrive
            engine.save()
        }
        engine.rescheduleNotifications()
    }

    private func pick(_ choice: StoryChoice) {
        guard !choosing, let run = engine.todaysRun() else { return }
        choosing = true
        if run.status == "traveling" { markReady(run) }
        engine.choose(run: run, choice: choice)
        guard run.status == "claimed" else {
            choosing = false
            return
        }
        beat = .home
        engine.haptics.celebrate()
    }

    private func watch() async {
        guard beat == .timer || beat == .place else { return }
        while !Task.isCancelled {
            engine.syncRuns()
            if engine.todaysRun()?.status == "ready" {
                engine.save()
                beat = .returning
                return
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
