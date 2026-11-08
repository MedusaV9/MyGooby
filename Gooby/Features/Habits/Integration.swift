import SwiftUI

@objc(HabitsIntegration)
final class HabitsIntegration: NSObject {
    @objc class func register() {
        MainActor.assumeIsolated {
            FeatureHost.shared.habitsScreen = { engine in
                AnyView(GoalListScreen(engine: engine))
            }
        }
    }
}
