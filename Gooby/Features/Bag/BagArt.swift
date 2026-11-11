import SwiftUI

enum BagColor {
    static var skyTop: Color { Paint.pick(0x253252) { $0.night } }
    static var sky: Color { Paint.pick(0x2D3655) { HexMix.tint($0.night, 0.05) } }
    static var stage: Color { Paint.pick(0xFD9F55) { $0.bag } }
    static var colorsTile: Color { Paint.pick(0xF88119) { $0.bagDeep } }
    static let plaque = Color(hex: 0xFECB55)
    static let plaqueInk = Color(hex: 0x7D6027)
    static let dash = Color(hex: 0x8A6A26)
    static var label: Color { Paint.pick(0x333333) { $0.ink } }
    static var tile: Color { Paint.pick(0xFFFFFF) { $0.card } }
    static let place = Color(hex: 0xFFF8E7)
}

enum BagMetric {
    static let designWidth: CGFloat = 390
    static let stageTop: CGFloat = 246
    static let stageRadius: CGFloat = 32
    static let plaque = CGRect(x: 102, y: 299.3, width: 186, height: 55.3)
    static let plaqueTilt: Double = -0.95
    static let plaqueInset: CGFloat = 8
    static let margin: CGFloat = 33
    static let gap: CGFloat = 14
    static let tileHeight: CGFloat = 80.5
    static let corner: CGFloat = 22
    static let iconBox: CGFloat = 40
    static let iconY: CGFloat = 30
    static let labelY: CGFloat = 63.5
    static let mailY: CGFloat = 379
    static let row2Y: CGFloat = 473.4
    static let row3Y: CGFloat = 567
    static let locationY: CGFloat = 690
    static let gearCenter = CGPoint(x: 356, y: 86)
    static let gearSize: CGFloat = 40
    static let satchelCenter = CGPoint(x: 195, y: 245)
    static let satchelSize = CGSize(width: 90, height: 90)
    static let hillsSize = CGSize(width: 390, height: 420)
    static let pinSize = CGSize(width: 14, height: 14)
}

/// Sticker art measured off the 390-point reference. Tile icons sit in a
/// 40-point box whose centre is `iconY` below the tile top.
extension BagArt {
    static let bundle = BagArt(width: 90, height: 90, layers: [
        .stroke("M 11.8 18.4 L 72.4 41.2", 0xFFFAF0, width: 12.6),
        .stroke("M 39.6 33.5 C 39 28 38.6 19 39.8 13.5 C 40.6 9.8 43.5 9.2 47 9.2 C 50.5 9.2 53.2 10 55.5 12.5 C 58.5 15.8 62.5 20.2 68.5 22 C 73.5 22.6 79.6 23 82 26.6 C 83.6 29.2 82.4 33 78.6 33.6 C 74.5 34.2 70 33.8 66.5 34.8 C 64.6 35.3 63.2 36.4 62.6 38 C 64.6 43 65.6 52 65.2 60 C 64.8 70 57 81.8 43.5 81.8 C 29 81.8 16.6 72.5 16.8 62 C 17.2 53.5 28.5 43.6 35 38.2 C 37.4 37 39 35.6 39.6 33.5 Z", 0xFFFAF0, width: 6.2),
        .stroke("M 11.8 18.4 L 72.4 41.2", 0x97500E, width: 6.4),
        .stroke("M 14.4 16.6 L 26.8 21.2", 0xB06A2A, width: 1.3),
        .fill("M 39.6 33.5 C 39 28 38.6 19 39.8 13.5 C 40.6 9.8 43.5 9.2 47 9.2 C 50.5 9.2 53.2 10 55.5 12.5 C 58.5 15.8 62.5 20.2 68.5 22 C 73.5 22.6 79.6 23 82 26.6 C 83.6 29.2 82.4 33 78.6 33.6 C 74.5 34.2 70 33.8 66.5 34.8 C 64.6 35.3 63.2 36.4 62.6 38 C 64.6 43 65.6 52 65.2 60 C 64.8 70 57 81.8 43.5 81.8 C 29 81.8 16.6 72.5 16.8 62 C 17.2 53.5 28.5 43.6 35 38.2 C 37.4 37 39 35.6 39.6 33.5 Z", 0xF15839),
        .fill("M 18 66.5 C 23.5 73.8 33.5 76.6 44 76.4 C 54.5 76.2 61.4 70.8 64.4 63 L 65.2 60 C 64.8 70 57 81.8 43.5 81.8 C 29.5 81.8 19.6 73.6 18 66.5 Z", 0xCE3B22),
        .fill("M 62.6 38 C 64.6 43 65.6 52 65.2 60 C 64 52 62 45 58.8 40.4 Z", 0xDD4A2E),
        .stroke("M 54.4 33.2 C 58 29.6 62.8 26.6 68.6 25.4", 0xCE3B22, width: 1.6),
        .stroke("M 52.2 22.2 C 51 25.6 50.6 28.4 50.6 31.2", 0xCE3B22, width: 1.4),
        .oval(25.4, 55.2, 1.5, 3.4, 32, 0xF67459),
        .oval(43.4, 14.4, 1, 2.2, 18, 0xF67459),
        .stroke("M 39.4 29 C 46 31 54 34.2 62.8 38.6", 0xD9A21E, width: 3.2),
        .stroke("M 39.4 28.6 C 46 30.6 54 33.8 62.8 38.2", 0xF4C432, width: 2.2),
        .stroke("M 58.6 37.2 C 61 39.6 63.6 42 66 44.6", 0xF4C432, width: 2.4)
    ])

