import SwiftUI

/// A story trail drawn for Gooby. Hills and a dashed path, not a world map.
enum SagaTrail {
    static let order = [
        "meadow", "garden", "cherry", "sugar", "beach",
        "crystal", "clouds", "starwood", "moon", "snow"
    ]

    static func ordered(_ stops: [SagaStop]) -> [SagaStop] {
        let known = order.compactMap { id in stops.first { $0.place.id == id } }
        let extra = stops.filter { !order.contains($0.place.id) }
        return known + extra
    }

    static func unit(for id: String, index: Int, count: Int) -> CGPoint {
        if let spot = spots[id] { return spot }
        let span = max(count, 1)
        let y = 0.11 + 0.82 * CGFloat(index) / CGFloat(span)
        let x: CGFloat = index % 2 == 0 ? 0.28 : 0.72
        return CGPoint(x: x, y: min(0.94, y))
    }

    private static let spots: [String: CGPoint] = [
        "meadow": CGPoint(x: 0.28, y: 0.11),
        "garden": CGPoint(x: 0.72, y: 0.20),
        "cherry": CGPoint(x: 0.30, y: 0.29),
        "sugar": CGPoint(x: 0.74, y: 0.38),
        "beach": CGPoint(x: 0.28, y: 0.47),
        "crystal": CGPoint(x: 0.72, y: 0.56),
        "clouds": CGPoint(x: 0.30, y: 0.66),
        "starwood": CGPoint(x: 0.74, y: 0.75),
        "moon": CGPoint(x: 0.32, y: 0.84),
        "snow": CGPoint(x: 0.68, y: 0.93)
    ]
}

struct SagaMapGlyph: View {
    var body: some View {
        SagaMapMark()
            .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .frame(width: 22, height: 16)
    }
}

struct SagaMapMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let box = rect.insetBy(dx: 0.8, dy: 0.8)
        path.addRoundedRect(in: box, cornerSize: CGSize(width: 3, height: 3))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY - rect.height * 0.30))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.minY + rect.height * 0.34),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.08)
        )
        let dot = CGRect(x: rect.midX - 1.5, y: rect.midY - 1.5, width: 3, height: 3)
        path.addEllipse(in: dot)
        return path
    }
}

struct SagaMapCanvas: View {
    var engine: GoobyEngine
    var stops: [SagaStop]
    var anchorID: String?
    var selectedID: String?
    var calm: Bool
    var onSelect: (SagaStop) -> Void
    var onClear: () -> Void

