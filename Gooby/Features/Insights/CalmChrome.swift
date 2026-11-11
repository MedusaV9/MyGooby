import SwiftUI

struct CalmPet: View {
    var engine: GoobyEngine
    var animation: GoobyAnimation
    var reduceMotion: Bool
    var scale: CGFloat = 1

    var body: some View {
        GoobyCharacterView(
            look: engine.wornLook(),
            stage: Growth.stage(of: engine.pet),
            animation: animation,
            reduceMotion: reduceMotion,
            companion: nil,
            showCompanion: false
        )
        .scaleEffect(scale, anchor: .bottom)
        .accessibilityHidden(true)
    }
}

struct CalmIconButton: View {
    var symbol: String
    var label: String
    var fill: Color = Color.black.opacity(0.45)
    var ink: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ink)
                .frame(width: 36, height: 36)
                .background(fill, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct CalmSparkPill: View {
    var count: Int
    var label: String

    var body: some View {
        HStack(spacing: 6) {
            if PackArt.image("pack-rainbow-stone") != nil {
                PackImage(name: "pack-rainbow-stone", side: 22)
            } else {
                CalmGem()
                    .frame(width: 22, height: 22)
            }
            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x1C1C1E))
                .contentTransition(.numericText())
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .padding(.vertical, 4)
        .background(Color.white, in: Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 5, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(count)")
    }
}

struct CalmGem: View {
    var body: some View {
        ZStack {
            CalmGemShape().fill(
                LinearGradient(
                    colors: [Color(hex: 0x7C5CFF), Color(hex: 0x3DDCFF), Color(hex: 0xFFE14A), Color(hex: 0xFF7AD9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            CalmGemShape().stroke(Color.white.opacity(0.75), lineWidth: 1)
        }
    }
}

struct CalmGemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.38))
        path.addLine(to: CGPoint(x: width * 0.5, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.38))
        path.closeSubpath()
        return path
    }
}

struct CalmLengthSheet: View {
    var title: String
    var doneTitle: String
    var closeLabel: String
    var options: [Int]
    @Binding var minutes: Int
    var label: (Int) -> String
    var customTitle: String? = nil
    var customRange: ClosedRange<Int>? = nil
    var close: () -> Void
    var done: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: 0x8E8E93))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(closeLabel)
                Spacer()
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1C1C1E))
                Spacer()
                Color.clear.frame(width: 32, height: 32)
            }
            ForEach(options, id: \.self) { option in
                lengthRow(option)
            }
            if let customTitle, let customRange {
                Stepper(value: $minutes, in: customRange) {
                    HStack {
                        Text(customTitle)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x1C1C1E))
                        Spacer()
                        if !options.contains(minutes) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color(hex: 0x34C759))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 56)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(options.contains(minutes) ? Color.clear : Color(hex: 0x34C759), lineWidth: 2)
                )
            }
            Button(action: done) {
                Text(doneTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color(hex: 0x3DDC78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .padding(.bottom, 6)
        .background(Color(hex: 0xF3F4F6), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func lengthRow(_ option: Int) -> some View {
        let picked = minutes == option
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) { minutes = option }
            GoobyFeedback.play(.select)
        } label: {
            HStack {
                Text(label(option))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                if picked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: 0x34C759))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(Color(hex: 0x1C1C1E))
            .padding(.horizontal, 16)
            .frame(height: 58)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(picked ? Color(hex: 0x34C759) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(picked ? .isSelected : AccessibilityTraits())
    }
}

struct CalmDimSheet<Content: View>: View {
    var close: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture(perform: close)
            content()
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct CalmConfetti: View {
    var start: Date
    var still: Bool
    @State private var settled = false

    var body: some View {
        TimelineView(.animation(minimumInterval: still ? 1 : 1.0 / 30.0, paused: still || settled)) { timeline in
            let time = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                guard time < 2.1 else { return }
                let colors = [
                    Color(hex: 0xFF5A7A), Color(hex: 0xFFC83D), Color(hex: 0x3DDCFF),
                    Color(hex: 0x7C5CFF), Color(hex: 0x3DDC78), Color(hex: 0xFF8A3D)
                ]
                let stamp = PackArt.image("pack-confetti")?.cgImage
                for index in 0..<24 {
                    let seed = Double(index) + 1
                    let column = unit(sin(seed * 12.9898) * 43758.5453)
                    let delay = seed * 0.028
                    let local = max(0, time - delay)
                    let x = size.width * (0.08 + 0.84 * column)
                    let y = -16 + local * (150 + seed * 9)
                    let spin = local * (1.4 + unit(seed * 0.37) * 3)
                    let wide = index.isMultiple(of: 3) ? 18.0 : 14.0
                    let piece = CGRect(x: -wide / 2, y: -wide / 2, width: wide, height: wide)
                    var mark = context
                    mark.translateBy(x: x, y: y)
                    mark.rotate(by: .radians(spin))
                    mark.opacity = 1 - max(0, (time - 1.35) / 0.7)
                    if let stamp {
                        mark.draw(Image(decorative: stamp, scale: 1), in: piece)
                    } else {
                        let chip = CGRect(x: -5, y: -8, width: index.isMultiple(of: 3) ? 8 : 12, height: index.isMultiple(of: 2) ? 14 : 8)
                        mark.fill(Path(roundedRect: chip, cornerRadius: 2), with: .color(colors[index % colors.count]))
                    }
                }
            }
            .onChange(of: timeline.date) { _, date in
                if date.timeIntervalSince(start) > 2.15 { settled = true }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func unit(_ value: Double) -> Double {
        let whole = value.rounded(.towardZero)
        return abs(value - whole)
    }
}

struct CalmWrap: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let lines = measure(width, subviews)
        let height = lines.reduce(CGFloat(0)) { $0 + $1.height } + spacing * CGFloat(max(0, lines.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let lines = measure(bounds.width, subviews)
        var y = bounds.minY
        for line in lines {
            var x = bounds.minX
            for slot in line.slots {
                subviews[slot.index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: slot.width, height: slot.height)
                )
                x += slot.width + spacing
            }
            y += line.height + spacing
        }
    }

    private struct Slot {
        var index: Int
        var width: CGFloat
        var height: CGFloat
    }

    private struct Line {
        var slots: [Slot]
        var height: CGFloat
    }

    private func measure(_ width: CGFloat, _ subviews: Subviews) -> [Line] {
        var lines: [Line] = []
        var current: [Slot] = []
        var used: CGFloat = 0
        var height: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let gap: CGFloat = current.isEmpty ? 0 : spacing
            if !current.isEmpty, used + gap + size.width > width {
                lines.append(Line(slots: current, height: height))
                current = []
                used = 0
                height = 0
            }
            let lead: CGFloat = current.isEmpty ? 0 : spacing
            current.append(Slot(index: index, width: size.width, height: size.height))
            used += lead + size.width
            height = max(height, size.height)
        }
        if !current.isEmpty { lines.append(Line(slots: current, height: height)) }
        return lines
    }
}
