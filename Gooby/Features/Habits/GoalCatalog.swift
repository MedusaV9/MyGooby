import Foundation

struct GoalArea: Identifiable, Hashable {
    var id: String
    var glyph: String
    var tint: UInt32
    var en: String
    var de: String
    var blurbEN: String
    var blurbDE: String

    func name(_ language: String) -> String { language == "en" ? en : de }
    func blurb(_ language: String) -> String { language == "en" ? blurbEN : blurbDE }
}

struct GoalSuggestion: Identifiable, Hashable {
    var id: String
    var areaID: String
    var glyph: String
    var energy: Int = 5
    var en: String
    var de: String

    func title(_ language: String) -> String { language == "en" ? en : de }
}

struct GoalStarter {
    var id: String
    var showArea: Bool
}

enum GoalCatalog {
    static let areas: [GoalArea] = [
        GoalArea(id: "productivity", glyph: "timer", tint: 0xF3B56A, en: "Productivity", de: "Produktivität", blurbEN: "One clear thing at a time.", blurbDE: "Eine klare Sache nach der anderen."),
        GoalArea(id: "gratitude", glyph: "star", tint: 0xF6D56A, en: "Gratitude", de: "Dankbarkeit", blurbEN: "Noticing what is already good.", blurbDE: "Bemerken, was schon gut ist."),
        GoalArea(id: "kindness", glyph: "smile", tint: 0xF7B4C8, en: "Self-kindness", de: "Freundlichkeit zu mir", blurbEN: "Being on your own side.", blurbDE: "Auf der eigenen Seite stehen."),
        GoalArea(id: "calm", glyph: "leaf", tint: 0x9FD9C8, en: "Calm", de: "Ruhe", blurbEN: "A pause you can actually take.", blurbDE: "Eine Pause, die sich machen lässt."),
        GoalArea(id: "sleep", glyph: "bed", tint: 0xC9B7F5, en: "Sleep", de: "Schlaf", blurbEN: "Rest that starts before the night does.", blurbDE: "Ruhe, die schon vor der Nacht beginnt."),
        GoalArea(id: "hygiene", glyph: "shower", tint: 0x8EC8F5, en: "Hygiene", de: "Hygiene", blurbEN: "Small steps that feel fresh.", blurbDE: "Kleine Schritte, die sich frisch anfühlen."),
        GoalArea(id: "movement", glyph: "giraffe", tint: 0xF6C14A, en: "Movement", de: "Bewegung", blurbEN: "A little motion counts.", blurbDE: "Ein bisschen Bewegung zählt."),
        GoalArea(id: "nutrition", glyph: "tea", tint: 0x8FCB74, en: "Nutrition", de: "Ernährung", blurbEN: "Food and drink that feel kind.", blurbDE: "Essen und Trinken, das guttut."),
        GoalArea(id: "connection", glyph: "people", tint: 0xF08A7A, en: "Connection", de: "Verbindung", blurbEN: "People you want close by.", blurbDE: "Menschen, die dir nah sein sollen."),
        GoalArea(id: "tidy", glyph: "home", tint: 0xD7C4A3, en: "Home", de: "Zuhause", blurbEN: "A home that feels a little lighter.", blurbDE: "Ein Zuhause, das sich leichter anfühlt.")
    ]

    static let starters: [GoalStarter] = [
        GoalStarter(id: "get-out-of-bed", showArea: false),
        GoalStarter(id: "stretch-break", showArea: false),
        GoalStarter(id: "three-breaths", showArea: false),
        GoalStarter(id: "happy-thing", showArea: false),
        GoalStarter(id: "tea", showArea: true)
    ]

