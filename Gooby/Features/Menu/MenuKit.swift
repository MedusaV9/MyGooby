import SwiftUI

// Building blocks of the menu slice (hamburger menu, settings and the self-care screens reached
// from them): screenshot-reference.md sections 9 and 10.

// Colors live in `Theme.Tab.menu` (Gooby/Design/Theme.swift).

// MARK: - Chrome

/// Own top row (the system bar is hidden): back chevron or close circle on the left, the title
/// centered, an optional trailing control. `dismiss` pops a pushed screen or closes a sheet.
struct MenuChrome<Trailing: View>: ViewModifier {
    var engine: GoobyEngine
    var title: String
    var close: Bool
    var background: Color
    var trailing: Trailing
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                ZStack {
                    Text(title)
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 64)
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        if close {
                            CloseCircleButton(label: engine.t("kit.close")) { dismiss() }
                        } else {
                            BackChevronButton(label: engine.t("kit.back")) { dismiss() }
                        }
                        Spacer()
                        trailing
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 52)
                .background(background.ignoresSafeArea(edges: .top))
            }
            .background(background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
    }
}

extension View {
    func menuChrome(_ engine: GoobyEngine, title: String, close: Bool = false, background: Color = Theme.Tab.menu.bg) -> some View {
        modifier(MenuChrome(engine: engine, title: title, close: close, background: background, trailing: EmptyView()))
    }

    func menuChrome<Trailing: View>(
        _ engine: GoobyEngine,
        title: String,
        close: Bool = false,
        background: Color = Theme.Tab.menu.bg,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        modifier(MenuChrome(engine: engine, title: title, close: close, background: background, trailing: trailing()))
    }
}

/// Scrolling column with the reference margins.
struct MenuScroll<Content: View>: View {
    var spacing: CGFloat
    var content: Content

    init(spacing: CGFloat = Theme.Space.gap, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
            .padding(.horizontal, Theme.Space.margin)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Grouped lists (screen I)

/// Type of the menu lists: row titles are 16 pt bold rounded (reference I), Dynamic Type keeps
/// working through the text style.
enum MenuFonts {
    static let rowTitle = Font.system(.callout, design: .rounded, weight: .bold)
    static let tileTitle = Font.system(.callout, design: .rounded, weight: .heavy)
}

/// Grouped white card, radius 18, rows stacked without gaps.
struct MenuListGroup<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity)
        .background(Color.white, in: shape)
        .clipShape(shape)
        .cardShadow()
    }
}

/// Hairline separator inset past the row icon.
struct MenuListDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: 0xE3E6EA))
            .frame(height: 0.75)
            .padding(.leading, 58)
            .accessibilityHidden(true)
    }
}

/// Icon (~28) or a custom leading view, bold dark grey label, optional grey subtitle, trailing
/// control. Height >= 56.
struct MenuListRow<Trailing: View>: View {
    var icon: String
    var title: String
    var subtitle: String?
    var titleColor: Color
    var leading: AnyView?
    var trailing: Trailing

    init(icon: String, title: String, subtitle: String? = nil, titleColor: Color = Theme.text, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.leading = nil
        self.trailing = trailing()
    }

