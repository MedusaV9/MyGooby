import SwiftUI

struct MicropetGlyph: View {
    var id: String
    var ink: Color?

    var body: some View {
        ZStack {
            switch id {
            case "chick": chick
            case "cloud": cloud
            case "dragon": dragon
            case "fox": fox
            case "starling": starling
            case "penguin": penguin
            case "bear": bear
            case "cat": cat
            case "ghost": ghost
            case "unicorn": unicorn
            case "moon": moon
            case "mushroom": mushroom
            case "sprout": sprout
            case "lantern": lantern
            case "pebble": pebble
            case "kite": kite
            case "teacup": teacup
            default: comet
            }
        }
        .scaleEffect(1.35)
    }

    private func paint(_ color: Color) -> Color { ink ?? color }

    private var chick: some View {
        ZStack {
            Circle().fill(paint(Color(hex: 0xE7D3A8))).frame(width: 22).offset(y: -14)
            ProfileTriangle().fill(paint(Color(hex: 0xE7D3A8))).frame(width: 8, height: 10).offset(y: -26)
            ProfileTriangle().fill(paint(Color(hex: 0xE7D3A8))).frame(width: 12, height: 8).rotationEffect(.degrees(90)).offset(x: 14, y: -12)
            Capsule().fill(paint(Color(hex: 0xE7D3A8))).frame(width: 4, height: 16).offset(x: -5, y: 6)
            Capsule().fill(paint(Color(hex: 0xE7D3A8))).frame(width: 4, height: 16).offset(x: 5, y: 6)
            Ellipse().fill(paint(Color(hex: 0xE7D3A8))).frame(width: 12, height: 6).offset(x: -8, y: 16)
            Ellipse().fill(paint(Color(hex: 0xE7D3A8))).frame(width: 12, height: 6).offset(x: 8, y: 16)
        }
    }

    private var cloud: some View {
        ZStack {
            Circle().fill(paint(Color(hex: 0xE7F1F8))).frame(width: 22).offset(x: -10, y: 4)
            Circle().fill(paint(Color(hex: 0xE7F1F8))).frame(width: 28).offset(y: -2)
            Circle().fill(paint(Color(hex: 0xE7F1F8))).frame(width: 18).offset(x: 12, y: 6)
        }
    }

    private var dragon: some View {
        ZStack {
            Ellipse().fill(paint(Color(hex: 0x8FCBB0))).frame(width: 28, height: 24).offset(y: 8)
            Circle().fill(paint(Color(hex: 0x8FCBB0))).frame(width: 22).offset(x: 4, y: -8)
            ProfileTriangle().fill(paint(Color(hex: 0x8FCBB0))).frame(width: 10, height: 16).offset(x: -6, y: -20)
            ProfileTriangle().fill(paint(Color(hex: 0x8FCBB0))).frame(width: 10, height: 18).offset(x: 8, y: -22)
            Ellipse().fill(paint(Color(hex: 0x8FCBB0))).frame(width: 18, height: 12).offset(x: 16, y: -4)
            Ellipse().fill(paint(Color(hex: 0x8FCBB0))).frame(width: 16, height: 10).rotationEffect(.degrees(-20)).offset(x: -18, y: 10)
        }
    }

    private var fox: some View {
        ZStack {
            Ellipse().fill(paint(Color(hex: 0xF09A4A))).frame(width: 22, height: 14).rotationEffect(.degrees(-28)).offset(x: -16, y: 12)
            Ellipse().fill(paint(Color(hex: 0xF09A4A))).frame(width: 30, height: 24).offset(y: 10)
            Circle().fill(paint(Color(hex: 0xF09A4A))).frame(width: 24).offset(x: 4, y: -6)
            ProfileTriangle().fill(paint(Color(hex: 0xF09A4A))).frame(width: 12, height: 18).offset(x: -8, y: -20)
            ProfileTriangle().fill(paint(Color(hex: 0xF09A4A))).frame(width: 12, height: 20).offset(x: 10, y: -22)
            Ellipse().fill(paint(Color(hex: 0xF09A4A))).frame(width: 16, height: 12).offset(x: 16, y: -2)
            Ellipse().fill(paint(Color.white)).frame(width: 14, height: 10).offset(x: 4, y: 2)
            Circle().fill(paint(Color(hex: 0x3A2416))).frame(width: 4).offset(x: -1, y: -8)
            Circle().fill(paint(Color(hex: 0x3A2416))).frame(width: 4).offset(x: 9, y: -8)
            Ellipse().fill(paint(Color(hex: 0x3A2416))).frame(width: 5, height: 3).offset(x: 18, y: -2)
        }
    }

