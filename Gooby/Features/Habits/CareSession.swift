import Combine
import Foundation

/// Language and the simulated app clock. The dev menu may replace "now" without touching the device clock.
@MainActor
final class CareSession: ObservableObject {
    static let shared = CareSession()

    @Published var language: CareLanguage = .german
    @Published var simulatedNow: Date?

    var now: Date { simulatedNow ?? Date() }

    var calendar: Calendar {
        CareDay.gregorian(
            timeZone: .current,
            firstWeekday: nil,
            locale: language.localeIdentifier
        )
    }

    var todayKey: String {
        CareDay.key(for: now, calendar: calendar)
    }

    func text(_ key: CareString) -> String {
        CareCopy.text(key, language)
    }

    func format(_ key: CareString, _ args: CVarArg...) -> String {
        CareCopy.format(key, language, args)
    }

    func setLanguageCode(_ raw: String) {
        guard let language = CareLanguage.resolve(raw) else { return }
        self.language = language
    }
}
