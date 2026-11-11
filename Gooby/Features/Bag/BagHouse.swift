import SwiftUI

enum BagHouseKind: Hashable {
    case outfits, furniture, colors

    var hintKey: String {
        switch self {
        case .outfits: "bag.shop.hint.outfits"
        case .furniture: "bag.shop.hint.furniture"
        case .colors: "bag.shop.hint.colors"
        }
    }

    var slotOrder: [String] {
        switch self {
        case .outfits:
            ["hat", "glasses", "bow", "shirt", "sweater", "jacket", "dress", "pants", "shoes", "scarf", "backpack", "accessory"]
        case .furniture:
            ["window", "bed", "rug", "lamp", "shelf", "picture", "plant", "sofa", "table", "cushion", "wall", "floor", "seasonal"]
        case .colors:
            ["fur"]
        }
    }

    func matches(_ item: ItemDef) -> Bool {
        switch self {
        case .outfits: item.shop == "wardrobe" || item.kind == "clothing"
        case .furniture: item.shop == "furniture" || item.kind == "furniture"
        case .colors: item.shop == "colors" || item.kind == "color"
        }
    }

    var stage: Color {
        switch self {
        case .outfits: Color(hex: 0xF6D56A)
        case .furniture: Color(hex: 0xD7F3EE)
        case .colors: Color(hex: 0xF7E3C4)
        }
    }
}

