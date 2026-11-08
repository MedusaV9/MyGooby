import SwiftUI

// Building blocks of the timer Live Activity (Lock Screen, Dynamic Island, in-app preview).
// Live Activities render still frames: only `Text(timerInterval:)` and
// `ProgressView(timerInterval:)` move on their own, so every live element is one of those.

/// Everything a Live Activity view needs, resolved once: the attributes, the content state and
/// whether the system marked it stale (the timer ran out while the app could not update it).
struct GoobyActivityLook {
    typealias State = GoobyTimerAttributes.ContentState

    var attributes: GoobyTimerAttributes
    var state: State
    var isStale: Bool = false

    var kind: GoobyTimerAttributes.Kind { attributes.kind }

    /// Finished: the app ended it as done, or the timer ran out while the app was closed.
    var done: Bool { state.phase == State.done || ranOut }
    var paused: Bool { !done && state.pausedRemaining != nil }
    /// The stale date passed while it was running: the lines come from here, not from the app.
    private var ranOut: Bool { isStale && state.phase == State.running }

    var name: String { attributes.goobyName.isEmpty ? "Gooby" : attributes.goobyName }

    func text(de: String, en: String) -> String {
        GoobyText.pick(attributes.language, de: de, en: en)
    }

    var face: GoobyMiniHead.Face {
        if done { return .happy }
        return kind == .breath ? .sleepy : .smile
    }

    var title: String {
        guard ranOut else { return state.title }
        switch kind {
        case .adventure: return text(de: "\(name) ist zurück!", en: "\(name) is back!")
        case .focus: return text(de: "Fokus geschafft!", en: "Focus done!")
        case .breath: return text(de: "Atemübung vorbei", en: "Breathing finished")
        }
    }

    var detail: String {
        guard ranOut else { return state.detail }
        switch kind {
        case .adventure: return state.detail
        case .focus: return text(de: "Öffne Gooby für deine Belohnung", en: "Open Gooby to collect your reward")
        case .breath: return text(de: "Tippe, um weiterzuatmen", en: "Tap to breathe again")
        }
    }

    var note: String {
        guard ranOut else { return state.note }
        return kind == .adventure ? text(de: "Neue Geschichte", en: "New story") : ""
    }

