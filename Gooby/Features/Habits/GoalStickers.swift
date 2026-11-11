import SwiftUI

/// Sticker art on a 40 x 40 grid: flat colour, a small shine, a white rim and a soft drop.
struct GoalSticker: View {
    var glyph: String

    var body: some View {
        switch glyph {
        case "giraffe": GiraffeSticker()
        case "leaf": LeafSticker()
        case "smile": SmileSticker()
        case "tea": TeaSticker()
        case "bed": BedSticker()
        case "drop": DropSticker()
        case "walk": WalkSticker()
        case "moon": MoonSticker()
        case "shower": ShowerSticker()
        case "heart": HeartSticker()
        case "people": PeopleSticker()
        case "sun": SunSticker()
        case "home": HomeSticker()
        case "note": NoteSticker()
        case "phone": PhoneSticker()
        case "star": StarSticker()
        case "hands": HandsSticker()
        case "broom": BroomSticker()
        case "mail": MailSticker()
        case "yoga": YogaSticker()
        case "plate": PlateSticker()
        case "apple": AppleSticker()
        case "book": BookSticker()
        case "flower": FlowerSticker()
        case "timer": TimerSticker()
        case "gift": GiftSticker()
        case "shirt": ShirtSticker()
        case "bolt": BoltSticker()
        case "sparkle": SparkleSticker()
        case "target": TargetSticker()
        case "mirror": MirrorSticker()
        case "pencil": PencilSticker()
        case "face": FaceSticker()
        case "rocket": RocketSticker()
        default: SparkleSticker()
        }
    }
}

private enum Pal {
    static let yellow = Color(hex: 0xFFCC4D)
    static let gold = Color(hex: 0xFFAC33)
    static let orange = Color(hex: 0xF4900C)
    static let spot = Color(hex: 0xE8913A)
    static let brown = Color(hex: 0xC1694F)
    static let tan = Color(hex: 0xD99E82)
    static let cocoa = Color(hex: 0x664500)
    static let hoof = Color(hex: 0x5C3A1E)
    static let ink = Color(hex: 0x292F33)
    static let slate = Color(hex: 0x66757F)
    static let steel = Color(hex: 0x99AAB5)
    static let mist = Color(hex: 0xCCD6DD)
    static let snow = Color(hex: 0xF5F8FA)
    static let white = Color(hex: 0xFFFFFF)
    static let red = Color(hex: 0xDD2E44)
    static let rose = Color(hex: 0xEA596E)
    static let pink = Color(hex: 0xF4ABBA)
    static let blush = Color(hex: 0xFF7892)
    static let sky = Color(hex: 0x55ACEE)
    static let deep = Color(hex: 0x3B88C3)
    static let ice = Color(hex: 0xBBDDF5)
    static let leaf = Color(hex: 0xA6D388)
    static let green = Color(hex: 0x77B255)
    static let forest = Color(hex: 0x5C913B)
    static let skin = Color(hex: 0xFFDC5D)
    static let cream = Color(hex: 0xFFE8B6)
    static let phone = Color(hex: 0x31373D)
    static let face = Color(hex: 0xFCC654)
}

private struct StickerCanvas<Content: View>: View {
    var rim: CGFloat = 2.2
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .topLeading) { content }
            .frame(width: 40, height: 40, alignment: .topLeading)
            .stickerRim(rim)
    }
}

extension View {
    func stickerRim(_ width: CGFloat = 2.2) -> some View {
        compositingGroup()
            .shadow(color: .white, radius: 0, x: width, y: 0)
            .compositingGroup()
            .shadow(color: .white, radius: 0, x: -width, y: 0)
            .compositingGroup()
            .shadow(color: .white, radius: 0, x: 0, y: width)
            .compositingGroup()
            .shadow(color: .white, radius: 0, x: 0, y: -width)
            .compositingGroup()
            .shadow(color: .black.opacity(0.16), radius: 1.2, x: 0, y: 1.4)
    }
}

private extension StrokeStyle {
    static func soft(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}

private func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, turn: Double = 0) -> Path {
    Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
        .applying(CGAffineTransform(rotationAngle: turn * .pi / 180).concatenating(CGAffineTransform(translationX: cx, y: cy)))
}

private func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
    Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r, style: .circular)
}

/// Reads absolute `M L Q C Z` commands separated by spaces.
private func shape(_ d: String) -> Path {
    let tokens = d.split(separator: " ")
    var path = Path()
    var index = 0
    func next() -> CGFloat {
        defer { index += 1 }
        return index < tokens.count ? CGFloat(Double(tokens[index]) ?? 0) : 0
    }
    func point() -> CGPoint {
        let x = next()
        return CGPoint(x: x, y: next())
    }
    while index < tokens.count {
        let command = tokens[index]
        index += 1
        switch command {
        case "M":
            path.move(to: point())
        case "L":
            path.addLine(to: point())
        case "Q":
            let control = point()
            path.addQuadCurve(to: point(), control: control)
        case "C":
            let first = point()
            let second = point()
            path.addCurve(to: point(), control1: first, control2: second)
        case "Z":
            path.closeSubpath()
        default:
            break
        }
    }
    return path
}

