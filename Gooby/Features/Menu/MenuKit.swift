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

// MARK: - Grouped lists (screen 10)

/// Grouped white card, radius 20, rows stacked without gaps.
struct MenuListGroup<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
        .cardShadow()
    }
}

/// Thin separator inset past the row icon.
struct MenuListDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.line)
            .frame(height: 1)
            .padding(.leading, 60)
            .accessibilityHidden(true)
    }
}

/// Icon (~30), bold dark grey label, optional grey subtitle, trailing control. Height >= 60.
struct MenuListRow<Trailing: View>: View {
    var icon: String
    var title: String
    var subtitle: String?
    var titleColor: Color
    var trailing: Trailing

    init(icon: String, title: String, subtitle: String? = nil, titleColor: Color = Theme.text, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 14) {
            MenuRowText(icon: icon, title: title, subtitle: subtitle, titleColor: titleColor)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }
}

extension MenuListRow where Trailing == MenuChevron {
    /// Row with the grey chevron (navigation).
    init(icon: String, title: String, subtitle: String? = nil, titleColor: Color = Theme.text) {
        self.init(icon: icon, title: title, subtitle: subtitle, titleColor: titleColor) { MenuChevron() }
    }
}

/// Icon and texts of a row; also the label of toggle rows.
struct MenuRowText: View {
    var icon: String
    var title: String
    var subtitle: String?
    var titleColor: Color = Theme.text

    var body: some View {
        HStack(spacing: 14) {
            GoobyIcon(icon, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Fonts.headline)
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

/// Row with an iOS switch; the whole row is the toggle's label.
struct MenuToggleRow: View {
    var icon: String
    var title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            MenuRowText(icon: icon, title: title, subtitle: subtitle)
        }
        .tint(Theme.checkGreen)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 60)
    }
}

struct MenuChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 15, weight: .heavy))
            .foregroundStyle(Theme.greyText.opacity(0.75))
            .accessibilityHidden(true)
    }
}

/// Row highlight while pressed (navigation and action rows).
struct MenuRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Theme.Tab.menu.rowPressed : Color.clear)
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

/// Menu grid tile (screen 9): white, radius 20, ~76 high, icon on the left and a bold label.
struct MenuTile: View {
    var icon: String
    var title: String

    var body: some View {
        HStack(spacing: 10) {
            GoobyIcon(icon, size: 34)
            Text(title)
                .font(Theme.Fonts.headline)
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
        .cardShadow()
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
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

    var body: some View {
        Button(action: action) {
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
