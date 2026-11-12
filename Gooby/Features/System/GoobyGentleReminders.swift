import SwiftUI
import UserNotifications

// Opt-in evening nudge plus the switch for the adventure-return notice.
// IDs use the "goobysys." prefix so GoobyAlerts.sync, which clears "gooby.*", leaves them alone.
enum GoobyNoticePrefs {
    private static let store = UserDefaults.standard

    static var returnNotice: Bool {
        get { store.object(forKey: "gooby.notice.return") as? Bool ?? true }
        set { store.set(newValue, forKey: "gooby.notice.return") }
    }

    static var gentle: Bool {
        get { store.bool(forKey: "gooby.notice.gentle") }
        set { store.set(newValue, forKey: "gooby.notice.gentle") }
    }

    static var gentleHour: Int {
        get { store.object(forKey: "gooby.notice.gentleHour") as? Int ?? 18 }
        set { store.set(min(23, max(0, newValue)), forKey: "gooby.notice.gentleHour") }
    }

    static var gentleMinute: Int {
        get { store.object(forKey: "gooby.notice.gentleMinute") as? Int ?? 0 }
        set { store.set(min(59, max(0, newValue)), forKey: "gooby.notice.gentleMinute") }
    }
}

@MainActor
enum GoobyGentleReminders {
    static let prefix = "goobysys.gentle."
    private static var lastKey = ""

    // Today's line is only planned while goals are open, so a finished day stays quiet.
    // The next days get a soft, generic line that never counts what was missed.
    static func refresh(_ engine: GoobyEngine, force: Bool = false) {
        let open = engine.dueHabits(on: engine.now()).filter { habit in
            (engine.habitLog(habit.id, engine.dayKey())?.count ?? 0) < max(1, habit.timesPerDay)
        }.count
        let enabled = engine.profile.notificationsEnabled && GoobyNoticePrefs.gentle
        let key = [
            enabled ? "on" : "off",
            engine.dayKey(),
            String(open),
            String(GoobyNoticePrefs.gentleHour),
            String(GoobyNoticePrefs.gentleMinute),
            engine.languageCode,
            engine.profile.goobyName
        ].joined(separator: "|")
        guard force || key != lastKey else { return }
        lastKey = key
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<4).map { prefix + String($0) })
        guard enabled else { return }
        let calendar = Calendar.current
        let now = Date()
        let name = engine.profile.goobyName.trimmingCharacters(in: .whitespaces).isEmpty ? "Gooby" : engine.profile.goobyName
        for offset in 0..<4 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                  let fire = calendar.date(bySettingHour: GoobyNoticePrefs.gentleHour, minute: GoobyNoticePrefs.gentleMinute, second: 0, of: day) else { continue }
            let seconds = fire.timeIntervalSince(now)
            guard seconds > 60 else { continue }
            let body: String
            if offset == 0 {
                guard open > 0 else { continue }
                body = open == 1 ? engine.t("system.gentle.todayOne") : engine.tf("system.gentle.today", open)
            } else {
                let variant = 1 + (calendar.ordinality(of: .day, in: .year, for: day) ?? offset) % 3
                body = engine.t("system.gentle.\(variant)")
            }
            let content = UNMutableNotificationContent()
            content.title = name
            content.body = body
            content.sound = .default
            content.userInfo = ["link": GoobyLink.home.rawValue]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            center.add(UNNotificationRequest(identifier: prefix + String(offset), content: content, trigger: trigger))
        }
    }
}

struct GoobyGentleNoticesCard: View {
    var engine: GoobyEngine
    @State private var returnOn = GoobyNoticePrefs.returnNotice
    @State private var gentleOn = GoobyNoticePrefs.gentle
    @State private var time = GoobyGentleNoticesCard.storedTime()
    @State private var denied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LookSectionTitle(text: engine.t("system.notify.section"))
            LookCard {
                VStack(spacing: 0) {
                    row(engine.t("system.notify.return"), engine.t("system.notify.return.sub"), isOn: Binding(get: { returnOn }, set: { value in
                        returnOn = value
                        GoobyNoticePrefs.returnNotice = value
                        enableIfNeeded(value)
                    }))
                    LookDivider()
                    row(engine.t("system.notify.gentle"), engine.t("system.notify.gentle.sub"), isOn: Binding(get: { gentleOn }, set: { value in
                        gentleOn = value
                        GoobyNoticePrefs.gentle = value
                        enableIfNeeded(value)
                    }))
                    if gentleOn {
                        LookDivider()
                        DatePicker(engine.t("system.notify.time"), selection: Binding(get: { time }, set: { value in
                            time = value
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: value)
                            GoobyNoticePrefs.gentleHour = parts.hour ?? 18
                            GoobyNoticePrefs.gentleMinute = parts.minute ?? 0
                            GoobyGentleReminders.refresh(engine)
                        }), displayedComponents: .hourAndMinute)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Look.row)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 56)
                    }
                }
            }
            if denied {
                Text(engine.t("system.notify.denied"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.sub)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
        }
    }

    private func row(_ title: String, _ subtitle: String, isOn: Binding<Bool>) -> some View {
        LookNavRow(title: title, subtitle: subtitle, icon: .bell, showsChevron: false)
            .padding(.trailing, 58)
            .overlay(alignment: .trailing) {
                LookSwitch(isOn: isOn, label: title)
                    .padding(.trailing, 14)
            }
    }

    private func enableIfNeeded(_ on: Bool) {
        Task {
            if on && !engine.profile.notificationsEnabled {
                let granted = await GoobyAlerts.request()
                denied = !granted
                guard granted else { return }
                engine.profile.notificationsEnabled = true
                engine.save()
            }
            engine.rescheduleNotifications()
            GoobyGentleReminders.refresh(engine, force: true)
        }
    }

    private static func storedTime() -> Date {
        Calendar.current.date(bySettingHour: GoobyNoticePrefs.gentleHour, minute: GoobyNoticePrefs.gentleMinute, second: 0, of: Date()) ?? Date()
    }
}
