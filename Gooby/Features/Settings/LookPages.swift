import SwiftUI

struct LookGoalsPage: View {
    var engine: GoobyEngine

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.goals"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                let rows = engine.habits().filter { !$0.isArchived }
                if rows.isEmpty {
                    Text(engine.t("look.goals.empty"))
                        .foregroundStyle(Look.row)
                } else {
                    LookCard {
                        VStack(spacing: 0) {
                            ForEach(Array(rows.enumerated()), id: \.element.id) { index, habit in
                                NavigationLink {
                                    HabitDetail(engine: engine, habit: habit)
                                        .toolbar(.visible, for: .navigationBar)
                                } label: {
                                    LookNavRow(title: habit.title)
                                }
                                .buttonStyle(.plain)
                                if index < rows.count - 1 { LookDivider() }
                            }
                        }
                    }
                }
                NavigationLink {
                    HabitEditor(engine: engine, habit: nil)
                        .toolbar(.visible, for: .navigationBar)
                } label: {
                    Text(engine.t("habit.new"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Look.plus, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CareArea: Identifiable {
    var id: String
    var titleKey: String
    var category: String
    var icon: LookIcon.Kind
}

struct LookAreasPage: View {
    var engine: GoobyEngine
    private let areas = [
        CareArea(id: "sleep", titleKey: "look.area.sleep", category: "sleep", icon: .history),
        CareArea(id: "movement", titleKey: "look.area.movement", category: "movement", icon: .activities),
        CareArea(id: "nutrition", titleKey: "look.area.nutrition", category: "health", icon: .sprout),
        CareArea(id: "hygiene", titleKey: "look.area.hygiene", category: "hygiene", icon: .profile),
        CareArea(id: "kindness", titleKey: "look.area.kindness", category: "mindful", icon: .sparkles),
        CareArea(id: "focus", titleKey: "look.area.focus", category: "learning", icon: .insights),
        CareArea(id: "social", titleKey: "look.area.social", category: "custom", icon: .circles),
        CareArea(id: "mindful", titleKey: "look.area.mindful", category: "mindful", icon: .bell),
        CareArea(id: "home", titleKey: "look.area.home", category: "home", icon: .gift)
    ]

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.areas").replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                LookCard {
                    VStack(spacing: 0) {
                        ForEach(Array(areas.enumerated()), id: \.element.id) { index, area in
                            NavigationLink {
                                LookAreaDetail(engine: engine, area: area)
                            } label: {
                                let count = engine.habits().filter { !$0.isArchived && $0.category == area.category }.count
                                LookNavRow(title: engine.t(area.titleKey), subtitle: engine.tf("look.area.count", count), icon: area.icon)
                            }
                            .buttonStyle(.plain)
                            if index < areas.count - 1 { LookDivider() }
                        }
                    }
                }
            }
        }
    }
}

private struct LookAreaDetail: View {
    var engine: GoobyEngine
    var area: CareArea

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t(area.titleKey))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                let rows = engine.habits().filter { !$0.isArchived && $0.category == area.category }
                ForEach(rows) { habit in
                    NavigationLink {
                        HabitDetail(engine: engine, habit: habit)
                            .toolbar(.visible, for: .navigationBar)
                    } label: {
                        LookCard { LookNavRow(title: habit.title) }
                    }
                    .buttonStyle(.plain)
                }
                NavigationLink {
                    HabitEditor(engine: engine, habit: nil)
                        .toolbar(.visible, for: .navigationBar)
                } label: {
                    Text(engine.t("look.area.add"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Look.plus, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct LookCirclesPage: View {
    var engine: GoobyEngine
    var code: String
    @State private var name = ""
    @State private var note = ""
    @State private var circles = UserDefaults.standard.stringArray(forKey: LookMark.circles) ?? []

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("look.circles"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.t("look.circles.lead"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                Text(code)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                ShareLink(item: engine.tf("look.invite.share", code)) {
                    Text(engine.t("look.invite"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Look.plus)
                }
                TextField(engine.t("look.circles.placeholder"), text: $name)
                    .textFieldStyle(.roundedBorder)
                Button(engine.t("look.circles.add")) { add() }
                    .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                if !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.row)
                }
                if circles.isEmpty {
                    Text(engine.t("look.circles.empty")).foregroundStyle(Look.sub)
                }
                ForEach(circles, id: \.self) { circle in
                    HStack {
                        Text(circle).foregroundStyle(Look.ink)
                        Spacer()
                        Button(engine.t("common.delete")) { remove(circle) }
                            .foregroundStyle(Theme.rose)
                    }
                    .padding(12)
                    .background(Look.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            note = engine.t("look.circles.need")
            return
        }
        if circles.contains(trimmed) {
            note = engine.t("look.circles.have")
            return
        }
        circles.append(trimmed)
        name = ""
        note = ""
        UserDefaults.standard.set(circles, forKey: LookMark.circles)
    }

    private func remove(_ circle: String) {
        circles.removeAll { $0 == circle }
        UserDefaults.standard.set(circles, forKey: LookMark.circles)
    }
}
