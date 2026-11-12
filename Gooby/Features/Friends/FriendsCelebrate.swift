import SwiftUI

/// Two cream rabbits high-five. The clock is `Finch_TwoBirbsHighFive_AdultAdult_01.json`
/// (frames 6...206 at 25 fps, 8.00 s). Hearts are `clip-heartbub-f12-r3`: twelve frames at
/// 3 fps, the 4.00 s length of `heart-bubbling.json` (96 frames at 24 fps).
struct FriendsCelebration: View {
    var calm: Bool
    var hearts: Bool
    var label: String

    var body: some View {
        ZStack {
            FriendsHighFive(calm: calm)
            if hearts, !calm {
                StageClip(name: "clip-heartbub", reduceMotion: false)
                    .frame(width: 96, height: 196)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 196)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

struct FriendsHighFive: View {
    var calm: Bool
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: calm ? 30 : 1.0 / 30.0, paused: calm)) { timeline in
            let tau = calm
                ? FriendsHighFiveMotion.still
                : min(FriendsHighFiveMotion.period, timeline.date.timeIntervalSince(start))
            FriendsHighFiveStage(pose: FriendsHighFiveMotion.pose(at: tau))
        }
        .accessibilityHidden(true)
    }
}

enum FriendsHighFiveMotion {
    /// Frames 6...206 at 25 fps.
    static let period = (206.0 - 6.0) / 25.0
    /// Paw meets paw at frame 106.39.
    static let still = (106.39 - 6.0) / 25.0

    struct Pose {
        var slide: CGFloat
        var hop: CGFloat
        var paw: CGFloat
        var lean: CGFloat
        var squash: CGFloat
    }

    static func pose(at tau: Double) -> Pose {
        let frame = 6.0 + min(max(tau, 0), period) * 25.0
        let x = sample(frame, placeX)
        let y = sample(frame, placeY)
        let slide = (x - 1008.54) / (1431.27 - 1008.54)
        let hop = (345.0 - y) / (345.0 - 186.46)
        let wing = frame >= 83 ? linear(frame, wingTurn) : -53.0
        let paw = min(1, max(0, (-53.0 - wing) / 149.0))
        return Pose(
            slide: CGFloat(min(1, max(0, slide))),
            hop: CGFloat(max(0, hop)),
            paw: CGFloat(paw),
            lean: CGFloat(sample(frame, leanKeys)),
            squash: CGFloat(landSquash(frame))
        )
    }

    private static func landSquash(_ frame: Double) -> Double {
        var extra = 0.0
        for bump in [(15.0, 2.2), (119.0, 2.4)] {
            let distance = abs(frame - bump.0) / bump.1
            if distance < 1 {
                let falloff = (1 - distance) * (1 - distance)
                extra = max(extra, falloff)
            }
        }
        return 1 + 0.08 * extra
    }

    private struct EaseKey {
        var frame: Double
        var value: Double
        var outX: Double
        var outY: Double
        var inX: Double
        var inY: Double
    }

    private struct LinearKey {
        var frame: Double
        var value: Double
    }

    private static let placeX: [EaseKey] = [
        EaseKey(frame: 6.25, value: 1431.27, outX: 0.72, outY: 0, inX: 0.67, inY: 1),
        EaseKey(frame: 7.29, value: 1340.36, outX: 0.61, outY: 0.01, inX: 0.59, inY: 1),
        EaseKey(frame: 15, value: 1008.54, outX: 1, outY: 1, inX: 0.59, inY: 0.59),
        EaseKey(frame: 91.58, value: 1008.54, outX: 0.15, outY: 0, inX: 0, inY: 1),
        EaseKey(frame: 111, value: 1008.43, outX: 1, outY: 0, inX: 0.79, inY: 1),
        EaseKey(frame: 118.96, value: 1008.43, outX: 0, outY: 0, inX: 0, inY: 0)
    ]

