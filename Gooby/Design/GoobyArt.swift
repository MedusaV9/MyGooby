import SwiftUI

// Flat illustrated icons (reference-screens.md, "Icons inside cards are colorful flat
// illustrations"): layered rounded shapes without outlines, a second tone for shading. Each icon
// is a small list of shapes on a 32 x 32 grid, one shape per line:
//
//   <RRGGBB>[/<alpha>] [S<width>] <command> <numbers...> [@<degrees>[,<cx>,<cy>]]
//
//   c cx cy r                   circle
//   e cx cy rx ry               ellipse
//   r x y w h [radius]          rounded rectangle
//   k cx cy r ratio points      star (inner radius = r * ratio)
//   x cx cy r [pinch]           four-point sparkle with curved sides
//   o cx cy dist r n [start]    n dots of radius r on a circle (petals)
//   p <svg path data>           path: M L H V C Q Z, absolute and relative
//
// `S<width>` strokes the shape with round caps and joins instead of filling it; `@deg` rotates it
// (clockwise) around its own center or around (cx, cy). Shapes paint in order.

/// One painted shape of an icon, in 32 x 32 art units.
struct GoobyArtShape {
    var path: Path
    var color: Color
    /// Stroke width in art units; nil fills the shape.
    var stroke: CGFloat?
}

/// Draws the art icon `name` (a key of `GoobyArt.source`) scaled into its frame.
struct GoobyArtView: View {
    var name: String

