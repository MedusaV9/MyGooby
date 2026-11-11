import SwiftUI
import UIKit

struct OnlineFriendsSection: View {
    var engine: GoobyEngine
    private var center: OnlineCenter { MainActor.assumeIsolated { OnlineCenter.shared } }
    @State private var showPairing = false
    @State private var inviteCode = ""
    @State private var madeCode = ""
    @State private var note = ""
    @State private var busy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(engine.t("online.section"))
                .font(.system(.headline, design: .rounded))
                .padding(.top, 8)
            Text(engine.t("online.limits"))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.72))
            Toggle(engine.t("online.nearby"), isOn: Binding(
                get: { center.state.nearbyOn },
                set: { center.setNearby($0) }
            ))
            .font(.system(.body, design: .rounded).weight(.semibold))
            Text(engine.t("online.nearby.sub"))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.72))
            if center.state.nearbyOn, !center.bluetoothNote.isEmpty {
                Text(engine.t(center.bluetoothNote))
                    .font(.system(.subheadline, design: .rounded))
            }
            Button(engine.t("online.pair")) { showPairing = true }
                .buttonStyle(GoobyButtonStyle(fill: Theme.mint, ink: Theme.ink))
            if center.serverConfigured {
                Button(engine.t("online.invite.make")) { makeInvite() }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
                    .disabled(busy)
                if !madeCode.isEmpty {
                    Text(madeCode)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .textSelection(.enabled)
                    Button(engine.t("friends.tree.copy")) {
                        UIPasteboard.general.string = madeCode
                        note = engine.t("online.invite.copied")
                    }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.sky, ink: Theme.ink))
                }
                TextField(engine.t("online.invite.enter"), text: $inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button(engine.t("online.invite.claim")) { claim() }
                    .buttonStyle(GoobyButtonStyle(fill: FriendsPaint.buttonInk, ink: .white))
                    .disabled(busy)
            } else {
                Text(engine.t("online.sheet.server"))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.72))
            }
            if !note.isEmpty {
                Text(note)
                    .font(.system(.subheadline, design: .rounded))
            }
            if center.state.friends.isEmpty {
                Text(engine.t("online.friends.empty"))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.72))
            } else {
                ForEach(center.state.friends) { friend in
                    friendCard(friend)
                }
            }
        }
        .id(center.revision)
        .sheet(isPresented: $showPairing) {
            OnlinePairingSheet(engine: engine)
        }
    }

    private func friendCard(_ friend: OnlineFriend) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(friend.displayName)
                .font(.system(.headline, design: .rounded))
            if let card = friend.card {
                Text(engine.tf("online.friend.gooby", card.goobyName))
                Text(engine.tf("online.friend.stage", engine.t("pet.stage.\(card.stage)")))
                if card.mood > 0 {
                    Text(engine.tf("online.friend.mood", engine.t("mood.level.\(card.mood)")))
                } else {
                    Text(engine.t("online.friend.moodNone"))
                }
                Text(engine.tf("online.friend.streak", card.streak))
                Text(engine.tf("online.friend.progress", card.done, card.total))
                if !card.companion.isEmpty {
                    let species = engine.catalog.friendsByID[card.companion]?.name.text(engine.languageCode) ?? card.companion
                    Text(engine.tf("online.friend.companion", species))
                }
            } else {
                Text(engine.t("online.friend.waiting"))
            }
            if let met = friend.lastMetAt {
                Text(engine.tf("online.friend.met", engine.formatDate(met, time: true)))
            }
            if let synced = friend.lastServerAt {
                Text(engine.tf("online.friend.server", engine.formatDate(synced, time: true)))
            }
            HStack(spacing: 8) {
                Button(engine.t("online.gift.heart")) {
                    note = center.sendGift(GoobyGift.heart, to: friend.id)
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.pink, ink: Theme.ink))
                Button(engine.t("online.gift.sparks")) {
                    note = center.sendGift(GoobyGift.sparks, to: friend.id)
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.yellow, ink: Theme.ink))
            }
        }
        .font(.system(.subheadline, design: .rounded))
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func makeInvite() {
        busy = true
        Task {
            let result = await center.createInvite()
            if let code = result.code { madeCode = code }
            note = result.note
            busy = false
        }
    }

    private func claim() {
        busy = true
        Task {
            note = await center.claimInvite(inviteCode)
            inviteCode = ""
            busy = false
        }
    }
}

