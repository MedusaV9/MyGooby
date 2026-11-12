import Foundation

enum ActivityLane: String, CaseIterable, Identifiable {
    case ideas
    case reflections
    case breathe
    case soundscapes
    case movements
    case timers
    case kindness
    case aid

    var id: String { rawValue }
    var tileKey: String { "activity.tile.\(rawValue)" }
    var titleKey: String { "activity.lane.\(rawValue)" }

    var canvas: UInt32 {
        switch self {
        case .ideas: return 0x5CB648
        case .reflections: return 0x2E9BE0
        case .breathe: return 0x7346C9
        case .soundscapes: return 0x5648C4
        case .movements: return 0xE45B8C
        case .timers: return 0xE0A020
        case .kindness: return 0x62C04A
        case .aid: return 0xE86A9A
        }
    }
}

enum ActivityRun {
    case breathe
    case sound(String)
    case movement(String)
    case timer
    case grounding
    case calm
    case journal
    case affirmation
}

struct ActivityPiece: Identifiable {
    var id: String
    var title: String
    var detail: String
    var symbol: String
    var tint: UInt32
    var filters: [String]
    var run: ActivityRun
    var badge: String = ""
}

struct ActivityIdeaBundle: Identifiable {
    var id: String
    var symbol: String
    var tint: UInt32
    var titleKey: String?
    var detailKey: String?
    var areaID: String?
    var suggestionIDs: [String]?

    @MainActor
    func title(_ engine: GoobyEngine) -> String {
        if let titleKey { return engine.t(titleKey) }
        if let areaID, let area = GoalCatalog.area(areaID) { return area.name(engine.languageCode) }
        return id
    }

    @MainActor
    func detail(_ engine: GoobyEngine) -> String {
        if let detailKey { return engine.t(detailKey) }
        if let areaID, let area = GoalCatalog.area(areaID) { return area.blurb(engine.languageCode) }
        return ""
    }

    func suggestions() -> [GoalSuggestion] {
        if let suggestionIDs { return suggestionIDs.compactMap { GoalCatalog.suggestion($0) } }
        if let areaID { return GoalCatalog.suggestions(in: areaID) }
        return GoalCatalog.starters.compactMap { GoalCatalog.suggestion($0.id) }
    }
}

struct ActivityKindnessCard: Identifiable, Hashable {
    var id: String
    var filter: String
    var titleKey: String
    var detailKey: String
    var symbol: String
    var tint: UInt32
}

enum ActivityKindnessReward {
    /// Same energy a saved journal entry grants in `GoobyEngine.updateJournal`.
    /// The sheet shows this number; the grant itself is that method, including its daily cap.
    static let energy = 5
}

@MainActor
enum ActivityCatalog {
    static func starID(_ scope: String, _ id: String) -> String {
        "\(scope):\(id)"
    }

    static func starLabel(_ engine: GoobyEngine, on: Bool, title: String) -> String {
        engine.tf(on ? "activity.star.on" : "activity.star.off", title)
    }

    static func filterTitle(_ id: String, _ engine: GoobyEngine) -> String {
        engine.t(id == "all" ? "activity.filter.all" : "activity.filter.\(id)")
    }

    static func filters(for lane: ActivityLane) -> [String] {
        switch lane {
        case .breathe: return ["all", "morning", "energize", "focus", "calm", "night"]
        case .soundscapes: return SoundscapeCatalog.filters
        case .movements: return ["all", "stretch", "yoga", "exercise"]
        case .timers: return ["all", "meditate", "focus"]
        case .kindness: return ["all", "friends", "nearby", "values"]
        case .reflections: return ["all", "morning", "energize", "deep", "calm", "night"]
        default: return ["all"]
        }
    }

    static func matches(
        query: String,
        title: String,
        detail: String,
        filters: [String],
        filter: String,
        starsOnly: Bool,
        starID: String,
        favorites: ActivityFavoriteStore
    ) -> Bool {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let textOK = text.isEmpty
            || title.localizedCaseInsensitiveContains(text)
            || detail.localizedCaseInsensitiveContains(text)
        let filterOK = filter == "all" || filters.contains(filter)
        let starOK = !starsOnly || favorites.contains(starID)
        return textOK && filterOK && starOK
    }

    static func breathe(_ engine: GoobyEngine) -> [ActivityPiece] {
        [
            piece("calm", "activity.breathe.calm", "leaf.fill", 0x3EAE45, ["morning", "calm", "night"], .breathe, "10+", engine),
            piece("energy", "activity.breathe.energy", "bolt.fill", 0xF0A020, ["energize", "morning"], .breathe, "10+", engine),
            piece("ease", "activity.breathe.ease", "wind", 0x7A6AD4, ["calm", "focus"], .breathe, "10+", engine),
            piece("alert", "activity.breathe.alert", "sun.max.fill", 0xE39A1A, ["energize", "focus"], .breathe, "10+", engine)
        ]
    }

