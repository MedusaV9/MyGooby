import SwiftUI

struct FeedbackSettingsCard: View {
    var engine: GoobyEngine
    private var feedback: GoobyFeedback { GoobyFeedback.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LookCard {
                VStack(spacing: 0) {
                    row(engine.t("feedback.sounds"), engine.t("feedback.sounds.sub"), isOn: Binding(get: { feedback.soundsOn }, set: { feedback.soundsOn = $0 }))
                    LookDivider()
                    row(engine.t("feedback.haptics"), engine.t("feedback.haptics.sub"), isOn: Binding(get: { feedback.hapticsOn }, set: { feedback.hapticsOn = $0 }))
                }
            }
            Text(engine.t("feedback.note"))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Look.sub)
                .padding(.horizontal, 16)
        }
    }

    private func row(_ title: String, _ subtitle: String, isOn: Binding<Bool>) -> some View {
        LookNavRow(title: title, subtitle: subtitle, showsChevron: false)
            .padding(.trailing, 58)
            .overlay(alignment: .trailing) {
                LookSwitch(isOn: isOn, label: title)
                    .padding(.trailing, 14)
            }
    }
}

struct FeedbackAuditionList: View {
    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(GoobyCue.allCases, id: \.self) { cue in
                Button(cue.rawValue) { GoobyFeedback.play(cue) }
                    .buttonStyle(.bordered)
                    .font(.system(.caption, design: .rounded))
            }
            Button("breathe") { GoobyFeedback.shared.breathe(rising: true, seconds: 4) }
                .buttonStyle(.bordered)
                .font(.system(.caption, design: .rounded))
        }
    }
}
