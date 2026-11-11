import SwiftUI
import UIKit

/// Motion copied from the 25 fps waiting, nest-sleep, and jog loops onto the drawn rabbit.
enum GoobyStageMotion {
    /// Waiting loop, frames 25...276.
    static let idlePeriod = (276.0 - 25.0) / 25.0

    static func applyIdle(_ pose: inout GoobyPose, time t: Double) {
        let local = remainder(t, idlePeriod)
        pose.breath = 1
        pose.squash = 1
        pose.hop = 0
        pose.blink = 1
        for beat in idleBeats where local >= beat && local <= beat + 0.80 {
            waitingPulse(&pose, u: local - beat)
        }
        pose.earRight += CGFloat(sample(local, knots: nearEar) * (16.0 / 28.0))
        pose.earLeft += CGFloat(sample(local, knots: farEar) * (18.0 / 101.0))
        pose.headTilt = CGFloat(sample(local, knots: glance))
        pose.tilt = CGFloat(sample(local, knots: lean) * (5.0 / 13.0))
        pose.blink = waitingBlink(local)
    }

    /// Four seconds in, four seconds out. Chest scale only.
    static func applyBreathe(_ pose: inout GoobyPose, time t: Double) {
        let cycle = remainder(t, 8)
        let phase = cycle <= 4 ? cycle / 4 : (8 - cycle) / 4
        let eased = 0.5 - 0.5 * cos(phase * .pi)
        pose.breath = 1 + 0.06 * CGFloat(eased)
        pose.squash = 1
    }

    /// One ear reaches its peak at 0.36 s and settles by 0.70 s. The other ear follows half a beat later.
    static func applyEars(_ pose: inout GoobyPose, time t: Double) {
        let local = remainder(t, 1.4)
        pose.earRight += CGFloat(earFlick(local))
        pose.earLeft -= CGFloat(earFlick(remainder(local + 0.7, 1.4)))
    }

    /// Jog cycle: one bounce every 6 frames (0.24 s), squash on the landing.
    static func applyTravelHop(_ pose: inout GoobyPose, time t: Double) {
        let local = remainder(t, 0.24) / 0.24
        let up = cos(local * 2 * .pi)
        pose.hop = CGFloat(-up) * 18
        pose.squash = 1 + 0.05 * CGFloat(max(0, -up))
        pose.breath = 1
        pose.step = CGFloat(sin(local * 2 * .pi))
        pose.earLeft = pose.step * 5
        pose.earRight = -pose.step * 5
    }

    /// Nest sleep: one breath across 5 seconds, eyes closed, ears drift with the inhale.
    static func applyNestSleep(_ pose: inout GoobyPose, time t: Double) {
        let local = remainder(t, 5)
        let phase = local <= 2.5 ? local / 2.5 : (5 - local) / 2.5
        let eased = CGFloat(0.5 - 0.5 * cos(phase * .pi))
        pose.squash = 1 + 0.02 * eased
        pose.breath = 1
        pose.hop = 0
        pose.earRight += 8 * eased
        pose.earLeft += 2 * eased
        pose.blink = 0
    }

    private static let idleBeats = [1.08, 3.08, 5.32, 8.12]

    private static func waitingPulse(_ pose: inout GoobyPose, u: Double) {
        pose.squash = CGFloat(sample(u, knots: [
            (0, 1), (0.28, 1.043), (0.52, 0.987), (0.80, 1)
        ]))
        pose.hop = CGFloat(sample(u, knots: [
            (0, 0), (0.28, 10), (0.52, -8), (0.80, 0)
        ]))
    }

    /// Near ear, degrees, loop-local seconds. Peak is −28°.
    private static let nearEar: [(Double, Double)] = [
        (0, 0), (0.52, -28), (0.88, -22), (1.20, -26.31), (3.08, -28),
        (3.88, -15.52), (5.32, -15.52), (6.40, -4), (8.12, -4),
        (8.96, -15.52), (10.04, 0)
    ]

    /// Far ear lift, as a delta from its rest angle.
    private static let farEar: [(Double, Double)] = [
        (0, 0), (3.08, 0), (3.88, 93), (4.08, 85), (5.32, 93),
        (6.40, 101), (8.12, 101), (8.96, 93), (10.04, 0)
    ]

    /// Head glance, degrees from the rest pose.
    private static let glance: [(Double, Double)] = [
        (0, 0), (1.08, -4), (1.60, 0), (5.32, 0), (6.40, 9), (8.12, 9), (8.96, 0), (10.04, 0)
    ]

    /// Body lean, degrees from the rest pose. Scaled down where it is applied.
    private static let lean: [(Double, Double)] = [
        (0, 0), (1.04, 0), (2.04, -13), (3.20, -13), (3.96, 0),
        (5.56, 0), (6.56, -13), (8.28, -13), (9.04, 0), (10.04, 0)
    ]

    /// Eye closes copied from the waiting loop: (open, shut, open) in loop-local seconds.
    private static let blinks: [(Double, Double, Double)] = [
        (0.32, 0.41, 0.56),
        (0.56, 0.65, 0.80),
        (3.08, 3.17, 3.32),
        (4.12, 4.21, 4.36),
        (4.36, 4.45, 4.60),
        (7.52, 7.595, 7.72),
        (7.72, 7.795, 7.92),
        (9.32, 9.44, 9.64)
    ]

    private static func waitingBlink(_ local: Double) -> CGFloat {
        var value = 1.0
        for (open, shut, reopen) in blinks {
            guard local >= open, local <= reopen, shut > open, reopen > shut else { continue }
            if local <= shut {
                let p = (local - open) / (shut - open)
                value = min(value, 1 - p)
            } else {
                let p = (local - shut) / (reopen - shut)
                value = min(value, p)
            }
        }
        return CGFloat(value)
    }

    private static func earFlick(_ local: Double) -> Double {
        guard local >= 0, local <= 0.70 else { return 0 }
        if local <= 0.36 { return 16 * (local / 0.36) }
        return 16 * (1 - (local - 0.36) / 0.34)
    }

    private static func sample(_ time: Double, knots: [(Double, Double)]) -> Double {
        guard let first = knots.first else { return 0 }
        if time <= first.0 { return first.1 }
        for index in 1..<knots.count {
            let left = knots[index - 1]
            let right = knots[index]
            if time <= right.0 {
                let span = right.0 - left.0
                if span <= 0 { return right.1 }
                let p = (time - left.0) / span
                return left.1 + (right.1 - left.1) * p
            }
        }
        return knots[knots.count - 1].1
    }

    private static func remainder(_ time: Double, _ period: Double) -> Double {
        let value = time.truncatingRemainder(dividingBy: period)
        return value < 0 ? value + period : value
    }
}

/// Stage plates shipped in the app bundle. Missing art falls back to the drawn scenes.
enum GoobyStageArt {
    private static var cache: [String: UIImage] = [:]
    private static var missing = Set<String>()

    static func image(named name: String) -> UIImage? {
        if let cached = cache[name] { return cached }
        if missing.contains(name) { return nil }
        if let image = load(named: name) {
            cache[name] = image
            return image
        }
        missing.insert(name)
        return nil
    }

    private static func load(named name: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = image(at: url) {
            return image
        }
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return nil }
        for case let url as URL in enumerator {
            if url.pathExtension.lowercased() == "png",
               url.deletingPathExtension().lastPathComponent == name,
               let image = image(at: url) {
                return image
            }
        }
        return nil
    }

    private static func image(at url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
