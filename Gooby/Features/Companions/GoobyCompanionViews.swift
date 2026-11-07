#if canImport(SwiftUI)
import SwiftUI

struct GoobyCompanionBadgeSlot: View {
    var languageCode: String
    var now: Date
    @State private var revision = 0

    var body: some View {
        let companion = GoobyEventsIntegration.selectedCompanion(languageCode: languageCode)
        Group {
            if let companion {
                VStack(spacing: 4) {
                    GoobyCompanionArt(
                        speciesID: companion.speciesID,
                        primaryHex: companion.primaryHex,
                        secondaryHex: companion.secondaryHex,
                        animation: companion.animation,
                        size: 78
                    )
                    Text(companion.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GoobyEventsPalette.ink)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(companion.name)
            }
        }
        .onAppear {
            GoobyEventsIntegration.ensureResources()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goobyEventsDidChange)) { _ in
            revision += 1
        }
        .id(revision)
    }
}

struct GoobyNestBoard: View {
    var model: GoobyEventsScreenModel
    var libraries: GoobyEventsLibraries
    var habits: [GoobyHabitLink]
    var now: Date
    var calendar: Calendar
    var onGrants: ([GoobyRewardGrant]) -> Void

    @State private var customHabit = ""
    @State private var chosenHabitID: String?
    @State private var confirmBind = false
    @State private var notice: String?
    @State private var detail: GoobyCompanionSnapshot?

    private var activeEggs: [GoobyEggSnapshot] {
        model.eggs.filter { $0.hatchedCompanionID == nil }
    }

