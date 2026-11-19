import SwiftUI

/// Large art shrinks and fades into a slim bar as `offset` grows from 0 to the
/// travel distance. Callers snap `offset` for Reduce Motion; this view does not
/// add its own animation, so a snapped value jumps and a live value tracks the finger.
struct CollapsingHeader<Art: View, Bar: View, Chrome: View>: View {
    var offset: CGFloat
    var expandedHeight: CGFloat
    var collapsedHeight: CGFloat
    var plate: Color
    var artAlignment: Alignment
    var shrinkAnchor: UnitPoint
    var barAlignment: Alignment
    var chromeAlignment: Alignment
    private let art: Art
    private let bar: Bar
    private let chrome: Chrome

    init(
        offset: CGFloat,
        expandedHeight: CGFloat,
        collapsedHeight: CGFloat,
        plate: Color,
        artAlignment: Alignment = .top,
        shrinkAnchor: UnitPoint = .top,
        barAlignment: Alignment = .top,
        chromeAlignment: Alignment = .top,
        @ViewBuilder art: () -> Art,
        @ViewBuilder bar: () -> Bar,
        @ViewBuilder chrome: () -> Chrome
    ) {
        self.offset = offset
        self.expandedHeight = expandedHeight
        self.collapsedHeight = collapsedHeight
        self.plate = plate
        self.artAlignment = artAlignment
        self.shrinkAnchor = shrinkAnchor
        self.barAlignment = barAlignment
        self.chromeAlignment = chromeAlignment
        self.art = art()
        self.bar = bar()
        self.chrome = chrome()
    }

    private var span: CGFloat { max(expandedHeight - collapsedHeight, 1) }
    private var shown: CGFloat { min(max(offset / span, 0), 1) }
    private var currentHeight: CGFloat { expandedHeight - span * shown }
    private var artOpacity: CGFloat { min(1, max(0, 1 - shown / 0.82)) }
    private var barOpacity: CGFloat { min(1, max(0, (shown - 0.18) / 0.82)) }
    private var pinAlignment: Alignment { shrinkAnchor == .center ? .center : .top }

    var body: some View {
        ZStack(alignment: chromeAlignment) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: currentHeight)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .background {
                    plate
                        .frame(maxWidth: .infinity)
                        .frame(height: currentHeight)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .overlay {
                    art
                        .frame(maxWidth: .infinity)
                        .frame(height: expandedHeight, alignment: artAlignment)
                        .scaleEffect(1 - 0.62 * shown, anchor: shrinkAnchor)
                        .opacity(artOpacity)
                        .frame(maxWidth: .infinity)
                        .frame(height: currentHeight, alignment: pinAlignment)
                        .allowsHitTesting(false)
                        .accessibilityHidden(shown >= 0.5)
                }
                .overlay(alignment: barAlignment) {
                    bar
                        .opacity(barOpacity)
                        .allowsHitTesting(false)
                        .accessibilityHidden(shown < 0.5)
                }
                .clipped()
            chrome
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: currentHeight, alignment: .top)
    }
}

/// Scroll view whose first region is a `CollapsingHeader`. The header overlay
/// does not take drags; only `chrome` keeps its own controls.
struct CollapsingHeaderScroll<Art: View, Bar: View, Chrome: View, Content: View>: View {
    var expandedHeight: CGFloat
    var collapsedHeight: CGFloat
    var reduceMotion: Bool
    var showsIndicators: Bool
    var plate: Color
    var artAlignment: Alignment
    var shrinkAnchor: UnitPoint
    var barAlignment: Alignment
    var chromeAlignment: Alignment
    private let art: Art
    private let bar: Bar
    private let chrome: Chrome
    private let content: Content

    @State private var offset: CGFloat = 0

    init(
        expandedHeight: CGFloat,
        collapsedHeight: CGFloat,
        reduceMotion: Bool,
        showsIndicators: Bool = true,
        plate: Color,
        artAlignment: Alignment = .top,
        shrinkAnchor: UnitPoint = .top,
        barAlignment: Alignment = .top,
        chromeAlignment: Alignment = .top,
        @ViewBuilder art: () -> Art,
        @ViewBuilder bar: () -> Bar,
        @ViewBuilder chrome: () -> Chrome,
        @ViewBuilder content: () -> Content
    ) {
        self.expandedHeight = expandedHeight
        self.collapsedHeight = collapsedHeight
        self.reduceMotion = reduceMotion
        self.showsIndicators = showsIndicators
        self.plate = plate
        self.artAlignment = artAlignment
        self.shrinkAnchor = shrinkAnchor
        self.barAlignment = barAlignment
        self.chromeAlignment = chromeAlignment
        self.art = art()
        self.bar = bar()
        self.chrome = chrome()
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical, showsIndicators: showsIndicators) {
                VStack(spacing: 0) {
                    GoobyScrollProbe()
                    Color.clear
                        .frame(height: expandedHeight)
                        .accessibilityHidden(true)
                    content
                }
            }
            .goobyCollapsingOffset(
                travel: expandedHeight - collapsedHeight,
                reduceMotion: reduceMotion,
                offset: $offset
            )

