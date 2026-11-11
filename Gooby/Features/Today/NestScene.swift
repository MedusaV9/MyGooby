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

    /// Drawn on a 402-point-wide screen from the top edge, so the room hangs behind the status bar like the reference.
    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / 402
            ZStack(alignment: .topLeading) {
                TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 24.0, paused: reduceMotion)) { timeline in
                    let glow = reduceMotion ? 0 : sin(timeline.date.timeIntervalSinceReferenceDate * 1.2)
                    Canvas { context, size in
                        var context = context
                        context.scaleBy(x: s, y: s)
                        NestPaint.room(&context, height: size.height / s, glow: glow)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                GoobyCharacterView(
                    look: look,
                    stage: growth,
                    animation: animation,
                    reduceMotion: reduceMotion,
                    companion: companion
                )
                .colorMultiply(Color(hex: 0x9AA8C2))
                .frame(width: 150 * s, height: 150 * s)
                .position(x: 53 * s, y: 205 * s)
                .homeStagePet(label: petLabel, petAction: petAction, onTap: onTap, onPet: onPet)
                Canvas { context, _ in
                    var context = context
                    context.scaleBy(x: s, y: s)
                    NestPaint.nestFront(&context)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                dream
                    .frame(width: 88 * s, height: 66 * s)
                    .position(x: 124 * s, y: 146 * s)
                    .allowsHitTesting(false)
            }
        }
        .clipped()
    }

    private var dream: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 8 : 1.0 / 24.0, paused: reduceMotion)) { timeline in
            let bob = CGFloat(reduceMotion ? 0.0 : sin(timeline.date.timeIntervalSinceReferenceDate * 1.1) * 3)
            NestDreamBubble(showsHatch: animation == .sleep || animation == .petting)
                .offset(y: bob)
                .opacity(animation == .sleep || animation == .petting ? 1 : 0)
        }
    }
}

/// The night room in 402-point screen coordinates, measured from reference/finch-frames 081.5s.
private enum NestPaint {
    static let wall: UInt32 = 0x506A8D
    static let floor: UInt32 = 0x26637F
    static let lilac: UInt32 = 0x7C87B5

    static func room(_ context: inout GraphicsContext, height: CGFloat, glow: Double) {
        let bottom = max(height, 400)
        rect(&context, CGRect(x: 0, y: 0, width: 402, height: bottom), wall)
        fill(&context, "M194 68 L214 68 L108 264 L-48 264 Z", 0x6A81A0, 0.82 + glow * 0.12)
        window(&context)
        dresser(&context)
        door(&context)
        lamp(&context)
        context.fill(Path(ellipseIn: CGRect(x: 140 - 430, y: 252, width: 860, height: 180)), with: .color(Color(hex: floor)))
        rect(&context, CGRect(x: 0, y: 342, width: 402, height: bottom - 342), floor)
        oval(&context, 70, 309, 78, 13, 0x215F74)
        nestBack(&context)
    }

    private static func window(_ context: inout GraphicsContext) {
        let center = CGPoint(x: 155, y: 142)
        circle(&context, center, 68, lilac)
        let glass = Path(ellipseIn: CGRect(x: center.x - 60, y: center.y - 60, width: 120, height: 120))
        context.fill(glass, with: .color(Color(hex: 0x2E3063)))
        var pane = context
        pane.clip(to: glass)
        rect(&pane, CGRect(x: 90, y: 150, width: 130, height: 60), 0x3D355E)
        fill(&pane, "M120 210 L210 90 L228 96 L142 214 Z", 0x464A7A, 0.55)
        fill(&pane, "M150 212 L222 118 L230 128 L164 214 Z", 0x464A7A, 0.4)
        circle(&pane, CGPoint(x: 192, y: 121), 13, 0x7A7A78)
        circle(&pane, CGPoint(x: 188, y: 117), 2.6, 0x6A6A68)
        circle(&pane, CGPoint(x: 197, y: 127), 1.8, 0x6A6A68)
        rect(&pane, CGRect(x: 152, y: 70, width: 6, height: 150), lilac)
        rect(&pane, CGRect(x: 80, y: 147, width: 150, height: 6), lilac)
    }

    private static func dresser(_ context: inout GraphicsContext) {
        rounded(&context, CGRect(x: 114, y: 211, width: 92, height: 52), 3, 0x4F7E9C)
        rounded(&context, CGRect(x: 110, y: 204, width: 100, height: 9), 3, 0x2A6A78)
        for y in [228.0, 245.0] {
            rect(&context, CGRect(x: 118, y: y, width: 84, height: 2), 0x3E6D89)
        }
        for y in [220.0, 237.0, 254.0] {
            circle(&context, CGPoint(x: 160, y: y), 2.6, 0x2A6474)
        }
    }

    private static func door(_ context: inout GraphicsContext) {
        context.fill(arch(CGRect(x: 268, y: 143, width: 84, height: 122)), with: .color(Color(hex: 0x66719E)))
        context.fill(arch(CGRect(x: 277, y: 152, width: 66, height: 113)), with: .color(Color(hex: 0x654B26)))
        let center = CGPoint(x: 310, y: 186)
        circle(&context, center, 21, 0x6D729C)
        circle(&context, center, 16, 0x48416B)
        rect(&context, CGRect(x: center.x - 1.5, y: center.y - 16, width: 3, height: 32), 0x6D729C)
        rect(&context, CGRect(x: center.x - 16, y: center.y - 1.5, width: 32, height: 3), 0x6D729C)
        circle(&context, CGPoint(x: 285, y: 222), 3.2, 0x8A8FC0)
    }

