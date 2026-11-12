import Foundation

/// Passport numbers and words for the profile card.
/// Weight, height, and ear span are derived from calendar age and full-energy days.
/// Day one with no full-energy day is 2.0 g, 0.5 cm, and 2.0 cm.
enum ProfilePassport {
    struct Body: Equatable {
        var grams: Double
        var heightCM: Double
        var spanCM: Double
    }

    /// The travel agency stays locked on the first six days. The seventh day is old enough.
    static let travelAgeDays = 7

    static let hexTraitIDs = ["curiosity", "courage", "kindness", "confidence", "calm", "empathy"]

    /// Hatch day, shown where a friend code used to sit. Day and month follow the app language.
    static func hatchday(_ date: Date, language: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == "en" ? "en" : "de")
        formatter.setLocalizedDateFormatFromTemplate("dMMMMy")
        return formatter.string(from: date)
    }

    static func ageDays(from createdAt: Date, to now: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: createdAt)
        let end = calendar.startOfDay(for: now)
        let span = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, span + 1)
    }

    static func body(ageDays: Int, fullEnergyDays: Int) -> Body {
        let grown = Double(max(0, ageDays - 1))
        let fed = Double(max(0, fullEnergyDays))
        return Body(
            grams: 2.0 + grown * 0.4 + fed * 0.6,
            heightCM: 0.5 + grown * 0.15 + fed * 0.25,
            spanCM: 2.0 + grown * 0.35 + fed * 0.5
        )
    }

    static func travelLocked(ageDays: Int) -> Bool {
        ageDays < travelAgeDays
    }

    static func friendship(affection: Int, language: String) -> String {
        let index: Int
        switch affection {
        case ..<3: index = 0
        case ..<10: index = 1
        case ..<25: index = 2
        case ..<50: index = 3
        default: index = 4
        }
        let english = ["Pals", "Friends", "Good friends", "Close friends", "Best friends"]
        let german = ["Kumpel", "Freunde", "Gute Freunde", "Enge Freunde", "Beste Freunde"]
        return ProfileCopy.pick(language, en: english[index], de: german[index])
    }

    /// A place is seasonal when a calendar event uses its id, or names that id in the blurb.
    /// The starter place (open from the first day) stays on the everyday list.
    static func seasonalIDs(places: [PlaceDef], events: [EventDef]) -> Set<String> {
        var ids = Set<String>()
        for place in places where place.unlockAfterAdventures > 0 {
            let token = place.id.lowercased()
            for event in events {
                if event.id.lowercased() == token {
                    ids.insert(place.id)
                    break
                }
                let blob = "\(event.blurb.de) \(event.blurb.en)"
                if words(blob).contains(token) {
                    ids.insert(place.id)
                    break
                }
            }
        }
        return ids
    }

    static func words(_ text: String) -> Set<String> {
        var found = Set<String>()
        var current = ""
        for scalar in text.lowercased().unicodeScalars {
            if CharacterSet.letters.contains(scalar) {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                found.insert(current)
                current = ""
            }
        }
        if !current.isEmpty { found.insert(current) }
        return found
    }

    static func measure(_ value: Double, unit: String, language: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: language == "en" ? "en_US" : "de_DE")
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
        return number + unit
    }
}

enum PetPronounChoice: String, CaseIterable, Identifiable {
    case he
    case she
    case they

    var id: String { rawValue }
    /// Save token. The card prints `label`, never this value.
    var stored: String { rawValue }

    func label(_ language: String) -> String {
        StringTable.text("profile.pronoun.\(rawValue)", language)
    }

    static func match(_ raw: String) -> PetPronounChoice? {
        let key = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "de"))
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
        switch key {
        case "he/him", "he", "him", "er/ihn", "er/ihm", "er", "ihn", "ihm": return .he
        case "she/her", "she", "her", "sie/ihr", "sie": return .she
        case "they/them", "they", "them", "dey/denen", "dey", "denen": return .they
        default: return nil
        }
    }
}

enum ProfileCopy {
    static func pick(_ language: String, en: String, de: String) -> String {
        language == "en" ? en : de
    }

    static func ageText(days: Int, language: String) -> String {
        if language == "en" {
            return days == 1 ? "1 day" : "\(days) days"
        }
        return days == 1 ? "1 Tag" : "\(days) Tage"
    }