    static func sounds(_ engine: GoobyEngine) -> [ActivityPiece] {
        SoundscapeCatalog.scenes.map { scene in
            ActivityPiece(
                id: scene.id,
                title: engine.t("soundscape.\(scene.id).title"),
                detail: engine.t("soundscape.\(scene.id).detail"),
                symbol: scene.symbol,
                tint: scene.tint,
                filters: [scene.filter],
                run: .sound(scene.id)
            )
        }
    }

    static func movements(_ engine: GoobyEngine) -> [ActivityPiece] {
        engine.catalog.exercises.map { exercise in
            ActivityPiece(
                id: exercise.id,
                title: exercise.title.text(engine.languageCode),
                detail: engine.tf("move.minutes", exercise.minutes),
                symbol: movementSymbol(exercise.id),
                tint: 0xE25B93,
                filters: movementFilters(exercise.id),
                run: .movement(exercise.id)
            )
        }
    }

    static func timers(_ engine: GoobyEngine) -> [ActivityPiece] {
        [
            piece("meditate", "activity.timer.meditate", "moon.fill", 0x7A6AD4, ["meditate"], .timer, "5", engine),
            piece("focus", "activity.timer.focus", "timer", 0xE39A1A, ["focus"], .timer, "10+", engine)
        ]
    }

    static func aid(_ engine: GoobyEngine) -> [ActivityPiece] {
        [
            piece("emotion", "activity.aid.emotion", "face.smiling.fill", 0x5AA7E8, [], .grounding, "5", engine),
            piece("affirm", "activity.aid.affirm", "quote.bubble.fill", 0xF0A020, [], .affirmation, "5", engine),
            piece("breath", "activity.aid.breath", "leaf.fill", 0x3EAE45, [], .breathe, "5", engine),
            piece("rest", "activity.aid.rest", "moon.fill", 0x7A6AD4, [], .movement("rest"), "2+", engine),
            piece("colors", "activity.aid.colors", "paintpalette.fill", 0xE25B93, [], .grounding, "5", engine),
            piece("senses", "activity.aid.senses", "eye.fill", 0x3EAE45, [], .grounding, "5", engine),
            piece("body", "activity.aid.body", "figure.walk", 0x5AA7E8, [], .movement("body"), "5", engine)
        ]
    }

    static func pieces(_ lane: ActivityLane, _ engine: GoobyEngine) -> [ActivityPiece] {
        switch lane {
        case .breathe: return breathe(engine)
        case .soundscapes: return sounds(engine)
        case .movements: return movements(engine)
        case .timers: return timers(engine)
        case .aid: return aid(engine)
        default: return []
        }
    }

    static let kindness: [ActivityKindnessCard] = [
        ActivityKindnessCard(id: "thanks", filter: "friends", titleKey: "activity.kindness.thanks.title", detailKey: "activity.kindness.thanks.detail", symbol: "heart.fill", tint: 0xE25B93),
        ActivityKindnessCard(id: "note", filter: "friends", titleKey: "activity.kindness.note.title", detailKey: "activity.kindness.note.detail", symbol: "pencil", tint: 0x5AA7E8),
        ActivityKindnessCard(id: "act", filter: "nearby", titleKey: "activity.kindness.act.title", detailKey: "activity.kindness.act.detail", symbol: "hands.clap.fill", tint: 0x3EAE45),
        ActivityKindnessCard(id: "hand", filter: "nearby", titleKey: "activity.kindness.hand.title", detailKey: "activity.kindness.hand.detail", symbol: "hand.raised.fill", tint: 0xF0A020),
        ActivityKindnessCard(id: "share", filter: "nearby", titleKey: "activity.kindness.share.title", detailKey: "activity.kindness.share.detail", symbol: "gift.fill", tint: 0xE07A3D),
        ActivityKindnessCard(id: "value", filter: "values", titleKey: "activity.kindness.value.title", detailKey: "activity.kindness.value.detail", symbol: "star.fill", tint: 0xE0A322),
        ActivityKindnessCard(id: "reflect", filter: "values", titleKey: "activity.kindness.reflect.title", detailKey: "activity.kindness.reflect.detail", symbol: "quote.bubble.fill", tint: 0x7A6AD4)
    ]

