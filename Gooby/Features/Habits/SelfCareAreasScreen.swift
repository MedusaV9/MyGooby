import SwiftUI

struct SelfCareAreasScreen: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var onChange: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showCreate = false
    @State private var draft = ""
    @State private var tick = 0

    var body: some View {
        let _ = tick
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(engine.t("care.areas.lead"))
                    .font(GoalFont.body)
                    .foregroundStyle(GoalLook.ink.opacity(0.72))
                ForEach(orderedAreas, id: \.id) { area in
                    NavigationLink {
                        AreaIdeasScreen(engine: engine, store: store, areaID: area.id, onChange: {
                            tick += 1
                            onChange()
                        })
                    } label: {
                        areaCard(area)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    draft = ""
                    showCreate = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text(engine.t("care.areas.new"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(GoalLook.button, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(20)
        }
        .background(GoalLook.paper.ignoresSafeArea())
        .navigationTitle(engine.t("care.areas"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(GoalLook.paper, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(GoalLook.ink)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(engine.t("care.areas.new"), isPresented: $showCreate) {
            TextField(engine.t("care.areas.placeholder"), text: $draft)
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("care.areas.create")) {
                if GoalActions.createArea(name: draft, store: store) != nil {
                    tick += 1
                    onChange()
                }
            }
        } message: {
            Text(engine.t("care.areas.ask"))
        }
    }

    private var orderedAreas: [AreaRow] {
        var rows = GoalCatalog.areas.map { AreaRow(id: $0.id, name: $0.name(engine.languageCode), blurb: $0.blurb(engine.languageCode), glyph: $0.glyph, tint: $0.tint, custom: false) }
        rows += store.meta.customAreas.map { AreaRow(id: $0.id, name: $0.name, blurb: engine.t("care.areas.custom"), glyph: $0.glyph, tint: $0.tint, custom: true) }
        let focus = store.meta.focused
        return rows.enumerated().sorted { lhs, rhs in
            let left = focus.contains(lhs.element.id)
            let right = focus.contains(rhs.element.id)
            if left != right { return left && !right }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func areaCard(_ area: AreaRow) -> some View {
        let goals = engine.habits().filter { !$0.isArchived && $0.category == area.id }
        let due = goals.filter { engine.isDue($0, on: engine.now()) && !$0.isPaused }
        let done = due.filter { habit in
            (engine.habitLog(habit.id, engine.dayKey())?.count ?? 0) >= max(1, habit.timesPerDay)
        }.count
        let ideas = GoalCatalog.suggestions(in: area.id).count
        let focused = store.meta.focused.contains(area.id)
        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: area.tint))
                GoalGlyph(glyph: area.glyph, showsPlate: false).padding(6)
            }
            .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(area.name)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(GoalLook.ink)
                    if focused {
                        Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(Color(hex: 0xE2B43A))
                    }
                }
                Text(area.blurb)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(GoalLook.subtitle)
                    .multilineTextAlignment(.leading)
                Text(ideas > 0 ? engine.tf("care.ideas.count", ideas) + " · " + engine.tf("care.today", done, due.count) : engine.tf("care.today", done, due.count))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(GoalLook.ink.opacity(0.55))
                if !due.isEmpty && done == due.count {
                    Text(engine.t("care.completeArea"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(GoalLook.check)
                }
            }
            Spacer(minLength: 4)
            VStack(spacing: 10) {
                Button {
                    GoalActions.toggleFocus(area.id, store: store)
                    tick += 1
                } label: {
                    Image(systemName: focused ? "star.fill" : "star")
                        .foregroundStyle(Color(hex: 0xE2B43A))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t(focused ? "care.focus.on" : "care.focus"))
                if area.custom {
                    Button(role: .destructive) {
                        GoalActions.deleteArea(area.id, engine: engine, store: store)
                        tick += 1
                        onChange()
                    } label: {
                        Image(systemName: "trash").foregroundStyle(Color(hex: 0xC45B5B))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.t("common.delete"))
                }
                Image(systemName: "chevron.right").foregroundStyle(GoalLook.subtitle)
            }
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct AreaRow: Identifiable {
    var id: String
    var name: String
    var blurb: String
    var glyph: String
    var tint: UInt32
    var custom: Bool
}

struct AreaIdeasScreen: View {
    var engine: GoobyEngine
    var store: GoalMetaStore
    var areaID: String
    var onChange: () -> Void
    @State private var tick = 0
    @State private var writing = false

    var body: some View {
        let _ = tick
        let ideas = GoalCatalog.suggestions(in: areaID)
        List {
            if let area = GoalCatalog.area(areaID) {
                Text(area.blurb(engine.languageCode))
                    .font(GoalFont.body)
                    .foregroundStyle(GoalLook.ink.opacity(0.75))
                    .listRowBackground(Color.clear)
            }
            Button {
                writing = true
            } label: {
                Label(engine.t("care.own"), systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(GoalLook.button)
            }
            .listRowBackground(Color.white)
            ForEach(ideas) { suggestion in
                let added = GoalActions.isAdded(suggestion, engine: engine, store: store)
                HStack(spacing: 12) {
                    GoalGlyph(glyph: suggestion.glyph).frame(width: 44, height: 44)
                    Text(suggestion.title(engine.languageCode))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(GoalLook.ink)
                    Spacer()
                    Button {
                        guard !added else { return }
                        _ = GoalActions.addSuggestion(suggestion, engine: engine, store: store)
                        tick += 1
                        onChange()
                    } label: {
                        Image(systemName: added ? "checkmark" : "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 32, height: 32)
                            .background(added ? GoalLook.check : GoalLook.button, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(added)
                }
                .listRowBackground(Color.white)
            }
            if ideas.isEmpty {
                Text(engine.t("care.areas.custom.empty"))
                    .font(GoalFont.body)
                    .foregroundStyle(GoalLook.subtitle)
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(GoalLook.paper)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $writing) {
            GoalDraftSheet(engine: engine, store: store, habit: nil, presetArea: areaID) {
                tick += 1
                onChange()
            }
        }
    }

    private var title: String {
        if let area = GoalCatalog.area(areaID) { return area.name(engine.languageCode) }
        return store.custom(areaID)?.name ?? engine.t("care.areas")
    }
}
