import PhotosUI
import SwiftUI
import UIKit
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

/// Settings list (screenshot-reference.md section 10): grouped white cards with emoji icons on the
/// pale blue menu background. Account, pause mode, language (with the hidden developer gesture on
/// "English") and about.
struct SettingsView: View {
    var engine: GoobyEngine
    @State private var devTaps: [Date] = []
    @State private var showDev = false
    @State private var message: String?
    @State private var help = false
    @State private var privacy = false

    var body: some View {
        MenuScroll {
            MenuSectionHeader(text: engine.tx("menu.settings.general", de: "Allgemein", en: "General"))
            MenuListGroup {
                MenuToggleRow(
                    icon: "🔔",
                    title: engine.t("settings.notifications"),
                    subtitle: engine.tx("menu.settings.notifications.sub", de: "Für Ziele und Feste", en: "For goals and events"),
                    isOn: Binding(get: { engine.profile.notificationsEnabled }, set: { toggleNotes($0) })
                )
                MenuListDivider()
                NavigationLink {
                    MenuProfileScreen(engine: engine)
                } label: {
                    MenuListRow(icon: "🐰", title: engine.tx("menu.profile", de: "Profil", en: "Profile"), subtitle: profileSummary)
                }
                .buttonStyle(MenuRowButtonStyle())
                MenuListDivider()
                NavigationLink {
                    SettingsPreferencesScreen(engine: engine)
                } label: {
                    MenuListRow(icon: "📐", title: engine.tx("menu.preferences", de: "Vorlieben", en: "Preferences"), subtitle: engine.tx("menu.preferences.sub", de: "Animation und Gerätesperre", en: "Animation and device lock"))
                }
                .buttonStyle(MenuRowButtonStyle())
                MenuListDivider()
                NavigationLink {
                    SettingsDataScreen(engine: engine)
                } label: {
                    MenuListRow(icon: "💾", title: engine.tx("menu.data", de: "Deine Daten", en: "Your data"), subtitle: engine.tx("menu.data.sub", de: "Export, Import, Backup, Löschen", en: "Export, import, backup, erase"))
                }
                .buttonStyle(MenuRowButtonStyle())
            }
            MenuListGroup {
                MenuToggleRow(
                    icon: "🌾",
                    title: engine.tx("menu.pause", de: "Pausenmodus", en: "Pause mode"),
                    subtitle: engine.tx("menu.pause.sub", de: "Ziele und Erinnerungen ruhen, Gooby und deine Sachen bleiben.", en: "Goals and reminders rest, Gooby and your things stay."),
                    isOn: Binding(get: { engine.pauseModeOn }, set: { engine.setPauseMode($0) })
                )
            }
            .padding(.top, 8)
            MenuSectionHeader(text: engine.t("settings.language"))
            MenuListGroup {
                languageRow("de", flag: "🇩🇪", title: "Deutsch") { engine.setLanguage("de") }
                MenuListDivider()
                languageRow("en", flag: "🇬🇧", title: "English") {
                    engine.setLanguage("en")
                    registerDevTap()
                }
            }
            MenuSectionHeader(text: engine.tx("menu.about", de: "Über Gooby", en: "About Gooby"))
            MenuListGroup {
                Button {
                    help = true
                } label: {
                    MenuListRow(icon: "❓", title: engine.t("settings.help"))
                }
                .buttonStyle(MenuRowButtonStyle())
                MenuListDivider()
                Button {
                    privacy = true
                } label: {
                    MenuListRow(icon: "🔒", title: engine.tx("menu.privacy", de: "Datenschutz", en: "Privacy"), subtitle: engine.tx("menu.privacy.sub", de: "Alles bleibt auf diesem iPhone", en: "Everything stays on this iPhone"))
                }
                .buttonStyle(MenuRowButtonStyle())
                MenuListDivider()
                MenuListRow(icon: "ℹ️", title: engine.tx("menu.version", de: "Version", en: "Version")) {
                    Text("\(engine.versionString()) (\(engine.buildString()))")
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.greyText)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .menuChrome(engine, title: engine.t("settings.title"))
        .fullScreenCover(isPresented: $showDev) { DevMenuView(engine: engine) }
        .sheet(isPresented: $help) { HelpView(engine: engine) }
        .sheet(isPresented: $privacy) { MenuPrivacyView(engine: engine) }
        .alert(engine.t("common.error"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button(engine.t("common.ok"), role: .cancel) {}
        } message: { Text(message ?? "") }
    }

    private var profileSummary: String {
        let nickname = engine.profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let gooby = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return [gooby.isEmpty ? "Gooby" : gooby, nickname].filter { !$0.isEmpty }.joined(separator: " & ")
    }

    /// One tap selects the language. On "English" every tap also counts toward the hidden
    /// developer gesture: three taps within 2 s open the developer menu, also when English is
    /// already active.
    private func languageRow(_ code: String, flag: String, title: String, action: @escaping () -> Void) -> some View {
        let selected = engine.languageCode == code
        return Button(action: action) {
            MenuListRow(icon: flag, title: title) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.checkGreen)
                } else {
                    Circle()
                        .stroke(Theme.line, lineWidth: 2.5)
                        .frame(width: 22, height: 22)
                }
            }
        }
        .buttonStyle(MenuRowButtonStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
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

/// Settings > Preferences: reduce animation and the Face ID / passcode lock.
struct SettingsPreferencesScreen: View {
    var engine: GoobyEngine

    var body: some View {
        MenuScroll {
            MenuListGroup {
                MenuToggleRow(
                    icon: "🐢",
                    title: engine.t("settings.reduce"),
                    subtitle: engine.tx("menu.reduce.sub", de: "Gooby bewegt sich ruhiger, Effekte pausieren", en: "Gooby moves more calmly, effects pause"),
                    isOn: Binding(get: { engine.reduceMotion }, set: { engine.setReduceMotion($0) })
                )
                MenuListDivider()
                MenuToggleRow(
                    icon: "🔐",
                    title: engine.t("settings.face"),
                    subtitle: engine.tx("menu.face.sub", de: "Fragt beim Öffnen nach", en: "Asks when the app opens"),
                    isOn: Binding(get: { engine.profile.faceIDEnabled }, set: { engine.profile.faceIDEnabled = $0; engine.save() })
                )
            }
            .padding(.top, 8)
        }
        .menuChrome(engine, title: engine.tx("menu.preferences", de: "Vorlieben", en: "Preferences"))
    }
}

/// Settings > Your data: export, encrypted backup, import, diagnostics and erasing the save with
/// a double confirmation. Same logic as the former settings backup section.
struct SettingsDataScreen: View {
    var engine: GoobyEngine
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

    var body: some View {
        MenuScroll {
            MenuSectionHeader(text: engine.tx("menu.data.backup", de: "Sichern", en: "Back up"))
            MenuListGroup {
                Button {
                    prepareExport(encrypted: false)
                } label: {
                    MenuListRow(icon: "📤", title: engine.t("settings.export"), subtitle: engine.tx("menu.export.sub", de: "JSON-Datei für die Dateien-App", en: "JSON file for the Files app"))
                }
                .buttonStyle(MenuRowButtonStyle())
                MenuListDivider()
                Button {
                    encrypt = true
                    password = ""
                    showPassword = true
                } label: {
                    MenuListRow(icon: "🔐", title: engine.t("settings.exportLock"), subtitle: engine.tx("menu.exportLock.sub", de: "Mit Passwort geschützt", en: "Protected with a password"))
                }
                .buttonStyle(MenuRowButtonStyle())
                MenuListDivider()
                Button {
                    showImport = true
                } label: {
                    MenuListRow(icon: "📥", title: engine.t("settings.import"), subtitle: engine.tx("menu.import.sub", de: "Ersetzt den aktuellen Spielstand", en: "Replaces the current save"))
                }
                .buttonStyle(MenuRowButtonStyle())
                MenuListDivider()
                Button {
                    exportFile = DataFile(data: Data(engine.diagnostics().utf8))
                    encrypt = false
                    showExport = true
                } label: {
                    MenuListRow(icon: "🩺", title: engine.t("settings.diagnostics"))
                }
                .buttonStyle(MenuRowButtonStyle())
            }
            MenuFootnote(text: engine.t("settings.backupNote"))
            MenuListGroup {
                Button {
                    reset1 = true
                } label: {
                    MenuListRow(icon: "🗑️", title: engine.t("settings.reset"), titleColor: MenuPalette.danger)
                }
                .buttonStyle(MenuRowButtonStyle())
            }
            .padding(.top, 10)
        }
        .menuChrome(engine, title: engine.tx("menu.data", de: "Deine Daten", en: "Your data"))
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

    private var passwordSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                SecureField(engine.t("settings.password"), text: $password)
                    .font(Theme.Fonts.button)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .cardShadow()
                Button {
                    if pendingImport != nil { runImport() } else { prepareExport(encrypted: true) }
                    showPassword = false
                } label: {
                    Text(engine.t("common.confirm"))
                }
                .menuPrimaryButton()
                Spacer()
            }
            .padding(Theme.Space.margin)
            .menuChrome(engine, title: engine.t("settings.password"), close: true)
        }
        .presentationDetents([.medium])
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
}

/// Profile photo picker row (Settings > Profile). Saves the picked image next to the store and
/// excludes it from the iCloud backup, as before.
struct MenuProfilePhotoRow: View {
    var engine: GoobyEngine
    @State private var photoItem: PhotosPickerItem?
    @State private var version = 0

    var body: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            MenuListRow(icon: "🖼️", title: engine.t("settings.photo")) {
                if let image = currentPhoto {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .id(version)
                } else {
                    MenuChevron()
                }
            }
        }
        .buttonStyle(MenuRowButtonStyle())
        .onChange(of: photoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    let url = GoobyFiles.supportDirectory().appendingPathComponent("profile.jpg")
                    try? data.write(to: url)
                    GoobyFiles.exclude(url)
                    engine.profile.photoFilename = "profile.jpg"
                    engine.save()
                    version += 1
                }
            }
        }
    }

    private var currentPhoto: UIImage? {
        _ = version
        let name = engine.profile.photoFilename
        guard !name.isEmpty else { return nil }
        return UIImage(contentsOfFile: GoobyFiles.supportDirectory().appendingPathComponent(name).path)
    }
}

