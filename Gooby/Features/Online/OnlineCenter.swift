import BackgroundTasks
import Foundation
import Observation
import UIKit
import UserNotifications

enum OnlineVia {
    case nearby
    case server
}

struct NearbyPeer: Identifiable, Equatable {
    let id: String
    let name: String
}

@MainActor
@Observable
final class OnlineCenter {
    static let shared = OnlineCenter()
    static let refreshTaskID = "gooby.online.refresh"

    private(set) var state = OnlineState.load()
    private(set) var revision = 0
    private(set) var syncing = false
    var bluetoothNote = ""
    var meetNote = ""
    var pairingPeers: [NearbyPeer] = []
    var pairingInvite: NearbyPeer?
    var pairingNote = ""
    var pairedName: String?

    @ObservationIgnored private weak var engine: GoobyEngine?
    @ObservationIgnored private var beacon: OnlineBeacon?
    @ObservationIgnored private var pairing: NearbyPairing?
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var launched = false
    @ObservationIgnored private var backgroundWork = UIBackgroundTaskIdentifier.invalid

    private init() {}

    // Must run before launch finishes. BGTaskScheduler refuses a later registration,
    // and Core Bluetooth restores a beacon only if its managers exist at launch.
    static func prepareLaunch() {
        let center = shared
        guard !center.launched else { return }
        center.launched = true
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskID, using: nil) { task in
            let finish = RefreshFinish()
            task.expirationHandler = { finish.finish(task, success: false) }
            Task { @MainActor in
                let ok = await OnlineCenter.shared.syncServer()
                OnlineCenter.shared.scheduleRefresh()
                finish.finish(task, success: ok)
            }
        }
        center.applyNearby()
        center.observeLifecycle()
    }

    func attach(_ engine: GoobyEngine) {
        self.engine = engine
        refreshOwnCard()
        claimTreeInviteIfDue()
        applyPending()
        if UIApplication.shared.applicationState == .active {
            becameActive()
        }
    }

    func t(_ key: String) -> String { StringTable.text(key, engine?.languageCode ?? state.language) }

    var hasFriends: Bool { !state.friends.isEmpty }

    var serverConfigured: Bool { client != nil }

    var signedIn: Bool { !state.accountToken.isEmpty && !state.saveKey.isEmpty }

    private var client: OnlineServerClient? {
        OnlineServerClient(address: state.serverURL, key: state.serverKey)
    }

    private func persist() {
        state.save()
        let published = state
        state = published
        revision += 1
    }

    // MARK: Lifecycle

    private func observeLifecycle() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in OnlineCenter.shared.becameActive() }
        })
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            Task { @MainActor in OnlineCenter.shared.enteredBackground() }
        })
    }

    private func becameActive() {
        refreshOwnCard()
        applyPending()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { _ in
            Task { @MainActor in
                OnlineCenter.shared.refreshOwnCard()
                await OnlineCenter.shared.syncServer()
            }
        }
        Task { await syncServer() }
    }

    private func enteredBackground() {
        timer?.invalidate()
        timer = nil
        refreshOwnCard()
        scheduleRefresh()
        guard serverConfigured, backgroundWork == .invalid else { return }
        backgroundWork = UIApplication.shared.beginBackgroundTask(withName: "gooby-online") {
            Task { @MainActor in OnlineCenter.shared.endBackgroundWork() }
        }
        Task {
            await syncServer()
            endBackgroundWork()
        }
    }

    private func endBackgroundWork() {
        guard backgroundWork != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundWork)
        backgroundWork = .invalid
    }

    func scheduleRefresh() {
        guard serverConfigured, !state.friends.isEmpty || !state.invites.isEmpty else { return }
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 20 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: Own card

    func refreshOwnCard() {
        guard let engine else { return }
        var card = GoobyCard()
        card.code = GoobyFriendCode.make(profileID: engine.profile.id)
        card.nickname = String(engine.profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
        let pet = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        card.goobyName = String((pet.isEmpty ? "Gooby" : pet).prefix(24))
        card.stage = Growth.stage(of: engine.pet)
        card.fur = engine.pet.furStyle
        let today = engine.dayKey()
        card.mood = engine.all(MoodEntry.self)
            .filter { $0.dayKey == today }
            .max { $0.recordedAt < $1.recordedAt }?.level ?? 0
        card.streak = engine.streak()
        let progress = engine.todayProgress()
        card.done = progress.done
        card.total = progress.total
        card.careDays = engine.pet.careDays
        card.companion = engine.all(MiniFriend.self).first { $0.isCompanion }?.speciesID ?? ""
        card.updatedAt = Int(Date().timeIntervalSince1970)
        if let old = state.ownCard, old.sameContent(as: card) {
            card.updatedAt = old.updatedAt
        }
        guard state.ownCard != card || state.language != engine.languageCode else { return }
        state.ownCard = card
        state.language = engine.languageCode
        persist()
    }

    // MARK: Shared merge

    private func envelope(for friend: OnlineFriend, gifts: Int, acks: Int) -> SyncEnvelope? {
        guard let card = state.ownCard else { return nil }
        return SyncEnvelope(
            from: state.memberID,
            card: card,
            gifts: Array(friend.outbox.prefix(gifts)),
            acks: Array(friend.received.suffix(acks)),
            sentAt: Int(Date().timeIntervalSince1970)
        )
    }

    private func sealedEnvelope(for friend: OnlineFriend, maxBytes: Int?) -> Data? {
        let attempts: [(Int, Int)] = maxBytes == nil ? [(64, 80)] : [(8, 24), (4, 12), (2, 6), (1, 3), (0, 2), (0, 0)]
        for (gifts, acks) in attempts {
            guard let value = envelope(for: friend, gifts: gifts, acks: acks),
                  let sealed = try? SyncSeal.seal(value, secret: friend.pairKey) else { return nil }
            if let maxBytes, sealed.count > maxBytes { continue }
            return sealed
        }
        return nil
    }

    private func receive(_ envelope: SyncEnvelope, at index: Int, via: OnlineVia) {
        guard state.friends.indices.contains(index) else { return }
        var friend = state.friends[index]
        guard envelope.from == friend.id else { return }
        if envelope.card.updatedAt >= (friend.card?.updatedAt ?? -1) {
            friend.card = envelope.card
        }
        for gift in envelope.gifts {
            guard gift.kind == GoobyGift.heart || gift.kind == GoobyGift.sparks else { continue }
            if let seen = friend.received.firstIndex(of: gift.id) {
                friend.received.remove(at: seen)
                friend.received.append(gift.id)
                continue
            }
            friend.received.append(gift.id)
            friend.pendingGifts.append(gift)
        }
        if friend.received.count > 120 {
            friend.received.removeFirst(friend.received.count - 120)
        }
        friend.outbox.removeAll { envelope.acks.contains($0.id) }
        switch via {
        case .nearby:
            friend.lastMetAt = Date()
        case .server:
            let heard = Date(timeIntervalSince1970: TimeInterval(envelope.sentAt))
            friend.lastServerAt = max(friend.lastServerAt ?? .distantPast, heard)
        }
        state.friends[index] = friend
        persist()
        adoptIntoTree(friend)
        applyPending()
    }

    @discardableResult
    private func addFriend(member: String, pairKey: Data, card: GoobyCard) -> Int {
        if let index = state.friends.firstIndex(where: { $0.id == member }) {
            state.friends[index].pairKey = pairKey
            state.friends[index].card = card
            persist()
            adoptIntoTree(state.friends[index])
            return index
        }
        if !card.code.isEmpty {
            state.friends.removeAll { $0.card?.code == card.code }
        }
        state.friends.append(OnlineFriend(id: member, pairKey: pairKey, card: card))
        persist()
        let index = state.friends.count - 1
        adoptIntoTree(state.friends[index])
        return index
    }

    func forget(code: String) {
        let before = state.friends.count
        state.friends.removeAll { $0.card?.code == code }
        if state.friends.count != before { persist() }
    }

    private func adoptIntoTree(_ friend: OnlineFriend) {
        guard let card = friend.card, GoobyFriendCode.isShape(card.code) else { return }
        var book = FriendsBook.load()
        if let index = book.pals.firstIndex(where: { $0.code == card.code }) {
            if book.pals[index].name != friend.displayName {
                book.pals[index].name = friend.displayName
                book.save()
            }
            return
        }
        book.pals.append(TreePal(id: UUID(), name: friend.displayName, code: card.code))
        book.save()
        claimTreeInviteIfDue()
    }

    private func claimTreeInviteIfDue() {
        guard let engine else { return }
        var book = FriendsBook.load()
        guard !book.inviteClaimed, !book.pals.isEmpty else { return }
        book.inviteClaimed = true
        book.save()
        engine.hatchInviteFriend()
        engine.haptics.celebrate()
    }

    func applyPending() {
        guard let engine else { return }
        var lines: [String] = []
        var changed = false
        for index in state.friends.indices where !state.friends[index].pendingGifts.isEmpty {
            let friend = state.friends[index]
            for gift in friend.pendingGifts {
                let sparks = gift.kind == GoobyGift.sparks ? min(max(gift.amount, 0), 10) : 0
                guard engine.grant(key: "online-gift:\(friend.id):\(gift.id)", sparks: sparks, energy: 0) else { continue }
                if gift.kind == GoobyGift.heart {
                    engine.pet.affection += 1
                    lines.append(engine.tf("online.gift.heartGot", friend.displayName))
                } else {
                    lines.append(engine.tf("online.gift.sparksGot", friend.displayName, sparks))
                }
            }
            state.friends[index].pendingGifts = []
            changed = true
        }
        guard changed else { return }
        persist()
        engine.save()
        if let last = lines.last {
            engine.banner = last
            engine.haptics.celebrate()
        }
    }

    func sendGift(_ kind: String, to id: String) -> String {
        guard let engine, let index = state.friends.firstIndex(where: { $0.id == id }) else { return "" }
        let today = engine.dayKey()
        var friend = state.friends[index]
        var amount = 1
        if kind == GoobyGift.heart {
            guard friend.lastHeartDay != today else { return engine.t("online.gift.already") }
            friend.lastHeartDay = today
        } else {
            guard friend.lastSparksDay != today else { return engine.t("online.gift.already") }
            amount = GoobyGift.sparkAmount
            guard engine.wallet.sparks >= amount else { return engine.t("online.gift.poor") }
            engine.wallet.sparks -= amount
            engine.wallet.lifetimeSparksSpent += amount
            engine.save()
            friend.lastSparksDay = today
        }
        friend.outbox.append(GoobyGift(id: SyncSeal.shortID(), kind: kind, amount: amount, sentAt: Int(Date().timeIntervalSince1970)))
        if friend.outbox.count > 30 {
            friend.outbox.removeFirst(friend.outbox.count - 30)
        }
        state.friends[index] = friend
        persist()
        engine.haptics.celebrate()
        Task { await syncServer() }
        return engine.tf("online.gift.sent", friend.displayName)
    }

    // MARK: Bluetooth meetups

    func setNearby(_ on: Bool) {
        state.nearbyOn = on
        persist()
        applyNearby()
    }

    private func applyNearby() {
        if state.nearbyOn {
            if beacon == nil { beacon = OnlineBeacon(center: self) }
            beacon?.start()
        } else {
            beacon?.stop()
            beacon = nil
            bluetoothNote = ""
        }
    }

    func beaconWho() -> Data {
        let hour = SyncSeal.hour()
        return state.friends.prefix(60).reduce(Data()) { $0 + SyncSeal.meetTag($1.pairKey, hour: hour) }
    }

    private func friendIndex(matching tags: Set<Data>) -> Int? {
        let hour = SyncSeal.hour()
        return state.friends.firstIndex { friend in
            (hour - 1...hour + 1).contains { tags.contains(SyncSeal.meetTag(friend.pairKey, hour: $0)) }
        }
    }

    func beaconFrame(forWho who: Data) -> (String, Data)? {
        var tags = Set<Data>()
        var offset = 0
        while offset + 8 <= who.count {
            let start = who.startIndex + offset
            tags.insert(who.subdata(in: start..<(start + 8)))
            offset += 8
        }
        guard let index = friendIndex(matching: tags) else { return nil }
        let friend = state.friends[index]
        if let met = friend.lastMetAt, Date().timeIntervalSince(met) < 180 { return nil }
        refreshOwnCard()
        guard let sealed = sealedEnvelope(for: state.friends[index], maxBytes: 500) else { return nil }
        return (friend.id, SyncSeal.meetTag(friend.pairKey, hour: SyncSeal.hour()) + sealed)
    }

    func beaconIncoming(_ frame: Data) -> Data? {
        guard frame.count > 8 else { return nil }
        let tag = Data(frame.prefix(8))
        let body = Data(frame.dropFirst(8))
        guard let index = friendIndex(matching: [tag]),
              let value = try? SyncSeal.open(SyncEnvelope.self, body, secret: state.friends[index].pairKey) else { return nil }
        let id = state.friends[index].id
        refreshOwnCard()
        receive(value, at: index, via: .nearby)
        noteMeetup(id)
        guard let fresh = state.friends.first(where: { $0.id == id }) else { return nil }
        return sealedEnvelope(for: fresh, maxBytes: 510)
    }

    func beaconReply(_ data: Data, friendID: String) {
        guard let index = state.friends.firstIndex(where: { $0.id == friendID }),
              let value = try? SyncSeal.open(SyncEnvelope.self, data, secret: state.friends[index].pairKey) else { return }
        receive(value, at: index, via: .nearby)
        noteMeetup(friendID)
    }

    private func noteMeetup(_ id: String) {
        guard let index = state.friends.firstIndex(where: { $0.id == id }) else { return }
        if let last = state.friends[index].lastNotifiedAt, Date().timeIntervalSince(last) < 3600 { return }
        state.friends[index].lastNotifiedAt = Date()
        persist()
        let name = state.friends[index].displayName
        let body = String(format: t("online.met.body"), name)
        if UIApplication.shared.applicationState == .active {
            meetNote = body
            engine?.banner = body
            engine?.haptics.celebrate()
            Task {
                try? await Task.sleep(for: .seconds(3))
                if meetNote == body { meetNote = "" }
            }
            return
        }
        let content = UNMutableNotificationContent()
        content.title = t("online.met.title")
        content.body = body
        let request = UNNotificationRequest(identifier: "online-met-\(id)", content: content, trigger: nil)
        Task { try? await UNUserNotificationCenter.current().add(request) }
    }

    // MARK: Multipeer pairing

    func startPairing() {
        refreshOwnCard()
        pairing?.stop()
        pairedName = nil
        pairingPeers = []
        pairingInvite = nil
        pairingNote = t("online.pair.searching")
        let nickname = state.ownCard?.nickname ?? ""
        let name = nickname.isEmpty ? (state.ownCard?.goobyName ?? "Gooby") : nickname
        let session = NearbyPairing(center: self, nickname: name)
        pairing = session
        session.start()
    }

    func stopPairing() {
        pairing?.stop()
        pairing = nil
        pairingPeers = []
        pairingInvite = nil
    }

    func invitePeer(_ peer: NearbyPeer) {
        pairingNote = String(format: t("online.pair.waiting"), peer.name)
        pairing?.invite(peer.id)
    }

    func answerInvite(_ accept: Bool) {
        pairingInvite = nil
        if accept { pairingNote = t("online.pair.connecting") }
        pairing?.answer(accept)
    }

    func pairingFound(_ peers: [NearbyPeer]) {
        pairingPeers = peers
    }

    func pairingInvited(by peer: NearbyPeer) {
        pairingInvite = peer
    }

    func pairingHello(keyPart: Data) -> PairingHello? {
        guard let card = state.ownCard else { return nil }
        return PairingHello(member: state.memberID, card: card, keyPart: keyPart)
    }

    func pairingReceived(_ hello: PairingHello, myPart: Data) {
        guard hello.member != state.memberID, hello.keyPart.count == 32 else { return }
        let key = SyncSeal.combine(myPart, hello.keyPart)
        let index = addFriend(member: hello.member, pairKey: key, card: hello.card)
        state.friends[index].lastMetAt = Date()
        if !state.nearbyOn { state.nearbyOn = true }
        persist()
        applyNearby()
        pairedName = state.friends[index].displayName
        pairingNote = ""
        engine?.haptics.celebrate()
        Task { await syncServer() }
    }

    func pairingFailed(_ key: String) {
        guard pairedName == nil else { return }
        pairingNote = t(key)
    }

    // MARK: Server

    func configureServer(address: String, key: String) async -> String {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            let oldToken = state.accountToken
            let oldClient = client
            state.serverURL = ""
            state.serverKey = ""
            state.lastSyncError = ""
            clearAccountSession()
            persist()
            if let oldClient, !oldToken.isEmpty {
                try? await oldClient.logout(token: oldToken)
            }
            return t("online.server.cleared")
        }
        guard let candidate = OnlineServerClient(address: trimmed, key: key) else { return t("online.server.bad") }
        if candidate.base.absoluteString != state.serverURL {
            clearAccountSession()
        }
        state.serverURL = candidate.base.absoluteString
        state.serverKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
        do {
            let info = try await candidate.info()
            guard info.service == "gooby-sync" else { return t("online.server.notGooby") }
            if info.keyRequired && state.serverKey.isEmpty { return t("online.server.needsKey") }
            await syncServer()
            if !state.lastSyncError.isEmpty { return state.lastSyncError }
            return candidate.isSecure ? t("online.server.ok") : t("online.server.insecure")
        } catch {
            return describe(error)
        }
    }

    @discardableResult
    func syncServer() async -> Bool {
        guard !syncing, let client else { return false }
        syncing = true
        defer {
            syncing = false
            scheduleRefresh()
        }
        refreshOwnCard()
        do {
            try await syncAccount(client)
            for id in state.friends.map(\.id) {
                try await syncFriend(id, client)
            }
            try await syncInvites(client)
            if signedIn { try await pushAccount(client, allowRetry: true) }
            state.lastSyncAt = Date()
            state.lastSyncError = ""
            persist()
            return true
        } catch {
            if let sync = error as? SyncError, case let .http(_, code) = sync, code == "session" {
                clearAccountSession()
            }
            state.lastSyncError = describe(error)
            persist()
            return false
        }
    }

    func createAccount(name: String, password: String) async -> String {
        let display = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !display.isEmpty else { return t("online.account.needName") }
        guard password.count >= 8 else { return t("online.account.short") }
        guard let client else { return t("online.invite.needServer") }
        do {
            let session = try await client.createAccount(name: display, password: password, memberId: state.memberID)
            adopt(session, name: display, password: password)
            await syncServer()
            if !state.lastSyncError.isEmpty { return state.lastSyncError }
            return t("online.account.created")
        } catch {
            return describe(error)
        }
    }

    func loginAccount(name: String, password: String) async -> String {
        let display = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !display.isEmpty else { return t("online.account.needName") }
        guard password.count >= 8 else { return t("online.account.short") }
        guard let client else { return t("online.invite.needServer") }
        do {
            let session = try await client.login(name: display, password: password)
            adopt(session, name: display, password: password)
            await syncServer()
            if !state.lastSyncError.isEmpty { return state.lastSyncError }
            return String(format: t("online.account.ready"), state.accountName)
        } catch {
            return describe(error)
        }
    }

    func logoutAccount() async -> String {
        let token = state.accountToken
        let current = client
        clearAccountSession()
        persist()
        if let current, !token.isEmpty {
            try? await current.logout(token: token)
        }
        return t("online.account.out")
    }

    private func adopt(_ session: OnlineServerClient.Session, name: String, password: String) {
        state.accountName = name
        state.accountID = session.accountId
        state.accountToken = session.token
        if !session.memberId.isEmpty { state.memberID = session.memberId }
        state.saveKey = SyncSeal.accountKey(password)
        state.saveRevision = 0
        state.saveDigest = ""
        persist()
    }

    private func clearAccountSession() {
        state.accountName = ""
        state.accountID = ""
        state.accountToken = ""
        state.saveKey = Data()
        state.saveRevision = 0
        state.saveDigest = ""
    }

    private func syncAccount(_ client: OnlineServerClient) async throws {
        guard signedIn else { return }
        let remote = try await client.accountDocument(token: state.accountToken)
        if remote.revision > state.saveRevision {
            if let blob = remote.blob, !blob.isEmpty {
                try applyAccount(blob, revision: remote.revision)
            } else {
                state.saveRevision = remote.revision
                persist()
            }
            return
        }
        try await pushAccount(client, allowRetry: true)
    }

    private func pushAccount(_ client: OnlineServerClient, allowRetry: Bool) async throws {
        let bundle = try makeBundle()
        let digest = try SyncSeal.digest(bundle)
        guard digest != state.saveDigest else { return }
        let sealed = try SyncSeal.seal(bundle, secret: state.saveKey, label: "account-v1")
        let next = state.saveRevision + 1
        let saved = try await client.putAccount(token: state.accountToken, revision: next, blob: sealed)
        if saved.revision == next {
            state.saveRevision = next
            state.saveDigest = digest
            persist()
            return
        }
        if let blob = saved.blob, !blob.isEmpty {
            try applyAccount(blob, revision: saved.revision)
            return
        }
        state.saveRevision = saved.revision
        state.saveDigest = ""
        persist()
        guard allowRetry else { return }
        try await pushAccount(client, allowRetry: false)
    }

    private func makeBundle() throws -> AccountBundle {
        guard let engine else { throw SyncError.unreadable }
        refreshOwnCard()
        guard let card = state.ownCard else { throw SyncError.unreadable }
        let envelope = SyncEnvelope(
            from: state.memberID,
            card: card,
            gifts: [],
            acks: [],
            sentAt: card.updatedAt
        )
        return AccountBundle(
            profileID: engine.profile.id.uuidString,
            export: try engine.exportData(password: nil),
            friends: state.friends,
            invites: state.invites,
            envelope: envelope
        )
    }

    private func applyAccount(_ blob: Data, revision: Int) throws {
        guard let engine else { throw SyncError.unreadable }
        let bundle = try SyncSeal.open(AccountBundle.self, blob, secret: state.saveKey, label: "account-v1")
        try engine.importData(bundle.export, password: nil)
        if let id = UUID(uuidString: bundle.profileID) {
            engine.profile.id = id
            engine.save()
        }
        state.friends = bundle.friends
        state.invites = bundle.invites
        if !bundle.envelope.from.isEmpty { state.memberID = bundle.envelope.from }
        state.ownCard = bundle.envelope.card
        state.saveRevision = revision
        persist()
        applyPending()
        if let fresh = try? makeBundle() {
            state.saveDigest = (try? SyncSeal.digest(fresh)) ?? ""
        } else {
            state.saveDigest = ""
        }
        persist()
    }

    private func syncFriend(_ id: String, _ client: OnlineServerClient) async throws {
        guard let friend = state.friends.first(where: { $0.id == id }) else { return }
        let channel = SyncSeal.channelID(friend.pairKey)
        let token = SyncSeal.channelToken(friend.pairKey)
        let mine = SyncSeal.slot(friend.pairKey, member: state.memberID)
        let slots = try await client.pull(channel: channel, token: token)
        for slot in slots where slot.slot != mine {
            guard let index = state.friends.firstIndex(where: { $0.id == id }),
                  let value = try? SyncSeal.open(SyncEnvelope.self, slot.blob, secret: state.friends[index].pairKey),
                  value.from == id else { continue }
            receive(value, at: index, via: .server)
        }
        guard let fresh = state.friends.first(where: { $0.id == id }),
              let sealed = sealedEnvelope(for: fresh, maxBytes: nil) else { return }
        try await client.push(channel: channel, slot: mine, token: token, blob: sealed)
    }

    private func syncInvites(_ client: OnlineServerClient) async throws {
        let cutoff = Date().addingTimeInterval(-72 * 3600)
        if state.invites.contains(where: { $0.createdAt < cutoff }) {
            state.invites.removeAll { $0.createdAt < cutoff }
            persist()
        }
        for invite in state.invites {
            let channel = SyncSeal.channelID(invite.pairKey)
            let token = SyncSeal.channelToken(invite.pairKey)
            let mine = SyncSeal.slot(invite.pairKey, member: state.memberID)
            let slots = try await client.pull(channel: channel, token: token)
            for slot in slots where slot.slot != mine {
                guard let value = try? SyncSeal.open(SyncEnvelope.self, slot.blob, secret: invite.pairKey),
                      value.from != state.memberID else { continue }
                let index = addFriend(member: value.from, pairKey: invite.pairKey, card: value.card)
                receive(value, at: index, via: .server)
                state.invites.removeAll { $0.code == invite.code }
                persist()
                try await syncFriend(value.from, client)
                break
            }
        }
    }

    func createInvite() async -> (code: String?, note: String) {
        refreshOwnCard()
        guard let client else { return (nil, t("online.invite.needServer")) }
        guard let card = state.ownCard else { return (nil, t("online.server.failed")) }
        let code = SyncSeal.makeInviteCode()
        let pairKey = SyncSeal.randomBytes()
        do {
            let payload = InvitePayload(member: state.memberID, card: card, pairKey: pairKey)
            let blob = try SyncSeal.seal(payload, secret: SyncSeal.inviteSecret(code), label: "invite-v1")
            try await client.postInvite(id: SyncSeal.inviteID(code), blob: blob)
            state.invites.append(OnlineInvite(code: code, pairKey: pairKey, createdAt: Date()))
            persist()
            return (code, t("online.invite.made"))
        } catch {
            return (nil, describe(error))
        }
    }

    func claimInvite(_ raw: String) async -> String {
        let code = SyncSeal.normalizeInvite(raw)
        guard code.count == 10 else { return t("online.invite.badCode") }
        guard let client else { return t("online.invite.needServer") }
        guard !state.invites.contains(where: { SyncSeal.normalizeInvite($0.code) == code }) else { return t("online.invite.own") }
        refreshOwnCard()
        do {
            let blob = try await client.claimInvite(id: SyncSeal.inviteID(code))
            let payload = try SyncSeal.open(InvitePayload.self, blob, secret: SyncSeal.inviteSecret(code), label: "invite-v1")
            guard payload.member != state.memberID, payload.pairKey.count == 32 else { return t("online.invite.own") }
            let index = addFriend(member: payload.member, pairKey: payload.pairKey, card: payload.card)
            let id = state.friends[index].id
            let name = state.friends[index].displayName
            try await syncFriend(id, client)
            return String(format: t("online.invite.joined"), name)
        } catch let sync as SyncError {
            if case .http(404, _) = sync { return t("online.invite.missing") }
            return describe(sync)
        } catch {
            return describe(error)
        }
    }

    private func describe(_ error: Error) -> String {
        if let sync = error as? SyncError {
            switch sync {
            case .badURL:
                return t("online.server.bad")
            case let .http(status, code):
                switch code {
                case "exists": return t("online.account.taken")
                case "password": return t("online.account.bad")
                case "session": return t("online.account.signedOut")
                case "key": return t("online.server.keyWrong")
                default: break
                }
                switch status {
                case 401: return t("online.server.keyWrong")
                case 403, 409: return t("online.server.denied")
                case 413: return t("online.server.tooBig")
                case 429: return t("online.server.busy")
                default: return String(format: t("online.server.status"), status)
                }
            default:
                return t("online.server.failed")
            }
        }
        if error is URLError { return t("online.server.unreachable") }
        return t("online.server.failed")
    }
}

private final class RefreshFinish: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false

    func finish(_ task: BGTask, success: Bool) {
        lock.lock()
        let first = !done
        done = true
        lock.unlock()
        guard first else { return }
        task.setTaskCompleted(success: success)
    }
}
