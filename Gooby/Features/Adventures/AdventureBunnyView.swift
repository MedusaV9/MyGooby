import SwiftUI

enum AdventureBunnyPose: Equatable {
    case idle
    case hop
    case rest
    case celebrate
    case think
}

/// Leichte SwiftUI-Zeichnung nach dem Referenzfoto: runder cremefarbener Kopf,
/// hohe Ohren mit rosa Innenseite, glänzende Augen, rosa Wangen und kleine Pfoten.
struct AdventureBunnyView: View {
    var pose: AdventureBunnyPose
    var reducedMotion: Bool

    @State private var moving = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(AdventurePalette.ink.opacity(0.08))
                .frame(width: 96, height: 18)
                .offset(y: 104)

            ears
                .offset(y: -86)
            bodyShape
            feet
            head
            arms
            if pose == .celebrate {
                hearts
            }
        }
        .frame(width: 210, height: 230)
        .scaleEffect(y: moving && pose != .rest ? 1.035 : 1, anchor: .bottom)
        .offset(y: hopOffset)
        .rotationEffect(.degrees(pose == .think ? -7 : 0))
        .onAppear(perform: start)
        .onChange(of: reducedMotion) { _, _ in start() }
        .onChange(of: pose) { _, _ in start() }
        .accessibilityHidden(true)
    }

    private var hopOffset: CGFloat {
        let hopping = pose == .hop || pose == .celebrate
        guard moving, hopping else { return 0 }
        return pose == .hop ? -12 : -8
    }

    private var ears: some View {
        HStack(spacing: 26) {
            ear(angle: moving ? -8 : -3)
            ear(angle: moving ? 8 : 3)
        }
    }

    private func ear(angle: Double) -> some View {
        ZStack {
            Capsule()
                .fill(AdventurePalette.fur)
                .frame(width: 38, height: 96)
                .shadow(color: AdventurePalette.furShade.opacity(0.6), radius: 0, x: 2, y: 2)
            Capsule()
                .fill(AdventurePalette.innerEar)
                .frame(width: 18, height: 64)
                .offset(y: 8)
        }
        .rotationEffect(.degrees(angle))
    }

    private var bodyShape: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [AdventurePalette.fur, AdventurePalette.furShade.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 118, height: 84)
            .offset(y: 72)
    }

    private var feet: some View {
        HStack(spacing: 16) {
            Ellipse().fill(AdventurePalette.furShade).frame(width: 30, height: 16)
            Ellipse().fill(AdventurePalette.furShade).frame(width: 30, height: 16)
        }
        .offset(y: 108)
    }

    private var head: some View {
        ZStack {
            Ellipse()
                .fill(AdventurePalette.fur)
                .frame(width: 156, height: 138)
            Ellipse()
                .fill(AdventurePalette.furShade.opacity(0.28))
                .frame(width: 120, height: 36)
                .offset(y: 46)
                .mask(Ellipse().frame(width: 156, height: 138))
            cheeks
            eyes
            noseAndMouth
        }
        .offset(y: -8)
    }

    private var cheeks: some View {
        HStack(spacing: 78) {
            Ellipse().fill(AdventurePalette.cheek.opacity(0.9)).frame(width: 40, height: 28)
            Ellipse().fill(AdventurePalette.cheek.opacity(0.9)).frame(width: 40, height: 28)
        }
        .offset(y: 22)
    }

    private var eyes: some View {
        HStack(spacing: 30) {
            eye
            eye
        }
        .offset(y: -10)
    }

    private var eye: some View {
        ZStack {
            if pose == .rest {
                Capsule()
                    .fill(AdventurePalette.eye)
                    .frame(width: 26, height: 5)
            } else {
                Circle()
                    .fill(AdventurePalette.eye)
                    .frame(width: 30, height: 30)
                Circle()
                    .fill(Color.white)
                    .frame(width: 11, height: 11)
                    .offset(x: -6, y: -7)
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 4, height: 4)
                    .offset(x: 7, y: 5)
            }
        }
        .frame(width: 30, height: 30)
    }

    private var noseAndMouth: some View {
        ZStack {
            Ellipse()
                .fill(AdventurePalette.nose)
                .frame(width: 18, height: 13)
                .offset(y: 16)
            AdventureSmile()
                .fill(AdventurePalette.eye.opacity(0.85))
                .frame(width: 28, height: 16)
                .offset(y: 30)
            Ellipse()
                .fill(AdventurePalette.tongue)
                .frame(width: 12, height: 8)
                .offset(y: 34)
        }
    }

    private var arms: some View {
        HStack(spacing: pose == .celebrate ? 18 : 34) {
            Capsule()
                .fill(AdventurePalette.fur)
                .frame(width: 20, height: 32)
                .rotationEffect(.degrees(pose == .celebrate ? -48 : 16))
            Capsule()
                .fill(AdventurePalette.fur)
                .frame(width: 20, height: 32)
                .rotationEffect(.degrees(pose == .celebrate ? 48 : -16))
        }
        .offset(y: pose == .celebrate ? 48 : 58)
    }

    private var hearts: some View {
        HStack(spacing: 120) {
            AdventureHeart().fill(AdventurePalette.pink).frame(width: 16, height: 14).offset(y: moving ? -36 : -18)
            AdventureHeart().fill(AdventurePalette.lavender).frame(width: 12, height: 11).offset(y: moving ? -28 : -8)
        }
        .offset(y: -70)
    }

    private func start() {
        moving = false
        guard !reducedMotion else { return }
        withAnimation(.easeInOut(duration: pose == .hop ? 0.45 : 1.5).repeatForever(autoreverses: true)) {
            moving = true
        }
    }
}

struct AdventureSmile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY * 0.72)
        )
        return path
    }
}

struct AdventureHeart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: width / 2, y: height))
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.32),
            control1: CGPoint(x: width * 0.15, y: height * 0.72),
            control2: CGPoint(x: 0, y: height * 0.55)
        )
        path.addArc(
            center: CGPoint(x: width * 0.25, y: height * 0.28),
            radius: width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: width * 0.75, y: height * 0.28),
            radius: width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: width, y: height * 0.55),
            control2: CGPoint(x: width * 0.85, y: height * 0.72)
        )
        return path
    }
}
