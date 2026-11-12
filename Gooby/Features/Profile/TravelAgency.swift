import SwiftUI

/// Local desk for the ten spec destinations. Sparks buy a closed place through the existing ticket.
/// An open place is chosen, then `startAdventure` runs today's outing. No second clock, no map.
struct TravelAgencyScreen: View {
    var engine: GoobyEngine
    var calm: Bool
    var onClose: () -> Void

    @State private var selectedID: String?
    @State private var notice: String?
    @State private var ask = false
    @State private var askTitle = ""
    @State private var askBody = ""
    @State private var askPlaceID: String?

    private var places: [PlaceDef] { TravelDesk.destinations(engine) }

    private var selected: PlaceDef? {
        guard let selectedID else { return nil }
        return places.first { $0.id == selectedID }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0xC19668).ignoresSafeArea()
            VStack(spacing: 12) {
                header
                desk
            }
            .padding(.top, 8)
        }
        .accessibilityIdentifier("travel-agency")
        .alert(askTitle, isPresented: $ask) {
            Button(engine.t("common.cancel"), role: .cancel) {}
            Button(engine.t("common.confirm"), action: commit)
        } message: {
            Text(askBody)
        }
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(engine.t("travel.agency.title"))
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(ProfilePalette.ink)
                Text(engine.tf("travel.agency.balance", engine.wallet.sparks))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ProfilePalette.brown)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 56)
            HStack {
                Button(action: onClose) {
                    ChevronGlyph()
                        .rotationEffect(.degrees(180))
                        .foregroundStyle(ProfilePalette.ink)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.92), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ProfileCopy.back(engine.languageCode))
                Spacer()
                TravelSpark()
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
    }

    private var desk: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(engine.t("travel.agency.lead"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(ProfilePalette.brown)
                .fixedSize(horizontal: false, vertical: true)
            Text(AdventureText.line(engine, "adventure.energy", [
                "have": "\(engine.wallet.energy)",
                "need": "\(max(1, engine.profile.energyGoal))"
            ]))
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(ProfilePalette.ink)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(places) { place in
                        placeRow(place)
                    }
                }
                .padding(.bottom, 8)
            }
            if let notice {
                Text(notice)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ProfilePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("travel-agency-notice")
            }
            Button(action: askCommit) {
                Text(commitTitle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(GoobyButtonStyle(fill: ProfilePalette.brown, ink: .white))
            .disabled(!commitEnabled)
            .opacity(commitEnabled ? 1 : 0.45)
            .accessibilityIdentifier("travel-agency-commit")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ProfilePalette.paper)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28, style: .continuous))
        .padding(.horizontal, 12)
    }

    private func placeRow(_ place: PlaceDef) -> some View {
        let picked = place.id == selectedID
        let open = engine.isPlaceUnlocked(place.id)
        let name = place.name.text(engine.languageCode)
        let price = open ? engine.t("travel.agency.open") : engine.tf("travel.agency.balance", TravelDesk.cost(engine, place: place))
        return Button {
            selectedID = place.id
            notice = nil
        } label: {
            HStack(alignment: .center, spacing: 10) {
                AdventurePlaceArt(place: place)
                    .frame(width: 72, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .opacity(open ? 1 : 0.88)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(name)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(ProfilePalette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(price)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(ProfilePalette.brown)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .layoutPriority(1)
                    }
                    Text(engine.t("rarity.\(TravelDesk.rarityKey(engine, place: place))"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(ProfilePalette.brownSoft)
                    Text(place.blurb.text(engine.languageCode))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(ProfilePalette.brown)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(picked ? Color(hex: 0xF6E7D2) : Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(picked ? ProfilePalette.brown : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("travel-place-\(place.id)")
        .accessibilityAddTraits(picked ? .isSelected : [])
        .accessibilityLabel(rowLabel(name: name, place: place, open: open))
    }

    private func rowLabel(name: String, place: PlaceDef, open: Bool) -> String {
        let rarity = engine.t("rarity.\(TravelDesk.rarityKey(engine, place: place))")
        let price = open ? engine.t("travel.agency.open") : engine.tf("travel.agency.balance", TravelDesk.cost(engine, place: place))
        return "\(name), \(rarity), \(price)"
    }

    private var commitTitle: String {
        guard let place = selected else { return engine.t("travel.agency.pick") }
        switch TravelDesk.action(engine, place: place) {
        case .buyAndGo(let cost):
            return engine.tf("travel.agency.buyGo", cost)
        case .buy(let cost):
            return engine.tf("travel.agency.buy", cost)
        case .go:
            return engine.t("adventure.start.trip")
        case .wait:
            return engine.t("adventure.already")
        }
    }

    private var commitEnabled: Bool {
        guard let place = selected else { return false }
        if case .wait = TravelDesk.action(engine, place: place) { return false }
        return true
    }

    private func askCommit() {
        guard let place = selected, commitEnabled else { return }
        askPlaceID = place.id
        let name = place.name.text(engine.languageCode)
        switch TravelDesk.action(engine, place: place) {
        case .buyAndGo(let cost):
            askTitle = engine.t("travel.agency.confirmTitle")
            askBody = engine.tf("travel.agency.confirmBuyGo", name, cost)
        case .buy(let cost):
            askTitle = engine.t("travel.agency.confirmTitle")
            askBody = engine.tf("travel.agency.confirmBuy", name, cost)
        case .go:
            if engine.wallet.energy < engine.profile.energyGoal {
                notice = engine.t("adventure.needEnergy")
                return
            }
            askTitle = engine.t("travel.agency.confirmTitleGo")
            askBody = engine.tf("travel.agency.confirmGo", name)
        case .wait:
            notice = engine.t("adventure.already")
            return
        }
        ask = true
    }

    private func commit() {
        guard let id = askPlaceID, let place = places.first(where: { $0.id == id }) else { return }
        switch TravelDesk.action(engine, place: place) {
        case .buy(let cost):
            guard pay(place, cost: cost) else { return }
            notice = boughtNote()
        case .buyAndGo(let cost):
            guard pay(place, cost: cost) else { return }
            depart(place)
        case .go:
            depart(place)
        case .wait:
            notice = engine.t("adventure.already")
        }
    }

    private func pay(_ place: PlaceDef, cost: Int) -> Bool {
        if engine.placeProgress(place.id) == nil { engine.ensureWorld() }
        if let ticket = TravelDesk.ticket(engine, place: place), engine.owns(ticket.id) {
            engine.placeProgress(place.id)?.unlocked = true
            engine.save()
            guard engine.isPlaceUnlocked(place.id) else {
                notice = engine.t("adventure.locked")
                return false
            }
            return true
        }
        guard engine.wallet.sparks >= cost else {
            notice = engine.t("travel.agency.poor")
            return false
        }
        guard let ticket = TravelDesk.ticket(engine, place: place) else {
            notice = engine.t("adventure.locked")
            return false
        }
        if let error = engine.buy(ticket) {
            notice = error == "shop.poor" ? engine.t("travel.agency.poor") : engine.t(error)
            return false
        }
        guard engine.isPlaceUnlocked(place.id) else {
            notice = engine.t("adventure.locked")
            return false
        }
        return true
    }

    private func boughtNote() -> String {
        var line = engine.t("travel.agency.bought")
        if engine.todaysRun() != nil {
            line += " " + engine.t("adventure.already")
        } else if engine.wallet.energy < engine.profile.energyGoal {
            line += " " + engine.t("adventure.needEnergy")
        }
        return line
    }

    private func depart(_ place: PlaceDef) {
        if let error = engine.startAdventure(placeID: place.id) {
            notice = engine.t(error)
            return
        }
        notice = engine.t("adventure.started")
        engine.haptics.soft()
    }
}

@MainActor
enum TravelDesk {
    /// Spec places. Catalog order, so the desk follows the same list the album already stores.
    static let destinationIDs: [String] = [
        "meadow", "garden", "cherry", "crystal", "beach", "sugar", "clouds", "starwood", "moon", "snow"
    ]

    static func destinations(_ engine: GoobyEngine) -> [PlaceDef] {
        let wanted = Set(destinationIDs)
        return engine.catalog.places.filter { wanted.contains($0.id) }
    }

    static func ticket(_ engine: GoobyEngine, place: PlaceDef) -> ItemDef? {
        engine.catalog.itemsByID["ticket-\(place.id)"]
    }

    /// What `buy` will charge. A free starter place stays at zero.
    static func cost(_ engine: GoobyEngine, place: PlaceDef) -> Int {
        guard place.ticketPrice > 0, let ticket = ticket(engine, place: place) else {
            return max(0, place.ticketPrice)
        }
        return max(0, engine.price(of: ticket))
    }

    static func rarityKey(_ engine: GoobyEngine, place: PlaceDef) -> String {
        ticket(engine, place: place)?.rarity ?? "common"
    }

    static func canDepart(_ engine: GoobyEngine) -> Bool {
        engine.todaysRun() == nil && engine.wallet.energy >= engine.profile.energyGoal
    }

    static func action(_ engine: GoobyEngine, place: PlaceDef) -> TravelDeskAction {
        let price = cost(engine, place: place)
        if !engine.isPlaceUnlocked(place.id), price > 0 {
            return canDepart(engine) ? .buyAndGo(cost: price) : .buy(cost: price)
        }
        if engine.todaysRun() != nil { return .wait }
        return .go
    }
}

enum TravelDeskAction: Equatable {
    case buyAndGo(cost: Int)
    case buy(cost: Int)
    case go
    case wait
}

struct TravelSpark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xFFE7AD))
            TravelSparkShape()
                .fill(Color(hex: 0xE3A31B))
                .padding(6)
        }
        .accessibilityHidden(true)
    }
}

struct TravelSparkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.38
        var path = Path()
        for index in 0..<8 {
            let angle = (Double(index) * .pi / 4) - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