            CollapsingHeader(
                offset: offset,
                expandedHeight: expandedHeight,
                collapsedHeight: collapsedHeight,
                plate: plate,
                artAlignment: artAlignment,
                shrinkAnchor: shrinkAnchor,
                barAlignment: barAlignment,
                chromeAlignment: chromeAlignment,
                art: { art },
                bar: { bar },
                chrome: { chrome }
            )
        }
    }
}

extension CollapsingHeaderScroll where Chrome == EmptyView {
    init(
        expandedHeight: CGFloat,
        collapsedHeight: CGFloat,
        reduceMotion: Bool,
        showsIndicators: Bool = true,
        plate: Color,
        artAlignment: Alignment = .top,
        shrinkAnchor: UnitPoint = .top,
        barAlignment: Alignment = .top,
        @ViewBuilder art: () -> Art,
        @ViewBuilder bar: () -> Bar,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            reduceMotion: reduceMotion,
            showsIndicators: showsIndicators,
            plate: plate,
            artAlignment: artAlignment,
            shrinkAnchor: shrinkAnchor,
            barAlignment: barAlignment,
            chromeAlignment: .top,
            art: art,
            bar: bar,
            chrome: { EmptyView() },
            content: content
        )
    }
}

enum CollapsingMotion {
    /// Distance the header has collapsed. Reduce Motion returns only the two ends,
    /// with a gap in the middle so the value cannot flicker on the threshold.
    static func distance(raw: CGFloat, previous: CGFloat, travel: CGFloat, reduceMotion: Bool) -> CGFloat {
        let span = max(travel, 1)
        let clamped = min(max(raw, 0), span)
        guard reduceMotion else { return clamped }
        let collapsed = previous >= span * 0.5
        if collapsed {
            return clamped <= span * 0.32 ? 0 : span
        }
        return clamped >= span * 0.68 ? span : 0
    }
}

extension View {
    func goobyCollapsingOffset(travel: CGFloat, reduceMotion: Bool, offset: Binding<CGFloat>) -> some View {
        modifier(GoobyCollapsingOffsetModifier(travel: travel, reduceMotion: reduceMotion, offset: offset))
    }
}

/// Reads how far the scroll view has moved. iOS 18 uses `onScrollGeometryChange`.
/// Earlier systems use a zero-height probe inside the scroll content.
private struct GoobyCollapsingOffsetModifier: ViewModifier {
    var travel: CGFloat
    var reduceMotion: Bool
    @Binding var offset: CGFloat
    @Environment(\.accessibilityReduceMotion) private var systemReduce

    private var calm: Bool { reduceMotion || systemReduce }

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geometry in
                max(0, geometry.contentOffset.y + geometry.contentInsets.top)
            } action: { _, newValue in
                publish(newValue)
            }
        } else {
            content
                .coordinateSpace(name: GoobyScrollSpace.name)
                .onPreferenceChange(GoobyScrollOffsetKey.self) { value in
                    DispatchQueue.main.async { publish(value) }
                }
        }
    }

    private func publish(_ raw: CGFloat) {
        let next = CollapsingMotion.distance(raw: raw, previous: offset, travel: travel, reduceMotion: calm)
        let stepped = calm ? next : (next * 2).rounded() / 2
        guard abs(stepped - offset) >= 0.01 else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { offset = stepped }
    }
}

struct GoobyScrollProbe: View {
    var body: some View {
        if #available(iOS 18, *) {
            Color.clear
                .frame(height: 0)
                .accessibilityHidden(true)
        } else {
            Color.clear
                .frame(height: 0)
                .accessibilityHidden(true)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: GoobyScrollOffsetKey.self,
                            value: max(0, -proxy.frame(in: .named(GoobyScrollSpace.name)).minY)
                        )
                    }
                }
        }
    }
}

private enum GoobyScrollSpace {
    static let name = "goobyCollapsingScroll"
}

private struct GoobyScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
