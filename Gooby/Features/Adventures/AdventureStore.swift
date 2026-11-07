import Foundation
import Observation

@MainActor
@Observable
final class AdventureStore {
    private(set) var save: AdventureSave
    private(set) var catalogLoad: AdventureCatalogLoad
    var previewStoryID: String?
    var banner: AdventureBanner?

    private let memoryOnly: Bool
    private let fileURL: URL
    private var startInFlight = false

    static let shared = AdventureStore(memoryOnly: false)

    var catalog: AdventureCatalog { catalogLoad.catalog }

    init(memoryOnly: Bool, fileURL: URL? = nil) {
        self.memoryOnly = memoryOnly
        self.fileURL = fileURL ?? Self.defaultURL()
        self.catalogLoad = AdventureCatalogLoader.load()
        if memoryOnly {
            self.save = .fresh()
        } else {
            self.save = Self.read(from: self.fileURL) ?? .fresh()
        }
    }

    func phase(energy: Int, energyGoal: Int, appNow: Date, wallNow: Date) -> AdventurePhase {
        AdventureEngine.phase(
            save: save,
            energy: energy,
            energyGoal: energyGoal,
            appNow: appNow,
            wallNow: wallNow
        )
    }

    func startAdventure(bridge: AdventureBridge, wallNow: Date) -> AdventureStartError? {
        guard !startInFlight else { return .notReady }
        startInFlight = true
        defer { startInFlight = false }

        let current = phase(energy: bridge.energy, energyGoal: bridge.energyGoal, appNow: bridge.appNow, wallNow: wallNow)
        guard case .ready = current else {
            banner = nil
            return .notReady
        }
        let placeID = AdventureEngine.destinationID(save: save, catalog: catalog)
        guard let place = catalog.place(id: placeID), AdventureEngine.isUnlocked(place, save: save) else {
            banner = .placeLocked
            return .placeLocked
        }
        guard let story = AdventureEngine.storyForStart(placeID: place.id, save: save, catalog: catalog) else {
            return .missingStory
        }
        let goal = max(bridge.energyGoal, 0)
        if goal > 0 {
            guard bridge.onSpendEnergy(goal) else {
                banner = .energyRefused
                return .energyRefused
            }
        }
        var next = save
        if next.queuedStoryID == story.id {
            next.queuedStoryID = nil
        }
        next.selectedPlaceID = place.id
        next.active = AdventureActiveTrip(
            id: UUID().uuidString,
            placeID: place.id,
            storyID: story.id,
            startedAt: wallNow,
            returnsAt: wallNow.addingTimeInterval(TimeInterval(place.durationMinutes * 60)),
            appDayKey: AdventureEngine.dayKey(for: bridge.appNow),
            countsAsDaily: true
        )
        save = next
        banner = nil
        persist()
        return nil
    }

    @discardableResult
    func claim(tripID: String, choiceID: String, bridge: AdventureBridge, wallNow: Date) -> AdventureJournalEntry? {
        guard let trip = save.active, trip.id == tripID else { return nil }
        guard let story = catalog.story(id: trip.storyID),
              let choice = story.choices.first(where: { $0.id == choiceID }) else { return nil }
        return commit(
            story: story,
            choice: choice,
            placeID: trip.placeID,
            dayKey: trip.appDayKey,
            countsAsDaily: trip.countsAsDaily,
            clearActive: true,
            bridge: bridge,
            wallNow: wallNow
        )
    }

    @discardableResult
    func claimPreview(storyID: String, choiceID: String, bridge: AdventureBridge, wallNow: Date) -> AdventureJournalEntry? {
        guard previewStoryID == storyID,
              let story = catalog.story(id: storyID),
              let choice = story.choices.first(where: { $0.id == choiceID }) else { return nil }
        let already = save.previewRewardedStoryIDs.contains(storyID)
        return commit(
            story: story,
            choice: choice,
            placeID: story.placeID,
            dayKey: AdventureEngine.dayKey(for: bridge.appNow),
            countsAsDaily: false,
            clearActive: false,
            grantRewards: !already,
            bridge: bridge,
            wallNow: wallNow
        )
    }

    func completeCurrent(wallNow: Date) {
        guard var trip = save.active else { return }
        trip.returnsAt = wallNow.addingTimeInterval(-1)
        var next = save
        next.active = trip
        save = next
        persist()
    }

    func resetProgress() {
        save = .fresh()
        previewStoryID = nil
        banner = nil
        persist()
    }

    func setAllPlacesUnlocked(_ unlocked: Bool) {
        var next = save
        next.allPlacesUnlocked = unlocked
        save = next
        persist()
    }

