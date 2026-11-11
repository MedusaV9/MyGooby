import SwiftUI

// Night nest for Home. The room editor can embed this view.
// Sleep, the dream, and the still variant live here. Placing furniture does not.

enum HomeStageKind: Equatable {
    case nest
    case forest

    var page: Color {
        switch self {
        case .nest: return Color(hex: 0x25637E)
        case .forest: return HomePalette.page
        }
    }

    var card: Color {
        switch self {
        case .nest: return Color(hex: 0x1F576C)
        case .forest: return HomePalette.card
        }
    }

    var action: Color {
        switch self {
        case .nest: return Color(hex: 0x1A4F64)
        case .forest: return HomePalette.addGoal
        }
    }

    var bar: Color {
        switch self {
        case .nest: return Color(hex: 0x297392)
        case .forest: return HomePalette.tabBar
        }
    }

    var pill: Color {
        switch self {
        case .nest: return Color(hex: 0x6AA2B5)
        case .forest: return HomePalette.pill
        }
    }

    var banner: Color {
        switch self {
        case .nest: return Color(hex: 0x1B4B5C)
        case .forest: return Color(hex: 0x2F6E34)
        }
    }
}

enum HomeStage {
    static let buddyDismissedKey = "gooby.homeStage.buddyDismissed"

    @MainActor
    static func kind(engine: GoobyEngine) -> HomeStageKind {
        _ = engine.animation
        return kind(at: engine.now(), run: engine.todaysRun())
    }

    @MainActor
    static func isWalking(engine: GoobyEngine) -> Bool {
        isWalking(at: engine.now(), run: engine.todaysRun())
    }

    /// Nest before the day's departure, and again at night once Gooby is home.
    /// The forest, with the pet walking, stays up for the whole trip.
    static func kind(at date: Date, run: AdventureRun?) -> HomeStageKind {
        if isWalking(at: date, run: run) { return .forest }
        guard run != nil else { return .nest }
        switch DaylightPhase.of(date) {
        case .night, .evening: return .nest
        case .morning, .day: return .forest
        }
    }

    static func isWalking(at date: Date, run: AdventureRun?) -> Bool {
        guard let run, run.status == "traveling" else { return false }
        return date < run.returnsAt
    }
}

@MainActor
@Observable
final class HomeStageTone {
    static let shared = HomeStageTone()
    private(set) var kind: HomeStageKind = .nest

    func adopt(_ kind: HomeStageKind) {
        guard self.kind != kind else { return }
        self.kind = kind
    }
}

