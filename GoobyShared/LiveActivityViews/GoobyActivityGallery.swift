import ActivityKit
import SwiftUI

/// One example activity for the in-app preview.
struct GoobyActivitySample: Identifiable {
    var id: String
    var attributes: GoobyTimerAttributes
    var state: GoobyTimerAttributes.ContentState
    var isStale: Bool = false

    var look: GoobyActivityLook { GoobyActivityLook(attributes: attributes, state: state, isStale: isStale) }
}

/// In-app preview of the Live Activities (ExtrasGallery, `widgets` screenshot route): every
/// sample as a Lock Screen banner on a wallpaper, then as compact and expanded Dynamic Island on
/// black stand-ins. Same views as the widget extension; the timers run live here too.
struct GoobyActivityGallery: View {
    var samples: [GoobyActivitySample]

    private var language: String? { samples.first?.attributes.language }

    private func text(de: String, en: String) -> String {
        GoobyText.pick(language, de: de, en: en)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            caption(text(de: "Sperrbildschirm", en: "Lock Screen"))
            VStack(spacing: 10) {
                ForEach(samples) { sample in
                    GoobyTimerLockView(attributes: sample.attributes, state: sample.state, isStale: sample.isStale)
                        .frame(maxWidth: .infinity)
                        .background(GoobyTimerLockView.tint(sample.attributes.kind))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .padding(10)
            .background(GoobyActivityWallpaper())
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            caption(text(de: "Dynamic Island", en: "Dynamic Island"))
            VStack(spacing: 10) {
                ForEach(samples) { sample in
                    compact(sample.look)
                }
                ForEach(samples) { sample in
                    expanded(sample.look)
                }
            }
            .frame(maxWidth: .infinity)
            Text(note)
                .font(GoobyTokens.Fonts.caption)
                .foregroundStyle(GoobyTokens.greyText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }

    private var note: String {
        if !ActivityAuthorizationInfo().areActivitiesEnabled {
            return text(
                de: "Live-Aktivitäten sind für Gooby in den iOS-Einstellungen ausgeschaltet. Schalte sie dort unter Gooby wieder ein.",
                en: "Live Activities are turned off for Gooby in the iOS Settings. Turn them back on under Gooby there."
            )
        }
        return text(
            de: "Gooby zeigt Live-Aktivitäten bei Abenteuern, beim Fokus-Timer und bei Atemübungen, ganz ohne Internet. Ein- und ausschalten unter Einstellungen › Vorlieben.",
            en: "Gooby shows Live Activities for adventures, the focus timer and breathing, all offline. Switch them on or off in Settings › Preferences."
        )
    }

    private func caption(_ value: String) -> some View {
        Text(value.uppercased())
            .font(GoobyTokens.Fonts.caps)
            .tracking(1.2)
            .foregroundStyle(GoobyTokens.capsGrey)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    /// Compact island: head left of the camera, clock right of it.
    private func compact(_ look: GoobyActivityLook) -> some View {
        HStack(spacing: 0) {
            GoobyIslandCompactLeading(look: look)
            Spacer(minLength: 0)
            GoobyIslandCompactTrailing(look: look)
        }
        .padding(.horizontal, 9)
        .frame(width: 250, height: 37)
        .background(Color.black, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(look.spoken)
    }

    /// Expanded island (long press): leading, center, trailing and bottom regions.
    private func expanded(_ look: GoobyActivityLook) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                GoobyIslandLeading(look: look)
                GoobyIslandCenter(look: look)
                GoobyIslandTrailing(look: look)
            }
            GoobyIslandBottom(look: look)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 42, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(look.spoken)
    }
}