    private var starling: some View {
        ProfileSun(points: 5, inner: 0.46)
            .fill(paint(Color(hex: 0xFFE08A)))
            .frame(width: 36, height: 36)
    }

    private var penguin: some View {
        ZStack {
            Ellipse().fill(paint(Color(hex: 0x5C5348))).frame(width: 26, height: 28).offset(y: 4)
            Circle().fill(paint(Color(hex: 0x5C5348))).frame(width: 18).offset(y: -14)
            ProfileTriangle().fill(paint(Color(hex: 0x5C5348))).frame(width: 12, height: 8).rotationEffect(.degrees(90)).offset(x: 12, y: -14)
            Ellipse().fill(paint(Color(hex: 0x5C5348))).frame(width: 16, height: 8).rotationEffect(.degrees(-24)).offset(x: -16, y: 2)
            Ellipse().fill(paint(Color(hex: 0x5C5348))).frame(width: 16, height: 8).rotationEffect(.degrees(24)).offset(x: 16, y: 2)
            Ellipse().fill(paint(Color(hex: 0x5C5348))).frame(width: 12, height: 6).offset(x: -6, y: 18)
            Ellipse().fill(paint(Color(hex: 0x5C5348))).frame(width: 12, height: 6).offset(x: 6, y: 18)
        }
    }

    private var bear: some View {
        ZStack {
            Circle().fill(paint(Color(hex: 0xE7C4A8))).frame(width: 32)
            Circle().fill(paint(Color(hex: 0xC9956A))).frame(width: 12).offset(x: -14, y: -14)
            Circle().fill(paint(Color(hex: 0xC9956A))).frame(width: 12).offset(x: 14, y: -14)
            Ellipse().fill(paint(Color(hex: 0xFFD0DC))).frame(width: 12, height: 8).offset(y: 6)
        }
    }

    private var cat: some View {
        ZStack {
            Ellipse().fill(paint(Color(hex: 0xF4E4D4))).frame(width: 30, height: 24).offset(y: 4)
            Circle().fill(paint(Color(hex: 0xF4E4D4))).frame(width: 18).offset(x: 8, y: -6)
            ProfileTriangle().fill(paint(Color(hex: 0xF4E4D4))).frame(width: 7, height: 8).offset(x: 4, y: -16)
            ProfileTriangle().fill(paint(Color(hex: 0xF4E4D4))).frame(width: 7, height: 8).offset(x: 12, y: -16)
            Capsule().fill(paint(Color(hex: 0xF4E4D4))).frame(width: 6, height: 16).rotationEffect(.degrees(30)).offset(x: -16, y: 2)
        }
    }

    private var ghost: some View {
        ZStack {
            ProfileTriangle().fill(paint(Color(hex: 0xE4D8C4))).frame(width: 32, height: 26).offset(y: -20)
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(paint(Color(hex: 0xE4D8C4))).frame(width: 32, height: 16).offset(y: -2)
            Circle().fill(paint(Color(hex: 0xE4D8C4))).frame(width: 16).offset(x: -12, y: 12)
            Circle().fill(paint(Color(hex: 0xE4D8C4))).frame(width: 16).offset(y: 14)
            Circle().fill(paint(Color(hex: 0xE4D8C4))).frame(width: 16).offset(x: 12, y: 12)
            Ellipse().fill(paint(Color(hex: 0xE4D8C4))).frame(width: 16, height: 10).offset(x: -20, y: 0)
        }
    }

    private var unicorn: some View {
        ZStack {
            Circle().fill(paint(Color(hex: 0xF7F4EF))).frame(width: 30)
            Capsule().fill(paint(Color(hex: 0xD3C2FF))).frame(width: 6, height: 16).offset(y: -22)
            Capsule().fill(paint(Color(hex: 0xFFD6E7))).frame(width: 8, height: 14).rotationEffect(.degrees(20)).offset(x: 12, y: -8)
        }
    }