    private static let placeY: [EaseKey] = [
        EaseKey(frame: 6.25, value: 117.73, outX: 0.72, outY: 0, inX: 0.67, inY: 1),
        EaseKey(frame: 7.29, value: 117.73, outX: 0.61, outY: 0.01, inX: 0.59, inY: 1),
        EaseKey(frame: 15, value: 345, outX: 1, outY: 1, inX: 0.59, inY: 0.59),
        EaseKey(frame: 91.58, value: 345, outX: 0.15, outY: 0, inX: 0, inY: 1),
        EaseKey(frame: 111, value: 186.46, outX: 1, outY: 0, inX: 0.79, inY: 1),
        EaseKey(frame: 118.96, value: 345, outX: 0, outY: 0, inX: 0, inY: 0)
    ]

    private static let leanKeys: [EaseKey] = [
        EaseKey(frame: 7.29, value: -6, outX: 0.61, outY: 0.8, inX: 0, inY: 1),
        EaseKey(frame: 15, value: 0, outX: 0, outY: 0, inX: 0, inY: 0)
    ]

    /// Inner wing, degrees, from frame 83. Linear between the file's keys.
    private static let wingTurn: [LinearKey] = [
        LinearKey(frame: 83, value: -53),
        LinearKey(frame: 89, value: -76),
        LinearKey(frame: 91, value: -73),
        LinearKey(frame: 98, value: -53.68),
        LinearKey(frame: 103.17, value: -89.12),
        LinearKey(frame: 106.39, value: -202),
        LinearKey(frame: 108.71, value: -147.61),
        LinearKey(frame: 112, value: -143.5),
        LinearKey(frame: 115, value: -164.24),
        LinearKey(frame: 118.96, value: -89.01),
        LinearKey(frame: 119.54, value: -56),
        LinearKey(frame: 123.96, value: -53),
        LinearKey(frame: 129.96, value: -57),
        LinearKey(frame: 135.54, value: -57)
    ]

    private static func sample(_ frame: Double, _ keys: [EaseKey]) -> Double {
        if frame <= keys[0].frame { return keys[0].value }
        if frame >= keys[keys.count - 1].frame { return keys[keys.count - 1].value }
        var index = 0
        while index < keys.count - 2, frame > keys[index + 1].frame { index += 1 }
        let start = keys[index]
        let end = keys[index + 1]
        let span = end.frame - start.frame
        let unit = span == 0 ? 1 : (frame - start.frame) / span
        let eased = unitEase(unit, start.outX, start.outY, start.inX, start.inY)
        return start.value + (end.value - start.value) * eased
    }

    private static func linear(_ frame: Double, _ keys: [LinearKey]) -> Double {
        if frame <= keys[0].frame { return keys[0].value }
        if frame >= keys[keys.count - 1].frame { return keys[keys.count - 1].value }
        var index = 0
        while index < keys.count - 2, frame > keys[index + 1].frame { index += 1 }
        let start = keys[index]
        let end = keys[index + 1]
        let span = end.frame - start.frame
        let unit = span == 0 ? 1 : (frame - start.frame) / span
        return start.value + (end.value - start.value) * unit
    }

    /// Temporal bezier. `out` leaves the first key, `in` arrives at the next.
    private static func unitEase(_ x: Double, _ outX: Double, _ outY: Double, _ inX: Double, _ inY: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        var u = x
        for _ in 0..<16 {
            let a = 1 - u
            let along = 3 * a * a * u * outX + 3 * a * u * u * inX + u * u * u
            let slope = 3 * a * a * outX + 6 * a * u * (inX - outX) + 3 * u * u * (1 - inX)
            if abs(slope) < 1e-6 { break }
            u = min(1, max(0, u - (along - x) / slope))
        }
        let guess = 1 - u
        let along = 3 * guess * guess * u * outX + 3 * guess * u * u * inX + u * u * u
        if abs(along - x) > 0.002 {
            var lo = 0.0
            var hi = 1.0
            for _ in 0..<24 {
                let mid = (lo + hi) / 2
                let span = 1 - mid
                let probe = 3 * span * span * mid * outX + 3 * span * mid * mid * inX + mid * mid * mid
                if probe < x { lo = mid } else { hi = mid }
                u = mid
            }
        }
        let span = 1 - u
        return 3 * span * span * u * outY + 3 * span * u * u * inY + u * u * u
    }
}