/// Closet and room editor. Placement lives here. Sleep stays with the home strand.
struct BagHouse: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var kind: BagHouseKind
    @State private var slot: String?
    @State private var favoritesOnly = false
    @State private var searching = false
    @State private var query = ""
    @State private var revision = 0
    @State private var loved: Bool
    @State private var heartScale: CGFloat = 1

    init(engine: GoobyEngine, reduceMotion: Bool, kind: BagHouseKind) {
        self.engine = engine
        self.reduceMotion = reduceMotion
        _kind = State(initialValue: kind)
        _loved = State(initialValue: BagHouseHeart.isOn())
    }

    private var still: Bool { reduceMotion || engine.reduceMotion }

    var body: some View {
        VStack(spacing: 0) {
            stage
            categoryBar
            if searching { searchField }
            shelf
            if kind != .colors { switcher }
        }
        .background(BagHouseColor.shelf.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var stage: some View {
        ZStack {
            kind.stage
            if kind == .furniture {
                BagRoomStage(engine: engine, reduceMotion: still)
            } else {
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: .idle,
                    reduceMotion: still,
                    companion: nil
                )
                .padding(.top, 28)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: kind == .furniture ? 300 : 268)
        .overlay(alignment: .topLeading) { closeButton.padding(12) }
        .overlay(alignment: .topTrailing) { shopButton.padding(12) }
        .overlay(alignment: .trailing) { sideControl.padding(.trailing, 16) }
        .animation(still ? nil : .easeOut(duration: 0.2), value: kind)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                chip(symbol: "magnifyingglass", label: engine.t("bag.house.search"), on: searching) {
                    searching.toggle()
                    if !searching { query = "" }
                }
                chip(symbol: favoritesOnly ? "heart.fill" : "heart", label: engine.t("bag.house.favorites"), on: favoritesOnly) {
                    favoritesOnly.toggle()
                    if favoritesOnly { slot = nil }
                }
                chip(symbol: "square.grid.2x2", label: engine.t("bag.house.all"), on: slot == nil && !favoritesOnly) {
                    slot = nil
                    favoritesOnly = false
                }
                ForEach(categorySlots, id: \.self) { name in
                    chip(symbol: BagSlotSymbol.name(name), label: engine.t("slot.\(name)"), on: slot == name) {
                        slot = slot == name ? nil : name
                        favoritesOnly = false
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(BagHouseColor.bar)
    }

    private var searchField: some View {
        TextField(engine.t("bag.house.searchPrompt"), text: $query)
            .font(.system(.body, design: .rounded))
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(BagHouseColor.bar)
            .accessibilityLabel(engine.t("bag.house.search"))
    }

    private var shelf: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if showBigHint {
                    bigHint
                } else {
                    hintRow
                    if filtered.isEmpty {
                        Text(engine.t("bag.house.emptyRow"))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Theme.ink.opacity(0.65))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 12)
                    } else {
                        grid
                    }
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BagHouseColor.shelf)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filtered) { item in
                cell(item)
            }
        }
        .id(revision)
    }

    private func cell(_ item: ItemDef) -> some View {
        let placed = isOn(item)
        let name = item.name.text(engine.languageCode)
        return Button {
            place(item)
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BagHouseColor.cell)
                BagItemMark(item: item)
                if placed {
                    BagPlacedMark()
                        .padding(6)
                        .transition(still ? .identity : .opacity)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityValue(placed ? placedWord : engine.t("bag.house.held"))
        .accessibilityHint(placed ? engine.t("bag.off") : actionWord)
        .accessibilityAddTraits(placed ? .isSelected : [])
    }

    private var switcher: some View {
        HStack(spacing: 8) {
            switchChip(.outfits)
            switchChip(.furniture)
        }
        .padding(8)
        .background(BagHouseColor.switcher.ignoresSafeArea(edges: .bottom))
    }

    private func switchChip(_ next: BagHouseKind) -> some View {
        let on = kind == next
        return Button {
            show(next)
        } label: {
            VStack(spacing: 2) {
                mark(next)
                    .frame(width: 36, height: 32)
                Text(title(next))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(BagColor.label)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(on ? BagHouseColor.switcherOn : Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title(next))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    @ViewBuilder
    private func mark(_ next: BagHouseKind) -> some View {
        switch next {
        case .outfits: BagOutfitsIcon()
        case .furniture: BagFurnitureIcon()
        case .colors: EmptyView()
        }
    }

    private func title(_ next: BagHouseKind) -> String {
        switch next {
        case .outfits: engine.t("bag.outfits")
        case .furniture: engine.t("bag.furniture")
        case .colors: engine.t("bag.colors")
        }
    }

    private var bigHint: some View {
        shopLink {
            VStack(spacing: 16) {
                hintMark.frame(width: 48, height: 48)
                Text(engine.t(kind.hintKey))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(BagColor.label)
                    .multilineTextAlignment(.center)
                Text(engine.t("bag.shop.visit"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(BagColor.label)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Theme.ink.opacity(0.06), radius: 8, y: 3)
            }
            .padding(.horizontal, 12)
            .padding(.top, 28)
            .accessibilityElement(children: .combine)
        }
    }

    private var hintRow: some View {
        shopLink {
            HStack(spacing: 10) {
                hintMark.frame(width: 36, height: 36)
                Text(engine.t(kind.hintKey))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(BagColor.label)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(BagColor.label.opacity(0.45))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityHint(engine.t("bag.shop.visit"))
        }
    }

    private func shopLink<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        NavigationLink {
            BagShopGate(engine: engine, reduceMotion: still)
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { engine.haptics.soft() })
    }

    @ViewBuilder private var hintMark: some View {
        switch kind {
        case .outfits: BagRainbowStone()
        case .furniture: BagHintFace()
        case .colors: BagColorDot()
        }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(BagColor.label.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.92), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(engine.t("common.close"))
    }

    private var shopButton: some View {
        shopLink {
            VStack(spacing: 1) {
                StageStill(name: "still-shop")
                    .frame(width: 26, height: 22)
                Text(engine.t("tab.shop"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(BagColor.label)
            .frame(width: 52, height: 44)
        }
        .accessibilityLabel(engine.t("bag.shop.visit"))
    }

    @ViewBuilder private var sideControl: some View {
        if kind == .furniture {
            Button(action: toggleLove) {
                Image(systemName: loved ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(loved ? Color(hex: 0xE989B0) : Color.white)
                    .shadow(color: Theme.ink.opacity(0.2), radius: 2, y: 1)
                    .scaleEffect(still ? 1 : heartScale)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("bag.house.heart"))
            .accessibilityValue(loved ? engine.t("bag.house.hearted") : engine.t("bag.off"))
        } else if kind == .outfits {
            Button { show(.furniture) } label: {
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xE07A3D))
                    .frame(width: 36, height: 36)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t("bag.furniture"))
        }
    }

    private func chip(symbol: String, label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BagColor.label.opacity(on ? 1 : 0.7))
                .frame(width: 36, height: 36)
                .background(on ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    }

    private var categorySlots: [String] {
        let present = Set(engine.catalog.items.filter { kind.matches($0) }.map(\.slot))
        return kind.slotOrder.filter { present.contains($0) }
    }

    private var owned: [ItemDef] {
        let order = kind.slotOrder
        let language = engine.languageCode
        var seen = Set<String>()
        let rows = engine.all(OwnedItem.self).compactMap { row -> ItemDef? in
            guard seen.insert(row.catalogID).inserted,
                  let item = engine.catalog.itemsByID[row.catalogID],
                  kind.matches(item) else { return nil }
            return item
        }
        return rows.sorted { lhs, rhs in
            let left = order.firstIndex(of: lhs.slot) ?? 99
            let right = order.firstIndex(of: rhs.slot) ?? 99
            if left != right { return left < right }
            return lhs.name.text(language) < rhs.name.text(language)
        }
    }

    private var filtered: [ItemDef] {
        _ = revision
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return owned.filter { item in
            if let slot, item.slot != slot { return false }
            if favoritesOnly, engine.ownedRow(item.id)?.favorite != true { return false }
            if !needle.isEmpty && !item.name.text(engine.languageCode).localizedCaseInsensitiveContains(needle) {
                return false
            }
            return true
        }
    }

    private var filtering: Bool {
        slot != nil || favoritesOnly || !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showBigHint: Bool { filtered.isEmpty && !filtering }

    private var placedWord: String {
        kind == .furniture ? engine.t("bag.house.placed") : engine.t("bag.house.worn")
    }

    private var actionWord: String {
        kind == .furniture ? engine.t("bag.placeItem") : engine.t("bag.wear")
    }

    private func isOn(_ item: ItemDef) -> Bool {
        if item.kind == "color" || item.slot == "fur" {
            return engine.pet.furStyle == item.id
        }
        if item.kind == "furniture" {
            return engine.roomItem(item.slot) == item.id
        }
        return engine.wornLook().slots[item.slot]?.id == item.id
    }

    private func place(_ item: ItemDef) {
        engine.haptics.soft()
        let apply = {
            if isOn(item) {
                if item.kind == "color" || item.slot == "fur" { return }
                engine.unequip(slot: item.slot)
            } else {
                engine.equip(item)
            }
            revision += 1
        }
        if still {
            apply()
        } else {
            withAnimation(.easeOut(duration: 0.2)) { apply() }
        }
    }

    private func show(_ next: BagHouseKind) {
        guard next != kind else { return }
        engine.haptics.soft()
        let apply = {
            kind = next
            slot = nil
            favoritesOnly = false
            searching = false
            query = ""
            revision += 1
        }
        if still {
            apply()
        } else {
            withAnimation(.easeOut(duration: 0.2)) { apply() }
        }
    }

    private func toggleLove() {
        engine.haptics.soft()
        loved.toggle()
        BagHouseHeart.set(loved)
        guard !still else {
            heartScale = 1
            return
        }
        heartScale = 1.16
        withAnimation(.easeOut(duration: 0.18)) { heartScale = 1 }
    }
}

/// Live room for placement. Sleep stays with the home strand.
/// This stage builds the birdhouse from the pack stills, with Gooby in the middle.
struct BagRoomStage: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            roomPiece("wall", fallback: "still-room-wall", fill: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            roomPiece("floor", fallback: "still-room-floor", fill: true)
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .frame(maxHeight: .infinity, alignment: .bottom)
            roomPiece("window", fallback: "still-room-window")
                .frame(width: 96, height: 96)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 16)
            HStack(alignment: .bottom, spacing: 6) {
                StageStill(name: "still-room-door")
                    .frame(width: 52, height: 92)
                roomPiece("bed", fallback: "still-room-nest")
                    .frame(width: 108, height: 72)
                roomPiece("shelf", fallback: "still-room-dresser")
                    .frame(width: 68, height: 78)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 34)
            roomPiece("rug", fallback: "still-room-rug")
                .frame(width: 150, height: 42)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 16)
            roomPiece("lamp", fallback: "still-room-lamp")
                .frame(width: 46, height: 72)
                .stageSway(amount: 2.2, seconds: 2.3, still: reduceMotion)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 14)
                .padding(.top, 20)
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: reduceMotion ? .idle : .breathe,
                reduceMotion: reduceMotion,
                companion: nil,
                showCompanion: false
            )
            .frame(height: 118)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 28)
        }
        .padding(8)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(engine.t("bag.house.room"))
    }

    private func roomPiece(_ slot: String, fallback: String, fill: Bool = false) -> some View {
        let equipped = engine.roomItem(slot)
        let named = equipped.isEmpty ? fallback : StagePack.itemName(equipped)
        let art = StagePack.image(named: named) == nil ? fallback : named
        let tinted = slot == "wall" || slot == "floor" || slot == "cushion"
        let color = engine.catalog.itemsByID[equipped]?.color ?? ""
        return StageStill(name: art, fill: fill)
            .colorMultiply(tinted && !color.isEmpty ? Color(hexString: color) : .white)
    }
}