    private var hatchedEggs: [GoobyEggSnapshot] {
        model.eggs.filter { $0.hatchedCompanionID != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(libraries.text("nest.lead", language: model.language))
                .font(.subheadline)
                .foregroundStyle(GoobyEventsPalette.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
            Text(libraries.text("nest.duplicates", language: model.language))
                .font(.caption)
                .foregroundStyle(GoobyEventsPalette.ink.opacity(0.6))

            bindCard
            eggSection
            friendSection
        }
        .confirmationDialog(
            libraries.text("nest.confirmTitle", language: model.language),
            isPresented: $confirmBind,
            titleVisibility: .visible
        ) {
            Button(libraries.text("nest.bind", language: model.language)) {
                tieEgg()
            }
            Button(libraries.text("nest.cancel", language: model.language), role: .cancel) {}
        } message: {
            Text(libraries.text("nest.confirmBody", language: model.language))
        }
        .sheet(item: $detail) { companion in
            GoobyCompanionDetail(
                companion: companion,
                libraries: libraries,
                language: model.language,
                now: now,
                calendar: calendar,
                onGrants: onGrants
            )
        }
    }

    private var bindCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if habits.isEmpty {
                TextField(libraries.text("nest.habitPlaceholder", language: model.language), text: $customHabit)
                    .textFieldStyle(.roundedBorder)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(habits) { habit in
                            Button(habit.title) {
                                chosenHabitID = habit.id
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(chosenHabitID == habit.id ? GoobyEventsPalette.blush : Color.white)
                            .foregroundStyle(GoobyEventsPalette.ink)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            if let notice {
                Text(notice)
                    .font(.footnote)
                    .foregroundStyle(GoobyEventsPalette.ink)
            }
            GoobyPrimaryButton(title: libraries.text("nest.bind", language: model.language), tint: GoobyEventsPalette.ink) {
                confirmBind = true
            }
            .disabled(!canBind)
            .opacity(canBind ? 1 : 0.45)
        }
        .goobyCard(fill: GoobyEventsPalette.butter.opacity(0.55))
    }

    private var eggSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(libraries.text("nest.eggs", language: model.language))
                .font(.title3.weight(.bold))
                .foregroundStyle(GoobyEventsPalette.ink)
            if activeEggs.isEmpty {
                Text(libraries.text("nest.noEggs", language: model.language))
                    .font(.subheadline)
                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.72))
            }
            ForEach(activeEggs) { egg in
                HStack(spacing: 14) {
                    GoobyEggArt(progress: egg.validDays)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(egg.habitTitle)
                            .font(.headline)
                            .foregroundStyle(GoobyEventsPalette.ink)
                        Text(libraries.format("progress.of", language: model.language, tokens: [
                            "current": "\(egg.validDays)",
                            "target": "\(egg.requiredDays)"
                        ]))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GoobyEventsPalette.ink.opacity(0.75))
                        HStack(spacing: 5) {
                            ForEach(0..<egg.requiredDays, id: \.self) { index in
                                Circle()
                                    .fill(index < egg.validDays ? GoobyEventsPalette.ink : GoobyEventsPalette.ink.opacity(0.15))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
            if !hatchedEggs.isEmpty {
                Text(libraries.text("nest.hatched", language: model.language))
                    .font(.headline)
                    .foregroundStyle(GoobyEventsPalette.ink)
                    .padding(.top, 4)
                ForEach(hatchedEggs) { egg in
                    Text(egg.habitTitle)
                        .font(.subheadline)
                        .foregroundStyle(GoobyEventsPalette.ink.opacity(0.75))
                }
            }
        }
        .goobyCard()
    }

    private var friendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(libraries.text("nest.friends", language: model.language))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(GoobyEventsPalette.ink)
                Spacer()
                if model.companions.contains(where: \.selected) {
                    Button(libraries.text("nest.showNone", language: model.language)) {
                        GoobyEventsIntegration.selectCompanion(id: nil)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GoobyEventsPalette.ink)
                }
            }
            if model.companions.isEmpty {
                Text(libraries.text("nest.noFriends", language: model.language))
                    .font(.subheadline)
                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.72))
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(model.companions) { companion in
                        Button {
                            detail = companion
                        } label: {
                            VStack(spacing: 4) {
                                GoobyCompanionArt(
                                    speciesID: companion.speciesID,
                                    primaryHex: companion.primaryHex,
                                    secondaryHex: companion.secondaryHex,
                                    animation: companion.animation,
                                    size: 86
                                )
                                Text(companion.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(GoobyEventsPalette.ink)
                                    .lineLimit(1)
                                if companion.selected {
                                    Text(libraries.text("nest.selected", language: model.language))
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(GoobyEventsPalette.ink)
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(companion.selected ? GoobyEventsPalette.blush.opacity(0.8) : Color.white.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(GoobySquishButtonStyle())
                        .accessibilityLabel(companion.name)
                    }
                }
            }
        }
        .goobyCard(fill: GoobyEventsPalette.mint.opacity(0.45))
    }

    private var canBind: Bool {
        if habits.isEmpty {
            return !customHabit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return chosenHabitID != nil
    }

    private func tieEgg() {
        if activeEggs.count >= GoobyCompanionEngine.activeEggCap {
            notice = libraries.text("nest.cap", language: model.language)
            return
        }
        let habit: GoobyHabitLink
        if habits.isEmpty {
            habit = GoobyHabitIdentity.link(title: customHabit)
        } else if let chosenHabitID, let match = habits.first(where: { $0.id == chosenHabitID }) {
            habit = match
        } else {
            return
        }
        let result = GoobyEventsIntegration.bindEgg(habit: habit, now: now, calendar: calendar)
        if result.egg == nil {
            notice = libraries.text("nest.cap", language: model.language)
            return
        }
        notice = nil
        customHabit = ""
        onGrants(result.grants)
    }
}

struct GoobyCompanionDetail: View {
    var companion: GoobyCompanionSnapshot
    var libraries: GoobyEventsLibraries
    var language: GoobyEventsLanguage
    var now: Date
    var calendar: Calendar
    var onGrants: ([GoobyRewardGrant]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""
    @State private var revision = 0

    var body: some View {
        let _ = revision
        let current = GoobyEventsIntegration.screen(languageCode: language.rawValue, now: now, calendar: calendar)
            .companions.first { $0.id == companion.id } ?? companion
        ScrollView {
            VStack(spacing: 16) {
                GoobyCompanionArt(
                    speciesID: current.speciesID,
                    primaryHex: current.primaryHex,
                    secondaryHex: current.secondaryHex,
                    animation: current.animation,
                    size: 180
                )
                Text(current.name)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(GoobyEventsPalette.ink)
                Text(libraries.text("stage.\(current.stage)", language: language))
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(GoobyEventsPalette.lavender)
                    .clipShape(Capsule())
                Text(libraries.text("rarity.\(current.rarity)", language: language))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.7))
                Text(current.story)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GoobyEventsPalette.ink.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                TextField(libraries.text("nest.namePlaceholder", language: language), text: $draftName)
                    .textFieldStyle(.roundedBorder)
                GoobyPrimaryButton(title: libraries.text("nest.rename", language: language)) {
                    GoobyEventsIntegration.renameCompanion(id: current.id, name: draftName)
                }
                GoobyPrimaryButton(
                    title: libraries.text(current.playedToday ? "nest.played" : "nest.play", language: language),
                    tint: current.playedToday ? GoobyEventsPalette.ink.opacity(0.45) : GoobyEventsPalette.ink
                ) {
                    let grants = GoobyEventsIntegration.record(.companionPlayed(companionID: current.id), now: now, calendar: calendar)
                    onGrants(grants)
                }
                .disabled(current.playedToday)
                if current.selected {
                    Text(libraries.text("nest.selected", language: language))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(GoobyEventsPalette.ink)
                } else {
                    Button(libraries.text("nest.selected", language: language)) {
                        GoobyEventsIntegration.selectCompanion(id: current.id)
                    }
                    .font(.headline)
                    .foregroundStyle(GoobyEventsPalette.ink)
                }
            }
            .padding(24)
        }
        .background(GoobyEventsPalette.cream.ignoresSafeArea())
        .onAppear {
            draftName = current.name
        }
        .onReceive(NotificationCenter.default.publisher(for: .goobyEventsDidChange)) { _ in
            revision += 1
        }
    }
}
#endif
