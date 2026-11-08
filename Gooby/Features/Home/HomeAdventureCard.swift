import SwiftUI

/// Translucent green card over the bottom of the Home scene (screen F): adventure status on the left, return
/// time or energy on the right, and a track from a lightning circle to a "?" circle with Gooby's
/// head at the current progress. While energy is still gathering the track shows the energy.
struct HomeAdventureCard: View {
    var engine: GoobyEngine
    /// Opens the world (places, start, story).
    var open: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 20)) { _ in
            let state = engine.homeAdventureState(at: engine.now())
            if let action = actionTitle(state) {
                VStack(alignment: .leading, spacing: 12) {
                    content(state)
                    Button(action: open) {
                        Text(action)
                            .foregroundStyle(Theme.Tab.home.leafDark)
                    }
                    .buttonStyle(Press3DButtonStyle(fill: .white, edge: Color(hex: 0xCFE3BF), radius: 16, vertical: 12, expand: true))
                }
                .modifier(HomeAdventureCardBackground())
            } else {
                Button(action: open) {
                    content(state)
                        .modifier(HomeAdventureCardBackground())
                }
                .buttonStyle(HomeSoftPressStyle())
                .accessibilityHint(engine.tx("home.adventure.open", de: "Öffnet die Orte und Abenteuer.", en: "Opens places and adventures."))
            }
        }
    }

    private func content(_ state: HomeAdventureState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title(state))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer(minLength: 6)
                Text(detail(state))
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Color.white.opacity(0.92))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            HomeAdventureTrack(
                progress: progress(state),
                end: endSymbol(state),
                avatar: GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: 30)
            )
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

    private var name: String {
        engine.profile.goobyName.isEmpty ? "Gooby" : engine.profile.goobyName
    }

    private func title(_ state: HomeAdventureState) -> String {
        switch state {
        case .gathering:
            return engine.tx("home.adventure.gathering", de: "Energie sammeln", en: "Gathering energy")
        case .ready:
            return engine.tx("home.adventure.ready", de: "Bereit fürs Abenteuer!", en: "Ready for an adventure!")
        case .traveling:
            return engine.tx("home.adventure.traveling", de: "Unterwegs", en: "Adventuring")
        case .returned:
            return engine.txf("home.adventure.returned", de: "%@ ist zurück!", en: "%@ is back!", name)
        case .told:
            return engine.tx("home.adventure.told", de: "Abenteuer erzählt", en: "Adventure told")
        }
    }

    private func detail(_ state: HomeAdventureState) -> String {
        switch state {
        case .gathering(let energy, let goal):
            return engine.txf("home.adventure.energy", de: "⚡ %d / %d", en: "⚡ %d / %d", energy, goal)
        case .ready:
            let goal = max(1, engine.profile.energyGoal)
            return engine.txf("home.adventure.energy", de: "⚡ %d / %d", en: "⚡ %d / %d", goal, goal)
        case .traveling(_, let returnsAt):
            let time = clock(returnsAt)
            if Calendar.current.isDate(returnsAt, inSameDayAs: engine.now()) {
                return engine.txf("home.adventure.backAt", de: "zurück um %@", en: "back at %@", time)
            }
            return engine.txf("home.adventure.backTomorrow", de: "zurück morgen um %@", en: "back tomorrow at %@", time)
        case .returned:
            return engine.tx("home.adventure.story", de: "Neue Geschichte", en: "New story")
        case .told:
            return engine.tx("home.adventure.tomorrow", de: "Morgen geht's weiter", en: "More tomorrow")
        }
    }

    private func actionTitle(_ state: HomeAdventureState) -> String? {
        switch state {
        case .ready: return engine.t("adventure.start")
        case .returned: return engine.t("adventure.read")
        default: return nil
        }
    }

    private func progress(_ state: HomeAdventureState) -> Double {
        switch state {
        case .gathering(let energy, let goal): return goal > 0 ? min(1, Double(energy) / Double(goal)) : 0
        case .traveling(let progress, _): return progress
        case .ready, .returned, .told: return 1
        }
    }

    private func endSymbol(_ state: HomeAdventureState) -> String {
        switch state {
        case .returned: return "exclamationmark"
        case .told: return "checkmark"
        default: return "questionmark"
        }
    }

    private func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.languageCode)
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct HomeAdventureCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Theme.Space.inner)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Tab.home.adventureCard, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

/// Lightning circle, traveled part solid, the rest dotted, "?" circle at the end; the avatar sits
/// on the track at `progress`.
struct HomeAdventureTrack<Avatar: View>: View {
    var progress: Double
    var end: String
    var avatar: Avatar

    var body: some View {
        GeometryReader { geo in
            let side: CGFloat = 30
            let startX = side
            let endX = geo.size.width - side
            let span = max(0, endX - startX)
            let clamped = CGFloat(min(1, max(0, progress)))
            let headX = startX + 6 + (span - 12) * clamped
            let midY = geo.size.height / 2
            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: startX, y: midY))
                    path.addLine(to: CGPoint(x: headX, y: midY))
                }
                .stroke(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                Path { path in
                    path.move(to: CGPoint(x: headX, y: midY))
                    path.addLine(to: CGPoint(x: endX - 4, y: midY))
                }
                .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [0.1, 9]))
                bolt
                    .position(x: side / 2, y: midY)
                goal
                    .position(x: geo.size.width - side / 2, y: midY)
                avatar
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .position(x: headX, y: midY)
            }
        }
        .frame(height: 36)
    }

    private var bolt: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(
                Circle().fill(LinearGradient(colors: [Color(hex: 0xFFC93C), Color(hex: 0xF59B23)], startPoint: .top, endPoint: .bottom))
            )
    }

    private var goal: some View {
        Image(systemName: end)
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(Color(hex: 0x9A6A12))
            .frame(width: 30, height: 30)
            .background(Circle().fill(Color(hex: 0xFFD45E)))
    }
}