private struct GiraffeSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                shape("M 29.5 20 Q 33 23 32.6 28").stroke(Pal.spot, style: .soft(1.5))
                oval(32.6, 29.2, 1.5, 2.3).fill(Pal.hoof)
                box(27, 23, 3.3, 12.5, 1.5).fill(Pal.gold)
                box(22.8, 23, 3.3, 12.5, 1.5).fill(Pal.gold)
                box(26.6, 33, 3.3, 3, 1.1).fill(Pal.hoof)
                box(22.4, 33, 3.3, 3, 1.1).fill(Pal.hoof)
                box(13.4, 23, 3.3, 12.5, 1.5).fill(Pal.yellow)
                box(17.6, 23, 3.3, 12.5, 1.5).fill(Pal.yellow)
                box(13.4, 33, 3.3, 3, 1.1).fill(Pal.hoof)
            }
            Group {
                box(17.6, 33, 3.3, 3, 1.1).fill(Pal.hoof)
                shape("M 12.8 18.5 C 12.8 15.8 15 14.6 18 14.6 L 27 15 C 30.6 15.3 31.6 17.8 31.2 21 C 30.8 24.4 29 26 26 26 L 16.2 26 C 13.6 26 12.6 24 12.8 21 Z").fill(Pal.yellow)
                shape("M 10.6 9.2 C 11.8 7.6 15 7.2 16.8 8.4 L 19.6 18 L 12.6 19.6 Z").fill(Pal.yellow)
                shape("M 16.6 9.6 L 19.2 17.6").stroke(Pal.spot, style: .soft(1.6))
                oval(11.2, 7.4, 4.8, 3.5, turn: -12).fill(Pal.yellow)
                oval(7.4, 9.1, 3, 2.4).fill(Pal.yellow)
                shape("M 11.6 4.6 L 11 1.8").stroke(Pal.brown, style: .soft(1.4))
                shape("M 14.2 4.8 L 14.9 2").stroke(Pal.brown, style: .soft(1.4))
                oval(10.9, 1.6, 1.2, 1.2).fill(Pal.brown)
            }
            Group {
                oval(15, 1.8, 1.2, 1.2).fill(Pal.brown)
                oval(16.6, 5.8, 2.4, 1.1, turn: 25).fill(Pal.yellow)
                oval(16.6, 5.8, 1.3, 0.6, turn: 25).fill(Pal.tan)
                oval(11.3, 6.6, 1, 1).fill(Pal.ink)
                oval(5.6, 9.3, 0.5, 0.5).fill(Pal.ink)
                oval(17.6, 19, 2.4, 1.9, turn: 10).fill(Pal.spot)
                oval(23, 18.1, 2.5, 1.9, turn: -8).fill(Pal.spot)
                oval(28.2, 20.2, 1.8, 2.1).fill(Pal.spot)
                oval(21.2, 23.2, 2, 1.5).fill(Pal.spot)
            }
            Group {
                oval(26.4, 23.7, 1.5, 1.3).fill(Pal.spot)
                oval(14.6, 12.4, 1.3, 1.7, turn: -15).fill(Pal.spot)
                oval(16.3, 16.3, 1.4, 1.4).fill(Pal.spot)
                oval(9.4, 5.6, 1.6, 0.8, turn: -20).fill(Pal.white.opacity(0.7))
                oval(20, 16.2, 2.2, 0.7, turn: -4).fill(Pal.white.opacity(0.5))
            }
        }
    }
}

private struct LeafSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                shape("M 2.8 11.7 L 5.1 14.6").stroke(Pal.forest, style: .soft(1.6))
                shape("M 5.1 14.6 C 16.2 8.8 32 17.7 30.4 31.7 C 18.8 37.2 3.6 27.5 5.1 14.6 Z").fill(Pal.leaf)
                shape("M 5.1 14.6 C 3.6 27.5 18.8 37.2 30.4 31.7 C 20.8 32.4 7.2 23.9 5.1 14.6 Z").fill(Pal.green.opacity(0.3))
                shape("M 4.6 14.3 L 28.3 30.3").stroke(Pal.green, style: .soft(1.5))
                shape("M 11.3 18.8 L 18.1 15.7").stroke(Pal.green, style: .soft(1.2))
                shape("M 17.1 22.7 L 24.2 19.5").stroke(Pal.green, style: .soft(1.2))
                shape("M 22.8 26.6 L 28 24.6").stroke(Pal.green, style: .soft(1.2))
                shape("M 12.4 19.5 L 12 26.5").stroke(Pal.green, style: .soft(1.2))
                shape("M 18.2 23.4 L 18.1 30.7").stroke(Pal.green, style: .soft(1.2))
            }
            Group {
                shape("M 23.6 27.1 L 23.7 32.1").stroke(Pal.green, style: .soft(1.2))
                oval(15.5, 15.2, 3.6, 1, turn: 22).fill(Pal.white.opacity(0.6))
                shape("M 26.6 3.4 Q 32.2 4.8 33.4 10.6").stroke(Pal.sky, style: .soft(1.9))
                shape("M 31 1.4 Q 37.6 4 37.6 11").stroke(Pal.sky, style: .soft(1.9))
                shape("M 25.2 8.6 Q 28.6 9.6 29.4 13").stroke(Pal.sky, style: .soft(1.9))
            }
        }
    }
}

private struct SmileSticker: View {
    var body: some View {
        StickerCanvas {
            oval(20, 20, 16.5, 16.5).fill(Pal.yellow)
            oval(10.8, 23.8, 3.8, 2.7).fill(Pal.blush.opacity(0.9))
            oval(29.2, 23.8, 3.8, 2.7).fill(Pal.blush.opacity(0.9))
            shape("M 10.8 18.4 Q 14 13.2 17.2 18.4").stroke(Pal.cocoa, style: .soft(2.3))
            shape("M 22.8 18.4 Q 26 13.2 29.2 18.4").stroke(Pal.cocoa, style: .soft(2.3))
            shape("M 12.4 24.6 Q 20 33.2 27.6 24.6").stroke(Pal.cocoa, style: .soft(2.3))
            oval(12.4, 9.6, 3.2, 1.7, turn: -35).fill(Pal.white.opacity(0.6))
        }
    }
}

