import SwiftUI

struct AdventureMapScreen: View {
    var bridge: AdventureBridge
    var store: AdventureStore
    var reduceMotion: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var inspectedPlaceID: String?

    private var copy: AdventureCopy { AdventureCopy(language: bridge.language) }

    var body: some View {
        ZStack {
            AdventureScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AdventureBackHeader(title: copy.map, backTitle: copy.back) { dismiss() }
                    map
                    Text(copy.placesTitle)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AdventurePalette.ink)
                    ForEach(store.catalog.places) { place in
                        placeRow(place)
                    }
                }
                .padding(20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: inspected) { item in
            if let place = store.catalog.place(id: item.id) {
                AdventurePlaceSheet(place: place, bridge: bridge, store: store, reduceMotion: reduceMotion)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var inspected: Binding<AdventurePlaceToken?> {
        Binding(
            get: { inspectedPlaceID.map(AdventurePlaceToken.init(id:)) },
            set: { inspectedPlaceID = $0?.id }
        )
    }

    private var map: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                mapBackground
                path(in: size)
                ForEach(store.catalog.places) { place in
                    node(place, in: size)
                }
            }
        }
        .frame(height: 560)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: AdventurePalette.ink.opacity(0.08), radius: 14, y: 8)
    }

    private var mapBackground: some View {
        ZStack {
            LinearGradient(
                colors: [AdventurePalette.sky, AdventurePalette.cream, AdventurePalette.mint.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            Ellipse()
                .fill(AdventurePalette.mint.opacity(0.9))
                .frame(width: 280, height: 120)
                .offset(x: -40, y: 180)
            Ellipse()
                .fill(AdventurePalette.peach.opacity(0.85))
                .frame(width: 220, height: 90)
                .offset(x: 90, y: 150)
            Ellipse()
                .fill(AdventurePalette.lavender.opacity(0.75))
                .frame(width: 200, height: 80)
                .offset(x: -70, y: -40)
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: 90, height: 36)
                .offset(x: 40, y: -160)
        }
    }

    private func path(in size: CGSize) -> some View {
            let points = store.catalog.places.map { point($0, in: size) }
        return Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for index in 1..<points.count {
                let previous = points[index - 1]
                let current = points[index]
                let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2 - 24)
                path.addQuadCurve(to: current, control: mid)
            }
        }
        .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
    }

    private func point(_ place: AdventurePlaceDefinition, in size: CGSize) -> CGPoint {
        CGPoint(
            x: 36 + place.mapX * (size.width - 72),
            y: 42 + place.mapY * (size.height - 84)
        )
    }

    private func node(_ place: AdventurePlaceDefinition, in size: CGSize) -> some View {
        let unlocked = AdventureEngine.isUnlocked(place, save: store.save)
        let selected = AdventureEngine.destinationID(save: store.save, catalog: store.catalog) == place.id
        return Button {
            inspectedPlaceID = place.id
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(AdventurePalette.color(hex: place.accentHex))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Circle()
                                .stroke(selected ? AdventurePalette.ink : Color.white, lineWidth: selected ? 4 : 3)
                        )
                    AdventurePlaceIcon(motif: place.motif, tint: AdventurePalette.ink)
                        .frame(width: 28, height: 28)
                    if !unlocked {
                        AdventureLockMark()
                            .padding(4)
                            .background(Color.white.opacity(0.9), in: Circle())
                            .offset(x: 18, y: 18)
                    }
                }
                Text(place.name.resolved(bridge.language))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.88), in: Capsule())
                    .lineLimit(1)
            }
        }
        .buttonStyle(AdventurePressStyle())
        .opacity(unlocked ? 1 : 0.72)
        .position(point(place, in: size))
        .accessibilityLabel(place.name.resolved(bridge.language))
        .accessibilityHint(unlocked ? copy.open : copy.locked)
    }

    private func placeRow(_ place: AdventurePlaceDefinition) -> some View {
        let unlocked = AdventureEngine.isUnlocked(place, save: store.save)
        let found = place.discoveries.filter { store.save.foundDiscoveryIDs.contains($0.id) }.count
        return Button {
            inspectedPlaceID = place.id
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(AdventurePalette.color(hex: place.accentHex))
                    AdventurePlaceIcon(motif: place.motif, tint: AdventurePalette.ink)
                        .padding(8)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name.resolved(bridge.language))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AdventurePalette.ink)
                    Text(unlocked ? copy.foundCount(found: found, total: place.discoveries.count) : copy.locked)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AdventurePalette.ink.opacity(0.65))
                }
                Spacer()
            }
            .padding(12)
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(AdventurePressStyle())
    }
}

struct AdventurePlaceToken: Identifiable {
    var id: String
}

struct AdventurePlaceSheet: View {
    var place: AdventurePlaceDefinition
    var bridge: AdventureBridge
    var store: AdventureStore
    var reduceMotion: Bool

    @Environment(\.dismiss) private var dismiss

    private var copy: AdventureCopy { AdventureCopy(language: bridge.language) }
    private var unlocked: Bool { AdventureEngine.isUnlocked(place, save: store.save) }
    private var selected: Bool { store.save.selectedPlaceID == place.id && unlocked }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .bottomLeading) {
                    AdventureSky(place: place, reducedMotion: reduceMotion)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    Text(place.name.resolved(bridge.language))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AdventurePalette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.9), in: Capsule())
                        .padding(12)
                }
                Text(place.summary.resolved(bridge.language))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink)
                HStack {
                    stat(copy.visits, "\(store.save.placeVisits[place.id, default: 0])")
                    stat(copy.storiesLabel, copy.seenStories(seen: seenCount, total: storyCount))
                }
                if unlocked {
                    Text(selected ? copy.selected : copy.open)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AdventurePalette.ink)
                    AdventurePrimaryButton(title: selected ? copy.selected : copy.selectPlace, enabled: !selected) {
                        store.selectPlace(id: place.id)
                        dismiss()
                    }
                } else {
                    Text(copy.unlockRemaining(AdventureEngine.adventuresUntilUnlock(place, save: store.save)))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AdventurePalette.ink)
                }
                discoveryList
            }
            .padding(20)
        }
        .background(AdventurePalette.cream)
    }

    private var storyCount: Int {
        store.catalog.stories.filter { $0.placeID == place.id }.count
    }

    private var seenCount: Int {
        store.catalog.stories.filter { $0.placeID == place.id && store.save.seenStoryIDs.contains($0.id) }.count
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AdventurePalette.ink.opacity(0.6))
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AdventurePalette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var discoveryList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(copy.discoveries)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AdventurePalette.ink)
            ForEach(place.discoveries) { discovery in
                let found = store.save.foundDiscoveryIDs.contains(discovery.id)
                VStack(alignment: .leading, spacing: 2) {
                    Text(found ? discovery.name.resolved(bridge.language) : copy.hidden)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AdventurePalette.ink)
                    if found {
                        Text(discovery.detail.resolved(bridge.language))
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AdventurePalette.ink.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background((found ? AdventurePalette.yellow : Color.white).opacity(0.75), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

struct AdventureBackHeader: View {
    var title: String
    var backTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text(backTitle)
                }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(AdventurePalette.ink)
            }
            .buttonStyle(AdventurePressStyle())
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(AdventurePalette.ink)
        }
    }
}
