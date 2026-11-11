import SwiftUI

enum Look {
    static var canvas: Color { Paint.pick(0xD3E1EE) { $0.settings } }
    static var ink: Color { Paint.pick(0x313131) { $0.ink } }
    static var row: Color { Paint.pick(0x687178) { $0.inkSoft } }
    static var code: Color { Paint.pick(0x9AA4AB) { $0.inkFaint } }
    static var sub: Color { Paint.pick(0x9EA5AB) { $0.inkFaint } }
    static var section: Color { Paint.pick(0x5A656E) { $0.inkSoft } }
    static var chevron: Color { Paint.pick(0xA0AAB2) { $0.inkFaint } }
    static var back: Color { Paint.pick(0x6A7780) { $0.inkSoft } }
    static var widget: Color { Paint.pick(0x7478C1) { HexMix.mix($0.accent, $0.home, 0.35) } }
    static var plus: Color { Paint.pick(0x566FD6) { $0.accent } }
    static var line: Color { Paint.pick(0xF0F2F4) { $0.line } }
    static var track: Color { Paint.pick(0xE8E8EA) { $0.well } }
    static var trailing: Color { Paint.pick(0x8E949A) { $0.inkFaint } }
    static var shadow: Color { Paint.shadow(0x7E96A8, 0.18) }
    static var card: Color { Paint.pick(0xFFFFFF) { $0.card } }

    static let margin: CGFloat = 16
    static let nameRadius: CGFloat = 26
    static let tileRadius: CGFloat = 20
    static let bannerRadius: CGFloat = 22
    static let groupRadius: CGFloat = 22
    static let tileHeight: CGFloat = 68
    static let nameHeight: CGFloat = 90
    static let widgetHeight: CGFloat = 86
    static let plusHeight: CGFloat = 92
    static let rowHeight: CGFloat = 60
}

struct LookScreen<Content: View>: View {
    var back: String
    @ViewBuilder var content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LookBackButton(title: back) { dismiss() }
                content()
            }
            .padding(.horizontal, Look.margin)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Look.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
    }
}

struct LookBackButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Look.back)
                .frame(width: 44, height: 32, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .accessibilityLabel(title)
    }
}

struct LookCard<Content: View>: View {
    var radius: CGFloat = Look.groupRadius
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Look.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Look.shadow, radius: 10, y: 4)
    }
}

struct LookSectionTitle: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .tracking(1.15)
            .foregroundStyle(Look.section)
            .padding(.top, 18)
            .padding(.bottom, 8)
            .padding(.leading, 16)
    }
}

struct LookIcon: View {
    enum Kind {
        case activities, areas, goals, insights, news, history
        case invite, circles, bell, profile, appIcon, ruler, floppy, sprout
        case sparkles, rainbow, gift, bunnyHeart
    }

    var kind: Kind

    var body: some View {
        LookArt(kind: kind)
            .frame(width: 34, height: 34)
            .accessibilityHidden(true)
    }
}

struct LookSwitch: View {
    @Binding var isOn: Bool
    var label: String
    var audible: Bool = true

    var body: some View {
        Button {
            isOn.toggle()
            if audible { GoobyFeedback.play(isOn ? .toggleOn : .toggleOff) }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? Color(hex: 0x34C759) : Look.track)
                Circle()
                    .fill(Color.white)
                    .frame(width: 27, height: 27)
                    .shadow(color: Color.black.opacity(0.16), radius: 1.5, y: 1)
                    .padding(2)
            }
            .frame(width: 51, height: 31)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "1" : "0")
        .accessibilityAddTraits(.isButton)
    }
}

struct LookNavRow: View {
    var title: String
    var subtitle: String? = nil
    var icon: LookIcon.Kind? = nil
    var badge: String? = nil
    var trailing: String? = nil
    var showsChevron: Bool = true
    var indented: Bool = false
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                LookIcon(kind: icon)
            } else if indented {
                Color.clear.frame(width: 34, height: 34)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Look.row)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Look.plus, in: Capsule())
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.sub)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.trailing)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Look.chevron)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: rowHeight)
        .contentShape(Rectangle())
    }

    private var rowHeight: CGFloat {
        if compact { return subtitle == nil ? 48 : 54 }
        return subtitle == nil ? Look.rowHeight : 84
    }
}

struct LookDivider: View {
    var body: some View {
        Rectangle()
            .fill(Look.line)
            .frame(height: 1)
            .padding(.leading, 60)
    }
}

enum LookMark {
    static let pause = "look.pause"
    static let plus = "look.plus"
    static let pauseIDs = "look.pause.ids"
    static let pauseStart = "look.pause.start"
    static let circles = "look.circles"
    static let letters = "look.letters.read"
    static let icon = "look.icon"
    static let holdHabit = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!

    @MainActor
    static func isOn(_ engine: GoobyEngine, _ key: String) -> Bool {
        engine.all(RewardLedger.self).contains { $0.key == key }
    }

    @MainActor
    static func set(_ engine: GoobyEngine, _ key: String, _ on: Bool) {
        let rows = engine.all(RewardLedger.self).filter { $0.key == key }
        if on {
            if rows.isEmpty {
                let row = RewardLedger()
                row.key = key
                row.sparks = 0
                row.energy = 0
                row.createdAt = engine.now()
                engine.context.insert(row)
            }
        } else {
            rows.forEach { engine.context.delete($0) }
        }
        engine.save()
    }

    @MainActor
    static func setPause(_ engine: GoobyEngine, _ on: Bool) {
        if on {
            let ids = engine.habits().filter { !$0.isArchived && !$0.isPaused }.map(\.id.uuidString)
            UserDefaults.standard.set(ids, forKey: pauseIDs)
            UserDefaults.standard.set(engine.dayKey(), forKey: pauseStart)
            for habit in engine.habits() where ids.contains(habit.id.uuidString) {
                habit.isPaused = true
            }
            set(engine, pause, true)
            holdDays(engine)
        } else {
            let ids = UserDefaults.standard.stringArray(forKey: pauseIDs) ?? []
            if ids.isEmpty {
                for habit in engine.habits() where habit.isPaused { habit.isPaused = false }
            } else {
                for habit in engine.habits() where ids.contains(habit.id.uuidString) {
                    habit.isPaused = false
                }
            }
            UserDefaults.standard.removeObject(forKey: pauseIDs)
            UserDefaults.standard.removeObject(forKey: pauseStart)
            set(engine, pause, false)
        }
        engine.rescheduleNotifications()
    }

    @MainActor
    static func holdDays(_ engine: GoobyEngine) {
        guard isOn(engine, pause) else { return }
        let startKey = UserDefaults.standard.string(forKey: pauseStart) ?? engine.dayKey()
        guard var day = DayKey.parse(startKey) else { return }
        let end = Calendar.current.startOfDay(for: engine.now())
        while day <= end {
            let key = DayKey.make(day)
            let already = engine.all(HabitLog.self).contains { $0.dayKey == key && !$0.skipped && $0.count > 0 && $0.habitID != holdHabit }
            if !already, engine.habitLog(holdHabit, key) == nil {
                let log = HabitLog()
                log.habitID = holdHabit
                log.dayKey = key
                log.count = 1
                log.skipped = false
                log.createdAt = engine.now()
                engine.context.insert(log)
            }
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        engine.save()
    }
}

struct LookPillButton: View {
    var title: String
    var fill: Color = Look.card
    var ink: Color = Look.ink
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .padding(.horizontal, 18)
                .frame(minWidth: 72, minHeight: 40)
                .background(fill, in: Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
