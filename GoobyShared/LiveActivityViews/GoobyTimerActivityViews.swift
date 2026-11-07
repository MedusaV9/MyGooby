import SwiftUI

/// Lock Screen and banner presentation of the timer Live Activity. Plain views over the
/// attributes and the content state, so the app can preview them (ExtrasGallery) and the widget
/// extension can show them (GoobyWidgets/LiveActivity/GoobyTimerLiveActivity.swift).
struct GoobyTimerLockView: View {
    var attributes: GoobyTimerAttributes
    var state: GoobyTimerAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            GoobyMiniHead(fur: attributes.fur, stage: attributes.stage, face: state.phase == "done" ? .happy : .smile)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(GoobyTokens.Fonts.rounded(16))
                    .foregroundStyle(GoobyTokens.text)
                    .lineLimit(1)
                if !state.detail.isEmpty {
                    Text(state.detail)
                        .font(GoobyTokens.Fonts.rounded(13, .bold))
                        .foregroundStyle(GoobyTokens.greyText)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            GoobyTimerText(state: state)
                .font(GoobyTokens.Fonts.rounded(24))
                .foregroundStyle(GoobyTokens.text)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 96, alignment: .trailing)
        }
        .padding(16)
    }
}

/// Count-down of the timer, a fixed "m:ss" while paused, a check when done.
struct GoobyTimerText: View {
    var state: GoobyTimerAttributes.ContentState

    var body: some View {
        if let left = state.pausedRemaining {
            Text(verbatim: String(format: "%d:%02d", max(0, left) / 60, max(0, left) % 60))
                .monospacedDigit()
        } else if state.phase == "done" {
            Text(verbatim: "✓")
        } else {
            Text(timerInterval: state.interval, countsDown: true)
                .monospacedDigit()
        }
    }
}

/// One example activity for the in-app preview.
struct GoobyActivitySample: Identifiable {
    var id: String
    var attributes: GoobyTimerAttributes
    var state: GoobyTimerAttributes.ContentState
}

/// In-app preview of the Live Activity: the Lock Screen banner and a compact Dynamic Island
/// stand-in for every sample.
struct GoobyActivityGallery: View {
    var samples: [GoobyActivitySample]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(samples) { sample in
                GoobyTimerLockView(attributes: sample.attributes, state: sample.state)
                    .frame(maxWidth: .infinity)
                    .background(GoobyTokens.cream, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
                HStack(spacing: 8) {
                    GoobyMiniHead(fur: sample.attributes.fur, stage: sample.attributes.stage)
                        .frame(width: 24, height: 24)
                    Spacer(minLength: 40)
                    GoobyTimerText(state: sample.state)
                        .font(GoobyTokens.Fonts.rounded(14))
                        .foregroundStyle(GoobyTokens.progressFill)
                        .frame(maxWidth: 56, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .frame(width: 236, height: 36)
                .background(Color.black, in: Capsule())
                .frame(maxWidth: .infinity)
            }
        }
    }
}
