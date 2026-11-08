import SwiftUI

/// In-app preview of every widget at home-screen size, with the current save and in the offline
/// look (no App Group). Shown by ExtrasGallery (developer menu) and the `widgets` screenshot route,
/// because the simulator cannot place widgets on the home screen from CI.
struct GoobyWidgetGallery: View {
    var snapshot: GoobyWidgetSnapshot?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            GoobyWidgetPreviewFrame(width: 158, height: 158) {
                GoobyTodayWidgetView(snapshot: snapshot)
            }
            GoobyWidgetPreviewFrame(width: 158, height: 158) {
                GoobyTodayWidgetView(snapshot: nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A widget-sized rounded card with the system content margins, standing in for the home screen.
struct GoobyWidgetPreviewFrame<Content: View>: View {
    var width: CGFloat
    var height: CGFloat
    var background: Color = GoobyTokens.cream
    var content: Content

    init(width: CGFloat, height: CGFloat, background: Color = GoobyTokens.cream, @ViewBuilder content: () -> Content) {
        self.width = width
        self.height = height
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(width: width, height: height)
            .background(background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
    }
}
