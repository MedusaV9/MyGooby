import SwiftUI
import UIKit

struct FriendsRewardSheet: View {
    var engine: GoobyEngine
    @Binding var book: FriendsBook
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var showAsk = false
    @State private var copied = false

    private var calm: Bool { systemReduce || engine.reduceMotion }
    private var paid: Bool { FriendsFirstGift.paid(engine) }
    private var code: String { GoobyFriendCode.make(profileID: engine.profile.id) }
    private var fill: CGFloat {
        switch min(book.pals.count, 3) {
        case 0: return 0.08
        case 1: return 0.2
        case 2: return 0.54
        default: return 1
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        track
                        VStack(spacing: 8) {
                            Text(engine.t("friends.reward.yours"))
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .tracking(1.1)
                                .foregroundStyle(Theme.ink.opacity(0.45))
                            Text(paid ? engine.t("friends.reward.done") : engine.t("friends.reward.body"))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                            if FriendsFirstGift.hasHood(engine) {
                                Text(engine.tf("friends.reward.closet", FriendsFirstGift.hoodName(engine)))
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Theme.ink.opacity(0.72))
                                    .multilineTextAlignment(.center)
                            }
                            if paid {
                                Text(engine.tf("friends.reward.now", engine.wallet.sparks))
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(FriendsFunPaint.ink)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)
                        codeRow
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 12)
                }
                bottomBar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(FriendsFunPaint.ink)
                    .frame(width: 36, height: 36)
                    .background(.white, in: Circle())
            }
            .buttonStyle(FriendsPressStyle(calm: calm))
            .accessibilityLabel(engine.t("friends.fun.close"))
            .padding(.leading, 16)
            .padding(.top, 16)
        }
        .sheet(isPresented: $showAsk) {
            FriendsAddSheet(engine: engine, book: $book)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.white)
        .presentationCornerRadius(28)
    }

    private var header: some View {
        ZStack {
            FriendsFunPaint.header
            HStack {
                StageStill(name: "still-tree")
                    .frame(width: 110, height: 140)
                    .stageSway(amount: 1.4, seconds: 3.1, still: calm)
                Spacer()
                StageStill(name: "still-tree-2")
                    .frame(width: 110, height: 140)
                    .stageSway(amount: 1.2, seconds: 3.5, still: calm)
            }
            .colorMultiply(Color(hex: 0x2F7A34))
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
            if !calm {
                FriendsRayBurst()
                    .frame(width: 280, height: 200)
                    .offset(y: -10)
            }
            VStack(spacing: 10) {
                HStack(alignment: .bottom, spacing: 4) {
                    GoobyMark().scaleEffect(1.02)
                    FriendsInviteEgg(calm: calm).frame(width: 108, height: 118)
                    FriendsShyHare()
                }
                .padding(.top, 48)
                Text(engine.t("friends.reward.title"))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(engine.t("friends.reward.sub"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 0, bottomLeading: 28, bottomTrailing: 28, topTrailing: 0)))
    }

    private var track: some View {
        VStack(spacing: 8) {
            ZStack {
                VStack {
                    Spacer(minLength: 0)
                    ZStack(alignment: .leading) {
                        Capsule().fill(FriendsFunPaint.track).frame(height: 8)
                        Capsule()
                            .fill(FriendsFunPaint.button)
                            .frame(height: 8)
                            .scaleEffect(x: fill, y: 1, anchor: .leading)
                    }
                    .padding(.horizontal, 36)
                    Spacer(minLength: 0)
                }
                HStack {
                    FriendsBearHood(ring: true, paid: paid)
                    Spacer()
                    FriendsPenguinFace()
                    Spacer()
                    FriendsCowFace()
                }
            }
            .frame(height: 86)
            .padding(.horizontal, 22)
            HStack {
                Text(engine.t("friends.reward.n1"))
                Spacer()
                Text(engine.t("friends.reward.n2"))
                Spacer()
                Text(engine.t("friends.reward.n3"))
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 18)
        }
    }

    private var codeRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.t("friends.tree.yours"))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                Text(code)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.ink)
                    .textSelection(.enabled)
            }
            Spacer()
            Button(engine.t("friends.tree.copy")) {
                UIPasteboard.general.string = code
                copied = true
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(FriendsFunPaint.ink)
        }
        .padding(14)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            ShareLink(item: engine.tf("friends.reward.share", code)) {
                Text(engine.t("friends.reward.invite"))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(FriendsFunPaint.button, in: Capsule())
            }
            .buttonStyle(FriendsPressStyle(calm: calm))
            .frame(maxWidth: .infinity)
            Button { showAsk = true } label: {
                Text(engine.t("friends.reward.asked"))
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.ink.opacity(0.78))
            }
            .buttonStyle(.plain)
            if copied {
                Text(engine.t("friends.tree.copied"))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FriendsFunPaint.ink)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.white)
    }
}

