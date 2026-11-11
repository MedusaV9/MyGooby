import Foundation

// Talks to the self-hosted relay in Server/. Every blob is already sealed with a
// pair key. The server only routes and stores ciphertext.
struct OnlineServerClient {
    struct Info: Decodable {
        var service: String
        var version: Int
        var keyRequired: Bool
    }

    struct Slot: Decodable {
        var slot: String
        var blob: Data
        var at: Double
    }

    private struct SlotList: Decodable {
        var slots: [Slot]
    }

    private struct BlobBody: Codable {
        var blob: Data
    }

    private struct InviteBody: Encodable {
        var id: String
        var blob: Data
    }

    let base: URL
    let key: String

    init?(address: String, key: String) {
        var text = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if !text.contains("://") { text = "https://" + text }
        while text.hasSuffix("/") { text.removeLast() }
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host, !host.isEmpty else { return nil }
        base = url
        self.key = key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isSecure: Bool { base.scheme?.lowercased() == "https" }

    func info() async throws -> Info {
        let data = try await send(try request("v1/info"))
        return try JSONDecoder().decode(Info.self, from: data)
    }

    func pull(channel: String, token: String) async throws -> [Slot] {
        let data = try await send(try request("v1/channels/\(channel)", token: token))
        return try JSONDecoder().decode(SlotList.self, from: data).slots
    }

    func push(channel: String, slot: String, token: String, blob: Data) async throws {
        let body = try JSONEncoder().encode(BlobBody(blob: blob))
        _ = try await send(try request("v1/channels/\(channel)/\(slot)", method: "PUT", token: token, body: body))
    }

    func postInvite(id: String, blob: Data) async throws {
        let body = try JSONEncoder().encode(InviteBody(id: id, blob: blob))
        _ = try await send(try request("v1/invites", method: "POST", body: body))
    }

    func claimInvite(id: String) async throws -> Data {
        let data = try await send(try request("v1/invites/\(id)/claim", method: "POST", body: Data("{}".utf8)))
        return try JSONDecoder().decode(BlobBody.self, from: data).blob
    }

    private func endpoint(_ path: String) throws -> URL {
        var root = base.absoluteString
        if !root.hasSuffix("/") { root += "/" }
        guard let rooted = URL(string: root),
              let url = URL(string: path, relativeTo: rooted)?.absoluteURL,
              url.host == base.host else { throw SyncError.badURL }
        return url
    }

    private func request(_ path: String, method: String = "GET", token: String? = nil, body: Data? = nil) throws -> URLRequest {
        var request = URLRequest(url: try endpoint(path))
        request.httpMethod = method
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if !key.isEmpty { request.setValue(key, forHTTPHeaderField: "X-Gooby-Key") }
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw SyncError.http(status) }
        return data
    }
}
