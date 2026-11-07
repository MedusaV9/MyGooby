import SwiftUI

struct ShopPreviewSheet: View {
    var item: ShopItem

    @Environment(\.dismiss) private var dismiss
    @State private var store = ShopRoomStore.shared
    @State private var confirmBuy = false
    @State private var confirmSell = false
    @State private var needFunds = false
    @State private var toast: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ShopGlyph(item: item, language: store.language)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(ShopTheme.cream, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                Text(item.name(store.language))
                    .font(ShopTheme.titleFont())
                    .foregroundStyle(ShopTheme.ink)
                Text(item.blurb(store.language))
                    .font(ShopTheme.bodyFont())
                    .foregroundStyle(ShopTheme.ink.opacity(0.82))
                HStack(spacing: 8) {
                    ShopRarityPill(rarity: item.rarity, language: store.language)
                    Text(ShopL10n.anchor(item.anchor, store.language))
                        .font(ShopTheme.captionFont())
                        .foregroundStyle(ShopTheme.ink.opacity(0.7))
                    if let season = item.season {
                        Text(ShopL10n.season(season, store.language))
                            .font(ShopTheme.captionFont())
                            .foregroundStyle(ShopTheme.ink.opacity(0.7))
                    }
                }
                ShopPriceLabel(
                    catalogPrice: item.price,
                    price: store.price(for: item),
                    daily: store.isDaily(item)
                )
                if store.owns(item.id) {
                    Text(ShopL10n.text(.owned, store.language))
                        .font(ShopTheme.captionFont())
                        .foregroundStyle(ShopTheme.ink)
                    Text(ShopL10n.sparks(store.refund(for: item), store.language))
                        .font(ShopTheme.captionFont())
                        .foregroundStyle(ShopTheme.ink.opacity(0.7))
                }
                statusLine
                actionRow
            }
            .padding(20)
        }
        .background(ShopBackground())
        .overlay(alignment: .bottom) {
            if let toast {
                ShopBanner(text: toast)
                    .padding(.bottom, 16)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .confirmationDialog(ShopL10n.text(.buyTitle, store.language), isPresented: $confirmBuy, titleVisibility: .visible) {
            Button(ShopL10n.text(.confirmBuy, store.language)) { performBuy() }
            Button(ShopL10n.text(.cancel, store.language), role: .cancel) {}
        } message: {
            Text(question(.buyQuestion, store.price(for: item)))
        }
        .confirmationDialog(ShopL10n.text(.sellTitle, store.language), isPresented: $confirmSell, titleVisibility: .visible) {
            Button(ShopL10n.text(.confirmSell, store.language), role: .destructive) { performSell() }
            Button(ShopL10n.text(.cancel, store.language), role: .cancel) {}
        } message: {
            Text(question(.sellQuestion, store.refund(for: item)))
        }
        .alert(ShopL10n.text(.notEnoughTitle, store.language), isPresented: $needFunds) {
            Button(ShopL10n.text(.done, store.language), role: .cancel) {}
        } message: {
            Text(ShopL10n.text(.notEnoughBody, store.language))
        }
        .task(id: toast) {
            guard toast != nil else { return }
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            toast = nil
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if store.state.equipped[item.anchor.rawValue] == item.id {
            Text(ShopL10n.text(.wearingNow, store.language))
                .font(ShopTheme.captionFont())
                .foregroundStyle(ShopTheme.ink)
        } else if store.state.placements[item.anchor.rawValue] == item.id {
            Text(ShopL10n.text(.placedNow, store.language))
                .font(ShopTheme.captionFont())
                .foregroundStyle(ShopTheme.ink)
        } else if item.destinationID != nil && store.activeDestinationID() == item.destinationID {
            Text(ShopL10n.text(.chosenTrip, store.language))
                .font(ShopTheme.captionFont())
                .foregroundStyle(ShopTheme.ink)
        }
    }

    private var actionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !store.owns(item.id) {
                    ShopActionButton(title: ShopL10n.text(.buy, store.language), systemImage: "bag", filled: true) {
                        if store.shownBalance < store.price(for: item) {
                            needFunds = true
                        } else {
                            confirmBuy = true
                        }
                    }
                }
                if item.anchor.isWear || item.anchor.isRoom {
                    ShopActionButton(title: ShopL10n.text(.tryOn, store.language), systemImage: "eye") {
                        store.tryOn(id: item.id)
                        toast = ShopL10n.text(.tryOnBanner, store.language)
                    }
                }
                if store.owns(item.id) {
                    ShopActionButton(title: useTitle, systemImage: "checkmark", filled: true) {
                        if store.use(id: item.id) != nil {
                            toast = useToast
                        }
                    }
                    ShopActionButton(title: ShopL10n.text(.sell, store.language), systemImage: "arrow.uturn.backward") {
                        confirmSell = true
                    }
                }
                ShopActionButton(
                    title: ShopL10n.text(store.isFavorite(item.id) ? .unfavorite : .favorite, store.language),
                    systemImage: store.isFavorite(item.id) ? "heart.fill" : "heart"
                ) {
                    store.toggleFavorite(id: item.id)
                }
            }
        }
    }

    private var useTitle: String {
        if item.anchor.isWear { return ShopL10n.text(.wear, store.language) }
        if item.anchor.isRoom { return ShopL10n.text(.use, store.language) }
        return ShopL10n.text(.setDestination, store.language)
    }

    private var useToast: String {
        if item.anchor.isWear { return ShopL10n.text(.wornToast, store.language) }
        if item.anchor.isRoom { return ShopL10n.text(.placedToast, store.language) }
        return ShopL10n.text(.tripToast, store.language)
    }

    private func question(_ key: ShopL10n.Key, _ amount: Int) -> String {
        ShopL10n.format(key, store.language, item.name(store.language), ShopL10n.sparks(amount, store.language))
    }

    private func performBuy() {
        let result = store.buy(id: item.id)
        if result == .success {
            toast = ShopL10n.text(.boughtToast, store.language)
        } else if result == .insufficientFunds {
            needFunds = true
        }
    }

    private func performSell() {
        if store.sell(id: item.id) == .success {
            toast = ShopL10n.text(.soldToast, store.language)
        }
    }
}
