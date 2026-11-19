import SwiftUI

struct ActivityLaunch: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var run: ActivityRun

    var body: some View {
        switch run {
        case .breathe:
            BreathingView(engine: engine, reduceMotion: reduceMotion)
        case .sound(let name):
            ActivitySoundLaunch(engine: engine, name: name)
        case .movement(let id):
            ActivityMovementLaunch(engine: engine, exerciseID: id)
        case .timer:
            FocusTimerView(engine: engine)
        case .grounding:
            GroundingView(engine: engine)
        case .calm:
            calmScreen
        case .journal:
            journalScreen
        case .affirmation:
            AidAffirmationFlow(engine: engine, reduceMotion: reduceMotion)
        case .aid(let flow):
            AidDestination(engine: engine, reduceMotion: reduceMotion, flow: flow)
        }
    }

    @ViewBuilder private var calmScreen: some View {
        if let make = FeatureHost.shared.calmScreen {
            make(engine)
        } else {
            CalmScreen(engine: engine, reduceMotion: reduceMotion)
        }
    }

    @ViewBuilder private var journalScreen: some View {
        if let make = FeatureHost.shared.journalScreen {
            make(engine)
        } else {
            JournalScreen(engine: engine)
        }
    }
}

private struct ActivitySoundLaunch: View {
    var engine: GoobyEngine
    var name: String

    var body: some View {
        SoundscapeView(engine: engine)
            .onAppear {
                guard SoundscapePlayer.names.contains(name) else { return }
                if engine.sound.active != name {
                    engine.sound.toggle(name)
                }
            }
    }
}

private struct ActivityMovementLaunch: View {
    var engine: GoobyEngine
    var exerciseID: String

    var body: some View {
        if let exercise = engine.catalog.exercises.first(where: { $0.id == exerciseID }) {
            MovementPlayer(engine: engine, exercise: exercise)
        } else {
            MovementList(engine: engine)
        }
    }
}

