import SwiftUI

struct MicropediaScreen: View {
    var engine: GoobyEngine
    var snap: ProfileSnapshot
    var onBag: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: String?
    @State private var headerOffset: CGFloat = 0

    private let headerExpanded: CGFloat = 112
    private let headerCollapsed: CGFloat = 64

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack(alignment: .top) {
            ProfilePalette.page.ignoresSafeArea()
            VStack(spacing: 22) {
                CollapsingHeader(
                    offset: headerOffset,
                    expandedHeight: headerExpanded,
                    collapsedHeight: headerCollapsed,
                    plate: ProfilePalette.page,
                    artAlignment: .center,
                    shrinkAnchor: .center,
                    barAlignment: .center,
                    chromeAlignment: .center,
                    art: { headerArt },
                    bar: { headerBar },
                    chrome: { headerChrome }
                )
                notebook
                    .frame(maxHeight: .infinity)
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var headerArt: some View {
        RibbonBanner(title: engine.t("profile.micropedia"))
            .scaleEffect(1.15)
            .frame(maxWidth: .infinity)
    }

    private var headerBar: some View {
        VStack(spacing: 1) {
            Text(engine.t("profile.micropedia"))
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
                .lineLimit(1)
            Text(ProfileCopy.foundLine(snap.foundCount, snap.dexTotal, engine.languageCode))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(ProfilePalette.brown)
                .lineLimit(1)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 52)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var headerChrome: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                CloseCross()
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.55), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("profile.close"))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
    }

    private var notebook: some View {
        VStack(spacing: 0) {
            SpiralRings()
                .padding(.bottom, -12)
                .zIndex(1)
            VStack(spacing: 0) {
                HStack {
                    Text(ProfileCopy.foundLine(snap.foundCount, snap.dexTotal, engine.languageCode))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.brown)
                    Spacer()
                    Button(action: onBag) {
                        HStack(spacing: 4) {
                            Text(engine.t("profile.bag"))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.brown)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                ScrollView(showsIndicators: false) {
                    GoobyScrollProbe()
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ProfileDex.entries) { entry in
                            Button { selected = entry.id } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(ProfilePalette.cell)
                                    MicropetGlyph(id: entry.id, ink: snap.found(entry.id) ? nil : ProfilePalette.silhouette)
                                    .frame(width: 64, height: 64)
                                }
                                .aspectRatio(1, contentMode: .fit)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(label(for: entry.id))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 28)
                }
                .goobyCollapsingOffset(
                    travel: headerExpanded - headerCollapsed,
                    reduceMotion: engine.reduceMotion,
                    offset: $headerOffset
                )
            }
            .background(ProfilePalette.paper)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28, style: .continuous))
        }
        .padding(.horizontal, 16)
        .sheet(item: binding) { item in
            detail(item.id)
        }
    }

    private var binding: Binding<DexID?> {
        Binding(
            get: { selected.map(DexID.init) },
            set: { selected = $0?.id }
        )
    }

    private func label(for id: String) -> String {
        snap.found(id) ? name(id) : engine.t("profile.dex.locked")
    }

    private func name(_ id: String) -> String {
        if let friend = engine.catalog.friendsByID[id] {
            return friend.name.text(engine.languageCode)
        }
        return engine.t("profile.dex.\(id)")
    }

    private func blurb(_ id: String) -> String {
        guard snap.found(id) else { return engine.t("profile.dex.locked") }
        if let friend = engine.catalog.friendsByID[id] {
            return friend.blurb.text(engine.languageCode)
        }
        return engine.t("profile.dex.found")
    }

    private func detail(_ id: String) -> some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(snap.found(id) ? ProfilePalette.tileDark : ProfilePalette.cell)
                MicropetGlyph(id: id, ink: snap.found(id) ? nil : ProfilePalette.silhouette)
                    .frame(width: 90, height: 90)
            }
            .frame(width: 140, height: 140)
            Text(snap.found(id) ? name(id) : engine.t("profile.dex.locked"))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
            Text(blurb(id))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(ProfilePalette.brown)
                .multilineTextAlignment(.center)
            Button(engine.t("profile.close")) { selected = nil }
                .buttonStyle(ProfileSaveStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ProfilePalette.page.ignoresSafeArea())
        .sheetRise(calm: engine.reduceMotion)
        .presentationDetents([.medium])
    }
}

private struct DexID: Identifiable {
    var id: String
}
