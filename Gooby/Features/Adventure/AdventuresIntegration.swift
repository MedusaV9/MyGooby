import SwiftUI

// The shell looks up this exact class name and calls register().
@objc(AdventuresIntegration)
final class AdventuresIntegration: NSObject {
    @objc class func register() {
        MainActor.assumeIsolated {
            FeatureHost.shared.adventuresScreen = { engine in
                AnyView(AdventureScreen(engine: engine, reduceMotion: engine.reduceMotion))
            }
        }
    }
}
