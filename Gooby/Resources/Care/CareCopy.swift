import Foundation

enum CareString {
    case careTitle, tabHabits, tabMood, tabJournal, tabCalm
    case save, cancel, delete, edit, close, done, add, today
    case disclaimer, notShared
    case habitsEmpty, habitsEmptyArchive, noHabitsDue, addHabit, editHabit
    case fieldTitle, fieldDescription, fieldIcon, fieldColor, fieldCategory, fieldPriority
    case fieldStart, fieldEnd, fieldNoEnd, fieldRepeat, fieldReminder, fieldRepetitions, fieldReward
    case fieldDailyGoal, dailyGoalHint, filterActive, filterArchive
    case archive, restore, pause, resume, skip, undoSkip, undo, completeRep, reschedule, moveTo
    case deleteHabitTitle, deleteHabitMessage, pausedSection, skippedBadge, doneBadge, dailyGoalBadge
    case repsOf, progressLine, futureLocked, pastHint
    case ruleOnce, ruleDaily, ruleWeekly, ruleMonthly, ruleWeekdays, ruleEvery, ruleCustom
    case everyDays, monthDays, customHint
    case priorityLow, priorityNormal, priorityHigh
    case weekdaySun, weekdayMon, weekdayTue, weekdayWed, weekdayThu, weekdayFri, weekdaySat
    case catMorning, catEvening, catHygiene, catMovement, catSleep, catLearning, catHousehold
    case catMindfulness, catHealth, catCreativity, catCustom, customCategory
    case reminderBody, historyCount, pauseUntil, pauseOpen
    case starterWater, starterBed, starterTeeth, starterWalk, starterRelax, starterNote
    case errEmptyTitle, errInterval, errWeekdays, errCustom, errDates, errReps, errReward
    case errMonthDay, errCustomName, errSymbol, errColor, errReminder, errPause
    case errNotDue, errAlreadyDone, errSameDay, errOutOfRange, errTargetDue, errFuture, errPaused, errMissing
    case errEmptyEntry, errEmptyReflection
    case moodQuestion, moodVeryBad, moodBad, moodNeutral, moodGood, moodVeryGood
    case moodNote, moodSave, moodSaved, moodTags
    case tagHappy, tagSad, tagTired, tagStressed, tagGrateful, tagMotivated, tagOverwhelmed, tagRelaxed
    case moodWeek, moodMonth, moodCalendar, moodAverage, moodPrevious, moodNoData
    case trendUp, trendDown, trendFlat, moodEntries, moodJournalTitle, moodToJournal, moodAddAnother
    case journalEmpty, journalSearch, journalNew, journalFree, journalGuided
    case journalTitleField, journalBody, journalTags, journalAddTag, journalDate
    case journalDeleteTitle, journalDeleteMessage, reflectionChoose, reflectionSave
    case kindGratitude, kindSelfWorth, kindStress, kindReview, kindMindful, kindMotivation, kindFeelings
    case reflectionFoot, tagAll
    case promptGratitude1, promptGratitude2, promptGratitude3
    case promptWorth1, promptWorth2, promptWorth3
    case promptStress1, promptStress2, promptStress3
    case promptReview1, promptReview2, promptReview3
    case promptMind1, promptMind2, promptMind3
    case promptMotive1, promptMotive2, promptMotive3
    case promptFeel1, promptFeel2, promptFeel3
    case calmIntro, groundingTitle, groundingLead, groundingShortcut
    case breathTitle, focusTitle, soundTitle, moveTitle
    case breathCalm, breathBox, breathSleep, breathStress, breathCustom
    case breathCalmDetail, breathBoxDetail, breathSleepDetail, breathStressDetail
    case phaseInhale, phaseHold, phaseExhale, phaseRest
    case cycleLine, inhaleSeconds, holdSeconds, exhaleSeconds, restSeconds, cycleCount
    case start, pauseSession, resumeSession, stopSession, sessionDone
    case focusPick, focusMinutes, focusRunning, focusPaused, focusEnd, focusFinished, focusCustom
    case soundRain, soundOcean, soundForest, soundWind, soundFire, soundNature
    case soundGenerated, soundPlaying, soundStopped, soundFailed
    case moveNext, moveFinish, moveComfort
    case moveStretch, moveShoulders, moveBreak, moveRelax
    case moveLeadStretch, moveLeadShoulders, moveLeadBreak, moveLeadRelax
    case stepNeck, stepNeckDetail, stepSide, stepSideDetail, stepRoll, stepRollDetail
    case stepFold, stepFoldDetail, stepTall, stepTallDetail
    case stepShrug, stepShrugDetail, stepCircle, stepCircleDetail, stepOpen, stepOpenDetail, stepHug, stepHugDetail
    case stepStand, stepStandDetail, stepMarch, stepMarchDetail, stepWrist, stepWristDetail
    case stepShake, stepShakeDetail, stepEasy, stepEasyDetail
    case stepJaw, stepJawDetail, stepHands, stepHandsDetail, stepDrop, stepDropDetail
    case stepSeat, stepSeatDetail, stepSlow, stepSlowDetail
    case groundSee, groundTouch, groundHear, groundSmell, groundTaste
    case groundFeeling, groundThought, groundThoughtPlaceholder, groundDone, groundStep
    case calmLine1, calmLine2, calmLine3, rewardNoted
}

