import SwiftUI

/// Settings > Notifications: the switch for all local notifications (permission request, plans
/// in GoobyEngine+Notifications.swift). Only local notifications, no push server.
struct ReminderSettingsScreen: View {
    var engine: GoobyEngine
    @State private var message: String?

    var body: some View {
        MenuScroll {
            MenuListGroup {
                MenuToggleRow(
                    icon: "🔔",
                    title: engine.t("settings.notifications"),
                    subtitle: engine.tx("menu.settings.notifications.sub", de: "Für Ziele und Feste", en: "For goals and events"),
                    isOn: Binding(get: { engine.profile.notificationsEnabled }, set: { toggleNotes($0) })
                )
            }
            .padding(.top, 8)
            MenuFootnote(text: engine.tx(
                "extras.notify.footnote",
                de: "Gooby erinnert dich an Ziele mit Uhrzeit, an Abenteuer, die zu Ende sind, und an neue Feste. Alles wird auf diesem iPhone geplant.",
                en: "Gooby reminds you of goals with a time, of adventures that are over and of new events. Everything is planned on this iPhone."
            ))
        }
        .menuChrome(engine, title: engine.t("settings.notifications"))
        .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: { Text(message ?? "") }
    }

    private func toggleNotes(_ on: Bool) {
        engine.profile.notificationsEnabled = on
        engine.save()
        guard on else { return }
        Task {
            let ok = await GoobyAlerts.request()
            if ok { engine.rescheduleNotifications() }
            else {
                engine.profile.notificationsEnabled = false
                engine.save()
                message = engine.t("settings.notificationsDenied")
            }
        }
    }
}
