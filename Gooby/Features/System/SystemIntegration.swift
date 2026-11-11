import SwiftUI

@objc(SystemIntegration)
final class SystemIntegration: NSObject {
    @objc class func register() {
        MainActor.assumeIsolated {
            FeatureHost.shared.appLaunched = {
                GoobySystem.shared.launch()
            }
            FeatureHost.shared.shellEvent = { engine, event in
                GoobySystem.shared.handle(engine, event)
            }
            FeatureHost.shared.shellLinks = { engine, reduceMotion, selectTab in
                AnyView(GoobySystemLinks(engine: engine, reduceMotion: reduceMotion, selectTab: selectTab))
            }
            FeatureHost.shared.widgetSettings = { engine in
                AnyView(GoobyWidgetSettings(engine: engine))
            }
        }
    }
}
