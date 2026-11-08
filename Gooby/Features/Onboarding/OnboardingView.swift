import SwiftUI

/// First-launch onboarding (masterprompt 7): welcome, nickname, goals, naming Gooby, first habits
/// and the first reward. The welcome and the reward play on the green home scene, the questions on
/// warm beige; Gooby stands in a soft spotlight on every step. On the welcome Gooby sits on the
/// hill at the bottom of the scene, waves and says hello in a speech bubble. Reward particles play
/// in the app's celebration layer (`goobyCelebrations`).
struct OnboardingView: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @State private var step = 0
    @State private var nickname = ""
    @State private var goobyName = "Gooby"
    @State private var goals: Set<String> = []
    @State private var chosen: Set<String> = ["water", "bed", "walk"]
    @State private var created: [Habit] = []
    @State private var finished = false
    @State private var rewardText = ""
    /// Gooby waves hello when the welcome appears and whenever he is tapped there.
    @State private var waving = true
    @State private var bubbleShown = false

    private let goalIDs = ["care", "sleep", "habits", "move", "stress", "motivation", "organize", "mood", "mindful"]
    private let goalIcons: [String: String] = [
        "care": "💗", "sleep": "😴", "habits": "🌱", "move": "🤸", "stress": "🍃",
        "motivation": "⭐", "organize": "📅", "mood": "🌈", "mindful": "🧘"
    ]
    private let suggestions: [(String, String, String, String)] = [
        ("water", "drop.fill", "hygiene", "onb.habit.water"),
        ("bed", "bed.double.fill", "morning", "onb.habit.bed"),
        ("teeth", "sparkles", "hygiene", "onb.habit.teeth"),
        ("walk", "figure.walk", "movement", "onb.habit.walk"),
        ("relax", "wind", "mindful", "onb.habit.relax"),
        ("note", "pencil", "creative", "onb.habit.note")
    ]

    /// The welcome and the reward use the green home scene, the questions warm beige.
    private var onGreen: Bool { step == 0 || step == 5 }
    private var ink: Color { onGreen ? .white : Theme.brown }

    var body: some View {
        GeometryReader { frame in
            ScrollView {
                VStack(spacing: 20) {
                    if step == 0 {
                        welcomeScene(in: frame.size)
                    } else {
                        hero(size: heroSize)
                        content
                            .id(step)
                            .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    }
                }
                .padding(.horizontal, Theme.Space.margin)
                .padding(.bottom, step == 0 ? 0 : 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .top, spacing: 0) { progress }
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .background { background.ignoresSafeArea() }
        .goobyCelebrations(engine)
        .task { await greet() }
    }

    /// Waves for a moment, then settles (in screenshot runs he keeps waving).
    private func greet() async {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.35).delay(0.25)) {
            bubbleShown = true
        }
        guard ShotMode.route == nil else { return }
        try? await Task.sleep(nanoseconds: 2_600_000_000)
        waving = false
    }

    // MARK: Frame

    private var progress: some View {
        let position = "\(step + 1) / 6"
        return HStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(index == step ? ink : ink.opacity(index < step ? 0.6 : 0.28))
                    .frame(width: index == step ? 26 : 9, height: 9)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .animation(reduceMotion ? nil : .spring(duration: 0.35), value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(position)
    }

    /// Fixed backdrop. On the green steps the hills and the lawn belong to the hero (so they always
    /// meet Gooby's feet); the backdrop only adds the dusk sky, the moon and green under the lawn.
    @ViewBuilder private var background: some View {
        if onGreen {
            let home = Theme.Tab.home
            LinearGradient(
                stops: [.init(color: home.sky, location: 0), .init(color: home.skyLow, location: 0.6), .init(color: home.bg, location: 0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .topTrailing) {
                ZStack {
                    Circle().fill(home.moon.opacity(0.22)).frame(width: 72, height: 72)
                    Circle().fill(home.moon).frame(width: 44, height: 44)
                }
                .padding(.top, 70)
                .padding(.trailing, 44)
            }
            .overlay { OnboardingStars(twinkle: !reduceMotion) }
        } else {
            ZStack {
                Theme.Tab.pet.bg
                Theme.Tab.pet.background
            }
        }
    }

    private var heroSize: CGFloat {
        switch step {
        case 0: return 320
        case 2, 4: return 150
        case 5: return 210
        default: return 200
        }
    }

    private var heroAnimation: GoobyAnimation {
        switch step {
        case 0: return waving ? .wave : .sit
        case 1: return .ears
        case 2: return .think
        case 3: return .present
        case 4: return .breathe
        default: return finished ? .celebrate : .hearts
        }
    }

    /// Gooby in a soft spotlight; on the green steps he sits on the hills of the home scene.
    private func hero(size: CGFloat) -> some View {
        ZStack {
            if onGreen {
                OnboardingHills()
                    .offset(y: size * 0.86 - size / 2)
            }
            Circle()
                .fill(RadialGradient(colors: [Color.white.opacity(onGreen ? 0.4 : 0.9), Color.white.opacity(0)], center: .center, startRadius: 0, endRadius: size * 0.62))
                .frame(width: size * 1.3, height: size * 1.3)
            GoobyCharacterView(look: WornLook(), stage: "baby", animation: heroAnimation, reduceMotion: reduceMotion, companion: nil)
                .frame(width: size, height: size)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard step == 0, !waving else { return }
                    waving = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 2_400_000_000)
                        waving = false
                    }
                }
        }
        .frame(height: size)
        // The spotlight and the rig may be wider than the screen; they must not widen the layout.
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.top, 4)
    }

    /// The welcome: Gooby's speech bubble in the dusk sky, Gooby on the hill below it.
    private func welcomeScene(in space: CGSize) -> some View {
        let size = max(220, min(space.width * 1.05, space.height - 230, 420))
        return VStack(spacing: 6) {
            Spacer(minLength: 0)
            welcomeBubble
                .scaleEffect(bubbleShown || reduceMotion ? 1 : 0.6, anchor: .bottom)
                .opacity(bubbleShown || reduceMotion ? 1 : 0)
            hero(size: size)
        }
        .frame(minHeight: space.height, alignment: .bottom)
    }

    /// White speech bubble with a tail pointing down at Gooby.
    private var welcomeBubble: some View {
        VStack(spacing: 6) {
            Text(engine.t("onb.welcome.title"))
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.text)
            Text(engine.t("onb.welcome.body"))
                .font(Theme.Fonts.headline.weight(.semibold))
                .foregroundStyle(Theme.greyText)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 18 + OnboardingBubbleShape.tail)
        .frame(maxWidth: .infinity)
        .background(OnboardingBubbleShape().fill(Color.white).shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5))
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: 4) {
            switch step {
            case 0:
                primary(engine.t("onb.welcome.go")) { go(1) }
            case 1:
                primary(engine.t("common.continue")) { go(2) }
                skip { nickname = ""; go(2) }
            case 2:
                primary(engine.t("common.continue")) { go(3) }
                skip { goals = []; go(3) }
            case 3:
                primary(engine.t("common.continue")) {
                    if goobyName.trimmingCharacters(in: .whitespaces).isEmpty { goobyName = "Gooby" }
                    go(4)
                }
                skip { goobyName = "Gooby"; go(4) }
            case 4:
                primary(engine.t("common.continue")) { prepareTasks(); go(5) }
                skip { chosen = []; prepareTasks(); go(5) }
            default:
                if finished {
                    primary(engine.t("onb.first.home")) { finishOnboarding() }
                }
            }
        }
        .padding(.horizontal, Theme.Space.margin)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Fonts.title3)
                .foregroundStyle(onGreen ? Theme.Tab.home.leafDark : Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
        }
        .buttonStyle(Press3DButtonStyle(
            fill: onGreen ? .white : Theme.checkGreen,
            edge: onGreen ? Color(hex: 0xCFDDC4) : Theme.checkGreenEdge,
            radius: 18,
            vertical: 14,
            expand: true
        ))
    }

    private func skip(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(engine.t("common.skip"))
                .font(Theme.Fonts.button)
                .foregroundStyle(ink.opacity(0.75))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func go(_ next: Int) {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.2)) {
            step = next
        }
    }

    private func titleBlock(_ title: String, _ subtitle: String? = nil, large: Bool = false) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(large ? .system(.largeTitle, design: .rounded, weight: .heavy) : .system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .shadow(color: Color.black.opacity(onGreen ? 0.12 : 0), radius: 0, x: 0, y: 2)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Fonts.headline.weight(.semibold))
                    .foregroundStyle(ink.opacity(0.85))
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(Theme.Fonts.title3)
            .foregroundStyle(Theme.text)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .padding(.horizontal, 18)
            .frame(height: 60)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .cardShadow()
    }

    // MARK: Steps

    @ViewBuilder private var content: some View {
        switch step {
        case 1: nickStep
        case 2: goalStep
        case 3: nameStep
        case 4: habitStep
        default: firstTask
        }
    }

    private var nickStep: some View {
        VStack(spacing: 18) {
            titleBlock(engine.t("onb.nick.title"))
            field(engine.t("onb.nick.placeholder"), text: $nickname)
        }
    }

    private var goalStep: some View {
        VStack(spacing: 16) {
            titleBlock(engine.t("onb.goals.title"), engine.t("onb.goals.subtitle"))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(goalIDs, id: \.self) { id in
                    OnboardingOption(icon: goalIcons[id] ?? "✨", title: engine.t("onb.goal.\(id)"), selected: goals.contains(id), tile: true) {
                        if goals.contains(id) { goals.remove(id) } else { goals.insert(id) }
                    }
                }
            }
        }
    }

    private var nameStep: some View {
        VStack(spacing: 18) {
            titleBlock(engine.t("onb.name.title"))
            RibbonTitle(text: goobyName.trimmingCharacters(in: .whitespaces).isEmpty ? "Gooby" : goobyName)
            field(engine.t("onb.name.placeholder"), text: $goobyName)
        }
    }

    private var habitStep: some View {
        VStack(spacing: 16) {
            titleBlock(engine.t("onb.habits.title"), engine.t("onb.habits.subtitle"))
            VStack(spacing: Theme.Space.gap) {
                ForEach(suggestions, id: \.0) { item in
                    OnboardingOption(icon: item.1, title: engine.t(item.3), subtitle: engine.t(item.3 + ".detail"), selected: chosen.contains(item.0)) {
                        if chosen.contains(item.0) { chosen.remove(item.0) } else { chosen.insert(item.0) }
                    }
                }
            }
        }
    }

    private var firstTask: some View {
        VStack(spacing: 16) {
            titleBlock(engine.t("onb.first.title"), engine.t("onb.first.body"))
            if finished {
                GCard {
                    VStack(spacing: 10) {
                        HStack(spacing: 6) {
                            GoobyIcon("⚡", size: 34)
                            GoobyIcon("✨", size: 34)
                        }
                        Text(rewardText)
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                        Text(engine.tf("onb.first.reward", engine.wallet.energy, engine.wallet.sparks))
                            .font(Theme.Fonts.title3)
                            .foregroundStyle(Theme.brown)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else {
                VStack(spacing: Theme.Space.gap) {
                    ForEach(created) { habit in
                        taskCard(habit)
                    }
                }
            }
        }
    }

    /// Goal card like the home list: icon blob, title, reward and the 3D check button.
    private func taskCard(_ habit: Habit) -> some View {
        HStack(spacing: 12) {
            GoobyIcon(habit.icon, size: 34)
                .frame(width: 48, height: 48)
                .background(Theme.keyFace, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.text)
                if !habit.details.isEmpty {
                    Text(habit.details)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                }
            }
            Spacer(minLength: 8)
            HStack(spacing: 2) {
                Text(verbatim: "\(habit.energyReward)")
                    .font(Theme.Fonts.button)
                    .foregroundStyle(Theme.greyText)
                GoobyIcon("⚡", size: 18)
            }
            .accessibilityHidden(true)
            CheckButton(done: false, label: engine.t("today.complete")) {
                complete(habit)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 70)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .cardShadow()
    }

    // MARK: Logic

    private func complete(_ habit: Habit) {
        engine.completeHabit(habit, on: engine.now())
        rewardText = habit.title
        withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.3)) {
            finished = true
        }
    }

    private func prepareTasks() {
        guard created.isEmpty else { return }
        engine.profile.nickname = nickname.trimmingCharacters(in: .whitespaces)
        engine.profile.goobyName = goobyName.trimmingCharacters(in: .whitespaces).isEmpty ? "Gooby" : goobyName
        engine.profile.goals = goalIDs.filter { goals.contains($0) }
        engine.save()
        let picked = suggestions.filter { chosen.contains($0.0) }
        if picked.isEmpty {
            let habit = engine.makeHabit(title: engine.t("onb.greeting.title"), details: engine.t("onb.greeting.detail"), icon: "heart.fill", category: "mindful", dailyGoal: true)
            created = [habit]
        } else {
            for (index, item) in picked.enumerated() {
                let habit = engine.makeHabit(
                    title: engine.t(item.3),
                    details: engine.t(item.3 + ".detail"),
                    icon: item.1,
                    category: item.2,
                    dailyGoal: index == 0
                )
                created.append(habit)
            }
        }
    }

    private func finishOnboarding() {
        engine.profile.onboardingDone = true
        engine.profile.nickname = nickname.trimmingCharacters(in: .whitespaces)
        engine.profile.goobyName = goobyName
        engine.save()
        engine.rescheduleNotifications()
    }
}

