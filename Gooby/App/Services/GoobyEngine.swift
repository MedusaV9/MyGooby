import Foundation
import SwiftData

@MainActor
@Observable
final class GoobyEngine {
    let context: ModelContext
    let catalog = ContentCatalog.shared
    let sound = SoundscapePlayer()
    var haptics: GoobyHaptics { GoobyFeedback.shared.haptics }

    var profile: PlayerProfile
    var wallet: Wallet
    var pet: GoobyPet
    var room: RoomLayout
    var languageCode: String
    var reduceMotion: Bool
    var animation: GoobyAnimation = .idle
    var banner: String?
    var celebration: Int = 0
    /// Latest flat spark bonus earned after the energy bar was already full.
    var homeSparkFlight: HomeSparkFlight?

    init(context: ModelContext) {
        self.context = context
        let profiles = (try? context.fetch(FetchDescriptor<PlayerProfile>())) ?? []
        let resolvedProfile: PlayerProfile
        let resolvedWallet: Wallet
        let resolvedPet: GoobyPet
        let resolvedRoom: RoomLayout
        if let existing = profiles.first {
            resolvedProfile = existing
            resolvedWallet = GoobyEngine.one(Wallet.self, in: context) { Wallet() }
            resolvedPet = GoobyEngine.one(GoobyPet.self, in: context) { GoobyPet() }
            resolvedRoom = GoobyEngine.one(RoomLayout.self, in: context) { RoomLayout() }
        } else {
            let created = PlayerProfile()
            created.appSeed = Int64.random(in: 1...9_000_000_000_000)
            created.languageCode = "de"
            created.goobyName = "Gooby"
            created.energyGoal = 15
            context.insert(created)
            resolvedWallet = Wallet()
            resolvedPet = GoobyPet()
            resolvedRoom = RoomLayout()
            context.insert(resolvedWallet)
            context.insert(resolvedPet)
            context.insert(resolvedRoom)
            resolvedProfile = created
        }
        let language = GoobyLocale.normalized(resolvedProfile.languageCode)
        profile = resolvedProfile
        wallet = resolvedWallet
        pet = resolvedPet
        room = resolvedRoom
        languageCode = language
        reduceMotion = resolvedProfile.reduceMotion
        liftEnergyGoal()
        GoobyLocale.apply(language)
    }

    func boot() {
        grantStarterItems()
        ensureWorld()
        refreshDay()
        GoobyFiles.excludeRecursively(GoobyFiles.supportDirectory())
        log("boot")
        rescheduleNotifications()
        GoobyFeedback.shared.warmUp()
    }

    func t(_ key: String) -> String { StringTable.text(key, languageCode) }

    func tf(_ key: String, _ args: CVarArg...) -> String {
        let template = t(key)
        return String(format: template, locale: Locale(identifier: languageCode), arguments: args)
    }

    func now() -> Date { Date().addingTimeInterval(profile.timeOffset) }

    func dayKey(_ date: Date? = nil) -> String { DayKey.make(date ?? now()) }

    func formatDate(_ date: Date, time: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode)
        formatter.dateStyle = .full
        formatter.timeStyle = time ? .short : .none
        return formatter.string(from: date)
    }

    func setLanguage(_ code: String) {
        languageCode = GoobyLocale.normalized(code)
        profile.languageCode = languageCode
        GoobyLocale.apply(languageCode)
        save()
        rescheduleNotifications()
    }

    func setReduceMotion(_ on: Bool) {
        reduceMotion = on
        profile.reduceMotion = on
        save()
    }

    func save() {
        liftEnergyGoal()
        do {
            try context.save()
            GoobyFiles.excludeRecursively(GoobyFiles.supportDirectory())
            FeatureHost.shared.shellEvent?(self, .saved)
        } catch {
            log("save \(error.localizedDescription)")
            banner = t("error.save")
            cue(.error)
        }
    }

    func log(_ message: String) {
        let row = AppLogEntry()
        row.at = Date()
        row.message = message
        context.insert(row)
        let rows = all(AppLogEntry.self).sorted { $0.at > $1.at }
        for extra in rows.dropFirst(180) { context.delete(extra) }
    }

    func all<T: PersistentModel>(_ type: T.Type) -> [T] {
        (try? context.fetch(FetchDescriptor<T>())) ?? []
    }

    func refreshDay() {
        let key = dayKey()
        if wallet.energyDayKey != key {
            wallet.energy = 0
            wallet.energyDayKey = key
        }
        clearOldMoves()
        syncRuns()
        reconcileFocus()
        ensureDailyQuests(key)
        ensureMilestones()
        recomputeQuests()
        unlockPlacesIfEarned()
        save()
    }

    func setOffset(to target: Date) {
        profile.timeOffset = target.timeIntervalSince(Date())
        save()
        refreshDay()
        log("time offset \(profile.timeOffset)")
    }

    func clearOffset() {
        profile.timeOffset = 0
        save()
        refreshDay()
    }

    func shiftDays(_ days: Int) {
        let target = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        setOffset(to: target)
    }

    func shiftMonths(_ months: Int) {
        let target = Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
        setOffset(to: target)
    }

    /// Older saves stored the earlier target of 12. Fifteen is the daily bar.
    private func liftEnergyGoal() {
        if profile.energyGoal == 12 { profile.energyGoal = 15 }
    }

    private static func one<T: PersistentModel>(_ type: T.Type, in context: ModelContext, make: () -> T) -> T {
        if let found = (try? context.fetch(FetchDescriptor<T>()))?.first { return found }
        let created = make()
        context.insert(created)
        return created
    }
}

