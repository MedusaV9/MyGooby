import Foundation

struct OnlineFriend: Codable, Identifiable, Equatable {
    var id: String
    var pairKey: Data
    var card: GoobyCard?
    var outbox: [GoobyGift] = []
    var received: [String] = []
    var pendingGifts: [GoobyGift] = []
    var lastMetAt: Date?
    var lastServerAt: Date?
    var lastNotifiedAt: Date?
    var lastHeartDay: String = ""
    var lastSparksDay: String = ""
    var addedAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id, pairKey, card, outbox, received, pendingGifts
        case lastMetAt, lastServerAt, lastNotifiedAt, lastHeartDay, lastSparksDay, addedAt
    }

    init(id: String, pairKey: Data, card: GoobyCard?) {
        self.id = id
        self.pairKey = pairKey
        self.card = card
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        id = try box.decode(String.self, forKey: .id)
        pairKey = try box.decode(Data.self, forKey: .pairKey)
        card = try box.decodeIfPresent(GoobyCard.self, forKey: .card)
        outbox = try box.decodeIfPresent([GoobyGift].self, forKey: .outbox) ?? []
        received = try box.decodeIfPresent([String].self, forKey: .received) ?? []
        pendingGifts = try box.decodeIfPresent([GoobyGift].self, forKey: .pendingGifts) ?? []
        lastMetAt = try box.decodeIfPresent(Date.self, forKey: .lastMetAt)
        lastServerAt = try box.decodeIfPresent(Date.self, forKey: .lastServerAt)
        lastNotifiedAt = try box.decodeIfPresent(Date.self, forKey: .lastNotifiedAt)
        lastHeartDay = try box.decodeIfPresent(String.self, forKey: .lastHeartDay) ?? ""
        lastSparksDay = try box.decodeIfPresent(String.self, forKey: .lastSparksDay) ?? ""
        addedAt = try box.decodeIfPresent(Date.self, forKey: .addedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        try box.encode(id, forKey: .id)
        try box.encode(pairKey, forKey: .pairKey)
        try box.encodeIfPresent(card, forKey: .card)
        try box.encode(outbox, forKey: .outbox)
        try box.encode(received, forKey: .received)
        try box.encode(pendingGifts, forKey: .pendingGifts)
        try box.encodeIfPresent(lastMetAt, forKey: .lastMetAt)
        try box.encodeIfPresent(lastServerAt, forKey: .lastServerAt)
        try box.encodeIfPresent(lastNotifiedAt, forKey: .lastNotifiedAt)
        try box.encode(lastHeartDay, forKey: .lastHeartDay)
        try box.encode(lastSparksDay, forKey: .lastSparksDay)
        try box.encode(addedAt, forKey: .addedAt)
    }

    var displayName: String {
        let name = card?.nickname.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !name.isEmpty { return name }
        let pet = card?.goobyName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return pet.isEmpty ? "Gooby" : pet
    }
}

struct OnlineInvite: Codable, Equatable {
    var code: String
    var pairKey: Data
    var createdAt: Date
}

struct OnlineState: Codable {
    var memberID: String = UUID().uuidString
    var nearbyOn: Bool = false
    var serverURL: String = ""
    var serverKey: String = ""
    var language: String = "de"
    var ownCard: GoobyCard?
    var friends: [OnlineFriend] = []
    var invites: [OnlineInvite] = []
    var lastSyncAt: Date?
    var lastSyncError: String = ""

    enum CodingKeys: String, CodingKey {
        case memberID, nearbyOn, serverURL, serverKey, language, ownCard, friends, invites, lastSyncAt, lastSyncError
    }

    init() {}

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        memberID = try box.decodeIfPresent(String.self, forKey: .memberID) ?? UUID().uuidString
        nearbyOn = try box.decodeIfPresent(Bool.self, forKey: .nearbyOn) ?? false
        serverURL = try box.decodeIfPresent(String.self, forKey: .serverURL) ?? ""
        serverKey = try box.decodeIfPresent(String.self, forKey: .serverKey) ?? ""
        language = try box.decodeIfPresent(String.self, forKey: .language) ?? "de"
        ownCard = try box.decodeIfPresent(GoobyCard.self, forKey: .ownCard)
        friends = try box.decodeIfPresent([OnlineFriend].self, forKey: .friends) ?? []
        invites = try box.decodeIfPresent([OnlineInvite].self, forKey: .invites) ?? []
        lastSyncAt = try box.decodeIfPresent(Date.self, forKey: .lastSyncAt)
        lastSyncError = try box.decodeIfPresent(String.self, forKey: .lastSyncError) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        try box.encode(memberID, forKey: .memberID)
        try box.encode(nearbyOn, forKey: .nearbyOn)
        try box.encode(serverURL, forKey: .serverURL)
        try box.encode(serverKey, forKey: .serverKey)
        try box.encode(language, forKey: .language)
        try box.encodeIfPresent(ownCard, forKey: .ownCard)
        try box.encode(friends, forKey: .friends)
        try box.encode(invites, forKey: .invites)
        try box.encodeIfPresent(lastSyncAt, forKey: .lastSyncAt)
        try box.encode(lastSyncError, forKey: .lastSyncError)
    }

    static func load() -> OnlineState {
        guard let data = try? Data(contentsOf: fileURL()),
              let state = try? JSONDecoder().decode(OnlineState.self, from: data) else {
            return OnlineState()
        }
        return state
    }

    func save() {
        let url = Self.fileURL()
        guard let data = try? JSONEncoder().encode(self) else { return }
        // Readable after the first unlock so a pocket meetup can still be exchanged.
        try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        GoobyFiles.exclude(url)
    }

    private static func fileURL() -> URL {
        GoobyFiles.supportDirectory().appendingPathComponent("online.json")
    }
}
