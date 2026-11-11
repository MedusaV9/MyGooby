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
                        PlusMark().fill(Color.white).frame(width: 14, height: 14)
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
                    ChevronMark(direction: .left)
                        .stroke(GoalLook.ink, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 9, height: 16)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(engine.t("common.close"))
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
            GoalGlyph(glyph: area.glyph, plate: Color(hex: area.tint))
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(area.name)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(GoalLook.ink)
                    if focused {
                        StarMark().fill(Color(hex: 0xFFCC4D)).frame(width: 13, height: 13)
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
                    ZStack {
                        if focused {
                            StarMark().fill(Color(hex: 0xFFCC4D))
                        }
                        StarMark().stroke(Color(hex: 0xFFAC33), style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                    }
                    .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t(focused ? "care.focus.on" : "care.focus"))
                if area.custom {
                    Button(role: .destructive) {
                        GoalActions.deleteArea(area.id, engine: engine, store: store)
                        tick += 1
                        onChange()
                    } label: {
                        TrashMark()
                            .stroke(Color(hex: 0xC45B5B), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                            .frame(width: 15, height: 17)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.t("common.delete"))
                }
                ChevronMark(direction: .right)
                    .stroke(GoalLook.subtitle, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .frame(width: 7, height: 12)
            }
        }
        .padding(14)
        .background(GoalLook.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                HStack(spacing: 12) {
                    GoalGlyph(glyph: "pencil", plate: GoalLook.plusDisc.opacity(0.45))
                        .frame(width: 46, height: 46)
                    Text(engine.t("care.own"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(GoalLook.button)
                }
            }
            .listRowBackground(GoalLook.card)
            ForEach(ideas) { suggestion in
                let added = GoalActions.isAdded(suggestion, engine: engine, store: store)
                HStack(spacing: 12) {
                    GoalGlyph(glyph: suggestion.glyph).frame(width: 46, height: 46)
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
                        GoalAddMark(added: added)
                    }
                    .buttonStyle(.plain)
                    .disabled(added)
                }
                .listRowBackground(GoalLook.card)
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
