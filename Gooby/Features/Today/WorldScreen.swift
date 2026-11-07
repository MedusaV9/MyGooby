import SwiftUI

/// World map in the pet-tab look: beige screen, ribbon title, today's adventure card, the map in
/// a notebook and one card per place.
struct WorldScreen: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selected: PlaceDef?

    var body: some View {
        let found = engine.petFoundDiscoveries()
        ScrollView {
            VStack(spacing: Theme.Space.gap) {
                RibbonTitle(text: engine.t("world.map"), color: Theme.Tab.pet.ribbon)
                Text(engine.t("world.intro"))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.brown)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 2)
                statusCard
                IllustratedMap(engine: engine) { selected = $0 }
                SectionCaps(engine.t("kit.pet.places"), color: Theme.brown.opacity(0.7))
                    .padding(.top, 6)
                ForEach(engine.catalog.places) { place in
                    placeCard(place, found: found)
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 32)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                BackChevronButton(label: engine.t("kit.back")) { dismiss() }
                Spacer()
                WorldSparksPill(engine: engine)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
            .background(Theme.Tab.pet.bgTop.ignoresSafeArea(edges: .top))
        }
        .background(Theme.Tab.pet.screen.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .goobySheet(item: $selected) { place in
            PlaceDetail(engine: engine, place: place, reduceMotion: reduceMotion)
        }
    }

    private var statusCard: some View {
        GCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    IconTile(color: Theme.Tab.quests.orange, size: 48, radius: 14) {
                        GoobyIcon("🎒", size: 30)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.t("world.status"))
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.text)
                        Text(statusLine)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.greyText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                statusAction
            }
        }
    }

    private var statusLine: String {
        guard let run = engine.todaysRun() else {
            if engine.wallet.energy < engine.profile.energyGoal { return engine.t("today.adventure.hint") }
            let ready: String = engine.t("today.adventure.readyToStart")
            let pick: String = engine.tx("pet.world.pick", de: "Wähle einen Ort auf der Karte.", en: "Pick a place on the map.")
            return "\(ready) \(pick)"
        }
        if run.status == "claimed" { return engine.t("today.adventure.done") }
        if run.status == "ready" || engine.now() >= run.returnsAt { return engine.t("today.adventure.returned") }
        let minutes = max(1, Int(run.returnsAt.timeIntervalSince(engine.now()) / 60))
        return engine.t("today.adventure.traveling") + " " + engine.tf("today.adventure.minutes", minutes)
    }

    @ViewBuilder private var statusAction: some View {
        if let run = engine.todaysRun() {
            if run.status != "claimed", run.status == "ready" || engine.now() >= run.returnsAt,
               let story = engine.catalog.storiesByID[run.storyID] {
                NavigationLink {
                    StoryReader(engine: engine, run: run, story: story, reduceMotion: reduceMotion)
                } label: {
                    Label(engine.t("adventure.read"), systemImage: "book.fill")
                        .foregroundStyle(.white)
                }
                .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.quests.orange, edge: nil, radius: 18, vertical: 13, expand: true))
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(engine.t("today.energy"))
                    .font(Theme.Fonts.caps)
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.greyText)
                StripedProgressBar(value: engine.wallet.energy, goal: max(1, engine.profile.energyGoal), height: 22)
            }
        }
    }

    private func placeCard(_ place: PlaceDef, found: Set<String>) -> some View {
        let unlocked = engine.isPlaceUnlocked(place.id)
        let percent = engine.petExploredPercent(place, found: found)
        let visits: String = engine.tf("world.visits", engine.placeProgress(place.id)?.visits ?? 0)
        let explored: String = engine.txf("pet.world.explored", de: "%d %% erkundet", en: "%d%% explored", percent)
        let detail: String = unlocked ? "\(visits) · \(explored)" : engine.tf("world.locked", place.unlockAfterAdventures)
        return Button { selected = place } label: {
            HStack(spacing: 14) {
                if unlocked {
                    PetPlaceArt(place: place, size: 64)
                } else {
                    PetLockedTile(size: 64)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name.text(engine.languageCode))
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                    Text(place.blurb.text(engine.languageCode))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                        .lineLimit(2)
                    Text(detail)
                        .font(Theme.Fonts.caption.weight(.heavy))
                        .foregroundStyle(unlocked ? Theme.ochre : Theme.brown.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 4)
                CircleChevron(color: Theme.greyText, fill: Theme.keyFace, size: 28)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .cardShadow()
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Current star sparks, shown where tickets can be bought.
struct WorldSparksPill: View {
    var engine: GoobyEngine

    var body: some View {
        HStack(spacing: 5) {
            Text(verbatim: "✨").font(.system(size: 15))
            Text(verbatim: "\(engine.wallet.sparks)")
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.brown)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Theme.Tab.pet.cream, in: Capsule())
        .overlay(Capsule().stroke(Theme.Tab.pet.pill, lineWidth: 2))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(engine.tf("shop.balance", engine.wallet.sparks))
    }
}

/// Paper map in a notebook: land blobs, a dotted path and one pin per place.
struct IllustratedMap: View {
    var engine: GoobyEngine
    var select: (PlaceDef) -> Void

    private static let spots: [(CGFloat, CGFloat)] = [
        (0.16, 0.84), (0.42, 0.72), (0.72, 0.80), (0.86, 0.58), (0.62, 0.50),
        (0.34, 0.47), (0.14, 0.31), (0.40, 0.20), (0.66, 0.16), (0.86, 0.10)
    ]

    var body: some View {
        NotebookCard {
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    land(size)
                    Path { path in
                        for (index, spot) in Self.spots.prefix(engine.catalog.places.count).enumerated() {
                            let point = CGPoint(x: spot.0 * size.width, y: spot.1 * size.height)
                            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                        }
                    }
                    .stroke(Theme.Tab.pet.stand.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 7]))
                    ForEach(Array(engine.catalog.places.prefix(Self.spots.count).enumerated()), id: \.element.id) { index, place in
                        pin(place)
                            .position(x: Self.spots[index].0 * size.width, y: Self.spots[index].1 * size.height)
                    }
                }
            }
            .frame(height: 300)
        }
    }

    private func land(_ size: CGSize) -> some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xDCEBC2)).frame(width: size.width * 0.72, height: size.height * 0.46).position(x: size.width * 0.32, y: size.height * 0.7)
            Ellipse().fill(Color(hex: 0xE3EFCB)).frame(width: size.width * 0.6, height: size.height * 0.42).position(x: size.width * 0.72, y: size.height * 0.62)
            Ellipse().fill(Color(hex: 0xD6E8F2)).frame(width: size.width * 0.34, height: size.height * 0.2).position(x: size.width * 0.58, y: size.height * 0.34)
            Ellipse().fill(Color(hex: 0xE9E0F5)).frame(width: size.width * 0.66, height: size.height * 0.34).position(x: size.width * 0.5, y: size.height * 0.16)
            PetLeaf(color: Color(hex: 0xBFD9A0), vein: false).frame(width: 14, height: 24).position(x: size.width * 0.08, y: size.height * 0.6)
            PetLeaf(color: Color(hex: 0xBFD9A0), vein: false).frame(width: 12, height: 20).rotationEffect(.degrees(30)).position(x: size.width * 0.94, y: size.height * 0.84)
        }
        .accessibilityHidden(true)
    }

    private func pin(_ place: PlaceDef) -> some View {
        let unlocked = engine.isPlaceUnlocked(place.id)
        let name = place.name.text(engine.languageCode)
        return Button { select(place) } label: {
            VStack(spacing: 2) {
                Group {
                    if unlocked {
                        Text(verbatim: PetPlaceArt.glyph(place.id)).font(.system(size: 18))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Theme.Tab.pet.albumSilhouette)
                    }
                }
                .frame(width: 36, height: 36)
                .background(unlocked ? Color(hexString: place.accent) : Theme.Tab.pet.tileLocked, in: Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Theme.brown.opacity(0.18), radius: 2, x: 0, y: 2)
                Text(name)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(unlocked ? Theme.brown : Theme.brown.opacity(0.5))
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(unlocked ? name : "\(name), \(engine.tx("pet.places.locked", de: "Gesperrt", en: "Locked"))")
    }
}

