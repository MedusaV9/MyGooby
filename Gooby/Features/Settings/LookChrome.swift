import SwiftUI

enum Look {
    static let canvas = Color(hex: 0xD3E1EE)
    static let ink = Color(hex: 0x313131)
    static let row = Color(hex: 0x687178)
    static let code = Color(hex: 0x9AA4AB)
    static let sub = Color(hex: 0x9EA5AB)
    static let section = Color(hex: 0x5A656E)
    static let chevron = Color(hex: 0xA0AAB2)
    static let back = Color(hex: 0x6A7780)
    static let widget = Color(hex: 0x7478C1)
    static let plus = Color(hex: 0x566FD6)
    static let line = Color(hex: 0xF0F2F4)
    static let track = Color(hex: 0xE8E8EA)
    static let trailing = Color(hex: 0x8E949A)
    static let shadow = Color(hex: 0x7E96A8).opacity(0.18)

    static let margin: CGFloat = 16
    static let nameRadius: CGFloat = 26
    static let tileRadius: CGFloat = 20
    static let bannerRadius: CGFloat = 22
    static let groupRadius: CGFloat = 22
    static let tileHeight: CGFloat = 68
    static let nameHeight: CGFloat = 90
    static let widgetHeight: CGFloat = 86
    static let plusHeight: CGFloat = 92
    static let rowHeight: CGFloat = 60
}

struct LookScreen<Content: View>: View {
    var back: String
    @ViewBuilder var content: () -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LookBackButton(title: back) { dismiss() }
                content()
            }
            .padding(.horizontal, Look.margin)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Look.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
    }
}

struct LookBackButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Look.back)
                .frame(width: 44, height: 32, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .accessibilityLabel(title)
    }
}

struct LookCard<Content: View>: View {
    var radius: CGFloat = Look.groupRadius
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Look.shadow, radius: 10, y: 4)
    }
}

struct LookSectionTitle: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .tracking(1.15)
            .foregroundStyle(Look.section)
            .padding(.top, 18)
            .padding(.bottom, 8)
            .padding(.leading, 16)
    }
}

struct LookIcon: View {
    enum Kind {
        case activities, areas, goals, insights, news, history
        case invite, circles, bell, profile, appIcon, ruler, floppy, sprout
        case sparkles, rainbow, gift, bunnyHeart
    }

    var kind: Kind

