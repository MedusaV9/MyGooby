import Foundation

enum GoobyQuestCatalog {
    static let templates: [GoobyQuestTemplate] = [
        template(
            "care-1",
            "habitCount",
            1,
            8,
            "Eine kleine Pflege",
            "One small care",
            "Schließe heute eine Gewohnheit ab.",
            "Complete one habit today."
        ),
        template(
            "care-3",
            "habitCount",
            3,
            18,
            "Drei gute Punkte",
            "Three good checks",
            "Schließe heute drei verschiedene Gewohnheiten ab.",
            "Complete three different habits today."
        ),
        template(
            "mood-1",
            "mood",
            1,
            10,
            "Stimmung ablegen",
            "Set the mood down",
            "Halte fest, wie es dir gerade geht.",
            "Notice how you feel right now."
        ),
        template(
            "journal-1",
            "journal",
            1,
            12,
            "Ein paar Zeilen",
            "A few lines",
            "Schreibe heute eine Tagebuchnotiz.",
            "Write a journal note today."
        ),
        template(
            "calm-1",
            "calm",
            1,
            10,
            "Kurz zur Ruhe",
            "A short calm",
            "Mach eine kleine Ruheübung.",
            "Do one small calm exercise."
        ),
        template(
            "pet-1",
            "pet",
            1,
            6,
            "Gooby streicheln",
            "Pet Gooby",
            "Nimm dir einen Moment mit Gooby.",
            "Take a moment with Gooby."
        ),
        template(
            "adventure-1",
            "adventure",
            1,
            14,
            "Aufbrechen",
            "Head out",
            "Starte das Tagesabenteuer oder hol Gooby zurück.",
            "Start today's adventure or welcome Gooby home."
        ),
        template(
            "goal-1",
            "dailyGoal",
            1,
            20,
            "Tagesziel",
            "Daily goal",
            "Schließe dein Tagesziel ab.",
            "Finish your daily goal."
        ),
        template(
            "companion-1",
            "companionPlay",
            1,
            8,
            "Mit Freund spielen",
            "Play with a friend",
            "Spiel einmal mit einem Mini-Freund.",
            "Play with a mini-friend once."
        ),
        template(
            "reflect-2",
            "reflection",
            2,
            16,
            "Zweimal hinspüren",
            "Notice twice",
            "Halte heute Stimmung und Tagebuch fest.",
            "Log both a mood and a journal note today."
        )
    ]

    static let milestones: [GoobyMilestoneDefinition] = [
        milestone("first-quest", "questsCompleted", 1, 20, "Erster Auftrag", "First quest", "Ein Tagesauftrag ist geschafft.", "One daily quest is finished."),
        milestone("quest-week", "questDays", 7, 80, "Sieben Questtage", "Seven quest days", "An sieben Tagen hast du Aufträge abgeschlossen.", "You finished quests on seven days."),
        milestone("quest-thirty", "questsCompleted", 30, 150, "Quest-Sammlung", "Quest collection", "Dreißig Tagesaufträge sind abgeschlossen.", "Thirty daily quests are complete."),
        milestone("first-egg", "eggsBound", 1, 15, "Erstes Ei", "First egg", "Ein Ei wartet auf eine Gewohnheit.", "An egg is waiting on a habit."),
        milestone("first-hatch", "hatches", 1, 50, "Erstes Schlüpfen", "First hatch", "Ein Mini-Freund ist aus dem Ei gekommen.", "A mini-friend came out of an egg."),
        milestone("nest-five", "companions", 5, 100, "Volles Nest", "Full nest", "Fünf Mini-Freunde wohnen bei dir.", "Five mini-friends live with you."),
        milestone("three-species", "species", 3, 90, "Bunte Runde", "Colorful circle", "Drei verschiedene Arten sind da.", "Three different species are here."),
        milestone("first-event", "eventsClaimed", 1, 60, "Erstes Fest", "First event", "Eine Festbelohnung ist abgeholt.", "An event reward has been claimed."),
        milestone("three-events", "eventsTouched", 3, 120, "Drei Feste", "Three events", "Du warst bei drei Festen dabei.", "You took part in three events."),
        milestone("playful", "plays", 10, 30, "Spielfreude", "Playful days", "Zehn Spielmomente mit Mini-Freunden.", "Ten play moments with mini-friends.")
    ]

    private static func template(
        _ id: String,
        _ metric: String,
        _ target: Int,
        _ sparks: Int,
        _ titleDE: String,
        _ titleEN: String,
        _ detailDE: String,
        _ detailEN: String
    ) -> GoobyQuestTemplate {
        GoobyQuestTemplate(
            id: id,
            metric: metric,
            target: target,
            sparks: sparks,
            titleDE: titleDE,
            titleEN: titleEN,
            detailDE: detailDE,
            detailEN: detailEN
        )
    }

    private static func milestone(
        _ id: String,
        _ metric: String,
        _ target: Int,
        _ sparks: Int,
        _ titleDE: String,
        _ titleEN: String,
        _ detailDE: String,
        _ detailEN: String
    ) -> GoobyMilestoneDefinition {
        GoobyMilestoneDefinition(
            id: id,
            metric: metric,
            target: target,
            sparks: sparks,
            titleDE: titleDE,
            titleEN: titleEN,
            detailDE: detailDE,
            detailEN: detailEN
        )
    }
}
