import SwiftUI

@objc(BagIntegration)
final class BagIntegration: NSObject {
    /// The shell does not call this yet. The bag screen is `BagScreen`.
    @MainActor
    @objc class func register() {}

    @MainActor
    static func screen(_ engine: GoobyEngine, reduceMotion: Bool) -> AnyView {
        AnyView(BagScreen(engine: engine, reduceMotion: reduceMotion))
    }
}