private struct TeaSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                oval(20, 32.4, 15.4, 4.8).fill(Pal.ink)
                oval(20, 31.8, 13.8, 3.7).fill(Pal.slate)
                oval(20, 31.4, 9.6, 2.3).fill(Pal.steel)
                shape("M 5.2 18 C 5.2 27.4 11 31.8 20 31.8 C 29 31.8 34.8 27.4 34.8 18 Z").fill(Pal.ink)
                shape("M 6.8 18.6 C 7.2 26.2 12 30.3 20 30.3 C 28 30.3 32.8 26.2 33.2 18.6 Z").fill(Pal.snow)
                shape("M 9 25 C 11.6 28.6 15.2 30.3 20 30.3 C 24.8 30.3 28.4 28.6 31 25 C 27 27.2 13 27.2 9 25 Z").fill(Pal.mist)
                oval(20, 18, 14.8, 4.8).fill(Pal.ink)
                oval(20, 18, 13.4, 3.8).fill(Pal.snow)
                oval(20, 18.4, 11.6, 2.9).fill(Pal.leaf)
            }
            Group {
                oval(20, 19.2, 8.4, 1.8).fill(Pal.green)
                shape("M 15.6 13.6 C 13.6 11 17.6 9.8 15.6 6.4").stroke(Pal.forest, style: .soft(1.7))
                shape("M 21.2 13.4 C 19.2 10.4 23.2 9 21.2 4.8").stroke(Pal.forest, style: .soft(1.7))
                shape("M 26.4 13.6 C 24.8 11.4 28 10.4 26.4 7.6").stroke(Pal.forest, style: .soft(1.7))
                oval(10.6, 22.6, 1.2, 2.6, turn: -20).fill(Pal.white.opacity(0.9))
            }
        }
    }
}

private struct BedSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                box(3.5, 9.5, 5.4, 25.5, 2.4).fill(Pal.brown)
                box(31.6, 17, 5.4, 18, 2.4).fill(Pal.brown)
                box(5.5, 31, 2.6, 5, 1.2).fill(Pal.brown)
                box(32, 31, 2.6, 5, 1.2).fill(Pal.brown)
                box(6, 25, 28.5, 6.5, 1.6).fill(Pal.tan)
                box(6.5, 20.5, 27.5, 6, 2.4).fill(Pal.snow)
                oval(11.4, 18.8, 4.8, 3.4).fill(Pal.mist)
                oval(11.4, 18.5, 4.2, 2.8).fill(Pal.white)
                box(14, 16.5, 20.5, 10.5, 3).fill(Pal.sky)
            }
            Group {
                box(14, 16.5, 20.5, 3.4, 1.7).fill(Pal.ice)
                oval(5.8, 13, 0.8, 2.6).fill(Pal.white.opacity(0.5))
                oval(22, 22.6, 4.6, 0.9).fill(Pal.white.opacity(0.5))
            }
        }
    }
}

private struct DropSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 20 6.5 C 24.4 13.8 30.9 19.6 30.9 26.1 C 30.9 32.3 26.1 36.2 20 36.2 C 13.9 36.2 9.1 32.3 9.1 26.1 C 9.1 19.6 15.7 13.8 20 6.5 Z").fill(Pal.sky)
            shape("M 28.4 20 C 30.4 25 29.6 31.6 22.6 34 C 28.8 34.4 32.2 29.4 31.4 24.4 C 31 22.6 29.8 21 28.4 20 Z").fill(Pal.deep.opacity(0.6))
            oval(14.6, 24, 1.8, 3.8, turn: 18).fill(Pal.white.opacity(0.8))
        }
    }
}

private struct WalkSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 4.2 27.6 L 4.6 19 C 4.7 17 6.2 15.9 8.2 16.4 L 12.8 17.8 C 15.2 18.4 16.8 17 17.4 15 L 17.9 13.6 C 18.4 12 20 11.5 21.6 12.3 L 25 14.4 C 30 17.5 35.2 19.8 36.2 23.6 L 36.6 27.6 Z").fill(Pal.red)
            shape("M 3.6 27 L 36.8 27 C 37.8 27 38.2 28 37.9 29.4 L 37.6 30.8 C 37.4 32 36.6 32.6 35.4 32.6 L 6 32.6 C 4.6 32.6 3.6 31.6 3.6 30.2 Z").fill(Pal.snow)
            shape("M 4 29.8 L 37.8 29.8").stroke(Pal.mist, style: .soft(1.1))
            shape("M 8.6 23 Q 15.4 26 23.2 21.6").stroke(Pal.white, style: .soft(1.9))
            shape("M 19.4 15.4 L 23 17.8").stroke(Pal.white, style: .soft(1.4))
            shape("M 21.8 13.8 L 25.6 16.2").stroke(Pal.white, style: .soft(1.4))
            oval(8.8, 19.4, 2.4, 0.9, turn: -15).fill(Pal.white.opacity(0.5))
        }
    }
}

private struct MoonSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 24 4 C 13.6 4.4 5.6 12 5.6 21.4 C 5.6 30.6 13 36.4 22 36.4 C 29.2 36.4 34.4 32.2 36.4 26.6 C 26.4 30 16.8 23.6 16.8 14.6 C 16.8 9.6 19.6 6.2 24 4 Z").fill(Pal.yellow)
            oval(11.6, 22, 1.8, 1.8).fill(Pal.gold)
            oval(15.6, 30, 1.3, 1.3).fill(Pal.gold)
            oval(10.4, 15.2, 1, 1).fill(Pal.gold)
            shape("M 30 6.8 Q 30.7 10.3 34.2 11 Q 30.7 11.7 30 15.2 Q 29.3 11.7 25.8 11 Q 29.3 10.3 30 6.8 Z").fill(Pal.gold)
            oval(10.6, 11.4, 1.2, 2.8, turn: 30).fill(Pal.white.opacity(0.6))
        }
    }
}