    static func pronounsLine(_ raw: String, language: String) -> String {
        PetPronounChoice.match(raw)?.label(language) ?? ""
    }

    static func about(stageKey: String, language: String) -> String {
        switch stageKey {
        case "little":
            return pick(language, en: "A little bigger now, and the meadow feels familiar.", de: "Schon ein bisschen größer, die Wiese wird vertraut.")
        case "young":
            return pick(language, en: "Out and about, with more courage than yesterday.", de: "Unterwegs, mit mehr Mut als gestern.")
        case "teen":
            return pick(language, en: "Almost grown, and still playful.", de: "Fast erwachsen, und immer noch verspielt.")
        case "adult":
            return pick(language, en: "At home in a story of their own.", de: "Zuhause in der eigenen Geschichte.")
        default:
            return pick(language, en: "Just arrived, still light and curious.", de: "Gerade da, noch leicht und neugierig.")
        }
    }

    static func forestTitle(_ language: String) -> String {
        pick(language, en: "Gooby Forest", de: "Gooby-Wald")
    }

    static func foundLine(_ found: Int, _ total: Int, _ language: String) -> String {
        pick(language, en: "\(found) of \(total) found", de: "\(found) von \(total) gefunden")
    }

    static func ageLabel(_ language: String) -> String { pick(language, en: "Age", de: "Alter") }
    static func friendshipLabel(_ language: String) -> String { pick(language, en: "Friendship", de: "Freundschaft") }
    static func humanLabel(_ language: String) -> String { pick(language, en: "Human", de: "Mensch") }

    static func weightName(_ language: String) -> String { pick(language, en: "Weight", de: "Gewicht") }
    static func heightName(_ language: String) -> String { pick(language, en: "Height", de: "Größe") }
    static func spanName(_ language: String) -> String { StringTable.text("profile.measure.span", language) }

    static func editTitle(_ language: String) -> String { pick(language, en: "Edit pet profile", de: "Tierprofil bearbeiten") }
    static func changeName(_ language: String) -> String { pick(language, en: "Change name", de: "Namen ändern") }
    static func changePronouns(_ language: String) -> String { pick(language, en: "Change pronouns", de: "Pronomen ändern") }
    static func changeHuman(_ language: String) -> String { pick(language, en: "Change human name", de: "Menschennamen ändern") }
    static func changeOutfit(_ language: String) -> String { StringTable.text("profile.edit.outfit", language) }
    static func clothes(_ language: String) -> String { StringTable.text("profile.edit.clothes", language) }
    static func namePlaceholder(_ language: String) -> String { pick(language, en: "Gooby", de: "Gooby") }
    static func humanPlaceholder(_ language: String) -> String { pick(language, en: "Your name", de: "Dein Name") }
    static func pronounsMissing(_ language: String) -> String { pick(language, en: "Pronouns not chosen", de: "Pronomen nicht gewählt") }
    static func emptyCloset(_ language: String) -> String { pick(language, en: "Nothing in the closet yet.", de: "Im Schrank ist noch nichts.") }
    static func savedOutfits(_ language: String) -> String { StringTable.text("profile.edit.outfits.saved", language) }

    static func travel(_ language: String) -> String { pick(language, en: "Travel", de: "Reise") }
    static func travelOpen(_ language: String) -> String { pick(language, en: "Travel agency is open", de: "Reisebüro ist offen") }

    static func travelLockedToast(name: String, language: String) -> String {
        let safe = name.isEmpty ? "Gooby" : name
        return pick(
            language,
            en: "\(safe) needs to be older to unlock the Travel Agency!",
            de: "\(safe) muss älter sein, um das Reisebüro zu öffnen!"
        )
    }

    static func noSeasonal(_ language: String) -> String {
        pick(language, en: "No seasonal places yet.", de: "Noch keine saisonalen Orte.")
    }

    static func unknownPlace(_ language: String) -> String { pick(language, en: "Unknown place", de: "Unbekannter Ort") }
    static func allPlaces(_ language: String) -> String { pick(language, en: "All", de: "Alle") }
    static func seasonalPlaces(_ language: String) -> String { pick(language, en: "Seasonal", de: "Saison") }
    static func back(_ language: String) -> String { pick(language, en: "Back", de: "Zurück") }
}
