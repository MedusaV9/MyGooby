import Foundation

enum BreathPhaseKind: Equatable {
    case inhale
    case hold
    case exhale
    case rest
}

struct BreathPattern: Equatable, Identifiable {
    var id: String
    var inhale: Double
    var holdIn: Double
    var exhale: Double
    var holdOut: Double
    var cycles: Int

    var cycleLength: Double { max(0, inhale) + max(0, holdIn) + max(0, exhale) + max(0, holdOut) }

    static let calm = BreathPattern(id: "calm", inhale: 4, holdIn: 2, exhale: 6, holdOut: 0, cycles: 6)
    static let box = BreathPattern(id: "box", inhale: 4, holdIn: 4, exhale: 4, holdOut: 4, cycles: 4)
    static let sleep = BreathPattern(id: "sleep", inhale: 4, holdIn: 7, exhale: 8, holdOut: 0, cycles: 4)
    static let stress = BreathPattern(id: "stress", inhale: 4, holdIn: 0, exhale: 6, holdOut: 2, cycles: 6)

    static let presets: [BreathPattern] = [.calm, .box, .sleep, .stress]

    func clamped() -> BreathPattern {
        var copy = self
        copy.inhale = min(12, max(1, copy.inhale))
        copy.holdIn = min(12, max(0, copy.holdIn))
        copy.exhale = min(12, max(1, copy.exhale))
        copy.holdOut = min(12, max(0, copy.holdOut))
        copy.cycles = min(20, max(1, copy.cycles))
        return copy
    }

    func phases() -> [(BreathPhaseKind, Double)] {
        var items: [(BreathPhaseKind, Double)] = []
        if inhale > 0 { items.append((.inhale, inhale)) }
        if holdIn > 0 { items.append((.hold, holdIn)) }
        if exhale > 0 { items.append((.exhale, exhale)) }
        if holdOut > 0 { items.append((.rest, holdOut)) }
        return items
    }
}

struct BreathFrame: Equatable {
    var kind: BreathPhaseKind
    var phaseProgress: Double
    var cycleIndex: Int
    var cycleCount: Int
    var finished: Bool
    var scale: Double
}

enum BreathEngine {
    static func frame(elapsed rawElapsed: TimeInterval, pattern rawPattern: BreathPattern) -> BreathFrame {
        let pattern = rawPattern.clamped()
        let phases = pattern.phases()
        let empty = BreathFrame(kind: .inhale, phaseProgress: 0, cycleIndex: 0, cycleCount: pattern.cycles, finished: true, scale: 0.62)
        guard pattern.cycleLength > 0, !phases.isEmpty else { return empty }
        let elapsed = max(0, rawElapsed)
        let total = pattern.cycleLength * Double(pattern.cycles)
        if elapsed >= total {
            return BreathFrame(kind: .rest, phaseProgress: 1, cycleIndex: pattern.cycles, cycleCount: pattern.cycles, finished: true, scale: 0.62)
        }
        let cycleIndex = min(pattern.cycles - 1, Int(elapsed / pattern.cycleLength))
        let into = elapsed - Double(cycleIndex) * pattern.cycleLength
        var cursor = 0.0
        for (index, phase) in phases.enumerated() {
            let end = cursor + phase.1
            let isLast = index == phases.count - 1
            if into < end || isLast {
                let progress = min(1, max(0, (into - cursor) / phase.1))
                return BreathFrame(
                    kind: phase.0,
                    phaseProgress: progress,
                    cycleIndex: cycleIndex,
                    cycleCount: pattern.cycles,
                    finished: false,
                    scale: scale(kind: phase.0, progress: progress)
                )
            }
            cursor = end
        }
        return empty
    }

    static func scale(kind: BreathPhaseKind, progress: Double) -> Double {
        switch kind {
        case .inhale:
            return 0.62 + 0.38 * progress
        case .hold:
            return 1
        case .exhale:
            return 1 - 0.38 * progress
        case .rest:
            return 0.62
        }
    }

    static func selfCheck() -> [String] {
        var failures: [String] = []
        let start = frame(elapsed: 0, pattern: .box)
        if start.kind != .inhale || start.cycleIndex != 0 || start.finished {
            failures.append("box breathing should start on an inhale")
        }
        if frame(elapsed: 4, pattern: .box).kind != .hold {
            failures.append("box breathing at 4s should hold")
        }
        if frame(elapsed: 8, pattern: .box).kind != .exhale {
            failures.append("box breathing at 8s should exhale")
        }
        if frame(elapsed: 12, pattern: .box).kind != .rest {
            failures.append("box breathing at 12s should rest")
        }
        let next = frame(elapsed: 16, pattern: .box)
        if next.kind != .inhale || next.cycleIndex != 1 {
            failures.append("box breathing at 16s should be the next inhale")
        }
        if !frame(elapsed: 64, pattern: .box).finished {
            failures.append("box breathing should finish after 4 cycles")
        }
        if frame(elapsed: 63.9, pattern: .box).finished {
            failures.append("box breathing should still be running just before the end")
        }
        let custom = BreathPattern(id: "custom", inhale: 3, holdIn: 0, exhale: 5, holdOut: 1, cycles: 2).clamped()
        if frame(elapsed: 3, pattern: custom).kind != .exhale {
            failures.append("a zero hold should be skipped")
        }
        return failures
    }
}

