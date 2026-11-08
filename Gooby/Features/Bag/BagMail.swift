import Foundation

struct BagLetter: Identifiable, Hashable {
    var id: String
    var title: String
    var body: String
    var date: Date
}

enum BagMail {
    static func letters(_ engine: GoobyEngine) -> [BagLetter] {
        let name = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let who = name.isEmpty ? "Gooby" : name
        var rows = [
            BagLetter(
                id: "welcome",
                title: engine.t("bag.mail.welcomeTitle"),
                body: engine.tf("bag.mail.welcomeBody", who),
                date: engine.profile.createdAt
            )
        ]
        for run in engine.all(AdventureRun.self) where run.status == "claimed" {
            let placeName = engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode) ?? run.placeID
            rows.append(BagLetter(
                id: "run-\(run.id.uuidString)",
                title: engine.tf("bag.mail.tripTitle", placeName),
                body: engine.tf("bag.mail.tripBody", who, placeName),
                date: run.claimedAt ?? run.returnsAt
            ))
        }
        for found in engine.all(DiscoveryRecord.self) {
            let place = engine.catalog.placesByID[found.placeID]
            guard let discovery = place?.discoveries.first(where: { $0.id == found.discoveryID }) else { continue }
            let body = discovery.detail.text(engine.languageCode)
            guard !body.isEmpty else { continue }
            rows.append(BagLetter(
                id: "found-\(found.discoveryID)",
                title: discovery.name.text(engine.languageCode),
                body: body,
                date: found.foundAt
            ))
        }
        return rows.sorted { $0.date > $1.date }
    }

    static func isRead(_ id: String) -> Bool {
        readIDs().contains(id)
    }

    static func markRead(_ id: String) {
        var ids = readIDs()
        guard ids.insert(id).inserted else { return }
        guard let data = try? JSONEncoder().encode(Array(ids).sorted()) else { return }
        let url = fileURL()
        try? data.write(to: url, options: .atomic)
        GoobyFiles.exclude(url)
    }

    private static func readIDs() -> Set<String> {
        guard let data = try? Data(contentsOf: fileURL()),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return Set(ids)
    }

    private static func fileURL() -> URL {
        GoobyFiles.supportDirectory().appendingPathComponent("bag-mail-read.json")
    }
}
