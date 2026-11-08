import SwiftUI
import UIKit

// Extras hub. Engine methods and the shared UI components emit `GoobyMoment`s; `MomentHub` hands
// every moment to the four extras services, and each service picks what it needs:
//   GoobySounds          (Gooby/App/Services/GoobySounds.swift)          sound effects
//   GoobyLiveActivities  (Gooby/App/Services/GoobyLiveActivities.swift)  Live Activities
//   GoobyWidgetBridge    (Gooby/App/Services/GoobyWidgetBridge.swift)    widget snapshot + reload
//   GoobyAlerts.handle   (Gooby/App/Services/GoobyAlerts.swift)          local notifications
// Rules for the services: `handle` must return quickly, must not call `engine.save()` (save emits
// `.saved`) and must not emit moments itself. Moments carry ids; read the rest from the engine.

/// Something that happened in Gooby.
enum GoobyMoment: Equatable {
    // App lifecycle
    /// `GoobyEngine.boot()` finished (once per launch).
    case booted
    /// The app became active / went to the background (UIApplication notifications).
    case appActive
    case appBackground
    /// The store was saved (after every change).
    case saved
    case languageChanged(String)
    /// Everything was erased or a backup was imported.
    case dataReset

    // Goals
    /// A goal was checked off today. `allDone`: every goal due today is done now.
    case goalDone(habitID: String, dailyGoal: Bool, allDone: Bool)
    case goalUndone(habitID: String)
    case goalSkipped(habitID: String)

    // Rewards and growth
    /// Small rewards without their own moment (journal, breathing, developer test).
    case reward(sparks: Int, energy: Int)
    case questClaimed(sparks: Int)
    case eventTaskClaimed(sparks: Int)
    /// A quest or event reward item went into the bag.
    case giftReceived(itemID: String)
    /// Today's energy just reached the adventure goal.
    case energyReady
    /// Gooby's growth stage changed (baby, little, young, teen, adult).
    case levelUp(stage: String)

    // Adventures (AdventureRun ids)
    case adventureStarted(runID: String)
    /// Gooby is back home, the story waits.
    case adventureReturned(runID: String)
    case storyAnswered(runID: String, sparks: Int)

    // Calm tools (FocusSession ids)
    case focusStarted(sessionID: String)
    case focusPaused(sessionID: String)
    case focusResumed(sessionID: String)
    case focusStopped(sessionID: String)
    case focusFinished(sessionID: String, minutes: Int)
    case breathStarted(BreathPlan)
    /// `completed`: ended with the Stop button (rewarded when cycles > 0), false when the screen
    /// was left while running.
    case breathEnded(sessionID: String, cycles: Int, completed: Bool)
    case movementDone

    // Gooby, friends and things
    case petted(GoobyAnimation)
    case eggHatched(speciesID: String)
    case friendVisited(npcID: String)
    case companionChanged
    case itemBought(itemID: String)
    case itemEquipped(itemID: String)
    case moodLogged(level: Int)
    case journalSaved

    // UI
    /// A shared button style was pressed down (Press3DButtonStyle, GoobyButtonStyle,
    /// MenuRowButtonStyle, MenuChip). Bigger moments of the same tap follow right after.
    case tap
    /// A MenuToggleRow switch changed.
    case toggled(on: Bool)
    /// A sheet or full-screen cover presented with `goobySheet` / `goobyCover` opened or closed.
    case sheetOpened
    case sheetClosed
    case tabChanged(GoobyTab)
}

/// A running breathing exercise (BreathingView): seconds per phase of one cycle.
struct BreathPlan: Equatable {
    var sessionID: String
    /// calm, box, sleep, stress or custom.
    var pattern: String
    var inhale: Int
    var hold: Int
    var exhale: Int
    var hold2: Int
    /// App time (engine.now()) when the exercise started.
    var startedAt: Date

    var cycleSeconds: Int { max(1, inhale + hold + exhale + hold2) }
}

@MainActor
final class MomentHub {
    static let shared = MomentHub()

    private(set) weak var engine: GoobyEngine?
    private var observers: [NSObjectProtocol] = []

    /// Called first in `GoobyEngine.boot()`; also after `resetAll` keeps the same engine.
    func attach(_ engine: GoobyEngine) {
        self.engine = engine
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { MomentHub.shared.emit(.appActive) }
        })
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { MomentHub.shared.emit(.appBackground) }
        })
        ExtrasDevTools.register()
    }

    func emit(_ moment: GoobyMoment) {
        // Screenshot runs (DEBUG, -GoobyShot) stay silent.
        if ShotMode.route == nil { GoobySounds.shared.handle(moment) }
        guard let engine else { return }
        engine.haptics.handle(moment)
        GoobyLiveActivities.shared.handle(moment, engine: engine)
        GoobyWidgetBridge.shared.handle(moment, engine: engine)
        GoobyAlerts.handle(moment, engine: engine)
    }
}

extension GoobyEngine {
    func emit(_ moment: GoobyMoment) { MomentHub.shared.emit(moment) }
}

// MARK: - Presentations with moments

@MainActor
extension View {
    /// `.sheet(isPresented:)` that emits `.sheetOpened` and `.sheetClosed`.
    func goobySheet<Content: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View {
        sheet(isPresented: isPresented, onDismiss: {
            MomentHub.shared.emit(.sheetClosed)
            onDismiss?()
        }, content: content)
        .onChange(of: isPresented.wrappedValue) { _, shown in
            if shown { MomentHub.shared.emit(.sheetOpened) }
        }
    }

    /// `.sheet(item:)` that emits `.sheetOpened` and `.sheetClosed`.
    func goobySheet<Item: Identifiable, Content: View>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        sheet(item: item, onDismiss: {
            MomentHub.shared.emit(.sheetClosed)
            onDismiss?()
        }, content: content)
        .onChange(of: item.wrappedValue != nil) { _, shown in
            if shown { MomentHub.shared.emit(.sheetOpened) }
        }
    }

    /// `.fullScreenCover(isPresented:)` that emits `.sheetOpened` and `.sheetClosed`.
    func goobyCover<Content: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: {
            MomentHub.shared.emit(.sheetClosed)
            onDismiss?()
        }, content: content)
        .onChange(of: isPresented.wrappedValue) { _, shown in
            if shown { MomentHub.shared.emit(.sheetOpened) }
        }
    }

    /// `.fullScreenCover(item:)` that emits `.sheetOpened` and `.sheetClosed`.
    func goobyCover<Item: Identifiable, Content: View>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        fullScreenCover(item: item, onDismiss: {
            MomentHub.shared.emit(.sheetClosed)
            onDismiss?()
        }, content: content)
        .onChange(of: item.wrappedValue != nil) { _, shown in
            if shown { MomentHub.shared.emit(.sheetOpened) }
        }
    }
}