/// A few soft stars in the dusk sky; they twinkle slowly unless motion is reduced.
private struct OnboardingStars: View {
    var twinkle: Bool

    private static let spots: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.12, 0.14, 4), (0.3, 0.22, 3), (0.46, 0.1, 3.5), (0.64, 0.26, 3), (0.86, 0.36, 4),
        (0.2, 0.36, 3), (0.08, 0.5, 3.5), (0.9, 0.52, 3), (0.56, 0.4, 2.5)
    ]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 15.0, paused: !twinkle)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(OnboardingStars.spots.indices, id: \.self) { index in
                        let spot = OnboardingStars.spots[index]
                        let glow = twinkle ? 0.55 + 0.45 * abs(sin(t * 0.9 + Double(index) * 1.7)) : 0.8
                        Circle()
                            .fill(Color.white.opacity(glow))
                            .frame(width: spot.size, height: spot.size)
                            .position(x: geo.size.width * spot.x, y: geo.size.height * spot.y)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Rounded speech bubble whose tail (`tail` points tall) points down from the middle.
private struct OnboardingBubbleShape: Shape {
    static let tail: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - OnboardingBubbleShape.tail)
        var path = Path(roundedRect: body, cornerRadius: 24, style: .continuous)
        var tip = Path()
        tip.move(to: CGPoint(x: rect.midX - 16, y: body.maxY - 1))
        tip.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.midX - 4, y: body.maxY + 4))
        tip.addQuadCurve(to: CGPoint(x: rect.midX + 16, y: body.maxY - 1), control: CGPoint(x: rect.midX + 4, y: body.maxY + 4))
        tip.closeSubpath()
        path.addPath(tip)
        return path
    }
}

