import SwiftUI

/// Finch timings drawn on the rabbit. No Lottie, Rive, GIF, or wing art.
enum PackMotion {
    /// `Finch_Waiting_01.json`, frames 25...276 at 25 fps.
    static let waitingPeriod = (276.0 - 25.0) / 25.0
    /// `Loops/FinchieLoop_106_sleep-nest-bed.json`, 125 frames at 25 fps.
    static let nestPeriod = 125.0 / 25.0
    /// `Loops/FinchieLoop_002_run-wings-back.json`: one bounce every 6 frames.
    static let runPeriod = 6.0 / 25.0
    /// `assets/audio/eggHatch.m4a` movie header (timescale 1000, duration 827).
    static let hatchPeriod = 827.0 / 1000.0

    static func applyIdle(_ pose: inout GoobyPose, time t: Double) {
        let local = remainder(t, waitingPeriod)
        pose.breath = 1
        pose.squash = 1
        pose.hop = 0
        pose.blink = 1
        for beat in waitingBeats where local >= beat && local <= beat + 0.80 {
            waitingPulse(&pose, u: local - beat)
        }
        pose.earRight += CGFloat(sample(local, nearEar) * (16.0 / 28.0))
        pose.earLeft += CGFloat(sample(local, farEar) * (18.0 / 101.0))
        pose.headTilt = CGFloat(sample(local, glance))
        pose.tilt = CGFloat(sample(local, lean) * (5.0 / 13.0))
        pose.blink = waitingBlink(local)
    }

    /// Four seconds in, four seconds out. Not the Insights breath ring.
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

    /// Forest run. Main Control Y only: airborne, land at 0.12 s, airborne again. X stays put, so there is no sine.
    static func applyRun(_ pose: inout GoobyPose, time t: Double) {
        let local = remainder(t, runPeriod)
        let airborne = sample(local, runAir)
        pose.hop = CGFloat(-runLift * airborne)
        pose.squash = CGFloat(1 + 0.01 * (1 - airborne))
        pose.breath = 1
        pose.step = 0
        pose.earLeft = 0
        pose.earRight = 0
    }

    /// Nest sleep. Scale peaks at frame 62 (2.48 s): 102% wide, 98% tall. Ears stay put.
    static func applyNestSleep(_ pose: inout GoobyPose, time t: Double) {
        let local = remainder(t, nestPeriod)
        pose.squash = CGFloat(sample(local, nestScale))
        pose.breath = 1
        pose.hop = 0
        pose.blink = 0
    }

    /// One hatch pop per `eggHatch.m4a` length. The Rive rig is not sampled, so only the duration is the pack's.
    static func applyHatch(_ pose: inout GoobyPose, time t: Double) {
        let local = remainder(t, hatchPeriod)
        pose.hop = CGFloat(sample(local, hatchHop))
        pose.squash = CGFloat(sample(local, hatchSquash))
        pose.breath = 1
    }

    static func label(_ animation: GoobyAnimation) -> String {
        let key = "motion.a11y.\(animation.rawValue)"
        let text = GoobyIntentText.t(key)
        return text == key ? GoobyIntentText.t("motion.a11y.gooby") : text
    }

    private static let runLift = 35.0 * 320.0 / 800.0
    private static let nestPeak = 62.0 / 25.0
    private static let runLand = 3.0 / 25.0
    private static let squashWide = 24.09 / 23.09
    private static let squashTall = 22.8 / 23.09
    private static let waitingBeats = [1.08, 3.08, 5.32, 8.12]
    private static let hatchPress = hatchPeriod * 0.30
    private static let hatchCrest = hatchPeriod * 0.55

    private static func waitingPulse(_ pose: inout GoobyPose, u: Double) {
        pose.squash = CGFloat(sample(u, pulseSquash))
        pose.hop = CGFloat(sample(u, pulseHop))
    }

    /// Torso scale, as a ratio of the rest scale 23.09. y follows from `(2 - squash)`.
    private static let pulseSquash: [Knot] = [
        Knot(0, 1, 0.33, 0),
        Knot(0.28, squashWide, 0.33, 0, 0.67, 1),
        Knot(0.52, squashTall, 0.33, 0, 0.67, 1),
        Knot(0.80, 1, ix: 0.67, iy: 1)
    ]

