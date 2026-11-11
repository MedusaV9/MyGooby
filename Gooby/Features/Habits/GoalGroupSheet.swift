import SwiftUI

struct GoalGroupSheet: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    @Environment(\.dismiss) private var dismiss
    @State private var tick = 0

    var body: some View {
        let _ = tick
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(GoalLook.ink.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: 0xF2F2F4), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("common.close"))
                Spacer()
                Text(engine.t("care.group.title"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.ink.opacity(0.8))
                Spacer()
                Color.clear.frame(width: 32, height: 32)
            }
            HStack(spacing: 10) {
                tile("time", system: "clock", title: engine.t("care.daypart"))
                tile("area", system: "square.grid.2x2", title: engine.t("care.area"))
                tile("custom", system: "signpost.right", title: engine.t("care.group.custom"))
            }
            Toggle(isOn: expandBinding) {
                Text(engine.t("care.group.expand"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
            }
            .tint(GoalLook.button)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(hex: 0xF6F6F8), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer(minLength: 0)
        }
        .padding(18)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    private var expandBinding: Binding<Bool> {
        Binding(
            get: { store.meta.expandSections },
            set: { value in
                store.update { $0.expandSections = value }
                tick += 1
            }
        )
    }

    private func tile(_ id: String, system: String, title: String) -> some View {
        let on = store.meta.groupMode == id
        return Button {
            store.update { $0.groupMode = id }
            tick += 1
            engine.haptics.soft()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: system)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(GoalLook.ink)
                    .frame(height: 28)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(on ? GoalLook.button : Color(hex: 0xE6E6EA), lineWidth: on ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
