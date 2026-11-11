import ObjectiveC
import SwiftUI
import UIKit

enum GoobySize {
    static let readableMax: CGFloat = 760
    static let sideRailWidth: CGFloat = 96
    static let glanceRailWidth: CGFloat = 286
    static let sceneBand: CGFloat = 318
    static let regularPadding: CGFloat = 20
    static let compactPadding: CGFloat = 16
    static let formWidth: CGFloat = 560
    static let formHeight: CGFloat = 680

    static func horizontalPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? regularPadding : compactPadding
    }
}

extension View {
    /// On a regular width, keep the column in a readable measure. Compact width stays edge to edge.
    func goobyReadableColumn() -> some View {
        modifier(GoobyReadableColumn())
    }

    /// Sheet content prefers a form on iPad and the system sheet on iPhone.
    func goobyFormSheet() -> some View {
        modifier(GoobyFormSheetModifier())
    }
}

private struct GoobyReadableColumn: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    @ViewBuilder func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .frame(maxWidth: GoobySize.readableMax)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content
        }
    }
}

private struct GoobyFormSheetModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    @ViewBuilder func body(content: Content) -> some View {
        if sizeClass == .regular {
            content.modifier(GoobyRegularFormSizing())
        } else {
            content
        }
    }
}

private struct GoobyRegularFormSizing: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.presentationSizing(.form)
        } else {
            content
        }
    }
}

enum GoobySheetForm {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        let original = #selector(UIViewController.present(_:animated:completion:))
        let swapped = #selector(UIViewController.gooby_present(_:animated:completion:))
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, original),
              let swappedMethod = class_getInstanceMethod(UIViewController.self, swapped) else { return }
        method_exchangeImplementations(originalMethod, swappedMethod)
        installed = true
    }

    static func adapt(_ presenter: UIViewController, _ presented: UIViewController) {
        guard regularWidth(presenter), shouldAdapt(presented) else { return }
        presented.modalPresentationStyle = .formSheet
        if presented.preferredContentSize == .zero {
            presented.preferredContentSize = CGSize(width: GoobySize.formWidth, height: GoobySize.formHeight)
        }
    }

    private static func regularWidth(_ presenter: UIViewController) -> Bool {
        if presenter.traitCollection.horizontalSizeClass == .regular { return true }
        if presenter.traitCollection.horizontalSizeClass == .compact { return false }
        if let window = presenter.viewIfLoaded?.window {
            if window.traitCollection.horizontalSizeClass == .regular { return true }
            if window.traitCollection.horizontalSizeClass == .compact { return false }
        }
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    private static func shouldAdapt(_ presented: UIViewController) -> Bool {
        let name = NSStringFromClass(type(of: presented))
        let blocked = ["UIAlert", "UIActivity", "UIDocument", "PHPicker", "UIImagePicker", "QLPreview", "UIPrint", "MFMail"]
        if blocked.contains(where: name.contains) { return false }
        switch presented.modalPresentationStyle {
        case .automatic, .pageSheet:
            return true
        default:
            return false
        }
    }
}

extension UIViewController {
    @objc dynamic func gooby_present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        GoobySheetForm.adapt(self, viewControllerToPresent)
        gooby_present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
