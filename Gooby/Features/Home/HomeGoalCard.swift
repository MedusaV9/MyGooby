import SwiftUI

/// Goal card of the Home list (screen 2): drag handle, icon on a soft blob, bold title with a grey
/// category line, energy reward with an orange bolt and the 3D check button. The daily goal gets a
/// yellow border and a bonus tag.
struct HomeGoalCard: View {
    var engine: GoobyEngine
    var habit: Habit
    var day: Date
    var showsHandle: Bool = true
    var onOpen: (() -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    var body: some View {
        let log = engine.habitLog(habit.id, DayKey.make(day))
        let count = log?.count ?? 0
        let cap = max(1, habit.timesPerDay)
        let done = count >= cap
        HStack(spacing: 10) {
            if showsHandle {
                HomeDragHandle()
                    .draggable(habit.id.uuidString) { dragPreview }
                    .accessibilityHidden(true)
            }
            if let onOpen {
                Button(action: onOpen) {
                    info(count: count, cap: cap, done: done, skipped: log?.skipped ?? false)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(engine.tx("home.goal.openHint", de: "Öffnet die Details des Ziels.", en: "Opens the goal details."))
            } else {
                info(count: count, cap: cap, done: done, skipped: log?.skipped ?? false)
            }
            CheckButton(done: done, label: checkLabel(done: done)) { toggle(done: done) }
        }
        .padding(.leading, showsHandle ? 6 : 12)
        .padding(.trailing, 12)
        .padding(.vertical, 11)
        .frame(minHeight: 70)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay {
            if habit.isDailyGoal {
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.progressFill, lineWidth: 3)
            }
        }
        .overlay(alignment: .topTrailing) {
            if habit.isDailyGoal { dailyTag.offset(x: -14, y: -10) }
        }
        .cardShadow()
        .accessibilityElement(children: .contain)
    }

    private func info(count: Int, cap: Int, done: Bool, skipped: Bool) -> some View {
        HStack(spacing: 12) {
            HomeGoalIcon(icon: habit.icon, colorHex: habit.colorHex, size: 48)
                .opacity(done ? 0.6 : 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.text.opacity(done ? 0.5 : 1))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle(count: count, cap: cap, skipped: skipped))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.greyText)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 2) {
                Text("\(habit.energyReward)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.greyText)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Theme.bolt)
            }
            // Checking the goal floats a "+5 ⚡" chip up from the reward.
            .goobyGainFloat(count * habit.energyReward, symbol: "⚡", color: Theme.bolt)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(engine.tf("habit.energyValue", habit.energyReward))
        }
    }

    private func subtitle(count: Int, cap: Int, skipped: Bool) -> String {
        var parts = [engine.t("cat.\(habit.category)")]
        if cap > 1 { parts.append("\(count)/\(cap)") }
        if let egg = engine.activeEgg(for: habit.id), !egg.hatched {
            parts.append("🥚 \(egg.progress)/\(egg.requiredCount)")
        }
        if skipped && count == 0 {
            parts.append(engine.tx("home.goal.skipped", de: "Übersprungen", en: "Skipped"))
        }
        return parts.joined(separator: " · ")
    }

    private var dailyTag: some View {
        Text(engine.tx("home.goal.daily", de: "⭐ Tagesziel · Bonus", en: "⭐ Daily goal · Bonus"))
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.brown)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Theme.progressFill, in: Capsule())
    }

    private var dragPreview: some View {
        HStack(spacing: 8) {
            GoobyIcon(habit.icon, size: 24)
            Text(habit.title).font(Theme.Fonts.headline).foregroundStyle(Theme.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white, in: Capsule())
    }

    private func checkLabel(done: Bool) -> String {
        let state = done ? engine.t("kit.check.done") : engine.t("kit.check.todo")
        return "\(state): \(habit.title)"
    }

    /// Checking animates the card's done look, the counters and the adventure track together.
    private func toggle(done: Bool) {
        let reduce = systemReduce || appReduce
        if done {
            goobyAnimate(reduce, GoobyMotion.soft) { engine.undoHabit(habit, on: day) }
            engine.haptics.soft()
        } else {
            goobyAnimate(reduce) { engine.completeHabit(habit, on: day) }
        }
    }
}

/// Goal icon on a light grey circle (screen D); the goal's color tints the circle a little.
struct HomeGoalIcon: View {
    var icon: String
    var colorHex: String
    var size: CGFloat = 48

    var body: some View {
        GoobyIcon(icon, size: size * 0.7)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(Theme.keyFace)
                    .overlay(Circle().fill(Color(hexString: colorHex).opacity(0.3)))
            }
    }
}

/// 2 x 3 grey dots; dragging them moves the goal.
struct HomeDragHandle: View {
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: 0xC9C9C9)).frame(width: 4.5, height: 4.5)
                    Circle().fill(Color(hex: 0xC9C9C9)).frame(width: 4.5, height: 4.5)
                }
            }
        }
        .frame(width: 18, height: 48)
        .contentShape(Rectangle())
    }
}

/// Full-width darker translucent green card with "+" in a lighter circle.
struct HomeAddGoalCard: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.2), in: Circle())
                Text(title)
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Color.white.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, Theme.Space.inner)
            .frame(height: 70)
            .background(Theme.Tab.home.addGoal, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(HomeSoftPressStyle())
    }
}

/// Lighter green wave at the bottom of Home with the "need a pause?" card (opens Calm).
struct HomePauseFooter: View {
    var title: String
    var subtitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HomeWaveEdge()
                .fill(Theme.Tab.home.wave)
                .frame(height: 34)
                .background(Theme.Tab.home.bg)
                .accessibilityHidden(true)
            VStack {
                Button(action: action) {
                    HStack(spacing: 14) {
                        GoobyIcon("wind", size: 34)
                            .frame(width: 52, height: 52)
                            .background(Theme.keyFace, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.text)
                            Text(subtitle)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.greyText)
                        }
                        Spacer(minLength: 4)
                        CircleChevron(color: .white, fill: Theme.Tab.home.bg, size: 30)
                    }
                    .padding(Theme.Space.inner)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    .cardShadow()
                    .contentShape(Rectangle())
                }
                .buttonStyle(HomeSoftPressStyle())
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.top, 4)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.Tab.home.wave)
        }
    }
}