    /// Row with a drawn leading view instead of an emoji (Gooby's head on the profile row).
    init<Leading: View>(leading: Leading, title: String, subtitle: String? = nil, titleColor: Color = Theme.text, @ViewBuilder trailing: () -> Trailing) {
        self.icon = ""
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.leading = AnyView(leading)
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 14) {
            MenuRowText(icon: icon, title: title, subtitle: subtitle, titleColor: titleColor, leading: leading)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

extension MenuListRow where Trailing == MenuChevron {
    /// Row with the grey chevron (navigation).
    init(icon: String, title: String, subtitle: String? = nil, titleColor: Color = Theme.text) {
        self.init(icon: icon, title: title, subtitle: subtitle, titleColor: titleColor) { MenuChevron() }
    }

    /// Row with a drawn leading view and the grey chevron.
    init<Leading: View>(leading: Leading, title: String, subtitle: String? = nil, titleColor: Color = Theme.text) {
        self.init(leading: leading, title: title, subtitle: subtitle, titleColor: titleColor) { MenuChevron() }
    }
}

/// Icon and texts of a row; also the label of toggle rows.
struct MenuRowText: View {
    var icon: String
    var title: String
    var subtitle: String?
    var titleColor: Color = Theme.text
    var leading: AnyView? = nil

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let leading {
                    leading
                } else {
                    GoobyIcon(icon, size: 28)
                }
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MenuFonts.rowTitle)
                    .foregroundStyle(titleColor)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// Gooby's head as a list icon (settings profile row, reference I "Profile (pet head)").
struct MenuGoobyHead: View {
    var engine: GoobyEngine
    var size: CGFloat = 30

    var body: some View {
        GoobyAvatar(look: engine.wornLook(), stage: Growth.stage(of: engine.pet), size: size)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Row with an iOS switch; the whole row is the toggle's label.
struct MenuToggleRow: View {
    var icon: String
    var title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: Binding(get: { isOn }, set: { value in
            isOn = value
            MomentHub.shared.emit(.toggled(on: value))
        })) {
            MenuRowText(icon: icon, title: title, subtitle: subtitle)
        }
        .tint(Theme.checkGreen)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .frame(minHeight: 56)
    }
}

struct MenuChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 15, weight: .heavy))
            .foregroundStyle(Color(hex: 0xB4B9C1))
            .accessibilityHidden(true)
    }
}

/// Row highlight while pressed (navigation and action rows).
struct MenuRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Theme.Tab.menu.rowPressed : Color.clear)
            .animation(.easeOut(duration: configuration.isPressed ? 0.05 : 0.25), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, down in
                if down { MomentHub.shared.emit(.tap) }
            }
    }
}

/// Press feedback of the menu tiles and banners: the card dips to 96 % and dims a little (the
/// scale only without reduced motion) and emits the tap moment for the sound effects.
struct MenuTilePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    func makeBody(configuration: Configuration) -> some View {
        let reduce = systemReduce || appReduce
        let pressed = configuration.isPressed
        configuration.label
            .brightness(pressed ? -0.03 : 0)
            .scaleEffect(!reduce && pressed ? 0.96 : 1)
            .animation(reduce ? nil : (pressed ? .easeOut(duration: 0.08) : .spring(response: 0.3, dampingFraction: 0.6)), value: pressed)
            .onChange(of: pressed) { _, down in
                if down { MomentHub.shared.emit(.tap) }
            }
    }
}

/// Caps header placed above a group, with the small inset of the reference.
struct MenuSectionHeader: View {
    var text: String

    var body: some View {
        SectionCaps(text)
            .padding(.top, 10)
            .padding(.bottom, -4)
    }
}

/// Small grey footnote under a group.
struct MenuFootnote: View {
    var text: String

    var body: some View {
        Text(text)
            .font(Theme.Fonts.caption)
            .foregroundStyle(Theme.capsGrey)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6)
    }
}

// MARK: - Tiles and fields

/// Menu grid tile (reference J): white, radius 16, ~62 high, icon on the left and a bold label.
struct MenuTile: View {
    var icon: String
    var title: String
    var leading: AnyView? = nil

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        HStack(spacing: 10) {
            Group {
                if let leading {
                    leading
                } else {
                    GoobyIcon(icon, size: 32)
                }
            }
            .frame(width: 34, height: 34)
            Text(title)
                .font(MenuFonts.tileTitle)
                .foregroundStyle(Theme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 62)
        .background(Color.white, in: shape)
        .cardShadow()
        .contentShape(shape)
    }
}