    /// Head bob on the same beats. +10 / −8 is the rabbit's reading of the head-Y keys.
    private static let pulseHop: [Knot] = [
        Knot(0, 0, 0.33, 0),
        Knot(0.28, 10, 0.33, 0, 0.67, 1),
        Knot(0.52, -8, 0.33, 0, 0.67, 1),
        Knot(0.80, 0, ix: 0.67, iy: 1)
    ]

    /// Near wing, degrees. Peak −28°, drawn at 16°. The last key is frame 275 (10.0 s); the loop holds to 10.04 s.
    private static let nearEar: [Knot] = [
        Knot(0, 0, 0.34, 0),
        Knot(0.52, -28, 0.29, 0, 0.11, 1),
        Knot(0.88, -22, 0.31, 0.02, 0.65, 0.95),
        Knot(1.20, -26.31, 0.34, 0.74, 0.81, 1),
        Knot(3.08, -28, 0.33, 0, 0.67, 0.84),
        Knot(3.88, -15.52, 0.33, 3.67, 0.67, -2.67),
        Knot(5.32, -15.52, 0.33, 0.24, 0, 1),
        Knot(6.40, -4, 0.17, 0, 0.67, 1),
        Knot(8.12, -4, 0.17, 0, 0.67, 1.19),
        Knot(8.96, -15.52, 0.33, 0.17, 0, 1),
        Knot(10, 0)
    ]

    /// Far wing, degrees from its rest of −219°, then scaled by 18/101.
    private static let farEar: [Knot] = [
        Knot(0, 0, 0.33, 0),
        Knot(3.08, 0, 0.33, 0, 0.67, 1),
        Knot(3.88, 93, 0.33, 0, 0.67, 1),
        Knot(4.08, 85, 0.33, 0, 0.67, 1),
        Knot(5.32, 93, 0.33, 0, 0, 1),
        Knot(6.40, 101, 0.17, 0, 0.67, 1),
        Knot(8.12, 101, 0.17, 0, 0.67, 1),
        Knot(8.96, 93, 0.33, 0, 0, 1),
        Knot(10, 0)
    ]

    /// Head glance, degrees from the rest angle of −2°.
    private static let glance: [Knot] = [
        Knot(0, 0, 0.33, 0),
        Knot(1.08, -4, 0.33, 0, 0.67, 1),
        Knot(1.60, 0, 0.33, 0, 0.67, 1),
        Knot(3.88, 0, 0.33, 0, 0.67, 1),
        Knot(5.32, 0, 0.33, 0, 0, 1),
        Knot(6.40, 9, 0.17, 0, 0.67, 1),
        Knot(8.12, 9, 0.17, 0, 0.67, 1),
        Knot(8.96, 0, 0.33, 0, 0, 0.95),
        Knot(10, 0)
    ]

    /// Body lean, degrees from the rest angle. Scaled by 5/13 where it is applied.
    private static let lean: [Knot] = [
        Knot(0, 0),
        Knot(1.04, 0, 0.33, 0, 0, 1),
        Knot(2.04, -13, 0.33, 0, 0, 1),
        Knot(3.20, -13, 0.17, 0, 0, 1),
        Knot(3.96, 0, 0.17, 0, 0.67, 1),
        Knot(5.56, 0, 0.33, 0, 0, 1),
        Knot(6.56, -13, 0.33, 0, 0, 1),
        Knot(8.28, -13, 0.17, 0, 0, 1),
        Knot(9.04, 0)
    ]

    /// 1 in the air, 0 on the landing. Bezier 0.333 / 0.667, same as the run file.
    private static let runAir: [Knot] = [
        Knot(0, 1, 0.333, 0),
        Knot(runLand, 0, 0.333, 0, 0.667, 1),
        Knot(runPeriod, 1, ix: 0.667, iy: 1)
    ]