/// What stays where: offline, no account, excluded from iCloud backup, exports only by hand.
struct MenuPrivacyView: View {
    var engine: GoobyEngine

    var body: some View {
        NavigationStack {
            MenuScroll {
                GCard {
                    VStack(alignment: .leading, spacing: 12) {
                        GoobyIcon("🔒", size: 40)
                        Text(engine.tx(
                            "menu.privacy.body",
                            de: "Gooby funktioniert komplett offline. Es gibt kein Konto, keinen Server, keine Werbung und keine Analyse. Alle Daten bleiben auf diesem iPhone.",
                            en: "Gooby works fully offline. There is no account, no server, no ads and no analytics. All data stays on this iPhone."
                        ))
                        .font(Theme.Fonts.button)
                        .foregroundStyle(Theme.text)
                        Text(engine.tx(
                            "menu.privacy.backup",
                            de: "Die internen Spieldaten sind vom iCloud-Backup ausgeschlossen. Wechselst du das iPhone oder löschst du die App, sind sie weg, außer du hast vorher unter „Deine Daten“ einen Export gesichert. Ein Export liegt nur dort, wo du ihn selbst ablegst.",
                            en: "The internal save data is excluded from iCloud backup. If you switch iPhones or delete the app, it is gone unless you saved an export under \"Your data\" first. An export lives only where you put it yourself."
                        ))
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.greyText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
            }
            .menuChrome(engine, title: engine.tx("menu.privacy", de: "Datenschutz", en: "Privacy"), close: true)
        }
    }
}

struct HelpView: View {
    var engine: GoobyEngine

    var body: some View {
        NavigationStack {
            MenuScroll {
                GCard {
                    VStack(alignment: .leading, spacing: 12) {
                        GoobyIcon("🐰", size: 40)
                        Text(engine.t("help.body"))
                            .font(Theme.Fonts.button)
                            .foregroundStyle(Theme.text)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
                MenuFootnote(text: engine.t("calm.disclaimer"))
            }
            .menuChrome(engine, title: engine.t("settings.help"), close: true)
        }
    }
}
