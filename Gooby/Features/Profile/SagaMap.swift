import SwiftUI

/// Local map of the adventure stories already in the catalog.
/// A place with at least one visit is marked and lists its story titles.
/// Every other place stays closed, so its name and titles stay hidden.
/// Hook: `openSaga` in `LocationsScreen`, which presents `SagaMap.open`.
enum SagaMap {
    static func open(engine: GoobyEngine, calm: Bool, onClose: @escaping () -> Void) -> SagaMapScreen {
        SagaMapScreen(engine: engine, calm: calm, onClose: onClose)
    }
}

struct SagaStop: Identifiable {
    var place: PlaceDef
    var visits: Int
    var stories: [StoryDef]
    var heardIDs: Set<String>

    var id: String { place.id }
    var visited: Bool { visits > 0 }
    var heardCount: Int { stories.reduce(0) { $0 + (heardIDs.contains($1.id) ? 1 : 0) } }
}

@MainActor
enum SagaLedger {
    static func stops(_ engine: GoobyEngine) -> [SagaStop] {
        let heard = Set(
            engine.all(AdventureRun.self)
                .filter { $0.status == "claimed" && !$0.storyID.isEmpty }
                .map(\.storyID)
        )
        var visits: [String: Int] = [:]
        for row in engine.all(PlaceProgress.self) {
            visits[row.placeID] = row.visits
        }
        let grouped = Dictionary(grouping: engine.catalog.stories, by: \.placeID)
        return engine.catalog.places.map { place in
            SagaStop(
                place: place,
                visits: visits[place.id] ?? 0,
                stories: grouped[place.id] ?? [],
                heardIDs: heard
            )
        }
    }

    /// Latest claimed outing on a visited place. Nil when nothing has been visited.
    static func anchorID(_ engine: GoobyEngine, stops: [SagaStop]) -> String? {
        let open = Set(stops.filter(\.visited).map(\.place.id))
        guard !open.isEmpty else { return nil }
        let latest = engine.all(AdventureRun.self)
            .filter { $0.status == "claimed" && open.contains($0.placeID) }
            .max { lhs, rhs in
                (lhs.claimedAt ?? lhs.startedAt) < (rhs.claimedAt ?? rhs.startedAt)
            }
        if let id = latest?.placeID, open.contains(id) { return id }
        return stops.first { $0.visited }?.place.id
    }
}

struct SagaMapScreen: View {
    var engine: GoobyEngine
    var calm: Bool
    var onClose: () -> Void

    @State private var focus: SagaFocus?

    var body: some View {
        let stops = SagaLedger.stops(engine)
        screen(stops)
    }

    private func screen(_ stops: [SagaStop]) -> some View {
        let visited = stops.filter(\.visited).count
        return ZStack {
            Color(hex: 0xC19668).ignoresSafeArea()
            VStack(spacing: 0) {
                header(visited: visited, total: stops.count)
                    .padding(.bottom, 12)
                sheet(stops)
            }
            .padding(.top, 8)
        }
        .accessibilityIdentifier("saga-map")
        .animation(calm ? nil : .easeOut(duration: 0.22), value: focus)
    }

    private func header(visited: Int, total: Int) -> some View {
        ZStack {
            VStack(spacing: 2) {
                Text(engine.t("saga.map.title"))
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(ProfilePalette.ink)
                Text(engine.tf("saga.map.count", visited, total))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ProfilePalette.brown)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 56)
            HStack {
                Button(action: onClose) {
                    ChevronGlyph()
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(ProfilePalette.ink)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.92), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ProfileCopy.back(engine.languageCode))
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }

    private func sheet(_ stops: [SagaStop]) -> some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Text(engine.t("saga.map.note"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(ProfilePalette.brown)
                    .fixedSize(horizontal: false, vertical: true)
                if stops.allSatisfy({ !$0.visited }) {
                    Text(engine.t("saga.map.empty"))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ScrollView(showsIndicators: false) {
                    SagaMapCanvas(
                        engine: engine,
                        stops: stops,
                        anchorID: SagaLedger.anchorID(engine, stops: stops),
                        selectedID: selectedID,
                        calm: calm,
                        onSelect: { self.choose($0) },
                        onClear: { self.focus = nil }
                    )
                    .frame(height: 1200)
                    .padding(.bottom, focus == nil ? 12 : 250)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(ProfilePalette.paper)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28,
                style: .continuous
            ))
            if let focus {
                card(focus, stops: stops)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
    }

    private var selectedID: String? {
        if case .place(let id) = focus { return id }
        return nil
    }

    @ViewBuilder
    private func card(_ focus: SagaFocus, stops: [SagaStop]) -> some View {
        switch focus {
        case .shut:
            HStack(spacing: 10) {
                Text(engine.t("saga.map.placeClosed"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(ProfilePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Button { self.focus = nil } label: {
                    ChevronGlyph(direction: .down)
                        .foregroundStyle(ProfilePalette.ink)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: 0xF6E7D2), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ProfileCopy.back(engine.languageCode))
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityIdentifier("saga-map-closed")
        case .place(let id):
            if let stop = stops.first(where: { $0.place.id == id }) {
                placeCard(stop)
            }
        }
    }

    private func placeCard(_ stop: SagaStop) -> some View {
        let name = stop.place.name.text(engine.languageCode)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.ink)
                    if !stop.stories.isEmpty {
                        Text(engine.tf("saga.map.stories", stop.heardCount, stop.stories.count))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(ProfilePalette.brown)
                    }
                }
                Spacer(minLength: 8)
                Button { self.focus = nil } label: {
                    ChevronGlyph(direction: .down)
                        .foregroundStyle(ProfilePalette.ink)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: 0xF6E7D2), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ProfileCopy.back(engine.languageCode))
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(stop.stories) { story in
                        storyRow(story, stop: stop)
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityIdentifier("saga-map-stories")
    }

    private func storyRow(_ story: StoryDef, stop: SagaStop) -> some View {
        let heard = stop.heardIDs.contains(story.id)
        let title = story.title.text(engine.languageCode)
        return HStack(spacing: 8) {
            Circle()
                .fill(heard ? Color(hex: 0xE3A31B) : Color(hex: 0xE7DCC8))
                .frame(width: 10, height: 10)
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 6)
            if heard {
                Text(engine.t("saga.map.heard"))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(ProfilePalette.brown)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            heard ? Color(hex: 0xF6E7D2) : Color(hex: 0xF7F1EA),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heard ? "\(title). \(engine.t("saga.map.heard"))" : title)
    }

    private func choose(_ stop: SagaStop) {
        engine.haptics.soft()
        let next: SagaFocus = stop.visited ? .place(stop.place.id) : .shut
        focus = (focus == next) ? nil : next
    }
}

private enum SagaFocus: Equatable {
    case place(String)
    case shut
}
