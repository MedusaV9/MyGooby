import AVFoundation
import Foundation

/// Sound effects for app moments (masterprompt 2.1 AVFoundation, 27 "Soundeffekte").
/// Effects are bundled files rendered with earshot (Gooby/Resources/Sounds, no streaming).
/// `enabled` mirrors Settings > Preferences > Sound effects (`GoobyEngine.soundEffectsOn`).
@MainActor
final class GoobySounds {
    static let shared = GoobySounds()

    var enabled = true

    /// Every moment from `MomentHub`; plays the matching effect. Muted in screenshot runs.
    func handle(_ moment: GoobyMoment) {
        guard enabled else { return }
        // Sound mapping comes with the sounds extra.
    }
}