struct NestScene: View {
    var reduceMotion: Bool
    var look: WornLook
    var growth: String
    var companion: String?
    var animation: GoobyAnimation = .sleep
    var petLabel: String = "Gooby"
    var petAction: String = "Gooby"
    var onTap: () -> Void = {}
    var onPet: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            ZStack {
                decor(width: width, height: height)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                GoobyCharacterView(
                    look: look,
                    stage: growth,
                    animation: animation,
                    reduceMotion: reduceMotion,
                    companion: companion
                )
                .frame(width: width * 0.36, height: height * 0.42)
                .position(x: width * 0.23, y: height * 0.55)
                .homeStagePet(label: petLabel, petAction: petAction, onTap: onTap, onPet: onPet)
            }
        }
        .clipped()
    }

    private func decor(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Color(hex: 0x506B8D)
            Ellipse()
                .fill(Color(hex: 0x26647F))
                .frame(width: width * 1.4, height: height * 0.64)
                .position(x: width * 0.5, y: height * 0.96)
            Ellipse()
                .fill(Color(hex: 0x1E5A72))
                .frame(width: width * 1.2, height: height * 0.26)
                .position(x: width * 0.5, y: height * 1.02)
            lightCone(width: width, height: height)
            dresser
                .frame(width: width * 0.34, height: height * 0.16)
                .position(x: width * 0.50, y: height * 0.52)
            window
                .frame(width: width * 0.30, height: width * 0.30)
                .position(x: width * 0.50, y: height * 0.36)
            door
                .frame(width: width * 0.20, height: height * 0.40)
                .position(x: width * 0.84, y: height * 0.48)
            nestBowl
                .frame(width: width * 0.42, height: height * 0.16)
                .position(x: width * 0.23, y: height * 0.66)
            dream
                .frame(width: width * 0.28, height: width * 0.24)
                .position(x: width * 0.40, y: height * 0.25)
            lamp
                .frame(width: width * 0.16, height: height * 0.16)
                .position(x: width * 0.60, y: height * 0.12)
        }
    }

    private func lightCone(width: CGFloat, height: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 24.0, paused: reduceMotion)) { timeline in
            let wave = reduceMotion ? 0.0 : sin(timeline.date.timeIntervalSinceReferenceDate * 1.2)
            NestLightCone()
                .fill(Color(hex: 0xFFE7A8).opacity(0.18 + wave * 0.06))
                .frame(width: width * 0.62, height: height * 0.70)
                .position(x: width * 0.58, y: height * 0.40)
        }
    }

    private var window: some View {
        ZStack {
            Circle().fill(Color(hex: 0x2A315C))
            Circle().fill(Color(hex: 0xF6E7B2)).frame(width: 22, height: 22).offset(x: 16, y: -14)
            Circle().fill(Color(hex: 0xE6D39A)).frame(width: 6, height: 6).offset(x: 20, y: -16)
            ForEach(Array(NestStars.spots.enumerated()), id: \.offset) { _, spot in
                Circle().fill(Color.white.opacity(0.9)).frame(width: spot.size, height: spot.size).offset(x: spot.x, y: spot.y)
            }
            Rectangle().fill(Color(hex: 0xD5DDE6)).frame(width: 5)
            Rectangle().fill(Color(hex: 0xD5DDE6)).frame(height: 5)
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(hex: 0xE4EAF0), lineWidth: 7))
    }

    private var dresser: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(hex: 0x8EABC2))
                    .overlay(Circle().fill(Color(hex: 0xF0E2B0)).frame(width: 6, height: 6))
            }
        }
        .padding(6)
        .background(Color(hex: 0x6E90A8), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var door: some View {
        NestDoorArch()
            .fill(Color(hex: 0xE0943C))
            .overlay(NestDoorArch().stroke(Color(hex: 0x8A4E22), lineWidth: 6))
            .overlay {
                VStack(spacing: 16) {
                    ZStack {
                        Circle().stroke(Color(hex: 0x8A4E22), lineWidth: 4)
                        Rectangle().fill(Color(hex: 0x8A4E22)).frame(width: 3)
                        Rectangle().fill(Color(hex: 0x8A4E22)).frame(height: 3)
                    }
                    .frame(width: 32, height: 32)
                    Circle().fill(Color(hex: 0xF6E2A8)).frame(width: 8, height: 8).offset(x: -16)
                }
                .offset(y: 6)
            }
    }

    private var nestBowl: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0x8A8A32))
            ForEach(0..<14, id: \.self) { index in
                Capsule()
                    .fill(index.isMultiple(of: 2) ? Color(hex: 0xE4D56A) : Color(hex: 0xC6B44A))
                    .frame(width: 5, height: 22)
                    .rotationEffect(.degrees(Double(index) * 18 - 117))
                    .offset(y: 2)
            }
            Ellipse().fill(Color(hex: 0xC6B44A)).padding(.horizontal, 10).padding(.vertical, 8).offset(y: 4)
            Ellipse().fill(Color(hex: 0xF0E08A).opacity(0.85)).padding(.horizontal, 28).padding(.vertical, 14)
        }
    }

    private var dream: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 24.0, paused: reduceMotion)) { timeline in
            let bob = CGFloat(reduceMotion ? 0.0 : sin(timeline.date.timeIntervalSinceReferenceDate * 1.1) * 5)
            NestDreamBubble(showsHatch: animation == .sleep || animation == .petting)
                .offset(y: bob)
                .opacity(animation == .sleep || animation == .petting ? 1 : 0)
        }
    }

    private var lamp: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: 0xD9C7A2)).frame(width: 2).frame(maxHeight: .infinity)
            ZStack {
                Capsule().fill(Color(hex: 0xF2D56A))
                Capsule().fill(Color(hex: 0xFFE7A0)).frame(width: 22, height: 10).offset(y: -2)
            }
            .frame(width: 36, height: 22)
        }
    }
}

private enum NestStars {
    static let spots: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-22, -8, 3), (8, 16, 2.4), (-10, 18, 2), (24, 6, 2.2), (-16, -20, 2.5)
    ]
}