    var body: some View {
        icon
            .frame(width: 34, height: 34)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var icon: some View {
        switch kind {
        case .activities: activities
        case .areas: areas
        case .goals: goals
        case .insights: insights
        case .news: news
        case .history: history
        case .invite: invite
        case .circles: circles
        case .bell: bell
        case .profile: profile
        case .appIcon: appIcon
        case .ruler: ruler
        case .floppy: floppy
        case .sprout: sprout
        case .sparkles: sparkles
        case .rainbow: rainbow
        case .gift: gift
        case .bunnyHeart: bunnyHeart
        }
    }

    private var activities: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: 0x3B82F6))
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            Circle()
                .fill(Color(hex: 0xFF8FA8))
                .frame(width: 11, height: 11)
                .offset(x: 3, y: -3)
        }
    }

    private var areas: some View {
        ZStack {
            Circle().fill(Color(hex: 0xFF7A45)).frame(width: 12, height: 12).offset(x: -8, y: -8)
            Circle().fill(Color(hex: 0x4DA3FF)).frame(width: 12, height: 12).offset(x: 8, y: -8)
            Circle().fill(Color(hex: 0x8B5CF6)).frame(width: 12, height: 12).offset(x: -8, y: 8)
            Image(systemName: "sparkle")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: 0xFFC83D))
                .offset(x: 8, y: 8)
        }
    }

    private var goals: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: 0xF6C56B))
                .frame(width: 26, height: 30)
                .rotationEffect(.degrees(-8))
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white)
                .frame(width: 16, height: 18)
                .offset(y: 3)
            Circle()
                .fill(Color(hex: 0x3DDC84))
                .frame(width: 12, height: 12)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: 2, y: 4)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0xE09A3A))
                .frame(width: 12, height: 5)
                .offset(y: -13)
        }
    }

    private var insights: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(hex: 0xE7EAED))
                .frame(width: 32, height: 30)
            HStack(alignment: .bottom, spacing: 3) {
                RoundedRectangle(cornerRadius: 1.5).fill(Color(hex: 0x3DDC84)).frame(width: 5, height: 8)
                RoundedRectangle(cornerRadius: 1.5).fill(Color(hex: 0xFF5A6A)).frame(width: 5, height: 14)
                RoundedRectangle(cornerRadius: 1.5).fill(Color(hex: 0x3B82F6)).frame(width: 5, height: 20)
            }
            .padding(.bottom, 4)
        }
    }

    private var news: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0xD6E4F2))
                .frame(width: 28, height: 30)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(hex: 0x8FB4D6))
                .frame(width: 28, height: 7)
            VStack(alignment: .leading, spacing: 3) {
                RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x5C89B0)).frame(width: 16, height: 2)
                RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x8FB4D6)).frame(width: 18, height: 2)
                RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x8FB4D6)).frame(width: 12, height: 2)
            }
            .padding(.top, 11)
        }
    }

    private var history: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: 0x7EC8F0))
                .frame(width: 30, height: 28)
                .offset(y: 2)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(hex: 0xFF5A5A))
                .frame(width: 30, height: 10)
            HStack(spacing: 8) {
                Circle().fill(Color.white).frame(width: 4, height: 4)
                Circle().fill(Color.white).frame(width: 4, height: 4)
            }
            .offset(y: 3)
            HStack(spacing: 6) {
                Circle().fill(Color(hex: 0x2F6BFF)).frame(width: 4, height: 4)
                Circle().fill(Color(hex: 0x2F6BFF)).frame(width: 4, height: 4)
            }
            .offset(y: 14)
        }
    }

    private var invite: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color(hex: 0x8AA0B0), lineWidth: 1.6)
                .frame(width: 26, height: 18)
            Path { path in
                path.move(to: CGPoint(x: 4, y: 8))
                path.addLine(to: CGPoint(x: 17, y: 16))
                path.addLine(to: CGPoint(x: 30, y: 8))
            }
            .stroke(Color(hex: 0x8AA0B0), lineWidth: 1.4)
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: 0xFF4D4D))
                .offset(y: -1)
        }
    }

    private var circles: some View {
        ZStack {
            Circle().fill(Color(hex: 0xB9A6F5)).frame(width: 16, height: 16).offset(x: -6, y: 2)
            Circle().fill(Color(hex: 0x8B74E8)).frame(width: 18, height: 18).offset(x: 6, y: -1)
            Capsule().fill(Color(hex: 0xB9A6F5)).frame(width: 16, height: 8).offset(x: -6, y: 12)
            Capsule().fill(Color(hex: 0x8B74E8)).frame(width: 18, height: 9).offset(x: 6, y: 11)
        }
    }

    private var bell: some View {
        Image(systemName: "bell.fill")
            .font(.system(size: 24))
            .foregroundStyle(Color(hex: 0xFFB020))
    }

    private var profile: some View {
        ZStack {
            Circle().fill(Color(hex: 0xD9F5E3)).frame(width: 30, height: 30).offset(y: 1)
            BunnyFace(eye: 3.4, cheek: 2.4)
                .scaleEffect(0.82)
                .offset(y: 1)
        }
    }

    private var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: 0xF4E2D4))
            BunnyFace(eye: 2.6, cheek: 1.8)
                .scaleEffect(0.62)
            Circle()
                .fill(Color(hex: 0xFF8FA8))
                .frame(width: 8, height: 8)
                .offset(x: 9, y: 8)
        }
    }

    private var ruler: some View {
        ZStack {
            RulerShape()
                .fill(Color(hex: 0x3B6BFF))
                .frame(width: 26, height: 26)
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color(hex: 0xFFC83D))
                .frame(width: 5, height: 22)
                .rotationEffect(.degrees(38))
                .offset(x: 6, y: 2)
        }
    }

    private var floppy: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0xB7B6FF))
                .frame(width: 22, height: 26)
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color(hex: 0x8E8DFF))
                .frame(width: 12, height: 7)
                .offset(y: -9)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white)
                .frame(width: 14, height: 8)
                .offset(y: 6)
        }
    }

    private var sprout: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x7ED37A)).frame(width: 5, height: 16).offset(y: 6)
            Ellipse().fill(Color(hex: 0xB6E38A)).frame(width: 12, height: 8).rotationEffect(.degrees(-30)).offset(x: -6, y: -2)
            Ellipse().fill(Color(hex: 0xE7D36A)).frame(width: 12, height: 8).rotationEffect(.degrees(28)).offset(x: 6, y: -4)
        }
    }

    private var sparkles: some View {
        ZStack {
            Diamond().fill(Color(hex: 0xFFE56A)).frame(width: 14, height: 14).offset(x: -2, y: 1)
            Diamond().fill(Color(hex: 0xFFD23A)).frame(width: 8, height: 8).offset(x: 9, y: -8)
            Circle().fill(Color(hex: 0xFFE9A0)).frame(width: 3, height: 3).offset(x: 10, y: 8)
            Circle().fill(Color(hex: 0xFFE9A0)).frame(width: 2.5, height: 2.5).offset(x: -11, y: -6)
        }
    }

    private var rainbow: some View {
        ZStack {
            Circle().trim(from: 0.5, to: 1).stroke(Color(hex: 0xFF5A5A), style: StrokeStyle(lineWidth: 3.2, lineCap: .round)).frame(width: 28, height: 28)
            Circle().trim(from: 0.5, to: 1).stroke(Color(hex: 0xFFB020), style: StrokeStyle(lineWidth: 3.2, lineCap: .round)).frame(width: 22, height: 22)
            Circle().trim(from: 0.5, to: 1).stroke(Color(hex: 0xFFE14A), style: StrokeStyle(lineWidth: 3.2, lineCap: .round)).frame(width: 16, height: 16)
            Circle().trim(from: 0.5, to: 1).stroke(Color(hex: 0x3DDC84), style: StrokeStyle(lineWidth: 3.2, lineCap: .round)).frame(width: 10, height: 10)
        }
        .offset(y: 6)
    }

    private var gift: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0xFFC83D))
                .frame(width: 24, height: 18)
                .offset(y: 4)
            Rectangle().fill(Color(hex: 0xFF4D4D)).frame(width: 24, height: 4).offset(y: -2)
            Rectangle().fill(Color(hex: 0xFF4D4D)).frame(width: 4, height: 22)
            Capsule().fill(Color(hex: 0xFF4D4D)).frame(width: 8, height: 6).offset(x: -5, y: -12)
            Capsule().fill(Color(hex: 0xFF4D4D)).frame(width: 8, height: 6).offset(x: 5, y: -12)
        }
    }

    private var bunnyHeart: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: 0x8E9BE8))
                .frame(width: 32, height: 32)
            BunnyFace(eye: 3.1, cheek: 2)
                .scaleEffect(0.78)
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: 0xFF6FA0))
                .offset(x: 10, y: -10)
        }
    }
}

