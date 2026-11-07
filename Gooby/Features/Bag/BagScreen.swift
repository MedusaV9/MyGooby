import SwiftUI

// Owned by the social slice. Foundation stub of the bag tab (screen 7): working entries to the
// shop, the room editor and the mini-friend album.
struct BagScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var showRoom = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                NavigationLink {
                    if let make = FeatureHost.shared.shopScreen { make(engine) } else { ShopScreen(engine: engine, reduceMotion: reduceMotion) }
                } label: {
                    tile(engine.t("kit.tab.shop"), icon: "tshirt.fill")
                }
                .buttonStyle(.plain)
                Button {
                    showRoom = true
                } label: {
                    tile(engine.t("kit.bag.furniture"), icon: "sofa.fill")
                }
                .buttonStyle(.plain)
                NavigationLink {
                    MicropediaScreen(engine: engine, reduceMotion: reduceMotion)
                } label: {
                    tile(engine.t("kit.pet.album"), icon: "pawprint.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.vertical, Theme.Space.gap)
        }
        .goobyScreen(Theme.Tab.bag.sheet)
        .navigationTitle(engine.t("kit.tab.bag"))
        .sheet(isPresented: $showRoom) {
            if let make = FeatureHost.shared.roomScreen { make(engine) } else { RoomEditorSheet(engine: engine) }
        }
    }

    private func tile(_ title: String, icon: String) -> some View {
        GCard(radius: Theme.Radius.tile) {
            VStack(spacing: 8) {
                GoobyIcon(icon, size: 44)
                Text(title)
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.text)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