private struct ShowerSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 20 10 L 20 6.4 Q 20 3.6 22.8 3.6 L 33.6 3.6").stroke(Pal.steel, style: .soft(2.8))
            shape("M 10.6 18.4 C 10.6 12.6 14.6 10 20 10 C 25.4 10 29.4 12.6 29.4 18.4 Z").fill(Pal.steel)
            box(9.6, 17.4, 20.8, 3.4, 1.7).fill(Pal.slate)
            shape("M 13.6 22.8 C 14.7 24.7 16.4 26.2 16.4 27.9 C 16.4 29.6 15.2 30.6 13.6 30.6 C 12 30.6 10.8 29.6 10.8 27.9 C 10.8 26.2 12.5 24.7 13.6 22.8 Z").fill(Pal.sky)
            shape("M 20 24.6 C 21.1 26.5 22.9 28 22.9 29.7 C 22.9 31.4 21.6 32.4 20 32.4 C 18.4 32.4 17.1 31.4 17.1 29.7 C 17.1 28 18.9 26.5 20 24.6 Z").fill(Pal.sky)
            shape("M 26.4 22.8 C 27.5 24.7 29.2 26.2 29.2 27.9 C 29.2 29.6 28 30.6 26.4 30.6 C 24.8 30.6 23.5 29.6 23.5 27.9 C 23.5 26.2 25.3 24.7 26.4 22.8 Z").fill(Pal.sky)
            shape("M 16.8 30.6 C 17.9 32.4 19.5 33.8 19.5 35.5 C 19.5 37 18.3 38 16.8 38 C 15.3 38 14.1 37 14.1 35.5 C 14.1 33.8 15.7 32.4 16.8 30.6 Z").fill(Pal.sky)
            shape("M 23.2 30.6 C 24.3 32.4 25.9 33.8 25.9 35.5 C 25.9 37 24.7 38 23.2 38 C 21.7 38 20.5 37 20.5 35.5 C 20.5 33.8 22.1 32.4 23.2 30.6 Z").fill(Pal.sky)
            oval(15.2, 13.6, 2.4, 0.9, turn: -25).fill(Pal.white.opacity(0.6))
        }
    }
}

private struct HeartSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 20 35.1 C 13.5 30.3 2.7 23.2 2.7 14.1 C 2.7 8.7 7 4.9 11.9 4.9 C 15.7 4.9 18.4 7 20 9.7 C 21.6 7 24.3 4.9 28.1 4.9 C 33 4.9 37.3 8.7 37.3 14.1 C 37.3 23.2 26.5 30.3 20 35.1 Z").fill(Pal.red)
            oval(11.2, 12.2, 3.2, 1.8, turn: -38).fill(Pal.white.opacity(0.7))
        }
    }
}

private struct PeopleSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                shape("M 21 35.6 L 21 29.4 C 21 24.8 24.4 21.6 28.6 21.6 C 32.8 21.6 36.2 24.8 36.2 29.4 L 36.2 34 Q 36.2 35.6 34.6 35.6 Z").fill(Pal.sky)
                oval(28.6, 15.2, 5.2, 5.2).fill(Pal.skin)
                shape("M 23.4 14.6 C 23.6 10.8 26 9.6 28.6 9.6 C 31.2 9.6 33.6 10.8 33.8 14.6 C 32 12.6 30 12.2 28.6 12.2 C 27.2 12.2 25.2 12.6 23.4 14.6 Z").fill(Pal.gold)
                oval(26.9, 16.2, 0.8, 0.8).fill(Pal.ink)
                oval(30.3, 16.2, 0.8, 0.8).fill(Pal.ink)
                shape("M 4.4 35.6 L 4.4 30.2 C 4.4 25.2 8.4 22.2 13.6 22.2 C 18.8 22.2 22.8 25.2 22.8 30.2 L 22.8 34 Q 22.8 35.6 21.2 35.6 L 6 35.6 Q 4.4 35.6 4.4 34 Z").fill(Pal.orange)
                oval(13.6, 15.6, 5.8, 5.8).fill(Pal.skin)
                shape("M 7.8 15 C 7.8 10.6 10.4 9.2 13.6 9.2 C 16.8 9.2 19.4 10.6 19.4 15 C 17.6 12.6 15 12.2 13.6 12.2 C 12.2 12.2 9.6 12.6 7.8 15 Z").fill(Pal.brown)
                oval(11.8, 16.6, 0.8, 0.8).fill(Pal.ink)
            }
            Group {
                oval(15.4, 16.6, 0.8, 0.8).fill(Pal.ink)
                oval(8.6, 26, 0.9, 2.2, turn: 20).fill(Pal.white.opacity(0.5))
            }
        }
    }
}

private struct SunSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                shape("M 33.4 20 L 37.2 20").stroke(Pal.gold, style: .soft(3.4))
                shape("M 29.5 29.5 L 32.2 32.2").stroke(Pal.gold, style: .soft(3.4))
                shape("M 20 33.4 L 20 37.2").stroke(Pal.gold, style: .soft(3.4))
                shape("M 10.5 29.5 L 7.8 32.2").stroke(Pal.gold, style: .soft(3.4))
                shape("M 6.6 20 L 2.8 20").stroke(Pal.gold, style: .soft(3.4))
                shape("M 10.5 10.5 L 7.8 7.8").stroke(Pal.gold, style: .soft(3.4))
                shape("M 20 6.6 L 20 2.8").stroke(Pal.gold, style: .soft(3.4))
                shape("M 29.5 10.5 L 32.2 7.8").stroke(Pal.gold, style: .soft(3.4))
                oval(20, 20, 10.6, 10.6).fill(Pal.yellow)
            }
            Group {
                oval(16, 15.4, 3, 1.6, turn: -35).fill(Pal.white.opacity(0.6))
            }
        }
    }
}

private struct HomeSticker: View {
    var body: some View {
        StickerCanvas {
            box(25.6, 6, 4.8, 9, 1.2).fill(Pal.brown)
            box(8, 18, 24, 16.4, 2).fill(Pal.cream)
            shape("M 3.8 19.8 L 20 5.4 L 36.2 19.8 C 37 20.6 36.4 22 35.2 22 L 4.8 22 C 3.6 22 3 20.6 3.8 19.8 Z").fill(Pal.red)
            box(17, 25, 6.6, 9.4, 1.6).fill(Pal.brown)
            oval(21.8, 30.2, 0.7, 0.7).fill(Pal.gold)
            box(10.4, 24.4, 5, 5, 1.2).fill(Pal.sky)
            box(25.6, 24.4, 5, 5, 1.2).fill(Pal.sky)
            box(6, 33.4, 28, 3, 1.5).fill(Pal.green)
            oval(12.6, 14.4, 3.6, 0.9, turn: -42).fill(Pal.white.opacity(0.5))
        }
    }
}

