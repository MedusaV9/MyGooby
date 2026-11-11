import SwiftUI

enum FriendsFunPaint {
    static let sheet = Color(hex: 0x67C63E)
    static let hill = Color(hex: 0x8BE05C)
    static let hillDeep = Color(hex: 0x52B534)
    static let circle = Color(hex: 0xE7F8DC)
    static let ink = Color(hex: 0x1A4D22)
    static let header = Color(hex: 0x5EC447)
    static let button = Color(hex: 0x3CBF4A)
    static let track = Color(hex: 0xE4E4E4)
    static let card = Color(hex: 0xF7F7F7)
}

struct FriendsPressStyle: ButtonStyle {
    var calm: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!calm && configuration.isPressed ? 0.96 : 1)
            .animation(calm ? nil : .spring(duration: 0.22), value: configuration.isPressed)
    }
}

struct FriendsHeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.92))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.32), control1: CGPoint(x: w * 0.16, y: h * 0.72), control2: CGPoint(x: 0, y: h * 0.52))
        path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.28), control1: CGPoint(x: 0, y: h * 0.08), control2: CGPoint(x: w * 0.28, y: h * 0.08))
        path.addCurve(to: CGPoint(x: w, y: h * 0.32), control1: CGPoint(x: w * 0.72, y: h * 0.08), control2: CGPoint(x: w, y: h * 0.08))
        path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.92), control1: CGPoint(x: w, y: h * 0.52), control2: CGPoint(x: w * 0.84, y: h * 0.72))
        return path
    }
}

enum FriendsFunStop: Hashable {
    case treehouse, vibes, gift, post
}

struct FriendsFunSheet: View {
    var engine: GoobyEngine
    @Binding var book: FriendsBook
    @Binding var lane: FriendsPostBook
    var start: FriendsFunStop?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var path: [FriendsFunStop] = []
    @State private var showReward = false

