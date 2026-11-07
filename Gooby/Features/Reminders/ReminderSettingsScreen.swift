import SwiftUI
import UIKit
import UserNotifications

/// Settings > Reminders (masterprompt 26): the switch for all local notifications with the iOS
/// permission flow, what Gooby sends (daily reminder, goal reminders, adventure, events, focus
/// timer), quiet hours, the next planned notification and the goals with their reminder time.
/// Plans: GoobyEngine+Notifications.swift; delivery: GoobyAlerts.swift. Local only, no push server.
struct ReminderSettingsScreen: View {
    var engine: GoobyEngine
    @Environment(\.scenePhase) private var phase
    @State private var status: UNAuthorizationStatus?
    @State private var deniedAlert = false

    var body: some View {
        let on = engine.profile.notificationsEnabled
        MenuScroll {
            if on, let status, !GoobyAlerts.isAllowed(status) {
                permissionCard(denied: status == .denied)
                    .padding(.top, 8)
            }
            MenuListGroup {
                MenuToggleRow(
                    icon: "🔔",
                    title: engine.t("settings.notifications"),
                    subtitle: engine.tx("extras.notify.master.sub", de: "Schaltet alle Mitteilungen von Gooby an oder aus", en: "Turns all of Gooby's notifications on or off"),
                    isOn: Binding(get: { on }, set: { toggleAll($0) })
                )
            }
            .padding(.top, 8)
            if on {
                if engine.pauseModeOn {
                    MenuFootnote(text: engine.tx("extras.notify.paused", de: "Der Pausenmodus ist an: Ziel- und Tageserinnerungen und Fest-Nachrichten ruhen.", en: "Pause mode is on: goal and daily reminders and event news rest."))
                }
                if let status, GoobyAlerts.isAllowed(status) { nextUp }
                kinds
                quiet
                goals
            }
            MenuFootnote(text: engine.tx(
                "extras.notify.about",
                de: "Gooby plant alle Mitteilungen auf diesem iPhone, ohne Server. Bei jedem Öffnen der App plant Gooby die nächsten 7 Tage neu.",
                en: "Gooby plans every notification on this iPhone, without a server. Each time you open the app, Gooby plans the next 7 days again."
            ))
            .padding(.top, 4)
        }
        .menuChrome(engine, title: engine.t("settings.notifications"))
        .task { await refreshStatus() }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .active { Task { await refreshStatus() } }
        }
        .alert(engine.t("settings.notificationsDenied"), isPresented: $deniedAlert) {
            Button(openSettingsTitle) { openSettings() }
            Button(engine.t("common.cancel"), role: .cancel) {}
        } message: {
            Text(deniedHelp)
        }
    }

    // MARK: Permission

    private var openSettingsTitle: String {
        engine.tx("extras.notify.openSettings", de: "iOS-Einstellungen öffnen", en: "Open iOS Settings")
    }

    private var deniedHelp: String {
        engine.tx("extras.notify.denied.sub", de: "Erlaube Mitteilungen für Gooby in den iOS-Einstellungen, dann kommen deine Erinnerungen an.", en: "Allow notifications for Gooby in iOS Settings so your reminders arrive.")
    }

    /// Shown while the switch is on but iOS does not allow notifications (yet).
    private func permissionCard(denied: Bool) -> some View {
        GCard {
            HStack(alignment: .top, spacing: 14) {
                GoobyIcon(denied ? "🔕" : "🔔", size: 36)
                VStack(alignment: .leading, spacing: 10) {
                    Text(denied
                         ? engine.t("settings.notificationsDenied")
                         : engine.tx("extras.notify.ask", de: "Gooby darf dir noch keine Mitteilungen schicken.", en: "Gooby may not send you notifications yet."))
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                    Text(denied
                         ? deniedHelp
                         : engine.tx("extras.notify.ask.sub", de: "iOS fragt dich einmal, ob Gooby dir Mitteilungen schicken darf.", en: "iOS asks you once whether Gooby may send you notifications."))
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.greyText)
                    Button {
                        if denied { openSettings() } else { allow() }
                    } label: {
                        Text(denied ? openSettingsTitle : engine.tx("extras.notify.allow", de: "Mitteilungen erlauben", en: "Allow notifications"))
                    }
                    .menuPrimaryButton()
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func toggleAll(_ value: Bool) {
        guard value else {
            engine.disableNotifications()
            return
        }
        Task {
            let before = await GoobyAlerts.status()
            let granted = await engine.enableNotifications()
            await refreshStatus()
            // iOS shows its own prompt only the first time; afterwards explain where to allow it.
            if !granted && before == .denied { deniedAlert = true }
        }
    }

    private func allow() {
        Task {
            if await GoobyAlerts.request() { engine.rescheduleNotifications() }
            await refreshStatus()
        }
    }

    private func refreshStatus() async {
        status = await GoobyAlerts.status()
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: Next notification

    /// The next notification from the plan, drawn like a banner, and how many are planned.
    @ViewBuilder private var nextUp: some View {
        let plan = engine.notificationPlan()
        if let next = plan.notices.first {
            MenuSectionHeader(text: engine.tx("extras.notify.next", de: "Als Nächstes", en: "Coming up"))
            HStack(alignment: .top, spacing: 12) {
                GoobyMiniHead(fur: engine.pet.furStyle, stage: Growth.stage(of: engine.pet), face: .happy)
                    .padding(4)
                    .frame(width: 44, height: 44)
                    .background(Theme.cream, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(next.title)
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(when(next.fireAt))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.greyText)
                            .lineLimit(1)
                    }
                    Text(next.body)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    if next.quiet {
                        Text(engine.tx("extras.notify.next.quiet", de: "🌙 Kommt still an (Ruhezeit)", en: "🌙 Arrives quietly (quiet hours)"))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.greyText)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
            .cardShadow()
            .accessibilityElement(children: .combine)
            MenuFootnote(text: engine.txf("extras.notify.planned", de: "%@ Mitteilungen für die nächsten 7 Tage geplant.", en: "%@ notifications planned for the next 7 days.", String(plan.notices.count)))
        }
    }

    private func when(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: What Gooby sends

    @ViewBuilder private var kinds: some View {
        MenuSectionHeader(text: engine.tx("extras.notify.kinds", de: "Was Gooby dir schickt", en: "What Gooby sends you"))
        MenuListGroup {
            MenuToggleRow(
                icon: "🐰",
                title: engine.tx("extras.notify.daily", de: "Tägliche Erinnerung", en: "Daily reminder"),
                subtitle: engine.tx("extras.notify.daily.sub", de: "Ein liebes Wort von Gooby, an Tagen mit offenen Zielen", en: "A kind word from Gooby on days with open goals"),
                isOn: flag(NotifyPref.daily)
            )
            if engine.notifyOn(NotifyPref.daily) {
                MenuListDivider()
                timeRow(icon: "⏰", title: engine.tx("extras.notify.dailyAt", de: "Uhrzeit", en: "Time"), pref: NotifyPref.dailyAt)
            }
            MenuListDivider()
            MenuToggleRow(
                icon: "✅",
                title: engine.tx("extras.notify.goals", de: "Zielerinnerungen", en: "Goal reminders"),
                subtitle: engine.tx("extras.notify.goals.sub", de: "Zur Uhrzeit, die du beim Ziel einstellst", en: "At the time you set on the goal"),
                isOn: flag(NotifyPref.goals)
            )
            MenuListDivider()
            MenuToggleRow(
                icon: "🗺️",
                title: engine.tx("extras.notify.adventure", de: "Abenteuer beendet", en: "Adventure finished"),
                subtitle: engine.tx("extras.notify.adventure.sub", de: "Wenn Gooby mit einer Geschichte zurück ist", en: "When Gooby is back with a story"),
                isOn: flag(NotifyPref.adventure)
            )
            MenuListDivider()
            MenuToggleRow(
                icon: "🎉",
                title: engine.tx("extras.notify.events", de: "Neue Feste", en: "New events"),
                subtitle: engine.tx("extras.notify.events.sub", de: "Am ersten Tag eines Fests um 10 Uhr", en: "At 10 am on the first day of an event"),
                isOn: flag(NotifyPref.events)
            )
            MenuListDivider()
            MenuToggleRow(
                icon: "⏱️",
                title: engine.tx("extras.notify.focus", de: "Fokus-Timer", en: "Focus timer"),
                subtitle: engine.tx("extras.notify.focus.sub", de: "Wenn deine Fokuszeit vorbei ist", en: "When your focus time is over"),
                isOn: flag(NotifyPref.focus)
            )
        }
    }

    // MARK: Quiet hours

    @ViewBuilder private var quiet: some View {
        MenuSectionHeader(text: engine.tx("extras.notify.quiet", de: "Ruhezeiten", en: "Quiet hours"))
        MenuListGroup {
            MenuToggleRow(
                icon: "🌙",
                title: engine.tx("extras.notify.quiet", de: "Ruhezeiten", en: "Quiet hours"),
                subtitle: engine.tx("extras.notify.quiet.sub", de: "Gooby bleibt nachts leise", en: "Gooby stays quiet at night"),
                isOn: flag(NotifyPref.quiet)
            )
            if engine.notifyOn(NotifyPref.quiet) {
                MenuListDivider()
                timeRow(icon: "🌛", title: engine.tx("extras.notify.quietFrom", de: "Ab", en: "From"), pref: NotifyPref.quietFrom)
                MenuListDivider()
                timeRow(icon: "🌅", title: engine.tx("extras.notify.quietTo", de: "Bis", en: "Until"), pref: NotifyPref.quietTo)
            }
        }
        MenuFootnote(text: engine.tx(
            "extras.notify.quiet.note",
            de: "In der Ruhezeit kommen Erinnerungen ohne Ton und ohne dass der Bildschirm aufleuchtet. Nachrichten zu Abenteuern und Festen warten, bis die Ruhezeit vorbei ist.",
            en: "During quiet hours, reminders arrive without a sound and without lighting up the screen. News about adventures and events waits until quiet hours are over."
        ))
    }

    // MARK: Goals with a time

    @ViewBuilder private var goals: some View {
        let list = engine.habits().filter { !$0.isArchived }
        if engine.notifyOn(NotifyPref.goals) && !list.isEmpty {
            MenuSectionHeader(text: engine.tx("extras.notify.yourGoals", de: "Deine Ziele", en: "Your goals"))
            MenuListGroup {
                ForEach(Array(list.enumerated()), id: \.element.id) { index, habit in
                    if index > 0 { MenuListDivider() }
                    NavigationLink {
                        HabitEditor(engine: engine, habit: habit)
                    } label: {
                        MenuListRow(
                            icon: habit.icon,
                            title: habit.title,
                            subtitle: habit.isPaused ? engine.tx("extras.notify.goal.paused", de: "Pausiert, keine Erinnerung", en: "Paused, no reminder") : nil
                        ) {
                            HStack(spacing: 8) {
                                Text(reminderTime(habit))
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(habit.reminderHour >= 0 && !habit.isPaused ? Theme.text : Theme.greyText)
                                MenuChevron()
                            }
                        }
                    }
                    .buttonStyle(MenuRowButtonStyle())
                }
            }
            MenuFootnote(text: engine.tx("extras.notify.yourGoals.note", de: "Tippe auf ein Ziel, um seine Erinnerung zu ändern.", en: "Tap a goal to change its reminder."))
        }
    }

    private func reminderTime(_ habit: Habit) -> String {
        guard habit.reminderHour >= 0 else {
            return engine.tx("extras.notify.goal.none", de: "Keine", en: "None")
        }
        return clock(habit.reminderHour * 60 + habit.reminderMinute)
    }

    // MARK: Helpers

    private func flag(_ name: String) -> Binding<Bool> {
        Binding(get: { engine.notifyOn(name) }, set: { engine.setNotify(name, $0) })
    }

    private func timeRow(icon: String, title: String, pref: String) -> some View {
        MenuListRow(icon: icon, title: title) {
            DatePicker(title, selection: clockBinding(pref), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Theme.Tab.menu.banner)
                .environment(\.locale, Locale(identifier: engine.languageCode))
        }
    }

    /// A time of day as today's date at that time; only hour and minute are stored.
    private func clockBinding(_ pref: String) -> Binding<Date> {
        Binding(
            get: {
                let minutes = engine.notifyMinutes(pref)
                return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                engine.setNotifyMinutes(pref, (parts.hour ?? 0) * 60 + (parts.minute ?? 0))
            }
        )
    }

    private func clock(_ minutes: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let date = Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
