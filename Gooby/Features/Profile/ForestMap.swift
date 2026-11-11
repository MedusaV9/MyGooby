import SwiftUI

struct ForestMap: View {
    var places: [PlaceSnap]

    var body: some View {
        GeometryReader { geo in
            let visited = Set(places.filter { $0.visits > 0 }.map(\.id))
            ZStack {
                ForEach(ForestLayout.spots) { spot in
                    let lit = spot.placeID.map { visited.contains($0) } ?? false
                    ForestMotif(kind: spot.kind, lit: lit)
                        .frame(width: geo.size.width * spot.scale, height: geo.size.width * spot.scale)
                        .position(x: geo.size.width * spot.x, y: geo.size.height * spot.y)
                        .accessibilityHidden(spot.placeID == nil)
                }
            }
        }
        .clipped()
    }
}

struct ForestMapScreen: View {
    var title: String
    var count: String
    var closeLabel: String
    var places: [PlaceSnap]
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color(hex: 0x6ECF78).ignoresSafeArea()
            VStack(spacing: 14) {
                ZStack {
                    VStack(spacing: 2) {
                        Text(title)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text(count)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                    HStack {
                        Button(action: onClose) {
                            CloseCross()
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.92), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(closeLabel)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                ForestMap(places: places)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ProfilePalette.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
            }
        }
    }
}

private enum ForestLayout {
    struct Spot: Identifiable {
        var id: String
        var placeID: String?
        var kind: ForestKind
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
    }

    static let spots: [Spot] = [
        Spot(id: "meadow", placeID: "meadow", kind: .sun, x: 0.22, y: 0.30, scale: 0.20),
        Spot(id: "sugar", placeID: "sugar", kind: .hill, x: 0.42, y: 0.18, scale: 0.16),
        Spot(id: "bird", placeID: nil, kind: .bird, x: 0.62, y: 0.12, scale: 0.11),
        Spot(id: "cherry", placeID: "cherry", kind: .cherries, x: 0.82, y: 0.22, scale: 0.15),
        Spot(id: "leaf-1", placeID: nil, kind: .leaf, x: 0.12, y: 0.48, scale: 0.08),
        Spot(id: "garden", placeID: "garden", kind: .flower, x: 0.30, y: 0.52, scale: 0.12),
        Spot(id: "clouds", placeID: "clouds", kind: .cloud, x: 0.54, y: 0.40, scale: 0.22),
        Spot(id: "heart-1", placeID: nil, kind: .heart, x: 0.72, y: 0.34, scale: 0.07),
        Spot(id: "moon", placeID: "moon", kind: .moon, x: 0.88, y: 0.46, scale: 0.12),
        Spot(id: "bunny", placeID: nil, kind: .bunny, x: 0.16, y: 0.72, scale: 0.16),
        Spot(id: "beach", placeID: "beach", kind: .wave, x: 0.40, y: 0.68, scale: 0.14),
        Spot(id: "leaf-2", placeID: nil, kind: .leaf, x: 0.58, y: 0.58, scale: 0.07),
        Spot(id: "bush", placeID: nil, kind: .bush, x: 0.74, y: 0.58, scale: 0.12),
        Spot(id: "starwood", placeID: "starwood", kind: .tree, x: 0.18, y: 0.90, scale: 0.16),
        Spot(id: "crystal", placeID: "crystal", kind: .crystal, x: 0.40, y: 0.88, scale: 0.11),
        Spot(id: "heart-2", placeID: nil, kind: .heart, x: 0.56, y: 0.80, scale: 0.07),
        Spot(id: "snow", placeID: "snow", kind: .mushroom, x: 0.72, y: 0.84, scale: 0.13),
        Spot(id: "cat", placeID: nil, kind: .cat, x: 0.90, y: 0.78, scale: 0.13),
        Spot(id: "egg", placeID: nil, kind: .egg, x: 0.90, y: 0.14, scale: 0.09),
        Spot(id: "leaf-3", placeID: nil, kind: .leaf, x: 0.48, y: 0.26, scale: 0.07)
    ]
}

private enum ForestKind {
    case sun, cherries, cloud, flower, tree, mushroom, moon, wave, hill, crystal, leaf, heart, bunny, bird, bush, cat, egg
}

private struct ForestMotif: View {
    var kind: ForestKind
    var lit: Bool

    private var ink: Color { lit ? Color(hex: 0xC4923E) : ProfilePalette.doodle }
    private var fade: Double { lit ? 0.95 : 0.72 }

    var body: some View {
        motif
            .foregroundStyle(ink)
            .opacity(fade)
    }

    @ViewBuilder private var motif: some View {
        switch kind {
        case .sun:
            Circle()
        case .cherries:
            ZStack {
                Circle().frame(width: 18, height: 18).offset(x: -8, y: 4)
                Circle().frame(width: 16, height: 16).offset(x: 8, y: 2)
                Capsule().frame(width: 2, height: 12).offset(y: -10)
            }
        case .cloud:
            ZStack {
                Circle().frame(width: 22).offset(x: -12, y: 4)
                Circle().frame(width: 30)
                Circle().frame(width: 18).offset(x: 14, y: 6)
            }
        case .flower:
            ZStack {
                Circle().frame(width: 10).offset(x: -6, y: -4)
                Circle().frame(width: 10).offset(x: 6, y: -4)
                Circle().frame(width: 10).offset(y: -10)
                Capsule().frame(width: 3, height: 16).offset(y: 8)
            }
        case .tree:
            ZStack {
                ProfileTriangle().frame(width: 28, height: 22).offset(y: -6)
                Capsule().frame(width: 4, height: 12).offset(y: 12)
            }
        case .mushroom:
            ZStack {
                Capsule().frame(width: 8, height: 14).offset(y: 6)
                Ellipse().frame(width: 26, height: 16).offset(y: -4)
            }
        case .moon:
            Crescent()
        case .wave:
            Ellipse().frame(height: 16)
        case .hill:
            Ellipse().frame(height: 18)
        case .crystal:
            ProfileDiamond()
        case .leaf:
            Ellipse().rotationEffect(.degrees(-32))
        case .heart:
            ZStack {
                Circle().frame(width: 10).offset(x: -4, y: -2)
                Circle().frame(width: 10).offset(x: 4, y: -2)
                ProfileTriangle().rotationEffect(.degrees(180)).frame(width: 16, height: 12).offset(y: 4)
            }
        case .bunny:
            ZStack {
                Ellipse().frame(width: 28, height: 16).offset(y: 6)
                Circle().frame(width: 8).offset(x: -6, y: -6)
                Circle().frame(width: 8).offset(x: 4, y: -8)
            }
        case .bird:
            ZStack {
                Circle().frame(width: 16)
                ProfileTriangle().rotationEffect(.degrees(90)).frame(width: 8, height: 6).offset(x: 10)
            }
        case .bush:
            ZStack {
                Circle().frame(width: 16).offset(x: -8, y: 2)
                Circle().frame(width: 18).offset(y: -2)
                Circle().frame(width: 14).offset(x: 10, y: 3)
            }
        case .cat:
            ZStack {
                Circle().frame(width: 20)
                ProfileTriangle().frame(width: 8, height: 8).offset(x: -6, y: -12)
                ProfileTriangle().frame(width: 8, height: 8).offset(x: 6, y: -12)
            }
        case .egg:
            Ellipse()
        }
    }
}
