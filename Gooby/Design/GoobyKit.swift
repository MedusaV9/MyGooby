import SwiftUI

// Shared components for the reference look (screenshot-reference.md, "Cross-screen style").
// Every component takes its action as a closure; icon-only buttons take a localized `label`
// for VoiceOver.
// Top-bar buttons (HamburgerButton, GearButton, BackChevronButton, CloseCircleButton) belong in
// the screen's own top row, e.g. `.safeAreaInset(edge: .top)` plus
// `.toolbar(.hidden, for: .navigationBar)`: inside `.toolbar` iOS 26 wraps them in a glass bubble.

// MARK: - Strings

extension GoobyEngine {
    /// Localized text for `key`, with the German and English text inline.
    /// The l10n tables win once the key exists there; until then the inline text is used, so a
    /// screen can add strings without editing the shared l10n JSON files.
    func tx(_ key: String, de: String, en: String) -> String {
        let value = t(key)
        if value != key { return value }
        return languageCode == "en" ? en : de
    }

    /// `tx` with `String(format:)` arguments, like `tf`.
    func txf(_ key: String, de: String, en: String, _ args: CVarArg...) -> String {
        String(format: tx(key, de: de, en: en), locale: Locale(identifier: languageCode), arguments: args)
    }
}

// MARK: - Cards

/// White card, radius 22, padding 16, very light shadow.
struct GCard<Content: View>: View {
    var fill: Color
    var padding: CGFloat
    var radius: CGFloat
    var content: Content

    init(fill: Color = .white, padding: CGFloat = Theme.Space.inner, radius: CGFloat = Theme.Radius.card, @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.padding = padding
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .cardShadow()
    }
}

/// Desk-calendar card: cream body, 5 binding tabs above the top edge and an optional darker
/// stand below it with bold white text and a circle chevron.
struct NotebookCard<Content: View>: View {
    var tabColor: Color
    var standColor: Color
    var standText: String?
    var onStand: (() -> Void)?
    var content: Content