private struct NestDoorArch: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY + radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct NestLightCone: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct NestDreamBubble: View {
    var showsHatch: Bool

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.95)).frame(width: 9, height: 9).offset(x: -36, y: 30)
            Circle().fill(Color.white).frame(width: 14, height: 14).offset(x: -24, y: 20)
            Circle().fill(Color.white).frame(width: 72, height: 60)
            if showsHatch {
                hatch.offset(y: -1)
            }
        }
        .shadow(color: Color.black.opacity(0.12), radius: 3, y: 2)
    }

    private var hatch: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xFFF6EA)).frame(width: 26, height: 32)
            ear.rotationEffect(.degrees(-16)).offset(x: -6, y: -16)
            ear.rotationEffect(.degrees(16)).offset(x: 6, y: -16)
            Path { path in
                path.move(to: CGPoint(x: 2, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 7))
                path.addLine(to: CGPoint(x: 4, y: 13))
                path.addLine(to: CGPoint(x: 12, y: 20))
            }
            .stroke(Color(hex: 0xE0B898), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
            .frame(width: 16, height: 22)
        }
    }

    private var ear: some View {
        Capsule().fill(Color(hex: 0xFFF6EA)).frame(width: 6, height: 12)
            .overlay(Capsule().fill(HomePalette.innerEar).frame(width: 3, height: 7).offset(y: 1))
    }
}

struct HomeDreamToast: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(hex: 0x333333), in: Capsule())
            .padding(.horizontal, 24)
            .accessibilityAddTraits(.isStaticText)
    }
}

struct HomeBuddyBanner: View {
    var title: String
    var message: String
    var actionTitle: String
    var closeLabel: String
    var fill: Color
    var onAction: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                    Text(message)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                bunnies
                    .frame(width: 92, height: 78)
                    .accessibilityHidden(true)
                    .padding(.top, 10)
            }
            Button(action: onAction) {
                Text(actionTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1B3A48))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 12))
        .background(fill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(closeLabel)
        }
    }

    private var bunnies: some View {
        ZStack {
            bannerBunny(body: Color(hex: 0xF3C7A8), ear: Color(hex: 0xFFB7CB)).offset(x: 16, y: 8)
            bannerBunny(body: Color(hex: 0xD7F3E4), ear: Color(hex: 0xF7C3DE)).offset(x: -16, y: 0)
        }
    }

    private func bannerBunny(body: Color, ear: Color) -> some View {
        ZStack {
            Capsule().fill(body).frame(width: 9, height: 16).rotationEffect(.degrees(-18)).offset(x: -7, y: -20)
            Capsule().fill(body).frame(width: 9, height: 16).rotationEffect(.degrees(16)).offset(x: 7, y: -20)
            Capsule().fill(ear).frame(width: 4, height: 9).rotationEffect(.degrees(-18)).offset(x: -7, y: -18)
            Capsule().fill(ear).frame(width: 4, height: 9).rotationEffect(.degrees(16)).offset(x: 7, y: -18)
            Circle().fill(body).frame(width: 34, height: 34)
            Capsule().fill(Color(hex: 0x5C4030)).frame(width: 7, height: 2).rotationEffect(.degrees(-8)).offset(x: -6, y: -2)
            Capsule().fill(Color(hex: 0x5C4030)).frame(width: 7, height: 2).rotationEffect(.degrees(8)).offset(x: 6, y: -2)
            Ellipse().fill(Color(hex: 0xFF9BB8)).frame(width: 5, height: 3.5).offset(y: 4)
            Capsule().fill(body).frame(width: 16, height: 7).offset(x: 14, y: 8)
        }
    }
}

extension View {
    func homeStagePet(label: String, petAction: String, onTap: @escaping () -> Void, onPet: @escaping () -> Void) -> some View {
        modifier(HomeStagePetModifier(label: label, petAction: petAction, onTap: onTap, onPet: onPet))
    }
}

private struct HomeStagePetModifier: ViewModifier {
    var label: String
    var petAction: String
    var onTap: () -> Void
    var onPet: () -> Void
    @State private var petAt = Date.distantPast

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                if Date().timeIntervalSince(petAt) < 0.55 { return }
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.45) {
                petAt = Date()
                onPet()
            }
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: Text(petAction)) {
                petAt = Date()
                onPet()
            }
    }
}