/// One place: header art with Gooby, blurb, duration and exploration, the start button (or the
/// lock with a ticket offer) and the discoveries in a notebook.
struct PlaceDetail: View {
    var engine: GoobyEngine
    var place: PlaceDef
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var message: String?

    var body: some View {
        let unlocked = engine.isPlaceUnlocked(place.id)
        let found = engine.petFoundDiscoveries()
        let explored = engine.petExplored(place, found: found)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                Text(place.name.text(engine.languageCode))
                    .font(Theme.Fonts.title)
                    .foregroundStyle(Theme.brown)
                    .accessibilityAddTraits(.isHeader)
                Text(place.blurb.text(engine.languageCode))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.brown.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    chip("⏱️", engine.tf("world.duration", place.durationMinutes))
                    chip("🔍", "\(explored.found)/\(explored.total)")
                }
                actions(unlocked: unlocked)
                discoveries(found: found)
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 28)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                CloseCircleButton(label: engine.t("kit.close")) { dismiss() }
                Spacer()
                WorldSparksPill(engine: engine)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Tab.pet.bgTop.ignoresSafeArea(edges: .top))
        }
        .background(Theme.Tab.pet.screen.ignoresSafeArea())
        .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: { Text(message ?? "") }
    }

    private var header: some View {
        ZStack(alignment: .bottom) {
            PetPlaceArt(place: place, size: 360, radius: Theme.Radius.card, showsGlyph: false)
                .frame(maxWidth: .infinity)
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            GoobyCharacterView(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), animation: .hop, reduceMotion: reduceMotion, companion: engine.companionSpecies(), adventuring: true)
                .frame(width: 180, height: 180)
                .padding(.bottom, 4)
        }
        .frame(height: 230)
        .frame(maxWidth: .infinity)
    }

    private func chip(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Text(verbatim: icon).font(.system(size: 13))
            Text(text)
                .font(Theme.Fonts.caption.weight(.heavy))
                .foregroundStyle(Theme.brown)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Theme.Tab.pet.cream, in: Capsule())
    }

    @ViewBuilder
    private func actions(unlocked: Bool) -> some View {
        if unlocked {
            Button {
                if let error = engine.startAdventure(placeID: place.id) {
                    message = engine.t(error)
                } else {
                    dismiss()
                }
            } label: {
                Label(engine.t("adventure.start"), systemImage: "figure.walk")
                    .foregroundStyle(.white)
            }
            .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.quests.orange, edge: nil, radius: 18, vertical: 14, expand: true))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    GoobyIcon("🔒", size: 24)
                    Text(engine.tf("world.locked", place.unlockAfterAdventures))
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.brown)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let ticket = engine.petTicket(for: place) {
                    Button {
                        if let error = engine.buy(ticket) {
                            message = engine.t(error)
                        }
                    } label: {
                        Label(engine.txf("pet.world.ticket", de: "Ticket kaufen · %d ✨", en: "Buy a ticket · %d ✨", engine.price(of: ticket)), systemImage: "ticket.fill")
                            .foregroundStyle(Theme.brown)
                    }
                    .buttonStyle(Press3DButtonStyle(fill: Theme.Tab.pet.cream, edge: Theme.Tab.pet.pill, radius: 18, vertical: 14, expand: true))
                }
            }
        }
    }

    private func discoveries(found: Set<String>) -> some View {
        NotebookCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(engine.t("world.discoveries"))
                    .font(Theme.Fonts.title3)
                    .foregroundStyle(Theme.brown)
                    .accessibilityAddTraits(.isHeader)
                ForEach(place.discoveries) { discovery in
                    let known = found.contains(discovery.id)
                    HStack(alignment: .top, spacing: 10) {
                        GoobyIcon(known ? "✨" : "❔", size: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(known ? discovery.name.text(engine.languageCode) : engine.t("world.unknown"))
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(known ? Theme.brown : Theme.brown.opacity(0.55))
                            if known {
                                Text(discovery.detail.text(engine.languageCode))
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.greyText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(known ? Color.white : Theme.Tab.pet.tileLocked, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

/// Today's story: Gooby, the story on a notebook page, then the choices as keys. Choosing applies
/// the personality deltas, sparks and discovery (engine.choose).
struct StoryReader: View {
    var engine: GoobyEngine
    var run: AdventureRun
    var story: StoryDef
    var reduceMotion: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var choice: StoryChoice?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                GoobyCharacterView(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), animation: choice == nil ? .think : .celebrate, reduceMotion: reduceMotion, companion: engine.companionSpecies(), adventuring: false)
                    .frame(width: 200, height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Tab.pet.cream, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                NotebookCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(story.title.text(engine.languageCode))
                            .font(Theme.Fonts.title)
                            .foregroundStyle(Theme.brown)
                            .accessibilityAddTraits(.isHeader)
                        Text(story.body.text(engine.languageCode))
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.brown.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let choice {
                    outcome(choice)
                    Button(engine.t("common.done")) { dismiss() }
                        .buttonStyle(Press3DButtonStyle(fill: Theme.checkGreen, edge: Theme.checkGreenEdge, radius: 18, vertical: 14, expand: true))
                        .foregroundStyle(.white)
                } else if run.choiceID.isEmpty && (run.status == "ready" || engine.now() >= run.returnsAt) {
                    ForEach(story.choices) { option in
                        Button {
                            engine.choose(run: run, choice: option)
                            choice = option
                        } label: {
                            Text(option.text.text(engine.languageCode))
                                .foregroundStyle(Theme.text)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(Press3DButtonStyle(fill: .white, edge: Theme.Tab.pet.pill, radius: 18, vertical: 14, expand: true))
                    }
                } else if run.choiceID.isEmpty {
                    note(engine.t("today.adventure.traveling"))
                } else {
                    note(engine.t("adventure.alreadyChosen"))
                }
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.bottom, 28)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            ZStack {
                Text(engine.catalog.placesByID[run.placeID]?.name.text(engine.languageCode) ?? "")
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.brown)
                    .lineLimit(1)
                    .padding(.horizontal, 60)
                HStack {
                    BackChevronButton(label: engine.t("kit.back")) { dismiss() }
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
            .background(Theme.Tab.pet.bgTop.ignoresSafeArea(edges: .top))
        }
        .background(Theme.Tab.pet.screen.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func outcome(_ choice: StoryChoice) -> some View {
        GCard(fill: Color(hex: 0xFFF1C7)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(choice.outcome.text(engine.languageCode))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(engine.tf("adventure.sparks", choice.sparks))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.ochre)
                if !choice.discoveryID.isEmpty, let place = engine.catalog.placesByID[run.placeID], let found = place.discoveries.first(where: { $0.id == choice.discoveryID }) {
                    Text(engine.tf("adventure.found", found.name.text(engine.languageCode)))
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.brown)
                }
                personalityHint(choice)
            }
        }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(Theme.Fonts.headline)
            .foregroundStyle(Theme.brown)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Theme.Tab.pet.cream, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func personalityHint(_ choice: StoryChoice) -> some View {
        let bits = choice.deltas.filter { abs($0.value) > 0.0001 }.map { key, value in
            let sign = value > 0 ? "+" : ""
            return "\(engine.t("stat.\(key)")) \(sign)\(Int((value * 100).rounded()))"
        }
        return Text(bits.joined(separator: "  "))
            .font(Theme.Fonts.caption)
            .foregroundStyle(Theme.greyText)
    }
}