enum CareCopy {
    static func text(_ key: CareString, _ language: CareLanguage) -> String {
        let german = language == .german
        func pick(_ de: String, _ en: String) -> String { german ? de : en }
        switch key {
        case .careTitle: return pick("Für mich", "For me")
        case .tabHabits: return pick("Gewohnheiten", "Habits")
        case .tabMood: return pick("Stimmung", "Mood")
        case .tabJournal: return pick("Tagebuch", "Journal")
        case .tabCalm: return pick("Ruhe", "Calm")
        case .save: return pick("Sichern", "Save")
        case .cancel: return pick("Abbrechen", "Cancel")
        case .delete: return pick("Löschen", "Delete")
        case .edit: return pick("Bearbeiten", "Edit")
        case .close: return pick("Schließen", "Close")
        case .done: return pick("Fertig", "Done")
        case .add: return pick("Neu", "New")
        case .today: return pick("Heute", "Today")
        case .disclaimer: return pick(
            "Gooby stellt keine Diagnosen und bietet keine Therapie. Das hier sind kleine Alltagsübungen und Notizen.",
            "Gooby does not diagnose anything and does not provide therapy. These are small everyday exercises and notes."
        )
        case .notShared: return pick(
            "Alles bleibt auf diesem Gerät. Wenn du echte Unterstützung brauchst, wende dich an einen Menschen oder eine Stelle, der du vertraust.",
            "Everything stays on this device. If you need real support, turn to a person or service you trust."
        )
        case .habitsEmpty: return pick("Noch keine Gewohnheit. Ein kleiner Schritt reicht.", "No habits yet. One small step is enough.")
        case .habitsEmptyArchive: return pick("Das Archiv ist leer.", "The archive is empty.")
        case .noHabitsDue: return pick("An diesem Tag ist nichts fällig.", "Nothing is due on this day.")
        case .addHabit: return pick("Gewohnheit anlegen", "Add a habit")
        case .editHabit: return pick("Gewohnheit bearbeiten", "Edit habit")
        case .fieldTitle: return pick("Titel", "Title")
        case .fieldDescription: return pick("Beschreibung", "Description")
        case .fieldIcon: return pick("Symbol", "Icon")
        case .fieldColor: return pick("Farbe", "Color")
        case .fieldCategory: return pick("Kategorie", "Category")
        case .fieldPriority: return pick("Priorität", "Priority")
        case .fieldStart: return pick("Beginn", "Starts")
        case .fieldEnd: return pick("Ende", "Ends")
        case .fieldNoEnd: return pick("Ohne Enddatum", "No end date")
        case .fieldRepeat: return pick("Wiederholung", "Repeat")
        case .fieldReminder: return pick("Erinnerung", "Reminder")
        case .fieldRepetitions: return pick("Wiederholungen am Tag", "Times per day")
        case .fieldReward: return pick("Belohnungswert", "Reward")
        case .fieldDailyGoal: return pick("Tagesziel", "Daily goal")
        case .dailyGoalHint: return pick("Es gibt immer nur ein Tagesziel. Es bringt einen Extra-Bonus.", "There is only one daily goal. It adds a bonus.")
        case .filterActive: return pick("Aktiv", "Active")
        case .filterArchive: return pick("Archiv", "Archive")
        case .archive: return pick("Archivieren", "Archive")
        case .restore: return pick("Zurückholen", "Restore")
        case .pause: return pick("Pausieren", "Pause")
        case .resume: return pick("Fortsetzen", "Resume")
        case .skip: return pick("Überspringen", "Skip")
        case .undoSkip: return pick("Überspringen zurücknehmen", "Undo skip")
        case .undo: return pick("Rückgängig", "Undo")
        case .completeRep: return pick("Erledigt", "Done")
        case .reschedule: return pick("Verschieben", "Move")
        case .moveTo: return pick("Verschieben auf", "Move to")
        case .deleteHabitTitle: return pick("Gewohnheit löschen?", "Delete this habit?")
        case .deleteHabitMessage: return pick("Die Einträge dieser Gewohnheit werden mit gelöscht.", "This also removes the habit's check-ins.")
        case .pausedSection: return pick("Pausiert", "Paused")
        case .skippedBadge: return pick("Übersprungen", "Skipped")
        case .doneBadge: return pick("Geschafft", "Complete")
        case .dailyGoalBadge: return pick("Tagesziel", "Daily goal")
        case .repsOf: return pick("%1$d von %2$d", "%1$d of %2$d")
        case .progressLine: return pick("%1$d geschafft · %2$d fällig", "%1$d done · %2$d due")
        case .futureLocked: return pick("Diesen Tag kannst du erst eintragen, wenn er da ist.", "You can check this day in when it arrives.")
        case .pastHint: return pick("Nachtragen für einen vergangenen Tag.", "Log a past day.")
        case .ruleOnce: return pick("Einmalig", "Once")
        case .ruleDaily: return pick("Täglich", "Daily")
        case .ruleWeekly: return pick("Wöchentlich", "Weekly")
        case .ruleMonthly: return pick("Monatlich", "Monthly")
        case .ruleWeekdays: return pick("Wochentage", "Weekdays")
        case .ruleEvery: return pick("Alle X Tage", "Every X days")
        case .ruleCustom: return pick("Benutzerdefiniert", "Custom")
        case .everyDays: return pick("Alle %d Tage", "Every %d days")
        case .monthDays: return pick("Tage im Monat", "Days of the month")
        case .customHint: return pick("Es gelten alle gesetzten Regeln zusammen. Der 31. fällt in kurzen Monaten auf den letzten Tag.", "Every rule you set applies together. The 31st lands on the last day of a short month.")
        case .priorityLow: return pick("Niedrig", "Low")
        case .priorityNormal: return pick("Normal", "Normal")
        case .priorityHigh: return pick("Hoch", "High")
        case .weekdaySun: return pick("So", "Sun")
        case .weekdayMon: return pick("Mo", "Mon")
        case .weekdayTue: return pick("Di", "Tue")
        case .weekdayWed: return pick("Mi", "Wed")
        case .weekdayThu: return pick("Do", "Thu")
        case .weekdayFri: return pick("Fr", "Fri")
        case .weekdaySat: return pick("Sa", "Sat")
        case .catMorning: return pick("Morgenroutine", "Morning routine")
        case .catEvening: return pick("Abendroutine", "Evening routine")
        case .catHygiene: return pick("Hygiene", "Hygiene")
        case .catMovement: return pick("Bewegung", "Movement")
        case .catSleep: return pick("Schlaf", "Sleep")
        case .catLearning: return pick("Lernen", "Learning")
        case .catHousehold: return pick("Haushalt", "Home")
        case .catMindfulness: return pick("Achtsamkeit", "Mindfulness")
        case .catHealth: return pick("Gesundheit", "Health")
        case .catCreativity: return pick("Kreativität", "Creativity")
        case .catCustom: return pick("Eigene", "Custom")
        case .customCategory: return pick("Eigener Name", "Custom name")
        case .reminderBody: return pick("Kleine Erinnerung an deine Gewohnheit.", "A small reminder for your habit.")
        case .historyCount: return pick("%d Abschlüsse bisher", "%d check-ins so far")
        case .pauseUntil: return pick("Pausiert bis einschließlich", "Paused through")
        case .pauseOpen: return pick("Ohne Enddatum pausieren", "Pause with no end date")
        case .starterWater: return pick("Wasser trinken", "Drink water")
        case .starterBed: return pick("Bett machen", "Make the bed")
        case .starterTeeth: return pick("Zähne putzen", "Brush your teeth")
        case .starterWalk: return pick("Spaziergang", "Go for a walk")
        case .starterRelax: return pick("Kurz entspannen", "Take a short pause")
        case .starterNote: return pick("Etwas Schönes aufschreiben", "Write down something good")
        case .errEmptyTitle: return pick("Bitte einen Titel eintragen.", "Add a title.")
        case .errInterval: return pick("Der Abstand muss zwischen 1 und 366 Tagen liegen.", "The interval must be from 1 to 366 days.")
        case .errWeekdays: return pick("Wähle mindestens einen Wochentag.", "Choose at least one weekday.")
        case .errCustom: return pick("Setze mindestens eine eigene Regel.", "Set at least one custom rule.")
        case .errDates: return pick("Das Ende liegt vor dem Beginn.", "The end is before the start.")
        case .errReps: return pick("Die Wiederholungen müssen zwischen 1 und 24 liegen.", "Repetitions must be from 1 to 24.")
        case .errReward: return pick("Der Belohnungswert muss zwischen 0 und 100 liegen.", "The reward must be from 0 to 100.")
        case .errMonthDay: return pick("Der Tag im Monat muss zwischen 1 und 31 liegen.", "The day of the month must be from 1 to 31.")
        case .errCustomName: return pick("Wie heißt deine eigene Kategorie?", "Name your custom category.")
        case .errSymbol: return pick("Dieses Symbol gibt es hier nicht.", "That icon is not available.")
        case .errColor: return pick("Diese Farbe gibt es hier nicht.", "That color is not available.")
        case .errReminder: return pick("Die Uhrzeit der Erinnerung stimmt nicht.", "The reminder time is not valid.")
        case .errPause: return pick("Das Pausenende liegt vor dem Anfang.", "The pause ends before it starts.")
        case .errNotDue: return pick("An diesem Tag ist die Gewohnheit nicht fällig.", "This habit is not due that day.")
        case .errAlreadyDone: return pick("Für diesen Tag ist schon alles eingetragen.", "This day is already filled in.")
        case .errSameDay: return pick("Das ist derselbe Tag.", "That is the same day.")
        case .errOutOfRange: return pick("Der Tag liegt außerhalb von Beginn und Ende.", "That day is outside the start and end.")
        case .errTargetDue: return pick("An dem Tag ist sie schon fällig.", "It is already due on that day.")
        case .errFuture: return pick("Zukünftige Tage kann man noch nicht abhaken.", "Future days cannot be checked off yet.")
        case .errPaused: return pick("Die Gewohnheit ist an dem Tag pausiert.", "The habit is paused that day.")
        case .errMissing: return pick("Das gibt es nicht mehr.", "That no longer exists.")
        case .errEmptyEntry: return pick("Schreib ein paar Worte oder einen Titel.", "Write a few words or a title.")
        case .errEmptyReflection: return pick("Beantworte mindestens eine Frage.", "Answer at least one prompt.")
        case .moodQuestion: return pick("Wie ist deine Stimmung?", "How is your mood?")
        case .moodVeryBad: return pick("Sehr schlecht", "Very low")
        case .moodBad: return pick("Schlecht", "Low")
        case .moodNeutral: return pick("Neutral", "Neutral")
        case .moodGood: return pick("Gut", "Good")
        case .moodVeryGood: return pick("Sehr gut", "Very good")
        case .moodNote: return pick("Notiz dazu", "A note")
        case .moodSave: return pick("Stimmung sichern", "Save mood")
        case .moodSaved: return pick("Gespeichert.", "Saved.")
        case .moodTags: return pick("Dazu noch", "Also")
        case .tagHappy: return pick("Glücklich", "Happy")
        case .tagSad: return pick("Traurig", "Sad")
        case .tagTired: return pick("Müde", "Tired")
        case .tagStressed: return pick("Gestresst", "Stressed")
        case .tagGrateful: return pick("Dankbar", "Grateful")
        case .tagMotivated: return pick("Motiviert", "Motivated")
        case .tagOverwhelmed: return pick("Überfordert", "Overwhelmed")
        case .tagRelaxed: return pick("Entspannt", "Relaxed")
        case .moodWeek: return pick("Diese Woche", "This week")
        case .moodMonth: return pick("Dieser Monat", "This month")
        case .moodCalendar: return pick("Kalender", "Calendar")
        case .moodAverage: return pick("Schnitt %@", "Average %@")
        case .moodPrevious: return pick("Davor %@", "Before %@")
        case .moodNoData: return pick("Noch keine Stimmung in diesem Zeitraum.", "No moods in this stretch yet.")
        case .trendUp: return pick("Etwas leichter als davor", "A little lighter than before")
        case .trendDown: return pick("Etwas schwerer als davor", "A little heavier than before")
        case .trendFlat: return pick("Ungefähr wie davor", "About the same as before")
        case .moodEntries: return pick("%d Einträge", "%d entries")
        case .moodJournalTitle: return pick("Stimmung", "Mood")
        case .moodToJournal: return pick("Als Tagebuchnotiz", "Save as a journal note")
        case .moodAddAnother: return pick("Noch eine Stimmung", "Add another mood")
        case .journalEmpty: return pick("Dein Tagebuch ist noch leer.", "Your journal is still empty.")
        case .journalSearch: return pick("Suchen", "Search")
        case .journalNew: return pick("Eintrag", "Entry")
        case .journalFree: return pick("Frei schreiben", "Free writing")
        case .journalGuided: return pick("Geführte Reflexion", "Guided reflection")
        case .journalTitleField: return pick("Titel", "Title")
        case .journalBody: return pick("Text", "Writing")
        case .journalTags: return pick("Tags", "Tags")
        case .journalAddTag: return pick("Tag", "Tag")
        case .journalDate: return pick("Datum", "Date")
        case .journalDeleteTitle: return pick("Eintrag löschen?", "Delete this entry?")
        case .journalDeleteMessage: return pick("Der Text wird nur auf diesem Gerät entfernt.", "The writing is removed only on this device.")
        case .reflectionChoose: return pick("Wähle eine Reflexion", "Choose a reflection")
        case .reflectionSave: return pick("Reflexion sichern", "Save reflection")
        case .kindGratitude: return pick("Dankbarkeit", "Gratitude")
        case .kindSelfWorth: return pick("Selbstwert", "Self-worth")
        case .kindStress: return pick("Stressbewältigung", "Coping with stress")
        case .kindReview: return pick("Tagesrückblick", "Daily review")
        case .kindMindful: return pick("Achtsamkeit", "Mindfulness")
        case .kindMotivation: return pick("Motivation", "Motivation")
        case .kindFeelings: return pick("Gefühle", "Feelings")
        case .reflectionFoot: return pick("Das sind persönliche Notizen, keine Auswertung und keine Therapie.", "These are personal notes, not an assessment and not therapy.")
        case .tagAll: return pick("Alle", "All")
        case .promptGratitude1: return pick("Was war heute klein und gut?", "What was small and good today?")
        case .promptGratitude2: return pick("Wer oder was hat mir geholfen?", "Who or what helped me?")
        case .promptGratitude3: return pick("Was möchte ich davon behalten?", "What do I want to keep from it?")
        case .promptWorth1: return pick("Was habe ich getan, das gezählt hat, auch wenn es klein war?", "What did I do that mattered, even a little?")
        case .promptWorth2: return pick("Was würde ich einer befreundeten Person an meiner Stelle sagen?", "What would I say to a friend in my place?")
        case .promptWorth3: return pick("Welche Stärke war heute da?", "Which strength showed up today?")
        case .promptStress1: return pick("Was liegt gerade auf mir?", "What is weighing on me?")
        case .promptStress2: return pick("Was liegt heute in meiner Hand?", "What is in my hands today?")
        case .promptStress3: return pick("Was ist ein kleiner nächster Schritt?", "What is one small next step?")
        case .promptReview1: return pick("Was ist heute passiert?", "What happened today?")
        case .promptReview2: return pick("Was war in Ordnung?", "What felt okay?")
        case .promptReview3: return pick("Was kann bis morgen warten?", "What can wait until tomorrow?")
        case .promptMind1: return pick("Was merke ich gerade im Körper?", "What do I notice in my body right now?")
        case .promptMind2: return pick("Was sehe, höre oder fühle ich in diesem Raum?", "What can I see, hear, or feel in this room?")
        case .promptMind3: return pick("Wie ist dieser Moment, ohne ihn reparieren zu müssen?", "How is this moment, without fixing it?")
        case .promptMotive1: return pick("Was ist mir diese Woche wichtig?", "What matters to me this week?")
        case .promptMotive2: return pick("Welchen winzigen Schritt kann ich tun?", "What tiny step can I take?")
        case .promptMotive3: return pick("Was würde morgen ein bisschen leichter machen?", "What would make tomorrow a little easier?")
        case .promptFeel1: return pick("Welches Gefühl ist gerade da?", "Which feeling is here?")
        case .promptFeel2: return pick("Woran merke ich es?", "Where do I notice it?")
        case .promptFeel3: return pick("Was braucht es von mir, ohne Bewertung?", "What does it need from me, without a verdict?")
        case .calmIntro: return pick("Kleine Pausen. Nichts davon muss perfekt sein.", "Small pauses. None of this has to be perfect.")
        case .groundingTitle: return pick("Ankommen", "Arrive here")
        case .groundingLead: return pick("Bemerke, was gerade um dich ist. Du kannst jeden Schritt leer lassen.", "Notice what is around you. You can leave any step blank.")
        case .groundingShortcut: return pick("Ankommen", "Arrive")
        case .breathTitle: return pick("Atmen", "Breathing")
        case .focusTitle: return pick("Fokus", "Focus")
        case .soundTitle: return pick("Klänge", "Sounds")
        case .moveTitle: return pick("Bewegen", "Movement")
        case .breathCalm: return pick("Ruhiges Atmen", "Calm breathing")
        case .breathBox: return pick("Box Breathing", "Box breathing")
        case .breathSleep: return pick("Einschlafatmung", "Sleep breathing")
        case .breathStress: return pick("Bei Anspannung", "When you feel tense")
        case .breathCustom: return pick("Eigene Intervalle", "Custom intervals")
        case .breathCalmDetail: return pick("4 Sekunden ein, kurz halten, 6 Sekunden aus.", "In for 4, a short hold, out for 6.")
        case .breathBoxDetail: return pick("4 ein, 4 halten, 4 aus, 4 halten.", "4 in, 4 hold, 4 out, 4 hold.")
        case .breathSleepDetail: return pick("4 ein, 7 halten, 8 aus.", "In for 4, hold for 7, out for 8.")
        case .breathStressDetail: return pick("4 ein, 6 aus, kurz ruhen. Nur ein Atemrhythmus, nichts weiter.", "In for 4, out for 6, a short rest. Only a rhythm, nothing more.")
        case .phaseInhale: return pick("Einatmen", "Breathe in")
        case .phaseHold: return pick("Halten", "Hold")
        case .phaseExhale: return pick("Ausatmen", "Breathe out")
        case .phaseRest: return pick("Ruhen", "Rest")
        case .cycleLine: return pick("Runde %1$d von %2$d", "Cycle %1$d of %2$d")
        case .inhaleSeconds: return pick("Einatmen", "Inhale")
        case .holdSeconds: return pick("Halten", "Hold")
        case .exhaleSeconds: return pick("Ausatmen", "Exhale")
        case .restSeconds: return pick("Pause danach", "Rest after")
        case .cycleCount: return pick("Runden", "Cycles")
        case .start: return pick("Start", "Start")
        case .pauseSession: return pick("Pause", "Pause")
        case .resumeSession: return pick("Weiter", "Resume")
        case .stopSession: return pick("Beenden", "End")
        case .sessionDone: return pick("Runde geschafft.", "That round is complete.")
        case .focusPick: return pick("Wie lange?", "How long?")
        case .focusMinutes: return pick("%d Minuten", "%d minutes")
        case .focusRunning: return pick("Läuft", "Running")
        case .focusPaused: return pick("Pausiert", "Paused")
        case .focusEnd: return pick("Beenden ohne Belohnung", "End without a reward")
        case .focusFinished: return pick("Zeit um. Kleine Belohnung fürs Dranbleiben.", "Time is up. A small reward for staying with it.")
        case .focusCustom: return pick("Eigene Minuten", "Custom minutes")
        case .soundRain: return pick("Regen", "Rain")
        case .soundOcean: return pick("Meer", "Ocean")
        case .soundForest: return pick("Wald", "Forest")
        case .soundWind: return pick("Wind", "Wind")
        case .soundFire: return pick("Kamin", "Fireplace")
        case .soundNature: return pick("Sanfte Natur", "Gentle nature")
        case .soundGenerated: return pick("Leise und auf dem Gerät erzeugt. Keine Aufnahme und kein Stream.", "Quiet and generated on this device. Not a recording and not a stream.")
        case .soundPlaying: return pick("Läuft", "Playing")
        case .soundStopped: return pick("Aus", "Off")
        case .soundFailed: return pick("Der Klang konnte hier nicht starten.", "The sound could not start here.")
        case .moveNext: return pick("Weiter", "Next")
        case .moveFinish: return pick("Abschließen", "Finish")
        case .moveComfort: return pick("Hör auf, wenn sich etwas unangenehm anfühlt. Das sind sanfte Vorschläge, keine Übung mit einem Ziel für den Körper.", "Stop if something feels uncomfortable. These are gentle suggestions, not a body goal.")
        case .moveStretch: return pick("Dehnen", "Stretching")
        case .moveShoulders: return pick("Schultern", "Shoulders")
        case .moveBreak: return pick("Bewegungspause", "Movement break")
        case .moveRelax: return pick("Entspannen", "Relax")
        case .moveLeadStretch: return pick("Nacken, Seite, Rollen, eine leichte Beuge.", "Neck, side, rolls, an easy fold.")
        case .moveLeadShoulders: return pick("Schultern heben, kreisen, öffnen.", "Shrug, circle, and open the shoulders.")
        case .moveLeadBreak: return pick("Aufstehen, gehen, Hände ausschütteln.", "Stand, walk in place, shake out your hands.")
        case .moveLeadRelax: return pick("Kiefer, Hände und Schultern weich werden lassen.", "Let the jaw, hands, and shoulders soften.")
        case .stepNeck: return pick("Nacken", "Neck")
        case .stepNeckDetail: return pick("Schau langsam nach links, dann nach rechts.", "Look slowly to the left, then to the right.")
        case .stepSide: return pick("Seite", "Side")
        case .stepSideDetail: return pick("Ein Arm nach oben, sanft zur Seite lehnen. Dann die andere Seite.", "One arm up, lean gently to the side. Then the other side.")
        case .stepRoll: return pick("Schultern rollen", "Shoulder rolls")
        case .stepRollDetail: return pick("Langsame Kreise nach hinten.", "Slow circles backward.")
        case .stepFold: return pick("Beuge", "Fold")
        case .stepFoldDetail: return pick("Nur so weit, wie es leicht geht. Knie dürfen weich bleiben.", "Only as far as feels easy. Knees can stay soft.")
        case .stepTall: return pick("Groß stehen", "Stand tall")
        case .stepTallDetail: return pick("Beide Füße spüren und einmal ruhig atmen.", "Feel both feet and take one quiet breath.")
        case .stepShrug: return pick("Hochziehen", "Shrug")
        case .stepShrugDetail: return pick("Schultern zu den Ohren, dann fallen lassen.", "Shoulders toward the ears, then drop them.")
        case .stepCircle: return pick("Kreisen", "Circles")
        case .stepCircleDetail: return pick("Langsame Kreise nach hinten.", "Slow circles backward.")
        case .stepOpen: return pick("Öffnen", "Open")
        case .stepOpenDetail: return pick("Arme weich zur Seite, Brust darf weit sein.", "Arms softly out to the sides. The chest can be wide.")
        case .stepHug: return pick("Umarmen", "Hug")
        case .stepHugDetail: return pick("Dich selbst kurz umarmen, dann lösen.", "Give yourself a short hug, then let go.")
        case .stepStand: return pick("Aufstehen", "Stand up")
        case .stepStandDetail: return pick("Komm hoch, wenn das gerade geht. Sonst bleib sitzen.", "Stand if you can. Otherwise stay seated.")
        case .stepMarch: return pick("Marschieren", "March")
        case .stepMarchDetail: return pick("Locker auf der Stelle gehen.", "Walk easily in place.")
        case .stepWrist: return pick("Handgelenke", "Wrists")
        case .stepWristDetail: return pick("Kleine Kreise mit beiden Händen.", "Small circles with both hands.")
        case .stepShake: return pick("Ausschütteln", "Shake out")
        case .stepShakeDetail: return pick("Hände locker ausschütteln.", "Shake your hands loose.")
        case .stepEasy: return pick("Ankommen", "Settle")
        case .stepEasyDetail: return pick("Stehen oder sitzen, wie es gerade passt.", "Stand or sit, whichever fits.")
        case .stepJaw: return pick("Kiefer", "Jaw")
        case .stepJawDetail: return pick("Zähne nicht aufeinander. Der Kiefer darf locker sein.", "Teeth apart. The jaw can be loose.")
        case .stepHands: return pick("Hände", "Hands")
        case .stepHandsDetail: return pick("Finger öffnen, dann weich lassen.", "Open the fingers, then let them soften.")
        case .stepDrop: return pick("Schultern", "Shoulders")
        case .stepDropDetail: return pick("Schultern nach unten sinken lassen.", "Let the shoulders sink down.")
        case .stepSeat: return pick("Sitz", "Seat")
        case .stepSeatDetail: return pick("Spüre Stuhl oder Boden unter dir.", "Feel the chair or the floor under you.")
        case .stepSlow: return pick("Ein Atemzug", "One breath")
        case .stepSlowDetail: return pick("Ein langsamer Atemzug, ohne ihn zu bewerten.", "One slow breath, without judging it.")
        case .groundSee: return pick("Nenne bis zu fünf Dinge, die du siehst.", "Name up to five things you can see.")
        case .groundTouch: return pick("Nenne bis zu vier Dinge, die du berühren kannst.", "Name up to four things you can touch.")
        case .groundHear: return pick("Nenne bis zu drei Dinge, die du hörst.", "Name up to three things you can hear.")
        case .groundSmell: return pick("Nenne bis zu zwei Dinge, die du riechst.", "Name up to two things you can smell.")
        case .groundTaste: return pick("Nenne eine Sache, die du schmeckst.", "Name one thing you can taste.")
        case .groundFeeling: return pick("Welches Gefühl ist gerade da? Du musst keins wählen.", "Which feeling is here? You do not have to pick one.")
        case .groundThought: return pick("Wenn du magst, schreib einen Gedanken auf. Er landet nur im Tagebuch auf diesem Gerät.", "If you want, write a thought down. It goes only into the journal on this device.")
        case .groundThoughtPlaceholder: return pick("Der Gedanke darf unfertig sein.", "The thought can be unfinished.")
        case .groundDone: return pick("Du bist für einen Moment hier. Das reicht.", "You are here for a moment. That is enough.")
        case .groundStep: return pick("Schritt %1$d von %2$d", "Step %1$d of %2$d")
        case .calmLine1: return pick("Du kannst das langsam nehmen.", "You can take this slowly.")
        case .calmLine2: return pick("Du musst in dieser Minute nicht alles lösen.", "You do not have to solve everything in this minute.")
        case .calmLine3: return pick("Gooby sitzt einen Moment mit dir.", "Gooby sits with you for a moment.")
        case .rewardNoted: return pick("Dafür gibt es eine kleine Belohnung.", "That earns a small reward.")
        }
    }