    var body: some View {
        let shapes = GoobyArt.parsed[name] ?? []
        Canvas { context, size in
            let scale = min(size.width, size.height) / 32
            context.translateBy(x: (size.width - 32 * scale) / 2, y: (size.height - 32 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            for shape in shapes {
                if let width = shape.stroke {
                    context.stroke(shape.path, with: .color(shape.color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                } else {
                    context.fill(shape.path, with: .color(shape.color))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

enum GoobyArt {
    /// The art drawn for an icon name (art key, SF Symbol name or emoji), or nil.
    static func resolve(_ name: String) -> String? {
        let key = name.replacingOccurrences(of: "\u{FE0F}", with: "")
        if source[key] != nil { return key }
        return alias[key]
    }

    /// All icons, parsed once on first use.
    static let parsed: [String: [GoobyArtShape]] = source.mapValues(GoobyArtParser.parse)

    /// SF Symbol names (stored `Habit.icon` values) and emoji that draw an art icon.
    static let alias: [String: String] = [
        "sparkle": "sparkles",
        "✨": "sparkles",
        "bolt.fill": "bolt",
        "⚡": "bolt",
        "flame.fill": "flame",
        "🔥": "flame",
        "calendar": "art.calendar",
        "📅": "art.calendar",
        "🗓": "art.calendar",
        "🥚": "egg",
        "👕": "tshirt",
        "tshirt.fill": "tshirt",
        "🎒": "backpack",
        "backpack.fill": "backpack",
        "🌿": "leaf.fill",
        "🍃": "leaf.fill",
        "💗": "heart.fill",
        "⏱": "stopwatch",
        "timer": "stopwatch",
        "🗺": "map",
        "map.fill": "map",
        "📋": "clipboard",
        "list.bullet.clipboard": "clipboard",
        "⭐": "star",
        "star.fill": "star",
        "😊": "smiley",
        "face.smiling": "smiley",
        "face.smiling.fill": "smiley",
        "🌬": "wind",
        "🤸": "figure.run"
    ]

    static let source: [String: String] = [
        // MARK: Habit icons (Theme.habitIcons and the editor's extra icons)

        "drop.fill": """
        4AA8F0 p M16 3 C16 3 6.5 13.5 6.5 19.8 C6.5 25 10.8 29 16 29 C21.2 29 25.5 25 25.5 19.8 C25.5 13.5 16 3 16 3 Z
        2F8FE0 p M16 29 C21.2 29 25.5 25 25.5 19.8 C25.5 16.5 22.8 12.2 20.4 9 C21.8 12.4 22.6 15.6 22.6 18.4 C22.6 23.8 19.6 27.6 16 29 Z
        D6EEFF e 11.6 19.8 1.9 3.6 @18
        D6EEFF c 13.2 14.4 1.2
        """,

        "sun.max.fill": """
        5BAA45 S2.6 p M16 18 L16 29.5
        6CBF4E p M16 26.5 C18.5 22.4 23.5 21.6 26 23.2 C23.6 27 19.4 28 16 26.5 Z
        57A83F p M16 25 C13.8 21.6 9.6 20.8 7.4 22.2 C9.4 25.4 13 26.2 16 25 Z
        F9C531 o 16 12.5 7.4 3.3 10
        F2A81F o 16 12.5 5.2 2.4 10 18
        8A5A2E c 16 12.5 4.6
        6E4424 c 16.6 13.1 3.2
        B07A4E c 14.6 11.3 0.9
        B07A4E c 17 10.6 0.7
        B07A4E c 15.4 14.2 0.7
        """,

        "cup.and.saucer.fill": """
        E3D4BC e 16 25.6 12.5 3.4
        F3EADB e 16 25 10 2.3
        F7EFE3 S2.8 p M24.6 15.4 C29.6 15.4 29.6 21.2 23.8 21.2
        F7EFE3 p M5.5 13 L26.5 13 C26.5 20 22.8 24.8 16 24.8 C9.2 24.8 5.5 20 5.5 13 Z
        E8DCC8 p M16 24.8 C22.8 24.8 26.5 20 26.5 13 L23.8 13 C23.8 19.2 20.8 23.4 16 24.8 Z
        8CC152 e 16 13 10.5 2.7
        A8D86B e 13.4 12.6 4.6 1.1
        C4CCD2 S1.6 p M12.5 9.4 C11 7.6 14 6.4 12.5 4.2
        C4CCD2 S1.6 p M18.5 9.4 C17 7.6 20 6.4 18.5 4.2
        """,

        "sparkles": """
        F9C531 x 13 17.5 11.5
        F2A81F x 13 17.5 4 0.3
        FFD95A x 24.8 7.6 5.2
        FFE58A x 24.6 23.6 3.6
        """,

        "figure.walk": """
        D9D9D9 r 3 23.4 26.2 4 2
        F0564F p M4 22.5 C4 16.5 5.6 11.4 8.6 10 L13.2 10 C14 13 16.4 14.8 19.4 15.3 L24.2 16.6 C27.2 17.4 28.8 19.4 28.8 22 L28.8 23 L4 23 Z
        D9403A p M8.6 10 L13.2 10 C12.9 12.3 11.2 13.6 8.8 13.6 Z
        FFFFFF r 3 21.6 26.2 3.6 1.8
        FFB3AE e 25.2 19.4 2.4 1.5
        FFFFFF S1.4 p M12.4 14.2 L15 12.8
        FFFFFF S1.4 p M14.6 16.2 L17.4 14.9
        """,

        "wind": """
        6CBF4E p M11.5 19 C11.5 10.5 17.5 5 28.5 4.5 C28.5 14.5 22.5 19.5 11.5 19 Z
        57A83F p M11.5 19 C17 15.5 22.5 10.5 28.5 4.5 C28.5 14.5 22.5 19.5 11.5 19 Z
        8FD46E S1.2 p M13 17.6 C17.5 14 21.5 10.4 26 6.6
        7CC4EE S2.2 p M3 14.5 L9.5 14.5
        7CC4EE S2.2 p M4.5 20.8 L15.5 20.8 C18.8 20.8 18.8 25.2 15.8 25.2
        7CC4EE S2.2 p M3 26.2 L9 26.2
        """,

        "wind.white": """
        6CBF4E p M11.5 19 C11.5 10.5 17.5 5 28.5 4.5 C28.5 14.5 22.5 19.5 11.5 19 Z
        57A83F p M11.5 19 C17 15.5 22.5 10.5 28.5 4.5 C28.5 14.5 22.5 19.5 11.5 19 Z
        8FD46E S1.2 p M13 17.6 C17.5 14 21.5 10.4 26 6.6
        FFFFFF S2.2 p M3 14.5 L9.5 14.5
        FFFFFF S2.2 p M4.5 20.8 L15.5 20.8 C18.8 20.8 18.8 25.2 15.8 25.2
        FFFFFF S2.2 p M3 26.2 L9 26.2
        """,

        "pencil": """
        F5D3A0 p M5 27 L7.53 19.53 L12.47 24.47 Z
        4A4A4A p M5 27 L6.01 24.01 L7.99 25.99 Z
        F9C531 p M7.53 19.53 L19.03 8.03 L23.97 12.97 L12.47 24.47 Z
        F2A81F p M10 22 L21.5 10.5 L23.97 12.97 L12.47 24.47 Z
        C9CED6 p M19.03 8.03 L21.03 6.03 L25.97 10.97 L23.97 12.97 Z
        F48FA6 S1.6 p M21.03 6.03 L24.03 3.03 L28.97 7.97 L25.97 10.97 Z
        F48FA6 p M21.03 6.03 L24.03 3.03 L28.97 7.97 L25.97 10.97 Z
        """,

        "book.fill": """
        3A6BC9 r 7.5 5.5 19 23.5 3.5
        F7F2E8 r 9 6 16.5 21 2
        4F86E8 r 5.5 4 18.5 23 3.5
        3A6BC9 r 5.5 4 4.5 23 2.2
        FFFFFF/0.85 r 12.5 9 8 4.5 1.6
        """,

        "heart.fill": """
        FF6F91 p M16 28 C16 28 3.5 20.8 3.5 12 C3.5 7.5 7 4.5 11 4.5 C13.3 4.5 15 5.7 16 7.4 C17 5.7 18.7 4.5 21 4.5 C25 4.5 28.5 7.5 28.5 12 C28.5 20.8 16 28 16 28 Z
        F2557A p M16 28 C16 28 28.5 20.8 28.5 12 C28.5 9.6 27.5 7.6 25.9 6.2 C26.4 7.3 26.6 8.5 26.6 9.8 C26.6 18 17.8 25.6 16 28 Z
        FFFFFF/0.6 e 9.8 10.6 2.6 1.6 @-35
        """,

        "leaf.fill": """
        57A83F S2 p M7.5 24.5 L3.8 28.2
        6CBF4E p M6.5 25.5 C6 14 13 5.5 27.5 4.5 C27.5 18.5 19.5 26.5 6.5 25.5 Z
        57A83F p M6.5 25.5 C14 18.5 20.5 11.5 27.5 4.5 C27.5 18.5 19.5 26.5 6.5 25.5 Z
        8FD46E S1.3 p M8 24 C13.5 18.6 19 12.8 25.2 6.8
        """,

        "moon.fill": """
        F9C531 p M18.5 4 C10.6 4.6 5 11 5 18 C5 24.6 10.6 29.5 17.4 29.5 C22 29.5 26 27 28 23 C26.4 23.6 24.6 24 22.8 24 C16.4 24 11.8 19 11.8 13.2 C11.8 9.2 14.4 5.8 18.5 4 Z
        F2A81F p M17.4 29.5 C22 29.5 26 27 28 23 C26.4 23.6 24.6 24 22.8 24 C20.2 24 17.8 23.2 15.9 21.8 C17.2 25 17.8 27.4 17.4 29.5 Z
        F2A81F c 9.6 18.4 1.4
        F2A81F c 12.6 24.4 1
        """,

        "house.fill": """
        C9473F r 20.5 5.5 3.4 7 0.8
        FFE7B8 r 6.5 13.5 19 15 2.2
        F7D79C r 19.5 13.5 6 15 2.2
        E8574F S2.6 p M4 15 L16 4.8 L28 15 Z
        E8574F p M4 15 L16 4.8 L28 15 Z
        A0703F p M13.3 28.5 L13.3 22.5 C13.3 19.4 18.7 19.4 18.7 22.5 L18.7 28.5 Z
        8FD0F5 r 20.4 17.6 3.8 3.8 1
        """,

        "brain.head.profile": """
        F7A8C2 c 11.2 13 6
        F7A8C2 c 20.2 12.4 6.6
        F7A8C2 c 9.8 19.6 5
        F7A8C2 c 16 20.4 6
        F7A8C2 c 22.6 19.2 5.4
        E890AE c 21 21.4 4.2
        E2809F S1.5 p M16 7.4 L16 25.6
        E2809F S1.5 p M11 11.6 C13.4 12.8 13.4 15.4 11.4 16.8
        E2809F S1.5 p M21.4 10.6 C19 12.6 19.4 15.2 21.8 16.2
        FFFFFF/0.55 e 9.6 11 1.8 1.1 @-30
        """,

        "fork.knife": """
        6CBF4E c 10 15.5 4.6
        57A83F c 16 13 5.2
        8FD46E c 21.8 14.8 4.4
        F0564F c 13.2 14.6 2.6
        F0564F c 19.6 12.2 2.2
        F9C531 c 23.4 16.4 1.8
        6FA8E6 p M3.8 16.2 L28.2 16.2 C28.2 23.2 22.8 27.8 16 27.8 C9.2 27.8 3.8 23.2 3.8 16.2 Z
        5A93D6 p M16 27.8 C22.8 27.8 28.2 23.2 28.2 16.2 L25.2 16.2 C25.2 22 21.2 26.4 16 27.8 Z
        9CC6F0 r 3.4 15.4 25.2 2.4 1.2
        """,

        "music.note": """
        8B6BE0 r 11.4 8 2.4 16.4 1
        8B6BE0 r 24.4 5 2.4 16.4 1
        8B6BE0 p M11.4 8 L26.8 5 L26.8 9.8 L11.4 12.8 Z
        8B6BE0 e 9.6 24.2 4.2 3.3 @-20
        8B6BE0 e 22.6 21.2 4.2 3.3 @-20
        B6A0F2 e 8.6 23.2 1.5 0.9 @-20
        B6A0F2 e 21.6 20.2 1.5 0.9 @-20
        """,

        "figure.run": """
        D9D9D9 r 3 23.4 26.2 4 2
        4F86E8 p M4 22.5 C4 16.5 5.6 11.4 8.6 10 L13.2 10 C14 13 16.4 14.8 19.4 15.3 L24.2 16.6 C27.2 17.4 28.8 19.4 28.8 22 L28.8 23 L4 23 Z
        3A6BC9 p M8.6 10 L13.2 10 C12.9 12.3 11.2 13.6 8.8 13.6 Z
        FFFFFF r 3 21.6 26.2 3.6 1.8
        F9C531 p M17 17.4 L21.6 17.4 L19.4 20.6 Z
        FFFFFF S1.4 p M12.4 14.2 L15 12.8
        FFFFFF S1.4 p M14.6 16.2 L17.4 14.9
        B8C4CC S1.8 p M1.5 12.5 L5 12.5
        B8C4CC S1.8 p M1 16.5 L3.5 16.5
        """,

        "bicycle": """
        4A4A4A S2.6 c 8.5 21 5.4
        4A4A4A S2.6 c 23.5 21 5.4
        E8574F S2.2 p M8.5 21 L13.5 12.2 L22 12.2 L23.5 21
        E8574F S2.2 p M13.5 12.2 L16.2 21 L22 12.2
        E8574F S2.2 p M8.5 21 L16.2 21
        4A4A4A r 10.6 9.4 5.4 2.2 1.1
        4A4A4A S2 p M21.4 12.2 L20.6 8.6 L23.6 8.6
        4A4A4A c 8.5 21 1.3
        4A4A4A c 23.5 21 1.3
        """,

        "figure.mind.and.body": """
        6CBF4E e 16 25.4 11 2.4
        F9C6D6 p M16 23.5 C10.5 23.5 4.5 20 3 13.8 C8.4 13.6 13.4 17 16 23.5 Z
        F9C6D6 p M16 23.5 C21.5 23.5 27.5 20 29 13.8 C23.6 13.6 18.6 17 16 23.5 Z
        F48FB1 p M16 23.5 C11.6 21.6 8.4 16.6 9 10.4 C12.8 12 15.4 16.6 16 23.5 Z
        F48FB1 p M16 23.5 C20.4 21.6 23.6 16.6 23 10.4 C19.2 12 16.6 16.6 16 23.5 Z
        F7A8C2 p M16 6 C20.4 10.2 20.6 18 16 23.5 C11.4 18 11.6 10.2 16 6 Z
        FFFFFF/0.5 e 14.6 13 1 2.6
        """,

        "pills.fill": """
        7FB5E8 r 4.5 12.5 23 7 3.5 @-40,16,16
        F0564F r 4.5 12.5 11.5 7 3.5 @-40,16,16
        F0564F r 12 12.5 4 7 0 @-40,16,16
        FFFFFF/0.5 r 7 13.6 6 1.6 0.8 @-40,16,16
        """,

        "shower.fill": """
        B9C0C9 S2.4 p M16 2.8 L16 6.5
        9FB0C2 p M8.5 12 C8.5 7.8 11.8 6 16 6 C20.2 6 23.5 7.8 23.5 12 Z
        7C8FA6 r 7.6 11 16.8 2.6 1.3
        4AA8F0 p M10.5 16 c0 0 -2 2.6 -2 3.8 c0 1.1 0.9 2 2 2 c1.1 0 2 -0.9 2 -2 c0 -1.2 -2 -3.8 -2 -3.8 z
        4AA8F0 p M16 17.5 c0 0 -2 2.6 -2 3.8 c0 1.1 0.9 2 2 2 c1.1 0 2 -0.9 2 -2 c0 -1.2 -2 -3.8 -2 -3.8 z
        4AA8F0 p M21.5 16 c0 0 -2 2.6 -2 3.8 c0 1.1 0.9 2 2 2 c1.1 0 2 -0.9 2 -2 c0 -1.2 -2 -3.8 -2 -3.8 z
        4AA8F0 p M13 23.5 c0 0 -2 2.6 -2 3.8 c0 1.1 0.9 2 2 2 c1.1 0 2 -0.9 2 -2 c0 -1.2 -2 -3.8 -2 -3.8 z
        4AA8F0 p M19 23.5 c0 0 -2 2.6 -2 3.8 c0 1.1 0.9 2 2 2 c1.1 0 2 -0.9 2 -2 c0 -1.2 -2 -3.8 -2 -3.8 z
        """,

        "bathtub.fill": """
        7FC6F0 e 16 28 13 2.4
        F9C531 p M4.5 18.5 C4.5 14.5 8.5 13.2 12.6 14.2 C13.4 10 16.2 7 20.4 7 C24.6 7 27.2 10 27.2 13.6 C27.2 15.6 26.2 17.2 24.6 18.2 C26.6 19.2 27.6 21.2 27 23.2 C26 27.2 21.2 28.6 16 28.6 C8.8 28.6 4.5 24.2 4.5 18.5 Z
        F2A81F p M9.6 20.4 C12.6 18.2 17.8 18.6 19.6 21.2 C17 24.4 11.8 24.4 9.6 20.4 Z
        F28C28 p M26.6 12 L31 13.2 L27 15.6 Z
        3A3A3A c 22.6 11.6 1.3
        CFE9FA c 5.6 9 2
        CFE9FA c 9.4 5.2 1.3
        """,

        "carrot.fill": """
        6CBF4E p M22 9.4 C20.8 5.4 22.4 3 25 2.8 C25.6 5.6 24.6 8.2 22 9.4 Z
        57A83F p M23.6 10.4 C26 7.2 28.6 6.8 30.2 8 C28.8 10.6 26.2 11.4 23.6 10.4 Z
        F28C28 p M6.8 27.4 C5.8 26.4 6.3 24.4 7.8 22.4 L18.8 9.8 C20.8 7.8 24.4 9.2 24.9 11.2 C25.4 13.2 24 14.8 22.4 15.8 L9.4 26.8 C8.7 27.5 7.6 28 6.8 27.4 Z
        D9711A S1.4 p M11.6 21.2 L14.2 22.2
        D9711A S1.4 p M15.4 16.6 L18 17.6
        D9711A S1.4 p M19.4 12.4 L21.2 13.2
        """,

        "paintbrush.fill": """
        C98A4B S3.6 p M27.4 4.6 L15.6 16.4
        C9CED6 S4.6 p M15.8 16.2 L13.4 18.6
        8B6BE0 p M13.8 17 C11 16.8 8 18 7 21.5 C6.3 24 5 26 3.5 27.5 C7.5 28 11.5 27 13.5 24.5 C15 22.8 15.4 20.4 15.2 18.4 Z
        B6A0F2 e 9.4 22.4 1.2 2.2 @40
        """,

        "camera.fill": """
        E2789E r 10 6 8.5 5 2
        F48FB1 r 3.5 9 25 17.5 4.5
        E2789E r 3.5 21 25 5.5 0
        F48FB1 r 3.5 20.5 25 2 0
        FFF3E2 c 16 17.6 6.6
        4A4F63 c 16 17.6 4.8
        7FB5E8 c 16 17.6 2.8
        FFFFFF/0.85 c 14.6 16.2 1.1
        F9C531 r 22.6 11.4 3.6 2.6 1.1
        """,

        "lightbulb.fill": """
        F9C531 p M16 3.5 C10.5 3.5 7 7.5 7 12.5 C7 15.8 8.8 18 10.5 19.8 C11.6 21 12 22 12 23 L20 23 C20 22 20.4 21 21.5 19.8 C23.2 18 25 15.8 25 12.5 C25 7.5 21.5 3.5 16 3.5 Z
        FFF1B0 e 11.8 10.8 2 3.4 @25
        F2A81F S1.4 p M13.5 19.5 L13.5 15.5 L16 17 L18.5 15.5 L18.5 19.5
        B9C0C9 r 11.8 22.6 8.4 3.2 1.2
        9FA8B3 r 12.4 25.6 7.2 2.6 1.2
        7C8592 r 14 28 4 1.8 0.9
        """,

        "graduationcap.fill": """
        5A6075 p M8.5 14.5 L8.5 21 C8.5 24.4 23.5 24.4 23.5 21 L23.5 14.5 L16 18 Z
        4A4F63 S1.4 p M16 5.5 L30 12 L16 18.5 L2 12 Z
        4A4F63 p M16 5.5 L30 12 L16 18.5 L2 12 Z
        6A7189 p M16 7.4 L25.6 12 L16 16.4 L6.4 12 Z
        F9C531 S1.5 p M16 12 L26.6 14.6 L26.6 21.4
        F9C531 r 25 21 3.2 4.2 1.4
        """,

        "birthday.cake.fill": """
        E0E0E0 e 16 27.6 12.5 2
        F7E0C0 r 5.5 15 21 12 3
        F48FB1 p M5.5 18.5 L5.5 17.5 C5.5 15.6 6.9 14.2 8.8 14.2 L23.2 14.2 C25.1 14.2 26.5 15.6 26.5 17.5 L26.5 18.5 C25 18.5 25 20.6 23.4 20.6 C21.8 20.6 21.8 18.5 20.2 18.5 C18.6 18.5 18.6 21.2 17 21.2 C15.4 21.2 15.4 18.5 13.8 18.5 C12.2 18.5 12.2 20.6 10.6 20.6 C9 20.6 9 18.5 7.4 18.5 Z
        7FB5E8 r 14.8 7.4 2.4 7 1
        F9C531 p M16 2.4 C17.6 4 18.2 5.4 16 7 C13.8 5.4 14.4 4 16 2.4 Z
        F0564F c 10 23.6 0.9
        6CBF4E c 15 24.6 0.9
        F9C531 c 20.4 23.4 0.9
        """,

        // MARK: Shell and quest icons

        "art.calendar": """
        D7DCE3 r 4 7.5 24 21.5 4.5
        FFFFFF r 4 6 24 21.5 4.5
        F0564F r 4 6 24 8 4.5
        F0564F r 4 10 24 4 0
        8A8F99 r 9 3.2 2.6 6.2 1.3
        8A8F99 r 20.4 3.2 2.6 6.2 1.3
        D7DCE3 r 8 16.6 4 3.4 1
        D7DCE3 r 14 16.6 4 3.4 1
        F9C531 r 20 16.6 4 3.4 1
        D7DCE3 r 8 21.4 4 3.4 1
        D7DCE3 r 14 21.4 4 3.4 1
        D7DCE3 r 20 21.4 4 3.4 1
        """,

        "clipboard": """
        9A6840 r 5 5.5 22 25 4
        B07A4E r 5 4.5 22 24.5 4
        FFFFFF r 8 8 16 18.5 2
        8A8F99 r 11 2.4 10 5.6 2
        C9CED6 r 12.6 3.4 6.8 3 1.5
        D7DCE3 r 11 12.6 10 1.8 0.9
        D7DCE3 r 11 16.4 7 1.8 0.9
        FFFFFF k 21.2 21.6 6.2 0.5 5
        FFFFFF S1.6 k 21.2 21.6 6.2 0.5 5
        4F86E8 S1 k 21.2 21.6 4.6 0.5 5
        4F86E8 k 21.2 21.6 4.6 0.5 5
        """,

        "clipboard.check": """
        9A6840 r 5 5.5 22 25 4
        B07A4E r 5 4.5 22 24.5 4
        FFFFFF r 8 8 16 18.5 2
        8A8F99 r 11 2.4 10 5.6 2
        C9CED6 r 12.6 3.4 6.8 3 1.5
        D7DCE3 r 11 12.4 10 1.8 0.9
        4CAF50 S3 p M11.4 19.6 L14.6 22.6 L20.8 16.2
        """,

        "bolt": """
        F9C531 S1.6 p M18.5 3 L7.5 18 L14.5 18 L12.5 29 L24.5 12.5 L17.5 12.5 Z
        F9C531 p M18.5 3 L7.5 18 L14.5 18 L12.5 29 L24.5 12.5 L17.5 12.5 Z
        F2A81F p M14.5 18 L12.5 29 L24.5 12.5 L20.6 12.5 L14.8 20.6 Z
        """,

        "flame": """
        F47B4F p M16 3 C17 8 23 10.5 24.5 17 C25.8 23 21.5 28.5 16 28.5 C10.5 28.5 6.5 24.5 7 19 C7.3 15.5 9.5 13.5 11 11.5 C11.5 13.5 12.5 15 14 15.5 C13.5 10.5 14.5 6 16 3 Z
        F9C531 p M16 13 C17.5 16 21 18 21 22.5 C21 25.5 18.8 27.5 16 27.5 C13.2 27.5 11 25.5 11 22.5 C11 19.5 14 17.5 16 13 Z
        FFF1B0 e 16 24.4 2.6 3
        """,

        "star": """
        F9C531 S2 k 16 17 12.5 0.48 5
        F9C531 k 16 17 12.5 0.48 5
        FFE58A e 12.6 13.6 1.6 2.4 @-30
        """,

        "smiley": """
        E9A92B c 16 17 12
        FFD34E c 16 16 12
        FFE58A e 11.4 9.6 3.6 1.8 @-20
        6B4420 e 11.8 14.4 1.6 2.3
        6B4420 e 20.2 14.4 1.6 2.3
        F7A3A3/0.8 e 8.8 19.2 2.2 1.4
        F7A3A3/0.8 e 23.2 19.2 2.2 1.4
        6B4420 S2.2 p M11.6 19.6 C13.8 22.8 18.2 22.8 20.4 19.6
        """,

        "notebook": """
        E2789E r 8 5 18.5 23.5 3.5
        FFF7EF r 9.5 6 15.5 21.5 2
        F48FB1 r 6 4 18.5 23 3.5
        E2789E r 6 4 4.2 23 2
        FFFFFF p M17.4 20.4 C17.4 20.4 12.4 17.4 12.4 14.2 C12.4 12.6 13.6 11.4 15 11.4 C16 11.4 16.9 12 17.4 12.8 C17.9 12 18.8 11.4 19.8 11.4 C21.2 11.4 22.4 12.6 22.4 14.2 C22.4 17.4 17.4 20.4 17.4 20.4 Z
        """,

        "stopwatch": """
        B9C0C9 r 15 5.6 2 3 0
        F0564F r 13.4 3 5.2 3.6 1.4
        B9C0C9 r 23.2 7.6 3.2 3.2 1 @45
        E0E3E8 c 16 18.4 11
        FFFFFF c 16 18.4 9
        D7DCE3 r 15.3 10.6 1.4 2.4 0.7
        D7DCE3 r 15.3 23.8 1.4 2.4 0.7
        D7DCE3 r 8.2 17.7 2.4 1.4 0.7
        D7DCE3 r 21.4 17.7 2.4 1.4 0.7
        F0564F S2 p M16 18.4 L16 12
        3A3A3A S2 p M16 18.4 L19.8 20.6
        3A3A3A c 16 18.4 1.6
        """,

        "backpack": """
        C93A3F S2.4 p M12.5 9 C12.5 4.6 19.5 4.6 19.5 9
        E5484D r 6.5 8 19 21.5 6
        C93A3F p M6.5 15 C6.5 11 9.5 8 13.5 8 L18.5 8 C22.5 8 25.5 11 25.5 15 L25.5 15.5 L6.5 15.5 Z
        F27A7E r 10.2 18.6 11.6 8 3
        E5484D r 10.2 18.6 11.6 2 1
        FFD45E r 14.4 13 3.2 4.4 1
        """,

        "egg": """
        FFF3E2 p M16 3.8 C21.6 3.8 26 12 26 18.6 C26 24.6 21.6 28.6 16 28.6 C10.4 28.6 6 24.6 6 18.6 C6 12 10.4 3.8 16 3.8 Z
        F0DFC4 p M16 28.6 C21.6 28.6 26 24.6 26 18.6 C26 14.6 24.4 10 22 7 C23.2 10.4 23.6 13.6 23.6 16.6 C23.6 22.8 20.4 27 16 28.6 Z
        F7C6A3 c 12 15 2
        F7C6A3 c 19.4 10.8 1.4
        F7C6A3 c 19.6 20 2.4
        F7C6A3 c 12.4 23 1.3
        """,

        "map": """
        F7EFE3 p M4 8 L12 5 L20 8 L28 5 L28 25 L20 28 L12 25 L4 28 Z
        E9DCC8 p M12 5 L20 8 L20 28 L12 25 Z
        9ED36A c 8.4 13 2.6
        8FD0F5 e 23.4 20.6 2.8 2
        F0564F S1.6 p M7.4 22.4 C10 18.6 13.6 20.4 15.6 16.4 C17.4 12.8 21 14 23.2 10.8
        F0564F c 23.4 10.4 2.2
        FFFFFF c 23.4 10.4 0.8
        """,

        "tshirt": """
        5B9BEF S1.4 p M11 5 L6 7.5 L2.5 13 L7 16 L9 14.5 L9 27 C9 27.8 9.7 28.5 10.5 28.5 L21.5 28.5 C22.3 28.5 23 27.8 23 27 L23 14.5 L25 16 L29.5 13 L26 7.5 L21 5 C20 7.2 18.2 8.3 16 8.3 C13.8 8.3 12 7.2 11 5 Z
        5B9BEF p M11 5 L6 7.5 L2.5 13 L7 16 L9 14.5 L9 27 C9 27.8 9.7 28.5 10.5 28.5 L21.5 28.5 C22.3 28.5 23 27.8 23 27 L23 14.5 L25 16 L29.5 13 L26 7.5 L21 5 C20 7.2 18.2 8.3 16 8.3 C13.8 8.3 12 7.2 11 5 Z
        3F80D9 p M11 5 C12 7.2 13.8 8.3 16 8.3 C18.2 8.3 20 7.2 21 5 L19.2 4.6 C18.6 5.8 17.4 6.4 16 6.4 C14.6 6.4 13.4 5.8 12.8 4.6 Z
        FFFFFF/0.9 r 9 17.5 14 2.6 0
        """,

        // MARK: Tab bar

        "tab.home": """
        FFF3E2 e 12.2 6.4 2.2 4.4 @-16
        FFB7CC e 12.3 6.8 1 2.8 @-16
        FFF3E2 e 19.8 6.4 2.2 4.4 @16
        FFB7CC e 19.7 6.8 1 2.8 @16
        FFC94D p M7 15 L25 15 L25 27.4 C25 28.5 24.1 29.4 23 29.4 L9 29.4 C7.9 29.4 7 28.5 7 27.4 Z
        F2B23A p M20.5 15 L25 15 L25 27.4 C25 28.5 24.1 29.4 23 29.4 L20.5 29.4 Z
        F47B4F S1.8 p M3.6 16.6 L16 6.6 L28.4 16.6 Z
        F47B4F p M3.6 16.6 L16 6.6 L28.4 16.6 Z
        E0643C p M16 6.6 L28.4 16.6 L22.4 16.6 Z
        8A5A3C c 16 22.2 3.9
        6E4424 c 16.4 22.6 2.9
        A0703F r 13.4 27 5.2 1.8 0.9
        """,

        "tab.quests": """
        9A6840 r 5 5.5 22 25 4
        B07A4E r 5 4.5 22 24.5 4
        FFFFFF r 8 8 16 18.5 2
        8A8F99 r 11 2.4 10 5.6 2
        C9CED6 r 12.6 3.4 6.8 3 1.5
        D7DCE3 r 11 12.6 10 1.8 0.9
        D7DCE3 r 11 16.4 6 1.8 0.9
        FFFFFF S1.8 k 20.6 21.4 6.6 0.5 5
        FFFFFF k 20.6 21.4 6.6 0.5 5
        4F86E8 S1 k 20.6 21.4 5 0.5 5
        4F86E8 k 20.6 21.4 5 0.5 5
        """,

        "tab.shop": """
        FFF1DC r 5 12 22 17 2.5
        E9D5B8 r 5 12 22 4 0
        8FC1E8 r 8.6 18.4 6.4 10.6 1.6
        5FA3DB r 8.6 18.4 6.4 2 1
        8FC1E8 r 18 18 6 5.4 1.6
        A0703F r 5 27.4 22 1.8 0.9
        C93A3F r 3.6 4.2 24.8 4.6 2.2
        E8574F r 3.6 7 6.2 5 0
        FFFFFF r 9.8 7 6.2 5 0
        E8574F r 16 7 6.2 5 0
        FFFFFF r 22.2 7 6.2 5 0
        E8574F c 6.7 12 3.1
        FFFFFF c 12.9 12 3.1
        E8574F c 19.1 12 3.1
        FFFFFF c 25.3 12 3.1
        """,

        "tab.friends": """
        000000/0.12 e 16 29.4 6.4 1.4
        9A6B43 r 14 18 4 11.4 1.6
        7A5233 r 16.2 18 1.8 11.4 0.9
        2E8B3A c 16.6 14 11
        4CA84A c 15.4 12.8 10
        2E8B3A/0.5 c 21 17.4 3.4
        7BC768 c 11.6 9.2 4.2
        A6DE8C c 10.2 7.6 1.6
        """,

        "tab.bag": """
        7A5233 S2.6 p M3.6 29 L23.4 7
        E5484D p M21.6 11.4 C26.8 11.4 30 16 29.4 21 C28.8 25.8 25 28.4 20.4 28.4 C15.4 28.4 11.8 25.2 12.4 20.2 C13 15.2 16.8 11.4 21.6 11.4 Z
        C93A3F p M20.4 28.4 C25 28.4 28.8 25.8 29.4 21 C29.6 19.4 29.4 17.8 28.8 16.4 C28.4 21.6 25 25.6 19.4 26.4 C17 26.8 14.6 26.2 13 24.8 C14.4 27 17.2 28.4 20.4 28.4 Z
        E5484D p M20.6 12 C18.6 9.4 18.6 6.4 20.4 5 C22 6.8 22.6 9.6 22 12 Z
        E5484D p M23 12.4 C24 9.6 25.8 7.6 28 7.6 C28 10 26.4 12.2 24.2 13 Z
        FFD45E r 18.6 10.8 7.4 2.8 1.4 @8
        F27A7E e 17.6 17.4 2.4 3.2 @25
        """
    ]
}

/// Reads the shape lines of `GoobyArt.source`. Unknown lines are skipped.
enum GoobyArtParser {
    static func parse(_ text: String) -> [GoobyArtShape] {
        text.split(separator: "\n").compactMap { shape(String($0)) }
    }

    private static func shape(_ line: String) -> GoobyArtShape? {
        var words = line.split(separator: " ").map(String.init)
        guard words.count >= 2, !words[0].hasPrefix("#") else { return nil }
        let color = paint(words.removeFirst())
        var stroke: CGFloat?
        if let first = words.first, first.hasPrefix("S"), let width = Double(first.dropFirst()) {
            stroke = CGFloat(width)
            words.removeFirst()
        }
        var degrees: CGFloat = 0
        var pivot: CGPoint?
        if let last = words.last, last.hasPrefix("@") {
            words.removeLast()
            let parts = last.dropFirst().split(separator: ",").compactMap { Double($0) }.map { CGFloat($0) }
            degrees = parts.first ?? 0
            if parts.count >= 3 { pivot = CGPoint(x: parts[1], y: parts[2]) }
        }
        guard !words.isEmpty else { return nil }
        let command = words.removeFirst()
        guard var path = makePath(command, words) else { return nil }
        if degrees != 0 {
            let box = path.boundingRect
            let center = pivot ?? CGPoint(x: box.midX, y: box.midY)
            let turn = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: degrees * .pi / 180)
                .translatedBy(x: -center.x, y: -center.y)
            path = path.applying(turn)
        }
        return GoobyArtShape(path: path, color: color, stroke: stroke)
    }

    /// "RRGGBB" or "RRGGBB/alpha".
    private static func paint(_ word: String) -> Color {
        let parts = word.split(separator: "/")
        let hex = UInt32(parts.first ?? "", radix: 16) ?? 0
        let alpha = parts.count > 1 ? Double(parts[1]) ?? 1 : 1
        return Color(hex: hex).opacity(alpha)
    }

    private static func makePath(_ command: String, _ words: [String]) -> Path? {
        if command == "p" { return svgPath(words.joined(separator: " ")) }
        let n = words.compactMap { Double($0) }.map { CGFloat($0) }
        switch command {
        case "c" where n.count >= 3:
            return Path(ellipseIn: CGRect(x: n[0] - n[2], y: n[1] - n[2], width: n[2] * 2, height: n[2] * 2))
        case "e" where n.count >= 4:
            return Path(ellipseIn: CGRect(x: n[0] - n[2], y: n[1] - n[3], width: n[2] * 2, height: n[3] * 2))
        case "r" where n.count >= 4:
            let radius = n.count >= 5 ? min(n[4], n[2] / 2, n[3] / 2) : 0
            return Path(roundedRect: CGRect(x: n[0], y: n[1], width: n[2], height: n[3]), cornerRadius: radius)
        case "k" where n.count >= 5:
            return star(center: CGPoint(x: n[0], y: n[1]), radius: n[2], ratio: n[3], points: max(2, Int(n[4])))
        case "x" where n.count >= 3:
            return sparkle(center: CGPoint(x: n[0], y: n[1]), radius: n[2], pinch: n.count >= 4 ? n[3] : 0.18)
        case "o" where n.count >= 5:
            var path = Path()
            let count = max(1, Int(n[4]))
            let start = n.count >= 6 ? n[5] : 0
            for index in 0..<count {
                let angle = Double(start + CGFloat(index) * 360 / CGFloat(count) - 90) * Double.pi / 180
                let center = CGPoint(x: n[0] + CGFloat(cos(angle)) * n[2], y: n[1] + CGFloat(sin(angle)) * n[2])
                path.addEllipse(in: CGRect(x: center.x - n[3], y: center.y - n[3], width: n[3] * 2, height: n[3] * 2))
            }
            return path
        default:
            return nil
        }
    }

    private static func star(center: CGPoint, radius: CGFloat, ratio: CGFloat, points: Int) -> Path {
        var path = Path()
        for index in 0..<(points * 2) {
            let length = index.isMultiple(of: 2) ? radius : radius * ratio
            let angle = -Double.pi / 2 + Double(index) * Double.pi / Double(points)
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * length, y: center.y + CGFloat(sin(angle)) * length)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private static func sparkle(center: CGPoint, radius: CGFloat, pinch: CGFloat) -> Path {
        let q = radius * pinch
        let x = center.x
        let y = center.y
        var path = Path()
        path.move(to: CGPoint(x: x, y: y - radius))
        path.addQuadCurve(to: CGPoint(x: x + radius, y: y), control: CGPoint(x: x + q, y: y - q))
        path.addQuadCurve(to: CGPoint(x: x, y: y + radius), control: CGPoint(x: x + q, y: y + q))
        path.addQuadCurve(to: CGPoint(x: x - radius, y: y), control: CGPoint(x: x - q, y: y + q))
        path.addQuadCurve(to: CGPoint(x: x, y: y - radius), control: CGPoint(x: x - q, y: y - q))
        path.closeSubpath()
        return path
    }

    /// SVG path data with M L H V C Q Z (upper case absolute, lower case relative).
    static func svgPath(_ data: String) -> Path {
        let tokens = tokenize(data)
        var path = Path()
        var index = 0
        var command: Character = "M"
        var current = CGPoint.zero
        var start = CGPoint.zero

        func take(_ count: Int) -> [CGFloat]? {
            guard index + count <= tokens.count else { return nil }
            var values: [CGFloat] = []
            for offset in 0..<count {
                guard let value = Double(tokens[index + offset]) else { return nil }
                values.append(CGFloat(value))
            }
            index += count
            return values
        }

        while index < tokens.count {
            let token = tokens[index]
            if token.count == 1, let letter = token.first, letter.isLetter {
                command = letter
                index += 1
                if letter == "Z" || letter == "z" {
                    path.closeSubpath()
                    current = start
                    continue
                }
            }
            let relative = command.isLowercase
            let base = relative ? current : CGPoint.zero
            switch command {
            case "M", "m":
                guard let v = take(2) else { return path }
                let point = CGPoint(x: base.x + v[0], y: base.y + v[1])
                path.move(to: point)
                current = point
                start = point
                command = relative ? "l" : "L"
            case "L", "l":
                guard let v = take(2) else { return path }
                let point = CGPoint(x: base.x + v[0], y: base.y + v[1])
                path.addLine(to: point)
                current = point
            case "H", "h":
                guard let v = take(1) else { return path }
                let point = CGPoint(x: (relative ? current.x : 0) + v[0], y: current.y)
                path.addLine(to: point)
                current = point
            case "V", "v":
                guard let v = take(1) else { return path }
                let point = CGPoint(x: current.x, y: (relative ? current.y : 0) + v[0])
                path.addLine(to: point)
                current = point
            case "C", "c":
                guard let v = take(6) else { return path }
                let point = CGPoint(x: base.x + v[4], y: base.y + v[5])
                path.addCurve(
                    to: point,
                    control1: CGPoint(x: base.x + v[0], y: base.y + v[1]),
                    control2: CGPoint(x: base.x + v[2], y: base.y + v[3])
                )
                current = point
            case "Q", "q":
                guard let v = take(4) else { return path }
                let point = CGPoint(x: base.x + v[2], y: base.y + v[3])
                path.addQuadCurve(to: point, control: CGPoint(x: base.x + v[0], y: base.y + v[1]))
                current = point
            default:
                return path
            }
        }
        return path
    }

    /// Splits path data into single-letter commands and numbers ("M4-2.5.5" -> M, 4, -2.5, .5).
    private static func tokenize(_ data: String) -> [String] {
        var tokens: [String] = []
        var number = ""
        func flush() {
            if !number.isEmpty {
                tokens.append(number)
                number = ""
            }
        }
        for character in data {
            if character.isLetter && character != "e" && character != "E" {
                flush()
                tokens.append(String(character))
            } else if character == "-" {
                if let last = number.last, last == "e" || last == "E" {
                    number.append(character)
                } else {
                    flush()
                    number.append(character)
                }
            } else if character == "." {
                if number.contains(".") { flush() }
                number.append(character)
            } else if character.isNumber || character == "e" || character == "E" {
                number.append(character)
            } else {
                flush()
            }
        }
        flush()
        return tokens
    }
}
