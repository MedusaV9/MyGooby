import SwiftUI

struct ShopRoomScreen: View {
    @State private var store = ShopRoomStore.shared
    @State private var anchor: ShopAnchor = .bed
    @State private var selectedID: String?
    @State private var confirmBuy = false
    @State private var confirmSell = false
    @State private var needFunds = false
    @State private var showDesigns = false
    @State private var toast: String?

    private let columns = [GridItem(.adaptive(minimum: 148), spacing: 12)]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 10) {
                header
                ShopRoomCanvas(
                    placements: shownRoom,
                    worn: store.resolved(store.state.equipped),
                    phase: store.resolvedPhase(),
                    highlighted: anchor,
                    showsBunny: true,
                    animatedBunny: true,
                    language: store.language
                )
                .padding(.horizontal, 16)
                .frame(maxHeight: 380)
                Text(lightCaption)
                    .font(ShopTheme.captionFont())
                    .foregroundStyle(ShopTheme.ink.opacity(0.75))
                    .padding(.horizontal, 16)
                lightRow
                Text(ShopL10n.text(.roomHint, store.language))
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
        .sheet(isPresented: $showDesigns) {
            ShopDesignLibrary()
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
            Text(ShopL10n.text(.roomTitle, store.language))
                .font(ShopTheme.titleFont())
                .foregroundStyle(ShopTheme.ink)
            Spacer()
            ShopBalancePill(amount: store.shownBalance, language: store.language)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var lightRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShopDaylight.allCases) { mode in
                    ShopChip(
                        title: ShopL10n.daylight(mode, store.language),
                        systemImage: ShopL10n.symbol(for: mode),
                        selected: store.lightingMode() == mode
                    ) {
                        store.setLighting(mode)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShopAnchor.roomAnchors) { item in
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
                if store.state.placements[anchor.rawValue] != nil || store.state.previewRoom[anchor.rawValue] != nil {
                    ShopActionButton(title: ShopL10n.text(.clearSlot, store.language), systemImage: "xmark") {
                        store.clearRoom(anchor)
                        toast = ShopL10n.text(.removedToast, store.language)
                    }
                }
                if !store.state.previewRoom.isEmpty {
                    ShopActionButton(title: ShopL10n.text(.endTryOn, store.language), systemImage: "arrow.uturn.backward") {
                        store.clearRoomPreview()
                    }
                }
                if let selected, store.owns(selected.id) {
                    ShopActionButton(title: ShopL10n.text(.sell, store.language), systemImage: "arrow.uturn.backward") {
                        confirmSell = true
                    }
                }
                ShopActionButton(title: ShopL10n.text(.designs, store.language), systemImage: "square.stack", filled: true) {
                    showDesigns = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var choices: [ShopItem] {
        store.roomChoices(for: anchor)
    }

    private var selected: ShopItem? {
        guard let selectedID else { return nil }
        return choices.first { $0.id == selectedID }
    }

    private var shownRoom: [ShopAnchor: ShopItem] {
        var map = store.resolved(store.state.placements)
        for (key, item) in store.resolved(store.state.previewRoom) {
            map[key] = item
        }
        return map
    }

    private var lightCaption: String {
        let mode = store.lightingMode()
        let resolved = store.resolvedPhase()
        if mode == .auto {
            return ShopL10n.format(
                .lightLine,
                store.language,
                ShopL10n.daylight(.auto, store.language),
                ShopL10n.daylight(resolved, store.language)
            )
        }
        return ShopL10n.daylightCaption(resolved, store.language)
    }

    private func select(_ item: ShopItem) {
        selectedID = item.id
        if store.owns(item.id) {
            if store.use(id: item.id) != nil {
                toast = ShopL10n.text(.placedToast, store.language)
            }
        } else {
            store.tryOn(id: item.id)
            toast = ShopL10n.text(.previewBanner, store.language)
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
    ShopRoomScreen()
}