struct BagShopGate: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        if let make = FeatureHost.shared.shopScreen {
            make(engine)
        } else {
            ShopScreen(engine: engine, reduceMotion: reduceMotion)
                .toolbar(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
        }
    }
}

private enum BagHouseHeart {
    static func isOn() -> Bool {
        guard let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(Bool.self, from: data) else { return false }
        return value
    }

    static func set(_ on: Bool) {
        guard let data = try? JSONEncoder().encode(on) else { return }
        try? data.write(to: url, options: .atomic)
        GoobyFiles.exclude(url)
    }

    private static var url: URL {
        GoobyFiles.supportDirectory().appendingPathComponent("bag-house-heart.json")
    }
}

private enum BagHouseColor {
    static let bar = Color(hex: 0xF4EFE4)
    static let shelf = Color(hex: 0xFBF6EC)
    static let cell = Color(hex: 0xF7F1E4)
    static let switcher = Color(hex: 0xE7C56B)
    static let switcherOn = Color(hex: 0xF8E7B0)
}

private enum BagSlotSymbol {
    static func name(_ slot: String) -> String {
        switch slot {
        case "hat": "crown"
        case "bow": "seal"
        case "glasses": "eyeglasses"
        case "shirt", "sweater", "jacket", "dress": "tshirt"
        case "pants": "rectangle.split.2x1"
        case "shoes": "shoeprints.fill"
        case "backpack": "backpack"
        case "scarf": "line.3.horizontal"
        case "accessory": "star"
        case "bed": "bed.double"
        case "rug": "oval.portrait"
        case "lamp": "lamp.desk"
        case "window": "macwindow"
        case "plant": "leaf"
        case "shelf": "books.vertical"
        case "picture": "photo"
        case "sofa": "sofa"
        case "table": "table.furniture"
        case "cushion": "square"
        case "seasonal": "sparkles"
        case "wall": "rectangle.split.3x1"
        case "floor": "square.fill"
        case "fur": "paintpalette"
        default: "square"
        }
    }
}

