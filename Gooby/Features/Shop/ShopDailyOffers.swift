import Foundation

/// Daily offers are a pure function of the app day, the department, and the app seed.
/// The same three inputs always return the same item ids. `Hasher` is never used.
enum ShopDailyOffers {
    static func count(for department: ShopDepartment) -> Int {
        switch department {
        case .wardrobe:
            return 3
        case .furniture:
            return 2
        case .colors:
            return 2
        case .travel:
            return 1
        case .season:
            return 2
        }
    }

    static func salt(for department: ShopDepartment) -> UInt64 {
        switch department {
        case .wardrobe:
            return 0xC10A
        case .furniture:
            return 0xF047
        case .colors:
            return 0xC010
        case .travel:
            return 0x7A17
        case .season:
            return 0x5EA5
        }
    }

    static func dayParts(of date: Date, calendar: Calendar = ShopDailyOffers.gregorian) -> (year: Int, month: Int, day: Int) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = max(1, parts.year ?? 1)
        let month = min(12, max(1, parts.month ?? 1))
        let day = min(31, max(1, parts.day ?? 1))
        return (year, month, day)
    }

    static func offers(
        catalog: [ShopItem],
        department: ShopDepartment,
        year: Int,
        month: Int,
        day: Int,
        seed: UInt64
    ) -> [ShopItem] {
        let safeMonth = min(12, max(1, month))
        let safeDay = min(31, max(1, day))
        let safeYear = max(1, year)
        let season = ShopSeason.of(month: safeMonth)
        var pool = catalog.filter { $0.department == department }
        if department == .season {
            let matching = pool.filter { $0.season == season }
            if !matching.isEmpty {
                pool = matching
            }
        } else {
            pool = pool.filter { $0.season == nil }
        }
        let dayKey = UInt64(safeYear) * 10_000 + UInt64(safeMonth) * 100 + UInt64(safeDay)
        let mixed = mix([seed, dayKey, salt(for: department)])
        return pick(from: pool, count: count(for: department), seed: mixed)
    }

    static func salePrice(catalogPrice: Int, discounted: Bool) -> Int {
        let price = max(0, catalogPrice)
        guard discounted else { return price }
        return max(1, price * 4 / 5)
    }

    static func sellPrice(catalogPrice: Int) -> Int {
        max(1, catalogPrice * 2 / 5)
    }

    /// FNV-1a over 64-bit words. Stable across processes and platforms.
    static func mix(_ values: [UInt64]) -> UInt64 {
        var hash: UInt64 = 0xCBF29CE484222325
        for value in values {
            hash ^= value
            hash &*= 0x100000001B3
        }
        return hash
    }

    static func pick(from items: [ShopItem], count: Int, seed: UInt64) -> [ShopItem] {
        var pool = items.sorted { $0.id < $1.id }
        guard !pool.isEmpty else { return [] }
        if pool.count <= count {
            return pool
        }
        var generator = SplitMix(seed: seed)
        var index = pool.count - 1
        while index > 0 {
            let choice = Int(generator.next() % UInt64(index + 1))
            pool.swapAt(index, choice)
            index -= 1
        }
        return Array(pool.prefix(count)).sorted { $0.id < $1.id }
    }

    static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    struct SplitMix: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var mixed = state
            mixed = (mixed ^ (mixed >> 30)) &* 0xBF58476D1CE4E5B9
            mixed = (mixed ^ (mixed >> 27)) &* 0x94D049BB133111EB
            return mixed ^ (mixed >> 31)
        }
    }
}
