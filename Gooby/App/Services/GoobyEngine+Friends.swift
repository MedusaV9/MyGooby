import Foundation

// Local NPC friends (masterprompt section 24). Gooby meets Momo, Luna, Pino and Nini offline;
// there are no online friends, invites or friend codes. No schema change: unlocks come from
// finished adventures, a visit is an idempotent RewardLedger row "npc.visit.<id>.<dayKey>", the
// friendship level counts those rows, and the letters in the bag are derived from them.

/// A localized line with its German and English text inline (see `GoobyEngine.tx`).
struct SocialLine: Hashable {
    var key: String
    var de: String
    var en: String

    init(_ key: String, de: String, en: String) {
        self.key = key
        self.de = de
        self.en = en
    }
}

struct SocialNPC: Identifiable, Hashable {
    var id: String
    /// Head drawn by `SocialNPCHead`.
    var species: String
    var name: String
    /// "Momo, der kleine Bär".
    var title: SocialLine
    /// Finished adventures needed to meet this friend.
    var unlockAdventures: Int
    /// Tile color behind the head.
    var color: UInt32
    var welcome: SocialLine
    var stories: [SocialLine]

    static let all: [SocialNPC] = [
        SocialNPC(
            id: "momo",
            species: "bear",
            name: "Momo",
            title: SocialLine("social.npc.momo.title", de: "Momo, der kleine Bär", en: "Momo the little bear"),
            unlockAdventures: 0,
            color: 0xF47B4F,
            welcome: SocialLine("social.npc.momo.welcome", de: "Hallo! Ich bin Momo und wohne gleich hinter dem großen Baum. Komm mich besuchen, ich teile gern meinen Honigtee.", en: "Hi! I'm Momo and I live right behind the big tree. Come visit me, I love sharing my honey tea."),
            stories: [
                SocialLine("social.npc.momo.story.0", de: "Momo und Gooby haben Honigtee getrunken und den Wolken Namen gegeben.", en: "Momo and Gooby sipped honey tea and gave the clouds names."),
                SocialLine("social.npc.momo.story.1", de: "Momo hat Gooby gezeigt, wo die süßesten Beeren wachsen. Ein paar sind sogar im Korb gelandet.", en: "Momo showed Gooby where the sweetest berries grow. A few even made it into the basket."),
                SocialLine("social.npc.momo.story.2", de: "Die beiden haben sich unter den Baum gekuschelt und dem Regen zugehört.", en: "The two of them snuggled under the tree and listened to the rain."),
                SocialLine("social.npc.momo.story.3", de: "Momo hat gebrummt, Gooby hat gesummt. Zusammen klang es fast wie ein Lied.", en: "Momo hummed low, Gooby hummed high. Together it almost sounded like a song."),
                SocialLine("social.npc.momo.story.4", de: "Momo hat erzählt, dass kleine Pausen auch Mut brauchen. Gooby hat genickt.", en: "Momo said that small breaks take courage too. Gooby nodded.")
            ]
        ),
        SocialNPC(
            id: "luna",
            species: "cat",
            name: "Luna",
            title: SocialLine("social.npc.luna.title", de: "Luna, die Katze", en: "Luna the cat"),
            unlockAdventures: 1,
            color: 0x8B4FE0,
            welcome: SocialLine("social.npc.luna.welcome", de: "Miau! Ich habe von deinem ersten Abenteuer gehört. Ich bin Luna und kenne die gemütlichsten Sonnenplätze.", en: "Meow! I heard about your first adventure. I'm Luna and I know all the coziest sunny spots."),
            stories: [
                SocialLine("social.npc.luna.story.0", de: "Luna und Gooby haben sich den wärmsten Sonnenfleck auf der Fensterbank geteilt.", en: "Luna and Gooby shared the warmest patch of sun on the windowsill."),
                SocialLine("social.npc.luna.story.1", de: "Luna hat Gooby beigebracht, sich ganz lang zu strecken. Danach waren beide wach und froh.", en: "Luna taught Gooby a really long stretch. Afterwards both felt awake and happy."),
                SocialLine("social.npc.luna.story.2", de: "Die beiden haben ein Wollknäuel quer durch das Zimmer gerollt und viel gelacht.", en: "The two of them rolled a ball of yarn across the room and laughed a lot."),
                SocialLine("social.npc.luna.story.3", de: "Luna hat geschnurrt, bis Gooby ganz ruhig geatmet hat.", en: "Luna purred until Gooby was breathing slow and calm."),
                SocialLine("social.npc.luna.story.4", de: "Luna hat Gooby die Sterne gezeigt, die man nur von ihrem Dach aus sieht.", en: "Luna showed Gooby the stars you can only see from her roof.")
            ]
        ),
        SocialNPC(
            id: "pino",
            species: "fox",
            name: "Pino",
            title: SocialLine("social.npc.pino.title", de: "Pino, der Fuchs", en: "Pino the fox"),
            unlockAdventures: 3,
            color: 0x3EB5E8,
            welcome: SocialLine("social.npc.pino.welcome", de: "Hey, Abenteurer! Ich bin Pino. Drei Reisen schon? Dann lass uns Karten tauschen und Pläne schmieden.", en: "Hey, adventurer! I'm Pino. Three trips already? Let's swap maps and make plans."),
            stories: [
                SocialLine("social.npc.pino.story.0", de: "Pino und Gooby haben eine Schatzkarte gemalt. Der Schatz war am Ende ein besonders schöner Stein.", en: "Pino and Gooby drew a treasure map. The treasure turned out to be a very pretty pebble."),
                SocialLine("social.npc.pino.story.1", de: "Pino hat Gooby ein Versteck im hohen Gras gezeigt, perfekt zum Ausruhen.", en: "Pino showed Gooby a hideout in the tall grass, perfect for a rest."),
                SocialLine("social.npc.pino.story.2", de: "Die beiden sind um die Wette gehüpft. Gewonnen haben beide.", en: "The two of them had a hopping race. Both of them won."),
                SocialLine("social.npc.pino.story.3", de: "Pino hat von seinem längsten Ausflug erzählt und Gooby hat staunend zugehört.", en: "Pino told the story of his longest trip and Gooby listened in awe."),
                SocialLine("social.npc.pino.story.4", de: "Pino hat Gooby gezeigt, wie man Pläne macht, die auch mal schiefgehen dürfen.", en: "Pino showed Gooby how to make plans that are allowed to go wrong sometimes.")
            ]
        ),
        SocialNPC(
            id: "nini",
            species: "chick",
            name: "Nini",
            title: SocialLine("social.npc.nini.title", de: "Nini, das Küken", en: "Nini the chick"),
            unlockAdventures: 6,
            color: 0xF7C540,
            welcome: SocialLine("social.npc.nini.welcome", de: "Piep piep! Ich bin Nini. Ich habe so lange gewartet, bis du hier vorbeikommst. Wollen wir Freunde sein?", en: "Cheep cheep! I'm Nini. I waited so long for you to come by. Shall we be friends?"),
            stories: [
                SocialLine("social.npc.nini.story.0", de: "Nini und Gooby haben Gänseblümchen gezählt. Bei siebenundzwanzig haben sie aufgehört und gekichert.", en: "Nini and Gooby counted daisies. At twenty-seven they stopped and giggled."),
                SocialLine("social.npc.nini.story.1", de: "Nini hat Gooby ihr neues Lied vorgepiepst. Gooby hat dazu geklatscht.", en: "Nini cheeped her new song for Gooby. Gooby clapped along."),
                SocialLine("social.npc.nini.story.2", de: "Die beiden haben in einer Pfütze den Himmel angeschaut.", en: "The two of them looked at the sky in a puddle."),
                SocialLine("social.npc.nini.story.3", de: "Nini hat Gooby erzählt, dass man auch mit kleinen Flügeln weit kommt.", en: "Nini told Gooby that small wings can still take you far."),
                SocialLine("social.npc.nini.story.4", de: "Nini und Gooby haben ein Nest aus Blättern gebaut und darin ein Nickerchen gemacht.", en: "Nini and Gooby built a nest of leaves and took a nap in it.")
            ]
        )
    ]

