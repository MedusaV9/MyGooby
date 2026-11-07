import SwiftUI

struct ShopFeatureScreen: View {
    @State private var store = ShopRoomStore.shared
    @State private var department: ShopDepartment = .wardrobe
    @State private var filter: ShopBrowserFilter = .all
    @State private var inspected: ShopItem?

    private let columns = [GridItem(.adaptive(minimum: 148), spacing: 12)]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 12) {
                header
                chipRow(ShopDepartment.allCases.map { department in
                    (
                        ShopL10n.department(department, store.language),
                        ShopL10n.symbol(for: department),
                        self.department == department,
                        { self.department = department }
                    )
                })
                chipRow(ShopBrowserFilter.allCases.map { item in
                    (
                        filterTitle(item),
                        nil,
                        filter == item,
                        { filter = item }
                    )
                })
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(ShopL10n.text(.todayHint, store.language))
                            .font(ShopTheme.bodyFont())
                            .foregroundStyle(ShopTheme.ink.opacity(0.75))
                        if department == .season {
                            Text(ShopL10n.format(.seasonNow, store.language, ShopL10n.season(store.currentSeason(), store.language)))
                                .font(ShopTheme.captionFont())
                                .foregroundStyle(ShopTheme.ink)
                        }
                        Text(ShopL10n.text(.todayHeading, store.language))
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(ShopTheme.ink)
                        if items.isEmpty {
                            Text(ShopL10n.text(.emptyFilter, store.language))
                                .font(ShopTheme.bodyFont())
                                .foregroundStyle(ShopTheme.ink.opacity(0.7))
                                .padding(.vertical, 24)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(items) { item in
                                    ShopItemCard(
                                        item: item,
                                        language: store.language,
                                        price: store.price(for: item),
                                        daily: store.isDaily(item),
                                        owned: store.owns(item.id),
                                        favorite: store.isFavorite(item.id)
                                    ) {
                                        inspected = item
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .background(ShopBackground())
            .overlay(alignment: .top) {
                ShopSparkles(tick: store.tradeTick)
                    .padding(.top, 28)
            }
            .onAppear { store.syncClock() }
            .onChange(of: context.date) { _, _ in store.syncClock() }
            .sensoryFeedback(.success, trigger: store.tradeTick)
        }
        .sheet(item: $inspected) { item in
            ShopPreviewSheet(item: item)
        }
        .environment(\.locale, store.language.locale)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ShopL10n.text(.shopTitle, store.language))
                    .font(ShopTheme.titleFont())
                    .foregroundStyle(ShopTheme.ink)
                Text(store.clock.formatted(date: .abbreviated, time: .omitted))
                    .font(ShopTheme.captionFont())
                    .foregroundStyle(ShopTheme.ink.opacity(0.65))
            }
            Spacer(minLength: 8)
            ShopBalancePill(amount: store.shownBalance, language: store.language)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var items: [ShopItem] {
        store.browserItems(department: department, filter: filter)
    }

    private func filterTitle(_ item: ShopBrowserFilter) -> String {
        switch item {
        case .all: return ShopL10n.text(.filterAll, store.language)
        case .today: return ShopL10n.text(.filterToday, store.language)
        case .owned: return ShopL10n.text(.filterOwned, store.language)
        case .favorites: return ShopL10n.text(.filterFavorites, store.language)
        }
    }

    private func chipRow(_ chips: [(String, String?, Bool, () -> Void)]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                    ShopChip(title: chip.0, systemImage: chip.1, selected: chip.2, action: chip.3)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    ShopFeatureScreen()
}
