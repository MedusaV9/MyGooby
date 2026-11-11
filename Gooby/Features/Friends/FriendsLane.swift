import Foundation

// Local post and the first-friend reward. A later transport can set
// FriendsLane.shared.carrier and deliver the same notes. This file does not
// open a radio, a socket, or an account.

struct FriendsDispatch: Codable, Equatable, Identifiable {
    var id: UUID
    var palName: String
    var code: String
    var kind: String
    var token: String
    var createdAt: Date
}

enum FriendsNoteKind {
    static let visit = "visit"
    static let vibes = "vibes"
    static let gift = "gift"
}

struct FriendsPostBook: Codable, Equatable {
    var funSeen: Bool = false
    var notes: [FriendsDispatch] = []

    private enum CodingKeys: String, CodingKey {
        case funSeen, notes
    }

    init() {}

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        funSeen = try box.decodeIfPresent(Bool.self, forKey: .funSeen) ?? false
        notes = try box.decodeIfPresent([FriendsDispatch].self, forKey: .notes) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        try box.encode(funSeen, forKey: .funSeen)
        try box.encode(notes, forKey: .notes)
    }

    static func load() -> FriendsPostBook {
        let url = fileURL()
        guard let data = try? Data(contentsOf: url) else { return FriendsPostBook() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let book = try? decoder.decode(FriendsPostBook.self, from: data) else { return FriendsPostBook() }
        return book
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else { return }
        let url = Self.fileURL()
        try? data.write(to: url, options: .atomic)
        GoobyFiles.exclude(url)
    }

    func adding(pal: TreePal, kind: String, token: String, at: Date) -> (FriendsPostBook, FriendsDispatch) {
        var copy = self
        let note = FriendsDispatch(
            id: UUID(),
            palName: pal.name,
            code: pal.code,
            kind: kind,
            token: token,
            createdAt: at
        )
        copy.notes.insert(note, at: 0)
        if copy.notes.count > 40 { copy.notes = Array(copy.notes.prefix(40)) }
        return (copy, note)
    }

    private static func fileURL() -> URL {
        GoobyFiles.supportDirectory().appendingPathComponent("friends-post.json")
    }
}

@MainActor
enum FriendsNoteCopy {
    static func line(_ engine: GoobyEngine, _ note: FriendsDispatch) -> String {
        switch note.kind {
        case FriendsNoteKind.visit:
            return engine.tf("friends.fun.postVisit", note.palName)
        case FriendsNoteKind.vibes:
            return engine.tf("friends.fun.postVibe", note.palName, engine.t("friends.fun.\(note.token)"))
        case FriendsNoteKind.gift:
            return engine.tf("friends.fun.postGift", note.palName, engine.t("friends.fun.\(note.token)"))
        default:
            return note.palName
        }
    }
}

@MainActor
protocol FriendsCarrier: AnyObject {
    func carry(_ note: FriendsDispatch)
}

@MainActor
final class FriendsLane {
    static let shared = FriendsLane()
    weak var carrier: (any FriendsCarrier)?

    func handoff(_ note: FriendsDispatch) {
        carrier?.carry(note)
    }
}

@MainActor
enum FriendsFirstGift {
    static let ledgerKey = "friends:first-pal"
    static let itemID = "cloth.sweater.honey"
    static let stones = 600

    static func hoodName(_ engine: GoobyEngine) -> String {
        let fallback = engine.t("friends.fun.hood")
        guard let item = engine.catalog.itemsByID[itemID] else { return fallback }
        let name = item.name.text(engine.languageCode)
        return name.isEmpty ? fallback : name
    }

    static func hasHood(_ engine: GoobyEngine) -> Bool {
        engine.catalog.itemsByID[itemID] != nil
    }

    static func paid(_ engine: GoobyEngine) -> Bool {
        engine.all(RewardLedger.self).contains { $0.key == ledgerKey }
    }

    /// Books 600 stones through the existing wallet ledger and unlocks the hood.
    /// True only when those stones are new.
    @discardableResult
    static func grantFirstPal(engine: GoobyEngine, pals: [TreePal]) -> Bool {
        guard !pals.isEmpty else { return false }
        let fresh = engine.grant(key: ledgerKey, sparks: stones, energy: 0)
        let owned = engine.owns(itemID)
        engine.grantItem(itemID)
        let hoodIsNew = !owned && engine.owns(itemID)
        guard fresh || hoodIsNew else { return false }
        engine.recomputeQuests()
        engine.save()
        return fresh
    }
}