private struct FriendsHighFiveStage: View {
    var pose: FriendsHighFiveMotion.Pose

    var body: some View {
        let lift = pose.hop * 42
        let travel = pose.slide * 86
        ZStack {
            shadow(x: -78 - travel, hop: pose.hop)
            shadow(x: 78 + travel, hop: pose.hop)
            hare(face: 1)
                .offset(x: -78 - travel, y: 28 - lift)
            hare(face: -1)
                .offset(x: 78 + travel, y: 28 - lift)
            contact
                .offset(y: -8 - lift)
                .opacity(pose.paw > 0.62 ? Double((pose.paw - 0.62) / 0.38) : 0.0)
                .scaleEffect(0.65 + 0.4 * pose.paw)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func shadow(x: CGFloat, hop: CGFloat) -> some View {
        let lift = min(hop, 1)
        return Ellipse()
            .fill(Color.black.opacity(Double(0.16 * (1 - 0.55 * lift))))
            .frame(width: 50 * (1 - 0.28 * lift), height: 10)
            .offset(x: x, y: 78)
    }

    private func hare(face: CGFloat) -> some View {
        let air = min(pose.hop, 1)
        let tall = (1 + 0.04 * air) / pose.squash
        let wide = pose.squash / (1 + 0.015 * air)
        return FriendsHighFiveHare(paw: pose.paw)
            .rotationEffect(.degrees(Double(pose.lean)), anchor: .bottom)
            .scaleEffect(x: wide, y: tall, anchor: .bottom)
            .scaleEffect(x: face, y: 1)
    }

    private var contact: some View {
        ZStack {
            FriendsHeartShape().fill(FriendsPaint.heart).frame(width: 14, height: 13).rotationEffect(.degrees(-16)).offset(x: -18, y: 6)
            FriendsHeartShape().fill(FriendsPaint.heart).frame(width: 18, height: 16).offset(y: -12)
            FriendsHeartShape().fill(FriendsPaint.heart).frame(width: 12, height: 11).rotationEffect(.degrees(14)).offset(x: 18, y: 8)
        }
        .accessibilityHidden(true)
    }
}

/// Cream rabbit facing right, one paw ready to meet a friend.
private struct FriendsHighFiveHare: View {
    var paw: CGFloat

    var body: some View {
        ZStack {
            Capsule().fill(FriendsPaint.creamShade).frame(width: 16, height: 12).offset(x: -14, y: 50)
            Capsule().fill(FriendsPaint.creamShade).frame(width: 16, height: 12).offset(x: 8, y: 50)
            Ellipse().fill(FriendsPaint.creamShade).frame(width: 56, height: 42).offset(y: 38)
            Ellipse().fill(FriendsPaint.cream).frame(width: 54, height: 40).offset(y: 36)
            Ellipse().fill(Color.white.opacity(0.42)).frame(width: 26, height: 18).offset(y: 40)
            raisedPaw
            GoobyMark().offset(y: -10)
        }
        .frame(width: 108, height: 124)
    }

    private var raisedPaw: some View {
        let length = 32 + 26 * paw
        return ZStack(alignment: .top) {
            Capsule()
                .fill(FriendsPaint.creamShade)
                .frame(width: 16, height: length)
            Capsule()
                .fill(FriendsPaint.cream)
                .frame(width: 13, height: max(CGFloat(8), length - 2))
            Circle()
                .fill(FriendsPaint.cream)
                .overlay(Circle().stroke(FriendsPaint.creamShade, lineWidth: 1))
                .frame(width: 20, height: 20)
                .offset(y: length - 14)
            Circle()
                .fill(FriendsPaint.cheek)
                .frame(width: 7, height: 7)
                .offset(y: length - 8)
        }
        .frame(width: 24, height: 72, alignment: .top)
        .rotationEffect(.degrees(Double(-38 - 94 * paw)), anchor: .top)
        .offset(x: 22, y: 22)
    }
}
