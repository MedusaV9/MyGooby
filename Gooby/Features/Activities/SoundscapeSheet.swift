import SwiftUI

struct SoundscapeScene: Identifiable {
    var id: String
    var filter: String
    var tint: UInt32
    var symbol: String
}

enum SoundscapeCatalog {
    static let filters = ["all", "water", "ecosystems", "weather", "animals"]
    static let fadeChoices = [0, 1, 5, 15, 30, 60]

    static let scenes: [SoundscapeScene] = [
        SoundscapeScene(id: "home", filter: "ecosystems", tint: 0xF2C14E, symbol: "house.fill"),
        SoundscapeScene(id: "water", filter: "water", tint: 0x2E9BE0, symbol: "water.waves"),
        SoundscapeScene(id: "forest", filter: "ecosystems", tint: 0x3EAE45, symbol: "tree.fill"),
        SoundscapeScene(id: "rain", filter: "weather", tint: 0x5AA7E8, symbol: "cloud.rain.fill"),
        SoundscapeScene(id: "travel", filter: "ecosystems", tint: 0xF0A020, symbol: "airplane"),
        SoundscapeScene(id: "boat", filter: "water", tint: 0xE07A3D, symbol: "sailboat.fill"),
        SoundscapeScene(id: "shop", filter: "ecosystems", tint: 0xE25B93, symbol: "bag.fill"),
        SoundscapeScene(id: "thunder", filter: "weather", tint: 0x6E5BD4, symbol: "cloud.bolt.fill"),
        SoundscapeScene(id: "wind", filter: "weather", tint: 0x8EB4D4, symbol: "wind"),
        SoundscapeScene(id: "land", filter: "animals", tint: 0xC47A3A, symbol: "pawprint.fill"),
        SoundscapeScene(id: "birds", filter: "animals", tint: 0x7EB6D6, symbol: "bird.fill")
    ]
}

struct SoundscapeSheet: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @ObservedObject private var favorites = ActivityFavoriteStore.shared
    @State private var query = ""
    @State private var filter = "all"
    @State private var starsOnly = false

    var body: some View {
        let rows = filtered
        let sound = engine.sound
        ActivityLanePage(engine: engine, lane: .soundscapes) {
            ActivitySearchField(prompt: engine.t("common.search"), text: $query)
            ActivityFilterBar(
                engine: engine,
                filters: SoundscapeCatalog.filters,
                filter: filter,
                starsOnly: starsOnly,
                onFilter: { filter = $0 },
                onStars: { starsOnly.toggle() }
            )
            timerCard
            if !GoobyFeedback.shared.soundsOn {
                Text(engine.t("soundscape.sounds.off"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x243041))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            ForEach(rows) { scene in
                row(scene, sound: sound)
            }
            if rows.isEmpty {
                ActivityQuietNote(text: engine.t("activity.search.empty"))
            }
            ActivityQuietNote(text: engine.t("soundscape.note"))
        }
        .transaction { transaction in
            if reduceMotion { transaction.disablesAnimations = true }
        }
    }

    private var filtered: [SoundscapeScene] {
        SoundscapeCatalog.scenes.filter { scene in
            ActivityCatalog.matches(
                query: query,
                title: engine.t("soundscape.\(scene.id).title"),
                detail: engine.t("soundscape.\(scene.id).detail"),
                filters: [scene.filter],
                filter: filter,
                starsOnly: starsOnly,
                starID: starID(scene.id),
                favorites: favorites
            )
        }
    }

    private var timerCard: some View {
        let sound = engine.sound
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(engine.t("soundscape.timer"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x243041))
                Spacer(minLength: 8)
                if let selection = sound.active {
                    Text(statusLine(selection, sound: sound))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x5648C4))
                        .multilineTextAlignment(.trailing)
                }
            }
            Text(engine.t("soundscape.timer.help"))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x7C8792))
                .fixedSize(horizontal: false, vertical: true)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SoundscapeCatalog.fadeChoices, id: \.self) { minutes in
                        fadeChip(minutes, sound: sound)
                    }
                    if sound.active != nil {
                        Button {
                            sound.stop()
                            engine.haptics.soft()
                        } label: {
                            Text(engine.t("soundscape.stop"))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: 0x243041))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(hex: 0xF4E4D4), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func fadeChip(_ minutes: Int, sound: SoundscapePlayer) -> some View {
        let on = sound.fadeMinutes == minutes
        let title = minutes == 0
            ? engine.t("soundscape.timer.off")
            : engine.tf("soundscape.timer.minutes", minutes)
        return Button {
            sound.chooseFade(minutes: minutes)
            engine.haptics.soft()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(on ? Color.white : Color(hex: 0x5648C4))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(on ? Color(hex: 0x5648C4) : Color(hex: 0x5648C4).opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func statusLine(_ id: String, sound: SoundscapePlayer) -> String {
        let title = engine.t("soundscape.\(id).title")
        if !GoobyFeedback.shared.soundsOn {
            return "\(title) · \(engine.t("soundscape.sounds.short"))"
        }
        if sound.fading {
            return "\(title) · \(engine.t("soundscape.fading"))"
        }
        if let left = sound.secondsLeft {
            let clock = String(format: "%d:%02d", left / 60, left % 60)
            return "\(title) · \(engine.tf("soundscape.timer.left", clock))"
        }
        return "\(title) · \(engine.t("soundscape.playing"))"
    }

    private func row(_ scene: SoundscapeScene, sound: SoundscapePlayer) -> some View {
        let title = engine.t("soundscape.\(scene.id).title")
        let detail = engine.t("soundscape.\(scene.id).detail")
        let chosen = sound.active == scene.id
        let audible = chosen && sound.heard
        let starred = favorites.contains(starID(scene.id))
        return ActivityCard {
            HStack(spacing: 0) {
                Button {
                    sound.toggle(scene.id)
                    engine.haptics.soft()
                } label: {
                    HStack(spacing: 10) {
                        SoundscapeGlyph(id: scene.id)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: 0x243041))
                                .multilineTextAlignment(.leading)
                            Text(audible ? engine.t("soundscape.playing") : detail)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(audible ? Color(hex: 0x5648C4) : Color(hex: 0x7C8792))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 4)
                        if chosen {
                            Image(systemName: audible ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x5648C4))
                                .accessibilityHidden(true)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityValue(audible ? engine.t("soundscape.playing") : detail)
                ActivityStarButton(
                    on: starred,
                    label: ActivityCatalog.starLabel(engine, on: starred, title: title)
                ) {
                    favorites.toggle(starID(scene.id))
                    engine.haptics.soft()
                }
            }
        }
    }

    private func starID(_ id: String) -> String {
        ActivityCatalog.starID("soundscapes", id)
    }
}
