import SwiftUI

struct GoalGroupSheet: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(GoalGrouping.modeKey) private var grouping = "time"
    @AppStorage(GoalGrouping.expandKey) private var expandSections = true

    var body: some View {
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
                tile("time", title: engine.t("care.daypart")) { GroupClock() }
                tile("area", title: engine.t("care.area")) { AreaCluster() }
                tile("custom", title: engine.t("care.group.custom")) { GroupSignpost() }
            }
            Toggle(isOn: expandBinding) {
                Text(engine.t("care.group.expand"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .tint(Color(hex: 0x3CC85A))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(hex: 0xF6F6F8), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer(minLength: 0)
        }
        .padding(18)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .presentationBackground(Color.white)
    }

    private var expandBinding: Binding<Bool> {
        Binding(
            get: { expandSections },
            set: { value in
                expandSections = value
                store.update { $0.expandSections = value }
            }
        )
    }

    private func tile<Icon: View>(_ id: String, title: String, @ViewBuilder icon: () -> Icon) -> some View {
        let on = GoalGrouping.normalized(grouping) == id
        return Button {
            let mode = GoalGrouping.normalized(id)
            grouping = mode
            store.update { $0.groupMode = mode }
            engine.haptics.soft()
        } label: {
            VStack(spacing: 8) {
                icon()
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
                    .stroke(on ? Color(hex: 0x3CC85A) : Color(hex: 0xE6E6EA), lineWidth: on ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

private struct GroupClock: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(GoalLook.ink, lineWidth: 2.2)
                .frame(width: 26, height: 26)
            hand(color: GoalLook.ink, length: 8, angle: -18)
            hand(color: Color(hex: 0xE25B4A), length: 10, angle: 52)
            Circle()
                .fill(GoalLook.ink)
                .frame(width: 4, height: 4)
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    }

    private func hand(color: Color, length: CGFloat, angle: Double) -> some View {
        Capsule()
            .fill(color)
            .frame(width: 2.2, height: length)
            .offset(y: -length / 2)
            .frame(width: 26, height: 26)
            .rotationEffect(.degrees(angle))
    }
}

private struct GroupSignpost: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0xC9A36A))
                .frame(width: 4, height: 28)
            GroupArrow()
                .fill(Color(hex: 0x3EAE45))
                .frame(width: 20, height: 9)
                .offset(x: -5, y: -6)
            GroupArrow()
                .fill(Color(hex: 0xE25B4A))
                .frame(width: 20, height: 9)
                .scaleEffect(x: -1, y: 1)
                .offset(x: 5, y: 6)
        }
        .frame(width: 32, height: 28)
        .accessibilityHidden(true)
    }
}

private struct GroupArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let head = rect.width * 0.42
        let inset = rect.height * 0.22
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + head, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + head, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.minX + head, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.minX + head, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct AreaCluster: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x4AA3F0)).frame(width: 10, height: 10).offset(x: -8, y: -6)
            Circle().fill(Color(hex: 0xF08A3A)).frame(width: 10, height: 10).offset(x: 8, y: -6)
            Circle().fill(Color(hex: 0xE56BB8)).frame(width: 10, height: 10).offset(x: -8, y: 7)
            Image(systemName: "star.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: 0xF6C14A))
                .offset(x: 8, y: 7)
        }
        .frame(width: 32, height: 28)
        .accessibilityHidden(true)
    }
}
