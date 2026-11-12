import SwiftUI

/// Catalog of every shop item, and selling an owned item back.
/// The refund is `GoobyEngine.sellPrice`: half the catalog price, rounded down.
/// Stones land on `wallet.sparks`, the balance the shop already spends.

enum ShopLedgerPictures {
    case stage
    case glyph
}

private enum ShopOwnFilter: String, CaseIterable, Identifiable {
    case all, owned, missing

    var id: String { rawValue }

    func title(_ engine: GoobyEngine) -> String {
        switch self {
        case .all: return engine.t("shop.catalog.all")
        case .owned: return engine.t("shop.have")
        case .missing: return engine.t("shop.catalog.missing")
        }
    }
}

private struct ShopLedgerSection: Identifiable {
    var id: String
    var title: String
    var items: [ItemDef]
}

private struct ShopHoldings {
    var owned: Set<String>
    var equipped: Set<String>
}

@MainActor
private enum ShopLedgerList {
    static let shopOrder = ["wardrobe", "colors", "furniture", "travel", "seasonal"]

    static func holdings(engine: GoobyEngine, revision: Int) -> ShopHoldings {
        _ = engine.wallet.sparks
        _ = engine.animation
        _ = engine.celebration
        _ = revision
        let rows = engine.all(OwnedItem.self)
        return ShopHoldings(
            owned: Set(rows.map(\.catalogID)),
            equipped: Set(rows.filter { !$0.equippedSlot.isEmpty }.map(\.catalogID))
        )
    }

    static func sections(_ items: [ItemDef], engine: GoobyEngine) -> [ShopLedgerSection] {
        var grouped: [String: [ItemDef]] = [:]
        var seen: [String] = []
        for item in items {
            if grouped[item.shop] == nil { seen.append(item.shop) }
            grouped[item.shop, default: []].append(item)
        }
        let known = shopOrder.filter { grouped[$0] != nil }
        let rest = seen.filter { !shopOrder.contains($0) }
        return (known + rest).map { id in
            let key = "shop.\(id)"
            let named = engine.t(key)
            return ShopLedgerSection(id: id, title: named == key ? id : named, items: grouped[id] ?? [])
        }
    }
}

struct ShopLedgerPicture: View {
    var item: ItemDef
    var pictures: ShopLedgerPictures

    private var tinted: Bool {
        item.slot == "wall" || item.slot == "floor" || item.slot == "cushion"
    }

    var body: some View {
        switch pictures {
        case .stage:
            StageStill(name: StagePack.itemName(item.id))
                .colorMultiply(tinted ? Color(hexString: item.color) : .white)
        case .glyph:
            ShopItemGlyph(item: item)
        }
    }
}

struct ShopCatalogScreen<Detail: View>: View {
    var engine: GoobyEngine
    var paint: ShopFloorPaint
    var pictures: ShopLedgerPictures
    var still: Bool
    @ViewBuilder var detail: (ItemDef) -> Detail

    @Environment(\.dismiss) private var dismiss
    @State private var filter: ShopOwnFilter = .all
    @State private var query = ""

