import SwiftUI

struct GoalBunny: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0xF6E7C1))
                .frame(width: 16, height: 34)
                .rotationEffect(.degrees(-16))
                .offset(x: -14, y: -30)
            Capsule()
                .fill(Color(hex: 0xF6E7C1))
                .frame(width: 16, height: 34)
                .rotationEffect(.degrees(16))
                .offset(x: 14, y: -30)
            Capsule()
                .fill(Color(hex: 0xF4B6C2))
                .frame(width: 7, height: 18)
                .rotationEffect(.degrees(-16))
                .offset(x: -14, y: -28)
            Capsule()
                .fill(Color(hex: 0xF4B6C2))
                .frame(width: 7, height: 18)
                .rotationEffect(.degrees(16))
                .offset(x: 14, y: -28)
            Circle()
                .fill(Color(hex: 0xF6E7C1))
                .frame(width: 62, height: 62)
            Circle().fill(Color(hex: 0x3A342E)).frame(width: 5, height: 5).offset(x: -10, y: -2)
            Circle().fill(Color(hex: 0x3A342E)).frame(width: 5, height: 5).offset(x: 10, y: -2)
            Capsule().fill(Color(hex: 0xE7A0A8)).frame(width: 10, height: 5).offset(y: 10)
        }
        .accessibilityHidden(true)
    }
}

struct GoalWindowScene: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: 0xB7E6DC))
            HStack(spacing: 0) {
                curtain.frame(width: 28)
                Spacer(minLength: 0)
                curtain.frame(width: 28)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: 0xF4FBFF))
                .frame(width: 128, height: 86)
                .offset(y: -22)
            Path { path in
                path.move(to: CGPoint(x: 64, y: 6))
                path.addLine(to: CGPoint(x: 64, y: 80))
                path.move(to: CGPoint(x: 6, y: 42))
                path.addLine(to: CGPoint(x: 122, y: 42))
            }
            .stroke(Color(hex: 0x9BB8C9), lineWidth: 3)
            .frame(width: 128, height: 86)
            .offset(y: -22)
            Capsule().fill(Color(hex: 0xE7F6F1)).frame(height: 18).offset(y: 36)
            plant(leaf: 0x3E8F45, pot: 0xE07A9A).offset(x: -78, y: 28)
            plant(leaf: 0x7BC96A, pot: 0xF0A0B0).offset(x: 78, y: 34)
            plant(leaf: 0x2F8A40, pot: 0xC47A4A).scaleEffect(0.72).offset(y: 42)
            GoalBunny()
                .frame(width: 78, height: 86)
                .offset(y: 18)
            Capsule()
                .fill(Color(hex: 0xE6C07A))
                .frame(width: 54, height: 14)
                .offset(y: -8)
            Capsule()
                .fill(Color(hex: 0xC9843A))
                .frame(width: 22, height: 8)
                .offset(y: -2)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: 0x8EC8F5))
                .frame(width: 16, height: 10)
                .rotationEffect(.degrees(-28))
                .offset(x: 28, y: 8)
        }
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityHidden(true)
    }

    private var curtain: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(hex: 0x8FD0C4))
    }

    private func plant(leaf: UInt32, pot: UInt32) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Ellipse().fill(Color(hex: leaf)).frame(width: 28, height: 16).offset(x: -6, y: 4)
                Ellipse().fill(Color(hex: leaf)).frame(width: 28, height: 16).offset(x: 6, y: 4)
                Ellipse().fill(Color(hex: leaf)).frame(width: 16, height: 22)
            }
            .frame(height: 28)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: pot))
                .frame(width: 22, height: 14)
        }
    }
}

struct GoalAreaScene: View {
    var glyph: String
    var areaID: String = ""

    var body: some View {
        AreaCast(areaID: areaID.isEmpty ? glyph : areaID, glyph: glyph)
            .accessibilityHidden(true)
    }
}

private struct AreaCast: View {
    var areaID: String
    var glyph: String