private struct NoteSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                box(6, 4.4, 23.6, 30.6, 3).fill(Pal.mist)
                box(6.8, 5.2, 22, 29, 2.4).fill(Pal.white)
                box(6, 4.4, 23.6, 6.2, 3).fill(Pal.red)
                shape("M 10.6 15.4 L 25 15.4").stroke(Pal.mist, style: .soft(1.5))
                shape("M 10.6 19.8 L 25 19.8").stroke(Pal.mist, style: .soft(1.5))
                shape("M 10.6 24.2 L 22 24.2").stroke(Pal.mist, style: .soft(1.5))
                shape("M 10.6 28.6 L 18 28.6").stroke(Pal.mist, style: .soft(1.5))
                shape("M 29.5 18.2 L 31.6 16.1 Q 32.8 15 33.9 16.1 L 35.3 17.5 Q 36.4 18.6 35.3 19.8 L 33.2 21.9 Z").fill(Pal.rose)
                shape("M 28.2 19.5 L 29.8 17.9 L 33.5 21.6 L 31.9 23.2 Z").fill(Pal.steel)
            }
            Group {
                shape("M 18.2 29.5 L 28.4 19.3 L 32.1 23 L 21.9 33.2 Z").fill(Pal.gold)
                shape("M 18.2 29.5 L 28.4 19.3 L 29.8 20.8 L 19.6 30.9 Z").fill(Pal.yellow)
                shape("M 18.2 29.5 L 16.4 35 L 21.9 33.2 Z").fill(Pal.tan)
                shape("M 17 33 L 16.4 35 L 18.4 34.4 Z").fill(Pal.ink)
            }
        }
    }
}

private struct PhoneSticker: View {
    var body: some View {
        StickerCanvas {
            box(10.6, 3.4, 18.8, 33.2, 4.4).fill(Pal.phone)
            box(12.8, 7.6, 14.4, 23.4, 1.6).fill(Pal.sky)
            box(17.4, 5, 5.2, 1.3, 0.7).fill(Pal.slate)
            oval(20, 33.6, 1.3, 1.3).fill(Pal.slate)
            box(14.8, 11, 8.4, 3.4, 1.7).fill(Pal.white.opacity(0.9))
            box(16.8, 16.4, 8.4, 3.4, 1.7).fill(Pal.white.opacity(0.9))
            box(14.8, 21.8, 6, 3.4, 1.7).fill(Pal.white.opacity(0.9))
            oval(13.8, 6.4, 1.4, 0.6).fill(Pal.white.opacity(0.3))
        }
    }
}

private struct StarSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 20 4.4 L 24.5 14.9 L 35.8 15.9 L 27.2 23.3 L 29.8 34.4 L 20 28.6 L 10.2 34.4 L 12.8 23.3 L 4.2 15.9 L 15.5 14.9 Z").fill(Pal.yellow)
            shape("M 20 4.4 L 24.5 14.9 L 35.8 15.9 L 27.2 23.3 L 29.8 34.4 L 20 28.6 L 10.2 34.4 L 12.8 23.3 L 4.2 15.9 L 15.5 14.9 Z").stroke(Pal.yellow, style: .soft(2.6))
            shape("M 20 12 L 22.4 17.7 L 28.6 18.2 L 23.9 22.3 L 25.3 28.3 L 20 25.1 L 14.7 28.3 L 16.1 22.3 L 11.4 18.2 L 17.6 17.7 Z").fill(Pal.gold.opacity(0.6))
            oval(14.4, 14.6, 2.4, 1.2, turn: -30).fill(Pal.white.opacity(0.7))
        }
    }
}

private struct HandsSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                oval(10.6, 22.4, 2.4, 5.6, turn: -36).fill(Pal.skin)
                box(12.6, 9.4, 4, 13, 2).fill(Pal.skin)
                box(16.8, 6.6, 4, 15, 2).fill(Pal.skin)
                box(21, 7.6, 4, 14, 2).fill(Pal.skin)
                box(25.1, 10.6, 3.8, 11, 1.9).fill(Pal.skin)
                box(12.6, 15.6, 16.3, 15.4, 6).fill(Pal.skin)
                shape("M 16.7 14 L 16.7 18").stroke(Pal.gold, style: .soft(0.9))
                shape("M 20.9 14 L 20.9 18").stroke(Pal.gold, style: .soft(0.9))
                shape("M 25 14 L 25 18").stroke(Pal.gold, style: .soft(0.9))
            }
            Group {
                box(13.8, 29.4, 13.8, 6.4, 2).fill(Pal.sky)
                shape("M 31 11.6 C 29.2 10.2 26.2 8.3 26.2 5.8 C 26.2 4.2 27.4 3.2 28.8 3.2 C 29.8 3.2 30.6 3.8 31 4.6 C 31.4 3.8 32.2 3.2 33.2 3.2 C 34.6 3.2 35.8 4.2 35.8 5.8 C 35.8 8.3 32.8 10.2 31 11.6 Z").fill(Pal.red)
                oval(18.4, 8.6, 0.7, 1.6).fill(Pal.white.opacity(0.6))
            }
        }
    }
}

