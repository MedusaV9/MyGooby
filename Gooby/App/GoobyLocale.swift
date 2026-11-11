import Foundation
import SwiftData

/// App language. German is the default; English is used only when the save says `en`.
enum GoobyLocale {
    private(set) static var code = "de"

    static func normalized(_ raw: String?) -> String {
        raw == "en" ? "en" : "de"
    }

    /// `nil` keeps the language applied at launch, before the engine exists.
    static func locale(for raw: String?) -> Locale {
        Locale(identifier: raw == nil ? code : normalized(raw))
    }

    static func apply(_ raw: String?) {
        let language = normalized(raw)
        code = language
        let defaults = UserDefaults.standard
        if defaults.stringArray(forKey: "AppleLanguages")?.first != language {
            defaults.set([language], forKey: "AppleLanguages")
        }
    }

    static func applyStored(in container: ModelContainer) {
        let context = ModelContext(container)
        let profiles = (try? context.fetch(FetchDescriptor<PlayerProfile>())) ?? []
        apply(profiles.first?.languageCode)
    }
}
