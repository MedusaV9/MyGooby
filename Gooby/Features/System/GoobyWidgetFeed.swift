import SwiftUI
import UIKit

@MainActor
enum GoobyWidgetFeed {
    private static let signatureKey = "system.portrait.signature"
    private static var attemptedSignature: String?

    // Widgets and Live Activities count real time. The engine may run on shifted dev time.
    static func snapshot(_ engine: GoobyEngine) -> GoobyWidgetSnapshot {
        let now = engine.now()
        let key = engine.dayKey()
        let offset = engine.profile.timeOffset
        let goals = engine.dueHabits(on: now).prefix(8).map { habit in
            GoobyWidgetSnapshot.Goal(
                id: habit.id.uuidString,
                title: habit.title,
                icon: habit.icon,
                colorHex: habit.colorHex,
                count: engine.habitLog(habit.id, key)?.count ?? 0,
                target: max(1, habit.timesPerDay),
                isDailyGoal: habit.isDailyGoal
            )
        }
        var trip: GoobyWidgetSnapshot.Trip?
        if let run = engine.all(AdventureRun.self).first(where: { $0.status == "traveling" || $0.status == "ready" }) {
            trip = GoobyWidgetSnapshot.Trip(
                placeName: engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode) ?? run.placeID,
                startedAt: run.startedAt.addingTimeInterval(-offset),
                returnsAt: run.returnsAt.addingTimeInterval(-offset)
            )
        }
        var focus: GoobyWidgetSnapshot.Focus?
        if let session = engine.currentFocus(), !session.finished {
            focus = GoobyWidgetSnapshot.Focus(
                plannedSeconds: session.plannedSeconds,
                remainingSeconds: engine.focusRemaining(),
                endsAt: focusEnd(session, offset: offset)
            )
        }
        return GoobyWidgetSnapshot(
            dayKey: key,
            timeOffset: offset,
            language: engine.languageCode,
            goobyName: engine.profile.goobyName.isEmpty ? "Gooby" : engine.profile.goobyName,
            stage: Growth.stage(of: engine.pet),
            energy: engine.wallet.energy,
            energyGoal: max(1, engine.profile.energyGoal),
            sparks: engine.wallet.sparks,
            streak: engine.streak(),
            goals: Array(goals),
            trip: trip,
            focus: focus,
            updatedAt: Date()
        )
    }

    static func focusEnd(_ session: FocusSession, offset: Double) -> Date? {
        guard let since = session.runningSince else { return nil }
        let left = max(0, Double(session.plannedSeconds) - session.accumulated)
        return since.addingTimeInterval(left - offset)
    }

    // Renders the real character once per look, so widgets follow outfits and the current drawing.
    static func renderPortraitIfNeeded(_ engine: GoobyEngine) -> Bool {
        let look = engine.wornLook()
        let stage = Growth.stage(of: engine.pet)
        let slots = look.slots.map { "\($0.key)=\($0.value.id)" }.sorted().joined(separator: ",")
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let signature = "1|\(build)|\(look.fur)|\(slots)|\(stage)"
        let missing = [GoobySharedStore.portraitName, GoobySharedStore.badgeName].contains { name in
            guard let url = GoobySharedStore.url(name) else { return true }
            return !FileManager.default.fileExists(atPath: url.path)
        }
        let stored = UserDefaults.standard.string(forKey: signatureKey)
        guard missing || stored != signature else { return false }
        guard attemptedSignature != signature else { return false }
        attemptedSignature = signature
        let wrote = render(look, stage, size: CGSize(width: 200, height: 230), scale: 2, name: GoobySharedStore.portraitName)
            && render(look, stage, size: CGSize(width: 60, height: 69), scale: 3, name: GoobySharedStore.badgeName)
        if wrote { UserDefaults.standard.set(signature, forKey: signatureKey) }
        return wrote
    }

    private static func render(_ look: WornLook, _ stage: String, size: CGSize, scale: CGFloat, name: String) -> Bool {
        let pose = GoobyPose.make(animation: .idle, time: 0, reduce: true)
        let view = GoobyRig(look: look, stage: stage, pose: pose, companion: nil)
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = false
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        guard let image = renderer.uiImage, image.size.width > 1, let data = image.pngData(), !data.isEmpty,
              let url = GoobySharedStore.url(name) else { return false }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
