import SwiftUI

struct AdventureDiscoveriesScreen: View {
    var bridge: AdventureBridge
    var store: AdventureStore

    @Environment(\.dismiss) private var dismiss

    private var copy: AdventureCopy { AdventureCopy(language: bridge.language) }

    var body: some View {
        ZStack {
            AdventureScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AdventureBackHeader(title: copy.discoveries, backTitle: copy.back) { dismiss() }
                    let found = store.save.foundDiscoveryIDs.count
                    let total = store.catalog.places.reduce(0) { $0 + $1.discoveries.count }
                    Text(copy.foundCount(found: found, total: total))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AdventurePalette.ink.opacity(0.7))
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(store.catalog.places) { place in
                            ForEach(place.discoveries) { discovery in
                                card(place: place, discovery: discovery)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func card(place: AdventurePlaceDefinition, discovery: AdventureDiscoveryDefinition) -> some View {
        let known = store.save.foundDiscoveryIDs.contains(discovery.id)
        return VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle().fill(AdventurePalette.color(hex: place.accentHex))
                if known {
                    AdventurePlaceIcon(motif: place.motif, tint: AdventurePalette.ink)
                        .padding(10)
                } else {
                    AdventureLockMark()
                }
            }
            .frame(width: 48, height: 48)
            Text(known ? discovery.name.resolved(bridge.language) : copy.hidden)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(AdventurePalette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(place.name.resolved(bridge.language))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AdventurePalette.ink.opacity(0.65))
            if known {
                Text(discovery.detail.resolved(bridge.language))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(copy.hidden)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink.opacity(0.45))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background((known ? Color.white : AdventurePalette.cream).opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct AdventurePersonalityScreen: View {
    var bridge: AdventureBridge
    var store: AdventureStore

    @Environment(\.dismiss) private var dismiss

    private var copy: AdventureCopy { AdventureCopy(language: bridge.language) }

    var body: some View {
        ZStack {
            AdventureScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AdventureBackHeader(title: copy.personality, backTitle: copy.back) { dismiss() }
                    AdventureBunnyView(pose: .idle, reducedMotion: bridge.prefersReducedMotion)
                        .frame(maxWidth: .infinity)
                    Text(copy.personalityNote)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AdventurePalette.ink)
                    ForEach(AdventureTrait.allCases) { trait in
                        meter(trait)
                    }
                }
                .padding(20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func meter(_ trait: AdventureTrait) -> some View {
        let value = store.save.traits[trait.rawValue, default: AdventureEngine.traitBaseline]
        let fraction = Double(value) / Double(AdventureEngine.traitMaximum)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(copy.traitName(trait))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AdventurePalette.ink)
                Spacer()
                Text("\(value)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AdventurePalette.ink.opacity(0.7))
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AdventurePalette.ink.opacity(0.08))
                    Capsule()
                        .fill(tint(trait))
                        .frame(width: max(10, proxy.size.width * fraction))
                }
            }
            .frame(height: 12)
        }
        .padding(14)
        .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(copy.traitName(trait)) \(value)")
    }

    private func tint(_ trait: AdventureTrait) -> Color {
        switch trait {
        case .curiosity: return AdventurePalette.sky
        case .courage: return AdventurePalette.peach
        case .kindness: return AdventurePalette.pink
        case .playfulness: return AdventurePalette.yellow
        case .confidence: return AdventurePalette.lavender
        case .calm: return AdventurePalette.mint
        case .empathy: return AdventurePalette.pink.opacity(0.9)
        }
    }
}