    /// Star sparks each visit brings (once per friend and app day).
    static let visitSparks = 5
    /// Visits needed for friendship levels 2 to 5.
    static let levelSteps = [2, 5, 9, 14]

    static func find(_ id: String) -> SocialNPC? { all.first { $0.id == id } }
}

/// A letter in the bag's mail: a welcome note from a new friend or the story of a visit.
struct SocialLetter: Identifiable, Hashable {
    var id: String
    var npcID: String
    var date: Date
    var text: String
    var welcome: Bool
}

extension GoobyEngine {
    func tx(_ line: SocialLine) -> String { tx(line.key, de: line.de, en: line.en) }

    func socialFinishedAdventures() -> Int {
        all(AdventureRun.self).filter { $0.status == "claimed" }.count
    }

    func socialIsUnlocked(_ npc: SocialNPC) -> Bool {
        socialFinishedAdventures() >= npc.unlockAdventures
    }

    func socialUnlocked() -> [SocialNPC] {
        let done = socialFinishedAdventures()
        return SocialNPC.all.filter { done >= $0.unlockAdventures }
    }

    func socialVisitKey(_ npc: SocialNPC, dayKey key: String) -> String {
        "npc.visit.\(npc.id).\(key)"
    }

    func socialVisitedToday(_ npc: SocialNPC) -> Bool {
        let key = socialVisitKey(npc, dayKey: dayKey())
        return all(RewardLedger.self).contains { $0.key == key }
    }

