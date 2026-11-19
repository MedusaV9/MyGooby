import SwiftUI

enum FriendsFollowUp: Int, Identifiable {
    case ask, reward
    var id: Int { rawValue }
}

struct FriendsTreehouseVisit: View {
    var engine: GoobyEngine
    @Binding var book: FriendsBook
    @Binding var lane: FriendsPostBook
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var palID: UUID?
    @State private var noted: Set<UUID> = []
    @State private var follow: FriendsFollowUp?

    private var calm: Bool { systemReduce || engine.reduceMotion }
    private var night: Bool { DaylightPhase.of(engine.now()) == .night }
    private var selected: TreePal? {
        if let palID, let pal = book.pals.first(where: { $0.id == palID }) { return pal }
        return book.pals.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let pal = selected {
                    ZStack(alignment: .bottom) {
                        FriendsTreehouseArt(night: night, calm: calm, name: pal.name)
                        GoobyCharacterView(
                            look: engine.wornLook(),
                            stage: Growth.stage(of: engine.pet),
                            animation: calm ? .idle : .hop,
                            reduceMotion: calm,
                            companion: nil,
                            showCompanion: false
                        )
                        .frame(height: 168)
                        .padding(.bottom, 4)
                    }
                    .frame(height: 440)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    Text(engine.tf("friends.house.title", pal.name))
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .multilineTextAlignment(.center)
                    Text(engine.t("friends.house.quiet"))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.72))
                        .multilineTextAlignment(.center)
                    FriendsPalPicker(engine: engine, pals: book.pals, palID: bindingID, calm: calm)
                } else {
                    FriendsNeedPal(engine: engine, calm: calm, ask: { follow = .ask }, invite: { follow = .reward })
                        .padding(.top, 32)
                }
            }
            .padding(20)
            .foregroundStyle(night && selected != nil ? Color.white : Theme.ink)
        }
        .background(night ? Color(hex: 0x142033) : Theme.cream)
        .navigationTitle(engine.t("friends.house.nav"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $follow) { step in
            switch step {
            case .ask:
                FriendsAddSheet(engine: engine, book: $book)
            case .reward:
                FriendsRewardSheet(engine: engine, book: $book)
            }
        }
        .onAppear { noteVisit(selected) }
        .onChange(of: selected?.id) { _, _ in noteVisit(selected) }
    }

    private var bindingID: Binding<UUID?> {
        Binding(
            get: { selected?.id },
            set: { palID = $0 }
        )
    }

    private func noteVisit(_ pal: TreePal?) {
        guard let pal, noted.insert(pal.id).inserted else { return }
        let (next, note) = lane.adding(pal: pal, kind: FriendsNoteKind.visit, token: "visit", at: engine.now())
        next.save()
        lane = next
        FriendsLane.shared.handoff(note)
    }
}

struct FriendsTreehouseArt: View {
    var night: Bool
    var calm: Bool
    var name: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: night
                    ? [Color(hex: 0x1B2A4A), Color(hex: 0x243656)]
                    : [FriendsPaint.skyTop, FriendsPaint.skyHaze],
                startPoint: .top,
                endPoint: .bottom
            )
            StageStill(name: "still-tree")
                .frame(width: 180, height: 220)
                .colorMultiply(night ? Color(hex: 0x5E8A52) : .white)
                .stageSway(amount: 1.3, seconds: 3.2, still: calm)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 8)
                .padding(.top, 12)
            StageStill(name: "still-tree-2")
                .frame(width: 170, height: 210)
                .colorMultiply(night ? Color(hex: 0x5E8A52) : .white)
                .stageSway(amount: 1.5, seconds: 2.8, still: calm)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 8)
                .padding(.top, 20)
            FriendsDoorVisit(calm: calm)
                .frame(width: 210, height: 230)
                .offset(y: 16)
            FriendsHouseWindow(night: night, calm: calm)
                .offset(x: 36, y: 8)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(FriendsPaint.wood)
                .frame(width: 120, height: 28)
                .overlay {
                    Text(name)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: 0x5C3A28))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 6)
                }
                .offset(y: -36)
        }
        .accessibilityHidden(true)
    }
}

