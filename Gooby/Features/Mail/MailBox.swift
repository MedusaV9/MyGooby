import Foundation
import Observation

struct MailNote: Identifiable, Hashable {
    var id: String
    var title: String
    var body: String
    var date: Date
}

extension Notification.Name {
    static let goobyMailArrived = Notification.Name("gooby.mail.arrived")
}

@MainActor
final class MailCarrier: FriendsCarrier {
    static let shared = MailCarrier()
    var next: (any FriendsCarrier)?

    func install() {
        let lane = FriendsLane.shared
        if let current = lane.carrier, current is MailCarrier { return }
        next = lane.carrier
        lane.carrier = self
    }

    func carry(_ note: FriendsDispatch) {
        next?.carry(note)
        NotificationCenter.default.post(name: .goobyMailArrived, object: nil)
    }
}

@MainActor
@Observable
final class MailReadLedger {
    static let shared = MailReadLedger()
    private(set) var ids: Set<String>

    init() {
        let url = GoobyFiles.supportDirectory().appendingPathComponent("gooby-mail-read.json")
        if let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([String].self, from: data) {
            ids = Set(list)
        } else {
            ids = []
        }
    }

    func seen(_ id: String) -> Bool { ids.contains(id) }

    func mark(_ id: String) {
        guard !ids.contains(id) else { return }
        var next = ids
        next.insert(id)
        ids = next
        guard let data = try? JSONEncoder().encode(next.sorted()) else { return }
        let url = GoobyFiles.supportDirectory().appendingPathComponent("gooby-mail-read.json")
        try? data.write(to: url, options: .atomic)
        GoobyFiles.exclude(url)
    }
}

@MainActor
enum MailBox {
    static func petName(_ engine: GoobyEngine) -> String {
        let trimmed = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Gooby" : trimmed
    }

    static func boxTitle(_ engine: GoobyEngine) -> String {
        let who = petName(engine)
        if engine.languageCode != "en", let last = who.lowercased().last, "sßxz".contains(last) {
            return engine.tf("mail.titleOf", who)
        }
        return engine.tf("mail.title", who)
    }

    static func letters(_ engine: GoobyEngine, notes: [FriendsDispatch]) -> [MailNote] {
        let who = petName(engine)
        var rows: [MailNote] = []
        for run in engine.all(AdventureRun.self) where run.status == "claimed" {
            rows.append(trip(engine, run, who: who))
        }
        for found in engine.all(DiscoveryRecord.self) {
            if let note = discovery(engine, found) { rows.append(note) }
        }
        for note in notes {
            let raw = note.palName.trimmingCharacters(in: .whitespacesAndNewlines)
            let pal = raw.isEmpty ? engine.t("mail.friend.someone") : raw
            let body = FriendsNoteCopy.line(engine, note)
            guard !body.isEmpty else { continue }
            rows.append(MailNote(
                id: "pal-\(note.id.uuidString)",
                title: engine.tf("mail.friend.title", pal),
                body: body,
                date: note.createdAt
            ))
        }
        if let day = dayLetter(engine, who: who) { rows.append(day) }
        return rows.sorted { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            return lhs.id > rhs.id
        }
    }

    private static func trip(_ engine: GoobyEngine, _ run: AdventureRun, who: String) -> MailNote {
        let place = engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode) ?? run.placeID
        let story = engine.catalog.storiesByID[run.storyID]
        let storyBody = story?.body.text(engine.languageCode) ?? ""
        let title: String
        let body: String
        if let story, !storyBody.isEmpty {
            let name = story.title.text(engine.languageCode)
            title = name.isEmpty ? engine.tf("mail.trip.title", place) : name
            body = storyBody + "\n\n" + engine.tf("mail.trip.sign", who)
        } else {
            title = engine.tf("mail.trip.title", place)
            body = engine.tf("mail.trip.body", who, place)
        }
        return MailNote(
            id: "run-\(run.id.uuidString)",
            title: title,
            body: body,
            date: run.claimedAt ?? run.returnsAt
        )
    }

    private static func discovery(_ engine: GoobyEngine, _ found: DiscoveryRecord) -> MailNote? {
        guard let place = engine.catalog.placesByID[found.placeID],
              let item = place.discoveries.first(where: { $0.id == found.discoveryID }) else { return nil }
        let body = item.detail.text(engine.languageCode)
        guard !body.isEmpty else { return nil }
        let title = item.name.text(engine.languageCode)
        return MailNote(
            id: "found-\(found.discoveryID)",
            title: title.isEmpty ? found.discoveryID : title,
            body: body,
            date: found.foundAt
        )
    }

    private static func dayLetter(_ engine: GoobyEngine, who: String) -> MailNote? {
        let key = engine.dayKey()
        let progress = engine.todayProgress()
        let mood = engine.all(MoodEntry.self)
            .filter { $0.dayKey == key }
            .sorted { $0.recordedAt > $1.recordedAt }
            .first
        let journals = engine.all(JournalEntry.self).filter {
            $0.dayKey == key && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard progress.done > 0 || mood != nil || !journals.isEmpty else { return nil }
        var lines = [engine.tf("mail.day.hello", who)]
        if progress.total > 0 {
            lines.append(engine.tf("mail.day.goals", progress.done, progress.total))
        }
        if let mood {
            let level = min(5, max(1, mood.level))
            lines.append(engine.tf("mail.day.mood", engine.t("mood.level.\(level)")))
        }
        if !journals.isEmpty {
            let titles = journals.prefix(3).map(\.title).joined(separator: ", ")
            lines.append(engine.tf("mail.day.notes", titles))
        }
        let streak = engine.streak()
        if streak > 0 { lines.append(engine.tf("mail.day.streak", streak)) }
        lines.append(engine.tf("mail.trip.sign", who))
        return MailNote(
            id: "day-\(key)",
            title: engine.tf("mail.day.title", who),
            body: lines.joined(separator: "\n\n"),
            date: engine.now()
        )
    }
}
