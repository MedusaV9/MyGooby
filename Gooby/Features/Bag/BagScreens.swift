import SwiftUI

/// Mail: welcome letters from the friends Gooby met and one letter per visit, newest first.
struct BagMailScreen: View {
    var engine: GoobyEngine

    var body: some View {
        let letters = engine.socialLetters()
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                if letters.isEmpty {
                    GCard {
                        Text(engine.tx("social.mail.none", de: "Noch keine Briefe. Besuch einen Freund im Freunde-Tab!", en: "No letters yet. Visit a friend on the friends tab!"))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.greyText)
                    }
                } else {
                    ForEach(letters) { letter in
                        letterCard(letter)
                    }
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.vertical, Theme.Space.gap)
        }
        .goobyScreen(Theme.Tab.bag.sheet)
        .navigationTitle(engine.tx("social.bag.mail", de: "Post", en: "Mail"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func letterCard(_ letter: SocialLetter) -> some View {
        let npc = SocialNPC.find(letter.npcID)
        return GCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    IconTile(color: Color(hex: npc?.color ?? 0xF47B4F), size: 48, radius: 14) {
                        SocialNPCHead(species: npc?.species ?? "bear", size: 42)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: npc?.name ?? "")
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                        Text(letter.welcome
                             ? engine.tx("social.mail.welcome", de: "Willkommensbrief", en: "Welcome letter")
                             : engine.tx("social.mail.visit", de: "Erinnerung an euren Besuch", en: "A visit to remember"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.greyText)
                    }
                    Spacer(minLength: 0)
                    GoobyIcon(letter.welcome ? "💌" : "✉️", size: 28)
                }
                Text(letter.text)
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.text.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                Text(engine.formatDate(letter.date))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.greyText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Outfits: Gooby in the current look, saving and applying outfits with favorites, and every
/// owned piece of clothing (tap to wear, take off, favorite or sell on the item page).
struct BagOutfitsScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        let outfits = engine.all(SavedOutfit.self).sorted { lhs, rhs in
            if lhs.favorite != rhs.favorite { return lhs.favorite }
            return lhs.createdAt > rhs.createdAt
        }
        let clothes = ownedClothes
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                GCard {
                    VStack(spacing: 12) {
                        GoobyCharacterView(
                            look: engine.wornLook(),
                            stage: Growth.stage(of: engine.pet),
                            animation: .present,
                            reduceMotion: reduceMotion,
                            companion: nil
                        )
                        .frame(height: 220)
                        Button {
                            engine.saveOutfit(name: engine.txf("social.outfit.name", de: "Outfit %d", en: "Outfit %d", outfits.count + 1))
                        } label: {
                            HStack(spacing: 6) {
                                GoobyIcon("👗", size: 22)
                                Text(engine.t("wardrobe.save"))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.quests.purple, edge: nil, radius: 18, vertical: 12, expand: true))
                    }
                }
                if !outfits.isEmpty {
                    SectionCaps(engine.tx("social.outfits.saved", de: "Gespeicherte Outfits", en: "Saved outfits"), color: Color.white.opacity(0.95))
                        .padding(.top, 4)
                    GCard(padding: 0) {
                        VStack(spacing: 0) {
                            ForEach(Array(outfits.enumerated()), id: \.element.id) { index, outfit in
                                if index > 0 {
                                    Rectangle().fill(Theme.line).frame(height: 1).padding(.leading, 56)
                                }
                                outfitRow(outfit)
                            }
                        }
                    }
                }
                SectionCaps(engine.tx("social.outfits.clothes", de: "Deine Kleidung", en: "Your clothes"), color: Color.white.opacity(0.95))
                    .padding(.top, 4)
                if clothes.isEmpty {
                    GCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(engine.tx("social.outfits.none", de: "Noch keine Kleidung. Im Kleiderschrank-Shop findest du Hüte, Schleifen und mehr.", en: "No clothes yet. The wardrobe shop has hats, bows and more."))
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.greyText)
                                .fixedSize(horizontal: false, vertical: true)
                            NavigationLink {
                                ShopScreen(engine: engine, reduceMotion: reduceMotion, initialShop: "wardrobe")
                            } label: {
                                Text(engine.tx("social.outfits.shop", de: "Zum Kleiderschrank", en: "Go to the wardrobe"))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.shop.accent, edge: nil, radius: 16, vertical: 12, expand: true))
                        }
                    }
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(clothes) { item in
                            NavigationLink {
                                ItemDetail(engine: engine, item: item, reduceMotion: reduceMotion)
                            } label: {
                                clothesTile(item)
                            }
                            .buttonStyle(ShopPressStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.vertical, Theme.Space.gap)
        }
        .goobyScreen(Theme.Tab.bag.sheet)
        .navigationTitle(engine.tx("social.bag.outfits", de: "Outfits", en: "Outfits"))
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Owned clothing, favorites first, then by slot.
    private var ownedClothes: [ItemDef] {
        let rows = engine.all(OwnedItem.self)
        let favorites = Set(rows.filter(\.favorite).map(\.catalogID))
        let items = rows.compactMap { engine.catalog.itemsByID[$0.catalogID] }.filter { $0.kind == "clothing" }
        return items.sorted { lhs, rhs in
            let left = favorites.contains(lhs.id)
            let right = favorites.contains(rhs.id)
            if left != right { return left }
            if lhs.slot != rhs.slot { return lhs.slot < rhs.slot }
            return lhs.id < rhs.id
        }
    }

    private func outfitRow(_ outfit: SavedOutfit) -> some View {
        HStack(spacing: 12) {
            Button {
                engine.toggleFavoriteOutfit(outfit)
            } label: {
                Image(systemName: outfit.favorite ? "star.fill" : "star")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(outfit.favorite ? Theme.progressFill : Theme.greyText)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(engine.t(outfit.favorite ? "shop.unfavorite" : "common.favorite"))
            Text(outfit.name)
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.text)
                .lineLimit(1)
            Spacer(minLength: 0)
            Button(engine.t("common.equip")) { engine.apply(outfit: outfit) }
                .buttonStyle(Press3DButtonStyle(radius: 14, horizontal: 14, vertical: 8))
                .foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func clothesTile(_ item: ItemDef) -> some View {
        let row = engine.ownedRow(item.id)
        let worn = row?.equippedSlot.isEmpty == false
        return VStack(spacing: 6) {
            ShopItemArt(engine: engine, item: item, height: 84)
                .overlay(alignment: .topTrailing) {
                    if worn {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.checkGreen)
                            .background(Color.white, in: Circle())
                            .padding(5)
                    }
                }
                .overlay(alignment: .topLeading) {
                    if row?.favorite == true {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.progressFill)
                            .padding(6)
                    }
                }
            Text(item.name.text(engine.languageCode))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.text)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
        .cardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityValue(worn ? engine.tx("social.outfits.worn", de: "Angezogen", en: "Wearing") : "")
    }
}

