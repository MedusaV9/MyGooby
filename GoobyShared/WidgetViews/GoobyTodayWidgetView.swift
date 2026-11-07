import SwiftUI

/// Small "Gooby today" widget content: Gooby, today's goals done and the next open goal. Without
/// a snapshot (no App Group) it shows Gooby, a greeting and the date; a tap opens the app.
/// Lives in GoobyShared so the app can preview it (ExtrasGallery). The widget's container
/// background is cream (`GoobyTokens.cream`).
struct GoobyTodayWidgetView: View {
    var snapshot: GoobyWidgetSnapshot?
    var date: Date = Date()

    var body: some View {
        let language = GoobyText.resolved(snapshot?.language)
        VStack(alignment: .leading, spacing: 2) {
            GoobyMiniHead(fur: snapshot?.fur ?? "fur-cream", stage: snapshot?.stage ?? "baby", face: allDone ? .happy : .smile)
                .frame(width: 58, height: 58)
            Spacer(minLength: 0)
            if let snapshot {
                Text(verbatim: "\(snapshot.goalsDone)/\(snapshot.goalsTotal)")
                    .font(GoobyTokens.Fonts.rounded(26))
                    .foregroundStyle(GoobyTokens.text)
                Text(GoobyText.pick(language, de: "Ziele geschafft", en: "goals done"))
                    .font(GoobyTokens.Fonts.rounded(13, .bold))
                    .foregroundStyle(GoobyTokens.greyText)
            } else {
                Text(greeting(language))
                    .font(GoobyTokens.Fonts.rounded(16))
                    .foregroundStyle(GoobyTokens.text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: language))))
                    .font(GoobyTokens.Fonts.rounded(12, .bold))
                    .foregroundStyle(GoobyTokens.greyText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var allDone: Bool {
        guard let snapshot else { return false }
        return snapshot.goalsTotal > 0 && snapshot.goalsDone >= snapshot.goalsTotal
    }

    private func greeting(_ language: String) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return GoobyText.pick(language, de: "Guten Morgen!", en: "Good morning!")
        case 11..<18: return GoobyText.pick(language, de: "Hallo du!", en: "Hi there!")
        default: return GoobyText.pick(language, de: "Guten Abend!", en: "Good evening!")
        }
    }
}
