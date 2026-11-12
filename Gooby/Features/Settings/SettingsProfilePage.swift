import PhotosUI
import SwiftUI

struct SettingsProfilePage: View {
    var engine: GoobyEngine
    var onDelete: () -> Void

    @State private var petName = ""
    @State private var humanName = ""
    @State private var birthdayRaw = ""
    @State private var pronounRaw = ""
    @State private var petDraft = ""
    @State private var humanDraft = ""
    @State private var showPet = false
    @State private var showHuman = false
    @State private var showPronouns = false
    @State private var showBirthday = false
    @State private var photoItem: PhotosPickerItem?

    init(engine: GoobyEngine, onDelete: @escaping () -> Void) {
        self.engine = engine
        self.onDelete = onDelete
        _petName = State(initialValue: engine.profile.goobyName)
        _humanName = State(initialValue: engine.profile.nickname)
        _birthdayRaw = State(initialValue: engine.profile.birthday)
        _pronounRaw = State(initialValue: engine.pet.pronouns)
    }

    var body: some View {
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 0) {
                SettingsSleepingHead(engine: engine)
                Text(engine.t("look.profile"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                    .padding(.bottom, 4)
                LookSectionTitle(text: engine.t("look.pet.section"))
                LookCard {
                    VStack(spacing: 0) {
                        Button {
                            petDraft = petName
                            showPet = true
                        } label: {
                            LookNavRow(title: engine.t("look.pet.name"), trailing: petName.isEmpty ? "Gooby" : petName)
                        }
                        .buttonStyle(.plain)
                        LookDivider()
                        Button { showPronouns = true } label: {
                            LookNavRow(title: engine.t("look.pet.pronouns"), trailing: SettingsPronouns.label(engine, pronounRaw))
                        }
                        .buttonStyle(.plain)
                        LookDivider()
                        let hatchday = ProfilePassport.hatchday(engine.profile.createdAt, language: engine.languageCode)
                        LookNavRow(
                            title: engine.t("profile.hatchday"),
                            trailing: hatchday,
                            showsChevron: false
                        )
                        .accessibilityLabel("\(engine.t("profile.hatchday")), \(hatchday)")
                    }
                }
                LookSectionTitle(text: engine.t("look.you.section"))
                LookCard {
                    VStack(spacing: 0) {
                        Button {
                            humanDraft = humanName
                            showHuman = true
                        } label: {
                            LookNavRow(title: engine.t("look.yourName"), trailing: humanTrailing)
                        }
                        .buttonStyle(.plain)
                        LookDivider()
                        Button { showBirthday = true } label: {
                            LookNavRow(title: engine.t("look.birthday"), trailing: birthdayTrailing)
                        }
                        .buttonStyle(.plain)
                        LookDivider()
                        let photoTitle = engine.t("settings.photo")
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            LookNavRow(title: photoTitle, icon: .profile, showsChevron: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button(action: onDelete) {
                    Text(engine.t("look.delete"))
                }
                .buttonStyle(GoobyButtonStyle(fill: Color(hex: 0xE23D3D), ink: .white))
                .padding(.top, 28)
            }
        }
        .onAppear(perform: reload)
        .sheet(isPresented: $showPet) {
            SettingsTextSheet(engine: engine, title: engine.t("look.pet.name"), draft: $petDraft) {
                let name = String(petDraft.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
                engine.profile.goobyName = name.isEmpty ? "Gooby" : name
                engine.save()
                reload()
            }
        }
        .sheet(isPresented: $showHuman) {
            SettingsTextSheet(engine: engine, title: engine.t("look.yourName"), draft: $humanDraft) {
                engine.profile.nickname = String(humanDraft.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
                engine.save()
                reload()
            }
        }
        .sheet(isPresented: $showPronouns) {
            SettingsPronounSheet(engine: engine) { reload() }
        }
        .sheet(isPresented: $showBirthday) {
            SettingsBirthdaySheet(engine: engine)
        }
        .onChange(of: showBirthday) { _, open in
            if !open { reload() }
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
    }

    private var humanTrailing: String {
        humanName.isEmpty ? engine.t("look.birthday.unset") : humanName
    }

    private var birthdayTrailing: String {
        let raw = birthdayRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return engine.t("look.birthday.unset") }
        guard let date = DayKey.parse(raw) else { return raw }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func reload() {
        petName = engine.profile.goobyName
        humanName = engine.profile.nickname
        birthdayRaw = engine.profile.birthday
        pronounRaw = engine.pet.pronouns
    }

}

@MainActor
enum SettingsPronouns {
    static func canonical(_ raw: String) -> String {
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "", "not set", "nicht gesetzt":
            return ""
        case "he", "he/him", "er", "er/ihn", "er/ihm":
            return "he"
        case "she", "she/her", "sie", "sie/ihr":
            return "she"
        case "they", "they/them", "dey":
            return "they"
        default:
            return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    static func label(_ engine: GoobyEngine, _ raw: String) -> String {
        switch canonical(raw) {
        case "": return engine.t("look.pronoun.unset")
        case "he": return engine.t("look.pronoun.he")
        case "she": return engine.t("look.pronoun.she")
        case "they": return engine.t("look.pronoun.they")
        default: return raw
        }
    }
}

private struct SettingsTextSheet: View {
    var engine: GoobyEngine
    var title: String
    @Binding var draft: String
    var save: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField(title, text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                Button(engine.t("common.save")) {
                    save()
                    dismiss()
                }
                .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Look.canvas.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button(engine.t("common.done")) { dismiss() } }
        }
    }
}

private struct SettingsPronounSheet: View {
    var engine: GoobyEngine
    var saved: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                LookCard {
                    VStack(spacing: 0) {
                        row("", engine.t("look.pronoun.unset"))
                        LookDivider()
                        row("he", engine.t("look.pronoun.he"))
                        LookDivider()
                        row("she", engine.t("look.pronoun.she"))
                        LookDivider()
                        row("they", engine.t("look.pronoun.they"))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Look.canvas.ignoresSafeArea())
            .navigationTitle(engine.t("look.pet.pronouns"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button(engine.t("common.done")) { dismiss() } }
        }
    }

    private func row(_ id: String, _ title: String) -> some View {
        Button {
            engine.setPetPronouns(id)
            saved()
            dismiss()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Look.row)
                Spacer()
                if SettingsPronouns.canonical(engine.pet.pronouns) == id {
                    Image(systemName: "checkmark").foregroundStyle(Look.plus)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SettingsBirthdaySheet: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date

    init(engine: GoobyEngine) {
        self.engine = engine
        let calendar = Calendar.current
        let fallback = calendar.date(byAdding: .year, value: -25, to: engine.now()) ?? engine.now()
        let parsed = DayKey.parse(engine.profile.birthday) ?? fallback
        _date = State(initialValue: min(parsed, engine.now()))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DatePicker(
                        engine.t("look.birthday"),
                        selection: $date,
                        in: ...engine.now(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: engine.languageCode))
                    Button(engine.t("common.save")) {
                        engine.setBirthday(DayKey.make(date))
                        dismiss()
                    }
                    .buttonStyle(GoobyButtonStyle(fill: Look.plus, ink: .white))
                    if !engine.profile.birthday.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(engine.t("look.birthday.clear")) {
                            engine.setBirthday("")
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: 0xE23D3D))
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
                .padding(16)
            }
            .background(Look.canvas.ignoresSafeArea())
            .navigationTitle(engine.t("look.birthday"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button(engine.t("common.done")) { dismiss() } }
        }
    }
}
