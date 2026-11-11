import SwiftUI

/// A flat sticker drawing in its own point grid. Paths use absolute
/// `M`, `L`, `Q`, `C` and `Z` commands separated by single spaces.
struct BagArt {
    let size: CGSize
    let layers: [BagLayer]

    init(width: CGFloat, height: CGFloat, layers: [BagLayer]) {
        size = CGSize(width: width, height: height)
        self.layers = layers
    }
}

struct BagLayer {
    let path: Path
    let color: Color
    let lineWidth: CGFloat?

    static func fill(_ d: String, _ hex: UInt32) -> BagLayer {
        BagLayer(path: BagPathParser.path(d), color: Color(hex: hex), lineWidth: nil)
    }

    static func stroke(_ d: String, _ hex: UInt32, width: CGFloat) -> BagLayer {
        BagLayer(path: BagPathParser.path(d), color: Color(hex: hex), lineWidth: width)
    }

    static func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ degrees: CGFloat, _ hex: UInt32) -> BagLayer {
        let transform = CGAffineTransform(rotationAngle: degrees * .pi / 180)
            .concatenating(CGAffineTransform(translationX: cx, y: cy))
        let path = Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2)).applying(transform)
        return BagLayer(path: path, color: Color(hex: hex), lineWidth: nil)
    }
}

enum BagPathParser {
    static func path(_ d: String) -> Path {
        let tokens = d.split(separator: " ")
        var path = Path()
        var index = 0
        var command: Character = "M"

        func number() -> CGFloat {
            guard index < tokens.count else { return 0 }
            defer { index += 1 }
            return CGFloat(Double(tokens[index]) ?? 0)
        }

        func point() -> CGPoint {
            let x = number()
            let y = number()
            return CGPoint(x: x, y: y)
        }

        while index < tokens.count {
            if let first = tokens[index].first, first.isLetter {
                command = first
                index += 1
                if command == "Z" {
                    path.closeSubpath()
                    continue
                }
            }
            switch command {
            case "M":
                path.move(to: point())
                command = "L"
            case "L":
                path.addLine(to: point())
            case "Q":
                let control = point()
                path.addQuadCurve(to: point(), control: control)
            case "C":
                let first = point()
                let second = point()
                path.addCurve(to: point(), control1: first, control2: second)
            default:
                index = tokens.count
            }
        }
        return path
    }
}

/// Draws a `BagArt` aspect-fit and centred in whatever frame it gets.
struct BagArtView: View {
    let art: BagArt

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / art.size.width, size.height / art.size.height)
            context.translateBy(
                x: (size.width - art.size.width * scale) / 2,
                y: (size.height - art.size.height * scale) / 2
            )
            context.scaleBy(x: scale, y: scale)
            for layer in art.layers {
                if let width = layer.lineWidth {
                    context.stroke(
                        layer.path,
                        with: .color(layer.color),
                        style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
                    )
                } else {
                    context.fill(layer.path, with: .color(layer.color))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