struct BunnyFace: View {
    var eye: CGFloat = 3.4
    var cheek: CGFloat = 2.4

    var body: some View {
        ZStack {
            Capsule().fill(Color(hex: 0xFFD0DC)).frame(width: 7, height: 12).offset(x: -8, y: -12)
            Capsule().fill(Color(hex: 0xFFD0DC)).frame(width: 7, height: 12).offset(x: 8, y: -12)
            Circle().fill(Color(hex: 0xFFF6EA)).frame(width: 22, height: 22)
            Circle().fill(Color(hex: 0x5A4636)).frame(width: eye, height: eye + 0.6).offset(x: -4, y: -1)
            Circle().fill(Color(hex: 0x5A4636)).frame(width: eye, height: eye + 0.6).offset(x: 4, y: -1)
            Circle().fill(.white).frame(width: 1.2, height: 1.2).offset(x: -3.2, y: -1.6)
            Circle().fill(Color(hex: 0xFFB3C7)).frame(width: cheek, height: cheek * 0.7).offset(x: -7, y: 3)
            Circle().fill(Color(hex: 0xFFB3C7)).frame(width: cheek, height: cheek * 0.7).offset(x: 7, y: 3)
            Capsule().fill(Color(hex: 0xE989A8)).frame(width: 4, height: 2).offset(y: 4)
        }
    }
}

struct RulerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 2, y: rect.maxY - 2))
        path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.minY + 8))
        path.addLine(to: CGPoint(x: rect.maxX - 6, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.minY + 8))
        path.closeSubpath()
        return path
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct LookSwitch: View {
    @Binding var isOn: Bool
    var label: String

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? Color(hex: 0x34C759) : Look.track)
                Circle()
                    .fill(Color.white)
                    .frame(width: 27, height: 27)
                    .shadow(color: Color.black.opacity(0.16), radius: 1.5, y: 1)
                    .padding(2)
            }
            .frame(width: 51, height: 31)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "1" : "0")
        .accessibilityAddTraits(.isButton)
    }
}

