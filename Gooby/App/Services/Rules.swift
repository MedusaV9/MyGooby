import Foundation

enum DayKey {
    static func make(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func parse(_ key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return calendar.date(from: components)
    }
}

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func int(_ upper: Int) -> Int {
        guard upper > 0 else { return 0 }
        return Int(next() % UInt64(upper))
    }
}

enum ShopRotation {
    static func seed(dayKey: String, category: String, appSeed: Int64) -> UInt64 {
        var hash = UInt64(bitPattern: appSeed) &+ 0x9E3779B97F4A7C15
        for byte in "\(dayKey)|\(category)".utf8 {
            hash = hash &* 131 &+ UInt64(byte)
        }
        return hash == 0 ? 1 : hash
    }

    static func orderedIDs(_ ids: [String], dayKey: String, category: String, appSeed: Int64) -> [String] {
        var rng = SeededRNG(state: seed(dayKey: dayKey, category: category, appSeed: appSeed))
        var copy = ids
        var index = copy.count - 1
        while index > 0 {
            let swap = rng.int(index + 1)
            copy.swapAt(index, swap)
            index -= 1
        }
        return copy
    }
}

enum HabitCalendar {
    static func isDue(_ habit: Habit, on date: Date, calendar: Calendar = .current) -> Bool {
        if habit.isArchived || habit.isPaused { return false }
        let day = calendar.startOfDay(for: date)
        let key = DayKey.make(day, calendar: calendar)
        if !habit.movedFromKey.isEmpty, habit.movedFromKey == key { return false }
        if !habit.movedToKey.isEmpty, habit.movedToKey == key { return true }

        let start = calendar.startOfDay(for: habit.startDate)
        if day < start { return false }
        if let end = habit.endDate, day > calendar.startOfDay(for: end) { return false }

        switch habit.recurrence {
        case "once":
            return calendar.isDate(day, inSameDayAs: start)
        case "daily":
            return true
        case "weekly":
            return calendar.component(.weekday, from: day) == calendar.component(.weekday, from: start)
        case "monthly":
            let wanted = calendar.component(.day, from: start)
            let actual = calendar.component(.day, from: day)
            let last = calendar.range(of: .day, in: .month, for: day)?.count ?? 28
            return actual == min(wanted, last)
        case "weekdays":
            return habit.weekdays.contains(calendar.component(.weekday, from: day))
        case "everyX":
            let step = max(1, habit.intervalDays)
            let delta = calendar.dateComponents([.day], from: start, to: day).day ?? 0
            return delta >= 0 && delta % step == 0
        case "custom":
            let delta = calendar.dateComponents([.day], from: start, to: day).day ?? 0
            let stepOK = habit.intervalDays <= 1 || (delta >= 0 && delta % max(1, habit.intervalDays) == 0)
            let daysOK = habit.weekdays.isEmpty || habit.weekdays.contains(calendar.component(.weekday, from: day))
            return stepOK && daysOK
        default:
            return false
        }
    }
}

enum Growth {
    static let order = ["baby", "little", "young", "teen", "adult"]

    static func stage(of pet: GoobyPet) -> String {
        if Growth.order.contains(pet.stageOverride) { return pet.stageOverride }
        let score = pet.adventureDays * 2 + pet.careDays
        switch score {
        case ..<8: return "baby"
        case ..<20: return "little"
        case ..<40: return "young"
        case ..<70: return "teen"
        default: return "adult"
        }
    }

    static func scale(for stage: String) -> Double {
        switch stage {
        case "baby": return 0.94
        case "little": return 0.97
        case "young": return 1.0
        case "teen": return 1.03
        default: return 1.05
        }
    }
}

enum DaylightPhase: String {
    case morning, day, evening, night

    static func of(_ date: Date, calendar: Calendar = .current) -> DaylightPhase {
        switch calendar.component(.hour, from: date) {
        case 5..<8: return .morning
        case 8..<17: return .day
        case 17..<21: return .evening
        default: return .night
        }
    }
}

enum EventWindow {
    static func monthDay(_ date: Date, calendar: Calendar = .current) -> Int {
        let parts = calendar.dateComponents([.month, .day], from: date)
        return (parts.month ?? 1) * 100 + (parts.day ?? 1)
    }

    static func contains(_ date: Date, startMonth: Int, startDay: Int, endMonth: Int, endDay: Int, calendar: Calendar = .current) -> Bool {
        let current = monthDay(date, calendar: calendar)
        let start = startMonth * 100 + startDay
        let end = endMonth * 100 + endDay
        if start <= end {
            return current >= start && current <= end
        }
        return current >= start || current <= end
    }
}

enum Personality {
    static let keys = ["curiosity", "courage", "kindness", "playfulness", "confidence", "calm", "empathy"]

    static func value(_ pet: GoobyPet, _ key: String) -> Double {
        switch key {
        case "curiosity": return pet.curiosity
        case "courage": return pet.courage
        case "kindness": return pet.kindness
        case "playfulness": return pet.playfulness
        case "confidence": return pet.confidence
        case "calm": return pet.calm
        case "empathy": return pet.empathy
        default: return 0
        }
    }

    static func set(_ pet: GoobyPet, _ key: String, _ raw: Double) {
        let value = min(1, max(0, raw))
        switch key {
        case "curiosity": pet.curiosity = value
        case "courage": pet.courage = value
        case "kindness": pet.kindness = value
        case "playfulness": pet.playfulness = value
        case "confidence": pet.confidence = value
        case "calm": pet.calm = value
        case "empathy": pet.empathy = value
        default: break
        }
    }

    static func apply(_ pet: GoobyPet, deltas: [String: Double]) {
        for (key, delta) in deltas {
            set(pet, key, value(pet, key) + delta)
        }
    }
}
