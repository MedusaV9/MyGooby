import SwiftUI
import UserNotifications

/// Developer menu section "Reminders" (FeatureHost.devSections), registered once on `.booted`:
/// the iOS permission state, what is planned next, test notifications in 5 seconds and planning
/// again on demand.
@MainActor
enum ReminderDevTools {
    private static var registered = false

    static func register() {
        guard !registered else { return }
        registered = true
        FeatureHost.shared.devSections.append(("settings.notifications", { engine in AnyView(ReminderDevSection(engine: engine)) }))
    }
}

struct ReminderDevSection: View {
    var engine: GoobyEngine
    @State private var lines: [String] = []
    @State private var note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.greyText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let note {
                Text(note)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.Tab.menu.danger)
            }
            Button(engine.tx("extras.notify.dev.daily", de: "Tageserinnerung in 5 Sekunden", en: "Daily reminder in 5 seconds")) {
                send(.daily)
            }
            .menuKeyButton(expand: true)
            Button(engine.tx("extras.notify.dev.goal", de: "Zielerinnerung in 5 Sekunden", en: "Goal reminder in 5 seconds")) {
                send(.goal)
            }
            .menuKeyButton(expand: true)
            Button(engine.tx("extras.notify.dev.replan", de: "Jetzt neu planen", en: "Plan again now")) {
                engine.rescheduleNotifications()
                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    await reload()
                }
            }
            .menuKeyButton(expand: true)
        }
        .task { await reload() }
    }

    private func send(_ kind: GoobyNotice.Kind) {
        Task {
            let sent = await GoobyAlerts.sendTest(kind, engine: engine)
            note = sent ? nil : engine.tx("extras.notify.dev.failed", de: "Nicht gesendet: keine Erlaubnis oder kein Ziel.", en: "Not sent: no permission or no goal.")
            await reload()
        }
    }

    private func reload() async {
        let center = UNUserNotificationCenter.current()
        let status = await GoobyAlerts.status()
        let pending = await center.pendingNotificationRequests().filter { $0.identifier.hasPrefix("gooby.") }
        let dated = pending.map { request -> (Date, String) in
            let date = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                ?? (request.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
                ?? .distantFuture
            return (date, request.content.body)
        }
        .sorted { $0.0 < $1.0 }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        lines = [engine.txf("extras.notify.dev.status", de: "iOS: %@ · %@ geplant", en: "iOS: %@ · %@ planned", statusName(status), String(pending.count))]
            + dated.prefix(4).map { "\(formatter.string(from: $0.0)) · \($0.1)" }
    }

    private func statusName(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }
}
