import SwiftUI

/// Small drawings that show a look with its own colors, independent of the look that is active.
struct ThemeMiniHome: View {
    let theme: AppTheme

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let u = h / 200
            VStack(spacing: 0) {
                scene(width: w, height: h * 0.36, unit: u)
                page(unit: u)
                tabBar(unit: u)
                    .frame(height: h * 0.12)
            }
            .frame(width: w, height: h)
        }
        .accessibilityHidden(true)
    }

    private func scene(width: CGFloat, height: CGFloat, unit u: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x526DB4), Color(hex: 0x8088C2)], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(hex: 0xFECB4E)).frame(width: 12 * u, height: 12 * u)
                .position(x: width * 0.18, y: height * 0.3)
            Ellipse().fill(Color(hex: 0x8FB85A)).frame(width: width * 1.3, height: height * 0.7)
                .position(x: width * 0.4, y: height * 1.02)
            Ellipse().fill(Color(hex: 0x6E9A48)).frame(width: width * 1.1, height: height * 0.55)
                .position(x: width * 0.85, y: height * 1.08)
            MiniPine(color: Color(hex: 0x1E8266)).frame(width: 18 * u, height: 30 * u)
                .position(x: width * 0.82, y: height * 0.62)
            MiniPine(color: Color(hex: 0x40964F)).frame(width: 14 * u, height: 24 * u)
                .position(x: width * 0.7, y: height * 0.7)
            MiniBunny().frame(width: 20 * u, height: 28 * u)
                .position(x: width * 0.42, y: height * 0.72)
        }
        .frame(width: width, height: height)
        .clipped()
        .colorMultiply(theme.color(theme.sceneTint))
        .saturation(theme.sceneSaturation)
        .brightness(theme.sceneBrightness)
    }

    private func page(unit u: CGFloat) -> some View {
        VStack(spacing: 5 * u) {
            RoundedRectangle(cornerRadius: 7 * u, style: .continuous)
                .fill(theme.color(theme.homeDeep))
                .frame(height: 24 * u)
                .overlay(alignment: .leading) {
                    HStack(spacing: 4 * u) {
                        Circle().fill(theme.color(theme.energy)).frame(width: 9 * u, height: 9 * u)
                        Capsule().fill(Color.white.opacity(0.85)).frame(width: 40 * u, height: 4 * u)
                    }
                    .padding(.leading, 6 * u)
                }
            ForEach(0..<2, id: \.self) { index in
                goalRow(done: index == 0, unit: u)
            }
            RoundedRectangle(cornerRadius: 7 * u, style: .continuous)
                .fill(theme.color(theme.homeButton))
                .frame(height: 14 * u)
        }
        .padding(.horizontal, 7 * u)
        .padding(.top, 6 * u)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.color(theme.home))
    }

    private func goalRow(done: Bool, unit u: CGFloat) -> some View {
        HStack(spacing: 5 * u) {
            Circle().fill(theme.color(theme.well)).frame(width: 13 * u, height: 13 * u)
                .overlay(Circle().fill(theme.color(done ? theme.rose : theme.sky)).padding(3 * u))
            VStack(alignment: .leading, spacing: 2 * u) {
                Capsule().fill(theme.color(theme.ink)).frame(width: 34 * u, height: 3.5 * u)
                Capsule().fill(theme.color(theme.inkFaint)).frame(width: 22 * u, height: 2.5 * u)
            }
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 3.5 * u, style: .continuous)
                .fill(theme.color(done ? theme.success : theme.well))
                .frame(width: 13 * u, height: 13 * u)
        }
        .padding(.horizontal, 5 * u)
        .frame(height: 21 * u)
        .background(theme.color(theme.card), in: RoundedRectangle(cornerRadius: 8 * u, style: .continuous))
    }

    private func tabBar(unit u: CGFloat) -> some View {
        HStack(spacing: 3 * u) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 5 * u, style: .continuous)
                    .fill(index == 0 ? theme.color(theme.homePill) : Color.clear)
                    .overlay(Circle().fill(Color.white).frame(width: 7 * u, height: 7 * u))
            }
        }
        .padding(3 * u)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.color(theme.homeBar))
    }
}

struct ThemeMiniSettings: View {
    let theme: AppTheme

