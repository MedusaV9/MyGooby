#if canImport(SwiftUI)
import SwiftUI

struct GoobyEventsHubView: View {
    var languageCode: String
    var now: Date
    var habits: [GoobyHabitLink]
    var calendar: Calendar
    var onRewards: ([GoobyRewardGrant]) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab = GoobyEventsTab.events
    @State private var banner: String?
    @State private var revision = 0
    @State private var didRefresh = false

    var body: some View {
        let _ = revision
        let language = GoobyEventsLanguage.resolve(languageCode)
        let libraries = GoobyEventsLibraries.current
        let model = GoobyEventsIntegration.screen(languageCode: languageCode, now: now, calendar: calendar)
        ZStack {
            LinearGradient(
                colors: [GoobyEventsPalette.cream, GoobyEventsPalette.blush.opacity(0.55), GoobyEventsPalette.sky.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(libraries.text("hub.title", language: language))
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(GoobyEventsPalette.ink)
                    Text(libraries.text("hub.subtitle", language: language))
                        .font(.subheadline)
                        .foregroundStyle(GoobyEventsPalette.ink.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let banner {
                    Text(banner)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GoobyEventsPalette.ink)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(GoobyEventsPalette.butter)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
                tabBar(language: language, libraries: libraries)
                ScrollView {
                    Group {
                        switch tab {
                        case .events:
                            GoobyEventBoard(
                                model: model,
                                libraries: libraries,
                                now: now,
                                calendar: calendar,
                                onGrants: { show($0, language: language, libraries: libraries) }
                            )
                        case .quests:
                            GoobyQuestBoard(model: model, libraries: libraries)
                        case .nest:
                            GoobyNestBoard(
                                model: model,
                                libraries: libraries,
                                habits: habits,
                                now: now,
                                calendar: calendar,
                                onGrants: { show($0, language: language, libraries: libraries) }
                            )
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            if let hatch = model.pendingHatches.first {
                GoobyHatchCelebration(
                    companion: hatch,
                    libraries: libraries,
                    language: language,
                    reduceMotion: reduceMotion
                ) {
                    GoobyEventsIntegration.dismissHatch(id: hatch.id)
                }
            }
        }
        .onAppear {
            guard !didRefresh else { return }
            didRefresh = true
            let grants = GoobyEventsIntegration.refresh(now: now, calendar: calendar)
            show(grants, language: language, libraries: GoobyEventsLibraries.current)
        }
        .onReceive(NotificationCenter.default.publisher(for: .goobyEventsDidChange)) { _ in
            revision += 1
        }
        .sensoryFeedback(.success, trigger: banner)
    }

    private func tabBar(language: GoobyEventsLanguage, libraries: GoobyEventsLibraries) -> some View {
        HStack(spacing: 8) {
            tabButton(.events, libraries.text("hub.events", language: language))
            tabButton(.quests, libraries.text("hub.quests", language: language))
            tabButton(.nest, libraries.text("hub.nest", language: language))
        }
        .padding(4)
        .background(Color.white.opacity(0.55))
        .clipShape(Capsule())
    }

    private func tabButton(_ value: GoobyEventsTab, _ title: String) -> some View {
        Button {
            tab = value
        } label: {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(GoobyEventsPalette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(tab == value ? Color.white : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(GoobySquishButtonStyle())
    }

    private func show(_ grants: [GoobyRewardGrant], language: GoobyEventsLanguage, libraries: GoobyEventsLibraries) {
        let meaningful = grants.filter { $0.starSparks > 0 || $0.companionSpeciesID != nil }
        guard !meaningful.isEmpty else {
            return
        }
        onRewards(meaningful)
        banner = GoobyEventsPresenter.banner(grants: meaningful, language: language, libraries: libraries)
    }
}

private enum GoobyEventsTab {
    case events
    case quests
    case nest
}

struct GoobyEventBoard: View {
    var model: GoobyEventsScreenModel
    var libraries: GoobyEventsLibraries
    var now: Date
    var calendar: Calendar
    var onGrants: ([GoobyRewardGrant]) -> Void

    @State private var openEventID: String?

    private var featured: [GoobyEventSnapshot] {
        model.events.filter { $0.phase == "active" || $0.forced }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if featured.isEmpty {
                Text(libraries.text("events.quiet", language: model.language))
                    .font(.body)
                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.8))
                    .goobyCard(fill: Color.white.opacity(0.9))
            }
            ForEach(featured) { event in
                eventCard(event, emphasized: true)
                    .onAppear {
                        let grants = GoobyEventsIntegration.record(
                            .eventVisited(eventID: event.id),
                            now: now,
                            calendar: calendar
                        )
                        onGrants(grants)
                    }
            }
            VStack(alignment: .leading, spacing: 12) {
                Text(libraries.text("events.calendar", language: model.language))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(GoobyEventsPalette.ink)
                ForEach(model.events) { event in
                    Button {
                        openEventID = event.id
                        let grants = GoobyEventsIntegration.record(
                            .eventVisited(eventID: event.id),
                            now: now,
                            calendar: calendar
                        )
                        onGrants(grants)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: event.symbolName)
                                .font(.title3)
                                .foregroundStyle(GoobyEventsPalette.ink)
                                .frame(width: 42, height: 42)
                                .background(GoobyEventsPalette.color(hex: event.accentHex))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.name)
                                    .font(.headline)
                                    .foregroundStyle(GoobyEventsPalette.ink)
                                Text(event.dateText)
                                    .font(.caption)
                                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.68))
                            }
                            Spacer(minLength: 8)
                            Text(event.phase == "active" ? libraries.text("events.now", language: model.language) : libraries.text("events.next", language: model.language))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(GoobyEventsPalette.ink)
                        }
                    }
                    .buttonStyle(GoobySquishButtonStyle())
                    if openEventID == event.id {
                        eventCard(event, emphasized: false)
                    }
                }
            }
            .goobyCard(fill: Color.white.opacity(0.9))
        }
    }

