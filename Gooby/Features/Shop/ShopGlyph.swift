import SwiftUI

struct ShopGlyph: View {
    var item: ShopItem
    var language: ShopLanguage

    var body: some View {
        Group {
            if item.anchor.isWear {
                ShopBunnyView(worn: [item.anchor: item], animated: false, language: language)
                    .padding(4)
            } else {
                Canvas { context, size in
                    let inset = CGRect(origin: .zero, size: size).insetBy(dx: 10, dy: 10)
                    ShopRoomArtist.drawPiece(item, phase: .day, in: inset, context: &context)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct ShopPriceLabel: View {
    var catalogPrice: Int
    var price: Int
    var daily: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
            if daily && price != catalogPrice {
                Text("\(catalogPrice)")
                    .strikethrough()
                    .foregroundStyle(ShopTheme.ink.opacity(0.45))
            }
            Text("\(price)")
        }
        .font(ShopTheme.captionFont())
        .foregroundStyle(ShopTheme.ink)
    }
}

struct ShopItemCard: View {
    var item: ShopItem
    var language: ShopLanguage
    var price: Int
    var daily: Bool
    var owned: Bool
    var favorite: Bool
    var selected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    ShopGlyph(item: item, language: language)
                        .frame(maxWidth: .infinity)
                        .frame(height: 104)
                        .background(ShopTheme.cream, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    if daily {
                        Text(ShopL10n.text(.dailyBadge, language))
                            .font(ShopTheme.captionFont())
                            .foregroundStyle(ShopTheme.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ShopTheme.yellow, in: Capsule())
                            .padding(6)
                    }
                    if favorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(ShopTheme.pink)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .topTrailing)
                    }
                }
                Text(item.name(language))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(ShopTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                ShopRarityPill(rarity: item.rarity, language: language)
                HStack {
                    ShopPriceLabel(catalogPrice: item.price, price: price, daily: daily)
                    Spacer(minLength: 0)
                    if owned {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(shopHex: 0x7DCEA0))
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
            .background(ShopTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(selected ? ShopTheme.ink : ShopTheme.ink.opacity(0.06), lineWidth: selected ? 2 : 1)
            }
            .shadow(color: ShopTheme.ink.opacity(0.06), radius: 10, y: 6)
        }
        .buttonStyle(ShopPressStyle())
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [item.name(language), ShopL10n.rarity(item.rarity, language), ShopL10n.sparks(price, language)]
        if owned {
            parts.append(ShopL10n.text(.owned, language))
        }
        if daily {
            parts.append(ShopL10n.text(.dailyBadge, language))
        }
        return parts.joined(separator: ", ")
    }
}