    static let suggestions: [GoalSuggestion] = [
        GoalSuggestion(id: "inbox-zero", areaID: "productivity", glyph: "mail", en: "Get my inbox down to zero", de: "Den Posteingang auf null bringen"),
        GoalSuggestion(id: "clear-tabs", areaID: "productivity", glyph: "note", en: "Clear out unused browser tabs", de: "Ungenutzte Browser-Tabs schließen"),
        GoalSuggestion(id: "focus-25", areaID: "productivity", glyph: "timer", en: "Focus for 25 minutes", de: "25 Minuten konzentriert bleiben"),
        GoalSuggestion(id: "top-task", areaID: "productivity", glyph: "target", en: "Pick the one task that matters", de: "Die eine wichtige Aufgabe auswählen"),
        GoalSuggestion(id: "review-plan", areaID: "productivity", glyph: "note", en: "Review my plan for tomorrow", de: "Den Plan für morgen ansehen"),
        GoalSuggestion(id: "reduce-screen", areaID: "productivity", glyph: "phone", en: "Reduce screen time by one hour", de: "Die Bildschirmzeit um eine Stunde kürzen"),
        GoalSuggestion(id: "start-hard", areaID: "productivity", glyph: "timer", en: "Start the hardest task for five minutes", de: "Die schwerste Aufgabe fünf Minuten anfangen"),
        GoalSuggestion(id: "desk-item", areaID: "productivity", glyph: "broom", en: "Put one work item back in its place", de: "Einen Arbeitsgegenstand an seinen Platz legen"),
        GoalSuggestion(id: "vision", areaID: "productivity", glyph: "star", en: "Sketch a small picture of the year ahead", de: "Ein kleines Bild vom kommenden Jahr skizzieren"),
        GoalSuggestion(id: "one-email", areaID: "productivity", glyph: "mail", en: "Answer one message that matters", de: "Eine wichtige Nachricht beantworten"),

        GoalSuggestion(id: "one-grateful", areaID: "gratitude", glyph: "star", en: "Name one thing I'm grateful for", de: "Eine Sache benennen, für die ich dankbar bin"),
        GoalSuggestion(id: "three-good", areaID: "gratitude", glyph: "note", en: "List three good things from today", de: "Drei gute Dinge von heute aufschreiben"),
        GoalSuggestion(id: "gratitude-bed", areaID: "gratitude", glyph: "moon", en: "Make a gratitude list before sleeping", de: "Vor dem Schlafen eine Dankbarkeitsliste schreiben"),
        GoalSuggestion(id: "positive-today", areaID: "gratitude", glyph: "note", en: "Write one positive thing about today", de: "Eine positive Sache über heute aufschreiben"),
        GoalSuggestion(id: "thank-note", areaID: "gratitude", glyph: "mail", en: "Write a short thank-you note", de: "Eine kurze Dankesnachricht schreiben"),
        GoalSuggestion(id: "notice-beauty", areaID: "gratitude", glyph: "flower", en: "Notice something beautiful", de: "Etwas Schönes bemerken"),
        GoalSuggestion(id: "savor", areaID: "gratitude", glyph: "sun", en: "Savor one small moment", de: "Einen kleinen Moment auskosten"),
        GoalSuggestion(id: "body-thanks", areaID: "gratitude", glyph: "heart", en: "Appreciate one thing my body did today", de: "Eine Sache würdigen, die mein Körper heute geschafft hat"),

        GoalSuggestion(id: "happy-thing", areaID: "kindness", glyph: "smile", en: "Do one thing that makes me happy", de: "Eine Sache tun, die mich glücklich macht"),
        GoalSuggestion(id: "happy-small", areaID: "kindness", glyph: "smile", en: "Do one small thing that makes me happy", de: "Eine kleine Sache tun, die mich glücklich macht"),
        GoalSuggestion(id: "i-can", areaID: "kindness", glyph: "mirror", en: "Look in the mirror and say I can do it", de: "In den Spiegel schauen und sagen: Ich schaffe das"),
        GoalSuggestion(id: "just-be", areaID: "kindness", glyph: "sun", en: "Just be", de: "Einfach da sein"),
        GoalSuggestion(id: "gentle-day", areaID: "kindness", glyph: "heart", en: "Get through today gently", de: "Heute sanft durch den Tag kommen"),
        GoalSuggestion(id: "small-win", areaID: "kindness", glyph: "star", en: "Name one small win from today", de: "Einen kleinen Erfolg von heute benennen"),
        GoalSuggestion(id: "win-aloud", areaID: "kindness", glyph: "star", en: "Name one win from today out loud", de: "Einen Erfolg von heute laut aussprechen"),
        GoalSuggestion(id: "grace", areaID: "kindness", glyph: "heart", en: "Give myself grace for a mistake", de: "Mir einen Fehler nachsehen"),
        GoalSuggestion(id: "credit", areaID: "kindness", glyph: "star", en: "Name one win and give myself credit", de: "Einen Erfolg anerkennen"),
        GoalSuggestion(id: "pause-harsh", areaID: "kindness", glyph: "leaf", en: "Notice when I'm hard on myself and pause", de: "Merken, wenn ich hart zu mir bin, und innehalten"),
        GoalSuggestion(id: "showed-up", areaID: "kindness", glyph: "heart", en: "Name one way I showed up today", de: "Eine Art benennen, wie ich heute da war"),
        GoalSuggestion(id: "reframe", areaID: "kindness", glyph: "note", en: "Catch a harsh thought and soften it", de: "Einen harten Gedanken abfangen und mildern"),
        GoalSuggestion(id: "rest-ok", areaID: "kindness", glyph: "moon", en: "Give myself permission to rest", de: "Mir erlauben, mich auszuruhen"),
        GoalSuggestion(id: "kind-line", areaID: "kindness", glyph: "smile", en: "Say one kind sentence to myself", de: "Einen freundlichen Satz zu mir sagen"),

        GoalSuggestion(id: "three-breaths", areaID: "calm", glyph: "leaf", en: "Take 3 deep breaths", de: "3 tiefe Atemzüge nehmen"),
        GoalSuggestion(id: "quiet-minute", areaID: "calm", glyph: "moon", en: "Sit quietly for one minute", de: "Eine Minute still sitzen"),
        GoalSuggestion(id: "name-feeling", areaID: "calm", glyph: "heart", en: "Name how I'm feeling", de: "Benennen, wie es mir gerade geht"),
        GoalSuggestion(id: "notice-five", areaID: "calm", glyph: "sun", en: "Notice five things I can see", de: "Fünf Dinge bemerken, die ich sehe"),
        GoalSuggestion(id: "unclench", areaID: "calm", glyph: "leaf", en: "Unclench my jaw and drop my shoulders", de: "Den Kiefer lösen und die Schultern senken"),
        GoalSuggestion(id: "scroll-pause", areaID: "calm", glyph: "phone", en: "Pause the endless scroll", de: "Das endlose Scrollen unterbrechen"),
        GoalSuggestion(id: "social-work", areaID: "calm", glyph: "phone", en: "Stay off social feeds while I work", de: "Bei der Arbeit nicht in soziale Feeds schauen"),
        GoalSuggestion(id: "joy-apps", areaID: "calm", glyph: "phone", en: "Remove one app that doesn't spark joy", de: "Eine App entfernen, die keine Freude macht"),
        GoalSuggestion(id: "step-away", areaID: "calm", glyph: "sun", en: "Step away from a screen for a few minutes", de: "Ein paar Minuten vom Bildschirm weggehen"),
        GoalSuggestion(id: "calm-sound", areaID: "calm", glyph: "leaf", en: "Listen to a calming sound", de: "Einem beruhigenden Klang zuhören"),
        GoalSuggestion(id: "enjoy-lunch", areaID: "calm", glyph: "plate", en: "Enjoy lunch without multitasking", de: "Das Mittagessen ohne Multitasking genießen"),

        GoalSuggestion(id: "get-out-of-bed", areaID: "sleep", glyph: "bed", en: "Get out of bed", de: "Aus dem Bett aufstehen"),
        GoalSuggestion(id: "dim-lights", areaID: "sleep", glyph: "moon", en: "Dim the lights before bed", de: "Vor dem Schlafen das Licht dimmen"),
        GoalSuggestion(id: "warm-screen", areaID: "sleep", glyph: "phone", en: "Use warm screen colors at night", de: "Abends warme Farben auf dem Bildschirm nutzen"),
        GoalSuggestion(id: "skip-late-caffeine", areaID: "sleep", glyph: "tea", en: "Skip caffeine after mid-afternoon", de: "Nach dem Nachmittag auf Koffein verzichten"),
        GoalSuggestion(id: "breathe-bed", areaID: "sleep", glyph: "leaf", en: "Do a few slow breaths before bed", de: "Vor dem Schlafen ein paar ruhige Atemzüge machen"),
        GoalSuggestion(id: "if-awake", areaID: "sleep", glyph: "bed", en: "If sleep won't come, get up for a little while", de: "Wenn der Schlaf nicht kommt, kurz aufstehen"),
        GoalSuggestion(id: "shower-bed", areaID: "sleep", glyph: "shower", en: "Take a warm shower before bed", de: "Vor dem Schlafen warm duschen"),
        GoalSuggestion(id: "tomorrow-note", areaID: "sleep", glyph: "note", en: "Write tomorrow's goals before sleeping", de: "Vor dem Schlafen die Ziele für morgen notieren"),
        GoalSuggestion(id: "airplane-bed", areaID: "sleep", glyph: "phone", en: "Turn on airplane mode 30 minutes before bed", de: "30 Minuten vor dem Schlafen in den Flugmodus wechseln"),
        GoalSuggestion(id: "skip-nap", areaID: "sleep", glyph: "moon", en: "Skip a late nap", de: "Ein spätes Nickerchen auslassen"),
        GoalSuggestion(id: "read-bed", areaID: "sleep", glyph: "book", en: "Read something relaxing before bed", de: "Vor dem Schlafen etwas Ruhiges lesen"),
        GoalSuggestion(id: "phone-away", areaID: "sleep", glyph: "phone", en: "Put my phone away an hour before bed", de: "Eine Stunde vor dem Schlafen das Handy weglegen"),
        GoalSuggestion(id: "dark-room", areaID: "sleep", glyph: "moon", en: "Darken the room for sleep", de: "Das Zimmer zum Schlafen abdunkeln"),

        GoalSuggestion(id: "brush-teeth", areaID: "hygiene", glyph: "sparkle", en: "Brush my teeth", de: "Zähne putzen"),
        GoalSuggestion(id: "wash-face", areaID: "hygiene", glyph: "drop", en: "Wash my face", de: "Das Gesicht waschen"),
        GoalSuggestion(id: "shower", areaID: "hygiene", glyph: "shower", en: "Take a shower", de: "Duschen"),
        GoalSuggestion(id: "shower-hair", areaID: "hygiene", glyph: "shower", en: "Shower and wash my hair", de: "Duschen und die Haare waschen"),
        GoalSuggestion(id: "change-clothes", areaID: "hygiene", glyph: "shirt", en: "Change my clothes", de: "Frische Kleidung anziehen"),
        GoalSuggestion(id: "comb-hair", areaID: "hygiene", glyph: "sparkle", en: "Brush my hair", de: "Die Haare bürsten"),
        GoalSuggestion(id: "clothes-ready", areaID: "hygiene", glyph: "shirt", en: "Set out clothes for tomorrow", de: "Kleidung für morgen bereitlegen"),
        GoalSuggestion(id: "moisturizer", areaID: "hygiene", glyph: "drop", en: "Put on moisturizer", de: "Eincremen"),

        GoalSuggestion(id: "stretch-break", areaID: "movement", glyph: "giraffe", en: "Take a stretch break", de: "Eine Dehnpause machen"),
        GoalSuggestion(id: "walk-neighborhood", areaID: "movement", glyph: "walk", en: "Walk around the neighborhood", de: "Eine Runde durch die Nachbarschaft gehen"),
        GoalSuggestion(id: "stroll-10", areaID: "movement", glyph: "walk", en: "Go on a 10 minute stroll outside", de: "10 Minuten draußen spazieren"),
        GoalSuggestion(id: "pushups-3", areaID: "movement", glyph: "bolt", en: "Do 3 push-ups", de: "3 Liegestütze machen"),
        GoalSuggestion(id: "plank-10", areaID: "movement", glyph: "bolt", en: "Hold a plank for 10 seconds", de: "10 Sekunden in der Planke bleiben"),
        GoalSuggestion(id: "situps-5", areaID: "movement", glyph: "bolt", en: "Do 5 sit-ups", de: "5 Sit-ups machen"),
        GoalSuggestion(id: "squats-5", areaID: "movement", glyph: "bolt", en: "Do 5 squats", de: "5 Kniebeugen machen"),
        GoalSuggestion(id: "burpees-5", areaID: "movement", glyph: "bolt", en: "Do 5 burpees", de: "5 Burpees machen"),
        GoalSuggestion(id: "jacks-10", areaID: "movement", glyph: "bolt", en: "Do 10 jumping jacks", de: "10 Hampelmänner machen"),
        GoalSuggestion(id: "crunches-10", areaID: "movement", glyph: "bolt", en: "Do 10 crunches", de: "10 Crunches machen"),
        GoalSuggestion(id: "morning-yoga", areaID: "movement", glyph: "yoga", en: "Do some morning yoga", de: "Ein bisschen Morgen-Yoga machen"),
        GoalSuggestion(id: "lunges-5", areaID: "movement", glyph: "walk", en: "Do 5 lunges", de: "5 Ausfallschritte machen"),
        GoalSuggestion(id: "yoga", areaID: "movement", glyph: "yoga", en: "Do some yoga", de: "Ein bisschen Yoga machen"),
        GoalSuggestion(id: "stand-10", areaID: "movement", glyph: "walk", en: "Stand up for 10 seconds", de: "10 Sekunden lang aufstehen"),
        GoalSuggestion(id: "step-outside", areaID: "movement", glyph: "sun", en: "Step outside once", de: "Einmal vor die Tür gehen"),
        GoalSuggestion(id: "dance", areaID: "movement", glyph: "smile", en: "Dance to one song", de: "Zu einem Lied tanzen"),

        GoalSuggestion(id: "tea", areaID: "nutrition", glyph: "tea", en: "Drink a cup of tea", de: "Eine Tasse Tee trinken"),
        GoalSuggestion(id: "water", areaID: "nutrition", glyph: "drop", en: "Drink water", de: "Wasser trinken"),
        GoalSuggestion(id: "hot-water", areaID: "nutrition", glyph: "tea", en: "Drink a warm cup of water", de: "Eine Tasse warmes Wasser trinken"),
        GoalSuggestion(id: "vegetable", areaID: "nutrition", glyph: "plate", en: "Add a vegetable to a meal", de: "Eine Mahlzeit um Gemüse ergänzen"),
        GoalSuggestion(id: "fruit", areaID: "nutrition", glyph: "apple", en: "Eat a piece of fruit", de: "Ein Stück Obst essen"),
        GoalSuggestion(id: "breakfast", areaID: "nutrition", glyph: "plate", en: "Eat breakfast", de: "Frühstücken"),
        GoalSuggestion(id: "snack", areaID: "nutrition", glyph: "apple", en: "Have a nourishing snack", de: "Einen nahrhaften Snack essen"),
        GoalSuggestion(id: "cook", areaID: "nutrition", glyph: "plate", en: "Cook a meal", de: "Eine Mahlzeit kochen"),
        GoalSuggestion(id: "screen-meal", areaID: "nutrition", glyph: "plate", en: "Eat one meal without a screen", de: "Eine Mahlzeit ohne Bildschirm essen"),
        GoalSuggestion(id: "skip-late-snack", areaID: "nutrition", glyph: "moon", en: "Skip the late-night snack", de: "Den späten Snack auslassen"),

        GoalSuggestion(id: "reach-out", areaID: "connection", glyph: "mail", en: "Reach out to a friend", de: "Einer Freundin oder einem Freund schreiben"),
        GoalSuggestion(id: "surprise", areaID: "connection", glyph: "gift", en: "Surprise a friend with a small gesture", de: "Jemanden mit einer kleinen Geste überraschen"),
        GoalSuggestion(id: "miss-you", areaID: "connection", glyph: "heart", en: "Tell an old friend that I miss them", de: "Einer alten Freundschaft sagen, dass sie fehlt"),
        GoalSuggestion(id: "fond-friend", areaID: "connection", glyph: "people", en: "Share a fond memory with a friend", de: "Eine schöne Erinnerung mit jemandem teilen"),
        GoalSuggestion(id: "fond-family", areaID: "connection", glyph: "people", en: "Share a fond memory with my family", de: "Eine schöne Erinnerung mit der Familie teilen"),
        GoalSuggestion(id: "time-family", areaID: "connection", glyph: "people", en: "Spend time with my family", de: "Zeit mit der Familie verbringen"),
        GoalSuggestion(id: "cook-loved", areaID: "connection", glyph: "plate", en: "Cook a meal for someone I love", de: "Für jemanden, den ich mag, kochen"),
        GoalSuggestion(id: "thank-helper", areaID: "connection", glyph: "heart", en: "Thank someone who made life easier", de: "Jemandem danken, der den Tag leichter gemacht hat"),
        GoalSuggestion(id: "helping-hand", areaID: "connection", glyph: "hands", en: "Offer a helping hand", de: "Eine helfende Hand anbieten"),
        GoalSuggestion(id: "tell-love", areaID: "connection", glyph: "heart", en: "Tell someone I love them", de: "Jemandem sagen, dass ich sie oder ihn lieb habe"),
        GoalSuggestion(id: "thanks-mom", areaID: "connection", glyph: "heart", en: "Tell my mom I appreciate her", de: "Meiner Mama sagen, dass ich sie schätze"),
        GoalSuggestion(id: "thanks-dad", areaID: "connection", glyph: "heart", en: "Tell my dad I appreciate him", de: "Meinem Papa sagen, dass ich ihn schätze"),
        GoalSuggestion(id: "reconnect", areaID: "connection", glyph: "mail", en: "Reconnect with someone I have not talked to in a while", de: "Mich bei jemandem melden, mit dem ich lange nicht gesprochen habe"),
        GoalSuggestion(id: "game-night", areaID: "connection", glyph: "people", en: "Plan a game night with friends", de: "Einen Spieleabend mit Freundinnen und Freunden planen"),
        GoalSuggestion(id: "who-cares", areaID: "connection", glyph: "heart", en: "Name one person who cares for me", de: "Eine Person benennen, der ich wichtig bin"),
        GoalSuggestion(id: "let-ahead", areaID: "connection", glyph: "hands", en: "Let the person behind me go ahead in line", de: "Die Person hinter mir vorlassen"),
        GoalSuggestion(id: "offer-seat", areaID: "connection", glyph: "hands", en: "Offer my seat to someone", de: "Meinen Platz anbieten"),
        GoalSuggestion(id: "kind-comment", areaID: "connection", glyph: "note", en: "Write a positive comment", de: "Einen freundlichen Kommentar schreiben"),
        GoalSuggestion(id: "messages-3", areaID: "connection", glyph: "mail", en: "Respond to 3 personal messages", de: "Drei persönliche Nachrichten beantworten"),
        GoalSuggestion(id: "bake", areaID: "connection", glyph: "gift", en: "Bake something for someone", de: "Etwas für jemanden backen"),
        GoalSuggestion(id: "donate-clothes", areaID: "connection", glyph: "shirt", en: "Donate clothes I no longer wear", de: "Kleidung weitergeben, die ich nicht mehr trage"),
        GoalSuggestion(id: "warm-meal", areaID: "connection", glyph: "plate", en: "Buy a warm meal for someone who needs one", de: "Jemandem, der sie braucht, eine warme Mahlzeit ausgeben"),

        GoalSuggestion(id: "dishes", areaID: "tidy", glyph: "plate", en: "Wash the dishes", de: "Geschirr spülen"),
        GoalSuggestion(id: "laundry", areaID: "tidy", glyph: "shirt", en: "Do a load of laundry", de: "Eine Maschine Wäsche waschen"),
        GoalSuggestion(id: "vacuum-room", areaID: "tidy", glyph: "broom", en: "Vacuum my room", de: "Mein Zimmer saugen"),
        GoalSuggestion(id: "vacuum-living", areaID: "tidy", glyph: "broom", en: "Vacuum the living room", de: "Das Wohnzimmer saugen"),
        GoalSuggestion(id: "towels", areaID: "tidy", glyph: "shower", en: "Wash the bathroom towels", de: "Die Handtücher waschen"),
        GoalSuggestion(id: "sheets", areaID: "tidy", glyph: "bed", en: "Wash the bed sheets", de: "Die Bettwäsche waschen"),
        GoalSuggestion(id: "closet", areaID: "tidy", glyph: "shirt", en: "Organize my closet", de: "Den Schrank ordnen"),
        GoalSuggestion(id: "make-bed", areaID: "tidy", glyph: "bed", en: "Make my bed", de: "Das Bett machen"),
        GoalSuggestion(id: "clothes-floor", areaID: "tidy", glyph: "shirt", en: "Pick clothes up off the floor", de: "Kleidung vom Boden aufheben"),
        GoalSuggestion(id: "trash", areaID: "tidy", glyph: "broom", en: "Take out the trash", de: "Den Müll rausbringen"),
        GoalSuggestion(id: "counters", areaID: "tidy", glyph: "broom", en: "Clean the kitchen counters", de: "Die Küchenflächen putzen"),
        GoalSuggestion(id: "put-away", areaID: "tidy", glyph: "home", en: "Put away one item that is not in its place", de: "Einen Gegenstand an seinen Platz legen"),
        GoalSuggestion(id: "declutter", areaID: "tidy", glyph: "home", en: "Declutter one small spot", de: "Eine kleine Stelle ausmisten"),
        GoalSuggestion(id: "plant", areaID: "tidy", glyph: "flower", en: "Water a plant or tend a small garden", de: "Eine Pflanze gießen oder ein kleines Beet pflegen")
    ]

    static let easyIDs = ["just-be", "hot-water", "change-clothes", "wash-face", "i-can", "stand-10", "water", "brush-teeth", "happy-thing", "three-breaths"]

    static let chipOrder = ["easy", "calm", "connection", "gratitude", "kindness", "productivity", "hygiene", "sleep", "nutrition", "movement", "tidy"]

    static let areaByID: [String: GoalArea] = Dictionary(uniqueKeysWithValues: areas.map { ($0.id, $0) })
    static let byID: [String: GoalSuggestion] = Dictionary(uniqueKeysWithValues: suggestions.map { ($0.id, $0) })

    static func suggestion(_ id: String) -> GoalSuggestion? { byID[id] }
    static func area(_ id: String) -> GoalArea? { areaByID[id] }

    static func suggestions(in areaID: String) -> [GoalSuggestion] {
        if areaID == "easy" {
            return easyIDs.compactMap { byID[$0] }
        }
        return suggestions.filter { $0.areaID == areaID }
    }

    static func matches(_ habit: Habit, _ suggestion: GoalSuggestion) -> Bool {
        let title = habit.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title == suggestion.en || title == suggestion.de
    }
}