    /// Main Control scale: 100, 102 at 2.48 s, 100. With breath 1 the height is 0.98 at the peak.
    private static let nestScale: [Knot] = [
        Knot(0, 1, 0.333, 0),
        Knot(nestPeak, 1.02, 0.333, 0, 0.667, 1),
        Knot(nestPeriod, 1, ix: 0.667, iy: 1)
    ]

    private static let hatchHop: [Knot] = [
        Knot(0, 0, 0.333, 0),
        Knot(hatchPress, 4, 0.333, 0, 0.667, 1),
        Knot(hatchCrest, -runLift, 0.333, 0, 0.667, 1),
        Knot(hatchPeriod, 0, ix: 0.667, iy: 1)
    ]

    private static let hatchSquash: [Knot] = [
        Knot(0, 1, 0.333, 0),
        Knot(hatchPress, 1.06, 0.333, 0, 0.667, 1),
        Knot(hatchCrest, 0.96, 0.333, 0, 0.667, 1),
        Knot(hatchPeriod, 1, ix: 0.667, iy: 1)
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

    private struct Knot {
        var t: Double
        var v: Double
        var ox: Double
        var oy: Double
        var ix: Double?
        var iy: Double?

        init(_ t: Double, _ v: Double, _ ox: Double = 0, _ oy: Double = 0, ix: Double? = nil, iy: Double? = nil) {
            self.t = t
            self.v = v
            self.ox = ox
            self.oy = oy
            self.ix = ix
            self.iy = iy
        }

        init(_ t: Double, _ v: Double, _ ox: Double, _ oy: Double, _ ix: Double, _ iy: Double) {
            self.init(t, v, ox, oy, ix: ix, iy: iy)
        }
    }

    /// Lottie temporal bezier. Outgoing handle is on the left key, incoming handle on the right.
    /// A value influence outside 0...1.5 is not a unit ease (the wing key at 3.88 s stores 3.67 and −2.67), so that segment is linear.
    private static func sample(_ time: Double, _ knots: [Knot]) -> Double {
        guard let first = knots.first else { return 0 }
        if time <= first.t { return first.v }
        for index in 1..<knots.count {
            let left = knots[index - 1]
            let right = knots[index]
            if time <= right.t || index == knots.count - 1 {
                let span = right.t - left.t
                if span <= 0 || time >= right.t { return right.v }
                let u = (time - left.t) / span
                let eased = unitEase(u, left.ox, left.oy, right.ix, right.iy)
                return left.v + (right.v - left.v) * eased
            }
        }
        return knots[knots.count - 1].v
    }

    private static func unitEase(_ u: Double, _ x1: Double, _ y1: Double, _ x2: Double?, _ y2: Double?) -> Double {
        guard let x2, let y2 else { return u }
        if y1 < 0 || y2 < 0 || y1 > 1.5 || y2 > 1.5 { return u }
        func cx(_ t: Double) -> Double {
            let mt = 1 - t
            return 3 * mt * mt * t * x1 + 3 * mt * t * t * x2 + t * t * t
        }
        func cy(_ t: Double) -> Double {
            let mt = 1 - t
            return 3 * mt * mt * t * y1 + 3 * mt * t * t * y2 + t * t * t
        }
        func dx(_ t: Double) -> Double {
            let mt = 1 - t
            return 3 * mt * mt * x1 + 6 * mt * t * (x2 - x1) + 3 * t * t * (1 - x2)
        }
        var slope = dx(0)
        var step = 0.0
        while step <= 1 {
            slope = min(slope, dx(step))
            step += 0.025
        }
        if slope < -0.0001 { return u }
        var t = u
        for _ in 0..<16 {
            let derivative = dx(t)
            if abs(derivative) < 1e-9 { break }
            t = min(1, max(0, t - (cx(t) - u) / derivative))
        }
        if abs(cx(t) - u) > 0.001 { return u }
        return cy(t)
    }

    private static func remainder(_ time: Double, _ period: Double) -> Double {
        let value = time.truncatingRemainder(dividingBy: period)
        return value < 0 ? value + period : value
    }
}
