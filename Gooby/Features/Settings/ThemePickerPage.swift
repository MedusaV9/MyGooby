import SwiftUI
import UIKit

struct ThemePickerPage: View {
    var engine: GoobyEngine
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let iconColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    @State private var iconNote = ""

    private var animation: Animation? {
        systemReduce || engine.reduceMotion ? nil : .easeInOut(duration: 0.35)
    }

    var body: some View {
        let store = ThemeStore.shared
        LookScreen(back: engine.t("look.back")) {
            VStack(alignment: .leading, spacing: 0) {
                Text(engine.t("theme.title"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Look.ink)
                Text(engine.t("theme.lead"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.row)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                preview(store)
                    .padding(.top, 16)
                LookSectionTitle(text: engine.t("theme.mode"))
                modePicker(store)
                Text(engine.t("theme.mode.note"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.sub)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                LookSectionTitle(text: engine.t("theme.lightSection"))
                grid(AppTheme.lightLooks, store)
                LookSectionTitle(text: engine.t("theme.darkSection"))
                grid(AppTheme.darkLooks, store)
                LookSectionTitle(text: engine.t("theme.icon"))
                iconCard(store)
            }
        }
        .onAppear { store.readIcon() }
        .onDisappear { store.endPreview() }
    }

    private func preview(_ store: ThemeStore) -> some View {
        let theme = store.active
        return VStack(spacing: 10) {
            HStack(spacing: 16) {
                phone { ThemeMiniHome(theme: theme) }
                phone { ThemeMiniSettings(theme: theme) }
            }
            .frame(height: 220)
            Text(engine.t(theme.nameKey))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Look.ink)
            if store.isPreviewing {
                Text(engine.t(theme.isDark ? "theme.preview.dark" : "theme.preview.light"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Look.sub)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Look.card, in: RoundedRectangle(cornerRadius: Look.groupRadius, style: .continuous))
        .shadow(color: Look.shadow, radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }

    private func phone<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        Color.clear
            .aspectRatio(0.52, contentMode: .fit)
            .overlay { content() }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Look.ink.opacity(0.14), lineWidth: 2))
    }

    private func modePicker(_ store: ThemeStore) -> some View {
        HStack(spacing: 6) {
            ForEach(AppearanceMode.allCases) { mode in
                let on = store.mode == mode
                Button {
                    withAnimation(animation) { store.setMode(mode) }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: symbol(mode))
                            .font(.system(size: 18, weight: .semibold))
                        Text(engine.t(mode.titleKey))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(on ? Color.white : Look.row)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(on ? Look.plus : Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(engine.t(mode.titleKey))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(6)
        .background(Look.card, in: RoundedRectangle(cornerRadius: Look.groupRadius, style: .continuous))
        .shadow(color: Look.shadow, radius: 10, y: 4)
    }

    private func symbol(_ mode: AppearanceMode) -> String {
        switch mode {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    private func grid(_ looks: [AppTheme], _ store: ThemeStore) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(looks) { theme in
                tile(theme, store)
            }
        }
    }

    private func tile(_ theme: AppTheme, _ store: ThemeStore) -> some View {
        let chosen = store.isChosen(theme)
        return Button {
            withAnimation(animation) { store.choose(theme) }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ThemeMiniHome(theme: theme)
                    .frame(height: 122)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                HStack(spacing: 6) {
                    Text(engine.t(theme.nameKey))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Look.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    if chosen {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Look.plus)
                    }
                }
                ThemeSwatches(theme: theme)
            }
            .padding(10)
            .background(Look.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(chosen ? Look.plus : Color.clear, lineWidth: 3))
            .shadow(color: Look.shadow, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(engine.t(theme.nameKey))
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    private func iconCard(_ store: ThemeStore) -> some View {
        LookCard {
            VStack(alignment: .leading, spacing: 0) {
                LookNavRow(title: engine.t("theme.icon.match"), subtitle: engine.t("theme.icon.matchSub"), showsChevron: false)
                    .padding(.trailing, 58)
                    .overlay(alignment: .trailing) {
                        LookSwitch(isOn: Binding(get: { store.matchIcon }, set: { store.setMatchIcon($0) }), label: engine.t("theme.icon.match"))
                            .padding(.trailing, 14)
                    }
                Rectangle().fill(Look.line).frame(height: 1)
                if UIApplication.shared.supportsAlternateIcons {
                    LazyVGrid(columns: iconColumns, spacing: 12) {
                        ForEach(AppTheme.all) { theme in
                            iconButton(theme, store)
                        }
                    }
                    .padding(14)
                } else {
                    Text(engine.t("theme.icon.unsupported"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.sub)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                }
                if !iconNote.isEmpty {
                    Text(iconNote)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Look.row)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 14)
                }
            }
        }
    }

    private func chooseIcon(_ name: String?) {
        let app = UIApplication.shared
        let store = ThemeStore.shared
        guard app.supportsAlternateIcons else {
            iconNote = engine.t("theme.icon.unsupported")
            return
        }
        if app.alternateIconName == name {
            store.readIcon()
            iconNote = ""
            return
        }
        app.setAlternateIconName(name) { error in
            let failed = error != nil
            Task { @MainActor in
                if failed {
                    iconNote = engine.t("settings.icon.kept")
                } else {
                    iconNote = ""
                    store.readIcon()
                }
            }
        }
    }

    private func iconButton(_ theme: AppTheme, _ store: ThemeStore) -> some View {
        let selected = store.iconName == theme.icon
        return Button {
            chooseIcon(theme.icon)
        } label: {
            VStack(spacing: 5) {
                ThemeIconBadge(theme: theme)
                    .padding(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Look.plus : Color.clear, lineWidth: 3)
                    )
                Text(engine.t(theme.nameKey))
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Look.row)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.06 : 1)
        .animation(systemReduce || engine.reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.68), value: selected)
        .accessibilityLabel(engine.t(theme.nameKey))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
