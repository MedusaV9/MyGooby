import Foundation
import MultipeerConnectivity

// Face-to-face pairing. Both phones keep this session open, one invites, the other
// accepts. Each side contributes half of the pair key. The session itself is
// encrypted by Multipeer. Later meetups do not use this class; they use OnlineBeacon,
// which can run in the background. Multipeer stays in the foreground on purpose:
// iOS will not keep a peer session alive once the app is suspended.
@MainActor
final class NearbyPairing: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    static let serviceType = "gooby-pass"

    private weak var center: OnlineCenter?
    private let nickname: String
    private let me: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    private let keyPart = SyncSeal.randomBytes()
    private var found: [String: (peer: MCPeerID, name: String)] = [:]
    private var pendingAnswer: ((Bool, MCSession?) -> Void)?
    private var done = false
    private var running = false

    init(center: OnlineCenter, nickname: String) {
        self.center = center
        let trimmed = String(nickname.prefix(20))
        let name = trimmed.isEmpty ? "Gooby" : trimmed
        let peer = MCPeerID(displayName: "gooby-" + SyncSeal.shortID().lowercased())
        self.nickname = name
        me = peer
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: ["n": name], serviceType: NearbyPairing.serviceType)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: NearbyPairing.serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func start() {
        guard !running else { return }
        running = true
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func stop() {
        running = false
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        pendingAnswer?(false, nil)
        pendingAnswer = nil
        session.disconnect()
    }

    func invite(_ id: String) {
        guard let peer = found[id]?.peer else { return }
        browser.invitePeer(peer, to: session, withContext: Data(nickname.utf8), timeout: 30)
    }

    func answer(_ accept: Bool) {
        pendingAnswer?(accept, accept ? session : nil)
        pendingAnswer = nil
    }

    private func publish() {
        let peers = found.map { NearbyPeer(id: $0.key, name: $0.value.name) }.sorted { $0.name < $1.name }
        center?.pairingFound(peers)
    }

    private func sendHello(to peer: MCPeerID) {
        guard let hello = center?.pairingHello(keyPart: keyPart),
              let data = try? JSONEncoder().encode(hello) else { return }
        try? session.send(data, toPeers: [peer], with: .reliable)
    }

    private func received(_ data: Data) {
        guard !done, let hello = try? JSONDecoder().decode(PairingHello.self, from: data) else { return }
        done = true
        center?.pairingReceived(hello, myPart: keyPart)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            MainActor.assumeIsolated { self?.session.disconnect() }
        }
    }

    private func changed(_ state: MCSessionState, peer: MCPeerID) {
        switch state {
        case .connected:
            sendHello(to: peer)
        case .notConnected:
            if !done { center?.pairingFailed("online.pair.lost") }
        default:
            break
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        let name = String((info?["n"] ?? "Gooby").prefix(20))
        Task { @MainActor in
            self.found[peerID.displayName] = (peerID, name)
            self.publish()
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.found.removeValue(forKey: peerID.displayName)
            self.publish()
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in self.center?.pairingFailed("online.pair.denied") }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let raw = context.flatMap { String(data: $0, encoding: .utf8) } ?? "Gooby"
        let name = String(raw.prefix(20))
        Task { @MainActor in
            self.pendingAnswer?(false, nil)
            self.pendingAnswer = invitationHandler
            self.center?.pairingInvited(by: NearbyPeer(id: peerID.displayName, name: name))
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in self.center?.pairingFailed("online.pair.denied") }
    }

    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in self.changed(state, peer: peerID) }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in self.received(data) }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
