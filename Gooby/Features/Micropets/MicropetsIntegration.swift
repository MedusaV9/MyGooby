import SwiftUI

@objc(MicropetsIntegration)
final class MicropetsIntegration: NSObject {
    @objc class func register() {
        MainActor.assumeIsolated {
            FeatureHost.shared.micropetsScreen = { engine in
                AnyView(MicropetsScreen(engine: engine))
            }
            let title = "micropets.dev"
            if !FeatureHost.shared.devSections.contains(where: { $0.0 == title }) {
                FeatureHost.shared.devSections.append((title, { engine in
                    AnyView(NavigationLink {
                        MicropetsScreen(engine: engine)
                    } label: {
                        Text(engine.t("micropets.open"))
                            .font(.system(.body, design: .rounded))
                    })
                }))
            }
        }
    }
}
