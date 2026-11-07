import SwiftUI

/// Preview of the widgets and the Live Activity with the current save, because the simulator
/// cannot place widgets on the home screen from CI. Reached from the developer menu (section
/// "Extras") and the `widgets` screenshot route. The views come from GoobyShared, the same code
/// the widget extension draws.
struct ExtrasGallery: View {
    var engine: GoobyEngine
    /// True when shown as a full-screen cover (close button), false when pushed (back chevron).
    var presented = false

    var body: some View {
        MenuScroll(spacing: 14) {
            MenuSectionHeader(text: engine.tx("extras.gallery.widgets", de: "Widgets", en: "Widgets"))
            GoobyWidgetGallery(snapshot: GoobyWidgetBridge.shared.makeSnapshot(engine))
            MenuFootnote(text: bridgeNote)
            MenuSectionHeader(text: engine.tx("extras.gallery.activities", de: "Live-Aktivitäten", en: "Live Activities"))
            GoobyActivityGallery(samples: GoobyLiveActivities.shared.previewSamples(engine))
        }
        .menuChrome(engine, title: engine.tx("extras.gallery.title", de: "Widgets & Live-Aktivitäten", en: "Widgets & Live Activities"), close: presented)
    }

    private var bridgeNote: String {
        if GoobyAppGroup.isAvailable {
            return engine.tx("extras.gallery.bridgeOn", de: "Die Widgets zeigen deine Ziele, Energie und Abenteuer von diesem iPhone.", en: "The widgets show your goals, energy and adventures from this iPhone.")
        }
        return engine.tx("extras.gallery.bridgeOff", de: "Diese Installation hat keine App-Gruppe. Die Widgets zeigen deshalb Gooby mit Gruß und Datum (rechts). Deine Daten erscheinen, wenn du die App mit der App-Gruppe „group.app.mygooby.gooby“ signierst.", en: "This install has no App Group, so the widgets show Gooby with a greeting and the date (right). Your data appears once you sign the app with the App Group \"group.app.mygooby.gooby\".")
    }
}

/// Developer menu section "Extras" (FeatureHost.devSections), registered once by MomentHub.
@MainActor
enum ExtrasDevTools {
    private static var registered = false

    static func register() {
        guard !registered else { return }
        registered = true
        FeatureHost.shared.devSections.append(("dev.extras", { engine in AnyView(ExtrasDevSection(engine: engine)) }))
    }
}

struct ExtrasDevSection: View {
    var engine: GoobyEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink {
                ExtrasGallery(engine: engine)
            } label: {
                Text(engine.tx("extras.dev.gallery", de: "Widgets und Live-Aktivitäten ansehen", en: "Preview widgets and Live Activities"))
            }
            .menuKeyButton(expand: true)
            Button(engine.tx("extras.dev.refresh", de: "Widgets jetzt aktualisieren", en: "Refresh widgets now")) {
                GoobyWidgetBridge.shared.write(engine)
            }
            .menuKeyButton(expand: true)
        }
    }
}
