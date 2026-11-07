import Foundation

// Extras preferences without a SwiftData schema change (plan D4: existing saves must open
// unchanged). A preference is a 0-spark, 0-energy reward-ledger row "pref.<name>=<value>", like
// the pause mode markers, so it is exported, imported and erased together with the save.
// `prefsRevision` (GoobyEngine) changes on every write so SwiftUI redraws the switches.
extension GoobyEngine {
    func prefValue(_ name: String) -> String? {
        _ = prefsRevision
        let prefix = "pref.\(name)="
        guard let row = all(RewardLedger.self).first(where: { $0.key.hasPrefix(prefix) }) else { return nil }
        return String(row.key.dropFirst(prefix.count))
    }

    /// Stores `value` for `name`; nil removes the preference (back to its default).
    func setPrefValue(_ name: String, _ value: String?) {
        guard prefValue(name) != value else { return }
        let prefix = "pref.\(name)="
        for row in all(RewardLedger.self) where row.key.hasPrefix(prefix) { context.delete(row) }
        if let value { grant(key: prefix + value, sparks: 0, energy: 0) }
        prefsRevision += 1
        save()
    }

    func prefFlag(_ name: String, default fallback: Bool) -> Bool {
        guard let value = prefValue(name) else { return fallback }
        return value == "on"
    }

    func setPrefFlag(_ name: String, _ on: Bool) {
        setPrefValue(name, on ? "on" : "off")
    }

    /// Settings > Preferences > Sound effects (default on).
    var soundEffectsOn: Bool { prefFlag("sfx", default: true) }

    func setSoundEffects(_ on: Bool) {
        setPrefFlag("sfx", on)
        syncExtrasPrefs()
    }

    /// Settings > Preferences > Haptic feedback (default on).
    var hapticsOn: Bool { prefFlag("haptics", default: true) }

    func setHaptics(_ on: Bool) {
        setPrefFlag("haptics", on)
        syncExtrasPrefs()
    }

    /// Settings > Preferences > Live Activities (default on). Off ends running activities.
    var liveActivitiesOn: Bool { prefFlag("liveActivities", default: true) }

    func setLiveActivities(_ on: Bool) {
        setPrefFlag("liveActivities", on)
        syncExtrasPrefs()
        if !on { GoobyLiveActivities.shared.endAll() }
    }

    /// Pushes the stored switches into the services. Called at boot, after erase and import and
    /// by every setter above.
    func syncExtrasPrefs() {
        GoobySounds.shared.enabled = soundEffectsOn
        haptics.enabled = hapticsOn
        GoobyLiveActivities.shared.enabled = liveActivitiesOn
    }
}