    static func bundles() -> [ActivityIdeaBundle] {
        [
            ActivityIdeaBundle(id: "day", symbol: "sun.max.fill", tint: 0xF2C14E, titleKey: "activity.ideas.day.title", detailKey: "activity.ideas.day.detail", areaID: nil, suggestionIDs: ["get-out-of-bed", "three-breaths", "wash-face", "water", "happy-thing"]),
            ActivityIdeaBundle(id: "tomorrow", symbol: "sun.max.fill", tint: 0xF6A34A, titleKey: "activity.ideas.tomorrow.title", detailKey: "activity.ideas.tomorrow.detail", areaID: nil, suggestionIDs: ["tomorrow-note", "review-plan", "clothes-ready", "kind-line", "phone-away"]),
            ActivityIdeaBundle(id: "sleep", symbol: "moon.stars.fill", tint: 0x8E7CC3, titleKey: "activity.ideas.sleep.title", detailKey: "activity.ideas.sleep.detail", areaID: "sleep", suggestionIDs: ["dim-lights", "breathe-bed", "phone-away", "dark-room", "read-bed"]),
            ActivityIdeaBundle(id: "active", symbol: "shoe.fill", tint: 0xE25B93, titleKey: "activity.ideas.active.title", detailKey: "activity.ideas.active.detail", areaID: "movement", suggestionIDs: ["stretch-break", "stroll-10", "dance", "morning-yoga", "step-outside"]),
            ActivityIdeaBundle(id: "connect", symbol: "person.2.fill", tint: 0xF08A7A, titleKey: "activity.ideas.connect.title", detailKey: "activity.ideas.connect.detail", areaID: "connection", suggestionIDs: ["reach-out", "tell-love", "time-family", "thank-helper", "fond-friend"])
        ]
    }

    static func packPlan(_ bundle: ActivityIdeaBundle) -> [(id: String, daypart: String)] {
        let parts = packDayparts[bundle.id] ?? [:]
        return bundle.suggestions().map { suggestion in
            (suggestion.id, parts[suggestion.id] ?? "any")
        }
    }

    private static let packDayparts: [String: [String: String]] = [
        "day": [
            "get-out-of-bed": "morning",
            "three-breaths": "morning",
            "wash-face": "morning",
            "water": "morning",
            "happy-thing": "any"
        ],
        "tomorrow": [
            "tomorrow-note": "night",
            "review-plan": "evening",
            "clothes-ready": "evening",
            "kind-line": "morning",
            "phone-away": "night"
        ],
        "sleep": [
            "dim-lights": "night",
            "breathe-bed": "night",
            "phone-away": "night",
            "dark-room": "night",
            "read-bed": "night"
        ],
        "active": [
            "stretch-break": "afternoon",
            "stroll-10": "afternoon",
            "dance": "any",
            "morning-yoga": "morning",
            "step-outside": "morning"
        ],
        "connect": [
            "reach-out": "any",
            "tell-love": "evening",
            "time-family": "evening",
            "thank-helper": "any",
            "fond-friend": "any"
        ]
    ]

    static func reflectionChip(_ theme: String) -> String {
        switch theme {
        case "day": return "morning"
        case "motive": return "energize"
        case "mind": return "deep"
        case "stress": return "night"
        default: return "calm"
        }
    }

    static func reflectionSymbol(_ theme: String) -> String {
        switch theme {
        case "gratitude": return "star.fill"
        case "worth": return "heart.fill"
        case "stress": return "wind"
        case "day": return "sun.max.fill"
        case "mind": return "brain.head.profile"
        case "motive": return "bolt.fill"
        case "feel": return "face.smiling.fill"
        default: return "pencil"
        }
    }

    static func reflectionTint(_ theme: String) -> UInt32 {
        switch theme {
        case "gratitude": return 0xE0A322
        case "worth": return 0xE25B93
        case "stress": return 0x7A6AD4
        case "day": return 0xF2C14E
        case "mind": return 0x5AA7E8
        case "motive": return 0xF0A020
        case "feel": return 0x3EAE45
        default: return 0x5AA7E8
        }
    }

    private static func piece(
        _ id: String,
        _ key: String,
        _ symbol: String,
        _ tint: UInt32,
        _ filters: [String],
        _ run: ActivityRun,
        _ badge: String,
        _ engine: GoobyEngine
    ) -> ActivityPiece {
        ActivityPiece(
            id: id,
            title: engine.t("\(key).title"),
            detail: engine.t("\(key).detail"),
            symbol: symbol,
            tint: tint,
            filters: filters,
            run: run,
            badge: badge
        )
    }

    private static func movementFilters(_ id: String) -> [String] {
        switch id {
        case "break": return ["exercise"]
        case "rest": return ["yoga"]
        default: return ["stretch"]
        }
    }

    private static func movementSymbol(_ id: String) -> String {
        switch id {
        case "rest": return "figure.mind.and.body"
        case "break": return "figure.walk"
        default: return "figure.flexibility"
        }
    }
}
