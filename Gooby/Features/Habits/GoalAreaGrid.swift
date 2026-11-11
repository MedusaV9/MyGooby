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
                .fill(Color(hex: 0xB7E3D4))
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: 0xF7FBFF))
                .frame(width: 132, height: 92)
                .offset(y: -16)
            Path { path in
                path.move(to: CGPoint(x: 66, y: 8))
                path.addLine(to: CGPoint(x: 66, y: 84))
                path.move(to: CGPoint(x: 8, y: 46))
                path.addLine(to: CGPoint(x: 124, y: 46))
            }
            .stroke(Color(hex: 0x9BB8C9), lineWidth: 3)
            .frame(width: 132, height: 92)
            .offset(y: -16)
            Capsule().fill(Color(hex: 0x7EBF8A)).frame(width: 28, height: 36).offset(x: -78, y: 28)
            Capsule().fill(Color(hex: 0x5C9A68)).frame(width: 18, height: 22).offset(x: -78, y: 18)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xC47A4A)).frame(width: 22, height: 14).offset(x: -78, y: 48)
            Capsule().fill(Color(hex: 0x8FCB74)).frame(width: 24, height: 30).offset(x: 78, y: 30)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xC47A4A)).frame(width: 20, height: 12).offset(x: 78, y: 48)
            GoalBunny()
                .frame(width: 86, height: 96)
                .offset(y: 36)
        }
        .frame(height: 188)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityHidden(true)
    }
}

struct GoalAreaScene: View {
    var glyph: String

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GoalBunny()
                .frame(width: 92, height: 108)
            GoalGlyph(glyph: glyph, showsPlate: false)
                .frame(width: 42, height: 42)
                .offset(x: 8, y: 6)
        }
        .accessibilityHidden(true)
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
                                tile(name: area.name(engine.languageCode), glyph: area.glyph, tint: area.tint)
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(store.meta.customAreas) { area in
                            Button {
                                onPick(area.id)
                                dismiss()
                            } label: {
                                tile(name: area.name, glyph: area.glyph, tint: area.tint)
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

    private func tile(name: String, glyph: String, tint: UInt32) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: tint))
            Text(name)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 1, y: 1)
                .padding(12)
                .lineLimit(2)
            GoalAreaScene(glyph: glyph)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 6)
        }
        .frame(height: 168)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
    }
}