    static let mailbox = BagArt(width: 40, height: 40, layers: [
        .fill("M 19 31.6 Q 19 29 21.6 29 L 22.4 29 Q 25 29 25 31.6 L 25 34.4 Q 25 37 22.4 37 L 21.6 37 Q 19 37 19 34.4 Z", 0xBD7356),
        .fill("M 19 30.6 Q 19 30 19.6 30 L 24.4 30 Q 25 30 25 30.6 L 25 31.4 Q 25 32 24.4 32 L 19.6 32 Q 19 32 19 31.4 Z", 0xA85E47),
        .fill("M 2.5 11.5 Q 2.5 4.5 9.5 4.5 L 31 4.5 Q 38 4.5 38 11.5 L 38 29 Q 38 31 36 31 L 4.5 31 Q 2.5 31 2.5 29 Z", 0xF35045),
        .fill("M 19.6 8.9 Q 19.6 8 20.5 8 L 20.5 8 Q 21.4 8 21.4 8.9 L 21.4 30.1 Q 21.4 31 20.5 31 L 20.5 31 Q 19.6 31 19.6 30.1 Z", 0xDB4539),
        .fill("M 2.5 11.5 Q 2.5 4.5 9.5 4.5 L 12.6 4.5 Q 19.6 4.5 19.6 11.5 L 19.6 31 L 4.5 31 Q 2.5 31 2.5 29 Z", 0xC44137),
        .stroke("M 5.4 21 L 5.4 12.2 Q 5.4 8 9 7.4", 0xD65A4F, width: 1.4),
        .stroke("M 28 6.6 L 34.4 6.6", 0xFF7A6C, width: 1.2),
        .stroke("M 25 19.6 L 25 13.5 L 28.5 13.5", 0xFFD067, width: 4)
    ])