    private static func lamp(_ context: inout GraphicsContext) {
        rect(&context, CGRect(x: 199, y: 0, width: 2, height: 48), 0x4B5E7C)
        fill(&context, "M178 70 C178 55 188 46 200 46 C212 46 222 55 222 70 Z", 0x757D70)
        oval(&context, 200, 70, 22, 3, 0x8A9180)
        oval(&context, 200, 73, 5, 4, 0xD8D3A8)
    }

    private static func nestBack(_ context: inout GraphicsContext) {
        oval(&context, 62, 262, 78, 46, 0x5E5C2E)
        oval(&context, 60, 252, 60, 24, 0x4A4824)
        for index in 0..<26 {
            let angle = Double(index) / 26 * .pi * 2
            let x = 62 + CGFloat(cos(angle)) * 74
            let y = 258 + CGFloat(sin(angle)) * 40
            let tilt = CGFloat((index * 37) % 11) - 5
            stroke(&context, "M\(x - 9) \(y + tilt * 0.4) Q\(x) \(y - 6) \(x + 10) \(y - tilt * 0.5)", index.isMultiple(of: 3) ? 0x8A8448 : 0x6C6A39, 2.6)
        }
    }

    static func nestFront(_ context: inout GraphicsContext) {
        var front = context
        front.clip(to: Path(CGRect(x: -20, y: 256, width: 200, height: 70)))
        oval(&front, 62, 278, 79, 33, 0x626030)
        for index in 0..<34 {
            let x = CGFloat(-12 + (index * 23) % 150)
            let y = CGFloat(262 + (index * 17) % 42)
            let lean = CGFloat((index * 29) % 13) - 6
            let hex: UInt32 = index.isMultiple(of: 4) ? 0x8A8448 : (index.isMultiple(of: 3) ? 0x4E4B25 : 0x75723C)
            stroke(&front, "M\(x - 12) \(y + lean * 0.3) Q\(x) \(y - 5) \(x + 13) \(y - lean * 0.4)", hex, 2.4)
        }
        for index in 0..<9 {
            let x = CGFloat(-6 + index * 17)
            let rise = CGFloat((index * 31) % 9)
            stroke(&context, "M\(x - 8) \(262 - rise) Q\(x) \(254 - rise) \(x + 10) \(260 - rise * 0.5)", index.isMultiple(of: 2) ? 0x8A8448 : 0x6C6A39, 2.4)
        }
    }

    private static func arch(_ rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.minY + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private static func rect(_ context: inout GraphicsContext, _ rect: CGRect, _ hex: UInt32) {
        context.fill(Path(rect), with: .color(Color(hex: hex)))
    }

    private static func rounded(_ context: inout GraphicsContext, _ rect: CGRect, _ radius: CGFloat, _ hex: UInt32) {
        context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(Color(hex: hex)))
    }

    private static func circle(_ context: inout GraphicsContext, _ center: CGPoint, _ radius: CGFloat, _ hex: UInt32) {
        context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(Color(hex: hex)))
    }

    private static func oval(_ context: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ hex: UInt32) {
        context.fill(Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)), with: .color(Color(hex: hex)))
    }

    private static func fill(_ context: inout GraphicsContext, _ d: String, _ hex: UInt32, _ opacity: Double = 1) {
        context.fill(GoobyPathData.path(d), with: .color(Color(hex: hex).opacity(opacity)))
    }

    private static func stroke(_ context: inout GraphicsContext, _ d: String, _ hex: UInt32, _ width: CGFloat) {
        context.stroke(GoobyPathData.path(d), with: .color(Color(hex: hex)), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

private struct NestDreamBubble: View {
    var showsHatch: Bool

    var body: some View {
        let cloud = Color(hex: 0x7C87B4)
        ZStack {
            Circle().fill(cloud).frame(width: 8, height: 8).offset(x: -40, y: 44)
            Circle().fill(cloud).frame(width: 14, height: 14).offset(x: -32, y: 34)
            Circle().fill(cloud).frame(width: 40, height: 40).offset(x: -22, y: 4)
            Circle().fill(cloud).frame(width: 46, height: 46).offset(x: 4, y: -6)
            Circle().fill(cloud).frame(width: 40, height: 40).offset(x: 24, y: 4)
            Capsule().fill(cloud).frame(width: 80, height: 34).offset(y: 12)
            if showsHatch {
                hatch.offset(y: 1)
            }
        }
    }

    private var hatch: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xCDC4C2)).frame(width: 24, height: 28)
            ear.rotationEffect(.degrees(-16)).offset(x: -6, y: -15)
            ear.rotationEffect(.degrees(16)).offset(x: 6, y: -15)
            Circle().fill(Color(hex: 0x4A3A3A)).frame(width: 3, height: 3).offset(x: -5, y: -2)
            Circle().fill(Color(hex: 0x4A3A3A)).frame(width: 3, height: 3).offset(x: 5, y: -2)
            Ellipse().fill(Color(hex: 0xC98A8E)).frame(width: 4, height: 3).offset(y: 3)
        }
    }

    private var ear: some View {
        Capsule().fill(Color(hex: 0xCDC4C2)).frame(width: 6, height: 12)
            .overlay(Capsule().fill(Color(hex: 0xC99AA4)).frame(width: 3, height: 7).offset(y: 1))
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .padding(.trailing, 118)
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onAction) {
                Text(actionTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1B3A48))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 34)
        }
        .foregroundStyle(.white)
        .padding(EdgeInsets(top: 17, leading: 22, bottom: 14, trailing: 14))
        .background(alignment: .topTrailing) {
            ZStack(alignment: .topTrailing) {
                fill
                GoobyCharacterView(look: WornLook(), stage: "young", animation: .wave, reduceMotion: true, companion: nil)
                    .frame(width: 92, height: 92)
                    .padding(.top, 6)
                    .padding(.trailing, 26)
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .padding(.trailing, 2)
            .accessibilityLabel(closeLabel)
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
