import CryptoKit
import Foundation

// One sync model for every transport. A meetup over Bluetooth and a relay through
// the self-hosted server both move the same sealed SyncEnvelope. Only the two
// friends hold the pair key, so the server and anyone listening over the air see
// ciphertext. Journal text, notes, the profile photo, and the rest of the save
// never enter this envelope.

struct GoobyCard: Codable, Equatable {
    var code: String = ""
    var nickname: String = ""
    var goobyName: String = "Gooby"
    var stage: String = "baby"
    var fur: String = "fur-cream"
    var mood: Int = 0
    var streak: Int = 0
    var done: Int = 0
    var total: Int = 0
    var careDays: Int = 0
    var companion: String = ""
    var updatedAt: Int = 0

    enum CodingKeys: String, CodingKey {
        case code = "c", nickname = "n", goobyName = "g", stage = "s", fur = "f", mood = "m"
        case streak = "k", done = "d", total = "t", careDays = "y", companion = "p", updatedAt = "u"
    }

    init() {}

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        code = try box.decodeIfPresent(String.self, forKey: .code) ?? ""
        nickname = try box.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        goobyName = try box.decodeIfPresent(String.self, forKey: .goobyName) ?? "Gooby"
        stage = try box.decodeIfPresent(String.self, forKey: .stage) ?? "baby"
        fur = try box.decodeIfPresent(String.self, forKey: .fur) ?? "fur-cream"
        mood = try box.decodeIfPresent(Int.self, forKey: .mood) ?? 0
        streak = try box.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        done = try box.decodeIfPresent(Int.self, forKey: .done) ?? 0
        total = try box.decodeIfPresent(Int.self, forKey: .total) ?? 0
        careDays = try box.decodeIfPresent(Int.self, forKey: .careDays) ?? 0
        companion = try box.decodeIfPresent(String.self, forKey: .companion) ?? ""
        updatedAt = try box.decodeIfPresent(Int.self, forKey: .updatedAt) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        try box.encode(code, forKey: .code)
        try box.encode(nickname, forKey: .nickname)
        try box.encode(goobyName, forKey: .goobyName)
        try box.encode(stage, forKey: .stage)
        try box.encode(fur, forKey: .fur)
        try box.encode(mood, forKey: .mood)
        try box.encode(streak, forKey: .streak)
        try box.encode(done, forKey: .done)
        try box.encode(total, forKey: .total)
        try box.encode(careDays, forKey: .careDays)
        try box.encode(companion, forKey: .companion)
        try box.encode(updatedAt, forKey: .updatedAt)
    }

    func sameContent(as other: GoobyCard) -> Bool {
        var left = self
        var right = other
        left.updatedAt = 0
        right.updatedAt = 0
        return left == right
    }
}

struct GoobyGift: Codable, Equatable, Identifiable {
    static let heart = "heart"
    static let sparks = "sparks"
    static let sparkAmount = 5

    var id: String
    var kind: String
    var amount: Int
    var sentAt: Int

    enum CodingKeys: String, CodingKey {
        case id = "i", kind = "k", amount = "a", sentAt = "w"
    }
}

struct SyncEnvelope: Codable {
    var version: Int = 1
    var from: String
    var card: GoobyCard
    var gifts: [GoobyGift] = []
    var acks: [String] = []
    var sentAt: Int

    enum CodingKeys: String, CodingKey {
        case version = "v", from = "f", card = "c", gifts = "g", acks = "a", sentAt = "w"
    }

    init(from member: String, card: GoobyCard, gifts: [GoobyGift], acks: [String], sentAt: Int) {
        self.from = member
        self.card = card
        self.gifts = gifts
        self.acks = acks
        self.sentAt = sentAt
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        version = try box.decodeIfPresent(Int.self, forKey: .version) ?? 1
        from = try box.decode(String.self, forKey: .from)
        card = try box.decode(GoobyCard.self, forKey: .card)
        gifts = try box.decodeIfPresent([GoobyGift].self, forKey: .gifts) ?? []
        acks = try box.decodeIfPresent([String].self, forKey: .acks) ?? []
        sentAt = try box.decodeIfPresent(Int.self, forKey: .sentAt) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        try box.encode(version, forKey: .version)
        try box.encode(from, forKey: .from)
        try box.encode(card, forKey: .card)
        try box.encode(gifts, forKey: .gifts)
        try box.encode(acks, forKey: .acks)
        try box.encode(sentAt, forKey: .sentAt)
    }
}

