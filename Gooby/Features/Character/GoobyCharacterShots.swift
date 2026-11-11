#if DEBUG
import SwiftUI
import UIKit

/// Debug builds launched with `-GoobyCharacterShots` render every pose, a few motion frames,
/// and the home forest into Documents/gooby-shots. The same sheet stays on screen, so a
/// simulator screenshot catches it even if the files cannot be copied out.
enum GoobyCharacterShots {
    static var requested: Bool {
        ProcessInfo.processInfo.arguments.contains("-GoobyCharacterShots")
    }

    static let poses: [(String, GoobyAnimation)] = [
        ("idle", .idle), ("wave", .wave), ("read", .read), ("sleep", .sleep), ("curious", .curious),
        ("flower", .flower), ("back", .walk), ("sit", .sit), ("surprised", .surprised), ("celebrate", .celebrate)
    ]

    /// Times chosen so the frame lands mid-blink, at the top of a hop, or at the crest of a wave.
    static let motion: [(String, GoobyAnimation, Double)] = [
        ("blink", .blink, 2.2 * 4 + 2.2 - 0.22),
        ("hop", .hop, 0),
        ("ears", .ears, Double.pi / 12),
        ("breathe", .breathe, 1000 * Double.pi * 2 / 1.2 + Double.pi / 2.4),
        ("wave-up", .wave, Double.pi / 10),
        ("walk", .walk, 0),
        ("sleep", .sleep, 62.0 / 25.0),
        ("unwrap", .unwrap, 827.0 / 1000.0 * 0.55)
    ]

    @MainActor
    static func writeAll() {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("gooby-shots", isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        func save<V: View>(_ name: String, _ view: V, _ size: CGSize) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            renderer.proposedSize = ProposedViewSize(size)
            if let data = renderer.uiImage?.pngData() {
                try? data.write(to: folder.appendingPathComponent("\(name).png"))
            }
        }
        save("sheet", GoobyPoseSheet(), CGSize(width: 390, height: 760))
        for entry in poses {
            for size in [320, 160, 64] {
                let side = CGFloat(size)
                save("pose-\(entry.0)-\(size)", tile(GoobyPose.still(entry.1), size: side), CGSize(width: side, height: side))
            }
        }
        for entry in motion {
            let pose = GoobyPose.make(animation: entry.1, time: entry.2, reduce: false)
            save("motion-\(entry.0)", tile(pose, size: 240), CGSize(width: 240, height: 240))
        }
        save("gear", gearStrip, CGSize(width: 800, height: 200))
        let forest = ForestScene(reduceMotion: true, showHearts: false) {}.frame(width: 390, height: 428)
        save("forest", forest, CGSize(width: 390, height: 428))
        try? "ok".write(to: folder.appendingPathComponent("done.txt"), atomically: true, encoding: .utf8)
    }

    static func tile(_ pose: GoobyPose, size: CGFloat, look: WornLook = WornLook()) -> some View {
        GoobyRig(look: look, stage: "young", pose: pose, companion: nil)
            .frame(width: size, height: size)
            .background(Color(hex: 0xFAEADB))
    }

    private static var gearStrip: some View {
        let items = catalogItems()
        func pick(_ ids: [String]) -> WornLook {
            var look = WornLook()
            for id in ids {
                if let item = items.first(where: { $0.id == id }) { look.slots[item.slot] = item }
            }
            return look
        }
        let looks = [
            pick(["hat-sun", "scarf-rose"]),
            pick(["glass-star", "sweater-sky", "shoes-button"]),
            pick(["bow-rose", "pack-mint"]),
            WornLook(fur: "fur-lilac")
        ]
        return HStack(spacing: 0) {
            ForEach(looks.indices, id: \.self) { index in
                tile(GoobyPose.still(.idle), size: 200, look: looks[index])
            }
        }
    }

    private static func catalogItems() -> [ItemDef] {
        struct Box: Decodable { var items: [ItemDef] }
        guard let url = BundleResources.urls(prefix: "content-", extension: "json").first(where: { $0.lastPathComponent == "content-shell.json" }),
              let data = try? Data(contentsOf: url),
              let box = try? JSONDecoder().decode(Box.self, from: data) else { return [] }
        return box.items
    }
}

struct GoobyPoseSheet: View {
    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(120), spacing: 4), count: 3), spacing: 4) {
                ForEach(GoobyCharacterShots.poses.indices, id: \.self) { index in
                    let entry = GoobyCharacterShots.poses[index]
                    VStack(spacing: 0) {
                        GoobyCharacterShots.tile(GoobyPose.still(entry.1), size: 120)
                        Text(entry.0).font(.caption2).foregroundStyle(Theme.ink.opacity(0.6))
                    }
                }
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach([96, 64, 44, 32], id: \.self) { size in
                    GoobyCharacterShots.tile(GoobyPose.still(.idle), size: CGFloat(size))
                }
            }
        }
        .padding(10)
        .frame(width: 390)
        .background(Color(hex: 0xFAEADB))
    }
}

struct GoobyCharacterShotsScreen: View {
    @State private var written = false

    var body: some View {
        ScrollView {
            GoobyPoseSheet()
            GoobyCharacterView(look: WornLook(), stage: "young", animation: .idle, reduceMotion: false, companion: nil)
                .frame(width: 200, height: 200)
            Text(written ? "shots written" : "writing…").font(.caption)
        }
        .background(Color(hex: 0xFAEADB).ignoresSafeArea())
        .task { @MainActor in
            GoobyCharacterShots.writeAll()
            written = true
        }
    }
}
#endif
