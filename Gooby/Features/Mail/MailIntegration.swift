import SwiftUI

@objc(MailIntegration)
final class MailIntegration: NSObject {
    @objc class func register() {
        MainActor.assumeIsolated {
            FeatureHost.shared.mailScreen = { engine in
                AnyView(MailScreen(engine: engine))
            }
            let title = "mail.dev"
            if !FeatureHost.shared.devSections.contains(where: { $0.0 == title }) {
                FeatureHost.shared.devSections.append((title, { engine in
                    AnyView(NavigationLink {
                        MailScreen(engine: engine)
                    } label: {
                        Text(engine.t("mail.open"))
                            .font(.system(.body, design: .rounded))
                    })
                }))
            }
        }
    }
}