struct OnlinePairingSheet: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    private var center: OnlineCenter { MainActor.assumeIsolated { OnlineCenter.shared } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(engine.t("online.pair.lead"))
                        .font(.system(.body, design: .rounded))
                    if let invite = center.pairingInvite {
                        Text(invite.name)
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                        Button(engine.t("online.pair.accept")) { center.answerInvite(true) }
                            .buttonStyle(GoobyButtonStyle(fill: Theme.mint, ink: Theme.ink))
                        Button(engine.t("online.pair.decline")) { center.answerInvite(false) }
                            .buttonStyle(GoobyButtonStyle(fill: Theme.peach, ink: Theme.ink))
                    }
                    if let paired = center.pairedName {
                        Text(engine.tf("online.pair.done", paired))
                            .font(.system(.headline, design: .rounded))
                    }
                    if !center.pairingNote.isEmpty {
                        Text(center.pairingNote)
                            .font(.system(.subheadline, design: .rounded))
                    }
                    if center.pairingPeers.isEmpty && center.pairingInvite == nil && center.pairedName == nil {
                        Text(engine.t("online.pair.none"))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Theme.ink.opacity(0.72))
                    }
                    ForEach(center.pairingPeers) { peer in
                        Button(peer.name) { center.invitePeer(peer) }
                            .buttonStyle(GoobyButtonStyle(fill: FriendsPaint.buttonInk, ink: .white))
                    }
                }
                .padding(20)
                .foregroundStyle(Theme.ink)
            }
            .background(Theme.cream)
            .navigationTitle(engine.t("online.pair.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(engine.t("online.pair.close")) { dismiss() }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear { center.startPairing() }
        .onDisappear { center.stopPairing() }
    }
}

struct OnlineSettingsPage: View {
    var engine: GoobyEngine
    private var center: OnlineCenter { MainActor.assumeIsolated { OnlineCenter.shared } }
    @State private var address = ""
    @State private var key = ""
    @State private var note = ""
    @State private var busy = false

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(engine.t("online.settings.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.t("online.settings.lead"))
                    .foregroundStyle(Look.row)
                Text(engine.t("online.settings.hint"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                LookCard {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField(engine.t("online.settings.address"), text: $address)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        SecureField(engine.t("online.settings.key"), text: $key)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button(engine.t("online.settings.save")) { save() }
                            .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                            .disabled(busy)
                        Button(engine.t("online.settings.clear")) {
                            address = ""
                            key = ""
                            save()
                        }
                        .buttonStyle(GoobyButtonStyle(fill: Look.track, ink: Look.ink))
                        .disabled(busy)
                        Button(engine.t("online.sync.now")) { syncNow() }
                            .buttonStyle(GoobyButtonStyle(fill: Theme.mint, ink: Theme.ink))
                            .disabled(busy || !center.serverConfigured)
                    }
                    .padding(14)
                }
                if let synced = center.state.lastSyncAt {
                    Text(engine.tf("online.settings.last", engine.formatDate(synced, time: true)))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.sub)
                } else {
                    Text(engine.t("online.settings.never"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.sub)
                }
                if !center.state.lastSyncError.isEmpty {
                    Text(center.state.lastSyncError)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.row)
                }
                if !note.isEmpty {
                    Text(note)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Look.ink)
                }
                Text(engine.t("online.limits"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.sub)
            }
        }
        .id(center.revision)
        .onAppear {
            address = center.state.serverURL
            key = center.state.serverKey
        }
    }

    private func save() {
        busy = true
        let typedAddress = address
        let typedKey = key
        Task {
            note = await center.configureServer(address: typedAddress, key: typedKey)
            busy = false
        }
    }

    private func syncNow() {
        busy = true
        Task {
            let ok = await center.syncServer()
            note = ok ? engine.t("online.server.ok") : center.state.lastSyncError
            busy = false
        }
    }
}