    static let outfits = BagArt(width: 40, height: 40, layers: [
        .fill("M 20.9 11.6 L 19.4 11.6 L 13.65 15.1 L 13.65 22.6 L 18.4 20.1 L 17.9 36.6 L 33.9 36.6 L 33.4 20.1 L 38.15 22.6 L 38.15 15.1 L 32.4 11.6 L 30.9 11.6 L 25.9 14.4 Z", 0xF86168),
        .fill("M 38.15 15.1 L 38.15 22.6 L 36.5 21.7 L 36.5 15.2 Z", 0xE24E57),
        .stroke("M 25.1 2.4 L 25.1 8 L 20.3 11.8 M 25.1 8 L 29.9 11.8", 0x87B9C2, width: 2.2),
        .fill("M 9.7 11.6 L 8.2 11.6 L 2.45 15.1 L 2.45 22.6 L 7.2 20.1 L 6.7 36.6 L 22.7 36.6 L 22.2 20.1 L 26.95 22.6 L 26.95 15.1 L 21.2 11.6 L 19.7 11.6 L 14.7 14.4 Z", 0xFBB861),
        .fill("M 2.45 15.1 L 2.45 22.6 L 4.1 21.7 L 4.1 15.2 Z", 0xFFCB82),
        .stroke("M 13.9 2.4 L 13.9 8 L 9.1 11.8 M 13.9 8 L 18.7 11.8", 0xB1D2DF, width: 2.2)
    ])

    static let furniture = BagArt(width: 40, height: 40, layers: [
        .stroke("M 31.5 10.6 L 31.5 30 L 35.7 33.2", 0xC8D3DD, width: 2.1),
        .fill("M 28.5 1.4 L 34.9 1.4 Q 35.8 1.4 36.1 2.2 L 38.2 9.8 Q 38.5 11.4 37.1 11.4 L 26.5 11.4 Q 25.1 11.4 25.4 9.8 L 27.3 2.2 Q 27.6 1.4 28.5 1.4 Z", 0xFCAA42),
        .stroke("M 29.1 3.4 L 28.1 8", 0xFFC872, width: 1.1),
        .fill("M 6.3 32.6 L 6.3 21.6 C 6.3 16.2 11.3 14.2 18.75 14.2 C 26.2 14.2 31.2 16.2 31.2 21.6 L 31.2 32.6 Z", 0xEC3630),
        .stroke("M 9.9 20 C 10.9 17.6 12.9 16.6 15.5 16.2", 0xF5675E, width: 1.3),
        .fill("M 8.7 32.3 Q 8.7 31.2 9.8 31.2 L 28.1 31.2 Q 29.2 31.2 29.2 32.3 L 29.2 33.3 Q 29.2 34.4 28.1 34.4 L 9.8 34.4 Q 8.7 34.4 8.7 33.3 Z", 0xBF3E3C),
        .fill("M 8.7 27.6 Q 8.7 26.6 9.7 26.6 L 17.5 26.6 Q 18.9 28.4 20.3 26.6 L 28.2 26.6 Q 29.2 26.6 29.2 27.6 L 29.2 31.6 L 8.7 31.6 Z", 0xF67772),
        .fill("M 4.5 24.4 Q 4.5 22.6 6.3 22.6 L 7 22.6 Q 8.8 22.6 8.8 24.4 L 8.8 34.6 Q 8.8 36.4 7 36.4 L 6.3 36.4 Q 4.5 36.4 4.5 34.6 Z", 0xF57576),
        .fill("M 29.4 24.4 Q 29.4 22.6 31.2 22.6 L 31.9 22.6 Q 33.7 22.6 33.7 24.4 L 33.7 34.6 Q 33.7 36.4 31.9 36.4 L 31.2 36.4 Q 29.4 36.4 29.4 34.6 Z", 0xF57576),
        .oval(5.7, 24.4, 3.2, 2.9, 0, 0xF57576),
        .oval(32.6, 24.4, 3.2, 2.9, 0, 0xF57576),
        .oval(4.8, 23.5, 1.1, 0.8, -20, 0xFFA8A4),
        .oval(31.7, 23.5, 1.1, 0.8, -20, 0xFFA8A4)
    ])

