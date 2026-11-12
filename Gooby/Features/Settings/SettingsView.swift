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
    @State private var devTaps: [Date] = []
    @State private var showDev = false
    @State private var exportFile: DataFile?
    @State private var showExport = false
    @State private var showImport = false
    @State private var password = ""
    @State private var encrypt = false
    @State private var showPassword = false
    @State private var pendingImport: Data?
    @State private var message: String?
    @State private var reset1 = false
    @State private var reset2 = false
    @State private var help = false
    @State private var paused = false
    @State private var alertTitleKey = "common.error"

    private var alertTitle: String { engine.t(alertTitleKey) }

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsSleepingHead(engine: engine, paused: paused)
                LookSectionTitle(text: engine.t("look.device"))
                accountCard
                if !GoobyAppGroup.isAvailable {
                    Text(engine.t("settings.group.missing"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.row)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                        .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            paused = LookMark.isOn(engine, LookMark.pause)
            SettingsDayPause.apply(engine)
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
                showError(engine.t("error.import"))
                return
            }
            pendingImport = data
            if encryptedBackup(data) {
                password = ""
                showPassword = true
            } else {
                do {
                    try engine.importData(data, password: nil)
                    pendingImport = nil
                } catch {
                    showError(engine.t("error.import"))
                }
            }
        }
        .alert(alertTitle, isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
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

    private var accountCard: some View {
        LookCard {
            VStack(spacing: 0) {
                NavigationLink { NotificationsPage(engine: engine) } label: {
                    LookNavRow(title: engine.t("look.notifications"), icon: .bell)
                }.buttonStyle(.plain)
                LookDivider()
                NavigationLink { SettingsProfilePage(engine: engine, onDelete: { reset1 = true }) } label: {
                    LookNavRow(title: engine.t("look.profile"), icon: .profile)
                }.buttonStyle(.plain)
                LookDivider()
                NavigationLink { ThemePickerPage(engine: engine) } label: {
                    LookNavRow(title: engine.t("theme.row"), subtitle: engine.t(ThemeStore.shared.active.nameKey), icon: .appIcon)
                }.buttonStyle(.plain)
                LookDivider()
                NavigationLink { PreferencesPage(engine: engine, devTaps: $devTaps, showDev: $showDev) } label: {
                    LookNavRow(title: engine.t("look.preferences"), icon: .ruler)
                }.buttonStyle(.plain)
                LookDivider()
                NavigationLink {
                    DataPage(engine: engine, exportPlain: { prepareExport(encrypted: false) }, exportLocked: {
                        encrypt = true
                        password = ""
                        showPassword = true
                    }, importSave: { showImport = true }, diagnostics: {
                        exportFile = DataFile(data: Data(engine.diagnostics().utf8))
                        encrypt = false
                        showExport = true
                    }, reset: { reset1 = true }, help: { help = true })
                } label: {
                    LookNavRow(title: engine.t("look.data"), icon: .floppy)
                }.buttonStyle(.plain)
                LookDivider()
                LookNavRow(title: engine.t("look.pause"), subtitle: engine.t("look.pause.sub"), icon: .sprout, showsChevron: false)
                    .padding(.trailing, 58)
                    .overlay(alignment: .trailing) {
                        LookSwitch(isOn: pauseBinding, label: engine.t("look.pause"))
                            .padding(.trailing, 14)
                    }
            }
        }
    }

    private var pauseBinding: Binding<Bool> {
        Binding(get: { paused }, set: { value in
            paused = value
            SettingsDayPause.setOn(engine, value)
        })
    }

    private var passwordSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {
                SecureField(engine.t("settings.password"), text: $password).textFieldStyle(.roundedBorder)
                Button(engine.t("common.confirm")) {
                    if pendingImport != nil { runImport() } else { prepareExport(encrypted: true) }
                    showPassword = false
                }
                .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Look.canvas.ignoresSafeArea())
            .sheetRise(calm: engine.reduceMotion)
            .navigationTitle(engine.t("settings.password"))
        }
    }

    private func prepareExport(encrypted: Bool) {
        do {
            exportFile = DataFile(data: try engine.exportData(password: encrypted ? password : nil))
            encrypt = encrypted
            showExport = true
        } catch {
            showError(engine.t("error.export"))
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
        } catch {
            showError(engine.t("error.import"))
        }
    }

    private func showError(_ text: String) {
        alertTitleKey = "common.error"
        message = text
    }
}