    func queueStory(id: String?) {
        var next = save
        if let id, catalog.story(id: id) != nil {
            next.queuedStoryID = id
            if let placeID = catalog.story(id: id)?.placeID {
                next.selectedPlaceID = placeID
            }
        } else {
            next.queuedStoryID = nil
        }
        save = next
        persist()
    }

    func beginPreview(storyID: String) {
        guard catalog.story(id: storyID) != nil else { return }
        previewStoryID = storyID
    }

    func endPreview() {
        previewStoryID = nil
    }

    func selectPlace(id: String) {
        guard let place = catalog.place(id: id), AdventureEngine.isUnlocked(place, save: save) else { return }
        var next = save
        next.selectedPlaceID = id
        save = next
        persist()
    }

    func setTrait(_ key: String, value: Int) {
        guard AdventureTrait(rawValue: key) != nil else { return }
        var next = save
        next.traits[key] = min(AdventureEngine.traitMaximum, max(0, value))
        save = next
        persist()
    }

    func clearBanner() {
        banner = nil
    }

    var savePath: String { fileURL.path }

    private func commit(
        story: AdventureStoryDefinition,
        choice: AdventureChoiceDefinition,
        placeID: String,
        dayKey: String,
        countsAsDaily: Bool,
        clearActive: Bool,
        grantRewards: Bool = true,
        bridge: AdventureBridge,
        wallNow: Date
    ) -> AdventureJournalEntry {
        var next = save
        var applied: [String: Int] = [:]
        var discoveryID: String?
        var sparks = 0
        if grantRewards {
            applied = AdventureEngine.apply(deltas: choice.traits, to: &next.traits)
            if let id = choice.discoveryID, !next.foundDiscoveryIDs.contains(id) {
                next.foundDiscoveryIDs.append(id)
                discoveryID = id
            }
            sparks = story.sparkReward
            if !countsAsDaily, !next.previewRewardedStoryIDs.contains(story.id) {
                next.previewRewardedStoryIDs.append(story.id)
            }
        }
        if countsAsDaily {
            next.completedCount += 1
            next.placeVisits[placeID, default: 0] += 1
            if !next.seenStoryIDs.contains(story.id) {
                next.seenStoryIDs.append(story.id)
            }
            next.lastResolvedDayKey = dayKey
        }
        let entry = AdventureJournalEntry(
            id: UUID().uuidString,
            storyID: story.id,
            placeID: placeID,
            choiceID: choice.id,
            sparks: sparks,
            discoveryID: discoveryID,
            traitDeltas: applied,
            dayKey: dayKey,
            claimedAt: wallNow,
            preview: !countsAsDaily
        )
        next.journal.insert(entry, at: 0)
        if next.journal.count > 40 {
            next.journal.removeLast(next.journal.count - 40)
        }
        if clearActive {
            next.active = nil
        }
        save = next
        persist()
        if sparks > 0 {
            bridge.onGrantSparks(sparks)
        }
        if !applied.isEmpty {
            bridge.onPersonalityShift(AdventurePersonalityDelta(traits: applied))
        }
        return entry
    }

    private func persist() {
        guard !memoryOnly else { return }
        do {
            let folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var folderValues = URLResourceValues()
            folderValues.isExcludedFromBackup = true
            var folderURL = folder
            try? folderURL.setResourceValues(folderValues)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(save)
            let temporary = folder.appendingPathComponent("save-\(UUID().uuidString).tmp")
            try data.write(to: temporary, options: [.atomic])
            if FileManager.default.fileExists(atPath: fileURL.path) {
                _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: temporary)
            } else {
                try FileManager.default.moveItem(at: temporary, to: fileURL)
            }
            var saved = fileURL
            try? saved.setResourceValues(folderValues)
            if FileManager.default.fileExists(atPath: temporary.path) {
                try? FileManager.default.removeItem(at: temporary)
            }
        } catch {
            // Der Spielstand im Speicher bleibt erhalten. Der nächste erfolgreiche Schreibversuch holt die Datei nach.
        }
    }

    private static func read(from url: URL) -> AdventureSave? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode(AdventureSave.self, from: data), decoded.version == AdventureSave.currentVersion {
            return decoded.normalized()
        }
        let stamp = Int(Date().timeIntervalSince1970)
        let corrupt = url.deletingLastPathComponent().appendingPathComponent("save-corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: url, to: corrupt)
        return nil
    }

    private static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("GoobyAdventures", isDirectory: true)
            .appendingPathComponent("save.json")
    }
}
