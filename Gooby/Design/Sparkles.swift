import SpriteKit
import SwiftUI
import UIKit

final class SparkleScene: SKScene {
    private var lastToken = -1

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .clear
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
    }

    func burst(token: Int) {
        guard token != lastToken, token > 0 else { return }
        lastToken = token
        removeAllChildren()
        let emitter = SKEmitterNode()
        emitter.particleTexture = SparkleScene.dot
        emitter.particleBirthRate = 180
        emitter.numParticlesToEmit = 28
        emitter.particleLifetime = 0.9
        emitter.particleLifetimeRange = 0.3
        emitter.particleSpeed = 90
        emitter.particleSpeedRange = 50
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.95
        emitter.particleAlphaSpeed = -1.1
        emitter.particleScale = 0.18
        emitter.particleScaleRange = 0.1
        emitter.particleColor = UIColor(red: 1, green: 0.72, blue: 0.82, alpha: 1)
        emitter.particleColorBlendFactor = 1
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(emitter)
    }

    private static let dot: SKTexture = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 1, y: 1, width: 14, height: 14))
        }
        return SKTexture(image: image)
    }()
}

struct SparkleOverlay: View {
    var token: Int
    var enabled: Bool
    @State private var scene = SparkleScene(size: CGSize(width: 240, height: 240))

    var body: some View {
        if enabled {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .allowsHitTesting(false)
                .onChange(of: token) { _, newValue in
                    scene.burst(token: newValue)
                }
        }
    }
}
