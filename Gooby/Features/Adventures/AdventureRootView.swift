import SwiftUI
import UIKit

enum AdventureRoute: Hashable {
    case map
    case discoveries
    case personality
    case story
}

struct AdventureRootView: View {
    var bridge: AdventureBridge
    var store: AdventureStore

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var wallNow = Date()

    private var reduceMotion: Bool { systemReduceMotion || bridge.prefersReducedMotion }
    private var copy: AdventureCopy { AdventureCopy(language: bridge.language) }
    private var phase: AdventurePhase {
        store.phase(
            energy: bridge.energy,
            energyGoal: bridge.energyGoal,
            appNow: bridge.appNow,
            wallNow: wallNow
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdventureScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        if store.catalog.stories.isEmpty {
                            AdventureCard {
                                Text(copy.catalogError)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(AdventurePalette.ink)
                            }
                        } else {
                            statusCard(phase: phase, wallNow: wallNow)
                            if let banner = store.banner {
                                Text(bannerText(banner))
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(AdventurePalette.ink)
                                    .padding(.horizontal, 4)
                            }
                            linkRow
                        }
                    }
                    .padding(20)
                }
            }
            .navigationDestination(for: AdventureRoute.self) { route in
                switch route {
                case .map:
                    AdventureMapScreen(bridge: bridge, store: store, reduceMotion: reduceMotion)
                case .discoveries:
                    AdventureDiscoveriesScreen(bridge: bridge, store: store)
                case .personality:
                    AdventurePersonalityScreen(bridge: bridge, store: store)
                case .story:
                    AdventureStoryScreen(bridge: bridge, store: store, reduceMotion: reduceMotion, mode: .activeTrip)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: previewPresented) {
            AdventureStoryScreen(bridge: bridge, store: store, reduceMotion: reduceMotion, mode: .preview)
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            AdventuresIntegration.attach(bridge)
            wallNow = Date()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                wallNow = Date()
                store.clearBanner()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                wallNow = Date()
            }
        }
    }

    private var previewPresented: Binding<Bool> {
        Binding(
            get: { store.previewStoryID != nil },
            set: { isPresented in
                if !isPresented {
                    store.endPreview()
                }
            }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(copy.screenTitle)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(AdventurePalette.ink)
            Text(copy.subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AdventurePalette.ink.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func statusCard(phase: AdventurePhase, wallNow: Date) -> some View {
        switch phase {
        case .needsEnergy(let current, let goal):
            homeCard {
                AdventureBunnyView(pose: .idle, reducedMotion: reduceMotion)
                Text(copy.energyHint)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink)
                    .multilineTextAlignment(.center)
                energyBar(current: current, goal: goal)
                AdventurePrimaryButton(title: copy.start, enabled: false) {}
            }
        case .ready:
            homeCard {
                AdventureBunnyView(pose: .idle, reducedMotion: reduceMotion)
                Text(copy.readyHint(bridge.displayName))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink)
                    .multilineTextAlignment(.center)
                destinationLine
                if bridge.energyGoal > 0 {
                    energyBar(current: bridge.energy, goal: bridge.energyGoal)
                }
                AdventurePrimaryButton(title: copy.start) {
                    if !reduceMotion {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                    _ = store.startAdventure(bridge: bridge, wallNow: wallNow)
                }
            }
        case .traveling(let trip, let remaining):
            travelCard(trip: trip, remaining: remaining, justLeft: wallNow.timeIntervalSince(trip.startedAt) < 8)
        case .storyReady:
            homeCard {
                AdventureBunnyView(pose: .celebrate, reducedMotion: reduceMotion)
                Text(copy.returnedTitle(bridge.displayName))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AdventurePalette.ink)
                Text(copy.returnedBody(bridge.displayName))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink.opacity(0.8))
                    .multilineTextAlignment(.center)
                NavigationLink(value: AdventureRoute.story) {
                    Text(copy.hearStory)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AdventurePalette.ink, in: Capsule())
                }
                .buttonStyle(AdventurePressStyle())
            }
        case .rested:
            homeCard {
                AdventureBunnyView(pose: .rest, reducedMotion: reduceMotion)
                Text(copy.restedTitle)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AdventurePalette.ink)
                    .multilineTextAlignment(.center)
                Text(copy.restedBody)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink.opacity(0.78))
                    .multilineTextAlignment(.center)
                if let entry = todayRecap {
                    recap(entry)
                }
            }
        }
    }

    private func homeCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        AdventureCard {
            VStack(spacing: 14) {
                doorway
                content()
            }
        }
    }

    private var doorway: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(AdventurePalette.sky.opacity(0.85))
                .frame(height: 92)
            Circle()
                .fill(AdventurePalette.yellow.opacity(0.9))
                .frame(width: 36, height: 36)
                .offset(x: 78, y: -16)
            Capsule()
                .fill(AdventurePalette.mint)
                .frame(width: 120, height: 18)
                .offset(y: 34)
        }
        .accessibilityHidden(true)
        .padding(.bottom, -28)
    }

    private func travelCard(trip: AdventureActiveTrip, remaining: TimeInterval, justLeft: Bool) -> some View {
        let place = store.catalog.place(id: trip.placeID)
        return ZStack(alignment: .bottom) {
            if let place {
                AdventureSky(place: place, reducedMotion: reduceMotion)
            } else {
                AdventurePalette.sky
            }
            VStack(spacing: 8) {
                AdventureBunnyView(pose: .hop, reducedMotion: reduceMotion)
                    .offset(x: justLeft && !reduceMotion ? 24 : 0)
                    .scaleEffect(justLeft && !reduceMotion ? 0.92 : 1)
                    .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8), value: justLeft)
                VStack(spacing: 8) {
                    Text(copy.onTheWay)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    if let place {
                        Text(copy.travelingToward(place.name.resolved(bridge.language)))
                            .font(.system(.body, design: .rounded))
                    }
                    Text(copy.leftHome(bridge.displayName))
                        .font(.system(.subheadline, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(copy.remaining(remaining))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AdventurePalette.yellow, in: Capsule())
                        .accessibilityLabel(copy.remaining(remaining))
                    Text(copy.clockNote)
                        .font(.system(.footnote, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(AdventurePalette.ink)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(AdventurePalette.cream.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding(16)
        }
        .frame(minHeight: 460)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: AdventurePalette.ink.opacity(0.08), radius: 16, y: 8)
    }

    private var destinationLine: some View {
        let placeID = AdventureEngine.destinationID(save: store.save, catalog: store.catalog)
        let name = store.catalog.place(id: placeID)?.name.resolved(bridge.language) ?? ""
        return VStack(spacing: 2) {
            Text(copy.destination)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(AdventurePalette.ink.opacity(0.6))
            Text(name)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AdventurePalette.ink)
            Text(copy.changeOnMap)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AdventurePalette.ink.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private func energyBar(current: Int, goal: Int) -> some View {
        let fraction = goal > 0 ? min(1, Double(current) / Double(goal)) : 1
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(copy.energyTitle)
                Spacer()
                Text(copy.energyValue(current: current, goal: goal))
            }
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(AdventurePalette.ink)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AdventurePalette.ink.opacity(0.08))
                    Capsule()
                        .fill(AdventurePalette.mint)
                        .frame(width: max(8, proxy.size.width * fraction))
                }
            }
            .frame(height: 12)
        }
        .accessibilityElement(children: .combine)
    }

    private var linkRow: some View {
        VStack(spacing: 10) {
            NavigationLink(value: AdventureRoute.map) { tile(copy.map, AdventurePalette.sky) }
            NavigationLink(value: AdventureRoute.discoveries) { tile(copy.discoveries, AdventurePalette.yellow) }
            NavigationLink(value: AdventureRoute.personality) { tile(copy.personality, AdventurePalette.lavender) }
        }
        .buttonStyle(AdventurePressStyle())
    }

    private func tile(_ title: String, _ tint: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AdventurePalette.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(AdventurePalette.ink.opacity(0.55))
        }
        .padding(16)
        .background(tint.opacity(0.85), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var todayRecap: AdventureJournalEntry? {
        guard let day = store.save.lastResolvedDayKey else { return nil }
        return store.save.journal.first { $0.dayKey == day && !$0.preview }
    }

    private func recap(_ entry: AdventureJournalEntry) -> some View {
        let title = store.catalog.story(id: entry.storyID)?.title.resolved(bridge.language) ?? ""
        return VStack(alignment: .leading, spacing: 4) {
            Text(copy.today)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(AdventurePalette.ink.opacity(0.6))
            Text(title)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(AdventurePalette.ink)
            if entry.sparks > 0 {
                Text(copy.sparks(entry.sparks))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AdventurePalette.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AdventurePalette.yellow.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func bannerText(_ banner: AdventureBanner) -> String {
        switch banner {
        case .energyRefused:
            return copy.energyRefused
        case .placeLocked:
            return copy.placeLockedBanner
        }
    }
}

#Preview("Abenteuer") {
    AdventureRootView(
        bridge: AdventuresIntegration.previewBridge(),
        store: AdventureStore(memoryOnly: true)
    )
}
