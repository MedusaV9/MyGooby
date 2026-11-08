import Foundation

struct TreePal: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var code: String
}

struct FriendsBook: Codable, Equatable {
    var inviteClaimed: Bool = false
    var pals: [TreePal] = []

    static func load() -> FriendsBook {
        let url = fileURL()
        guard let data = try? Data(contentsOf: url),
              let book = try? JSONDecoder().decode(FriendsBook.self, from: data) else {
            return FriendsBook()
        }
        return book
    }

    func save() {
        let url = Self.fileURL()
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: .atomic)
        GoobyFiles.exclude(url)
    }

    private static func fileURL() -> URL {
        GoobyFiles.supportDirectory().appendingPathComponent("friends-tree.json")
    }
}

enum GoobyFriendCode {
    private static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func make(profileID: UUID) -> String {
        let uuid = profileID.uuid
        var bytes = [UInt8]()
        bytes.reserveCapacity(16)
        withUnsafeBytes(of: uuid) { raw in
            bytes.append(contentsOf: raw)
        }
        var value: UInt64 = 1469598103934665603
        for byte in bytes {
            value ^= UInt64(byte)
            value = value &* 1099511628211
        }
        var code = "G"
        for _ in 0..<7 {
            code.append(alphabet[Int(value % UInt64(alphabet.count))])
            value /= UInt64(alphabet.count)
            if value == 0 { value = 17 }
        }
        return code
    }

    static func normalize(_ raw: String) -> String {
        String(raw.uppercased().filter { $0.isLetter || $0.isNumber })
    }

    static func isShape(_ code: String) -> Bool {
        guard code.count == 8, code.first == "G" else { return false }
        let allowed = Set(alphabet)
        return code.dropFirst().allSatisfy { allowed.contains($0) }
    }
}
