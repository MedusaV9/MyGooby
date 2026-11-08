#if DEBUG
import SwiftUI

/// DEBUG-only contact sheet for the `gooby` screenshot route: every animation at a telling
/// frame, a few outfits and fur colors, the avatar crops and the widget head. Labels are the
/// animation identifiers, so nothing here needs translating; release builds leave it out.
struct GoobyPoseSheet: View {
    var engine: GoobyEngine

    /// Seconds into each animation that show its key frame.
    private static let frames: [GoobyAnimation: Double] = [
        .hop: 0.32, .celebrate: 0.4, .surprised: 0.18, .clap: 0.0, .wake: 1.5, .unwrap: 1.6,
        .depart: 0.5, .arrive: 1.5, .dance: 0.4, .play: 0.5, .laugh: 0.17, .wiggle: 0.26
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
                    ForEach(GoobyAnimation.allCases) { animation in
                        cell(animation.rawValue) {
                            GoobyRig(look: WornLook(), stage: "baby", pose: pose(animation), companion: animation == .play ? "chick" : nil)
                        }
                    }
                    cell("pack") {
                        GoobyRig(look: WornLook(), stage: "baby", pose: pose(.idle), companion: nil, adventuring: true)
                    }
                    cell("pack-up") {
                        GoobyRig(look: WornLook(), stage: "baby", pose: pose(.celebrate), companion: nil, adventuring: true)
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {
                    ForEach(outfits.indices, id: \.self) { index in
                        cell(outfits[index].0) {
                            GoobyRig(look: outfits[index].1, stage: "young", pose: pose(.idle), companion: nil)
                        }
                    }
                }
                HStack(alignment: .bottom, spacing: 12) {
                    GoobyAvatar(look: WornLook(), stage: "baby", size: 32)
                    GoobyAvatar(look: WornLook(), stage: "baby", size: 44)
                    GoobyAvatar(look: WornLook(), stage: "baby", size: 96)
                        .background(Color(hex: 0xFDF3DF), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    GoobyMiniHead(face: .smile).frame(width: 56, height: 56)
                    GoobyMiniHead(face: .happy).frame(width: 56, height: 56)
                    GoobyMiniHead(face: .sleepy).frame(width: 56, height: 56)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .background(Color(hex: 0xF2E5C4).ignoresSafeArea())
    }

    private func pose(_ animation: GoobyAnimation) -> GoobyPose {
        let elapsed = GoobyPoseSheet.frames[animation] ?? 0.5
        var pose = GoobyPose.make(animation: animation, time: 1000 + elapsed, elapsed: elapsed, reduce: false)
        if animation != .blink { pose.blink = 1 } else { pose.blink = 0.1 }
        return pose
    }

    private func cell<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
                .frame(height: 68)
            Text(verbatim: label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x7A6340))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
        .background(Color(hex: 0xFFFBF3), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// Fur colors and outfits from the catalog, one slot or color per cell.
    private var outfits: [(String, WornLook)] {
        let items = engine.catalog.items
        func first(_ slot: String) -> ItemDef? { items.first { $0.slot == slot } }
        var looks: [(String, WornLook)] = []
        for fur in ["fur-peach", "fur-lilac", "fur-mint", "fur-sky"] {
            looks.append((fur, WornLook(fur: fur)))
        }
        var full: [String: ItemDef] = [:]
        for slot in ["hat", "glasses", "scarf", "sweater", "shoes", "backpack", "bow", "dress"] {
            guard let item = first(slot) else { continue }
            looks.append((slot, WornLook(slots: [slot: item])))
            if ["hat", "scarf", "sweater", "shoes"].contains(slot) { full[slot] = item }
        }
        return Array(looks.prefix(14)) + [("outfit", WornLook(slots: full))]
    }
}
#endif