private struct BroomSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 31.4 3.4 L 20 20.6").stroke(Pal.brown, style: .soft(2.8))
            shape("M 16.4 18 L 23.6 22.6 L 20.6 34.6 Q 11 35.6 5 29.4 Z").fill(Pal.yellow)
            shape("M 18.4 22.2 L 10.2 31.2").stroke(Pal.gold, style: .soft(1.1))
            shape("M 21 24 L 15.4 33.6").stroke(Pal.gold, style: .soft(1.1))
            shape("M 15.4 16.8 L 24.6 22.8 L 23.2 25.2 L 14 19.2 Z").fill(Pal.red)
            shape("M 31.4 21 Q 32.2 25.2 36.4 26 Q 32.2 26.8 31.4 31 Q 30.6 26.8 26.4 26 Q 30.6 25.2 31.4 21 Z").fill(Pal.gold)
            oval(30.2, 5.6, 0.6, 1.6, turn: 34).fill(Pal.white.opacity(0.6))
        }
    }
}

private struct MailSticker: View {
    var body: some View {
        StickerCanvas {
            box(3.4, 9.4, 33.2, 23.2, 3.6).fill(Pal.steel)
            box(4.2, 10.2, 31.6, 21.6, 2.8).fill(Pal.snow)
            shape("M 5.4 30.4 L 15.6 20.6").stroke(Pal.mist, style: .soft(1.3))
            shape("M 34.6 30.4 L 24.4 20.6").stroke(Pal.mist, style: .soft(1.3))
            shape("M 4.6 11.2 L 20 23.4 L 35.4 11.2 Z").fill(Pal.mist)
            shape("M 5 11.6 L 20 23.4 L 35 11.6").stroke(Pal.steel, style: .soft(1.3))
            shape("M 20 27.2 C 17.8 25.6 14.2 23.3 14.2 20.2 C 14.2 18.4 15.7 17.2 17.3 17.2 C 18.6 17.2 19.5 17.9 20 18.8 C 20.5 17.9 21.4 17.2 22.7 17.2 C 24.3 17.2 25.8 18.4 25.8 20.2 C 25.8 23.3 22.2 25.6 20 27.2 Z").fill(Pal.red)
        }
    }
}

private struct YogaSticker: View {
    var body: some View {
        StickerCanvas {
            oval(20, 30.4, 14, 3.8).fill(Pal.green)
            shape("M 2.9 22.5 C 8.9 20 16.6 23.1 20 29.4 C 13.2 31.6 5.5 28.5 2.9 22.5 Z").fill(Pal.rose)
            shape("M 37.1 22.5 C 34.5 28.5 26.8 31.6 20 29.4 C 23.4 23.1 31.1 20 37.1 22.5 Z").fill(Pal.rose)
            shape("M 8.8 12.8 C 15.8 14.2 20.8 21.6 20 29.4 C 12.5 27.2 7.5 19.8 8.8 12.8 Z").fill(Pal.pink)
            shape("M 31.2 12.8 C 32.5 19.8 27.5 27.2 20 29.4 C 19.2 21.6 24.2 14.2 31.2 12.8 Z").fill(Pal.pink)
            shape("M 20 8.4 C 25.2 13.6 25.2 23.1 20 29.4 C 14.8 23.1 14.8 13.6 20 8.4 Z").fill(Pal.pink)
            shape("M 20 27 L 20 15").stroke(Pal.rose.opacity(0.6), style: .soft(1.1))
            oval(18.2, 15.4, 0.8, 2.6).fill(Pal.white.opacity(0.6))
        }
    }
}

private struct PlateSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                oval(20, 19.6, 16.4, 3).fill(Pal.brown)
                oval(11.4, 17.6, 5, 5).fill(Pal.green)
                oval(19, 14.6, 6, 6).fill(Pal.leaf)
                oval(27.4, 17.2, 5.4, 5.4).fill(Pal.green)
                oval(23.6, 12.6, 4, 4).fill(Pal.forest)
                oval(14.6, 13.4, 3.2, 3.2).fill(Pal.red)
                oval(28.6, 12.8, 2.6, 2.6).fill(Pal.red)
                oval(21.6, 17.6, 4, 2.6).fill(Pal.white)
                oval(22, 17.6, 1.6, 1.6).fill(Pal.yellow)
            }
            Group {
                shape("M 3.4 19.4 C 8 22.2 32 22.2 36.6 19.4 C 36 28.6 29 34.2 20 34.2 C 11 34.2 4 28.6 3.4 19.4 Z").fill(Pal.tan)
                oval(13.6, 12.6, 0.9, 0.6).fill(Pal.white.opacity(0.8))
                oval(10.6, 26, 2.6, 1, turn: 30).fill(Pal.white.opacity(0.5))
            }
        }
    }
}

private struct AppleSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 20 12 Q 20 7.4 22.6 4.4").stroke(Pal.brown, style: .soft(1.9))
            shape("M 21.6 8 C 23 4 28 3 31.2 4.4 C 29.2 8 25 9.6 21.6 8 Z").fill(Pal.green)
            shape("M 20 11.6 C 24 8.6 34 8 34.6 19 C 35 28 28.6 35.6 24 35.6 C 22 35.6 21.6 34.6 20 34.6 C 18.4 34.6 18 35.6 16 35.6 C 11.4 35.6 5 28 5.4 19 C 6 8 16 8.6 20 11.6 Z").fill(Pal.red)
            oval(12, 17.4, 2.4, 4, turn: 20).fill(Pal.white.opacity(0.6))
        }
    }
}

private struct BookSticker: View {
    var body: some View {
        StickerCanvas {
            box(8.4, 7.4, 25, 29, 3).fill(Pal.deep)
            box(9.6, 6.6, 22.2, 27.8, 2).fill(Pal.snow)
            shape("M 29.4 9 L 29.4 33").stroke(Pal.mist, style: .soft(1))
            shape("M 11 32.2 L 29 32.2").stroke(Pal.mist, style: .soft(1))
            shape("M 22 30 L 22 37.4 L 24 35.8 L 26 37.4 L 26 30 Z").fill(Pal.red)
            box(6, 4, 22.4, 28.4, 3).fill(Pal.sky)
            box(6, 4, 4.6, 28.4, 2.3).fill(Pal.deep)
            box(13.4, 10, 11, 6, 1.6).fill(Pal.white.opacity(0.9))
            oval(15.8, 22.4, 3, 0.8, turn: -20).fill(Pal.white.opacity(0.4))
        }
    }
}

