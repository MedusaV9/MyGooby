import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct DataFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .data] }
    var data: Data
    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct SettingsView: View {
    var engine: GoobyEngine
    @State private var nickname = ""
    @State private var goobyName = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var devTaps: [Date] = []
    @State private var showDev = false
    @State private var exportFile: DataFile?
    @State private var showExport = false
    @State private var showImport = false
    @State private var password = ""
    @State private var encrypt = false
    @State private var showPassword = false
    @State private var importURL: URL?
    @State private var pendingImport: Data?
    @State private var message: String?
    @State private var reset1 = false
    @State private var reset2 = false
    @State private var help = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                profile
                language
                toggles
                backup
                Button(engine.t("settings.help")) { help = true }.foregroundStyle(Theme.ink)
                Text(engine.tf("settings.version", engine.versionString(), engine.buildString()))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                Button(engine.t("settings.reset")) { reset1 = true }
                    .foregroundStyle(Theme.rose)
            }
            .padding(16)
        }
        .goobyScreen()
        .navigationTitle(engine.t("settings.title"))
        .onAppear {
            nickname = engine.profile.nickname
            goobyName = engine.profile.goobyName
        }
        .fullScreenCover(isPresented: $showDev) { DevMenuView(engine: engine) }
        .sheet(isPresented: $help) { HelpView(engine: engine) }
        .sheet(isPresented: $showPassword) { passwordSheet }
        .fileExporter(isPresented: $showExport, document: exportFile, contentType: .json, defaultFilename: encrypt ? "Gooby.goobybackup" : "Gooby-save.json") { _ in }
        .fileImporter(isPresented: $showImport, allowedContentTypes: [.json, .data]) { result in
            guard case let .success(url) = result else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else {
                message = engine.t("error.import")
                return
            }
            pendingImport = data
            if encryptedBackup(data) {
                password = ""
                importURL = url
                showPassword = true
            } else {
                do {
                    try engine.importData(data, password: nil)
                    pendingImport = nil
                } catch {
                    message = engine.t("error.import")
                }
            }
        }
        .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: { Text(message ?? "") }
        .alert(engine.t("reset.title"), isPresented: $reset1) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("reset.continue"), role: .destructive) { reset2 = true }
        } message: { Text(engine.t("reset.msg1")) }
        .alert(engine.t("reset.final"), isPresented: $reset2) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("reset.do"), role: .destructive) { engine.resetAll() }
        } message: { Text(engine.t("reset.msg2")) }
    }

    private var profile: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 8) {
                TextField(engine.t("settings.nickname"), text: $nickname)
                TextField(engine.t("settings.goobyName"), text: $goobyName)
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text(engine.t("settings.photo"))
                }
                .onChange(of: photoItem) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self) {
                            let url = GoobyFiles.supportDirectory().appendingPathComponent("profile.jpg")
                            try? data.write(to: url)
                            GoobyFiles.exclude(url)
                            engine.profile.photoFilename = "profile.jpg"
                            engine.save()
                        }
                    }
                }
                Button(engine.t("common.save")) {
                    engine.profile.nickname = nickname.trimmingCharacters(in: .whitespaces)
                    let name = goobyName.trimmingCharacters(in: .whitespaces)
                    engine.profile.goobyName = name.isEmpty ? "Gooby" : name
                    engine.save()
                }
                .buttonStyle(GoobyButtonStyle(fill: Theme.pink, ink: Theme.ink))
            }
        }
    }

    private var language: some View {
        SoftCard(fill: Theme.lavender.opacity(0.55)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(engine.t("settings.language")).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                languageRow("de", engine.t("settings.german")) { engine.setLanguage("de") }
                languageRow("en", "English") {
                    engine.setLanguage("en")
                    registerDevTap()
                }
            }
        }
    }

    private func languageRow(_ code: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(Theme.ink)
                Spacer()
                if engine.languageCode == code { Image(systemName: "checkmark").foregroundStyle(Theme.ink) }
            }
            .padding(10)
            .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func registerDevTap() {
        let now = Date()
        devTaps.append(now)
        devTaps = devTaps.filter { now.timeIntervalSince($0) <= 2 }
        if devTaps.count >= 3 {
            devTaps = []
            showDev = true
        }
    }

    private var toggles: some View {
        SoftCard(fill: Theme.mint.opacity(0.6)) {
            Toggle(engine.t("settings.reduce"), isOn: Binding(get: { engine.reduceMotion }, set: { engine.setReduceMotion($0) }))
            Toggle(engine.t("settings.face"), isOn: Binding(get: { engine.profile.faceIDEnabled }, set: { engine.profile.faceIDEnabled = $0; engine.save() }))
            Toggle(engine.t("settings.notifications"), isOn: Binding(get: { engine.profile.notificationsEnabled }, set: { toggleNotes($0) }))
            Text(engine.t("settings.backupNote")).font(.system(.footnote, design: .rounded)).foregroundStyle(Theme.ink.opacity(0.7))
        }
        .foregroundStyle(Theme.ink)
    }

    private var backup: some View {
        VStack(spacing: 8) {
            Button(engine.t("settings.export")) { prepareExport(encrypted: false) }.buttonStyle(GoobyButtonStyle())
            Button(engine.t("settings.exportLock")) { encrypt = true; password = ""; showPassword = true }.buttonStyle(GoobyButtonStyle(fill: Theme.lavender, ink: Theme.ink))
            Button(engine.t("settings.import")) { showImport = true }.buttonStyle(GoobyButtonStyle(fill: Theme.peach, ink: Theme.ink))
            Button(engine.t("settings.diagnostics")) {
                exportFile = DataFile(data: Data(engine.diagnostics().utf8))
                encrypt = false
                showExport = true
            }
        }
    }

    private var passwordSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {
                SecureField(engine.t("settings.password"), text: $password).textFieldStyle(.roundedBorder)
                Button(engine.t("common.confirm")) {
                    if pendingImport != nil { runImport() } else { prepareExport(encrypted: true) }
                    showPassword = false
                }
                .buttonStyle(GoobyButtonStyle())
            }
            .padding(16)
            .goobyScreen()
            .navigationTitle(engine.t("settings.password"))
        }
    }

    private func prepareExport(encrypted: Bool) {
        do {
            exportFile = DataFile(data: try engine.exportData(password: encrypted ? password : nil))
            encrypt = encrypted
            showExport = true
        } catch {
            message = engine.t("error.export")
        }
    }

    private func encryptedBackup(_ data: Data) -> Bool {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return true }
        return root["format"] as? String == "gooby-aes"
    }

    private func runImport() {
        guard let data = pendingImport else { return }
        do {
            try engine.importData(data, password: password.isEmpty ? nil : password)
            pendingImport = nil
            importURL = nil
        } catch {
            message = engine.t("error.import")
        }
    }

    private func toggleNotes(_ on: Bool) {
        engine.profile.notificationsEnabled = on
        engine.save()
        guard on else { return }
        Task {
            let ok = await GoobyAlerts.request()
            if ok { engine.rescheduleNotifications() }
            else {
                engine.profile.notificationsEnabled = false
                engine.save()
                message = engine.t("settings.notificationsDenied")
            }
        }
    }
}

struct HelpView: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(engine.t("help.body")).foregroundStyle(Theme.ink)
                    Text(engine.t("calm.disclaimer")).foregroundStyle(Theme.ink.opacity(0.7))
                }
                .padding(16)
            }
            .goobyScreen()
            .navigationTitle(engine.t("settings.help"))
            .toolbar { Button(engine.t("common.done")) { dismiss() } }
        }
    }
}
