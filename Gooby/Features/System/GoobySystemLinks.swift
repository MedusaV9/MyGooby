import SwiftUI

enum GoobySystemSheet: String, Identifiable {
    case focus, breath, adventure
    var id: String { rawValue }
}

struct GoobySystemLinks: View {
    var engine: GoobyEngine
    var reduceMotion: Bool
    var selectTab: (ShellTab) -> Void
    @State private var sheet: GoobySystemSheet?
    private let router = GoobyLinkRouter.shared

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .onAppear { consume() }
            .onChange(of: router.pending) { _, _ in consume() }
            .sheet(item: $sheet) { item in
                NavigationStack {
                    content(item)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(engine.t("common.done")) { sheet = nil }
                            }
                        }
                }
            }
    }

    @ViewBuilder
    private func content(_ item: GoobySystemSheet) -> some View {
        switch item {
        case .focus: FocusTimerView(engine: engine)
        case .breath: BreathingView(engine: engine, reduceMotion: reduceMotion)
        case .adventure: WorldScreen(engine: engine, reduceMotion: reduceMotion)
        }
    }

    private func consume() {
        router.consumeStoredRoute()
        guard let next = router.pending else { return }
        router.pending = nil
        switch next {
        case .home:
            sheet = nil
            selectTab(.home)
        case .breath:
            sheet = .breath
        case .adventure:
            sheet = .adventure
        case .focus(let minutes):
            if let minutes, engine.currentFocus() == nil {
                engine.focusStart(seconds: max(1, min(90, minutes)) * 60)
            }
            sheet = .focus
        }
    }
}

struct GoobyWidgetSettings: View {
    var engine: GoobyEngine
    @State private var pinned = GoobySystem.shared.goalsPinned

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $pinned) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.t("system.widget.pin"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(engine.t("system.widget.pinBody"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .opacity(0.75)
                }
            }
            .tint(Color(hex: 0xE989B0))
            .onChange(of: pinned) { _, value in GoobySystem.shared.pinGoals(value) }
            if !GoobySystem.shared.liveActivitiesEnabled() {
                note(engine.t("system.widget.liveOff"))
            }
            if !GoobyAppGroup.isAvailable {
                note(engine.t("system.widget.noGroup"))
            }
        }
        .foregroundStyle(Color(hex: 0x3D3656))
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onAppear { pinned = GoobySystem.shared.goalsPinned }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(hex: 0xC9504A))
    }
}
