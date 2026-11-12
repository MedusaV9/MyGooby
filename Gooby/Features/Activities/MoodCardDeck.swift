import SwiftUI

/// Local deck of short encouraging lines. Opening a card shows one sentence.
/// Hook: `MoodCards.open`, called from `ActivityDestination` for `ActivityLane.cards`.
enum MoodCards {
    static func open(engine: GoobyEngine, reduceMotion: Bool) -> MoodCardScreen {
        MoodCardScreen(engine: engine, reduceMotion: reduceMotion)
    }
}

struct MoodCardScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var index = MoodCardBox.index()
    @State private var shown = false

    var body: some View {
        ActivityLanePage(engine: engine, lane: .cards) {
            Text(engine.t("mood.cards.note"))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            card
                .scaleEffect(shown || reduceMotion ? 1 : 0.94)
                .opacity(shown || reduceMotion ? 1 : 0)
            Button(action: next) {
                Text(engine.t("mood.cards.next"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x243041))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            guard !shown else { return }
            if reduceMotion {
                shown = true
            } else {
                withAnimation(.spring(duration: 0.45)) { shown = true }
            }
        }
    }

    private var card: some View {
        ZStack {
            deckLeaf(dx: 16, dy: 14, angle: 8, opacity: 0.42)
            deckLeaf(dx: -14, dy: 9, angle: -7, opacity: 0.7)
            front
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(countLine). \(sentence)")
    }

    private var front: some View {
        VStack(spacing: 8) {
            Text(countLine)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color(hex: 0xC06A28))
            Text(sentence)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x243041))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
                .id(index)
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: reduceMotion ? .wave : .laugh,
                reduceMotion: reduceMotion,
                companion: nil,
                showCompanion: false
            )
            .frame(width: 160, height: 168)
            .accessibilityHidden(true)
            MoodCardSpark()
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color(hex: 0x8A4A12).opacity(0.16), radius: 12, y: 6)
        .rotationEffect(.degrees(reduceMotion ? 0 : tilt))
        .animation(reduceMotion ? nil : .spring(duration: 0.35), value: index)
    }

    private func deckLeaf(dx: CGFloat, dy: CGFloat, angle: Double, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(opacity))
            .frame(height: 280)
            .rotationEffect(.degrees(angle))
            .offset(x: dx, y: dy)
            .accessibilityHidden(true)
    }

    private var sentence: String {
        engine.t("mood.cards.line.\(index)")
    }

    private var countLine: String {
        engine.tf("mood.cards.count", index + 1, MoodCardBox.count)
    }

    private var tilt: Double {
        Double((index % 3) - 1) * 1.2
    }

    private func next() {
        engine.haptics.soft()
        let step = MoodCardBox.advance()
        if reduceMotion {
            index = step
        } else {
            withAnimation(.spring(duration: 0.35)) { index = step }
        }
    }
}

private struct MoodCardSpark: View {
    var body: some View {
        HStack(spacing: 16) {
            MoodCardStar().frame(width: 8, height: 8)
            MoodCardStar().frame(width: 12, height: 12)
            MoodCardStar().frame(width: 8, height: 8)
        }
        .foregroundStyle(Color(hex: 0xF2BE3A))
        .accessibilityHidden(true)
    }
}

private struct MoodCardStar: Shape {
    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let midY = rect.midY
        var path = Path()
        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addLine(to: CGPoint(x: midX + rect.width * 0.16, y: midY - rect.height * 0.16))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY))
        path.addLine(to: CGPoint(x: midX + rect.width * 0.16, y: midY + rect.height * 0.16))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: midX - rect.width * 0.16, y: midY + rect.height * 0.16))
        path.addLine(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: midX - rect.width * 0.16, y: midY - rect.height * 0.16))
        path.closeSubpath()
        return path
    }
}

/// The open card stays on this iPhone. The file only stores the index in the deck.
enum MoodCardBox {
    static let count = 12

    static func index() -> Int {
        guard let data = try? Data(contentsOf: file),
              let stored = try? JSONDecoder().decode(Int.self, from: data) else { return 0 }
        return normalize(stored)
    }

    static func advance() -> Int {
        let next = normalize(index() + 1)
        if let data = try? JSONEncoder().encode(next) {
            try? data.write(to: file, options: .atomic)
            GoobyFiles.exclude(file)
        }
        return next
    }

    private static var file: URL {
        GoobyFiles.supportDirectory().appendingPathComponent("mood-cards.json")
    }

    private static func normalize(_ value: Int) -> Int {
        ((value % count) + count) % count
    }
}
