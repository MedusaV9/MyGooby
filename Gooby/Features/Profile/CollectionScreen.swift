import SwiftUI

struct CollectionScreen: View {
    var engine: GoobyEngine
    var snap: ProfileSnapshot
    var calm: Bool
    var onBack: () -> Void
    var onMenu: () -> Void
    var onEdit: () -> Void
    var onMicropedia: () -> Void
    var shareText: String

    @State private var showLocations = false
    @State private var info: InfoKind?

    private enum InfoKind: Identifiable {
        case pets, places
        var id: Int { self == .pets ? 0 : 1 }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                ProfileHeader(
                    title: snap.name,
                    menuLabel: engine.t("profile.menu"),
                    shareLabel: engine.t("profile.share"),
                    editLabel: engine.t("profile.edit"),
                    shareText: shareText,
                    onMenu: onMenu,
                    onEdit: onEdit
                )
                .overlay {
                    Button(action: onBack) {
                        Color.clear
                            .frame(width: 140, height: 44)
                            .accessibilityLabel(engine.t("profile.menu.card"))
                    }
                    .buttonStyle(.plain)
                }
                seeAll
                petNotebook
                placeNotebook
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 18)
        }
        .background {
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: .sit,
                reduceMotion: true,
                companion: nil,
                showCompanion: false
            )
            .frame(width: 280, height: 280)
            .opacity(0.08)
            .offset(y: -250)
            .allowsHitTesting(false)
        }
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.startLocation.x < 28 && value.translation.width > 70 { onBack() }
                }
        )
        .fullScreenCover(isPresented: $showLocations) {
            LocationsScreen(engine: engine, snap: snap, calm: calm, onBack: { showLocations = false })
        }
        .sheet(item: $info) { kind in
            infoSheet(kind)
        }
    }

    private var seeAll: some View {
        Button { showLocations = true } label: {
            HStack(spacing: 6) {
                Text(engine.t("profile.seeAll"))
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                ChevronGlyph(direction: .down)
            }
            .foregroundStyle(ProfilePalette.brown)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(ProfilePalette.seeAll, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: ProfilePalette.shadow, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var petNotebook: some View {
        NotebookShell(binder: engine.tf("profile.binder", snap.foundCount, snap.dexTotal), binderAction: onMicropedia) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(engine.t("profile.micropets"))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.ink)
                    Spacer()
                    InfoDot { info = .pets }
                }
                HStack(spacing: 12) {
                    ForEach(Array(snap.previewPetIDs.enumerated()), id: \.element) { index, id in
                        petTile(id: id, featured: index == 0 && snap.found(id))
                    }
                }
            }
        }
    }

    private func petTile(id: String, featured: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(featured ? ProfilePalette.tileDark : ProfilePalette.quietTile)
            MicropetGlyph(id: id, ink: featured ? nil : ProfilePalette.silhouette)
                .frame(width: 72, height: 72)
            if featured {
                Text("#\(ProfileDex.number(for: id))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .padding(7)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 102)
    }

    private var placeNotebook: some View {
        let unlockedCount = snap.places.filter(\.unlocked).count
        return NotebookShell(binder: engine.tf("profile.binder", unlockedCount, snap.places.count), binderAction: { showLocations = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(engine.t("profile.locations"))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.ink)
                    Spacer()
                    InfoDot { info = .places }
                }
                HStack(alignment: .top, spacing: 12) {
                    ForEach(previewPlaces) { place in
                        if place.visits > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                PlaceStamp(place: place)
                                    .frame(height: 102)
                                Text(place.name)
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(ProfilePalette.brown)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                Text("\(place.percent)%")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(ProfilePalette.brownSoft)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(ProfilePalette.quietTile)
                                Text("?")
                                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                                    .foregroundStyle(ProfilePalette.question)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 102)
                        }
                    }
                }
            }
        }
    }

    private var previewPlaces: [PlaceSnap] {
        let open = snap.places.filter(\.unlocked)
        let shut = snap.places.filter { !$0.unlocked }
        return Array((open + shut).prefix(3))
    }

    private func infoSheet(_ kind: InfoKind) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(engine.t(kind == .pets ? "profile.info.pets.title" : "profile.info.places.title"))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
            Text(engine.t(kind == .pets ? "profile.info.pets.body" : "profile.info.places.body"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(ProfilePalette.brown)
            Button(engine.t("profile.close")) { info = nil }
                .buttonStyle(ProfileSaveStyle())
                .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ProfilePalette.page.ignoresSafeArea())
        .presentationDetents([.medium])
    }
}