private struct FlowerSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                shape("M 20 24 Q 19.6 31 21 37").stroke(Pal.green, style: .soft(2.4))
                shape("M 20.6 32 C 22.6 28 27.6 27 30.6 28.6 C 28.6 32.4 24 33.6 20.6 32 Z").fill(Pal.green)
                oval(20, 9.2, 6.6, 6.6).fill(Pal.pink)
                oval(26.8, 14.2, 6.6, 6.6).fill(Pal.pink)
                oval(24.2, 22.2, 6.6, 6.6).fill(Pal.pink)
                oval(15.8, 22.2, 6.6, 6.6).fill(Pal.pink)
                oval(13.2, 14.2, 6.6, 6.6).fill(Pal.pink)
                oval(20, 16.4, 4.4, 4.4).fill(Pal.yellow)
                oval(18.6, 15.2, 0.8, 0.8).fill(Pal.gold)
            }
            Group {
                oval(21.6, 15.6, 0.8, 0.8).fill(Pal.gold)
                oval(20, 18.2, 0.8, 0.8).fill(Pal.gold)
                oval(17.4, 4.6, 2.2, 1.1, turn: -10).fill(Pal.white.opacity(0.6))
            }
        }
    }
}

private struct TimerSticker: View {
    var body: some View {
        StickerCanvas {
            Group {
                oval(9.8, 8.8, 5.2, 5.2).fill(Pal.red)
                oval(30.2, 8.8, 5.2, 5.2).fill(Pal.red)
                shape("M 20 5.2 L 20 8.6").stroke(Pal.ink, style: .soft(2.2))
                oval(20, 4.6, 1.9, 1.9).fill(Pal.ink)
                shape("M 11.4 31.6 L 8.2 36").stroke(Pal.ink, style: .soft(2.6))
                shape("M 28.6 31.6 L 31.8 36").stroke(Pal.ink, style: .soft(2.6))
                oval(20, 21.4, 13.8, 13.8).fill(Pal.red)
                oval(20, 21.4, 10.6, 10.6).fill(Pal.snow)
                shape("M 20 21.4 L 20 14.6").stroke(Pal.ink, style: .soft(1.9))
            }
            Group {
                shape("M 20 21.4 L 24.8 24").stroke(Pal.ink, style: .soft(1.9))
                oval(20, 21.4, 1.4, 1.4).fill(Pal.red)
                oval(10.6, 14, 2.6, 1.4, turn: -42).fill(Pal.white.opacity(0.6))
                oval(7.8, 6.8, 1.4, 0.8, turn: -30).fill(Pal.white.opacity(0.6))
            }
        }
    }
}

private struct GiftSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 20 13.2 C 15 5.6 8.6 6.6 10.2 10.8 C 11.2 13.4 15.8 13.6 20 13.2 Z").fill(Pal.gold)
            shape("M 20 13.2 C 25 5.6 31.4 6.6 29.8 10.8 C 28.8 13.4 24.2 13.6 20 13.2 Z").fill(Pal.gold)
            box(6, 18.4, 28, 17, 2.6).fill(Pal.red)
            box(4.4, 13, 31.2, 7, 2.6).fill(Pal.rose)
            box(17.4, 13, 5.2, 22.4, 0.6).fill(Pal.yellow)
            oval(20, 12.8, 2.3, 2.3).fill(Pal.yellow)
            oval(9.4, 15.4, 2.6, 0.8).fill(Pal.white.opacity(0.6))
        }
    }
}

private struct ShirtSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 13 5 L 8 7.6 L 3.2 14 L 8.6 18.6 L 11 15.6 L 11 34 C 11 35 11.8 35.6 12.6 35.6 L 27.4 35.6 C 28.2 35.6 29 35 29 34 L 29 15.6 L 31.4 18.6 L 36.8 14 L 32 7.6 L 27 5 C 25.6 7.6 23 8.6 20 8.6 C 17 8.6 14.4 7.6 13 5 Z").fill(Pal.sky)
            shape("M 13 5 L 8 7.6 L 3.2 14 L 8.6 18.6 L 11 15.6 L 11 34 C 11 35 11.8 35.6 12.6 35.6 L 27.4 35.6 C 28.2 35.6 29 35 29 34 L 29 15.6 L 31.4 18.6 L 36.8 14 L 32 7.6 L 27 5 C 25.6 7.6 23 8.6 20 8.6 C 17 8.6 14.4 7.6 13 5 Z").stroke(Pal.sky, style: .soft(2))
            shape("M 13.4 5.6 C 15 8.8 17.4 9.8 20 9.8 C 22.6 9.8 25 8.8 26.6 5.6").stroke(Pal.deep, style: .soft(1.6))
            shape("M 20 17 L 21.2 19.9 L 24.4 20.2 L 22 22.2 L 22.7 25.3 L 20 23.7 L 17.3 25.3 L 18 22.2 L 15.6 20.2 L 18.8 19.9 Z").fill(Pal.white)
            oval(14.8, 17, 1.2, 3.6).fill(Pal.white.opacity(0.5))
        }
    }
}

private struct BoltSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 23.4 3 L 8 22.2 L 18.2 22.2 L 15 37 L 32.2 15.8 L 22 15.8 L 25.6 3 Z").fill(Pal.yellow)
            shape("M 23.4 3 L 8 22.2 L 18.2 22.2 L 15 37 L 32.2 15.8 L 22 15.8 L 25.6 3 Z").stroke(Pal.gold, style: .soft(1.8))
            oval(19.4, 9.6, 0.8, 3.2, turn: 38).fill(Pal.white.opacity(0.7))
        }
    }
}

