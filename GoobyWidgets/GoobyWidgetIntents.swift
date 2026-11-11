import AppIntents
import WidgetKit

struct GoobyToggleGoalIntent: AppIntent {
    static let title: LocalizedStringResource = "Ziel abhaken"
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Ziel")
    var habitID: String

    init() {
        habitID = ""
    }

    init(habitID: String) {
        self.habitID = habitID
    }

    func perform() async throws -> some IntentResult {
        guard !habitID.isEmpty, GoobySharedStore.toggleGoal(habitID) != nil else { return .result() }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
