import SwiftUI

// The shell looks up this exact class name and calls register().
@objc(CompanionsIntegration)
final class CompanionsIntegration: NSObject {
    @objc class func register() {
        MainActor.assumeIsolated {
            FeatureHost.shared.companionsScreen = { engine in
                AnyView(FriendsTreeScreen(engine: engine))
            }
        }
    }
}