    static let question = BagArt(width: 40, height: 40, layers: [
        .stroke("M 14.2 13.8 C 14.2 9.8 17 7.3 20.7 7.3 C 24.5 7.3 27 9.9 27 13.3 C 27 16.6 25 18.3 23 19.3 C 21.4 20.1 20.7 21.2 20.7 23 L 20.7 24.4", 0xFFE9CE, width: 6.2),
        .oval(20.5, 33.3, 3.2, 3.2, 0, 0xFFE9CE)
    ])

    static let paws = BagArt(width: 40, height: 40, layers: [
        .fill("M 27.65 11.7 C 30.4 11.7 32.1 14.3 33.2 16.6 C 34.1 18.6 33.3 20.8 31.1 20.8 C 29.9 20.8 28.9 20.2 27.65 20.2 C 26.4 20.2 25.4 20.8 24.2 20.8 C 22 20.8 21.2 18.6 22.1 16.6 C 23.2 14.3 24.9 11.7 27.65 11.7 Z", 0x7B543F),
        .oval(21.1, 12.4, 2.2, 3.05, -20, 0x7B543F),
        .oval(24.3, 6.6, 2.7, 3.25, -8, 0x7B543F),
        .oval(31, 6.6, 2.7, 3.25, 8, 0x7B543F),
        .oval(34.3, 12.4, 2.2, 3.05, 20, 0x7B543F),
        .oval(25.5, 15.4, 0.9, 0.6, -35, 0x96705C),
        .fill("M 12.65 26.55 C 15.4 26.55 17.1 29.15 18.2 31.45 C 19.1 33.45 18.3 35.65 16.1 35.65 C 14.9 35.65 13.9 35.05 12.65 35.05 C 11.4 35.05 10.4 35.65 9.2 35.65 C 7 35.65 6.2 33.45 7.1 31.45 C 8.2 29.15 9.9 26.55 12.65 26.55 Z", 0x7B543F),
        .oval(6.1, 27.25, 2.2, 3.05, -20, 0x7B543F),
        .oval(9.3, 21.45, 2.7, 3.25, -8, 0x7B543F),
        .oval(16, 21.45, 2.7, 3.25, 8, 0x7B543F),
        .oval(19.3, 27.25, 2.2, 3.05, 20, 0x7B543F),
        .oval(10.5, 30.25, 0.9, 0.6, -35, 0x96705C)
    ])

    static let gear = BagArt(width: 40, height: 40, layers: [
        .stroke("M 17.1 10.64 L 17.74 5.98 L 22.26 5.98 L 22.9 10.64 L 24.57 11.33 L 28.31 8.49 L 31.51 11.69 L 28.67 15.43 L 29.36 17.1 L 34.02 17.74 L 34.02 22.26 L 29.36 22.9 L 28.67 24.57 L 31.51 28.31 L 28.31 31.51 L 24.57 28.67 L 22.9 29.36 L 22.26 34.02 L 17.74 34.02 L 17.1 29.36 L 15.43 28.67 L 11.69 31.51 L 8.49 28.31 L 11.33 24.57 L 10.64 22.9 L 5.98 22.26 L 5.98 17.74 L 10.64 17.1 L 11.33 15.43 L 8.49 11.69 L 11.69 8.49 L 15.43 11.33 Z", 0x767579, width: 5.4),
        .fill("M 17.1 10.64 L 17.74 5.98 L 22.26 5.98 L 22.9 10.64 L 24.57 11.33 L 28.31 8.49 L 31.51 11.69 L 28.67 15.43 L 29.36 17.1 L 34.02 17.74 L 34.02 22.26 L 29.36 22.9 L 28.67 24.57 L 31.51 28.31 L 28.31 31.51 L 24.57 28.67 L 22.9 29.36 L 22.26 34.02 L 17.74 34.02 L 17.1 29.36 L 15.43 28.67 L 11.69 31.51 L 8.49 28.31 L 11.33 24.57 L 10.64 22.9 L 5.98 22.26 L 5.98 17.74 L 10.64 17.1 L 11.33 15.43 L 8.49 11.69 L 11.69 8.49 L 15.43 11.33 Z", 0x4A4F55),
        .oval(20, 20, 5.6, 5.6, 0, 0x767579),
        .oval(20, 20, 2.8, 2.8, 0, 0x2D3655)
    ])

