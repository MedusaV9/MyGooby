import SwiftUI

struct BagDestination: View {
    var route: BagRoute
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        switch route {
        case .mail:
            BagMailList(engine: engine)
        case .outfits:
            BagCloset(engine: engine, reduceMotion: reduceMotion, kind: .outfits)
        case .furniture:
            BagCloset(engine: engine, reduceMotion: reduceMotion, kind: .furniture)
        case .colors:
            BagCloset(engine: engine, reduceMotion: reduceMotion, kind: .colors)
        case .micropets:
            BagMicropets(engine: engine, reduceMotion: reduceMotion)
        case .settings:
            SettingsView(engine: engine)
        case .place(let id):
            if let place = engine.catalog.placesByID[id] {
                PlaceDetail(engine: engine, place: place, reduceMotion: reduceMotion)
            } else {
                EmptyView()
            }
        case .letter(let id):
            if let letter = BagMail.letters(engine).first(where: { $0.id == id }) {
                BagLetterPage(engine: engine, letter: letter)
            } else {
                EmptyView()
            }
        }
    }
}

private struct BagMailList: View {
    var engine: GoobyEngine

    var body: some View {
        let letters = BagMail.letters(engine)
        ScrollView {
            VStack(spacing: 12) {
                ForEach(letters) { letter in
                    NavigationLink(value: BagRoute.letter(letter.id)) {
                        HStack(alignment: .top, spacing: 12) {
                            BagMailbox().frame(width: 42, height: 36)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(letter.title)
                                        .font(.system(.headline, design: .rounded))
                                    Spacer()
                                    if !BagMail.isRead(letter.id) {
                                        Text(engine.t("bag.mail.new"))
                                            .font(.system(.caption2, design: .rounded).weight(.bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(BagColor.colorsTile, in: Capsule())
                                            .foregroundStyle(.white)
                                    }
                                }
                                Text(letter.body)
                                    .font(.system(.subheadline, design: .rounded))
                                    .lineLimit(2)
                                    .foregroundStyle(Theme.ink.opacity(0.7))
                                Text(engine.formatDate(letter.date))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(Theme.ink.opacity(0.55))
                            }
                        }
                        .foregroundStyle(Theme.ink)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(BagColor.stage.opacity(0.35).ignoresSafeArea())
        .navigationTitle(engine.t("bag.mail"))
    }
}

private struct BagLetterPage: View {
    var engine: GoobyEngine
    var letter: BagLetter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(letter.title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(engine.formatDate(letter.date, time: true))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                Text(letter.body)
                    .font(.system(.body, design: .rounded))
            }
            .foregroundStyle(Theme.ink)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(engine.t("bag.mail"))
        .onAppear { BagMail.markRead(letter.id) }
    }
}

private enum BagClosetKind {
    case outfits, furniture, colors

    func matches(_ item: ItemDef) -> Bool {
        switch self {
        case .outfits: return item.shop == "wardrobe" || item.kind == "clothing"
        case .furniture: return item.shop == "furniture" || item.kind == "furniture"
        case .colors: return item.shop == "colors" || item.kind == "color"
        }
    }
}

private struct BagCloset: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var kind: BagClosetKind
    @State private var pending: String?
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                hint
                preview
                if kind == .outfits {
                    Button(engine.t("wardrobe.save")) { engine.saveOutfit(name: engine.t("wardrobe.outfit")) }
                        .buttonStyle(GoobyButtonStyle(fill: BagColor.plaque, ink: BagColor.plaqueInk))
                }
                ForEach(items) { item in
                    row(item)
                }
            }
            .padding(16)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(title)
        .alert(engine.t("shop.confirmBuy"), isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) {
            Button(engine.t("common.ok")) { confirmBuy() }
            Button(engine.t("common.close"), role: .cancel) { pending = nil }
        }
        .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private var title: String {
        switch kind {
        case .outfits: engine.t("bag.outfits")
        case .furniture: engine.t("bag.furniture")
        case .colors: engine.t("bag.colors")
        }
    }

    private var hint: some View {
        Text(engine.t(hintKey))
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(Theme.ink.opacity(0.75))
    }

    private var hintKey: String {
        switch kind {
        case .outfits: "bag.outfits.hint"
        case .furniture: "bag.furniture.hint"
        case .colors: "bag.colors.hint"
        }
    }

    @ViewBuilder private var preview: some View {
        if kind == .furniture {
            RoomDiorama(engine: engine, reduceMotion: reduceMotion)
                .frame(height: 240)
        } else {
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: .present,
                reduceMotion: reduceMotion,
                companion: nil
            )
            .frame(height: 220)
            .frame(maxWidth: .infinity)
        }
    }

    private var items: [ItemDef] {
        engine.catalog.items.filter { item in
            kind.matches(item) && (item.seasonalEvent.isEmpty || engine.isEventActive(item.seasonalEvent))
        }
    }

    private func row(_ item: ItemDef) -> some View {
        let owned = engine.owns(item.id)
        let worn = isOn(item)
        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hexString: item.color))
                .frame(width: 54, height: 54)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(hexString: item.color2), lineWidth: 3))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.text(engine.languageCode))
                    .font(.system(.headline, design: .rounded))
                Text(item.blurb.text(engine.languageCode))
                    .font(.system(.caption, design: .rounded))
                    .lineLimit(2)
                Text(owned ? engine.t("common.owned") : engine.tf("shop.price", engine.price(of: item)))
                    .font(.system(.caption, design: .rounded).weight(.bold))
            }
            .foregroundStyle(Theme.ink)
            Spacer()
            Button(actionTitle(item, owned: owned, worn: worn)) {
                if worn {
                    engine.unequip(slot: item.slot == "fur" || item.kind == "color" ? "fur" : item.slot)
                } else if owned {
                    engine.equip(item)
                } else {
                    pending = item.id
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func actionTitle(_ item: ItemDef, owned: Bool, worn: Bool) -> String {
        if worn { return engine.t("bag.off") }
        if owned { return kind == .furniture ? engine.t("bag.placeItem") : engine.t("bag.wear") }
        return engine.tf("shop.buyFor", engine.price(of: item))
    }

    private func confirmBuy() {
        guard let pending, let item = engine.catalog.itemsByID[pending] else { return }
        self.pending = nil
        if let error = engine.buy(item) {
            message = engine.t(error)
        } else {
            engine.equip(item)
        }
    }

    private func isOn(_ item: ItemDef) -> Bool {
        if item.kind == "color" || item.slot == "fur" {
            return engine.pet.furStyle == item.id
        }
        return engine.wornLook().slots[item.slot]?.id == item.id
    }
}

private struct BagMicropets: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        let friends = engine.all(MiniFriend.self).sorted { $0.hatchedAt > $1.hatchedAt }
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if friends.isEmpty {
                    Text(engine.t("bag.micropets.empty"))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                ForEach(friends) { friend in
                    HStack(spacing: 12) {
                        MiniFriendBadge(species: friend.speciesID)
                            .frame(width: 54, height: 54)
                        VStack(alignment: .leading) {
                            Text(friend.givenName)
                                .font(.system(.headline, design: .rounded))
                            Text(engine.t("rarity.\(friend.rarity)"))
                                .font(.system(.caption, design: .rounded))
                        }
                        Spacer()
                        if friend.isCompanion {
                            Text(engine.t("friends.with"))
                        } else {
                            Button(engine.t("friends.choose")) { engine.setCompanion(friend) }
                                .buttonStyle(.bordered)
                        }
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: .play,
                    reduceMotion: reduceMotion,
                    companion: engine.companionSpecies()
                )
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(engine.t("bag.micropets"))
    }
}