/// Colored banner of the menu (reference J "Add the widget"): art on the left, a white bold
/// title and subtitle, and a white chunky pill on the right in the banner's color.
struct MenuBanner<Art: View>: View {
    var color: Color
    var edge: Color
    var title: String
    var subtitle: String
    var button: String
    var action: () -> Void
    var art: Art

    init(color: Color, edge: Color, title: String, subtitle: String, button: String, action: @escaping () -> Void, @ViewBuilder art: () -> Art) {
        self.color = color
        self.edge = edge
        self.title = title
        self.subtitle = subtitle
        self.button = button
        self.action = action
        self.art = art()
    }

    var body: some View {
        HStack(spacing: 12) {
            art
                .frame(width: 62, height: 62)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Button(action: action) {
                Text(button)
                    .foregroundStyle(color)
                    .lineLimit(1)
            }
            .buttonStyle(Press3DButtonStyle(fill: .white, edge: edge, radius: 16, depth: 4, horizontal: 16, vertical: 8))
        }
        .padding(.leading, 12)
        .padding(.trailing, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .cardShadow()
    }
}

/// Card with a colored icon square, a title, a subtitle and a circle chevron.
struct MenuLinkCard: View {
    var icon: String
    var color: Color
    var title: String
    var subtitle: String

    var body: some View {
        GCard {
            HStack(spacing: 14) {
                IconTile(color: color, size: 52) {
                    GoobyIcon(icon, size: 34)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.Fonts.headline)
                        .foregroundStyle(Theme.text)
                    Text(subtitle)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.greyText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                CircleChevron(fill: Theme.keyFace)
            }
        }
    }
}

/// Selectable pill (patterns, feelings, prompts).
struct MenuChip: View {
    var title: String
    var icon: String?
    var selected: Bool
    var tint: Color = Theme.Tab.menu.banner
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    @Environment(\.goobyReduceMotion) private var appReduce

    var body: some View {
        Button {
            MomentHub.shared.emit(.tap)
            goobyAnimate(systemReduce || appReduce, .easeOut(duration: 0.18)) { action() }
        } label: {
            HStack(spacing: 6) {
                if let icon { GoobyIcon(icon, size: 20) }
                Text(title)
                    .font(Theme.Fonts.body)
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? Color.white : Theme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? tint : Color.white, in: Capsule())
            .overlay(Capsule().stroke(selected ? Color.clear : Theme.line, lineWidth: 1.5))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .goobyPop(on: selected, amount: 1.08)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Text field on a white rounded card.
struct MenuField: View {
    var placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .font(Theme.Fonts.button)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .cardShadow()
    }
}

extension View {
    /// Primary 3D button: purple face with white text, full width.
    func menuPrimaryButton(fill: Color = Theme.Tab.menu.banner, ink: Color = .white) -> some View {
        buttonStyle(Press3DButtonStyle(fill: fill, edge: nil, radius: 18, horizontal: 18, vertical: 14, expand: true))
            .foregroundStyle(ink)
    }

    /// Light grey 3D key (secondary actions, developer tools).
    func menuKeyButton(expand: Bool = false, ink: Color = Theme.text) -> some View {
        buttonStyle(Press3DButtonStyle(radius: 12, depth: 3, horizontal: 12, vertical: 8, expand: expand))
            .foregroundStyle(ink)
    }
}

/// Emoji for the mood levels 1...5 and the feeling tags.
enum MenuMoodArt {
    static func face(_ level: Int) -> String {
        switch level {
        case 1: return "😣"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        default: return "😄"
        }
    }

    static func tag(_ id: String) -> String {
        switch id {
        case "happy": return "😊"
        case "sad": return "😢"
        case "tired": return "😴"
        case "stressed": return "😖"
        case "grateful": return "🙏"
        case "motivated": return "💪"
        case "overwhelmed": return "🤯"
        case "calm": return "😌"
        default: return "💭"
        }
    }

    static let tagIDs = ["happy", "sad", "tired", "stressed", "grateful", "motivated", "overwhelmed", "calm"]
}
