import SwiftUI
import UIKit
import UserNotifications

struct GoobyMenuView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var copied = false
    @State private var showWidget = false
    @State private var showPlus = false
    @State private var notificationsOn = true
    @State private var showInvited = false
    @State private var friendsBook = FriendsBook.load()

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 0) {
                nameCard
                widgetCard
                    .padding(.top, 22.7)
                if !notificationsOn {
                    notificationsCard
                        .padding(.top, 11.4)
                }
                grid
                    .padding(.top, 23)
                plusCard
                    .padding(.top, 23)
                LookSectionTitle(text: engine.t("look.community"))
                    .padding(.top, 10)
                    .padding(.bottom, -2.5)
                communityCard
                LookSectionTitle(text: engine.t("look.more"))
                    .padding(.top, 4)
                moreCard
                // BEGIN strand-6 activity sky row. Keep this block last in the menu list.
                // Other strands add their menu rows above this block.
                activitySkyRow
                // END strand-6 activity sky row.
            }
        }
        .sheet(isPresented: $showWidget) { LookWidgetSheet(engine: engine) }
        .sheet(isPresented: $showPlus) { LookPlusSheet(engine: engine) }
        .sheet(isPresented: $showInvited) { FriendsAddSheet(engine: engine, book: $friendsBook) }
        .onAppear {
            LookMark.holdDays(engine)
            SettingsDayPause.apply(engine)
        }
        .task { notificationsOn = await GoobyAlerts.status() == .authorized }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: copied)
    }

    private var displayName: Text {
        let pet = engine.profile.goobyName.trimmingCharacters(in: .whitespaces)
        let nick = engine.profile.nickname.trimmingCharacters(in: .whitespaces)
        let bunny = Text(pet.isEmpty ? "Gooby" : pet)
        guard !nick.isEmpty else { return bunny }
        return bunny + Text(" & ").foregroundStyle(Look.sub) + Text(nick)
    }

    private var code: String { GoobyFriendCode.make(profileID: engine.profile.id) }

    private var petName: String {
        let pet = engine.profile.goobyName.trimmingCharacters(in: .whitespaces)
        return pet.isEmpty ? "Gooby" : pet
    }

    private var nameCard: some View {
        LookCard(radius: Look.nameRadius) {
            VStack(alignment: .leading, spacing: 6) {
                NavigationLink {
                    SettingsView(engine: engine)
                } label: {
                    displayName
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Look.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                Button(action: copyCode) {
                    HStack(spacing: 6) {
                        Text(code)
                            .font(.system(size: 13.5, weight: .regular, design: .rounded))
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .semibold))
                        if copied {
                            Text(engine.t("look.copied"))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundStyle(Look.code)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(code)
            }
            .padding(.horizontal, 22)
            .padding(.top, 6)
            .frame(maxWidth: .infinity, minHeight: Look.nameHeight, alignment: .leading)
        }
    }

    private var widgetCard: some View {
        HStack(spacing: 11) {
            LookIcon(kind: .bunnyHeart, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(engine.t("look.widget.title"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(engine.tf("look.widget.body", petName))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .tracking(-0.25)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 4)
            LookPillButton(title: engine.t("look.widget.add"), ink: Look.widget) { showWidget = true }
        }
        .padding(.leading, 11)
        .padding(.trailing, 10.8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: Look.widgetHeight, alignment: .leading)
        .background(Look.widget, in: RoundedRectangle(cornerRadius: Look.bannerRadius, style: .continuous))
        .shadow(color: Look.shadow, radius: 10, y: 4)
    }

    private var notificationsCard: some View {
        HStack(spacing: 9) {
            LookIcon(kind: .bell, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(engine.t("look.notify.title"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(engine.tf("look.notify.body", petName))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .tracking(-0.25)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 4)
            LookPillButton(title: engine.t("look.notify.enable"), ink: Look.widget) {
                Task { notificationsOn = await GoobyAlerts.request() }
            }
        }
        .padding(.leading, 11)
        .padding(.trailing, 10.8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: Look.widgetHeight, alignment: .leading)
        .background(Look.widget, in: RoundedRectangle(cornerRadius: Look.bannerRadius, style: .continuous))
        .shadow(color: Look.shadow, radius: 10, y: 4)
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Look.tileGap), GridItem(.flexible(), spacing: Look.tileGap)], spacing: Look.tileRowGap) {
            tile(engine.t("look.activities"), .activities) { LookActivitiesPage(engine: engine) }
            tile(engine.t("look.areas"), .areas) { LookAreasPage(engine: engine) }
            tile(engine.t("look.goals"), .goals) { LookGoalsPage(engine: engine) }
            tile(engine.t("look.insights"), .insights) { LookInsightsPage(engine: engine) }
            tile(engine.t("look.news"), .news) { LookNewsPage(engine: engine) }
            tile(engine.t("look.history"), .history) { LookHistoryPage(engine: engine) }
        }
    }

    private func tile<Destination: View>(_ title: String, _ icon: LookIcon.Kind, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink { destination() } label: {
            HStack(spacing: 11) {
                LookIcon(kind: icon, size: 33)
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Look.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: Look.tileHeight, alignment: .leading)
            .background(Look.card, in: RoundedRectangle(cornerRadius: Look.tileRadius, style: .continuous))
            .shadow(color: Look.shadow, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var plusCard: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("Gooby")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                    Text(engine.t("look.plus.badge"))
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Look.plus)
                        .padding(.horizontal, 7)
                        .frame(height: 18.5)
                        .background(Look.card, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                Text(engine.t("look.plus.body"))
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .tracking(-0.25)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 4)
            LookPillButton(title: engine.t("look.plus.more"), ink: Look.plus) { showPlus = true }
        }
        .padding(.leading, 14)
        .padding(.trailing, 10.8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: Look.plusHeight, alignment: .leading)
        .background(Look.plus, in: RoundedRectangle(cornerRadius: Look.plusRadius, style: .continuous))
        .shadow(color: Look.shadow, radius: 10, y: 4)
    }

    private var communityCard: some View {
        LookCard {
            VStack(spacing: 0) {
                Button { showInvited = true } label: {
                    LookNavRow(title: engine.t("look.invited"), icon: .egg, compact: true)
                        .frame(minHeight: 55.5)
                }
                .buttonStyle(.plain)
                LookDivider()
                ShareLink(item: engine.tf("look.invite.share", code)) {
                    LookNavRow(title: engine.t("look.invite"), icon: .invite, compact: true)
                        .frame(minHeight: 55.5)
                }
                .buttonStyle(.plain)
                LookDivider()
                NavigationLink {
                    LookCirclesPage(engine: engine, code: code)
                } label: {
                    LookNavRow(title: engine.t("look.circles"), icon: .circles, compact: true)
                        .frame(minHeight: 55.5)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var moreCard: some View {
        LookCard {
            VStack(spacing: 0) {
                moreRow(engine.t("mood.title"), .rainbow) {
                    if let make = FeatureHost.shared.moodScreen { make(engine) } else { MoodScreen(engine: engine) }
                }
                LookDivider()
                // strand-12-insights-begin
                // One Insights row. Leave the end of this list free for the other menu row.
                moreRow(engine.t("insights.menu"), .insights) {
                    InsightsStage(engine: engine, reduceMotion: reduceMotion)
                }
                LookDivider()
                // strand-12-insights-end
                moreRow(engine.t("journal.title"), .floppy) {
                    if let make = FeatureHost.shared.journalScreen { make(engine) } else { JournalScreen(engine: engine) }
                }
                LookDivider()
                moreRow(engine.t("tab.calm"), .sprout) {
                    if let make = FeatureHost.shared.calmScreen { make(engine) } else { CalmScreen(engine: engine, reduceMotion: reduceMotion) }
                }
                LookDivider()
                moreRow(engine.t("today.room.edit"), .sparkles) {
                    if let make = FeatureHost.shared.roomScreen { make(engine) } else { RoomEditorSheet(engine: engine) }
                }
                LookDivider()
                moreRow(engine.t("stats.title"), .ruler) { StatsScreen(engine: engine) }
            }
        }
    }

    private func moreRow<Destination: View>(_ title: String, _ icon: LookIcon.Kind, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink { destination() } label: {
            LookNavRow(title: title, icon: icon)
        }
        .buttonStyle(.plain)
    }

    private var activitySkyRow: some View {
        NavigationLink {
            ActivitySkyView(engine: engine, reduceMotion: reduceMotion)
        } label: {
            LookCard {
                LookNavRow(
                    title: engine.t("activity.menu"),
                    subtitle: engine.t("activity.menu.note"),
                    icon: .sparkles
                )
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 20)
    }

    private func copyCode() {
        UIPasteboard.general.string = code
        copied = true
        engine.cue(.select)
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            copied = false
        }
    }
}

struct LookWidgetSheet: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @State private var kept = UserDefaults.standard.bool(forKey: "look.widget.kept")

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    LookIcon(kind: .bunnyHeart)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(engine.profile.goobyName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        let progress = engine.todayProgress()
                        Text(engine.tf("today.progress", progress.done, progress.total))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(Look.ink)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Look.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                Text(engine.t("look.widget.note"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                if let make = FeatureHost.shared.widgetSettings {
                    make(engine)
                } else {
                    Button(kept ? engine.t("look.widget.kept") : engine.t("look.widget.keep")) {
                        kept = true
                        UserDefaults.standard.set(true, forKey: "look.widget.kept")
                    }
                    .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                }
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Look.canvas.ignoresSafeArea())
            .navigationTitle(engine.t("look.widget.sheet"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(engine.t("common.done")) { dismiss() }
            }
        }
    }
}

struct LookPlusSheet: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @State private var enabled = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(engine.t("look.plus.name"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.t("look.plus.lead"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                Text(enabled ? engine.t("look.plus.on") : engine.t("look.plus.none"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.plus)
                Button(enabled ? engine.t("look.plus.disable") : engine.t("look.plus.enable")) {
                    enabled.toggle()
                    LookMark.set(engine, LookMark.plus, enabled)
                }
                .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Look.canvas.ignoresSafeArea())
            .navigationTitle(engine.t("look.plus.name"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button(engine.t("common.done")) { dismiss() } }
            .onAppear { enabled = LookMark.isOn(engine, LookMark.plus) }
        }
    }
}