extension GoobyEngine {
    @discardableResult
    func grant(key: String, sparks: Int, energy: Int) -> Bool {
        guard !key.isEmpty else { return false }
        if all(RewardLedger.self).contains(where: { $0.key == key }) { return false }
        let row = RewardLedger()
        row.key = key
        row.sparks = max(0, sparks)
        row.energy = max(0, energy)
        row.createdAt = now()
        context.insert(row)
        if sparks > 0 {
            wallet.sparks += sparks
            wallet.lifetimeSparksEarned += sparks
        }
        if energy > 0 {
            let cap = max(1, profile.energyGoal) + 15
            wallet.energy = min(cap, wallet.energy + energy)
        }
        wallet.sparks = max(0, wallet.sparks)
        wallet.energy = max(0, wallet.energy)
        return true
    }

    func revoke(key: String) {
        guard let row = all(RewardLedger.self).first(where: { $0.key == key }) else { return }
        wallet.sparks = max(0, wallet.sparks - max(0, row.sparks))
        wallet.energy = max(0, wallet.energy - max(0, row.energy))
        wallet.lifetimeSparksEarned = max(0, wallet.lifetimeSparksEarned - max(0, row.sparks))
        context.delete(row)
    }

    func setSparks(_ value: Int) {
        wallet.sparks = max(0, value)
        save()
        log("sparks set \(wallet.sparks)")
    }

    func fillEnergy() {
        wallet.energy = max(1, profile.energyGoal)
        wallet.energyDayKey = dayKey()
        save()
    }

    func owns(_ id: String) -> Bool { all(OwnedItem.self).contains { $0.catalogID == id } }

    func ownedRow(_ id: String) -> OwnedItem? { all(OwnedItem.self).first { $0.catalogID == id } }

    func grantItem(_ id: String) {
        guard !id.isEmpty, catalog.itemsByID[id] != nil, !owns(id) else { return }
        let row = OwnedItem()
        row.catalogID = id
        row.kind = catalog.itemsByID[id]?.kind ?? "item"
        row.acquiredAt = now()
        context.insert(row)
    }

    func grantStarterItems() {
        for item in catalog.items where item.starter && !owns(item.id) {
            let row = OwnedItem()
            row.catalogID = item.id
            row.kind = item.kind
            row.acquiredAt = now()
            row.equippedSlot = item.slot
            context.insert(row)
            if item.kind == "color" { pet.furStyle = item.id }
        }
        if pet.furStyle.isEmpty { pet.furStyle = "fur-cream" }
    }
}

