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
        .presentationDetents([.fraction(0.68), .large])
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

struct FriendsTreehouseBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(hex: 0xD7B08A))
                .frame(width: 36, height: 28)
                .offset(y: 8)
            Triangle()
                .fill(Color(hex: 0xC9B7F5))
                .frame(width: 48, height: 22)
                .offset(y: -12)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: 0x8D6A4A))
                .frame(width: 10, height: 16)
                .offset(y: 14)
            Circle()
                .fill(Color(hex: 0x9FD8F5))
                .frame(width: 10, height: 10)
                .offset(x: 10, y: 6)
            GoobyMark()
                .scaleEffect(0.28)
                .offset(x: -8, y: 8)
        }
        .accessibilityHidden(true)
    }
}

struct FriendsVibesBadge: View {
    var calm: Bool

    var body: some View {
        ZStack {
            if !calm {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(Color(hex: 0x7ED0A0))
                        .frame(width: 4, height: 9)
                        .offset(y: -32)
                        .rotationEffect(.degrees(Double(index) * 45))
                }
            }
            GoobyMark().scaleEffect(0.52)
            FriendsHeartShape()
                .fill(FriendsPaint.heart)
                .frame(width: 16, height: 14)
                .offset(x: 26, y: -22)
        }
        .accessibilityHidden(true)
    }
}

struct FriendsGiftBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: 0xFF8FAB))
                .frame(width: 36, height: 32)
            Rectangle()
                .fill(Color(hex: 0xFFE7AD))
                .frame(width: 8, height: 32)
            Rectangle()
                .fill(Color(hex: 0xFFE7AD))
                .frame(width: 36, height: 8)
            Circle().fill(Color(hex: 0xFFE7AD)).frame(width: 10, height: 10).offset(x: -6, y: -18)
            Circle().fill(Color(hex: 0xFFE7AD)).frame(width: 10, height: 10).offset(x: 6, y: -18)
        }
        .accessibilityHidden(true)
    }
}