    static func format(_ key: CareString, _ language: CareLanguage, _ args: [CVarArg]) -> String {
        String(format: text(key, language), locale: Locale(identifier: language.localeIdentifier), arguments: args)
    }

    static func issue(_ issue: CareIssue, _ language: CareLanguage) -> String {
        switch issue {
        case .emptyTitle: return text(.errEmptyTitle, language)
        case .interval: return text(.errInterval, language)
        case .weekdays: return text(.errWeekdays, language)
        case .custom: return text(.errCustom, language)
        case .dates: return text(.errDates, language)
        case .reps: return text(.errReps, language)
        case .reward: return text(.errReward, language)
        case .monthDay: return text(.errMonthDay, language)
        case .customName: return text(.errCustomName, language)
        case .symbol: return text(.errSymbol, language)
        case .color: return text(.errColor, language)
        case .reminder: return text(.errReminder, language)
        case .pause: return text(.errPause, language)
        case .notDue: return text(.errNotDue, language)
        case .alreadyDone: return text(.errAlreadyDone, language)
        case .sameDay: return text(.errSameDay, language)
        case .outOfRange: return text(.errOutOfRange, language)
        case .targetDue: return text(.errTargetDue, language)
        case .future: return text(.errFuture, language)
        case .paused: return text(.errPaused, language)
        case .missing: return text(.errMissing, language)
        case .emptyEntry: return text(.errEmptyEntry, language)
        case .emptyReflection: return text(.errEmptyReflection, language)
        }
    }