    var body: some View {
        GeometryReader { geo in
            let u = geo.size.height / 200
            VStack(alignment: .leading, spacing: 6 * u) {
                Capsule().fill(theme.color(theme.inkSoft)).frame(width: 9 * u, height: 3 * u)
                    .padding(.top, 6 * u)
                card(unit: u) {
                    VStack(alignment: .leading, spacing: 4 * u) {
                        Capsule().fill(theme.color(theme.ink)).frame(width: 46 * u, height: 5 * u)
                        Capsule().fill(theme.color(theme.inkFaint)).frame(width: 28 * u, height: 3 * u)
                    }
                    .padding(7 * u)
                }
                RoundedRectangle(cornerRadius: 7 * u, style: .continuous)
                    .fill(theme.color(theme.accent))
                    .frame(height: 22 * u)
                    .overlay(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.9)).frame(width: 36 * u, height: 4 * u).padding(.leading, 7 * u)
                    }
                HStack(spacing: 5 * u) {
                    ForEach(0..<2, id: \.self) { _ in
                        card(unit: u) {
                            HStack(spacing: 3 * u) {
                                Circle().fill(theme.color(theme.lavender)).frame(width: 9 * u, height: 9 * u)
                                Capsule().fill(theme.color(theme.ink)).frame(height: 3 * u)
                            }
                            .padding(5 * u)
                        }
                    }
                }
                card(unit: u) {
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { index in
                            HStack(spacing: 4 * u) {
                                Circle().fill(theme.color([theme.pink, theme.mint, theme.yellow, theme.peach][index])).frame(width: 9 * u, height: 9 * u)
                                Capsule().fill(theme.color(theme.inkSoft)).frame(width: 36 * u, height: 3 * u)
                                Spacer(minLength: 0)
                                Capsule().fill(theme.color(theme.inkFaint)).frame(width: 3 * u, height: 5 * u)
                            }
                            .frame(height: 15 * u)
                            if index < 3 {
                                Rectangle().fill(theme.color(theme.line)).frame(height: max(0.5, 0.8 * u))
                            }
                        }
                    }
                    .padding(.horizontal, 6 * u)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7 * u)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .background(theme.color(theme.settings))
        }
        .accessibilityHidden(true)
    }

    private func card<Content: View>(unit u: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.color(theme.card), in: RoundedRectangle(cornerRadius: 7 * u, style: .continuous))
    }
}

struct ThemeSwatches: View {
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array([theme.page, theme.home, theme.accent, theme.rose, theme.energy].enumerated()), id: \.offset) { _, hex in
                Circle()
                    .fill(theme.color(hex))
                    .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                    .frame(width: 14, height: 14)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A drawn stand-in for an alternate app icon. Icon sets cannot be loaded as images at runtime.
struct ThemeIconBadge: View {
    let theme: AppTheme

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let side = geo.size.width
                    let colors = ThemeIconBadge.background(theme.id)
                    ZStack {
                        LinearGradient(colors: [Color(hex: colors.top), Color(hex: colors.bottom)], startPoint: .top, endPoint: .bottom)
                        MiniBunny(outline: ThemeIconBadge.outline(theme.id).map { Color(hex: $0) })
                            .frame(width: side * 0.56, height: side * 0.78)
                            .offset(y: side * 0.06)
                    }
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: side * 0.225, style: .continuous))
                }
            }
            .accessibilityHidden(true)
    }

    /// Kept in step with Tools/make_theme_icons.py.
    static func background(_ id: String) -> (top: UInt32, bottom: UInt32) {
        switch id {
        case "cream": return (0xF8F1E6, 0xE3D6F3)
        case "forest": return (0xA8D095, 0x4E8A4C)
        case "sakura": return (0xFFE6EE, 0xF2A7C1)
        case "ocean": return (0xC4E8F6, 0x3A93BA)
        case "honey": return (0xFFE9AE, 0xF0A43A)
        case "contrast": return (0xFFD60A, 0xFFC300)
        case "night": return (0x2E3D6E, 0x17152A)
        case "firefly": return (0x2A5A3B, 0x101A14)
        case "contrastDark": return (0x1A1A1A, 0x000000)
        default: return (0xFFD6E7, 0xFFD6E7)
        }
    }

    static func outline(_ id: String) -> UInt32? {
        switch id {
        case "contrast": return 0x000000
        case "contrastDark": return 0xFFD60A
        default: return nil
        }
    }
}

struct MiniBunny: View {
    var outline: Color? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                if let outline {
                    shape(w: w, h: h, fur: outline, ear: outline, grow: max(1.5, w * 0.05))
                }
                shape(w: w, h: h, fur: HomePalette.fur, ear: HomePalette.innerEar, grow: 0)
                Circle().fill(HomePalette.eye).frame(width: w * 0.1, height: w * 0.1).position(x: w * 0.38, y: h * 0.6)
                Circle().fill(HomePalette.eye).frame(width: w * 0.1, height: w * 0.1).position(x: w * 0.62, y: h * 0.6)
                Ellipse().fill(HomePalette.cheek).frame(width: w * 0.14, height: w * 0.09).position(x: w * 0.27, y: h * 0.69)
                Ellipse().fill(HomePalette.cheek).frame(width: w * 0.14, height: w * 0.09).position(x: w * 0.73, y: h * 0.69)
                Ellipse().fill(HomePalette.nose).frame(width: w * 0.07, height: w * 0.05).position(x: w * 0.5, y: h * 0.68)
            }
        }
    }

    private func shape(w: CGFloat, h: CGFloat, fur: Color, ear: Color, grow g: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(fur).frame(width: w * 0.26 + g * 2, height: h * 0.5 + g * 2).position(x: w * 0.32, y: h * 0.26)
            Ellipse().fill(fur).frame(width: w * 0.26 + g * 2, height: h * 0.5 + g * 2).position(x: w * 0.68, y: h * 0.26)
            if g == 0 {
                Ellipse().fill(ear).frame(width: w * 0.12, height: h * 0.32).position(x: w * 0.32, y: h * 0.27)
                Ellipse().fill(ear).frame(width: w * 0.12, height: h * 0.32).position(x: w * 0.68, y: h * 0.27)
            }
            Ellipse().fill(fur).frame(width: w * 0.9 + g * 2, height: h * 0.58 + g * 2).position(x: w * 0.5, y: h * 0.66)
        }
    }
}

private struct MiniPine: View {
    var color: Color

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: CGPoint(x: w / 2, y: 0))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}
