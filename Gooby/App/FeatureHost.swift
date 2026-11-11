import ObjectiveC
import SwiftUI

// Sibling feature modules replace these closures from an @objc Integration class.
// Register must only assign closures. The shell already has a working screen for each one.
// Expected class names: AdventuresIntegration, ShopIntegration, RoomIntegration,
// WardrobeIntegration, HabitsIntegration, MoodIntegration, JournalIntegration,
// CalmIntegration, EventsIntegration, QuestsIntegration, CompanionsIntegration, SystemIntegration.
// Each exposes `@objc(Name) class Name: NSObject { @objc class func register() }`.

@MainActor
final class FeatureHost {
    static let shared = FeatureHost()

    var habitsScreen: ((GoobyEngine) -> AnyView)?
    var moodScreen: ((GoobyEngine) -> AnyView)?
    var journalScreen: ((GoobyEngine) -> AnyView)?
    var calmScreen: ((GoobyEngine) -> AnyView)?
    var adventuresScreen: ((GoobyEngine) -> AnyView)?
    var shopScreen: ((GoobyEngine) -> AnyView)?
    var wardrobeScreen: ((GoobyEngine) -> AnyView)?
    var roomScreen: ((GoobyEngine) -> AnyView)?
    var eventsScreen: ((GoobyEngine) -> AnyView)?
    var questsScreen: ((GoobyEngine) -> AnyView)?
    var companionsScreen: ((GoobyEngine) -> AnyView)?
    var devSections: [(String, (GoobyEngine) -> AnyView)] = []

    // System features follow the shell through these. Register may only assign closures.
    var appLaunched: (() -> Void)?
    var shellEvent: ((GoobyEngine, ShellEvent) -> Void)?
    var shellLinks: ((GoobyEngine, Bool, @escaping (ShellTab) -> Void) -> AnyView)?
    var widgetSettings: ((GoobyEngine) -> AnyView)?
}

enum ShellEvent {
    case booted, saved, active, background
    case breathStarted(pattern: String, seconds: [Int])
    case breathStopped
}

enum ModuleBootstrap {
    @MainActor
    static func boot() {
        let names = [
            "AdventuresIntegration",
            "ShopIntegration",
            "RoomIntegration",
            "WardrobeIntegration",
            "HabitsIntegration",
            "MoodIntegration",
            "JournalIntegration",
            "CalmIntegration",
            "EventsIntegration",
            "QuestsIntegration",
            "CompanionsIntegration",
            "SystemIntegration"
        ]
        for name in names {
            let candidates = [name, "Gooby.\(name)"]
            for candidate in candidates {
                guard let cls = NSClassFromString(candidate) else { continue }
                let selector = NSSelectorFromString("register")
                guard let method = class_getClassMethod(cls, selector) else { continue }
                typealias Register = @convention(c) (AnyClass, Selector) -> Void
                let implementation = method_getImplementation(method)
                let function = unsafeBitCast(implementation, to: Register.self)
                function(cls, selector)
                break
            }
        }
    }
}