    private var calm: Bool { systemReduce || engine.reduceMotion }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    Text(engine.t("friends.fun.title"))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    actions
                    Button { showReward = true } label: {
                        Text(engine.t("friends.fun.invite"))
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(FriendsFunPaint.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: Capsule())
                    }
                    .buttonStyle(FriendsPressStyle(calm: calm))
                    Button { path.append(.post) } label: {
                        HStack(spacing: 6) {
                            Text(engine.t("friends.fun.post"))
                            if !lane.notes.isEmpty {
                                Text("\(lane.notes.count)")
                            }
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .underline()
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(FriendsFunPaint.sheet)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FriendsFunStop.self) { stop in
                switch stop {
                case .treehouse:
                    FriendsTreehouseVisit(engine: engine, book: $book, lane: $lane)
                case .vibes:
                    FriendsVibePage(engine: engine, book: $book, lane: $lane)
                case .gift:
                    FriendsGiftPage(engine: engine, book: $book, lane: $lane)
                case .post:
                    FriendsPostPage(engine: engine, lane: lane)
                }
            }
        }
        .sheet(isPresented: $showReward) {
            FriendsRewardSheet(engine: engine, book: $book)
        }
        .onAppear {
            if let start, path.isEmpty { path = [start] }
        }
        .presentationDetents(start == nil ? [.fraction(0.68), .large] : [.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(FriendsFunPaint.sheet)
        .presentationCornerRadius(28)
    }

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                Circle().fill(FriendsFunPaint.hill).frame(width: 180, height: 180).offset(x: -120, y: 36)
                Circle().fill(FriendsFunPaint.hillDeep).frame(width: 210, height: 210).offset(x: 120, y: 48)
                Circle().fill(FriendsFunPaint.hill).frame(width: 250, height: 250).offset(y: 78)
                GoobyMark().offset(y: 4)
            }
            .frame(height: 132)
            .frame(maxWidth: .infinity)
            .clipped()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FriendsFunPaint.ink)
                    .frame(width: 36, height: 36)
                    .background(.white, in: Circle())
            }
            .buttonStyle(FriendsPressStyle(calm: calm))
            .accessibilityLabel(engine.t("friends.fun.close"))
            .padding(.top, 12)
        }
    }

    private var actions: some View {
        HStack(alignment: .top, spacing: 6) {
            action(.treehouse, title: engine.t("friends.fun.treehouse")) {
                FriendsTreehouseBadge()
            }
            action(.vibes, title: engine.t("friends.fun.vibes")) {
                FriendsVibesBadge(calm: calm)
            }
            action(.gift, title: engine.t("friends.fun.gift")) {
                FriendsGiftBadge()
            }
        }
    }

    private func action<Badge: View>(_ stop: FriendsFunStop, title: String, @ViewBuilder badge: () -> Badge) -> some View {
        Button { path.append(stop) } label: {
            VStack(spacing: 8) {
                badge()
                    .frame(width: 84, height: 84)
                    .background(FriendsFunPaint.circle, in: Circle())
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(FriendsFunPaint.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(FriendsPressStyle(calm: calm))
    }
}

/// The first-visit card over the dimmed tree: hills with Gooby peeking, three things to do
/// together and the invite button.
struct FriendsIntroCard: View {
    var engine: GoobyEngine
    var calm: Bool
    var open: (FriendsFunStop) -> Void
    var invite: () -> Void
    var close: () -> Void
    @State private var shown = false

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 402
            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(shown ? 0.81 : 0)
                    .ignoresSafeArea()
                    .onTapGesture { leave(close) }
                    .accessibilityHidden(true)
                card
                    .frame(width: 402, height: 416)
                    .scaleEffect(unit, anchor: .bottom)
                    .frame(width: geo.size.width, height: 416 * unit)
                    .offset(y: shown ? 0 : 416 * unit + 40)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
        .ignoresSafeArea()
        .onAppear {
            if calm {
                shown = true
            } else {
                withAnimation(.spring(duration: 0.38, bounce: 0.12)) { shown = true }
            }
        }
    }

    private func leave(_ then: @escaping () -> Void) {
        if calm {
            then()
            return
        }
        withAnimation(.easeIn(duration: 0.22)) { shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { then() }
    }

    private var card: some View {
        ZStack(alignment: .topLeading) {
            FriendsIntroPaint.body
            Canvas { context, _ in
                FriendsTrace.fill(FriendsTrace.cardHills, in: &context)
            }
            .frame(width: 402, height: 110)
            peek
                .position(x: 201, y: 52)
            Button { leave(close) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 29, height: 29)
                    .background(Color.white.opacity(0.2), in: Circle())
                    .contentShape(Circle().inset(by: -8))
            }
            .buttonStyle(FriendsPressStyle(calm: calm))
            .accessibilityLabel(engine.t("friends.fun.close"))
            .position(x: 21.4, y: 23.5)
            Text(engine.t("friends.fun.title"))
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(-1)
                .frame(width: 290)
                .position(x: 201, y: 139)
            stop(.treehouse, title: engine.t("friends.fun.treehouse"), x: 86) { FriendsTreehouseBadge().scaleEffect(1.55) }
            stop(.vibes, title: engine.t("friends.fun.vibes"), x: 201) { FriendsVibesBadge(calm: true).scaleEffect(1.45) }
            stop(.gift, title: engine.t("friends.fun.gift"), x: 315) { FriendsGiftBadge().scaleEffect(1.6) }
            Button { leave(invite) } label: {
                Text(engine.t("friends.fun.invite"))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: 0x202020))
                    .frame(width: 343, height: 40)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(hex: 0xE2E0E1))
                                .offset(y: 3)
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white)
                        }
                    }
            }
            .buttonStyle(FriendsPressStyle(calm: calm))
            .position(x: 201, y: 350)
        }
        .frame(width: 402, height: 416, alignment: .topLeading)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24, style: .continuous))
    }

    private var peek: some View {
        ZStack {
            GoobyMark().scaleEffect(1.3).offset(y: -2)
            paw.rotationEffect(.degrees(-18)).offset(x: -24, y: 28)
            paw.rotationEffect(.degrees(18)).offset(x: 24, y: 28)
        }
        .frame(width: 110, height: 110)
        .accessibilityHidden(true)
    }

    private var paw: some View {
        Ellipse()
            .fill(FriendsPaint.cream)
            .overlay(Ellipse().stroke(FriendsPaint.creamShade, lineWidth: 1.2))
            .frame(width: 30, height: 25)
    }

    private func stop<Badge: View>(_ stop: FriendsFunStop, title: String, x: CGFloat, @ViewBuilder badge: () -> Badge) -> some View {
        Button { leave { open(stop) } } label: {
            VStack(spacing: 7) {
                badge()
                    .frame(width: 87, height: 87)
                    .background(FriendsIntroPaint.circle, in: Circle())
                    .clipShape(Circle())
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-3)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 124)
        }
        .buttonStyle(FriendsPressStyle(calm: calm))
        .position(x: x, y: 241)
    }
}