    private func eventCard(_ event: GoobyEventSnapshot, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: event.symbolName)
                    .font(.title2)
                    .foregroundStyle(GoobyEventsPalette.ink)
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(emphasized ? .title2.weight(.bold) : .headline)
                        .foregroundStyle(GoobyEventsPalette.ink)
                    Text(event.dateText)
                        .font(.subheadline)
                        .foregroundStyle(GoobyEventsPalette.ink.opacity(0.7))
                    if event.forced {
                        Text(libraries.text("events.forced", language: model.language))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(GoobyEventsPalette.ink)
                    }
                }
                Spacer(minLength: 0)
            }
            Text(event.summary)
                .font(.body)
                .foregroundStyle(GoobyEventsPalette.ink.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
            Text(libraries.text("events.objectives", language: model.language))
                .font(.headline)
                .foregroundStyle(GoobyEventsPalette.ink)
            ForEach(event.objectives) { objective in
                VStack(alignment: .leading, spacing: 4) {
                    Text(objective.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GoobyEventsPalette.ink)
                    GoobyProgressBar(value: objective.current, total: objective.target, tint: GoobyEventsPalette.ink.opacity(0.75))
                    Text(libraries.format("progress.of", language: model.language, tokens: [
                        "current": "\(objective.current)",
                        "target": "\(objective.target)"
                    ]))
                    .font(.caption)
                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.65))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(libraries.text("events.reward", language: model.language))
                    .font(.headline)
                    .foregroundStyle(GoobyEventsPalette.ink)
                Text(libraries.format("banner.sparks", language: model.language, tokens: ["count": "\(event.rewardSparks)"]))
                Text("\(libraries.text("events.cosmetic", language: model.language)): \(event.cosmeticID)")
                    .font(.footnote)
                if let friend = event.bonusSpeciesName {
                    Text("\(libraries.text("events.friend", language: model.language)): \(friend)")
                        .font(.footnote.weight(.semibold))
                }
            }
            .foregroundStyle(GoobyEventsPalette.ink.opacity(0.8))
            if event.claimed {
                Label(libraries.text("events.claimed", language: model.language), systemImage: "gift.fill")
                    .font(.headline)
                    .foregroundStyle(GoobyEventsPalette.ink)
            } else if event.complete {
                GoobyPrimaryButton(title: libraries.text("events.claim", language: model.language)) {
                    onGrants(GoobyEventsIntegration.claimEvent(id: event.id, now: now, calendar: calendar))
                }
            } else if !emphasized {
                Text(libraries.text("events.open", language: model.language))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.65))
            }
        }
        .goobyCard(fill: GoobyEventsPalette.color(hex: event.accentHex).opacity(emphasized ? 0.95 : 0.75))
    }
}

struct GoobyHatchCelebration: View {
    var companion: GoobyCompanionSnapshot
    var libraries: GoobyEventsLibraries
    var language: GoobyEventsLanguage
    var reduceMotion: Bool
    var dismiss: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()
            VStack(spacing: 14) {
                GoobyCompanionArt(
                    speciesID: companion.speciesID,
                    primaryHex: companion.primaryHex,
                    secondaryHex: companion.secondaryHex,
                    animation: companion.animation,
                    size: 168,
                    animate: !reduceMotion
                )
                .scaleEffect(shown || reduceMotion ? 1 : 0.6)
                Text(companion.name)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(GoobyEventsPalette.ink)
                Text(companion.story)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.8))
                GoobyPrimaryButton(title: libraries.text("nest.hello", language: language), action: dismiss)
            }
            .padding(22)
            .background(GoobyEventsPalette.cream)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .padding(24)
            .shadow(color: GoobyEventsPalette.ink.opacity(0.16), radius: 24, y: 12)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(duration: 0.45)) {
                shown = true
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}
#endif