private struct NotificationsPage: View {
    var engine: GoobyEngine
    @State private var noticesDenied = false

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSleepingHead(engine: engine)
                Text(engine.t("look.notifications"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.t("look.notifications.lead"))
                    .foregroundStyle(Look.row)
                    .task { await refreshNotices() }
                if noticesDenied {
                    Text(engine.t("settings.notificationsDenied"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.row)
                        .fixedSize(horizontal: false, vertical: true)
                }
                LookCard {
                    Toggle(engine.t("settings.notifications"), isOn: Binding(get: { engine.profile.notificationsEnabled }, set: {
                        engine.cue($0 ? .toggleOn : .toggleOff)
                        toggleNotes($0)
                    }))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Look.row)
                        .padding(16)
                }
            }
        }
    }

    private func toggleNotes(_ on: Bool) {
        engine.profile.notificationsEnabled = on
        engine.save()
        noticesDenied = false
        guard on else { return }
        Task {
            let ok = await GoobyAlerts.request()
            if ok {
                engine.rescheduleNotifications()
                noticesDenied = false
            } else {
                engine.profile.notificationsEnabled = false
                engine.save()
                engine.cue(.toggleOff)
                noticesDenied = true
            }
        }
    }

    private func refreshNotices() async {
        let status = await GoobyAlerts.status()
        let allowed = status == .authorized || status == .provisional || status == .ephemeral
        if engine.profile.notificationsEnabled, status == .notDetermined {
            let ok = await GoobyAlerts.request()
            noticesDenied = !ok
            if ok {
                engine.rescheduleNotifications()
            } else {
                engine.profile.notificationsEnabled = false
                engine.save()
            }
            return
        }
        noticesDenied = status == .denied
        if engine.profile.notificationsEnabled, !allowed {
            engine.profile.notificationsEnabled = false
            engine.save()
        }
    }
}

private struct PreferencesPage: View {
    var engine: GoobyEngine
    @Binding var devTaps: [Date]
    @Binding var showDev: Bool

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSleepingHead(engine: engine)
                Text(engine.t("look.preferences"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                LookCard {
                    VStack(spacing: 0) {
                        languageRow("de", engine.t("settings.german")) { engine.setLanguage("de") }
                        LookDivider()
                        languageRow("en", engine.t("settings.english")) {
                            engine.setLanguage("en")
                            registerDevTap()
                        }
                    }
                }
                LookCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(engine.t("settings.reduce"), isOn: Binding(get: { engine.reduceMotion }, set: { engine.setReduceMotion($0); engine.cue($0 ? .toggleOn : .toggleOff) }))
                        Toggle(engine.t("settings.face"), isOn: Binding(get: { engine.profile.faceIDEnabled }, set: { engine.profile.faceIDEnabled = $0; engine.save(); engine.cue($0 ? .toggleOn : .toggleOff) }))
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Look.row)
                    .padding(16)
                }
                FeedbackSettingsCard(engine: engine)
            }
        }
    }

    private func languageRow(_ code: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Look.row)
                Spacer()
                if engine.languageCode == code {
                    Image(systemName: "checkmark").foregroundStyle(Look.plus)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
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
}

private struct DataPage: View {
    var engine: GoobyEngine
    var exportPlain: () -> Void
    var exportLocked: () -> Void
    var importSave: () -> Void
    var diagnostics: () -> Void
    var reset: () -> Void
    var help: () -> Void

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSleepingHead(engine: engine)
                Text(engine.t("look.data"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.t("settings.backupNote"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                LookCard {
                    VStack(spacing: 0) {
                        actionRow(engine.t("settings.export"), exportPlain)
                        LookDivider()
                        actionRow(engine.t("settings.exportLock"), exportLocked)
                        LookDivider()
                        actionRow(engine.t("settings.import"), importSave)
                        LookDivider()
                        actionRow(engine.t("settings.diagnostics"), diagnostics)
                        LookDivider()
                        actionRow(engine.t("settings.help"), help)
                        LookDivider()
                        actionRow(engine.t("settings.reset"), reset)
                    }
                }
                Text(engine.tf("settings.version", engine.versionString(), engine.buildString()))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.sub)
            }
        }
    }

    private func actionRow(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LookNavRow(title: title, showsChevron: false)
        }
        .buttonStyle(.plain)
    }
}

struct HelpView: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    SettingsSleepingHead(engine: engine)
                    Text(engine.t("settings.help.plain")).foregroundStyle(Look.ink)
                    Text(engine.t("calm.disclaimer")).foregroundStyle(Look.row)
                }
                .padding(16)
            }
            .background(Look.canvas.ignoresSafeArea())
            .navigationTitle(engine.t("settings.help"))
            .toolbar { Button(engine.t("common.done")) { dismiss() } }
        }
    }
}
