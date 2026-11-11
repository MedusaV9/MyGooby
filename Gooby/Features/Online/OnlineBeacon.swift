import CoreBluetooth
import Foundation

// StreetPass-style meetups over Bluetooth LE. Every phone advertises one service and
// scans for that same service. A visit reads the peer's hourly friend tags, writes
// one sealed envelope for the matching friend, and reads the sealed answer.
// Values stay at or below 512 bytes, which is the ATT limit.
//
// Background: with the bluetooth-central and bluetooth-peripheral modes, iOS may
// wake the app briefly when a matching service is seen. It does not promise how
// often. After the app is force-quit, Bluetooth stays off until the next launch.
// Nearby Interaction is not used: the precise-distance entitlement is a special
// capability, and it does not carry this envelope.
@MainActor
final class OnlineBeacon: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    static let serviceUUID = CBUUID(string: "6B1E7A30-4C1F-4D7B-9E39-2C5A9F0B6D11")
    static let whoUUID = CBUUID(string: "6B1E7A31-4C1F-4D7B-9E39-2C5A9F0B6D11")
    static let inboxUUID = CBUUID(string: "6B1E7A32-4C1F-4D7B-9E39-2C5A9F0B6D11")
    static let replyUUID = CBUUID(string: "6B1E7A33-4C1F-4D7B-9E39-2C5A9F0B6D11")

    private final class Visit {
        let peripheral: CBPeripheral
        var friendID: String?
        var inbox: CBCharacteristic?
        var reply: CBCharacteristic?

        init(_ peripheral: CBPeripheral) {
            self.peripheral = peripheral
        }
    }

    private weak var center: OnlineCenter?
    private var central: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var visits: [UUID: Visit] = [:]
    private var lastVisit: [UUID: Date] = [:]
    private var whoCache: [UUID: Data] = [:]
    private var replies: [UUID: Data] = [:]
    private var serviceAdded = false

    init(center: OnlineCenter) {
        self.center = center
        super.init()
    }

    func start() {
        if central == nil {
            central = CBCentralManager(delegate: self, queue: nil, options: [
                CBCentralManagerOptionRestoreIdentifierKey: "gooby.online.central"
            ])
        }
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [
                CBPeripheralManagerOptionRestoreIdentifierKey: "gooby.online.peripheral"
            ])
        }
    }

    func stop() {
        if let central {
            central.stopScan()
            for visit in visits.values { central.cancelPeripheralConnection(visit.peripheral) }
        }
        visits = [:]
        if let peripheralManager {
            peripheralManager.stopAdvertising()
            peripheralManager.removeAllServices()
        }
        central?.delegate = nil
        peripheralManager?.delegate = nil
        central = nil
        peripheralManager = nil
        serviceAdded = false
    }

    private func report(_ state: CBManagerState) {
        switch state {
        case .unauthorized: center?.bluetoothNote = "online.bt.denied"
        case .poweredOff: center?.bluetoothNote = "online.bt.off"
        case .unsupported: center?.bluetoothNote = "online.bt.unsupported"
        case .poweredOn: center?.bluetoothNote = ""
        default: break
        }
    }

    private func centralChanged(_ manager: CBCentralManager) {
        report(manager.state)
        guard manager.state == .poweredOn else {
            visits = [:]
            return
        }
        manager.scanForPeripherals(withServices: [Self.serviceUUID], options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
    }

    private func discovered(_ peripheral: CBPeripheral, by manager: CBCentralManager) {
        let id = peripheral.identifier
        guard visits[id] == nil, visits.count < 3, center?.hasFriends == true else { return }
        if let last = lastVisit[id], Date().timeIntervalSince(last) < 120 { return }
        lastVisit[id] = Date()
        if lastVisit.count > 200 {
            lastVisit = lastVisit.filter { Date().timeIntervalSince($0.value) < 600 }
        }
        visits[id] = Visit(peripheral)
        peripheral.delegate = self
        manager.connect(peripheral, options: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            MainActor.assumeIsolated { self?.finish(id) }
        }
    }

    private func finish(_ id: UUID) {
        guard let visit = visits.removeValue(forKey: id) else { return }
        central?.cancelPeripheralConnection(visit.peripheral)
    }

    private func servicesFound(_ peripheral: CBPeripheral, error: Error?) {
        guard error == nil, let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            finish(peripheral.identifier)
            return
        }
        peripheral.discoverCharacteristics([Self.whoUUID, Self.inboxUUID, Self.replyUUID], for: service)
    }

    private func characteristicsFound(_ peripheral: CBPeripheral, service: CBService, error: Error?) {
        guard error == nil, let visit = visits[peripheral.identifier] else {
            finish(peripheral.identifier)
            return
        }
        let list = service.characteristics ?? []
        visit.inbox = list.first { $0.uuid == Self.inboxUUID }
        visit.reply = list.first { $0.uuid == Self.replyUUID }
        guard let who = list.first(where: { $0.uuid == Self.whoUUID }), visit.inbox != nil, visit.reply != nil else {
            finish(peripheral.identifier)
            return
        }
        peripheral.readValue(for: who)
    }

    private func valueArrived(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let visit = visits[peripheral.identifier] else {
            finish(peripheral.identifier)
            return
        }
        let value = characteristic.value ?? Data()
        if characteristic.uuid == Self.whoUUID {
            guard let inbox = visit.inbox, let outgoing = center?.beaconFrame(forWho: value) else {
                finish(peripheral.identifier)
                return
            }
            visit.friendID = outgoing.0
            peripheral.writeValue(outgoing.1, for: inbox, type: .withResponse)
        } else if characteristic.uuid == Self.replyUUID {
            if let friendID = visit.friendID, !value.isEmpty {
                center?.beaconReply(value, friendID: friendID)
            }
            finish(peripheral.identifier)
        }
    }

    private func wrote(_ peripheral: CBPeripheral, error: Error?) {
        guard error == nil, let reply = visits[peripheral.identifier]?.reply else {
            finish(peripheral.identifier)
            return
        }
        peripheral.readValue(for: reply)
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MainActor.assumeIsolated { self.centralChanged(central) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        MainActor.assumeIsolated {
            for peripheral in restored { central.cancelPeripheralConnection(peripheral) }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        MainActor.assumeIsolated { self.discovered(peripheral, by: central) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MainActor.assumeIsolated {
            peripheral.delegate = self
            peripheral.discoverServices([Self.serviceUUID])
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        MainActor.assumeIsolated { self.finish(peripheral.identifier) }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        MainActor.assumeIsolated { _ = self.visits.removeValue(forKey: peripheral.identifier) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        MainActor.assumeIsolated { self.servicesFound(peripheral, error: error) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        MainActor.assumeIsolated { self.characteristicsFound(peripheral, service: service, error: error) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        MainActor.assumeIsolated { self.valueArrived(peripheral, characteristic: characteristic, error: error) }
    }

    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        MainActor.assumeIsolated { self.wrote(peripheral, error: error) }
    }

    private func peripheralChanged(_ manager: CBPeripheralManager) {
        report(manager.state)
        guard manager.state == .poweredOn else {
            serviceAdded = false
            return
        }
        guard !serviceAdded else { return }
        serviceAdded = true
        let who = CBMutableCharacteristic(type: Self.whoUUID, properties: [.read], value: nil, permissions: [.readable])
        let inbox = CBMutableCharacteristic(type: Self.inboxUUID, properties: [.write], value: nil, permissions: [.writeable])
        let reply = CBMutableCharacteristic(type: Self.replyUUID, properties: [.read], value: nil, permissions: [.readable])
        let service = CBMutableService(type: Self.serviceUUID, primary: true)
        service.characteristics = [who, inbox, reply]
        manager.removeAllServices()
        manager.add(service)
    }

    private func serviceReady(_ manager: CBPeripheralManager, error: Error?) {
        guard error == nil else {
            serviceAdded = false
            return
        }
        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [Self.serviceUUID]])
    }

    private func answerRead(_ manager: CBPeripheralManager, _ request: CBATTRequest) {
        let key = request.central.identifier
        let data: Data
        if request.characteristic.uuid == Self.whoUUID {
            if request.offset == 0 || whoCache[key] == nil {
                whoCache[key] = center?.beaconWho() ?? Data()
            }
            data = whoCache[key] ?? Data()
        } else if request.characteristic.uuid == Self.replyUUID {
            data = replies[key] ?? Data()
        } else {
            manager.respond(to: request, withResult: .requestNotSupported)
            return
        }
        guard request.offset <= data.count else {
            manager.respond(to: request, withResult: .invalidOffset)
            return
        }
        request.value = data.subdata(in: request.offset..<data.count)
        manager.respond(to: request, withResult: .success)
    }

    private func answerWrite(_ manager: CBPeripheralManager, _ requests: [CBATTRequest]) {
        guard let first = requests.first else { return }
        guard requests.allSatisfy({ $0.characteristic.uuid == Self.inboxUUID }) else {
            manager.respond(to: first, withResult: .writeNotPermitted)
            return
        }
        var frame = Data()
        for request in requests.sorted(by: { $0.offset < $1.offset }) {
            let value = request.value ?? Data()
            guard request.offset <= frame.count, request.offset + value.count <= 512 else {
                manager.respond(to: first, withResult: .invalidOffset)
                return
            }
            var bytes = [UInt8](frame.prefix(request.offset))
            bytes.append(contentsOf: value)
            frame = Data(bytes)
        }
        let key = first.central.identifier
        replies[key] = center?.beaconIncoming(frame) ?? Data()
        if replies.count > 24 {
            replies = [key: replies[key] ?? Data()]
            whoCache = [:]
        }
        manager.respond(to: first, withResult: .success)
    }

    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        MainActor.assumeIsolated { self.peripheralChanged(peripheral) }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {}

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        MainActor.assumeIsolated { self.serviceReady(peripheral, error: error) }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        MainActor.assumeIsolated { self.answerRead(peripheral, request) }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        MainActor.assumeIsolated { self.answerWrite(peripheral, requests) }
    }
}
