import SwiftUI

struct RoomDiorama: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var preview: ItemDef? = nil

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            let phase = DaylightPhase.of(engine.now())
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(wallColor)
                window(phase)
                floor
                furniture
                GoobyCharacterView(
                    look: engine.wornLook(preview: preview),
                    stage: Growth.stage(of: engine.pet),
                    animation: engine.animation,
                    reduceMotion: reduceMotion,
                    companion: engine.companionSpecies()
                )
                .padding(.bottom, 24)
                lighting(phase)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Theme.ink.opacity(0.06), lineWidth: 1))
    }

    private var wallColor: Color {
        catalogColor(engine.roomItem("wall")) ?? Color(hex: 0xFFF1E4)
    }

    private var floor: some View {
        Ellipse()
            .fill(catalogColor(engine.roomItem("floor")) ?? Theme.peach.opacity(0.85))
            .frame(height: 90)
            .padding(.horizontal, 18)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 18)
    }

    private var furniture: some View {
        ZStack {
            slot("rug", y: 70, wide: true)
            slot("bed", x: -90, y: 20)
            slot("sofa", x: 80, y: 24)
            slot("table", x: 20, y: 48)
            slot("plant", x: -120, y: -20)
            slot("shelf", x: 120, y: -70)
            slot("picture", x: -40, y: -90)
            slot("cushion", x: 70, y: 60)
            slot("lamp", x: 130, y: -10)
            if !engine.roomItem("seasonal").isEmpty { slot("seasonal", x: -10, y: -40) }
        }
    }

    private func window(_ phase: DaylightPhase) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(sky(phase))
            .frame(width: 110, height: 84)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.ink.opacity(0.15), lineWidth: 6))
            .overlay {
                if phase == .night {
                    Image(systemName: "moon.stars.fill").foregroundStyle(.white.opacity(0.9))
                } else if phase == .evening {
                    Image(systemName: "sun.haze.fill").foregroundStyle(Theme.yellow)
                } else {
                    Image(systemName: "sun.max.fill").foregroundStyle(Theme.yellow)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 28)
    }

    private func slot(_ name: String, x: CGFloat = 0, y: CGFloat = 0, wide: Bool = false) -> some View {
        let id = engine.roomItem(name)
        let color = catalogColor(id) ?? Theme.lavender.opacity(id.isEmpty ? 0 : 0.9)
        return RoundedRectangle(cornerRadius: wide ? 40 : 14, style: .continuous)
            .fill(color.opacity(id.isEmpty ? 0 : 0.95))
            .frame(width: wide ? 180 : 54, height: wide ? 28 : 42)
            .overlay {
                if !id.isEmpty {
                    Image(systemName: symbol(name))
                        .font(.system(size: wide ? 14 : 16))
                        .foregroundStyle(Theme.ink.opacity(0.55))
                }
            }
            .offset(x: x, y: y)
    }

    private func lighting(_ phase: DaylightPhase) -> some View {
        let color: Color
        let amount: Double
        switch phase {
        case .morning: color = Theme.yellow; amount = 0.18
        case .day: color = .clear; amount = 0
        case .evening: color = Theme.peach; amount = 0.28
        case .night: color = Color(hex: 0x6E7399); amount = 0.38
        }
        return color.opacity(amount)
            .overlay(alignment: .topTrailing) {
                if phase == .night && !engine.roomItem("lamp").isEmpty {
                    Circle().fill(Theme.yellow.opacity(0.35)).frame(width: 90).blur(radius: 8).padding(24)
                }
            }
            .allowsHitTesting(false)
    }

    private func sky(_ phase: DaylightPhase) -> LinearGradient {
        switch phase {
        case .morning:
            return LinearGradient(colors: [Theme.yellow, Theme.peach], startPoint: .top, endPoint: .bottom)
        case .day:
            return LinearGradient(colors: [Theme.sky, Theme.mint], startPoint: .top, endPoint: .bottom)
        case .evening:
            return LinearGradient(colors: [Theme.peach, Theme.lavender], startPoint: .top, endPoint: .bottom)
        case .night:
            return LinearGradient(colors: [Color(hex: 0x3D3656), Color(hex: 0x8E93B8)], startPoint: .top, endPoint: .bottom)
        }
    }

    private func catalogColor(_ id: String) -> Color? {
        guard let item = engine.catalog.itemsByID[id] else { return nil }
        return Color(hexString: item.color)
    }

    private func symbol(_ slot: String) -> String {
        switch slot {
        case "bed": return "bed.double.fill"
        case "rug": return "square.fill"
        case "lamp": return "lamp.floor.fill"
        case "plant": return "leaf.fill"
        case "shelf": return "books.vertical.fill"
        case "picture": return "photo.fill"
        case "sofa": return "sofa.fill"
        case "table": return "table.furniture.fill"
        case "cushion": return "circle.fill"
        case "seasonal": return "snowflake"
        default: return "sparkle"
        }
    }
}

struct RoomEditorSheet: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    private let slots = ["wall", "floor", "bed", "rug", "lamp", "window", "plant", "shelf", "picture", "sofa", "table", "cushion", "seasonal"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    RoomDiorama(engine: engine, reduceMotion: engine.reduceMotion).frame(height: 280)
                    ForEach(slots, id: \.self) { slot in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(engine.t("slot.\(slot)")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    Button(engine.t("room.empty")) { engine.unequip(slot: slot) }
                                        .buttonStyle(.bordered)
                                    ForEach(owned(slot)) { item in
                                        Button(item.name.text(engine.languageCode)) {
                                            engine.equip(item)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(engine.roomItem(slot) == item.id ? Theme.rose : Theme.lavender)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(16)
            }
            .goobyScreen()
            .navigationTitle(engine.t("today.room.edit"))
            .toolbar { Button(engine.t("common.done")) { dismiss() } }
        }
    }

    private func owned(_ slot: String) -> [ItemDef] {
        engine.all(OwnedItem.self).compactMap { row in
            guard let item = engine.catalog.itemsByID[row.catalogID], item.slot == slot else { return nil }
            return item
        }
    }
}
