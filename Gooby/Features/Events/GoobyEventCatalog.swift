import Foundation

enum GoobyEventCatalog {
    static let knownObjectiveKinds: Set<String> = [
        "habitDays",
        "habitCount",
        "reflections",
        "calmSessions",
        "companionPlays",
        "visits"
    ]

    static let events: [GoobySeasonalEventDefinition] = [
        event(
            id: "lantern-festival",
            nameDE: "Lichterfest",
            nameEN: "Lantern Festival",
            summaryDE: "Warme Lichter, leise Abende und kleine Versprechen an dich selbst.",
            summaryEN: "Warm lights, quiet evenings, and small promises you make to yourself.",
            start: (2, 1),
            end: (2, 14),
            accent: "#FFD6B3",
            symbol: "lightbulb.fill",
            objectives: [
                objective("visit", "visits", 1, "Die Festtafel ansehen", "Visit the event board"),
                objective("reflect", "reflections", 2, "Zweimal hinspüren", "Check in twice"),
                objective("days", "habitDays", 3, "An drei Tagen für dich sorgen", "Care for yourself on three days")
            ],
            sparks: 40,
            cosmetic: "gooby-season-paper-lantern",
            species: nil
        ),
        event(
            id: "spring-meadow",
            nameDE: "Frühlingswiese",
            nameEN: "Spring Meadow",
            summaryDE: "Die Wiese wird weich und grün. Kleine Mut-Momente reichen völlig.",
            summaryEN: "The meadow turns soft and green. Small moments of courage are enough.",
            start: (3, 20),
            end: (4, 12),
            accent: "#C6EFDC",
            symbol: "leaf.fill",
            objectives: [
                objective("days", "habitDays", 4, "Vier Pflegetage", "Four care days"),
                objective("reflect", "reflections", 2, "Stimmung oder Tagebuch, zweimal", "Mood or journal, twice"),
                objective("play", "companionPlays", 1, "Mit einem Mini-Freund spielen", "Play with a mini-friend")
            ],
            sparks: 45,
            cosmetic: "gooby-season-sprout-crown",
            species: "blossom-beetle"
        ),
        event(
            id: "blossom-week",
            nameDE: "Blütenwoche",
            nameEN: "Blossom Week",
            summaryDE: "Überall blüht etwas. Auch deine kleinen Routinen dürfen aufblühen.",
            summaryEN: "Something is blooming everywhere. Your small routines can bloom too.",
            start: (4, 13),
            end: (4, 30),
            accent: "#FFD6E7",
            symbol: "camera.macro",
            objectives: [
                objective("habits", "habitCount", 6, "Sechs Gewohnheiten abschließen", "Complete six habits"),
                objective("calm", "calmSessions", 2, "Zweimal zur Ruhe kommen", "Settle down twice"),
                objective("visit", "visits", 1, "Die Blütentafel öffnen", "Open the blossom board")
            ],
            sparks: 35,
            cosmetic: "gooby-season-petal-bow",
            species: nil
        ),
        event(
            id: "rainbow-week",
            nameDE: "Regenbogenwoche",
            nameEN: "Rainbow Week",
            summaryDE: "Nach dem Regen zeigt sich Farbe. Sammle ein paar helle Momente.",
            summaryEN: "Color shows up after the rain. Gather a few bright moments.",
            start: (5, 1),
            end: (5, 14),
            accent: "#D3C2FF",
            symbol: "rainbow",
            objectives: [
                objective("days", "habitDays", 3, "Drei bunte Pflegetage", "Three colorful care days"),
                objective("reflect", "reflections", 3, "Dreimal innehalten", "Pause three times"),
                objective("play", "companionPlays", 2, "Zweimal mit Freunden spielen", "Play with friends twice")
            ],
            sparks: 50,
            cosmetic: "gooby-season-rainbow-pin",
            species: "rainbow-wisp"
        ),
        event(
            id: "summer-picnic",
            nameDE: "Sommerpicknick",
            nameEN: "Summer Picnic",
            summaryDE: "Decke ausbreiten, Sonne teilen, den Tag in kleine Bissen teilen.",
            summaryEN: "Spread a blanket, share the sun, and split the day into small bites.",
            start: (6, 21),
            end: (7, 20),
            accent: "#FFE7AD",
            symbol: "sun.max.fill",
            objectives: [
                objective("habits", "habitCount", 8, "Acht Sommergewohnheiten", "Eight summer habits"),
                objective("calm", "calmSessions", 2, "Zwei Pausen im Schatten", "Two pauses in the shade"),
                objective("visit", "visits", 1, "Die Picknickdecke ansehen", "Look at the picnic blanket")
            ],
            sparks: 40,
            cosmetic: "gooby-season-picnic-hat",
            species: "picnic-bee"
        ),
        event(
            id: "starry-nights",
            nameDE: "Sternennächte",
            nameEN: "Starry Nights",
            summaryDE: "Wenn es leise wird, zählen schon die kleinen Dinge, die du geschafft hast.",
            summaryEN: "When the evening gets quiet, the small things you finished still count.",
            start: (8, 1),
            end: (8, 18),
            accent: "#C8E9FF",
            symbol: "star.fill",
            objectives: [
                objective("days", "habitDays", 4, "Vier Abendroutinen", "Four evening routines"),
                objective("reflect", "reflections", 2, "Zweimal den Tag ablegen", "Set the day down twice"),
                objective("play", "companionPlays", 1, "Einem Freund zuwinken", "Wave to a friend")
            ],
            sparks: 55,
            cosmetic: "gooby-season-star-cloak",
            species: nil
        ),
        event(
            id: "leaf-walk",
            nameDE: "Blätterspaziergang",
            nameEN: "Leaf Walk",
            summaryDE: "Knischernde Wege, warme Schals und ein Schritt nach dem anderen.",
            summaryEN: "Crunchy paths, warm scarves, and one step after another.",
            start: (9, 22),
            end: (10, 12),
            accent: "#FFD6B3",
            symbol: "leaf.fill",
            objectives: [
                objective("days", "habitDays", 4, "Vier Spazier-Tage", "Four walking days"),
                objective("calm", "calmSessions", 2, "Zweimal durchatmen", "Breathe twice"),
                objective("visit", "visits", 1, "Den Laubweg öffnen", "Open the leaf path")
            ],
            sparks: 40,
            cosmetic: "gooby-season-leaf-scarf",
            species: nil
        ),
        event(
            id: "lantern-eve",
            nameDE: "Laternenabend",
            nameEN: "Lantern Eve",
            summaryDE: "Ein Licht im Fenster und ein paar erledigte Kleinigkeiten reichen.",
            summaryEN: "A light in the window and a few finished little things are enough.",
            start: (10, 16),
            end: (10, 31),
            accent: "#D3C2FF",
            symbol: "moon.stars.fill",
            objectives: [
                objective("habits", "habitCount", 6, "Sechs kleine Lichter", "Six small lights"),
                objective("reflect", "reflections", 2, "Zweimal nachfühlen", "Check in twice"),
                objective("visit", "visits", 1, "Die Laterne anzünden", "Light the lantern")
            ],
            sparks: 50,
            cosmetic: "gooby-season-lantern",
            species: "lantern-sprite"
        ),
        event(
            id: "cozy-evenings",
            nameDE: "Gemütliche Abende",
            nameEN: "Cozy Evenings",
            summaryDE: "Tasse, Decke, ruhiger Atem. Der Abend darf klein und warm sein.",
            summaryEN: "A cup, a blanket, a quiet breath. The evening can stay small and warm.",
            start: (11, 1),
            end: (11, 14),
            accent: "#FFD6E7",
            symbol: "cup.and.saucer.fill",
            objectives: [
                objective("days", "habitDays", 3, "Drei gemütliche Tage", "Three cozy days"),
                objective("calm", "calmSessions", 3, "Drei Ruheübungen", "Three calm sessions"),
                objective("reflect", "reflections", 1, "Einmal aufschreiben oder fühlen", "Write or feel once")
            ],
            sparks: 35,
            cosmetic: "gooby-season-cocoa-mug",
            species: nil
        ),
        event(
            id: "winter-warmth",
            nameDE: "Winterwärme",
            nameEN: "Winter Warmth",
            summaryDE: "Draußen wird es still. Drinnen zählen Wärme, Pflege und Gesellschaft.",
            summaryEN: "Outside turns quiet. Inside, warmth, care, and company count.",
            start: (12, 1),
            end: (12, 26),
            accent: "#C8E9FF",
            symbol: "snowflake",
            objectives: [
                objective("days", "habitDays", 5, "Fünf warme Pflegetage", "Five warm care days"),
                objective("reflect", "reflections", 3, "Dreimal innehalten", "Pause three times"),
                objective("play", "companionPlays", 2, "Zweimal zusammen spielen", "Play together twice")
            ],
            sparks: 50,
            cosmetic: "gooby-season-wool-scarf",
            species: "snow-puff"
        ),
        event(
            id: "new-year-sparkle",
            nameDE: "Neujahrsfunkeln",
            nameEN: "New Year Sparkle",
            summaryDE: "Zwischen den Jahren glitzert ein kleiner Anfang. Nichts muss groß sein.",
            summaryEN: "Between the years, a small beginning glitters. Nothing has to be big.",
            start: (12, 27),
            end: (1, 5),
            accent: "#FFE7AD",
            symbol: "sparkles",
            objectives: [
                objective("visit", "visits", 1, "Das Funkeln begrüßen", "Greet the sparkle"),
                objective("habits", "habitCount", 3, "Drei erste Schritte", "Three first steps"),
                objective("reflect", "reflections", 1, "Einen Wunsch notieren oder fühlen", "Note or feel one wish")
            ],
            sparks: 60,
            cosmetic: "gooby-season-spark-crown",
            species: nil
        )
    ]

    private static func event(
        id: String,
        nameDE: String,
        nameEN: String,
        summaryDE: String,
        summaryEN: String,
        start: (Int, Int),
        end: (Int, Int),
        accent: String,
        symbol: String,
        objectives: [GoobyEventObjectiveDefinition],
        sparks: Int,
        cosmetic: String,
        species: String?
    ) -> GoobySeasonalEventDefinition {
        GoobySeasonalEventDefinition(
            id: id,
            nameDE: nameDE,
            nameEN: nameEN,
            summaryDE: summaryDE,
            summaryEN: summaryEN,
            startMonth: start.0,
            startDay: start.1,
            endMonth: end.0,
            endDay: end.1,
            accentHex: accent,
            symbolName: symbol,
            objectives: objectives,
            rewardSparks: sparks,
            cosmeticID: cosmetic,
            bonusSpeciesID: species
        )
    }

    private static func objective(
        _ id: String,
        _ kind: String,
        _ target: Int,
        _ titleDE: String,
        _ titleEN: String
    ) -> GoobyEventObjectiveDefinition {
        GoobyEventObjectiveDefinition(id: id, kind: kind, target: target, titleDE: titleDE, titleEN: titleEN)
    }
}
