import SwiftUI

struct LocationsScreen: View {
    var engine: GoobyEngine
    var snap: ProfileSnapshot
    var calm: Bool
    var onBack: () -> Void

    @State private var tab: LocationTab = .all
    @State private var toastVisible = false
    @State private var toastID = 0
    @State private var showAgency = false

    private var shown: [PlaceSnap] {
        tab == .seasonal ? snap.places.filter(\.seasonal) : snap.places
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: 0xC19668).ignoresSafeArea()
            VStack(spacing: 12) {
                header
                notebook
            }
            .padding(.top, 8)
            if toastVisible {
                travelToast
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: toastID) {
                        try? await Task.sleep(for: .seconds(2.8))
                        guard !Task.isCancelled else { return }
                        withAnimation(calm ? nil : .easeOut(duration: 0.2)) { toastVisible = false }
                    }
            }
            if showAgency {
                TravelAgencyScreen(engine: engine, calm: calm, onClose: { showAgency = false })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.move(edge: .trailing))
                    .zIndex(2)
            }
        }
        .animation(calm ? nil : .easeOut(duration: 0.25), value: toastVisible)
        .animation(calm ? nil : .easeInOut(duration: 0.28), value: showAgency)
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(engine.t("profile.locations"))
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(ProfilePalette.ink)
                Text(engine.tf("profile.count", snap.locationsFound, snap.places.count))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ProfilePalette.brown)
            }
            HStack {
                Button(action: onBack) {
                    ChevronGlyph()
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(ProfilePalette.ink)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.92), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ProfileCopy.back(engine.languageCode))
                Spacer()
                Button(action: tapTravel) {
                    VStack(spacing: 2) {
                        AirplaneGlyph()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(ProfilePalette.ink)
                        Text(ProfileCopy.travel(engine.languageCode))
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(ProfilePalette.ink)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ProfileCopy.travel(engine.languageCode))
                .accessibilityHint(snap.travelLocked ? ProfileCopy.travelLockedToast(name: snap.name, language: engine.languageCode) : ProfileCopy.travelOpen(engine.languageCode))
            }
        }
        .padding(.horizontal, 16)
    }

    private var notebook: some View {
        VStack(spacing: 0) {
            SpiralRings()
                .padding(.bottom, -12)
                .zIndex(1)
            VStack(alignment: .leading, spacing: 14) {
                tabs
                if shown.isEmpty {
                    Text(ProfileCopy.noSeasonal(engine.languageCode))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(ProfilePalette.brown)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(shown) { place in
                                QuestionPlaceTile(
                                    place: place,
                                    unknown: ProfileCopy.unknownPlace(engine.languageCode)
                                )
                            }
                        }
                        .padding(.bottom, 28)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(ProfilePalette.paper)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28, style: .continuous))
        }
        .padding(.horizontal, 12)
    }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            tabButton(.all, ProfileCopy.allPlaces(engine.languageCode))
            tabButton(.seasonal, ProfileCopy.seasonalPlaces(engine.languageCode))
        }
    }

    private func tabButton(_ item: LocationTab, _ title: String) -> some View {
        let selected = tab == item
        return Button { tab = item } label: {
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(selected ? ProfilePalette.brown : ProfilePalette.brownSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: 0xF6E7D2))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var travelToast: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle().fill(Color(hex: 0xF4E4C4))
                Circle().fill(Color(hex: 0x5C4A32)).frame(width: 3, height: 3).offset(x: -4, y: -1)
                Circle().fill(Color(hex: 0x5C4A32)).frame(width: 3, height: 3).offset(x: 4, y: -1)
                Capsule().fill(Color(hex: 0x5C4A32)).frame(width: 8, height: 1.4).offset(y: 5)
            }
            .frame(width: 28, height: 28)
            Text(ProfileCopy.travelLockedToast(name: snap.name, language: engine.languageCode))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0x3A342C), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityAddTraits(.isStaticText)
    }

    private func tapTravel() {
        guard snap.travelLocked else {
            engine.haptics.soft()
            showAgency = true
            return
        }
        engine.haptics.soft()
        toastID += 1
        withAnimation(calm ? nil : .easeOut(duration: 0.25)) { toastVisible = true }
    }
}

private enum LocationTab {
    case all, seasonal
}

struct QuestionPlaceTile: View {
    var place: PlaceSnap
    var unknown: String

    private var revealed: Bool { place.visits > 0 }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: 0xF7F1EA))
                if revealed {
                    PlaceStamp(place: place)
                        .padding(8)
                        .opacity(0.95)
                } else {
                    Text("?")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: 0xD5CBBF))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            Text(revealed ? place.name : "???")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(revealed ? ProfilePalette.brown : ProfilePalette.brownSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(revealed ? place.name : unknown)
    }
}

struct AirplaneGlyph: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 2, y: 12))
            path.addLine(to: CGPoint(x: 20, y: 3))
            path.addLine(to: CGPoint(x: 13, y: 19))
            path.addLine(to: CGPoint(x: 10, y: 12))
            path.closeSubpath()
        }
        .stroke(style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
        .frame(width: 22, height: 22)
    }
}
