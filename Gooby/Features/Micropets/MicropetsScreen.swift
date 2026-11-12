import SwiftUI

struct MicropetsScreen: View {
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var showDex = false
    @State private var showBind = false
    @State private var picked: UUID?
    @State private var tick = 0

    private var calm: Bool { systemReduce || engine.reduceMotion }

    var body: some View {
        let eggs = engine.all(EggBinding.self).filter { !$0.hatched }.sorted { $0.createdAt < $1.createdAt }
        let friends = engine.all(MiniFriend.self).sorted { $0.hatchedAt > $1.hatchedAt }
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if eggs.isEmpty && friends.isEmpty {
                    Text(engine.t("micropets.empty"))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                Button(engine.t("micropets.bind")) { showBind = true }
                    .buttonStyle(GoobyButtonStyle())
                if !eggs.isEmpty {
                    sectionTitle(engine.t("micropets.eggs"))
                    ForEach(eggs) { egg in
                        eggRow(egg)
                    }
                }
                if !friends.isEmpty {
                    sectionTitle(engine.t("micropets.friends"))
                    ForEach(friends) { friend in
                        friendRow(friend)
                    }
                }
                Button(engine.t("micropets.dex")) { showDex = true }
                    .buttonStyle(GoobyButtonStyle(fill: Color(hex: 0x7BB65C), ink: .white))
                stage
            }
            .padding(16)
            .id(tick)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(engine.t("micropets.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBind) {
            MicropetBindSheet(engine: engine) { tick += 1 }
        }
        .fullScreenCover(isPresented: $showDex) {
            MicropetDexPage(engine: engine)
        }
        .sheet(item: pick) { item in
            if let friend = engine.all(MiniFriend.self).first(where: { $0.id == item.id }) {
                MicropetFriendPage(engine: engine, friend: friend, calm: calm) { tick += 1 }
            }
        }
    }

    private var pick: Binding<MicropetPick?> {
        Binding(
            get: { picked.map(MicropetPick.init) },
            set: { picked = $0?.id }
        )
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    private func eggRow(_ egg: EggBinding) -> some View {
        let need = max(1, egg.requiredCount)
        let ready = egg.progress >= need
        let fraction = min(1, CGFloat(egg.progress) / CGFloat(need))
        let habit = engine.habits().first { $0.id == egg.habitID }?.title ?? engine.t("micropets.egg.gone")
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                MicropetEgg(fraction: fraction, ready: ready)
                    .frame(width: 48, height: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(engine.tf("micropets.progress", egg.progress, need))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.65))
                }
                Spacer(minLength: 0)
            }
            Capsule()
                .fill(Theme.ink.opacity(0.12))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                            Capsule()
                                .fill(Color(hex: 0x7BB65C))
                                .frame(width: geo.size.width * fraction, height: 8)
                    }
                }
            if ready {
                Button(engine.t("micropets.hatch")) {
                    engine.hatch(egg)
                    engine.save()
                    tick += 1
                }
                .buttonStyle(GoobyButtonStyle(fill: Color(hex: 0x7BB65C), ink: .white))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func friendRow(_ friend: MiniFriend) -> some View {
        Button { picked = friend.id } label: {
            HStack(spacing: 12) {
                MicropetMark(id: friend.speciesID)
                    .frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName(friend))
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Text(engine.t("rarity.\(friend.rarity)"))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.65))
                }
                Spacer(minLength: 0)
                if friend.isCompanion {
                    Text(engine.t("micropets.with"))
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(Color(hex: 0x3F9A48))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var stage: some View {
        VStack(spacing: 6) {
            GoobyCharacterView(
                look: engine.wornLook(),
                stage: Growth.stage(of: engine.pet),
                animation: calm ? .idle : .breathe,
                reduceMotion: calm,
                companion: engine.companionSpecies()
            )
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            Text(engine.t(engine.companionSpecies() == nil ? "micropets.stage.off" : "micropets.stage.on"))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.65))
        }
        .padding(.vertical, 8)
    }

    private func displayName(_ friend: MiniFriend) -> String {
        let given = friend.givenName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !given.isEmpty { return given }
        return engine.catalog.friendsByID[friend.speciesID]?.name.text(engine.languageCode) ?? friend.speciesID
    }
}

private struct MicropetPick: Identifiable {
    var id: UUID
}