    private var moon: some View {
        Crescent().fill(paint(Color(hex: 0xFFE7A0)), style: FillStyle(eoFill: true))
            .frame(width: 32, height: 32)
    }

    private var mushroom: some View {
        ZStack {
            Capsule().fill(paint(Color(hex: 0xFFF1E4))).frame(width: 14, height: 18).offset(y: 8)
            Ellipse().fill(paint(Color(hex: 0xF3A0B5))).frame(width: 34, height: 20).offset(y: -4)
        }
    }

    private var sprout: some View {
        ZStack {
            Capsule().fill(paint(Color(hex: 0x7EC8A4))).frame(width: 4, height: 22).offset(y: 8)
            Ellipse().fill(paint(Color(hex: 0x7EC8A4))).frame(width: 16, height: 7).rotationEffect(.degrees(-36)).offset(x: -10, y: 6)
            Ellipse().fill(paint(Color(hex: 0x7EC8A4))).frame(width: 16, height: 7).rotationEffect(.degrees(34)).offset(x: 10, y: 8)
            Ellipse().fill(paint(Color(hex: 0x7EC8A4))).frame(width: 10, height: 14).offset(y: -12)
            Ellipse().fill(paint(Color(hex: 0x7EC8A4))).frame(width: 10, height: 14).rotationEffect(.degrees(-50)).offset(x: -8, y: -16)
            Ellipse().fill(paint(Color(hex: 0x7EC8A4))).frame(width: 10, height: 14).rotationEffect(.degrees(48)).offset(x: 8, y: -16)
            Circle().fill(paint(Color(hex: 0x7EC8A4))).frame(width: 8).offset(y: -12)
        }
    }

    private var lantern: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(paint(Color(hex: 0xFFE08A))).frame(width: 22, height: 26)
            Capsule().fill(paint(Color(hex: 0xC9956A))).frame(width: 16, height: 4).offset(y: -16)
            Capsule().fill(paint(Color(hex: 0xC9956A))).frame(width: 4, height: 8).offset(y: 16)
        }
    }

    private var pebble: some View {
        Ellipse().fill(paint(Color(hex: 0xD7CBBA))).frame(width: 32, height: 24)
    }

    private var kite: some View {
        ZStack {
            ProfileDiamond().fill(paint(Color(hex: 0xF3A0B5))).frame(width: 28, height: 34)
            Capsule().fill(paint(Color(hex: 0xC9956A))).frame(width: 2, height: 16).offset(y: 22)
        }
    }

    private var teacup: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(paint(Color(hex: 0xFFF6EA))).frame(width: 26, height: 8).offset(y: -8)
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(paint(Color(hex: 0xF7C9D8))).frame(width: 28, height: 18).offset(y: 4)
            Circle().stroke(paint(Color(hex: 0xE7A0B8)), lineWidth: 3).frame(width: 10, height: 12).offset(x: 16, y: 4)
        }
    }

    private var comet: some View {
        ZStack {
            Capsule().fill(paint(Color(hex: 0xD3C2FF))).frame(width: 28, height: 10).rotationEffect(.degrees(-32)).offset(x: -6, y: 4)
            Circle().fill(paint(Color(hex: 0xFFE08A))).frame(width: 16).offset(x: 8, y: -8)
        }
    }
}

struct Crescent: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        let cut = rect.insetBy(dx: rect.width * 0.22, dy: rect.height * 0.18).offsetBy(dx: rect.width * 0.28, dy: -rect.height * 0.02)
        path.addEllipse(in: cut)
        return path
    }
}

