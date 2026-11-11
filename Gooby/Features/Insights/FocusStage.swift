import SwiftUI

struct FocusTimerView: View {
    var engine: GoobyEngine
    var mode: String = "focus"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @State private var modeID = "focus"
    @State private var primed = false
    @State private var minutes = 10
    @State private var showLengths = false
    @State private var showInfo = false
    @State private var finished = false
    @State private var stopped = false
    @State private var burst: Date?

    private var still: Bool { systemReduce || engine.reduceMotion }
    private var focusing: Bool { modeID != "meditate" }
    private var canvas: UInt32 { focusing ? 0xFFF3D6 : 0xE7E0FA }
    private var ringTint: Color { Color(hex: focusing ? 0xE39A1A : 0x7A6AD4) }
    private var live: FocusSession? { engine.currentFocus() }
    private var inSession: Bool { finished || live != nil }

    var body: some View {
        ZStack {
            Color(hex: canvas).ignoresSafeArea()
            TimelineView(.animation(minimumInterval: still ? 0.5 : 1.0 / 30.0, paused: live?.runningSince == nil && !finished)) { timeline in
                let _ = timeline.date
                if inSession {
                    session
                } else {
                    intro
                }
            }
            if showLengths {
                CalmDimSheet(close: { setLengths(false) }) {
                    CalmLengthSheet(
                        title: engine.t("calm.breath.length"),
                        doneTitle: engine.t("common.done"),
                        closeLabel: engine.t("common.close"),
                        options: [5, 10, 15, 25, 45, 60],
                        minutes: $minutes,
                        label: { engine.tf("calm.breath.minutes", $0) },
                        customTitle: engine.tf("calm.focus.custom", minutes),
                        customRange: 1...90,
                        close: { setLengths(false) },
                        done: { setLengths(false) }
                    )
                }
            } else if showInfo {
                CalmDimSheet(close: { setInfo(false) }) {
                    infoCard
                }
            }
            if let burst, !still {
                CalmConfetti(start: burst, still: still)
            }
        }
        .animation(still ? nil : .easeInOut(duration: 0.35), value: modeID)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            guard !primed else { return }
            primed = true
            modeID = mode == "meditate" ? "meditate" : "focus"
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000)
                let wasLive = engine.currentFocus() != nil
                engine.reconcileFocus()
                if wasLive && engine.currentFocus() == nil && !stopped && !finished {
                    finishRound()
                }
            }
        }
    }

    private var intro: some View {
        VStack(spacing: 16) {
            topBar
            modeMenu
            Text(engine.t(focusing ? "calm.focus.detail" : "calm.focus.meditate.detail"))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x5C6570))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            lengthPill
            Spacer(minLength: 0)
            PackImage(name: focusing ? "pack-stopwatch" : "pack-lotus", side: 84)
            ZStack {
                Circle().fill(Color.white.opacity(0.45)).frame(width: 260, height: 260)
                CalmPet(engine: engine, animation: focusing ? .read : .sit, reduceMotion: still)
                    .frame(width: 280, height: 280)
            }
            .frame(height: 280)
            Button(action: begin) {
                Text(engine.t("common.start"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1C1C1E))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private var session: some View {
        let planned = max(60, live?.plannedSeconds ?? minutes * 60)
        let remain = finished ? 0 : engine.focusRemaining()
        let fraction = min(1, max(0, 1 - Double(remain) / Double(planned)))
        return VStack(spacing: 18) {
            topBar
            Spacer(minLength: 0)
            PackImage(name: focusing ? "pack-stopwatch" : "pack-lotus", side: 56)
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.62), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: CGFloat(finished ? 1 : fraction))
                    .stroke(ringTint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 6) {
                    Text(clock(remain))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x1C1C1E))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    if finished {
                        Text(engine.t("calm.focus.done"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(ringTint)
                    } else if live?.runningSince == nil {
                        Text(engine.t("common.pause"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x8E8E93))
                    }
                }
            }
            .frame(width: 250, height: 250)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(engine.t("calm.focus.remaining"))
            .accessibilityValue(clock(remain))
            CalmPet(
                engine: engine,
                animation: finished ? .celebrate : (focusing ? .read : .sit),
                reduceMotion: still || live?.runningSince == nil
            )
            .frame(height: 180)
            if !finished {
                HStack(spacing: 28) {
                    Button(action: togglePause) {
                        Image(systemName: live?.runningSince == nil ? "play.fill" : "pause.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color(hex: 0x1C1C1E))
                            .frame(width: 64, height: 48)
                            .background(Color.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(live?.runningSince == nil ? engine.t("common.resume") : engine.t("common.pause"))
                    Button(action: stop) {
                        Text(engine.t("common.stop"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x1C1C1E))
                            .padding(.horizontal, 18)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.7), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private var topBar: some View {
        HStack {
            CalmIconButton(symbol: "xmark", label: engine.t("common.close"), action: { dismiss() })
            Spacer()
            CalmIconButton(
                symbol: "ellipsis",
                label: engine.t("calm.breath.info"),
                fill: Color.white.opacity(0.7),
                ink: Color(hex: 0x1C1C1E),
                action: { setInfo(true) }
            )
            CalmSparkPill(count: engine.wallet.sparks, label: engine.t("calm.breath.sparks"))
        }
        .padding(.top, 8)
    }

    private var modeMenu: some View {
        Menu {
            Button(engine.t("calm.focus.title")) { modeID = "focus" }
            Button(engine.t("calm.focus.meditate")) { modeID = "meditate" }
        } label: {
            Text(engine.t(focusing ? "calm.focus.title" : "calm.focus.meditate"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x1C1C1E))
                .multilineTextAlignment(.center)
        }
        .accessibilityHint(engine.t("calm.focus.pick"))
    }

    private var lengthPill: some View {
        Button {
            setLengths(true)
        } label: {
            HStack(spacing: 6) {
                Text(engine.tf("calm.breath.minutes", minutes))
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold))
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: 0x1C1C1E))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(ringTint.opacity(0.85), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(engine.t("calm.breath.length"))
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(engine.t(focusing ? "calm.focus.title" : "calm.focus.meditate"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1C1C1E))
                Spacer()
                Button(action: { setInfo(false) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: 0x8E8E93))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t("common.close"))
            }
            Text(engine.t(focusing ? "calm.focus.detail" : "calm.focus.meditate.detail"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x5C6570))
            Text(engine.t("focus.rewardHint"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x1C1C1E))
                .fixedSize(horizontal: false, vertical: true)
            Text(engine.t("calm.disclaimer"))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x8E8E93))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color(hex: 0xF3F4F6), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func begin() {
        stopped = false
        finished = false
        burst = nil
        engine.focusStart(seconds: minutes * 60)
    }

    private func togglePause() {
        if live?.runningSince == nil {
            engine.focusResume()
        } else {
            engine.focusPause()
        }
    }

    private func stop() {
        stopped = true
        finished = false
        engine.focusStop()
    }

    private func finishRound() {
        finished = true
        burst = Date()
    }

    private func clock(_ seconds: Int) -> String {
        let safe = max(0, seconds)
        return String(format: "%02d:%02d", safe / 60, safe % 60)
    }

    private func setLengths(_ open: Bool) {
        withAnimation(still ? nil : .spring(response: 0.38, dampingFraction: 0.86)) {
            showInfo = false
            showLengths = open
        }
        if open { GoobyFeedback.play(.sheet) }
    }

    private func setInfo(_ open: Bool) {
        withAnimation(still ? nil : .spring(response: 0.38, dampingFraction: 0.86)) {
            showLengths = false
            showInfo = open
        }
        if open { GoobyFeedback.play(.sheet) }
    }
}
