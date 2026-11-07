import Foundation
import Observation

/// Werte, die das App-Gerüst besitzt: Energie, App-Tag, Sprache, Name.
/// Das Abenteuer liest sie und meldet Belohnungen über die Rückrufe zurück.
@MainActor
@Observable
final class AdventureBridge {
    var energy: Int
    var energyGoal: Int
    var appNow: Date
    var languageCode: String
    var bunnyName: String
    var prefersReducedMotion: Bool
    var onGrantSparks: (Int) -> Void
    var onSpendEnergy: (Int) -> Bool
    var onPersonalityShift: (AdventurePersonalityDelta) -> Void

    var language: AdventureLanguage {
        AdventureLanguage.resolve(languageCode)
    }

    var displayName: String {
        let trimmed = bunnyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Gooby" : trimmed
    }

    func applyHost(
        energy: Int,
        energyGoal: Int,
        appNow: Date,
        languageCode: String,
        bunnyName: String,
        prefersReducedMotion: Bool
    ) {
        self.energy = energy
        self.energyGoal = energyGoal
        self.appNow = appNow
        self.languageCode = languageCode
        self.bunnyName = bunnyName
        self.prefersReducedMotion = prefersReducedMotion
    }

    init(
        energy: Int,
        energyGoal: Int,
        appNow: Date,
        languageCode: String,
        bunnyName: String,
        prefersReducedMotion: Bool,
        onGrantSparks: @escaping (Int) -> Void,
        onSpendEnergy: @escaping (Int) -> Bool,
        onPersonalityShift: @escaping (AdventurePersonalityDelta) -> Void
    ) {
        self.energy = energy
        self.energyGoal = energyGoal
        self.appNow = appNow
        self.languageCode = languageCode
        self.bunnyName = bunnyName
        self.prefersReducedMotion = prefersReducedMotion
        self.onGrantSparks = onGrantSparks
        self.onSpendEnergy = onSpendEnergy
        self.onPersonalityShift = onPersonalityShift
    }
}