struct FriendsRayBurst: View {
    var body: some View {
        StageClip(name: "clip-sparkles", reduceMotion: false)
            .accessibilityHidden(true)
    }
}

struct FriendsRayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.28
        for index in 0..<12 {
            let mid = (Double(index) / 12) * Double.pi * 2 - Double.pi / 2
            let spread = Double.pi / 28
            path.move(to: CGPoint(x: center.x + CGFloat(cos(mid - spread)) * inner, y: center.y + CGFloat(sin(mid - spread)) * inner))
            path.addLine(to: CGPoint(x: center.x + CGFloat(cos(mid)) * outer, y: center.y + CGFloat(sin(mid)) * outer))
            path.addLine(to: CGPoint(x: center.x + CGFloat(cos(mid + spread)) * inner, y: center.y + CGFloat(sin(mid + spread)) * inner))
            path.closeSubpath()
        }
        return path
    }
}

struct FriendsInviteEgg: View {
    var calm: Bool

    var body: some View {
        StageClip(name: "clip-egg", reduceMotion: calm, loop: false)
            .accessibilityHidden(true)
    }
}

struct FriendsShyHare: View {
    var body: some View {
        ZStack {
            Capsule().fill(FriendsPaint.creamShade).frame(width: 16, height: 34).rotationEffect(.degrees(-18)).offset(x: -16, y: -28)
            Capsule().fill(FriendsPaint.creamShade).frame(width: 16, height: 34).rotationEffect(.degrees(18)).offset(x: 16, y: -28)
            Capsule().fill(FriendsPaint.cream).frame(width: 12, height: 30).rotationEffect(.degrees(-18)).offset(x: -16, y: -28)
            Capsule().fill(FriendsPaint.cream).frame(width: 12, height: 30).rotationEffect(.degrees(18)).offset(x: 16, y: -28)
            Circle().fill(FriendsPaint.creamShade).frame(width: 58, height: 58)
            Circle().fill(FriendsPaint.cream).frame(width: 56, height: 56).offset(y: -1)
            Capsule().fill(FriendsPaint.creamShade).frame(width: 12, height: 18).rotationEffect(.degrees(28)).offset(x: -14, y: -6)
            Capsule().fill(FriendsPaint.creamShade).frame(width: 12, height: 18).rotationEffect(.degrees(-28)).offset(x: 14, y: -6)
            Ellipse().fill(FriendsPaint.nose).frame(width: 8, height: 6).offset(y: 12)
        }
        .frame(width: 78, height: 96)
        .accessibilityHidden(true)
    }
}

struct FriendsBearHood: View {
    var ring: Bool
    var paid: Bool
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        ZStack {
            Circle().fill(Color.white)
            if ring {
                Circle().stroke(FriendsFunPaint.button, lineWidth: 3)
            }
            StageStill(name: "still-hood")
                .padding(8)
            StageClip(name: "clip-stone", reduceMotion: reduce)
                .frame(width: 26, height: 26)
                .offset(x: -22, y: 20)
            if paid {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(FriendsFunPaint.button)
                    .background(Circle().fill(.white).padding(-1))
                    .offset(x: 22, y: 22)
            }
        }
        .frame(width: 72, height: 72)
        .accessibilityHidden(true)
    }
}

struct FriendsStone: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white)
            Star(points: 5)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFF8FAB), Color(hex: 0xFFE7AD), Color(hex: 0x7ED0F2), Color(hex: 0xB7F0C8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(4)
        }
    }
}

struct FriendsPenguinFace: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(FriendsFunPaint.card)
            StageStill(name: "still-penguin")
                .padding(6)
        }
        .frame(width: 64, height: 64)
        .accessibilityHidden(true)
    }
}

struct FriendsCowFace: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(FriendsFunPaint.card)
            StageStill(name: "still-cow")
                .padding(6)
        }
        .frame(width: 64, height: 64)
        .accessibilityHidden(true)
    }
}