    var body: some View {
        ZStack {
            switch areaID {
            case "productivity", "timer":
                propBroom
                GoalBunny().offset(x: 8, y: 8)
                Capsule().fill(Color(hex: 0xF6E27A)).frame(width: 36, height: 12).offset(x: 8, y: -18)
            case "movement", "giraffe":
                GoalBunny().offset(y: 6)
                Capsule().fill(Color(hex: 0x3E8F45)).frame(width: 34, height: 16).offset(y: 16)
                Circle().stroke(Color.black, lineWidth: 2).background(Circle().fill(Color.white)).frame(width: 22, height: 22).offset(x: 28, y: 4)
            case "kindness", "smile":
                heart(0xE23B3B).offset(x: -6, y: 10)
                GoalBunny().offset(x: 10, y: 4)
            case "gratitude", "star":
                GoalBunny().offset(y: 8)
                heart(0xE23B3B).scaleEffect(0.45).offset(x: 34, y: -16)
            case "hygiene", "shower":
                GoalBunny().offset(x: 12, y: 6)
                toothbrush.offset(x: -24, y: 4)
            case "connection", "people":
                GoalBunny().offset(x: -8, y: 8)
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xE23B3B)).frame(width: 16, height: 10).offset(x: 22, y: 12)
                Circle().fill(Color.white.opacity(0.85)).frame(width: 28, height: 28).offset(x: 30, y: -8)
                GoalBunny().scaleEffect(0.35).offset(x: 30, y: -8)
            case "calm", "leaf":
                GoalBunny().offset(y: 8)
                Ellipse().fill(Color(hex: 0x3E8F45)).frame(width: 22, height: 12).rotationEffect(.degrees(-30)).offset(x: 28, y: -6)
            case "sleep", "bed":
                GoalBunny().offset(y: 10)
                Text("z").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Color.white).offset(x: 26, y: -20)
            case "nutrition", "tea":
                GoalBunny().offset(x: -8, y: 6)
                RoundedRectangle(cornerRadius: 4).fill(Color.white).frame(width: 18, height: 14).offset(x: 26, y: 12)
            default:
                GoalBunny()
                GoalGlyph(glyph: glyph, showsPlate: false)
                    .frame(width: 36, height: 36)
                    .offset(x: 24, y: 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 8)
    }

    private var propBroom: some View {
        VStack(spacing: 0) {
            Circle().fill(Color.white.opacity(0.9)).frame(width: 18, height: 18)
            Capsule().fill(Color(hex: 0xC9843A)).frame(width: 4, height: 28)
        }
        .offset(x: -28, y: 4)
    }

    private var toothbrush: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2).fill(Color.white).frame(width: 16, height: 8)
            Capsule().fill(Color(hex: 0x4AA3F0)).frame(width: 5, height: 28)
        }
        .rotationEffect(.degrees(-18))
    }

    private func heart(_ hex: UInt32) -> some View {
        ZStack {
            Circle().fill(Color(hex: hex)).frame(width: 16, height: 16).offset(x: -6)
            Circle().fill(Color(hex: hex)).frame(width: 16, height: 16).offset(x: 6)
            Rectangle().fill(Color(hex: hex)).frame(width: 18, height: 16).offset(y: 6)
        }
        .frame(width: 28, height: 26)
    }
}

struct GoalAreaGrid: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var allowsNone: Bool = false
    var onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var naming = false
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if allowsNone {
                        Button {
                            onPick("")
                            dismiss()
                        } label: {
                            Text(engine.t("care.area.none"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(GoalLook.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(hex: 0xF4F4F6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(GoalCatalog.areas) { area in
                            Button {
                                onPick(area.id)
                                dismiss()
                            } label: {
                                tile(name: area.name(engine.languageCode), glyph: area.glyph, tint: GoalActions.tint(for: area.id, store: store), areaID: area.id)
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(store.meta.customAreas) { area in
                            Button {
                                onPick(area.id)
                                dismiss()
                            } label: {
                                tile(name: area.name, glyph: area.glyph, tint: area.tint, areaID: area.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack(spacing: 12) {
                        Rectangle().fill(Color(hex: 0xE4E4E8)).frame(height: 1)
                        Text(engine.t("care.areas.or"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(GoalLook.subtitle)
                        Rectangle().fill(Color(hex: 0xE4E4E8)).frame(height: 1)
                    }
                    .padding(.top, 4)
                    Button {
                        draft = ""
                        naming = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(GoalLook.subtitle)
                                .frame(width: 36, height: 36)
                                .background(Color(hex: 0xF0F0F2), in: Circle())
                            Text(engine.t("care.areas.own"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(GoalLook.ink)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 64)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: 0xE4E4E8), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(Color.white)
            .navigationTitle(engine.t("care.areas.pick"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(engine.t("common.close")) { dismiss() }
                }
            }
        }
        .alert(engine.t("care.areas.own"), isPresented: $naming) {
            TextField(engine.t("care.areas.placeholder"), text: $draft)
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("care.areas.create")) {
                if let area = GoalActions.createArea(name: draft, store: store) {
                    onPick(area.id)
                    dismiss()
                }
            }
        } message: {
            Text(engine.t("care.areas.ask"))
        }
    }

    private func tile(name: String, glyph: String, tint: UInt32, areaID: String) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: tint))
            Text(name)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 1, y: 1)
                .padding(12)
                .lineLimit(2)
            GoalAreaScene(glyph: glyph, areaID: areaID)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 6)
        }
        .frame(height: 168)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
    }
}
