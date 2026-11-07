import SwiftUI

struct ShopRoomCanvas: View {
    var placements: [ShopAnchor: ShopItem]
    var worn: [ShopAnchor: ShopItem]
    var phase: ShopDaylight
    var highlighted: ShopAnchor?
    var showsBunny: Bool = true
    var animatedBunny: Bool = true
    var language: ShopLanguage = .de

    var body: some View {
        Color.clear
            .aspectRatio(ShopRoomLayout.design.width / ShopRoomLayout.design.height, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let bunny = ShopRoomLayout.viewRect(ShopRoomLayout.bunny, in: geo.size)
                    ZStack {
                        Canvas { context, size in
                            ShopRoomArtist.draw(
                                context: &context,
                                size: size,
                                placements: placements,
                                phase: phase,
                                highlighted: highlighted
                            )
                        }
                        lightOverlay
                            .allowsHitTesting(false)
                        if showsBunny {
                            ShopBunnyView(worn: worn, animated: animatedBunny, language: language)
                                .frame(width: max(44, bunny.width), height: max(44, bunny.height))
                                .position(x: bunny.midX, y: bunny.midY)
                                .overlay {
                                    bunnyTint
                                        .allowsHitTesting(false)
                                        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                                }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(ShopTheme.ink.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: ShopTheme.ink.opacity(0.08), radius: 16, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            ShopL10n.format(
                .roomPortrait,
                language,
                ShopL10n.daylight(resolved, language)
            )
        )
    }

    private var resolved: ShopDaylight {
        phase == .auto ? .day : phase
    }

    private var lightOverlay: some View {
        let lamp = ShopRoomLayout.lamp
        let lampPoint = UnitPoint(
            x: lamp.midX / ShopRoomLayout.design.width,
            y: lamp.midY / ShopRoomLayout.design.height
        )
        return ZStack {
            LinearGradient(colors: overlayColors, startPoint: .top, endPoint: .bottom)
                .opacity(overlayOpacity)
            if placements[.lamp] != nil && (resolved == .night || resolved == .evening) {
                RadialGradient(
                    colors: [Color(shopHex: 0xFFE7AD).opacity(resolved == .night ? 0.55 : 0.35), .clear],
                    center: lampPoint,
                    startRadius: 4,
                    endRadius: 180
                )
            }
        }
    }

    private var overlayColors: [Color] {
        switch resolved {
        case .morning:
            return [Color(shopHex: 0xFFE7AD), Color(shopHex: 0xFFF8EF).opacity(0.2)]
        case .day, .auto:
            return [Color.white.opacity(0.2), Color.white.opacity(0.05)]
        case .evening:
            return [Color(shopHex: 0xFFB088), Color(shopHex: 0xD3C2FF).opacity(0.35)]
        case .night:
            return [Color(shopHex: 0x241C3C), Color(shopHex: 0x3D3656).opacity(0.2)]
        }
    }

    private var bunnyTint: some View {
        let color: Color
        let amount: Double
        switch resolved {
        case .morning:
            color = Color(shopHex: 0xFFE7AD)
            amount = 0.18
        case .evening:
            color = Color(shopHex: 0xFFB088)
            amount = 0.16
        case .night:
            color = Color(shopHex: 0x3D3656)
            amount = 0.2
        case .day, .auto:
            color = Color.white
            amount = 0
        }
        return color.opacity(amount)
    }

    private var overlayOpacity: Double {
        switch resolved {
        case .morning:
            return 0.34
        case .day, .auto:
            return 0.18
        case .evening:
            return 0.36
        case .night:
            return 0.42
        }
    }
}
