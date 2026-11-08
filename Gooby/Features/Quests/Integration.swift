import SwiftUI

@objc(QuestsIntegration)
final class QuestsIntegration: NSObject {
    @objc class func register() {
        MainActor.assumeIsolated {
            FeatureHost.shared.questsScreen = { engine in
                AnyView(QuestsJourneyScreen(engine: engine))
            }
        }
    }
}