    init(
        tabColor: Color = Theme.Tab.pet.binding,
        standColor: Color = Theme.Tab.pet.stand,
        standText: String? = nil,
        onStand: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.tabColor = tabColor
        self.standColor = standColor
        self.standText = standText
        self.onStand = onStand
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(Theme.Space.inner)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.notebook, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .overlay(alignment: .top) { bindingTabs.offset(y: -11) }
                .zIndex(1)
            if let standText {
                stand(standText)
            }
        }
        .padding(.top, 11)
    }

    private var bindingTabs: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { _ in
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(tabColor)
                    .frame(width: 16, height: 22)
                    .overlay(alignment: .top) {
                        Capsule().fill(Color.white.opacity(0.22)).frame(width: 8, height: 3).padding(.top, 3)
                    }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func stand(_ text: String) -> some View {
        let row = HStack {
            Text(text)
                .font(Theme.Fonts.headline)
                .foregroundStyle(.white)
            Spacer()
            CircleChevron(color: standColor, fill: .white, size: 26)
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
        .padding(.top, Theme.Radius.card)
        .frame(maxWidth: .infinity)
        .background(standColor, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .padding(.horizontal, 8)
        .padding(.top, -Theme.Radius.card)
        if let onStand {
            Button(action: onStand) { row.contentShape(Rectangle()) }
                .buttonStyle(.plain)
        } else {
            row
        }
    }
}

// MARK: - Buttons

/// Pressable "3D" key: a flat face over a darker bottom edge (`depth` pt). Pressing sinks the
/// face onto the edge; the slight scale only runs when reduce motion is off.
/// `edge: nil` darkens the face color for the edge.
struct Press3DButtonStyle: ButtonStyle {
    var fill: Color = Theme.keyFace
    var edge: Color? = Theme.keyEdge
    var radius: CGFloat = 14
    var depth: CGFloat = 4
    var horizontal: CGFloat = 16
    var vertical: CGFloat = 10
    /// Stretch to the full proposed width.
    var expand: Bool = false
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let pressed = configuration.isPressed
        let reduce = systemReduce || appReduce
        configuration.label
            .font(Theme.Fonts.button)
            .padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
            .frame(maxWidth: expand ? .infinity : nil)
            .background(shape.fill(fill))
            .offset(y: pressed ? depth : 0)
            .background(edgeLayer(shape).offset(y: depth))
            .padding(.bottom, depth)
            .contentShape(shape)
            .opacity(enabled ? 1 : 0.55)
            .scaleEffect(!reduce && pressed ? 0.97 : 1)
            .animation(reduce ? nil : .easeOut(duration: 0.08), value: pressed)
            .onChange(of: pressed) { _, down in
                if down { MomentHub.shared.emit(.tap) }
            }
    }

    @ViewBuilder
    private func edgeLayer(_ shape: RoundedRectangle) -> some View {
        if let edge {
            shape.fill(edge)
        } else {
            shape.fill(fill).overlay(shape.fill(Color.black.opacity(0.18)))
        }
    }
}

/// Goal check button, 52 x 44 with the edge: grey key with a green check, green when done.
/// Checking it pops the key, bounces the check and sends a green ring outwards (masterprompt
/// 6.3, "Aufgaben mit einem Häkchen bestätigen"); with reduced motion it just turns green.
struct CheckButton: View {
    var done: Bool
    var label: String
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce
    /// Counts the checks (not the un-checks) so only checking plays the effects.
    @State private var checks = 0

    var body: some View {
        let reduce = systemReduce || appReduce
        Button(action: action) {
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(done ? Color.white : Theme.checkGreen)
                .symbolEffect(.bounce, value: reduce ? 0 : checks)
                .frame(width: 52, height: 40)
        }
        .buttonStyle(Press3DButtonStyle(
            fill: done ? Theme.checkGreen : Theme.keyFace,
            edge: done ? Theme.checkGreenEdge : Theme.keyEdge,
            radius: 14,
            horizontal: 0,
            vertical: 0
        ))
        .background {
            if !reduce { CheckRing(trigger: checks) }
        }
        .goobyPop(on: checks, amount: 1.12)
        .animation(GoobyMotion.motion(reduce, .easeOut(duration: 0.18)), value: done)
        .onChange(of: done) { _, now in
            if now { checks += 1 }
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(done ? .isSelected : [])
    }
}

private struct CheckRingFrame {
    var scale: CGFloat = 0.9
    var opacity: Double = 0
}

/// Green ring that grows out of the check key and fades.
private struct CheckRing: View {
    var trigger: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Theme.checkGreen, lineWidth: 3)
            .frame(width: 52, height: 44)
            .keyframeAnimator(initialValue: CheckRingFrame(), trigger: trigger) { view, frame in
                view
                    .scaleEffect(frame.scale)
                    .opacity(frame.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(0.95, duration: 0.02)
                    CubicKeyframe(1.5, duration: 0.45)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.8, duration: 0.06)
                    LinearKeyframe(0, duration: 0.41)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Three thick rounded white lines with a soft blue-grey tone.
struct HamburgerButton: View {
    var label: String
    var tint: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(tint).frame(width: 26, height: 5)
                }
            }
            .shadow(color: Color(hex: 0x6F86A6).opacity(0.55), radius: 0, x: 0, y: 1.5)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct GearButton: View {
    var label: String
    var tint: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(tint)
                .shadow(color: Color(hex: 0x6F86A6).opacity(0.55), radius: 0, x: 0, y: 1.5)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// "✕" in a light circle (top-left close on full-screen sheets).
struct CloseCircleButton: View {
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Theme.text.opacity(0.75))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.75), in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Thick dark grey back chevron with a white outline (menu and settings).
struct BackChevronButton: View {
    var label: String
    var tint: Color = Theme.Tab.menu.chevron
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                ChevronLeftShape().stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                ChevronLeftShape().stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 13, height: 22)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct ChevronLeftShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

/// Chevron in a filled circle (streak card, notebook stand, banners). Decorative; wrap it in a
/// Button or put it inside one.
struct CircleChevron: View {
    var color: Color = Theme.greyText
    var fill: Color = .white
    var size: CGFloat = 28
    var symbol: String = "chevron.right"

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42, weight: .heavy))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(fill, in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - Labels and headers

/// Uppercase small bold grey header with letter spacing ("SPECIAL QUESTS", "ACCOUNT").
struct SectionCaps: View {
    var text: String
    var color: Color

    init(_ text: String, color: Color = Theme.capsGrey) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.Fonts.caps)
            .tracking(1.2)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .accessibilityAddTraits(.isHeader)
    }
}

