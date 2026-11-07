import SwiftUI

/// Seasonal events: the featured event in its own color theme with its reward path and a link to
/// the shop, then the whole calendar. Reached from the purple banner in the menu.
struct EventScreen: View {
    var engine: GoobyEngine

    var body: some View {
        let featured = MenuEvents.featured(engine)
        let theme = featured.map { MenuEvents.theme($0) } ?? MenuEvents.fallback
        MenuScroll {
            if let featured {
                hero(featured, theme: theme)
                rewardPath(featured, theme: theme)
                shopLink(featured, theme: theme)
            }
            MenuSectionHeader(text: engine.tx("menu.events.calendar", de: "Festkalender", en: "Event calendar"))
            MenuListGroup {
                let events = MenuEvents.calendar(engine)
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    if index > 0 { MenuListDivider() }
                    calendarRow(event)
                }
            }
        }
        .menuChrome(engine, title: engine.t("events.title"), background: theme.light)
    }

    // MARK: Hero

    private func hero(_ event: EventDef, theme: MenuEventTheme) -> some View {
        let active = engine.isEventActive(event.id)
        return VStack(spacing: 12) {
            MenuEventBadge(event: event, size: 110)
                .padding(.top, 6)
            Text(event.title.text(engine.languageCode))
                .font(Theme.Fonts.title)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(event.blurb.text(engine.languageCode))
                .font(Theme.Fonts.body)
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text((active ? engine.t("events.active") : engine.t("events.upcoming")).uppercased())
                    .font(Theme.Fonts.caps)
                    .tracking(1)
                    .foregroundStyle(theme.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white, in: Capsule())
                Text(active ? MenuEvents.untilText(engine, event) : MenuEvents.startsText(engine, event))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(.white)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(theme.color, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .cardShadow()
    }

    // MARK: Reward path

    private func rewardPath(_ event: EventDef, theme: MenuEventTheme) -> some View {
        let active = engine.isEventActive(event.id)
        let record = engine.all(EventRecord.self).first { $0.eventID == event.id }
        let claimed = record.map { engine.claimedTasks($0) } ?? []
        return VStack(alignment: .leading, spacing: Theme.Space.gap) {
            MenuSectionHeader(text: engine.tx("menu.events.path", de: "Belohnungspfad", en: "Reward path"))
            ForEach(Array(event.tasks.enumerated()), id: \.element.id) { index, task in
                let progress = engine.eventProgress(event, task)
                let done = claimed.contains(task.id)
                GCard {
                    HStack(alignment: .center, spacing: 14) {
                        IconTile(color: done ? Theme.checkGreen : theme.color, size: 52) {
                            if done {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.title.text(engine.languageCode))
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.text)
                                .fixedSize(horizontal: false, vertical: true)
                            rewardLine(task)
                            if active {
                                StripedProgressBar(value: progress, goal: task.goal, height: 22)
                            }
                        }
                        if active {
                            if done {
                                Text(engine.t("quests.claimed"))
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.greyText)
                            } else if progress >= task.goal {
                                Button {
                                    _ = engine.claimEventTask(event, task)
                                } label: {
                                    Text(engine.t("common.claim"))
                                }
                                .buttonStyle(Press3DButtonStyle(fill: theme.color, edge: nil, radius: 14, horizontal: 12, vertical: 8))
                                .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
            if !active {
                MenuFootnote(text: engine.tx("menu.events.later", de: "Der Pfad öffnet sich, sobald das Fest beginnt.", en: "The path opens when the event begins."))
            }
        }
    }

    private func rewardLine(_ task: EventTaskDef) -> some View {
        HStack(spacing: 6) {
            Text("+\(task.rewardSparks)")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.greyText)
            GoobyIcon("✨", size: 16)
            if let item = engine.catalog.itemsByID[task.rewardItemID] {
                Text("· \(item.name.text(engine.languageCode))")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.greyText)
                    .lineLimit(1)
                GoobyIcon("🎁", size: 16)
            }
        }
    }

    // MARK: Shop link

    private func shopLink(_ event: EventDef, theme: MenuEventTheme) -> some View {
        let items = engine.catalog.items.filter { $0.seasonalEvent == event.id }
        return NavigationLink {
            if let make = FeatureHost.shared.shopScreen { make(engine) } else { ShopScreen(engine: engine, reduceMotion: engine.reduceMotion) }
        } label: {
            GCard {
                HStack(spacing: 14) {
                    IconTile(color: theme.color.opacity(0.22), size: 52) {
                        GoobyIcon("🏪", size: 34)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(engine.tx("menu.events.shop", de: "Festladen", en: "Event shop"))
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                        Text(items.isEmpty
                             ? engine.tx("menu.events.shop.none", de: "Kleidung und Möbel im Laden", en: "Clothes and furniture in the shop")
                             : engine.txf("menu.events.shop.items", de: "%d Sachen nur zu diesem Fest", en: "%d items only during this event", items.count))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.greyText)
                    }
                    Spacer(minLength: 6)
                    CircleChevron(fill: Theme.keyFace)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Calendar

    private func calendarRow(_ event: EventDef) -> some View {
        let theme = MenuEvents.theme(event)
        let active = engine.isEventActive(event.id)
        return HStack(spacing: 14) {
            IconTile(color: theme.light, size: 44, radius: 12) {
                GoobyIcon(theme.emoji, size: 28)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title.text(engine.languageCode))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.text)
                Text(MenuEvents.rangeText(engine, event))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.greyText)
            }
            Spacer(minLength: 6)
            if active {
                Text(engine.t("events.active"))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(theme.color, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 60)
        .accessibilityElement(children: .combine)
    }
}

/// Color theme and emoji illustration of an event.
struct MenuEventTheme: Sendable {
    var emoji: String
    var color: Color
    var light: Color
}

/// Event round badge: the event's emoji on a light disc with small sparkles.
struct MenuEventBadge: View {
    var event: EventDef
    var size: CGFloat

    var body: some View {
        let theme = MenuEvents.theme(event)
        ZStack {
            Circle()
                .fill(theme.light)
            Circle()
                .stroke(Color.white, lineWidth: max(2, size * 0.05))
            Text(verbatim: theme.emoji)
                .font(.system(size: size * 0.52))
            Text(verbatim: "✨")
                .font(.system(size: size * 0.22))
                .offset(x: size * 0.36, y: -size * 0.34)
            Text(verbatim: "✨")
                .font(.system(size: size * 0.15))
                .offset(x: -size * 0.38, y: size * 0.3)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Event themes, and event dates for the menu banner and the event screen by the app clock
/// (`engine.now()`).
enum MenuEvents {
    static let fallback = MenuEventTheme(emoji: "🎉", color: Theme.Tab.menu.banner, light: Color(hex: 0xE6E2F7))

    static func theme(_ event: EventDef) -> MenuEventTheme {
        switch event.id {
        case "lantern-festival": return MenuEventTheme(emoji: "🏮", color: Color(hex: 0xE5574F), light: Color(hex: 0xFBE3DC))
        case "spring-meadow", "spring": return MenuEventTheme(emoji: "🌷", color: Color(hex: 0x6DB45A), light: Color(hex: 0xE4F3D9))
        case "blossom-week", "cherry": return MenuEventTheme(emoji: "🌸", color: Color(hex: 0xE277A3), light: Color(hex: 0xFBE4EE))
        case "rainbow-week": return MenuEventTheme(emoji: "🌈", color: Color(hex: 0x4FA3E3), light: Color(hex: 0xDCEDFB))
        case "summer-picnic": return MenuEventTheme(emoji: "🧺", color: Color(hex: 0xF0993B), light: Color(hex: 0xFDEBD2))
        case "summer": return MenuEventTheme(emoji: "☀️", color: Color(hex: 0xF2A23A), light: Color(hex: 0xFEF0CF))
        case "starry-nights": return MenuEventTheme(emoji: "🌠", color: Color(hex: 0x5866C4), light: Color(hex: 0xE0E3F7))
        case "leaf-walk": return MenuEventTheme(emoji: "🍂", color: Color(hex: 0xD9783A), light: Color(hex: 0xF9E3D3))
        case "harvest": return MenuEventTheme(emoji: "🍎", color: Color(hex: 0xD8574B), light: Color(hex: 0xF9E0DC))
        case "lantern-eve": return MenuEventTheme(emoji: "🎃", color: Color(hex: 0xEE8A2F), light: Color(hex: 0xFBE6D0))
        case "autumn": return MenuEventTheme(emoji: "🏮", color: Color(hex: 0xE0703A), light: Color(hex: 0xFAE2D4))
        case "cozy-evenings": return MenuEventTheme(emoji: "☕", color: Color(hex: 0xB5835A), light: Color(hex: 0xF3E6D8))
        case "honey": return MenuEventTheme(emoji: "🍯", color: Color(hex: 0xE6A82F), light: Color(hex: 0xFCEFCF))
        case "winter-warmth": return MenuEventTheme(emoji: "🧣", color: Color(hex: 0xD45D5D), light: Color(hex: 0xF9E1E1))
        case "winter": return MenuEventTheme(emoji: "⭐", color: Color(hex: 0x5C8FD6), light: Color(hex: 0xDFEAF8))
        case "new-year-sparkle": return MenuEventTheme(emoji: "🎆", color: Color(hex: 0xD9A02A), light: Color(hex: 0xFBEFD2))
        case "newyear": return MenuEventTheme(emoji: "✨", color: Color(hex: 0x8B6CD9), light: Color(hex: 0xE9E2FA))
        default: return fallback
        }
    }

    /// The active event that ends first, otherwise the next event to start.
    @MainActor
    static func featured(_ engine: GoobyEngine) -> EventDef? {
        let events = engine.catalog.events
        let active = events.filter { engine.isEventActive($0.id) }
        if !active.isEmpty {
            return active.min { nextEnd(engine, $0) < nextEnd(engine, $1) }
        }
        return events.min { nextStart(engine, $0) < nextStart(engine, $1) }
    }

    /// Active events first, then by their next start.
    @MainActor
    static func calendar(_ engine: GoobyEngine) -> [EventDef] {
        engine.catalog.events.sorted { lhs, rhs in
            let left = engine.isEventActive(lhs.id), right = engine.isEventActive(rhs.id)
            if left != right { return left }
            return nextStart(engine, lhs) < nextStart(engine, rhs)
        }
    }

    /// Start day of the event's next window (today or later).
    @MainActor
    static func nextStart(_ engine: GoobyEngine, _ event: EventDef) -> Date {
        next(engine, month: event.startMonth, day: event.startDay)
    }

    /// Last day of the event's current or next window (today or later).
    @MainActor
    static func nextEnd(_ engine: GoobyEngine, _ event: EventDef) -> Date {
        next(engine, month: event.endMonth, day: event.endDay)
    }

    @MainActor
    static func untilText(_ engine: GoobyEngine, _ event: EventDef) -> String {
        engine.txf("menu.event.until", de: "Läuft bis %@", en: "Runs until %@", dayMonth(engine, nextEnd(engine, event)))
    }

    @MainActor
    static func startsText(_ engine: GoobyEngine, _ event: EventDef) -> String {
        engine.txf("menu.event.starts", de: "Beginnt am %@", en: "Starts on %@", dayMonth(engine, nextStart(engine, event)))
    }

    @MainActor
    static func rangeText(_ engine: GoobyEngine, _ event: EventDef) -> String {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2001, month: event.startMonth, day: event.startDay)) ?? Date()
        let end = calendar.date(from: DateComponents(year: 2001, month: event.endMonth, day: event.endDay)) ?? Date()
        return "\(dayMonth(engine, start)) – \(dayMonth(engine, end))"
    }

    @MainActor
    private static func next(_ engine: GoobyEngine, month: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: engine.now())
        let year = calendar.component(.year, from: today)
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? today
        if date >= today { return date }
        return calendar.date(byAdding: .year, value: 1, to: date) ?? date
    }

    @MainActor
    private static func dayMonth(_ engine: GoobyEngine, _ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.setLocalizedDateFormatFromTemplate("dMMMM")
        return formatter.string(from: date)
    }
}