private struct BagItemMark: View {
    var item: ItemDef

    var body: some View {
        let color = Color(hexString: item.color)
        let name = StagePack.itemName(item.id)
        let tinted = item.slot == "wall" || item.slot == "floor" || item.slot == "cushion"
        if StagePack.image(named: name) != nil {
            StageStill(name: name)
                .colorMultiply(tinted ? color : .white)
                .frame(width: 52, height: 46)
        } else if item.slot == "wall" || item.slot == "floor" || item.slot == "fur" || item.kind == "color" {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 40, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hexString: item.color2), lineWidth: 3)
                )
        } else if item.kind == "furniture" {
            FurnitureGlyph(slot: item.slot, color: color, wide: item.slot == "rug")
                .frame(width: 52, height: 46)
        } else {
            Image(systemName: BagSlotSymbol.name(item.slot))
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(color)
        }
    }
}

private struct BagPlacedMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 16, height: 16)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: 0x6F62F0))
        }
        .accessibilityHidden(true)
    }
}

private struct BagRainbowStone: View {
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        StageClip(name: "clip-stone", reduceMotion: reduce)
            .accessibilityHidden(true)
    }
}

private struct BagHintFace: View {
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var bob = false

    var body: some View {
        StageStill(name: "still-robin")
            .offset(y: !reduce && bob ? -3 : 0)
            .onAppear {
                guard !reduce else { return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { bob = true }
            }
            .accessibilityHidden(true)
    }
}

private struct BagColorDot: View {
    var body: some View {
        Circle()
            .fill(Color(hex: 0xF4ECFF))
            .overlay(Circle().fill(Color(hex: 0xC7B0FF)).frame(width: 14, height: 14))
            .accessibilityHidden(true)
    }
}
