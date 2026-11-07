import SwiftUI

struct ShopWardrobeScreen: View {
    @State private var store = ShopRoomStore.shared
    @State private var anchor: ShopAnchor = .hat
    @State private var selectedID: String?
    @State private var confirmBuy = false
    @State private var confirmSell = false
    @State private var needFunds = false
    @State private var showOutfits = false
    @State private var toast: String?

    private let columns = [GridItem(.adaptive(minimum: 148), spacing: 12)]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 10) {
                header
                ShopBunnyView(
                    worn: store.resolved(store.state.previewWear),
                    animated: true,
                    language: store.language
                )
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                if tryingUnowned {
                    ShopBanner(text: ShopL10n.text(.onlyTrying, store.language))
                        .padding(.horizontal, 16)
                }
                Text(ShopL10n.text(.wardrobeHint, store.language))
                    .font(ShopTheme.captionFont())
                    .foregroundStyle(ShopTheme.ink.opacity(0.72))
                    .padding(.horizontal, 16)
                chipRow
                ScrollView {
                    if choices.isEmpty {
                        Text(ShopL10n.text(.emptyFilter, store.language))
                            .font(ShopTheme.bodyFont())
                            .foregroundStyle(ShopTheme.ink.opacity(0.7))
                            .padding(24)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(choices) { item in
                                ShopItemCard(
                                    item: item,
                                    language: store.language,
                                    price: store.price(for: item),
                                    daily: store.isDaily(item),
                                    owned: store.owns(item.id),
                                    favorite: store.isFavorite(item.id),
                                    selected: item.id == selected?.id
                                ) {
                                    select(item)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
                bar
            }
            .background(ShopBackground())
            .overlay(alignment: .top) { ShopSparkles(tick: store.tradeTick).padding(.top, 24) }
            .overlay(alignment: .bottom) {
                if let toast {
                    ShopBanner(text: toast)
                        .padding(.bottom, 78)
                }
            }
            .onAppear { store.syncClock() }
            .onChange(of: context.date) { _, _ in store.syncClock() }
            .sensoryFeedback(.success, trigger: store.tradeTick)
        }
        .confirmationDialog(ShopL10n.text(.buyTitle, store.language), isPresented: $confirmBuy, titleVisibility: .visible) {
            Button(ShopL10n.text(.confirmBuy, store.language)) { buySelected() }
            Button(ShopL10n.text(.cancel, store.language), role: .cancel) {}
        } message: {
            if let selected {
                Text(ShopL10n.format(.buyQuestion, store.language, selected.name(store.language), ShopL10n.sparks(store.price(for: selected), store.language)))
            }
        }
        .confirmationDialog(ShopL10n.text(.sellTitle, store.language), isPresented: $confirmSell, titleVisibility: .visible) {
            Button(ShopL10n.text(.confirmSell, store.language), role: .destructive) { sellSelected() }
            Button(ShopL10n.text(.cancel, store.language), role: .cancel) {}
        } message: {
            if let selected {
                Text(ShopL10n.format(.sellQuestion, store.language, selected.name(store.language), ShopL10n.sparks(store.refund(for: selected), store.language)))
            }
        }
        .alert(ShopL10n.text(.notEnoughTitle, store.language), isPresented: $needFunds) {
            Button(ShopL10n.text(.done, store.language), role: .cancel) {}
        } message: {
            Text(ShopL10n.text(.notEnoughBody, store.language))
        }
        .sheet(isPresented: $showOutfits) {
            ShopOutfitLibrary()
        }
        .environment(\.locale, store.language.locale)
        .task(id: toast) {
            guard toast != nil else { return }
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            toast = nil
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ShopL10n.text(.wardrobeTitle, store.language))
                    .font(ShopTheme.titleFont())
                    .foregroundStyle(ShopTheme.ink)
                Text(ShopL10n.format(.piecesLine, store.language, store.state.ownedIDs.filter { ShopCatalog.byID[$0]?.anchor.isWear == true }.count))
                    .font(ShopTheme.captionFont())
                    .foregroundStyle(ShopTheme.ink.opacity(0.65))
            }
            Spacer()
            ShopBalancePill(amount: store.shownBalance, language: store.language)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShopAnchor.wearAnchors) { item in
                    ShopChip(
                        title: ShopL10n.anchor(item, store.language),
                        systemImage: nil,
                        selected: item == anchor
                    ) {
                        anchor = item
                        selectedID = nil
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var bar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let selected, !store.owns(selected.id) {
                    ShopActionButton(title: ShopL10n.text(.buy, store.language), systemImage: "bag", filled: true) {
                        if store.shownBalance < store.price(for: selected) {
                            needFunds = true
                        } else {
                            confirmBuy = true
                        }
                    }
                }
                if store.state.equipped[anchor.rawValue] != nil || store.state.previewWear[anchor.rawValue] != nil {
                    ShopActionButton(title: ShopL10n.text(.takeOff, store.language), systemImage: "xmark") {
                        store.clearWear(anchor)
                        toast = ShopL10n.text(.removedToast, store.language)
                    }
                }
                if store.state.previewWear != store.state.equipped {
                    ShopActionButton(title: ShopL10n.text(.endTryOn, store.language), systemImage: "arrow.uturn.backward") {
                        store.endWearTryOn()
                    }
                }
                if let selected, store.owns(selected.id) {
                    ShopActionButton(title: ShopL10n.text(.sell, store.language), systemImage: "arrow.uturn.backward") {
                        confirmSell = true
                    }
                    ShopActionButton(
                        title: ShopL10n.text(store.isFavorite(selected.id) ? .unfavorite : .favorite, store.language),
                        systemImage: store.isFavorite(selected.id) ? "heart.fill" : "heart"
                    ) {
                        store.toggleFavorite(id: selected.id)
                    }
                }
                ShopActionButton(title: ShopL10n.text(.outfits, store.language), systemImage: "square.stack", filled: true) {
                    showOutfits = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var choices: [ShopItem] {
        store.wardrobeChoices(for: anchor)
    }

    private var selected: ShopItem? {
        guard let selectedID else { return nil }
        return choices.first { $0.id == selectedID }
    }

    private var tryingUnowned: Bool {
        store.state.previewWear.values.contains { !store.owns($0) }
    }

    private func select(_ item: ShopItem) {
        selectedID = item.id
        if store.owns(item.id) {
            if store.use(id: item.id) != nil {
                toast = ShopL10n.text(.wornToast, store.language)
            }
        } else {
            store.tryOn(id: item.id)
            toast = ShopL10n.text(.tryOnBanner, store.language)
        }
    }

    private func buySelected() {
        guard let selected else { return }
        let result = store.buy(id: selected.id)
        if result == .success {
            _ = store.use(id: selected.id)
            toast = ShopL10n.text(.boughtToast, store.language)
        } else if result == .insufficientFunds {
            needFunds = true
        }
    }

    private func sellSelected() {
        guard let selected else { return }
        if store.sell(id: selected.id) == .success {
            toast = ShopL10n.text(.soldToast, store.language)
        }
    }
}

#Preview {
    ShopWardrobeScreen()
}
