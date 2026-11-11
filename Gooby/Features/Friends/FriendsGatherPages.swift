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
            Circle().fill(night ? Color(hex: 0x1E6B32) : FriendsPaint.mid).frame(width: 280, height: 260).offset(y: -30)
            Circle().fill(night ? Color(hex: 0x2E8A3C) : FriendsPaint.bright).frame(width: 210, height: 190).offset(x: -90, y: 20)
            Circle().fill(night ? Color(hex: 0x174F28) : FriendsPaint.dark).frame(width: 180, height: 160).offset(x: 100, y: -10)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(FriendsPaint.trunk)
                .frame(width: 28, height: 90)
                .offset(y: 150)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: 0xE7C39A))
                .frame(width: 168, height: 118)
                .offset(y: 36)
            Triangle()
                .fill(Color(hex: 0x8C4E32))
                .frame(width: 196, height: 72)
                .offset(y: -36)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: 0x6D4030))
                .frame(width: 36, height: 58)
                .offset(x: -28, y: 62)
            FriendsHouseWindow(night: night, calm: calm)
                .offset(x: 36, y: 28)
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
                .offset(y: 8)
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
                    if sent {
                        Text(engine.t("friends.fun.sent"))
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(FriendsFunPaint.ink)
                        if !calm {
                            GoobyMark().frame(maxWidth: .infinity)
                        }
                    }
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
                                    FriendsGiftArt(token: token)
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
                    if sent {
                        Text(engine.t("friends.fun.sent"))
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(FriendsFunPaint.ink)
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
        sent = true
        if calm { engine.haptics.soft() } else { engine.haptics.celebrate() }
    }
}

struct FriendsGiftArt: View {
    var token: String

    var body: some View {
        ZStack {
            switch token {
            case "gift.flower":
                Circle().fill(Color(hex: 0xFF8FAB)).frame(width: 18, height: 18).offset(y: -8)
                Circle().fill(Color(hex: 0xFF8FAB)).frame(width: 16, height: 16).offset(x: -12, y: 2)
                Circle().fill(Color(hex: 0xFF8FAB)).frame(width: 16, height: 16).offset(x: 12, y: 2)
                Circle().fill(Color(hex: 0xFFE7AD)).frame(width: 12, height: 12)
                Capsule().fill(Color(hex: 0x3F933D)).frame(width: 4, height: 22).offset(y: 16)
            case "gift.stone":
                FriendsStone()
            default:
                FriendsHeartShape().fill(FriendsPaint.heart).frame(width: 36, height: 32)
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
        .navigationTitle(engine.t("friends.fun.post"))
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
