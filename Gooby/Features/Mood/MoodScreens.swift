import SwiftUI

struct MoodComposer: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @State private var level = 3
    @State private var tags: Set<String> = []
    @State private var note = ""
    private let tagIDs = ["happy", "sad", "tired", "stressed", "grateful", "motivated", "overwhelmed", "calm"]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("mood.level.\(level)")).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.ink)
                Picker(engine.t("mood.level"), selection: $level) {
                    ForEach(1...5, id: \.self) { Text(engine.t("mood.level.\($0)")).tag($0) }
                }
                .pickerStyle(.segmented)
                ForEach(tagIDs, id: \.self) { tag in
                    Button {
                        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
                    } label: {
                        HStack {
                            Text(engine.t("mood.tag.\(tag)")).foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: tags.contains(tag) ? "checkmark.circle.fill" : "circle")
                        }
                    }
                    .buttonStyle(.plain)
                }
                TextField(engine.t("mood.note"), text: $note, axis: .vertical).textFieldStyle(.roundedBorder)
                Button(engine.t("common.save")) {
                    engine.addMood(level: level, tags: Array(tags), note: note)
                    dismiss()
                }
                .buttonStyle(GoobyButtonStyle())
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .goobyScreen()
            .navigationTitle(engine.t("mood.add"))
            .toolbar { Button(engine.t("common.close")) { dismiss() } }
        }
    }
}

struct MoodScreen: View {
    var engine: GoobyEngine
    @State private var showAdd = false
    @State private var month = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Button(engine.t("mood.add")) { showAdd = true }.buttonStyle(GoobyButtonStyle(fill: Theme.pink, ink: Theme.ink))
                Text(summary(days: 7)).foregroundStyle(Theme.ink)
                Text(summary(days: 30)).foregroundStyle(Theme.ink.opacity(0.75))
                monthGrid
                ForEach(engine.all(MoodEntry.self).sorted { $0.recordedAt > $1.recordedAt }.prefix(30), id: \.id) { entry in
                    VStack(alignment: .leading) {
                        Text(engine.t("mood.level.\(entry.level)")).font(.system(.headline, design: .rounded))
                        Text(entry.tags.map { engine.t("mood.tag.\($0)") }.joined(separator: ", "))
                        if !entry.note.isEmpty { Text(entry.note) }
                        Text(engine.formatDate(entry.recordedAt, time: true)).font(.system(.caption, design: .rounded))
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contextMenu {
                        Button(engine.t("common.delete"), role: .destructive) { engine.deleteMood(entry) }
                    }
                }
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("mood.title"))
        .sheet(isPresented: $showAdd) { MoodComposer(engine: engine) }
    }

    private func summary(days: Int) -> String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: engine.now()) ?? engine.now()
        let rows = engine.all(MoodEntry.self).filter { $0.recordedAt >= cutoff }
        guard !rows.isEmpty else { return engine.tf(days == 7 ? "mood.week.empty" : "mood.month.empty", days) }
        let average = Double(rows.map(\.level).reduce(0, +)) / Double(rows.count)
        let counts = Dictionary(grouping: rows.flatMap(\.tags), by: { $0 }).mapValues(\.count)
        let top = counts.max { $0.value < $1.value }?.key
        let tone = average >= 4 ? engine.t("mood.tone.bright") : (average >= 3 ? engine.t("mood.tone.steady") : engine.t("mood.tone.tender"))
        let tag = top.map { engine.t("mood.tag.\($0)") } ?? engine.t("common.none")
        return engine.tf(days == 7 ? "mood.week" : "mood.month", tone, tag, average)
    }

    private var monthGrid: some View {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<29
        let map = Dictionary(grouping: engine.all(MoodEntry.self), by: \.dayKey)
        return VStack(alignment: .leading) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                Text(monthTitle).foregroundStyle(Theme.ink)
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(range, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
                    let key = DayKey.make(date)
                    let level = map[key]?.map(\.level).max()
                    Text("\(day)")
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(levelColor(level), in: Circle())
                        .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: month)
    }

    private func shift(_ value: Int) {
        month = Calendar.current.date(byAdding: .month, value: value, to: month) ?? month
    }

    private func levelColor(_ level: Int?) -> Color {
        switch level {
        case 1: return Theme.lavender
        case 2: return Theme.sky
        case 3: return Theme.cream
        case 4: return Theme.mint
        case 5: return Theme.yellow
        default: return Color.clear
        }
    }
}