struct FocusSession: Codable, Equatable, Identifiable {
    var id: UUID
    var plannedSeconds: Int
    var endsAt: Date?
    var pausedRemaining: TimeInterval?
    var finished: Bool
}

enum FocusMath {
    static func remaining(session: FocusSession, now: Date) -> TimeInterval {
        if session.finished { return 0 }
        if let paused = session.pausedRemaining { return max(0, paused) }
        if let endsAt = session.endsAt { return max(0, endsAt.timeIntervalSince(now)) }
        return Double(max(0, session.plannedSeconds))
    }

    static func selfCheck() -> [String] {
        var failures: [String] = []
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var session = FocusSession(id: UUID(), plannedSeconds: 60, endsAt: nil, pausedRemaining: 10, finished: false)
        if remaining(session: session, now: now) != 10 {
            failures.append("paused focus timer should keep its remaining time")
        }
        session.pausedRemaining = nil
        session.endsAt = now.addingTimeInterval(30)
        if abs(remaining(session: session, now: now) - 30) > 0.001 {
            failures.append("running focus timer should count down to endsAt")
        }
        session.endsAt = now.addingTimeInterval(-5)
        if remaining(session: session, now: now) != 0 {
            failures.append("an elapsed focus timer should report zero")
        }
        session.finished = true
        session.pausedRemaining = 20
        if remaining(session: session, now: now) != 0 {
            failures.append("a finished focus timer stays at zero")
        }
        return failures
    }
}

struct MovementStep: Identifiable, Equatable {
    var id: String
    var title: CareString
    var detail: CareString
    var seconds: Int
}

struct MovementRoutine: Identifiable, Equatable {
    var id: String
    var title: CareString
    var summary: CareString
    var steps: [MovementStep]
}

enum MovementCatalog {
    static let routines: [MovementRoutine] = [
        MovementRoutine(
            id: "stretch",
            title: .moveStretch,
            summary: .moveLeadStretch,
            steps: [
                MovementStep(id: "stretch-neck", title: .stepNeck, detail: .stepNeckDetail, seconds: 30),
                MovementStep(id: "stretch-side", title: .stepSide, detail: .stepSideDetail, seconds: 40),
                MovementStep(id: "stretch-roll", title: .stepRoll, detail: .stepRollDetail, seconds: 30),
                MovementStep(id: "stretch-fold", title: .stepFold, detail: .stepFoldDetail, seconds: 40),
                MovementStep(id: "stretch-tall", title: .stepTall, detail: .stepTallDetail, seconds: 20)
            ]
        ),
        MovementRoutine(
            id: "shoulders",
            title: .moveShoulders,
            summary: .moveLeadShoulders,
            steps: [
                MovementStep(id: "shoulder-shrug", title: .stepShrug, detail: .stepShrugDetail, seconds: 30),
                MovementStep(id: "shoulder-circle", title: .stepCircle, detail: .stepCircleDetail, seconds: 40),
                MovementStep(id: "shoulder-open", title: .stepOpen, detail: .stepOpenDetail, seconds: 40),
                MovementStep(id: "shoulder-hug", title: .stepHug, detail: .stepHugDetail, seconds: 30)
            ]
        ),
        MovementRoutine(
            id: "break",
            title: .moveBreak,
            summary: .moveLeadBreak,
            steps: [
                MovementStep(id: "break-stand", title: .stepStand, detail: .stepStandDetail, seconds: 20),
                MovementStep(id: "break-march", title: .stepMarch, detail: .stepMarchDetail, seconds: 40),
                MovementStep(id: "break-wrist", title: .stepWrist, detail: .stepWristDetail, seconds: 30),
                MovementStep(id: "break-shake", title: .stepShake, detail: .stepShakeDetail, seconds: 20),
                MovementStep(id: "break-easy", title: .stepEasy, detail: .stepEasyDetail, seconds: 20)
            ]
        ),
        MovementRoutine(
            id: "relax",
            title: .moveRelax,
            summary: .moveLeadRelax,
            steps: [
                MovementStep(id: "relax-jaw", title: .stepJaw, detail: .stepJawDetail, seconds: 25),
                MovementStep(id: "relax-hands", title: .stepHands, detail: .stepHandsDetail, seconds: 25),
                MovementStep(id: "relax-shoulders", title: .stepDrop, detail: .stepDropDetail, seconds: 25),
                MovementStep(id: "relax-seat", title: .stepSeat, detail: .stepSeatDetail, seconds: 40),
                MovementStep(id: "relax-breath", title: .stepSlow, detail: .stepSlowDetail, seconds: 30)
            ]
        )
    ]
}

enum GroundingCatalog {
    static let sensePrompts: [CareString] = [
        .groundSee, .groundTouch, .groundHear, .groundSmell, .groundTaste
    ]
}
