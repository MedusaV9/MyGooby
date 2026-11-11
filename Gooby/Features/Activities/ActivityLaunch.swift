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
            ActivityAffirmationLaunch(engine: engine, reduceMotion: reduceMotion)
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

struct ActivityAffirmationLaunch: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var editing: JournalEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("activity.aid.affirm.lead"))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                ForEach(0..<3, id: \.self) { index in
                    Text(engine.t("ground.card.\(index)"))
                        .foregroundStyle(Theme.ink)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.peach.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                NavigationLink {
                    GroundingView(engine: engine)
                } label: {
                    Text(engine.t("activity.open.grounding"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
                Button(engine.t("activity.aid.affirm.write")) {
                    editing = engine.addJournal(
                        title: engine.t("activity.aid.affirm.title"),
                        body: "",
                        tags: ["worth"],
                        promptID: "worth-1"
                    )
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.mint, ink: Theme.ink))
                Text(engine.t("calm.disclaimer"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("activity.aid.affirm.title"))
        .transaction { transaction in
            if reduceMotion { transaction.disablesAnimations = true }
        }
        .sheet(item: $editing) { entry in
            JournalEditor(engine: engine, entry: entry)
        }
    }
}