struct ProfileTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ProfileDiamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct PlaceStamp: View {
    var place: PlaceSnap

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hexString: place.skyTop), Color(hexString: place.skyBottom)],
                startPoint: .top,
                endPoint: .bottom
            )
            motif
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder private var motif: some View {
        switch place.id {
        case "garden": garden
        case "cherry": cherry
        case "crystal": crystal
        case "beach": beach
        case "sugar": sugar
        case "clouds": clouds
        case "starwood": starwood
        case "moon": moonValley
        case "snow": snow
        default: meadow
        }
    }

    private var meadow: some View {
        ZStack {
            Circle().fill(Color(hex: 0xFFE7A0)).frame(width: 16).offset(x: 32, y: -34)
            Ellipse().fill(Color(hex: 0xB7D99A)).frame(width: 56, height: 36).offset(x: -40, y: 4)
            Ellipse().fill(Color(hex: 0xA8D48C)).frame(width: 52, height: 40).offset(x: 42, y: 8)
            ProfileTriangle().fill(Color(hex: 0x3E8C48)).frame(width: 28, height: 36).offset(x: -36, y: -6)
            ProfileTriangle().fill(Color(hex: 0x5EAE62)).frame(width: 18, height: 26).offset(x: -24, y: 2)
            ProfileTriangle().fill(Color(hex: 0x3E8C48)).frame(width: 26, height: 34).offset(x: 36, y: 0)
            Capsule().fill(Color(hex: 0xC9956A)).frame(width: 6, height: 26).offset(x: -4, y: 2)
            Circle().fill(Color(hex: 0xF8D0DC)).frame(width: 22).offset(x: 4, y: -16)
            Circle().fill(Color(hex: 0xF7C1D4)).frame(width: 18).offset(x: -10, y: -8)
            Circle().fill(Color(hex: 0x7EC87A)).frame(width: 16).offset(x: 2, y: -2)
            hill(Color(hex: 0xC6E7B0), y: 22, h: 28)
            hill(Color(hex: 0x7FBF6E), y: 32, h: 30)
            hill(Color(hex: 0x5E9A55), y: 40, h: 22)
            Circle().fill(Color(hex: 0xE15B4C)).frame(width: 6).offset(x: -22, y: 18)
            Circle().fill(Color(hex: 0xFFE08A)).frame(width: 5).offset(x: -10, y: 24)
            Circle().fill(Color(hex: 0xF3A0B5)).frame(width: 6).offset(x: 4, y: 20)
            Circle().fill(Color.white).frame(width: 5).offset(x: 16, y: 26)
            Circle().fill(Color(hex: 0xE15B4C)).frame(width: 6).offset(x: 26, y: 18)
            Circle().fill(Color(hex: 0xF7C1D4)).frame(width: 5).offset(x: 34, y: 24)
        }
    }

    private var garden: some View {
        ZStack {
            hill(Color(hex: 0xA8D48C), y: 30, h: 34)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xC9956A)).frame(width: 16, height: 22).offset(y: 4)
            Circle().fill(Color(hex: 0xF7C1D4)).frame(width: 10).offset(x: -16, y: -2)
            Circle().fill(Color(hex: 0xFFE08A)).frame(width: 10).offset(x: 18, y: 2)
        }
    }

    private var cherry: some View {
        ZStack {
            hill(Color(hex: 0xC6E7B0), y: 30, h: 30)
            Capsule().fill(Color(hex: 0xC9956A)).frame(width: 6, height: 28).offset(x: -8, y: 2)
            Circle().fill(Color(hex: 0xF7B7C9)).frame(width: 22).offset(x: -8, y: -16)
            Capsule().fill(Color(hex: 0xC9956A)).frame(width: 6, height: 24).offset(x: 14, y: 6)
            Circle().fill(Color(hex: 0xF8C6D4)).frame(width: 18).offset(x: 14, y: -10)
        }
    }

    private var crystal: some View {
        ZStack {
            Ellipse().fill(Color(hex: 0xB9E4F5)).frame(width: 70, height: 24).offset(y: 16)
            ProfileDiamond().fill(Color(hex: 0xF4FBFF)).frame(width: 14, height: 28).offset(x: -10, y: -6)
            ProfileDiamond().fill(Color(hex: 0xD3C2FF)).frame(width: 12, height: 22).offset(x: 8, y: -2)
        }
    }

    private var beach: some View {
        ZStack {
            Circle().fill(Color(hex: 0xFFE08A)).frame(width: 16).offset(x: 26, y: -26)
            Ellipse().fill(Color(hex: 0xF6D7A8)).frame(width: 90, height: 28).offset(y: 24)
            Ellipse().fill(Color(hex: 0x9FD4EA)).frame(width: 80, height: 16).offset(y: 10)
        }
    }

    private var sugar: some View {
        ZStack {
            hill(Color(hex: 0xF7C1D4), y: 18, h: 26)
            hill(Color(hex: 0xFFE08A), y: 30, h: 24)
            Circle().fill(Color.white).frame(width: 8).offset(x: -12, y: 4)
            Circle().fill(Color.white).frame(width: 6).offset(x: 10, y: 12)
        }
    }

    private var clouds: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 22).offset(x: -16, y: 6)
            Circle().fill(Color.white).frame(width: 30).offset(y: -2)
            Circle().fill(Color.white).frame(width: 18).offset(x: 18, y: 8)
        }
    }

    private var starwood: some View {
        ZStack {
            hill(Color(hex: 0x6E8C62), y: 28, h: 30)
            Capsule().fill(Color(hex: 0x3D3656)).frame(width: 6, height: 26).offset(x: -14, y: 0)
            ProfileTriangle().fill(Color(hex: 0x2F4A3A)).frame(width: 22, height: 18).offset(x: -14, y: -16)
            Capsule().fill(Color(hex: 0x3D3656)).frame(width: 6, height: 22).offset(x: 12, y: 4)
            ProfileTriangle().fill(Color(hex: 0x2F4A3A)).frame(width: 18, height: 16).offset(x: 12, y: -10)
            Circle().fill(Color(hex: 0xFFE08A)).frame(width: 4).offset(x: 24, y: -24)
            Circle().fill(Color(hex: 0xFFE08A)).frame(width: 3).offset(x: -24, y: -18)
        }
    }

    private var moonValley: some View {
        ZStack {
            hill(Color(hex: 0xC7B7E8), y: 28, h: 32)
            Circle().fill(Color(hex: 0xFFF3C4)).frame(width: 18).offset(x: 22, y: -24)
            Circle().fill(Color(hexString: place.skyTop)).frame(width: 14).offset(x: 26, y: -26)
        }
    }

    private var snow: some View {
        ZStack {
            hill(Color.white, y: 26, h: 34)
            Capsule().fill(Color(hex: 0xD5E4EA)).frame(width: 8, height: 20).offset(x: -6, y: 2)
            Circle().fill(Color.white).frame(width: 14).offset(x: -6, y: -12)
            Circle().fill(Color(hex: 0x3D3656)).frame(width: 2).offset(x: -9, y: -13)
            Circle().fill(Color(hex: 0x3D3656)).frame(width: 2).offset(x: -3, y: -13)
        }
    }

    private func hill(_ color: Color, y: CGFloat, h: CGFloat) -> some View {
        Ellipse().fill(color).frame(width: 120, height: h).offset(y: y)
    }
}

