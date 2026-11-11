import Observation
import SwiftUI
import UIKit

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }
    var titleKey: String { "theme.mode.\(rawValue)" }
}

/// The chosen looks. Screens read colors through `Paint`, which reads `active`, so a change redraws them.
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    private(set) var active: AppTheme
    private(set) var mode: AppearanceMode
    private(set) var lightID: String
    private(set) var darkID: String
    private(set) var previewID: String?
    private(set) var matchIcon: Bool
    private(set) var iconName: String?
    @ObservationIgnored private var systemDark: Bool

    private enum Keys {
        static let mode = "theme.mode"
        static let light = "theme.light"
        static let dark = "theme.dark"
        static let matchIcon = "theme.matchIcon"
    }

    private init() {
        let defaults = UserDefaults.standard
        let storedMode = AppearanceMode(rawValue: defaults.string(forKey: Keys.mode) ?? "") ?? .light
        let light = AppTheme.lightLooks.first { $0.id == defaults.string(forKey: Keys.light) } ?? AppTheme.classic
        let dark = AppTheme.darkLooks.first { $0.id == defaults.string(forKey: Keys.dark) } ?? AppTheme.night
        let systemDark = Self.systemIsDark()
        mode = storedMode
        lightID = light.id
        darkID = dark.id
        previewID = nil
        matchIcon = defaults.bool(forKey: Keys.matchIcon)
        iconName = nil
        self.systemDark = systemDark
        active = Self.resolve(mode: storedMode, light: light, dark: dark, preview: nil, systemDark: systemDark)
    }

    var light: AppTheme { AppTheme.find(lightID) ?? AppTheme.classic }
    var dark: AppTheme { AppTheme.find(darkID) ?? AppTheme.night }

    func isChosen(_ theme: AppTheme) -> Bool {
        theme.isDark ? theme.id == darkID : theme.id == lightID
    }

    /// A tapped look is on screen even though the device scheme would show the other one.
    var isPreviewing: Bool {
        guard let previewID else { return false }
        return Self.resolve(mode: mode, light: light, dark: dark, preview: nil, systemDark: systemDark).id != previewID
    }

    func setMode(_ newMode: AppearanceMode) {
        mode = newMode
        previewID = nil
        UserDefaults.standard.set(newMode.rawValue, forKey: Keys.mode)
        refresh()
        if matchIcon { applyIcon(for: active) }
    }

    /// Stores a look and shows it at once, including when the device scheme would show the other one.
    func choose(_ theme: AppTheme) {
        if theme.isDark {
            darkID = theme.id
            UserDefaults.standard.set(theme.id, forKey: Keys.dark)
        } else {
            lightID = theme.id
            UserDefaults.standard.set(theme.id, forKey: Keys.light)
        }
        if mode != .system {
            mode = theme.isDark ? .dark : .light
            UserDefaults.standard.set(mode.rawValue, forKey: Keys.mode)
        }
        previewID = theme.id
        refresh()
        if matchIcon { applyIcon(for: theme) }
    }

    func endPreview() {
        guard previewID != nil else { return }
        previewID = nil
        refresh()
    }

    func systemChanged() {
        systemDark = Self.systemIsDark()
        refresh()
    }

    func setMatchIcon(_ on: Bool) {
        matchIcon = on
        UserDefaults.standard.set(on, forKey: Keys.matchIcon)
        if on { applyIcon(for: active) }
    }

    func readIcon() {
        iconName = UIApplication.shared.alternateIconName
    }

    func applyIcon(for theme: AppTheme) {
        setIcon(theme.icon)
    }

    func setIcon(_ name: String?) {
        let app = UIApplication.shared
        guard app.supportsAlternateIcons, app.alternateIconName != name else { return }
        app.setAlternateIconName(name) { [weak self] error in
            guard error == nil else { return }
            Task { @MainActor in self?.iconName = name }
        }
    }

    private func refresh() {
        if previewID == nil && mode == .system {
            applyWindowStyle(.unspecified)
            systemDark = Self.systemIsDark()
        }
        let next = Self.resolve(mode: mode, light: light, dark: dark, preview: previewID, systemDark: systemDark)
        if next !== active { active = next }
        if previewID != nil || mode != .system {
            applyWindowStyle(active.isDark ? .dark : .light)
        }
    }

    /// `.preferredColorScheme(nil)` does not reliably hand the window back to the system, so the window style is set here.
    private func applyWindowStyle(_ style: UIUserInterfaceStyle) {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where window.overrideUserInterfaceStyle != style {
                window.overrideUserInterfaceStyle = style
            }
        }
    }

    private static func resolve(mode: AppearanceMode, light: AppTheme, dark: AppTheme, preview: String?, systemDark: Bool) -> AppTheme {
        if let preview = AppTheme.find(preview) { return preview }
        switch mode {
        case .light: return light
        case .dark: return dark
        case .system: return systemDark ? dark : light
        }
    }

    /// The screen trait collection stays on the system setting when a window overrides its style.
    private static func systemIsDark() -> Bool {
        let screens = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }
        if let screen = screens.first {
            return screen.traitCollection.userInterfaceStyle == .dark
        }
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
}