extension GoobyEngine {
    func habits() -> [Habit] {
        all(Habit.self).sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            return lhs.sortIndex < rhs.sortIndex
        }
    }

    func habitLog(_ habitID: UUID, _ key: String) -> HabitLog? {
        all(HabitLog.self).first { $0.habitID == habitID && $0.dayKey == key }
    }

    func isDue(_ habit: Habit, on date: Date) -> Bool { HabitCalendar.isDue(habit, on: date) }

    func dueHabits(on date: Date) -> [Habit] {
        habits().filter { isDue($0, on: date) && !$0.isArchived }
    }

    func todayProgress() -> (done: Int, total: Int) {
        let due = dueHabits(on: now())
        let key = dayKey()
        let done = due.filter { (habitLog($0.id, key)?.count ?? 0) >= max(1, $0.timesPerDay) }.count
        return (done, due.count)
    }

    func streak() -> Int {
        let keys = Set(all(HabitLog.self).filter { !$0.skipped && $0.count > 0 }.map(\.dayKey))
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: now())
        if !keys.contains(DayKey.make(day)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while keys.contains(DayKey.make(day)), count < 5000 {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    func makeHabit(title: String, details: String, icon: String, category: String, dailyGoal: Bool) -> Habit {
        let habit = Habit()
        habit.title = title
        habit.details = details
        habit.icon = icon
        habit.category = category
        habit.startDate = Calendar.current.startOfDay(for: now())
        habit.energyReward = 5
        habit.sparkReward = 2
        habit.isDailyGoal = dailyGoal
        habit.sortIndex = habits().count
        habit.colorHex = ThemeHex.palette[habit.sortIndex % ThemeHex.palette.count]
        if dailyGoal {
            for other in habits() { other.isDailyGoal = false }
        }
        context.insert(habit)
        save()
        rescheduleNotifications()
        return habit
    }

    func updateHabit(_ habit: Habit, dailyGoal: Bool) {
        if dailyGoal {
            for other in habits() where other.id != habit.id { other.isDailyGoal = false }
            habit.isDailyGoal = true
        }
        habit.energyReward = min(20, max(0, habit.energyReward))
        habit.sparkReward = min(20, max(0, habit.sparkReward))
        habit.timesPerDay = min(8, max(1, habit.timesPerDay))
        habit.intervalDays = max(1, habit.intervalDays)
        save()
        rescheduleNotifications()
    }

    func deleteHabit(_ habit: Habit) {
        for log in all(HabitLog.self) where log.habitID == habit.id { context.delete(log) }
        for egg in all(EggBinding.self) where egg.habitID == habit.id && !egg.hatched { context.delete(egg) }
        context.delete(habit)
        save()
        rescheduleNotifications()
        cue(.select)
    }

    /// Sparks paid for one more goal once today's energy bar is already full.
    static let fullEnergySparkReward = 3

    static func energyBarIsFull(energy: Int, goal: Int) -> Bool {
        energy >= max(1, goal)
    }

    func completeHabit(_ habit: Habit, on date: Date) {
        refreshDay()
        let stageBefore = Growth.stage(of: pet)
        let key = DayKey.make(date)
        let log = habitLog(habit.id, key) ?? insertLog(habit.id, key)
        let cap = max(1, habit.timesPerDay)
        guard log.count < cap else { return }
        log.skipped = false
        log.count += 1
        log.createdAt = now()
        if key == dayKey() {
            let energyBefore = wallet.energy
            let sparksBefore = wallet.sparks
            let barFull = Self.energyBarIsFull(energy: energyBefore, goal: profile.energyGoal)
            let sparks = barFull ? Self.fullEnergySparkReward : habit.sparkReward
            let paidHabit = grant(key: "habit:\(habit.id.uuidString):\(key):\(log.count)", sparks: sparks, energy: habit.energyReward)
            if habit.isDailyGoal {
                _ = grant(key: "daily-goal:\(key)", sparks: 10, energy: 8)
            }
            if barFull && paidHabit {
                homeSparkFlight = HomeSparkFlight(
                    token: (homeSparkFlight?.token ?? 0) + 1,
                    habitID: habit.id,
                    shownGain: sparks,
                    startBalance: sparksBefore,
                    balance: wallet.sparks
                )
            }
            animation = .celebrate
            celebration += 1
        }
        noteCareDays()
        advanceEgg(for: habit)
        recomputeQuests()
        save()
        if key == dayKey() {
            cueProgress(stageBefore: stageBefore, otherwise: .goalDone)
        } else {
            cue(.select)
        }
    }

    func undoHabit(_ habit: Habit, on date: Date) {
        let key = DayKey.make(date)
        guard let log = habitLog(habit.id, key), log.count > 0 else { return }
        let index = log.count
        log.count -= 1
        if key == dayKey() {
            revoke(key: "habit:\(habit.id.uuidString):\(key):\(index)")
            if habit.isDailyGoal && log.count == 0 { revoke(key: "daily-goal:\(key)") }
        }
        if let egg = activeEgg(for: habit.id), !egg.hatched, egg.progress > 0 {
            egg.progress -= 1
        }
        noteCareDays()
        recomputeQuests()
        save()
        cue(.goalUndo)
    }

    func skipHabit(_ habit: Habit, on date: Date) {
        let key = DayKey.make(date)
        let log = habitLog(habit.id, key) ?? insertLog(habit.id, key)
        guard log.count == 0 else { return }
        log.skipped = true
        save()
        cue(.select)
    }

    func moveHabit(_ habit: Habit, from: Date, to: Date) {
        habit.movedFromKey = DayKey.make(from)
        habit.movedToKey = DayKey.make(to)
        save()
    }

    private func insertLog(_ habitID: UUID, _ key: String) -> HabitLog {
        let log = HabitLog()
        log.habitID = habitID
        log.dayKey = key
        context.insert(log)
        return log
    }

    private func noteCareDays() {
        let days = Set(all(HabitLog.self).filter { !$0.skipped && $0.count > 0 }.map(\.dayKey))
        pet.careDays = days.count
    }

    private func clearOldMoves() {
        let today = dayKey()
        for habit in habits() where !habit.movedToKey.isEmpty && habit.movedToKey < today {
            habit.movedFromKey = ""
            habit.movedToKey = ""
        }
    }
}

extension GoobyEngine {
    /// Starter words. Onboarding passes one of these to `setStarterTrait`.
    static let starterTraitIDs = ["curiosity", "resilience", "compassion", "logic", "confidence", "security"]

    /// A small step above one story choice (those add 0.04).
    private static let starterTraitStep = 0.08

    func setPetPronouns(_ pronouns: String) {
        pet.pronouns = pronouns.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func setBirthday(_ birthday: String) {
        profile.birthday = birthday.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func setStreakGoalDays(_ days: Int) {
        profile.streakGoalDays = max(0, days)
        save()
    }

    func setLastAffirmationDay(_ dayKey: String) {
        profile.lastAffirmationDay = dayKey.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func markAffirmationShownToday() {
        profile.lastAffirmationDay = dayKey()
        save()
    }

    func affirmationShownToday() -> Bool {
        let key = dayKey()
        return !key.isEmpty && profile.lastAffirmationDay == key
    }

    func setFullEnergyDays(_ days: Int) {
        pet.fullEnergyDays = max(0, days)
        save()
    }

    /// Counts one day that filled the energy bar. The ceremony calls this once per day.
    func addFullEnergyDay() {
        pet.fullEnergyDays = max(0, pet.fullEnergyDays) + 1
        save()
    }

    /// Stores the starter id and moves the existing doubles.
    /// Curiosity→curiosity, Resilience→courage, Compassion→empathy, Logic→calm,
    /// Confidence→confidence. Security is not an eighth trait: the same step
    /// lands on courage and calm together. English or German labels are
    /// accepted; the stored id stays one of `starterTraitIDs`. The same id
    /// does not stack. A new id takes the previous step back first.
    /// Unknown text returns false.
    @discardableResult
    func setStarterTrait(_ trait: String) -> Bool {
        let canonical = GoobyEngine.canonicalStarterTrait(trait)
        guard !canonical.isEmpty else { return false }
        guard pet.starterTrait != canonical else { return true }
        if !pet.starterTrait.isEmpty {
            Personality.apply(pet, deltas: GoobyEngine.starterTraitDeltas(pet.starterTrait, undo: true))
        }
        pet.starterTrait = canonical
        Personality.apply(pet, deltas: GoobyEngine.starterTraitDeltas(canonical, undo: false))
        save()
        return true
    }

    private static func canonicalStarterTrait(_ raw: String) -> String {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "de"))
            .lowercased()
        switch key {
        case "curiosity", "neugier", "neugierde": return "curiosity"
        case "resilience", "resilienz", "courage", "mut", "widerstandskraft": return "resilience"
        case "compassion", "mitgefuhl", "empathy", "empathie": return "compassion"
        case "logic", "logik", "calm", "gelassenheit": return "logic"
        case "confidence", "selbstvertrauen": return "confidence"
        case "security", "sicherheit": return "security"
        default: return ""
        }
    }

    private static func starterTraitDeltas(_ trait: String, undo: Bool) -> [String: Double] {
        let step = starterTraitStep * (undo ? -1 : 1)
        switch trait {
        case "curiosity": return ["curiosity": step]
        case "resilience": return ["courage": step]
        case "compassion": return ["empathy": step]
        case "logic": return ["calm": step]
        case "confidence": return ["confidence": step]
        case "security": return ["courage": step, "calm": step]
        default: return [:]
        }
    }
}

enum ThemeHex {
    static let palette = ["FFD6E7", "D3C2FF", "C6EFDC", "FFE7AD", "FFD6B3", "C8E9FF"]
}
