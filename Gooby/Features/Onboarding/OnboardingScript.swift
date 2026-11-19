import Foundation

struct OnboardingEgg: Identifiable, Hashable {
    var id: String
    var shell: UInt32
    var spots: UInt32
    var nameKey: String
}

struct OnboardingTrait: Identifiable, Hashable {
    var id: String
    var nameKey: String
    var symbol: String
}

struct OnboardingOption: Identifiable, Hashable {
    var id: String
    var titleKey: String
    var symbol: String?
    var tint: UInt32?
}

struct OnboardingQuestion: Identifiable, Hashable {
    var id: String
    var section: Int
    var titleKey: String
    var hintKey: String
    var centered: Bool
    var multi: Bool
    var options: [OnboardingOption]
}

/// Copy, egg colors, and the fixed starter plan for the first-start theater.
/// Quiz answers other than support areas stay in the view. They do not change the app.
enum OnboardingScript {
    static let names = [
        "Gooby", "Momo", "Pip", "Clover", "Mochi", "Pebble", "Nori", "Fig",
        "Lumi", "Plum", "Bean", "Dot", "Bramble", "Miso", "Thistle", "Pollen", "Coco", "Hopps"
    ]

    /// Circle starts at the top and runs clockwise. Lilac sits on the left, like the gray egg in the film.
    static let eggs: [OnboardingEgg] = [
        OnboardingEgg(id: "fur-sky", shell: 0xD7F0FA, spots: 0x7EB6E0, nameKey: "onb.egg.sky"),
        OnboardingEgg(id: "fur-honey", shell: 0xFFE3B8, spots: 0xF0A35A, nameKey: "onb.egg.honey"),
        OnboardingEgg(id: "fur-peach", shell: 0xFFD6E2, spots: 0xF094B0, nameKey: "onb.egg.peach"),
        OnboardingEgg(id: "fur-mint", shell: 0xD9F5E4, spots: 0x7DCA9A, nameKey: "onb.egg.mint"),
        OnboardingEgg(id: "fur-cream", shell: 0xF4F0EA, spots: 0xC8C2BA, nameKey: "onb.egg.cream"),
        OnboardingEgg(id: "fur-lilac", shell: 0xE4D7F5, spots: 0xB9A4DE, nameKey: "onb.egg.lilac")
    ]

    static let defaultEggIndex = 5
    /// The animal is always this coat. Egg ids only color the shell.
    static let rabbitFur = "fur-cream"
    static let skipFur = rabbitFur

    static let pronouns = ["he/him", "she/her", "they/them"]

    static let traits: [OnboardingTrait] = [
        OnboardingTrait(id: "curiosity", nameKey: "onb.trait.curiosity", symbol: "magnifyingglass"),
        OnboardingTrait(id: "resilience", nameKey: "onb.trait.resilience", symbol: "backpack.fill"),
        OnboardingTrait(id: "compassion", nameKey: "onb.trait.compassion", symbol: "heart.fill"),
        OnboardingTrait(id: "logic", nameKey: "onb.trait.logic", symbol: "brain.head.profile"),
        OnboardingTrait(id: "confidence", nameKey: "onb.trait.confidence", symbol: "star.fill"),
        OnboardingTrait(id: "security", nameKey: "onb.trait.security", symbol: "shield.fill")
    ]

    static let sectionKeys = [
        "onb.section.about",
        "onb.section.energy",
        "onb.section.home",
        "onb.section.areas"
    ]