    static func category(_ category: HabitCategory, _ language: CareLanguage) -> String {
        switch category {
        case .morning: return text(.catMorning, language)
        case .evening: return text(.catEvening, language)
        case .hygiene: return text(.catHygiene, language)
        case .movement: return text(.catMovement, language)
        case .sleep: return text(.catSleep, language)
        case .learning: return text(.catLearning, language)
        case .household: return text(.catHousehold, language)
        case .mindfulness: return text(.catMindfulness, language)
        case .health: return text(.catHealth, language)
        case .creativity: return text(.catCreativity, language)
        case .custom: return text(.catCustom, language)
        }
    }

    static func priority(_ priority: HabitPriority, _ language: CareLanguage) -> String {
        switch priority {
        case .low: return text(.priorityLow, language)
        case .normal: return text(.priorityNormal, language)
        case .high: return text(.priorityHigh, language)
        }
    }

    static func weekday(_ weekday: Int, _ language: CareLanguage) -> String {
        switch weekday {
        case 1: return text(.weekdaySun, language)
        case 2: return text(.weekdayMon, language)
        case 3: return text(.weekdayTue, language)
        case 4: return text(.weekdayWed, language)
        case 5: return text(.weekdayThu, language)
        case 6: return text(.weekdayFri, language)
        case 7: return text(.weekdaySat, language)
        default: return ""
        }
    }