    static let pin = BagArt(width: 14, height: 14, layers: [
        .stroke("M 1.4 11.2 C 1.4 10.21 3.91 9.4 7 9.4 C 10.09 9.4 12.6 10.21 12.6 11.2 C 12.6 12.19 10.09 13 7 13 C 3.91 13 1.4 12.19 1.4 11.2 Z", 0xFFF8E7, width: 1.8),
        .stroke("M 7 6.3 L 7 10.9", 0xFFF8E7, width: 2),
        .oval(7, 3.6, 3.5, 3.5, 0, 0xFFF8E7)
    ])

    static let hills = BagArt(width: 390, height: 420, layers: [
        .oval(222, 184, 60, 40, 0, 0x143516),
        .oval(276, 215.5, 75, 85, 0, 0x143516),
        .oval(352, 260, 76, 76, 0, 0x143516),
        .oval(75, 307.5, 190, 130, -60, 0x2D4E23),
        .oval(202, 270.5, 90, 95, 0, 0x1D471B),
        .oval(102, 317.3, 95, 95, 0, 0x143516),
        .oval(338, 262, 75, 50, 0, 0x0C3A13)
    ])
}

struct BagHills: View {
    var body: some View {
        BagArtView(art: .hills)
            .frame(width: BagMetric.hillsSize.width, height: BagMetric.hillsSize.height)
            .allowsHitTesting(false)
    }
}

struct BagSatchel: View {
    var body: some View { BagArtView(art: .bundle) }
}

struct BagGear: View {
    var body: some View { BagArtView(art: .gear) }
}

struct BagMailbox: View {
    var body: some View { BagArtView(art: .mailbox) }
}

struct BagOutfitsIcon: View {
    var body: some View { BagArtView(art: .outfits) }
}

struct BagFurnitureIcon: View {
    var body: some View { BagArtView(art: .furniture) }
}

struct BagQuestion: View {
    var body: some View { BagArtView(art: .question) }
}

struct BagPaws: View {
    var body: some View { BagArtView(art: .paws) }
}

struct BagPin: View {
    var body: some View {
        BagArtView(art: .pin)
            .frame(width: BagMetric.pinSize.width, height: BagMetric.pinSize.height)
    }
}

enum BagTitle {
    static func text(name: String, language: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let who = trimmed.isEmpty ? "Gooby" : trimmed
        if language == "en" {
            return "\(who)'s bag"
        }
        if let last = who.lowercased().last, "sßxz".contains(last) {
            return "Tasche von \(who)"
        }
        return "\(who)s Tasche"
    }

    static func mail(name: String, language: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let who = trimmed.isEmpty ? "Gooby" : trimmed
        if language == "en" {
            return "\(who)'s Mail"
        }
        if let last = who.lowercased().last, "sßxz".contains(last) {
            return "Post von \(who)"
        }
        return "\(who)s Post"
    }
}

@MainActor
enum BagPlace {
    static func current(_ engine: GoobyEngine) -> PlaceDef? {
        if let run = engine.todaysRun(), let place = engine.catalog.placesByID[run.placeID] {
            return place
        }
        let claimed = engine.all(AdventureRun.self)
            .filter { $0.status == "claimed" }
            .sorted { ($0.claimedAt ?? .distantPast) > ($1.claimedAt ?? .distantPast) }
        if let id = claimed.first?.placeID, let place = engine.catalog.placesByID[id] {
            return place
        }
        return engine.catalog.places.first { $0.unlockAfterAdventures == 0 } ?? engine.catalog.places.first
    }
}