    static let areas: [OnboardingOption] = [
        OnboardingOption(id: "gratitude", titleKey: "onb.area.gratitude", symbol: "sun.max.fill", tint: 0xF6C445),
        OnboardingOption(id: "focus", titleKey: "onb.area.focus", symbol: "scope", tint: 0xE25B4A),
        OnboardingOption(id: "eating", titleKey: "onb.area.eating", symbol: "fork.knife", tint: 0xE23B3B),
        OnboardingOption(id: "acceptance", titleKey: "onb.area.acceptance", symbol: "face.smiling.fill", tint: 0xF2B43A),
        OnboardingOption(id: "routine", titleKey: "onb.area.routine", symbol: "leaf.fill", tint: 0x7BC67B),
        OnboardingOption(id: "connection", titleKey: "onb.area.connection", symbol: "phone.fill", tint: 0xE23B3B),
        OnboardingOption(id: "move", titleKey: "onb.area.move", symbol: "figure.walk", tint: 0xE23B4A),
        OnboardingOption(id: "hygiene", titleKey: "onb.area.hygiene", symbol: "sparkles", tint: 0x4AA3E8),
        OnboardingOption(id: "stress", titleKey: "onb.area.stress", symbol: "wind", tint: 0x5B6B7A),
        OnboardingOption(id: "sleep", titleKey: "onb.area.sleep", symbol: "moon.zzz.fill", tint: 0xF2C14B)
    ]

    static var areaIDs: [String] { areas.map(\.id) }