/// Fur colors Gooby owns: tap one to change Gooby's coat; more colors are in the shop.
struct BagColorsScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    var body: some View {
        let colors = engine.all(OwnedItem.self)
            .compactMap { engine.catalog.itemsByID[$0.catalogID] }
            .filter { $0.kind == "color" }
            .sorted { lhs, rhs in
                if lhs.starter != rhs.starter { return lhs.starter }
                return lhs.id < rhs.id
            }
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                GCard {
                    GoobyCharacterView(
                        look: engine.wornLook(),
                        stage: Growth.stage(of: engine.pet),
                        animation: .present,
                        reduceMotion: reduceMotion,
                        companion: nil
                    )
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(colors) { item in
                        Button {
                            engine.equip(item)
                        } label: {
                            colorTile(item)
                        }
                        .buttonStyle(ShopPressStyle())
                    }
                }
                NavigationLink {
                    ShopScreen(engine: engine, reduceMotion: reduceMotion, initialShop: "colors")
                } label: {
                    HStack(spacing: 6) {
                        GoobyIcon("🎨", size: 22)
                        Text(engine.tx("social.colors.shop", de: "Mehr Farben im Shop", en: "More colors in the shop"))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.shop.accent, edge: nil, radius: 18, vertical: 12, expand: true))
                .padding(.top, 4)
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.vertical, Theme.Space.gap)
        }
        .goobyScreen(Theme.Tab.bag.sheet)
        .navigationTitle(engine.tx("social.bag.colors", de: "Farben", en: "Colors"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func colorTile(_ item: ItemDef) -> some View {
        let current = engine.pet.furStyle == item.id
        return VStack(spacing: 6) {
            GoobyAvatar(look: WornLook(fur: item.id, slots: [:]), stage: Growth.stage(of: engine.pet), size: 64)
                .frame(width: 76, height: 76)
                .background(Color(hexString: item.color).opacity(0.35), in: Circle())
            Text(item.name.text(engine.languageCode))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.text)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                .stroke(current ? Theme.checkGreen : Color.clear, lineWidth: 3)
        )
        .overlay(alignment: .topTrailing) {
            if current {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.checkGreen)
                    .padding(6)
            }
        }
        .cardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(current ? .isSelected : [])
    }
}
