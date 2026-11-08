import Foundation

/// Deep links into the app, `gooby://<link>`. Widgets (`widgetURL`, `Link`), Live Activities and
/// notifications open them; the app registers the `gooby` scheme (Gooby/Info.plist) and routes
/// them in `GoobyRouter` (Gooby/App/GoobyRouter.swift): the six tabs select their tab, the other
/// links open the screen on top of Home.
enum GoobyLink: String, CaseIterable, Codable, Sendable {
    case home, quests, shop, friends, bag, pet
    /// World map with today's adventure.
    case adventure
    /// Focus timer, breathing exercise, activities list.
    case focus, breath, calm

    static let scheme = "gooby"

    var url: URL {
        // The raw values are lowercase ASCII, so the URL is always valid.
        URL(string: "\(GoobyLink.scheme)://\(rawValue)")!
    }

    init?(url: URL) {
        guard url.scheme?.lowercased() == GoobyLink.scheme,
              let host = url.host?.lowercased(),
              let link = GoobyLink(rawValue: host) else { return nil }
        self = link
    }
}
