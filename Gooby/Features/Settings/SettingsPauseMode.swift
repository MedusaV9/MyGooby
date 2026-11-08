import Foundation

/// Pause mode for the Settings switch. It pauses every active goal through the existing
/// `Habit.isPaused` (paused goals are not due and send no reminders) and remembers which goals it
/// paused in reward-ledger marker keys (0 sparks, 0 energy), so turning it off resumes only those
/// and leaves goals the user paused by hand alone. No schema change; the markers are exported,
/// imported and erased with the rest of the save.
extension GoobyEngine {
    private static let pauseModeKey = "menu.pause:on"
    private static let pauseModeHabitPrefix = "menu.pause:habit:"

    var pauseModeOn: Bool {
        all(RewardLedger.self).contains { $0.key == GoobyEngine.pauseModeKey }
    }

    func setPauseMode(_ on: Bool) {
        if on {
            guard !pauseModeOn else { return }
            for habit in habits() where !habit.isArchived && !habit.isPaused {
                habit.isPaused = true
                grant(key: GoobyEngine.pauseModeHabitPrefix + habit.id.uuidString, sparks: 0, energy: 0)
            }
            grant(key: GoobyEngine.pauseModeKey, sparks: 0, energy: 0)
            log("pause mode on")
        } else {
            let markers = all(RewardLedger.self).filter { $0.key.hasPrefix(GoobyEngine.pauseModeHabitPrefix) }.map(\.key)
            let byID = Dictionary(habits().map { ($0.id.uuidString, $0) }, uniquingKeysWith: { first, _ in first })
            for key in markers {
                byID[String(key.dropFirst(GoobyEngine.pauseModeHabitPrefix.count))]?.isPaused = false
                revoke(key: key)
            }
            revoke(key: GoobyEngine.pauseModeKey)
            log("pause mode off")
        }
        save()
        rescheduleNotifications()
    }
}