/// White section label with a thin translucent line to the right and an optional "+" in a
/// translucent circle. With `expanded`, the title toggles it and shows a chevron.
struct LineSectionLabel: View {
    var title: String
    var color: Color = .white
    var expanded: Binding<Bool>? = nil
    var addLabel: String = ""
    var onAdd: (() -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    var body: some View {
        HStack(spacing: 10) {
            if let expanded {
                Button {
                    // The rows below unfold or fold away with the chevron.
                    goobyAnimate(systemReduce || appReduce) { expanded.wrappedValue.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Text(title)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .heavy))
                            .rotationEffect(.degrees(expanded.wrappedValue ? 0 : -90))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isHeader)
            } else {
                Text(title).accessibilityAddTraits(.isHeader)
            }
            Rectangle()
                .fill(color.opacity(0.45))
                .frame(height: 1.5)
            if let onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(color)
                        .frame(width: 26, height: 26)
                        .background(color.opacity(0.22), in: Circle())
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(addLabel)
            }
        }
        .font(Theme.Fonts.body)
        .foregroundStyle(color)
    }
}

/// Forked ribbon banner with a white outline and bold white text.
struct RibbonTitle: View {
    var text: String
    var color: Color = Theme.Tab.pet.ribbon

    var body: some View {
        let banner = RoundedRectangle(cornerRadius: 6, style: .continuous)
        Text(text)
            .font(Theme.Fonts.title3)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 20)
            .frame(height: 44)
            .background(banner.fill(color))
            .overlay(banner.stroke(Color.white, lineWidth: 3))
            .padding(.horizontal, 30)
            .background(alignment: .leading) { tail.offset(y: 9) }
            .background(alignment: .trailing) { tail.scaleEffect(x: -1).offset(y: 9) }
            .accessibilityAddTraits(.isHeader)
    }

    private var tail: some View {
        ZStack {
            RibbonTailShape().fill(color)
            RibbonTailShape().fill(Color.black.opacity(0.16))
            RibbonTailShape().stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
        }
        .frame(width: 46, height: 36)
    }
}

/// Ribbon end with a V notch on its outer (left) side.
struct RibbonTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Tiles and progress

/// Colored rounded square (56, radius 14) holding an illustrated glyph.
struct IconTile<Content: View>: View {
    var color: Color
    var size: CGFloat
    var radius: CGFloat
    var content: Content

    init(color: Color, size: CGFloat = 56, radius: CGFloat = Theme.Radius.icon, @ViewBuilder content: () -> Content) {
        self.color = color
        self.size = size
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: size, height: size)
            .background(color, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Light grey track, yellow fill with a lighter highlight stripe, centered bold "a / b".
struct StripedProgressBar: View {
    var value: Int
    var goal: Int
    var height: CGFloat = 24
    var fill: Color = Theme.progressFill
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    var body: some View {
        let shown = min(max(0, value), max(0, goal))
        let fraction = goal > 0 ? Double(shown) / Double(goal) : 0
        let reduce = systemReduce || appReduce
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line)
                if fraction > 0 {
                    Capsule()
                        .fill(fill)
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(Color.white.opacity(0.42))
                                .frame(height: height * 0.2)
                                .padding(.horizontal, height * 0.35)
                                .padding(.top, height * 0.16)
                        }
                        .frame(width: max(height, geo.size.width * fraction))
                        .transition(.opacity)
                }
            }
            // The fill grows to its new length.
            .animation(GoobyMotion.motion(reduce, .spring(response: 0.55, dampingFraction: 0.8)), value: fraction)
        }
        .frame(height: height)
        .overlay {
            Text("\(shown) / \(goal)")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.text)
                .goobyCounter(shown)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue("\(shown) / \(goal)")
    }
}