    var body: some View {
        let holdings = ShopLedgerList.holdings(engine: engine, revision: 0)
        let sections = ShopLedgerList.sections(visible(holdings), engine: engine)
        VStack(alignment: .leading, spacing: 0) {
            ledgerHead(holdings)
            ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if sections.isEmpty {
                    Text(engine.t("shop.catalog.empty"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(paint.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 36)
                } else {
                    ForEach(sections) { section in
                        Text(section.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(paint.ink)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.horizontal, 14)
                            .padding(.top, 18)
                            .padding(.bottom, 8)
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(section.items) { item in
                                NavigationLink {
                                    detail(item)
                                } label: {
                                    ShopCatalogCell(
                                        engine: engine,
                                        item: item,
                                        paint: paint,
                                        pictures: pictures,
                                        owned: holdings.owned.contains(item.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                }
            }
            .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(paint.sheet.ignoresSafeArea())
        .navigationTitle(engine.t("shop.catalog"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(paint.sheet, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(paint.lightStatus ? .dark : .light, for: .navigationBar)
        .toolbar {
            Button(engine.t("common.done")) { dismiss() }
                .foregroundStyle(paint.lightStatus ? Color.white : paint.ink)
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    private func ledgerHead(_ holdings: ShopHoldings) -> some View {
        let owned = engine.catalog.items.filter { holdings.owned.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 10) {
            ShopStonePill(
                count: engine.wallet.sparks,
                spoken: engine.tf("shop.balance", engine.wallet.sparks),
                still: still
            )
            Text(engine.tf("shop.catalog.count", owned, engine.catalog.items.count))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(paint.ink)
            HStack(spacing: 8) {
                ForEach(ShopOwnFilter.allCases) { choice in
                    let on = filter == choice
                    Button { filter = choice } label: {
                        Text(choice.title(engine))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(on ? (paint.lightStatus ? paint.sheet : paint.screen) : paint.ink)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(on ? (paint.lightStatus ? Color.white : paint.ink) : paint.cell, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .accessibilityHidden(true)
                TextField(engine.t("common.search"), text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .font(.system(size: 16, design: .rounded))
            .foregroundStyle(paint.ink)
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(paint.cell, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func visible(_ holdings: ShopHoldings) -> [ItemDef] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return engine.catalog.items.filter { item in
            switch filter {
            case .all: break
            case .owned: if !holdings.owned.contains(item.id) { return false }
            case .missing: if holdings.owned.contains(item.id) { return false }
            }
            if needle.isEmpty { return true }
            return item.name.de.localizedStandardContains(needle) || item.name.en.localizedStandardContains(needle)
        }
    }
}

private struct ShopCatalogCell: View {
    var engine: GoobyEngine
    var item: ItemDef
    var paint: ShopFloorPaint
    var pictures: ShopLedgerPictures
    var owned: Bool

    private var locked: Bool {
        !owned && !item.seasonalEvent.isEmpty && !engine.isEventActive(item.seasonalEvent)
    }

    var body: some View {
        VStack(spacing: 2) {
            ShopLedgerPicture(item: item, pictures: pictures)
                .frame(width: 72, height: 58)
                .opacity(locked ? 0.45 : 1)
                .padding(.top, 8)
            Text(item.name.text(engine.languageCode))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(paint.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
            HStack(spacing: 4) {
                if owned {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                    Text(engine.t("shop.have"))
                } else if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .heavy))
                    Text(engine.t("shop.locked"))
                } else {
                    ShopStoneGlyph()
                        .frame(width: 16, height: 16)
                    Text("\(engine.price(of: item))")
                }
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(paint.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(height: 22)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .frame(height: 128)
        .background(paint.cell, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: owned ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(owned ? Color(hex: 0x7DDE8A) : paint.ink.opacity(0.55))
                .padding(7)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessLabel)
        .accessibilityHint(item.blurb.text(engine.languageCode))
    }

    private var accessLabel: String {
        let name = item.name.text(engine.languageCode)
        if owned { return "\(name), \(engine.t("shop.have"))" }
        if locked { return "\(name), \(engine.t("shop.locked"))" }
        return "\(name), \(engine.tf("shop.balance", engine.price(of: item)))"
    }
}

struct ShopSellScreen<Detail: View>: View {
    var engine: GoobyEngine
    var paint: ShopFloorPaint
    var pictures: ShopLedgerPictures
    var still: Bool
    @ViewBuilder var detail: (ItemDef) -> Detail

    @Environment(\.dismiss) private var dismiss
    @State private var pending: ItemDef?
    @State private var confirm = false
    @State private var problem: String?
    @State private var credited: Int?
    @State private var revision = 0
    @State private var opened: ItemDef?

    var body: some View {
        let holdings = ShopLedgerList.holdings(engine: engine, revision: revision)
        let sections = ShopLedgerList.sections(forSale(holdings), engine: engine)
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                ShopStonePill(
                    count: engine.wallet.sparks,
                    spoken: engine.tf("shop.balance", engine.wallet.sparks),
                    still: still
                )
                Text(engine.t("shop.sell.hint"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(paint.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let credited {
                    Text(engine.tf("shop.sell.credited", credited))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(paint.lightStatus ? Color(hex: 0xFFE7AD) : paint.ink)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if sections.isEmpty {
                    Text(engine.t("shop.sell.empty"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(paint.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                } else {
                    ForEach(sections) { section in
                        Text(section.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(paint.ink)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(section.items) { item in
                            sellRow(item, equipped: holdings.equipped.contains(item.id))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(paint.sheet.ignoresSafeArea())
        .navigationTitle(engine.t("shop.sell"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(paint.sheet, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(paint.lightStatus ? .dark : .light, for: .navigationBar)
        .toolbar {
            Button(engine.t("common.done")) { dismiss() }
                .foregroundStyle(paint.lightStatus ? Color.white : paint.ink)
        }
        .navigationDestination(item: $opened) { item in
            detail(item)
        }
        .alert(
            engine.t("shop.confirmSell"),
            isPresented: $confirm,
            presenting: pending
        ) { item in
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.sell"), role: .destructive) { commitSell(item) }
        } message: { item in
            Text(engine.tf("shop.sell.amount", item.name.text(engine.languageCode), engine.sellPrice(of: item)))
        }
        .alert(engine.t("common.error"), isPresented: Binding(
            get: { problem != nil },
            set: { if !$0 { problem = nil } }
        )) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: {
            Text(problem ?? "")
        }
    }

    private func forSale(_ holdings: ShopHoldings) -> [ItemDef] {
        engine.catalog.items.filter { holdings.owned.contains($0.id) && !$0.starter }
    }

    private func sellRow(_ item: ItemDef, equipped: Bool) -> some View {
        let name = item.name.text(engine.languageCode)
        let refund = engine.sellPrice(of: item)
        return HStack(alignment: .center, spacing: 10) {
            Button { opened = item } label: {
                HStack(spacing: 10) {
                    ShopLedgerPicture(item: item, pictures: pictures)
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(paint.ink)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text(equipped ? engine.t("shop.equipped") : engine.tf("shop.sell.was", item.price))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(paint.ink.opacity(0.85))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(name), \(equipped ? engine.t("shop.equipped") : engine.tf("shop.sell.was", item.price))")
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    ShopStoneGlyph()
                        .frame(width: 18, height: 18)
                    Text("\(refund)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(paint.ink)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(engine.tf("shop.balance", refund))
                Button {
                    if equipped {
                        engine.unequip(slot: item.slot)
                        revision += 1
                    } else {
                        pending = item
                        confirm = true
                    }
                } label: {
                    Text(engine.t(equipped ? "common.unequip" : "common.sell"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(paint.lightStatus ? paint.sheet : Color.white)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 36)
                        .background(paint.lightStatus ? Color.white : paint.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(equipped ? engine.t("common.unequip") : engine.tf("shop.sell.amount", name, refund))
            }
        }
        .padding(10)
        .background(paint.cell, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func commitSell(_ item: ItemDef) {
        let refund = engine.sellPrice(of: item)
        pending = nil
        if let error = engine.sell(item) {
            problem = engine.t(error)
            return
        }
        credited = refund
        revision += 1
    }
}
