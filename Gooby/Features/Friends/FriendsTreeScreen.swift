import SwiftUI
import UIKit

struct FriendsTreeScreen: View {
    var engine: GoobyEngine
    @State private var book = FriendsBook.load()
    @State private var showSheet = false

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 390
            ZStack(alignment: .topLeading) {
                FriendsPaint.grass
                tree(unit)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .navigationTitle(engine.t("friends.tree.nav"))
        .sheet(isPresented: $showSheet) {
            FriendsAddSheet(engine: engine, book: $book)
        }
    }

    private var petName: String {
        let name = engine.profile.goobyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Gooby" : name
    }

    private var ownerName: String {
        let name = engine.profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? engine.t("friends.tree.you") : name
    }

    private var inviteTitle: String {
        let species = engine.catalog.friendsByID["mushroom"]?.name.text(engine.languageCode) ?? engine.t("friends.tree.mushroom")
        return engine.tf("friends.tree.meet", species.uppercased())
    }

    private func tree(_ unit: CGFloat) -> some View {
        let left = book.pals.first
        let right = book.pals.dropFirst().first
        return ZStack(alignment: .topLeading) {
            FriendsTreeCanvas(showInvite: !book.inviteClaimed, leftOpen: left == nil, rightOpen: right == nil)
            GoobyMark()
                .scaleEffect(unit)
                .position(x: 195 * unit, y: 300 * unit)
            VStack(spacing: 1 * unit) {
                Text(petName)
                    .font(.system(size: 18 * unit, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(ownerName)
                    .font(.system(size: 15 * unit, weight: .bold, design: .rounded))
                    .foregroundStyle(FriendsPaint.owner)
            }
            .position(x: 195 * unit, y: 338 * unit)
            if let left {
                slotFace(left.name, unit: unit, x: 78.5, y: 286)
            } else {
                mark("???", unit: unit, x: 78.5, y: 300)
            }
            if let right {
                slotFace(right.name, unit: unit, x: 312.5, y: 266)
            } else {
                mark("???", unit: unit, x: 312.5, y: 280)
            }
            addButton(unit)
            if !book.inviteClaimed {
                inviteButton(unit)
            }
            Button { showSheet = true } label: {
                Color.clear.frame(width: 44 * unit, height: 44 * unit)
            }
            .buttonStyle(.plain)
            .position(x: 356 * unit, y: 86 * unit)
            .accessibilityLabel(engine.t("friends.tree.gear"))
        }
        .frame(width: 390 * unit, height: 844 * unit, alignment: .topLeading)
    }

    private func mark(_ text: String, unit: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 11 * unit, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .position(x: x * unit, y: y * unit)
            .accessibilityLabel(text)
    }

    private func slotFace(_ name: String, unit: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            GoobyMark().scaleEffect(0.55 * unit)
            Text(name)
                .font(.system(size: 12 * unit, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .offset(y: 30 * unit)
        }
        .position(x: x * unit, y: y * unit)
        .accessibilityLabel(name)
    }

    private func addButton(_ unit: CGFloat) -> some View {
        Button { showSheet = true } label: {
            HStack(spacing: 8 * unit) {
                ZStack {
                    Circle().fill(FriendsPaint.buttonInk).frame(width: 22 * unit, height: 22 * unit)
                    Text("+")
                        .font(.system(size: 16 * unit, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .offset(y: -1 * unit)
                }
                Text(engine.t("friends.tree.add"))
                    .font(.system(size: 16.5 * unit, weight: .heavy, design: .rounded))
                    .foregroundStyle(FriendsPaint.buttonInk)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14 * unit)
            .frame(minWidth: 147 * unit, minHeight: 43 * unit)
            .background {
                Capsule().fill(.white).shadow(color: .black.opacity(0.12), radius: 0, y: 4 * unit)
            }
        }
        .buttonStyle(TreePressStyle(reduce: engine.reduceMotion))
        .position(x: 194.5 * unit, y: 438.5 * unit)
    }

    private func inviteButton(_ unit: CGFloat) -> some View {
        Button { showSheet = true } label: {
            HStack(spacing: 6 * unit) {
                Color.clear.frame(width: 52 * unit, height: 1)
                VStack(alignment: .leading, spacing: 2 * unit) {
                    Text(inviteTitle)
                        .font(.system(size: 11 * unit, weight: .heavy, design: .rounded))
                        .foregroundStyle(FriendsPaint.gold)
                        .lineLimit(1)
                    Text(engine.t("friends.tree.invite"))
                        .font(.system(size: 16 * unit, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(1 * unit)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle().fill(FriendsPaint.chevronFill).frame(width: 22 * unit, height: 22 * unit)
                    Text("›")
                        .font(.system(size: 16 * unit, weight: .heavy, design: .rounded))
                        .foregroundStyle(FriendsPaint.banner)
                        .offset(y: -1 * unit)
                }
            }
            .padding(.horizontal, 10 * unit)
            .frame(width: 358 * unit, height: 82 * unit)
        }
        .buttonStyle(TreePressStyle(reduce: engine.reduceMotion))
        .position(x: 195 * unit, y: 549 * unit)
        .accessibilityLabel(inviteTitle)
    }
}

private struct TreePressStyle: ButtonStyle {
    var reduce: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduce && configuration.isPressed ? 0.96 : 1)
            .animation(reduce ? nil : .spring(duration: 0.22), value: configuration.isPressed)
    }
}

private struct FriendsAddSheet: View {
    var engine: GoobyEngine
    @Binding var book: FriendsBook
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var code = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(engine.t("friends.tree.yours"))
                        .font(.system(.headline, design: .rounded))
                    Text(ownCode)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .textSelection(.enabled)
                    Text(engine.t("friends.tree.codeHint"))
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.72))
                    Button(engine.t("friends.tree.copy")) {
                        UIPasteboard.general.string = ownCode
                        message = engine.t("friends.tree.copied")
                    }
                    .buttonStyle(GoobyButtonStyle(fill: Theme.mint, ink: Theme.ink))
                    TextField(engine.t("friends.tree.name"), text: $name)
                        .textFieldStyle(.roundedBorder)
                    TextField(engine.t("friends.tree.code"), text: $code)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    if !message.isEmpty {
                        Text(message)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Theme.ink)
                    }
                    Button(engine.t("friends.tree.save")) { addPal() }
                        .buttonStyle(GoobyButtonStyle(fill: FriendsPaint.buttonInk, ink: .white))
                    if !book.pals.isEmpty {
                        ForEach(book.pals) { pal in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pal.name).font(.system(.headline, design: .rounded))
                                    Text(pal.code).font(.system(.caption, design: .rounded))
                                }
                                Spacer()
                                Button(engine.t("friends.tree.remove")) { remove(pal) }
                                    .font(.system(.subheadline, design: .rounded))
                            }
                            .padding(12)
                            .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    companions
                }
                .padding(20)
                .foregroundStyle(Theme.ink)
            }
            .background(Theme.cream)
            .navigationTitle(engine.t("friends.tree.nav"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(engine.t("friends.tree.close")) { dismiss() }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var ownCode: String { GoobyFriendCode.make(profileID: engine.profile.id) }

    @ViewBuilder private var companions: some View {
        let friends = engine.all(MiniFriend.self).sorted { $0.hatchedAt < $1.hatchedAt }
        if !friends.isEmpty {
            Text(engine.t("friends.tree.companions"))
                .font(.system(.headline, design: .rounded))
                .padding(.top, 6)
            ForEach(friends) { friend in
                HStack {
                    MiniFriendBadge(species: friend.speciesID).frame(width: 44, height: 44)
                    VStack(alignment: .leading) {
                        Text(friend.givenName).font(.system(.headline, design: .rounded))
                        Text(engine.t("rarity.\(friend.rarity)")).font(.system(.caption, design: .rounded))
                    }
                    Spacer()
                    if friend.isCompanion {
                        Text(engine.t("friends.with"))
                    } else {
                        Button(engine.t("friends.choose")) { engine.setCompanion(friend) }
                    }
                }
                .padding(10)
                .background(Theme.whiteCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func addPal() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            message = engine.t("friends.tree.needName")
            return
        }
        let entered = GoobyFriendCode.normalize(code)
        guard GoobyFriendCode.isShape(entered) else {
            message = engine.t("friends.tree.badCode")
            return
        }
        guard entered != ownCode else {
            message = engine.t("friends.tree.ownCode")
            return
        }
        guard !book.pals.contains(where: { $0.code == entered }) else {
            message = engine.t("friends.tree.duplicate")
            return
        }
        book.pals.append(TreePal(id: UUID(), name: trimmed, code: entered))
        if !book.inviteClaimed {
            grantMushroom()
            book.inviteClaimed = true
            message = engine.t("friends.tree.got")
        } else {
            message = ""
        }
        book.save()
        name = ""
        code = ""
        engine.haptics.celebrate()
    }

    private func remove(_ pal: TreePal) {
        book.pals.removeAll { $0.id == pal.id }
        book.save()
    }

    private func grantMushroom() {
        let species = engine.catalog.friendsByID["mushroom"]
        let friend = MiniFriend()
        friend.speciesID = "mushroom"
        friend.givenName = species?.name.text(engine.languageCode) ?? engine.t("friends.tree.mushroom")
        friend.rarity = species?.rarity ?? "uncommon"
        friend.hatchedAt = engine.now()
        friend.isCompanion = !engine.all(MiniFriend.self).contains { $0.isCompanion }
        engine.context.insert(friend)
        engine.animation = .play
        engine.celebration += 1
        engine.save()
    }
}
