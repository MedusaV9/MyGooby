import Combine
import SwiftUI

struct MailScreen: View {
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.dismiss) private var dismiss
    @State private var notes = FriendsPostBook.load().notes
    @State private var wave = false

    private var calm: Bool { systemReduce || engine.reduceMotion }
    private var ledger: MailReadLedger { MailReadLedger.shared }

    var body: some View {
        let rows = MailBox.letters(engine, notes: notes)
        let title = MailBox.boxTitle(engine)
        ZStack(alignment: .topLeading) {
            VStack(spacing: -22) {
                header
                sheet(title: title, rows: rows)
            }
            back
        }
        .background(MailPaint.sheet.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: MailLetterLink.self) { link in
            MailLetterPage(engine: engine, letterID: link.id, notes: notes)
        }
        .onAppear {
            MailCarrier.shared.install()
            notes = FriendsPostBook.load().notes
            syncWave()
        }
        .onChange(of: calm) { _, _ in syncWave() }
        .onReceive(NotificationCenter.default.publisher(for: .goobyMailArrived)) { _ in
            notes = FriendsPostBook.load().notes
        }
    }

    private var header: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [MailPaint.skyTop, MailPaint.sky], startPoint: .top, endPoint: .bottom)
                .overlay {
                    MailCloud()
                        .offset(x: wave && !calm ? 36 : 18, y: 28)
                    MailCloud()
                        .scaleEffect(0.72)
                        .offset(x: wave && !calm ? -8 : 8, y: 78)
                }
                .ignoresSafeArea(edges: .top)
            MailboxGlyph(waving: wave && !calm)
                .padding(.bottom, 18)
        }
        .frame(height: 236)
        .accessibilityHidden(true)
    }

    private func sheet(title: String, rows: [MailNote]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(MailPaint.title)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 8)
                .accessibilityAddTraits(.isHeader)
            if rows.isEmpty {
                Spacer(minLength: 0)
                Text(engine.t("mail.empty"))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(MailPaint.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(rows) { note in
                            NavigationLink(value: MailLetterLink(id: note.id)) {
                                row(note)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded { engine.cue(.tap) })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(topLeading: 28, bottomLeading: 0, bottomTrailing: 0, topTrailing: 28),
                style: .continuous
            )
            .fill(MailPaint.sheet)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func row(_ note: MailNote) -> some View {
        let unread = !ledger.seen(note.id)
        return HStack(alignment: .top, spacing: 12) {
            MailEnvelope(unread: unread)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.title)
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if unread {
                        Text(engine.t("mail.new"))
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(MailPaint.seal, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Text(note.body)
                    .font(.system(.subheadline, design: .rounded))
                    .lineLimit(2)
                    .foregroundStyle(Theme.ink.opacity(0.7))
                Text(engine.formatDate(note.date))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.55))
            }
        }
        .foregroundStyle(Theme.ink)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var back: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(MailPaint.title)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 6)
        .padding(.top, 4)
        .accessibilityLabel(engine.t("mail.back"))
    }

    private func syncWave() {
        if calm {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { wave = false }
            return
        }
        guard !wave else { return }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            wave = true
        }
    }
}

private struct MailLetterLink: Hashable {
    var id: String
}

struct MailLetterPage: View {
    var engine: GoobyEngine
    var letterID: String
    var notes: [FriendsDispatch]
    @Environment(\.dismiss) private var dismiss

    private var letter: MailNote? {
        MailBox.letters(engine, notes: notes).first { $0.id == letterID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(MailPaint.title)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(engine.t("mail.back"))
                    Spacer()
                    MailStamp()
                }
                if let letter {
                    Text(letter.title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(engine.formatDate(letter.date, time: true))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                    Text(letter.body)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(engine.t("mail.missing"))
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
                Text(engine.t("mail.stays"))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.55))
            }
            .padding(20)
        }
        .background(MailPaint.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear { MailReadLedger.shared.mark(letterID) }
    }
}
