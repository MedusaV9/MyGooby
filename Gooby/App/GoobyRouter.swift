import Observation
import SwiftUI

/// Deep links (`gooby://<link>`, GoobyShared/GoobyLink.swift) from widgets, Live Activities and
/// notifications. RootView passes opened URLs here; MainTabs takes `pending`, selects the tab or
/// shows the screen over Home, and clears it. A link that arrives before MainTabs exists (lock
/// screen, onboarding) waits until it appears.
@MainActor
@Observable
final class GoobyRouter {
    static let shared = GoobyRouter()

    var pending: GoobyLink?

    func open(_ url: URL) {
        guard let link = GoobyLink(url: url) else { return }
        pending = link
    }

    func open(_ link: GoobyLink) {
        pending = link
    }
}

extension GoobyLink: Identifiable {
    var id: String { rawValue }

    /// The tab a link selects; nil for the screens shown over Home.
    var tab: GoobyTab? {
        switch self {
        case .home: return .home
        case .quests: return .quests
        case .shop: return .shop
        case .friends: return .friends
        case .bag: return .bag
        case .pet: return .pet
        case .adventure, .focus, .breath, .calm: return nil
        }
    }
}

/// The screen a non-tab link opens, inside its own NavigationStack (its back chevron closes it).
struct GoobyLinkedScreen: View {
    var engine: GoobyEngine
    var link: GoobyLink
    var reduceMotion: Bool

    var body: some View {
        NavigationStack {
            switch link {
            case .adventure:
                if let make = FeatureHost.shared.adventuresScreen { make(engine) } else { WorldScreen(engine: engine, reduceMotion: reduceMotion) }
            case .focus:
                FocusTimerView(engine: engine)
            case .breath:
                BreathingView(engine: engine, reduceMotion: reduceMotion)
            default:
                if let make = FeatureHost.shared.calmScreen { make(engine) } else { CalmScreen(engine: engine, reduceMotion: reduceMotion) }
            }
        }
    }
}
