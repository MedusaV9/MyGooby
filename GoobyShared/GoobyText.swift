import Foundation

/// German or English text for surfaces outside the app's string tables: widgets, Live Activities
/// and anything else the widget extension draws. The app hands its language over in the widget
/// snapshot and the activity attributes; without it the device language decides (German for a
/// German device, English otherwise). Every string has both languages inline.
enum GoobyText {
    static func pick(_ language: String?, de: String, en: String) -> String {
        resolved(language) == "en" ? en : de
    }

    /// "de" or "en".
    static func resolved(_ language: String?) -> String {
        if let language, language == "de" || language == "en" { return language }
        return deviceLanguage
    }

    static var deviceLanguage: String {
        let first = Locale.preferredLanguages.first?.lowercased() ?? "de"
        return first.hasPrefix("de") ? "de" : "en"
    }
}