struct PairingHello: Codable {
    var member: String
    var card: GoobyCard
    var keyPart: Data
}

struct InvitePayload: Codable {
    var member: String
    var card: GoobyCard
    var pairKey: Data
}

struct AccountBundle: Codable {
    var profileID: String
    var export: Data
    var friends: [OnlineFriend]
    var invites: [OnlineInvite]
    var envelope: SyncEnvelope
}

enum SyncError: Error {
    case seal
    case badURL
    case http(Int, String)
    case unreadable
}

enum SyncSeal {
    static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func randomBytes(_ count: Int = 32) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        for index in bytes.indices {
            bytes[index] = UInt8.random(in: 0...255)
        }
        return Data(bytes)
    }

    static func shortID() -> String {
        String((0..<12).map { _ in alphabet.randomElement() ?? "G" })
    }

    static func combine(_ left: Data, _ right: Data) -> Data {
        let ordered = [left, right].sorted { $0.lexicographicallyPrecedes($1) }
        return Data(SHA256.hash(data: ordered[0] + ordered[1]))
    }

    static func accountKey(_ password: String) -> Data {
        let material = Data(SHA256.hash(data: Data(password.utf8)))
        return derive(material, "account-save-v1").withUnsafeBytes { Data($0) }
    }

    static func digest<T: Encodable>(_ value: T) throws -> String {
        hex(Data(SHA256.hash(data: try JSONEncoder().encode(value))))
    }

    static func derive(_ secret: Data, _ label: String) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: secret),
            salt: Data("gooby-online".utf8),
            info: Data(label.utf8),
            outputByteCount: 32
        )
    }

    static func seal<T: Encodable>(_ value: T, secret: Data, label: String = "seal-v1") throws -> Data {
        let json = try JSONEncoder().encode(value)
        let packed = try (json as NSData).compressed(using: .zlib) as Data
        let box = try AES.GCM.seal(packed, using: derive(secret, label))
        guard let combined = box.combined else { throw SyncError.seal }
        return combined
    }

    static func open<T: Decodable>(_ type: T.Type, _ data: Data, secret: Data, label: String = "seal-v1") throws -> T {
        let box = try AES.GCM.SealedBox(combined: data)
        let packed = try AES.GCM.open(box, using: derive(secret, label))
        let json = try (packed as NSData).decompressed(using: .zlib) as Data
        return try JSONDecoder().decode(T.self, from: json)
    }

    static func mac(_ secret: Data, _ label: String, _ message: String) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: derive(secret, label)))
    }

    static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    static func channelID(_ secret: Data) -> String { hex(mac(secret, "channel-v1", "channel")) }

    static func channelToken(_ secret: Data) -> String { hex(mac(secret, "token-v1", "token")) }

    static func slot(_ secret: Data, member: String) -> String {
        String(hex(mac(secret, "slot-v1", member)).prefix(32))
    }

    static func hour(_ date: Date = Date()) -> Int { Int(date.timeIntervalSince1970 / 3600) }

    // Rotates every hour so a stranger cannot follow one phone by a stable beacon.
    static func meetTag(_ secret: Data, hour: Int) -> Data {
        Data(mac(secret, "meet-v1", String(hour)).prefix(8))
    }

    static func makeInviteCode() -> String {
        let raw = String((0..<10).map { _ in alphabet.randomElement() ?? "G" })
        return String(raw.prefix(5)) + "-" + String(raw.suffix(5))
    }

    static func normalizeInvite(_ raw: String) -> String {
        let allowed = Set(alphabet)
        return String(raw.uppercased().filter { allowed.contains($0) })
    }

    static func inviteSecret(_ code: String) -> Data {
        Data(("gooby-invite:" + normalizeInvite(code)).utf8)
    }

    static func inviteID(_ code: String) -> String {
        hex(Data(SHA256.hash(data: inviteSecret(code))))
    }
}