struct NotebookDoodles: View {
    var body: some View {
        ZStack {
            Circle().fill(ProfilePalette.doodle).frame(width: 78).offset(x: -128, y: 8)
            FlowerDoodle().frame(width: 36, height: 44).offset(x: 132, y: -78)
            LeafPair().offset(x: -70, y: -62)
            BellDoodle().frame(width: 34, height: 42).offset(x: -132, y: 78)
            CloudDoodle().frame(width: 54, height: 32).offset(x: 124, y: 72)
            Circle().fill(ProfilePalette.doodle).frame(width: 8).offset(x: 8, y: -78)
            Circle().fill(ProfilePalette.doodle).frame(width: 6).offset(x: 70, y: -36)
            ProfileSun(points: 5, inner: 0.5).fill(ProfilePalette.doodle).frame(width: 16).offset(x: 86, y: -8)
            Circle().fill(ProfilePalette.doodle).frame(width: 7).offset(x: -20, y: 36)
            Capsule().fill(ProfilePalette.doodle).frame(width: 18, height: 10).rotationEffect(.degrees(-40)).offset(x: 96, y: 28)
        }
        .opacity(0.55)
        .allowsHitTesting(false)
    }
}

struct CarrotDoodle: View {
    var body: some View {
        ZStack {
            ProfileTriangle().fill(ProfilePalette.doodle).rotationEffect(.degrees(180))
            Capsule().fill(Color(hex: 0xD7C08A)).frame(width: 8, height: 12).offset(y: -16)
        }
    }
}

struct BellDoodle: View {
    var body: some View {
        ZStack {
            Capsule().fill(ProfilePalette.doodle).frame(width: 3, height: 16).offset(y: 8)
            Circle().fill(ProfilePalette.doodle).frame(width: 16).offset(y: -6)
        }
    }
}