struct LookNavRow: View {
    var title: String
    var subtitle: String? = nil
    var icon: LookIcon.Kind? = nil
    var badge: String? = nil
    var trailing: String? = nil
    var showsChevron: Bool = true
    var indented: Bool = false
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                LookIcon(kind: icon)
            } else if indented {
                Color.clear.frame(width: 34, height: 34)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Look.row)
                    if let badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Look.plus, in: Capsule())
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.sub)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.trailing)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Look.chevron)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: rowHeight)
        .contentShape(Rectangle())
    }

    private var rowHeight: CGFloat {
        if compact { return subtitle == nil ? 48 : 54 }
        return subtitle == nil ? Look.rowHeight : 84
    }
}

struct LookDivider: View {
    var body: some View {
        Rectangle()
            .fill(Look.line)
            .frame(height: 1)
            .padding(.leading, 60)
    }
}

enum FriendCode {
    static let forbidden = "B25F596HSK"

    static func make(seed: Int64) -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        var state = UInt64(bitPattern: seed) &* 0x9E3779B97F4A7C15 &+ 0xA5A5F00D
        if state == 0 { state = 0xC0FFEE }
        var chars: [Character] = []
        chars.reserveCapacity(9)
        for _ in 0..<9 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            chars.append(alphabet[Int(state % UInt64(alphabet.count))])
        }
        let code = String(chars)
        return code == forbidden ? "G7Q2M4N8K" : code
    }
}

enum LookMark {
    static let pause = "look.pause"
    static let plus = "look.plus"
    static let pauseIDs = "look.pause.ids"
    static let pauseStart = "look.pause.start"
    static let circles = "look.circles"
    static let letters = "look.letters.read"
    static let icon = "look.icon"
    static let holdHabit = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!

    static func isOn(_ engine: GoobyEngine, _ key: String) -> Bool {
        engine.all(RewardLedger.self).contains { $0.key == key }
    }

    static func set(_ engine: GoobyEngine, _ key: String, _ on: Bool) {
        let rows = engine.all(RewardLedger.self).filter { $0.key == key }
        if on {
            if rows.isEmpty {
                let row = RewardLedger()
                row.key = key
                row.sparks = 0
                row.energy = 0
                row.createdAt = engine.now()
                engine.context.insert(row)
            }
        } else {
            rows.forEach { engine.context.delete($0) }
        }
        engine.save()
    }

    static func setPause(_ engine: GoobyEngine, _ on: Bool) {
        if on {
            let ids = engine.habits().filter { !$0.isArchived && !$0.isPaused }.map(\.id.uuidString)
            UserDefaults.standard.set(ids, forKey: pauseIDs)
            UserDefaults.standard.set(engine.dayKey(), forKey: pauseStart)
            for habit in engine.habits() where ids.contains(habit.id.uuidString) {
                habit.isPaused = true
            }
            set(engine, pause, true)
            holdDays(engine)
        } else {
            let ids = UserDefaults.standard.stringArray(forKey: pauseIDs) ?? []
            if ids.isEmpty {
                for habit in engine.habits() where habit.isPaused { habit.isPaused = false }
            } else {
                for habit in engine.habits() where ids.contains(habit.id.uuidString) {
                    habit.isPaused = false
                }
            }
            UserDefaults.standard.removeObject(forKey: pauseIDs)
            UserDefaults.standard.removeObject(forKey: pauseStart)
            set(engine, pause, false)
        }
        engine.rescheduleNotifications()
    }

    static func holdDays(_ engine: GoobyEngine) {
        guard isOn(engine, pause) else { return }
        let startKey = UserDefaults.standard.string(forKey: pauseStart) ?? engine.dayKey()
        guard var day = DayKey.parse(startKey) else { return }
        let end = Calendar.current.startOfDay(for: engine.now())
        while day <= end {
            let key = DayKey.make(day)
            let already = engine.all(HabitLog.self).contains { $0.dayKey == key && !$0.skipped && $0.count > 0 && $0.habitID != holdHabit }
            if !already, engine.habitLog(holdHabit, key) == nil {
                let log = HabitLog()
                log.habitID = holdHabit
                log.dayKey = key
                log.count = 1
                log.skipped = false
                log.createdAt = engine.now()
                engine.context.insert(log)
            }
            guard let next = Calendar.current.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        engine.save()
    }
}

struct LookPillButton: View {
    var title: String
    var fill: Color = .white
    var ink: Color = Look.ink
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .padding(.horizontal, 18)
                .frame(minWidth: 72, minHeight: 40)
                .background(fill, in: Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
