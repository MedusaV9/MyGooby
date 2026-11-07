import Foundation

struct AdventureCopy {
    var language: AdventureLanguage

    var screenTitle: String { pick("Abenteuer", "Adventures") }
    var subtitle: String { pick("Kleine Reisen, echte Uhr", "Little journeys, a real clock") }
    var start: String { pick("Abenteuer starten", "Start adventure") }
    var map: String { pick("Weltkarte", "World map") }
    var discoveries: String { pick("Entdeckungen", "Discoveries") }
    var personality: String { pick("Persönlichkeit", "Personality") }
    var back: String { pick("Zurück", "Back") }
    var home: String { pick("Ins Zimmer", "Back to the room") }
    var hearStory: String { pick("Geschichte anhören", "Hear the story") }
    var destination: String { pick("Ziel", "Destination") }
    var changeOnMap: String { pick("Auf der Karte ändern", "Change it on the map") }
    var energyTitle: String { pick("Energie", "Energy") }
    var chooseHint: String { pick("Wie antwortet ihr?", "How do you answer?") }
    var outcomeTitle: String { pick("So ist es ausgegangen", "How it turned out") }
    var newDiscovery: String { pick("Neue Entdeckung", "New discovery") }
    var alreadyKnown: String { pick("Das lag schon im Körbchen.", "That was already in the basket.") }
    var steadyTraits: String { pick("Heute bleibt alles, wie es ist. Das ist auch in Ordnung.", "Nothing shifts today, and that is all right.") }
    var clockNote: String { pick("Die Uhr läuft weiter, auch wenn die App zu ist.", "The clock keeps going, even while the app is closed.") }
    var energyHint: String { pick("Sammle noch ein wenig Energie mit kleinen Aufgaben.", "Gather a little more energy with small tasks.") }
    var energyRefused: String { pick("Die Energie hat gerade nicht gereicht.", "There was not enough energy just now.") }
    var placeLockedBanner: String { pick("Dieses Ziel ist noch zu.", "This destination is still closed.") }
    var catalogError: String { pick("Die Geschichten lassen sich gerade nicht lesen.", "The stories cannot be read right now.") }
    var selectPlace: String { pick("Als Ziel wählen", "Choose as destination") }
    var selected: String { pick("Ausgewählt", "Selected") }
    var locked: String { pick("Noch zu", "Still closed") }
    var open: String { pick("Offen", "Open") }
    var visits: String { pick("Besuche", "Visits") }
    var storiesLabel: String { pick("Geschichten", "Stories") }
    var found: String { pick("Gefunden", "Found") }
    var hidden: String { pick("Noch verborgen", "Still hidden") }
    var close: String { pick("Schließen", "Close") }
    var personalityNote: String { pick("Jede Antwort verändert nur einen kleinen Schritt. Das wächst langsam.", "Each answer changes only a small step. It grows slowly.") }
    var today: String { pick("Heute", "Today") }
    var restedTitle: String { pick("Für heute ist die Reise vorbei", "Today's journey is done") }
    var restedBody: String { pick("Morgen darf wieder gepackt werden.", "Tomorrow there is room for another one.") }
    var onTheWay: String { pick("Unterwegs", "On the way") }
    var placesTitle: String { pick("Orte", "Places") }

    func readyHint(_ name: String) -> String {
        pick("Die Energie reicht. \(name) kann losziehen.", "There is enough energy. \(name) can head out.")
    }

    func leftHome(_ name: String) -> String {
        pick("\(name) ist aus dem Zimmer losgezogen.", "\(name) has left the room.")
    }

    func returnedTitle(_ name: String) -> String {
        pick("\(name) ist zurück", "\(name) is back")
    }

    func returnedBody(_ name: String) -> String {
        pick("\(name) hat etwas zu erzählen.", "\(name) has something to tell.")
    }

    func travelingToward(_ place: String) -> String {
        pick("nach \(place)", "to \(place)")
    }

    func energyValue(current: Int, goal: Int) -> String {
        pick("\(current) von \(goal)", "\(current) of \(goal)")
    }

    func sparks(_ amount: Int) -> String {
        pick("+\(amount) Sternenfunken", "+\(amount) star sparks")
    }

    func traitName(_ trait: AdventureTrait) -> String {
        switch trait {
        case .curiosity: return pick("Neugier", "Curiosity")
        case .courage: return pick("Mut", "Courage")
        case .kindness: return pick("Freundlichkeit", "Kindness")
        case .playfulness: return pick("Verspieltheit", "Playfulness")
        case .confidence: return pick("Selbstvertrauen", "Confidence")
        case .calm: return pick("Gelassenheit", "Calm")
        case .empathy: return pick("Empathie", "Empathy")
        }
    }

    func remaining(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        if seconds < 45 {
            return pick("Gleich da", "Almost back")
        }
        let minutes = max(1, seconds / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return pick("noch \(hours) Std. \(mins) Min.", "\(hours) hr \(mins) min left")
        }
        return pick("noch \(minutes) Min.", "\(minutes) min left")
    }

    func unlockRemaining(_ count: Int) -> String {
        if count == 1 {
            return pick("Noch ein Abenteuer, dann öffnet sich dieser Ort.", "One more adventure, then this place opens.")
        }
        return pick("Noch \(count) Abenteuer, dann öffnet sich dieser Ort.", "\(count) more adventures, then this place opens.")
    }

    func seenStories(seen: Int, total: Int) -> String {
        pick("\(seen) von \(total) erlebt", "\(seen) of \(total) lived")
    }

    func foundCount(found: Int, total: Int) -> String {
        pick("\(found) von \(total)", "\(found) of \(total)")
    }

    private func pick(_ german: String, _ english: String) -> String {
        language == .english ? english : german
    }
}
