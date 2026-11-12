import SwiftUI

@objc(ShopIntegration)
final class ShopIntegration: NSObject {
    @objc class func register() {
        MainActor.assumeIsolated {
            FeatureHost.shared.shopScreen = { engine in
                AnyView(MyShopScreen(engine: engine))
            }
            FeatureHost.shared.shopCounter = { engine, floor in
                AnyView(MyShopScreen(engine: engine, floor: floor))
            }
        }
    }
}