    static func mood(_ level: MoodLevel, _ language: CareLanguage) -> String {
        switch level {
        case .veryBad: return text(.moodVeryBad, language)
        case .bad: return text(.moodBad, language)
        case .neutral: return text(.moodNeutral, language)
        case .good: return text(.moodGood, language)
        case .veryGood: return text(.moodVeryGood, language)
        }
    }

    static func tag(_ tag: MoodTag, _ language: CareLanguage) -> String {
        switch tag {
        case .happy: return text(.tagHappy, language)
        case .sad: return text(.tagSad, language)
        case .tired: return text(.tagTired, language)
        case .stressed: return text(.tagStressed, language)
        case .grateful: return text(.tagGrateful, language)
        case .motivated: return text(.tagMotivated, language)
        case .overwhelmed: return text(.tagOverwhelmed, language)
        case .relaxed: return text(.tagRelaxed, language)
        }
    }

    static func reflection(_ kind: ReflectionKind, _ language: CareLanguage) -> String {
        switch kind {
        case .gratitude: return text(.kindGratitude, language)
        case .selfWorth: return text(.kindSelfWorth, language)
        case .stressCoping: return text(.kindStress, language)
        case .dailyReview: return text(.kindReview, language)
        case .mindfulness: return text(.kindMindful, language)
        case .motivation: return text(.kindMotivation, language)
        case .feelings: return text(.kindFeelings, language)
        }
    }

    static func phase(_ phase: BreathPhaseKind, _ language: CareLanguage) -> String {
        switch phase {
        case .inhale: return text(.phaseInhale, language)
        case .hold: return text(.phaseHold, language)
        case .exhale: return text(.phaseExhale, language)
        case .rest: return text(.phaseRest, language)
        }
    }
}