/// Rolling hills, two flowering bushes and the lawn. The view has no size of its own: its top
/// edge is the lawn line, the hills rise above it and the lawn runs far down behind the content.
private struct OnboardingHills: View {
    var body: some View {
        let home = Theme.Tab.home
        ZStack(alignment: .top) {
            Ellipse().fill(home.leaf).frame(width: 640, height: 260).offset(x: 190, y: -58)
            Ellipse().fill(home.lime).frame(width: 640, height: 260).offset(x: -200, y: -40)
            bush.offset(x: -138, y: -30)
            bush.scaleEffect(0.8).offset(x: 150, y: -40)
            Ellipse().fill(home.bg).frame(width: 1100, height: 1800)
        }
        .frame(width: 0, height: 0, alignment: .top)
        .accessibilityHidden(true)
    }

    private var bush: some View {
        let home = Theme.Tab.home
        return ZStack {
            Circle().fill(home.leafDark).frame(width: 46, height: 46).offset(x: -20, y: 6)
            Circle().fill(home.leafDark).frame(width: 46, height: 46).offset(x: 20, y: 6)
            Circle().fill(home.leaf).frame(width: 54, height: 54).offset(y: -8)
            Circle().fill(Color(hex: 0xF27B9B)).frame(width: 9, height: 9).offset(x: -18, y: -6)
            Circle().fill(Color(hex: 0xFFD6E7)).frame(width: 8, height: 8).offset(x: 6, y: -22)
            Circle().fill(Color(hex: 0xF27B9B)).frame(width: 9, height: 9).offset(x: 22, y: 4)
        }
        .frame(width: 90, height: 60)
    }
}

/// White option card with an emoji icon and a round check: a 2-column tile (goals) or a full
/// row with a subtitle (habits).
private struct OnboardingOption: View {
    var icon: String
    var title: String
    var subtitle: String?
    var selected: Bool
    var tile = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if tile {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            iconBlob
                            Spacer(minLength: 0)
                            check
                        }
                        Text(title)
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
                    }
                } else {
                    HStack(spacing: 12) {
                        iconBlob
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.text)
                            if let subtitle {
                                Text(subtitle)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.greyText)
                            }
                        }
                        .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        check
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                    .stroke(selected ? Theme.checkGreen : Color.clear, lineWidth: 3)
            )
            .cardShadow()
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
        }
        .buttonStyle(OnboardingPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var iconBlob: some View {
        GoobyIcon(icon, size: 30)
            .frame(width: 46, height: 46)
            .background(Theme.keyFace, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var check: some View {
        ZStack {
            Circle().fill(selected ? Theme.checkGreen : Theme.keyFace)
            Circle().stroke(selected ? Theme.checkGreenEdge : Theme.keyEdge, lineWidth: 2)
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color.white)
            }
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }
}

/// Soft press feedback for option cards; no scaling with Reduce Motion.
private struct OnboardingPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduce

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduce && configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduce ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
