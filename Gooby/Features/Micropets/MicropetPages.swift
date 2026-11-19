import SwiftUI

struct MicropetBindSheet: View {
    var engine: GoobyEngine
    var onBound: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let habits = engine.habits().filter { habit in
            !habit.isArchived && engine.activeEgg(for: habit.id) == nil
        }
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if habits.isEmpty {
                        Text(engine.t("micropets.bindEmpty"))
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    ForEach(habits) { habit in
                        Button {
                            engine.bindEgg(to: habit)
                            engine.cue(.select)
                            onBound()
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                MicropetEgg(fraction: 0, ready: false)
                                    .frame(width: 36, height: 44)
                                Text(habit.title)
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(2)
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Theme.cream.ignoresSafeArea())
            .navigationTitle(engine.t("micropets.bindTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(engine.t("micropets.close")) { dismiss() }
                }
            }
        }
    }
}

struct MicropetFriendPage: View {
    var engine: GoobyEngine
    var friend: MiniFriend
    var calm: Bool
    var onChange: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var original = ""
    @State private var popped = false
    @State private var along = false

    var body: some View {
        let found = true
        VStack(spacing: 16) {
            MicropetMark(id: friend.speciesID)
                .frame(width: 140, height: 140)
                .scaleEffect(popped ? 1 : 0.2)
            Text(MicropetDex.title(engine, id: friend.speciesID, found: found))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(MicropetDex.blurb(engine, id: friend.speciesID, found: found))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.75))
                .multilineTextAlignment(.center)
            TextField(engine.t("micropets.name"), text: $draft)
                .font(.system(.body, design: .rounded))
                .padding(12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onSubmit { commit() }
            if along {
                Text(engine.t("micropets.with"))
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color(hex: 0x3F9A48))
            } else {
                Button(engine.t("micropets.choose")) {
                    commit()
                    engine.setCompanion(friend)
                    along = true
                    onChange()
                }
                .buttonStyle(GoobyButtonStyle(fill: Color(hex: 0x7BB65C), ink: .white))
            }
            Button(engine.t("micropets.close")) {
                commit()
                dismiss()
            }
            .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.cream.ignoresSafeArea())
        .onAppear {
            draft = friend.givenName
            original = friend.givenName
            along = friend.isCompanion
            if calm {
                popped = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { popped = true }
            }
        }
        .onDisappear { commit() }
        .presentationDetents([.medium, .large])
    }

    private func commit() {
        guard draft != original else { return }
        let next = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = engine.catalog.friendsByID[friend.speciesID]?.name.text(engine.languageCode) ?? ""
        let name = next.isEmpty ? (fallback.isEmpty ? friend.givenName : fallback) : next
        original = name
        draft = name
        guard name != friend.givenName else { return }
        friend.givenName = name
        engine.save()
        engine.cue(.save)
        onChange()
    }
}

struct MicropetDexPage: View {
    var engine: GoobyEngine
    @Environment(\.dismiss) private var dismiss
    @State private var picked: String?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let roster = MicropetDex.roster()
        let found = MicropetDex.foundIDs(engine)
        ZStack(alignment: .top) {
            Theme.cream.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 36, height: 36)
                            .background(Theme.surface, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.t("micropets.close"))
                    Spacer()
                }
                .overlay {
                    Text(engine.t("micropets.dex"))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.horizontal, 8)
                Text(engine.tf("micropets.foundLine", found.intersection(Set(roster.map(\.id))).count, roster.count))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.75))
                Text(engine.t("micropets.dex.hint"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                    .multilineTextAlignment(.center)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(roster) { spot in
                            let known = found.contains(spot.id)
                            Button { picked = spot.id } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Theme.surface)
                                    MicropetMark(id: spot.id, ink: known ? nil : Theme.ink.opacity(0.28))
                                        .padding(14)
                                }
                                .aspectRatio(1, contentMode: .fit)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(MicropetDex.title(engine, id: spot.id, found: known))
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 28)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
        }
        .sheet(item: pick) { item in
            dexDetail(item.id, found: found.contains(item.id))
        }
    }

    private var pick: Binding<MicropetDexPick?> {
        Binding(
            get: { picked.map(MicropetDexPick.init) },
            set: { picked = $0?.id }
        )
    }

    private func dexDetail(_ id: String, found: Bool) -> some View {
        let rarity = MicropetDex.rarity(engine, id: id, found: found)
        return VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(found ? Color(hex: 0x4E4E4E) : Theme.surface)
                MicropetMark(id: id, ink: found ? nil : Theme.ink.opacity(0.28))
                    .frame(width: 90, height: 90)
            }
            .frame(width: 140, height: 140)
            Text(MicropetDex.title(engine, id: id, found: found))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            if !rarity.isEmpty {
                Text(rarity)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
            Text(MicropetDex.blurb(engine, id: id, found: found))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.75))
                .multilineTextAlignment(.center)
            Button(engine.t("micropets.close")) { picked = nil }
                .buttonStyle(GoobyButtonStyle())
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.cream.ignoresSafeArea())
        .presentationDetents([.medium])
    }
}

private struct MicropetDexPick: Identifiable {
    var id: String
}