    var body: some View {
        let trail = SagaTrail.ordered(stops)
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                sky(size)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onClear)
                hills(size)
                    .allowsHitTesting(false)
                SagaPath(units: units(trail))
                    .stroke(
                        ProfilePalette.brown.opacity(0.45),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [7, 6])
                    )
                    .allowsHitTesting(false)
                doodles(size)
                    .allowsHitTesting(false)
                ForEach(Array(trail.enumerated()), id: \.element.id) { index, stop in
                    pin(stop, index: index, count: trail.count, size: size)
                }
                gooby(trail, size: size)
                    .allowsHitTesting(false)
            }
            .frame(width: size.width, height: size.height)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func sky(_ size: CGSize) -> some View {
        LinearGradient(
            colors: [Color(hex: 0xD7F0FA), Color(hex: 0xF8E7C4), Color(hex: 0xD7EEC4)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: size.width, height: size.height)
    }

    private func units(_ trail: [SagaStop]) -> [CGPoint] {
        trail.enumerated().map { index, stop in
            SagaTrail.unit(for: stop.place.id, index: index, count: trail.count)
        }
    }

    private func hills(_ size: CGSize) -> some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: 0xC6E7B0))
                .frame(width: size.width * 1.15, height: size.height * 0.22)
                .position(x: size.width * 0.42, y: size.height * 0.78)
            Ellipse()
                .fill(Color(hex: 0xA8D48C))
                .frame(width: size.width * 0.9, height: size.height * 0.16)
                .position(x: size.width * 0.78, y: size.height * 0.9)
        }
        .frame(width: size.width, height: size.height)
    }

    private func doodles(_ size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xFFE7A0))
                .frame(width: 28, height: 28)
                .position(x: size.width * 0.86, y: size.height * 0.06)
            cloud(size, x: 0.14, y: 0.045, scale: 0.9)
        }
        .frame(width: size.width, height: size.height)
    }

    private func cloud(_ size: CGSize, x: CGFloat, y: CGFloat, scale: CGFloat) -> some View {
        ZStack {
            Circle().frame(width: 16 * scale, height: 16 * scale).offset(x: -10 * scale, y: 3 * scale)
            Circle().frame(width: 22 * scale, height: 22 * scale)
            Circle().frame(width: 14 * scale, height: 14 * scale).offset(x: 11 * scale, y: 4 * scale)
        }
        .foregroundStyle(Color.white.opacity(0.9))
        .position(x: size.width * x, y: size.height * y)
    }

    private func pin(_ stop: SagaStop, index: Int, count: Int, size: CGSize) -> some View {
        let spot = point(SagaTrail.unit(for: stop.place.id, index: index, count: count), in: size)
        let name = stop.place.name.text(engine.languageCode)
        return Button { onSelect(stop) } label: {
            mark(stop)
                .overlay(alignment: .top) {
                    VStack(spacing: 1) {
                        Text(stop.visited ? name : engine.t("saga.map.closed"))
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(stop.visited ? ProfilePalette.ink : ProfilePalette.brownSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        if stop.visited, !stop.stories.isEmpty {
                            Text("\(stop.heardCount)/\(stop.stories.count)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(ProfilePalette.brown)
                        }
                    }
                    .frame(width: 96)
                    .offset(y: 56)
                }
                .frame(width: 100, height: 54)
                .accessibilityElement(children: .ignore)
        }
        .buttonStyle(.plain)
        .position(spot)
        .accessibilityLabel(stop.visited ? "\(name). \(engine.t("saga.map.visited"))" : engine.t("saga.map.closed"))
        .accessibilityHint(stop.visited ? storyHint(stop) : engine.t("saga.map.placeClosed"))
    }

    @ViewBuilder
    private func mark(_ stop: SagaStop) -> some View {
        ZStack {
            if stop.visited {
                PlaceStamp(place: stamp(stop))
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
                Circle()
                    .stroke(selectedID == stop.place.id ? ProfilePalette.ink : Color.white, lineWidth: selectedID == stop.place.id ? 2.5 : 2)
                    .frame(width: 54, height: 54)
                Circle()
                    .fill(Color(hex: 0xE3A31B))
                    .frame(width: 16, height: 16)
                    .overlay(
                        SagaCheck()
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                            .padding(3)
                    )
                    .offset(x: 18, y: 18)
            } else {
                Circle().fill(Color(hex: 0xE7DCC8))
                Circle()
                    .stroke(ProfilePalette.brownSoft.opacity(0.7), style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]))
                Text("?")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0xC9BBA8))
            }
        }
        .frame(width: 54, height: 54)
    }

    private func stamp(_ stop: SagaStop) -> PlaceSnap {
        let place = stop.place
        return PlaceSnap(
            id: place.id,
            name: place.name.text(engine.languageCode),
            found: stop.heardCount,
            total: max(stop.stories.count, 1),
            unlocked: true,
            visits: stop.visits,
            skyTop: place.skyTop,
            skyBottom: place.skyBottom,
            accent: place.accent
        )
    }

    private func storyHint(_ stop: SagaStop) -> String {
        guard !stop.stories.isEmpty else { return engine.t("saga.map.visited") }
        return engine.tf("saga.map.stories", stop.heardCount, stop.stories.count)
    }

    private func gooby(_ trail: [SagaStop], size: CGSize) -> some View {
        let spot = goobySpot(trail, size: size)
        return GoobyCharacterView(
            look: engine.wornLook(),
            stage: Growth.stage(of: engine.pet),
            animation: calm ? .sit : .read,
            reduceMotion: calm,
            companion: nil,
            showCompanion: false
        )
        .frame(width: 72, height: 78)
        .position(spot)
        .accessibilityHidden(true)
    }

    private func goobySpot(_ trail: [SagaStop], size: CGSize) -> CGPoint {
        guard let anchorID, let index = trail.firstIndex(where: { $0.place.id == anchorID }) else {
            return CGPoint(x: size.width * 0.50, y: 64)
        }
        let unit = SagaTrail.unit(for: anchorID, index: index, count: trail.count)
        let spot = point(unit, in: size)
        let side: CGFloat = unit.x < 0.5 ? 92 : -92
        return CGPoint(x: min(size.width - 40, max(40, spot.x + side)), y: spot.y + 6)
    }

    private func point(_ unit: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: unit.x * size.width, y: unit.y * size.height)
    }

}

private struct SagaPath: Shape {
    var units: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = units.first else { return path }
        path.move(to: CGPoint(x: first.x * rect.width, y: first.y * rect.height))
        for unit in units.dropFirst() {
            path.addLine(to: CGPoint(x: unit.x * rect.width, y: unit.y * rect.height))
        }
        return path
    }
}

struct SagaCheck: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY - rect.height * 0.28))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.minY + rect.height * 0.26))
        return path
    }
}
