import SwiftUI

// Owned by the pet slice. Foundation stub: a working pet tab until the profile (screens 4 and 5)
// lands.
struct PetProfileScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var showMenu = false

    var body: some View {
        let stage = Growth.stage(of: engine.pet)
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                GCard {
                    HStack(spacing: 14) {
                        GoobyCharacterView(look: engine.wornLook(), stage: stage, animation: .idle, reduceMotion: reduceMotion, companion: nil, showCompanion: false)
                            .frame(width: 110, height: 110)
                            .background(Theme.Tab.pet.cream, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(engine.profile.goobyName)
                                .font(Theme.Fonts.title)
                                .foregroundStyle(Theme.text)
                            Text(engine.t("pet.stage.\(stage)"))
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.greyText)
                        }
                        Spacer(minLength: 0)
                    }
                }
                NavigationLink {
                    if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
                } label: {
                    row(engine.t("kit.pet.places"), icon: "map.fill")
                }
                .buttonStyle(.plain)
                NavigationLink {
                    MicropediaScreen(engine: engine, reduceMotion: reduceMotion)
                } label: {
                    row(engine.t("kit.pet.album"), icon: "pawprint.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.vertical, Theme.Space.gap)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                HamburgerButton(label: engine.t("kit.menu.open")) { showMenu = true }
                Spacer()
            }
            .padding(.horizontal, 12)
        }
        .background(Theme.Tab.pet.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showMenu) {
            NavigationStack { MoreScreen(engine: engine, reduceMotion: reduceMotion) }
        }
    }

    private func row(_ title: String, icon: String) -> some View {
        GCard {
            HStack(spacing: 12) {
                GoobyIcon(icon, size: 30)
                Text(title)
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.text)
                Spacer()
                CircleChevron(fill: Theme.keyFace)
            }
        }
    }
}
