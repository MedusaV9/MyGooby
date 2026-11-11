import SwiftUI

struct ProfileEditSheet: View {
    var engine: GoobyEngine
    var calm: Bool
    var onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .menu
    @State private var detent: PresentationDetent = .height(380)
    @State private var nameDraft = ""
    @State private var humanDraft = ""
    @State private var chosenPronouns = ""
    @State private var outfitTick = 0

    private enum Step: Equatable {
        case menu, name, pronouns, human, outfit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Group {
                switch step {
                case .menu: menu
                case .name: nameEditor
                case .pronouns: pronounEditor
                case .human: humanEditor
                case .outfit: outfitEditor
                }
            }
            .id(stepToken)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            if step != .outfit {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background((step == .menu ? Color.white : ProfilePalette.page).ignoresSafeArea())
        .presentationDetents([.height(380), .large], selection: $detent)
        .presentationDragIndicator(.hidden)
        .animation(calm ? nil : .spring(response: 0.42, dampingFraction: 0.86), value: step)
        .sheetRise(calm: calm)
        .onAppear {
            nameDraft = engine.profile.goobyName
            humanDraft = engine.profile.nickname
            chosenPronouns = engine.pet.pronouns
        }
        .onChange(of: step) { _, next in
            detent = next == .menu ? .height(380) : .large
        }
        .presentationBackground(step == .menu ? Color.white : ProfilePalette.page)
    }

    private var header: some View {
        ZStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(ProfilePalette.brownSoft)
                .lineLimit(1)
                .padding(.horizontal, 44)
            HStack {
                Button(action: back) {
                    Group {
                        if step == .menu {
                            CloseCross()
                        } else {
                            ChevronGlyph()
                                .rotationEffect(.degrees(180))
                                .foregroundStyle(ProfilePalette.ink)
                        }
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(step == .menu ? engine.t("profile.close") : ProfileCopy.back(engine.languageCode))
                Spacer()
            }
        }
        .padding(.bottom, 8)
    }

    private var stepToken: String {
        switch step {
        case .menu: return "menu"
        case .name: return "name"
        case .pronouns: return "pronouns"
        case .human: return "human"
        case .outfit: return "outfit"
        }
    }

    private var title: String {
        switch step {
        case .menu: return ProfileCopy.editTitle(engine.languageCode)
        case .name: return ProfileCopy.changeName(engine.languageCode)
        case .pronouns: return ProfileCopy.changePronouns(engine.languageCode)
        case .human: return ProfileCopy.changeHuman(engine.languageCode)
        case .outfit: return ProfileCopy.changeOutfit(engine.languageCode)
        }
    }

    private var menu: some View {
        VStack(alignment: .leading, spacing: 6) {
            row(ProfileCopy.changeName(engine.languageCode)) { open(.name) }
            row(ProfileCopy.changePronouns(engine.languageCode)) { open(.pronouns) }
            row(ProfileCopy.changeHuman(engine.languageCode)) { open(.human) }
            row(ProfileCopy.changeOutfit(engine.languageCode)) { open(.outfit) }
        }
    }

    private func row(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var nameEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField(ProfileCopy.namePlaceholder(engine.languageCode), text: $nameDraft)
                .font(.system(.body, design: .rounded))
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Button(engine.t("profile.edit.save")) { saveName() }
                .buttonStyle(ProfileSaveStyle())
        }
        .padding(.top, 8)
    }

    private var humanEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField(ProfileCopy.humanPlaceholder(engine.languageCode), text: $humanDraft)
                .font(.system(.body, design: .rounded))
                .padding(12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Button(engine.t("profile.edit.save")) { saveHuman() }
                .buttonStyle(ProfileSaveStyle())
        }
        .padding(.top, 8)
    }

    private var pronounEditor: some View {
        let selected = PetPronounChoice.match(chosenPronouns)
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(PetPronounChoice.allCases) { choice in
                Button {
                    engine.setPetPronouns(choice.stored)
                    chosenPronouns = choice.stored
                    onChange()
                } label: {
                    HStack {
                        Text(choice.label(engine.languageCode))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Spacer()
                        if selected == choice {
                            CheckMark()
                        }
                    }
                    .foregroundStyle(ProfilePalette.ink)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private var outfitEditor: some View {
        let colors = wearables(color: true)
        let clothes = wearables(color: false)
        let saved = engine.all(SavedOutfit.self).sorted { $0.createdAt > $1.createdAt }
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: calm ? .sit : .breathe,
                    reduceMotion: calm,
                    companion: nil,
                    showCompanion: false
                )
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                if colors.isEmpty && clothes.isEmpty && saved.isEmpty {
                    Text(ProfileCopy.emptyCloset(engine.languageCode))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(ProfilePalette.brown)
                }
                outfitGroup(engine.t("bag.colors"), colors)
                outfitGroup(engine.t("bag.outfits"), clothes)
                if !saved.isEmpty {
                    Text(ProfileCopy.savedOutfits(engine.languageCode))
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(ProfilePalette.muted)
                        .textCase(.uppercase)
                    ForEach(saved) { outfit in
                        Button {
                            engine.apply(outfit: outfit)
                            outfitTick += 1
                            onChange()
                        } label: {
                            outfitRow(outfit.name, marked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .id(outfitTick)
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder private func outfitGroup(_ title: String, _ items: [ItemDef]) -> some View {
        if !items.isEmpty {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(ProfilePalette.muted)
                .textCase(.uppercase)
            ForEach(items) { item in
                Button {
                    engine.equip(item)
                    outfitTick += 1
                    onChange()
                } label: {
                    outfitRow(item.name.text(engine.languageCode), marked: worn(item))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func outfitRow(_ title: String, marked: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(ProfilePalette.ink)
                .lineLimit(1)
            Spacer()
            if marked { CheckMark() }
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func wearables(color: Bool) -> [ItemDef] {
        engine.all(OwnedItem.self).compactMap { row -> ItemDef? in
            guard let item = engine.catalog.itemsByID[row.catalogID] else { return nil }
            let isColor = item.kind == "color" || item.slot == "fur" || item.shop == "colors"
            let isCloth = item.kind == "clothing" || item.shop == "wardrobe"
            guard color ? isColor : (isCloth && !isColor) else { return nil }
            return item
        }
        .sorted { $0.name.text(engine.languageCode) < $1.name.text(engine.languageCode) }
    }

    private func worn(_ item: ItemDef) -> Bool {
        if item.kind == "color" || item.slot == "fur" { return engine.pet.furStyle == item.id }
        return engine.ownedRow(item.id)?.equippedSlot == item.slot
    }

    private func open(_ next: Step) {
        if next == .name { nameDraft = engine.profile.goobyName }
        if next == .human { humanDraft = engine.profile.nickname }
        step = next
    }

    private func back() {
        if step == .menu {
            dismiss()
        } else {
            step = .menu
        }
    }

    private func saveName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        engine.profile.goobyName = trimmed.isEmpty ? "Gooby" : String(trimmed.prefix(24))
        engine.save()
        onChange()
        step = .menu
    }

    private func saveHuman() {
        let trimmed = humanDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        engine.profile.nickname = String(trimmed.prefix(24))
        engine.save()
        onChange()
        step = .menu
    }
}

private struct CheckMark: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 2, y: 7))
            path.addLine(to: CGPoint(x: 6, y: 11))
            path.addLine(to: CGPoint(x: 14, y: 3))
        }
        .stroke(ProfilePalette.brown, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: 16, height: 14)
        .accessibilityHidden(true)
    }
}
