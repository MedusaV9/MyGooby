import SwiftUI

struct OnboardingView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool

    @State private var step = Step.splash
    @State private var eggIndex = OnboardingScript.defaultEggIndex
    @State private var furID = OnboardingScript.eggs[OnboardingScript.defaultEggIndex].id
    @State private var pronoun = ""
    @State private var petName = "Gooby"
    @State private var trait = ""
    @State private var humanName = ""
    @State private var quizIndex = 0
    @State private var quizAnswers: [String: String] = [:]
    @State private var areas: Set<String> = []
    @State private var finishing = false

    private var shownPet: String {
        let trimmed = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Gooby" : trimmed
    }

    private var shownHuman: String {
        humanName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var egg: OnboardingEgg {
        OnboardingScript.eggs[min(max(0, eggIndex), OnboardingScript.eggs.count - 1)]
    }

    var body: some View {
        Group {
            switch step {
            case .splash:
                OnboardingSplashScreen(engine: engine, reduceMotion: reduceMotion) {
                    step = .egg
                }
            case .egg:
                OnboardingEggScreen(engine: engine, reduceMotion: reduceMotion, eggIndex: $eggIndex) {
                    commitFur(egg.id)
                } onSkip: {
                    commitFur(OnboardingScript.skipFur)
                }
            case .crack:
                OnboardingCrackScreen(egg: eggFor(furID), reduceMotion: reduceMotion, continueLabel: engine.t("motion.hatch")) {
                    step = .hatched
                }
            case .hatched:
                OnboardingHatchedScreen(engine: engine, reduceMotion: reduceMotion, fur: furID, egg: eggFor(furID)) {
                    step = .pronouns
                }
            case .pronouns:
                OnboardingPronounScreen(engine: engine, reduceMotion: reduceMotion, fur: furID, pronoun: $pronoun, onBack: { step = .egg }, onNext: confirmPronouns)
            case .name:
                OnboardingNameScreen(engine: engine, fur: furID, reduceMotion: reduceMotion, petName: $petName, onBack: { step = .pronouns }, onNext: confirmPetName)
            case .trait:
                OnboardingTraitScreen(
                    engine: engine,
                    reduceMotion: reduceMotion,
                    fur: furID,
                    petName: shownPet,
                    trait: $trait,
                    onBack: { step = .name },
                    onNext: { step = .chat }
                )
            case .chat:
                OnboardingChatScreen(
                    engine: engine,
                    reduceMotion: reduceMotion,
                    fur: furID,
                    petName: shownPet,
                    humanName: $humanName,
                    onBack: { step = .trait },
                    onNext: confirmHuman
                )
            case .care:
                OnboardingCareScreen(
                    engine: engine,
                    reduceMotion: reduceMotion,
                    fur: furID,
                    humanName: shownHuman,
                    onBack: { step = .chat },
                    onChoose: { step = .gain }
                )
            case .gain:
                OnboardingGainScreen(
                    engine: engine,
                    reduceMotion: reduceMotion,
                    fur: furID,
                    petName: shownPet,
                    traitName: traitTitle,
                    onBack: { step = .care },
                    onNext: { step = .reminders }
                )
            case .reminders:
                OnboardingRemindersScreen(
                    engine: engine,
                    reduceMotion: reduceMotion,
                    fur: furID,
                    petName: shownPet,
                    onBack: { step = .gain },
                    onDone: { step = .learn }
                )
            case .learn:
                OnboardingLearnScreen(
                    engine: engine,
                    reduceMotion: reduceMotion,
                    fur: furID,
                    petName: shownPet,
                    onBack: { step = .reminders },
                    onNext: { step = .quiz }
                )
            case .quiz:
                OnboardingQuizScreen(
                    engine: engine,
                    reduceMotion: reduceMotion,
                    fur: furID,
                    index: quizIndex,
                    answers: $quizAnswers,
                    areas: $areas,
                    onBack: backQuiz,
                    onAdvance: advanceQuiz,
                    onFinishAreas: commitAreas
                )
            case .generating:
                OnboardingGeneratingScreen(engine: engine, reduceMotion: reduceMotion, fur: furID, petName: shownPet) {
                    step = .plan
                }
            case .plan:
                OnboardingPlanScreen(
                    engine: engine,
                    reduceMotion: reduceMotion,
                    fur: furID,
                    petName: shownPet,
                    humanName: shownHuman,
                    busy: finishing,
                    onStart: finish
                )
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: step)
    }

    private var traitTitle: String {
        guard let item = OnboardingScript.traits.first(where: { $0.id == trait }) else { return "" }
        return engine.t(item.nameKey)
    }

    private func eggFor(_ id: String) -> OnboardingEgg {
        OnboardingScript.eggs.first { $0.id == id } ?? OnboardingScript.eggs[0]
    }

    private func commitFur(_ id: String) {
        furID = id
        engine.pet.furStyle = id
        engine.save()
        step = .crack
    }

    private func confirmPronouns() {
        guard !pronoun.isEmpty else { return }
        engine.setPetPronouns(pronoun)
        step = .name
    }

    private func confirmPetName() {
        let trimmed = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        petName = trimmed.isEmpty ? "Gooby" : trimmed
        engine.profile.goobyName = petName
        engine.save()
        step = .trait
    }

    private func confirmHuman() {
        let trimmed = humanName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        humanName = trimmed
        engine.profile.nickname = trimmed
        engine.save()
        step = .care
    }

    private func backQuiz() {
        if quizIndex > 0 {
            quizIndex -= 1
        } else {
            step = .learn
        }
    }

    private func advanceQuiz() {
        if quizIndex + 1 < OnboardingScript.questions.count {
            quizIndex += 1
        }
    }

    private func commitAreas() {
        guard !areas.isEmpty else { return }
        engine.profile.goals = OnboardingScript.areaIDs.filter { areas.contains($0) }
        engine.save()
        step = .generating
    }

    private func finish() {
        guard !finishing else { return }
        finishing = true
        engine.profile.goobyName = shownPet
        engine.profile.nickname = shownHuman
        engine.profile.goals = OnboardingScript.areaIDs.filter { areas.contains($0) }
        engine.pet.furStyle = furID
        if !pronoun.isEmpty { engine.setPetPronouns(pronoun) }
        if !trait.isEmpty { _ = engine.setStarterTrait(trait) }
        OnboardingScript.plantStarterPlan(engine: engine)
        engine.profile.onboardingDone = true
        engine.save()
        engine.rescheduleNotifications()
        engine.haptics.celebrate()
    }

    private enum Step: Equatable {
        case splash, egg, crack, hatched, pronouns, name, trait
        case chat, care, gain, reminders, learn, quiz, generating, plan
    }
}