    /// Detail and note on one line.
    var subline: String {
        [detail, note].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// Timer and bar color on dark surfaces (Dynamic Island).
    var accent: Color {
        kind == .breath ? GoobyActivityPalette.bubble : GoobyTokens.progressFill
    }

    /// Breathing steps with short labels; steps of 0 seconds are left out.
    var steps: [(label: String, seconds: Int)] {
        let labels = [
            text(de: "Ein", en: "In"),
            text(de: "Halten", en: "Hold"),
            text(de: "Aus", en: "Out"),
            text(de: "Pause", en: "Rest")
        ]
        return zip(labels, attributes.breathSteps)
            .filter { $0.1 > 0 }
            .map { (label: $0.0, seconds: $0.1) }
    }

    /// Spoken summary for VoiceOver.
    var spoken: String {
        [title, subline].filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

/// Colors of the activity surfaces beyond the shared tokens: the Home scene, the adventure track
/// circles and the breathing bubble, same values as in the app's screens.
enum GoobyActivityPalette {
    static let leafDark = Color(hex: 0x3F8A3C)
    static let hillFar = Color(hex: 0x8CC66A)
    static let hillShine = Color(hex: 0xA8D88A)
    static let pillEdge = Color(hex: 0xCFE3BF)
    static let boltTop = Color(hex: 0xFFC93C)
    static let boltBottom = Color(hex: 0xF59B23)
    static let goal = Color(hex: 0xFFD45E)
    static let goalInk = Color(hex: 0x9A6A12)
    static let goalEdge = Color(hex: 0xE0A93A)
    static let bubble = Color(hex: 0xA9DCF5)
    static let bubbleLight = Color(hex: 0xE4F4FD)
    static let calmEdge = Color(hex: 0xC9C0EA)
    static let calmInk = Color(hex: 0x6B6488)
    static let wallpaperTop = Color(hex: 0x2D3456)
    static let wallpaperBottom = Color(hex: 0x8F8FC9)
}

// MARK: - Timer

/// Count-down (adventure, focus) or count-up (breathing) of the timer, a fixed clock while
/// paused, a check when done.
struct GoobyTimerText: View {
    var state: GoobyTimerAttributes.ContentState

    var body: some View {
        if state.phase == GoobyTimerAttributes.ContentState.done {
            Text(verbatim: "✓")
        } else if let left = state.pausedRemaining {
            Text(verbatim: GoobyTimerText.clock(left))
                .monospacedDigit()
        } else {
            Text(timerInterval: state.interval, countsDown: !state.countsUp)
                .monospacedDigit()
        }
    }

    /// "m:ss", or "h:mm:ss" from one hour on.
    static func clock(_ seconds: Int) -> String {
        let value = max(0, seconds)
        if value >= 3600 {
            return String(format: "%d:%02d:%02d", value / 3600, value / 60 % 60, value % 60)
        }
        return String(format: "%d:%02d", value / 60, value % 60)
    }

    /// Width that fits the longest clock of this timer at `size` points.
    static func width(_ state: GoobyTimerAttributes.ContentState, size: CGFloat) -> CGFloat {
        let long = state.length >= 3600 && !state.countsUp
        return size * (long ? 4.1 : 2.95)
    }
}

/// Progress of the timer as a system bar, the only bar that moves on its own in a Live Activity.
/// Still when paused, full when done; breathing has no bar.
struct GoobyActivityBar: View {
    var look: GoobyActivityLook
    var tint: Color

    var body: some View {
        Group {
            if look.done || look.paused || look.state.countsUp {
                ProgressView(value: look.done ? 1 : look.state.fraction())
            } else {
                ProgressView(timerInterval: look.state.interval, countsDown: false, label: { EmptyView() }, currentValueLabel: { EmptyView() })
            }
        }
        .progressViewStyle(.linear)
        .tint(tint)
        .scaleEffect(x: 1, y: 1.8, anchor: .center)
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

// MARK: - Track circles, badges, pills

/// Yellow-orange start circle with a lightning bolt (Home adventure track).
struct GoobyActivityBolt: View {
    var size: CGFloat

    var body: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: size * 0.47, weight: .black))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Circle().fill(LinearGradient(colors: [GoobyActivityPalette.boltTop, GoobyActivityPalette.boltBottom], startPoint: .top, endPoint: .bottom))
            )
    }
}

/// Yellow goal circle at the end of the track: "?" while traveling, "!" when Gooby is back.
struct GoobyActivityGoal: View {
    var symbol: String
    var size: CGFloat

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.47, weight: .black))
            .foregroundStyle(GoobyActivityPalette.goalInk)
            .frame(width: size, height: size)
            .background(Circle().fill(GoobyActivityPalette.goal))
    }
}

/// Round "3D" badge with a darker bottom edge, like the check buttons.
struct GoobyActivityBadge: View {
    var symbol: String
    var fill: Color
    var edge: Color
    var ink: Color
    var size: CGFloat

    var body: some View {
        let lift = max(2, size * 0.08)
        ZStack(alignment: .top) {
            Circle()
                .fill(edge)
                .frame(width: size, height: size)
                .offset(y: lift)
            Image(systemName: symbol)
                .font(.system(size: size * 0.44, weight: .black))
                .foregroundStyle(ink)
                .frame(width: size, height: size)
                .background(Circle().fill(fill))
        }
        .frame(width: size, height: size + lift, alignment: .top)
        .accessibilityHidden(true)
    }

    static func done(_ look: GoobyActivityLook, size: CGFloat) -> GoobyActivityBadge {
        if look.kind == .adventure {
            return GoobyActivityBadge(symbol: "exclamationmark", fill: GoobyActivityPalette.goal, edge: GoobyActivityPalette.goalEdge, ink: GoobyActivityPalette.goalInk, size: size)
        }
        return GoobyActivityBadge(symbol: "checkmark", fill: GoobyTokens.checkGreen, edge: GoobyTokens.checkGreenEdge, ink: .white, size: size)
    }
}

/// White "3D" pill with a darker bottom edge (Home "Read story" button). The whole activity is
/// the tap target; the pill names what the tap opens.
struct GoobyActivityPill: View {
    var text: String
    var ink: Color
    var fill: Color = .white
    var edge: Color = GoobyActivityPalette.pillEdge

    var body: some View {
        Text(text)
            .font(GoobyTokens.Fonts.rounded(14))
            .foregroundStyle(ink)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(fill))
            .background(Capsule().fill(edge).offset(y: 3))
            .padding(.bottom, 3)
    }
}

// MARK: - Gooby

/// Gooby's head on a rounded tile with a darker bottom edge (focus activity).
struct GoobyActivityTile: View {
    var look: GoobyActivityLook
    var size: CGFloat
    var fill: Color
    var edge: Color

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
        GoobyMiniHead(fur: look.attributes.fur, stage: look.attributes.stage, face: look.face)
            .padding(size * 0.12)
            .frame(width: size, height: size)
            .background(shape.fill(fill))
            .background(shape.fill(edge).offset(y: 3))
            .padding(.bottom, 3)
    }
}