struct FriendsHouseWindow: View {
    var night: Bool
    var calm: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: calm || !night ? 30 : 1.0 / 12.0, paused: calm || !night)) { timeline in
            let glow: Double = {
                guard night, !calm else { return 1 }
                return 0.72 + 0.28 * abs(sin(timeline.date.timeIntervalSinceReferenceDate * 1.4))
            }()
            Circle()
                .fill(night ? Color(hex: 0xFFE3A3) : Color(hex: 0xD7F1FF))
                .overlay(Circle().stroke(Color(hex: 0x8C4E32), lineWidth: 3))
                .opacity(glow)
                .frame(width: 34, height: 34)
        }
        .accessibilityHidden(true)
    }
}

struct FriendsVibePage: View {
    var engine: GoobyEngine
    @Binding var book: FriendsBook
    @Binding var lane: FriendsPostBook
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var palID: UUID?
    @State private var sent = false
    @State private var cheer = 0
    @State private var follow: FriendsFollowUp?

    private var calm: Bool { systemReduce || engine.reduceMotion }
    private var selected: TreePal? {
        if let palID, let pal = book.pals.first(where: { $0.id == palID }) { return pal }
        return book.pals.first
    }
    private let tokens = ["vibe.think", "vibe.can", "vibe.step"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if selected != nil {
                    Text(engine.t("friends.vibes.nav"))
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                    if book.pals.count > 1 {
                        Text(engine.t("friends.fun.pick"))
                            .font(.system(.subheadline, design: .rounded))
                        FriendsPalPicker(engine: engine, pals: book.pals, palID: bindingID, calm: calm)
                    }
                    ForEach(tokens, id: \.self) { token in
                        Button {
                            send(token)
                        } label: {
                            Text(engine.t("friends.fun.\(token)"))
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(FriendsPressStyle(calm: calm))
                        .accessibilityHint(engine.t("friends.fun.send"))
                    }
                    if sent, let pal = selected {
                        Text(engine.t("friends.fun.sent"))
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(FriendsFunPaint.ink)
                        FriendsCelebration(
                            calm: calm,
                            hearts: true,
                            label: engine.tf("friends.fun.highFive", pal.name)
                        )
                        .id(cheer)
                    }
                    NavigationLink(value: FriendsFunStop.gift) {
                        HStack(spacing: 10) {
                            StageClip(name: "clip-gift", reduceMotion: calm)
                                .frame(width: 52, height: 52)
                            Text(engine.t("friends.stage.giftHere"))
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Theme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(12)
                        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(FriendsPressStyle(calm: calm))
                } else {
                    FriendsNeedPal(engine: engine, calm: calm, ask: { follow = .ask }, invite: { follow = .reward })
                }
            }
            .padding(20)
        }
        .background(Theme.cream)
        .navigationTitle(engine.t("friends.vibes.nav"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $follow) { step in
            switch step {
            case .ask:
                FriendsAddSheet(engine: engine, book: $book)
            case .reward:
                FriendsRewardSheet(engine: engine, book: $book)
            }
        }
    }

    private var bindingID: Binding<UUID?> {
        Binding(get: { selected?.id }, set: { palID = $0 })
    }

    private func send(_ token: String) {
        guard let pal = selected else { return }
        let (next, note) = lane.adding(pal: pal, kind: FriendsNoteKind.vibes, token: token, at: engine.now())
        next.save()
        lane = next
        FriendsLane.shared.handoff(note)
        sent = true
        cheer += 1
        if calm { engine.haptics.soft() } else { engine.haptics.celebrate() }
    }
}

struct FriendsGiftPage: View {
    var engine: GoobyEngine
    @Binding var book: FriendsBook
    @Binding var lane: FriendsPostBook
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var palID: UUID?
    @State private var sent = false
    @State private var sentToken = "gift.heart"
    @State private var cheer = 0
    @State private var follow: FriendsFollowUp?

    private var calm: Bool { systemReduce || engine.reduceMotion }
    private var selected: TreePal? {
        if let palID, let pal = book.pals.first(where: { $0.id == palID }) { return pal }
        return book.pals.first
    }
    private let tokens = ["gift.flower", "gift.heart", "gift.stone"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if selected != nil {
                    Text(engine.t("friends.gift.nav"))
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                    if book.pals.count > 1 {
                        Text(engine.t("friends.fun.pick"))
                            .font(.system(.subheadline, design: .rounded))
                        FriendsPalPicker(engine: engine, pals: book.pals, palID: bindingID, calm: calm)
                    }
                    HStack(spacing: 10) {
                        ForEach(tokens, id: \.self) { token in
                            Button { send(token) } label: {
                                VStack(spacing: 8) {
                                    FriendsGiftArt(token: token, calm: calm)
                                        .frame(width: 72, height: 72)
                                    Text(engine.t("friends.fun.\(token)"))
                                        .font(.system(.caption, design: .rounded).weight(.bold))
                                        .foregroundStyle(Theme.ink)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(FriendsPressStyle(calm: calm))
                            .accessibilityHint(engine.t("friends.fun.send"))
                        }
                    }
                    if sent, let pal = selected {
                        Text(engine.t("friends.fun.sent"))
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(FriendsFunPaint.ink)
                        FriendsCelebration(
                            calm: calm,
                            hearts: false,
                            label: engine.tf("friends.fun.highFive", pal.name)
                        )
                        .id(cheer)
                        if !calm {
                            ZStack {
                                StageClip(name: "clip-gift", reduceMotion: false, loop: false)
                                    .frame(width: 140, height: 140)
                                StageClip(name: burstName, reduceMotion: false, loop: false)
                                    .frame(width: 120, height: 120)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                } else {
                    FriendsNeedPal(engine: engine, calm: calm, ask: { follow = .ask }, invite: { follow = .reward })
                }
            }
            .padding(20)
        }
        .background(Theme.cream)
        .navigationTitle(engine.t("friends.gift.nav"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $follow) { step in
            switch step {
            case .ask:
                FriendsAddSheet(engine: engine, book: $book)
            case .reward:
                FriendsRewardSheet(engine: engine, book: $book)
            }
        }
    }

    private var bindingID: Binding<UUID?> {
        Binding(get: { selected?.id }, set: { palID = $0 })
    }

    private func send(_ token: String) {
        guard let pal = selected else { return }
        let (next, note) = lane.adding(pal: pal, kind: FriendsNoteKind.gift, token: token, at: engine.now())
        next.save()
        lane = next
        FriendsLane.shared.handoff(note)
        sentToken = token
        sent = true
        cheer += 1
        if calm { engine.haptics.soft() } else { engine.haptics.celebrate() }
    }

    private var burstName: String {
        switch sentToken {
        case "gift.flower": "clip-sparkles"
        case "gift.stone": "clip-stone"
        default: "clip-hearts"
        }
    }
}

struct FriendsGiftArt: View {
    var token: String
    var calm: Bool

    var body: some View {
        Group {
            switch token {
            case "gift.flower":
                StageStill(name: "still-flower")
            case "gift.stone":
                StageClip(name: "clip-stone", reduceMotion: calm)
            default:
                StageStill(name: "still-heart")
            }
        }
        .accessibilityHidden(true)
    }
}

struct FriendsPostPage: View {
    var engine: GoobyEngine
    var lane: FriendsPostBook

    private var notes: [FriendsDispatch] {
        lane.notes.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    FriendsDrawnGooby(animation: .hop, calm: engine.reduceMotion)
                        .frame(width: 72, height: 72)
                        .stageSway(amount: 2, seconds: 1.8)
                    StageStill(name: "still-banana")
                        .frame(width: 48, height: 48)
                }
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
                if notes.isEmpty {
                    Text(engine.t("friends.fun.postEmpty"))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                } else {
                    ForEach(notes) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(FriendsNoteCopy.line(engine, note))
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            Text(engine.formatDate(note.createdAt, time: true))
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(Theme.ink.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.cream)
        .navigationTitle(engine.t("friends.stage.progressTitle"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FriendsPalPicker: View {
    var engine: GoobyEngine
    var pals: [TreePal]
    @Binding var palID: UUID?
    var calm: Bool

    var body: some View {
        if pals.count > 1 {
            HStack(spacing: 8) {
                ForEach(pals) { pal in
                    Button { palID = pal.id } label: {
                        Text(pal.name)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(palID == pal.id ? Color.white : Theme.ink)
                            .background(palID == pal.id ? FriendsFunPaint.button : Color.white, in: Capsule())
                    }
                    .buttonStyle(FriendsPressStyle(calm: calm))
                }
            }
            .accessibilityLabel(engine.t("friends.fun.pick"))
        }
    }
}

struct FriendsNeedPal: View {
    var engine: GoobyEngine
    var calm: Bool
    var ask: () -> Void
    var invite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(engine.t("friends.fun.need"))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: invite) {
                Text(engine.t("friends.fun.invite"))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(FriendsFunPaint.button, in: Capsule())
            }
            .buttonStyle(FriendsPressStyle(calm: calm))
            Button(action: ask) {
                Text(engine.t("friends.reward.asked"))
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(FriendsFunPaint.ink)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }
}