private struct SparkleSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 16 9 Q 18.1 20.3 29.4 22.4 Q 18.1 24.5 16 35.8 Q 13.9 24.5 2.6 22.4 Q 13.9 20.3 16 9 Z").fill(Pal.yellow)
            shape("M 30.4 3.2 Q 31.4 8.4 36.6 9.4 Q 31.4 10.4 30.4 15.6 Q 29.4 10.4 24.2 9.4 Q 29.4 8.4 30.4 3.2 Z").fill(Pal.gold)
            shape("M 31.4 26 Q 32.1 29.9 36 30.6 Q 32.1 31.3 31.4 35.2 Q 30.7 31.3 26.8 30.6 Q 30.7 29.9 31.4 26 Z").fill(Pal.gold)
            oval(13.6, 18.4, 1, 2.2).fill(Pal.white.opacity(0.6))
        }
    }
}

private struct TargetSticker: View {
    var body: some View {
        StickerCanvas {
            oval(18.6, 21.4, 15.2, 15.2).fill(Pal.red)
            oval(18.6, 21.4, 11.4, 11.4).fill(Pal.white)
            oval(18.6, 21.4, 7.6, 7.6).fill(Pal.red)
            oval(18.6, 21.4, 3.8, 3.8).fill(Pal.white)
            shape("M 18.6 21.4 L 32.6 7.4").stroke(Pal.ink, style: .soft(1.9))
            shape("M 31 5.2 L 34.4 1.8 L 35.2 4.8 L 38.2 5.6 L 34.8 9 Z").fill(Pal.sky)
            oval(9.6, 14.4, 2.4, 1.2, turn: -42).fill(Pal.white.opacity(0.5))
        }
    }
}

private struct MirrorSticker: View {
    var body: some View {
        StickerCanvas {
            box(17.4, 25, 5.2, 12.4, 2.6).fill(Pal.rose)
            oval(20, 15, 11.4, 12.6).fill(Pal.rose)
            oval(20, 15, 8.6, 9.8).fill(Pal.ice)
            oval(20, 17.4, 8.6, 7.4).fill(Pal.sky.opacity(0.3))
            shape("M 14.6 12.4 L 18.6 7.8").stroke(Pal.white, style: .soft(1.8))
            shape("M 15.6 17.6 L 22.8 9.6").stroke(Pal.white, style: .soft(1.4))
            shape("M 33 24.6 Q 33.7 28.3 37.4 29 Q 33.7 29.7 33 33.4 Q 32.3 29.7 28.6 29 Q 32.3 28.3 33 24.6 Z").fill(Pal.gold)
            oval(18.8, 30, 0.6, 1.8).fill(Pal.white.opacity(0.5))
        }
    }
}

private struct PencilSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 25.5 9.8 L 28.6 6.7 Q 30.2 5 31.9 6.7 L 33.9 8.7 Q 35.6 10.4 33.9 12 L 30.8 15.1 Z").fill(Pal.rose)
            shape("M 23.7 11.6 L 25.9 9.3 L 31.3 14.7 L 29 16.9 Z").fill(Pal.steel)
            shape("M 9.1 26.2 L 23.9 11.4 L 29.2 16.7 L 14.4 31.5 Z").fill(Pal.gold)
            shape("M 9.1 26.2 L 23.9 11.4 L 25.9 13.4 L 11.2 28.2 Z").fill(Pal.yellow)
            shape("M 9.1 26.2 L 6.4 34.2 L 14.4 31.5 Z").fill(Pal.tan)
            shape("M 7.4 31.2 L 6.4 34.2 L 9.4 33.2 Z").fill(Pal.ink)
        }
    }
}

private struct FaceSticker: View {
    var body: some View {
        StickerCanvas(rim: 3.4) {
            oval(15.2, 15.2, 9.4, 9.4).fill(Pal.face)
            oval(24.8, 15.2, 9.4, 9.4).fill(Pal.face)
            oval(15.2, 24.8, 9.4, 9.4).fill(Pal.face)
            oval(24.8, 24.8, 9.4, 9.4).fill(Pal.face)
            oval(20, 20, 12.4, 12.4).fill(Pal.face)
            oval(15.6, 18.2, 1.4, 1.4).fill(Pal.ink)
            oval(24.4, 18.2, 1.4, 1.4).fill(Pal.ink)
            shape("M 17 22.8 Q 20 25.6 23 22.8").stroke(Pal.ink, style: .soft(1.6))
            oval(11.6, 11.6, 2.4, 1.2, turn: -45).fill(Pal.white.opacity(0.6))
        }
    }
}

private struct RocketSticker: View {
    var body: some View {
        StickerCanvas {
            shape("M 14 16.7 L 3.7 18.3 L 1.3 21.5 L 8.4 23 Z").fill(Pal.red)
            shape("M 23.3 26 L 21.7 36.3 L 18.5 38.7 L 17 31.6 Z").fill(Pal.red)
            shape("M 9.9 24.5 Q 2.2 37.8 15.5 30.1 Z").fill(Pal.gold)
            shape("M 11.2 25.8 Q 6.9 33.1 14.2 28.8 Z").fill(Pal.yellow)
            shape("M 34 6 C 34.5 15.9 27.6 24.7 17.2 32.2 L 7.8 22.8 C 15.3 12.4 24.1 5.5 34 6 Z").fill(Pal.sky)
            shape("M 32.9 12 C 31.7 18.3 26.7 24.5 17.2 32.2 L 14.7 29.7 C 23.7 22.6 28.9 16.7 32.9 12 Z").fill(Pal.deep)
            oval(23.3, 16.7, 4, 4, turn: 45).fill(Pal.white)
            shape("M 23.1 13.9 Q 26.1 14.6 25.6 17.8").stroke(Pal.ink, style: .soft(1.5))
            oval(23, 12.6, 0.9, 3.4, turn: 45).fill(Pal.white.opacity(0.7))
        }
    }
}