struct LeafPair: View {
    var body: some View {
        ZStack {
            Ellipse().fill(ProfilePalette.doodle).frame(width: 16, height: 8).rotationEffect(.degrees(-30))
            Ellipse().fill(ProfilePalette.doodle).frame(width: 14, height: 7).rotationEffect(.degrees(24)).offset(x: 10, y: -6)
        }
        .frame(width: 28, height: 20)
    }
}

struct FlowerDoodle: View {
    var body: some View {
        ZStack {
            Circle().fill(ProfilePalette.doodle).frame(width: 8).offset(x: -5, y: -6)
            Circle().fill(ProfilePalette.doodle).frame(width: 8).offset(x: 5, y: -6)
            Circle().fill(ProfilePalette.doodle).frame(width: 8).offset(y: -12)
            Capsule().fill(Color(hex: 0xD7C08A)).frame(width: 2, height: 14).offset(y: 6)
        }
    }
}

struct CloudDoodle: View {
    var body: some View {
        ZStack {
            Circle().fill(ProfilePalette.doodle).frame(width: 16).offset(x: -10)
            Circle().fill(ProfilePalette.doodle).frame(width: 22)
            Circle().fill(ProfilePalette.doodle).frame(width: 14).offset(x: 12, y: 3)
        }
    }
}

struct GoobySticker: View {
    var engine: GoobyEngine
    var calm: Bool

    var body: some View {
        ZStack {
            StickerBlob().fill(Color.white)
            ZStack {
                Circle().fill(Color(hex: 0xD9F3EA)).frame(width: 78).offset(y: -8)
                Ellipse().fill(Color(hex: 0x8FCB86)).frame(width: 96, height: 34).offset(y: 30)
                Circle().fill(Color(hex: 0xF7C1D4)).frame(width: 16).offset(x: -30, y: 14)
                Circle().fill(Color(hex: 0xFFE08A)).frame(width: 12).offset(x: -8, y: 22)
                Circle().fill(Color(hex: 0xF3A0B5)).frame(width: 14).offset(x: 28, y: 16)
                Circle().fill(Color(hex: 0xFFE08A)).frame(width: 16).offset(x: 36, y: -28)
                GoobyCharacterView(
                    look: engine.wornLook(),
                    stage: Growth.stage(of: engine.pet),
                    animation: calm ? .sit : .breathe,
                    reduceMotion: calm,
                    companion: nil,
                    showCompanion: false
                )
                .frame(width: 112, height: 120)
                .offset(y: 6)
            }
            .mask(StickerBlob().scaleEffect(0.88))
        }
        .frame(width: 156, height: 140)
        .shadow(color: ProfilePalette.shadow, radius: 8, y: 4)
        .rotationEffect(.degrees(-7))
    }
}

struct StickerBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.46, y: h * 0.96))
        path.addCurve(to: CGPoint(x: w * 0.12, y: h * 0.62), control1: CGPoint(x: w * 0.22, y: h), control2: CGPoint(x: w * 0.08, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.02, y: h * 0.58))
        path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.52))
        path.addCurve(to: CGPoint(x: w * 0.32, y: h * 0.28), control1: CGPoint(x: w * 0.14, y: h * 0.4), control2: CGPoint(x: w * 0.22, y: h * 0.32))
        path.addLine(to: CGPoint(x: w * 0.36, y: h * 0.08))
        path.addLine(to: CGPoint(x: w * 0.48, y: h * 0.26))
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.06))
        path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.22))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.12))
        path.addLine(to: CGPoint(x: w * 0.96, y: h * 0.28))
        path.addLine(to: CGPoint(x: w * 0.84, y: h * 0.36))
        path.addCurve(to: CGPoint(x: w * 0.72, y: h * 0.9), control1: CGPoint(x: w * 0.96, y: h * 0.62), control2: CGPoint(x: w * 0.88, y: h * 0.86))
        path.addCurve(to: CGPoint(x: w * 0.46, y: h * 0.96), control1: CGPoint(x: w * 0.64, y: h), control2: CGPoint(x: w * 0.54, y: h))
        path.closeSubpath()
        return path
    }
}
