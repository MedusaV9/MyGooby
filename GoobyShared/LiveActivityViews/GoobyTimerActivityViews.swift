import SwiftUI

/// Lock Screen and banner presentation of the timer Live Activity. Plain views over the
/// attributes and the content state, so the app can preview them (ExtrasGallery) and the widget
/// extension can show them (GoobyWidgets/LiveActivity/GoobyTimerLiveActivity.swift).
/// Each kind wears the look of its screen: the adventure the Home dusk forest with the adventure
/// track, the focus timer a white card with the yellow progress bar, breathing the lavender calm
/// screen with the sky-blue bubble.
struct GoobyTimerLockView: View {
    var attributes: GoobyTimerAttributes
    var state: GoobyTimerAttributes.ContentState
    /// The stale date passed (the timer ran out while the app was closed).
    var isStale: Bool = false

    var body: some View {
        let look = GoobyActivityLook(attributes: attributes, state: state, isStale: isStale)
        Group {
            switch attributes.kind {
            case .adventure: GoobyAdventureLock(look: look)
            case .focus: GoobyFocusLock(look: look)
            case .breath: GoobyBreathLock(look: look)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// System background behind the view (`activityBackgroundTint`), the base color of each look.
    static func tint(_ kind: GoobyTimerAttributes.Kind) -> Color {
        switch kind {
        case .adventure: return GoobyTokens.homeSky
        case .focus: return GoobyTokens.white
        case .breath: return GoobyTokens.calm
        }
    }

    /// Color of system buttons on the activity (`activitySystemActionForegroundColor`).
    static func actionInk(_ kind: GoobyTimerAttributes.Kind) -> Color {
        kind == .adventure ? .white : GoobyTokens.text
    }
}

// MARK: - Adventure

/// Gooby's head, "Gooby is on an adventure", place and return time, the count-down, and the
/// Home adventure track (lightning circle, bar, "?" circle) on a translucent card.
private struct GoobyAdventureLock: View {
    var look: GoobyActivityLook

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                GoobyMiniHead(fur: look.attributes.fur, stage: look.attributes.stage, face: look.face)
                    .frame(width: 46, height: 46)
                    .background(alignment: .bottom) {
                        Ellipse()
                            .fill(Color.black.opacity(0.14))
                            .frame(width: 34, height: 7)
                            .offset(y: 4)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(look.title)
                        .font(GoobyTokens.Fonts.rounded(17))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if !look.subline.isEmpty {
                        Text(look.subline)
                            .font(GoobyTokens.Fonts.rounded(13, .bold))
                            .foregroundStyle(Color.white.opacity(0.88))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                Spacer(minLength: 6)
                if look.done {
                    GoobyActivityPill(text: look.text(de: "Lesen", en: "Read"), ink: GoobyActivityPalette.leafDark)
                } else {
                    GoobyTimerText(state: look.state)
                        .font(GoobyTokens.Fonts.rounded(26))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                        .frame(width: GoobyTimerText.width(look.state, size: 26), alignment: .trailing)
                }
            }
            HStack(spacing: 8) {
                GoobyActivityBolt(size: 26)
                GoobyActivityBar(look: look, tint: GoobyTokens.progressFill)
                GoobyActivityGoal(symbol: look.done ? "exclamationmark" : "questionmark", size: 26)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(14)
        .background(GoobyActivityDusk())
    }
}

// MARK: - Focus

/// White card: Gooby on a lavender tile, title and line, the big count-down with the planned
/// length under it, and the yellow progress bar. Paused: the clock stands still in grey.
private struct GoobyFocusLock: View {
    var look: GoobyActivityLook

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                GoobyActivityTile(look: look, size: 50, fill: GoobyTokens.calm, edge: GoobyActivityPalette.calmEdge)
                VStack(alignment: .leading, spacing: 2) {
                    Text(look.title)
                        .font(GoobyTokens.Fonts.rounded(17))
                        .foregroundStyle(GoobyTokens.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if !look.detail.isEmpty {
                        Text(look.detail)
                            .font(GoobyTokens.Fonts.rounded(13, .bold))
                            .foregroundStyle(GoobyTokens.greyText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                Spacer(minLength: 6)
                if look.done {
                    GoobyActivityBadge.done(look, size: 38)
                } else {
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack(spacing: 4) {
                            if look.paused {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 14, weight: .black))
                            }
                            GoobyTimerText(state: look.state)
                                .font(GoobyTokens.Fonts.rounded(28))
                                .multilineTextAlignment(.trailing)
                                .frame(width: GoobyTimerText.width(look.state, size: 28), alignment: .trailing)
                        }
                        .foregroundStyle(look.paused ? GoobyTokens.greyText : GoobyTokens.text)
                        if !look.note.isEmpty {
                            Text(look.note)
                                .font(GoobyTokens.Fonts.rounded(12, .bold))
                                .foregroundStyle(GoobyTokens.greyText)
                                .lineLimit(1)
                        }
                    }
                }
            }
            GoobyActivityBar(look: look, tint: look.paused ? GoobyTokens.capsGrey : GoobyTokens.progressFill)
        }
        .padding(16)
        .background(GoobyTokens.white)
    }
}

// MARK: - Breathing

/// Lavender calm card: Gooby resting in the sky-blue bubble, pattern name and line, the time
/// breathed so far, and the pattern as pills.
private struct GoobyBreathLock: View {
    var look: GoobyActivityLook

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                GoobyBreathBubble(look: look, size: 58)
                VStack(alignment: .leading, spacing: 2) {
                    Text(look.title)
                        .font(GoobyTokens.Fonts.rounded(17))
                        .foregroundStyle(GoobyTokens.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if !look.subline.isEmpty {
                        Text(look.subline)
                            .font(GoobyTokens.Fonts.rounded(13, .bold))
                            .foregroundStyle(GoobyActivityPalette.calmInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                Spacer(minLength: 6)
                if look.done {
                    GoobyActivityBadge.done(look, size: 38)
                } else {
                    GoobyTimerText(state: look.state)
                        .font(GoobyTokens.Fonts.rounded(26))
                        .foregroundStyle(GoobyTokens.text)
                        .multilineTextAlignment(.trailing)
                        .frame(width: GoobyTimerText.width(look.state, size: 26), alignment: .trailing)
                }
            }
            if !look.done && !look.steps.isEmpty {
                GoobyBreathChips(look: look)
            }
        }
        .padding(14)
        .background(GoobyTokens.calm)
    }
}
