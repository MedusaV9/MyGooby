import Foundation
import SwiftData

@MainActor
@Observable
final class GoobyEngine {
    let context: ModelContext
    let catalog = ContentCatalog.shared
    let sound = SoundscapePlayer()
    let haptics = GoobyHaptics()

    var profile: PlayerProfile
    var wallet: Wallet
    var pet: GoobyPet
    var room: RoomLayout
    var languageCode: String
    var reduceMotion: Bool
    var animation: GoobyAnimation = .idle
    var banner: String?
    var celebration: Int = 0

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
            created.energyGoal = 12
            context.insert(created)
            resolvedWallet = Wallet()
            resolvedPet = GoobyPet()
            resolvedRoom = RoomLayout()
            context.insert(resolvedWallet)
            context.insert(resolvedPet)
            context.insert(resolvedRoom)
            resolvedProfile = created
        }
        profile = resolvedProfile
        wallet = resolvedWallet
        pet = resolvedPet
        room = resolvedRoom
        languageCode = resolvedProfile.languageCode
        reduceMotion = resolvedProfile.reduceMotion
    }

    func boot() {
        grantStarterItems()
        ensureWorld()
        refreshDay()
        GoobyFiles.excludeRecursively(GoobyFiles.supportDirectory())
        log("boot")
        rescheduleNotifications()
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
        languageCode = code == "en" ? "en" : "de"
        profile.languageCode = languageCode
        save()
        rescheduleNotifications()
    }

    func setReduceMotion(_ on: Bool) {
        reduceMotion = on
        profile.reduceMotion = on
        save()
    }

    func save() {
        do {
            try context.save()
            GoobyFiles.excludeRecursively(GoobyFiles.supportDirectory())
            FeatureHost.shared.shellEvent?(self, .saved)
        } catch {
            log("save \(error.localizedDescription)")
            banner = t("error.save")
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
    }

    func completeHabit(_ habit: Habit, on date: Date) {
        refreshDay()
        let key = DayKey.make(date)
        let log = habitLog(habit.id, key) ?? insertLog(habit.id, key)
        let cap = max(1, habit.timesPerDay)
        guard log.count < cap else { return }
        log.skipped = false
        log.count += 1
        log.createdAt = now()
        if key == dayKey() {
            _ = grant(key: "habit:\(habit.id.uuidString):\(key):\(log.count)", sparks: habit.sparkReward, energy: habit.energyReward)
            if habit.isDailyGoal {
                _ = grant(key: "daily-goal:\(key)", sparks: 10, energy: 8)
            }
            animation = .celebrate
            celebration += 1
            haptics.celebrate()
        }
        noteCareDays()
        advanceEgg(for: habit)
        recomputeQuests()
        save()
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
    }

    func skipHabit(_ habit: Habit, on date: Date) {
        let key = DayKey.make(date)
        let log = habitLog(habit.id, key) ?? insertLog(habit.id, key)
        guard log.count == 0 else { return }
        log.skipped = true
        save()
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

enum ThemeHex {
    static let palette = ["FFD6E7", "D3C2FF", "C6EFDC", "FFE7AD", "FFD6B3", "C8E9FF"]
}