enum FriendsIntroPaint {
    static let body = Color(hex: 0x4FBD49)
    static let circle = Color(hex: 0x44A83D)
}

struct FriendsTreehouseBadge: View {
    var body: some View {
        ZStack {
            // Open doorway, the frame's left circle: purple door, cream frame, Gooby looking out.
            Circle()
                .fill(Color(hex: 0x7ED56A))
                .frame(width: 54, height: 54)
                .offset(x: 10, y: 4)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: 0xF7F4EF))
                .frame(width: 40, height: 52)
                .offset(x: -8, y: 6)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: 0xC9B6F2))
                .frame(width: 28, height: 44)
                .offset(x: -10, y: 8)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0xF7F4EF).opacity(0.85))
                .frame(width: 3, height: 44)
                .offset(x: -10, y: 8)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0xF7F4EF).opacity(0.7))
                .frame(width: 22, height: 3)
                .offset(x: -10, y: 2)
            Circle()
                .fill(Color(hex: 0xF2C14A))
                .frame(width: 4, height: 4)
                .offset(x: -2, y: 12)
            GoobyMark()
                .scaleEffect(0.42)
                .offset(x: 16, y: 10)
        }
        .accessibilityHidden(true)
    }
}

struct FriendsVibesBadge: View {
    var calm: Bool

    var body: some View {
        ZStack {
            // Still rays, so the screenshot matches the frame's burst without motion.
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(Color(hex: 0x8BE06A).opacity(0.9))
                    .frame(width: index % 2 == 0 ? 10 : 6, height: 34)
                    .offset(y: -8)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
            Circle().fill(Color(hex: 0x6ED45C)).frame(width: 36, height: 36)
            GoobyMark().scaleEffect(0.48).offset(y: 6)
            banana.offset(y: -22)
            if !calm {
                FriendsHeartShape()
                    .fill(FriendsPaint.heart)
                    .frame(width: 12, height: 10)
                    .offset(x: 24, y: -18)
            }
        }
        .accessibilityHidden(true)
    }

    private var banana: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0xF6D34A))
                .frame(width: 12, height: 28)
                .rotationEffect(.degrees(-28))
            Capsule()
                .fill(Color(hex: 0xF8E27A))
                .frame(width: 5, height: 16)
                .rotationEffect(.degrees(-28))
                .offset(x: -2)
            Capsule()
                .fill(Color(hex: 0xC9852A))
                .frame(width: 5, height: 7)
                .offset(y: -14)
            Circle().fill(Color(hex: 0x3A3530)).frame(width: 2.2).offset(x: -2, y: -2)
            Circle().fill(Color(hex: 0x3A3530)).frame(width: 2.2).offset(x: 3, y: -4)
        }
        .frame(width: 28, height: 32)
    }
}

struct FriendsGiftBadge: View {
    var body: some View {
        ZStack {
            // Gooby with a heart bubble, the frame's right circle, instead of a flat present.
            GoobyMark().scaleEffect(0.62)
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(Color(hex: 0xF4F7F4))
                    .frame(width: 18, height: 18)
                FriendsHeartShape()
                    .fill(Color(hex: 0xF2556A))
                    .frame(width: 11, height: 10)
            }
            .offset(x: 22, y: -20)
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .offset(x: 14, y: -8)
        }
        .accessibilityHidden(true)
    }
}
