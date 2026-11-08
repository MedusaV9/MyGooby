import SpriteKit
import SwiftUI
import UIKit

/// Particle effects for rewards (masterprompt 6.3, "Belohnungen mit Partikeln präsentieren").
enum CelebrationStyle: Equatable {
    /// Small multicolored star burst (goal checked, quest claimed, item bought).
    case sparkle
    /// Confetti raining from the top edge (all goals done, growth stage, story reward).
    case confetti
    /// A few hearts floating up (petting, Gooby back home, a friend's visit, mini-friends).
    case hearts

    /// Seconds until the last particle is gone; the view pauses afterwards.
    var length: Double {
        switch self {
        case .sparkle: return 1.6
        case .confetti: return 3.6
        case .hearts: return 2.6
        }
    }
}

/// SpriteKit layer for the bursts. The scene stays empty (and its view paused) between bursts.
final class SparkleScene: SKScene {
    private(set) var lastToken = -1
    private var pending: CelebrationStyle?

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .clear
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
    }

    /// Plays `style` once per new `token` (> 0).
    func burst(token: Int, style: CelebrationStyle = .sparkle) {
        guard token != lastToken, token > 0 else { return }
        lastToken = token
        removeAllChildren()
        guard size.width > 2, size.height > 2 else {
            pending = style
            return
        }
        emit(style)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if let style = pending, size.width > 2, size.height > 2 {
            pending = nil
            emit(style)
        }
    }

    private func emit(_ style: CelebrationStyle) {
        switch style {
        case .sparkle:
            for (index, color) in SparkleScene.palette.enumerated() {
                add(sparkle(color: color, texture: index.isMultiple(of: 2) ? SparkleScene.star : SparkleScene.dot), for: style)
            }
        case .confetti:
            for (index, color) in SparkleScene.palette.enumerated() {
                add(confetti(color: color, texture: index.isMultiple(of: 3) ? SparkleScene.star : SparkleScene.strip), for: style)
            }
            add(sparkle(color: SparkleScene.palette[1], texture: SparkleScene.star), for: style)
        case .hearts:
            add(hearts(color: SparkleScene.heartPink), for: style)
            add(hearts(color: SparkleScene.heartRed), for: style)
        }
    }

    private func add(_ emitter: SKEmitterNode, for style: CelebrationStyle) {
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: style.length + 0.4), .removeFromParent()]))
    }

    /// Radial burst a little above the middle.
    private func sparkle(color: UIColor, texture: SKTexture) -> SKEmitterNode {
        let emitter = base(color: color, texture: texture)
        emitter.position = CGPoint(x: size.width / 2, y: size.height * 0.56)
        emitter.particlePositionRange = CGVector(dx: 30, dy: 30)
        emitter.particleBirthRate = 420
        emitter.numParticlesToEmit = 8
        emitter.particleLifetime = 0.95
        emitter.particleLifetimeRange = 0.35
        emitter.particleSpeed = 170
        emitter.particleSpeedRange = 80
        emitter.emissionAngleRange = .pi * 2
        emitter.yAcceleration = -140
        emitter.particleAlphaSpeed = -0.95
        emitter.particleScale = 0.42
        emitter.particleScaleRange = 0.18
        emitter.particleScaleSpeed = -0.25
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = 2.5
        return emitter
    }

    /// Paper strips and stars falling from across the top edge.
    private func confetti(color: UIColor, texture: SKTexture) -> SKEmitterNode {
        let emitter = base(color: color, texture: texture)
        emitter.position = CGPoint(x: size.width / 2, y: size.height + 12)
        emitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
        emitter.particleBirthRate = 46
        emitter.numParticlesToEmit = 16
        emitter.particleLifetime = 2.6
        emitter.particleLifetimeRange = 0.6
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 4
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 70
        emitter.yAcceleration = -170
        emitter.xAcceleration = 0
        emitter.particleAlphaSpeed = -0.22
        emitter.particleScale = 0.55
        emitter.particleScaleRange = 0.25
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 3.5
        return emitter
    }

    /// Hearts rising from Gooby's height.
    private func hearts(color: UIColor) -> SKEmitterNode {
        let emitter = base(color: color, texture: SparkleScene.heart)
        emitter.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        emitter.particlePositionRange = CGVector(dx: min(160, size.width * 0.4), dy: 24)
        emitter.particleBirthRate = 9
        emitter.numParticlesToEmit = 6
        emitter.particleLifetime = 1.8
        emitter.particleLifetimeRange = 0.4
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = 0.6
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 30
        emitter.yAcceleration = 25
        emitter.particleAlphaSpeed = -0.5
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.18
        emitter.particleScaleSpeed = 0.08
        emitter.particleRotationRange = 0.5
        return emitter
    }

    private func base(color: UIColor, texture: SKTexture) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleAlpha = 1
        emitter.particleBlendMode = .alpha
        return emitter
    }

    // MARK: Palette and textures (white shapes, tinted per emitter)

    fileprivate static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    /// Pink, yellow, lavender, mint, sky, peach (masterprompt 6.2, a little stronger so they read
    /// on the cream and green screens).
    static let palette: [UIColor] = ([0xFF8FB8, 0xFFCF4A, 0xB49BFF, 0x6FD3A6, 0x72C2FF, 0xFFA868] as [UInt32]).map(SparkleScene.rgb)
    static let heartPink = SparkleScene.rgb(0xFF8FB8)
    static let heartRed = SparkleScene.rgb(0xF2557A)

    fileprivate static func texture(_ size: CGSize, draw: (CGContext, CGRect) -> Void) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            draw(ctx.cgContext, CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }

    static let dot: SKTexture = SparkleScene.texture(CGSize(width: 16, height: 16)) { ctx, rect in
        ctx.fillEllipse(in: rect.insetBy(dx: 1, dy: 1))
    }

    static let strip: SKTexture = SparkleScene.texture(CGSize(width: 10, height: 18)) { _, rect in
        UIBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 3).fill()
    }

    static let star: SKTexture = SparkleScene.texture(CGSize(width: 26, height: 26)) { _, rect in
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let path = UIBezierPath()
        for index in 0..<10 {
            let radius = index.isMultiple(of: 2) ? rect.width * 0.48 : rect.width * 0.2
            let angle = -CGFloat.pi / 2 + CGFloat(index) * .pi / 5
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.close()
        path.lineJoinStyle = .round
        path.fill()
    }

    static let heart: SKTexture = SparkleScene.texture(CGSize(width: 26, height: 24)) { _, rect in
        let w = rect.width
        let h = rect.height
        let path = UIBezierPath()
        path.move(to: CGPoint(x: w / 2, y: h * 0.95))
        path.addCurve(to: CGPoint(x: 0.5, y: h * 0.32), controlPoint1: CGPoint(x: w * 0.3, y: h * 0.78), controlPoint2: CGPoint(x: 0.5, y: h * 0.58))
        path.addArc(withCenter: CGPoint(x: w * 0.27, y: h * 0.3), radius: w * 0.25, startAngle: .pi, endAngle: 0, clockwise: true)
        path.addArc(withCenter: CGPoint(x: w * 0.73, y: h * 0.3), radius: w * 0.25, startAngle: .pi, endAngle: 0, clockwise: true)
        path.addCurve(to: CGPoint(x: w / 2, y: h * 0.95), controlPoint1: CGPoint(x: w - 0.5, y: h * 0.58), controlPoint2: CGPoint(x: w * 0.7, y: h * 0.78))
        path.close()
        path.fill()
    }
}

/// Particle overlay: plays `style` whenever `token` changes. The SpriteKit view is only in the
/// hierarchy while a burst is on screen (an idle, paused SpriteView inside a full-screen cover
/// drew an opaque grey layer over the whole cover) and never when `enabled` is false (reduced
/// motion). The scene starts at zero size, so the first burst waits for the view's real size.
struct SparkleOverlay: View {
    var token: Int
    var enabled: Bool
    var style: CelebrationStyle = .sparkle
    @State private var scene = SparkleScene(size: .zero)
    @State private var running = false

    var body: some View {
        ZStack {
            if enabled && running {
                SpriteView(scene: scene, options: [.allowsTransparency])
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: token) { _, newValue in
            if enabled { play(newValue) }
        }
    }

    private func play(_ value: Int) {
        guard value > 0 else { return }
        scene.burst(token: value, style: style)
        running = true
        let length = style.length
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((length + 0.5) * 1_000_000_000))
            if scene.lastToken == value { running = false }
        }
    }
}