    func socialVisitCount(_ npc: SocialNPC) -> Int {
        let prefix = "npc.visit.\(npc.id)."
        return all(RewardLedger.self).filter { $0.key.hasPrefix(prefix) }.count
    }

    /// Friendship level 1 to 5.
    func socialLevel(_ npc: SocialNPC) -> Int {
        let visits = socialVisitCount(npc)
        return 1 + SocialNPC.levelSteps.filter { visits >= $0 }.count
    }

    /// Visits still needed for the next level, nil at level 5.
    func socialVisitsToNextLevel(_ npc: SocialNPC) -> Int? {
        let visits = socialVisitCount(npc)
        guard let next = SocialNPC.levelSteps.first(where: { visits < $0 }) else { return nil }
        return next - visits
    }

    /// The story of a visit on `key`'s day. Deterministic, so the mail can show it again later.
    func socialStory(_ npc: SocialNPC, dayKey key: String) -> String {
        guard !npc.stories.isEmpty else { return "" }
        let seed = ShopRotation.seed(dayKey: key, category: "npc-\(npc.id)", appSeed: profile.appSeed)
        return tx(npc.stories[Int(seed % UInt64(npc.stories.count))])
    }

    /// Visits `npc` today: grants the sparks gift once per friend and app day.
    /// Returns false when the friend is still locked or was already visited today.
    @discardableResult
    func socialVisit(_ npc: SocialNPC) -> Bool {
        refreshDay()
        guard socialIsUnlocked(npc) else { return false }
        guard grant(key: socialVisitKey(npc, dayKey: dayKey()), sparks: SocialNPC.visitSparks, energy: 0) else { return false }
        animation = .hearts
        celebration += 1
        haptics.celebrate()
        log("npc visit \(npc.id)")
        save()
        return true
    }

    /// Welcome letters of every friend met so far plus one letter per visit, newest first.
    func socialLetters() -> [SocialLetter] {
        let claimed = all(AdventureRun.self)
            .filter { $0.status == "claimed" }
            .map { $0.claimedAt ?? $0.returnsAt }
            .sorted()
        var letters: [SocialLetter] = []
        for npc in SocialNPC.all where claimed.count >= npc.unlockAdventures {
            let met = npc.unlockAdventures == 0 ? profile.createdAt : claimed[npc.unlockAdventures - 1]
            letters.append(SocialLetter(id: "welcome.\(npc.id)", npcID: npc.id, date: met, text: tx(npc.welcome), welcome: true))
        }
        let rows = all(RewardLedger.self)
        for npc in SocialNPC.all {
            let prefix = "npc.visit.\(npc.id)."
            for row in rows where row.key.hasPrefix(prefix) {
                let key = String(row.key.dropFirst(prefix.count))
                letters.append(SocialLetter(id: row.key, npcID: npc.id, date: row.createdAt, text: socialStory(npc, dayKey: key), welcome: false))
            }
        }
        return letters.sorted { $0.date > $1.date }
    }

    /// Place of the latest adventure, or the first open place before any adventure.
    func socialCurrentPlace() -> PlaceDef? {
        let runs = all(AdventureRun.self).sorted { $0.startedAt > $1.startedAt }
        if let run = runs.first, let place = catalog.placesByID[run.placeID] { return place }
        return catalog.places.first { isPlaceUnlocked($0.id) } ?? catalog.places.first
    }
}