    static let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: "age", section: 0, titleKey: "onb.q.age", hintKey: "onb.q.age.hint", centered: true, multi: false,
            options: [
                OnboardingOption(id: "u18", titleKey: "onb.opt.age.u18"),
                OnboardingOption(id: "18", titleKey: "onb.opt.age.18"),
                OnboardingOption(id: "25", titleKey: "onb.opt.age.25"),
                OnboardingOption(id: "35", titleKey: "onb.opt.age.35"),
                OnboardingOption(id: "45", titleKey: "onb.opt.age.45"),
                OnboardingOption(id: "55", titleKey: "onb.opt.age.55"),
                OnboardingOption(id: "65", titleKey: "onb.opt.age.65")
            ]
        ),
        OnboardingQuestion(
            id: "gender", section: 0, titleKey: "onb.q.gender", hintKey: "", centered: true, multi: false,
            options: [
                OnboardingOption(id: "male", titleKey: "onb.opt.gender.male"),
                OnboardingOption(id: "female", titleKey: "onb.opt.gender.female"),
                OnboardingOption(id: "nonbinary", titleKey: "onb.opt.gender.nonbinary"),
                OnboardingOption(id: "undisclosed", titleKey: "onb.opt.gender.undisclosed")
            ]
        ),
        OnboardingQuestion(
            id: "experience", section: 0, titleKey: "onb.q.experience", hintKey: "", centered: false, multi: false,
            options: [
                OnboardingOption(id: "first", titleKey: "onb.opt.experience.first"),
                OnboardingOption(id: "fresh", titleKey: "onb.opt.experience.fresh")
            ]
        ),
        OnboardingQuestion(
            id: "sleep", section: 1, titleKey: "onb.q.sleep", hintKey: "", centered: false, multi: false,
            options: [
                OnboardingOption(id: "under5", titleKey: "onb.opt.sleep.under5", symbol: "moon.zzz.fill", tint: 0xF2C14B),
                OnboardingOption(id: "mid", titleKey: "onb.opt.sleep.mid", symbol: "bed.double.fill", tint: 0x7EB6E0),
                OnboardingOption(id: "full", titleKey: "onb.opt.sleep.full", symbol: "moon.fill", tint: 0xF2C14B),
                OnboardingOption(id: "over9", titleKey: "onb.opt.sleep.over9", symbol: "sun.max.fill", tint: 0xF6C445)
            ]
        ),
        OnboardingQuestion(
            id: "wake", section: 1, titleKey: "onb.q.wake", hintKey: "", centered: true, multi: false,
            options: [
                OnboardingOption(id: "easy", titleKey: "onb.opt.wake.easy"),
                OnboardingOption(id: "sometimes", titleKey: "onb.opt.wake.sometimes"),
                OnboardingOption(id: "hard", titleKey: "onb.opt.wake.hard")
            ]
        ),
        OnboardingQuestion(
            id: "move", section: 1, titleKey: "onb.q.move", hintKey: "", centered: false, multi: false,
            options: [
                OnboardingOption(id: "lots", titleKey: "onb.opt.move.lots", symbol: "figure.walk", tint: 0x7BC67B),
                OnboardingOption(id: "some", titleKey: "onb.opt.move.some", symbol: "figure.walk", tint: 0x4AA3E8),
                OnboardingOption(id: "sit", titleKey: "onb.opt.move.sit", symbol: "chair.fill", tint: 0xF0A35A),
                OnboardingOption(id: "limited", titleKey: "onb.opt.move.limited", symbol: "pause.circle.fill", tint: 0xB9A4DE)
            ]
        ),
        OnboardingQuestion(
            id: "overwhelm", section: 2, titleKey: "onb.q.overwhelm", hintKey: "", centered: false, multi: false,
            options: [
                OnboardingOption(id: "week", titleKey: "onb.opt.overwhelm.week", symbol: "cloud.rain.fill", tint: 0x7EB6E0),
                OnboardingOption(id: "month", titleKey: "onb.opt.overwhelm.month", symbol: "cloud.fill", tint: 0xF0A35A),
                OnboardingOption(id: "manage", titleKey: "onb.opt.overwhelm.manage", symbol: "sun.max.fill", tint: 0xF6C445)
            ]
        ),
        OnboardingQuestion(
            id: "people", section: 2, titleKey: "onb.q.people", hintKey: "", centered: true, multi: false,
            options: [
                OnboardingOption(id: "three", titleKey: "onb.opt.people.three"),
                OnboardingOption(id: "two", titleKey: "onb.opt.people.two"),
                OnboardingOption(id: "one", titleKey: "onb.opt.people.one"),
                OnboardingOption(id: "solo", titleKey: "onb.opt.people.solo")
            ]
        ),
        OnboardingQuestion(
            id: "routine", section: 2, titleKey: "onb.q.routine", hintKey: "", centered: false, multi: false,
            options: [
                OnboardingOption(id: "good", titleKey: "onb.opt.routine.good"),
                OnboardingOption(id: "mixed", titleKey: "onb.opt.routine.mixed"),
                OnboardingOption(id: "hard", titleKey: "onb.opt.routine.hard")
            ]
        ),
        OnboardingQuestion(
            id: "areas", section: 3, titleKey: "onb.q.areas", hintKey: "onb.q.areas.hint", centered: false, multi: true,
            options: areas
        )
    ]

    /// The note always shows these seven, in this order. Morning ones open the day.
    static let starterIDs = [
        "get-out-of-bed", "brush-teeth", "wash-face", "water",
        "stretch-break", "happy-thing", "three-breaths"
    ]
    static let morningIDs: Set<String> = ["get-out-of-bed", "brush-teeth", "wash-face"]

    static func shuffledName(besides current: String) -> String {
        let pool = names.filter { $0.caseInsensitiveCompare(current) != .orderedSame }
        return pool.randomElement() ?? "Gooby"
    }

    static func pose(for trait: String) -> GoobyAnimation {
        switch trait {
        case "curiosity": return .ears
        case "resilience": return .hop
        case "compassion": return .hearts
        case "logic": return .think
        case "confidence": return .dance
        case "security": return .sit
        default: return .idle
        }
    }

    static func symbol(for trait: String) -> String {
        traits.first { $0.id == trait }?.symbol ?? "sparkles"
    }

    /// Writes the seven catalog goals and stops the later home seed from adding a different set.
    @MainActor
    static func plantStarterPlan(engine: GoobyEngine) {
        let store = GoalMetaStore()
        for (index, id) in starterIDs.enumerated() {
            guard let suggestion = GoalCatalog.suggestion(id) else { continue }
            guard let habit = GoalActions.addSuggestion(suggestion, engine: engine, store: store) else { continue }
            habit.sortIndex = index
            habit.priority = 1
            let part = morningIDs.contains(id) ? "morning" : "any"
            GoalActions.update(
                habit,
                title: suggestion.title(engine.languageCode),
                areaID: suggestion.areaID,
                daypart: part,
                energy: suggestion.energy,
                remind: false,
                engine: engine,
                store: store
            )
        }
        store.update { meta in
            meta.didSeed = true
        }
    }
}