/// Gooby's head on a round colored disc (Dynamic Island).
struct GoobyActivityDisc: View {
    var look: GoobyActivityLook
    var size: CGFloat
    var fill: Color

    var body: some View {
        GoobyMiniHead(fur: look.attributes.fur, stage: look.attributes.stage, face: look.face)
            .padding(size * 0.13)
            .frame(width: size, height: size)
            .background(Circle().fill(fill))
    }
}

/// The breathing screen's soft layered bubble with Gooby resting in the middle.
struct GoobyBreathBubble: View {
    var look: GoobyActivityLook
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(GoobyTokens.tileSky.opacity(0.16))
            Circle()
                .fill(GoobyTokens.tileSky.opacity(0.28))
                .frame(width: size * 0.82, height: size * 0.82)
            Circle()
                .fill(RadialGradient(colors: [GoobyActivityPalette.bubbleLight, GoobyActivityPalette.bubble], center: .topLeading, startRadius: size * 0.04, endRadius: size * 0.76))
                .frame(width: size * 0.66, height: size * 0.66)
            GoobyMiniHead(fur: look.attributes.fur, stage: look.attributes.stage, face: look.face)
                .frame(width: size * 0.5, height: size * 0.5)
        }
        .frame(width: size, height: size)
    }
}

/// The breathing pattern as small pills: "In 4s", "Hold 4s", "Out 4s".
struct GoobyBreathChips: View {
    var look: GoobyActivityLook
    /// White text on translucent pills for the Dynamic Island.
    var dark = false

    var body: some View {
        let steps = look.steps
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { index in
                let step = steps[index]
                HStack(spacing: 3) {
                    Text(step.label)
                        .font(GoobyTokens.Fonts.rounded(12))
                        .foregroundStyle(dark ? Color.white : GoobyTokens.text)
                    Text(verbatim: "\(step.seconds)s")
                        .font(GoobyTokens.Fonts.rounded(12, .bold))
                        .foregroundStyle(dark ? GoobyActivityPalette.bubble : GoobyTokens.tileSky)
                        .monospacedDigit()
                }
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(dark ? Color.white.opacity(0.14) : GoobyTokens.white))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Backgrounds

/// Small dusk forest behind the adventure activity: the Home scene's sky, stars, moon and
/// rolling hills. The track card sits on the hills, the white text on the sky.
struct GoobyActivityDusk: View {
    private static let stars: [(CGFloat, CGFloat, CGFloat)] = [
        (0.30, 0.10, 2.5), (0.46, 0.22, 2), (0.58, 0.08, 3), (0.70, 0.30, 2), (0.80, 0.12, 2.5), (0.38, 0.36, 1.8)
    ]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            ZStack {
                LinearGradient(colors: [GoobyTokens.homeSky, GoobyTokens.homeSkyLow], startPoint: .top, endPoint: .bottom)
                ForEach(0..<GoobyActivityDusk.stars.count, id: \.self) { index in
                    let star = GoobyActivityDusk.stars[index]
                    Circle()
                        .fill(GoobyTokens.star.opacity(0.85))
                        .frame(width: star.2, height: star.2)
                        .position(x: width * star.0, y: height * star.1)
                }
                Circle()
                    .fill(GoobyTokens.moon)
                    .frame(width: 16, height: 16)
                    .shadow(color: GoobyTokens.moon.opacity(0.7), radius: 6)
                    .position(x: width - 26, y: 13)
                Ellipse()
                    .fill(GoobyActivityPalette.hillFar)
                    .overlay(alignment: .top) {
                        Ellipse()
                            .stroke(GoobyActivityPalette.hillShine, lineWidth: 3)
                            .mask(alignment: .top) { Rectangle().frame(height: 10) }
                    }
                    .frame(width: width * 1.25, height: height * 0.9)
                    .position(x: width * 0.22, y: height * 1.0)
                Ellipse()
                    .fill(GoobyTokens.homeGreen)
                    .frame(width: width * 1.2, height: height * 0.75)
                    .position(x: width * 0.9, y: height * 1.06)
            }
        }
    }
}

/// Lock Screen wallpaper for the in-app preview.
struct GoobyActivityWallpaper: View {
    var body: some View {
        LinearGradient(colors: [GoobyActivityPalette.wallpaperTop, GoobyTokens.homeSky, GoobyActivityPalette.wallpaperBottom], startPoint: .top, endPoint: .bottom)
    }
}
