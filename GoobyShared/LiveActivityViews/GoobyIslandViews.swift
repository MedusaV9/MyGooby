import SwiftUI

// Dynamic Island regions of the timer Live Activity. The widget extension places them in the
// DynamicIsland regions (GoobyTimerLiveActivity); GoobyActivityGallery draws the same views on
// black stand-ins for the in-app preview. The island is always black: white type, yellow timers,
// sky blue for breathing.

/// Expanded, left of the camera: Gooby on a disc in the color of the activity's screen.
struct GoobyIslandLeading: View {
    var look: GoobyActivityLook

    var body: some View {
        switch look.kind {
        case .adventure:
            GoobyActivityDisc(look: look, size: 50, fill: GoobyTokens.homeGreen)
        case .focus:
            GoobyActivityDisc(look: look, size: 50, fill: GoobyTokens.calm)
        case .breath:
            GoobyBreathBubble(look: look, size: 54)
        }
    }
}

/// Expanded, right of the camera: the clock, or a badge once done.
struct GoobyIslandTrailing: View {
    var look: GoobyActivityLook

    var body: some View {
        if look.done {
            GoobyActivityBadge.done(look, size: 38)
        } else {
            HStack(spacing: 4) {
                if look.paused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 13, weight: .black))
                }
                GoobyTimerText(state: look.state)
                    .font(GoobyTokens.Fonts.rounded(26))
                    .multilineTextAlignment(.trailing)
                    .frame(width: GoobyTimerText.width(look.state, size: 26), alignment: .trailing)
            }
            .foregroundStyle(look.paused ? Color.white.opacity(0.55) : look.accent)
        }
    }
}

/// Expanded, under the camera: title and line.
struct GoobyIslandCenter: View {
    var look: GoobyActivityLook

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(look.title)
                .font(GoobyTokens.Fonts.rounded(16))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if !look.subline.isEmpty {
                Text(look.subline)
                    .font(GoobyTokens.Fonts.rounded(12, .bold))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Expanded, bottom: the adventure track, the focus bar, or the breathing pattern.
struct GoobyIslandBottom: View {
    var look: GoobyActivityLook

    var body: some View {
        switch look.kind {
        case .adventure:
            HStack(spacing: 8) {
                GoobyActivityBolt(size: 22)
                GoobyActivityBar(look: look, tint: look.accent)
                GoobyActivityGoal(symbol: look.done ? "exclamationmark" : "questionmark", size: 22)
            }
            .padding(.horizontal, 4)
        case .focus:
            GoobyActivityBar(look: look, tint: look.paused ? Color.white.opacity(0.45) : look.accent)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
        case .breath:
            if look.done || look.steps.isEmpty {
                EmptyView()
            } else {
                GoobyBreathChips(look: look, dark: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// Compact, left of the camera: Gooby's head.
struct GoobyIslandCompactLeading: View {
    var look: GoobyActivityLook

    var body: some View {
        GoobyMiniHead(fur: look.attributes.fur, stage: look.attributes.stage, face: look.face)
            .frame(width: 24, height: 24)
            .padding(.leading, 2)
    }
}

/// Compact, right of the camera: the clock, a still clock with a pause sign, or a done sign.
struct GoobyIslandCompactTrailing: View {
    var look: GoobyActivityLook

    var body: some View {
        if look.done {
            Image(systemName: look.kind == .adventure ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(look.kind == .adventure ? GoobyActivityPalette.goal : GoobyTokens.checkGreen)
                .padding(.trailing, 2)
        } else if look.paused {
            HStack(spacing: 2) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 9, weight: .black))
                GoobyTimerText(state: look.state)
                    .font(GoobyTokens.Fonts.rounded(14))
            }
            .foregroundStyle(Color.white.opacity(0.6))
        } else {
            GoobyTimerText(state: look.state)
                .font(GoobyTokens.Fonts.rounded(14))
                .foregroundStyle(look.accent)
                .multilineTextAlignment(.trailing)
                .frame(width: GoobyTimerText.width(look.state, size: 14), alignment: .trailing)
        }
    }
}

/// Minimal (two activities at once): Gooby's head on a small disc in the accent color.
struct GoobyIslandMinimal: View {
    var look: GoobyActivityLook

    var body: some View {
        GoobyMiniHead(fur: look.attributes.fur, stage: look.attributes.stage, face: look.face)
            .padding(2)
            .frame(width: 24, height: 24)
            .background(Circle().stroke(look.done ? GoobyTokens.checkGreen : look.accent, lineWidth: 2))
    }
}
