import SwiftUI
import UIKit

struct FriendsTreeScreen: View {
    var engine: GoobyEngine
    @State private var book = FriendsBook.load()
    @State private var showSheet = false
    private var online: OnlineCenter { MainActor.assumeIsolated { OnlineCenter.shared } }

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
        .onChange(of: online.revision) { _, _ in
            book = FriendsBook.load()
        }
        .overlay(alignment: .top) {
            if !online.meetNote.isEmpty {
                Text(online.meetNote)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.yellow, in: Capsule())
                    .padding(.top, 58)
                    .padding(.horizontal, 24)
            }
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
                .position(x: 195 * unit, y: 294 * unit)
            Text(petName)
                .font(.system(size: 16.5 * unit, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .position(x: 195 * unit, y: 329 * unit)
            Text(ownerName)
                .font(.system(size: 14.5 * unit, weight: .bold, design: .rounded))
                .foregroundStyle(FriendsPaint.owner)
                .lineLimit(1)
                .position(x: 195 * unit, y: 349 * unit)
            if let left {
                slotFace(left.name, unit: unit, x: FriendsPaint.leftSign.x, y: FriendsPaint.leftSign.y - 12)
            } else {
                mark("???", unit: unit, x: FriendsPaint.leftSign.x + 0.3, y: FriendsPaint.leftSign.y + 0.4)
            }
            if let right {
                slotFace(right.name, unit: unit, x: FriendsPaint.rightSign.x, y: FriendsPaint.rightSign.y - 12)
            } else {
                mark("???", unit: unit, x: FriendsPaint.rightSign.x + 0.3, y: FriendsPaint.rightSign.y + 0.4)
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
            .font(.system(size: 12.5 * unit, weight: .heavy, design: .rounded))
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
            HStack(spacing: 6 * unit) {
                ZStack {
                    Circle().fill(FriendsPaint.buttonInk).frame(width: 21.5 * unit, height: 21.5 * unit)
                    RoundedRectangle(cornerRadius: 1.5 * unit).fill(.white).frame(width: 11 * unit, height: 3.2 * unit)
                    RoundedRectangle(cornerRadius: 1.5 * unit).fill(.white).frame(width: 3.2 * unit, height: 11 * unit)
                }
                Text(engine.t("friends.tree.add"))
                    .font(.system(size: 17.5 * unit, weight: .heavy, design: .rounded))
                    .foregroundStyle(FriendsPaint.buttonInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 16 * unit)
            .frame(minWidth: 147 * unit, minHeight: 42 * unit)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14 * unit, style: .continuous)
                        .fill(FriendsPaint.buttonLip)
                        .offset(y: 4 * unit)
                    RoundedRectangle(cornerRadius: 14 * unit, style: .continuous)
                        .fill(.white)
                }
            }
        }
        .buttonStyle(TreePressStyle(reduce: engine.reduceMotion))
        .position(x: 194.5 * unit, y: 437 * unit)
    }

    private func inviteButton(_ unit: CGFloat) -> some View {
        Button { showSheet = true } label: {
            HStack(spacing: 6 * unit) {
                Color.clear.frame(width: 65 * unit, height: 1)
                VStack(alignment: .leading, spacing: 3 * unit) {
                    Text(inviteTitle)
                        .font(.system(size: 12.8 * unit, weight: .heavy, design: .rounded))
                        .tracking(0.5 * unit)
                        .foregroundStyle(FriendsPaint.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(engine.t("friends.tree.invite"))
                        .font(.system(size: 17.5 * unit, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle().fill(FriendsPaint.chevronFill).frame(width: 17.5 * unit, height: 17.5 * unit)
                    Chevron()
                        .stroke(FriendsPaint.banner, style: StrokeStyle(lineWidth: 2 * unit, lineCap: .round, lineJoin: .round))
                        .frame(width: 4 * unit, height: 7.5 * unit)
                        .offset(x: 0.6 * unit)
                }
            }
            .padding(.leading, 10 * unit)
            .padding(.trailing, 8 * unit)
            .frame(width: 357 * unit, height: 84 * unit)
        }
        .buttonStyle(TreePressStyle(reduce: engine.reduceMotion))
        .position(x: 194.5 * unit, y: 546 * unit)
        .accessibilityLabel(inviteTitle)
    }
}

private struct Chevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
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
                    OnlineFriendsSection(engine: engine)
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
            engine.hatchInviteFriend()
            book.inviteClaimed = true
            message = engine.t("friends.tree.got")
        } else {
            message = ""
        }
        book.save()
        name = ""
        code = ""
        engine.cue(.gift)
    }

    private func remove(_ pal: TreePal) {
        book.pals.removeAll { $0.id == pal.id }
        book.save()
        OnlineCenter.shared.forget(code: pal.code)
    }
}

extension GoobyEngine {
    func hatchInviteFriend() {
        let species = catalog.friendsByID["mushroom"]
        let friend = MiniFriend()
        friend.speciesID = "mushroom"
        friend.givenName = species?.name.text(languageCode) ?? t("friends.tree.mushroom")
        friend.rarity = species?.rarity ?? "uncommon"
        friend.hatchedAt = now()
        friend.isCompanion = !all(MiniFriend.self).contains { $0.isCompanion }
        context.insert(friend)
        animation = .play
        celebration += 1
        save()
    }
}
